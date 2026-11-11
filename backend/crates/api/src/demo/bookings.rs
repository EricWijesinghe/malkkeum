//! Bookings and what hangs off them: payments, checkouts, quotes, completion reports, settlements and
//! reviews. Money is won with VAT included, as the API stores it. Prices come from the domain crate.

use super::{
    Ctx, DemoError, photo_url,
    people::{Customer, Pro, World},
};
use chrono::{DateTime, Duration, NaiveDate, TimeZone, Utc};
use rand::seq::SliceRandom;
use domain::{
    Won,
    catalog::{Pricing, Service, default_catalog},
    partner::{payout, payout_date},
    quote::{BuildingType, CleaningType, Layout, LuggageState, QuoteAnswers, QuoteFormula},
};
use serde_json::{Value, json};
use uuid::Uuid;

const PAST_BOOKINGS: usize = 150;
const FUTURE_BOOKINGS: usize = 34;
const START_HOURS: [i16; 4] = [8, 9, 13, 14];
/// Service mix. Quote services (move in/out) are rarer than fixed-price cleaning.
const SERVICE_POOL: [&str; 13] = [
    "studio", "studio", "studio", "kitchen", "kitchen", "bathroom", "bathroom", "aircon", "aircon", "sofa", "mattress", "move_in", "move_out",
];
const PARKING: [&str; 4] = ["지하 주차장 방문자석", "단지 방문자 주차장", "건물 앞 노상 (주차 가능)", "주차 공간 없음, 대중교통 이용"];
const ACCESS: [&str; 3] = ["현관 비밀번호는 앱 메모에 적어 두었어요", "경비실에 방문 사실을 알려 주세요", "초인종 누르시면 제가 나갈게요"];
const QUOTE_NOTES: [&str; 3] = ["평수와 짐 상태를 반영한 견적이에요.", "베란다 청소 포함 금액입니다.", "작업은 약 5시간 예상해요."];
const REVIEWS: [&str; 6] = [
    "약속 시간 딱 맞춰 오셨고 꼼꼼했어요. 다음에도 부탁드려요.",
    "욕실 물때가 완전히 사라졌어요. 기사님이 친절하셨습니다.",
    "전체적으로 만족해요. 에어컨 필터는 조금 아쉬웠어요.",
    "이사 나가는 날이라 급했는데 빠르게 정리해 주셨어요.",
    "가격 대비 괜찮아요. 소파 얼룩도 많이 빠졌습니다.",
    "처음 이용해 봤는데 사진으로 확인시켜 주셔서 안심됐어요.",
];

/// What chat and notifications need to know about one booking.
pub struct BookingRec {
    pub id: Uuid,
    pub number: String,
    pub customer: usize,
    pub pro: Option<usize>,
    pub service: String,
    pub status: i16,
    pub visit: NaiveDate,
    pub start_hour: i16,
    pub created: DateTime<Utc>,
    pub completed: Option<DateTime<Utc>>,
    pub cancelled: Option<DateTime<Utc>>,
    pub is_quote: bool,
    pub final_price: Option<i64>,
    pub deposit: Option<i64>,
    pub refunded: i64,
    pub answers: Option<QuoteAnswers>,
    pub estimate: Option<i64>,
}

/// One payment row plus the checkout that paid it.
struct Pay {
    kind: &'static str,
    amount: i64,
    status: &'static str,
    refunded: i64,
    at: DateTime<Utc>,
}

fn data_err<E: std::fmt::Debug>(e: E) -> DemoError {
    DemoError::Data(format!("domain rule: {e:?}"))
}

pub async fn run(c: &mut Ctx<'_>, world: &mut World) -> Result<Vec<BookingRec>, DemoError> {
    let catalog = default_catalog();
    let formula = QuoteFormula::default();
    let today = c.now.with_timezone(&c.kst).date_naive();
    let mut out = Vec::with_capacity(PAST_BOOKINGS + FUTURE_BOOKINGS);
    for seq in 1..=PAST_BOOKINGS + FUTURE_BOOKINGS {
        let offset = if seq <= PAST_BOOKINGS { -c.range(1, 90) } else { c.range(0, 14) };
        let visit = today + Duration::days(offset);
        let ci = c.range(0, world.customers.len() as i64 - 1) as usize;
        let rec = one(c, world, &catalog, &formula, ci, seq, visit, today).await?;
        out.push(rec);
    }
    extra_checkouts(c, world).await?;
    reviews_and_holds(c, world, &out).await?;
    Ok(out)
}

