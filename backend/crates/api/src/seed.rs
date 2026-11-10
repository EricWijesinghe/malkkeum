//! Idempotent first-run data: catalogue, quote formula, slot capacity, first admin, starter content.

use crate::{auth::hash_password, config::Config};
use domain::{catalog::default_catalog, quote::QuoteFormula};
use serde_json::json;
use sqlx::PgPool;

/// Default capacity per arrival hour until staff change it (decision #6).
const DEFAULT_SLOT_CAPACITY: i32 = 6;

pub async fn run(db: &PgPool, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    for (i, s) in default_catalog().into_iter().enumerate() {
        sqlx::query("INSERT INTO services (code, pricing, needs_preparation, max_pyeong, sort_order) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (code) DO NOTHING")
            .bind(&s.code)
            .bind(sqlx::types::Json(&s.pricing))
            .bind(s.needs_preparation)
            .bind(s.max_pyeong.map(|p| p as i16))
            .bind(i as i32)
            .execute(db)
            .await?;
    }
    sqlx::query("INSERT INTO settings (key, value) VALUES ('quote_formula', $1) ON CONFLICT DO NOTHING").bind(sqlx::types::Json(QuoteFormula::default())).execute(db).await?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ('business_hours', $1) ON CONFLICT DO NOTHING")
        .bind(json!({ "weekdays": [0,1,2,3,4], "open": "09:00", "close": "18:00" }))
        .execute(db)
        .await?;
    for h in [8i16, 9, 13, 14] {
        sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES ($1, $2) ON CONFLICT DO NOTHING").bind(h).bind(DEFAULT_SLOT_CAPACITY).execute(db).await?;
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
        let welcome = json!({ "ko": "첫 예약 쿠폰 2장 받기", "en": "2 welcome coupons for your first booking", "ja": "初回予約クーポン2枚", "zh": "首单优惠券2张", "vi": "2 phiếu giảm giá cho lần đặt đầu" });
        sqlx::query("INSERT INTO content_items (kind, title, body, sort_order) VALUES ('banner', $1, $2, 0)").bind(&welcome).bind(json!({"theme":"sun","link":"coupons"})).execute(db).await?;
        let faq = json!({ "ko": "취소는 언제까지 무료인가요?", "en": "Until when can I cancel for free?", "ja": "無料キャンセルはいつまで？", "zh": "什么时候可以免费取消？", "vi": "Hủy miễn phí đến khi nào?" });
        let answer = json!({ "ko": "방문 2일 전까지 무료로 취소할 수 있어요.", "en": "Free cancellation up to 2 days before the visit.", "ja": "訪問の2日前まで無料です。", "zh": "上门前2天内可免费取消。", "vi": "Miễn phí đến 2 ngày trước lịch hẹn." });
        sqlx::query("INSERT INTO content_items (kind, title, body, sort_order) VALUES ('faq', $1, $2, 0)").bind(faq).bind(json!({ "text": answer })).execute(db).await?;
    }
    Ok(())
}
