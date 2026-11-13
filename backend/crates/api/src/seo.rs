//! Public SEO pages, rendered per request from live data (per-owner, so no build step at install):
//! service x district landing pages under `/c/{service}/{district}`, `sitemap.xml`, `robots.txt`,
//! the notices RSS feed, and Search Console / Search Advisor verification files.
//! Korean first, English summary second. Every business fact comes from the `business` setting or the DB.

use crate::{
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Router,
    extract::{Path, State},
    http::header,
    response::{IntoResponse, Response},
    routing::get,
};
use chrono::{DateTime, Utc};
use domain::{catalog::Pricing, growth::mask_name, growth::redact_contacts};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const BUSINESS_KEY: &str = "business";
const DEFAULT_COLOR: &str = "#187A8F";
const CACHE_CONTROL: &str = "public, max-age=600";
const DESCRIPTION_CHARS: usize = 150;
const FAQ_LIMIT: usize = 10;
const REVIEW_SNIPPETS: i64 = 3;
const SNIPPET_CHARS: i32 = 200;
const NOTICE_ITEMS: i64 = 50;
/// Keyword pages: service code, Korean search term, English name.
pub const KEYWORDS: [(&str, &str, &str); 8] = [
    ("move_in", "입주청소", "Move-in cleaning"),
    ("move_out", "이사청소", "Move-out cleaning"),
    ("studio", "원룸청소", "Studio cleaning"),
    ("kitchen", "주방청소", "Kitchen cleaning"),
    ("bathroom", "욕실청소", "Bathroom cleaning"),
    ("mattress", "매트리스청소", "Mattress cleaning"),
    ("aircon", "에어컨청소", "Air conditioner cleaning"),
    ("sofa", "소파청소", "Sofa cleaning"),
];
/// Seoul districts: legal-dong code (what partners and bookings store), Korean and English names.
pub const SEOUL_DISTRICTS: [(&str, &str, &str); 25] = [
    ("11680", "강남구", "Gangnam-gu"), ("11650", "서초구", "Seocho-gu"), ("11710", "송파구", "Songpa-gu"),
    ("11740", "강동구", "Gangdong-gu"), ("11440", "마포구", "Mapo-gu"), ("11560", "영등포구", "Yeongdeungpo-gu"),
    ("11170", "용산구", "Yongsan-gu"), ("11200", "성동구", "Seongdong-gu"), ("11215", "광진구", "Gwangjin-gu"),
    ("11590", "동작구", "Dongjak-gu"), ("11620", "관악구", "Gwanak-gu"), ("11500", "강서구", "Gangseo-gu"),
    ("11470", "양천구", "Yangcheon-gu"), ("11530", "구로구", "Guro-gu"), ("11545", "금천구", "Geumcheon-gu"),
    ("11410", "서대문구", "Seodaemun-gu"), ("11380", "은평구", "Eunpyeong-gu"), ("11110", "종로구", "Jongno-gu"),
    ("11140", "중구", "Jung-gu"), ("11230", "동대문구", "Dongdaemun-gu"), ("11260", "중랑구", "Jungnang-gu"),
    ("11290", "성북구", "Seongbuk-gu"), ("11305", "강북구", "Gangbuk-gu"), ("11320", "도봉구", "Dobong-gu"),
    ("11350", "노원구", "Nowon-gu"),
];
const COMPANY_LABELS: [(&str, &str); 6] = [
    ("legal_name", "상호"),
    ("ceo", "대표자"),
    ("registration_no", "사업자등록번호"),
    ("mail_order_no", "통신판매업 신고번호"),
    ("address", "주소"),
    // 전자상거래법 시행규칙 제7조: the mall operator names its hosting provider.
    ("hosting_provider", "호스팅 제공자"),
];

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/c/{service}/{district}", get(service_page))
        .route("/c/{service}/{district}/og.svg", get(og_image))
        .route("/sitemap.xml", get(sitemap))
        .route("/robots.txt", get(robots))
        .route("/notices.xml", get(notices_feed))
        // Search Console / Search Advisor HTML-file verification at the site root.
        .route("/{file}", get(verification_file))
}

/// Verification tokens are pasted from the engines' consoles: letters, digits, `-` and `_`.
pub fn is_verification_token(s: &str) -> bool {
    !s.is_empty() && s.len() <= 128 && s.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
}

pub fn escape_html(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#39;"),
            _ => out.push(c),
        }
    }
    out
}