#[allow(clippy::too_many_arguments)]
async fn one(
    c: &mut Ctx<'_>,
    world: &mut World,
    catalog: &[Service],
    formula: &QuoteFormula,
    ci: usize,
    seq: usize,
    visit: NaiveDate,
    today: NaiveDate,
) -> Result<BookingRec, DemoError> {
    let addr = c.pick(&world.customers[ci].addresses).clone();
    let svc = pick_service(c, catalog, addr.size);
    let is_quote = svc.is_quote();
    let past = visit < today;
    let (status, pro) = pick_status(c, world, is_quote, past, svc.code.as_str(), addr.district);
    let created = created_at(c, visit, past, world.customers[ci].created);
    let start_hour = *c.pick(&START_HOURS);
    let unit = match &svc.pricing {
        Pricing::Unit { units } => Some(c.range(0, units.len() as i64 - 1) as usize),
        _ => None,
    };
    let answers = is_quote.then(|| quote_answers(c, svc.code.as_str(), addr.size));
    let estimate = match &answers {
        Some(a) => Some(formula.estimate(a).map_err(data_err)?.total.0),
        None => None,
    };
    let coupon = if is_quote { None } else { take_coupon(c, &mut world.customers[ci], svc.code.as_str(), created) };
    let (list, minutes) = if is_quote {
        (None, None)
    } else {
        let (p, m) = svc.list_price(unit).map_err(data_err)?;
        (Some(p.0), Some(m as i32))
    };
    let discount = coupon.map_or(0, |(_, amt)| amt.min(list.unwrap_or(0)));
    let final_price = match (is_quote, list) {
        (true, _) if pro.is_some() => estimate.map(|e| e + c.range(-2, 3) * 10_000),
        (true, _) => None,
        (false, Some(l)) => Some(l - discount),
        (false, None) => None,
    };
    let deposit = final_price.map(|f| formula.deposit(Won(f)).0);
    let completed = (status == 3).then(|| kst_at(c, visit, start_hour) + Duration::hours(2));
    let cancelled = (status == -1).then(|| (created + Duration::days(c.range(1, 3))).min(c.now - Duration::hours(1)));
    let pays = payments_for(c, status, is_quote, final_price, deposit, created, completed);
    let paid: i64 = pays.iter().map(|p| p.amount).sum();
    let refunded: i64 = pays.iter().map(|p| p.refunded).sum();
    let balance_paid = pays.iter().any(|p| p.kind == "balance");

    let id = c.id();
    let number = format!("BK{}-{:05}", created.with_timezone(&c.kst).format("%y%m"), seq);
    let pro_row = pro.map(|i| world.pros[i].clone());
    let assignee = pro_row.as_ref().map(|p| *c.pick(&p.assignees));
    let accepted = pro.map(|_| created + Duration::hours(2));
    let updated = completed.or(cancelled).or(accepted).unwrap_or(created);
    let notes = json!({ "parking": c.pick(&PARKING), "access": c.pick(&ACCESS) });
    let pets = if c.chance(0.15) { json!([{ "kind": "dog", "count": 1 }]) } else { json!([]) };
    let household = json!({ "pets": pets, "parking": c.pick(&PARKING), "elevator": c.chance(0.5) });
    let memo = if pro.is_some() && c.chance(0.3) { "현관 비번 확인 후 방문" } else { "" };
    let answers_json = answers.as_ref().map(|a| serde_json::to_value(a).expect("quote answers serialise"));
    let address = super::people::address_snapshot(&addr);
    sqlx::query(
        "INSERT INTO bookings (id, number, user_id, service_code, unit_index, address, district_code, visit_date, start_hour, minutes,
            status, answers, estimate, final_price, deposit, list_price, discount, paid_amount, balance_paid, coupon_id, team_name,
            pro_id, assignee_id, accepted_at, visit_notes, team_memo, cancelled_at, completed_at, created_at, updated_at, household)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31)",
    )
    .bind(id)
    .bind(&number)
    .bind(world.customers[ci].id)
    .bind(svc.code.as_str())
    .bind(unit.map(|u| u as i16))
    .bind(&address)
    .bind(addr.district)
    .bind(visit)
    .bind(start_hour)
    .bind(minutes)
    .bind(status)
    .bind(&answers_json)
    .bind(estimate)
    .bind(final_price)
    .bind(deposit)
    .bind(list)
    .bind(discount)
    .bind(paid)
    .bind(balance_paid)
    .bind(coupon.map(|(cid, _)| cid))
    .bind(pro_row.as_ref().map(|p| p.team.clone()))
    .bind(pro.map(|i| world.pros[i].id))
    .bind(assignee)
    .bind(accepted)
    .bind(&notes)
    .bind(memo)
    .bind(cancelled)
    .bind(completed)
    .bind(created)
    .bind(updated)
    .bind(&household)
    .execute(&mut *c.tx)
    .await?;
    c.reg("bookings", id).await?;
    if let Some((cid, _)) = coupon {
        sqlx::query("UPDATE coupons SET used_booking_id = $2 WHERE id = $1").bind(cid).bind(id).execute(&mut *c.tx).await?;
    }

    let user = world.customers[ci].id;
    let draft_body = json!({
        "service_code": svc.code, "unit_index": unit, "address_id": addr.id, "visit_date": visit,
        "start_hour": start_hour, "coupon_id": coupon.map(|(cid, _)| cid), "answers": answers, "visit_notes": notes,
    });
    let draft = json!({ "body": draft_body, "district_code": addr.district, "snapshot": address, "notes": notes });
    for p in &pays {
        payment(c, id, user, p, &draft).await?;
    }
    if is_quote {
        let winner = pro.zip(final_price);
        quotes(c, world, id, svc.code.as_str(), winner, estimate.unwrap_or(0), created).await?;
    }
    if let (Some(pi), Some(done), Some(price)) = (pro, completed, final_price) {
        completion(c, world, pi, id, done, price, balance_paid, is_quote).await?;
    }
    Ok(BookingRec {
        id,
        number,
        customer: ci,
        pro,
        service: svc.code.clone(),
        status,
        visit,
        start_hour,
        created,
        completed,
        cancelled,
        is_quote,
        final_price,
        deposit,
        refunded,
        answers,
        estimate,
    })
}

