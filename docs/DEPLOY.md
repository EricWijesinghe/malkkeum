# Delivery runbook (developer only)

The client never gets source. They get a **public delivery repo** (installer + Korean guides),
public server images, and store apps that the developer builds and uploads to the client's own
store accounts. Source stays in the private repo.

| Piece | Built by | Client receives |
|---|---|---|
| API image, web image (website + console at `/admin/`) | `release.yml` → GHCR | `docker pull` via install.sh |
| install.sh + `SHA256SUMS` + `guide/` + `store/` | `release.yml` → `DIST_REPO` (branches `main` = stable, `beta`; annotated tag `v<VER>` on the release's channel commit) | one `curl … \| sudo bash` line |
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
4. Release: `git tag v1.0.0 && git push --tags`.
5. **GHCR packages Public (developer, one time; never the owner).** A package pushed under a user
   account starts private, and the installer pulls without logging in. Until both packages are
   public every install stops at "새 버전을 내려받지 못했어요". After the first release, for each of
   `malkkeum-api` and `malkkeum-web`: GitHub → your profile → **Packages** → the package →
   **Package settings** → Danger Zone → **Change visibility → Public** → type the package name.
   Visibility sticks for later tags, so this is not repeated per release.
   The packages link to the public delivery repo through the OCI source label.
   Images contain compiled binaries and minified web assets only.
6. Check from a logged-out machine (`docker logout ghcr.io` first):
   `docker pull ghcr.io/<owner>/malkkeum-api:stable` and `…/malkkeum-web:stable`.

Send the client the delivery repo link. Guides 00 (one page) and 01 contain the exact install line
(`https://raw.githubusercontent.com/<owner>/malkkeum-install/main/install.sh`, the stable channel's
latest). In the delivery repo the copies on the release's own branch carry the pinned line instead,
`…/malkkeum-install/v<VER>/install.sh`: `publish-delivery.sh` commits `install.sh` + `SHA256SUMS` and
pushes an annotated tag `v<VER>` with the same deploy key (no token). Tags are never moved: a re-run on
the same commit is a no-op, anything else fails the job. Branches keep moving as the channels.

### Image signatures

`release.yml` signs both images by digest with cosign keyless signing (GitHub OIDC, `id-token: write`),
and `pull-check` verifies them anonymously with the installer's own code before anything is delivered.
The installer downloads a pinned cosign (`COSIGN_VERSION`, SHA-256 per CPU type in `install.sh`) to
`/opt/malkkeum/bin/cosign`. Every install and `dahae update` verifies `<repo>/malkkeum-*:<tag>` against
`--certificate-identity-regexp ^https://github.com/<SIGNER_REPO>/.github/workflows/release.yml@refs/tags/v`
and `--certificate-oidc-issuer https://token.actions.githubusercontent.com`, then pulls and runs the
verified digest. No valid signature = no switch, with a Korean error; the running version stays.
`SIGNER_REPO` defaults to this repo (`publish-delivery.sh` writes `$GITHUB_REPOSITORY` into
`SIGNER_REPO_DEFAULT`, like `IMAGE_REPO_DEFAULT`); `MALKKEUM_SIGNER` overrides it. Images loaded from a
tar (`MALKKEUM_IMAGES_TAR`, `dahae load`) are not signature-checked (the installer says so).
`MALKKEUM_SKIP_SIGNATURE=1` turns the check off for unsigned test registries only (e2e); re-running
the installer without it turns it back on. The signing certificate in the public transparency log
(Rekor) names this repo, the workflow and the commit: the private repo's name is not secret.
Servers installed before this change keep their old `dahae` until the installer is run once more.

### Database roles

Postgres keeps `app` as the superuser (backups, admin). The API connects as `dahae_api`: it owns the
`cleaning` database and every object in it, and has no SUPERUSER / CREATEDB / CREATEROLE, so a
compromised API or a tampered backup cannot `COPY … PROGRAM`. `dahae` creates the role and moves
ownership before every install, update and restore (idempotent; an older install is converted on its
first re-run, with `API_DB_PASSWORD` added to `.env`). `pgcrypto` and `pg_trgm` are created by the
superuser first. Restores run as `dahae_api` in a throwaway postgres container without volumes;
owner and extension lines of older dumps are dropped on the way in.

The owner never edits a file on the server. Everything after the install line is either the console
wizard or a `dahae` command (`guide/07-운영-명령어.md`); `/opt/malkkeum/.env` is only copied somewhere
safe. Brand: the user-visible name is 다해 / Dahae and the CLI is `dahae` (`malkkeum` stays as a
symlink). Internal ids keep the old name: `/opt/malkkeum`, image names, bundle ids, the
`malkkeum-install` repo, `MALKKEUM_*` installer variables (`DAHAE_*` is accepted too).

### Server sizing (what the guides tell the owner)

Ubuntu 24.04 (22.04 and Debian 12 also install), x86_64 or arm64. Recommended 2 vCPU / 4 GB RAM,
minimum 2 GB. The installer refuses below about 1 GB, creates a 2 GB `/swapfile` when RAM is under
2 GB and there is no swap, needs 5 GB free disk (2 GB on a re-run), and stops if a non-Docker
process holds port 80 or 443.

### Outside the server (owner checklist, mirrored in guide 01)

1. Domain and an A record for the bare domain pointing at the server IP.
2. Ports 22/80/443 open in the cloud firewall (the installer only touches `ufw`, and only
   when it is already active).
3. PortOne + PG merchant contracts; keys go into the console wizard.
4. Solapi account, sender-number registration, Kakao channel and approved AlimTalk templates (guide 06).
5. Kakao / Naver / Google / Apple developer apps for sign-in; Apple Developer and Google Play accounts (guide 03).
6. Firebase project for push; AI and address-search keys in the wizard.
7. 사업자등록, 통신판매업 신고, privacy-policy contact.
8. Optional: offsite backup bucket (wizard), uptime check URL (`dahae heartbeat`, §8).

## 2. Releases and channels

| Tag | Images (GHCR) | Delivery branch |
|---|---|---|
| `v1.2.3` | `1.2.3`, `beta`, `stable`, `latest` | `beta` and `main` |
| `v1.3.0-beta.1` | `1.3.0-beta.1`, `beta` | `beta` only |

- `stable` (client default) and `beta` are image tags; `sudo dahae channel beta|stable` switches a server.
- Every installed server keeps its channel tag in `/opt/malkkeum/.env` (`VERSION=stable`). Each
  Monday 04:00 KST it backs up, pulls the tag, checks health, and rolls back to the recorded previous
  image digests if the new one does not answer within 3 minutes.
- `sudo dahae rollback` returns to the images recorded by the last update (a registry digest, or a
  local `keep-…` tag for tar installs). It swaps the program only: migrations are not undone and
  no data is removed. To go back in time as well, `sudo dahae restore <backup>` (guide 07).
- **Migrations stay additive (expand/contract).** A rollback, automatic or manual, runs the previous
  binary against the already-migrated schema. So a release may add tables, columns and indexes, but
  must not drop, rename or tighten anything the previous release still reads or writes. Remove the
  old shape one release later, once no rollback target uses it.
- **Backups, RPO and RTO.** Every server takes a `pg_dump` daily at 03:30 KST and before every
  update, kept 14 days on the server's own disk; the optional offsite copy (setup wizard, S3-compatible)
  is AES-256-GCM encrypted. There is no WAL archiving, so the recovery point objective is **24 hours**
  (up to one day of bookings can be lost). Recovery time on a fresh VPS is about **1 hour**: run the
  installer, put the old `.env` back, `sudo dahae restore-offsite <name>`. Without offsite backups a
  lost disk is a total loss: configure them before launch.
- **`DATA_KEY` and `.env` are not in any backup.** `/opt/malkkeum/.env` holds `DATA_KEY` (it encrypts
  integration keys, payout accounts and the offsite backups), `JWT_SECRET` and the database passwords.
  Offsite backups cannot be decrypted without the same `DATA_KEY`. Right after install, copy `.env` to
  a password manager or an encrypted USB stick kept away from the server, and copy it again after any
  key rotation. Rotating `DATA_KEY` makes older offsite backups unreadable with the new key, so keep the
  old value until those backups expire.
- Re-running the installer on an installed server is the same safe update (backup → new images →
  health check → rollback on failure); settings and data are kept.
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
| `APP_LINK_DOMAIN` | bare server host, same as the server `DOMAIN` (e.g. `myshop.co.kr`). Android App Link host and iOS `applinks:` domain. Naver is hidden without it |
| `GOOGLE_SERVER_CLIENT_ID` | Google Cloud console → Credentials → *Web* OAuth client id (also put it in the console wizard Google card) |
| `GOOGLE_IOS_CLIENT_ID` | Google Cloud console → *iOS* OAuth client for each bundle id (the reversed id is derived) |
| `GOOGLE_SERVICES_JSON_B64`, `GOOGLE_SERVICE_INFO_PLIST_B64` | Firebase project → customer Android/iOS app config files, `base64 -w0` |
| `PARTNER_GOOGLE_SERVICES_JSON_B64`, `PARTNER_GOOGLE_SERVICE_INFO_PLIST_B64` | same for the partner apps |
| `SOCIAL_PROVIDERS` | optional override, e.g. `kakao,naver` |

**Naver App Link (M3).** Naver returns the login code to `https://<APP_LINK_DOMAIN>/auth/naver/callback`.
Android verifies an `android:autoVerify` intent filter (`https`, host, path) against
`/.well-known/assetlinks.json`; iOS 17.4+ uses ASWebAuthenticationSession with the `webcredentials:` (and `applinks:`) entitlement
against `/.well-known/apple-app-site-association` (both sections are served). iOS steps: `docs/store/ios-release.md`. Only the app can take that URL. Setup:
1. On the server (the API serves both files from these values; unset = 404, so the link does not verify):
   `sudo dahae applinks --android-sha256 AA:BB:…[,CC:DD:…] --apple-team-id ABCDE12345`.
   The fingerprint list is Play Console → Release → App integrity → *App signing key certificate* SHA-256,
   plus the upload key if you sideload. The command validates both values, stores them and restarts
   the API; either flag can be given alone. Send the owner this exact line; no file is edited.
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
| Kakao login | Sign-in with Kakao | Kakao Developers app: REST key → `KAKAO_APP_ID` (checked against each token). Optional Admin key (console Kakao card or `KAKAO_ADMIN_KEY`): unlinks the Kakao account when the user deletes theirs | `providers/social.rs::kakao`, `unlink_all` |
| Naver login | Sign-in with Naver | Naver Developers app: client id + secret in the console wizard (Naver card). The app sends a login code; the server redeems it with the secret, so the token is ours | `providers/social.rs::naver` |
| Google login | Sign-in with Google | OAuth client ids (one per Android/iOS/web) → `GOOGLE_CLIENT_IDS` | `providers/social.rs::google` |
| Apple login | Sign in with Apple | Bundle id and Services ID → `APPLE_CLIENT_IDS`; signing keys are fetched from appleid.apple.com and cached. For token revocation on account deletion (Review 5.1.1(v)) add a Sign in with Apple key in the console Apple card (Team ID, Key ID, .p8 contents) or `APPLE_TEAM_ID` + `APPLE_KEY_ID` + `APPLE_PRIVATE_KEY`; without it deletion still works and logs a warning. Server-to-server notification URL to register in the Apple developer account: `https://<API_DOMAIN>/v1/auth/apple/notifications` | `providers/social.rs::apple`, `providers/apple.rs` |
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

The SDKs are wired in code; each one switches on when its key is supplied at build time (Codemagic env, §3) or in the setup wizard. Without a key the feature hides itself.

How it works today:
- Social sign-in: `packages/core/lib/src/social_native_io.dart` (Kakao, Naver via https App Link, Google, Apple). A provider is offered only when its build keys are set (`SOCIAL_PROVIDERS` narrows the list). Dev API hosts get `DevSocialSignIn`.
- Payments: `packages/core/lib/src/portone_webview.dart` (`PortOneWebViewLauncher` on iOS/Android, `PortOneRedirectLauncher` on web) and `portone_browser.dart` (Windows) open the hosted PortOne V2 page (`website/pay/`). They answer `provider_not_configured` only while the PortOne store id / channel keys are missing in the setup wizard. Dev hosts use the simulated window.
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

## 5. Local development

Machine-specific tool locations (Flutter, cargo and pub caches, JDK, Postgres binaries and data
directory, Playwright) go in `scripts/local.env`, copied from `scripts/local.env.example` (gitignored).
Without it the tools on `PATH` are used.

```bash
source scripts/env.sh          # loads scripts/local.env and points SDK caches at DAHAE_TOOLS
scripts/dev-api.sh             # Postgres on :5433 + API on :8080 (DEV_MODE fakes)
python -I scripts/smoke.py     # 13 end-to-end business checks
cd app/apps/customer && flutter run -d windows   # or chrome / an Android device
```

## 6. Uploaded photos (operators)

- Chat, completion and review photos are no longer public files. Caddy does not route `/files`; the API serves them at `/v1/files/<name>` only with a link signed for one hour. Apps get fresh links on every API read, so nothing to configure.
- Signing key is derived from `DATA_KEY`. Rotating `DATA_KEY` ends open photo links within an hour; photos and their rows are unaffected.
- Photos stored before this change keep working as long as `PUBLIC_BASE_URL` stays the same.
- Backups still take the upload directory as a tar (`uploads-*.tar.gz`); no object storage is used.

## 7. Toss payouts (지급대행): sandbox verification

Toss mode stays off until all of these hold. Anything else keeps payouts on `manual`.

1. Env `TOSS_PAYOUTS_ENABLED=1` on the API host (read at startup and on every setup save).
2. Console **Setup → Payouts**: save `secret_key` (sandbox `test_sk_...`) and `security_key` (보안 키, 64 hex) with mode `manual`.
3. Press **Test connection**. The API calls `GET /v2/balances` with the secret key. It records `sandbox_connected` only for a `test_sk_` key that returns 200, with a fingerprint of that key. Changing the key requires testing again.
4. Save mode `toss`. Accepted only when steps 1 and 3 hold; otherwise `toss_unverified`.
5. Register each pro as a seller: `POST /v1/admin/settlements/toss-sellers/{pro_id}` with `business_type` (`individual` or `company`), `name`, or `representative` + `registration_no` (10 digits), `email`, `phone`. The bank account is the pro's verified payout account. Re-run after a bank-account change; a payout for a stale account is refused (`seller_account_changed`).
6. Webhook: point Toss at `{PUBLIC_BASE_URL}/v1/webhooks/toss` for `payout.changed` and `seller.changed`. The body is ignored; each call triggers a poll of open payouts.

Not covered by unit tests, so check in the sandbox:
- The JWE body is accepted: the first `POST /v2/sellers` returns a decodable response. On `INVALID_ENCRYPTION`, check the `security_key`, the `TossPayments-api-security-mode: ENCRYPTION` header and the `text/plain` content type.
- The payout `amount` object `{currency, value}` and the `Idempotency-Key` header name are accepted (the docs do not spell these out).
- A sandbox payout reaches `COMPLETED` through the poll path (`payout_sync.rs`).

Not in the docs (do not assume): the webhook signature scheme (none documented, so no signature check) and the seller response `status` field name.

## 8. Uptime monitoring (outside the server)

The server cannot report its own outage, so watch it from outside.

- **Heartbeat (required):** create a check at healthchecks.io (or any compatible service) with period 5 min, grace 15 min, then on the server run `sudo dahae heartbeat <ping URL>` (https only; `sudo dahae heartbeat off` disables it). The command stores the URL, restarts the API so the console checklist item clears, and sends one test ping. Unattended installs can pass `MALKKEUM_HEARTBEAT_URL=` instead. Cron runs `/usr/local/bin/malkkeum-heartbeat` every 5 minutes. It pings only when `https://DOMAIN/health` returns `"ok":true`, so a dead API stops the pings and the service alerts you by email/SMS.
- **Missing config:** without a heartbeat URL, `sudo dahae status` prints a warning and the heartbeat log says so. Nothing is alerted until the URL is set.
- **HTTP checks (optional, free tiers):** UptimeRobot or BetterStack, HTTPS `GET https://DOMAIN/health`, expect keyword `"ok":true`, interval 5 min. Use this to catch a crashed proxy as well.
- Logs: `/opt/malkkeum/backups/heartbeat.log` (rotated weekly, 8 kept). Server metrics and request ids are covered by the ops screens, not here.

## 9. Operations: probes, logs, metrics, shutdown (operators)

- **Liveness** `GET /health` answers while the process is up; it never touches the database.
- **Readiness** `GET /ready` returns 200 only when the database answers and every migration shipped with the image is applied (503 otherwise). The compose healthcheck runs `api --ready`. Caddy does not route `/ready` or `/metrics` to the internet (404).
- **Logs.** Production sets `LOG_FORMAT=json`: one JSON object per event, with the request span (`method`, `path`, `request_id`) attached. Local runs keep the readable format; set `LOG_FORMAT=json` to try the production format. `RUST_LOG` still controls the level.
- **Request ids.** Every response carries `x-request-id`. A client-sent id is kept when it is at most 128 characters of `[A-Za-z0-9-_.:]`; otherwise the API generates one. Error bodies repeat it as `error.request_id`, and it is the value to grep for in the logs. No other internal detail reaches a client.
- **Metrics** `GET /metrics` (Prometheus text format 0.0.4). Set `METRICS_TOKEN` (32+ characters) in the server environment and scrape with `Authorization: Bearer <token>`. Without a token, only loopback clients can scrape, so a scraper must run on the host or in the same network namespace. Series:
  - `malkkeum_http_requests_total{method,route,status}` and `malkkeum_http_request_duration_seconds` (histogram). `route` is the route template (`/v1/bookings/{id}`); unmatched paths share `route="unmatched"`, so cardinality stays bounded.
  - `malkkeum_db_pool_connections{state="open"|"idle"}`.
  - `malkkeum_payouts_pending`: payouts requested or sent and not yet settled.
  - `malkkeum_job_last_run_timestamp_seconds{job}` and `malkkeum_job_errors_total{job}` for `reconciler`, `ops_alerts`, `payout_sync`, `settings_refresh`. Alert when a timestamp is older than a few intervals.
  - `malkkeum_realtime_listening`: 0 means this replica is not receiving events from the others.
  - `malkkeum_build_info{version}`, `malkkeum_uptime_seconds`.
- **Shutdown.** On SIGTERM (`docker stop`) the API stops accepting connections, closes WebSockets with code 1012 so clients reconnect, lets in-flight requests finish (each is bounded by the 30 s request timeout), then stops the background jobs after their current pass (up to 10 s).
- **Several API replicas.** Realtime events fan out through Postgres `LISTEN/NOTIFY` (channel `malkkeum_events`). Each replica holds one pooled connection for it. Events larger than about 7 KB are stored in `realtime_events` for a few minutes and fetched by id. After a database failover, sockets receive `{"type":"resync"}` and refetch.

## 10. Uninstall

- `sudo dahae uninstall` (asks for `yes`): stops the stack, removes the cron file, logrotate rule and the
  `dahae` / `malkkeum` / `malkkeum-heartbeat` commands. Data volumes, `/opt/malkkeum/.env` and
  `/opt/malkkeum/backups` stay, so re-running the installer resumes the same server.
- `sudo dahae uninstall --purge` (asks for the domain): also deletes the Docker volumes (database,
  uploads, certificates) and `/opt/malkkeum` with its backups and keys. Not reversible. Offsite backups
  are untouched but need the old `DATA_KEY` to decrypt. Docker itself is left installed.
- `--yes` (or `DAHAE_YES=1`) skips the `yes` prompt for scripts, but never the `--purge` one: a script
  must pass the domain itself, `sudo dahae uninstall --purge --confirm <domain>`.
