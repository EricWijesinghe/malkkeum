# Build progress

Living log. Update at the end of every work session. Newest first in "Log".

## Product
Korean home-cleaning platform (working name 말끔, swappable brand). Specs: `NTD/`.
Three apps + one backend, all from this repo:

| Surface | Tech | Targets |
|---|---|---|
| Customer app | Flutter | Android, iOS (later Windows/macOS/Linux) |
| Partner (pro) app | Flutter | Android, iOS |
| Ops console (admin) | Flutter | Windows desktop, Android/iOS phone, web |
| Backend | Rust (axum, sqlx, Postgres) | Docker, self-hosted; cloud-portable |

Languages: ko (default), en, ja, zh-Hans, vi.

## Decisions
- 2026-11-10 Admin console moved from React to Flutter: owner wants it on phone **and** Windows; one stack shares design system + translations.
- 2026-11-10 Every SDK, cache and build lives on F: (`scripts/env.sh`).
- 2026-11-10 External services behind Rust traits with local fakes: payments (Toss/PortOne), SMS OTP, push (FCM/APNs), address search (Kakao/juso), masked 050 numbers, AlimTalk, object storage.
- 2026-11-10 Scope = spec "In" items, polished; extras go on `docs/PITCH.md` for the owner to approve.
- Visual: colorful-professional. Ink text, white surfaces, one hue per service, trust blue + fresh mint brand.

## Roadmap
- [x] Design canvas v0.1 (internal design canvas, source `design/canvas`)
- [x] Rust domain core: catalog, pricing, quote formula, coupons, booking states, schedule, partner payouts (22 tests)
- [x] API: auth (phone OTP + JWT refresh rotation, staff argon2), addresses, catalog, bookings, payments (fake PG), coupons, refunds
- [x] API: chat REST + WebSocket hub, notifications, uploads, quote desk, partner feed/atomic accept/quotes/completion/settlements, console CRUD, audit log
- [x] Postgres migrations + idempotent seed; `scripts/smoke.py` e2e (13 checks) green
- [ ] Real provider adapters: Toss/PortOne, SMS (NHN/Aligo), FCM/APNs, Kakao address, 050 numbers, AlimTalk
- [ ] Team-member logins (members currently get SMS only)
- [ ] Deploy: Dockerfile, docker-compose, TLS reverse proxy, backups
- [x] Flutter workspace (pub workspace `app/`): `packages/ui` (tokens, service hues, theme light/dark, components, Pretendard), `packages/core` (API client w/ refresh, secure session, realtime, models, i18n helpers, Seoul districts)
- [x] Strings: `app/tool/strings_*.py` -> `python -I app/tool/gen_arb.py` -> 5 ARB files (ko/en/ja/zh/vi), checked for missing/placeholder drift
- [x] Customer app: intro/OTP/profile, home, service, address, schedule, checkout, done, quote flow (6 steps), bookings calendar/list, detail (timeline, deposit/balance, photos, review, notes, reschedule, cancel), chat list/room (quote card, photos, quick replies), more (coupons, points, account, addresses, payments, scope, notices, tips, FAQ, language, legal, licenses, delete account). Web + Android debug builds OK.
- [ ] Customer: real PG registration SDK, Kakao address search, push (FCM), move-in cross-sell coupon claim, before/after review carousel on quote type step
- [x] Partner app: intro/OTP, onboarding (name, team, services, districts), pending/suspended gates, jobs feed (direct/quote, sort, closed), job detail (masked before accept, accept sheet, quote sheet w/ live payout, assignee, memo, reschedule reply, cancelled banner, payout breakdown), my quotes (filters, edit/withdraw), schedule month view, completion (photos + checklist + success), ops chat, settlements, reviews, areas, work schedule, payout account, team, notifications, language
- [x] Console (Flutter: Windows / phone / web): staff login, Ctrl+K palette, Ctrl+1..9, dashboard KPIs + by-service bars, bookings split view w/ status/assign/cancel-refund, quote desk (answers, estimate breakdown, partner quotes, send), inbox (customer/partner, J/K, Ctrl+Enter), catalog prices/capacity/formula, coupons + 5-language content editor, partners approve/suspend, settlements payout run + transfer sheet + hold, customers, staff (admin only)
- [x] Translations: 5 languages for all three apps (~580 keys)
- [x] Deploy kit: backend/Dockerfile, deploy/docker-compose.yml (+Caddy HTTPS), deploy/.env.example, docs/DEPLOY.md; extras list docs/PITCH.md
- [ ] Release: signing keys, store accounts, final app IDs/brand/icons (owner decisions, see DEPLOY.md §3)
- [x] CI pipeline `.github/workflows/ci.yml` (fmt, clippy -D warnings, tests, e2e smoke, dart analyze --fatal-infos, core tests)
- [x] Independent reviews (security, Rust correctness, Flutter) on 2026-11-10; all HIGH and most MEDIUM fixed (see commits 2302ea7, 5b3bc56)
- [ ] Widget tests for key flows (currently: Rust unit + e2e smoke; Flutter verified by analyze + screenshots)
- [ ] Design canvas refresh to the colorful v1 palette (code is the source of truth now)

## How to build / run
```
source scripts/env.sh
cd backend && cargo test          # unit tests
scripts/dev-api.sh                # Postgres (F:/tools/pgdata, port 5433) + API on :8080, DEV_MODE fakes
python -I scripts/smoke.py        # end-to-end checks against the running API
```
Screenshots: `node F:/tools/shot/tour.js` (Playwright on F:) against `flutter build web` served on :5173.
Dev console login: admin@local.test / change-me-now-please (from backend/.env, change it).

## Log
- 2026-11-10 Session 1b: review + hardening pass. Open review items (LOW): per-IP rate limiting (needs proxy IP config), push-token ownership on re-register, upload quotas, quote-request spam limits, team-member logins, refund idempotency key at the provider, large files to split (bookings.rs, booking_flow.dart, partner jobs.dart).
- 2026-11-10 Session 1: specs, design canvas, domain + API (smoke green), Flutter workspace, customer/partner/console apps (analyze clean), 5 languages, deploy kit. Screenshots verified customer intro/home + console dashboard/bookings. Next: real provider adapters once owner has accounts, CI, widget tests, store prep.
