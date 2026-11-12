# Backend: provider adapters, team-member login, flow tests

Status: code written, NOT compiled or run (machine overloaded; no cargo run per instruction). Everything below is a checklist for the first real build.

## Changed / created files

Created:
- `backend/migrations/0006_team_member_login.sql`: `team_members.last_login_at`, index on `team_members(phone)`. `refresh_tokens.role` is free text, so `member` needs no change.
- `backend/crates/api/src/providers/sms.rs`: Solapi v4 client. HMAC-SHA256 auth header, SMS/LMS, AlimTalk (`ATA`) with SMS fallback text. Unit tests: RFC 4231 TC2 vector split as date+salt, header format.
- `backend/crates/api/src/providers/fcm.rs`: FCM HTTP v1. RS256 assertion, token exchange, cached token (refresh 60 s before expiry, Mutex-guarded), per-token send, dead-token report (404/UNREGISTERED). Unit tests: claims, cache expiry (injected `Instant`), data stringification, message shape.
- `backend/crates/api/src/routes/member.rs`: `/v1/member/*`.
- `backend/crates/api/src/lib.rs`: library root (all modules, `build_state`, `serve`). Declares `ratelimit` and `reconciler` too.
- `backend/crates/api/tests/common/mod.rs`, `backend/crates/api/tests/flows.rs`: sqlx::test flows.

Changed:
- `backend/crates/api/src/main.rs`: now a thin wrapper calling `api::serve()`. Module declarations moved to `lib.rs`.
- `backend/crates/api/src/config.rs`: `Config.solapi: Option<SolapiConfig>`, `Config.fcm: Option<ServiceAccount>`, `solapi()`, `fcm_account()`.
- `backend/crates/api/src/providers.rs`: `Providers.fcm`; `send_sms` uses Solapi outside dev mode; new `send_customer_message` (AlimTalk or SMS) and `push_collect` (returns dead tokens); `push` keeps its signature and delegates.
- `backend/crates/api/src/realtime.rs`: `Recipient::Member(Uuid)` (role `member`, matched by id); `notify` pushes via `push_collect`, prunes dead tokens, and fires AlimTalk for customer kinds that have a template (spawned, failures only logged).
- `backend/crates/api/src/auth.rs`: `Role::Member` ("member"), `is_member_role`, `Member` extractor. `is_staff()` is false.
- `backend/crates/api/src/routes/auth.rs`: `verify_otp` member branch; `ensure_active` arm for `Member`.
- `backend/crates/api/src/routes/partner_jobs.rs`: only `assign` changed. It now notifies the member (`Recipient::Member`) via `best_effort(notify(...))`; the SMS stays. `accept`, `submit_quote`, `complete` untouched.
- `backend/crates/api/src/routes/mod.rs`: `mod member;` and `.nest("/member", member::routes())`.
- `backend/crates/api/Cargo.toml`: `tower` gets feature `util` (for `ServiceExt::oneshot`). No new crates.
- `deploy/.env.example`, `docs/DEPLOY.md` §4: rows and vars appended.

## Login rules (partner audience)

1. OTP proven as usual.
2. If `pros.phone` = phone, owner login (unchanged). The owner always wins.
3. Else if a `team_members` row with `role='member'`, same phone, `invite_status <> 'removed'` exists, member login: row becomes `active`, `last_login_at = now()`, token role `member`, subject = `team_members.id`.
4. Else the existing behaviour (creates a pro account).

Limitation: a phone invited to several teams logs into the team it used most recently. A phone that is both an owner and a member gets the owner login only.

## Member API contract (`/v1/member`, Bearer token with role `member`)

| Method | Path | Body / query | Response |
|---|---|---|---|
| GET | `/me` | | `{ "id", "name", "team_id", "team_name" }` |
| GET | `/jobs` | `?from=YYYY-MM-DD&to=YYYY-MM-DD` (max 62 days) | `[BookingRow]` (same columns as partner schedule) |
| GET | `/jobs/{id}` | | `{ "booking": BookingRow (includes address, visit_notes), "customer_name": masked, "team_memo": string or null }`. 404 if not assigned to the caller. No payout fields. |
| POST | `/jobs/{id}/complete` | `{ "before_photos": [url], "after_photos": [url], "checklist": [true,true,true,true] }` | `{ "ok": true }`. Same validation and writes as owner completion; settlement stays with the owner (`pro_id`); `completion_reports.submitted_by` = member id. |

Owner-only routes return 403 for members (`Pro` extractor). Notifications (`/v1/me/notifications`) and push registration (`/v1/me/push-token`) work for members through `Auth`.

## Env vars (new)

