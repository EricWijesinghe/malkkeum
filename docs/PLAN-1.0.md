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
- [ ] 1 Stabilize
- [ ] 2 Wow layer
- [ ] 3 Setup system
- [ ] 4 Installer + hosting
- [ ] 5 Website
- [ ] 6 Store readiness
- [ ] 7 Handover
