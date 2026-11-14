//! Home categories over the real router: the public group list the app reads, the console's audited
//! edit, and the home type a quote carries (CR-8.1, CR-8.2).

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use common::{SECRET, call};
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

#[sqlx::test(migrations = "../../migrations")]
async fn a_service_dropped_from_a_group_leaves_it_and_others_keep_their_place(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token(&pool).await;

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
    assert!(st.is_client_error(), "unknown home type: {st}");
}
