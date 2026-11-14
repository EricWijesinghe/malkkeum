//! Home categories over the real router: the public group list the app reads, the console's audited
//! edit, and the home type a quote carries (CR-8.1, CR-8.2).

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use chrono::Duration;
use common::{SECRET, call, customer};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn admin_token(pool: &PgPool) -> String {
    let staff: Uuid =
        sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ('owner@test.local', 'Owner', 'unused', 'admin') RETURNING id")
            .fetch_one(pool)
            .await
            .expect("staff row");
    auth::issue_access(SECRET, staff, Role::StaffAdmin).expect("token")
}

fn group<'a>(body: &'a Value, code: &str) -> &'a Value {
    body["groups"]
        .as_array()
        .expect("groups")
        .iter()
        .find(|g| g["code"] == code)
        .expect("group present")
}

fn living_update(services: Value) -> Value {
    json!({
        "title": { "ko": "거주 청소", "en": "Living-space cleaning" },
        "sort_order": 5,
        "active": true,
        "icon": "svc_bathroom",
        "services": services,
        "config": {},
    })
}

#[sqlx::test(migrations = "../../migrations")]
async fn public_list_is_the_four_groups_in_order_with_derived_badges(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());

    let (st, body) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let codes: Vec<&str> = body["groups"]
        .as_array()
        .expect("groups")
        .iter()
        .map(|g| g["code"].as_str().expect("code"))
        .collect();
    assert_eq!(codes, ["moving", "living", "appliance", "disinfection"]);

    let moving = group(&body, "moving");
    assert_eq!(moving["chooser"], "move");
    assert_eq!(moving["config"]["build_age"], json!({ "new": "move_in", "old": "move_out" }));
    assert!(moving["services"].as_array().expect("services").iter().any(|s| s == "move_in"));
    assert_eq!(moving["badge"], Value::Null);

    // mattress is N and aircon is HOT in the seed; HOT wins for the group.
    assert_eq!(group(&body, "appliance")["badge"], "HOT");
    assert_eq!(group(&body, "living")["chooser"], "list");
    assert_eq!(group(&body, "disinfection")["chooser"], "direct");
}

