# iOS 출시 순서 (App Store · TestFlight) / iOS release steps

고객 앱 `com.malkkeum.customer`(다해)와 파트너 앱 `com.malkkeum.partner`(다해 파트너)를 Codemagic 에서 빌드해 소유자의 Apple 개발자 계정으로 올려요. Mac 은 필요 없어요. 개인정보 라벨·수출 규정 답은 `app-privacy.md`, 심사 메모는 `review-notes.md`, 키 목록은 `docs/DEPLOY.md` §3 예요.
Both apps are built on Codemagic and uploaded to the owner's Apple developer account. No Mac needed. Privacy label and export answers: `app-privacy.md`; review notes: `review-notes.md`; key list: `docs/DEPLOY.md` §3.

## 1. 소유자가 준비할 것 / What the owner provides

| # | 준비물 / Item | 어디서 / Where | 비고 / Note |
|---|---|---|---|
| 1 | Apple Developer Program 가입 (연 99 USD, 법인은 D-U-N-S 번호) | developer.apple.com/programs | 개인 계정이면 판매자 이름이 개인 이름으로 보여요. Individual accounts show a personal seller name |
| 2 | App ID 2개 등록: `com.malkkeum.customer`, `com.malkkeum.partner` | Certificates, Identifiers & Profiles → Identifiers | 둘 다 **Push Notifications**, **Sign in with Apple**, **Associated Domains** 켜기. 하나라도 빠지면 Codemagic 서명이 실패해요. Enable all three on both IDs, or signing fails |
| 3 | App Store Connect 앱 2개 만들기 (언어 한국어, 번들 ID 위 2개, SKU 자유) | appstoreconnect.apple.com → Apps → + | 앱을 먼저 만들어야 TestFlight 업로드가 돼요. The app record must exist before the first upload |
| 4 | App Store Connect API 키 (역할 **App Manager**) | Users and Access → Integrations → App Store Connect API → Team Keys | `.p8`(한 번만 내려받기), Key ID, Issuer ID 3가지 |
| 5 | Codemagic 에 연결 | Teams → Integrations → App Store Connect → 이름 **`malkkeum_asc`** | 위 3가지 입력. Enter the three values. `codemagic.yaml` 이 이 이름을 써요 |
| 6 | APNs 인증 키 (`.p8`) | Apple Developer → Keys → Apple Push Notifications service | Firebase 콘솔 → 프로젝트 설정 → Cloud Messaging → Apple 앱 구성에 앱마다 업로드. Upload per iOS app in Firebase |
| 7 | Firebase iOS 앱 2개 (번들 ID 동일) → `GoogleService-Info.plist` | Firebase 콘솔 | `base64 -w0` 로 바꿔 Codemagic 변수 `GOOGLE_SERVICE_INFO_PLIST_B64`(고객), `PARTNER_GOOGLE_SERVICE_INFO_PLIST_B64`(파트너). 없으면 푸시만 꺼진 채로 빌드돼요. Without it the build works, push is off |
| 8 | 로그인 키 | `docs/DEPLOY.md` §3 표 | `GOOGLE_IOS_CLIENT_ID`(번들 ID마다 iOS OAuth 클라이언트), `KAKAO_NATIVE_KEY`(카카오 개발자 콘솔 → 플랫폼 → iOS 번들 ID 등록), 네이버 개발자센터에서 iOS 번들 ID 등록 |
| 9 | `APP_LINK_DOMAIN` (서버 도메인) + 서버 `.env` 의 `APPLE_TEAM_ID` | Apple Developer 우측 상단 Membership → Team ID | 서버가 `/.well-known/apple-app-site-association` 을 내줘야 네이버 로그인이 iOS 17.4+ 에서 돼요. 아래 4항 확인 |
| 10 | Apple 로그인 서버 키 (`.p8`) | 콘솔 Apple 카드, `review-notes.md` §3 | 탈퇴 때 Apple 토큰 해지에 쓰여요 |
| 11 | 스크린샷, 설명, 개인정보처리방침 URL | App Store Connect 앱 페이지 | 아이폰 6.9인치 스크린샷 필수 (`docs/store/screenshots`, 문구 `listing-*.md`). 아이패드용은 필요 없어요 (앱이 아이폰 전용) |

Codemagic 변수 그룹 `malkkeum` 에 넣는 값은 모두 **secure** 로 표시하세요. Mark every value in the group `malkkeum` as secure.

## 2. 첫 빌드 / First build

