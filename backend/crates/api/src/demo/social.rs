//! Conversations and what surrounds them: chat threads and messages (customer, partner and support),
//! notifications, push tokens, the staff audit log, console content and the placeholder upload row.
//! Nothing here calls SMS, push or chat providers: rows are written straight to the database.

use super::{Ctx, DemoError, bookings::BookingRec, people::World};
use chrono::{DateTime, Duration, Utc};
use serde_json::{Value, json};
use uuid::Uuid;

const CUSTOMER_LINES: [&str; 8] = [
    "내일 방문 전에 주차 가능한지 확인 부탁드려요.",
    "현관 비밀번호는 앱 메모에 적어 두었어요.",
    "베란다 창문 청소도 포함되나요?",
    "반려견이 한 마리 있는데 괜찮을까요?",
    "오후 2시로 시간을 바꿀 수 있을까요?",
    "작업 끝나면 사진 한 번 보내 주실 수 있나요?",
    "에어컨 필터도 같이 해 주시는 거죠?",
    "세제랑 수건은 따로 준비하지 않아도 되죠?",
];
const STAFF_LINES: [&str; 6] = [
    "네, 확인했어요. 배정된 팀이 전날 연락드릴 거예요.",
    "주차는 단지 방문자 주차장 이용하시면 됩니다.",
    "반려동물 있는 집도 괜찮아요. 방문 시 알려 주세요.",
    "베란다 청소는 기본 포함이에요.",
    "세제와 도구는 저희가 가져가니 준비하지 않으셔도 돼요.",
    "작업 사진은 완료 후 앱에서 확인하실 수 있어요.",
];
const PARTNER_LINES: [&str; 4] = [
    "안녕하세요, 배정된 팀입니다. 방문 전날 연락드릴게요.",
    "현관 출입 방법과 주차 위치 알려주실 수 있을까요?",
    "방문해 보니 욕실 줄눈 보수가 추가로 필요해 보여요. 상담 부탁드려요.",
    "청소 마쳤고 완료 사진 올려 두었습니다.",
];
const DESK_LINES: [&str; 2] = [
    "고객 요청 사항 전달했어요. 방문 시간 꼭 지켜 주세요.",
    "네, 확인했습니다. 추가 작업 견적은 고객과 상의해서 안내드릴게요.",
];
const OPS_TOPICS: [&str; 3] = ["정산 문의", "팀원 추가 요청", "출입 정보 수정"];
const OPS_LINES: [&str; 3] = [
    "지난주 정산 내역이 맞는지 확인하고 싶어요.",
    "확인해 보니 이번 주 목요일에 지급 예정이에요.",
    "팀원 한 명 더 초대했는데 상태가 아직 '초대됨'이에요.",
];
const SUPPORT_TOPICS: [&str; 5] = ["쿠폰 사용 문의", "영수증 요청", "예약 변경 문의", "서비스 후기 문의", "결제 수단 변경"];
const AUDIT_ACTIONS: [&str; 8] = [
    "pro.approve",
    "pro.suspend",
    "booking.assign",
    "booking.cancel",
    "settlement.payout",
    "content.create",
    "coupon.issue",
    "staff.create",
];

/// A chat message before it is written. Times are explicit so each thread reads in order.
struct Msg {
    sender: &'static str,
    sender_id: Option<Uuid>,
    kind: &'static str,
    body: Value,
    at: DateTime<Utc>,
}

struct Thread {
    audience: &'static str,
    user: Option<Uuid>,
    pro: Option<Uuid>,
    booking: Option<Uuid>,
    topic: String,
    closed: bool,
}

pub async fn run(c: &mut Ctx<'_>, world: &World, booked: &[BookingRec]) -> Result<(), DemoError> {
    let today = c.now.with_timezone(&c.kst).date_naive();
    for b in booked {
        let closed = b.status == 3 && (today - b.visit).num_days() > 7;
        if c.chance(0.8) {
            customer_thread(c, world, b, closed).await?;
        }
        if let Some(pi) = b.pro {
            partner_thread(c, world, b, pi, closed).await?;
        }
    }
    support_threads(c, world).await?;
    ops_threads(c, world).await?;
    notifications(c, world, booked).await?;
    push_tokens(c, world).await?;
    audit(c, world, booked).await?;
    content(c).await?;
    upload(c, world).await
}

fn card(b: &BookingRec, at: DateTime<Utc>) -> Msg {
    let body = json!({
        "booking_id": b.id, "service_code": b.service, "visit_date": b.visit, "start_hour": b.start_hour,
        "answers": b.answers, "estimate": b.estimate,
    });
    Msg { sender: "system", sender_id: None, kind: "card", body, at }
}

