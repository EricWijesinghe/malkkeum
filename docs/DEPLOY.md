# Deploy & run guide

For the owner and whoever operates the service. Everything here builds from this repo.

## What gets deployed

| Piece | Where it runs | How people get it |
|---|---|---|
| API + database | One Linux server (any cloud or a rented VPS) via Docker | — |
| Ops console | Same server (web, `https://console…`) **and** a Windows app **and** an Android/iOS app | Browser / installer / store or internal testing |
| Customer app | Google Play + App Store | Store |
| Partner app | Google Play + App Store | Store |

## 1. Server (API, database, console website)

Needs: a Linux server with Docker, two DNS names pointing at it (e.g. `api.yourbrand.kr`, `console.yourbrand.kr`).

```bash
cd app/apps/console && flutter build web --release --dart-define=API_BASE=https://api.yourbrand.kr
cd ../../../deploy && cp .env.example .env   # fill in every value
docker compose up -d --build
```

Caddy gets HTTPS certificates automatically. The first admin account comes from `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`; sign in to the console and change it.

Backups: back up the `dbdata` and `uploads` volumes daily, and keep `DATA_KEY` somewhere safe. Without it, stored bank account numbers can't be read.

## 2. Ops console on Windows

```bash
cd app/apps/console
flutter build windows --release --dart-define=API_BASE=https://api.yourbrand.kr
```

The app is in `build/windows/x64/runner/Release/`. Zip that folder, or package it as MSIX (`dart run msix:create`) for a proper installer.

## 3. Phone apps (customer, partner, console)

Every app takes the API address at build time:

```bash
flutter build appbundle --release --dart-define=API_BASE=https://api.yourbrand.kr   # Android → Play Console
flutter build ipa --release --dart-define=API_BASE=https://api.yourbrand.kr         # iOS → App Store Connect (needs a Mac)
```

Before the first store upload:
- **App IDs**: currently `com.malkkeum.customer|partner|console`. Change them now if the final brand differs. They can't be changed after publishing.
- **Signing**: create an Android upload keystore (`keytool -genkey …`) and set it in `android/key.properties`. iOS needs an Apple Developer account ($99/yr) and a Mac with Xcode.
- **Store accounts**: Google Play Console ($25 once) and Apple Developer, both under the business name.
- **Brand**: swap `BrandConfig.placeholder` (name, colors) in `app/packages/ui/lib/src/tokens.dart`, then replace launcher icons (`flutter_launcher_icons`).

## 4. Before launch: real services to sign up for

The code has an adapter point for each. Dev mode uses safe fakes until then.

| Service | Purpose | Korean options | Where it plugs in |
|---|---|---|---|
| Payment gateway | Cards, KakaoPay/NaverPay/TossPay, saved billing keys, refunds | Toss Payments, PortOne | `backend/crates/api/src/providers.rs` (`issue_billing_key`, `charge`, `refund`) + card-registration screen in the customer app |
| SMS | Login codes, invites | NHN Cloud, Aligo, Solapi | `providers.rs::send_sms` |
| Push | New message, status changes | Firebase (FCM) + APNs | `providers.rs::push`; apps register tokens at `/v1/me/push-token` |
| Address search | Road-name address lookup | Kakao postcode, juso.go.kr | customer `AddressFormScreen` |
| Masked phone numbers | Pro ↔ customer calls | 050 virtual-number vendors | partner job detail "call" button |
| AlimTalk (optional) | KakaoTalk booking notices | Kakao business channel | alongside push in `realtime::notify` |

Legal: publish a privacy policy and terms (PIPA). Add them in the console under Coupons & content → Legal (slugs `privacy` and `terms`). The apps show them automatically.

## 5. Local development (this PC)

```bash
source scripts/env.sh          # all tools and caches live on F:
scripts/dev-api.sh             # Postgres on :5433 + API on :8080 (DEV_MODE fakes)
python -I scripts/smoke.py     # 13 end-to-end business checks
cd app/apps/customer && flutter run -d windows   # or chrome / an Android device
```
