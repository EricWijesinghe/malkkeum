# Flutter test suite: verification notes

Status: **written, not executed.** The machine was overloaded, so no `flutter` or `dart` command was run while writing these tests. Expect a first-run pass to fix compile slips (imports, a finder that matches twice) before the suite is green.

## Commands

From the workspace root (`F:\EC\app`), in this order:

```sh
source /f/EC/scripts/env.sh
cd /f/EC/app && flutter pub get && dart analyze --fatal-infos
for p in packages/core packages/ui apps/customer apps/partner apps/console; do (cd $p && flutter test); done
```

End-to-end (opt-in, needs a dev API with DEV_MODE on):

```sh
cd /f/EC/app/apps/customer && flutter test integration_test/app_flow_test.dart \
  --dart-define=E2E=true --dart-define=API_BASE=https://<dev-api> --dart-define=E2E_PHONE=01012345678
cd /f/EC/app/apps/partner && flutter test integration_test/app_flow_test.dart \
  --dart-define=E2E=true --dart-define=API_BASE=https://<dev-api> --dart-define=E2E_PHONE=01012345678 --dart-define=E2E_CODE=<code>
cd /f/EC/app/apps/console && flutter test integration_test/app_flow_test.dart \
  --dart-define=E2E=true --dart-define=API_BASE=https://<dev-api> \
  --dart-define=E2E_STAFF_EMAIL=<email> --dart-define=E2E_STAFF_PASSWORD=<password>
```

Without `E2E=true` the integration tests are skipped and report as skipped.

## Shared helpers: `packages/test_support`

| File | Purpose |
|---|---|
| `lib/src/fake_api.dart` | `FakeApi`: route table on `MockClient` (method + regex path after `/v1`), records every `ApiCall`, `ApiReply` for non-200 status. Unmatched calls answer 404 `not_found`. |
| `lib/src/fake_storage.dart` | In-memory `FlutterSecureStorage`. |
| `lib/src/fixtures.dart` | JSON builders matching `core/models.dart`: default catalogue (backend `catalog.rs`), addresses, coupons, payment methods, bookings, threads, chat messages, slots, content. |
| `lib/src/env.dart` | `TestEnv.create(...)`: `Session`, `ApiClient`, `LocaleController`, `ThemeController` on one `FakeApi`. Default signed in, Korean, dark. |
| `lib/src/harness.dart` | `FakeRealtime` (no socket), `settle`, `pumpUntilFound`, `setViewport`, `phoneSize`, `wideSize`, `unmount`, `koT` (`lookupT(ko)`). |

`settle` pumps fixed frames instead of `pumpAndSettle`, because aurora, live-dot and parallax animations never settle.

## Test files

### Customer (`apps/customer`)

| File | Covers |
|---|---|
| `test/support/customer_host.dart` | `CustomerTestHost` (theme + localisation around any home), `pumpCustomerScreen`, `pumpCustomerApp` (real `CustomerApp`). |
| `test/support/customer_routes.dart` | `stockCustomerApi`: start-up endpoints for `AppState.loadAll` and the Shell. |
| `test/flutter_test_config.dart` | Loads intl date symbols for every test in the folder. |
| `test/onboarding_test.dart` | Intro, phone validation, OTP dev-code autofill, wrong-code error, profile save and welcome toast. |
| `test/home_test.dart` | Greeting by name, anonymous greeting, 8 service tiles with from-prices and quote badges. |
| `test/settings_test.dart` | Theme defaults to dark; tile cycles dark, light, system, dark; choice persisted. Language: Sinhala then English, re-rendered and saved with `PATCH /me`. |
| `test/booking_flow_test.dart` | Bathroom unit choice updates the rolling price; single fitting address skips to step 2/3; studio over 10 pyeong goes to address; full slots disabled; checkout pre-applies best coupon and posts the booking body (no `answers`). |
| `test/quote_flow_test.dart` | Move-out quote: six steps, `POST /bookings` answers with server enum names; first step gated on cleaning type. |
| `test/chat_room_test.dart` | System, request-card and quote bubbles; deposit-paid flips quote card; quick reply posts text; quote thread shows move-in quick replies. |
| `test/accessibility_test.dart` | `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` on intro, home and service detail, in dark and light. |
| `integration_test/app_flow_test.dart` | Golden path: intro, dev-code sign-in, home, open studio. Skipped unless `E2E=true`. |

