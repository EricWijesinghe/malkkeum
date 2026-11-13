use super::*;

fn obj(v: Value) -> Map<String, Value> {
    v.as_object().cloned().unwrap()
}

#[test]
fn portone_requires_store_and_secret_and_checks_webhook_format() {
    let base = Integrations::default();
    assert_eq!(
        apply(&base, Section::Portone, &obj(json!({"store_id": "s"}))).unwrap_err(),
        Invalid("missing_field")
    );
    let bad = json!({"store_id": "s", "api_secret": "k", "webhook_secret": "nope"});
    assert_eq!(apply(&base, Section::Portone, &obj(bad)).unwrap_err(), Invalid("invalid_webhook_secret"));
    let ok = json!({"store_id": "store-1", "api_secret": "k", "webhook_secret": "whsec_aGVsbG8=", "channel_keys": "{\"card\":\"ch-1\"}"});
    let out = apply(&base, Section::Portone, &obj(ok)).unwrap();
    assert_eq!(out.portone.store_id.as_deref(), Some("store-1"));
    assert_eq!(out.portone.channel_keys.get("card").map(String::as_str), Some("ch-1"));
    assert!(out.has(Section::Portone));
}

#[test]
fn solapi_sender_is_normalised_to_digits() {
    let v = json!({"api_key": "k", "api_secret": "s", "sender": "02-1234-5678"});
    let out = apply(&Integrations::default(), Section::Solapi, &obj(v)).unwrap();
    assert_eq!(out.solapi.unwrap().sender, "0212345678");
    let short = json!({"api_key": "k", "api_secret": "s", "sender": "12"});
    assert_eq!(
        apply(&Integrations::default(), Section::Solapi, &obj(short)).unwrap_err(),
        Invalid("invalid_sender")
    );
}

#[test]
fn solapi_template_keys_must_be_known_alert_keys() {
    let ok = json!({"api_key": "k", "api_secret": "s", "sender": "0212345678", "templates": {"booking.arrival": "T1"}});
    assert!(apply(&Integrations::default(), Section::Solapi, &obj(ok)).is_ok());
    let typo = json!({"api_key": "k", "api_secret": "s", "sender": "0212345678", "templates": {"booking.arival": "T1"}});
    assert_eq!(
        apply(&Integrations::default(), Section::Solapi, &obj(typo)).unwrap_err(),
        Invalid("unknown_template_key")
    );
}

#[test]
fn push_needs_a_real_key_file() {
    let bad = json!({"service_account": "{\"project_id\":\"p\",\"client_email\":\"e\",\"private_key\":\"x\"}"});
    assert_eq!(
        apply(&Integrations::default(), Section::Push, &obj(bad)).unwrap_err(),
        Invalid("invalid_service_account")
    );
    let good = json!({"service_account": {"project_id": "p", "client_email": "a@p.iam", "private_key": "-----BEGIN PRIVATE KEY-----\nx"}});
    assert!(apply(&Integrations::default(), Section::Push, &obj(good)).unwrap().fcm.is_some());
}

#[test]
fn google_accepts_comma_list_or_array() {
    let out = apply(&Integrations::default(), Section::Google, &obj(json!({"client_ids": "a.apps, b.apps"}))).unwrap();
    assert_eq!(out.google_client_ids, vec!["a.apps", "b.apps"]);
    let out = apply(&Integrations::default(), Section::Apple, &obj(json!({"client_ids": ["com.x"]}))).unwrap();
    assert_eq!(out.apple_client_ids, vec!["com.x"]);
    assert!(out.apple_signin.is_none(), "key fields are optional");
}

#[test]
fn apple_key_fields_go_together_and_must_parse() {
    let pem = include_str!("../providers/testdata/test_only_ec.p8");
    let full = json!({"client_ids": "com.x", "team_id": "TEAM123456", "key_id": "KEY1234567", "private_key": pem});
    let out = apply(&Integrations::default(), Section::Apple, &obj(full.clone())).unwrap();
    assert_eq!(out.apple_signin.as_ref().map(|k| k.key_id.as_str()), Some("KEY1234567"));
    let mut partial = full.clone();
    partial["private_key"] = json!("");
    assert_eq!(apply(&Integrations::default(), Section::Apple, &obj(partial)).unwrap_err(), Invalid("missing_field"));
    let mut bad = full;
    bad["private_key"] = json!("-----BEGIN PRIVATE KEY-----\nnot a key\n-----END PRIVATE KEY-----");
    assert_eq!(apply(&Integrations::default(), Section::Apple, &obj(bad)).unwrap_err(), Invalid("invalid_private_key"));
    let kakao = apply(&Integrations::default(), Section::Kakao, &obj(json!({"app_id": "1", "admin_key": "adm"}))).unwrap();
    assert_eq!(kakao.kakao_admin_key.as_deref(), Some("adm"));
}

