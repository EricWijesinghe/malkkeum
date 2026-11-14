//! Launch safety: entry/door codes (encrypted at rest, revealed on the visit day only), emergency
//! contacts, and the case state machine. Codes never go into push, SMS, AI context or logs.

use crate::{crypto, ops_alerts};
use chrono::NaiveDate;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

/// Hours after a job ends (or is cancelled) before its entry code is erased.
pub const CODE_RETENTION_HOURS: i32 = 24;

/// Removes the entry code from a notes object and returns it (trimmed, None when blank).
pub fn take_entry(notes: &mut Value) -> Option<String> {
    let code = notes.as_object_mut()?.remove("entry")?;
    code.as_str().map(str::trim).filter(|s| !s.is_empty()).map(str::to_string)
}

/// The code is revealed only on the visit day (KST), to the assigned partner or to staff.
pub fn reveal_allowed(visit: NaiveDate, today_kst: NaiveDate) -> bool {
    visit == today_kst
}

/// Legal case moves: open -> investigating -> resolved | rejected; open may also be rejected directly.
pub fn can_move(from: &str, to: &str) -> bool {
    matches!(
        (from, to),
        ("open", "investigating") | ("open", "rejected") | ("investigating", "resolved") | ("investigating", "rejected")
    )
}

/// Who may file which case kind. No-show is raised by the system or staff, never by a partner.
pub fn may_file(reporter: &str, kind: &str) -> bool {
    match reporter {
        "customer" => matches!(kind, "damage" | "loss" | "complaint" | "no_show" | "safety" | "payment_dispute"),
        "partner" => matches!(kind, "damage" | "loss" | "complaint" | "safety"),
        "staff" => true,
        _ => false,
    }
}

/// Moves a legacy plaintext entry code into the encrypted column. Runs at boot; idempotent.
pub async fn encrypt_legacy_codes(db: &PgPool, key: &[u8; 32]) -> Result<u64, sqlx::Error> {
    let rows: Vec<(Uuid, Value)> = sqlx::query_as("SELECT id, visit_notes FROM bookings WHERE visit_notes->'entry' IS NOT NULL")
        .fetch_all(db)
        .await?;
    let mut moved = 0;
    for (id, mut notes) in rows {
        let enc = take_entry(&mut notes).map(|code| crypto::encrypt(key, crypto::aad::ACCESS_CODE, &code));
        sqlx::query("UPDATE bookings SET visit_notes = $2, access_code_enc = COALESCE($3, access_code_enc) WHERE id = $1")
            .bind(id)
            .bind(&notes)
            .bind(enc.as_deref())
            .execute(db)
            .await?;
        moved += 1;
    }
    Ok(moved)
}

/// Erases entry codes of jobs that ended more than `CODE_RETENTION_HOURS` ago.
pub async fn purge_codes(db: &PgPool) -> Result<u64, sqlx::Error> {
    let r = sqlx::query(
        "UPDATE bookings SET access_code_enc = NULL
         WHERE access_code_enc IS NOT NULL AND COALESCE(completed_at, cancelled_at) < now() - make_interval(hours => $1)",
    )
    .bind(CODE_RETENTION_HOURS)
    .execute(db)
    .await?;
    Ok(r.rows_affected())
}

/// Emergency numbers plus the shop hotline from settings (null when none is set).
pub async fn emergency_contacts(db: &PgPool) -> Result<Value, sqlx::Error> {
    let shop = ops_alerts::business_phone(db).await?;
    Ok(json!([
        { "label": "police_fire_emergency", "number": "112" },
        { "label": "fire_rescue", "number": "119" },
        { "label": "shop", "number": shop },
    ]))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entry_code_is_taken_out_of_notes() {
        let mut notes = json!({ "entry": " 1234# ", "parking": "B1" });
        assert_eq!(take_entry(&mut notes).as_deref(), Some("1234#"));
        assert_eq!(notes, json!({ "parking": "B1" }));
        let mut blank = json!({ "entry": "  " });
        assert_eq!(take_entry(&mut blank), None);
        assert_eq!(blank, json!({}));
    }

    #[test]
    fn code_is_revealed_only_on_the_visit_day() {
        let day = NaiveDate::from_ymd_opt(2026, 11, 11).unwrap();
        assert!(reveal_allowed(day, day));
        assert!(!reveal_allowed(day, day.succ_opt().unwrap()), "day after");
        assert!(!reveal_allowed(day.pred_opt().unwrap(), day), "day before");
    }

    #[test]
    fn case_moves_follow_the_workflow() {
        assert!(can_move("open", "investigating"));
        assert!(can_move("investigating", "resolved"));
        assert!(can_move("open", "rejected"));
        assert!(!can_move("open", "resolved"), "must be investigated first");
        assert!(!can_move("resolved", "open"), "resolved is final");
        assert!(!can_move("rejected", "investigating"));
    }

    #[test]
    fn partners_cannot_raise_no_shows_or_payment_disputes() {
        assert!(may_file("customer", "no_show"));
        assert!(may_file("customer", "payment_dispute"));
        assert!(!may_file("partner", "no_show"));
        assert!(!may_file("partner", "payment_dispute"));
        assert!(may_file("partner", "damage"));
        assert!(!may_file("system", "damage"));
    }
}
