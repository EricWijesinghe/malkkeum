# Dahae (다해)

Home-services platform for the Korean market: on-demand and quoted cleaning (studio, move-in/move-out, kitchen, bathroom, mattress, air-conditioner, sofa), with a customer app, a partner (cleaner) app, an owner console and a self-hosted backend.

## Product surfaces

| Surface | Stack | Targets |
|---|---|---|
| Customer app | Flutter | Android, iOS, Web (PWA at `/app/`), Windows |
| Partner app | Flutter | Android, iOS |
| Owner console | Flutter | Web (`/admin/`), Android (sideload), desktop |
| API | Rust · axum · sqlx · PostgreSQL | Docker, any Linux VPS |
| Website | Static HTML + three.js | Served by Caddy at `/` |

## Features

- **Booking** — fixed-price services with live pricing from the catalog, quote flows for move-in/out with a 10% deposit, rescheduling, cancellation and refunds.
- **Payments** — PortOne V2 with Toss Payments as the PG channel (cards, Kakao/Naver/Toss/Samsung/Apple Pay, transfer, virtual account); signed webhooks, reconciliation, receipts, points and coupons. Partner payouts via Toss.
- **Authentication** — phone OTP, Kakao / Naver / Google / Apple sign-in, PASS identity check, staff accounts with MFA and lockout, account deletion with provider unlink/revoke.
- **Messaging** — real-time chat (WebSocket) with quote cards, push (FCM/APNs), Kakao AlimTalk, in-app notification inbox; optional AI-assisted support replies.
- **Operations** — console dashboard, quote desk, inbox, catalog and pricing editor, partner approval, settlements, finance exports, audit log, setup wizard with encrypted integration keys.
- **Internationalisation** — Korean (default) and English, server-side messages in the recipient's language. Twelve more languages are archived in `archive/i18n-extra-languages` (restore steps in its README).
- **Delivery** — one-command installer (`curl | bash`) with signed images, automatic HTTPS, backups, safe updates with rollback and the `dahae` CLI.

## Repository layout

```
app/                 Flutter workspace
  apps/customer      customer app
  apps/partner       partner app
  apps/console       owner/staff console
  packages/core      API client, session, models, i18n
  packages/ui        design system, theme, 3D icon set, motion
  tool/              string tables -> ARB generation
backend/             Rust workspace
  crates/domain      pricing, booking state machine, payouts (pure logic)
  crates/api         HTTP/WebSocket API, providers, migrations runner
  migrations/        PostgreSQL migrations
deploy/              installer, docker-compose, Caddy configuration
website/             marketing site, legal pages, payment pages
design/              3D icon pipeline and exported assets
docs/                deployment, store, operator guides, specs
scripts/             CI checks, release and demo tooling
```

## Getting started

Requirements: Rust (stable), Flutter (stable), PostgreSQL 17.

```bash
# backend — create backend/.env with DATABASE_URL, JWT_SECRET, DATA_KEY,
# PUBLIC_BASE_URL and DEV_MODE=1 (see scripts/dev-api.sh for a template)
cd backend
cargo run -p api                    # applies migrations, serves on :8080

# apps
cd app
flutter pub get
cd apps/customer && flutter run --dart-define=API_BASE=http://localhost:8080
```

## Testing

```bash
cd backend && cargo clippy --all-targets -- -D warnings && cargo test
cd app && dart analyze --fatal-infos
cd app/apps/customer && flutter test        # likewise for partner, console, packages/*
python scripts/ci/check-native.py           # store/native configuration checks
python scripts/ci/check-migrations.py
```

CI (`.github/workflows/ci.yml`) runs formatting, lints, unit and integration tests, an end-to-end smoke test and the installer self-test.

## Deployment

See [`docs/DEPLOY.md`](docs/DEPLOY.md) and the operator guides in [`docs/guide/`](docs/guide/). Store submission material lives in [`docs/store/`](docs/store/).

## License

Proprietary. All rights reserved. See [LICENSE](LICENSE).
