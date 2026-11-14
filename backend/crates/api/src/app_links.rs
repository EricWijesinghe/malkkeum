//! Android App Links and Apple Universal Links for the Naver login callback (`https://DOMAIN/auth/naver/callback`).
//! The OS fetches these files from the site before it hands that URL to the app. No values = 404, so the link is not verified.
//! Values saved in the console (settings key `app_links`) replace the env values (`ANDROID_CERT_SHA256`, `APPLE_TEAM_ID`) as a set.

use crate::{
    auth::{Admin, Staff},
    config,
    error::{ApiError, ApiResult},
    routes::audit,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

/// Store app ids (app/apps/customer, app/apps/partner): Android applicationId and iOS bundle identifier.
const APP_IDS: [&str; 2] = ["com.malkkeum.customer", "com.malkkeum.partner"];
/// Naver login returns here. Must match the Android intent-filter, the iOS applinks entry and social_native_io.dart.
pub const NAVER_CALLBACK_PATH: &str = "/auth/naver/callback";
const SETTINGS_KEY: &str = "app_links";
/// Debug, upload, Play app signing and one rotation spare fit comfortably.
const MAX_CERTS: usize = 8;

/// Link values. The same shape is the stored settings row, the admin API body and the audit payload.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Links {
    #[serde(default)]
    pub android_cert_sha256: Vec<String>,
    #[serde(default)]
    pub apple_team_id: Option<String>,
}

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/.well-known/assetlinks.json", get(assetlinks))
        .route("/.well-known/apple-app-site-association", get(apple_app_site_association))
}

/// Owner console (mounted under `/admin`): read, save and dry-run the link values.
pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/app-links", get(get_links).put(put_links))
        .route("/app-links/verify", post(verify_links))
}

/// Saved values when the owner has saved any, otherwise the env values. Also returns where they came from.
pub async fn current(s: &AppState) -> ApiResult<(Links, &'static str)> {
    let stored: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(SETTINGS_KEY)
        .fetch_optional(&s.db)
        .await?;
    match stored {
        Some(v) => {
            let links: Links = serde_json::from_value(v).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            Ok((links, "database"))
        }
        None => {
            let links = Links {
                android_cert_sha256: s.config.android_cert_sha256.clone(),
                apple_team_id: s.config.apple_team_id.clone(),
            };
            Ok((links, "environment"))
        }
    }
}

async fn assetlinks(State(s): State<AppState>) -> ApiResult<Response> {
    let (links, _) = current(&s).await?;
    if links.android_cert_sha256.is_empty() {
        return Ok(StatusCode::NOT_FOUND.into_response());
    }
    Ok(Json(assetlinks_document(&links.android_cert_sha256)).into_response())
}

async fn apple_app_site_association(State(s): State<AppState>) -> ApiResult<Response> {
    let (links, _) = current(&s).await?;
    Ok(match links.apple_team_id {
        Some(team) => Json(aasa_document(&team)).into_response(),
        None => StatusCode::NOT_FOUND.into_response(),
    })
}

async fn get_links(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let (links, source) = current(&s).await?;
    Ok(Json(preview(&links, source)))
}

/// Owner-only. Validated before it replaces the values; the audit row keeps the fingerprints (public values).
async fn put_links(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Links>) -> ApiResult<Json<Value>> {
    let links = clean(input).map_err(ApiError::BadRequest)?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = now()")
        .bind(SETTINGS_KEY)
        .bind(sqlx::types::Json(&links))
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(a.id), "app_links.update", "app_links", json!(links)).await?;
    Ok(Json(preview(&links, "database")))
}

/// Dry run of the save: checks the values and shows the two files that would be served. Saves nothing.
async fn verify_links(_a: Admin, Json(input): Json<Links>) -> ApiResult<Json<Value>> {
    let links = clean(input).map_err(ApiError::BadRequest)?;
    Ok(Json(preview(&links, "unsaved")))
}