/// Fixed-price and unit services are paid in full at booking; quotes pay a deposit, then a balance.
fn payments_for(
    c: &mut Ctx<'_>,
    status: i16,
    is_quote: bool,
    final_price: Option<i64>,
    deposit: Option<i64>,
    created: DateTime<Utc>,
    completed: Option<DateTime<Utc>>,
) -> Vec<Pay> {
    let mut out = Vec::new();
    let Some(total) = final_price else { return out };
    if is_quote {
        if status >= 1 {
            let dep = deposit.unwrap_or(0);
            out.push(Pay { kind: "deposit", amount: dep, status: "paid", refunded: 0, at: created + Duration::days(1) });
            if status == 3 && c.chance(0.8) {
                let at = completed.unwrap_or(created);
                out.push(Pay { kind: "balance", amount: total - dep, status: "paid", refunded: 0, at });
            }
        }
        return out;
    }
    let at = created + Duration::minutes(5);
    if status == -1 {
        let (st, refunded) = if c.chance(0.85) { ("refunded", total) } else { ("partially_refunded", total / 2) };
        out.push(Pay { kind: "full", amount: total, status: st, refunded, at });
    } else if status >= 1 {
        out.push(Pay { kind: "full", amount: total, status: "paid", refunded: 0, at });
    }
    out
}

async fn payment(c: &mut Ctx<'_>, booking: Uuid, user: Uuid, p: &Pay, draft: &Value) -> Result<(), DemoError> {
    let pid = c.id();
    let tx_id = format!("demo_pay_{}", c.hex(12));
    sqlx::query(
        "INSERT INTO payments (id, booking_id, amount, kind, status, refunded_amount, provider, provider_tx_id, idempotency_key, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,'portone',$7,$8,$9)",
    )
    .bind(pid)
    .bind(booking)
    .bind(p.amount)
    .bind(p.kind)
    .bind(p.status)
    .bind(p.refunded)
    .bind(&tx_id)
    .bind(format!("demo-{pid}"))
    .bind(p.at)
    .execute(&mut *c.tx)
    .await?;
    c.reg("payments", pid).await?;
    // The checkout that carried it: the booking request (full price or quote deposit), or the balance.
    if p.kind == "balance" {
        checkout(c, user, "balance", Some(booking), None, p.amount, "paid", Some(tx_id), None, p.at, None).await
    } else {
        checkout(c, user, "booking", Some(booking), Some(draft.clone()), p.amount, "paid", Some(tx_id), Some(booking), p.at, None).await
    }
}

