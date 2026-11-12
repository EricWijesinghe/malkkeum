# 스토어 심사 안내 (App Review / Play 심사 메모) · Store review notes

이 문서는 심사팀에 전달할 내용의 원본이에요. 실제 전화번호와 인증번호는 **저장소에 적지 않아요**. 제출할 때 아래 `<…>` 자리를 채워 Play Console 의 "앱 액세스" 와 App Store Connect 의 "심사 정보 > 메모" 에 붙여 넣으세요.
These notes are the source text for reviewers. Real phone numbers and codes are **never committed**: fill the `<…>` placeholders at submission time and paste into Play Console "App access" and App Store Connect "App Review Information > Notes".

---

## 1. 로그인 방법 (한국어)

다해는 휴대폰 번호 인증(문자 메시지 인증번호)으로 로그인해요. 한국 휴대폰 번호가 없는 심사팀을 위해, 심사 전용 번호 하나에 대해서만 인증번호를 고정했어요.

- **고객 앱**: 로그인 화면에서 휴대폰 번호 `<REVIEW_PHONE>` 을 입력하고 인증번호 `<REVIEW_CODE>` 를 입력하세요. 이 번호로는 문자가 발송되지 않아요.
- **파트너 앱**: 같은 번호 `<REVIEW_PHONE>` 과 인증번호 `<REVIEW_CODE>` 로 로그인해요. 파트너 계정은 운영팀 승인 후 일감 화면이 열려요. 제출 전에 운영팀이 이 번호의 파트너 계정을 승인해 두세요.
- 심사 계정은 샘플 예약 2건(예정 1건, 완료 1건)이 미리 들어 있어요. 결제 없이 예약 화면과 내역을 볼 수 있어요.
- 소셜 로그인(카카오, 네이버, 구글, 애플)도 있어요. 소셜 로그인은 실제 계정이 필요하므로 심사에는 위 번호 로그인을 사용해 주세요.
- 심사 계정은 **심사 기간 동안만** 켜져 있고, 설정한 날짜(최대 30일)가 지나면 자동으로 꺼져요.

## 2. Sign-in instructions (English)

Dahae signs users in with a phone number and a one-time code sent by SMS. Reviewers outside Korea cannot receive Korean SMS, so one review-only phone number has a fixed code. No SMS is sent for that number, and no other number can use the fixed code.

- **Customer app**: enter phone `<REVIEW_PHONE>` and code `<REVIEW_CODE>`.
- **Partner app**: sign in with the same phone and code. The partner account is shown once the operations team approves it, which we do before submission.
- The review customer account already has two sample bookings (one upcoming, one completed), so the booking and history screens can be reviewed without paying.
- Social login (Kakao, Naver, Google, and Sign in with Apple on iOS) is also offered. It needs a real account, so please use the phone login above.
- The review account is switched off automatically after the period we set (at most 30 days).

## 3. 계정 삭제 (Account deletion)

- 앱 안에서: 더보기 → 계정 → 회원 탈퇴 (고객 앱, 파트너 앱 모두). 웹 화면이나 전화로 넘기지 않고 앱 안에서 끝나요.
- 웹(앱을 쓸 수 없을 때): `https://<도메인>/delete-account.html`
- 고객이 탈퇴하면 저장된 카드의 자동결제 키를 결제대행사에서 먼저 지워요. 그래서 정기 청소 결제도 더는 일어나지 않아요.
- 파트너는 배정된 작업이 있으면 서버가 탈퇴를 거절해요 (작업 종료 후 탈퇴).
- 법으로 보관해야 하는 예약·결제 기록(5년)은 남고, 그 사실은 개인정보처리방침과 위 웹 페이지에 적혀 있어요.
- In-app: More → Account → Delete account (customer and partner apps). Deletion completes inside the app. Web fallback: `https://<domain>/delete-account.html`. Saved-card billing keys are deleted at the payment gateway first, so no further charge can occur. Booking and payment records are kept for five years as Korean e-commerce law requires; this is stated in the privacy policy. Partners with an assigned job are refused by the server until the job is closed.

> **병합 대기 (pending merge, WP-A) — 아직 출시 전이에요.** Apple 로그인 토큰 해지(Sign in with Apple REST API `auth/revoke`), Apple 서버 알림 수신 주소(`POST /v1/auth/apple/notifications`, 한국 개발자는 Services ID 등록 때 필수), 고객 탈퇴 시 소셜 연결 삭제는 다른 작업에서 만들고 있어요. 합쳐진 것을 확인한 뒤에만 아래 문장을 심사 메모에 넣으세요. 합쳐지기 전에는 넣지 마세요.
> "Deleting an account that used Sign in with Apple also revokes the Apple tokens through the Sign in with Apple REST API, and we process Apple server-to-server notifications (consent-revoked, account-delete)."

