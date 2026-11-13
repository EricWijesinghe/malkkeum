//! Owner-editable settings. Resolution order per key: the stored row (`settings.key = 'reg.<key>'`), then the
//! env seed from `Config` (integer keys only), then the compiled default. Writes are validated against the
//! registry as a whole (all or nothing), the order rules are checked on the resulting values, and each changed
//! key gets an audit row in the same transaction.

use crate::{
    auth::{Role, live_staff_role},
    config::Config,
    error::{ApiError, ApiResult},
};
use serde::Serialize;
use serde_json::{Map, Value, json};
use sqlx::PgPool;
use std::collections::HashMap;
use uuid::Uuid;

const STORAGE_PREFIX: &str = "reg.";

/// When a change takes effect.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Applies {
    /// Read on the next request or job pass.
    Instant,
    /// Edited by hand in the app store console; the registry only shows it.
    StoreManual,
    /// Read only at server start; a restart (or rebuild) applies it.
    Rebuild,
}

/// The direction a value may move from its default. `Down`: may only be lowered (a marketing cap).
/// `Up`: may only be raised (a free-disk alert that fires sooner).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Tighten {
    Down,
    Up,
}

/// What a key holds. Integers carry bounds, text carries a length cap.
#[derive(Clone, Copy, Debug)]
pub enum Kind {
    Int { min: i64, max: i64, default: i64 },
    Bool { default: bool },
    Text { max_chars: usize, default: &'static str },
}

#[derive(Clone, Copy, Debug)]
pub struct Spec {
    pub key: &'static str,
    pub group: &'static str,
    pub kind: Kind,
    pub tighten: Option<Tighten>,
    pub applies: Applies,
    /// Shown in the console but never written; the env value is the only source.
    pub read_only: bool,
}

const fn int(key: &'static str, group: &'static str, min: i64, max: i64, default: i64) -> Spec {
    Spec {
        key,
        group,
        kind: Kind::Int { min, max, default },
        tighten: None,
        applies: Applies::Instant,
        read_only: false,
    }
}

const fn boolean(key: &'static str, group: &'static str, default: bool) -> Spec {
    Spec {
        kind: Kind::Bool { default },
        ..int(key, group, 0, 0, 0)
    }
}

const fn text(key: &'static str, group: &'static str, max_chars: usize, default: &'static str) -> Spec {
    Spec {
        kind: Kind::Text { max_chars, default },
        ..int(key, group, 0, 0, 0)
    }
}

const fn tightened(s: Spec, tighten: Tighten) -> Spec {
    Spec { tighten: Some(tighten), ..s }
}

impl Spec {
    /// The compiled default, in stored form.
    pub fn default_value(&self) -> Value {
        match self.kind {
            Kind::Int { default, .. } => json!(default),
            Kind::Bool { default } => json!(default),
            Kind::Text { default, .. } => json!(default),
        }
    }
}

fn type_name(kind: Kind) -> &'static str {
    match kind {
        Kind::Int { .. } => "int",
        Kind::Bool { .. } => "bool",
        Kind::Text { .. } => "text",
    }
}

pub const GROUPS: &[&str] = &["business", "marketing", "points", "quality", "ops"];

pub const SPECS: &[Spec] = &[
    int("upload_daily_quota", "business", 1, 10_000, 100),
    int("max_open_quote_requests", "business", 1, 1_000, 3),
    int("max_threads_per_day", "business", 1, 1_000, 10),
    tightened(int("review_report_threshold", "business", 1, 50, 3), Tighten::Up),
    int("noshow_grace_minutes", "business", 10, 240, 30),
    int("ai_chat_retention_days", "business", 30, 3_650, 180),
    int("upload_orphan_days", "business", 7, 365, 30),
    Spec {
        read_only: true,
        applies: Applies::Rebuild,
        ..int("reconcile_interval_secs", "business", 10, 3_600, 60)
    },
    tightened(int("freq_cap_per_week", "marketing", 1, 7, 2), Tighten::Down),
    int("nudge_rebook_days", "marketing", 7, 180, 30),
    tightened(int("points_adjust_max", "points", 1, 1_000_000, 100_000), Tighten::Down),
    int("quality_window_days", "quality", 7, 365, 90),
    int("quality_on_time_grace_min", "quality", 0, 60, 15),
    tightened(int("backup_stale_hours", "ops", 1, 168, 36), Tighten::Down),
    tightened(int("backup_late_hours", "ops", 1, 168, 26), Tighten::Down),
    tightened(int("disk_low_pct", "ops", 1, 50, 10), Tighten::Up),
    tightened(int("disk_warn_pct", "ops", 1, 80, 20), Tighten::Up),
    boolean("maintenance_on", "ops", false),
    text("maintenance_message", "ops", 200, ""),
];

