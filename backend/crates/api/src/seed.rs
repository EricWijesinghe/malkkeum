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

/// The banner the seed wrote before the single 15,000 welcome coupon (two coupons, now wrong).
fn old_welcome_title() -> serde_json::Value {
    json!({ "ko": "첫 예약 쿠폰 2장 받기", "en": "2 welcome coupons for your first booking", "ja": "初回予約クーポン2枚", "zh": "首单优惠券2张", "vi": "2 phiếu giảm giá cho lần đặt đầu" })
}

fn welcome_title() -> serde_json::Value {
    json!({ "ko": "첫 청소 15,000원 웰컴쿠폰", "en": "₩15,000 welcome coupon for your first clean", "ja": "初回清掃 15,000ウォン ウェルカムクーポン", "zh": "首次清洁 15,000韩元欢迎券", "vi": "Phiếu chào mừng 15.000 KRW cho lần dọn đầu" })
}

pub async fn run(db: &PgPool, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    for s in default_catalog() {
        // Unlisted codes go after the brief's eight, in catalogue order.
        let order = SEED_ORDER.iter().position(|c| *c == s.code).unwrap_or(SEED_ORDER.len());
        sqlx::query("INSERT INTO services (code, pricing, needs_preparation, max_pyeong, sort_order) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (code) DO NOTHING")
            .bind(&s.code)
            .bind(sqlx::types::Json(&s.pricing))
            .bind(s.needs_preparation)
            .bind(s.max_pyeong.map(|p| p as i16))
            .bind(order as i32)
            .execute(db)
            .await?;
    }
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
        let faq = json!({ "ko": "취소는 언제까지 무료인가요?", "en": "Until when can I cancel for free?", "ja": "無料キャンセルはいつまで？", "zh": "什么时候可以免费取消？", "vi": "Hủy miễn phí đến khi nào?" });
        let answer = json!({ "ko": "방문 2일 전까지 무료로 취소할 수 있어요.", "en": "Free cancellation up to 2 days before the visit.", "ja": "訪問の2日前まで無料です。", "zh": "上门前2天内可免费取消。", "vi": "Miễn phí đến 2 ngày trước lịch hẹn." });
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
