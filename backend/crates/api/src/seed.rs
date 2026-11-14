//! Idempotent first-run data: catalogue, quote formula, slot capacity, first admin, starter content.

use crate::{auth::hash_password, config::Config};
use domain::{catalog::default_catalog, quote::QuoteFormula};
use serde_json::json;
use sqlx::PgPool;

/// Default capacity per arrival hour until staff change it (decision #6).
const DEFAULT_SLOT_CAPACITY: i32 = 6;

/// Home tile order for a fresh catalogue (owner brief): 원룸, 이사, 입주, 화장실, 주방, 매트리스, 에어컨, 소파.
/// Only the first insert uses it, so an order the owner set in the console is never overwritten.
pub const SEED_ORDER: [&str; 8] = ["studio", "move_out", "move_in", "bathroom", "kitchen", "mattress", "aircon", "sofa"];

/// Home tile badges of the owner design: N on mattress, HOT on aircon (`content.badge`, read by the app).
/// Like the order, only the first insert writes them, so a badge the owner removes stays removed.
pub const SEED_BADGES: [(&str, &str); 2] = [("mattress", "new"), ("aircon", "hot")];

/// The banner the seed wrote before the single 15,000 welcome coupon (two coupons, now wrong).
/// It matches stored rows word for word, so it keeps the archived languages.
fn old_welcome_title() -> serde_json::Value {
    json!({ "ko": "첫 예약 쿠폰 2장 받기", "en": "2 welcome coupons for your first booking", "ja": "初回予約クーポン2枚", "zh": "首单优惠券2张", "vi": "2 phiếu giảm giá cho lần đặt đầu" })
}

// i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
pub(crate) fn welcome_title() -> serde_json::Value {
    json!({ "ko": "첫 청소 15,000원 웰컴쿠폰", "en": "₩15,000 welcome coupon for your first clean" })
}

pub async fn run(db: &PgPool, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    for s in default_catalog() {
        // Unlisted codes go after the brief's eight, in catalogue order.
        let order = SEED_ORDER.iter().position(|c| *c == s.code).unwrap_or(SEED_ORDER.len());
        let content = SEED_BADGES
            .iter()
            .find(|(code, _)| *code == s.code)
            .map_or_else(|| json!({}), |(_, badge)| json!({ "badge": badge }));
        sqlx::query(
            "INSERT INTO services (code, pricing, needs_preparation, max_pyeong, sort_order, content) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (code) DO NOTHING",
        )
        .bind(&s.code)
        .bind(sqlx::types::Json(&s.pricing))
        .bind(s.needs_preparation)
        .bind(s.max_pyeong.map(|p| p as i16))
        .bind(order as i32)
        .bind(content)
        .execute(db)
        .await?;
    }
    // Services seeded after the migrations take their home tile from the group list (NULL only: owner choices stay).
    sqlx::query("UPDATE services s SET group_code = g.code FROM service_groups g WHERE s.code = ANY(g.services) AND s.group_code IS NULL")
        .execute(db)
        .await?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ('quote_formula', $1) ON CONFLICT DO NOTHING")
        .bind(sqlx::types::Json(QuoteFormula::default()))
        .execute(db)
        .await?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ('business_hours', $1) ON CONFLICT DO NOTHING")
        .bind(json!({ "weekdays": [0,1,2,3,4], "open": "09:00", "close": "18:00" }))
        .execute(db)
        .await?;
    // Every payment method starts enabled; admin switches them off in the console.
    let methods: Vec<&str> = crate::routes::payments::METHODS.iter().map(|m| m.0).collect();
    sqlx::query("INSERT INTO settings (key, value) VALUES ('payment_methods', $1) ON CONFLICT DO NOTHING")
        .bind(sqlx::types::Json(methods))
        .execute(db)
        .await?;
    for h in [8i16, 9, 13, 14] {
        sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES ($1, $2) ON CONFLICT DO NOTHING")
            .bind(h)
            .bind(DEFAULT_SLOT_CAPACITY)
            .execute(db)
            .await?;
    }
    if let Some((email, password)) = &config.seed_admin {
        sqlx::query("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Admin', $2, 'admin') ON CONFLICT (email) DO NOTHING")
            .bind(email)
            .bind(hash_password(password).map_err(|e| e.to_string())?)
            .execute(db)
            .await?;
    }
    let has_content: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM content_items)").fetch_one(db).await?;
    if !has_content {
        let welcome = welcome_title();
        sqlx::query("INSERT INTO content_items (kind, title, body, sort_order) VALUES ('banner', $1, $2, 0)")
            .bind(&welcome)
            .bind(json!({"theme":"sun","link":"coupons"}))
            .execute(db)
            .await?;
        let faq = json!({ "ko": "취소는 언제까지 무료인가요?", "en": "Until when can I cancel for free?" });
        let answer = json!({ "ko": "방문 2일 전까지 무료로 취소할 수 있어요.", "en": "Free cancellation up to 2 days before the visit." });
        sqlx::query("INSERT INTO content_items (kind, title, body, sort_order) VALUES ('faq', $1, $2, 0)")
            .bind(faq)
            .bind(json!({ "text": answer }))
            .execute(db)
            .await?;
    }
    // Upgrade: only a banner still carrying the exact old seeded title; an edited one is the owner's.
    sqlx::query("UPDATE content_items SET title = $1 WHERE kind = 'banner' AND title = $2")
        .bind(welcome_title())
        .bind(old_welcome_title())
        .execute(db)
        .await?;
    Ok(())
}
