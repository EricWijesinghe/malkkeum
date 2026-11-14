//! Live job state from the server agent's `status/<id>.json`. Root writes these files on the server; the API
//! reads them as untrusted text: size-capped, known states only, every text field length-capped.

use serde::Serialize;
use serde_json::Value;
use std::{fs::File, io::Read, path::Path};
use uuid::Uuid;

const MAX_READ_BYTES: u64 = 64 * 1024;
const MAX_FIELD_CHARS: usize = 4096;
const STATES: [&str; 8] = ["queued", "awaiting_approval", "running", "ok", "failed", "rolled_back", "rejected", "cancelled"];

#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct HostStatus {
    pub state: String,
    pub step: Option<String>,
}

/// `None` when the agent has not written a status yet. A file that cannot be read or parsed is `unknown`, never trusted.
pub fn read(dir: &Path, id: Uuid) -> Option<HostStatus> {
    let path = dir.join("status").join(format!("{}.json", id.hyphenated()));
    let mut text = String::new();
    let file = File::open(path).ok()?;
    if file.take(MAX_READ_BYTES).read_to_string(&mut text).is_err() {
        return Some(unknown());
    }
    Some(parse(&text))
}

pub fn parse(text: &str) -> HostStatus {
    let Ok(v) = serde_json::from_str::<Value>(text) else {
        return unknown();
    };
    let Some(state) = v.get("state").and_then(Value::as_str).filter(|s| STATES.contains(s)) else {
        return unknown();
    };
    HostStatus {
        state: state.to_string(),
        step: v.get("step").and_then(Value::as_str).map(cap),
    }
}

fn unknown() -> HostStatus {
    HostStatus {
        state: "unknown".into(),
        step: None,
    }
}

fn cap(s: &str) -> String {
    s.chars().take(MAX_FIELD_CHARS).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn known_state_and_step_pass_through() {
        let s = parse(r#"{"id":"x","state":"running","step":"백업 중"}"#);
        assert_eq!(
            s,
            HostStatus {
                state: "running".into(),
                step: Some("백업 중".into())
            }
        );
    }

    #[test]
    fn unknown_or_broken_state_is_unknown() {
        assert_eq!(parse(r#"{"state":"hacked"}"#).state, "unknown");
        assert_eq!(parse("not json").state, "unknown");
        assert_eq!(parse(r#"{"step":"no state"}"#).state, "unknown");
    }

    #[test]
    fn oversized_step_is_capped() {
        let long = "가".repeat(10_000);
        let s = parse(&format!(r#"{{"state":"ok","step":"{long}"}}"#));
        assert_eq!(s.step.map(|t| t.chars().count()), Some(MAX_FIELD_CHARS));
    }
}
