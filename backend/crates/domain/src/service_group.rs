//! Home categories (CR-8.1). Membership lives on `services.group_code`; the group row holds
//! title, order, chooser and its question config. Pure rules only: storage is in the API crate.

use serde_json::Value;

/// The four groups of the home screen. The owner renames, reorders and re-members them; codes are fixed.
pub const GROUP_CODES: [&str; 4] = ["moving", "living", "appliance", "disinfection"];

/// Home types the chooser can send (CR-8.2). Matches `quote::HomeType`'s wire names.
pub const HOME_TYPES: [&str; 3] = ["one_two_room", "apartment", "villa_house"];

/// Group a service is filed under when seeded or migrated. Unlisted codes have no group.
pub fn default_group_of(service_code: &str) -> Option<&'static str> {
    match service_code {
        "move_in" | "move_out" | "studio" => Some("moving"),
        "bathroom" | "kitchen" | "whole_home" | "window" => Some("living"),
        "aircon" | "mattress" | "sofa" => Some("appliance"),
        "disinfection" => Some("disinfection"),
        _ => None,
    }
}

/// Tile badge from the members' `content.badge` values ("hot", "new"). HOT wins over N.
pub fn derive_badge<'a>(badges: impl IntoIterator<Item = &'a str>) -> Option<&'static str> {
    let mut out = None;
    for badge in badges {
        match badge {
            "hot" => return Some("HOT"),
            "new" => out = Some("N"),
            _ => {}
        }
    }
    out
}

/// Config is an object; `build_age` (move chooser) needs both answers, `home_types` only known values.
pub fn valid_config(config: &Value) -> bool {
    let Some(obj) = config.as_object() else {
        return false;
    };
    let home_ok = obj.get("home_types").is_none_or(|v| {
        v.as_array()
            .is_some_and(|a| a.iter().all(|h| h.as_str().is_some_and(|h| HOME_TYPES.contains(&h))))
    });
    let age_ok = obj
        .get("build_age")
        .is_none_or(|v| v.get("new").and_then(Value::as_str).is_some() && v.get("old").and_then(Value::as_str).is_some());
    home_ok && age_ok
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn every_seeded_service_maps_to_a_known_group() {
        for code in [
            "move_in",
            "move_out",
            "studio",
            "bathroom",
            "kitchen",
            "whole_home",
            "window",
            "aircon",
            "mattress",
            "sofa",
            "disinfection",
        ] {
            let group = default_group_of(code).expect("mapped");
            assert!(GROUP_CODES.contains(&group), "{code} -> {group}");
        }
        assert_eq!(default_group_of("unknown"), None);
    }

    #[test]
    fn hot_wins_over_new_and_none_means_no_badge() {
        assert_eq!(derive_badge(["new", "hot"]), Some("HOT"));
        assert_eq!(derive_badge(["new"]), Some("N"));
        assert_eq!(derive_badge(Vec::<&str>::new()), None);
    }

    #[test]
    fn config_rejects_unknown_home_types_and_half_build_age() {
        let good = json!({"build_age": {"new": "move_in", "old": "move_out"}, "home_types": ["one_two_room", "villa_house"]});
        assert!(valid_config(&good));
        assert!(valid_config(&json!({})));
        assert!(!valid_config(&json!([])));
        assert!(!valid_config(&json!({"home_types": ["castle"]})));
        assert!(!valid_config(&json!({"build_age": {"new": "move_in"}})));
    }
}
