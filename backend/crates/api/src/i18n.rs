//! Server-sent text (push, inbox, SMS) in the recipient's language.
//!
//! Call sites keep writing the Korean source text; [`tr`] looks it up here. Unknown text (booking
//! numbers, amounts, chat previews) passes through unchanged. AlimTalk keeps Korean: its templates
//! are pre-approved word for word.

use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;

use crate::realtime::Recipient;

// i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
/// Korean source -> English. Status codes are keys too (body of pro.status).
const TABLE: &[(&str, &str)] = &[
    ("계정 상태", "Account status"),
    ("verified", "Your account is approved"),
    ("suspended", "Your account is suspended"),
    ("pending", "Your account is under review"),
    ("정산 완료", "Payout sent"),
    ("견적 요청", "New quote request"),
    ("예약 취소", "Booking cancelled"),
    ("예약이 취소됐어요", "Your booking was cancelled"),
    ("일정 변경 요청", "Reschedule request"),
    ("견적이 선택됐어요", "Your quote was accepted"),
    ("예약금 결제", "Pay the deposit"),
    ("새 예약", "New booking"),
    ("상담팀", "Support team"),
    ("청소가 끝났어요", "Cleaning is done"),
    (
        "전후 사진을 확인하고 후기를 남겨 주세요",
        "Check the before and after photos and leave a review",
    ),
    ("청소팀이 도착했어요", "The cleaning team has arrived"),
    ("결제가 완료됐어요", "Payment complete"),
    (
        "결제 내역은 예약 상세에서 확인할 수 있어요",
        "You can check the payment details in your booking",
    ),
    ("예약 상태가 바뀌었어요", "Your booking status changed"),
    ("결제가 자동으로 취소됐어요", "Your payment was cancelled automatically"),
    ("예약 조건이 바뀌어 결제 금액을 환불했어요", "The booking changed, so we refunded your payment"),
    ("결제 취소를 진행하고 있어요", "We're cancelling your payment"),
    (
        "예약 조건이 바뀌어 결제 금액을 환불하고 있어요. 환불이 끝나면 알려드릴게요",
        "The booking changed, so we're refunding your payment. We'll let you know once it's done",
    ),
    ("청소팀이 배정됐어요", "Your cleaning team is assigned"),
    ("새 작업이 배정됐어요", "You have a new job"),
    ("앱에서 일정과 주소를 확인하세요", "Check the time and address in the app"),
    ("변경된 일정이 확정됐어요", "Your new schedule is confirmed"),
    ("인증번호", "Verification code"),
    (
        "팀원으로 초대됐어요. 파트너 앱을 설치해 주세요.",
        "You were invited to a cleaning team. Please install the partner app.",
    ),
    ("내일 청소 예정이에요", "Your cleaning is tomorrow"),
    ("다음 청소를 예약해 보세요", "Book your next cleaning"),
    ("지난번과 같은 조건으로 빠르게 예약할 수 있어요", "Rebook with the same settings in a few taps"),
    ("견적 요청이 아직 남아 있어요", "Your quote request is still open"),
    ("원하는 시간에 청소팀을 바로 받아 보세요", "Get a cleaning team quote for your time slot"),
    ("도착 확인 없음", "No arrival check-in"),
    ("배정이 변경됐어요", "Your assignment changed"),
    ("새 현장이 배정됐어요", "You have a new job site"),
    ("청소팀이 변경됐어요", "Your cleaning team changed"),
    (
        "불편을 드려 죄송합니다. 다른 청소팀이 배정됐어요.",
        "Sorry for the trouble. A different cleaning team is assigned.",
    ),
    ("품질 점수가 낮아졌어요", "Your quality score dropped"),
    ("품질 점수를 확인하고 개선해 주세요.", "Check your quality score and how to improve it."),
    ("정기 청소가 일시 정지됐어요", "Your regular cleaning is paused"),
    ("결제 수단을 확인한 뒤 재개해 주세요", "Check your payment method, then resume it"),
    ("정기 청소 결제가 실패했어요", "Your regular cleaning payment failed"),
    ("카드 정보를 확인해 주세요", "Please check your card details"),
    ("이번 정기 청소를 잡지 못했어요", "We couldn't book this regular cleaning"),
    ("고객센터로 문의해 주세요", "Please contact customer support"),
    ("빈 자리가 생겼어요", "A slot opened up"),
    ("15분 안에 예약을 확정해 주세요.", "Confirm your booking within 15 minutes."),
];

/// Korean text for status-code keys, which aren't Korean themselves.
fn korean_for_code(key: &str) -> Option<&'static str> {
    match key {
        "verified" => Some("계정이 승인됐어요"),
        "suspended" => Some("계정이 일시 중지됐어요"),
        "pending" => Some("계정을 검토하고 있어요"),
        _ => None,
    }
}

