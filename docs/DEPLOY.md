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
| Payment gateway (PortOne V2) | One-off checkout (cards, KakaoPay, NaverPay, TossPay, PayCO, Samsung Pay, Apple Pay, bank transfer, virtual account, phone billing), saved one-tap billing, refunds | PortOne. One PortOne channel per method; put the keys in `PORTONE_CHANNEL_KEYS` (`{"kakaopay":"channel-key-…"}`). Also set `PORTONE_API_SECRET`, `PORTONE_WEBHOOK_SECRET` (webhook URL `https://<API_DOMAIN>/v1/webhooks/portone`), `PORTONE_STORE_ID` | `backend/crates/api/src/providers/portone.rs`, `routes/checkouts.rs`, `routes/webhooks.rs`; method switches in console (`/v1/admin/payment-methods`) |
| Identity (본인인증 / PASS) | Verified name and a CI hash (never the raw CI) | PortOne identity verification (same `PORTONE_API_SECRET`) | `providers/portone.rs::identity`, `POST /v1/me/identity` |
| Kakao login | Sign-in with Kakao | Kakao Developers app: REST key → `KAKAO_APP_ID` (checked against each token) | `providers/social.rs::kakao` |
| Naver login | Sign-in with Naver | Naver Developers app. No server env: the profile call is the check (see shortcut in `providers/social.rs`) | `providers/social.rs::naver` |
| Google login | Sign-in with Google | OAuth client ids (one per Android/iOS/web) → `GOOGLE_CLIENT_IDS` | `providers/social.rs::google` |
| Apple login | Sign in with Apple | Bundle id and Services ID → `APPLE_CLIENT_IDS`; signing keys are fetched from appleid.apple.com and cached | `providers/social.rs::apple` |
| SMS | Login codes, invites | NHN Cloud, Aligo, Solapi | `providers.rs::send_sms` |
| Push | New message, status changes | Firebase (FCM) + APNs | `providers.rs::push`; apps register tokens at `/v1/me/push-token` |
| Address search | Road-name address lookup | Kakao postcode, juso.go.kr | customer `AddressFormScreen` |
| Masked phone numbers | Pro ↔ customer calls | 050 virtual-number vendors | partner job detail "call" button |
| AlimTalk (optional) | KakaoTalk booking notices | Kakao business channel | alongside push in `realtime::notify` |

Legal: publish a privacy policy and terms (PIPA). Add them in the console under Coupons & content → Legal (slugs `privacy` and `terms`). The apps show them automatically.

### Sign-in and payment SDKs (not yet wired)

The apps ship with integration points, not SDK packages. They need native app keys, so nothing below is added until the owner has the accounts.

How it works today:
- `packages/core/lib/src/social_auth.dart`: `UnconfiguredSocialSignIn.obtainToken` has one TODO per provider. The build only shows providers listed in `--dart-define=SOCIAL_PROVIDERS=kakao,naver,google,apple`. Dev API hosts (localhost, 127.0.0.1, 10.0.2.2, *.local) always get `DevSocialSignIn` instead.
- `packages/core/lib/src/payment_launcher.dart`: `PortOneLauncher` returns `provider_not_configured` until wired. Dev hosts use the simulated window.
- `packages/core/lib/src/identity.dart`: `PortOneIdentityVerifier` for PASS 본인인증.

To wire each provider:

| Provider | Add to `app/apps/customer/pubspec.yaml` and `app/apps/partner/pubspec.yaml` | Native setup | Then |
|---|---|---|---|
| Kakao | `kakao_flutter_sdk_user` | Android: `<meta-data android:name="com.kakao.sdk.AppKey" .../>` and the `kakao{NATIVE_APP_KEY}` intent-filter in `AndroidManifest.xml`. Register the Android key hash (debug and release) in the Kakao console. iOS: `KAKAO_NATIVE_APP_KEY` in `Info.plist` plus a `kakao{key}` URL scheme and `LSApplicationQueriesSchemes` (`kakaokompassauth`, `kakaolink`). | `UserApi.instance.loginWithKakaoTalk()` (fallback `loginWithKakaoAccount()`), return `token.accessToken` |
| Naver | `flutter_naver_login` | Client id/secret/name in the Naver developer console; Android and iOS URL schemes; `naverlogin` and `naversearchapp` in `LSApplicationQueriesSchemes` | `FlutterNaverLogin.logIn()`, return `accessToken` |
| Google | `google_sign_in` | Android: OAuth client per package and SHA-1 (debug and release). iOS: reversed client id URL scheme and `GIDClientID` | `GoogleSignIn().signIn()`, return the access token the backend expects |
| Apple | `sign_in_with_apple` | Xcode: enable the *Sign in with Apple* capability; Apple developer console: App ID capability and a Services ID for web/Android | `SignInWithApple.getAppleIDCredential()`, return `identityToken` |
| PortOne payments | `portone_flutter_v2` (or a WebView) | Store id and channel keys from the PortOne console per method; add the app return scheme | Implement `PortOneLauncher.pay`: return `PaymentApproved(paymentId)` from the callback |
| PortOne identity (PASS) | the same PortOne package | Identity channel key; mobile return URL | Implement `PortOneIdentityVerifier.verify`: return the identity verification id |

After wiring a provider, add it to `SOCIAL_PROVIDERS` in the release build command. Keep the dev stubs out of release builds: they only appear on dev hosts, but the release API base must never be local.

## 5. Local development (this PC)

```bash
source scripts/env.sh          # all tools and caches live on F:
scripts/dev-api.sh             # Postgres on :5433 + API on :8080 (DEV_MODE fakes)
python -I scripts/smoke.py     # 13 end-to-end business checks
cd app/apps/customer && flutter run -d windows   # or chrome / an Android device
```