| Var | Required | Notes |
|---|---|---|
| `SOLAPI_API_KEY`, `SOLAPI_API_SECRET` | together, or neither | Neither = SMS unavailable outside dev mode (503 `provider_not_configured`). Only one set = startup error. |
| `SMS_SENDER` | with Solapi | digits only |
| `ALIMTALK_PF_ID` | for AlimTalk | without it, AlimTalk falls back to SMS |
| `ALIMTALK_TEMPLATES` | optional | JSON map event kind -> template id |
| `FCM_SERVICE_ACCOUNT` | for push | file path or inline JSON. Unreadable or malformed = startup error. |

Dev mode (`DEV_MODE=1`) always uses the fakes, whatever the vars say.

## Assumptions to confirm (cannot be checked without the vendor accounts)

Solapi (`docs.solapi.com`):
- Endpoint `POST https://api.solapi.com/messages/v4/send`, body `{"message": {...}}`. Message fields `to`, `from`, `text`, `type` (`SMS`/`LMS`/`ATA`), `kakaoOptions: {pfId, templateId, variables, disableSms}`.
- Auth header `HMAC-SHA256 apiKey=…, date=…, salt=…, signature=…`, signature = hex(HMAC-SHA256(secret, date ‖ salt)). `date` is sent as RFC 3339 UTC with seconds (`2026-11-10T01:02:03Z`). Confirm Solapi accepts `Z` (some docs show `+09:00`).
- AlimTalk template variables are `#{brand}` (shop name from the business profile), `#{title}` and `#{body}`. Approved templates must use those placeholders.
- SMS vs LMS split is 45 characters (EUC-KR 90 bytes).

FCM (`firebase.google.com/docs/cloud-messaging`):
- Message JSON `{"message": {"token", "notification", "data", "android": {"priority": "HIGH"}, "apns": {"payload": {"aps": {"sound": "default"}}}}}`.
- Dead token = HTTP 404 or body containing `UNREGISTERED`.
- Token endpoint form body with `grant_type` (percent-encoded) and `assertion`. Response `access_token`, `expires_in`.

Crate APIs (from memory, verify at compile):
- `jsonwebtoken` 9: `EncodingKey::from_rsa_pem`, `Header::new(Algorithm::RS256)`, `encode`.
- `hmac` 0.12: `Hmac::<Sha256>::new_from_slice`, `Mac::update`, `finalize().into_bytes()` (same as `portone.rs`).
- `reqwest` 0.12 without the `form` feature: the token body is built by hand (`.body(String)`), `bearer_auth`, `.json()`.
- `sqlx` 0.8: `query_scalar::<_, Option<String>>` with `.flatten()`, `Vec<String>` bind for `= ANY($1)`.
- `chrono` 0.4: `to_rfc3339_opts(SecondsFormat::Secs, true)`.

## Compile risks (ranked)

1. `lib.rs` conversion: any module that the other agent declares in `main.rs` must move to `lib.rs` (or the build breaks). `ratelimit` and `reconciler` are already moved. Keep new top-level modules in `lib.rs`.
2. `tests/common/mod.rs` builds `Config` by literal. Any new `Config` field needs a line there. Current fields are copied from `config.rs` as of this change.
3. `routes/member.rs::complete` is a copy of `partner_jobs::complete`. If the owner body changes (new columns, new rules), change both. Refactoring into a shared `pub(crate)` fn was skipped because the other agent edits the top of `complete`.
4. Clippy `-D warnings` on the new code: `collapsible_if` avoided, `unwrap_or_default` used, no unused imports expected in `flows.rs`/`common`.
5. `tower` `util` feature: added explicitly; should be a no-op if axum already enabled it.

## Verify (run when the machine is free)

```
source /f/EC/scripts/env.sh
cd /f/EC/backend
cargo fmt --all
cargo clippy --all-targets -j 2 -- -D warnings
cargo test -j 2                      # unit tests; flows.rs needs DATABASE_URL
```

Flow tests need a superuser connection to the local Postgres (F:/tools/pgdata, port 5433). Password is in `backend/.env`:

```
export DATABASE_URL=postgres://<superuser>:<password>@localhost:5433/postgres
cargo test -j 2 --test flows
```

`sqlx::test` creates and drops one database per test, so the superuser is needed for `CREATE DATABASE`.

Expected unit results: `signature_matches_hmac_sha256_known_vector` (RFC 4231 TC2), `cached_token_is_reused_until_the_refresh_margin`, `member_role_parses_and_only_members_pass_the_extractor_check`.

Smoke (optional, dev API running): `POST /v1/auth/otp` for a partner phone, invite a member with `POST /v1/partner/team`, sign the member in with `audience: "partner"`, and check `role` is `member`.