/// Thousands separators, then the currency suffix: 45000 -> "45,000원".
pub fn krw(n: i64) -> String {
    let digits = n.to_string();
    let mut out = String::new();
    for (i, c) in digits.chars().enumerate() {
        if i > 0 && (digits.len() - i).is_multiple_of(3) {
            out.push(',');
        }
        out.push(c);
    }
    format!("{out}원")
}

/// Lowest and highest list price. Quote services have none: the page says so instead of inventing one.
pub fn price_range(p: &Pricing) -> Option<(i64, i64)> {
    match p {
        Pricing::Fixed { price, .. } => Some((price.0, price.0)),
        Pricing::Unit { units } => {
            let lo = units.iter().map(|u| u.price.0).min()?;
            let hi = units.iter().map(|u| u.price.0).max()?;
            Some((lo, hi))
        }
        Pricing::Quote => None,
    }
}

fn price_text(price: Option<(i64, i64)>) -> String {
    match price {
        None => "현장 확인 후 견적".into(),
        Some((lo, hi)) if lo == hi => krw(lo),
        Some((lo, hi)) => format!("{}~{}", krw(lo), krw(hi)),
    }
}

/// Text of a localized JSON value: a plain string, or `{ "ko": .., "en": .. }` (Korean first).
fn localized(v: &Value) -> String {
    if let Some(s) = v.as_str() {
        return s.trim().to_string();
    }
    ["ko", "en"].iter().find_map(|k| v[*k].as_str().map(|s| s.trim().to_string())).unwrap_or_default()
}

fn text(v: &Value, key: &str) -> Option<String> {
    v.get(key)?.as_str().map(str::trim).filter(|s| !s.is_empty()).map(String::from)
}

fn clip(s: &str, max: usize) -> String {
    s.chars().take(max).collect()
}

/// JSON for a `<script>` element: `<` is escaped so no value can close the element.
fn script_json(v: &Value) -> String {
    serde_json::to_string(v).unwrap_or_default().replace('<', "\\u003c")
}

/// Business facts from the `business` setting. `name` is required: without it there is no page.
pub struct Brand {
    pub name: String,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub logo: Option<String>,
    /// Brand colour for generated images; the console validates it as #RRGGBB.
    pub color: String,
    pub company: Vec<(&'static str, String)>,
}

impl Brand {
    pub fn from_value(base: &str, v: &Value) -> Option<Brand> {
        let name = text(v, "name")?;
        let company = COMPANY_LABELS.iter().filter_map(|(k, label)| text(&v["company"], k).map(|t| (*label, t))).collect();
        Some(Brand {
            name,
            phone: text(v, "support_phone"),
            address: text(&v["company"], "address"),
            logo: text(v, "logo_url").map(|l| if l.starts_with('/') { format!("{base}{l}") } else { l }),
            color: text(v, "primary_color").filter(|c| crate::routes::setup::is_hex_color(c)).unwrap_or_else(|| DEFAULT_COLOR.into()),
            company,
        })
    }
}

pub struct Review {
    pub rating: i16,
    pub body: String,
    pub name: String,
}

/// Everything one service x district page shows. Built from the DB, rendered by [`render_service_page`].
pub struct ServicePage {
    pub base: String,
    pub brand: Brand,
    pub service: String,
    pub keyword: &'static str,
    pub english: &'static str,
    pub district_code: String,
    pub district: &'static str,
    pub district_en: &'static str,
    pub price: Option<(i64, i64)>,
    /// Owner FAQ (question, answer) from `content_items` kind `faq`.
    pub faqs: Vec<(String, String)>,
    pub review_count: i64,
    pub review_avg: f64,
    pub reviews: Vec<Review>,
    pub verify: Vec<(&'static str, String)>,
}

impl ServicePage {
    fn path(&self) -> String {
        format!("/c/{}/{}", self.service, self.district_code)
    }

    fn title(&self) -> String {
        format!("{} {} 가격·후기·예약 | {}", self.district, self.keyword, self.brand.name)
    }

    fn description(&self) -> String {
        clip(
            &format!("{} {} 가격 {}. 검증된 전문가 배정, 앱에서 바로 예약하세요.", self.district, self.keyword, price_text(self.price)),
            DESCRIPTION_CHARS,
        )
    }

    fn og_url(&self) -> String {
        format!("{}{}/og.svg", self.base, self.path())
    }

    fn cta(&self) -> String {
        format!("{}/app/?utm_source=seo&utm_medium=organic&utm_campaign={}_{}", self.base, self.service, self.district_code)
    }

