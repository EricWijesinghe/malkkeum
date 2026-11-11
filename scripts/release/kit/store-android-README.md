# 3-Store-Android · 구글 플레이 제출 파일 / Google Play submission

| 파일 / File | 용도 / Use |
|---|---|
| `customer-release.aab` | 고객 앱 번들, 플레이 콘솔 업로드용 / Customer app bundle for Play Console |
| `partner-release.aab` | 파트너 앱 번들 / Partner app bundle |
| `customer-universal.apk` | 고객 범용 APK (직접 설치 테스트용, 플레이에는 올리지 않아요) / Universal APK, direct install and testing only |
| `partner-universal.apk` | 파트너 범용 APK / Partner universal APK |
| `signing/` | 업로드 키 (비공개) / Upload key (private) |
| `listing-*.md` | 스토어 설명 문안 (ko, en, ja, vi, zh) / Store listing copy |
| `data-safety.md` | 데이터 보안 답안 / Data safety answers |
| `content-rating-draft.md` | 콘텐츠 등급 답안 초안 / Content rating draft |
| `review-notes.md` | 심사팀 메모 (로그인, 계정 삭제, 권한) / Reviewer notes |
| `screenshots/` | 스크린샷 (생성된 경우) / Screenshots, when generated |

**제출 전 필수 / Before upload**
- 서버 주소를 `MALKKEUM_API_BASE=https://<도메인>` 로 지정해 다시 빌드하세요. 지정하지 않으면 AAB/APK 에 플레이스홀더 주소 (`api.example.invalid`) 가 들어가요.
  Rebuild with `MALKKEUM_API_BASE=https://<domain>`; otherwise the binaries carry the placeholder address.
- 버전 코드는 업로드마다 올라가야 해요 (`pubspec.yaml` 의 `+N`). Play 는 같은 번호를 거부해요.
- 구글·카카오·네이버 로그인과 푸시 키는 CI (Codemagic) 에서만 주입돼요. 이 로컬 빌드에는 없어서 해당 로그인 버튼은 숨겨져요.
  Social-login and push keys are injected only by CI (Codemagic); those buttons are hidden in this local build.
