//! `GET /v1/openapi.json`: the hand-maintained spec, served to staff admins only (it lists admin routes).

use crate::auth::Admin;
use axum::{
    http::{HeaderValue, header},
    response::{IntoResponse, Response},
};

/// Source of truth, kept inside the crate so the Docker build context includes it.
const SPEC: &str = include_str!("../openapi.json");

pub async fn spec(_admin: Admin) -> Response {
    ([(header::CONTENT_TYPE, HeaderValue::from_static("application/json"))], SPEC).into_response()
}