#[sqlx::test(migrations = "../../migrations")]
async fn console_edit_is_audited_and_reorders_members_in_their_own_slots(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;

    let (st, b) = call(
        &app,
        "PUT",
        "/v1/admin/service-groups/living",
        Some(&token),
        Some(living_update(json!(["kitchen", "bathroom"]))),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");

    let (_, public) = call(&app, "GET", "/v1/service-groups", None, None).await;
    let living = group(&public, "living");
    assert_eq!(living["services"], json!(["kitchen", "bathroom"]));
    assert_eq!(living["title"]["en"], "Living-space cleaning");
    assert_eq!(living["sort_order"], 5);

    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'service_group.update' AND target = 'living'")
        .fetch_one(&pool)
        .await
        .expect("audit");
    assert_eq!(audited, 1);
}

async fn sort_orders(pool: &PgPool) -> Vec<(String, i32)> {
    sqlx::query_as("SELECT code, sort_order FROM services ORDER BY code")
        .fetch_all(pool)
        .await
        .expect("sort orders")
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_service_dropped_from_a_group_leaves_it_and_others_keep_their_place(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;
    let before = sort_orders(&pool).await;

    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/service-groups/living",
        Some(&token),
        Some(living_update(json!(["bathroom"]))),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let kitchen_group: Option<String> = sqlx::query_scalar("SELECT group_code FROM services WHERE code = 'kitchen'")
        .fetch_one(&pool)
        .await
        .expect("kitchen");
    assert_eq!(kitchen_group, None);
    assert_eq!(sort_orders(&pool).await, before, "no service moved its slot");
    let (_, admin) = call(&app, "GET", "/v1/admin/service-groups", Some(&token), None).await;
    assert_eq!(group(&admin, "living")["services"], json!(["bathroom"]));
}

#[sqlx::test(migrations = "../../migrations")]
async fn bad_edits_are_refused_and_change_nothing(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;
    let (_, before) = call(&app, "GET", "/v1/service-groups", None, None).await;

    let (st, _) = call(&app, "PUT", "/v1/admin/service-groups/living", None, Some(living_update(json!(["bathroom"])))).await;
    assert!(st == StatusCode::UNAUTHORIZED || st == StatusCode::FORBIDDEN, "no token: {st}");

    let (st, b) = call(
        &app,
        "PUT",
        "/v1/admin/service-groups/living",
        Some(&token),
        Some(living_update(json!(["bathroom", "no_such_service"]))),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");

    let mut bad_config = living_update(json!(["bathroom"]));
    bad_config["config"] = json!({ "home_types": ["castle"] });
    let (st, _) = call(&app, "PUT", "/v1/admin/service-groups/living", Some(&token), Some(bad_config)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/service-groups/nope",
        Some(&token),
        Some(living_update(json!(["bathroom"]))),
    )
    .await;
    assert_eq!(st, StatusCode::NOT_FOUND);

    let (_, after) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(before, after);
}

#[sqlx::test(migrations = "../../migrations")]
async fn quote_estimate_accepts_a_known_home_type_and_refuses_others(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let mut answers = json!({
        "cleaning_type": "standard", "luggage": "empty", "building": "apartment", "layout": "two_rooms",
        "duplex": false, "bathrooms": 1, "balconies": 1, "elevator": true, "floor_3_or_higher": false,
        "home_type": "apartment",
    });
    let (st, b) = call(&app, "POST", "/v1/quote/estimate", None, Some(answers.clone())).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    answers["home_type"] = json!("castle");
    let (st, _) = call(&app, "POST", "/v1/quote/estimate", None, Some(answers)).await;
    assert_eq!(st, StatusCode::UNPROCESSABLE_ENTITY);
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_chooser_quote_keeps_its_home_type_and_is_never_filed_as_other(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0101").await;
    let answers = json!({
        "cleaning_type": "standard", "luggage": "empty", "building": "other", "layout": "two_rooms",
        "duplex": false, "bathrooms": 1, "balconies": 1, "elevator": true, "floor_3_or_higher": false,
        "home_type": "villa_house",
    });
    let (st, b) = call(
        &app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "move_out", "address_id": c.address, "visit_date": api::util::today_kst() + Duration::days(3),
            "start_hour": 8, "answers": answers, "visit_notes": {}
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["answers"]["home_type"], "villa_house");
    assert_eq!(b["answers"]["building"], "house", "villa_house is filed as house, not other");

    let id = b["id"].as_str().expect("booking id");
    let (st, detail) = call(&app, "GET", &format!("/v1/bookings/{id}"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{detail}");
    assert_eq!(detail["answers"]["home_type"], "villa_house");
    assert_eq!(detail["answers"]["building"], "house");
    let stored: Option<String> = sqlx::query_scalar("SELECT answers->>'home_type' FROM bookings WHERE id = $1::uuid")
        .bind(id)
        .fetch_one(&pool)
        .await
        .expect("stored answers");
    assert_eq!(stored.as_deref(), Some("villa_house"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_new_member_alone_gives_the_group_an_n_and_hot_wins_over_it(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    sqlx::query("UPDATE services SET content = '{\"badge\": \"new\"}' WHERE code = 'bathroom'")
        .execute(&pool)
        .await
        .expect("badge");
    let (_, body) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(group(&body, "living")["badge"], "N");
    assert_eq!(group(&body, "moving")["badge"], Value::Null);

    sqlx::query("UPDATE services SET content = '{\"badge\": \"hot\"}' WHERE code = 'kitchen'")
        .execute(&pool)
        .await
        .expect("badge");
    let (_, body) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(group(&body, "living")["badge"], "HOT");
}

#[sqlx::test(migrations = "../../migrations")]
async fn inactive_members_and_groups_are_hidden_from_the_home_list_but_kept_for_admin(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;
    sqlx::query("UPDATE services SET active = false WHERE code = 'kitchen'")
        .execute(&pool)
        .await
        .expect("deactivate");
    let (_, public) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(group(&public, "living")["services"], json!(["bathroom"]));
    let (_, admin) = call(&app, "GET", "/v1/admin/service-groups", Some(&token), None).await;
    assert!(group(&admin, "living")["services"].as_array().expect("services").iter().any(|s| s == "kitchen"));

    let mut inactive = living_update(json!(["bathroom", "kitchen"]));
    inactive["active"] = json!(false);
    let (st, _) = call(&app, "PUT", "/v1/admin/service-groups/living", Some(&token), Some(inactive)).await;
    assert_eq!(st, StatusCode::OK);
    let (_, public) = call(&app, "GET", "/v1/service-groups", None, None).await;
    let codes: Vec<&str> = public["groups"]
        .as_array()
        .expect("groups")
        .iter()
        .map(|g| g["code"].as_str().expect("code"))
        .collect();
    assert!(!codes.contains(&"living"), "inactive group hidden: {codes:?}");
    let (_, admin) = call(&app, "GET", "/v1/admin/service-groups", Some(&token), None).await;
    assert_eq!(group(&admin, "living")["active"], false);
}

#[sqlx::test(migrations = "../../migrations")]
async fn studio_is_kept_in_its_group_and_admin_but_not_listed_on_the_home(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;
    let (_, public) = call(&app, "GET", "/v1/service-groups", None, None).await;
    let moving = group(&public, "moving")["services"].as_array().expect("services").clone();
    assert!(moving.iter().any(|s| s == "move_in"));
    assert!(!moving.iter().any(|s| s == "studio"), "studio is hidden from home: {moving:?}");
    let (_, admin) = call(&app, "GET", "/v1/admin/service-groups", Some(&token), None).await;
    assert!(group(&admin, "moving")["services"].as_array().expect("services").iter().any(|s| s == "studio"));
    let grouped: Option<String> = sqlx::query_scalar("SELECT group_code FROM services WHERE code = 'studio'")
        .fetch_one(&pool)
        .await
        .expect("studio");
    assert_eq!(grouped.as_deref(), Some("moving"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn seed_files_a_service_missing_from_an_existing_database_under_its_group(pool: PgPool) {
    common::seed_catalog(&pool).await;
    sqlx::query("DELETE FROM services WHERE code = 'kitchen'").execute(&pool).await.expect("delete");
    common::seed_catalog(&pool).await;
    let grouped: Option<String> = sqlx::query_scalar("SELECT group_code FROM services WHERE code = 'kitchen'")
        .fetch_one(&pool)
        .await
        .expect("kitchen re-seeded");
    assert_eq!(grouped.as_deref(), Some("living"));
}

#[sqlx::test(migrations = false)]
async fn migration_0214_files_existing_services_under_their_groups(pool: PgPool) {
    let mut older = sqlx::migrate!("../../migrations");
    older.migrations = older.migrations.iter().filter(|m| m.version < 214).cloned().collect::<Vec<_>>().into();
    older.run(&pool).await.expect("migrations before 0214");
    for code in ["aircon", "bathroom", "kitchen", "mattress", "move_in", "move_out", "sofa", "studio"] {
        sqlx::query("INSERT INTO services (code, pricing, content) VALUES ($1, '{}'::jsonb, '{}'::jsonb)")
            .bind(code)
            .execute(&pool)
            .await
            .expect("pre-0214 service row");
    }
    sqlx::migrate!("../../migrations").run(&pool).await.expect("0214 on existing rows");

    let rows: Vec<(String, Option<String>)> = sqlx::query_as("SELECT code, group_code FROM services ORDER BY code")
        .fetch_all(&pool)
        .await
        .expect("rows");
    let want = [
        ("aircon", "appliance"),
        ("bathroom", "living"),
        ("kitchen", "living"),
        ("mattress", "appliance"),
        ("move_in", "moving"),
        ("move_out", "moving"),
        ("sofa", "appliance"),
        ("studio", "moving"),
    ];
    assert_eq!(rows.len(), want.len());
    for ((code, group), (want_code, want_group)) in rows.iter().zip(want) {
        assert_eq!(code, want_code);
        assert_eq!(group.as_deref(), Some(want_group), "{code}");
    }
    let hidden: Option<String> = sqlx::query_scalar("SELECT content->>'hidden_from_home' FROM services WHERE code = 'studio'")
        .fetch_one(&pool)
        .await
        .expect("studio");
    assert_eq!(hidden.as_deref(), Some("true"));
}
