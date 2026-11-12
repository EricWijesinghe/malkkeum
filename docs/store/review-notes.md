# 스토어 심사 안내 (App Review / Play 심사 메모) · Store review notes

이 문서는 심사팀에 전달할 내용의 원본이에요. 실제 전화번호와 인증번호는 **저장소에 적지 않아요**. 제출할 때 아래 `<…>` 자리를 채워 Play Console 의 "앱 액세스" 와 App Store Connect 의 "심사 정보 > 메모" 에 붙여 넣으세요.
These notes are the source text for reviewers. Real phone numbers and codes are **never committed**: fill the `<…>` placeholders at submission time and paste into Play Console "App access" and App Store Connect "App Review Information > Notes".

---

## 1. 로그인 방법 (한국어)

말끔은 휴대폰 번호 인증(문자 메시지 인증번호)으로 로그인해요. 한국 휴대폰 번호가 없는 심사팀을 위해, 심사 전용 번호 하나에 대해서만 인증번호를 고정했어요.

- **고객 앱**: 로그인 화면에서 휴대폰 번호 `<REVIEW_PHONE>` 을 입력하고 인증번호 `<REVIEW_CODE>` 를 입력하세요. 이 번호로는 문자가 발송되지 않아요.
- **파트너 앱**: 같은 번호 `<REVIEW_PHONE>` 과 인증번호 `<REVIEW_CODE>` 로 로그인해요. 파트너 계정은 운영팀 승인 후 일감 화면이 열려요. 제출 전에 운영팀이 이 번호의 파트너 계정을 승인해 두세요.
- 심사 계정은 샘플 예약 2건(예정 1건, 완료 1건)이 미리 들어 있어요. 결제 없이 예약 화면과 내역을 볼 수 있어요.
- 소셜 로그인(카카오, 네이버, 구글, 애플)도 있어요. 소셜 로그인은 실제 계정이 필요하므로 심사에는 위 번호 로그인을 사용해 주세요.
- 심사 계정은 **심사 기간 동안만** 켜져 있고, 설정한 날짜(최대 30일)가 지나면 자동으로 꺼져요.

## 2. Sign-in instructions (English)

Malkkeum signs users in with a phone number and a one-time code sent by SMS. Reviewers outside Korea cannot receive Korean SMS, so one review-only phone number has a fixed code. No SMS is sent for that number, and no other number can use the fixed code.

- **Customer app**: enter phone `<REVIEW_PHONE>` and code `<REVIEW_CODE>`.
- **Partner app**: sign in with the same phone and code. The partner account is shown once the operations team approves it, which we do before submission.
- The review customer account already has two sample bookings (one upcoming, one completed), so the booking and history screens can be reviewed without paying.
- Social login (Kakao, Naver, Google, and Sign in with Apple on iOS) is also offered. It needs a real account, so please use the phone login above.
- The review account is switched off automatically after the period we set (at most 30 days).

## 3. 계정 삭제 (Account deletion)

- 앱 안에서: 더보기 → 계정 → 회원 탈퇴 (고객 앱, 파트너 앱 모두).
- 웹(앱을 쓸 수 없을 때): `https://<도메인>/delete-account.html`
- 파트너는 배정된 작업이 있으면 서버가 탈퇴를 거절해요 (작업 종료 후 탈퇴).
- In-app: More → Account → Delete account (customer and partner apps). Web fallback: `https://<domain>/delete-account.html`. Partners with an assigned job are refused by the server until the job is closed.

## 4. 결제 (Payments)

- 말끔은 **방문 청소 서비스**(실제 장소에서 제공되는 물리적 서비스)를 팔아요. 디지털 콘텐츠나 구독은 없어요.
- 결제는 국내 결제대행사 PortOne 을 통해 카드 등으로 처리해요. 인앱 결제(Apple IAP, Google Play Billing)는 쓰지 않아요. 앱 밖에서 소비되는 실물 서비스이므로 해당 정책의 예외에 해당한다고 판단했어요.
- Malkkeum sells in-person home cleaning, a physical service consumed outside the app. Payment goes through PortOne (Korean PG). No digital goods or subscriptions are sold, so in-app purchase is not used.

## 5. 권한 (Permissions)

| 권한 | 이유 | 요청 시점 |
|---|---|---|
| 카메라 | 청소 전후 사진을 바로 찍어 올리기 | 사진 찍기를 누를 때 |
| 사진 보관함 | 청소 전후 사진, 상담 사진 올리기 | 사진 고르기를 누를 때 (Android 는 사진 선택기, 별도 저장소 권한 없음) |
| 알림 | 예약·작업 알림 (푸시) | 앱 실행 후 안내에 따라 (Android 13+ 는 POST_NOTIFICATIONS 런타임 요청) |

위치 권한은 요청하지 않아요. 주소는 사용자가 직접 입력하거나 고른 주소만 저장해요.

## 6. 기타 질문 (Other answers)

- 광고: 없음 (광고 SDK 없음, 광고 ID 미사용).
- 추적: 없음 (ATT 요청 없음).
- 대상 연령: 성인 (아동 대상 아님). 아동을 겨냥한 기능은 없어요.
- 암호화: 앱은 HTTPS 등 OS 가 제공하는 표준 암호화만 써요 (iOS `ITSAppUsesNonExemptEncryption = false`).
- 금융 기능: 대금 결제 대행만 하며 대출, 송금, 투자 등 금융 상품은 없어요. 파트너 정산은 정산 계좌 입력 후 운영팀이 처리해요.
- 개인정보처리방침: `https://<도메인>/privacy.html`
- AI 상담: 고객 채팅에 AI 가 답할 수 있어요 (설정으로 끌 수 있음). 응답은 Anthropic API 로 만들어요.
- 사용자 생성 콘텐츠: 후기(사진 포함)가 다른 이용자에게 보여요. 모든 후기에는 앱 안에서 **신고** 버튼이 있고(사유 4가지, 1인 1회), 신고가 3건(서버 설정) 모이면 자동으로 숨겨져 운영팀 심사 대기열에 올라가요. 운영팀은 유지·숨기기·삭제와 작성자 후기 제한을 할 수 있어요. 후기 작성 화면에도 콘텐츠 규칙을 안내해요. 이용약관 제9조에 같은 내용이 있어요.

## 7. 제출 전 확인 (owner checklist, not for reviewers)

- [ ] 콘솔 설정 > 심사 계정: 번호와 인증번호 입력, 기간 설정 (저장 시 샘플 예약 2건 자동 생성)
- [ ] 파트너 심사 번호의 파트너 계정을 "승인" 처리
- [ ] 위 `<…>` 자리 채우기 (Play "앱 액세스", App Store "심사 메모")
- [ ] 심사 기간이 끝나기 전 제출, 승인 후 심사 계정을 끄거나 기간 만료 확인
- [ ] 콘솔 > 마케팅 > 성장 > 후기 신고 관리에 대기 건이 있으면 처리 (심사 중 신고가 들어오면 바로 처리)
- [ ] Sign in with Apple: 콘솔 Apple 카드에 키(.p8) 입력, Apple 개발자 계정에 서버 알림 URL `https://<API_DOMAIN>/v1/auth/apple/notifications` 등록
