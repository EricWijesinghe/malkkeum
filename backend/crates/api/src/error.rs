use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use domain::DomainError;
use serde_json::json;

/// Every API failure. Responses carry a stable `code` the apps translate;
/// internal details are logged, never returned.
#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("unauthorized")]
    Unauthorized,
    #[error("forbidden")]
    Forbidden,
    #[error("not found")]
    NotFound,
    #[error("conflict: {0}")]
    Conflict(&'static str),
    #[error("bad request: {0}")]
    BadRequest(&'static str),
    #[error("too many requests")]
    RateLimited,
    #[error("payment failed: {0}")]
    PaymentFailed(String),
    #[error("unavailable: {0}")]
    Unavailable(&'static str),
    #[error(transparent)]
    Domain(#[from] DomainError),
    #[error(transparent)]
    Db(#[from] sqlx::Error),
    #[error("internal: {0}")]
    Internal(String),
}

pub type ApiResult<T> = Result<T, ApiError>;

impl ApiError {
    fn status_and_code(&self) -> (StatusCode, &str) {
        match self {
            Self::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized"),
            Self::Forbidden => (StatusCode::FORBIDDEN, "forbidden"),
            Self::NotFound => (StatusCode::NOT_FOUND, "not_found"),
            Self::Conflict(c) => (StatusCode::CONFLICT, c),
            Self::BadRequest(c) => (StatusCode::BAD_REQUEST, c),
            Self::RateLimited => (StatusCode::TOO_MANY_REQUESTS, "rate_limited"),
            Self::PaymentFailed(_) => (StatusCode::PAYMENT_REQUIRED, "payment_failed"),
            Self::Unavailable(c) => (StatusCode::SERVICE_UNAVAILABLE, c),
            Self::Domain(e @ (DomainError::SlotFull | DomainError::CouponUsed | DomainError::InvalidTransition | DomainError::CancellationWindowClosed)) => {
                (StatusCode::CONFLICT, e.code())
            }
            Self::Domain(e) => (StatusCode::UNPROCESSABLE_ENTITY, e.code()),
            Self::Db(sqlx::Error::RowNotFound) => (StatusCode::NOT_FOUND, "not_found"),
            Self::Db(sqlx::Error::Database(d)) if d.is_unique_violation() => (StatusCode::CONFLICT, "duplicate"),
            Self::Db(_) | Self::Internal(_) => (StatusCode::INTERNAL_SERVER_ERROR, "internal"),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code) = self.status_and_code();
        if status.is_server_error() {
            tracing::error!(error = %self, "request failed");
        }
        (status, Json(json!({ "error": { "code": code } }))).into_response()
    }
}
