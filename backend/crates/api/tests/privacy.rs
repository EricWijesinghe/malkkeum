//! PIPA customer rights over the real router and a migrated database: consent records and re-consent,
//! marketing withdrawal gating sends, the data export, the account deletion cascade, the retention
//! purge, and the staff access record for customer contact details.

mod common;

use api::{
    auth::{self, Role},
    build_state,
    privacy::{self, CONSENT_VERSION},
    realtime::Recipient,
    retention,
};
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{SECRET, app, book, call, customer, seed_catalog, test_config};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

fn all_required_consents() -> serde_json::Value {
    json!([
        { "kind": "terms", "granted": true, "version": CONSENT_VERSION },
        { "kind": "privacy", "granted": true, "version": CONSENT_VERSION },
        { "kind": "overseas_transfer", "granted": true, "version": CONSENT_VERSION }
    ])
}

#[sqlx::test(migrations = "../../migrations")]
async fn required_consents_gate_the_service_and_marketing_is_withdrawable(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8100-0001").await;

    let (st, s) = call(&app, "GET", "/v1/me/consents", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(s["reconsent_required"], true, "new account has no consents yet");
    assert_eq!(s["items"].as_array().map(Vec::len), Some(4));

    let (st, body) = call(&app, "PUT", "/v1/me/consents", Some(c.token.as_str()), Some(json!({ "consents": [{ "kind": "marketing", "granted": true, "version": CONSENT_VERSION }] }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "required consents missing: {body}");
    assert_eq!(body["error"]["code"], "required_consent");

    let (st, body) = call(&app, "PUT", "/v1/me/consents", Some(c.token.as_str()), Some(json!({ "consents": [{ "kind": "terms", "granted": true, "version": "2020-01-01" }] }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "stale policy version: {body}");
    assert_eq!(body["error"]["code"], "stale_consent_version");

    let (st, body) = call(&app, "PUT", "/v1/me/consents", Some(c.token.as_str()), Some(json!({ "consents": all_required_consents() }))).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert_eq!(body["reconsent_required"], false);

    let (st, body) = call(
        &app,
        "PUT",
        "/v1/me/consents",
        Some(c.token.as_str()),
        Some(json!({ "consents": [{ "kind": "marketing", "granted": true, "version": CONSENT_VERSION }] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert!(privacy::marketing_allowed(&pool, c.user).await.expect("query"));

    let (st, _) = call(
        &app,
        "PUT",
        "/v1/me/consents",
        Some(c.token.as_str()),
        Some(json!({ "consents": [{ "kind": "marketing", "granted": false, "version": CONSENT_VERSION }] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    assert!(!privacy::marketing_allowed(&pool, c.user).await.expect("query"), "withdrawal stops marketing");

    let rows: i64 = sqlx::query_scalar("SELECT count(*) FROM user_consents WHERE user_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(rows, 5, "every choice is kept as evidence (3 required + grant + withdrawal)");
}

#[sqlx::test(migrations = "../../migrations")]
async fn marketing_message_is_dropped_without_consent_and_transactional_still_sent(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8100-0002").await;
    let state = build_state(pool.clone(), test_config()).expect("state");

    api::realtime::notify(&state, Recipient::User(c.user), "marketing.autumn", "t", "b", json!({})).await.expect("notify");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM notifications WHERE owner_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(n, 0, "no marketing without consent");

    privacy::update_consents(&pool, c.user, serde_json::from_value(json!({ "consents": all_required_consents() })).expect("body"))
        .await
        .expect("required");
    privacy::update_consents(&pool, c.user, serde_json::from_value(json!({ "consents": [{ "kind": "marketing", "granted": true, "version": CONSENT_VERSION }] })).expect("body"))
        .await
        .expect("grant");
    api::realtime::notify(&state, Recipient::User(c.user), "marketing.autumn", "t", "b", json!({})).await.expect("notify");
    api::realtime::notify(&state, Recipient::User(c.user), "booking.status", "t", "b", json!({})).await.expect("notify");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM notifications WHERE owner_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(n, 2, "consented marketing and a transactional message are both stored");
}

#[sqlx::test(migrations = "../../migrations")]
async fn export_contains_the_customers_data_but_no_gateway_keys(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8100-0003").await;
    let (st, doc) = call(&app, "GET", "/v1/me/export", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert!(doc["profile"]["phone"].is_string(), "profile phone exported");
    assert_eq!(doc["addresses"].as_array().map(Vec::len), Some(1));
    assert_eq!(doc["payment_methods"][0]["display_name"], "test card");
    assert!(!doc.to_string().contains("bk_test_"), "billing keys never leave the server");
}

#[sqlx::test(migrations = "../../migrations")]
async fn deletion_anonymises_and_removes_devices_but_keeps_records(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8100-0004").await;
    let (booking, _) = book(&app, &c, 10, None).await;
    privacy::update_consents(&pool, c.user, serde_json::from_value(json!({ "consents": all_required_consents() })).expect("body"))
        .await
        .expect("consent");
    sqlx::query("INSERT INTO push_tokens (token, owner_role, owner_id, platform) VALUES ('tok-del-1', 'customer', $1, 'android')")
        .bind(c.user)
        .execute(&pool)
        .await
        .expect("push");

    let (st, body) = call(&app, "DELETE", "/v1/me", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");

    let (phone, name): (String, String) = sqlx::query_as("SELECT phone, name FROM users WHERE id = $1").bind(c.user).fetch_one(&pool).await.expect("user");
    assert!(phone.starts_with("deleted:") && name.is_empty());
    let addresses: i64 = sqlx::query_scalar("SELECT count(*) FROM addresses WHERE user_id = $1").bind(c.user).fetch_one(&pool).await.expect("addr");
    assert_eq!(addresses, 0, "addresses removed");
    let key: String = sqlx::query_scalar("SELECT billing_key FROM payment_methods WHERE id = $1").bind(c.card).fetch_one(&pool).await.expect("card");
    assert!(key.is_empty(), "saved card key cleared");
    let tokens: i64 = sqlx::query_scalar("SELECT count(*) FROM push_tokens WHERE owner_id = $1").bind(c.user).fetch_one(&pool).await.expect("push");
    assert_eq!(tokens, 0, "push tokens removed");
    let kept: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE id = $1").bind(booking).fetch_one(&pool).await.expect("booking");
    assert_eq!(kept, 1, "bookings kept for the 5-year record rule");
    let consents: i64 = sqlx::query_scalar("SELECT count(*) FROM user_consents WHERE user_id = $1").bind(c.user).fetch_one(&pool).await.expect("consent");
    assert_eq!(consents, 3, "consent evidence kept");
}

#[sqlx::test(migrations = "../../migrations")]
async fn retention_purge_removes_expired_rows_and_unreferenced_uploads(pool: PgPool) {
    let cfg = test_config();
    let user: Uuid = sqlx::query_scalar("INSERT INTO users (phone) VALUES ('01081000005') RETURNING id").fetch_one(&pool).await.expect("user");
    sqlx::query("INSERT INTO otp_codes (phone, code_hash, expires_at, created_at) VALUES ('01081000005', 'h', now(), now() - interval '2 days')")
        .execute(&pool)
        .await
        .expect("old otp");
    sqlx::query("INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES ('01081000005', 'h', now())").execute(&pool).await.expect("new otp");
    sqlx::query("INSERT INTO refresh_tokens (token_hash, subject, role, family_id, expires_at) VALUES ('rt-expired', $1, 'customer', gen_random_uuid(), now() - interval '1 day')")
        .bind(user)
        .execute(&pool)
        .await
        .expect("rt");

    let old = Utc::now() - Duration::days(60);
    let orphan = "0123456789abcdef0123456789abcdef.jpg";
    let kept = "fedcba9876543210fedcba9876543210.jpg";
    for file in [orphan, kept] {
        sqlx::query("INSERT INTO uploads (owner_role, owner_id, file, bytes, created_at) VALUES ('customer', $1, $2, 10, $3)")
            .bind(user)
            .bind(file)
            .bind(old)
            .execute(&pool)
            .await
            .expect("upload");
    }
    sqlx::query("UPDATE users SET name = $2 WHERE id = $1").bind(user).bind(format!("/files/{kept}")).execute(&pool).await.expect("ref");

    let report = retention::purge(&pool, &cfg).await.expect("purge");
    assert_eq!(report.otp_codes, 1, "only the 2-day-old code");
    assert_eq!(report.refresh_tokens, 1);
    assert_eq!(report.uploads, 1, "only the unreferenced upload");
    let left: Vec<String> = sqlx::query_scalar("SELECT file FROM uploads").fetch_all(&pool).await.expect("left");
    assert_eq!(left, vec![kept.to_string()]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn staff_reads_of_customer_contacts_are_audit_logged(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8100-0006").await;
    let (booking, _) = book(&app, &c, 10, None).await;
    let hash = auth::hash_password("staff-pass-123").expect("hash");
    let staff: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ('pii@test.local', 'Staff', $1, 'admin') RETURNING id")
        .bind(hash)
        .fetch_one(&pool)
        .await
        .expect("staff");
    let token = auth::issue_access(SECRET, staff, Role::StaffAdmin).expect("token");

    let (st, _) = call(&app, "GET", &format!("/v1/admin/bookings/{booking}"), Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "GET", "/v1/admin/customers", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let logged: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE actor_id = $1 AND action LIKE 'customer.pii_%'").bind(staff).fetch_one(&pool).await.expect("audit");
    assert_eq!(logged, 2, "both contact views recorded");
}

#[sqlx::test(migrations = "../../migrations")]
async fn partner_export_omits_account_number_and_delete_clears_notifications(pool: PgPool) {
    let app = app(pool.clone());
    let (token, pro) = common::verified_pro(&app, &pool, "010-8100-0007").await;
    sqlx::query("INSERT INTO payout_accounts (pro_id, bank, account_enc, account_last4, holder) VALUES ($1, '신한', 'SECRET-CIPHER-TEXT', '1234', '홍길동')")
        .bind(pro)
        .execute(&pool)
        .await
        .expect("payout account");
    sqlx::query("INSERT INTO notifications (owner_role, owner_id, kind, data) VALUES ('pro', $1, 'booking.status', '{}')")
        .bind(pro)
        .execute(&pool)
        .await
        .expect("notification");

    let (st, doc) = call(&app, "GET", "/v1/partner/export", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{doc}");
    assert_eq!(doc["payout_account"]["account_last4"], "1234");
    assert!(!doc.to_string().contains("SECRET-CIPHER-TEXT"), "encrypted account number never leaves the server");

    let (st, body) = call(&app, "DELETE", "/v1/partner/me", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let left: i64 = sqlx::query_scalar("SELECT count(*) FROM notifications WHERE owner_id = $1").bind(pro).fetch_one(&pool).await.expect("count");
    assert_eq!(left, 0, "partner notifications removed");
}
