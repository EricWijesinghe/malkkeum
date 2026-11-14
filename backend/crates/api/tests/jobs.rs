//! Post-commit notifications (outbox), background job safety across replicas, campaign resume, and the
//! job completion shared by the owner and the team member. Same DB and fakes as the other flow tests.

mod common;

use api::{
    auth::{self, Role},
    config::Config,
    jobs, marketing, metrics, noshow, ops,
    privacy::CONSENT_VERSION,
    realtime, routes,
    state::AppState,
};
use axum::{Router, http::StatusCode};
use chrono::{DateTime, TimeZone, Utc};
use common::{PHOTO, SECRET, book, call, customer, login, register_photo, seed_catalog, test_config, verified_pro};
use serde_json::{Value, json};
use sqlx::{Connection, PgConnection, PgPool};
use std::{
    sync::atomic::{AtomicUsize, Ordering},
    time::Duration,
};
use uuid::Uuid;

const POLL: Duration = Duration::from_millis(50);
const POLLS: usize = 100;

fn state(pool: &PgPool) -> AppState {
    api::build_state(pool.clone(), test_config()).expect("app state")
}

/// The API in live mode with no push key: every push to a device fails at the provider.
fn live_app(pool: &PgPool) -> Router {
    routes::router(
        api::build_state(
            pool.clone(),
            Config {
                dev_mode: false,
                ..test_config()
            },
        )
        .expect("app state"),
    )
}

/// 2026-11-11 12:00 KST: inside the advertising window.
fn daytime() -> DateTime<Utc> {
    Utc.with_ymd_and_hms(2026, 11, 11, 3, 0, 0).single().expect("valid instant")
}

async fn admin(pool: &PgPool) -> String {
    let id = Uuid::now_v7();
    sqlx::query("INSERT INTO staff (id, email, name, password_hash, role) VALUES ($1, $2, 'tester', 'x', 'admin')")
        .bind(id)
        .bind(format!("{id}@test.local"))
        .execute(pool)
        .await
        .expect("staff row");
    auth::issue_access(SECRET, id, Role::StaffAdmin).expect("token")
}

async fn visit_today(pool: &PgPool, id: Uuid) {
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await
        .expect("today");
}

async fn accept(app: &Router, id: Uuid, pro: &str) {
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

fn report() -> Value {
    json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] })
}

async fn inbox_count(pool: &PgPool, owner: Uuid, kind: &str) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM notifications WHERE owner_id = $1 AND kind = $2")
        .bind(owner)
        .bind(kind)
        .fetch_one(pool)
        .await
        .expect("inbox")
}

/// Outbox rows of `owner` that carry `code`. Polls, because the push runs on a background task.
async fn outbox_failed(pool: &PgPool, owner: Uuid, code: &str, want: i64) -> bool {
    for _ in 0..POLLS {
        let n: i64 = sqlx::query_scalar("SELECT count(*) FROM notification_outbox WHERE owner_id = $1 AND last_error = $2")
            .bind(owner)
            .bind(code)
            .fetch_one(pool)
            .await
            .expect("outbox");
        if n == want {
            return true;
        }
        tokio::time::sleep(POLL).await;
    }
    false
}

/// Makes the failed rows due now and runs the job's pass. Returns how many rows it tried.
async fn retry_failed(pool: &PgPool, code: &str) -> usize {
    sqlx::query("UPDATE notification_outbox SET next_attempt_at = now() WHERE last_error = $1")
        .bind(code)
        .execute(pool)
        .await
        .expect("due");
    realtime::outbox_pass(&state(pool)).await.expect("outbox pass")
}

/// True once `owner` has nothing left in the outbox. Polls: pushes of earlier requests settle in the background.
async fn outbox_drained(pool: &PgPool, owner: Uuid) -> bool {
    for _ in 0..POLLS {
        let n: i64 = sqlx::query_scalar("SELECT count(*) FROM notification_outbox WHERE owner_id = $1")
            .bind(owner)
            .fetch_one(pool)
            .await
            .expect("outbox");
        if n == 0 {
            return true;
        }
        tokio::time::sleep(POLL).await;
    }
    false
}

