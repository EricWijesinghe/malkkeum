# 말끔 릴리스 패키지 · Malkkeum release package

이 폴더는 말끔(한국 가정 청소 플랫폼)의 **인계용 전체 패키지**입니다. 빌드 날짜와 커밋은 아래 "버전 정보" 를 보세요.
This folder is the **complete hand-over package** for Malkkeum (Korean home-cleaning platform). Build date and commit are listed under "Build info".

## 폴더 구성 · Folder layout

| 폴더 / Folder | 내용 / Contents |
|---|---|
| **1-Demo** | 체험판: 서버(api.exe), 관리자 콘솔(웹), 안드로이드 앱 APK, 실행 파일 "Malkkeum Demo.cmd". 한 번 더블클릭으로 시연. / Trial kit: server, owner console (web), Android APKs, "Malkkeum Demo.cmd". |
| **2-Install-Server** | 실서버 설치 (Ubuntu/Debian VPS): install.sh, 이미지 묶음(.tar), 설치 가이드 01-05, VPS 설치 한 페이지. / Production server install: installer, offline image bundle, guides 01-05, one-page VPS guide. |
| **3-Store-Android** | 구글 플레이용 AAB 와 범용 APK (고객·파트너), 업로드 키 (signing/), 스토어 문안·데이터 안전성·심사 메모. / Google Play AAB + universal APK (customer, partner), upload key, store texts. |
| **4-Store-Microsoft** | Windows MSIX (고객·파트너; 콘솔은 웹 전용): 로컬 설치용 테스트 서명과 Partner Center 제출용 미서명 패키지, 스토어 안내. / Windows MSIX packages (customer, partner; the console is web-only): test-signed and Partner Center store-mode. |
| **5-Store-Apple** | iOS 빌드 안내 (Windows 에서는 .ipa 를 만들 수 없어요: Codemagic 사용), App Store Connect 체크리스트, 앱 개인정보 답변. / iOS: Codemagic steps (no .ipa can be built on Windows), App Store Connect checklist. |
| **7-Console-Android** | 사장님 폰에 직접 설치하는 관리자 앱 APK (Dahae-Console.apk) 와 설치 안내. 스토어에는 올리지 않아요. / Owner console APK to sideload on your own Android phone (not on any store). |
| **6-Docs** | 사장님 가이드, 재무·세무 안내, 개인정보 보관 정책, 배포 runbook (DEPLOY.md). / Owner guide, finance and tax, privacy and retention, deploy runbook. |

## 처음 보는 분을 위한 순서 · Where to start

1. 시연만 하려면: `1-Demo\Malkkeum Demo.cmd` / Demo only: `1-Demo\Malkkeum Demo.cmd`.
2. 서버를 세우려면: `2-Install-Server/VPS-deploy-guide.html` (한 페이지 / one page).
3. 스토어 제출: 3, 4, 5 폴더의 README 를 순서대로 / Store submission: READMEs in folders 3, 4, 5.

## 주의 · Caveats

- 서명 키 (3-Store-Android/signing) 와 PASSWORD.txt 는 **절대 공유하거나 버전 관리에 올리지 마세요**. 잃어버리면 Play 지원팀으로 업로드 키를 재설정해야 해요.
  Keep signing/ and PASSWORD.txt private. If lost, Play support must reset the upload key.
- 체험판 빌드의 앱 주소는 이 PC 의 Wi-Fi 주소입니다 (1-Demo/api-address.txt). 주소가 바뀌면 다시 빌드해야 해요.
  Demo apps point to this PC's Wi-Fi address (1-Demo/api-address.txt); rebuild if it changes.
- 스토어 빌드의 서버 주소 (MALKKEUM_API_BASE) 없이 `-AllowPlaceholder` 로 빌드했다면 AAB/APK/MSIX 는 **플레이스홀더** 주소로 만들어졌어요. 제출 전에 다시 빌드하세요.
  If built with `-AllowPlaceholder` instead of MALKKEUM_API_BASE, store binaries (AAB/APK/MSIX) carry a placeholder server address; rebuild before upload.

## 버전 정보 · Build info

BUILD_INFO_PLACEHOLDER