1. `git tag v1.0.0 && git push origin v1.0.0` 후 Codemagic 에서 `customer-ios`, `partner-ios` 를 시작해요 (태그가 없으면 pubspec 의 1.0.0 을 써요). Start both workflows.
2. 워크플로가 하는 일 / The workflow does: `check-native.py`(Info.plist·권한·개인정보 매니페스트 검사) → `xcode-project use-profiles`(API 키로 인증서·프로필 자동 생성, 앱별 `ios/Runner.xcodeproj` 만) → `flutter build ipa`(난독화, 빌드 번호는 `scripts/ci/build-number.py`) → `check-native.py --ipa`(서명된 ipa 검사) → TestFlight 업로드.
3. 빌드 번호는 시간(분) 기준 증가 값이라 같은 번호가 두 번 나오지 않아요. 직접 올리지 마세요. Build numbers rise by the minute; never set one by hand.
4. 업로드 후 Apple 처리에 10~30분. TestFlight 내부 테스터로 먼저 실기기 확인: 로그인(전화, 카카오, 네이버, 구글, Apple), 사진 고르기, 결제창(PortOne, 카드 앱 호출), 푸시, 위치.
5. 심사 제출은 **사람이 해요** (워크플로는 심사에 자동 제출하지 않아요): App Store Connect → 버전에 빌드 추가 → `review-notes.md` 내용을 심사 메모에 붙여 넣기 → 개인정보 라벨은 `app-privacy.md` 대로 입력 → 제출. Submission is manual by design.

## 3. 앱 안에서 이미 해 둔 것 / Already in the app

- 최소 iOS 15.0 (Firebase, 구글 로그인, image_picker 가 15 이상 필요). 아이폰 전용.
- Apple 로 로그인 (지침 4.8), 앱 안 계정 삭제 (5.1.1(v)), 후기 신고 (1.2), 개인정보 매니페스트 `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption = false`.
- 권한 문구는 한국어·영어 2개 언어 (나머지 12개는 `archive/i18n-extra-languages`에 보관). 위치는 "사용 중에만"이고 고객 앱만 (geolocator 는 `BYPASS_PERMISSION_LOCATION_ALWAYS=1` 로 빌드해 항상 허용 요청을 뺐어요). 카메라 문구는 image_picker 가 카메라 API 를 링크하므로 남겨 둔 것이에요 (`review-notes.md` §5).
- 결제는 PortOne 웹 화면이고 인앱 결제(IAP)가 아니에요: 방문 청소는 앱 밖에서 쓰는 실물 서비스 (지침 3.1.3(e)).
- 키는 저장소에 없어요. `scripts/ci/native-keys.sh` 가 빌드 때 `keys.json`, `Keys.xcconfig`, `GoogleService-Info.plist` 를 만들고 모두 `.gitignore` 예요.

## 4. 확인 명령 / Checks

```
curl -s https://<도메인>/.well-known/apple-app-site-association     # applinks 와 webcredentials 둘 다 보여야 해요
python -I scripts/ci/check-native.py                                # 저장소 검사 (CI 가 매번 실행)
python -I scripts/ci/check-native.py --ipa <Runner.ipa>             # 빌드된 ipa 검사 (Codemagic 이 실행)
```

AASA 는 기기가 Apple CDN 을 거쳐 받아서 바꾼 뒤 반영까지 시간이 걸려요. 테스트 중에는 entitlement 값 끝에 `?mode=developer` 를 붙이고 기기 설정 > 개발자 > Associated Domains Development 를 켜는 방법이 있어요 (출시 빌드에는 붙이지 마세요). AASA changes reach devices through Apple's CDN with a delay.

## 5. 이 환경에서 확인하지 못한 것 / Not verifiable without a real build

Windows 에서는 Xcode 가 없어서 아래는 첫 Codemagic 빌드와 TestFlight 에서만 알 수 있어요. None of this can be tested without Xcode.

- SwiftPM 플러그인 해석 (Firebase 등을 GitHub 에서 받아요), 서명, 용량.
- iOS 에서 카드 앱(ISP, KB, 토스 등) 호출과 복귀: 호스팅 결제 페이지(`website/pay/index.html`)는 `redirectUrl` 만 써요. PortOne/PG 가 iOS 에서 앱 복귀용 `appScheme` 을 요구하면 앱 URL 스킴 추가와 페이지 수정이 필요해요. TestFlight 에서 카드 결제를 꼭 한 번 해 보세요.
- 네이버 로그인 (iOS 17.4+ https 콜백): AASA + `webcredentials` 가 Apple 쪽에서 확인되어야 해요. 17.4 미만은 `malkkeumnaver://` 스킴을 써요.
- `GoogleService-Info.plist` 없이 빌드하면 푸시는 꺼져요. 푸시를 쓰려면 7번을 먼저 하세요.
