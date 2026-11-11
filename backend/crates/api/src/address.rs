//! 도로명주소 검색 API (business.juso.go.kr) proxy. The confirm key (`confmKey`) stays on the
//! server; the app only receives address hits. Keywords are checked before they leave us.

use crate::providers::ProviderError;
use serde::Serialize;
use serde_json::Value;

pub const JUSO_API: &str = "https://business.juso.go.kr/addrlink/addrLinkApi.do";
pub const PAGE_SIZE: u32 = 10;
pub const MAX_PAGE: u32 = 100;
const MIN_CHARS: usize = 2;
const MAX_CHARS: usize = 100;
/// Characters that have no place in an address and are the usual SQL-injection carriers.
const FORBIDDEN_CHARS: [char; 8] = ['\'', '"', ';', '%', '\\', '<', '>', '`'];
/// Whole words the provider's guide rejects (SQL keywords), matched case-insensitively.
const FORBIDDEN_WORDS: [&str; 10] = ["select", "insert", "update", "delete", "drop", "alter", "union", "truncate", "exec", "create"];

#[derive(Debug, PartialEq, Eq)]
pub struct Invalid(pub &'static str);

/// One road-address result, trimmed to what the app shows. Zip and building name come from the provider.
#[derive(Debug, PartialEq, Eq, Serialize)]
pub struct Hit {
    pub road_address: String,
    pub jibun_address: String,
    pub zip_code: String,
    pub building_name: String,
}

/// Collapses whitespace, then rejects keywords the provider refuses (length, symbols, SQL words).
pub fn clean_keyword(raw: &str) -> Result<String, Invalid> {
    let q = raw.split_whitespace().collect::<Vec<_>>().join(" ");
    let len = q.chars().count();
    if !(MIN_CHARS..=MAX_CHARS).contains(&len) || q.chars().any(char::is_control) {
        return Err(Invalid("invalid_query"));
    }
    if q.contains(FORBIDDEN_CHARS) || q.contains("--") {
        return Err(Invalid("invalid_query"));
    }
    if q.split(' ').any(|w| FORBIDDEN_WORDS.contains(&w.to_ascii_lowercase().as_str())) {
        return Err(Invalid("invalid_query"));
    }
    Ok(q)
}

fn text(v: &Value) -> String {
    v.as_str().unwrap_or_default().trim().to_string()
}

/// Reads the provider's JSON. Any `errorCode` other than "0" is an upstream failure.
pub fn parse(v: &Value) -> Result<Vec<Hit>, ProviderError> {
    match v["results"]["common"]["errorCode"].as_str() {
        Some("0") => {}
        Some(code) => return Err(ProviderError::Upstream(format!("juso error {code}"))),
        None => return Err(ProviderError::Upstream("juso response shape".into())),
    }
    let items = v["results"]["juso"].as_array().map_or(&[][..], Vec::as_slice);
    Ok(items
        .iter()
        .map(|j| Hit {
            road_address: text(&j["roadAddr"]),
            jibun_address: text(&j["jibunAddr"]),
            zip_code: text(&j["zipNo"]),
            building_name: text(&j["bdNm"]),
        })
        .collect())
}

/// Same as [`search`] against `base`; tests point it at a local fake.
pub async fn search_at(http: &reqwest::Client, base: &str, key: &str, keyword: &str, page: u32) -> Result<Vec<Hit>, ProviderError> {
    let page = page.to_string();
    let count = PAGE_SIZE.to_string();
    let resp = http
        .get(base)
        .query(&[("confmKey", key), ("currentPage", page.as_str()), ("countPerPage", count.as_str()), ("keyword", keyword), ("resultType", "json")])
        .send()
        .await
        .map_err(|e| ProviderError::Upstream(e.to_string()))?;
    if !resp.status().is_success() {
        return Err(ProviderError::Upstream(format!("status {}", resp.status())));
    }
    let body: Value = resp.json().await.map_err(|e| ProviderError::Upstream(e.to_string()))?;
    parse(&body)
}

/// Road-address search. `keyword` must already be cleaned with [`clean_keyword`].
pub async fn search(http: &reqwest::Client, key: &str, keyword: &str, page: u32) -> Result<Vec<Hit>, ProviderError> {
    search_at(http, JUSO_API, key, keyword, page).await
}

/// Setup-wizard check: a fixed keyword must return a clean response.
pub async fn check(http: &reqwest::Client, key: &str) -> Result<(), ProviderError> {
    search(http, key, "세종대로", 1).await.map(|_| ())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Json, Router, extract::Query, routing::get};
    use serde_json::json;
    use std::collections::HashMap;

    #[test]
    fn keyword_rules_block_symbols_and_sql_words() {
        assert_eq!(clean_keyword("  테헤란로   123 ").as_deref(), Ok("테헤란로 123"));
        assert_eq!(clean_keyword("a"), Err(Invalid("invalid_query")));
        assert_eq!(clean_keyword(&"가".repeat(101)), Err(Invalid("invalid_query")));
        for bad in ["강남' OR 1=1", "x\"y", "a;b", "100%", "a--b", "<script>", "SELECT addr", "drop table"] {
            assert_eq!(clean_keyword(bad), Err(Invalid("invalid_query")), "{bad}");
        }
        // SQL words inside a longer word are not rejected: "selection" is a fine street-name fragment.
        assert!(clean_keyword("selection road").is_ok());
    }

    #[test]
    fn parse_maps_hits_and_provider_errors() {
        let ok = json!({"results": {"common": {"errorCode": "0", "totalCount": "1"}, "juso": [
            {"roadAddr": " 서울 강남구 테헤란로 1 ", "jibunAddr": "서울 강남구 역삼동 1", "zipNo": "06234", "bdNm": "빌딩"}
        ]}});
        let hits = parse(&ok).expect("hits");
        assert_eq!(hits, vec![Hit { road_address: "서울 강남구 테헤란로 1".into(), jibun_address: "서울 강남구 역삼동 1".into(), zip_code: "06234".into(), building_name: "빌딩".into() }]);
        let none = json!({"results": {"common": {"errorCode": "0"}}});
        assert!(parse(&none).expect("empty").is_empty());
        let bad_key = json!({"results": {"common": {"errorCode": "E0001"}}});
        assert!(matches!(parse(&bad_key), Err(ProviderError::Upstream(_))));
        assert!(matches!(parse(&json!({})), Err(ProviderError::Upstream(_))));
    }

    /// Fake provider: echoes the query it received, so the test can check the parameters sent.
    async fn fake(Query(q): Query<HashMap<String, String>>) -> Json<Value> {
        let ok = q.get("confmKey").map(String::as_str) == Some("KEY-1") && q.get("resultType").map(String::as_str) == Some("json");
        if !ok {
            return Json(json!({"results": {"common": {"errorCode": "E0001"}}}));
        }
        // The road address carries the received keyword, page and page size back to the test.
        let echo = format!("{}|{}|{}", q["keyword"], q["currentPage"], q["countPerPage"]);
        Json(json!({"results": {"common": {"errorCode": "0"}, "juso": [{"roadAddr": echo, "jibunAddr": "j", "zipNo": "z", "bdNm": ""}]}}))
    }

    async fn serve() -> String {
        let app = Router::new().route("/addr", get(fake));
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind fake");
        let addr = listener.local_addr().expect("fake addr");
        tokio::spawn(async move { axum::serve(listener, app).await.expect("fake serves") });
        format!("http://{addr}/addr")
    }

    #[tokio::test]
    async fn search_sends_key_keyword_and_paging() {
        let base = serve().await;
        let http = reqwest::Client::new();
        let hits = search_at(&http, &base, "KEY-1", "테헤란로", 2).await.expect("search");
        assert_eq!(hits[0].road_address, "테헤란로|2|10");
        assert!(matches!(search_at(&http, &base, "WRONG", "테헤란로", 1).await, Err(ProviderError::Upstream(_))));
    }
}
