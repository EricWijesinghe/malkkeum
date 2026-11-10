# Malkkeum 1.0 — release plan (approved 2026-11-10)

Goal: a complete system the owner (non-technical) runs from the console, installed and deployed by his brother
(little IT knowledge) **without touching code, config files or a terminal beyond one installer step** — set up like an
industry-grade product (installer → web setup wizard → status page).

## Rules
- No setup step may require editing code, `.env`, YAML or JSON. Everything after install is done in the console wizard.
- Every integration key is entered in the console, stored encrypted in the database (AES-GCM, DATA_KEY), testable with a
  "연결 테스트" button. Env vars remain only as an override for developers.
- Every error the owner can see is plain Korean with a one-line fix and a link to the guide page.
- Guides in Korean with screenshots for everything only the owner can do (business registration, store accounts, PortOne).

## Phases
1. **Stabilize** — compile/test/smoke the `wip/uncompiled-expansion` branch, merge to `main`; finish
   `docs/verify/flutter-features-plan.md`.
2. **Wow layer** — clay 3D renders with tilt/touch parallax, Rive-style animated moments, home 3D carousel, before/after
   slider, animated booking path + tracking timeline, partner earnings chart; dark+light pass; 청연 side-by-side.
3. **Setup system**
   - `settings` table (encrypted secrets) + `/v1/admin/setup/*` (status, save, test per integration); providers read DB
     settings first, env second; hot-reload without restart.
   - Console first-run wizard: business info + logo + brand color, services/prices, connections (PortOne, Kakao, Naver,
     Apple, Google, Solapi, FCM) with guides and tests, payout account, staff invites; status page ✅/⚠️.
   - First-run admin creation in the browser (no seed password in env).
   - Korean alerts to the owner (AlimTalk/SMS) on integration failure.
4. **Installer + hosting** — one-click deploy (Render blueprint / Railway template) with managed Postgres + backups, and a
   single-command VPS installer (`install.sh`: Docker, compose, HTTPS via Caddy, generated secrets, auto-update, daily
   backup). Both end at the wizard URL.
5. **Website** — `website/` static site, three.js 3D hero, services, reviews, FAQ, partner recruiting, 14 languages,
   legal pages (개인정보처리방침, 이용약관, 위치기반서비스 약관, account deletion). Served by Caddy.
6. **Store readiness** — icons/splash, release signing, Codemagic (iOS without a Mac + Android), privacy manifest, Data
   Safety answers, in-app account deletion, store listings + generated screenshots, v1.0.0.
7. **Handover** — Korean 사장님 가이드 (owner) and 설치 가이드 (brother), support button in console.

## Status
See `docs/PROGRESS.md` (session log) and the checklist below.
- [x] 1 Stabilize — branch compiled, all tests green, merged to master (2026-11-11). Features plan items 5 (phone_required label) done; 3 (payment methods) done in Setup; 1, 2, 4, 6, 7 still open (docs/verify/flutter-features-plan.md).
- [ ] 2 Wow layer — website 3D hero done; in-app 3D renders / Rive moments / earnings chart not started.
- [x] 3 Setup system — encrypted keys + tests, first-run owner, business profile, payment methods, store-review demo account. Owner alerts (Korean AlimTalk on failures) not done.
- [x] 4 Installer + hosting — install.sh + malkkeum CLI + backups + weekly update; release workflow → GHCR. Never run on a real server yet. Render blueprint not done.
- [x] 5 Website — index + legal + partners, live prices/brand, 14-language picker (5 full, others fall back to English).
- [~] 6 Store readiness — signing, permissions, names, icons, launch screens, Codemagic, listing text, data safety, partner account deletion. Missing: store screenshots, Firebase/Kakao/Naver app SDK wiring (needs real keys).
- [x] 7 Handover — docs/guide/01..04 (Korean).
