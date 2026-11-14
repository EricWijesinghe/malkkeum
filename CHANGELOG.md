# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Server releases are git tags `vX.Y.Z`
(see [docs/DEPLOY.md](docs/DEPLOY.md#2-releases-and-channels)). Entries up to 1.4.0 were reconstructed
from the release branches; no tags existed for them.

## [Unreleased]

### Added
- Owner can queue server jobs (backup, update, update-skip, channel, restart, schedule) from the API: each accepted job is one file in the server job inbox with owner TOTP on the request and a double click queues one job; live state (queued, running, ok, failed) is read back from the server's status files as capped text (`/admin/host/jobs`).
- Renewal calendar (갱신 일정) in the console: domains, old-domain aliases, hosting, store and SMS accounts, storage, and the yearly keys check. The owner gets an SMS 30 and 7 days before each date; the keys check follows the last successful upload test.
- Server job runner (`deploy/agent.sh`, root) is installed and started by the installer on new installs and updates (systemd path, service and timer units). It runs schedule, update, update-skip, channel, restart and status jobs; a stable update waits 24 hours after a new digest is first seen; live progress is served read-only at `/ops-progress/<token>` for 10 minutes after a job ends; `dahae setup-code` expires after 2 hours (`--renew` gives a new code); `MALKKEUM_ANSWERS` installs without questions.
- Owner activity log (활동 기록): newest first, filter by person, kind and day; owner only (`GET /v1/admin/audit`).
- Keys bundle: the owner downloads DATA_KEY and JWT_SECRET sealed under a server-generated passphrase, and proves
  it opens with an upload test (owner TOTP on each request); `api keys-open` prints the two keys for restores.
- Maintenance mode is set in the owner's rules (점검 모드, message included) and read by the apps from `/config`. While it is on, the apps show a banner, customers cannot submit a new booking, and the API refuses new bookings only: direct and quote bookings, waitlist accepts, subscriptions and new booking checkouts. Cancellations and payments on existing bookings stay open. If the API is down, the website shows a static maintenance page instead of a bare 502.
- Owner settings registry: business limits, marketing cap, points cap, quality window and ops alert thresholds are read from the database (env is the seed), validated, and audited on every change.
- Owner console: app link values (Android signing fingerprints, Apple Team ID) can be saved and checked under the setup screen's "앱 링크" card. Saved values override the `ANDROID_CERT_SHA256` and `APPLE_TEAM_ID` server settings, which remain the fallback.
- Console "알림 문구" screen: edit the push and inbox text of each customer and cleaning-team notification in Korean and English, with a preview and restore to the built-in text. Only the placeholders listed for each notification (booking number, business name) can be used.
- Console: 탈퇴·개인정보 요청 screen. Staff find a customer by phone, download the customer's data as CSV, and see every request's outcome. Deletion is admin-only and needs the phone typed again; each request is recorded (migration 0157).
- Console setup: a PortOne cash receipt switch (off by default, saved value beats the env default). Changing Toss payouts needs the owner's TOTP in the same request. Services that need a developer's first-time help are badged, and guide cards reserve screenshot slots.
- Console catalogue: add a new service (code, name, fixed price or quote), archive one by switching it off, edit peak-hour surcharges and quality thresholds, edit a subscription's cadence, day and start time, and load or remove sample data (removal needs the owner's authenticator code).
- Customer app: guests see how a booking works on the Bookings tab and the FAQ and terms on the Chat tab (chat still asks for sign-in). The welcome offer and the referral amount show before sign-in, and a quote in progress is kept on the device across restarts.
- Public `GET /v1/public/offers`: welcome offer, sign-up coupons and referral amount for guests, cacheable for 5 minutes, no user data.

### Changed
- Partner app: review reply button hidden until replies ship; sign-out asks for confirmation; version row reads the installed build (PackageInfo); job detail and job cards show counts (e.g. 벽걸이 1 · 스탠드 2) and quote jobs show the home type (원룸·투룸 / 아파트 / 빌라·주택).
- Staff invites and password resets now use a one-time 6-digit code sent by SMS (or copied by the admin), valid 24 hours, single use, locked after five wrong tries; consultants can invite consultants only.
- Customer app: guests see the quote price before the address step without signing up; sign-in is asked only when they book, and the service detail shows the price-first line.
- Customer app: guests get the sign-in sheet with a reason for each protected action (chat, account, booking), member-only menu rows show a sign-in hint, the notifications screen shows only notices, and a nameless new account opens the name step after signing in from the sheet.
- Release hardening: release tags must point into master, the image and delivery jobs run in protected
  environments, every action is pinned to a commit, and the installer's SHA256SUMS is cosign-signed. An
  ed25519-signed installer manifest and a cloud-init install page are published with each release.
  Not done yet: a dispatch-driven release that replaces `scripts/release/build-all.ps1` and its
  `PASSWORD.txt`, and an Android-signing environment. Both still run locally.
- Customer and partner apps take the business colour and logo from the business profile, keep the last good copy for offline start, and the console warns when white button text would be hard to read on the chosen colour.
- Server installer: stricter domain and email checks, and settings values can no longer split `.env` lines.
  A root job runner (`deploy/agent.sh`) checks queued server jobs before running a fixed command.
- API JWT library upgraded from jsonwebtoken 10.3 to 11.1; token formats, verification rules and the Apple client secret are unchanged.
- Customer bookings, notifications, wallet points history and payment history, and partner quotes
  page through their lists on scroll (with a bottom loader and retry on error) instead of showing
  only the first 50 rows; the points ledger has a paged `GET /me/points/ledger` endpoint.
- SMS and AlimTalk to customers, partners and reminders now go through the notification outbox: a provider outage is retried with backoff, and a text that fails 8 times is dead-lettered, counted on the console's outbox card and raised as an owner alert. OTP codes stay inline with one quick retry.
- Website seller details (상호, 대표자, 사업자등록번호, 통신판매업 신고번호, 주소, 연락처, 호스팅 제공자, 개인정보 보호책임자) are written into the HTML by the server (Caddy includes `/v1/public/seller-info`), so they are visible without JavaScript; the JavaScript fill and the `build_legal.py --brand` bake are removed.
- 정산 내역 CSV (`/admin/finance/export/settlements`) ends with a 합계 row; KST month edges and totals covered by tests.
- Hardening: new encrypted values carry a version prefix and are bound to their column (old values still read); login codes use `OTP_PEPPER` when set; no-show cases are unique per booking; reviews reaching the report threshold are queued for staff, not hidden; reading partner quotes no longer changes them (a timer closes stale ones); setup code kept out of the structured log.

### Security
- Live-event sockets open with a 30-second, single-use ticket from `POST /v1/realtime/ticket` instead of the access token in the URL, so the long-lived token no longer reaches proxy and access logs. The old `?token=` form still works for one release. Silent sockets are pinged every 25 s and closed after 60 s without an answer.

## [1.4.0] - 2026-11-13

### Added
- 다해 (Dahae) brand across the apps, console, website and store material: design tokens, 3D icon set,
  new home, bookings, chat, booking flows and More tab; remaining design gaps closed (white flow canvas,
  banner art card, address sheet with search, teal brand word).
- One-command installer with the `dahae` CLI: preflight, signed images (cosign keyless), restore,
  uninstall, update channels, rollback-safe migrator, arm64 images, `www` redirect.
- Install end-to-end test (tar mode, wizard, restore, smoke, uninstall), upgrade path from an older
  installer, and a WSL harness.
- Owner console as a sideloadable Android APK with a first-launch server address screen.
- iOS release hardening (web credentials, per-app signing, IPA checks).
- Crash and error reports from the customer and partner apps to the API's own `client_errors`
  (no third-party SDK), declared in the store privacy answers and iOS privacy manifests.
- Durable notification outbox and a replica-safe background job runner with per-job health; the console
  status page shows each job's last success and flags stalled ones.
- Durable refund queue: a compensating refund that fails is retried with backoff and alerts the owner;
  customers see "refund in progress" until it lands.
- Cursor pagination (`X-Next-Cursor`) on long lists; the console, partner and chat lists load more on
  scroll.
- Repository guides: CONTRIBUTING, SECURITY, CODEOWNERS, issue and pull request templates, `.editorconfig`.
- Website: canonical and Open Graph / Twitter metadata, JSON-LD (`LocalBusiness`, `Service`, `WebSite`),
  self-hosted font subset, legal-page revision history, business details baked in on request
  (`scripts/build_legal.py --brand`).
- `scripts/local.env.example`: machine-specific tool locations, read by `scripts/env.sh` and the
  PowerShell release scripts.

### Changed
- Korean and English only. Twelve more languages are archived in `archive/i18n-extra-languages` with
  restore steps; accounts that used one read English.
- CI runs on GitHub-hosted runners only; the Rust and Flutter toolchains, actions and base images are
  pinned; cargo-deny, image scanning and SBOMs gate every release, and a tag publishes nothing unless CI
  and the install end-to-end test pass on it.
- Hardened compose stack (read-only filesystems, dropped capabilities, resource limits), working offsite
  backups, a copy of the encryption keys and alerts on failed unattended jobs; strict website CSP with no
  third-party hosts.
- Smaller apps: the Korean font subset (Dahae Sans) cuts fonts from 7.6 MB to 2.9 MB per app.
- A failed refresh keeps the data on screen with one notice instead of a blank error page; the partner
  app opened without signal starts from the last saved profile and catches up when the connection returns.
- The website hero loads a smaller three.js build only after first paint, and never with reduced motion.
- Documentation states RPO/RTO and how to keep `DATA_KEY` safe.

### Fixed
- Payments: each PortOne payment is bound to one checkout; idempotency keys are scoped to the verified
  user and reused per action, so a retry after a lost reply never charges twice; a confirm that never
  answers waits and resumes for the same account only.
- Cancellations refund once, under the booking lock, against the provider's cancellable balance; saved-card
  charges (tips, waitlist, deposits) go through PortOne billing; money actions check the live staff role.
- Abuse and privacy: durable sign-in lockout and rate limits, review report quorum, EXIF stripped from
  uploads.
- Sign-out clears the previous account's data, pending payment and live connection.
- Payment races: a deposit settled for a booking another checkout already confirmed is refunded.
- Installer security: non-superuser API database role, restore guards, `.env` permissions; Caddyfile
  parses on real servers.

### Removed
- Hardcoded developer-machine paths and account names from scripts and install guides.

## [1.3.0] - 2026-11-12

### Added
- Store readiness: privacy manifests, Data Safety answers, predictive back, native symbols, store
  screenshot pipeline and a single rising build number.
- Complete account deletion with Sign in with Apple revocation and server notifications, Kakao and
  Naver unlink.
- 전자상거래법 seller details in the customer app and website footer; hosting provider field.
- Points wallet, payment history and receipts; guest mode and personalised feed.
- Current-location address lookup behind location-terms consent.

### Fixed
- Strict CSP for the console and web app (no Google hosts).
- Large-table migrations rebuilt with `CONCURRENTLY` and `NOT VALID` + `VALIDATE`.

## [1.2.0] - 2026-11-12

### Added
- Operations screens, staff MFA and lockout, booking policy, tax exports, partner and console
  improvements; public API contract (`openapi.json`).

## [1.0.0] - 2026-11-11

### Added
- Setup wizard with encrypted integration keys and connection tests; first-run owner account.
- Single-domain deployment (Caddy: website, console, API), installer, backups and weekly updates.
- Website with live prices and legal pages; store listings and generated screenshots.
- AI-assisted support replies, reviews, referrals, demo data, finance dashboard, offsite backups,
  customer web app (PWA), native social sign-in and push.

## [0.1.0] - 2026-11-10

### Added
- Domain core (catalog, pricing, quotes, coupons, booking states, payouts) and the API
  (auth, bookings, payments, chat, quote desk, partner jobs, console, audit log).
- Customer, partner and console apps on a shared Flutter workspace; CI pipeline.