/// Pairs whose order drives the alert levels: the first must stay below the second.
const ORDERED_PAIRS: [(&str, &str); 2] = [("backup_late_hours", "backup_stale_hours"), ("disk_low_pct", "disk_warn_pct")];

pub fn find(key: &str) -> Option<&'static Spec> {
    SPECS.iter().find(|s| s.key == key)
}

/// The env seed for keys that `Config` carries; the rest fall back to the compiled default.
fn seed(cfg: &Config, key: &str) -> Option<i64> {
    let v = match key {
        "upload_daily_quota" => i64::from(cfg.upload_daily_quota),
        "max_open_quote_requests" => i64::from(cfg.max_open_quote_requests),
        "max_threads_per_day" => i64::from(cfg.max_threads_per_day),
        "review_report_threshold" => i64::from(cfg.review_report_threshold),
        "noshow_grace_minutes" => i64::from(cfg.noshow_grace_minutes),
        "ai_chat_retention_days" => i64::from(cfg.ai_chat_retention_days),
        "upload_orphan_days" => i64::from(cfg.upload_orphan_days),
        "reconcile_interval_secs" => i64::try_from(cfg.reconcile_interval_secs).ok()?,
        _ => return None,
    };
    Some(v)
}

/// Checks one proposed value and returns it in stored form. `Err` carries a plain code the console maps to Korean text.
pub fn validate(spec: &Spec, raw: &Value) -> ApiResult<Value> {
    if spec.read_only {
        return Err(ApiError::BadRequest("read_only_setting"));
    }
    match spec.kind {
        Kind::Int { min, max, default } => validate_int(spec.tighten, raw, min, max, default),
        Kind::Bool { .. } => raw.as_bool().map(|b| json!(b)).ok_or(ApiError::BadRequest("invalid_input")),
        Kind::Text { max_chars, .. } => validate_text(raw, max_chars),
    }
}

fn validate_int(tighten: Option<Tighten>, raw: &Value, min: i64, max: i64, default: i64) -> ApiResult<Value> {
    let n = raw.as_i64().ok_or(ApiError::BadRequest("invalid_input"))?;
    if !(min..=max).contains(&n) {
        return Err(ApiError::BadRequest("out_of_range"));
    }
    match tighten {
        Some(Tighten::Down) if n > default => Err(ApiError::BadRequest("tighten_only")),
        Some(Tighten::Up) if n < default => Err(ApiError::BadRequest("tighten_only")),
        _ => Ok(json!(n)),
    }
}

