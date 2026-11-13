//! Server-sent text (push, inbox, SMS) in the recipient's language.
//!
//! Call sites keep writing the Korean source text; [`tr`] looks it up here. Unknown text (booking
//! numbers, amounts, chat previews) passes through unchanged. AlimTalk keeps Korean: its templates
//! are pre-approved word for word.

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn translates_known_text_and_passes_through_the_rest() {
        assert_eq!(tr("en", "청소가 끝났어요"), "Cleaning is done");
        assert_eq!(tr("ko", "청소가 끝났어요"), "청소가 끝났어요");
        assert_eq!(tr("en", "B-20261111-0042"), "B-20261111-0042");
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
