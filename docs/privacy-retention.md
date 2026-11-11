# Privacy retention and deletion (PIPA)

Source of truth for what the server keeps, purges and deletes. Code: `backend/crates/api/src/privacy.rs`, `backend/crates/api/src/retention.rs`.

## Consent (`user_consents`, migration 0016)

- Append-only. Each change is a row `(user, kind, version, granted, created_at)`. The newest row per kind is the current state.
- Kinds: `terms`, `privacy`, `overseas_transfer` (required); `marketing` (optional, withdrawable).
- A consent counts only when granted for `CONSENT_VERSION` (privacy.rs). Bumping the version forces re-consent of required kinds (`reconsent_required: true`) and stops marketing until re-asked.
- API: `GET/PUT /v1/me/consents`. A change with a stale version is rejected; required kinds cannot be withdrawn.
- Marketing sends: `realtime::notify` drops any `marketing.*` kind unless `marketing_allowed`. Transactional kinds are unaffected.

## Deletion (`DELETE /v1/me`)

| Data | Action |
|---|---|
| Name, email, phone, CI hash, identity date | Cleared; phone set to `deleted:<id>` |
| Addresses | Hard delete (bookings keep their own address snapshot) |
| Saved card (PortOne billing key) | Deleted at PortOne first. If PortOne refuses, nothing changes and the call returns 503 `billing_key_delete_failed`; retry is safe |
| Push tokens, notifications | Deleted |
| Refresh tokens | Revoked |
| Chat messages sent by the customer | `sender_id` unlinked; text kept for disputes |
| Bookings, payments, refunds | Kept 5 years (전자상거래법) |
| Consent log | Kept as proof of consent (internal 5-year rule, see lawyer list) |
| Uploaded photos | Kept with the booking record; not separately deleted (see lawyer list) |

## Export (`GET /v1/me/export`)

JSON: profile, consent history, addresses, payment method labels (no keys), coupons, bookings, last 500 notifications. Gateway keys and tokens are never included.

## Retention purge (`retention::spawn`, hourly)

| Target | Rule | Setting |
|---|---|---|
| `otp_codes` | older than 1 day | fixed |
| `refresh_tokens` | expired, or revoked over 1 day ago | fixed |
| Ops failure and HTTP error counters | older than 3 days | fixed (`ops::prune`) |
| AI-assisted chat messages (threads with an `ai_usage` row) | older than N days | `AI_CHAT_RETENTION_DAYS`, default 180 |
| Uploads not referenced by bookings, chat, pros or users | older than N days; file removed, then row | `UPLOAD_ORPHAN_DAYS`, default 30 |

Each run logs counts (`retention purge done`). A database error stops the run; the next hour retries it.

## Staff access log

Every staff read of a customer's contact details writes `audit_log` with `action` `customer.pii_view` (booking detail) or `customer.pii_list` (customer search). Payout account reveals already log `payout.reveal`.

## Not yet covered

- Partner (pro) account deletion and export: the partner route deletes but does not run this cascade; export is not built.
- Access (connection) logs: nothing in the database stores IP-level access logs; the 3-month rule depends on the hosting proxy's logs.
- Customers with an open booking can still delete the account.