fn validate_text(raw: &Value, max_chars: usize) -> ApiResult<Value> {
    let s = raw.as_str().ok_or(ApiError::BadRequest("invalid_input"))?.trim();
    if s.chars().count() > max_chars {
        return Err(ApiError::BadRequest("out_of_range"));
    }
    Ok(json!(s))
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Source {
    Db,
    Env,
    Default,
}

/// Picks the value to use. A stored value that no longer passes the registry is ignored (logged), so a
/// hand-edited row cannot push a limit out of bounds.
fn resolve(spec: &Spec, stored: Option<&Value>, seed: Option<i64>) -> (Value, Source) {
    if let Some(v) = stored {
        match validate(spec, v) {
            Ok(n) => return (n, Source::Db),
            Err(_) => tracing::warn!(key = spec.key, "stored setting fails the registry; using the fallback"),
        }
    }
    match seed {
        Some(n) => (json!(n), Source::Env),
        None => (spec.default_value(), Source::Default),
    }
}

fn storage_key(key: &str) -> String {
    format!("{STORAGE_PREFIX}{key}")
}

async fn load(db: &PgPool, cfg: &Config, key: &str) -> ApiResult<Value> {
    let spec = find(key).ok_or_else(|| ApiError::Internal(format!("unknown setting {key}")))?;
    let stored: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(storage_key(key))
        .fetch_optional(db)
        .await?;
    Ok(resolve(spec, stored.as_ref(), seed(cfg, key)).0)
}

/// The effective integer value of one key, for handlers and jobs.
pub async fn get(db: &PgPool, cfg: &Config, key: &str) -> ApiResult<i64> {
    load(db, cfg, key)
        .await?
        .as_i64()
        .ok_or_else(|| ApiError::Internal(format!("setting {key} is not an integer")))
}

/// The effective on/off value of one flag key, for handlers and jobs.
pub async fn get_flag(db: &PgPool, cfg: &Config, key: &str) -> ApiResult<bool> {
    load(db, cfg, key)
        .await?
        .as_bool()
        .ok_or_else(|| ApiError::Internal(format!("setting {key} is not a flag")))
}

fn group_specs(group: &str) -> ApiResult<Vec<&'static Spec>> {
    let specs: Vec<&Spec> = SPECS.iter().filter(|s| s.group == group).collect();
    if specs.is_empty() {
        return Err(ApiError::NotFound);
    }
    Ok(specs)
}

/// Bounds as the console shows them: `min`/`max` for integers, `max_length` for text.
fn bounds(kind: Kind) -> Value {
    match kind {
        Kind::Int { min, max, .. } => json!({ "min": min, "max": max }),
        Kind::Text { max_chars, .. } => json!({ "max_length": max_chars }),
        Kind::Bool { .. } => json!({}),
    }
}

fn item(spec: &Spec, stored: Option<&Value>, cfg: &Config) -> Value {
    let (value, source) = resolve(spec, stored, seed(cfg, spec.key));
    let mut out = json!({
        "key": spec.key,
        "type": type_name(spec.kind),
        "value": value,
        "default": spec.default_value(),
        "tighten": spec.tighten,
        "applies": spec.applies,
        "read_only": spec.read_only,
        "source": source,
    });
    if let (Some(map), Value::Object(bounds)) = (out.as_object_mut(), bounds(spec.kind)) {
        map.extend(bounds);
    }
    out
}

async fn stored_rows(db: &PgPool, specs: &[&Spec]) -> Result<HashMap<String, Value>, sqlx::Error> {
    let keys: Vec<String> = specs.iter().map(|s| storage_key(s.key)).collect();
    let rows: Vec<(String, Value)> = sqlx::query_as("SELECT key, value FROM settings WHERE key = ANY($1)")
        .bind(keys)
        .fetch_all(db)
        .await?;
    Ok(rows.into_iter().map(|(k, v)| (k.trim_start_matches(STORAGE_PREFIX).to_string(), v)).collect())
}

/// The console view of one group: every key with its value, bounds and where the value comes from.
pub async fn group_view(db: &PgPool, cfg: &Config, group: &str) -> ApiResult<Value> {
    let specs = group_specs(group)?;
    let stored = stored_rows(db, &specs).await?;
    let items: Vec<Value> = specs.iter().map(|s| item(s, stored.get(s.key), cfg)).collect();
    Ok(json!({ "group": group, "items": items }))
}