fn text(sender: &'static str, sender_id: Option<Uuid>, line: &str, at: DateTime<Utc>) -> Msg {
    Msg { sender, sender_id, kind: "text", body: json!({ "text": line }), at }
}

fn system(code: &str, params: Value, at: DateTime<Utc>) -> Msg {
    Msg { sender: "system", sender_id: None, kind: "system", body: json!({ "code": code, "params": params }), at }
}

/// Customer-side thread of a booking: the card, quote and deposit steps, questions and the close-out.
async fn customer_thread(c: &mut Ctx<'_>, world: &World, b: &BookingRec, closed: bool) -> Result<(), DemoError> {
    let mut at = b.created + Duration::minutes(10);
    let mut msgs = vec![card(b, at)];
    let user = world.customers[b.customer].id;
    if let (true, Some(final_price), Some(deposit)) = (b.is_quote, b.final_price, b.deposit) {
        at += Duration::minutes(30);
        let note = "평수와 짐 상태를 반영한 견적이에요.";
        let body = json!({ "booking_id": b.id, "final_price": final_price, "deposit": deposit, "balance": final_price - deposit, "note": note });
        msgs.push(Msg { sender: "staff", sender_id: Some(world.consultant), kind: "quote", body, at });
        at += Duration::minutes(30);
        msgs.push(text("customer", Some(user), "견적 확인했어요. 보증금 결제할게요.", at));
        msgs.push(system("deposit_paid", json!({}), at + Duration::minutes(2)));
    }
    for n in 0..c.range(1, 2) as usize {
        at += Duration::minutes(40);
        msgs.push(text("customer", Some(user), CUSTOMER_LINES[(n + b.customer) % CUSTOMER_LINES.len()], at));
        at += Duration::minutes(15);
        msgs.push(text("staff", Some(world.consultant), STAFF_LINES[(n + b.customer) % STAFF_LINES.len()], at));
    }
    match b.status {
        3 => msgs.push(system("job_completed", json!({}), b.completed.unwrap_or(at) + Duration::minutes(5))),
        -1 => msgs.push(system("booking_cancelled", json!({ "by": "customer", "refunded": b.refunded }), b.cancelled.unwrap_or(at))),
        _ => {}
    }
    let thread = Thread { audience: "customer", user: Some(user), pro: None, booking: Some(b.id), topic: b.service.to_string(), closed };
    save_thread(c, thread, msgs).await
}

/// Partner-side thread: the team asks questions, the desk answers, completion is posted.
async fn partner_thread(c: &mut Ctx<'_>, world: &World, b: &BookingRec, pi: usize, closed: bool) -> Result<(), DemoError> {
    let pro = &world.pros[pi];
    let mut at = b.created + Duration::hours(3);
    let mut msgs = vec![card(b, at)];
    msgs.push(text("partner", Some(pro.id), PARTNER_LINES[0], at + Duration::minutes(5)));
    at += Duration::minutes(20);
    msgs.push(text("partner", Some(pro.id), PARTNER_LINES[1], at));
    at += Duration::minutes(20);
    msgs.push(text("staff", Some(world.admin), DESK_LINES[0], at));
    if b.status == 3 {
        let done = b.completed.unwrap_or(at);
        msgs.push(text("partner", Some(pro.id), PARTNER_LINES[3], done - Duration::minutes(10)));
        msgs.push(system("job_completed", json!({}), done));
    } else if c.chance(0.3) {
        msgs.push(text("partner", Some(pro.id), PARTNER_LINES[2], at + Duration::hours(1)));
        msgs.push(text("staff", Some(world.admin), DESK_LINES[1], at + Duration::hours(2)));
    }
    let thread = Thread { audience: "partner", user: None, pro: Some(pro.id), booking: Some(b.id), topic: b.service.to_string(), closed };
    save_thread(c, thread, msgs).await
}

/// Customer support inbox: no booking attached, a question and an answer, sometimes a follow-up.
async fn support_threads(c: &mut Ctx<'_>, world: &World) -> Result<(), DemoError> {
    for i in 0..8 {
        let cust = &world.customers[i * 4];
        let start = c.now - Duration::days(12 - i as i64);
        let mut msgs = vec![
            text("customer", Some(cust.id), CUSTOMER_LINES[i], start),
            text("staff", Some(world.consultant), STAFF_LINES[i % STAFF_LINES.len()], start + Duration::hours(2)),
        ];
        if i % 2 == 0 {
            msgs.push(text("customer", Some(cust.id), "그럼 그렇게 진행해 주세요. 감사합니다!", start + Duration::hours(5)));
        }
        let thread = Thread { audience: "customer", user: Some(cust.id), pro: None, booking: None, topic: SUPPORT_TOPICS[i % SUPPORT_TOPICS.len()].to_string(), closed: i > 5 };
        save_thread(c, thread, msgs).await?;
    }
    Ok(())
}