/// The language server text goes out in: Korean for "ko", English for every other locale,
/// including one stored before its language was archived.
pub fn shipped(locale: &str) -> &'static str {
    if locale == "ko" { "ko" } else { "en" }
}

/// `source` in `locale` (see [`shipped`]); unknown text is returned as is.
pub fn tr(locale: &str, source: &str) -> String {
    if shipped(locale) == "ko" {
        return korean_for_code(source).unwrap_or(source).to_string();
    }
    TABLE
        .iter()
        .find(|(ko, _)| *ko == source)
        .map(|(_, en)| en.to_string())
        .unwrap_or_else(|| source.to_string())
}

/// The recipient's account language ([`shipped`]); staff read Korean. Team members follow their team owner.
pub async fn locale_of(db: &PgPool, to: Recipient) -> String {
    let q = match to {
        Recipient::User(_) => "SELECT locale FROM users WHERE id = $1",
        Recipient::Pro(_) => "SELECT locale FROM pros WHERE id = $1",
        Recipient::Member(_) => "SELECT p.locale FROM team_members m JOIN pros p ON p.id = m.pro_id WHERE m.id = $1",
        Recipient::Staff => return "ko".into(),
    };
    let id: Uuid = match to {
        Recipient::User(id) | Recipient::Pro(id) | Recipient::Member(id) => id,
        Recipient::Staff => unreachable!(),
    };
    match sqlx::query_scalar::<_, String>(q).bind(id).fetch_optional(db).await {
        Ok(l) => shipped(l.as_deref().unwrap_or("ko")).into(),
        Err(e) => {
            tracing::warn!(error = %e, "locale lookup failed; using Korean");
            "ko".into()
        }
    }
}

/// A notification whose text the owner may replace. Only kinds with one call site and one text are
/// listed, so an override never changes another message that shares the kind.
pub struct Event {
    pub kind: &'static str,
    pub label: &'static str,
    /// Built-in Korean text, also the editor's starting point.
    pub title: &'static str,
    pub body: &'static str,
    /// Placeholders the text may use. Each resolves from the event's own data.
    pub vars: &'static [&'static str],
}

pub const BOOKING_NO: &str = "예약번호";
pub const BRAND: &str = "업체명";
/// Stands in for a real booking number in previews and checks.
pub const SAMPLE_BOOKING_NO: &str = "B-20261111-0042";
const BOOKING_BODY: &str = "{예약번호}";
const BOOKING_VARS: &[&str] = &[BOOKING_NO];

pub const EVENTS: &[Event] = &[
    Event {
        kind: "booking.created",
        label: "새 예약 (직원)",
        title: "새 예약",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "booking.quote_requested",
        label: "견적 요청 (직원)",
        title: "견적 요청",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "booking.deposit_paid",
        label: "예약금 결제 (직원)",
        title: "예약금 결제",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "booking.cancelled",
        label: "예약 취소 (고객)",
        title: "예약이 취소됐어요",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "booking.arrival",
        label: "청소팀 도착 (고객)",
        title: "청소팀이 도착했어요",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "booking.completed",
        label: "청소 완료 (고객)",
        title: "청소가 끝났어요",
        body: "전후 사진을 확인하고 후기를 남겨 주세요",
        vars: &[BOOKING_NO, BRAND],
    },
    Event {
        kind: "booking.reschedule_confirmed",
        label: "일정 변경 확정 (고객)",
        title: "변경된 일정이 확정됐어요",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "payment.receipt",
        label: "결제 완료 (고객)",
        title: "결제가 완료됐어요",
        body: "결제 내역은 예약 상세에서 확인할 수 있어요",
        vars: &[],
    },
    Event {
        kind: "job.cancelled",
        label: "예약 취소 (청소팀)",
        title: "예약 취소",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "job.reschedule_requested",
        label: "일정 변경 요청 (청소팀)",
        title: "일정 변경 요청",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "quote.selected",
        label: "견적 선택 (청소팀)",
        title: "견적이 선택됐어요",
        body: BOOKING_BODY,
        vars: BOOKING_VARS,
    },
    Event {
        kind: "quality.warning",
        label: "품질 점수 경고 (청소팀)",
        title: "품질 점수가 낮아졌어요",
        body: "품질 점수를 확인하고 개선해 주세요.",
        vars: &[],
    },
    Event {
        kind: "subscription.paused",
        label: "정기 청소 일시 정지 (고객)",
        title: "정기 청소가 일시 정지됐어요",
        body: "결제 수단을 확인한 뒤 재개해 주세요",
        vars: &[],
    },
    Event {
        kind: "subscription.payment_failed",
        label: "정기 청소 결제 실패 (고객)",
        title: "정기 청소 결제가 실패했어요",
        body: "카드 정보를 확인해 주세요",
        vars: &[],
    },
    Event {
        kind: "subscription.visit_missed",
        label: "정기 청소 미배정 (고객)",
        title: "이번 정기 청소를 잡지 못했어요",
        body: "고객센터로 문의해 주세요",
        vars: &[],
    },
    Event {
        kind: "subscription.visit_moved",
        label: "정기 청소 시간 변경 (고객)",
        title: "정기 청소 시간이 바뀌었어요",
        body: "요청하신 시간이 가득 차 가까운 시간으로 옮겼어요",
        vars: &[],
    },
    Event {
        kind: "subscription.visit_unplaced",
        label: "정기 청소 시간 미배정 (고객)",
        title: "정기 청소 시간을 잡지 못했어요",
        body: "고객센터로 문의해 주세요",
        vars: &[],
    },
    Event {
        kind: "subscription.capacity_full",
        label: "정기 청소 정원 초과 (직원)",
        title: "정기 청소 정원이 가득 찼어요",
        body: "배정 시간을 확인해 주세요",
        vars: &[],
    },
    Event {
        kind: "waitlist.offer",
        label: "빈 자리 안내 (고객)",
        title: "빈 자리가 생겼어요",
        body: "15분 안에 예약을 확정해 주세요.",
        vars: &[BRAND],
    },
];

