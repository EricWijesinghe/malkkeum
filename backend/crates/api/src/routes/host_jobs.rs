//! Owner-queued server jobs (`/admin/host/jobs`). An accepted request writes one job file into the agent's
//! inbox and records a row; the live state is read back from the agent's status files.

use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    host_jobs::{self, JobSpec},
    host_status::{self, HostStatus},
    idempotency,
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
use sqlx::FromRow;
use std::{fs::OpenOptions, io::Write, net::SocketAddr, path::Path as FsPath};
use uuid::Uuid;

use super::keys::owner_gate;

const LIST_LIMIT: i64 = 50;

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
    let spec = host_jobs::validate(&body.kind, &body.arg).map_err(ApiError::BadRequest)?;
    if spec.kind.needs_owner() {
        owner_gate(&s, peer, &headers, a.id).await?;
    }
    let dir = jobs_dir(&s)?;
    let id = Uuid::now_v7();
    let token = host_jobs::new_progress_token();
    sqlx::query("INSERT INTO host_jobs (id, kind, arg, progress_token, requested_by) VALUES ($1, $2, $3, $4, $5)")
        .bind(id)
        .bind(spec.kind.name())
        .bind(&spec.arg)
        .bind(&token)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    if let Err(e) = write_job_file(dir, id, &spec, &token) {
        tracing::error!(error = %e, "host job file not written");
        // A job that was never queued must not show up as queued.
        sqlx::query("DELETE FROM host_jobs WHERE id = $1").bind(id).execute(&s.db).await?;
        return Err(ApiError::Unavailable("host_queue_unwritable"));
    }
    let data = json!({ "kind": spec.kind.name(), "arg": spec.arg });
    sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data) VALUES ('staff', $1, 'host_job.enqueue', $2, $3)")
        .bind(a.id)
        .bind(id.to_string())
        .bind(data)
        .execute(&s.db)
        .await?;
    Ok((
        StatusCode::ACCEPTED,
        Json(job_json(
            &dir_status(&s, id),
            &JobRow {
                id,
                kind: spec.kind.name().into(),
                arg: spec.arg,
                progress_token: token,
                created_at: Utc::now(),
            },
        )),
    ))
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
        "state": status.as_ref().map_or("queued", |st| st.state.as_str()),
        "step": status.as_ref().and_then(|st| st.step.clone()),
    })
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
