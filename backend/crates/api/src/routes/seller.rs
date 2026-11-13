//! Public seller details (전자상거래법 제10조) as an HTML fragment. The website pages include it server-side
//! (`{{httpInclude}}` in deploy/Caddyfile), so the seller block is in the HTML itself: crawlers, no-JS
//! readers and store reviewers see it. Values come from the `business` setting the owner types in the console.

use crate::{
    error::{ApiError, ApiResult},
    seo::{business_value, escape_html},
    state::AppState,
};
use axum::{
    Router,
    extract::{Query, State},
    http::header,
    response::{IntoResponse, Response},
    routing::get,
};
use serde::Deserialize;
use serde_json::Value;
use sqlx::PgPool;
use std::{
    sync::Mutex,
    time::{Duration, Instant},
};

/// Short cache: the owner changes these rarely, and the fragment is cheap to rebuild.
const CACHE_CONTROL: &str = "public, max-age=300";
/// Every website page includes several fragments, so the business setting is read from memory for this long.
const BUSINESS_TTL: Duration = Duration::from_secs(60);
const BIZ_NO_DIGITS: usize = 10;
const FTC_LOOKUP: &str = "https://www.ftc.go.kr/bizCommPop.do";

static BUSINESS: Mutex<Option<(Instant, Value)>> = Mutex::new(None);

/// Single fields the legal pages put inline, with the text shown until the owner fills them in.
const FIELDS: [(&str, &str); 9] = [
    ("legal_name", "[상호]"),
    ("ceo", "[대표자]"),
    ("registration_no", "[사업자등록번호]"),
    ("mail_order_no", "[통신판매업 신고번호]"),
    ("address", "[주소]"),
    ("privacy_officer", "[개인정보 보호책임자]"),
    ("hosting_provider", "[호스팅 제공자]"),
    ("support_phone", "[고객센터 전화]"),
    ("support_email", "[고객센터 이메일]"),
];

/// Footer rows, in order: field, Korean label (empty label = the bare value).
const FOOTER_ROWS: [(&str, &str); 7] = [
    ("legal_name", ""),
    ("ceo", "대표"),
    ("registration_no", "사업자등록번호"),
    ("mail_order_no", "통신판매업 신고"),
    ("address", "주소"),
    ("privacy_officer", "개인정보 보호책임자"),
    ("hosting_provider", "호스팅 제공자"),
];

const NOT_CONFIGURED: &str = "사업자 정보는 준비 중이에요. 고객센터로 문의해 주세요.";

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/public/seller-info", get(seller_info))
}

#[derive(Deserialize)]
struct SellerQuery {
    field: Option<String>,
}

async fn seller_info(State(s): State<AppState>, Query(q): Query<SellerQuery>) -> ApiResult<Response> {
    let business = cached_business(&s.db).await?;
    let body = fragment(&business, q.field.as_deref()).ok_or(ApiError::NotFound)?;
    Ok((
        [(header::CONTENT_TYPE, "text/html; charset=utf-8"), (header::CACHE_CONTROL, CACHE_CONTROL)],
        body,
    )
        .into_response())
}

/// Forget the cached business setting; called when the owner saves it.
pub(crate) fn invalidate_business() {
    if let Ok(mut c) = BUSINESS.lock() {
        *c = None;
    }
}

/// The business setting from the cache when fresh, otherwise from the database (and cached).
async fn cached_business(db: &PgPool) -> ApiResult<Value> {
    if let Some(v) = fresh_business() {
        return Ok(v);
    }
    let v = business_value(db).await?;
    if let Ok(mut c) = BUSINESS.lock() {
        *c = Some((Instant::now(), v.clone()));
    }
    Ok(v)
}

fn fresh_business() -> Option<Value> {
    let c = BUSINESS.lock().ok()?;
    c.as_ref().filter(|(t, _)| t.elapsed() < BUSINESS_TTL).map(|(_, v)| v.clone())
}

/// Stored value of a field, trimmed; blank or missing counts as not configured.
fn value_of(business: &Value, field: &str) -> Option<String> {
    let raw = match field {
        "support_phone" | "support_email" => business[field].as_str(),
        _ => business["company"][field].as_str(),
    };
    raw.map(str::trim).filter(|s| !s.is_empty()).map(String::from)
}

/// The fragment for one field (`?field=`), or the footer block when no field is given. `None` for an unknown field.
pub fn fragment(business: &Value, field: Option<&str>) -> Option<String> {
    match field {
        None => Some(footer_block(business)),
        Some("bizcheck") => Some(ftc_link(business)),
        Some(f) => {
            let (_, placeholder) = FIELDS.iter().find(|(k, _)| *k == f)?;
            Some(field_html(f, value_of(business, f).as_deref(), placeholder))
        }
    }
}

/// One field's HTML: escaped text, or a `tel:` / `mailto:` link for the support contacts.
fn field_html(field: &str, value: Option<&str>, placeholder: &str) -> String {
    let Some(v) = value else { return escape_html(placeholder) };
    match field {
        "support_phone" => {
            let tel: String = v.chars().filter(|c| c.is_ascii_digit() || *c == '+').collect();
            format!("<a href=\"tel:{}\">{}</a>", escape_html(&tel), escape_html(v))
        }
        "support_email" => format!("<a href=\"mailto:{0}\">{0}</a>", escape_html(v)),
        _ => escape_html(v),
    }
}