/// Checks and normalises owner input with the env rules (config.rs): SHA-256 fingerprints and 10-character Team IDs.
/// A blank Team ID means unset. Returns an error code for `ApiError::BadRequest`.
pub fn clean(input: Links) -> Result<Links, &'static str> {
    if input.android_cert_sha256.len() > MAX_CERTS {
        return Err("app_link_too_many_certs");
    }
    let raw: Vec<String> = input.android_cert_sha256.iter().map(|c| c.trim().to_owned()).collect();
    let mut certs = config::cert_fingerprints("ANDROID_CERT_SHA256", raw).map_err(|_| "app_link_fingerprint")?;
    certs.sort();
    certs.dedup();
    let team = input.apple_team_id.map(|t| t.trim().to_owned()).filter(|t| !t.is_empty());
    let apple_team_id = config::team_id(team).map_err(|_| "app_link_team_id")?;
    Ok(Links {
        android_cert_sha256: certs,
        apple_team_id,
    })
}

/// What the two well-known files would contain, so the console can show it before the owner saves.
pub fn preview(links: &Links, source: &'static str) -> Value {
    json!({
        "android_cert_sha256": links.android_cert_sha256,
        "apple_team_id": links.apple_team_id,
        "source": source,
        "assetlinks": (!links.android_cert_sha256.is_empty()).then(|| assetlinks_document(&links.android_cert_sha256)),
        "aasa": links.apple_team_id.as_deref().map(aasa_document),
    })
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
    // webcredentials: ASWebAuthenticationSession (iOS 17.4+) only accepts an https callback for a domain the app
    // is associated with through this service, applinks alone is not enough.
    json!({
        "applinks": {
            "details": [{ "appIDs": app_ids, "components": [{ "/": NAVER_CALLBACK_PATH, "comment": "Naver login" }] }]
        },
        "webcredentials": { "apps": app_ids }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fingerprint(byte: &str) -> String {
        vec![byte; 32].join(":")
    }

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
        assert_eq!(doc["webcredentials"]["apps"], detail["appIDs"]);
    }

    #[test]
    fn clean_uppercases_trims_and_dedupes_fingerprints() {
        let lower = fingerprint("ab");
        let input = Links {
            android_cert_sha256: vec![format!(" {lower} "), lower.to_uppercase()],
            apple_team_id: None,
        };
        let out = clean(input).expect("valid");
        assert_eq!(out.android_cert_sha256, vec![fingerprint("AB")]);
    }

    #[test]
    fn clean_refuses_a_malformed_fingerprint() {
        let short = Links {
            android_cert_sha256: vec!["AA:BB".into()],
            apple_team_id: None,
        };
        assert_eq!(clean(short), Err("app_link_fingerprint"));
        let bad_hex = Links {
            android_cert_sha256: vec![fingerprint("zz")],
            apple_team_id: None,
        };
        assert_eq!(clean(bad_hex), Err("app_link_fingerprint"));
    }

    #[test]
    fn clean_treats_a_blank_team_id_as_unset_and_refuses_a_bad_one() {
        let blank = Links {
            android_cert_sha256: vec![],
            apple_team_id: Some("  ".into()),
        };
        assert_eq!(clean(blank).expect("unset").apple_team_id, None);
        let short = Links {
            android_cert_sha256: vec![],
            apple_team_id: Some("SHORT".into()),
        };
        assert_eq!(clean(short), Err("app_link_team_id"));
        let punct = Links {
            android_cert_sha256: vec![],
            apple_team_id: Some("ABCDE-1234".into()),
        };
        assert_eq!(clean(punct), Err("app_link_team_id"));
    }

    #[test]
    fn clean_caps_the_number_of_certificates() {
        let many = Links {
            android_cert_sha256: (0..=MAX_CERTS).map(|i| fingerprint(&format!("{i:02X}"))).collect(),
            apple_team_id: None,
        };
        assert_eq!(clean(many), Err("app_link_too_many_certs"));
    }

    #[test]
    fn preview_leaves_out_a_document_with_no_values() {
        let empty = preview(&Links::default(), "unsaved");
        assert!(empty["assetlinks"].is_null());
        assert!(empty["aasa"].is_null());
        assert_eq!(empty["source"], "unsaved");
    }
}
