# Project status

Current state of the platform and the work still open. Release history is in
[CHANGELOG.md](../CHANGELOG.md); product specs are in [`docs/specs/`](specs/).

## Product

Korean home-cleaning platform **다해 (Dahae)**: three Flutter apps and one Rust backend, all from this repo.

| Surface | Tech | Targets |
|---|---|---|
| Customer app | Flutter | Android, iOS, Web (PWA at `/app/`), Windows |
| Partner (pro) app | Flutter | Android, iOS |
| Owner console | Flutter | Web (`/admin/`), Android (sideload), desktop |
| Backend | Rust (axum, sqlx, PostgreSQL) | Docker, self-hosted |

Languages: Korean (default) and English.

## Design decisions

- The owner console is Flutter, not a separate web stack: the owner uses it on a phone and on Windows,
  and one stack shares the design system and translations.
- External services sit behind Rust traits with local fakes (payments, SMS/AlimTalk, push, address
  search, object storage), so every flow runs offline in `DEV_MODE`.
- Every integration key is entered in the console setup wizard and stored encrypted (AES-GCM with
  `DATA_KEY`); environment variables remain only as a developer override.
- Internal identifiers keep the original `malkkeum` name (app ids, image names, env vars, metrics);
  only user-visible text says 다해 / Dahae. See [REBRAND-CHECKLIST.md](REBRAND-CHECKLIST.md).

## Open items

- [ ] Release signing keys, store accounts and the first store upload (owner decisions, see
      [DEPLOY.md §3](DEPLOY.md#3-store-apps-per-client)).
- [ ] Real provider keys (PortOne/Toss, Solapi, FCM/APNs, Kakao/Naver/Apple/Google sign-in) on the
      production server.
- [ ] First install on a production VPS with offsite backups configured.
- [ ] Golden-test baselines generated in CI and enforced.
- [ ] Legal review of the terms (제5조 cancellation tiers, dispute wording) before launch.

## How to build and run

```bash
source scripts/env.sh             # tool locations from scripts/local.env (see local.env.example)
cd backend && cargo test          # unit and integration tests
scripts/dev-api.sh                # Postgres on :5433 + API on :8080 with DEV_MODE fakes
python -I scripts/smoke.py        # end-to-end checks against the running API
```

The dev console login is created from `backend/.env` on first run (`SEED_ADMIN_EMAIL` /
`SEED_ADMIN_PASSWORD`); it is for the local database only.
