//! Owner finance: period summary, time series, per-partner and per-service tables, accountant CSV exports,
//! and the partner's own earnings. Money is integer won. One event query feeds every owner report, so the
//! numbers on each screen and in each export agree.

use super::audit;
use crate::{
    auth::{Admin, Pro, Staff},
    error::{ApiError, ApiResult},
    state::AppState,
    util::today_kst,
};
use axum::{
    Json, Router,
    extract::{Query, State},
    http::{HeaderMap, HeaderValue, header},
    response::{IntoResponse, Response},
    routing::get,
};
use chrono::{Datelike, NaiveDate};
use domain::{
    Won,
    finance::{self, Cell, Grain},
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::{FromRow, PgPool};
use std::collections::BTreeMap;
use uuid::Uuid;

/// Every owner event, one row per (day, partner, service, kind). `$1`..`$2` is the inclusive KST date range.
/// Kinds: booking, cancelled, booking_value, discount (bookings by creation day); gross, refund (payments);
/// job, settled_gross, fee (settlements by creation day, held excluded); paid (by payout day);
/// pending, held (settlements by creation day).
const EVENTS_SQL: &str = r#"
WITH ev AS (
  SELECT (b.created_at AT TIME ZONE 'Asia/Seoul')::date AS d, NULL::uuid AS pro, b.service_code AS svc, 'booking' AS kind, 1::bigint AS v
    FROM bookings b WHERE (b.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (b.created_at AT TIME ZONE 'Asia/Seoul')::date, NULL::uuid, b.service_code, 'cancelled', 1::bigint
    FROM bookings b WHERE b.status = -1 AND (b.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (b.created_at AT TIME ZONE 'Asia/Seoul')::date, NULL::uuid, b.service_code, 'booking_value', COALESCE(b.final_price, b.list_price, 0)
    FROM bookings b WHERE b.status <> -1 AND (b.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (b.created_at AT TIME ZONE 'Asia/Seoul')::date, NULL::uuid, b.service_code, 'discount', b.discount
    FROM bookings b WHERE b.status <> -1 AND (b.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (p.created_at AT TIME ZONE 'Asia/Seoul')::date, NULL::uuid, b.service_code, 'gross', p.amount
    FROM payments p JOIN bookings b ON b.id = p.booking_id
    WHERE p.status IN ('paid','partially_refunded','refunded') AND (p.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (COALESCE(b.cancelled_at, p.created_at) AT TIME ZONE 'Asia/Seoul')::date, NULL::uuid, b.service_code, 'refund', p.refunded_amount
    FROM payments p JOIN bookings b ON b.id = p.booking_id
    WHERE p.refunded_amount > 0 AND (COALESCE(b.cancelled_at, p.created_at) AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.created_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'job', 1::bigint
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state <> 'held' AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.created_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'settled_gross', st.gross
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state <> 'held' AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.created_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'fee', st.fee
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state <> 'held' AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.paid_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'paid', st.net
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state = 'paid' AND (st.paid_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.created_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'pending', st.net
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state IN ('pending','waiting_balance') AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
  UNION ALL
  SELECT (st.created_at AT TIME ZONE 'Asia/Seoul')::date, st.pro_id, b.service_code, 'held', st.net
    FROM settlements st JOIN bookings b ON b.id = st.booking_id
    WHERE st.state = 'held' AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
)
"#;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/finance/summary", get(summary))
        .route("/finance/series", get(series))
        .route("/finance/partners", get(partners))
        .route("/finance/services", get(services))
        .route("/finance/export/ledger", get(export_ledger))
        .route("/finance/export/settlements", get(export_settlements))
        .route("/finance/export/monthly", get(export_monthly))
}

pub fn partner_routes() -> Router<AppState> {
    Router::new().route("/earnings", get(partner_earnings))
}

#[derive(Deserialize)]
struct PeriodQuery {
    /// day | week | month | custom (default month)
    period: Option<String>,
    /// Any date inside the wanted day, week or month (default today, KST).
    anchor: Option<NaiveDate>,
    from: Option<NaiveDate>,
    to: Option<NaiveDate>,
}

fn resolve(q: &PeriodQuery) -> ApiResult<(NaiveDate, NaiveDate)> {
    Ok(finance::period(q.period.as_deref().unwrap_or("month"), q.anchor.unwrap_or_else(today_kst), q.from, q.to)?)
}

#[derive(FromRow)]
struct Agg {
    key: NaiveDate,
    pro: Option<Uuid>,
    svc: Option<String>,
    kind: String,
    v: i64,
}

/// Sums the events in `[from, to]`, grouped by `unit` (a `date_trunc` unit; "year" folds the whole range).
async fn aggregate(db: &PgPool, from: NaiveDate, to: NaiveDate, unit: &str) -> ApiResult<Vec<Agg>> {
    let sql = format!(
        "{EVENTS_SQL} SELECT date_trunc($3, ev.d::timestamp)::date AS key, ev.pro, ev.svc, ev.kind, SUM(ev.v)::bigint AS v FROM ev GROUP BY 1, 2, 3, 4"
    );
    Ok(sqlx::query_as::<_, Agg>(&sql).bind(from).bind(to).bind(unit).fetch_all(db).await?)
}

/// Totals by kind for one group. Filled from `Agg` rows; `Metrics` derives the reported figures.
#[derive(Default, Clone, Copy)]
struct Totals {
    bookings: i64,
    cancelled: i64,
    booking_value: i64,
    discount: i64,
    gross: i64,
    refunds: i64,
    jobs: i64,
    settled_gross: i64,
    fee: i64,
    paid: i64,
    pending: i64,
    held: i64,
}

impl Totals {
    fn add(&mut self, kind: &str, v: i64) {
        let slot = match kind {
            "booking" => &mut self.bookings,
            "cancelled" => &mut self.cancelled,
            "booking_value" => &mut self.booking_value,
            "discount" => &mut self.discount,
            "gross" => &mut self.gross,
            "refund" => &mut self.refunds,
            "job" => &mut self.jobs,
            "settled_gross" => &mut self.settled_gross,
            "fee" => &mut self.fee,
            "paid" => &mut self.paid,
            "pending" => &mut self.pending,
            "held" => &mut self.held,
            _ => return,
        };
        *slot += v;
    }
}

/// Groups events by an optional key (rows with no key are skipped).
fn fold_by<K: Ord>(rows: &[Agg], key: impl Fn(&Agg) -> Option<K>) -> BTreeMap<K, Totals> {
    let mut out: BTreeMap<K, Totals> = BTreeMap::new();
    for r in rows {
        if let Some(k) = key(r) {
            out.entry(k).or_default().add(&r.kind, r.v);
        }
    }
    out
}

fn total_of(rows: &[Agg]) -> Totals {
    let mut t = Totals::default();
    for r in rows {
        t.add(&r.kind, r.v);
    }
    t
}

#[derive(Serialize)]
struct Payouts {
    paid: i64,
    pending: i64,
    held: i64,
}

#[derive(Serialize)]
struct Metrics {
    bookings: i64,
    cancelled: i64,
    cancellation_bps: i64,
    avg_order_value: i64,
    discount: i64,
    gross: i64,
    refunds: i64,
    net_revenue: i64,
    platform_fee: i64,
    /// Estimate: 10% of the platform fee. Confirm with the accountant before filing.
    vat_estimate: i64,
    payouts: Payouts,
}

impl From<Totals> for Metrics {
    fn from(t: Totals) -> Self {
        let active = t.bookings - t.cancelled;
        Metrics {
            bookings: t.bookings,
            cancelled: t.cancelled,
            cancellation_bps: finance::ratio_bps(t.cancelled, t.bookings),
            avg_order_value: if active > 0 { t.booking_value / active } else { 0 },
            discount: t.discount,
            gross: t.gross,
            refunds: t.refunds,
            net_revenue: t.gross - t.refunds,
            platform_fee: t.fee,
            vat_estimate: finance::vat_estimate(Won(t.fee)).0,
            payouts: Payouts { paid: t.paid, pending: t.pending, held: t.held },
        }
    }
}

#[derive(Serialize, FromRow)]
struct MethodRow {
    method: String,
    count: i64,
    amount: i64,
}

async fn payment_methods(db: &PgPool, from: NaiveDate, to: NaiveDate) -> ApiResult<Vec<MethodRow>> {
    Ok(sqlx::query_as(
        "SELECT method, count(*)::bigint AS count, COALESCE(SUM(amount), 0)::bigint AS amount FROM checkouts
         WHERE status = 'paid' AND (created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
         GROUP BY method ORDER BY amount DESC",
    )
    .bind(from)
    .bind(to)
    .fetch_all(db)
    .await?)
}

#[derive(Serialize)]
struct Summary {
    from: NaiveDate,
    to: NaiveDate,
    #[serde(flatten)]
    metrics: Metrics,
    payment_methods: Vec<MethodRow>,
    vat_basis: &'static str,
}

async fn summary(State(s): State<AppState>, _st: Staff, Query(q): Query<PeriodQuery>) -> ApiResult<Json<Summary>> {
    let (from, to) = resolve(&q)?;
    let rows = aggregate(&s.db, from, to, "year").await?;
    Ok(Json(Summary {
        from,
        to,
        metrics: total_of(&rows).into(),
        payment_methods: payment_methods(&s.db, from, to).await?,
        vat_basis: "platform_fee_10pct_estimate",
    }))
}

#[derive(Serialize)]
struct Point {
    key: NaiveDate,
    #[serde(flatten)]
    m: Metrics,
}

/// One point per bucket, zero-filled, oldest first.
async fn series_points(db: &PgPool, grain: Grain, from: NaiveDate, to: NaiveDate) -> ApiResult<Vec<Point>> {
    let rows = aggregate(db, from, to, grain.trunc_unit()).await?;
    let by_key = fold_by(&rows, |r| Some(r.key));
    Ok(finance::buckets(grain, from, to)
        .into_iter()
        .map(|key| Point {
            key,
            m: by_key.get(&key).copied().unwrap_or_default().into(),
        })
        .collect())
}

#[derive(Deserialize)]
struct SeriesQuery {
    /// day (last `days`, default 30, 7..=90) | week (12) | month (12)
    grain: Option<String>,
    days: Option<u32>,
}

async fn series(State(s): State<AppState>, _st: Staff, Query(q): Query<SeriesQuery>) -> ApiResult<Json<Vec<Point>>> {
    let grain = match q.grain.as_deref() {
        Some(g) => Grain::parse(g).ok_or(ApiError::BadRequest("invalid_grain"))?,
        None => Grain::Day,
    };
    let count = match grain {
        Grain::Day => q.days.unwrap_or(30).clamp(7, 90),
        Grain::Week | Grain::Month => 12,
    };
    let (from, to) = finance::series_range(grain, today_kst(), count);
    Ok(Json(series_points(&s.db, grain, from, to).await?))
}

#[derive(Serialize)]
struct PartnerRow {
    pro_id: Uuid,
    name: String,
    team_name: String,
    jobs: i64,
    settled_gross: i64,
    fee: i64,
    net: i64,
    paid: i64,
    pending: i64,
    held: i64,
}

#[derive(FromRow)]
struct ProName {
    id: Uuid,
    name: String,
    team_name: String,
}

async fn partners(State(s): State<AppState>, _st: Staff, Query(q): Query<PeriodQuery>) -> ApiResult<Json<Vec<PartnerRow>>> {
    let (from, to) = resolve(&q)?;
    let rows = aggregate(&s.db, from, to, "year").await?;
    let by_pro = fold_by(&rows, |r| r.pro);
    let ids: Vec<Uuid> = by_pro.keys().copied().collect();
    let names: Vec<ProName> = sqlx::query_as("SELECT id, name, team_name FROM pros WHERE id = ANY($1)").bind(&ids).fetch_all(&s.db).await?;
    let mut out: Vec<PartnerRow> = names
        .into_iter()
        .filter_map(|p| {
            let t = by_pro.get(&p.id)?;
            Some(PartnerRow {
                pro_id: p.id,
                name: p.name,
                team_name: p.team_name,
                jobs: t.jobs,
                settled_gross: t.settled_gross,
                fee: t.fee,
                net: t.settled_gross - t.fee,
                paid: t.paid,
                pending: t.pending,
                held: t.held,
            })
        })
        .collect();
    out.sort_by_key(|r| std::cmp::Reverse(r.settled_gross));
    Ok(Json(out))
}

#[derive(Serialize)]
struct ServiceRow {
    service_code: String,
    #[serde(flatten)]
    m: Metrics,
}

async fn services(State(s): State<AppState>, _st: Staff, Query(q): Query<PeriodQuery>) -> ApiResult<Json<Vec<ServiceRow>>> {
    let (from, to) = resolve(&q)?;
    let rows = aggregate(&s.db, from, to, "year").await?;
    let by_svc = fold_by(&rows, |r| r.svc.clone());
    let mut out: Vec<ServiceRow> = by_svc.into_iter().map(|(service_code, t)| ServiceRow { service_code, m: t.into() }).collect();
    out.sort_by_key(|r| std::cmp::Reverse(r.m.gross));
    Ok(Json(out))
}

/// Partner's own earnings: weekly or monthly buckets (12), upcoming payout, and balances.
/// Team members never reach this route: the `Pro` extractor is owner-only.
#[derive(Deserialize)]
struct EarningsQuery {
    grain: Option<String>,
}

#[derive(Serialize, FromRow)]
struct EarnRow {
    key: NaiveDate,
    jobs: i64,
    gross: i64,
    fee: i64,
    net: i64,
}

#[derive(Serialize, FromRow)]
struct NextPayout {
    date: NaiveDate,
    amount: i64,
    count: i64,
}

#[derive(Serialize)]
struct Earnings {
    next_payout: Option<NextPayout>,
    pending_total: i64,
    paid_total: i64,
    series: Vec<EarnRow>,
}

async fn partner_earnings(State(s): State<AppState>, Pro(a): Pro, Query(q): Query<EarningsQuery>) -> ApiResult<Json<Earnings>> {
    let grain = match q.grain.as_deref() {
        Some(g) => Grain::parse(g).filter(|g| *g != Grain::Day).ok_or(ApiError::BadRequest("invalid_grain"))?,
        None => Grain::Week,
    };
    let (from, _) = finance::series_range(grain, today_kst(), 12);
    let rows: Vec<EarnRow> = sqlx::query_as(
        "SELECT date_trunc($2, st.created_at AT TIME ZONE 'Asia/Seoul')::date AS key, COUNT(*)::bigint AS jobs,
           COALESCE(SUM(st.gross), 0)::bigint AS gross, COALESCE(SUM(st.fee), 0)::bigint AS fee, COALESCE(SUM(st.net), 0)::bigint AS net
         FROM settlements st WHERE st.pro_id = $1 AND st.state <> 'held' AND (st.created_at AT TIME ZONE 'Asia/Seoul')::date >= $3
         GROUP BY 1",
    )
    .bind(a.id)
    .bind(grain.trunc_unit())
    .bind(from)
    .fetch_all(&s.db)
    .await?;
    let by_key: BTreeMap<NaiveDate, EarnRow> = rows.into_iter().map(|r| (r.key, r)).collect();
    let series = finance::buckets(grain, from, today_kst())
        .into_iter()
        .map(|key| match by_key.get(&key) {
            Some(r) => EarnRow { key, jobs: r.jobs, gross: r.gross, fee: r.fee, net: r.net },
            None => EarnRow { key, jobs: 0, gross: 0, fee: 0, net: 0 },
        })
        .collect();
    let next_payout: Option<NextPayout> = sqlx::query_as(
        "SELECT st.payout_date AS date, COALESCE(SUM(st.net), 0)::bigint AS amount, COUNT(*)::bigint AS count
         FROM settlements st WHERE st.pro_id = $1 AND st.state = 'pending'
           AND st.payout_date = (SELECT MIN(payout_date) FROM settlements WHERE pro_id = $1 AND state = 'pending')
         GROUP BY st.payout_date",
    )
    .bind(a.id)
    .fetch_optional(&s.db)
    .await?;
    let pending_total: i64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(net), 0)::bigint FROM settlements WHERE pro_id = $1 AND state IN ('pending','waiting_balance')",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    let paid_total: i64 = sqlx::query_scalar("SELECT COALESCE(SUM(net), 0)::bigint FROM settlements WHERE pro_id = $1 AND state = 'paid'")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    Ok(Json(Earnings {
        next_payout,
        pending_total,
        paid_total,
        series,
    }))
}

// ---- CSV exports (owner only; UTF-8 with BOM, formula-guarded) ----

fn text(v: impl Into<String>) -> Cell {
    Cell::Text(v.into())
}

fn csv_response(name: &str, body: String) -> ApiResult<Response> {
    let mut h = HeaderMap::new();
    h.insert(header::CONTENT_TYPE, HeaderValue::from_static("text/csv; charset=utf-8"));
    h.insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
    let disposition = HeaderValue::from_str(&format!("attachment; filename=\"{name}.csv\"")).map_err(|e| ApiError::Internal(e.to_string()))?;
    h.insert(header::CONTENT_DISPOSITION, disposition);
    Ok((h, body).into_response())
}

fn export_name(kind: &str, from: NaiveDate, to: NaiveDate) -> String {
    format!("malkkeum-{kind}-{from}_{to}")
}

#[derive(FromRow)]
struct LedgerRow {
    day: NaiveDate,
    payment_id: Uuid,
    number: String,
    service_code: String,
    kind: String,
    provider: String,
    provider_tx_id: Option<String>,
    amount: i64,
    refunded_amount: i64,
    status: String,
}

async fn export_ledger(State(s): State<AppState>, Admin(a): Admin, Query(q): Query<PeriodQuery>) -> ApiResult<Response> {
    let (from, to) = resolve(&q)?;
    let rows: Vec<LedgerRow> = sqlx::query_as(
        "SELECT (p.created_at AT TIME ZONE 'Asia/Seoul')::date AS day, p.id AS payment_id, b.number, b.service_code, p.kind,
           p.provider, p.provider_tx_id, p.amount, p.refunded_amount, p.status
         FROM payments p JOIN bookings b ON b.id = p.booking_id
         WHERE (p.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2 ORDER BY p.created_at, p.id",
    )
    .bind(from)
    .bind(to)
    .fetch_all(&s.db)
    .await?;
    let mut doc = vec![vec![
        text("결제일"),
        text("결제ID"),
        text("예약번호"),
        text("서비스"),
        text("구분"),
        text("결제수단"),
        text("PG거래번호"),
        text("결제금액"),
        text("환불금액"),
        text("상태"),
    ]];
    doc.extend(rows.into_iter().map(|r| {
        vec![
            text(r.day.to_string()),
            text(r.payment_id.to_string()),
            text(r.number),
            text(r.service_code),
            text(r.kind),
            text(r.provider),
            text(r.provider_tx_id.unwrap_or_default()),
            Cell::Number(r.amount),
            Cell::Number(r.refunded_amount),
            text(r.status),
        ]
    }));
    audit(&s.db, "staff", Some(a.id), "finance.export", "ledger", json!({ "from": from, "to": to })).await?;
    csv_response(&export_name("ledger", from, to), finance::csv_document(&doc))
}

#[derive(FromRow)]
struct SettlementRow {
    id: Uuid,
    number: String,
    service_code: String,
    visit_date: NaiveDate,
    pro_name: String,
    team_name: String,
    gross: i64,
    fee: i64,
    net: i64,
    payout_date: Option<NaiveDate>,
    state: String,
    paid_day: Option<NaiveDate>,
    created_day: NaiveDate,
}

async fn export_settlements(State(s): State<AppState>, Admin(a): Admin, Query(q): Query<PeriodQuery>) -> ApiResult<Response> {
    let (from, to) = resolve(&q)?;
    let rows: Vec<SettlementRow> = sqlx::query_as(
        "SELECT st.id, b.number, b.service_code, b.visit_date, p.name AS pro_name, p.team_name, st.gross, st.fee, st.net,
           st.payout_date, st.state, (st.paid_at AT TIME ZONE 'Asia/Seoul')::date AS paid_day,
           (st.created_at AT TIME ZONE 'Asia/Seoul')::date AS created_day
         FROM settlements st JOIN bookings b ON b.id = st.booking_id JOIN pros p ON p.id = st.pro_id
         WHERE (st.created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2 ORDER BY st.created_at, st.id",
    )
    .bind(from)
    .bind(to)
    .fetch_all(&s.db)
    .await?;
    let opt = |d: Option<NaiveDate>| text(d.map(|d| d.to_string()).unwrap_or_default());
    let mut doc = vec![vec![
        text("정산ID"),
        text("정산일"),
        text("예약번호"),
        text("서비스"),
        text("방문일"),
        text("파트너"),
        text("팀명"),
        text("총액"),
        text("수수료"),
        text("지급액"),
        text("지급예정일"),
        text("지급일"),
        text("상태"),
    ]];
    doc.extend(rows.into_iter().map(|r| {
        vec![
            text(r.id.to_string()),
            text(r.created_day.to_string()),
            text(r.number),
            text(r.service_code),
            text(r.visit_date.to_string()),
            text(r.pro_name),
            text(r.team_name),
            Cell::Number(r.gross),
            Cell::Number(r.fee),
            Cell::Number(r.net),
            opt(r.payout_date),
            opt(r.paid_day),
            text(r.state),
        ]
    }));
    audit(&s.db, "staff", Some(a.id), "finance.export", "settlements", json!({ "from": from, "to": to })).await?;
    csv_response(&export_name("settlements", from, to), finance::csv_document(&doc))
}

fn metric_cells(m: &Metrics) -> Vec<Cell> {
    vec![
        Cell::Number(m.bookings),
        Cell::Number(m.cancelled),
        Cell::Number(m.gross),
        Cell::Number(m.refunds),
        Cell::Number(m.net_revenue),
        Cell::Number(m.platform_fee),
        Cell::Number(m.vat_estimate),
        Cell::Number(m.payouts.paid),
        Cell::Number(m.payouts.pending),
        Cell::Number(m.payouts.held),
    ]
}

/// Monthly summary for the accountant: one row per month and a total row (sums of the same events).
async fn export_monthly(State(s): State<AppState>, Admin(a): Admin, Query(q): Query<PeriodQuery>) -> ApiResult<Response> {
    let (from, to) = resolve(&q)?;
    let points = series_points(&s.db, Grain::Month, from, to).await?;
    let total: Metrics = total_of(&aggregate(&s.db, from, to, "year").await?).into();
    let mut doc = vec![vec![
        text("월"),
        text("예약건수"),
        text("취소건수"),
        text("총결제액"),
        text("환불액"),
        text("순매출"),
        text("플랫폼수수료"),
        text("부가세추정(수수료의10%)"),
        text("파트너지급(완료)"),
        text("지급예정"),
        text("보류"),
    ]];
    doc.extend(points.iter().map(|p| {
        let mut row = vec![text(format!("{:04}-{:02}", p.key.year(), p.key.month()))];
        row.extend(metric_cells(&p.m));
        row
    }));
    let mut total_row = vec![text("합계")];
    total_row.extend(metric_cells(&total));
    doc.push(total_row);
    audit(&s.db, "staff", Some(a.id), "finance.export", "monthly", json!({ "from": from, "to": to })).await?;
    csv_response(&export_name("monthly", from, to), finance::csv_document(&doc))
}