/// One checkout row. Only settled states are written: pending or expired checkouts would be picked up
/// by the reconciler and sent to the real PortOne account.
#[allow(clippy::too_many_arguments)]
async fn checkout(
    c: &mut Ctx<'_>,
    user: Uuid,
    kind: &str,
    booking: Option<Uuid>,
    draft: Option<Value>,
    amount: i64,
    status: &str,
    provider_id: Option<String>,
    result: Option<Uuid>,
    created: DateTime<Utc>,
    refund_reason: Option<&str>,
) -> Result<(), DemoError> {
    let id = c.id();
    sqlx::query(
        "INSERT INTO checkouts (id, user_id, kind, booking_id, draft, method, amount, status, provider_payment_id, result_booking_id,
            refund_reason, expires_at, created_at)
         VALUES ($1,$2,$3,$4,$5,'card',$6,$7,$8,$9,$10,$11,$12)",
    )
    .bind(id)
    .bind(user)
    .bind(kind)
    .bind(booking)
    .bind(draft)
    .bind(amount)
    .bind(status)
    .bind(provider_id)
    .bind(result)
    .bind(refund_reason)
    .bind(created + Duration::minutes(15))
    .bind(created)
    .execute(&mut *c.tx)
    .await?;
    c.reg("checkouts", id).await
}

/// Abandoned, failed and late-refunded checkouts that never became bookings.
async fn extra_checkouts(c: &mut Ctx<'_>, world: &World) -> Result<(), DemoError> {
    let now = c.now;
    let cases: [(&str, Option<&str>, i64); 7] = [
        ("failed", None, 0),
        ("failed", None, 1),
        ("failed", None, 2),
        ("cancelled", None, 3),
        ("cancelled", None, 4),
        ("refunded", Some("예약 마감 후 입금 확인되어 환불"), 5),
        ("refunded", Some("서비스 지역 외 주소로 확인되어 환불"), 6),
    ];
    for (status, reason, n) in cases {
        let cust = &world.customers[n as usize % world.customers.len()];
        let created = now - Duration::days(3 + n * 4);
        let tx_id = (status == "refunded").then(|| format!("demo_pay_{}", c.hex(12)));
        checkout(c, cust.id, "booking", None, Some(json!({ "body": { "service_code": "studio" }, "district_code": cust.addresses[0].district })), 45_000, status, tx_id, None, created, reason).await?;
    }
    Ok(())
}

fn pick_service<'a>(c: &mut Ctx<'_>, catalog: &'a [Service], size: i16) -> &'a Service {
    let fits: Vec<&str> = SERVICE_POOL
        .iter()
        .copied()
        .filter(|code| catalog.iter().any(|s| s.code == *code && s.check_address_size(size as u16).is_ok()))
        .collect();
    let code = *c.pick(&fits);
    catalog.iter().find(|s| s.code == code).expect("pool codes exist in the catalogue")
}

/// Status and assigned pro. Past visits end completed (85%) or cancelled; upcoming ones are open or assigned.
fn pick_status(c: &mut Ctx<'_>, world: &World, is_quote: bool, past: bool, service: &str, district: &str) -> (i16, Option<usize>) {
    if past {
        return if c.chance(0.85) { (3, pick_pro(c, world, service, district)) } else { (-1, None) };
    }
    if is_quote {
        return match c.range(0, 9) {
            0..=3 => (0, None),
            4..=6 => (1, pick_pro(c, world, service, district)),
            _ => (2, pick_pro(c, world, service, district)),
        };
    }
    if c.chance(0.6) { (2, pick_pro(c, world, service, district)) } else { (1, None) }
}

