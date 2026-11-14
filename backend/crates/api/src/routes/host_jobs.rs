//! Owner-queued server jobs (`/admin/host/jobs`). An accepted request writes one job file into the agent's
//! inbox and records a row; the live state is read back from the agent's status files.

use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    host_jobs::{self, JobSpec, Kind},
    host_status::{self, HostStatus},
    idempotency,
    sms_outbox::{self, Message},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, Path, State},
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    routing::get,
};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::{FromRow, PgPool};
use std::{fs::OpenOptions, io::Write, net::SocketAddr, path::Path as FsPath};
use uuid::Uuid;

use super::keys::owner_gate;

const LIST_LIMIT: i64 = 50;
/// A job with no status file this long after it was queued never reached the agent.
const QUEUED_WINDOW_MIN: i64 = 10;

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/host/jobs", idempotency::replayable(get(list).post(enqueue)))
        .route("/host/jobs/{id}", get(detail))
}

#[derive(Deserialize)]
struct EnqueueBody {
    kind: String,
    #[serde(default)]
    arg: String,
}

#[derive(FromRow)]
struct JobRow {
    id: Uuid,
    kind: String,
    arg: String,
    progress_token: String,
    created_at: DateTime<Utc>,
}

async fn enqueue(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
    Json(body): Json<EnqueueBody>,
) -> ApiResult<impl IntoResponse> {
    let key = idempotency_key(&headers)?;
    let spec = host_jobs::validate(&body.kind, &body.arg).map_err(ApiError::BadRequest)?;
    // Checked before the TOTP is spent, so a missing inbox does not burn the owner's code.
    let dir = jobs_dir(&s)?;
    if spec.kind.needs_owner() {
        owner_gate(&s, peer, &headers, a.id).await?;
    }
    let id = Uuid::now_v7();
    let token = host_jobs::new_progress_token();
    let created_at = queue(&s, dir, id, &spec, &token, &key, a.id).await?;
    if spec.kind.needs_owner() {
        notify_owner(&s, a.id, spec.kind).await;
    }
    let row = JobRow {
        id,
        kind: spec.kind.name().into(),
        arg: spec.arg,
        progress_token: token,
        created_at,
    };
    Ok((StatusCode::ACCEPTED, Json(job_json(&dir_status(&s, id), &row))))
}

fn idempotency_key(headers: &HeaderMap) -> ApiResult<String> {
    headers
        .get("idempotency-key")
        .and_then(|v| v.to_str().ok())
        .map(str::to_owned)
        .ok_or(ApiError::BadRequest("idempotency_key_required"))
}

/// Writes the row, its audit entry and the job file in one transaction. The file rename is the point of no
/// return: once it succeeds the job runs, so a commit error after it is logged, not returned to the owner.
async fn queue(s: &AppState, dir: &FsPath, id: Uuid, spec: &JobSpec, token: &str, key: &str, actor: Uuid) -> ApiResult<DateTime<Utc>> {
    let mut tx = s.db.begin().await?;
    let created_at: DateTime<Utc> = sqlx::query_scalar(
        "INSERT INTO host_jobs (id, kind, arg, progress_token, requested_by, idempotency_key) VALUES ($1, $2, $3, $4, $5, $6) RETURNING created_at",
    )
    .bind(id)
    .bind(spec.kind.name())
    .bind(&spec.arg)
    .bind(token)
    .bind(actor)
    .bind(key)
    .fetch_one(&mut *tx)
    .await?;
    let data = json!({ "kind": spec.kind.name(), "arg": spec.arg });
    sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data) VALUES ('staff', $1, 'host_job.enqueue', $2, $3)")
        .bind(actor)
        .bind(id.to_string())
        .bind(data)
        .execute(&mut *tx)
        .await?;
    if let Err(e) = write_job_file(dir, id, spec, token) {
        // Dropping the transaction rolls back the row and the audit entry: a job never queued leaves no trace.
        tracing::error!(error = %e, "host job file not written");
        return Err(ApiError::Unavailable("host_queue_unwritable"));
    }
    if let Err(e) = tx.commit().await {
        tracing::error!(error = %e, job = %id, "host job queued but its record was not saved");
    }
    Ok(created_at)
}

