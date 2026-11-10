# Sample data · 데이터베이스 예시

Every table in the Malkkeum database with one example row from the demo data
(`malkkeum demo load`). All names, phones and amounts are fake. Secret columns are hidden.
모든 표와 예시 한 줄이에요. 이름·전화번호·금액은 모두 가짜이고, 비밀 값은 가렸어요.

## `addresses` — Customers' saved addresses · 고객 주소

56 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | e7a43b24-c429-3756-edf3-3e904513ef99 |
| `user_id` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `kind` | text | home |
| `label` | text | 집 |
| `road_address` | text | 서울특별시 영등포구 도산대로 139 |
| `detail` | text | 오피스텔 1502호 |
| `district_code` | text | 11560 |
| `size_pyeong` | smallint | 35 |
| `created_at` | timestamp with time zone | 2026-05-29T23:18:40.845049+09:00 |
| `deleted_at` | timestamp with time zone | — |

## `ai_usage` — AI assistant replies and their token cost · AI 상담 사용량

0 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | bigint | (empty) |
| `thread_id` | uuid | (empty) |
| `model` | text | (empty) |
| `outcome` | text | (empty) |
| `input_tokens` | integer | (empty) |
| `output_tokens` | integer | (empty) |
| `cache_read_tokens` | integer | (empty) |
| `cache_write_tokens` | integer | (empty) |
| `created_at` | timestamp with time zone | (empty) |

## `audit_log` — Who changed what in the console · 변경 기록

24 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | bigint | 1 |
| `actor_role` | text | staff |
| `actor_id` | uuid | d5c1dbf0-1f47-9636-23be-455a81ddfd5f |
| `action` | text | pro.approve |
| `target` | text | b42ab2c1-570d-6606-0cb4-cfe2a77b1544 |
| `data` | jsonb | {"note": "샘플 데이터"} |
| `created_at` | timestamp with time zone | 2026-11-10T23:18:40.845049+09:00 |

## `bookings` — Every booking, from request to completion · 예약

