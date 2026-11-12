//! Launch safety: encrypted entry codes, check-in/out, cases, no-show and reassignment, AI handoff
//! cases. Same DB and fakes as the other flow tests.

mod common;

use api::auth::{self, Role};
use axum::{Router, http::StatusCode};
use common::{PHOTO, SECRET, book, call, customer, register_photo, seed_catalog, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn token(role: Role) -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), role).expect("token")
}

/// A staff row (notes and assignees reference `staff`) plus a token for it.
async fn staff(pool: &PgPool, role: Role) -> String {
    let id = Uuid::now_v7();
    let db_role = if role == Role::StaffAdmin { "admin" } else { "consultant" };
    sqlx::query("INSERT INTO staff (id, email, name, password_hash, role) VALUES ($1, $2, 'tester', 'x', $3)")
        .bind(id)
        .bind(format!("{id}@test.local"))
        .bind(db_role)
        .execute(pool)
        .await
        .expect("staff row");
    auth::issue_access(SECRET, id, role).expect("token")
}

async fn accept_today(app: &Router, pool: &PgPool, id: Uuid, pro: &str) {
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1").bind(id).execute(pool).await.expect("today");
}

async fn complete_today(app: &Router, pool: &PgPool, id: Uuid, pro: &str) {
    accept_today(app, pool, id, pro).await;
    let pro_id: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(id).fetch_one(pool).await.expect("pro");
    register_photo(pool, pro_id).await;
    let done = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/complete"), Some(pro), Some(done)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

async fn audit_count(pool: &PgPool, action: &str) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = $1").bind(action).fetch_one(pool).await.expect("audit")
}

#[sqlx::test(migrations = "../../migrations")]
async fn entry_code_is_encrypted_and_revealed_only_to_the_assigned_partner_on_the_visit_day(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0001").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0101").await;
    let (other, _) = verified_pro(&app, &pool, "010-5400-0102").await;
    let (id, _) = book(&app, &c, 10, None).await;

    let (st, b) = call(&app, "PUT", &format!("/v1/bookings/{id}/notes"), Some(c.token.as_str()), Some(json!({ "entry": "1234#", "parking": "B1" }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["entry_code_set"], true);
    assert!(b["visit_notes"].get("entry").is_none(), "code is not in visit_notes");
    let (notes, enc): (String, Option<String>) = sqlx::query_as("SELECT visit_notes::text, access_code_enc FROM bookings WHERE id = $1").bind(id).fetch_one(&pool).await.expect("row");
    assert!(!notes.contains("1234#") && enc.as_deref().is_some_and(|e| !e.contains("1234#")), "stored encrypted only");

    let (st, detail) = call(&app, "GET", &format!("/v1/bookings/{id}"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let numbers: Vec<&str> = detail["emergency"].as_array().expect("emergency").iter().filter_map(|e| e["number"].as_str()).collect();
    assert!(numbers.contains(&"112") && numbers.contains(&"119"), "{detail}");

    accept_today(&app, &pool, id, pro.as_str()).await;
    sqlx::query("UPDATE bookings SET visit_date = visit_date + 1 WHERE id = $1").bind(id).execute(&pool).await.expect("tomorrow");
    let (st, b) = call(&app, "GET", &format!("/v1/partner/jobs/{id}/entry-code"), Some(pro.as_str()), None).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("entry_code_not_today")), "{b}");
    sqlx::query("UPDATE bookings SET visit_date = visit_date - 1 WHERE id = $1").bind(id).execute(&pool).await.expect("today");

    let (st, _) = call(&app, "GET", &format!("/v1/partner/jobs/{id}/entry-code"), Some(other.as_str()), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "unassigned partner");
    let (st, b) = call(&app, "GET", &format!("/v1/partner/jobs/{id}/entry-code"), Some(pro.as_str()), None).await;
    assert_eq!((st, b["entry_code"].as_str()), (StatusCode::OK, Some("1234#")), "{b}");
    assert_eq!(audit_count(&pool, "entry_code.reveal").await, 1, "reveal is audited");

    let (st, b) = call(&app, "GET", &format!("/v1/admin/bookings/{id}/entry-code"), Some(staff(&pool, Role::StaffConsultant).await.as_str()), None).await;
    assert_eq!((st, b["entry_code"].as_str()), (StatusCode::OK, Some("1234#")), "{b}");
    assert_eq!(audit_count(&pool, "entry_code.reveal").await, 2, "staff reveal is audited too");
}

#[sqlx::test(migrations = "../../migrations")]
async fn legacy_plaintext_codes_are_encrypted_and_purged_a_day_after_completion(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0002").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0103").await;
    let (id, _) = book(&app, &c, 10, None).await;
    sqlx::query("UPDATE bookings SET visit_notes = '{\"entry\":\"9999\",\"parking\":\"P1\"}' WHERE id = $1").bind(id).execute(&pool).await.expect("legacy");

    let cfg = common::test_config();
    assert_eq!(api::safety::encrypt_legacy_codes(&pool, &cfg.data_key).await.expect("backfill"), 1);
    let (notes, enc): (Value, Option<String>) = sqlx::query_as("SELECT visit_notes, access_code_enc FROM bookings WHERE id = $1").bind(id).fetch_one(&pool).await.expect("row");
    assert_eq!(notes, json!({ "parking": "P1" }));
    assert_eq!(api::crypto::decrypt(&cfg.data_key, &enc.expect("enc")).as_deref(), Some("9999"));

    complete_today(&app, &pool, id, pro.as_str()).await;
    let report = api::retention::purge(&pool, &cfg).await.expect("purge");
    assert_eq!(report.entry_codes, 0, "still inside the 24h window");
    sqlx::query("UPDATE bookings SET completed_at = now() - interval '25 hours' WHERE id = $1").bind(id).execute(&pool).await.expect("age");
    let report = api::retention::purge(&pool, &cfg).await.expect("purge");
    assert_eq!(report.entry_codes, 1);
    let enc: Option<String> = sqlx::query_scalar("SELECT access_code_enc FROM bookings WHERE id = $1").bind(id).fetch_one(&pool).await.expect("row");
    assert!(enc.is_none(), "erased after completion + 24h");
}