    /// Generated answers use only the live price and the brand name; owner FAQ follows.
    fn faq_items(&self) -> Vec<(String, String)> {
        let mut out = vec![
            (format!("{} {} 가격은 얼마인가요?", self.district, self.keyword), format!("{} {} 가격은 {}입니다. 최종 금액은 예약 전 앱에서 확인할 수 있어요.", self.district, self.keyword, price_text(self.price))),
            (format!("{} {} 예약은 어떻게 하나요?", self.district, self.keyword), format!("{} 앱에서 날짜와 시간을 고르면 바로 예약할 수 있어요.", self.brand.name)),
        ];
        out.extend(self.faqs.iter().take(FAQ_LIMIT).cloned());
        out
    }

    fn json_ld(&self, faq: &[(String, String)]) -> Value {
        let business_id = format!("{}/#business", self.base);
        let mut local = json!({ "@type": "LocalBusiness", "@id": business_id, "name": self.brand.name, "url": self.base });
        if let Some(p) = &self.brand.phone {
            local["telephone"] = json!(p);
        }
        if let Some(a) = &self.brand.address {
            local["address"] = json!({ "@type": "PostalAddress", "streetAddress": a, "addressCountry": "KR" });
        }
        if let Some(l) = &self.brand.logo {
            local["image"] = json!(l);
        }
        if self.review_count > 0 {
            local["aggregateRating"] = json!({ "@type": "AggregateRating", "ratingValue": format!("{:.1}", self.review_avg), "reviewCount": self.review_count, "bestRating": 5, "worstRating": 1 });
        }
        let mut service = json!({
            "@type": "Service",
            "name": format!("{} {}", self.district, self.keyword),
            "serviceType": self.keyword,
            "areaServed": { "@type": "AdministrativeArea", "name": format!("서울특별시 {}", self.district) },
            "provider": { "@id": business_id },
        });
        if let Some((lo, hi)) = self.price {
            service["offers"] = if lo == hi {
                json!({ "@type": "Offer", "priceCurrency": "KRW", "price": lo })
            } else {
                json!({ "@type": "AggregateOffer", "priceCurrency": "KRW", "lowPrice": lo, "highPrice": hi })
            };
        }
        let questions: Vec<Value> = faq.iter().map(|(q, a)| json!({ "@type": "Question", "name": q, "acceptedAnswer": { "@type": "Answer", "text": a } })).collect();
        json!({ "@context": "https://schema.org", "@graph": [local, service, { "@type": "FAQPage", "mainEntity": questions }] })
    }
}

/// Full HTML document for one service x district page.
pub fn render_service_page(p: &ServicePage) -> String {
    let (title, desc, canon) = (escape_html(&p.title()), escape_html(&p.description()), escape_html(&format!("{}{}", p.base, p.path())));
    let brand = escape_html(&p.brand.name);
    let faq = p.faq_items();
    let mut h = format!(
        "<!doctype html>\n<html lang=\"ko\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n\
<title>{title}</title>\n<meta name=\"description\" content=\"{desc}\">\n<link rel=\"canonical\" href=\"{canon}\">\n\
<meta property=\"og:type\" content=\"website\">\n<meta property=\"og:site_name\" content=\"{brand}\">\n<meta property=\"og:title\" content=\"{title}\">\n\
<meta property=\"og:description\" content=\"{desc}\">\n<meta property=\"og:url\" content=\"{canon}\">\n<meta name=\"twitter:card\" content=\"summary_large_image\">\n"
    );
    let og = escape_html(&p.og_url());
    h.push_str(&format!("<meta property=\"og:image\" content=\"{og}\">\n<meta name=\"twitter:image\" content=\"{og}\">\n"));
    for (name, token) in &p.verify {
        h.push_str(&format!("<meta name=\"{name}\" content=\"{}\">\n", escape_html(token)));
    }
    h.push_str(&format!("<script type=\"application/ld+json\">{}</script>\n", script_json(&p.json_ld(&faq))));
    h.push_str(PAGE_STYLE);
    h.push_str(&format!("</head>\n<body>\n<header><a href=\"{}/\">{brand}</a></header>\n<main>\n", escape_html(&p.base)));
    h.push_str(&format!(
        "<h1>{} {}</h1>\n<p lang=\"en\">{} in {}, Seoul. Vetted cleaners from {brand}.</p>\n",
        escape_html(p.district), escape_html(p.keyword), escape_html(p.english), escape_html(p.district_en)
    ));
    h.push_str(&format!("<section><h2>가격</h2><p class=\"price\">{}</p></section>\n", escape_html(&price_text(p.price))));
    h.push_str(&format!("<p><a class=\"cta\" href=\"{}\">앱에서 {} 예약하기</a></p>\n", escape_html(&p.cta()), escape_html(p.keyword)));
    h.push_str(&reviews_html(p));
    h.push_str("<section><h2>자주 묻는 질문</h2>\n");
    for (q, a) in &faq {
        h.push_str(&format!("<details><summary>{}</summary><p>{}</p></details>\n", escape_html(q), escape_html(a)));
    }
    h.push_str("</section>\n</main>\n<footer>\n");
    if let Some(phone) = &p.brand.phone {
        h.push_str(&format!("<p>고객센터 <a href=\"tel:{}\">{}</a></p>\n", escape_html(&phone.replace(|c: char| !c.is_ascii_digit() && c != '+', "")), escape_html(phone)));
    }
    for (label, value) in &p.brand.company {
        h.push_str(&format!("<p>{label}: {}</p>\n", escape_html(value)));
    }
    h.push_str("</footer>\n</body>\n</html>\n");
    h
}

fn reviews_html(p: &ServicePage) -> String {
    if p.review_count == 0 {
        return "<section><h2>후기</h2><p>첫 후기를 기다리고 있어요.</p></section>\n".into();
    }
    let mut h = format!("<section><h2>후기</h2><p>평점 {:.1} ({}건)</p><ul>\n", p.review_avg, p.review_count);
    for r in &p.reviews {
        h.push_str(&format!("<li>★{} {} · {}</li>\n", r.rating, escape_html(&r.body), escape_html(&r.name)));
    }
    h.push_str("</ul></section>\n");
    h
}

const PAGE_STYLE: &str = "<style>body{margin:0;font:16px/1.6 system-ui,'Pretendard',sans-serif;color:#1d2433;background:#fff}\
header,footer,main{max-width:720px;margin:0 auto;padding:16px}header a{font-weight:700;color:inherit;text-decoration:none}\
h1{font-size:1.6rem;margin:8px 0}h2{font-size:1.1rem;margin:24px 0 8px}.price{font-size:1.4rem;font-weight:700}\
.cta{display:inline-block;padding:14px 20px;border-radius:12px;background:#2f6fed;color:#fff;font-weight:700;text-decoration:none}\
details{border-top:1px solid #e5e8ef;padding:10px 0}summary{cursor:pointer;font-weight:600}footer{font-size:.85rem;color:#5b6375}\
@media (prefers-color-scheme:dark){body{background:#0b1022;color:#e8ecf5}footer{color:#9aa3b8}}</style>\n</head>\n";

pub fn sitemap_xml(base: &str, paths: &[String]) -> String {
    let mut s = String::from("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");
    for p in paths {
        s.push_str(&format!("  <url><loc>{}</loc></url>\n", escape_html(&format!("{base}{p}"))));
    }
    s.push_str("</urlset>\n");
    s
}

pub fn robots_txt(base: &str) -> String {
    let rules = "Allow: /\nDisallow: /admin/\nDisallow: /app/\nDisallow: /v1/\n";
    format!("User-agent: *\n{rules}\nUser-agent: Yeti\n{rules}\nSitemap: {base}/sitemap.xml\n")
}

pub struct Notice {
    pub id: Uuid,
    pub title: String,
    pub body: String,
    pub at: DateTime<Utc>,
}

pub fn rss_xml(base: &str, brand: &str, items: &[Notice]) -> String {
    let mut s = format!(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss version=\"2.0\">\n<channel>\n<title>{}</title>\n<link>{}/</link>\n<description>{}</description>\n",
        escape_html(&format!("{brand} 공지")), escape_html(base), escape_html(&format!("{brand} 공지사항"))
    );
    for n in items {
        s.push_str(&format!(
            "<item>\n<title>{}</title>\n<link>{}/</link>\n<guid isPermaLink=\"false\">{}</guid>\n<pubDate>{}</pubDate>\n<description>{}</description>\n</item>\n",
            escape_html(&n.title), escape_html(base), n.id, n.at.to_rfc2822(), escape_html(&n.body)
        ));
    }
    s.push_str("</channel>\n</rss>\n");
    s
}

/// 1200x630 share card: brand colour, district and service, price. SVG, because a PNG encoder would be a new
/// dependency; crawlers that refuse SVG (some KakaoTalk previews) fall back to the page title and description.
pub fn og_svg(brand: &str, color: &str, title: &str, price: &str) -> String {
    format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1200\" height=\"630\" viewBox=\"0 0 1200 630\">\n\
<rect width=\"1200\" height=\"630\" fill=\"{}\"/>\n\
<text x=\"80\" y=\"120\" font-family=\"sans-serif\" font-size=\"36\" fill=\"#ffffff\" opacity=\"0.85\">{}</text>\n\
<text x=\"80\" y=\"330\" font-family=\"sans-serif\" font-size=\"84\" font-weight=\"700\" fill=\"#ffffff\">{}</text>\n\
<text x=\"80\" y=\"440\" font-family=\"sans-serif\" font-size=\"48\" fill=\"#ffffff\">{}</text>\n</svg>\n",
        escape_html(color),
        escape_html(brand),
        escape_html(title),
        escape_html(price)
    )
}

async fn og_image(State(s): State<AppState>, Path((service, district)): Path<(String, String)>) -> ApiResult<Response> {
    let (keyword, _) = keyword(&service).ok_or(ApiError::NotFound)?;
    let (district_name, _) = seoul_district(&district).ok_or(ApiError::NotFound)?;
    let business = business_value(&s.db).await?;
    let brand = Brand::from_value(&base_url(&s), &business).ok_or(ApiError::NotFound)?;
    let svc = crate::routes::catalog::load_service(&s.db, &service).await?;
    let title = format!("{district_name} {keyword}");
    let svg = og_svg(&brand.name, &brand.color, &title, &price_text(price_range(&svc.pricing)));
    Ok(([(header::CONTENT_TYPE, "image/svg+xml"), (header::CACHE_CONTROL, CACHE_CONTROL)], svg).into_response())
}

fn html(body: String) -> Response {
    ([(header::CONTENT_TYPE, "text/html; charset=utf-8"), (header::CACHE_CONTROL, CACHE_CONTROL)], body).into_response()
}

fn xml(body: String, content_type: &'static str) -> Response {
    ([(header::CONTENT_TYPE, content_type), (header::CACHE_CONTROL, CACHE_CONTROL)], body).into_response()
}

fn base_url(s: &AppState) -> String {
    s.config.public_base_url.trim_end_matches('/').to_string()
}

async fn business_value(db: &PgPool) -> ApiResult<Value> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(BUSINESS_KEY).fetch_optional(db).await?;
    Ok(v.unwrap_or_else(|| json!({})))
}