## 4. 결제 (Payments)

다해가 파는 것은 전부 **사람이 집에 방문해서 하는 청소**예요. 앱 안에서 쓰는 디지털 상품이나 기능 잠금 해제는 없어요.

| 앱에서 돈이 오가는 것 | 내용 | 근거 |
|---|---|---|
| 1회 청소 예약 | 방문 청소 요금 | `apps/customer/lib/screens/booking_flow.dart` |
| **정기 청소 (구독)** | 매주·2주·4주마다 같은 요일에 방문하는 청소 일정. 방문 **전날** 그 방문 1회분을 저장된 카드로 결제해요. 앱에서 일시정지, 재개, 해지, 방문 건너뛰기·날짜 변경을 할 수 있어요. 구독으로 열리는 앱 기능은 없어요 | `subscribe.dart`, `subscriptions.dart`, `backend/migrations/0066_subscriptions.sql` |
| 팁 (선택) | 청소가 끝난 뒤 고객이 원하면 주는 팁. 전액 청소 파트너에게 가요 | `backend/migrations/0076_tips.sql` |
| 쿠폰 · 포인트 | 청소 요금을 깎아 주는 혜택. **팔지 않아요.** 예약·가입·친구 초대로만 생기고, 현금으로 바꿀 수 없어요 (포인트는 병합 대기, money 브랜치 `00f107b`) | `coupons`, `points_ledger` |

- 결제는 국내 결제대행사 PortOne(연동 PG: 토스페이먼츠 등)의 결제 화면에서 해요. 카드 번호는 앱과 서버가 받지 않아요.
- **Apple**: 심사 지침 3.1.3(e) 는 "앱 밖에서 소비되는 실물 상품·서비스"는 인앱 결제가 **아닌** 결제 수단(카드 등)을 써야 한다고 정해요. 그래서 인앱 결제(IAP)를 쓰지 않아요. 3.1.1(인앱 결제 의무)은 앱 안의 기능·콘텐츠를 여는 경우에 적용되는데, 다해에는 그런 상품이 없어요. 3.1.2 의 "자동 갱신 구독"도 인앱 결제 상품에 관한 규정이라 정기 청소에는 해당하지 않아요.
- **Google**: Play 결제 정책도 실물 상품·서비스 결제에는 Play 결제 시스템을 쓰지 않도록 해요.

심사 메모에 붙여 넣을 영어 문장:

```
PAYMENTS (Guideline 3.1.3(e))
Everything sold in this app is in-person home cleaning performed at the customer's
home, i.e. a physical service consumed outside the app. Under Guideline 3.1.3(e) such
purchases must use a payment method other than in-app purchase, so payments go through
the Korean payment gateway PortOne (card and local wallets) on the gateway's hosted
page. The app unlocks no digital content, features or functionality for money, so
Guideline 3.1.1 does not apply.

"Regular cleaning" (shown as a subscription) is a recurring schedule of in-person
visits: weekly, every 2 weeks or every 4 weeks. Each visit is charged individually to
the saved card the day before that visit. It is not an auto-renewable digital
subscription (3.1.2). The customer can pause, resume, cancel, skip or move a visit in
the app: More > Regular cleaning.

Optional tips after a completed visit go in full to the cleaner who performed the
physical service. Coupons and loyalty points only reduce the price of a cleaning visit;
they are never sold and cannot be cashed out.
```

## 5. 권한 (Permissions)

| 권한 | 앱 | 이유 | 요청 시점 |
|---|---|---|---|
| 사진 고르기 | 고객, 파트너 | 청소 전후 사진, 상담·후기 사진 올리기 | 사진 버튼을 누를 때. 운영체제의 사진 선택기(Android 사진 선택기, iOS PHPicker)를 써서 사용자가 고른 사진만 앱에 전달돼요. 사진 보관함 전체 접근 권한을 묻지 않아요 |
| 카메라 | 없음 | 이 버전은 앱에서 카메라를 직접 열지 않아요 (사진은 보관함에서 골라요) | 요청하지 않음 |
| 알림 | 고객, 파트너 | 예약·작업 알림 (푸시) | 로그인한 뒤 (Android 13+ 는 POST_NOTIFICATIONS 런타임 요청) |
| 위치 (사용 중에만) | 고객만 | 주소 입력 화면의 [현재 위치로 찾기] | 그 버튼을 누를 때만 |