pub fn event(kind: &str) -> Option<&'static Event> {
    EVENTS.iter().find(|e| e.kind == kind)
}

/// The built-in text in `locale`: what the editor starts from and what reset returns to.
pub fn default_text(ev: &Event, locale: &str) -> (String, String) {
    (tr(locale, ev.title), tr(locale, ev.body))
}

#[derive(Debug, PartialEq, Eq)]
pub enum TemplateError {
    /// A brace is unclosed, stray or nested.
    Unbalanced,
    /// A `{name}` the event does not allow.
    UnknownVariable(String),
}

impl TemplateError {
    /// Stable code for API error responses.
    pub fn code(&self) -> &'static str {
        match self {
            Self::Unbalanced => "unbalanced_braces",
            Self::UnknownVariable(_) => "unknown_variable",
        }
    }
}

/// `template` with each `{name}` replaced by its value. A name without a value is an error.
pub fn fill(template: &str, values: &[(&str, String)]) -> Result<String, TemplateError> {
    let mut out = String::with_capacity(template.len());
    let mut rest = template;
    while let Some(open) = rest.find(['{', '}']) {
        if rest.as_bytes()[open] == b'}' {
            return Err(TemplateError::Unbalanced);
        }
        let close = rest[open..].find('}').ok_or(TemplateError::Unbalanced)? + open;
        let name = &rest[open + 1..close];
        if name.contains('{') {
            return Err(TemplateError::Unbalanced);
        }
        let (_, value) = values
            .iter()
            .find(|(key, _)| *key == name)
            .ok_or_else(|| TemplateError::UnknownVariable(name.to_string()))?;
        out.push_str(&rest[..open]);
        out.push_str(value);
        rest = &rest[close + 1..];
    }
    out.push_str(rest);
    Ok(out)
}

