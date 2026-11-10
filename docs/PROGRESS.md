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
- [ ] API: auth (phone OTP + JWT), addresses, catalog, bookings, payments, coupons
- [ ] API: chat (WebSocket), push, photos, quotes desk, partner jobs (atomic accept), settlements
- [ ] Postgres migrations + seed; docker-compose (postgres, api, minio)
- [ ] Flutter workspace: ui package (tokens, components), core package (API client, models, l10n)
- [ ] Customer app: all ~25 screens
- [ ] Partner app: all ~18 screens + onboarding
- [ ] Console: bookings, quote desk, inbox, catalog, marketing, partners, settlements, staff roles
- [ ] Translations for 5 languages
- [ ] Release: signing, store listings, CI, deploy guide (docs/DEPLOY.md)

## How to build
```
source scripts/env.sh
cd backend && cargo test
```

## Log
- 2026-11-10 Session 1: specs read, design canvas, repo init, domain crate green.
