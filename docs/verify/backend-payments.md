# Backend: payment recovery, partner phone gate, abuse limits

Written without compiling (machine overloaded). Every item below is unverified until the compile pass.

## Files

Created
- `backend/migrations/0005_payment_recovery.sql`: checkouts status CHECK adds `refunded`; columns `checkouts.refund_reason`, `checkouts.reconciled_at`; table `uploads`.
- `backend/crates/api/src/ratelimit.rs`: sliding-window limiter (pure `Limiter`, injected `Instant`), `Gate` + `limit` middleware, `client_ip`, `forwarded_ip`, `within_quota`.
- `backend/crates/api/src/reconciler.rs`: `enabled()` rule and the background `spawn`.
- `backend/crates/api/src/routes/checkout_policy.rs`: pure settle policy `decide(Recovery) -> Action`, `refund_reason`.
- `docs/verify/backend-payments.md`: this file.

Modified
- `crates/api/src/lib.rs` (other agent moved `main.rs` body here): calls `reconciler::spawn(state.clone())` and `routes::router(state).into_make_service_with_connect_info::<SocketAddr>()`. My edits were made to main.rs first and carried over.
- `crates/api/src/config.rs`: fields `trusted_proxy`, `rate_auth_per_min`, `rate_upload_per_min`, `rate_general_per_min`, `upload_daily_quota`, `max_open_quote_requests`, `max_threads_per_day`, `reconcile_interval_secs`; helpers `flag`, `number<T>`.
- `crates/api/src/error.rs`: `ApiError::Quota(&'static str)` -> 429 with that code.
- `crates/api/src/routes/mod.rs`: `pub(crate) mod checkouts`, `mod checkout_policy`, rate-limit layer, `/admin` merges `checkouts::admin_routes()`.
- `crates/api/src/routes/checkouts.rs`: `settle` -> `apply` (decision-driven), `refund_late`, `find_by_id`, `find_by_payment`, `reconcile_pass` / `reconcile_one`, `GET /v1/admin/checkouts`.
- `crates/api/src/routes/webhooks.rs`: `webhook_auth` gate, handles `Transaction.Paid|VirtualAccountIssued|Cancelled` for any checkout, locate by id, payment id, then `customData.checkoutId`.
- `crates/api/src/providers/portone.rs`: `custom_checkout_id` (customData lookup), dev fake pays any UUID as PAID. Tests added.
- `crates/api/src/routes/partner_jobs.rs`: `require_phone` on accept, submit_quote, complete.
- `crates/api/src/routes/uploads.rs`: daily quota in a transaction with advisory lock, insert into `uploads`.
- `crates/api/src/routes/chat.rs`: customer thread quota (non-booking threads).
- `crates/api/src/routes/bookings.rs`: open quote-request cap in `create_quote`.
- `scripts/smoke.py`: card webhook settles, console list (200/403/400), social pro `phone_required`, 4th quote `too_many_open_requests`.
- `scripts/dev-api.sh`: `RATE_LIMIT_AUTH_PER_MIN` default 1000 for local runs.
- `.github/workflows/ci.yml`: `RATE_LIMIT_AUTH_PER_MIN: "1000"` for the smoke job.
- `deploy/.env.example`: new env vars documented.

## Endpoints and behaviour

- `POST /v1/webhooks/portone`: signed when `PORTONE_WEBHOOK_SECRET` is set (any mode). With no secret: unsigned accepted only if `DEV_MODE`; otherwise 503 `provider_not_configured`. Payment events re-read PortOne; the body never moves money.
- `GET /v1/admin/checkouts?status=pending|awaiting_deposit|paid|refunded|expired` (Staff). Newest first, LIMIT 200. Invalid status -> 400 `invalid_status`. Customer -> 403.
- Checkout decisions (`checkout_policy::decide`):
  - PAID, amount ok, open, not expired -> book (`Fulfil`).
  - PAID after expiry -> try to book (`FulfilLate`). On failure: refund, status `refunded`, `refund_reason` = error code, customer notified (best effort), response 409 `checkout_refunded`.
  - PAID, amount wrong -> refund, `failed` (existing).
  - PAID on failed/cancelled/refunded checkout, or second payment on a paid one -> refund (`RefundClosed`).
  - VIRTUAL_ACCOUNT_ISSUED on open checkout -> `awaiting_deposit`.
  - Pending, expired, provider has no PAID -> `expired` (409 `checkout_expired`).
  - Otherwise unchanged (confirm returns `payment_failed` for READY/FAILED etc.).
