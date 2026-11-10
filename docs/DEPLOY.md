# Delivery runbook (developer only)

The client never gets source. They get a **public delivery repo** (installer + Korean guides),
public server images, and store apps that the developer builds and uploads to the client's own
store accounts. Source stays in the private repo.

| Piece | Built by | Client receives |
|---|---|---|
| API image, web image (website + console at `/admin/`) | `release.yml` → GHCR | `docker pull` via install.sh |
| install.sh + `guide/` + `store/` | `release.yml` → `DIST_REPO` (branches `main` = stable, `beta`) | one `curl … \| sudo bash` line |
| Customer / partner apps | Codemagic on the private repo | TestFlight / Play internal test, then stores |

## 0. Release gate

`release.yml` runs `e2e.yml` first: it builds both images on the runner, runs the real
`deploy/install.sh` against them (HTTPS with an internal CA, console, website, setup code, re-run
keeps data, broken image → automatic rollback, good image → update). Nothing is pushed or published
unless that passes. The same job runs on every push and PR via `ci.yml`.

## 1. One-time setup (developer)

1. Private repo: `gh repo create malkkeum --private --source . --push`
2. Public delivery repo: `gh repo create malkkeum-install --public --add-readme`; make sure it has a
   `main` branch (the default branch of the new repo).
3. Deploy key: `ssh-keygen -t ed25519 -N '' -f malkkeum-dist` → add `malkkeum-dist.pub` to
   `malkkeum-install` under *Settings → Deploy keys* with **Allow write access** ticked.
   In the private repo: secret `DIST_DEPLOY_KEY` = contents of `malkkeum-dist` (then delete the local
   files). Variable `DIST_REPO=<owner>/malkkeum-install`.
4. Release: `git tag v1.0.0 && git push --tags`. Then, once, open both GHCR packages
   (`malkkeum-api`, `malkkeum-web`) → Package settings → **Change visibility → Public**.
   The packages link to the public delivery repo through the OCI source label.
   Images contain compiled binaries and minified web assets only.
5. Check: `docker pull ghcr.io/<owner>/malkkeum-api:stable` from a logged-out machine.

Send the client the delivery repo link. Guide 01 already contains the exact install line
(`https://raw.githubusercontent.com/<owner>/malkkeum-install/main/install.sh`).

## 2. Releases and channels

| Tag | Images (GHCR) | Delivery branch |
|---|---|---|
| `v1.2.3` | `1.2.3`, `beta`, `stable`, `latest` | `beta` and `main` |
| `v1.3.0-beta.1` | `1.3.0-beta.1`, `beta` | `beta` only |

- `stable` (client default) and `beta` are image tags; `malkkeum channel beta|stable` switches a server.
- Every installed server keeps its channel tag in `/opt/malkkeum/.env` (`VERSION=stable`). Each
  Monday 04:00 KST it backs up, pulls the tag, checks health, and rolls back to the recorded previous
  image digests if the new one does not answer within 3 minutes.
- `malkkeum rollback` returns to the digests recorded by the last update (forward-only migrations:
  restore a backup if the schema changed; see guide 01).
- Apps bake in the API version floor: set `min_app_version` / `latest_app_version` per app in the
  console (사업장 정보). Below the minimum the app shows a blocking update screen.

## 3. Store apps (per client)

The client creates the store accounts and invites the developer (guide 03). Then in Codemagic,
connected to the **private** repo:
1. Integrations → App Store Connect: the client's API key, name `malkkeum_asc`.
2. Code signing → Android keystores: generate upload keystore, reference `malkkeum_upload`.
   Keep a copy offline — losing it blocks Play updates (recoverable only via Play support).
3. Env group `malkkeum`: `API_BASE=https://<client domain>`, `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`
   (service account created in the client's Play Console, *Release* permission, secure).
4. Create the two apps in App Store Connect / Play Console (bundle ids `com.malkkeum.customer`,
   `com.malkkeum.partner`), run the four workflows in `codemagic.yaml`.
5. Store listing text: `docs/store/listing-ko.md`; data safety: `docs/store/data-safety.md`;
   demo login from the client's console (guide 03 D).

Apps bake in `API_BASE` at build time, so a domain change means a rebuild.

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
| Solapi SMS + AlimTalk (adapter built) | SMS fallback and AlimTalk for customer booking events | Solapi: `SOLAPI_API_KEY`, `SOLAPI_API_SECRET`, `SMS_SENDER`, `ALIMTALK_PF_ID`, `ALIMTALK_TEMPLATES` (kind → approved template id). Env vars in `deploy/.env.example` | `providers/sms.rs`, `Providers::send_sms` / `send_customer_message` |
| FCM push (adapter built) | Push to customer, pro and team-member devices | Firebase project; service-account key as `FCM_SERVICE_ACCOUNT` (path or JSON). Dead device tokens are pruned on UNREGISTERED | `providers/fcm.rs`, `Providers::push_collect`, `realtime::notify` |
| Team-member login (built) | Team members sign in on the partner app with their invited phone; they see only assigned jobs and never payouts | No external account. Owner invites by phone (`POST /v1/partner/team`) | `routes/member.rs`, `routes/auth.rs::verify_otp`, migration `0006` |

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