/// Texts the owner which job was queued. Best effort: the job is already queued, so a failure is only logged.
async fn notify_owner(s: &AppState, actor: Uuid, kind: Kind) {
    let phone = match owner_phone(&s.db, actor).await {
        Ok(Some(phone)) => phone,
        Ok(None) => {
            tracing::warn!("owner has no phone on file; job text skipped");
            return;
        }
        Err(e) => {
            tracing::warn!(error = %e, "owner phone not read; job text skipped");
            return;
        }
    };
    let text = format!("서버 작업이 요청됐어요: {}. 본인이 요청하지 않았다면 바로 확인하세요.", kind.label());
    if let Err(e) = sms_outbox::enqueue(s, None, &phone, "host_job.enqueue", Message::Sms(&text)).await {
        tracing::warn!(error = %e, "owner job text not queued");
    }
}

async fn owner_phone(db: &PgPool, actor: Uuid) -> sqlx::Result<Option<String>> {
    let row: Option<Option<String>> = sqlx::query_scalar("SELECT phone FROM staff WHERE id = $1")
        .bind(actor)
        .fetch_optional(db)
        .await?;
    Ok(row.flatten())
}

async fn list(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let rows: Vec<JobRow> = sqlx::query_as("SELECT id, kind, arg, progress_token, created_at FROM host_jobs ORDER BY created_at DESC LIMIT $1")
        .bind(LIST_LIMIT)
        .fetch_all(&s.db)
        .await?;
    let jobs: Vec<Value> = rows.iter().map(|r| job_json(&dir_status(&s, r.id), r)).collect();
    Ok(Json(json!({ "jobs": jobs })))
}

async fn detail(State(s): State<AppState>, Admin(_): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let row: JobRow = sqlx::query_as("SELECT id, kind, arg, progress_token, created_at FROM host_jobs WHERE id = $1")
        .bind(id)
        .fetch_optional(&s.db)
        .await?
        .ok_or(ApiError::NotFound)?;
    Ok(Json(job_json(&dir_status(&s, id), &row)))
}

fn jobs_dir(s: &AppState) -> ApiResult<&FsPath> {
    let dir = s.config.host_jobs_dir.as_path();
    if dir.join("inbox").is_dir() {
        Ok(dir)
    } else {
        Err(ApiError::Unavailable("host_queue_missing"))
    }
}

fn dir_status(s: &AppState, id: Uuid) -> Option<HostStatus> {
    host_status::read(&s.config.host_jobs_dir, id)
}

fn job_json(status: &Option<HostStatus>, row: &JobRow) -> Value {
    json!({
        "id": row.id,
        "kind": row.kind,
        "arg": row.arg,
        "progress_token": row.progress_token,
        "created_at": row.created_at,
        "state": state_of(status, row.created_at),
        "step": status.as_ref().and_then(|st| st.step.clone()),
    })
}

/// No status file yet means queued, but only for a short window. Older than that, the agent never picked it up.
fn state_of(status: &Option<HostStatus>, created_at: DateTime<Utc>) -> &str {
    match status {
        Some(st) => st.state.as_str(),
        None if Utc::now() - created_at <= chrono::Duration::minutes(QUEUED_WINDOW_MIN) => "queued",
        None => "unknown",
    }
}

/// Writes `inbox/<id>.tmp` exclusively, then renames it to `<id>.job`, so the agent never reads a partial file.
fn write_job_file(dir: &FsPath, id: Uuid, spec: &JobSpec, token: &str) -> std::io::Result<()> {
    let inbox = dir.join("inbox");
    let tmp = inbox.join(format!("{}.tmp", id.hyphenated()));
    let result = (|| {
        let mut f = OpenOptions::new().write(true).create_new(true).open(&tmp)?;
        f.write_all(host_jobs::job_file(id, spec, token).as_bytes())?;
        f.sync_all()?;
        std::fs::rename(&tmp, inbox.join(format!("{}.job", id.hyphenated())))
    })();
    if result.is_err() {
        let _ = std::fs::remove_file(&tmp);
    }
    result
}