fn seoul_district(code: &str) -> Option<(&'static str, &'static str)> {
    SEOUL_DISTRICTS.iter().find(|d| d.0 == code).map(|d| (d.1, d.2))
}

fn keyword(code: &str) -> Option<(&'static str, &'static str)> {
    KEYWORDS.iter().find(|k| k.0 == code).map(|k| (k.1, k.2))
}

/// Service x district pairs with at least one verified partner covering both.
async fn covered_pairs(db: &PgPool) -> ApiResult<Vec<(String, String)>> {
    let rows = sqlx::query_as(
        "SELECT DISTINCT sv.svc, ds.dst FROM partner_prefs pp JOIN pros p ON p.id = pp.pro_id
         CROSS JOIN LATERAL unnest(pp.services) AS sv(svc)
         CROSS JOIN LATERAL unnest(pp.districts) AS ds(dst)
         WHERE p.status = 'verified'",
    )
    .fetch_all(db)
    .await?;
    Ok(rows)
}

async fn service_page(State(s): State<AppState>, Path((service, district)): Path<(String, String)>) -> ApiResult<Response> {
    let (keyword, english) = keyword(&service).ok_or(ApiError::NotFound)?;
    let (district_name, district_en) = seoul_district(&district).ok_or(ApiError::NotFound)?;
    let base = base_url(&s);
    let business = business_value(&s.db).await?;
    let brand = Brand::from_value(&base, &business).ok_or(ApiError::NotFound)?;
    let svc = crate::routes::catalog::load_service(&s.db, &service).await?;
    let covered: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM partner_prefs pp JOIN pros p ON p.id = pp.pro_id
         WHERE p.status = 'verified' AND $1 = ANY(pp.services) AND $2 = ANY(pp.districts))",
    )
    .bind(&service)
    .bind(&district)
    .fetch_one(&s.db)
    .await?;
    if !covered {
        return Err(ApiError::NotFound);
    }
    let page = ServicePage {
        price: price_range(&svc.pricing),
        faqs: owner_faqs(&s.db).await?,
        verify: verification_tokens(&business),
        review_count: 0,
        review_avg: 0.0,
        reviews: Vec::new(),
        base,
        brand,
        service,
        keyword,
        english,
        district_code: district,
        district: district_name,
        district_en,
    };
    let page = with_reviews(&s.db, page).await?;
    Ok(html(render_service_page(&page)))
}