/// Partner ops inbox: settlement and team questions, answered by staff.
async fn ops_threads(c: &mut Ctx<'_>, world: &World) -> Result<(), DemoError> {
    for (i, pi) in [0usize, 3, 6].into_iter().enumerate() {
        let pro = &world.pros[pi];
        let start = c.now - Duration::days(4 + i as i64 * 3);
        let msgs = vec![
            text("partner", Some(pro.id), OPS_LINES[0], start),
            text("staff", Some(world.consultant), OPS_LINES[1], start + Duration::hours(3)),
            text("partner", Some(pro.id), OPS_LINES[2], start + Duration::hours(6)),
        ];
        let thread = Thread { audience: "partner", user: None, pro: Some(pro.id), booking: None, topic: OPS_TOPICS[i].to_string(), closed: false };
        save_thread(c, thread, msgs).await?;
    }
    Ok(())
}

/// Writes one thread and its messages. Unread counters follow the last sender, like the live API.
async fn save_thread(c: &mut Ctx<'_>, th: Thread, msgs: Vec<Msg>) -> Result<(), DemoError> {
    let (Some(first), Some(last)) = (msgs.first().map(|m| m.at), msgs.last()) else { return Ok(()) };
    let last_at = last.at;
    let unread_staff = i32::from(matches!(last.sender, "customer" | "partner"));
    let unread_member = i32::from(last.sender == "staff");
    let id = c.id();
    sqlx::query(
        "INSERT INTO chat_threads (id, audience, user_id, pro_id, booking_id, topic, unread_member, unread_staff, closed, last_message_at, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)",
    )
    .bind(id)
    .bind(th.audience)
    .bind(th.user)
    .bind(th.pro)
    .bind(th.booking)
    .bind(&th.topic)
    .bind(unread_member)
    .bind(unread_staff)
    .bind(th.closed)
    .bind(last_at)
    .bind(first)
    .execute(&mut *c.tx)
    .await?;
    c.reg("chat_threads", id).await?;
    for m in msgs {
        let mid = c.id();
        sqlx::query("INSERT INTO chat_messages (id, thread_id, sender, sender_id, kind, body, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7)")
            .bind(mid)
            .bind(id)
            .bind(m.sender)
            .bind(m.sender_id)
            .bind(m.kind)
            .bind(&m.body)
            .bind(m.at)
            .execute(&mut *c.tx)
            .await?;
        c.reg("chat_messages", mid).await?;
    }
    Ok(())
}

/// Customers hear about cancellations; pros hear about every job they are assigned; verified pros get a status note.
async fn notifications(c: &mut Ctx<'_>, world: &World, booked: &[BookingRec]) -> Result<(), DemoError> {
    for b in booked {
        if let (-1, Some(at)) = (b.status, b.cancelled) {
            let data = json!({ "booking_id": b.id, "number": b.number });
            notify(c, "customer", world.customers[b.customer].id, "booking.cancelled", data, at).await?;
        }
        if let Some(pi) = b.pro {
            let data = json!({ "booking_id": b.id, "number": b.number });
            let at = b.created + Duration::hours(2);
            notify(c, "pro", world.pros[pi].id, "job.updated", data, at).await?;
        }
    }
    for pro in world.pros.iter().filter(|p| p.verified && !p.deleted) {
        notify(c, "pro", pro.id, "pro.status", json!({ "status": "verified" }), c.now - Duration::days(60)).await?;
    }
    Ok(())
}

async fn notify(c: &mut Ctx<'_>, role: &str, owner: Uuid, kind: &str, data: Value, at: DateTime<Utc>) -> Result<(), DemoError> {
    let id = c.id();
    // Roughly two in three are read, and read ones were read a little after they arrived.
    let read_at = c.chance(0.66).then(|| (at + Duration::hours(3)).min(c.now));
    sqlx::query("INSERT INTO notifications (id, owner_role, owner_id, kind, data, read_at, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7)")
        .bind(id)
        .bind(role)
        .bind(owner)
        .bind(kind)
        .bind(&data)
        .bind(read_at)
        .bind(at)
        .execute(&mut *c.tx)
        .await?;
    c.reg("notifications", id).await
}

