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
- 2026-11-10 Session 1c: Korean social sign-in (Kakao/Naver/Google/Apple) + PASS identity + PortOne checkout for all Korean methods (card, Kakao/Naver/Toss/PAYCO/Samsung/Apple Pay, transfer, virtual account, phone) with signed webhooks; 3D design system (Tilt3D, Pressable, clay glyphs, glass, aurora), dark theme default + toggle in all apps; 14 languages (ko en zh vi ja ru ne si th id mn uz fil km; tool/lang_*.py, validated by tool/check_lang.py + gen_arb). Customer booking skips address step when one address fits. Open: native-speaker review for mn/si/ne/uz/km/fil; real SDK/PG keys; card-payment recovery via PortOne customData when confirm never arrives.
- 2026-11-10 Session 1b: review + hardening pass. Open review items (LOW): per-IP rate limiting (needs proxy IP config), push-token ownership on re-register, upload quotas, quote-request spam limits, team-member logins, refund idempotency key at the provider, large files to split (bookings.rs, booking_flow.dart, partner jobs.dart).
- 2026-11-10 Session 1: specs, design canvas, domain + API (smoke green), Flutter workspace, customer/partner/console apps (analyze clean), 5 languages, deploy kit. Screenshots verified customer intro/home + console dashboard/bookings. Next: real provider adapters once owner has accounts, CI, widget tests, store prep.

### 2026-11-11 — 1.0 push (setup wizard, installer, website, store readiness)
- Compile/debug pass of `wip/uncompiled-expansion`: backend compiled first try; fixed test slot hour; 53 widget tests fixed (10 real UI bugs). Merged to `master` (dc0bb44).
- Setup system: `integration_settings` (AES-GCM), providers hot-swap keys, connection tests; `/v1/setup` first-run owner with setup code; `/v1/brand`; review demo account; partner self-deletion (`0008`).
- Deploy: single-domain Caddy (website `/`, console `/admin/`, API), `deploy/install.sh`, `malkkeum` CLI, release workflow (GHCR + installer asset), CI builds images.
- Website (`website/`): three.js hero, live prices from `/v1/services`, footer/legal filled from `/v1/brand`.
- Store: `scripts/store_ready.py`, icons via `F:/tools/shot/icons.js`, `codemagic.yaml`, `docs/store/*`, `docs/guide/*`.
- Next: features plan items 1, 2, 4, 6, 7; in-app wow layer; real SDK keys; store screenshots; first real install on a VPS.


### 2026-11-11 (evening) — complete suite push (10 parallel feature branches, merged + verified centrally)
- Features: AI support agent (Claude, offline/always-first modes, per-thread pause, usage; mig 0009); reviews, referrals, welcome offer, honest social proof + seats-left (0010); demo data `malkkeum demo load|clear` + `docs/sample-data.md` (0011); finance dashboard, charts, accountant CSV (UTF-8 BOM, formula guard), partner earnings; system status page, owner alerts, encrypted S3-compatible offsite backups (0013); in-app 3D cards/transitions/celebrations, contrast-tested palette; update channels (stable/beta), safe update + auto-rollback, CI install e2e, app update prompts; native Kakao/Naver/Google/Apple sign-in + Firebase push (keys from Codemagic via `scripts/ci/native-keys.sh`); customer web app (PWA) at `/app/`; generated store screenshots/listings (`scripts/store/generate.sh`).
- i18n: server push/inbox/SMS in recipient language (`backend/crates/api/src/i18n.rs`), OTP SMS in app language, first-launch language picker.
- Quality: 14-language × 320px × 1.3x text sweeps for customer and partner (`test/locale_sweep_test.dart`) — fixed every overflow found; real-font store renders caught one more (arrival grid).
- Security review: all HIGH/MEDIUM fixed except CSP tightening (needs a live PortOne check); jsonwebtoken → 10.3 (GHSA-h395-gr6q-cpjc).
- Totals: Rust 177 tests, Flutter 201+ tests, analyze/clippy/shellcheck/actionlint clean.
- Blocked: GitHub Actions jobs for the private repo stay queued (no runner assigned) → owner must check GitHub billing/spending limit; release v1.0.0 waits on it. Then make GHCR packages public once.