- Reconciler (`reconciler::spawn`): enabled when `DEV_MODE=1` or `PORTONE_API_SECRET` set. Every `RECONCILE_INTERVAL_SECS` (default 60, min 10): pending checkouts older than 24 h -> `expired`; claims up to 20 checkouts in status pending|awaiting_deposit|expired, created 2 min to 24 h ago, not checked in the last 5 min (`reconciled_at` stamp, `FOR UPDATE SKIP LOCKED` in the claim subquery); each is looked up at PortOne with payment id = checkout id and passed through `apply`.
- Partner gate: accept, quote submit and completion return 409 `phone_required` when `pros.phone IS NULL`. Feed and job view stay open.
- Abuse limits:
  - Rate limit per client IP per minute: `/v1/auth/*` 20, `/v1/uploads` 30, everything else 300 -> 429 `rate_limited`. Behind Caddy set `TRUSTED_PROXY=1` (uses right-most X-Forwarded-For).
  - Uploads: more than `UPLOAD_DAILY_QUOTA` (100) in 24 h -> 429 `upload_quota`.
  - Quote requests: a customer with 3 open quote bookings (status 0) -> 409 `too_many_open_requests`.
  - Chat: more than `MAX_CHAT_THREADS_PER_DAY` (10) new free-standing customer threads in 24 h -> 429 `thread_quota`.

## Assumptions to confirm at compile/run time

- Let chains (`if let ... && let ...`) in `checkouts.rs`, `webhooks.rs`, `find_by_payment` (edition 2024, already used in repo).
- `Option::is_none_or` (Rust 1.82+) in `ratelimit.rs`.
- axum 0.8: `middleware::from_fn_with_state`, `extract::{ConnectInfo, Request}`, `middleware::Next`, `Router::into_make_service_with_connect_info`. ConnectInfo read from `req.extensions()`.
- sqlx 0.8: `query_as` with `format!`, `FromRow`, `Transaction` rollback on drop, `Option<String>` bound to `$1::text`, `hashtext` advisory locks.
- SQL: `UPDATE ... WHERE id IN (SELECT ... LIMIT n FOR UPDATE SKIP LOCKED) RETURNING ...`; the default name `checkouts_status_check` is dropped with `IF EXISTS`.
- chrono 0.4: `Duration::hours/seconds`, `DateTime<Utc> - Duration`.
- tracing field shorthand `payment_id` (a `&str`).
- `domain::DomainError::code(&self) -> &'static str` (crates/domain/src/error.rs) used by `refund_reason`.
- `realtime::notify(&AppState, Recipient, &'static str, &str, &str, Value) -> ApiResult<()>`.
- `PaymentInfo` has no new field (kept on purpose: providers.rs is shared with the other agent).
- `reconciler::spawn` future must be `Send` (tokio::spawn).
- `Config` has no struct literal outside `from_env`.
- `ApiError::Quota` arm mirrors the `Conflict(c)` pattern in `status_and_code`.

## Commands (run later, in order)

```
source /f/EC/scripts/env.sh; cd /f/EC/backend && cargo fmt --all && cargo clippy --all-targets -j 2 -- -D warnings && cargo test -j 2
```

Then, in a second shell, start Postgres and the API in dev mode, and run the smoke test:

```
/f/EC/scripts/dev-api.sh
python -I /f/EC/scripts/smoke.py
```

Migration check (optional): `psql -h localhost -p 5433 -U postgres -d cleaning -c "\d checkouts"` should show `refund_reason`, `reconciled_at`, and the CHECK including `refunded`. `\d uploads` should exist.

Unit tests added (all in-module):
- `ratelimit::tests`: window admit/refuse, sliding release, key isolation, idle sweep, bucket mapping, X-Forwarded-For right-most parsing, `client_ip` trust rules, `within_quota` boundaries.
- `routes::checkout_policy::tests`: exhaustive decision table; PAID-only money invariant; refund reason codes.
- `routes::webhooks::tests`: signature gate truth table; payment event filter.
- `reconciler::tests`: enabled rule.
- `providers::portone::tests`: customData parsing (object and JSON text); dev gateway UUID and fake ids.

## Risks for the compile pass

- `checkouts.rs` ~660 lines, `checkout_policy.rs` ~190. `routes/partner_jobs.rs` ~510 (already over the 400 target; not split).
- Dev behaviour change: the dev fake pays any checkout id, so the reconciler auto-settles pending dev checkouts about 2 minutes after creation. Intended for exercising recovery; expect bookings to appear in dev.
- Flutter app must pass `checkout.id` as the PortOne `paymentId` for the recovery path to find payments by id. Otherwise recovery relies on `customData.checkoutId`, which the app must also set. Not changed in this task.
- Rate limits are per process (in memory). Multiple API replicas each allow the full limit. Caddy must set `X-Forwarded-For`, and `TRUSTED_PROXY=1` must not be set when clients reach the API directly.
- Smoke needs the auth limit lifted (`RATE_LIMIT_AUTH_PER_MIN=1000`, set in dev-api.sh and CI). Without it, sign-ins in smoke hit 429.
- Upload quota uses a transaction-scoped advisory lock per user; still a per-user serialization point on upload.
- Photos (`/files/...`) count against the general 300/min bucket. Heavy apps may hit it.
- Quote cap counts only status 0 quote bookings. Cancelled or completed requests free a slot.
- Thread quota counts only customer threads created without a booking.
- Refund reason codes are stored in `refund_reason`; they are not yet shown anywhere in the console.
