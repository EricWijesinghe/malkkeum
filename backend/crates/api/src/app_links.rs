//! Android App Links and Apple Universal Links for the Naver login callback (`https://DOMAIN/auth/naver/callback`).
//! The OS fetches these files from the site before it hands that URL to the app. Unset env = 404, so the link is not verified.

use crate::state::AppState;
use axum::{
    Json, Router,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::get,
};
use serde_json::{Value, json};

/// Store app ids (app/apps/customer, app/apps/partner): Android applicationId and iOS bundle identifier.
const APP_IDS: [&str; 2] = ["com.malkkeum.customer", "com.malkkeum.partner"];
/// Naver login returns here. Must match the Android intent-filter, the iOS applinks entry and social_native_io.dart.
pub const NAVER_CALLBACK_PATH: &str = "/auth/naver/callback";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/.well-known/assetlinks.json", get(assetlinks))
        .route("/.well-known/apple-app-site-association", get(apple_app_site_association))
}

async fn assetlinks(State(s): State<AppState>) -> Response {
    let certs = &s.config.android_cert_sha256;
    if certs.is_empty() {
        return StatusCode::NOT_FOUND.into_response();
    }
    Json(assetlinks_document(certs)).into_response()
}

async fn apple_app_site_association(State(s): State<AppState>) -> Response {
    match &s.config.apple_team_id {
        Some(team) => Json(aasa_document(team)).into_response(),
        None => StatusCode::NOT_FOUND.into_response(),
    }
}

/// Digital Asset Links, one statement per app: https://developers.google.com/digital-asset-links/v1/getting-started
pub fn assetlinks_document(certs: &[String]) -> Value {
    Value::Array(
        APP_IDS
            .iter()
            .map(|id| {
                json!({
                    "relation": ["delegate_permission/common.handle_all_urls"],
                    "target": { "namespace": "android_app", "package_name": id, "sha256_cert_fingerprints": certs },
                })
            })
            .collect(),
    )
}

/// Apple App Site Association: https://developer.apple.com/documentation/bundleresources/applinks
pub fn aasa_document(team: &str) -> Value {
    let app_ids: Vec<String> = APP_IDS.iter().map(|id| format!("{team}.{id}")).collect();
    json!({
        "applinks": {
            "details": [{ "appIDs": app_ids, "components": [{ "/": NAVER_CALLBACK_PATH, "comment": "Naver login" }] }]
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn assetlinks_names_both_apps_and_the_signing_certs() {
        let certs = vec!["AA:BB".to_string()];
        let doc = assetlinks_document(&certs);
        let statements = doc.as_array().expect("array");
        assert_eq!(statements.len(), APP_IDS.len());
        assert_eq!(statements[0]["target"]["package_name"], "com.malkkeum.customer");
        assert_eq!(statements[1]["target"]["package_name"], "com.malkkeum.partner");
        assert_eq!(statements[1]["target"]["sha256_cert_fingerprints"], json!(["AA:BB"]));
        assert_eq!(statements[0]["relation"][0], "delegate_permission/common.handle_all_urls");
    }

    #[test]
    fn aasa_limits_the_link_to_the_naver_path_and_both_app_ids() {
        let doc = aasa_document("ABCDE12345");
        let detail = &doc["applinks"]["details"][0];
        assert_eq!(detail["appIDs"], json!(["ABCDE12345.com.malkkeum.customer", "ABCDE12345.com.malkkeum.partner"]));
        assert_eq!(detail["components"][0]["/"], NAVER_CALLBACK_PATH);
    }
}