/// Footer seller block: one `<span>` per row (the page's `<p class="company">` lays them out), then the FTC lookup link.
fn footer_block(business: &Value) -> String {
    let configured = FOOTER_ROWS.iter().any(|(k, _)| value_of(business, k).is_some());
    if !configured {
        return format!("<span>{}</span>", escape_html(NOT_CONFIGURED));
    }
    let mut out = String::new();
    for (field, label) in FOOTER_ROWS {
        let value = value_of(business, field);
        let text = match (value.as_deref(), label) {
            (Some(v), "") => escape_html(v),
            (Some(v), _) => escape_html(&format!("{label} {v}")),
            (None, "") => escape_html(FIELDS.iter().find(|(k, _)| *k == field).map_or("", |(_, p)| *p)),
            (None, _) => escape_html(&format!("{label} {}", FIELDS.iter().find(|(k, _)| *k == field).map_or("", |(_, p)| *p))),
        };
        out.push_str(&format!("<span>{text}</span>"));
    }
    out.push_str(&ftc_link(business));
    out
}

/// The 사업자정보확인 link (FTC lookup). With a 10-digit registration number it opens that seller's record.
fn ftc_link(business: &Value) -> String {
    let digits: String = value_of(business, "registration_no")
        .unwrap_or_default()
        .chars()
        .filter(char::is_ascii_digit)
        .collect();
    let href = if digits.len() == BIZ_NO_DIGITS {
        format!("{FTC_LOOKUP}?wrkr_no={digits}")
    } else {
        FTC_LOOKUP.to_string()
    };
    format!(
        "<a href=\"{}\" target=\"_blank\" rel=\"noopener\" data-t=\"c_bizcheck\">사업자정보확인</a>",
        escape_html(&href)
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn configured() -> Value {
        json!({
            "name": "다해",
            "support_phone": " 02-123-4567 ",
            "support_email": "help@example.com",
            "company": {"legal_name": "주식회사 <다해>", "ceo": "홍길동", "registration_no": "123-45-67890", "address": "서울 \"중구\" & 기타"}
        })
    }

    #[test]
    fn values_are_html_escaped() {
        let html = fragment(&configured(), Some("legal_name")).unwrap();
        assert_eq!(html, "주식회사 &lt;다해&gt;");
        let addr = fragment(&configured(), Some("address")).unwrap();
        assert_eq!(addr, "서울 &quot;중구&quot; &amp; 기타");
    }

    #[test]
    fn footer_block_escapes_every_row() {
        let html = fragment(&configured(), None).unwrap();
        assert!(html.contains("<span>주식회사 &lt;다해&gt;</span>"), "{html}");
        assert!(html.contains("<span>사업자등록번호 123-45-67890</span>"), "{html}");
        assert!(!html.contains("<다해>"), "raw markup must not leak: {html}");
        assert!(html.ends_with("사업자정보확인</a>"), "{html}");
    }

    #[test]
    fn missing_fields_show_placeholders() {
        let html = fragment(&json!({"name": "다해"}), Some("ceo")).unwrap();
        assert_eq!(html, "[대표자]");
        let phone = fragment(&json!({}), Some("support_phone")).unwrap();
        assert_eq!(phone, "[고객센터 전화]");
    }

    #[test]
    fn unconfigured_footer_says_so_without_a_lookup_link() {
        let html = fragment(&json!({"name": "다해", "company": {"ceo": "   "}}), None).unwrap();
        assert_eq!(html, "<span>사업자 정보는 준비 중이에요. 고객센터로 문의해 주세요.</span>");
    }

    #[test]
    fn contacts_become_links_with_escaped_targets() {
        let phone = fragment(&configured(), Some("support_phone")).unwrap();
        assert_eq!(phone, "<a href=\"tel:021234567\">02-123-4567</a>");
        let mail = fragment(&configured(), Some("support_email")).unwrap();
        assert_eq!(mail, "<a href=\"mailto:help@example.com\">help@example.com</a>");
    }

    #[test]
    fn unknown_field_is_none() {
        assert!(fragment(&configured(), Some("password")).is_none());
        assert!(fragment(&configured(), Some("company.ceo")).is_none());
    }

    #[test]
    fn bizcheck_link_opens_the_sellers_record() {
        let html = fragment(&configured(), Some("bizcheck")).unwrap();
        assert_eq!(
            html,
            "<a href=\"https://www.ftc.go.kr/bizCommPop.do?wrkr_no=1234567890\" target=\"_blank\" rel=\"noopener\" data-t=\"c_bizcheck\">사업자정보확인</a>"
        );
    }

    #[test]
    fn bizcheck_link_without_a_full_registration_number_is_the_bare_lookup() {
        let html = fragment(&json!({"company": {"registration_no": "123-45"}}), Some("bizcheck")).unwrap();
        assert!(html.starts_with("<a href=\"https://www.ftc.go.kr/bizCommPop.do\" "), "{html}");
    }

    #[test]
    fn footer_lookup_link_carries_the_registration_number() {
        let html = fragment(&configured(), None).unwrap();
        assert!(html.contains("bizCommPop.do?wrkr_no=1234567890"), "{html}");
    }

    #[test]
    fn business_cache_serves_until_invalidated() {
        *BUSINESS.lock().unwrap() = Some((Instant::now(), json!({"name": "다해"})));
        assert_eq!(fresh_business(), Some(json!({"name": "다해"})));
        invalidate_business();
        assert_eq!(fresh_business(), None);
    }
}
