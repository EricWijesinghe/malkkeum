//! Text messages (SMS and AlimTalk) through the notification outbox. A send stores a row and makes one
//! attempt at once. A failure stays in the row and the `notify_outbox` job retries it with the push
//! backoff. After `MAX_ATTEMPTS` the row is dead-lettered and the owner gets the `sms_dead_letter` alert.
//! OTP codes are not queued: the user is waiting on them (see [`retry_once`]).

use crate::{
    error::ApiResult,
    ops,
    providers::ProviderError,
    realtime::{OUTBOX_BACKOFF_SECS, OUTBOX_BATCH, OUTBOX_MAX_BATCHES},
    state::AppState,
};
use futures_util::future::join_all;
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{future::Future, time::Duration};
use uuid::Uuid;

pub const CHANNEL_SMS: &str = "sms";
pub const CHANNEL_ALIMTALK: &str = "alimtalk";
/// Attempts before a text is dead-lettered. With the 60 s base that is about four hours of retries.
const MAX_ATTEMPTS: i32 = 8;
/// Dead rows stay this long for inspection, then go: they hold a phone number.
const DEAD_KEEP_DAYS: i32 = 30;
const OTP_RETRY_DELAY: Duration = Duration::from_millis(500);

/// One text to one phone.
pub enum Message<'a> {
    Sms(&'a str),
    /// AlimTalk with an approved template. Without a template or channel id it goes out as SMS: `title` and `body` on two lines.
    Alimtalk {
        template: &'static str,
        brand: &'a str,
        title: &'a str,
        body: &'a str,
    },
}

/// Row columns for a message: channel, title, body, data. `template_ready` is whether the Solapi
/// config has the template and the channel id.
fn stored(msg: Message<'_>, template_ready: bool) -> (&'static str, String, String, Value) {
    match msg {
        Message::Sms(text) => (CHANNEL_SMS, String::new(), text.to_string(), json!({})),
        Message::Alimtalk { template, brand, title, body } if template_ready => (
            CHANNEL_ALIMTALK,
            title.to_string(),
            body.to_string(),
            json!({ "template": template, "brand": brand }),
        ),
        Message::Alimtalk { title, body, .. } => (CHANNEL_SMS, String::new(), format!("{title}\n{body}"), json!({})),
    }
}

/// Whether a failed attempt dead-letters the row. `attempts` counts the attempt that just failed.
pub fn dead_letters(attempts: i32) -> bool {
    attempts >= MAX_ATTEMPTS
}

/// Runs `attempt` and, on failure, once more after a short pause. For OTP codes only: the user is
/// waiting on the code, so it cannot wait for the job's next pass.
pub async fn retry_once<F, Fut>(mut attempt: F) -> Result<(), ProviderError>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = Result<(), ProviderError>>,
{
    match attempt().await {
        Ok(()) => Ok(()),
        Err(first) => {
            tracing::warn!(error = %first, "sms failed; one retry");
            tokio::time::sleep(OTP_RETRY_DELAY).await;
            attempt().await
        }
    }
}

/// Queues one text to `phone` and starts its first attempt in the background. Returns at once.
pub async fn send(state: &AppState, owner: Option<Uuid>, phone: &str, kind: &str, msg: Message<'_>) -> ApiResult<()> {
    let id = enqueue(state, owner, phone, kind, msg).await?;
    let state = state.clone();
    tokio::spawn(async move {
        if let Err(e) = run(&state, Some(id)).await {
            tracing::warn!(error = %e, outbox = id, "text attempt not run; the job retries it");
        }
    });
    Ok(())
}

/// Stores one text as a due row and returns its id. Nothing is sent here. Without Solapi a live server
/// refuses the text, so nothing is queued or counted as sent. Dev mode queues it: the attempt logs it.
pub async fn enqueue(state: &AppState, owner: Option<Uuid>, phone: &str, kind: &str, msg: Message<'_>) -> ApiResult<i64> {
    let integ = state.providers.integ();
    let template_ready = match (integ.solapi.as_ref(), &msg) {
        (None, _) if !state.config.dev_mode => return Err(ProviderError::NotConfigured("sms").into()),
        (Some(cfg), Message::Alimtalk { template, .. }) => cfg.templates.contains_key(*template) && cfg.pf_id.is_some(),
        _ => false,
    };
    let (channel, title, body, data) = stored(msg, template_ready);
    let id: i64 = sqlx::query_scalar(
        "INSERT INTO notification_outbox (owner_role, owner_id, kind, title, body, data, channel, phone, next_attempt_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now()) RETURNING id",
    )
    .bind(owner.map(|_| "customer"))
    .bind(owner)
    .bind(kind)
    .bind(title)
    .bind(body)
    .bind(data)
    .bind(channel)
    .bind(phone)
    .fetch_one(&state.db)
    .await?;
    Ok(id)
}

/// One pass of the `notify_outbox` job over texts: due rows are attempted, old dead rows are removed.
pub async fn pass(state: &AppState) -> ApiResult<usize> {
    sqlx::query("DELETE FROM notification_outbox WHERE dead_at < now() - make_interval(days => $1)")
        .bind(DEAD_KEEP_DAYS)
        .execute(&state.db)
        .await?;
    run(state, None).await
}

/// Texts dead-lettered and not yet removed. Shown on the console's jobs card.
pub async fn dead_count(db: &PgPool) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar("SELECT count(*) FROM notification_outbox WHERE dead_at IS NOT NULL")
        .fetch_one(db)
        .await
}

/// id, channel, phone, kind, title, body, data, attempts.
type Due = (i64, String, String, String, String, String, Value, i32);