#[sqlx::test(migrations = "../../migrations")]
async fn push_provider_error_keeps_the_accept_200_and_the_push_is_retried(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5600-0001").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5600-0101").await;
    let (id, _) = book(&app, &c, 10, None).await;
    sqlx::query("INSERT INTO push_tokens (token, owner_role, owner_id, platform) VALUES ('tok-wp3', 'customer', $1, 'ios')")
        .bind(c.user)
        .execute(&pool)
        .await
        .expect("device");
    let before = inbox_count(&pool, c.user, "booking.status").await;

    let (st, b) = call(&live_app(&pool), "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "the job is won whatever the push service does: {b}");
    assert_eq!(inbox_count(&pool, c.user, "booking.status").await, before + 1, "the inbox row is there at once");
    assert!(outbox_failed(&pool, c.user, "push_failed", 1).await, "the failed push is recorded for retry");

    // The push service is back (dev fake): the job delivers and clears the row. No second inbox row.
    assert_eq!(retry_failed(&pool, "push_failed").await, 1);
    assert!(outbox_drained(&pool, c.user).await, "delivered");
    assert_eq!(inbox_count(&pool, c.user, "booking.status").await, before + 1, "stored once");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_failing_notification_insert_never_fails_the_request_and_is_stored_later(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5600-0002").await;
    let (pro, pro_id) = verified_pro(&app, &pool, "010-5600-0102").await;
    let staff = admin(&pool).await;
    let (won, _) = book(&app, &c, 10, None).await;
    let (done, _) = book(&app, &c, 11, None).await;
    let (manual, _) = book(&app, &c, 12, None).await;
    accept(&app, done, pro.as_str()).await;
    visit_today(&pool, done).await;
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{done}/check-in"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    register_photo(&pool, pro_id).await;

    let before = inbox_count(&pool, c.user, "booking.status").await;

    // The inbox table refuses every insert for a while.
    sqlx::query("ALTER TABLE notifications ADD CONSTRAINT broken CHECK (false) NOT VALID")
        .execute(&pool)
        .await
        .expect("break");
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{won}/accept"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "accept: {b}");
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{done}/complete"), Some(pro.as_str()), Some(report())).await;
    assert_eq!(st, StatusCode::OK, "complete: {b}");
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/admin/bookings/{manual}/status"),
        Some(staff.as_str()),
        Some(json!({ "status": 2, "team_name": "직영팀" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "status change: {b}");
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/admin/pros/{pro_id}/status"),
        Some(staff.as_str()),
        Some(json!({ "status": "verified" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "pro status: {b}");
    let settled: i64 = sqlx::query_scalar("SELECT count(*) FROM settlements WHERE booking_id = $1")
        .bind(done)
        .fetch_one(&pool)
        .await
        .expect("settlement");
    assert_eq!(settled, 1, "the completion is committed");
    assert!(
        outbox_failed(&pool, c.user, "store_failed", 3).await,
        "accept, completion and status change wait in the outbox"
    );
    assert!(outbox_failed(&pool, pro_id, "store_failed", 1).await, "so does the pro's status notice");

    assert_eq!(inbox_count(&pool, c.user, "booking.status").await, before, "nothing reached the inbox");

    sqlx::query("ALTER TABLE notifications DROP CONSTRAINT broken")
        .execute(&pool)
        .await
        .expect("repair");
    assert_eq!(retry_failed(&pool, "store_failed").await, 4);
    assert_eq!(inbox_count(&pool, c.user, "booking.completed").await, 1);
    assert_eq!(inbox_count(&pool, c.user, "booking.status").await, before + 2);
    assert_eq!(inbox_count(&pool, pro_id, "pro.status").await, 1);
    assert!(
        outbox_drained(&pool, c.user).await && outbox_drained(&pool, pro_id).await,
        "nothing left to retry"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn two_no_show_scans_in_parallel_open_one_case_per_booking(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5600-0003").await;
    let mut late = Vec::new();
    for (days, phone) in [(10, "010-5600-0103"), (11, "010-5600-0104")] {
        let (pro, _) = verified_pro(&app, &pool, phone).await;
        let (id, _) = book(&app, &c, days, None).await;
        accept(&app, id, pro.as_str()).await;
        visit_today(&pool, id).await;
        // From midnight KST: the grace period has passed.
        sqlx::query("UPDATE bookings SET start_hour = 0 WHERE id = $1")
            .bind(id)
            .execute(&pool)
            .await
            .expect("window");
        late.push(id);
    }

    let s = state(&pool);
    let (a, b) = tokio::join!(noshow::scan(&s), noshow::scan(&s));
    assert_eq!(a.expect("scan") + b.expect("scan"), 2, "each case is opened by exactly one scan");
    for id in &late {
        let cases: i64 = sqlx::query_scalar("SELECT count(*) FROM cases WHERE booking_id = $1 AND kind = 'no_show'")
            .bind(id)
            .fetch_one(&pool)
            .await
            .expect("cases");
        assert_eq!(cases, 1, "one case per booking");
    }
    assert_eq!(noshow::scan(&s).await.expect("scan"), 0, "nothing left to open");
    let dup = sqlx::query(
        "INSERT INTO cases (booking_id, kind, source, reporter_role, summary, sla_due_at) VALUES ($1, 'no_show', 'no_show', 'system', 'again', now())",
    )
    .bind(late[0])
    .execute(&pool)
    .await;
    assert!(
        dup.is_err_and(|e| e.as_database_error().and_then(|d| d.constraint().map(str::to_owned)).as_deref() == Some("cases_one_no_show_idx")),
        "the database refuses a second no-show case"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_job_pass_runs_on_one_replica_at_a_time_and_a_dead_holder_frees_it(pool: PgPool) {
    let s = state(&pool);
    let runs = AtomicUsize::new(0);
    let pass = || {
        let runs = &runs;
        async move {
            runs.fetch_add(1, Ordering::SeqCst);
            tokio::time::sleep(Duration::from_millis(300)).await;
            Ok::<_, String>(())
        }
    };
    let (a, b) = tokio::join!(jobs::run(&s, "test_job", pass()), jobs::run(&s, "test_job", pass()));
    assert_eq!(runs.load(Ordering::SeqCst), 1, "the second runner skips the pass");
    assert!(a.is_some() != b.is_some(), "exactly one runner did the work");
    assert!(jobs::run(&s, "test_job", pass()).await.is_some(), "the lock ends with the pass");
    assert!(
        jobs::run(&s, "test_job", async { Err::<(), _>("boom") }).await.is_none(),
        "a failed pass reports nothing"
    );

    // A replica that dies in the middle of a pass: its connection, and with it the lock, is gone.
    let mut dead = PgConnection::connect_with(&pool.connect_options()).await.expect("second replica");
    sqlx::query("SELECT pg_advisory_lock(hashtext('job:test_job'))")
        .execute(&mut dead)
        .await
        .expect("lock");
    assert!(jobs::run(&s, "test_job", pass()).await.is_none(), "held by the other replica");
    drop(dead);
    let mut recovered = false;
    for _ in 0..POLLS {
        if jobs::run(&s, "test_job", pass()).await.is_some() {
            recovered = true;
            break;
        }
        tokio::time::sleep(POLL).await;
    }
    assert!(recovered, "no stale lease: the next pass runs once the dead holder's connection is gone");
}

async fn consenting_customer(app: &Router, pool: &PgPool, phone: &str) -> Uuid {
    let c = customer(app, pool, phone).await;
    sqlx::query("INSERT INTO user_consents (user_id, kind, version, granted) VALUES ($1, 'marketing', $2, true)")
        .bind(c.user)
        .bind(CONSENT_VERSION)
        .execute(pool)
        .await
        .expect("consent");
    c.user
}

async fn push_campaign(pool: &PgPool, status: &str) -> Uuid {
    sqlx::query_scalar(
        "INSERT INTO campaigns (name, channel, title, body, status, scheduled_at) VALUES ('test', 'push', '신규 혜택', '이번 주 할인 안내', $1, now() - interval '1 minute') RETURNING id",
    )
    .bind(status)
    .fetch_one(pool)
    .await
    .expect("campaign")
}

#[sqlx::test(migrations = "../../migrations")]
async fn an_interrupted_campaign_resumes_without_a_second_send(pool: PgPool) {
    let app = common::app(pool.clone());
    let reached = consenting_customer(&app, &pool, "010-5600-0005").await;
    let waiting = [
        consenting_customer(&app, &pool, "010-5600-0006").await,
        consenting_customer(&app, &pool, "010-5600-0007").await,
    ];
    // The process died mid-run: the campaign is still `sending` and one customer is already recorded.
    let campaign = push_campaign(&pool, "sending").await;
    sqlx::query("INSERT INTO marketing_sends (dedupe_key, campaign_id, user_id, channel, status) VALUES ($1, $2, $3, 'push', 'sent')")
        .bind(format!("campaign:{campaign}:{reached}:push"))
        .bind(campaign)
        .bind(reached)
        .execute(&pool)
        .await
        .expect("recorded send");

    assert_eq!(
        marketing::dispatch_at(&state(&pool), daytime()).await.expect("dispatch"),
        1,
        "the next pass picks it up"
    );

    let status: String = sqlx::query_scalar("SELECT status FROM campaigns WHERE id = $1")
        .bind(campaign)
        .fetch_one(&pool)
        .await
        .expect("status");
    assert_eq!(status, "sent");
    assert_eq!(
        inbox_count(&pool, reached, "marketing.campaign").await,
        0,
        "the customer reached before the crash gets nothing more"
    );
    for user in waiting {
        assert_eq!(inbox_count(&pool, user, "marketing.campaign").await, 1, "the rest get it once");
    }
    let sends: i64 = sqlx::query_scalar("SELECT count(*) FROM marketing_sends WHERE campaign_id = $1")
        .bind(campaign)
        .fetch_one(&pool)
        .await
        .expect("sends");
    assert_eq!(sends, 3);
}

#[sqlx::test(migrations = "../../migrations")]
async fn two_dispatchers_send_a_campaign_to_each_customer_once(pool: PgPool) {
    let app = common::app(pool.clone());
    let mut users = Vec::new();
    for phone in ["010-5600-0008", "010-5600-0009", "010-5600-0010", "010-5600-0011"] {
        users.push(consenting_customer(&app, &pool, phone).await);
    }
    let campaign = push_campaign(&pool, "scheduled").await;

    let s = state(&pool);
    let (a, b) = tokio::join!(marketing::dispatch_at(&s, daytime()), marketing::dispatch_at(&s, daytime()));
    a.expect("dispatch");
    b.expect("dispatch");

    for user in users {
        assert_eq!(inbox_count(&pool, user, "marketing.campaign").await, 1, "one message per customer");
    }
    let sends: i64 = sqlx::query_scalar("SELECT count(*) FROM marketing_sends WHERE campaign_id = $1 AND status = 'sent'")
        .bind(campaign)
        .fetch_one(&pool)
        .await
        .expect("sends");
    assert_eq!(sends, 4);
}

/// Everything a completion writes for one booking, without ids and timestamps.
async fn completion_state(pool: &PgPool, booking: Uuid) -> Value {
    sqlx::query_scalar(
        "SELECT jsonb_build_object(
           'status', b.status, 'completed', b.completed_at IS NOT NULL,
           'settlement', (SELECT jsonb_build_object('pro', s.pro_id, 'gross', s.gross, 'fee', s.fee, 'net', s.net, 'payout_date', s.payout_date, 'state', s.state)
                          FROM settlements s WHERE s.booking_id = b.id),
           'report', (SELECT jsonb_build_object('before', r.before_photos, 'after', r.after_photos, 'checklist', r.checklist)
                      FROM completion_reports r WHERE r.booking_id = b.id),
           'points', (SELECT COALESCE(sum(l.amount), 0) FROM points_ledger l WHERE l.booking_id = b.id),
           'notices', (SELECT count(*) FROM notifications n WHERE n.owner_id = b.user_id AND n.kind = 'booking.completed'))
         FROM bookings b WHERE b.id = $1",
    )
    .bind(booking)
    .fetch_one(pool)
    .await
    .expect("completion state")
}

#[sqlx::test(migrations = "../../migrations")]
async fn completion_by_the_owner_and_by_a_team_member_write_the_same_state(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    // Two first-time customers with the same booking, so rewards and points start equal.
    let by_owner = book(&app, &customer(&app, &pool, "010-5600-0012").await, 10, None).await.0;
    let by_member = book(&app, &customer(&app, &pool, "010-5600-0013").await, 11, None).await.0;
    let (owner, owner_id) = verified_pro(&app, &pool, "010-5600-0105").await;
    for id in [by_owner, by_member] {
        accept(&app, id, owner.as_str()).await;
        visit_today(&pool, id).await;
    }
    let (st, team) = call(
        &app,
        "POST",
        "/v1/partner/team",
        Some(owner.as_str()),
        Some(json!({ "name": "김팀원", "phone": "010-5600-0106" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{team}");
    let member_id: Uuid = team["id"].as_str().expect("member id").parse().expect("uuid");
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/partner/jobs/{by_member}/assign"),
        Some(owner.as_str()),
        Some(json!({ "member_id": member_id })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (member, _) = login(&app, "010-5600-0106", "partner").await;
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{by_owner}/check-in"), Some(owner.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", &format!("/v1/member/jobs/{by_member}/check-in"), Some(member.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    register_photo(&pool, owner_id).await;
    register_photo(&pool, member_id).await;
    let owner_url = format!("/v1/partner/jobs/{by_owner}/complete");
    let member_url = format!("/v1/member/jobs/{by_member}/complete");

    // The team's phone gate holds on both paths.
    let phone: String = sqlx::query_scalar("UPDATE pros p SET phone = NULL FROM pros old WHERE p.id = $1 AND old.id = p.id RETURNING old.phone")
        .bind(owner_id)
        .fetch_one(&pool)
        .await
        .expect("unbind phone");
    for (url, token) in [(&owner_url, &owner), (&member_url, &member)] {
        let (st, b) = call(&app, "POST", url, Some(token.as_str()), Some(report())).await;
        assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("phone_required")), "{b}");
    }
    sqlx::query("UPDATE pros SET phone = $2 WHERE id = $1")
        .bind(owner_id)
        .bind(phone)
        .execute(&pool)
        .await
        .expect("bind phone");

    let (st, done) = call(&app, "POST", &owner_url, Some(owner.as_str()), Some(report())).await;
    assert_eq!(st, StatusCode::OK, "{done}");
    let (st, b) = call(&app, "POST", &member_url, Some(member.as_str()), Some(report())).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(b.get("net").is_none(), "no payout in the member response");

    let (left, right) = (completion_state(&pool, by_owner).await, completion_state(&pool, by_member).await);
    assert_eq!(left, right, "one completion, whoever submits it");
    assert_eq!(
        (left["status"].as_i64(), left["settlement"]["pro"].as_str()),
        (Some(3), Some(owner_id.to_string().as_str())),
        "{left}"
    );
    assert_eq!(done["net"], left["settlement"]["net"], "the owner's response shows the settled net");
    let submitted: Vec<Uuid> = sqlx::query_scalar("SELECT submitted_by FROM completion_reports WHERE booking_id = ANY($1) ORDER BY booking_id = $2 DESC")
        .bind(vec![by_owner, by_member])
        .bind(by_owner)
        .fetch_all(&pool)
        .await
        .expect("reports");
    assert_eq!(submitted, vec![owner_id, member_id], "only the submitter differs");

    // A repeat after a lost response: the first answer again, nothing written twice.
    let (st, again) = call(&app, "POST", &owner_url, Some(owner.as_str()), Some(report())).await;
    assert_eq!((st, &again["net"]), (StatusCode::OK, &done["net"]), "{again}");
    assert_eq!(completion_state(&pool, by_owner).await, left);
}

#[sqlx::test(migrations = "../../migrations")]
async fn every_job_reports_to_metrics_and_the_status_page(pool: PgPool) {
    let s = state(&pool);
    assert!(jobs::run(&s, "noshow", noshow::scan(&s)).await.is_some(), "a pass under the runner");
    assert_eq!(realtime::outbox_pass(&s).await.expect("outbox pass"), 0);

    let snap = metrics::Snapshot {
        pool_open: 1,
        pool_idle: 1,
        payouts_pending: None,
        realtime_listening: false,
        version: "test",
        uptime_secs: 1,
    };
    let text = metrics::render(&snap);
    for (job, _) in jobs::ALL {
        for series in [
            "malkkeum_job_last_run_timestamp_seconds",
            "malkkeum_job_last_success_timestamp_seconds",
            "malkkeum_job_errors_total",
        ] {
            assert!(text.contains(&format!("{series}{{job=\"{job}\"}}")), "{series} for {job}");
        }
    }

    let status = ops::status(&s).await.expect("status");
    let listed = status["jobs"].as_array().expect("jobs on the status page");
    assert_eq!(listed.len(), jobs::ALL.len(), "{status}");
    let noshow = listed.iter().find(|j| j["job"] == "noshow").expect("noshow row");
    assert!(noshow["last_ok_unix"].as_f64().is_some_and(|t| t > 0.0), "the pass above is stamped: {noshow}");
    assert!(listed.iter().all(|j| j["stalled"] == false), "a fresh process has no stalled job: {status}");
    assert!(jobs::stalled(Utc::now().timestamp() as f64).is_empty());
}
