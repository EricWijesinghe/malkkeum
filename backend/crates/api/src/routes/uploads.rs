//! Photo uploads (chat photos, completion photos). Validated by magic bytes, stored under random names.

use crate::{
    auth::Auth,
    error::{ApiError, ApiResult},
    ratelimit::within_quota,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Multipart, State},
    routing::post,
};
use rand::{RngCore, rngs::OsRng};
use serde_json::{Value, json};

const MAX_IMAGE_BYTES: usize = 10 * 1024 * 1024;

pub fn routes() -> Router<AppState> {
    Router::new().route("/uploads", post(upload))
}

fn sniff(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0xFF, 0xD8, 0xFF, ..] => Some("jpg"),
        [0x89, b'P', b'N', b'G', ..] => Some("png"),
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some("webp"),
        [_, _, _, _, b'f', b't', b'y', b'p', b'h', b'e', b'i', b'c', ..] => Some("heic"),
        _ => None,
    }
}

async fn upload(State(s): State<AppState>, a: Auth, mut form: Multipart) -> ApiResult<Json<Value>> {
    let field = form
        .next_field()
        .await
        .map_err(|_| ApiError::BadRequest("invalid_upload"))?
        .ok_or(ApiError::BadRequest("invalid_upload"))?;
    let bytes = field.bytes().await.map_err(|_| ApiError::BadRequest("invalid_upload"))?;
    if bytes.len() > MAX_IMAGE_BYTES {
        return Err(ApiError::BadRequest("file_too_large"));
    }
    let ext = sniff(&bytes).ok_or(ApiError::BadRequest("unsupported_image"))?;
    let mut name = [0u8; 16];
    OsRng.fill_bytes(&mut name);
    // shortcut: unguessable names on a public path; move to signed URLs on object storage before launch.
    let file = format!("{}.{ext}", hex::encode(name));
    let size = i64::try_from(bytes.len()).unwrap_or(i64::MAX);
    // Quota check, row insert and file write share one transaction: a failed write leaves no row.
    let mut tx = s.db.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("upload:{}", a.id))
        .execute(&mut *tx)
        .await?;
    let used: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads WHERE owner_role = $1 AND owner_id = $2 AND created_at > now() - interval '24 hours'")
        .bind(a.role.as_str())
        .bind(a.id)
        .fetch_one(&mut *tx)
        .await?;
    if !within_quota(used, s.config.upload_daily_quota) {
        return Err(ApiError::Quota("upload_quota"));
    }
    sqlx::query("INSERT INTO uploads (owner_role, owner_id, file, bytes) VALUES ($1, $2, $3, $4)")
        .bind(a.role.as_str())
        .bind(a.id)
        .bind(&file)
        .bind(size)
        .execute(&mut *tx)
        .await?;
    tokio::fs::write(s.config.upload_dir.join(&file), &bytes)
        .await
        .map_err(|e| ApiError::Internal(e.to_string()))?;
    tx.commit().await?;
    Ok(Json(json!({ "url": format!("{}/files/{file}", s.config.public_base_url) })))
}

#[cfg(test)]
mod tests {
    use super::sniff;

    #[test]
    fn sniffs_images_only() {
        assert_eq!(sniff(&[0xFF, 0xD8, 0xFF, 0xE0]), Some("jpg"));
        assert_eq!(sniff(b"\x89PNG\r\n"), Some("png"));
        assert_eq!(sniff(b"<html>"), None);
    }
}
