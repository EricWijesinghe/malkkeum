# Microsoft Store 제출 가이드 · Microsoft Store submission guide

대상 앱 3개: 고객 앱(말끔), 관리자 앱(말끔 관리자), 파트너 앱(말끔 파트너). 각각 Partner Center에서 **별도 앱**으로 등록합니다.
Three apps (customer, console, partner). Each is a **separate app** in Partner Center.

설명 문구는 `docs/store/listing-ko.md`, `listing-en.md` 등을 그대로 씁니다. 글자 수는 `python -I docs/store/check_listings.py`로 확인합니다.
Listing text: copy from `listing-ko.md`, `listing-en.md` and the others. Check lengths with `python -I docs/store/check_listings.py`.

---

## 1. 준비물 · Before you start

| 항목 | 설명 |
|---|---|
| Partner Center 계정 | 개인 또는 회사 계정. 등록비가 필요합니다. / Individual or company account. A registration fee applies. |
| 개인정보처리방침 URL | `https://도메인/privacy.html` (`docs/store/app-privacy.md` 참고). 공개 접속이 되어야 합니다. / Must be publicly reachable. |
| 스크린샷 | 가로 1366×768 이상. 권장 1920×1080. 최소 1장, 최대 10장. / Landscape, at least 1366×768 (1920×1080 recommended). 1–10 images. |
| 앱 아이콘 | 원본 1024×1024 PNG (`app/apps/*/ios/.../Icon-App-1024x1024@1x.png`). 스토어가 크기를 자동으로 만듭니다. / Source 1024×1024 PNG; the Store generates the sizes. |
| 패키지 파일 | `dist/msix/malkkeum-customer.msix` 등 (아래 3번). / Package files from step 3. |

## 2. 이름 예약 · Reserve the name (Partner Center)

1. Partner Center 로그인 → **앱 관리 > 앱 만들기** / Sign in → **Apps > New product**.
2. 앱 이름 입력 후 예약 / Enter the name and reserve it.
   - 고객: `말끔` (영문 Malkkeum) / Customer: 말끔 (Malkkeum)
   - 관리자: `말끔 관리자` / Console: 말끔 관리자
   - 파트너: `말끔 파트너` / Partner: 말끔 파트너
3. **제품 ID / 패키지 ID 값 복사** (앱 관리 > 제품 식별 / App identity): **Package/Identity/Name**, **Package/Identity/Publisher**, **Package/Identity/PublisherDisplayName**.
   이 3개 값을 `scripts/store/msix.local.psd1` 파일 또는 환경 변수에 넣습니다. 이 값은 Git에 올리지 않습니다.
   Copy the three values from **App identity**. Put them in `scripts/store/msix.local.psd1` (or env vars). Never commit them.

```powershell
# scripts/store/msix.local.psd1  (gitignored)
@{
  MSIX_PUBLISHER                = 'CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
  MSIX_PUBLISHER_DISPLAY_NAME   = 'Malkkeum'
  MSIX_IDENTITY_CUSTOMER        = '12345Malkkeum.Customer'
  MSIX_IDENTITY_CONSOLE         = '12345Malkkeum.Console'
  MSIX_IDENTITY_PARTNER         = '12345Malkkeum.Partner'
}
```

## 3. 패키지 만들기 · Build the package (owner or developer)

```powershell
pwsh scripts/store/build-msix.ps1 -Store
```

- 결과: `dist/msix/malkkeum-customer.msix`, `malkkeum-console.msix`, `malkkeum-partner.msix` (서명되지 않은 스토어용 패키지). / Output: unsigned store packages.
- 로컬 설치 테스트용은 `pwsh scripts/store/build-msix.ps1` (인증서로 서명). / Without `-Store` it is test-signed for local install.

## 4. 연령 등급 · Age rating (IARC)

1. 앱 > **등급 / Age ratings** > 설문 시작 / Start the questionnaire.
2. 답변: 폭력·성적 콘텐츠 없음, 사용자 간 상호작용(채팅·사진 업로드) 있음, 실제 금전 거래 있음 (예약 결제). / Answer: no violence or sexual content; user interaction (chat, photo upload) yes; real-money transactions yes (bookings).
3. 결과 등급이 표시됩니다. 보통 전체 이용가 또는 12세 이상입니다. / Shows the resulting rating.

## 5. 개인정보 · Privacy

- **개인정보처리방침 URL** 입력 (1번 참고). / Enter the privacy policy URL.
- **데이터 수집 항목** 은 `docs/store/app-privacy.md` 표를 따릅니다. / Data collection answers follow `docs/store/app-privacy.md`.

## 6. 기능 설정 · Capabilities

- 패키지 기능은 `internetClient` 하나만 씁니다. 카메라·위치·알림 권한은 요청하지 않습니다. / The package requests only `internetClient`. No camera, location or notification capability.
- Windows 버전은 소셜 로그인(카카오·네이버·구글·애플)과 푸시 알림을 쓰지 않습니다. 이 기능이 없어도 된다고 심사에 설명하세요. / The Windows build has no social login and no push. Say so in the notes to testers.

## 7. 스크린샷 · Screenshots

- 1366×768 이상으로 찍습니다. 앱 창은 기본 1366×800이라 그대로 캡처하면 됩니다. / Capture at 1366×768 or larger; the default window is 1366×800.
- 한국어 화면 기준으로 5장 권장: 홈, 예약, 결제 전 확인, 예약 내역, 프로필. / Recommended five Korean screens.

## 8. 제출 · Submit

1. **패키지** 메뉴 > 3번에서 만든 `.msix` 파일 업로드. 이 빌드는 지원 언어 14개(en-us, ko-kr, ja-jp, zh-cn, vi-vn, th-th, id-id, fil-ph, km-kh, mn-mn, ne-np, ru-ru, si-lk, uz-latn-uz)를 포함합니다. / Upload the `.msix`. It lists 14 languages.
   - Partner Center가 `.msixupload`를 요구하면 `.msix` 하나를 같은 이름으로 묶어 올립니다. 최신 흐름은 `.msix`를 바로 받습니다. / If Partner Center asks for `.msixupload`, use the same package in that wrapper; the current flow accepts `.msix` directly.
2. **스토어 목록** 에 `listing-ko.md` 문구와 스크린샷 입력. / Fill the store listing from the listing files and screenshots.
3. **가격 및 공개 범위** → 무료, 대한민국 등 판매 국가 선택. / Pricing: free, choose countries.
4. **인증서** 메뉴 확인 후 **제출 / Submit for certification**. 심사는 보통 1–3일입니다. / Review usually takes 1–3 days.

## 9. 문제 해결 · Troubleshooting

| 증상 / Symptom | 원인 / Cause | 해결 / Fix |
|---|---|---|
| 업로드 시 "Publisher 불일치" | `msix.local.psd1` 의 Publisher 값이 Partner Center와 다름 | 제품 식별 값 다시 복사 / Copy the identity values again |
| 로컬 설치 시 "신뢰할 수 없는 게시자" | 테스트 인증서 미설치 | `build-msix.ps1` 를 다시 실행 (인증서를 TrustedPeople에 설치) / Re-run the script |
| 파트너 앱 아이콘이 기본값 | 아이콘 빌드 누락 | `app/apps/partner/windows/runner/resources/app_icon.ico` 확인 / Check the file |