/// A verified, non-deleted pro who offers the service in the district; falls back to looser matches.
fn pick_pro(c: &mut Ctx<'_>, world: &World, service: &str, district: &str) -> Option<usize> {
    let active = |p: &Pro| p.verified && !p.deleted;
    let strict: Vec<usize> = (0..world.pros.len())
        .filter(|&i| active(&world.pros[i]) && world.pros[i].services.contains(&service) && world.pros[i].districts.contains(&district))
        .collect();
    let loose: Vec<usize> = (0..world.pros.len()).filter(|&i| active(&world.pros[i]) && world.pros[i].services.contains(&service)).collect();
    let any: Vec<usize> = (0..world.pros.len()).filter(|&i| active(&world.pros[i])).collect();
    let pool = if !strict.is_empty() { strict } else if !loose.is_empty() { loose } else { any };
    if pool.is_empty() { None } else { Some(*c.pick(&pool)) }
}

/// Booking time: a few days before the visit for past jobs, a few days ago for upcoming ones.
/// Never before the customer signed up, never in the future.
fn created_at(c: &mut Ctx<'_>, visit: NaiveDate, past: bool, since: DateTime<Utc>) -> DateTime<Utc> {
    let base = if past {
        kst_at(c, visit, 9) - Duration::days(c.range(1, 10)) + Duration::hours(c.range(0, 10))
    } else {
        c.now - Duration::days(c.range(0, 4)) - Duration::hours(c.range(1, 5))
    };
    base.max(since + Duration::hours(1)).min(c.now - Duration::hours(1))
}

/// UTC instant of a KST wall-clock time on `date`.
pub(crate) fn kst_at(c: &Ctx<'_>, date: NaiveDate, hour: i16) -> DateTime<Utc> {
    let local = date.and_hms_opt(hour as u32, 0, 0).expect("valid hour");
    c.kst.from_local_datetime(&local).single().expect("fixed offset").with_timezone(&Utc)
}

/// Uses one matching, unused coupon for about a third of fixed-price bookings.
fn take_coupon(c: &mut Ctx<'_>, cust: &mut Customer, service: &str, created: DateTime<Utc>) -> Option<(Uuid, i64)> {
    if !c.chance(0.35) {
        return None;
    }
    let coupon = cust
        .coupons
        .iter_mut()
        .find(|k| !k.used && k.service.is_none_or(|s| s == service) && k.issued <= created && created < k.expires)?;
    coupon.used = true;
    Some((coupon.id, coupon.amount))
}

fn quote_answers(c: &mut Ctx<'_>, service: &str, size: i16) -> QuoteAnswers {
    let cleaning = if service == "move_out" {
        *c.pick(&[CleaningType::Standard, CleaningType::SameDayMove, CleaningType::SomeLuggageLeft])
    } else {
        *c.pick(&[CleaningType::NormalMoveIn, CleaningType::AfterInterior, CleaningType::LivedInDeepClean])
    };
    let layout = match size {
        0..=14 => Layout::Studio,
        15..=24 => Layout::OneAndHalf,
        25..=31 => Layout::TwoRooms,
        32..=39 => Layout::ThreeRooms,
        _ => Layout::FourPlus,
    };
    QuoteAnswers {
        cleaning_type: cleaning,
        luggage: *c.pick(&[LuggageState::Empty, LuggageState::PartlyUnpacked, LuggageState::FullyLivedIn, LuggageState::Unknown]),
        building: *c.pick(&[BuildingType::Apartment, BuildingType::Apartment, BuildingType::Apartment, BuildingType::Villa, BuildingType::Officetel]),
        layout,
        duplex: c.chance(0.1),
        bathrooms: c.range(1, 2) as u8,
        balconies: c.range(0, 2) as u8,
        elevator: c.chance(0.7),
        floor_3_or_higher: c.chance(0.5),
    }
}

/// Quote desk rows. An open quote gets three waiting bids. A chosen quote gets the winner (selected,
/// at the final price) and two rejected bids from other pros. `winner` is (pro index, final price).
async fn quotes(c: &mut Ctx<'_>, world: &World, booking: Uuid, service: &str, winner: Option<(usize, i64)>, estimate: i64, created: DateTime<Utc>) -> Result<(), DemoError> {
    let mut bidders: Vec<usize> = (0..world.pros.len())
        .filter(|&i| world.pros[i].verified && !world.pros[i].deleted && world.pros[i].services.contains(&service))
        .filter(|&i| winner.is_none_or(|(w, _)| i != w))
        .collect();
    bidders.shuffle(&mut c.rng);
    let (others, state) = if winner.is_some() { (2, "rejected") } else { (3, "waiting") };
    for &pi in bidders.iter().take(others) {
        let amount = (estimate + c.range(-2, 2) * 10_000).max(100);
        insert_quote(c, booking, world.pros[pi].id, amount, state, created).await?;
    }
    if let Some((pi, price)) = winner {
        insert_quote(c, booking, world.pros[pi].id, price, "selected", created).await?;
    }
    Ok(())
}

