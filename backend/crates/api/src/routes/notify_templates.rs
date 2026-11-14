//! Console: owner-edited push and inbox text, per notification event and language (`i18n::EVENTS`).

use super::audit;
use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    i18n::{self, Event},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::FromRow;

const LOCALES: [&str; 2] = ["ko", "en"];
const MAX_TITLE_CHARS: usize = 40;
const MAX_BODY_CHARS: usize = 120;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/notify-templates", get(list_templates))
        .route("/notify-templates/preview", post(preview))
        .route("/notify-templates/{kind}/{locale}", put(save_template).delete(reset_template))
}

#[derive(Deserialize)]
struct TextInput {
    title: String,
    body: String,
}

#[derive(Deserialize)]
struct PreviewInput {
    kind: String,
    locale: String,
    title: String,
    body: String,
}

#[derive(FromRow)]
struct Saved {
    kind: String,
    locale: String,
    title: String,
    body: String,
}

async fn list_templates(State(s): State<AppState>, _admin: Admin) -> ApiResult<Json<Value>> {
    let saved: Vec<Saved> = sqlx::query_as("SELECT kind, locale, title, body FROM notify_templates")
        .fetch_all(&s.db)
        .await?;
    let items: Vec<Value> = i18n::EVENTS.iter().map(|ev| listing(ev, &saved)).collect();
    Ok(Json(json!({ "items": items, "variables": [i18n::BOOKING_NO, i18n::BRAND] })))
}

/// One event: its label and placeholders, then per language the built-in text beside the owner's, if any.
fn listing(ev: &Event, saved: &[Saved]) -> Value {
    let mut item = json!({ "kind": ev.kind, "label": ev.label, "variables": ev.vars });
    for lang in LOCALES {
        let (title, body) = i18n::default_text(ev, lang);
        let custom = saved
            .iter()
            .find(|r| r.kind == ev.kind && r.locale == lang)
            .map(|r| json!({ "title": r.title, "body": r.body }));
        item[lang] = json!({ "default": { "title": title, "body": body }, "custom": custom });
    }
    item
}

fn event_for(kind: &str) -> ApiResult<&'static Event> {
    i18n::event(kind).ok_or(ApiError::BadRequest("unknown_kind"))
}

fn locale_for(locale: &str) -> ApiResult<&'static str> {
    LOCALES.into_iter().find(|l| *l == locale).ok_or(ApiError::BadRequest("unknown_locale"))
}

/// Checks one text with sample values, and returns it filled in.
fn checked(text: &str, max_chars: usize, values: &[(&str, String)]) -> ApiResult<String> {
    if text.is_empty() {
        return Err(ApiError::BadRequest("text_empty"));
    }
    if text.chars().count() > max_chars {
        return Err(ApiError::BadRequest("text_too_long"));
    }
    if text.chars().any(char::is_control) {
        return Err(ApiError::BadRequest("invalid_text"));
    }
    i18n::fill(text, values).map_err(|e| ApiError::BadRequest(e.code()))
}

/// Both texts, trimmed, checked against the event's allowed placeholders.
fn checked_pair(ev: &Event, title: &str, body: &str, brand: &str) -> ApiResult<(String, String)> {
    let values = i18n::sample_values(ev.vars, brand);
    Ok((checked(title, MAX_TITLE_CHARS, &values)?, checked(body, MAX_BODY_CHARS, &values)?))
}

async fn preview(State(s): State<AppState>, _admin: Admin, Json(p): Json<PreviewInput>) -> ApiResult<Json<Value>> {
    let ev = event_for(&p.kind)?;
    locale_for(&p.locale)?;
    let brand = crate::routes::setup::brand_name(&s.db).await;
    let (title, body) = checked_pair(ev, p.title.trim(), p.body.trim(), &brand)?;
    Ok(Json(json!({ "title": title, "body": body })))
}

async fn save_template(
    State(s): State<AppState>,
    Admin(st): Admin,
    Path((kind, locale)): Path<(String, String)>,
    Json(t): Json<TextInput>,
) -> ApiResult<Json<Value>> {
    let ev = event_for(&kind)?;
    let lang = locale_for(&locale)?;
    let brand = crate::routes::setup::brand_name(&s.db).await;
    let (title, body) = (t.title.trim(), t.body.trim());
    checked_pair(ev, title, body, &brand)?;
    sqlx::query(
        "INSERT INTO notify_templates (kind, locale, title, body, updated_at) VALUES ($1, $2, $3, $4, now())
         ON CONFLICT (kind, locale) DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body, updated_at = now()",
    )
    .bind(ev.kind)
    .bind(lang)
    .bind(title)
    .bind(body)
    .execute(&s.db)
    .await?;
    audit(&s.db, "staff", Some(st.id), "notify_template.update", &format!("{}/{lang}", ev.kind), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn reset_template(State(s): State<AppState>, Admin(st): Admin, Path((kind, locale)): Path<(String, String)>) -> ApiResult<Json<Value>> {
    let ev = event_for(&kind)?;
    let lang = locale_for(&locale)?;
    sqlx::query("DELETE FROM notify_templates WHERE kind = $1 AND locale = $2")
        .bind(ev.kind)
        .bind(lang)
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(st.id), "notify_template.reset", &format!("{}/{lang}", ev.kind), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}