/// Fake device tokens for some customers and every verified pro. They never receive a push.
async fn push_tokens(c: &mut Ctx<'_>, world: &World) -> Result<(), DemoError> {
    let customers = world.customers.iter().enumerate().filter(|(i, _)| i % 5 != 0).map(|(i, cu)| ("customer", cu.id, i));
    let pros = world.pros.iter().filter(|p| p.verified && !p.deleted).map(|p| ("pro", p.id, 0));
    for (role, owner, i) in customers.chain(pros).collect::<Vec<_>>() {
        let token = format!("demo_fcm_{}", c.hex(16));
        let platform = if i % 2 == 0 { "ios" } else { "android" };
        sqlx::query("INSERT INTO push_tokens (token, owner_role, owner_id, platform, updated_at) VALUES ($1,$2,$3,$4,$5)")
            .bind(&token)
            .bind(role)
            .bind(owner)
            .bind(platform)
            .bind(c.now)
            .execute(&mut *c.tx)
            .await?;
        c.reg("push_tokens", &token).await?;
    }
    Ok(())
}

/// Staff actions, newest last. Targets point at real demo rows so the console links work.
async fn audit(c: &mut Ctx<'_>, world: &World, booked: &[BookingRec]) -> Result<(), DemoError> {
    for i in 0..24usize {
        let action = AUDIT_ACTIONS[i % AUDIT_ACTIONS.len()];
        let target = match action {
            "booking.assign" | "booking.cancel" => booked[i % booked.len()].id.to_string(),
            "pro.approve" | "pro.suspend" | "settlement.payout" => world.pros[i % world.pros.len()].id.to_string(),
            "coupon.issue" => "autumn-2026".to_string(),
            "staff.create" => world.consultant.to_string(),
            _ => format!("content-{i}"),
        };
        let at = c.now - Duration::hours(6 * (i as i64 + 1));
        let row: i64 = sqlx::query_scalar(
            "INSERT INTO audit_log (actor_role, actor_id, action, target, data, created_at) VALUES ('staff', $1, $2, $3, $4, $5) RETURNING id",
        )
        .bind(world.admin)
        .bind(action)
        .bind(&target)
        .bind(json!({ "note": "샘플 데이터" }))
        .bind(at)
        .fetch_one(&mut *c.tx)
        .await?;
        c.reg("audit_log", row).await?;
    }
    Ok(())
}

