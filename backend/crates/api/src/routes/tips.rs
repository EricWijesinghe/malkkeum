//! Customer tip after a completed job. Charged to the saved payment method like the job payment. The
//! whole amount is added to the partner's settlement (`domain::tip::split_tip`), so it pays out with it.

use super::bookings::{self, charge};
use crate::{
    auth::Customer,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::post,
};
use domain::{
    Won,
    booking::BookingStatus,
    tip::{check_tip_allowed, split_tip, validate_tip},
};
use serde::Deserialize;
use serde_json::{Value, json};
use uuid::Uuid;

pub fn routes() -> Router<AppState> {
    Router::new().route("/bookings/{id}/tip", post(tip))
}

#[derive(Deserialize)]
struct TipBody {
    amount: i64,
    payment_method_id: Uuid,
}

async fn tip(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(t): Json<TipBody>) -> ApiResult<Json<Value>> {
    let b = bookings::owned(&s, a.id, id).await?;
    let completed = matches!(b.status()?, BookingStatus::Completed);
    let amount = validate_tip(Won(t.amount))?;
    let pro = b.pro_id.ok_or(ApiError::Conflict("tip_unavailable"))?;
    let mut tx = s.db.begin().await?;
    // Locking the settlement serializes concurrent tips and refuses once the partner has been paid out.
    let settlement: Option<(String, Option<Uuid>)> = sqlx::query_as("SELECT state, payout_id FROM settlements WHERE booking_id = $1 FOR UPDATE")
        .bind(id)
        .fetch_optional(&mut *tx)
        .await?;
    // A settlement already in a payout batch may be at the provider: a tip added now would not be in the money moved.
    if settlement.as_ref().is_none_or(|(state, payout)| state == "paid" || payout.is_some()) {
        return Err(ApiError::Conflict("tip_unavailable"));
    }
    let existing: Option<i64> = sqlx::query_scalar("SELECT amount FROM booking_tips WHERE booking_id = $1")
        .bind(id)
        .fetch_optional(&mut *tx)
        .await?;
    check_tip_allowed(completed, existing.map(Won))?;
    let split = split_tip(amount);
    let tx_id = charge(&s, &mut tx, a.id, t.payment_method_id, id, amount, "tip").await?;
    sqlx::query("INSERT INTO booking_tips (booking_id, user_id, pro_id, amount, payment_key) VALUES ($1, $2, $3, $4, $5)")
        .bind(id)
        .bind(a.id)
        .bind(pro)
        .bind(split.partner.0)
        .bind(&tx_id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE settlements SET tip = tip + $2, net = net + $2 WHERE booking_id = $1")
        .bind(id)
        .bind(split.partner.0)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(json!({ "ok": true, "amount": amount.0 })))
}