#[test]
fn merge_keeps_blank_secrets_clears_null_and_drops_unknown() {
    let current = obj(json!({"store_id": "s", "api_secret": "old", "webhook_secret": "whsec_x"}));
    let incoming = obj(json!({"api_secret": "", "webhook_secret": null, "store_id": "s2", "evil": "x"}));
    let out = merge(Section::Portone, &current, &incoming);
    assert_eq!(out.get("api_secret"), Some(&json!("old")));
    assert_eq!(out.get("store_id"), Some(&json!("s2")));
    assert!(!out.contains_key("webhook_secret"));
    assert!(!out.contains_key("evil"));
}

#[test]
fn preview_masks_secrets_and_shows_key_file_email() {
    assert_eq!(preview(Kind::Secret, &json!("abcdef123456")), json!("••••3456"));
    assert_eq!(preview(Kind::Secret, &json!("ab")), json!("••••ab"));
    assert_eq!(preview(Kind::File, &json!({"client_email": "push@p.iam"})), json!("push@p.iam"));
    assert_eq!(preview(Kind::Text, &json!("store-1")), json!("store-1"));
}

#[test]
fn ai_defaults_to_offline_and_validates_mode_and_model() {
    let base = Integrations::default();
    let out = apply(&base, Section::Ai, &obj(json!({"api_key": "sk-ant-x"}))).unwrap();
    let ai = out.ai.clone().expect("ai config");
    assert_eq!((ai.model.as_str(), ai.mode), (ai::DEFAULT_MODEL, Mode::Offline));
    assert!(out.has(Section::Ai));
    let always = json!({"api_key": "k", "mode": "always_first", "model": "claude-opus-5-5"});
    assert_eq!(apply(&base, Section::Ai, &obj(always)).unwrap().ai.unwrap().mode, Mode::AlwaysFirst);
    assert_eq!(apply(&base, Section::Ai, &obj(json!({"api_key": "k", "mode": "daytime"}))).unwrap_err(), Invalid("invalid_mode"));
    assert_eq!(apply(&base, Section::Ai, &obj(json!({"api_key": "k", "model": "x y"}))).unwrap_err(), Invalid("invalid_model"));
    assert_eq!(apply(&base, Section::Ai, &obj(json!({"model": "claude-opus-5-5"}))).unwrap_err(), Invalid("missing_field"));
}

#[test]
fn ai_caps_default_when_unset_and_read_when_saved() {
    let base = Integrations::default();
    let plain = apply(&base, Section::Ai, &obj(json!({"api_key": "k"}))).unwrap().ai.unwrap();
    assert_eq!(plain.caps, Caps::default());
    let saved = json!({"api_key": "k", "thread_hourly_cap": "5", "member_daily_cap": 20, "daily_cap": " 300 "});
    let caps = apply(&base, Section::Ai, &obj(saved)).unwrap().ai.unwrap().caps;
    assert_eq!(caps, Caps { thread_hourly: 5, member_daily: 20, daily: 300 });
}

#[test]
fn ai_caps_accept_only_whole_numbers_inside_their_bounds() {
    let base = Integrations::default();
    let with = |field: &str, v: Value| apply(&base, Section::Ai, &obj(json!({"api_key": "k", field: v})));
    assert!(with("thread_hourly_cap", json!("1")).is_ok());
    assert!(with("thread_hourly_cap", json!("60")).is_ok());
    assert!(with("member_daily_cap", json!("500")).is_ok());
    assert!(with("daily_cap", json!("10000")).is_ok());
    for (field, bad) in [
        ("thread_hourly_cap", json!("0")),
        ("thread_hourly_cap", json!("61")),
        ("member_daily_cap", json!("501")),
        ("daily_cap", json!("10001")),
        ("daily_cap", json!("-5")),
        ("daily_cap", json!("12.5")),
        ("member_daily_cap", json!("ten")),
        ("daily_cap", json!(0)),
        ("daily_cap", json!([1])),
    ] {
        assert_eq!(with(field, bad.clone()).unwrap_err(), Invalid("invalid_cap"), "{field} = {bad}");
    }
}