184 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `number` | text | BK2608-00001 |
| `user_id` | uuid | 998b2020-895b-0bd2-2834-1de37477ac10 |
| `service_code` | text | move_out |
| `unit_index` | smallint | — |
| `address` | jsonb | {"kind": "home", "label": "집", "detail": "가든하우스 1층", "size_… |
| `district_code` | text | 11290 |
| `visit_date` | date | 2026-09-01 |
| `start_hour` | smallint | 13 |
| `minutes` | integer | — |
| `status` | smallint | 3 |
| `answers` | jsonb | {"duplex": false, "layout": "two_rooms", "luggage": "partly… |
| `estimate` | bigint | 427400 |
| `final_price` | bigint | 437400 |
| `deposit` | bigint | 43700 |
| `list_price` | bigint | — |
| `discount` | bigint | 0 |
| `paid_amount` | bigint | 437400 |
| `balance_paid` | boolean | True |
| `coupon_id` | uuid | — |
| `team_name` | text | 깔끔홈 마포점 |
| `pro_id` | uuid | 0dbf64ce-9e66-c737-9165-a9795e5b8271 |
| `assignee_id` | uuid | a3c0d92d-39e2-a290-1d72-ffe4bd1a7369 |
| `accepted_at` | timestamp with time zone | 2026-08-27T18:00:00+09:00 |
| `visit_notes` | jsonb | {"pets": false, "access": "초인종 누르시면 제가 나갈게요", "parking": "건… |
| `team_memo` | text |  |
| `reschedule` | jsonb | — |
| `cancelled_at` | timestamp with time zone | — |
| `completed_at` | timestamp with time zone | 2026-09-01T15:00:00+09:00 |
| `created_at` | timestamp with time zone | 2026-08-27T16:00:00+09:00 |
| `updated_at` | timestamp with time zone | 2026-09-01T15:00:00+09:00 |

## `chat_messages` — Messages in a conversation · 상담 메시지

1743 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | b80faeac-8fdf-8a8c-5cd7-b63b4855b36d |
| `thread_id` | uuid | 3dbee8f6-da41-16b9-4779-231f2f8391b9 |
| `sender` | text | system |
| `sender_id` | uuid | — |
| `kind` | text | card |
| `body` | jsonb | {"answers": {"duplex": false, "layout": "two_rooms", "lugga… |
| `created_at` | timestamp with time zone | 2026-08-27T16:10:00+09:00 |

## `chat_threads` — One conversation (customer or partner ↔ office) · 상담방

322 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 3dbee8f6-da41-16b9-4779-231f2f8391b9 |
| `audience` | text | customer |
| `user_id` | uuid | 998b2020-895b-0bd2-2834-1de37477ac10 |
| `pro_id` | uuid | — |
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `topic` | text | move_out |
| `unread_member` | integer | 0 |
| `unread_staff` | integer | 0 |
| `closed` | boolean | True |
| `last_message_at` | timestamp with time zone | 2026-09-01T15:05:00+09:00 |
| `created_at` | timestamp with time zone | 2026-08-27T16:10:00+09:00 |
| `ai_paused` | boolean | False |

## `checkouts` — Payment attempts sent to PortOne · 결제 시도

209 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | b0acfe64-1f52-5600-f4c1-be8c2af62382 |
| `user_id` | uuid | 998b2020-895b-0bd2-2834-1de37477ac10 |
| `kind` | text | booking |
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `draft` | jsonb | {"body": {"answers": {"duplex": false, "layout": "two_rooms… |
| `method` | text | card |
| `amount` | bigint | 43700 |
| `status` | text | paid |
| `provider_payment_id` | text | demo_pay_c508fe66ec909290f068c095 |
| `virtual_account` | jsonb | — |
| `result_booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `expires_at` | timestamp with time zone | 2026-08-28T16:15:00+09:00 |
| `created_at` | timestamp with time zone | 2026-08-28T16:00:00+09:00 |
| `refund_reason` | text | — |
| `reconciled_at` | timestamp with time zone | — |

## `completion_reports` — Before/after photos and checklist when a job ends · 완료 보고

131 rows in the demo.

| column | type | example |
|---|---|---|
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `before_photos` | ARRAY | ["http://127.0.0.1:8080/files/de30de30de30de30de30de30de30d… |
| `after_photos` | ARRAY | ["http://127.0.0.1:8080/files/de30de30de30de30de30de30de30d… |
| `checklist` | jsonb | [true, true, true, true] |
| `submitted_by` | uuid | 0dbf64ce-9e66-c737-9165-a9795e5b8271 |
| `submitted_at` | timestamp with time zone | 2026-09-01T15:00:00+09:00 |

## `content_items` — Notices, tips, FAQ, banners, legal pages · 공지·FAQ·약관

14 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 046187ce-c7ca-4b74-b577-e3ba4793d63b |
| `kind` | text | banner |
| `slug` | text | — |
| `title` | jsonb | {"en": "2 welcome coupons for your first booking", "ja": "初… |
| `body` | jsonb | {"link": "coupons", "theme": "sun"} |
| `image_url` | text | — |
| `link` | text | — |
| `sort_order` | integer | 0 |
| `starts_at` | timestamp with time zone | — |
| `ends_at` | timestamp with time zone | — |
| `active` | boolean | True |
| `created_at` | timestamp with time zone | 2026-11-11T05:18:40.820914+09:00 |

## `coupons` — Discount coupons · 쿠폰

95 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | baa97862-6bf7-9fc0-bef5-98a3bccfc78e |
| `user_id` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `name` | text | 스튜디오 첫 예약 1만원 할인 |
| `amount` | bigint | 10000 |
| `service_code` | text | studio |
| `campaign` | text | welcome |
| `issued_at` | timestamp with time zone | 2026-05-29T23:18:40.845049+09:00 |
| `expires_at` | timestamp with time zone | 2026-06-12T23:18:40.845049+09:00 |
| `used_booking_id` | uuid | — |

## `demo_rows` — Which rows are sample data (for demo clear) · 체험용 데이터 목록

3707 rows in the demo.

| column | type | example |
|---|---|---|
| `tbl` | text | users |
| `row_key` | text | •••• (hidden) |
| `created_at` | timestamp with time zone | 2026-11-11T05:18:40.828684+09:00 |

## `integration_settings` — Encrypted keys from the setup wizard · 연동 키(암호화)

0 rows in the demo.

| column | type | example |
|---|---|---|
| `section` | text | (empty) |
| `secret` | text | (empty) |
| `last_test` | jsonb | (empty) |
| `updated_at` | timestamp with time zone | (empty) |
| `updated_by` | uuid | (empty) |

## `notifications` — Inbox entries shown in the apps · 알림함

183 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 67d3ad7e-148a-73d2-391b-595e9d8e1a87 |
| `owner_role` | text | pro |
| `owner_id` | uuid | 0dbf64ce-9e66-c737-9165-a9795e5b8271 |
| `kind` | text | job.updated |
| `data` | jsonb | {"number": "BK2608-00001", "booking_id": "2ec5bd13-9f53-710… |
| `read_at` | timestamp with time zone | 2026-08-27T21:00:00+09:00 |
| `created_at` | timestamp with time zone | 2026-08-27T18:00:00+09:00 |

## `ops_alerts` — Owner alerts that were sent (dedup) · 사장님 알림 기록

0 rows in the demo.

| column | type | example |
|---|---|---|
| `alert_key` | text | (empty) |
| `last_sent_at` | timestamp with time zone | (empty) |

## `ops_failures` — Recent integration failures · 연동 오류 기록

0 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | bigint | (empty) |
| `integration` | text | (empty) |
| `code` | text | (empty) |
| `at` | timestamp with time zone | (empty) |

## `ops_health` — Last success/failure per integration · 연동 상태

0 rows in the demo.

| column | type | example |
|---|---|---|
| `integration` | text | (empty) |
| `last_ok_at` | timestamp with time zone | (empty) |
| `last_fail_at` | timestamp with time zone | (empty) |
| `last_error` | text | (empty) |

## `ops_http_errors` — Server error counts per hour · 서버 오류 집계

0 rows in the demo.

| column | type | example |
|---|---|---|
| `hour` | timestamp with time zone | (empty) |
| `count` | bigint | (empty) |

## `otp_codes` — Login codes sent by SMS (hashed) · 로그인 인증번호

12 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | d74e853a-4d8c-fd5f-6b7d-5a2b07ffe554 |
| `phone` | text | 01000000001 |
| `code_hash` | text | •••• (hidden) |
| `attempts` | integer | 1 |
| `expires_at` | timestamp with time zone | 2026-11-09T05:21:40.845049+09:00 |
| `created_at` | timestamp with time zone | 2026-11-09T05:18:40.845049+09:00 |

## `partner_prefs` — Which services, areas and hours a partner takes · 파트너 작업 조건

12 rows in the demo.

| column | type | example |
|---|---|---|
| `pro_id` | uuid | b42ab2c1-570d-6606-0cb4-cfe2a77b1544 |
| `services` | ARRAY | ["studio", "aircon", "bathroom", "move_in", "sofa"] |
| `districts` | ARRAY | ["11140", "11500", "11320", "11560", "11380", "11740", "114… |
| `weekdays` | ARRAY | [0, 1, 2, 3, 4, 5, 6] |
| `day_parts` | ARRAY | ["morning", "afternoon"] |
| `days_off` | ARRAY | ["2026-11-21"] |
| `notify` | jsonb | {"chat": true, "direct": true, "quotes": true, "quiet_night… |

## `payment_methods` — Saved one-tap cards (PG token only, no card numbers) · 저장된 간편결제

57 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 9bd334ea-9ba9-33b1-2976-2269cb788590 |
| `user_id` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `provider` | text | card |
| `billing_key` | text | •••• (hidden) |
| `display_name` | text | 데모 카드 1234 |
| `created_at` | timestamp with time zone | 2026-05-29T23:18:40.845049+09:00 |
| `deleted_at` | timestamp with time zone | — |

## `payments` — Money actually received or refunded · 결제·환불 내역

202 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 4bbdba37-12cf-7c59-3f71-47a1c525b3b6 |
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `amount` | bigint | 43700 |
| `kind` | text | deposit |
| `status` | text | paid |
| `refunded_amount` | bigint | 0 |
| `provider` | text | portone |
| `provider_tx_id` | text | demo_pay_c508fe66ec909290f068c095 |
| `failure_code` | text | — |
| `idempotency_key` | text | •••• (hidden) |
| `created_at` | timestamp with time zone | 2026-08-28T16:00:00+09:00 |

## `payout_accounts` — Partner bank accounts (number encrypted) · 파트너 정산 계좌

8 rows in the demo.

| column | type | example |
|---|---|---|
| `pro_id` | uuid | b42ab2c1-570d-6606-0cb4-cfe2a77b1544 |
| `bank` | text | 데모은행 |
| `account_enc` | text | M26i8H5DhjCao8Rlz5jWtH5mZc9QTDQpmjoUbwaaq8CZmYU2U06iO/UpYpM… |
| `account_last4` | text | 5678 |
| `holder` | text | 김태현 |
| `verified_at` | timestamp with time zone | 2026-05-29T09:18:40.845049+09:00 |

## `pros` — Partner cleaning teams (owner account) · 파트너(청소팀) 계정

12 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | b42ab2c1-570d-6606-0cb4-cfe2a77b1544 |
| `phone` | text | 01000010001 |
| `name` | text | 김태현 |
| `team_name` | text | 말끔케어 강남팀 |
| `status` | text | verified |
| `fee_bps` | integer | 2000 |
| `locale` | text | ko |
| `created_at` | timestamp with time zone | 2026-05-26T09:18:40.845049+09:00 |
| `deleted_at` | timestamp with time zone | — |

## `push_tokens` — Phone addresses for push notifications · 푸시 알림 기기

40 rows in the demo.

| column | type | example |
|---|---|---|
| `token` | text | •••• (hidden) |
| `owner_role` | text | customer |
| `owner_id` | uuid | ea2a0b06-57f7-44d3-5519-11f2c7da556c |
| `platform` | text | android |
| `updated_at` | timestamp with time zone | 2026-11-11T05:18:40.845049+09:00 |

## `quotes` — Partner price offers for quote-type jobs · 파트너 견적

111 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 4b285cb0-f277-4601-4596-aa095ce642dd |
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `pro_id` | uuid | 30fcd602-f775-5e64-373a-4282037641ac |
| `amount` | bigint | 427400 |
| `note` | text | 작업은 약 5시간 예상해요. |
| `state` | text | rejected |
| `seen_by_pro` | boolean | True |
| `created_at` | timestamp with time zone | 2026-08-27T17:00:00+09:00 |
| `updated_at` | timestamp with time zone | 2026-08-27T17:00:00+09:00 |

## `referrals` — Invite-a-friend links and rewards · 친구 초대

0 rows in the demo.

| column | type | example |
|---|---|---|
| `referred_user_id` | uuid | (empty) |
| `referrer_id` | uuid | (empty) |
| `referred_phone` | text | (empty) |
| `state` | text | (empty) |
| `created_at` | timestamp with time zone | (empty) |
| `rewarded_at` | timestamp with time zone | (empty) |

## `refresh_tokens` — Signed-in devices (hashed) · 로그인 유지 기록

11 rows in the demo.

| column | type | example |
|---|---|---|
| `token_hash` | text | •••• (hidden) |
| `subject` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `role` | text | customer |
| `expires_at` | timestamp with time zone | 2026-12-11T05:18:40.845049+09:00 |
| `revoked_at` | timestamp with time zone | 2026-11-06T05:18:40.845049+09:00 |

## `reviews` — Star ratings after a job · 리뷰

76 rows in the demo.

| column | type | example |
|---|---|---|
| `booking_id` | uuid | 68063141-adef-6bd7-ea7e-4a19e62d00bf |
| `user_id` | uuid | 4aeba51c-05ed-5737-42dc-024f99c03bc2 |
| `pro_id` | uuid | 81782a47-8aa7-37c2-8de8-1ea56d69cefa |
| `rating` | smallint | 5 |
| `body` | text | 이사 나가는 날이라 급했는데 빠르게 정리해 주셨어요. |
| `hidden` | boolean | False |
| `created_at` | timestamp with time zone | 2026-11-10T16:00:00+09:00 |
| `photos` | jsonb | [] |

## `services` — What can be booked and its price rules · 서비스 목록과 가격 규칙

8 rows in the demo.

| column | type | example |
|---|---|---|
| `code` | text | studio |
| `pricing` | jsonb | {"type": "fixed", "price": 45000, "minutes": 120} |
| `needs_preparation` | boolean | True |
| `max_pyeong` | smallint | 10 |
| `content` | jsonb | {} |
| `active` | boolean | True |
| `sort_order` | integer | 0 |
| `updated_at` | timestamp with time zone | 2026-11-11T05:18:39.695656+09:00 |

## `settings` — Shop settings (hours, prices formula, offers) · 매장 설정

3 rows in the demo.

| column | type | example |
|---|---|---|
| `key` | text | •••• (hidden) |
| `value` | jsonb | {"duplex": 60000, "vat_bps": 1000, "type_bps": {"same_day_m… |
| `updated_at` | timestamp with time zone | 2026-11-11T05:18:39.899959+09:00 |

## `settlements` — What each partner is owed per job · 파트너 정산

131 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | f727234b-0815-c898-9574-0741042652dc |
| `pro_id` | uuid | 0dbf64ce-9e66-c737-9165-a9795e5b8271 |
| `booking_id` | uuid | 2ec5bd13-9f53-7108-2ac8-910ffdb5878d |
| `gross` | bigint | 437400 |
| `fee` | bigint | 78732 |
| `net` | bigint | 358668 |
| `payout_date` | date | 2026-09-02 |
| `state` | text | paid |
| `paid_at` | timestamp with time zone | 2026-09-02T14:00:00+09:00 |
| `created_at` | timestamp with time zone | 2026-09-01T15:00:00+09:00 |

## `slot_capacity` — How many bookings each arrival hour can take · 시간대별 예약 한도

4 rows in the demo.

| column | type | example |
|---|---|---|
| `start_hour` | smallint | 8 |
| `capacity` | integer | 6 |

## `staff` — Office staff who use the console · 콘솔 직원 계정

3 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 3e7bbd64-a901-440a-8542-dc0d37b3008e |
| `email` | text | admin@local.test |
| `name` | text | Admin |
| `password_hash` | text | •••• (hidden) |
| `role` | text | admin |
| `active` | boolean | True |
| `created_at` | timestamp with time zone | 2026-11-11T05:18:40.808571+09:00 |
| `failed_logins` | integer | 0 |
| `locked_until` | timestamp with time zone | — |

## `team_members` — People in a partner's team · 파트너 팀원

18 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | bfd9dffc-d8dc-9ced-112b-ff3a4682de66 |
| `pro_id` | uuid | b42ab2c1-570d-6606-0cb4-cfe2a77b1544 |
| `name` | text | 김태현 |
| `phone` | text | 01000010001 |
| `role` | text | owner |
| `invite_status` | text | active |
| `created_at` | timestamp with time zone | 2026-05-26T09:18:40.845049+09:00 |
| `last_login_at` | timestamp with time zone | — |

## `uploads` — Uploaded photos · 업로드 사진

1 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | d5ed5aa2-47bb-04a6-cb7e-8be853face77 |
| `owner_role` | text | staff |
| `owner_id` | uuid | 0a8e96fb-ef01-6fd5-ed9c-9606f75c4d12 |
| `file` | text | de30de30de30de30de30de30de30de30.png |
| `bytes` | bigint | 70 |
| `created_at` | timestamp with time zone | 2026-11-11T05:18:40.828684+09:00 |

## `user_identities` — Kakao/Naver/Google/Apple links to an account · 간편 로그인 연결

15 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 94438c03-b73c-043e-1926-135979b4e326 |
| `provider` | text | kakao |
| `provider_user_id` | text | demo_kakao_0001 |
| `role` | text | customer |
| `subject_id` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `email` | text | — |
| `created_at` | timestamp with time zone | 2026-05-29T23:18:40.845049+09:00 |

## `users` — Customers who signed up · 고객 계정

40 rows in the demo.

| column | type | example |
|---|---|---|
| `id` | uuid | 1bf6a875-3d6b-47ed-6f07-65b415c3bc07 |
| `phone` | text | 01000000001 |
| `name` | text | 한지민 |
| `email` | text | user001@demo.invalid |
| `locale` | text | ko |
| `welcome_issued` | boolean | True |
| `created_at` | timestamp with time zone | 2026-05-29T23:18:40.845049+09:00 |
| `deleted_at` | timestamp with time zone | — |
| `identity_verified_at` | timestamp with time zone | 2026-05-30T23:18:40.845049+09:00 |
| `ci_hash` | text | — |
| `referral_code` | text | — |

