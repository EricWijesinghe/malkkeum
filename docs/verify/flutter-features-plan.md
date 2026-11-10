# Flutter features — plan for the next session (not started)

The 2026-11-10 attempt was aborted because the machine was too loaded to verify imports; no files were changed.
Do these one at a time, running `dart analyze --fatal-infos` after each.

## 1. Split `apps/customer/lib/screens/booking_flow.dart` (mapped)
Line ranges (as of commit 729ebac):
- constants 14–16, `isoDate` 18 → keep in `schedule_step.dart` (export `isoDate`; `booking_detail.dart` uses it)
- address step 19–111 → `address_step.dart` (`AddressPickScreen`, `openTopicChat`)
- schedule 113–305 → `schedule_step.dart` (`ScheduleScreen`, `_DayChip`)
- checkout 306–514 → `checkout_step.dart` (`CheckoutScreen`, `_Line`, coupon sheet)
- done 515–564 → `done_step.dart` (`DoneScreen`; imports only core, ui, flutter, booking_detail.dart)
Importers to update: `booking_detail.dart`, `chat.dart`, `more.dart`, `quote_flow.dart`, `service.dart`.
Simplest safe route: keep `booking_flow.dart` as a barrel that `export`s the four new files, so importers need no change.

## 2. Split partner `jobs.dart` (928 lines) and `more.dart` (810 lines)
Feed / job detail / quote sheet; settlements / reviews / prefs editors / payout / team. Use the same barrel-export approach.

## 3. Console payment methods + reconciliation
Append admin-only sections after `Settlements` in `apps/console/lib/shell.dart` (badge indices 2 and 3 stay valid).
APIs: `GET/PUT /v1/admin/payment-methods`, `GET /v1/admin/checkouts?status=…` (being added by the backend payments work).
Brand chips: `PayBrandBadge(code)` from `packages/core/lib/src/pay_brands.dart` (exported by `auth_pay.dart`).

## 4. Customer notification inbox
`home.dart` bell currently opens `ContentListScreen(kind: 'notice')` (from `more.dart`). New screen with tabs: notifications
(`GET /v1/me/notifications`, `POST /v1/me/notifications/read`) and notices; unread dot on the bell.

## 5. Partner phone gate
`PhoneAttachScreen(api, audience)` from `auth_pay.dart`; banner in jobs tab when `GET /v1/partner/me` has `phone_verified == false`.
Add `'phone_required' => err_phone_required` to `Labels.error` in `packages/core/lib/src/i18n.dart` (+ string key).

## 6. Partner team-member mode
Add a `ProScope` (base path `/partner` vs `/member`, `showPayouts`) to `apps/partner/lib/state.dart`; read it in schedule, job
detail and complete screens instead of hard-coded paths. When `session.role == 'member'` show a MemberShell
(schedule, job detail, complete, more). Member API contract: see `docs/verify/backend-providers.md`.

## Strings
New keys → a new `app/tool/strings_more.py` plus the same keys in every `app/tool/lang_<code>.py`; then regenerate
`app/tool/i18n_source.json` and run `python -I app/tool/check_lang.py <code>` for each extra language.

## 7. PortOne paymentId (required by backend recovery)
When wiring `PortOneLauncher`, pass `checkout.id` as PortOne's `paymentId` (and also `customData: {"checkoutId": id}`).
The webhook and reconciler find checkouts by that id; any other id means a paid-but-unconfirmed card payment is never recovered.
