//! 세금계산서 requests from business customers. The customer gives business details at checkout; once the checkout
//! settles the request is queued for the owner. The owner exports the queue for the 홈택스 upload (layout UNVERIFIED,
//! see domain::tax::TAX_INVOICE_HEADERS), issues on 홈택스, then marks each request issued with its approval number.

use super::{audit, checkouts::load_owned, finance::csv_response};
use crate::{
    auth::{Admin, Customer},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    response::Response,
    routing::{get, post, put},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::{
    cash_receipt::normalize_business_number,
    finance,
    tax::{self, InvoiceRow},
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

/// Line item name on the invoice. ACCOUNTANT: confirm the 품목 wording for cleaning services.
const ITEM_NAME: &str = "청소 서비스";
const MAX_TEXT: usize = 100;

#[derive(Deserialize)]
struct RequestBody {
    business_number: String,
    company_name: String,
    #[serde(default)]
    representative: String,
    #[serde(default)]
    business_type: String,
    #[serde(default)]
    business_item: String,
    #[serde(default)]
    address: String,
    email: String,
}

/// Trims a free-text field and bounds its length.
fn clean(v: &str) -> ApiResult<String> {
    let t = v.trim();
    if t.chars().count() > MAX_TEXT {
        return Err(ApiError::BadRequest("text_too_long"));
    }
    Ok(t.to_string())
}

/// Basic shape check only: one `@`, a dot in the domain part, no spaces.
fn valid_email(e: &str) -> bool {
    let Some((local, domain)) = e.split_once('@') else { return false };
    !local.is_empty() && domain.contains('.') && !domain.starts_with('.') && !domain.ends_with('.') && !e.contains(char::is_whitespace) && e.len() <= 254
}

#[derive(Serialize, FromRow)]
pub struct InvoiceView {
    id: Uuid,
    checkout_id: Uuid,
    payment_id: Option<Uuid>,
    business_number: String,
    company_name: String,
    representative: String,
    email: String,
    state: String,
    approval_number: Option<String>,
    issued_on: Option<NaiveDate>,
    exported_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
}

const VIEW_COLUMNS: &str = "id, checkout_id, payment_id, business_number, company_name, representative, email, state, approval_number, issued_on, exported_at, created_at";

async fn view(db: &PgPool, id: Uuid) -> ApiResult<InvoiceView> {
    sqlx::query_as(&format!("SELECT {VIEW_COLUMNS} FROM tax_invoice_requests WHERE id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// `PUT /checkouts/{id}/tax-invoice`: replaces the pending request for the checkout. Only while unpaid.
async fn request(State(s): State<AppState>, Customer(a): Customer, Path(checkout): Path<Uuid>, Json(b): Json<RequestBody>) -> ApiResult<Json<InvoiceView>> {
    let ck = load_owned(&s.db, a.id, checkout).await?;
    if ck.status != "pending" && ck.status != "awaiting_deposit" {
        return Err(ApiError::Conflict("checkout_not_open"));
    }
    let business_number = normalize_business_number(&b.business_number)?;
    let company_name = clean(&b.company_name)?;
    if company_name.is_empty() {
        return Err(ApiError::BadRequest("company_name"));
    }
    let email = b.email.trim().to_string();
    if !valid_email(&email) {
        return Err(ApiError::BadRequest("email"));
    }
    let mut tx = s.db.begin().await?;
    sqlx::query("DELETE FROM tax_invoice_requests WHERE checkout_id = $1 AND state = 'pending'").bind(checkout).execute(&mut *tx).await?;
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO tax_invoice_requests (checkout_id, business_number, company_name, representative, business_type, business_item, address, email, state)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending') RETURNING id",
    )
    .bind(checkout)
    .bind(business_number)
    .bind(company_name)
    .bind(clean(&b.representative)?)
    .bind(clean(&b.business_type)?)
    .bind(clean(&b.business_item)?)
    .bind(clean(&b.address)?)
    .bind(email)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Json(view(&s.db, id).await?))
}

/// Called after a checkout settles: links the pending request to the payment and queues it for the owner.
pub async fn on_settled(s: &AppState, checkout: Uuid, provider_tx_id: &str) {
    let linked = sqlx::query(
        "UPDATE tax_invoice_requests SET payment_id = (SELECT id FROM payments WHERE provider = 'portone' AND provider_tx_id = $2 LIMIT 1),
         state = 'requested', updated_at = now() WHERE checkout_id = $1 AND state = 'pending'",
    )
    .bind(checkout)
    .bind(provider_tx_id)
    .execute(&s.db)
    .await;
    if let Err(e) = linked {
        tracing::error!(error = %e, checkout = %checkout, "tax invoice link failed");
    }
}

#[derive(Deserialize)]
struct RangeQuery {
    from: NaiveDate,
    to: NaiveDate,
}

/// Owner queue: requests created in the KST date range that are not yet cancelled.
async fn list(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<RangeQuery>) -> ApiResult<Json<Vec<InvoiceView>>> {
    let rows: Vec<InvoiceView> = sqlx::query_as(&format!(
        "SELECT {VIEW_COLUMNS} FROM tax_invoice_requests
         WHERE state IN ('requested', 'issued') AND (created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
         ORDER BY created_at DESC LIMIT 500"
    ))
    .bind(q.from)
    .bind(q.to)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(FromRow)]
struct ExportRow {
    id: Uuid,
    day: NaiveDate,
    business_number: String,
    company_name: String,
    representative: String,
    business_type: String,
    business_item: String,
    address: String,
    email: String,
    amount: i64,
}

/// CSV for the 홈택스 upload: queued requests (state 'requested') in the range. Marks them exported.
async fn export(State(s): State<AppState>, Admin(a): Admin, Query(q): Query<RangeQuery>) -> ApiResult<Response> {
    let rows: Vec<ExportRow> = sqlx::query_as(
        "SELECT t.id, (t.created_at AT TIME ZONE 'Asia/Seoul')::date AS day, t.business_number, t.company_name, t.representative,
           t.business_type, t.business_item, t.address, t.email, p.amount
         FROM tax_invoice_requests t JOIN payments p ON p.id = t.payment_id
         WHERE t.state = 'requested' AND (t.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
         ORDER BY t.created_at, t.id",
    )
    .bind(q.from)
    .bind(q.to)
    .fetch_all(&s.db)
    .await?;
    let invoice_rows: Vec<InvoiceRow> = rows
        .iter()
        .map(|r| InvoiceRow {
            day: r.day,
            business_number: r.business_number.clone(),
            company_name: r.company_name.clone(),
            representative: r.representative.clone(),
            business_type: r.business_type.clone(),
            business_item: r.business_item.clone(),
            address: r.address.clone(),
            email: r.email.clone(),
            item_name: ITEM_NAME.to_string(),
            total: r.amount,
        })
        .collect();
    let ids: Vec<Uuid> = rows.iter().map(|r| r.id).collect();
    sqlx::query("UPDATE tax_invoice_requests SET exported_at = now(), updated_at = now() WHERE id = ANY($1)").bind(&ids).execute(&s.db).await?;
    audit(&s.db, "staff", Some(a.id), "finance.export", "tax_invoices", json!({ "from": q.from, "to": q.to, "rows": ids.len() })).await?;
    let name = format!("malkkeum-tax-invoices-{}_{}", q.from, q.to);
    csv_response(&name, finance::csv_document(&tax::tax_invoice_document(&invoice_rows)))
}

#[derive(Deserialize)]
struct IssuedBody {
    approval_number: String,
    issued_on: NaiveDate,
}

/// `POST /finance/tax-invoices/{id}/issued`: the owner issued it on 홈택스. Only for queued requests.
async fn mark_issued(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(b): Json<IssuedBody>) -> ApiResult<Json<InvoiceView>> {
    let approval = b.approval_number.trim().to_string();
    let shape_ok = !approval.is_empty() && approval.len() <= 40 && approval.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'-');
    if !shape_ok {
        return Err(ApiError::BadRequest("approval_number"));
    }
    let updated = sqlx::query("UPDATE tax_invoice_requests SET state = 'issued', approval_number = $2, issued_on = $3, updated_at = now() WHERE id = $1 AND state = 'requested'")
        .bind(id)
        .bind(approval)
        .bind(b.issued_on)
        .execute(&s.db)
        .await?;
    if updated.rows_affected() == 0 {
        return Err(ApiError::Conflict("not_requested"));
    }
    audit(&s.db, "staff", Some(a.id), "tax_invoice.issued", "tax_invoice", json!({ "id": id })).await?;
    Ok(Json(view(&s.db, id).await?))
}

/// Customer routes, merged at the top level like the checkout routes.
pub fn routes() -> Router<AppState> {
    Router::new().route("/checkouts/{id}/tax-invoice", put(request))
}

/// Owner routes, merged under `/admin`.
pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/finance/tax-invoices", get(list))
        .route("/finance/export/tax-invoices", get(export))
        .route("/finance/tax-invoices/{id}/issued", post(mark_issued))
}