/// Stand-in values for an event's placeholders: a sample booking number and the business name.
pub fn sample_values(vars: &[&'static str], brand: &str) -> Vec<(&'static str, String)> {
    vars.iter()
        .map(|&name| match name {
            BRAND => (name, brand.to_string()),
            _ => (name, SAMPLE_BOOKING_NO.to_string()),
        })
        .collect()
}

/// Real values for an event's placeholders. `None` when the booking they need cannot be found.
async fn live_values(db: &PgPool, vars: &[&'static str], booking: Option<Uuid>) -> sqlx::Result<Option<Vec<(&'static str, String)>>> {
    let mut out = Vec::with_capacity(vars.len());
    for &name in vars {
        if name == BRAND {
            out.push((name, crate::routes::setup::brand_name(db).await));
            continue;
        }
        let Some(id) = booking else {
            return Ok(None);
        };
        let number: Option<String> = sqlx::query_scalar("SELECT number FROM bookings WHERE id = $1")
            .bind(id)
            .fetch_optional(db)
            .await?;
        let Some(number) = number else {
            return Ok(None);
        };
        out.push((name, number));
    }
    Ok(Some(out))
}

/// The owner's text filled with `values`, or the built-in text when there is none or it does not fill.
pub fn pick(custom: Option<(&str, &str)>, values: &[(&str, String)], built_in: (String, String)) -> (String, String) {
    let Some((title, body)) = custom else {
        return built_in;
    };
    match (fill(title, values), fill(body, values)) {
        (Ok(title), Ok(body)) => (title, body),
        (Err(e), _) | (_, Err(e)) => {
            tracing::warn!(error = ?e, "notification text override does not fill; using built-in text");
            built_in
        }
    }
}

/// Inbox and push text for a notification of `kind`: the owner's text in the recipient's language when set,
/// else the built-in text. AlimTalk does not use this; its templates are approved word for word.
pub async fn notice(db: &PgPool, locale: &str, kind: &str, title: &str, body: &str, data: &Value) -> (String, String) {
    let built_in = (tr(locale, title), tr(locale, body));
    let Some(ev) = event(kind) else {
        return built_in;
    };
    let saved = sqlx::query_as::<_, (String, String)>("SELECT title, body FROM notify_templates WHERE kind = $1 AND locale = $2")
        .bind(ev.kind)
        .bind(shipped(locale))
        .fetch_optional(db)
        .await;
    let custom = match saved {
        Ok(row) => row,
        Err(e) => {
            tracing::warn!(error = %e, kind, "notification text lookup failed; using built-in text");
            return built_in;
        }
    };
    let Some((title, body)) = custom else {
        return built_in;
    };
    let booking = data.get("booking_id").and_then(Value::as_str).and_then(|s| Uuid::parse_str(s).ok());
    match live_values(db, ev.vars, booking).await {
        Ok(Some(values)) => pick(Some((&title, &body)), &values, built_in),
        Ok(None) => {
            tracing::warn!(kind, "notification placeholder has no value; using built-in text");
            built_in
        }
        Err(e) => {
            tracing::warn!(error = %e, kind, "notification placeholder lookup failed; using built-in text");
            built_in
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fill_replaces_allowed_placeholders() {
        let values = [(BOOKING_NO, "B-1".to_string())];
        assert_eq!(fill("예약 {예약번호} 확인", &values).unwrap(), "예약 B-1 확인");
        assert_eq!(fill("placeholder-free", &values).unwrap(), "placeholder-free");
    }

    #[test]
    fn fill_rejects_unknown_variable_and_broken_braces() {
        let values = [(BOOKING_NO, "B-1".to_string())];
        assert_eq!(fill("{이름}님", &values), Err(TemplateError::UnknownVariable("이름".into())));
        assert_eq!(fill("{예약번호", &values), Err(TemplateError::Unbalanced));
        assert_eq!(fill("예약번호}", &values), Err(TemplateError::Unbalanced));
        assert_eq!(fill("{{예약번호}}", &values), Err(TemplateError::Unbalanced));
    }

    #[test]
    fn unusable_override_falls_back_to_built_in_text() {
        let built_in = ("새 예약".to_string(), "B-2".to_string());
        let values = [(BOOKING_NO, "B-2".to_string())];
        assert_eq!(pick(Some(("{이름}", "ok")), &values, built_in.clone()), built_in);
        assert_eq!(pick(None, &values, built_in.clone()), built_in);
        assert_eq!(
            pick(Some(("안내", "{예약번호} 확인")), &values, built_in.clone()),
            ("안내".into(), "B-2 확인".into())
        );
    }

    #[test]
    fn every_event_default_fills_with_its_own_placeholders() {
        let mut kinds = std::collections::HashSet::new();
        for ev in EVENTS {
            assert!(kinds.insert(ev.kind), "duplicate kind {}", ev.kind);
            let samples = sample_values(ev.vars, "다해");
            let (title, body) = default_text(ev, "ko");
            assert!(fill(&title, &samples).is_ok() && fill(&body, &samples).is_ok(), "{}", ev.kind);
            assert!(!default_text(ev, "en").0.trim().is_empty(), "{}", ev.kind);
        }
    }

    #[test]
    fn translates_known_text_and_passes_through_the_rest() {
        assert_eq!(tr("en", "청소가 끝났어요"), "Cleaning is done");
        assert_eq!(tr("ko", "청소가 끝났어요"), "청소가 끝났어요");
        assert_eq!(tr("en", "B-20261111-0042"), "B-20261111-0042");
        assert_eq!(tr("en", "결제 취소를 진행하고 있어요"), "We're cancelling your payment");
        assert_eq!(tr("ko", "verified"), "계정이 승인됐어요");
        assert_eq!(tr("en", "verified"), "Your account is approved");
    }

    #[test]
    fn archived_locales_read_english() {
        assert_eq!(shipped("vi"), "en");
        assert_eq!(tr("vi", "새 예약"), "New booking");
        assert_eq!(tr("fil", "verified"), "Your account is approved");
    }

    #[test]
    fn table_has_no_blank_translation() {
        assert_eq!(crate::routes::me::SUPPORTED_LOCALES, ["ko", "en"]);
        for (ko, en) in TABLE {
            assert!(!en.trim().is_empty(), "blank translation for {ko}");
        }
    }
}
