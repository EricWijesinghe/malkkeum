//! Home tiles over the real router and a migrated database: the owner edits a group, the public list
//! follows it, and refusals carry the coded reasons the console maps to Korean. Needs DATABASE_URL (sqlx::test).

mod common;

use api::auth::Role;
use axum::http::StatusCode;
use common::{app, call, seed_catalog, staff_token};
use serde_json::{Value, json};
use sqlx::PgPool;

fn move_group(active: bool) -> Value {
    json!({
        "title_ko": "이사·입주 청소",
        "title_en": "Move",
        "sort_order": 0,
        "active": active,
        "icon": "svc_move",
        "chooser": "move",
        "services": ["move_in", "move_out"],
        "config": { "build_age": { "new": "move_in", "old": "move_out" }, "home_types": ["apartment"] },
    })
}

fn codes(body: &Value) -> Vec<String> {
    body["groups"]
        .as_array()
        .expect("groups")
        .iter()
        .map(|g| g["code"].as_str().expect("code").to_string())
        .collect()
}

fn refusal(body: &Value) -> &str {
    body["error"]["code"].as_str().expect("error code")
}

#[sqlx::test(migrations = "../../migrations")]
async fn public_list_hides_empty_tiles_and_follows_the_owner(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (admin, _) = staff_token(&pool, Role::StaffAdmin).await;

    let (st, body) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(st, StatusCode::OK);
    // Disinfection has no live member yet, so its tile stays off the home list.
    assert_eq!(codes(&body), ["moving", "living", "appliance"]);

    let (st, _) = call(&app, "PUT", "/v1/admin/service-groups/moving", Some(&admin), Some(move_group(false))).await;
    assert_eq!(st, StatusCode::OK);
    let (_, body) = call(&app, "GET", "/v1/service-groups", None, None).await;
    assert_eq!(codes(&body), ["living", "appliance"]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn staff_cannot_edit_groups(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (consultant, _) = staff_token(&pool, Role::StaffConsultant).await;
    let (st, _) = call(&app, "PUT", "/v1/admin/service-groups/moving", Some(&consultant), Some(move_group(true))).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "../../migrations")]
async fn refusals_carry_their_reason_codes(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (admin, _) = staff_token(&pool, Role::StaffAdmin).await;
    let put = |body: Value| {
        let app = app.clone();
        let admin = admin.clone();
        async move { call(&app, "PUT", "/v1/admin/service-groups/living", Some(&admin), Some(body)).await }
    };
    let living = |services: Value| {
        json!({
            "title_ko": "거주 청소", "title_en": "Home", "sort_order": 1, "active": true, "icon": "svc_bathroom",
            "chooser": "list", "services": services, "config": {},
        })
    };

    let mut bad_title = living(json!(["bathroom"]));
    bad_title["title_ko"] = json!("   ");
    let (st, body) = put(bad_title).await;
    assert_eq!((st, refusal(&body)), (StatusCode::BAD_REQUEST, "invalid_group_title"));

    let (st, body) = put(living(json!(["move_in"]))).await;
    assert_eq!((st, refusal(&body)), (StatusCode::BAD_REQUEST, "service_in_other_group"));

    let (st, body) = put(living(json!(["nope"]))).await;
    assert_eq!((st, refusal(&body)), (StatusCode::BAD_REQUEST, "unknown_service"));

    let mut bad_icon = living(json!(["bathroom"]));
    bad_icon["icon"] = json!("Bad Icon");
    let (st, body) = put(bad_icon).await;
    assert_eq!((st, refusal(&body)), (StatusCode::BAD_REQUEST, "invalid_group_icon"));

    let mut move_without_targets = living(json!(["bathroom"]));
    move_without_targets["chooser"] = json!("move");
    move_without_targets["config"] = json!({ "build_age": { "new": "move_in", "old": "move_out" }, "home_types": ["apartment"] });
    let (st, body) = put(move_without_targets).await;
    assert_eq!((st, refusal(&body)), (StatusCode::BAD_REQUEST, "invalid_group_config"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn counted_pricing_is_saved_and_refused_when_out_of_range(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (admin, _) = staff_token(&pool, Role::StaffAdmin).await;
    let counted = |max_each: Value, bps: i64| {
        json!({
            "pricing": {
                "type": "counts",
                "units": [
                    { "label_key": "wall", "label": "벽걸이", "minutes": 90, "price": 79000 },
                    { "label_key": "stand", "minutes": 120, "price": 119000 },
                ],
                "max_each": max_each,
                "multi_discount_bps": bps,
            },
            "needs_preparation": false, "max_pyeong": null, "content": { "name": "에어컨" }, "active": true, "sort_order": 40,
        })
    };

    let (st, _) = call(&app, "PUT", "/v1/admin/services/aircon", Some(&admin), Some(counted(json!(5), 1000))).await;
    assert_eq!(st, StatusCode::OK);
    let (_, body) = call(&app, "GET", "/v1/services", None, None).await;
    let aircon = body.as_array().expect("services").iter().find(|s| s["code"] == "aircon").expect("aircon");
    assert_eq!(aircon["pricing"]["type"], "counts");

    let (st, _) = call(&app, "PUT", "/v1/admin/services/aircon", Some(&admin), Some(counted(json!(21), 1000))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let (st, _) = call(&app, "PUT", "/v1/admin/services/aircon", Some(&admin), Some(counted(json!(5), 6000))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
}