fn verification_tokens(business: &Value) -> Vec<(&'static str, String)> {
    [("google-site-verification", "google_site_verification"), ("naver-site-verification", "naver_site_verification")]
        .into_iter()
        .filter_map(|(meta, key)| text(business, key).map(|t| (meta, t)))
        .collect()
}

async fn owner_faqs(db: &PgPool) -> ApiResult<Vec<(String, String)>> {
    let rows: Vec<(Value, Value)> = sqlx::query_as("SELECT title, body FROM content_items WHERE kind = 'faq' AND active ORDER BY sort_order LIMIT $1")
        .bind(FAQ_LIMIT as i64)
        .fetch_all(db)
        .await?;
    Ok(rows.iter().map(|(q, a)| (localized(q), localized(&a["text"]))).filter(|(q, a)| !q.is_empty() && !a.is_empty()).collect())
}

async fn with_reviews(db: &PgPool, mut page: ServicePage) -> ApiResult<ServicePage> {
    let (count, avg): (i64, Option<f64>) = sqlx::query_as(
        "SELECT count(*), avg(r.rating)::float8 FROM reviews r JOIN bookings b ON b.id = r.booking_id
         WHERE NOT r.hidden AND b.service_code = $1 AND b.district_code = $2",
    )
    .bind(&page.service)
    .bind(&page.district_code)
    .fetch_one(db)
    .await?;
    let rows: Vec<(i16, String, String)> = sqlx::query_as(
        "SELECT r.rating, left(r.body, $3), u.name FROM reviews r JOIN bookings b ON b.id = r.booking_id JOIN users u ON u.id = r.user_id
         WHERE NOT r.hidden AND r.body <> '' AND b.service_code = $1 AND b.district_code = $2
         ORDER BY r.created_at DESC LIMIT $4",
    )
    .bind(&page.service)
    .bind(&page.district_code)
    .bind(SNIPPET_CHARS)
    .bind(REVIEW_SNIPPETS)
    .fetch_all(db)
    .await?;
    page.review_count = count;
    page.review_avg = avg.unwrap_or(0.0);
    page.reviews = rows.into_iter().map(|(rating, body, name)| Review { rating, body: redact_contacts(&body), name: mask_name(&name) }).collect();
    Ok(page)
}