#[sqlx::test(migrations = "../../migrations")]
async fn check_in_and_out_are_visit_day_only_and_visible_to_staff(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0003").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0104").await;
    let (id, _) = book(&app, &c, 10, None).await;
    accept_today(&app, &pool, id, pro.as_str()).await;
    sqlx::query("UPDATE bookings SET visit_date = visit_date + 1 WHERE id = $1").bind(id).execute(&pool).await.expect("tomorrow");

    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/check-in"), Some(pro.as_str()), None).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("not_visit_day")), "{b}");
    sqlx::query("UPDATE bookings SET visit_date = visit_date - 1 WHERE id = $1").bind(id).execute(&pool).await.expect("today");

    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/check-out"), Some(pro.as_str()), None).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("not_checked_in")), "{b}");
    let (st, _) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/check-in"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/check-out"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);

    let (st, b) = call(&app, "GET", &format!("/v1/admin/bookings/{id}"), Some(staff(&pool, Role::StaffConsultant).await.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(b["booking"]["checked_in_at"].is_string() && b["booking"]["checked_out_at"].is_string(), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cases_file_by_role_with_photo_ownership_and_a_guarded_workflow(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0004").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0105").await;
    let (other, _) = verified_pro(&app, &pool, "010-5400-0106").await;
    let (id, _) = book(&app, &c, 10, None).await;
    let damage = json!({ "kind": "damage", "summary": "벽에 흠집", "photos": [] });

    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id}/cases"), Some(c.token.as_str()), Some(damage.clone())).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("booking_closed")), "not yet assigned: {b}");
    accept_today(&app, &pool, id, pro.as_str()).await;

    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{id}/cases"), Some(c.token.as_str()), Some(json!({ "kind": "rude", "summary": "x" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "unknown kind");
    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{id}/cases"), Some(c.token.as_str()), Some(json!({ "kind": "damage", "summary": "x", "photos": [PHOTO] }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a photo the customer did not upload");
    let (st, _) = call(&app, "POST", &format!("/v1/jobs/{id}/cases"), Some(pro.as_str()), Some(json!({ "kind": "damage", "summary": "x" }))).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "wrong route prefix must not match");
    let (st, _) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/cases"), Some(pro.as_str()), Some(json!({ "kind": "no_show", "summary": "x" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "partners cannot raise no-shows");
    let (st, _) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/cases"), Some(other.as_str()), Some(json!({ "kind": "damage", "summary": "x" }))).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "not the assigned partner");

    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id}/cases"), Some(c.token.as_str()), Some(damage)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let case = b["id"].as_str().expect("case id").to_string();
    register_photo(&pool, pro_id(&pool, id).await).await;
    let (st, _) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/cases"), Some(pro.as_str()), Some(json!({ "kind": "safety", "summary": "문 잠김", "photos": [PHOTO] }))).await;
    assert_eq!(st, StatusCode::OK);

    let consultant = staff(&pool, Role::StaffConsultant).await;
    let (st, list) = call(&app, "GET", "/v1/admin/cases?status=open", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(list.as_array().map(Vec::len), Some(2), "{list}");
    assert_eq!(list[0]["overdue"], false);

    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(consultant.as_str()), Some(json!({ "status": "resolved" }))).await;
    assert_eq!(st, StatusCode::CONFLICT, "open cannot jump to resolved");
    let (st, b) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(consultant.as_str()), Some(json!({ "status": "investigating", "note": "기사 확인 중" }))).await;
    assert_eq!((st, b["case"]["status"].as_str()), (StatusCode::OK, Some("investigating")), "{b}");
    assert_eq!(b["notes"][0]["body"], "기사 확인 중");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(consultant.as_str()), Some(json!({ "status": "resolved" }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(consultant.as_str()), Some(json!({ "status": "investigating" }))).await;
    assert_eq!(st, StatusCode::CONFLICT, "resolved is final");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(consultant.as_str()), Some(json!({ "refund_amount": 1000 }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultants cannot refund");
    assert_eq!(audit_count(&pool, "case.open").await, 2);
}

#[sqlx::test(migrations = "../../migrations")]
async fn refunds_and_settlement_holds_are_admin_only_and_run_once(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0005").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0107").await;
    let (id, _) = book(&app, &c, 10, None).await;
    complete_today(&app, &pool, id, pro.as_str()).await;
    let case = call(&app, "POST", &format!("/v1/bookings/{id}/cases"), Some(c.token.as_str()), Some(json!({ "kind": "payment_dispute", "summary": "요금 이의" }))).await.1["id"]
        .as_str()
        .expect("case")
        .to_string();
    let admin = token(Role::StaffAdmin);
    // A newer tip payment on the same booking: a case refund must never take it back from the partner.
    let tip: Uuid = sqlx::query_scalar(
        "INSERT INTO payments (booking_id, amount, kind, status, provider, provider_tx_id, idempotency_key, created_at)
         VALUES ($1, 5000, 'tip', 'paid', 'fake', 'tip-tx', 'tip-key', now() + interval '1 minute') RETURNING id",
    )
    .bind(id)
    .fetch_one(&pool)
    .await
    .expect("tip payment");

    let (st, b) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(admin.as_str()), Some(json!({ "refund_amount": 1000 }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["case"]["outcome"]["refund"]["refunded"], 1000);
    let tip_refunded: i64 = sqlx::query_scalar("SELECT refunded_amount FROM payments WHERE id = $1").bind(tip).fetch_one(&pool).await.expect("tip row");
    assert_eq!(tip_refunded, 0, "refund_all leaves tips alone");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(admin.as_str()), Some(json!({ "refund_amount": 1000 }))).await;
    assert_eq!(st, StatusCode::CONFLICT, "a case refunds once");

    let (st, b) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(admin.as_str()), Some(json!({ "hold_settlement": true }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let state: String = sqlx::query_scalar("SELECT state FROM settlements WHERE booking_id = $1").bind(id).fetch_one(&pool).await.expect("settlement");
    assert_eq!(state, "held");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/cases/{case}"), Some(admin.as_str()), Some(json!({ "hold_settlement": false }))).await;
    assert_eq!(st, StatusCode::OK);
    let state: String = sqlx::query_scalar("SELECT state FROM settlements WHERE booking_id = $1").bind(id).fetch_one(&pool).await.expect("settlement");
    assert_eq!(state, "pending", "released");
}

#[sqlx::test(migrations = "../../migrations")]
async fn missed_check_in_opens_one_no_show_case_and_reassigns_to_a_matching_partner(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0006").await;
    let (late, _) = verified_pro(&app, &pool, "010-5400-0108").await;
    let (_, backup_id) = verified_pro(&app, &pool, "010-5400-0109").await;
    let (id, _) = book(&app, &c, 10, None).await;
    accept_today(&app, &pool, id, late.as_str()).await;
    // Visit today from midnight KST: the 30-minute grace has already passed.
    sqlx::query("UPDATE bookings SET start_hour = 0 WHERE id = $1").bind(id).execute(&pool).await.expect("window");

    let s = api::build_state(pool.clone(), common::test_config()).expect("state");
    assert_eq!(api::noshow::scan(&s).await.expect("scan"), 1);
    assert_eq!(api::noshow::scan(&s).await.expect("scan"), 0, "one case per job");
    let consultant = staff(&pool, Role::StaffConsultant).await;
    let (_, list) = call(&app, "GET", "/v1/admin/cases?status=open", Some(consultant.as_str()), None).await;
    assert_eq!((list[0]["kind"].as_str(), list[0]["source"].as_str()), (Some("no_show"), Some("no_show")), "{list}");
    let case = list[0]["id"].as_str().expect("case").to_string();

    // The apology coupon is admin-only and refused before anything moves.
    let (st, _) = call(&app, "POST", &format!("/v1/admin/cases/{case}/reassign"), Some(consultant.as_str()), Some(json!({ "coupon_amount": 5000 }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "apology coupon is admin-only");

    // The first real move goes to the matching backup (the late pro is excluded as the current one).
    let admin = token(Role::StaffAdmin);
    let (st, b) = call(&app, "POST", &format!("/v1/admin/cases/{case}/reassign"), Some(admin.as_str()), Some(json!({ "coupon_amount": 5000 }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["case"]["outcome"]["reassigned_to"], backup_id.to_string());
    assert_eq!(b["case"]["status"], "investigating");
    let pro_now: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(id).fetch_one(&pool).await.expect("pro");
    assert_eq!(pro_now, backup_id);

    // Staff may reassign without a coupon; the current pro (backup) is excluded, so the job moves on.
    let (st, _) = call(&app, "POST", &format!("/v1/admin/cases/{case}/reassign"), Some(consultant.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::OK, "staff can reassign");
    let pro_after: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(id).fetch_one(&pool).await.expect("pro");
    assert_ne!(pro_after, backup_id, "reassign never returns the job to its current pro");
    let coupons: i64 = sqlx::query_scalar("SELECT count(*) FROM coupons WHERE campaign = 'no_show_apology' AND amount = 5000").fetch_one(&pool).await.expect("coupons");
    assert_eq!(coupons, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn ai_handoff_on_a_job_opens_one_complaint_case(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0007").await;
    let (id, _) = book(&app, &c, 10, None).await;
    api::routes::cases::open_from_ai(&pool, Some(id), Some(c.user), Uuid::now_v7()).await.expect("first handoff");
    api::routes::cases::open_from_ai(&pool, Some(id), Some(c.user), Uuid::now_v7()).await.expect("second handoff");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM cases WHERE booking_id = $1 AND source = 'ai' AND kind = 'complaint'").bind(id).fetch_one(&pool).await.expect("count");
    assert_eq!(n, 1, "one open AI case per job");
    api::routes::cases::open_from_ai(&pool, None, None, Uuid::now_v7()).await.expect("no job, no case");
}

async fn pro_id(pool: &PgPool, booking: Uuid) -> Uuid {
    sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(booking).fetch_one(pool).await.expect("pro")
}