/// Claims due text rows (all, or only `only`) and delivers them in batches. Returns how many were tried.
async fn run(state: &AppState, only: Option<i64>) -> ApiResult<usize> {
    let mut tried = 0;
    for _ in 0..OUTBOX_MAX_BATCHES {
        let rows = claim(&state.db, only).await?;
        let claimed = rows.len();
        join_all(rows.into_iter().map(|row| deliver(state, row))).await;
        tried += claimed;
        if claimed < OUTBOX_BATCH || only.is_some() {
            break;
        }
    }
    Ok(tried)
}

/// The next-attempt stamp is the lease: a claimed row is not due again until its backoff has passed.
async fn claim(db: &PgPool, only: Option<i64>) -> ApiResult<Vec<Due>> {
    let rows = sqlx::query_as(
        "UPDATE notification_outbox SET attempts = attempts + 1, next_attempt_at = now() + make_interval(secs => $1 * power(2, attempts))
         WHERE id IN (SELECT id FROM notification_outbox
                      WHERE channel <> 'push' AND dead_at IS NULL AND next_attempt_at <= now() AND ($2::BIGINT IS NULL OR id = $2)
                      ORDER BY next_attempt_at LIMIT $3 FOR UPDATE SKIP LOCKED)
         RETURNING id, channel, phone, kind, title, body, data, attempts",
    )
    .bind(OUTBOX_BACKOFF_SECS)
    .bind(only)
    .bind(OUTBOX_BATCH as i64)
    .fetch_all(db)
    .await?;
    Ok(rows)
}

async fn deliver(state: &AppState, (id, channel, phone, kind, title, body, data, attempts): Due) {
    let sent = if channel == CHANNEL_ALIMTALK {
        let template = data["template"].as_str().unwrap_or_default();
        let brand = data["brand"].as_str().unwrap_or_default();
        state.providers.send_customer_message(&phone, template, brand, &title, &body).await
    } else {
        state.providers.send_sms(&phone, &body).await
    };
    let settled = match sent {
        Ok(()) => sqlx::query("DELETE FROM notification_outbox WHERE id = $1").bind(id).execute(&state.db).await,
        Err(e) => {
            tracing::warn!(error = %e, %kind, attempts, outbox = id, "text message failed");
            let code = if channel == CHANNEL_ALIMTALK { "alimtalk_failed" } else { "sms_failed" };
            if dead_letters(attempts) {
                return dead_letter(&state.db, id, code).await;
            }
            sqlx::query("UPDATE notification_outbox SET last_error = $2 WHERE id = $1")
                .bind(id)
                .bind(code)
                .execute(&state.db)
                .await
        }
    };
    if let Err(e) = settled {
        tracing::warn!(error = %e, outbox = id, "text outbox row not settled; it will be tried again");
    }
}

/// Marks the row dead and records the failure for the `sms_dead_letter` owner alert.
async fn dead_letter(db: &PgPool, id: i64, code: &str) {
    tracing::error!(outbox = id, code, attempts = MAX_ATTEMPTS, "text message dead-lettered: attempts used up");
    if let Err(e) = sqlx::query("UPDATE notification_outbox SET dead_at = now(), last_error = $2 WHERE id = $1")
        .bind(id)
        .bind(code)
        .execute(db)
        .await
    {
        tracing::warn!(error = %e, outbox = id, "dead-letter not recorded; it will be tried again");
        return;
    }
    ops::record(db, "sms_dead_letter", Err("dead_letter")).await;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn alimtalk_without_template_becomes_sms_with_both_lines() {
        let (channel, title, body, data) = stored(
            Message::Alimtalk {
                template: "booking.status",
                brand: "b",
                title: "t",
                body: "x",
            },
            false,
        );
        assert_eq!((channel, title.as_str(), body.as_str()), ("sms", "", "t\nx"));
        assert_eq!(data, json!({}));
    }

    #[test]
    fn alimtalk_with_template_keeps_title_body_and_template() {
        let (channel, title, body, data) = stored(
            Message::Alimtalk {
                template: "booking.status",
                brand: "b",
                title: "t",
                body: "x",
            },
            true,
        );
        assert_eq!((channel, title.as_str(), body.as_str()), ("alimtalk", "t", "x"));
        assert_eq!(data, json!({ "template": "booking.status", "brand": "b" }));
    }

    #[test]
    fn plain_sms_is_stored_as_its_text() {
        let (channel, title, body, _) = stored(Message::Sms("hello"), false);
        assert_eq!((channel, title.as_str(), body.as_str()), ("sms", "", "hello"));
    }

    #[test]
    fn dead_letter_only_once_the_attempts_are_used_up() {
        assert!(!dead_letters(MAX_ATTEMPTS - 1));
        assert!(dead_letters(MAX_ATTEMPTS));
    }

    #[tokio::test]
    async fn retry_once_tries_twice_and_stops_on_success() {
        let mut calls = 0;
        let out = retry_once(|| {
            calls += 1;
            let fail = calls == 1;
            async move { if fail { Err(ProviderError::Upstream("boom".into())) } else { Ok(()) } }
        })
        .await;
        assert!(out.is_ok());
        assert_eq!(calls, 2);
    }

    #[tokio::test]
    async fn retry_once_gives_up_after_the_second_failure() {
        let mut calls = 0;
        let out = retry_once(|| {
            calls += 1;
            async { Err::<(), _>(ProviderError::Upstream("down".into())) }
        })
        .await;
        assert!(out.is_err());
        assert_eq!(calls, 2);
    }
}