- 위치: 좌표는 휴대폰의 주소 변환에만 쓰고 다해 서버로 보내지 않아요. 백그라운드 위치는 쓰지 않아요. 권한을 거절해도 주소를 직접 입력해 모든 기능을 쓸 수 있어요. 파트너 앱은 위치 권한을 요청하지 않아요.
- iOS `Info.plist` 에는 카메라·사진 보관함 사용 문구(`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)가 들어 있어요. 사진 찍기 버튼을 넣을 때를 대비한 문구이고, 지금 버전은 카메라 권한 창을 띄우지 않아요. 심사팀이 물으면 이렇게 답하세요.
- 알림을 거절해도 앱은 그대로 쓸 수 있어요 (문자로 안내).
- Android 포그라운드 서비스는 쓰지 않아요.

## 6. 기타 질문 (Other answers)

- 광고: 없음 (광고 SDK 없음, 광고 ID 미사용).
- 추적: 없음 (ATT 요청 없음).
- 사용 통계: 고객 앱은 마케팅 수신에 동의한 사용자에 한해 정해진 이벤트 8가지를 임의 설치 ID 로 자체 서버에 보내요. 외부 분석 SDK 는 없어요.
- 대상 연령: 성인 (아동 대상 아님). 아동을 겨냥한 기능은 없어요.
- 암호화: 앱은 HTTPS 등 OS 가 제공하는 표준 암호화만 써요 (iOS `ITSAppUsesNonExemptEncryption = false`).
- 금융 기능: 청소 대금 결제만 하며 대출, 송금, 투자 등 금융 상품은 없어요. 파트너 정산은 정산 계좌 입력 후 운영팀이 처리해요.
- 개인정보처리방침: `https://<도메인>/privacy.html`
- 로그인: 소셜 로그인(카카오, 네이버, 구글)을 제공하므로 iOS 에서는 Apple 로 로그인도 함께 제공해요 (지침 4.8).
- AI 상담: 고객 채팅에 AI 가 답할 수 있어요 (설정으로 끌 수 있음). 응답은 Anthropic API 로 만들어요. 가입 때 국외 이전 동의에서 Anthropic 을 밝히고 동의를 받아요 (지침 5.1.2(i)). 운영팀 직원이 답하면 AI 는 그 대화에서 물러나요.
- 채팅: 고객과 파트너는 각각 **운영팀과만** 대화해요. 이용자끼리 직접 대화하는 기능은 없어요.
- 사용자 생성 콘텐츠: 후기(사진 포함)가 다른 이용자에게 보여요. 모든 후기에는 앱 안에서 **신고** 버튼이 있고(사유 4가지, 1인 1회), 신고가 3건(서버 설정) 모이면 자동으로 숨겨져 운영팀 심사 대기열에 올라가요. 운영팀은 유지·숨기기·삭제와 작성자 후기 제한을 할 수 있어요. 후기 작성 화면에도 콘텐츠 규칙을 안내해요. 이용약관 제9조에 같은 내용이 있어요.
- 연령 등급 설문 답: Apple 은 `app-privacy.md` 2항, Google·Microsoft(IARC)는 `play-declarations.md` 5항.

## 7. 제출 전 확인 (owner checklist, not for reviewers)

- [ ] 콘솔 설정 > 심사 계정: 번호와 인증번호 입력, 기간 설정 (저장 시 샘플 예약 2건 자동 생성)
- [ ] 파트너 심사 번호의 파트너 계정을 "승인" 처리
- [ ] 위 `<…>` 자리 채우기 (Play "앱 액세스", App Store "심사 메모")
- [ ] 심사 기간이 끝나기 전 제출, 승인 후 심사 계정을 끄거나 기간 만료 확인
- [ ] 콘솔 > 마케팅 > 성장 > 후기 신고 관리에 대기 건이 있으면 처리 (심사 중 신고가 들어오면 바로 처리)
- [ ] Sign in with Apple: 콘솔 Apple 카드에 키(.p8) 입력, Apple 개발자 계정에 서버 알림 URL `https://<API_DOMAIN>/v1/auth/apple/notifications` 등록
- [ ] 이름 변경(다해) 확인 목록: 상표(KIPRIS), 카카오 채널·알림톡, PG 가맹점 이름, 약관 변경 7일 전 공지 → `docs/REBRAND-CHECKLIST.md`
