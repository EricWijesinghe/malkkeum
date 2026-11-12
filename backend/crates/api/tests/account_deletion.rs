//! Account deletion completeness and Sign in with Apple compliance over the real router and a migrated
//! database: every table holding customer personal data is checked after deletion, Apple refresh tokens are
//! stored encrypted and removed with the identity, and Apple server-to-server notifications are verified,
//! acted on once, and replay-safe.

mod common;

use api::{build_state, privacy, providers::apple::Notification};
use axum::http::StatusCode;
use common::{app, call, customer, login, seed_catalog, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn social(app: &axum::Router, sub: &str, code: Option<&str>, audience: &str) -> (StatusCode, Value) {
    let mut body = json!({ "provider": "apple", "token": format!("dev:{sub}"), "audience": audience });
    if let Some(c) = code {
        body["authorization_code"] = json!(c);
    }
    call(app, "POST", "/v1/auth/social", None, Some(body)).await
}

async fn count(db: &PgPool, sql: &str, id: Uuid) -> i64 {
    sqlx::query_scalar(sql).bind(id).fetch_one(db).await.unwrap_or_else(|e| panic!("{sql}: {e}"))
}

fn notification(jti: &str, kind: &str, sub: &str) -> Notification {
    Notification {
        jti: jti.into(),
        kind: kind.into(),
        sub: sub.into(),
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn apple_token_is_stored_encrypted_and_deletion_unlinks_so_the_same_apple_id_starts_fresh(pool: PgPool) {
    let app = app(pool.clone());
    let (st, first) = social(&app, "apple-sub-1", Some("dev:code-1"), "customer").await;
    assert_eq!(st, StatusCode::OK, "{first}");
    let user: Uuid = first["subject"].as_str().expect("subject").parse().expect("uuid");
    let enc: String =
        sqlx::query_scalar("SELECT t.refresh_token_enc FROM social_tokens t JOIN user_identities i ON i.id = t.identity_id WHERE i.subject_id = $1")
            .bind(user)
            .fetch_one(&pool)
            .await
            .expect("token stored");
    assert!(!enc.contains("dev-refresh"), "refresh token is encrypted at rest");
    assert!(api::crypto::decrypt(&test_config().data_key, &enc).is_some_and(|t| t.starts_with("dev-refresh-")));

    let token = first["access_token"].as_str().expect("access");
    let (st, body) = call(&app, "DELETE", "/v1/me", Some(token), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert_eq!(
        count(&pool, "SELECT count(*) FROM user_identities WHERE subject_id = $1", user).await,
        0,
        "identities gone"
    );
    assert_eq!(
        count(&pool, "SELECT count(*) FROM social_tokens WHERE $1::uuid IS NOT NULL", user).await,
        0,
        "stored Apple token gone"
    );

    let (st, again) = social(&app, "apple-sub-1", None, "customer").await;
    assert_eq!(st, StatusCode::OK, "{again}");
    assert_eq!(again["is_new"], true, "same Apple id creates a new account");
    assert_ne!(again["subject"], first["subject"]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_deletion_leaves_no_personal_data_in_any_table(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8200-0001").await;
    let (_, referrer) = login(&app, "010-8200-0002", "customer").await;
    let referrer: Uuid = referrer.parse().expect("uuid");
    let phone: String = sqlx::query_scalar("SELECT phone FROM users WHERE id = $1")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("phone");
    let service: String = sqlx::query_scalar("SELECT code FROM services ORDER BY sort_order LIMIT 1")
        .fetch_one(&pool)
        .await
        .expect("service");
    let setup = [
        "UPDATE users SET name = '홍길동', email = 'hong@example.com', ci_hash = 'ci', acquisition = '{\"utm_source\":\"x\"}', referral_code = 'HONG01' WHERE id = $1",
        "INSERT INTO user_identities (provider, provider_user_id, role, subject_id, email) VALUES ('apple', 'apple-del-2', 'customer', $1, 'relay@privaterelay.appleid.com')",
        "INSERT INTO user_identities (provider, provider_user_id, role, subject_id, email) VALUES ('kakao', '424242', 'customer', $1, 'k@example.com')",
        "INSERT INTO social_tokens (identity_id, client_id, refresh_token_enc) SELECT id, 'com.example', 'ENC' FROM user_identities WHERE subject_id = $1 AND provider = 'apple'",
        "INSERT INTO push_tokens (token, owner_role, owner_id, platform) VALUES ('tok-del-2', 'customer', $1, 'ios')",
        "INSERT INTO notifications (owner_role, owner_id, kind, data) VALUES ('customer', $1, 'booking.status', '{}')",
        "INSERT INTO identity_sessions (id, user_id) VALUES ('idv-del-2', $1)",
        "INSERT INTO billing_issues (id, user_id, expires_at) VALUES (gen_random_uuid(), $1, now() + interval '1 hour')",
    ];
    for sql in setup {
        sqlx::query(sql).bind(c.user).execute(&pool).await.unwrap_or_else(|e| panic!("{sql}: {e}"));
    }
    sqlx::query("INSERT INTO referrals (referred_user_id, referrer_id, referred_phone) VALUES ($1, $2, $3)")
        .bind(c.user)
        .bind(referrer)
        .bind(&phone)
        .execute(&pool)
        .await
        .expect("referral");
    let sub: Uuid = sqlx::query_scalar(
        "INSERT INTO subscriptions (user_id, service_code, address_id, payment_method_id, cadence_weeks, weekday, start_hour, anchor_date)
         VALUES ($1, $2, $3, $4, 2, 1, 10, current_date) RETURNING id",
    )
    .bind(c.user)
    .bind(&service)
    .bind(c.address)
    .bind(c.card)
    .fetch_one(&pool)
    .await
    .expect("subscription");
    sqlx::query("INSERT INTO subscription_visits (subscription_id, visit_date, start_hour) VALUES ($1, current_date + 14, 10)")
        .bind(sub)
        .execute(&pool)
        .await
        .expect("visit");
    sqlx::query(
        "INSERT INTO waitlist_entries (user_id, service_code, visit_date, start_hour, end_hour, body)
         VALUES ($1, $2, current_date + 3, 10, 12, '{\"notes\": \"door code 1234\"}')",
    )
    .bind(c.user)
    .bind(&service)
    .execute(&pool)
    .await
    .expect("waitlist");
    sqlx::query(
        "INSERT INTO checkouts (user_id, kind, draft, method, amount, status, virtual_account, expires_at)
         VALUES ($1, 'booking', '{\"notes\": \"x\"}', 'card', 1000, 'failed', '{\"holder\": \"x\"}', now())",
    )
    .bind(c.user)
    .execute(&pool)
    .await
    .expect("checkout");
    let (booking, _) = common::book(&app, &c, 10, None).await;
    sqlx::query("INSERT INTO reviews (booking_id, user_id, rating, body, photos) VALUES ($1, $2, 5, 'great, see you at 101-1203', '[\"x.jpg\"]')")
        .bind(booking)
        .bind(c.user)
        .execute(&pool)
        .await
        .expect("review");
    let upload_dir = test_config().upload_dir;
    std::fs::create_dir_all(&upload_dir).expect("upload dir");
    let file = format!("del-{}.jpg", c.user.simple());
    std::fs::write(upload_dir.join(&file), b"jpg").expect("upload file");
    sqlx::query("INSERT INTO uploads (owner_role, owner_id, file, bytes) VALUES ('customer', $1, $2, 3)")
        .bind(c.user)
        .bind(&file)
        .execute(&pool)
        .await
        .expect("upload row");

    let (st, body) = call(&app, "DELETE", "/v1/me", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");

    let anonymised: bool = sqlx::query_scalar(
        "SELECT name = '' AND email IS NULL AND ci_hash IS NULL AND acquisition IS NULL AND referral_code IS NULL
                AND identity_verified_at IS NULL AND phone LIKE 'deleted:%' AND deleted_at IS NOT NULL FROM users WHERE id = $1",
    )
    .bind(c.user)
    .fetch_one(&pool)
    .await
    .expect("user");
    assert!(anonymised, "user row holds no contact data");
    let gone = [
        (
            "identities (provider ids, emails)",
            "SELECT count(*) FROM user_identities WHERE subject_id = $1",
        ),
        (
            "stored provider tokens",
            "SELECT count(*) FROM social_tokens WHERE refresh_token_enc = 'ENC' AND $1::uuid IS NOT NULL",
        ),
        (
            "addresses with text",
            "SELECT count(*) FROM addresses WHERE user_id = $1 AND (label <> '' OR road_address <> '' OR detail <> '')",
        ),
        (
            "addresses not held by a subscription",
            "SELECT count(*) FROM addresses a WHERE user_id = $1 AND NOT EXISTS (SELECT 1 FROM subscriptions s WHERE s.address_id = a.id)",
        ),
        (
            "card keys and labels",
            "SELECT count(*) FROM payment_methods WHERE user_id = $1 AND (billing_key <> '' OR display_name <> '' OR deleted_at IS NULL)",
        ),
        ("push tokens", "SELECT count(*) FROM push_tokens WHERE owner_id = $1"),
        (
            "notifications",
            "SELECT count(*) FROM notifications WHERE owner_role = 'customer' AND owner_id = $1",
        ),
        ("live sessions", "SELECT count(*) FROM refresh_tokens WHERE subject = $1 AND revoked_at IS NULL"),
        ("identity sessions", "SELECT count(*) FROM identity_sessions WHERE user_id = $1"),
        ("billing tickets", "SELECT count(*) FROM billing_issues WHERE user_id = $1"),
        (
            "raw referral phone",
            "SELECT count(*) FROM referrals WHERE referred_user_id = $1 AND referred_phone NOT LIKE 'hmac:%'",
        ),
        (
            "live subscriptions",
            "SELECT count(*) FROM subscriptions WHERE user_id = $1 AND status <> 'cancelled'",
        ),
        (
            "planned visits",
            "SELECT count(*) FROM subscription_visits v JOIN subscriptions s ON s.id = v.subscription_id WHERE s.user_id = $1 AND v.state = 'planned'",
        ),
        (
            "waitlist places",
            "SELECT count(*) FROM waitlist_entries WHERE user_id = $1 AND status IN ('waiting','offered')",
        ),
        (
            "waitlist snapshots",
            "SELECT count(*) FROM waitlist_entries WHERE user_id = $1 AND body <> '{}'::jsonb",
        ),
        (
            "unpaid checkout snapshots",
            "SELECT count(*) FROM checkouts WHERE user_id = $1 AND status <> 'paid' AND (draft IS NOT NULL OR virtual_account IS NOT NULL)",
        ),
        (
            "review text and photos",
            "SELECT count(*) FROM reviews WHERE user_id = $1 AND (body <> '' OR photos <> '[]'::jsonb)",
        ),
        ("uploads", "SELECT count(*) FROM uploads WHERE owner_role = 'customer' AND owner_id = $1"),
        (
            "chat sender links",
            "SELECT count(*) FROM chat_messages WHERE sender = 'customer' AND sender_id = $1",
        ),
    ];
    for (what, sql) in gone {
        assert_eq!(count(&pool, sql, c.user).await, 0, "{what} left after deletion");
    }
    let codes: i64 = sqlx::query_scalar("SELECT count(*) FROM otp_codes WHERE phone = $1")
        .bind(&phone)
        .fetch_one(&pool)
        .await
        .expect("otp");
    assert_eq!(codes, 0, "login codes for the phone removed");
    assert!(!upload_dir.join(&file).exists(), "uploaded file removed from disk");
    let kept: String = sqlx::query_scalar("SELECT referred_phone FROM referrals WHERE referred_user_id = $1")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("referral kept");
    assert_eq!(
        kept,
        api::crypto::phone_digest(&test_config().data_key, &phone),
        "referral keeps only the keyed digest"
    );
    let plain = sqlx::query_scalar::<_, String>("SELECT encode(sha256(convert_to($1, 'UTF8')), 'hex')")
        .bind(&phone)
        .fetch_one(&pool)
        .await
        .expect("sha");
    assert!(!kept.contains(&plain), "not an unsalted hash of the phone");
    let ratings: i64 = count(&pool, "SELECT count(*) FROM reviews WHERE user_id = $1 AND rating = 5", c.user).await;
    assert_eq!(ratings, 1, "rating kept for the partner score");

    // Deleting twice (a replayed Apple account-delete) changes nothing and does not fail.
    privacy::delete_account(&build_state(pool.clone(), test_config()).expect("state"), c.user)
        .await
        .expect("idempotent");
}

#[sqlx::test(migrations = "../../migrations")]
async fn apple_account_delete_notification_deletes_the_account_once(pool: PgPool) {
    let app = app(pool.clone());
    let state = build_state(pool.clone(), test_config()).expect("state");
    let (st, signed) = social(&app, "apple-sub-3", Some("dev:code-3"), "customer").await;
    assert_eq!(st, StatusCode::OK, "{signed}");
    let user: Uuid = signed["subject"].as_str().expect("subject").parse().expect("uuid");

    privacy::apple_notification(&state, &notification("jti-3", "account-delete", "apple-sub-3"))
        .await
        .expect("handled");
    assert_eq!(
        count(&pool, "SELECT count(*) FROM users WHERE id = $1 AND deleted_at IS NOT NULL", user).await,
        1
    );
    assert_eq!(count(&pool, "SELECT count(*) FROM user_identities WHERE subject_id = $1", user).await, 0);
    assert_eq!(
        count(&pool, "SELECT count(*) FROM refresh_tokens WHERE subject = $1 AND revoked_at IS NULL", user).await,
        0,
        "signed out"
    );

    // A partner signed in with the same Apple ID is handled by the same notification type.
    let (st, partner) = social(&app, "apple-sub-3p", None, "partner").await;
    assert_eq!(st, StatusCode::OK, "{partner}");
    let pro: Uuid = partner["subject"].as_str().expect("subject").parse().expect("uuid");
    privacy::apple_notification(&state, &notification("jti-3p", "account-deleted", "apple-sub-3p"))
        .await
        .expect("partner");
    assert_eq!(count(&pool, "SELECT count(*) FROM pros WHERE id = $1 AND deleted_at IS NOT NULL", pro).await, 1);
    assert_eq!(count(&pool, "SELECT count(*) FROM user_identities WHERE subject_id = $1", pro).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn consent_revoked_ends_sessions_keeps_the_link_and_a_replay_is_skipped(pool: PgPool) {
    let app = app(pool.clone());
    let state = build_state(pool.clone(), test_config()).expect("state");
    let (_, signed) = social(&app, "apple-sub-4", Some("dev:code-4"), "customer").await;
    let user: Uuid = signed["subject"].as_str().expect("subject").parse().expect("uuid");
    let event = notification("jti-4", "consent-revoked", "apple-sub-4");

    privacy::apple_notification(&state, &event).await.expect("handled");
    assert_eq!(
        count(&pool, "SELECT count(*) FROM refresh_tokens WHERE subject = $1 AND revoked_at IS NULL", user).await,
        0,
        "signed out"
    );
    assert_eq!(
        count(&pool, "SELECT count(*) FROM user_identities WHERE subject_id = $1", user).await,
        1,
        "link kept"
    );
    assert_eq!(
        count(
            &pool,
            "SELECT count(*) FROM social_tokens t JOIN user_identities i ON i.id = t.identity_id WHERE i.subject_id = $1",
            user
        )
        .await,
        0
    );
    assert_eq!(
        count(&pool, "SELECT count(*) FROM users WHERE id = $1 AND deleted_at IS NULL", user).await,
        1,
        "account kept"
    );

    // Signing in again works (same account) and stores a new token; the replayed notification must not drop it.
    let (_, again) = social(&app, "apple-sub-4", Some("dev:code-4b"), "customer").await;
    assert_eq!(again["subject"], signed["subject"]);
    privacy::apple_notification(&state, &event).await.expect("replay acknowledged");
    assert_eq!(
        count(&pool, "SELECT count(*) FROM refresh_tokens WHERE subject = $1 AND revoked_at IS NULL", user).await,
        1,
        "replay did not sign out"
    );
    assert_eq!(
        count(
            &pool,
            "SELECT count(*) FROM social_tokens t JOIN user_identities i ON i.id = t.identity_id WHERE i.subject_id = $1",
            user
        )
        .await,
        1
    );
    let seen: i64 = sqlx::query_scalar("SELECT count(*) FROM apple_notifications WHERE jti = 'jti-4'")
        .fetch_one(&pool)
        .await
        .expect("seen");
    assert_eq!(seen, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn notification_endpoint_rejects_unsigned_or_malformed_payloads(pool: PgPool) {
    let app = app(pool);
    let unsigned = format!("{}.{}.", "eyJhbGciOiJub25lIn0", "eyJzdWIiOiJ4In0");
    for payload in ["garbage", "a.b.c", unsigned.as_str()] {
        let (st, body) = call(&app, "POST", "/v1/auth/apple/notifications", None, Some(json!({ "payload": payload }))).await;
        assert_eq!(st, StatusCode::UNAUTHORIZED, "{payload}: {body}");
    }
    let (st, _) = call(&app, "POST", "/v1/auth/apple/notifications", None, Some(json!({}))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "no payload");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_deleted_friends_phone_still_counts_for_one_referral_reward(pool: PgPool) {
    seed_catalog(&pool).await;
    sqlx::query(
        "INSERT INTO settings (key, value) VALUES ('referral_offer', '{\"enabled\": true, \"amount\": 3000}')
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
    )
    .execute(&pool)
    .await
    .expect("setting");
    let app = app(pool.clone());
    let referrer = customer(&app, &pool, "010-8200-0101").await;
    let (_, mine) = call(&app, "GET", "/v1/me/referral", Some(referrer.token.as_str()), None).await;
    let code = mine["code"].as_str().expect("code").to_string();
    let (friend, _) = login(&app, "010-8200-0102", "customer").await;
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(friend.as_str()), Some(json!({ "code": code }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "DELETE", "/v1/me", Some(friend.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    let (again, _) = login(&app, "010-8200-0102", "customer").await;
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(again.as_str()), Some(json!({ "code": code }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("already_referred")), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn apple_account_delete_for_a_busy_partner_waits_then_completes(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let state = build_state(pool.clone(), test_config()).expect("state");
    let (st, partner) = social(&app, "apple-sub-5p", None, "partner").await;
    assert_eq!(st, StatusCode::OK, "{partner}");
    let pro: Uuid = partner["subject"].as_str().expect("subject").parse().expect("uuid");
    let c = customer(&app, &pool, "010-8200-0201").await;
    let (booking, _) = common::book(&app, &c, 10, None).await;
    sqlx::query("UPDATE bookings SET pro_id = $2, status = 2 WHERE id = $1")
        .bind(booking)
        .bind(pro)
        .execute(&pool)
        .await
        .expect("assign");

    privacy::apple_notification(&state, &notification("jti-5", "account-delete", "apple-sub-5p"))
        .await
        .expect("handled");
    let marked = "SELECT count(*) FROM pros WHERE id = $1 AND deleted_at IS NULL AND deletion_requested_at IS NOT NULL";
    assert_eq!(count(&pool, marked, pro).await, 1, "marked, not deleted");
    assert_eq!(privacy::finish_pending_partner_deletions(&state).await.expect("retry"), 0, "still busy");

    sqlx::query("UPDATE bookings SET status = 3 WHERE id = $1")
        .bind(booking)
        .execute(&pool)
        .await
        .expect("done");
    assert_eq!(privacy::finish_pending_partner_deletions(&state).await.expect("retry"), 1);
    assert_eq!(count(&pool, "SELECT count(*) FROM pros WHERE id = $1 AND deleted_at IS NOT NULL", pro).await, 1);
    assert_eq!(count(&pool, "SELECT count(*) FROM user_identities WHERE subject_id = $1", pro).await, 0);
    let (st, again) = social(&app, "apple-sub-5p", None, "partner").await;
    assert_eq!(st, StatusCode::OK, "{again}");
    assert_ne!(again["subject"], partner["subject"], "same Apple id signs up fresh");
}
