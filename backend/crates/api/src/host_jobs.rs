//! Server jobs an owner queues from the console: the kinds the server agent runs, their argument rules,
//! and the job file format `deploy/agent.sh` reads from the inbox. Nothing here touches the disk.

use rand::{RngCore, rngs::OsRng};
use uuid::Uuid;

const DAYS: [&str; 7] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];

/// Kinds the server agent runs today. Anything else is refused before a job file is written.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    StatusRefresh,
    BackupNow,
    Update,
    UpdateSkip,
    Channel,
    Restart,
    Schedule,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct JobSpec {
    pub kind: Kind,
    pub arg: String,
}

impl Kind {
    pub fn parse(name: &str) -> Option<Self> {
        Some(match name {
            "status-refresh" => Self::StatusRefresh,
            "backup-now" => Self::BackupNow,
            "update" => Self::Update,
            "update-skip" => Self::UpdateSkip,
            "channel" => Self::Channel,
            "restart" => Self::Restart,
            "schedule" => Self::Schedule,
            _ => return None,
        })
    }

    pub fn name(self) -> &'static str {
        match self {
            Self::StatusRefresh => "status-refresh",
            Self::BackupNow => "backup-now",
            Self::Update => "update",
            Self::UpdateSkip => "update-skip",
            Self::Channel => "channel",
            Self::Restart => "restart",
            Self::Schedule => "schedule",
        }
    }

    /// Plain Korean name for owner texts.
    pub fn label(self) -> &'static str {
        match self {
            Self::StatusRefresh => "상태 새로고침",
            Self::BackupNow => "지금 백업",
            Self::Update => "업데이트",
            Self::UpdateSkip => "업데이트 건너뛰기",
            Self::Channel => "업데이트 채널 변경",
            Self::Restart => "서버 재시작",
            Self::Schedule => "자동 작업 일정 변경",
        }
    }

    /// Owner kinds need the owner's TOTP on the request. The read-only status refresh needs only an admin session.
    pub fn needs_owner(self) -> bool {
        self != Self::StatusRefresh
    }
}

/// Checks a kind and its argument the way the agent does. Returns a stable error code for the response.
pub fn validate(kind: &str, arg: &str) -> Result<JobSpec, &'static str> {
    let kind = Kind::parse(kind).ok_or("unknown_job_kind")?;
    let ok = match kind {
        Kind::StatusRefresh | Kind::BackupNow | Kind::Update | Kind::UpdateSkip => arg.is_empty(),
        Kind::Channel => matches!(arg, "stable" | "beta"),
        Kind::Restart => matches!(arg, "api" | "web" | "db" | "all"),
        Kind::Schedule => valid_schedule(arg),
    };
    if ok {
        Ok(JobSpec { kind, arg: arg.to_string() })
    } else {
        Err("invalid_job_arg")
    }
}

/// `off`, or a weekday and a 24-hour time such as `mon@04:00`.
fn valid_schedule(arg: &str) -> bool {
    if arg == "off" {
        return true;
    }
    let Some((day, time)) = arg.split_once('@') else {
        return false;
    };
    let Some((hh, mm)) = time.split_once(':') else {
        return false;
    };
    DAYS.contains(&day) && two_digits(hh).is_some_and(|h| h <= 23) && two_digits(mm).is_some_and(|m| m <= 59)
}

fn two_digits(s: &str) -> Option<u8> {
    if s.len() == 2 && s.bytes().all(|b| b.is_ascii_digit()) {
        s.parse().ok()
    } else {
        None
    }
}

/// A fresh 128-bit public progress token, as 32 lowercase hex digits (the agent's token format).
pub fn new_progress_token() -> String {
    let mut bytes = [0u8; 16];
    OsRng.fill_bytes(&mut bytes);
    hex::encode(bytes)
}

/// The job file the agent reads: `id`, `kind`, optional `arg`, `token`, one `key=value` per line.
pub fn job_file(id: Uuid, spec: &JobSpec, token: &str) -> String {
    let arg = if spec.arg.is_empty() { String::new() } else { format!("arg={}\n", spec.arg) };
    format!("id={}\nkind={}\n{arg}token={token}\n", id.hyphenated(), spec.kind.name())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_only_the_kinds_and_args_the_agent_runs() {
        assert!(validate("backup-now", "").is_ok());
        assert!(validate("channel", "beta").is_ok());
        assert!(validate("restart", "all").is_ok());
        assert!(validate("schedule", "sun@23:59").is_ok());
        assert!(validate("schedule", "off").is_ok());
        assert_eq!(validate("restart-service", ""), Err("unknown_job_kind"));
        assert_eq!(validate("channel", "nightly"), Err("invalid_job_arg"));
        assert_eq!(validate("update-skip", "x"), Err("invalid_job_arg"));
    }

    #[test]
    fn schedule_rejects_bad_days_and_times() {
        for bad in ["mon@24:00", "mon@12:60", "mon@1:00", "mon@+1:00", "funday@04:00", "mon@04-00", "mon04:00"] {
            assert_eq!(validate("schedule", bad), Err("invalid_job_arg"), "{bad}");
        }
    }

    #[test]
    fn job_file_has_the_agent_format() {
        let id = Uuid::now_v7();
        let spec = JobSpec {
            kind: Kind::Channel,
            arg: "stable".into(),
        };
        let body = job_file(id, &spec, "0123456789abcdef0123456789abcdef");
        assert_eq!(
            body,
            format!("id={}\nkind=channel\narg=stable\ntoken=0123456789abcdef0123456789abcdef\n", id.hyphenated())
        );
        let bare = job_file(
            id,
            &JobSpec {
                kind: Kind::BackupNow,
                arg: String::new(),
            },
            "0123456789abcdef0123456789abcdef",
        );
        assert!(!bare.contains("arg="));
    }

    #[test]
    fn progress_token_is_32_lowercase_hex() {
        let t = new_progress_token();
        assert_eq!(t.len(), 32);
        assert!(t.bytes().all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b)));
    }
}
