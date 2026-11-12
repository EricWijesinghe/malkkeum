# Microsoft Store 제출 가이드 · Microsoft Store submission guide

대상 앱은 **2개**예요: 고객 앱(다해), 파트너 앱(다해 파트너). 각각 Partner Center에서 **별도 앱**으로 등록해요.
Two apps (customer, partner). Each is a **separate app** in Partner Center.

**사장님용 관리 화면(콘솔)은 스토어 앱이 아니에요.** 웹 브라우저에서 `https://도메인/admin/` 으로 접속해요. Microsoft Store 에 올리지 않고, 이름 예약도 하지 않아요.
**The owner console is web-only** at `https://DOMAIN/admin/`. It is not submitted to the Microsoft Store and needs no name reservation.

설명 문구는 `docs/store/listing-ko.md`, `listing-en.md` 등을 그대로 써요. 글자 수는 `python -I docs/store/check_listings.py`로 확인해요.
Listing text: copy from `listing-ko.md`, `listing-en.md` and the others. Check lengths with `python -I docs/store/check_listings.py`.

기준 정책: Microsoft Store Policies 7.20 (2026-09-14, https://learn.microsoft.com/en-us/windows/apps/publish/store-policies).

---

## 1. 준비물 · Before you start

| 항목 | 설명 |
|---|---|
| Partner Center 계정 | **회사(Company) 계정**이어야 해요. 정책 10.8.3: 계좌·카드 같은 금융 정보를 받는 앱은 개인 계정으로 낼 수 없어요 (고객 앱은 카드 등록, 파트너 앱은 정산 계좌). 등록비가 있어요. / Must be a **Company** account (policy 10.8.3: the apps take card and bank-account details). A registration fee applies. |
| 개인정보처리방침 URL | `https://도메인/privacy.html`. 로그인 없이 열려야 해요 (정책 10.5.1). / Must be publicly reachable (policy 10.5.1). |
| 고객 지원 연락처 | 회사 계정은 스토어 화면에 고객 지원 연락처가 표시돼요 (정책 10.14). 고객센터 이메일·전화를 준비하세요. / Company accounts show support contact details. |
| 스크린샷 | 가로 1366×768 이상. 권장 1920×1080. 최소 1장, 최대 10장. / Landscape, at least 1366×768 (1920×1080 recommended). 1–10 images. |
| 앱 아이콘 | 원본 1024×1024 PNG (`app/apps/*/ios/.../Icon-App-1024x1024@1x.png`). 스토어가 크기를 자동으로 만들어요. / Source 1024×1024 PNG; the Store generates the sizes. |
| 패키지 파일 | `dist/msix/malkkeum-customer.msix`, `malkkeum-partner.msix` (아래 3번). / Package files from step 3. |

## 2. 이름 예약 · Reserve the name (Partner Center)

1. Partner Center 로그인 → **앱 관리 > 앱 만들기** / Sign in → **Apps > New product**.
2. 앱 이름 입력 후 예약 / Enter the name and reserve it.
   - 고객: `다해` (영문 Dahae) / Customer: 다해 (Dahae)
   - 파트너: `다해 파트너` / Partner: 다해 파트너
3. **제품 ID / 패키지 ID 값 복사** (앱 관리 > 제품 식별 / App identity): **Package/Identity/Name**, **Package/Identity/Publisher**, **Package/Identity/PublisherDisplayName**.
   이 값을 `scripts/store/msix.local.psd1` 파일 또는 환경 변수에 넣어요. 이 값은 Git에 올리지 않아요.
   Copy the values from **App identity**. Put them in `scripts/store/msix.local.psd1` (or env vars). Never commit them.

```powershell
# scripts/store/msix.local.psd1  (gitignored)
@{
  MSIX_PUBLISHER                = 'CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
  MSIX_PUBLISHER_DISPLAY_NAME   = 'Dahae'
  MSIX_IDENTITY_CUSTOMER        = '12345Dahae.Customer'
  MSIX_IDENTITY_PARTNER         = '12345Dahae.Partner'
}
```

## 3. 패키지 만들기 · Build the package (developer)

```powershell
pwsh scripts/store/build-msix.ps1 -Store -Apps customer,partner
```

- 결과: `dist/msix/malkkeum-customer.msix`, `malkkeum-partner.msix` (서명되지 않은 스토어용 패키지). / Output: unsigned store packages.
- `-Apps customer,partner` 를 꼭 붙이세요. 지금 스크립트는 기본값으로 콘솔 패키지도 만들지만 콘솔은 스토어에 올리지 않아요. / Always pass `-Apps customer,partner`: the script still builds a console package by default, and the console is not a Store app.
- 로컬 설치 테스트용은 `-Store` 없이 실행해요 (인증서로 서명). / Without `-Store` it is test-signed for local install.

> **병합 대기 (pending merge, 빌드 스크립트 작업 WP-D).** 기준 커밋 `a365e37` 의 `build-msix.ps1` 은 (1) 서버 주소(`API_BASE`)를 패키지에 넣지 않아서 앱이 `http://127.0.0.1:8080` 을 바라보고, (2) 패키지 버전이 `1.0.0.0` 으로 고정이라 두 번째 제출이 거절돼요. 이 두 가지가 고쳐진 스크립트로 만든 패키지만 스토어에 올리세요. 올리기 전에 설치해서 실제 서버로 로그인되는지 확인하세요.

## 4. 연령 등급 · Age rating (IARC)

1. 앱 > **등급 / Age ratings** > 설문 시작 / Start the questionnaire (정책 11.11).
2. 답은 `play-declarations.md` 5항 표와 같아요 (Google Play 와 같은 IARC 설문). 요약: 폭력·성적 콘텐츠·도박 없음, 사용자 간 콘텐츠 공유 **예**(후기), 위치 공유 **아니요**, 디지털 상품 구매 **아니요**. / Same answers as `play-declarations.md` section 5: no violence, sexual content or gambling; users share content (reviews) yes; location sharing no; digital purchases no.
3. 결과는 보통 전체 이용가(3+)예요. / Usually rated for all ages.

## 5. 개인정보 · Privacy

- **개인정보처리방침 URL** 입력 (1번 참고). / Enter the privacy policy URL.
- Microsoft Store 에는 Google·Apple 같은 항목별 데이터 표가 없어요. 방침 문서가 수집 항목·이용 목적·제공 대상을 모두 설명해야 해요 (정책 10.5.1). 수집 항목은 `data-safety.md` 와 같아요. / There is no per-data-type form; the policy page must cover what is collected, why and who receives it. The facts are in `data-safety.md`.
- Windows 앱에서 달라지는 점 / What differs on Windows:
  - 푸시 알림이 없어 푸시 토큰을 수집하지 않아요. / No push, so no push token.
  - 소셜 로그인이 없어 제공자 ID·이메일을 새로 받지 않아요. / No social login.
  - 위치 기능이 없어요 ([현재 위치로 찾기] 버튼은 Android·iOS 에서만 보여요). / No location feature.
  - 고객 앱의 사용 통계(마케팅 동의 시, 임의 설치 ID)는 Windows 에서도 같아요. / Consent-gated product analytics is the same.
  - 계정 삭제는 같은 [더보기] → [계정] → [회원 탈퇴] 예요. / Account deletion is the same in-app path.

## 6. 기능 설정과 제출 메모 · Capabilities and submission notes

- 패키지 기능은 `internetClient` 하나만 써요. 카메라·위치·알림 기능은 선언하지 않아요. / The package requests only `internetClient`. No camera, location or notification capability.
- Windows 버전은 소셜 로그인(카카오·네이버·구글·애플)과 푸시 알림을 쓰지 않아요. 로그인은 휴대폰 번호 인증이에요. / The Windows build has no social login and no push; sign-in is by phone code.
- **결제 (정책 10.8.2)**: 방문 청소는 실물 서비스라서 외부 결제(PortOne)를 써요. Windows 에서는 결제 페이지가 기본 브라우저에서 열려요 (`payment_launcher.dart`). 제출할 때 Partner Center 의 "보안 제3자 구매 API 사용" 항목에 **예**로 표시하고, 인증 테스트 메모에 아래 영어 문장을 넣으세요. / Physical service, paid through a third-party gateway opened in the default browser. Declare the third-party purchase API in Partner Center.
- **생성형 AI (정책 11.16)**: 운영자가 AI 상담을 켜면 채팅에서 AI 가 답해요. 제출할 때 "실시간 생성형 AI 사용"을 **예**로 표시하고, 스토어 설명에 한 줄("상담 채팅에서 AI 가 먼저 답할 수 있어요")을 넣으세요. AI 상담을 쓰지 않을 거면 **아니요**로 두고 콘솔에서 AI 상담을 꺼 두세요. **확인 필요**: 이 정책은 사용자가 부적절한 AI 답변을 신고할 방법도 요구해요. 지금은 같은 채팅에서 운영팀에 말하는 방법뿐이에요. / If AI chat is enabled, disclose live generative AI in the listing and in Partner Center. The policy also asks for a way to report inappropriate AI output; today that is the same chat with the operations team.

인증 테스트 메모(Notes for certification)에 넣을 문장. `<…>` 자리는 제출할 때 채워요 (`review-notes.md` 참고). / Paste into "Notes for certification"; fill the placeholders at submission time.

```
Sign-in: phone <REVIEW_PHONE>, code <REVIEW_CODE> (review-only number, no SMS is sent).
The Windows build has no social login and no push notifications.
Payments: the app sells in-person home cleaning (a physical service). Payment uses a
secure third-party purchase API (PortOne, a Korean payment gateway). The hosted payment
page opens in the default browser and the customer confirms every payment there.
No digital goods are sold.
Account deletion: More > Account > Delete account.
```

## 7. 스크린샷 · Screenshots

- 1366×768 이상으로 찍어요. 앱 창은 기본 1366×800이라 그대로 캡처하면 돼요. / Capture at 1366×768 or larger; the default window is 1366×800.
- 한국어 화면 기준으로 5장 권장: 홈, 예약, 결제 전 확인, 예약 내역, 프로필. / Recommended five Korean screens.

## 8. 제출 · Submit

1. **패키지** 메뉴 > 3번에서 만든 `.msix` 파일 업로드. 이 빌드는 지원 언어 14개(en-us, ko-kr, ja-jp, zh-cn, vi-vn, th-th, id-id, fil-ph, km-kh, mn-mn, ne-np, ru-ru, si-lk, uz-latn-uz)를 포함해요. / Upload the `.msix`. It lists 14 languages.
   - Partner Center가 `.msixupload`를 요구하면 `.msix` 하나를 같은 이름으로 묶어 올려요. 최신 흐름은 `.msix`를 바로 받아요. / If Partner Center asks for `.msixupload`, use the same package in that wrapper; the current flow accepts `.msix` directly.
2. **스토어 목록** 에 `listing-ko.md` 문구와 스크린샷 입력. / Fill the store listing from the listing files and screenshots.
3. **가격 및 공개 범위** → 무료, 대한민국 등 판매 국가 선택. / Pricing: free, choose countries.
4. 4·5·6번 답을 넣은 뒤 **제출 / Submit for certification**. 심사는 보통 1–3일이에요. / Review usually takes 1–3 days.

## 9. 문제 해결 · Troubleshooting

| 증상 / Symptom | 원인 / Cause | 해결 / Fix |
|---|---|---|
| 업로드 시 "Publisher 불일치" | `msix.local.psd1` 의 Publisher 값이 Partner Center와 다름 | 제품 식별 값 다시 복사 / Copy the identity values again |
| 로컬 설치 시 "신뢰할 수 없는 게시자" | 테스트 인증서 미설치 | `build-msix.ps1` 를 다시 실행 (인증서를 TrustedPeople에 설치) / Re-run the script |
| 파트너 앱 아이콘이 기본값 | 아이콘 빌드 누락 | `app/apps/partner/windows/runner/resources/app_icon.ico` 확인 / Check the file |
| 설치한 앱이 "서버에 연결할 수 없음" | 패키지에 서버 주소가 안 들어감 | 3번의 병합 대기 안내 확인 / See the pending-merge note in step 3 |
| 두 번째 제출에서 "버전이 이미 있음" | 패키지 버전이 그대로임 | 3번의 병합 대기 안내 확인 / See the pending-merge note in step 3 |

---

## 10. 스토어 설명 · Store description (short; paste into the "Description" field)

Microsoft Store has no 80/30-char fields; use the first lines as the hook (search shows them). Use the full description from `listing-*.md` for the remaining languages. Windows build has no social login or push (see section 6), so these texts do not mention them.

**고객 앱 · 다해 (ko)**
```
입주청소·이사청소·에어컨청소, 가격부터 확인하고 1분 만에 예약하세요.

다해는 본인 인증과 심사를 거친 청소 전문가만 연결해 드리는 홈클리닝 앱이에요.
· 원룸 · 주방 · 욕실 · 매트리스 · 에어컨 · 소파 청소: 앱에서 바로 보는 정찰제 요금
· 이사청소 · 입주청소: 전문가 견적을 받아 비교
· 취소 수수료와 환불액을 취소 전에 미리 안내, 방문 2일 전까지 무료 취소
· 청소팀 배정부터 완료까지 실시간 진행 상황, 전후 사진과 후기
· 앱 채팅 상담, 청소 포인트와 쿠폰
· 14개 언어 지원
```

**Customer app · Dahae (en)**
```
Move-in, move-out and aircon cleaning in Korea. See the price first, book in a minute.

Dahae connects you only with cleaning professionals who passed identity checks and review.
· Studio, kitchen, bathroom, mattress, air conditioner and sofa cleaning at fixed prices
· Move-out and move-in cleaning: compare quotes from professionals
· Cancellation fee and refund shown before you cancel; free cancellation up to 2 days before the visit
· Live progress from team assigned to finished, with before and after photos and reviews
· In-app chat, cleaning points and coupons
· 14 languages
```

**파트너 앱 · 다해 파트너 (ko)**
```
다해 청소 전문가 전용 앱. 내 동네 작업 받기, 이사·입주청소 견적, 일정, 매주 수요일 정산.

· 내 활동 지역과 시간에 맞는 작업만 골라 받기
· 이사·입주청소는 직접 견적 내기
· 길찾기, 일정, 방문 메모, 전후 사진 업로드
· 팀원 초대, 운영팀과 앱 채팅
· 14개 언어 지원
```

**Partner app · Dahae Partner (en)**
```
The app for Dahae cleaning professionals: jobs in your area, quotes, schedule and weekly payouts.

· Pick jobs that match your areas and available hours
· Send your own quotes for move-in and move-out cleanings
· Directions, schedule, visit notes, before and after photos
· Invite team members, chat with the operations team
· Paid out every Wednesday; 14 languages
```
