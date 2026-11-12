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
    /// 409 `price_changed`: the amount the customer saw is no longer the amount due; `current` carries the new one.
    #[error("price changed: now {0}")]
    PriceChanged(i64),
    #[error("bad request: {0}")]
    BadRequest(&'static str),
    #[error("too many requests")]
    RateLimited,
    #[error("quota exceeded: {0}")]
    Quota(&'static str),
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
            Self::PriceChanged(_) => (StatusCode::CONFLICT, "price_changed"),
            Self::BadRequest(c) => (StatusCode::BAD_REQUEST, c),
            Self::RateLimited => (StatusCode::TOO_MANY_REQUESTS, "rate_limited"),
            Self::Quota(c) => (StatusCode::TOO_MANY_REQUESTS, c),
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
            // The request span carries the request id, so this line can be matched to the client's report.
            tracing::error!(error = %self, "request failed");
        }
        // The id is the only extra thing a client sees; internal details stay in the logs.
        let mut body = json!({ "error": { "code": code } });
        if let Self::PriceChanged(current) = self {
            body["error"]["current"] = json!(current);
        }
        if let Some(id) = crate::telemetry::current_request_id() {
            body["error"]["request_id"] = json!(id);
        }
        (status, Json(body)).into_response()
    }
}
