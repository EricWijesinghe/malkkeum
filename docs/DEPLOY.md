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
5. Store listing text: `docs/store/listing-{ko,en,ja,zh,vi}.md` (check lengths with
   `python -I docs/store/check_listings.py`); data safety: `docs/store/data-safety.md` (Google) and
   `docs/store/app-privacy.md` (Apple); demo login from the client's console (guide 03 D).
6. Store images are generated, not hand-made: `scripts/store/generate.sh` renders both apps at the store
   sizes (iPhone 6.9"/6.5", iPad 13", Android 1080x2400), frames them with captions in 5 languages, and
   writes the Play feature graphics and poster. Output: `docs/store/screenshots/<app>/<size>/<lang>/NN-name.png`,
   `docs/store/graphics/`. Re-run after app screen changes, then upload the folders. Captions:
   `docs/store/screenshots/captions.json`. Screen list and fake data: `app/apps/*/test/store_screenshots/`.

Apps bake in `API_BASE` at build time, so a domain change means a rebuild.

### Native keys (Codemagic env group `malkkeum`)
`scripts/ci/native-keys.sh <app>` turns these into `keys.json` (dart-defines), `ios/Flutter/Keys.xcconfig`
and the Firebase files. All optional except `API_BASE`; a missing key hides that button / disables push.

| Var | Where to get it |
|---|---|
| `API_BASE` | `https://<client domain>` |
| `KAKAO_NATIVE_KEY` | developers.kakao.com → app → 앱 키 → 네이티브 앱 키. Register Android key hash (Play App Signing SHA-1 → base64) and iOS bundle id under 플랫폼 |
| `NAVER_CLIENT_ID` | developers.naver.com → 애플리케이션 → 네아로. Callback URL: `https://<APP_LINK_DOMAIN>/auth/naver/callback` (see Naver App Link below). The secret stays on the server |
| `APP_LINK_DOMAIN` | bare server host, same as the server `DOMAIN` (e.g. `malkkeum.co.kr`). Android App Link host and iOS `applinks:` domain. Naver is hidden without it |
| `GOOGLE_SERVER_CLIENT_ID` | Google Cloud console → Credentials → *Web* OAuth client id (also put it in the console wizard Google card) |
| `GOOGLE_IOS_CLIENT_ID` | Google Cloud console → *iOS* OAuth client for each bundle id (the reversed id is derived) |
| `GOOGLE_SERVICES_JSON_B64`, `GOOGLE_SERVICE_INFO_PLIST_B64` | Firebase project → customer Android/iOS app config files, `base64 -w0` |
| `PARTNER_GOOGLE_SERVICES_JSON_B64`, `PARTNER_GOOGLE_SERVICE_INFO_PLIST_B64` | same for the partner apps |
| `SOCIAL_PROVIDERS` | optional override, e.g. `kakao,naver` |

**Naver App Link (M3).** Naver returns the login code to `https://<APP_LINK_DOMAIN>/auth/naver/callback`.
Android verifies an `android:autoVerify` intent filter (`https`, host, path) against
`/.well-known/assetlinks.json`; iOS 17.4+ uses ASWebAuthenticationSession with the `applinks:` entitlement
against `/.well-known/apple-app-site-association`. Only the app can take that URL. Setup:
1. Server `.env` (the API serves both files from these; empty = 404, so the link does not verify):
   `ANDROID_CERT_SHA256=AA:BB:…` (comma list: Play Console → Release → App integrity → *App signing key certificate* SHA-256,
   plus the upload key if you sideload) and `APPLE_TEAM_ID=ABCDE12345`. Then
   `sudo docker compose --env-file .env up -d api` in `/opt/malkkeum`.
2. Naver Developers app: add the callback URL `https://<APP_LINK_DOMAIN>/auth/naver/callback`.
3. Apple Developer portal: enable **Associated Domains** on both bundle ids (`com.malkkeum.customer`,
   `com.malkkeum.partner`) so the entitlement can be signed. Codemagic signing fails without it.
4. Check: `curl -s https://<DOMAIN>/.well-known/assetlinks.json` and `…/apple-app-site-association` return JSON.
   On Android, `adb shell pm get-app-links com.malkkeum.customer` must show `verified`.

**Residual risk (iOS below 17.4).** `ASWebAuthenticationSession` cannot finish an https callback there, so the
app keeps `malkkeumnaver://naverlogin` on those devices. Another app can register that scheme, and Naver has no
PKCE. Remove the scheme (`Info.plist` URL type, `social_native_io.dart::_naverLegacyScheme`) when the minimum iOS is 17.4.

iOS, once per bundle id in the Apple Developer portal: enable **Sign in with Apple** and **Push
Notifications**, upload an APNs key (.p8) to Firebase → Cloud Messaging. In Xcode the Runner target
needs both capabilities (Codemagic automatic signing picks them up from the App ID).
Server side (console wizard): Firebase service-account key (Push card), Kakao REST key, Naver client id + secret,
Google + Apple client ids — these verify the tokens the apps send.

## 4. Before launch: real services to sign up for

The code has an adapter point for each. Dev mode uses safe fakes until then.

| Service | Purpose | Korean options | Where it plugs in |
|---|---|---|---|
| Payment gateway (PortOne V2) | One-off checkout (cards, KakaoPay, NaverPay, TossPay, PayCO, Samsung Pay, Apple Pay, bank transfer, virtual account, phone billing), saved one-tap billing, refunds | PortOne. One PortOne channel per method; put the keys in `PORTONE_CHANNEL_KEYS` (`{"kakaopay":"channel-key-…"}`). Also set `PORTONE_API_SECRET`, `PORTONE_WEBHOOK_SECRET` (webhook URL `https://<API_DOMAIN>/v1/webhooks/portone`), `PORTONE_STORE_ID` | `backend/crates/api/src/providers/portone.rs`, `routes/checkouts.rs`, `routes/webhooks.rs`; method switches in console (`/v1/admin/payment-methods`) |
| Identity (본인인증 / PASS) | Verified name and a CI hash (never the raw CI) | PortOne identity verification (same `PORTONE_API_SECRET`) | `providers/portone.rs::identity`, `POST /v1/me/identity` |
| Kakao login | Sign-in with Kakao | Kakao Developers app: REST key → `KAKAO_APP_ID` (checked against each token) | `providers/social.rs::kakao` |
| Naver login | Sign-in with Naver | Naver Developers app: client id + secret in the console wizard (Naver card). The app sends a login code; the server redeems it with the secret, so the token is ours | `providers/social.rs::naver` |
| Google login | Sign-in with Google | OAuth client ids (one per Android/iOS/web) → `GOOGLE_CLIENT_IDS` | `providers/social.rs::google` |
| Apple login | Sign in with Apple | Bundle id and Services ID → `APPLE_CLIENT_IDS`; signing keys are fetched from appleid.apple.com and cached | `providers/social.rs::apple` |
| SMS | Login codes, invites | NHN Cloud, Aligo, Solapi | `providers.rs::send_sms` |
| Push | New message, status changes | Firebase (FCM) + APNs | `providers.rs::push`; apps register tokens at `/v1/me/push-token` |
| Address search | Road-name address lookup | Kakao postcode, juso.go.kr | customer `AddressFormScreen` |
| Masked phone numbers | Pro ↔ customer calls | 050 virtual-number vendors | partner job detail "call" button |
| AlimTalk (optional) | KakaoTalk booking notices | Kakao business channel | alongside push in `realtime::notify` |
| Solapi SMS + AlimTalk (adapter built) | SMS fallback and AlimTalk for customer booking events | Solapi: `SOLAPI_API_KEY`, `SOLAPI_API_SECRET`, `SMS_SENDER`, `ALIMTALK_PF_ID`, `ALIMTALK_TEMPLATES` (kind → approved template id). Env vars in `deploy/.env.example` | `providers/sms.rs`, `Providers::send_sms` / `send_customer_message` |
| FCM push (adapter built) | Push to customer, pro and team-member devices | Firebase project; service-account key as `FCM_SERVICE_ACCOUNT` (path or JSON). Dead device tokens are pruned on UNREGISTERED | `providers/fcm.rs`, `Providers::push_collect`, `realtime::notify` |
| Partner payouts (built; default manual) | Weekly pro payouts go requested → sent → paid, or failed (retryable). Default `manual`: owner transfers from the bank app and confirms; no contract needed. Optional `toss`: Toss Payments 지급대행, set in the setup wizard "payout" card (mode `toss` + test or live secret key). **Toss mode is NOT usable yet; keep `manual`.** Verified against https://docs.tosspayments.com/guides/v2/payouts and /reference/additional: endpoints (`POST /v2/payouts`, `GET /v2/payouts/{id}` by Toss id), status enum, bank codes. Still missing: (1) seller registration `POST /v2/sellers` per pro, since each payout needs a `destination` seller id and the account lives on the seller; (2) JWE body encryption (`TossPayments-api-security-mode: ENCRYPTION`, A256GCM with the secret key), both requests and responses; (3) create-payout body schema (amount shape, scheduleType/payoutDate); (4) `payout.changed` webhook signature scheme (not on the guide page; polling stays). Toss also gates payouts behind a contract/application, so check before enabling | `providers/payout.rs`, `routes/payouts.rs`, `payout.rs` (state machine), migration `0014`; owner guide `guide/02` §7 |
| Team-member login (built) | Team members sign in on the partner app with their invited phone; they see only assigned jobs and never payouts | No external account. Owner invites by phone (`POST /v1/partner/team`) | `routes/member.rs`, `routes/auth.rs::verify_otp`, migration `0006` |

Legal: publish a privacy policy and terms (PIPA). Add them in the console under Coupons & content → Legal (slugs `privacy` and `terms`). The apps show them automatically.

### Sign-in and push SDKs (wired; keys via Codemagic, see §3)

The apps ship with integration points, not SDK packages. They need native app keys, so nothing below is added until the owner has the accounts.

How it works today:
- `packages/core/lib/src/social_auth.dart`: `UnconfiguredSocialSignIn.obtainToken` has one TODO per provider. The build only shows providers listed in `--dart-define=SOCIAL_PROVIDERS=kakao,naver,google,apple`. Dev API hosts (localhost, 127.0.0.1, 10.0.2.2, *.local) always get `DevSocialSignIn` instead.
- `packages/core/lib/src/payment_launcher.dart`: `PortOneLauncher` returns `provider_not_configured` until wired. Dev hosts use the simulated window.
- `packages/core/lib/src/identity.dart`: `PortOneIdentityVerifier` for PASS 본인인증.

To wire each provider:

| Provider | Add to `app/apps/customer/pubspec.yaml` and `app/apps/partner/pubspec.yaml` | Native setup | Then |
|---|---|---|---|
| Kakao | `kakao_flutter_sdk_user` | Android: `<meta-data android:name="com.kakao.sdk.AppKey" .../>` and the `kakao{NATIVE_APP_KEY}` intent-filter in `AndroidManifest.xml`. Register the Android key hash (debug and release) in the Kakao console. iOS: `KAKAO_NATIVE_APP_KEY` in `Info.plist` plus a `kakao{key}` URL scheme and `LSApplicationQueriesSchemes` (`kakaokompassauth`, `kakaolink`). | `UserApi.instance.loginWithKakaoTalk()` (fallback `loginWithKakaoAccount()`), return `token.accessToken` |
| Naver | `flutter_web_auth_2` | Client id (`NAVER_CLIENT_ID`) + `APP_LINK_DOMAIN`. Android: `CallbackActivity` `autoVerify` https intent filter (`${appLinkHost}`). iOS: `applinks:$(APP_LINK_HOST)` entitlement; `malkkeumnaver` URL type only for iOS < 17.4. Browser login returns `code` + `state`; app sends `code:state` | `social_native_io.dart::NaverSocialSignIn` |
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

## 6. Uploaded photos (operators)

- Chat, completion and review photos are no longer public files. Caddy does not route `/files`; the API serves them at `/v1/files/<name>` only with a link signed for one hour. Apps get fresh links on every API read, so nothing to configure.
- Signing key is derived from `DATA_KEY`. Rotating `DATA_KEY` ends open photo links within an hour; photos and their rows are unaffected.
- Photos stored before this change keep working as long as `PUBLIC_BASE_URL` stays the same.
- Backups still take the upload directory as a tar (`uploads-*.tar.gz`); no object storage is used.
