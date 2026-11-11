# 5-Store-Apple · iOS 빌드 안내 / iOS build guide

**이 폴더에는 .ipa 가 없어요.** iOS 앱은 Windows 에서 빌드할 수 없어요 (Xcode 와 macOS 가 필요). 그래서 클라우드 Mac 인 **Codemagic** 에서 빌드합니다. 저장소의 `codemagic.yaml` 이 설정 파일이에요.
**There is no .ipa in this folder.** iOS cannot be built on Windows (it needs Xcode on macOS). Builds run on Codemagic's cloud Mac from `codemagic.yaml` in the repository.

## 1. 최초 1회 설정 / One-time setup (Codemagic web UI)
1. Teams > Integrations > App Store Connect: API key 를 추가하고 이름을 `malkkeum_asc` 로 지정.
2. Environment variables > 그룹 `malkkeum`: `API_BASE` (https://서버 도메인, 필수), 로그인·푸시 키 (선택). 목록은 `docs/DEPLOY.md` §3.
3. Apple Developer 에서 번들 ID `com.malkkeum.customer` 와 `com.malkkeum.partner` 를 등록.

## 2. 빌드 실행 / Run the builds
- `customer-ios`: 고객 앱, TestFlight 자동 제출.
- `partner-ios`: 파트너 앱, TestFlight 자동 제출.
- 각 워크플로는 `Strings and packages` 단계에서 `check-native.py` 를 먼저 실행해 설정 오류를 막아요.

## 3. App Store Connect 체크리스트 / Checklist
- [ ] 앱 등록 (이름, 기본 언어, SKU, 번들 ID) / App record created
- [ ] 개인정보 라벨: `../3-Store-Android/data-safety.md` 의 App Store 항목, `docs/store/app-privacy.md` 답안 / App Privacy answers
- [ ] 심사 메모: `review-notes.md` (로그인, 계정 삭제, 결제 안내) / Review notes pasted
- [ ] 스크린샷 (6.7", 6.5" 등 요구 크기) / Screenshots at required sizes
- [ ] 연령 등급: `content-rating-draft.md` 답안 기준 / Age rating from the draft
- [ ] 계정 삭제 경로 (앱 내) 가 심사 메모와 같은지 확인 / In-app account deletion matches the notes
- [ ] 수출 규정 (암호화 사용 여부) 답변 / Export compliance answered

## 4. 제출 파일 / Submission files
- Codemagic 이 만든 `.ipa` 는 TestFlight 에 자동 업로드돼요. App Store 제출은 App Store Connect 에서 빌드를 골라 진행하세요.
- 이 패키지에 .ipa 를 넣지 않았어요. 빌드가 한 번 성공한 뒤 Codemagic 아티팩트에서 받으세요.

Files: the .ipa is uploaded to TestFlight by Codemagic. Pick the build in App Store Connect for review.

## 5. 아직 확인 안 된 것 / Not verified here
- 이 PC 에서는 iOS 빌드와 서명을 실행하지 않았어요. Codemagic 의 첫 빌드 결과로 확인해야 해요.
- Not built or signed on this PC; the first Codemagic build is the real test.