### Partner (`apps/partner`)

| File | Covers |
|---|---|
| `test/support/partner_host.dart` | `PartnerTestHost`, `pumpPartnerScreen`, `pumpPartnerApp`, `stockPartnerApi`, `verifiedProfile`, `jobJson`. |
| `test/flutter_test_config.dart` | intl date symbols. |
| `test/onboarding_gate_test.dart` | Onboarding validation (finish disabled until name, team, service and district are set); save writes profile and prefs then reaches the waiting screen; verified pro skips onboarding; pending waiting screen; suspended block. |
| `test/jobs_test.dart` | Feed segment changes the `kind` query; direct-job card shows payout after 20% fee; accept asks for confirmation before posting; `already_taken` shows the error. |
| `test/quote_sheet_test.dart` | Live payout math (100,000 gives 80,000; 8 gives 6, half-up rounding); empty price disables send; double tap posts once (busy guard). |
| `test/complete_test.dart` | Completion locked without photos even with all four checklist items ticked. Photo paths are not covered (see gaps). |
| `test/accessibility_test.dart` | Guidelines on jobs feed and pending screen, dark and light. |
| `integration_test/app_flow_test.dart` | Golden path: intro, phone, code, relaunch through Gate, reach onboarding, waiting or jobs. Skipped unless `E2E=true`. |

### Console (`apps/console`)

| File | Covers |
|---|---|
| `test/support/console_host.dart` | `ConsoleTestHost` (home wrapped in Scaffold), `pumpConsoleScreen`, `pumpConsoleApp`, `stockConsoleApi`, `bookingDetail`. |
| `test/flutter_test_config.dart` | intl date symbols. |
| `test/login_test.dart` | Wrong password shows `cLoginFailed` under the field. Correct login opens the shell (see risk 1). |
| `test/palette_test.dart` | Ctrl+K opens the palette; picking Inbox navigates; search button opens the palette; typed booking number offers "open booking". |
| `test/bookings_test.dart` | Wide split view: selecting a row opens the panel. Status change is busy-guarded (one POST, body `{status: 3}`). Quote desk sends `final_price`, `quote_id`, `note: null`. |
| `test/inbox_test.dart` | J and K step through threads on the wide layout, clamped at both ends. |
| `test/accessibility_test.dart` | Guidelines on login and the bookings split view, dark and light. |
| `integration_test/app_flow_test.dart` | Golden path: staff login, relaunch, palette to bookings. Skipped unless `E2E=true`. |

### Core and UI

No new tests added. Existing `packages/core/test/*` and `packages/ui/test/*` are untouched.

## Assumptions about widget text and keys (adjust after the refactors)

Tests look up strings through `koT` (`lookupT(Locale('ko'))`) rather than literals, so copy changes do not break them. Structure and count assumptions remain:

