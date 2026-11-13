# Dahae API

Base: `https://<host>/v1` (health and app-links at the root). Spec: `GET /v1/openapi.json` (staff admins only).
Source of truth: `backend/crates/api/openapi.json` (kept inside the crate so the Docker build context includes it).

## Conventions

| Topic | Rule |
|---|---|
| Errors | `{"error":{"code":"<stable_code>","message":"<optional>"}}`. Clients branch on `code`, never on `message`. Framework failures (unknown route, bad method, rejected body, timeout) use the same envelope. |
| Common codes | `unauthorized`, `forbidden`, `not_found`, `conflict`, `invalid_body`, `invalid_limit`, `invalid_cursor`, `invalid_status`, `invalid_idempotency_key`, `idempotency_key_reused`, `idempotency_in_progress`, `payload_too_large`, `rate_limited`, `internal`. Domain codes (`slot_full`, `coupon_used`, `payment_failed`, ...) are listed in the spec's operation descriptions and `backend/crates/domain`. |
| 404 vs 403 | A resource the caller does not own answers `404 not_found`, the same as a missing one, so ids cannot be probed. `403 forbidden` is only for a known role that lacks the permission on a route the caller can see. |
| Pagination | Growing lists take `limit` (1-100, default 50; else `400 invalid_limit`) and `cursor`. Read `X-Next-Cursor` from the response; absent means last page. Cursors are opaque; a malformed one is `400 invalid_cursor`. Cursored today: `GET /bookings`, `GET /me/notifications`, `GET /checkouts`, `GET /admin/checkouts`, `GET /admin/bookings`. `GET /chat/threads/{id}/messages` takes `limit` and `before`. Other staff lists are capped (200) and not yet cursored. |
| Filters | Enumerated filters (`status`) reject unknown values with a 400 rather than returning an empty list. |
| Timestamps | RFC 3339 in UTC (`2026-03-04T05:06:07.123456Z`). Business dates (visit dates, payout dates, "today") are Korean dates (KST, UTC+9) as `YYYY-MM-DD`; the server never uses the database or host timezone for them. |
| Idempotency | Money-moving and duplicate-prone POSTs accept `Idempotency-Key` (1-128 printable ASCII characters). See below. |
| Body limits | Auth bodies 16 KiB; photo upload 12 MiB; every other JSON body 1 MiB. Over the limit is `413 payload_too_large`. |
| Unknown fields | Staff bodies reject unknown fields (`422 invalid_body`), so a typo fails loudly. Customer and partner bodies ignore them, so older apps keep working. |
| Auth | `Authorization: Bearer <access token>`. Access tokens are short-lived; rotate with `POST /v1/auth/refresh`. |

## Idempotency-Key

Send `Idempotency-Key: <unique per logical action>` on:
`POST /bookings`, `POST /bookings/{id}/cancel|deposit|balance|review`, `POST /checkouts`, `POST /checkouts/{id}/confirm`, `POST /admin/bookings/{id}/cancel`, `POST /admin/settlements/payouts/{id}/{action}`.

- Keys are scoped to the caller (a hash of the bearer token) and the path, and last 24 hours.
- Same key and same body: the first answer is replayed with its original status and body, plus `Idempotent-Replayed: true`. Nothing runs twice.
- Same key, different body: `400 idempotency_key_reused`.
- Same key while the first request is still running: `409 idempotency_in_progress`. Retry after a short wait.
- Only final answers are stored. 5xx, 401, 403 and 429 release the key so the client can retry.
- A claim older than 5 minutes that never finished is treated as abandoned.

Clients: generate a UUID v4 per user action (not per attempt) and reuse it across retries of that action.

## Paging example

```
GET /v1/bookings?limit=20
  -> 200 [...]   X-Next-Cursor: MjAyNi0wMS0wN3wxMHxmYzk...
GET /v1/bookings?limit=20&cursor=MjAyNi0wMS0wN3wxMHxmYzk...
```

## Versioning and deprecation

- The major version is in the path (`/v1`). A breaking change (removing a route, removing or renaming a field, changing a meaning, tightening validation a previous client relied on) requires `/v2`.
- Additive changes stay in `/v1`: new routes, new optional request fields, new response fields, new error codes. Clients must ignore unknown response fields and treat unknown error codes as the generic failure for their status.
- Deprecation: the route answers with `Deprecation: true`, `Sunset: <HTTP date>` (RFC 9745 / RFC 8594) and `Link: <successor>; rel="successor-version"`. Use the helper `contract::deprecated_route` in `backend/crates/api/src/contract.rs`.
- Minimum notice: 6 months between the first deprecation response and the sunset date, and the apps must have shipped a version that no longer calls the route before it is removed. Mobile store review adds lag, so the window is counted from the store release, not from the merge.
- The spec marks deprecated operations with `"deprecated": true` in the same change that adds the headers.

## Contract checks

`cargo test -p api --test api_contract` fails when:
- a mounted route has no OpenAPI operation, or an operation has no route;
- a Flutter app under `app/apps/*/lib` or `app/packages/*/lib` calls a path and method the spec does not document;
- an idempotent operation does not document `Idempotency-Key`, or a paged list does not document `limit` and `X-Next-Cursor`.

## Load targets

See `scripts/load/README.md` for the tool and the 2 vCPU VPS targets.