/// Maps each entry to its spec and validated value. `null` means reset. Any failure rejects the whole group.
fn plan_changes(specs: &[&'static Spec], values: &Map<String, Value>) -> ApiResult<Vec<(&'static Spec, Option<Value>)>> {
    let mut plan = Vec::with_capacity(values.len());
    for (key, raw) in values {
        let spec = specs
            .iter()
            .copied()
            .find(|s| s.key == key.as_str())
            .ok_or(ApiError::BadRequest("unknown_setting"))?;
        let new = if raw.is_null() { None } else { Some(validate(spec, raw)?) };
        plan.push((spec, new));
    }
    Ok(plan)
}

/// The values the group will hold once the plan is applied. Order rules are checked against these.
async fn effective_after(
    db: &PgPool,
    cfg: &Config,
    specs: &[&'static Spec],
    plan: &[(&'static Spec, Option<Value>)],
) -> ApiResult<HashMap<&'static str, Value>> {
    let stored = stored_rows(db, specs).await?;
    let mut after: HashMap<&'static str, Value> = specs.iter().map(|s| (s.key, resolve(s, stored.get(s.key), seed(cfg, s.key)).0)).collect();
    for (spec, new) in plan {
        let value = new.clone().unwrap_or_else(|| resolve(spec, None, seed(cfg, spec.key)).0);
        after.insert(spec.key, value);
    }
    Ok(after)
}

/// Rejects a group whose alert levels would never show: each lower threshold must stay below its pair.
fn check_order(after: &HashMap<&'static str, Value>) -> ApiResult<()> {
    for (lower, higher) in ORDERED_PAIRS {
        let (Some(lo), Some(hi)) = (after.get(lower).and_then(Value::as_i64), after.get(higher).and_then(Value::as_i64)) else {
            continue;
        };
        if lo >= hi {
            return Err(ApiError::BadRequest("threshold_order"));
        }
    }
    Ok(())
}

/// Applies one group's changes. `null` resets a key to its env seed or default. Nothing is written unless
/// every entry passes and the group's order rules hold.
pub async fn save_group(db: &PgPool, cfg: &Config, group: &str, actor: Uuid, values: &Map<String, Value>) -> ApiResult<Value> {
    let specs = group_specs(group)?;
    let plan = plan_changes(&specs, values)?;
    check_order(&effective_after(db, cfg, &specs, &plan).await?)?;
    let mut tx = db.begin().await?;
    for (spec, new) in plan {
        let skey = storage_key(spec.key);
        let old: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1 FOR UPDATE")
            .bind(&skey)
            .fetch_optional(&mut *tx)
            .await?;
        match &new {
            Some(n) => {
                sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = now()")
                    .bind(&skey)
                    .bind(n)
                    .execute(&mut *tx)
                    .await?;
            }
            None => {
                sqlx::query("DELETE FROM settings WHERE key = $1").bind(&skey).execute(&mut *tx).await?;
            }
        }
        let data = json!({ "group": group, "old": old, "new": new });
        sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data) VALUES ('staff', $1, 'settings.update', $2, $3)")
            .bind(actor)
            .bind(spec.key)
            .bind(data)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    group_view(db, cfg, group).await
}

/// Only staff admins may change limits; consultants may read them.
pub async fn ensure_can_write(db: &PgPool, actor: Uuid) -> ApiResult<()> {
    if live_staff_role(db, actor).await? != Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn by_key(key: &str) -> &'static Spec {
        find(key).expect("registered key")
    }

    fn after(pairs: &[(&'static str, i64)]) -> HashMap<&'static str, Value> {
        pairs.iter().map(|(k, v)| (*k, json!(v))).collect()
    }

    #[test]
    fn keys_are_unique_and_every_default_is_in_bounds() {
        let mut seen = std::collections::HashSet::new();
        for s in SPECS {
            assert!(seen.insert(s.key), "duplicate key {}", s.key);
            if let Kind::Int { min, max, default } = s.kind {
                assert!(min <= default && default <= max, "default out of bounds for {}", s.key);
            }
            assert!(GROUPS.contains(&s.group), "unknown group for {}", s.key);
        }
    }

    #[test]
    fn bounds_reject_out_of_range_and_non_integers() {
        let quota = by_key("upload_daily_quota");
        assert_eq!(validate(quota, &json!(1)).ok(), Some(json!(1)));
        assert_eq!(validate(quota, &json!(10_000)).ok(), Some(json!(10_000)));
        assert!(validate(quota, &json!(0)).is_err());
        assert!(validate(quota, &json!(10_001)).is_err());
        assert!(validate(quota, &json!(2.5)).is_err());
        assert!(validate(quota, &json!("50")).is_err());
    }

    #[test]
    fn destructive_floors_refuse_values_that_delete_too_soon() {
        assert!(validate(by_key("ai_chat_retention_days"), &json!(29)).is_err());
        assert!(validate(by_key("ai_chat_retention_days"), &json!(30)).is_ok());
        assert!(validate(by_key("upload_orphan_days"), &json!(6)).is_err());
        assert!(validate(by_key("noshow_grace_minutes"), &json!(9)).is_err());
    }

    #[test]
    fn tighten_down_refuses_a_value_above_the_default() {
        let cap = by_key("freq_cap_per_week");
        assert!(validate(cap, &json!(1)).is_ok());
        assert!(validate(cap, &json!(2)).is_ok());
        assert!(validate(cap, &json!(3)).is_err());
        let points = by_key("points_adjust_max");
        assert!(validate(points, &json!(50_000)).is_ok());
        assert!(validate(points, &json!(1_000_000)).is_err(), "the money guard cannot be loosened");
    }

    #[test]
    fn tighten_up_refuses_a_value_below_the_default() {
        let disk = by_key("disk_low_pct");
        assert!(validate(disk, &json!(25)).is_ok());
        assert!(validate(disk, &json!(5)).is_err());
        let reports = by_key("review_report_threshold");
        assert!(validate(reports, &json!(1)).is_err(), "one report must not hide a review");
    }

    #[test]
    fn read_only_rows_refuse_any_value() {
        let r = by_key("reconcile_interval_secs");
        assert!(r.read_only);
        assert!(matches!(validate(r, &json!(60)), Err(ApiError::BadRequest("read_only_setting"))));
    }

    #[test]
    fn flag_and_text_keep_their_own_types() {
        let on = by_key("maintenance_on");
        assert_eq!(validate(on, &json!(true)).ok(), Some(json!(true)));
        assert!(validate(on, &json!("yes")).is_err());
        assert!(validate(on, &json!(1)).is_err());
        let msg = by_key("maintenance_message");
        assert_eq!(validate(msg, &json!("  곧 돌아와요  ")).ok(), Some(json!("곧 돌아와요")));
        assert!(validate(msg, &json!("가".repeat(201))).is_err());
        assert!(validate(msg, &json!(5)).is_err());
    }

    #[test]
    fn stored_value_beats_env_seed_then_default() {
        let spec = by_key("upload_daily_quota");
        assert_eq!(resolve(spec, Some(&json!(500)), Some(100)), (json!(500), Source::Db));
        assert_eq!(resolve(spec, None, Some(100)), (json!(100), Source::Env));
        assert_eq!(resolve(spec, None, None), (json!(100), Source::Default));
    }

    #[test]
    fn invalid_stored_value_falls_back_to_the_seed() {
        let spec = by_key("upload_daily_quota");
        assert_eq!(resolve(spec, Some(&json!(0)), Some(100)), (json!(100), Source::Env));
    }

    #[test]
    fn order_rules_reject_inverted_alert_levels() {
        assert!(check_order(&after(&[("backup_late_hours", 26), ("backup_stale_hours", 10)])).is_err());
        assert!(check_order(&after(&[("backup_late_hours", 10), ("backup_stale_hours", 10)])).is_err());
        assert!(check_order(&after(&[("backup_late_hours", 10), ("backup_stale_hours", 26)])).is_ok());
        assert!(check_order(&after(&[("disk_low_pct", 30), ("disk_warn_pct", 20)])).is_err());
        assert!(check_order(&after(&[("disk_low_pct", 10), ("disk_warn_pct", 20)])).is_ok());
    }

    #[test]
    fn order_rules_skip_pairs_outside_the_group() {
        assert!(check_order(&after(&[("disk_low_pct", 30)])).is_ok());
    }
}