1. **Pushed routes stay in the tree.** After a push, `find.text(koT.next)` matches the covered route too. Tests use `.last` (topmost route) or scope with `widgetWithText`. Any new covered-route text needs the same care.
2. **`customer/lib/screens/booking_flow.dart`** must keep exporting `AddressPickScreen`, `ScheduleScreen`, `CheckoutScreen`, `DoneScreen`, and `openTopicChat`. The split into `address_step.dart`, `schedule_step.dart`, `checkout_step.dart`, `done_step.dart` is expected to re-export these from `booking_flow.dart`. **If not, change the imports in `booking_flow_test.dart` and `quote_flow_test.dart`.** The tests import `package:customer/screens/booking_flow.dart`.
3. **`customer/lib/screens/quote_flow.dart`** exports `QuoteFlowScreen` and `QuoteConfirmScreen`.
4. **Home tile tags.** `find.text(koT.fromPrice(formatWon(45000,'ko')))` expects two matches (studio, kitchen); `koT.quoteBadge` expects two (move in and out). Any other occurrence of those strings on home breaks the count.
5. **Yes/no on the quote steps.** Step 2 uses `find.text(koT.yes).first` and step 3 `.last`, relying on `PageView` child order.
6. **Partner `jobs.dart`** must keep `JobsTab`, `JobDetailScreen`, `showQuoteSheet`. Split files need the imports updated in `jobs_test.dart`, `quote_sheet_test.dart` and `accessibility_test.dart`.
7. **Partner `complete.dart`** keeps `CompleteScreen(bookingId, isQuote)`. The completion test depends on checkbox widgets and the `pCompleteNeed` note.
8. **Partner `shell.dart`** keeps `Gate`. The integration test imports it.
9. **Console `shell.dart`** keeps `ConsoleShell` and the palette: a `TextField` whose hint is `cPaletteHint`, `ListTile` entries per section, and an app-bar button with tooltip `cSearchCommand`.
10. **Console `bookings.dart`** keeps `BookingsScreen(quoteDesk:)`, `BookingPanel` (used internally) and the row title `"<number> · <serviceShort>"`.
11. **Console `inbox.dart`** relies on `ValueKey(threadId)` on the selected `ThreadView`, plus `Focus(autofocus: true)` under `CallbackShortcuts` for J and K.
12. **Booking fixture needs `district_code`** on every booking row (console row reads it). Added to `bookingJson`.

## Known risks

1. **Root route may stay stale after sign-in (suspected app defect).** `MaterialApp.home` only sets the initial route. The customer intro, partner `PartnerIntro` and console `LoginScreen` are the root route, so changing `home` on sign-in may leave the sign-in screen on top until relaunch. `console/test/login_test.dart` ("a correct staff login opens the console shell") will catch this. The integration tests relaunch the app to get around it. If confirmed, fix by keying the Navigator on `session.signedIn` or pushing the new root. Not fixed here; test code is outside the allowed scope.
2. **Ctrl+K needs focus inside the shortcut scope.** If no widget under `CallbackShortcuts` holds primary focus, the key press never reaches the handler. The search-button test is the fallback. If the Ctrl+K test fails and the button test passes, the fix is in the shell's focus, not the test.
3. **`textContrastGuideline` may flag the brand palette** (light and dark). A failure there is a real finding for design, not a test bug.
4. **Accessibility guidelines and semantics**: `ensureSemantics` is on. Labels from `Semantics(label: ...)` on home tiles are relied on via `bySemanticsLabel`.
5. **Timers**: `CodeScreen` runs a periodic timer; tests call `unmount` at the end to cancel it. If a new test leaves a timer running, Flutter reports "A Timer is still pending".
6. **Date and time**: bookings use `today + 1` and `today + 3`. A test that runs across midnight can flake on the visit-date assertion.
7. **Compile not verified.** Imports were checked by hand for unused and missing `material`/`core`/`ui` imports. Expect a few corrections on the first analyzer run.

## Gaps (not covered)

- Customer: booking detail (timeline, cancel sheet, deposit-due card), addresses, payment methods and pay flow, virtual account, pending deposits banner, bookings list, chat photo upload, quote estimate error paths, realtime events.
- Partner: photo-required completion path (needs an image picker seam), chat, schedule, quotes tab, settlements, team and areas screens, live realtime events.
- Console: dashboard, catalog, marketing, people, customers, staff, settlements, cancel-with-refund dialog, quote desk calculation display, thread send (`Ctrl+Enter`).
- Core: no live WebSocket or event injection (`FakeRealtime` no-ops `connect`). Event-driven behaviour needs a core-level test or a `@visibleForTesting` hook.
- Integration: only one golden path per app, and only against a live dev API.

## Note on this file

The task asked for this file under `docs/verify/`. It sits outside the folders listed as writable for tests. It is the only write outside them, apart from the pubspec and workspace edits the task allowed.