/// Console content: banners, news, notices, tips, FAQ and two legal pages. Made-up but realistic copy
/// for the home screen (banner, recommendation, news, tips); notices, FAQ and legal say "(샘플)".
async fn content(c: &mut Ctx<'_>) -> Result<(), DemoError> {
    // The first banner without a service link is the home hero; `service/<code>` makes a recommendation.
    let banners = [
        (json!({"ko": "첫 청소 15,000원 웰컴쿠폰", "en": "₩15,000 welcome coupon for your first clean"}), json!({"theme": "sun"}), Some("coupons")),
        (
            json!({"ko": "입주 청소, 이사 전 청소까지 한 번에", "en": "Move-in cleaning, including the pre-move-out clean"}),
            json!({"text": {"ko": "나가는 집과 들어가는 집을 함께 맡기면 일정을 한 번에 맞춰 드려요.", "en": "Book both homes together and we line up the two visits for you."}}),
            Some("service/move_in"),
        ),
        (json!({"ko": "파트너 모집 중", "en": "Partners wanted"}), json!({"theme": "sun"}), Some("partner")),
    ];
    for (i, (title, body, link)) in banners.into_iter().enumerate() {
        insert_content(c, "banner", None, title, body, link, i as i32).await?;
    }
    let news = [
        (json!({"ko": "원룸 청소 서비스 지역 확대", "en": "Studio cleaning now covers more areas"}), "이번 달부터 성남시 분당구와 하남시에서도 원룸 청소를 예약할 수 있어요. 주소를 등록하면 예약 가능 여부를 바로 알려 드려요."),
        (json!({"ko": "2in1 에어컨 청소 예약 오픈", "en": "2-in-1 aircon cleaning is open for booking"}), "스탠드와 벽걸이를 한 번에 청소하는 2in1 상품을 예약할 수 있어요. 분해 세척과 살균까지 포함돼요."),
        (json!({"ko": "상담 운영 시간 안내", "en": "Consultation hours"}), "상담은 평일 09:00~18:00에 운영해요. 보통 10분 안에 답변드려요."),
    ];
    for (i, (title, text)) in news.into_iter().enumerate() {
        insert_content(c, "news", None, title, json!({ "text": { "ko": text } }), None, i as i32).await?;
    }
    let notices = [
        (json!({"ko": "(샘플) 11월 정기 점검 안내", "en": "(sample) November maintenance"}), "11월 15일 새벽 2시부터 30분간 예약 시스템을 점검해요."),
        (json!({"ko": "(샘플) 연말 운영 시간 안내", "en": "(sample) Year-end opening hours"}), "12월 31일은 오후 4시까지 상담을 받아요."),
    ];
    for (i, (title, text)) in notices.into_iter().enumerate() {
        insert_content(c, "notice", None, title, json!({ "text": { "ko": text } }), None, i as i32).await?;
    }
    let tips = [
        (json!({"ko": "에어컨 냄새의 원인은?", "en": "What causes aircon odours?"}), "냉각핀에 남은 물기에 곰팡이가 자라면 쉰 냄새가 나요. 끄기 전 10분간 송풍으로 말리고, 필터는 2주에 한 번 씻어 주세요."),
        (json!({"ko": "에어컨 필터 청소 주기", "en": "How often to clean the aircon filter"}), "두세 달에 한 번 물로 헹구면 냄새와 전기료를 함께 줄일 수 있어요."),
        (json!({"ko": "욕실 물때 없애는 법", "en": "Removing bathroom limescale"}), "식초 물을 뿌리고 10분 뒤 헹구면 대부분 지워져요."),
        (json!({"ko": "이사 전 체크리스트", "en": "Move-out checklist"}), "보관 상자, 가전 분리, 가스·전기 정산일을 미리 적어 두세요."),
    ];
    for (i, (title, text)) in tips.into_iter().enumerate() {
        insert_content(c, "tip", None, title, json!({ "text": { "ko": text } }), None, i as i32).await?;
    }
    let faqs = [
        (json!({"ko": "(샘플) 취소는 언제까지 무료인가요?", "en": "(sample) Until when can I cancel for free?"}), "방문 2일 전까지 무료로 취소할 수 있어요."),
        (json!({"ko": "(샘플) 견적은 어떻게 정해지나요?", "en": "(sample) How is a quote decided?"}), "평수와 짐 상태를 반영해 먼저 예상 금액을 드리고, 방문 전 파트너가 최종 견적을 보내요."),
        (json!({"ko": "(샘플) 정산은 언제 받나요?", "en": "(sample) When are payouts made?"}), "작업이 끝나면 다음 주 정기 지급일에 입금돼요."),
    ];
    for (i, (title, text)) in faqs.into_iter().enumerate() {
        insert_content(c, "faq", None, title, json!({ "text": { "ko": text } }), None, i as i32).await?;
    }
    let legal = [
        ("terms", json!({"ko": "(샘플) 이용약관", "en": "(sample) Terms of service"})),
        ("privacy", json!({"ko": "(샘플) 개인정보 처리방침", "en": "(sample) Privacy policy"})),
    ];
    for (i, (slug, title)) in legal.into_iter().enumerate() {
        let body = json!({ "text": { "ko": "샘플 문서입니다. 실제 서비스 전에 반드시 법률 검토를 받으세요." } });
        insert_content(c, "legal", Some(slug), title, body, None, i as i32).await?;
    }
    Ok(())
}

async fn insert_content(c: &mut Ctx<'_>, kind: &str, slug: Option<&str>, title: Value, body: Value, link: Option<&str>, sort: i32) -> Result<(), DemoError> {
    let id = c.id();
    sqlx::query("INSERT INTO content_items (id, kind, slug, title, body, link, sort_order, active) VALUES ($1,$2,$3,$4,$5,$6,$7,TRUE)")
        .bind(id)
        .bind(kind)
        .bind(slug)
        .bind(&title)
        .bind(&body)
        .bind(link)
        .bind(sort)
        .execute(&mut *c.tx)
        .await?;
    c.reg("content_items", id).await
}

/// One row for the placeholder photo file that completion reports point at.
async fn upload(c: &mut Ctx<'_>, world: &World) -> Result<(), DemoError> {
    let id = c.id();
    let bytes = super::placeholder_bytes().len() as i64;
    sqlx::query("INSERT INTO uploads (id, owner_role, owner_id, file, bytes) VALUES ($1,'staff',$2,$3,$4)")
        .bind(id)
        .bind(world.consultant)
        .bind(super::PLACEHOLDER_FILE)
        .bind(bytes)
        .execute(&mut *c.tx)
        .await?;
    c.reg("uploads", id).await
}
