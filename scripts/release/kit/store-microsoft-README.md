# 4-Store-Microsoft · Windows MSIX 패키지 / Windows MSIX packages

| 폴더 / Folder | 내용 / Contents | 용도 / Use |
|---|---|---|
| `test-signed/` | `malkkeum-customer.msix`, `malkkeum-partner.msix` (테스트 서명) | 이 PC 나 시연 PC 에 설치 / Install on a PC for testing |
| `store/` | 같은 2개 패키지, 서명 없음 | Partner Center 에 제출 (제출 때 Microsoft 가 서명) / Upload to Partner Center (Microsoft signs on submission) |
| `malkkeum-test-signing.cer` | 테스트 인증서 (공개 키만) / Test certificate, public part only | 테스트 서명 패키지를 신뢰하기 위해 설치 / Trust the test-signed packages |

**로컬 설치 (테스트 서명)**
1. 현재 사용자 저장소에 인증서 설치 (관리자 권한 불필요): `Import-Certificate -FilePath malkkeum-test-signing.cer -CertStoreLocation Cert:\CurrentUser\TrustedPeople`
2. `Add-AppxPackage -Path test-signed\malkkeum-customer.msix`
Test-signed packages install only after the certificate is trusted.

**Partner Center 제출 전 필수 값 / Required before store submission**

환경 변수 또는 `scripts/store/msix.local.psd1` (저장소에 올리지 않음) 로 지정하세요. 이 패키지에는 지정되지 않은 **플레이스홀더** 값이 들어 있어요.
Set these (env vars, or the gitignored `scripts/store/msix.local.psd1`). This package carries placeholders.

| 변수 / Variable | 값 / Value from Partner Center |
|---|---|
| `MSIX_PUBLISHER` | Product identity 의 Publisher (예: `CN=XXXXXXXX-XXXX-...`) |
| `MSIX_PUBLISHER_DISPLAY_NAME` | 게시자 표시 이름 / Publisher display name |
| `MSIX_IDENTITY_CUSTOMER` | 고객 앱 Package/Identity/Name |
| `MSIX_IDENTITY_PARTNER` | 파트너 앱 Package/Identity/Name |

값을 넣은 뒤 `build-all.ps1` 을 다시 실행하면 store/ 가 새 값으로 만들어져요. 자세한 절차는 `microsoft-store.md` 를 보세요.
Re-run `build-all.ps1` after setting the values; `microsoft-store.md` has the full steps.
