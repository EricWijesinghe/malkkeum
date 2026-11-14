//! Owner-queued host jobs over the real router and a migrated database: owner TOTP and admin role on owner kinds,
//! one job file per accepted request (double clicks included), refused arguments write nothing, and status
//! files come back as capped, known states only. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{crypto, routes, totp};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use chrono::Utc;
use common::{staff_token, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{net::SocketAddr, path::PathBuf};
use tower::ServiceExt;
use uuid::Uuid;

const TOTP_SEED: &[u8] = b"12345678901234567890";
const KEY: &str = "0f6c2d9e-7a51-4c3b-9d2e-5b8a1c4e7f10";

/// A router whose agent folder is a fresh temp dir with `inbox/` and `status/`.
struct Host {
    app: Router,
    dir: PathBuf,
}

fn host(db: PgPool) -> Host {
    let dir = std::env::temp_dir().join(format!("dahae-host-jobs-{}", Uuid::now_v7().simple()));
    std::fs::create_dir_all(dir.join("inbox")).expect("inbox");
    std::fs::create_dir_all(dir.join("status")).expect("status");
    let mut cfg = test_config();
    cfg.host_jobs_dir = dir.clone();
    let state = api::build_state(db, cfg).expect("state");
    Host {
        app: routes::router(state),
        dir,
    }
}

fn job_files(dir: &PathBuf) -> Vec<PathBuf> {
    std::fs::read_dir(dir.join("inbox"))
        .expect("inbox listing")
        .map(|e| e.expect("entry").path())
        .collect()
}

/// One request with an optional `X-Owner-Totp` and `Idempotency-Key`, through the router.
async fn send(app: &Router, method: &str, uri: &str, token: &str, totp: Option<&str>, key: Option<&str>, body: Option<Value>) -> (StatusCode, Value) {
    let mut req = Request::builder()
        .method(method)
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"));
    if let Some(code) = totp {
        req = req.header("x-owner-totp", code);
    }
    if let Some(k) = key {
        req = req.header("idempotency-key", k);
    }
    let payload = match body {
        Some(v) => {
            req = req.header(header::CONTENT_TYPE, "application/json");
            Body::from(v.to_string())
        }
        None => Body::empty(),
    };
    let mut request = req.body(payload).expect("valid request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

/// Admin with an enrolled TOTP secret. Returns the access token.
async fn enrolled_admin(db: &PgPool) -> String {
    let (token, id) = staff_token(db, api::auth::Role::StaffAdmin).await;
    let enc = crypto::encrypt(&test_config().data_key, &totp::encode_secret(TOTP_SEED));
    sqlx::query("UPDATE staff SET totp_secret = $2, totp_enabled_at = now() WHERE id = $1")
        .bind(id)
        .bind(enc)
        .execute(db)
        .await
        .expect("enrol totp");
    token
}

fn code_now() -> String {
    let step = Utc::now().timestamp().div_euclid(totp::STEP_SECS);
    format!("{:06}", totp::code_at(TOTP_SEED, step as u64))
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_kinds_need_an_admin_and_a_totp_code(db: PgPool) {
    let h = host(db.clone());
    let admin = enrolled_admin(&db).await;
    let (consultant, _) = staff_token(&db, api::auth::Role::StaffConsultant).await;
    let body = Some(json!({ "kind": "backup-now" }));

    let (st, _) = send(&h.app, "POST", "/v1/admin/host/jobs", &consultant, Some(&code_now()), Some(KEY), body.clone()).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant");
    let (st, _) = send(&h.app, "POST", "/v1/admin/host/jobs", &admin, None, Some(KEY), body.clone()).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "owner kind without TOTP");
    let (st, _) = send(&h.app, "POST", "/v1/admin/host/jobs", &admin, Some("000000"), Some(KEY), body).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "wrong TOTP");
    assert!(job_files(&h.dir).is_empty(), "refused requests write nothing");
}

#[sqlx::test(migrations = "../../migrations")]
async fn accepted_job_writes_one_file_and_a_double_click_queues_once(db: PgPool) {
    let h = host(db.clone());
    let admin = enrolled_admin(&db).await;
    let body = Some(json!({ "kind": "channel", "arg": "beta" }));

    let (st, first) = send(&h.app, "POST", "/v1/admin/host/jobs", &admin, Some(&code_now()), Some(KEY), body.clone()).await;
    assert_eq!(st, StatusCode::ACCEPTED, "{first}");
    let (st, second) = send(&h.app, "POST", "/v1/admin/host/jobs", &admin, Some(&code_now()), Some(KEY), body).await;
    assert_eq!(st, StatusCode::ACCEPTED);
    assert_eq!(first["id"], second["id"], "same key replays the same job");

    let files = job_files(&h.dir);
    assert_eq!(files.len(), 1, "one job file");
    let id = first["id"].as_str().expect("id");
    assert_eq!(files[0].file_name().and_then(|n| n.to_str()), Some(format!("{id}.job").as_str()));
    let text = std::fs::read_to_string(&files[0]).expect("job file");
    assert!(text.starts_with(&format!("id={id}\nkind=channel\narg=beta\ntoken=")), "{text}");
    assert_eq!(first["state"], "queued");
}

#[sqlx::test(migrations = "../../migrations")]
async fn refused_arguments_write_nothing(db: PgPool) {
    let h = host(db.clone());
    let admin = enrolled_admin(&db).await;
    for bad in [
        json!({ "kind": "restart-service" }),
        json!({ "kind": "channel", "arg": "nightly" }),
        json!({ "kind": "schedule", "arg": "mon@25:00" }),
        json!({ "kind": "update-skip", "arg": "now" }),
    ] {
        let (st, _) = send(&h.app, "POST", "/v1/admin/host/jobs", &admin, Some(&code_now()), None, Some(bad.clone())).await;
        assert_eq!(st, StatusCode::BAD_REQUEST, "{bad}");
    }
    assert!(job_files(&h.dir).is_empty());
}

#[sqlx::test(migrations = "../../migrations")]
async fn status_is_read_back_capped_and_known_only(db: PgPool) {
    let h = host(db.clone());
    let admin = enrolled_admin(&db).await;
    let (st, created) = send(
        &h.app,
        "POST",
        "/v1/admin/host/jobs",
        &admin,
        Some(&code_now()),
        None,
        Some(json!({ "kind": "backup-now" })),
    )
    .await;
    assert_eq!(st, StatusCode::ACCEPTED);
    let id = created["id"].as_str().expect("id").to_string();

    let long = "가".repeat(9_000);
    std::fs::write(
        h.dir.join("status").join(format!("{id}.json")),
        format!(r#"{{"state":"running","step":"{long}"}}"#),
    )
    .expect("status file");
    let (st, detail) = send(&h.app, "GET", &format!("/v1/admin/host/jobs/{id}"), &admin, None, None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(detail["state"], "running");
    assert_eq!(detail["step"].as_str().map(|s| s.chars().count()), Some(4096));

    std::fs::write(h.dir.join("status").join(format!("{id}.json")), r#"{"state":"owned"}"#).expect("status file");
    let (_, listed) = send(&h.app, "GET", "/v1/admin/host/jobs", &admin, None, None, None).await;
    assert_eq!(listed["jobs"][0]["state"], "unknown");
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_job_id_is_not_found(db: PgPool) {
    let h = host(db.clone());
    let admin = enrolled_admin(&db).await;
    let (st, _) = send(&h.app, "GET", &format!("/v1/admin/host/jobs/{}", Uuid::now_v7()), &admin, None, None, None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}