async fn insert_quote(c: &mut Ctx<'_>, booking: Uuid, pro: Uuid, amount: i64, state: &str, created: DateTime<Utc>) -> Result<(), DemoError> {
    let id = c.id();
    let note = *c.pick(&QUOTE_NOTES);
    let seen = c.chance(0.8);
    sqlx::query("INSERT INTO quotes (id, booking_id, pro_id, amount, note, state, seen_by_pro, created_at, updated_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8)")
        .bind(id)
        .bind(booking)
        .bind(pro)
        .bind(amount)
        .bind(note)
        .bind(state)
        .bind(seen)
        .bind(created + Duration::hours(1))
        .execute(&mut *c.tx)
        .await?;
    c.reg("quotes", id).await
}

/// Completed job: photo report, then the settlement row that the payout run works from.
#[allow(clippy::too_many_arguments)]
async fn completion(c: &mut Ctx<'_>, world: &World, pro: usize, booking: Uuid, done: DateTime<Utc>, gross: i64, balance_paid: bool, is_quote: bool) -> Result<(), DemoError> {
    let p = &world.pros[pro];
    let photo = photo_url(&c.public_base);
    sqlx::query("INSERT INTO completion_reports (booking_id, before_photos, after_photos, checklist, submitted_by, submitted_at) VALUES ($1,$2,$3,$4,$5,$6)")
        .bind(booking)
        .bind(vec![photo.clone()])
        .bind(vec![photo])
        .bind(json!([true, true, true, true]))
        .bind(p.id)
        .bind(done)
        .execute(&mut *c.tx)
        .await?;
    c.reg("completion_reports", booking).await?;

    let fee = p.fee_bps;
    let split = payout(Won(gross), fee);
    let done_day = done.with_timezone(&c.kst).date_naive();
    let due = payout_date(done_day);
    let today = c.now.with_timezone(&c.kst).date_naive();
    let (state, date, paid_at): (&str, Option<NaiveDate>, Option<DateTime<Utc>>) = if is_quote && !balance_paid {
        ("waiting_balance", None, None)
    } else if due <= today {
        ("paid", Some(due), Some(kst_at(c, due, 14).min(c.now)))
    } else {
        ("pending", Some(due), None)
    };
    let id = c.id();
    sqlx::query("INSERT INTO settlements (id, pro_id, booking_id, gross, fee, net, payout_date, state, paid_at, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)")
        .bind(id)
        .bind(p.id)
        .bind(booking)
        .bind(split.gross.0)
        .bind(split.fee.0)
        .bind(split.net.0)
        .bind(date)
        .bind(state)
        .bind(paid_at)
        .bind(done)
        .execute(&mut *c.tx)
        .await?;
    c.reg("settlements", id).await
}

/// Two completed jobs are held for a dispute; reviews come from about half the completed jobs.
async fn reviews_and_holds(c: &mut Ctx<'_>, world: &World, booked: &[BookingRec]) -> Result<(), DemoError> {
    for b in booked.iter().filter(|b| b.status == 3 && !b.is_quote).take(2) {
        sqlx::query("UPDATE settlements SET state = 'held' WHERE booking_id = $1").bind(b.id).execute(&mut *c.tx).await?;
    }
    for b in booked.iter().filter(|b| b.status == 3) {
        if !c.chance(0.55) {
            continue;
        }
        let (Some(pi), Some(done)) = (b.pro, b.completed) else { continue };
        let rating = *c.pick(&[5i16, 5, 5, 4, 4, 4, 3, 2]);
        let body = *c.pick(&REVIEWS);
        let at = (done + Duration::days(1)).min(c.now);
        sqlx::query("INSERT INTO reviews (booking_id, user_id, pro_id, rating, body, hidden, created_at) VALUES ($1,$2,$3,$4,$5,FALSE,$6)")
            .bind(b.id)
            .bind(world.customers[b.customer].id)
            .bind(world.pros[pi].id)
            .bind(rating)
            .bind(body)
            .bind(at)
            .execute(&mut *c.tx)
            .await?;
        c.reg("reviews", b.id).await?;
    }
    Ok(())
}