/// Static website pages (website/*.html) listed next to the generated /c/ pages.
const STATIC_PAGES: [&str; 6] = [
    "/",
    "/partners.html",
    "/privacy.html",
    "/terms.html",
    "/location-terms.html",
    "/delete-account.html",
];

async fn sitemap(State(s): State<AppState>) -> ApiResult<Response> {
    let base = base_url(&s);
    let mut paths: Vec<String> = STATIC_PAGES.iter().map(|p| (*p).to_string()).collect();
    let active: Vec<(String,)> = sqlx::query_as("SELECT code FROM services WHERE active").fetch_all(&s.db).await?;
    for (svc, dst) in covered_pairs(&s.db).await? {
        let known = keyword(&svc).is_some() && seoul_district(&dst).is_some();
        if known && active.iter().any(|(c,)| *c == svc) {
            paths.push(format!("/c/{svc}/{dst}"));
        }
    }
    paths.sort();
    paths.dedup();
    Ok(xml(sitemap_xml(&base, &paths), "application/xml; charset=utf-8"))
}

async fn robots(State(s): State<AppState>) -> Response {
    xml(robots_txt(&base_url(&s)), "text/plain; charset=utf-8")
}

async fn notices_feed(State(s): State<AppState>) -> ApiResult<Response> {
    let base = base_url(&s);
    let business = business_value(&s.db).await?;
    let brand = text(&business, "name").ok_or(ApiError::NotFound)?;
    let rows: Vec<(Uuid, Value, Value, DateTime<Utc>)> = sqlx::query_as(
        "SELECT id, title, body, created_at FROM content_items
         WHERE kind = 'notice' AND active AND (starts_at IS NULL OR starts_at <= now()) AND (ends_at IS NULL OR ends_at > now())
         ORDER BY created_at DESC LIMIT $1",
    )
    .bind(NOTICE_ITEMS)
    .fetch_all(&s.db)
    .await?;
    let items: Vec<Notice> = rows.into_iter().map(|(id, title, body, at)| Notice { id, title: localized(&title), body: localized(&body["text"]), at }).collect();
    Ok(xml(rss_xml(&base, &brand, &items), "application/rss+xml; charset=utf-8"))
}

