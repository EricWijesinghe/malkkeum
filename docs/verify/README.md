# Compile & debug pass — start here

Branch `wip/uncompiled-expansion` holds code written while the machine was overloaded: **none of it has been compiled or run.**
`main` is the last verified state (commit 729ebac). Work through this list in order, then merge to `main`.

## Order
1. **Backend compiles.** `source /f/EC/scripts/env.sh; cd /f/EC/backend && cargo fmt --all && cargo clippy --all-targets -j 2 -- -D warnings`
   - First check `crates/api/src/lib.rs`: two agents edited it at the same time (lib+bin split, reconciler, rate limiter, connect-info).
   - `tests/common/mod.rs` builds a `Config` literal — it must match every field in `config.rs`.
   - Details: `backend-payments.md`, `backend-providers.md`.
2. **Backend tests.** `cargo test -j 2` (unit), then DB flow tests need `DATABASE_URL` for the local superuser
   (Postgres on F:/tools/pgdata, port 5433, password in `backend/.env`).
3. **End-to-end.** `scripts/dev-api.sh` then `python -I scripts/smoke.py` (dev-api sets `RATE_LIMIT_AUTH_PER_MIN=1000`).
4. **Flutter.** `cd /f/EC/app && flutter pub get && python -I tool/gen_arb.py && (cd packages/core && flutter gen-l10n) && dart analyze --fatal-infos`,
   then `flutter test` in packages/core, packages/ui, apps/customer, apps/partner, apps/console. Details: `flutter-tests.md`.
   Expect finder/import fixes on the first run of the new widget tests.
5. **Not started — do next:** `flutter-features-plan.md` (booking_flow split, console payment methods + reconciliation screens,
   notification inbox, partner phone gate, team-member mode, PortOne paymentId rule).

## Decisions made while reviewing
- The checkout reconciler runs **only with a real PortOne secret**. In dev mode the fake gateway reports any checkout as paid,
  so reconciling would have turned abandoned checkouts into bookings.
- The app must use `checkout.id` as PortOne's `paymentId` (recovery depends on it).
- A test agent suspected `MaterialApp.home` doesn't swap after sign-in; the browser run on `main` did reach Home after OTP,
  so treat a failing `login_test` there as a test issue first.