#[test]
fn backup_endpoint_must_be_a_public_host() {
    for bad in ["https://127.0.0.1", "https://10.0.0.5:9000", "https://169.254.169.254/latest", "https://[::1]", "https://localhost", "https://minio.internal"] {
        assert!(!public_host(bad), "{bad}");
    }
    for good in ["https://acc.r2.cloudflarestorage.com", "https://kr.object.ncloudstorage.com", "https://s3.ap-northeast-2.amazonaws.com:443"] {
        assert!(public_host(good), "{good}");
    }
}

#[test]
fn backup_section_validates_endpoint_bucket_and_retention() {
    let good = json!({"endpoint": "https://acc.r2.cloudflarestorage.com/", "region": "auto", "bucket": "malkkeum-backup", "access_key": "AK", "secret_key": "SK"});
    let out = apply(&Integrations::default(), Section::Backup, &obj(good.clone())).unwrap();
    let cfg = out.backup.clone().expect("backup configured");
    assert_eq!(cfg.endpoint, "https://acc.r2.cloudflarestorage.com");
    assert_eq!(cfg.retention_days, 30);
    assert!(out.has(Section::Backup));
    let mut insecure = good.clone();
    insecure["endpoint"] = json!("http://plain.example");
    assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(insecure)).unwrap_err(), Invalid("invalid_endpoint"));
    let mut bucket = good.clone();
    bucket["bucket"] = json!("Bad_Bucket");
    assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(bucket)).unwrap_err(), Invalid("invalid_bucket"));
    let mut keep = good;
    keep["retention_days"] = json!("0");
    assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(keep)).unwrap_err(), Invalid("invalid_retention"));
}

#[test]
fn payout_defaults_to_manual_and_toss_is_refused() {
    let base = Integrations::default();
    assert!(base.payout.is_none(), "no section means manual");
    let manual = apply(&base, Section::Payout, &obj(json!({"mode": "manual"}))).unwrap();
    assert_eq!(manual.payout.map(|p| p.mode), Some(PayoutMode::Manual));
    assert_eq!(apply(&base, Section::Payout, &obj(json!({"mode": "toss"}))).unwrap_err(), Invalid("missing_field"));
    let keys = json!({"mode": "toss", "secret_key": "test_sk_x", "security_key": "0123456789abcdef".repeat(4)});
    assert_eq!(apply(&base, Section::Payout, &obj(keys.clone())).unwrap_err(), Invalid("toss_unverified"), "gate closed without env and test");
    let ready = Integrations { payout_toss_ready: true, ..Integrations::default() };
    assert_eq!(apply(&ready, Section::Payout, &obj(keys)).unwrap().payout.map(|p| p.mode), Some(PayoutMode::Toss));
    let bad_key = json!({"mode": "toss", "secret_key": "test_sk_x", "security_key": "xyz"});
    assert_eq!(apply(&ready, Section::Payout, &obj(bad_key)).unwrap_err(), Invalid("invalid_security_key"));
    assert_eq!(apply(&base, Section::Payout, &obj(json!({"mode": "bank"}))).unwrap_err(), Invalid("invalid_mode"));
}

#[test]
fn toss_gate_needs_env_and_a_passing_test_for_this_key() {
    let ok = json!({"ok": true, "code": "sandbox_connected", "key_fp": key_fingerprint("test_sk_a")});
    assert!(toss_ready(true, Some(&ok), "test_sk_a"));
    assert!(!toss_ready(false, Some(&ok), "test_sk_a"), "env switch off");
    assert!(!toss_ready(true, Some(&ok), "test_sk_b"), "key changed since the test");
    assert!(!toss_ready(true, None, "test_sk_a"), "never tested");
    let failed = json!({"ok": false, "code": "unreachable", "key_fp": key_fingerprint("test_sk_a")});
    assert!(!toss_ready(true, Some(&failed), "test_sk_a"));
}

#[test]
fn juso_key_is_a_required_console_secret() {
    let base = Integrations::default();
    assert_eq!(apply(&base, Section::Juso, &obj(json!({}))).unwrap_err(), Invalid("missing_field"));
    let out = apply(&base, Section::Juso, &obj(json!({"confm_key": "U01TX"}))).unwrap();
    assert_eq!(out.juso_confm_key.as_deref(), Some("U01TX"));
    assert!(out.has(Section::Juso));
}

#[test]
fn every_section_code_round_trips() {
    for s in Section::ALL {
        assert_eq!(Section::parse(s.code()), Some(s));
        assert!(s.fields().iter().any(|f| f.required));
    }
    assert_eq!(Section::parse("nope"), None);
}