/// `googleTOKEN.html` / `naverTOKEN.html`, where TOKEN is the configured verification value. Anything else is 404.
async fn verification_file(State(s): State<AppState>, Path(file): Path<String>) -> ApiResult<Response> {
    if !file.ends_with(".html") {
        return Err(ApiError::NotFound);
    }
    let business = business_value(&s.db).await?;
    if let Some(token) = text(&business, "google_site_verification").filter(|t| file == format!("google{t}.html")) {
        return Ok(([(header::CONTENT_TYPE, "text/html; charset=utf-8")], format!("google-site-verification: google{}.html\n", escape_html(&token))).into_response());
    }
    if let Some(token) = text(&business, "naver_site_verification").filter(|t| file == format!("naver{t}.html")) {
        return Ok(html(format!("<meta name=\"naver-site-verification\" content=\"{}\"/>\n", escape_html(&token))));
    }
    Err(ApiError::NotFound)
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::{Won, catalog::UnitOption};

    fn brand() -> Brand {
        Brand {
            name: "테스트<청소>".into(),
            phone: Some("02-1234-5678".into()),
            address: Some("서울 강남구 테헤란로 1".into()),
            logo: Some("https://example.com/logo.png".into()),
            color: DEFAULT_COLOR.into(),
            company: vec![("상호", "테스트 주식회사".into())],
        }
    }

    fn page(price: Option<(i64, i64)>, reviews: i64) -> ServicePage {
        ServicePage {
            base: "https://example.com".into(),
            brand: brand(),
            service: "move_in".into(),
            keyword: "입주청소",
            english: "Move-in cleaning",
            district_code: "11680".into(),
            district: "강남구",
            district_en: "Gangnam-gu",
            price,
            faqs: vec![("환불은요?".into(), "방문 2일 전까지 전액 환불이에요.".into())],
            review_count: reviews,
            review_avg: 4.666,
            reviews: vec![Review { rating: 5, body: "좋아요 </script>".into(), name: "김*".into() }],
            verify: vec![("google-site-verification", "abc123".into())],
        }
    }

    fn json_ld_of(html: &str) -> Value {
        let start = html.find("application/ld+json\">").unwrap() + "application/ld+json\">".len();
        let end = start + html[start..].find("</script>").unwrap();
        serde_json::from_str(&html[start..end]).expect("valid JSON-LD")
    }

    #[test]
    fn price_range_follows_pricing_model() {
        let fixed = Pricing::Fixed { price: Won(45_000), minutes: 120 };
        let unit = Pricing::Unit { units: vec![UnitOption { label_key: "a".into(), minutes: 60, price: Won(59_000) }, UnitOption { label_key: "b".into(), minutes: 90, price: Won(99_000) }] };
        assert_eq!(price_range(&fixed), Some((45_000, 45_000)));
        assert_eq!(price_range(&unit), Some((59_000, 99_000)));
        assert_eq!(price_range(&Pricing::Quote), None);
        assert_eq!(price_range(&Pricing::Unit { units: vec![] }), None);
    }

    #[test]
    fn krw_groups_thousands() {
        assert_eq!(krw(0), "0원");
        assert_eq!(krw(999), "999원");
        assert_eq!(krw(45_000), "45,000원");
        assert_eq!(krw(1_234_567), "1,234,567원");
    }

    #[test]
    fn page_has_seo_basics_and_escapes_brand() {
        let h = render_service_page(&page(Some((45_000, 45_000)), 0));
        assert!(h.contains("<title>강남구 입주청소 가격·후기·예약 | 테스트&lt;청소&gt;</title>"));
        assert!(h.contains("<link rel=\"canonical\" href=\"https://example.com/c/move_in/11680\">"));
        assert!(h.contains("<h1>강남구 입주청소</h1>"));
        assert!(h.contains("utm_source=seo&amp;utm_medium=organic&amp;utm_campaign=move_in_11680"));
        assert!(h.contains("<meta name=\"google-site-verification\" content=\"abc123\">"));
        assert!(h.contains("45,000원"));
    }

    #[test]
    fn json_ld_is_valid_and_has_no_rating_without_reviews() {
        let ld = json_ld_of(&render_service_page(&page(Some((59_000, 99_000)), 0)));
        let graph = ld["@graph"].as_array().unwrap();
        assert_eq!(graph[0]["@type"], "LocalBusiness");
        assert!(graph[0].get("aggregateRating").is_none());
        assert_eq!(graph[1]["offers"]["@type"], "AggregateOffer");
        assert_eq!(graph[1]["offers"]["lowPrice"], 59_000);
        assert_eq!(graph[2]["@type"], "FAQPage");
        assert_eq!(graph[2]["mainEntity"].as_array().unwrap().len(), 3);
    }

    #[test]
    fn aggregate_rating_only_with_real_reviews_and_script_is_safe() {
        let raw = render_service_page(&page(None, 7));
        let ld = json_ld_of(&raw);
        assert_eq!(ld["@graph"][0]["aggregateRating"]["reviewCount"], 7);
        assert_eq!(ld["@graph"][0]["aggregateRating"]["ratingValue"], "4.7");
        assert!(ld["@graph"][1].get("offers").is_none(), "quote service has no offer");
    }

    #[test]
    fn script_json_cannot_close_its_element() {
        let out = script_json(&json!({ "name": "</script><script>alert(1)" }));
        assert!(!out.contains("</script"));
        assert_eq!(serde_json::from_str::<Value>(&out).unwrap()["name"], "</script><script>alert(1)");
    }

    #[test]
    fn sitemap_lists_each_url_escaped() {
        let x = sitemap_xml("https://example.com", &["/".into(), "/c/move_in/11680".into()]);
        assert!(x.contains("<loc>https://example.com/c/move_in/11680</loc>"));
        assert_eq!(x.matches("<url>").count(), 2);
    }

    #[test]
    fn robots_points_at_sitemap_and_blocks_admin() {
        let r = robots_txt("https://example.com");
        assert!(r.contains("Sitemap: https://example.com/sitemap.xml"));
        assert!(r.contains("Disallow: /admin/"));
        assert!(r.contains("User-agent: Yeti"));
    }

    #[test]
    fn rss_items_escape_and_carry_dates() {
        let at = DateTime::parse_from_rfc3339("2026-11-01T00:00:00Z").unwrap().with_timezone(&Utc);
        let items = [Notice { id: Uuid::nil(), title: "점검 & 안내".into(), body: "<b>x</b>".into(), at }];
        let x = rss_xml("https://example.com", "다해", &items);
        assert!(x.contains("<title>점검 &amp; 안내</title>"));
        assert!(x.contains("<description>&lt;b&gt;x&lt;/b&gt;</description>"));
        assert!(x.contains("<pubDate>Sun, 1 Nov 2026 00:00:00 +0000</pubDate>"));
    }

    #[test]
    fn verification_tokens_are_strict() {
        assert!(is_verification_token("abc-DEF_123"));
        assert!(!is_verification_token(""));
        assert!(!is_verification_token("a\"b"));
        assert!(!is_verification_token("a b"));
    }

    #[test]
    fn og_card_escapes_and_uses_brand_colour() {
        let svg = og_svg("다해 <b>", "#187A8F", "강남구 입주청소", "45,000원");
        assert!(svg.contains("width=\"1200\" height=\"630\""));
        assert!(svg.contains("fill=\"#187A8F\""));
        assert!(svg.contains("다해 &lt;b&gt;"));
        assert!(!svg.contains("<b>"));
    }

    #[test]
    fn brand_colour_falls_back_when_invalid() {
        let b = Brand::from_value("https://x", &json!({"name": "다해", "primary_color": "red"})).unwrap();
        assert_eq!(b.color, DEFAULT_COLOR);
    }

    #[test]
    fn company_block_names_the_hosting_provider() {
        let b = Brand::from_value("https://x", &json!({"name": "다해", "company": {"legal_name": "예시(주)", "hosting_provider": "예시호스팅(주)"}})).unwrap();
        assert_eq!(b.company, vec![("상호", "예시(주)".to_string()), ("호스팅 제공자", "예시호스팅(주)".to_string())]);
    }

    #[test]
    fn brand_needs_a_name_and_absolute_logo() {
        assert!(Brand::from_value("https://x", &json!({})).is_none());
        let b = Brand::from_value("https://x", &json!({"name": "다해", "logo_url": "/files/a.png"})).unwrap();
        assert_eq!(b.logo.as_deref(), Some("https://x/files/a.png"));
    }
}
