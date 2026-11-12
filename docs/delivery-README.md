# 다해 설치 안내

이 저장소에는 **설치 프로그램과 안내서만** 있어요. 코드를 고치거나 빌드할 일은 없어요.

## 순서 (처음 한 번)
| 단계 | 안내서 | 누가 | 시간 |
|---|---|---|---|
| 1 | [한 번에 설치하기](guide/00-한번에-설치.md) (자세히: [서버 설치](guide/01-서버-설치.md)) | 사장님 또는 설치 담당 | 약 30분 |
| 2 | [설정 마법사](guide/02-설정-마법사.md) | 설치 담당 + 사장님 | 1~2시간 (가입 승인 대기 별도) |
| 3 | [앱 출시](guide/03-앱-출시.md) | 설치 담당 → 개발자 | 계정 승인 1~7일 |
| 4 | [사장님 가이드](guide/04-사장님-가이드.md) | 사장님 | 매일 5분 |

## 설치 명령
서버 SSH 화면에 붙여넣기 (이 브랜치의 채널 설치 명령 — 안정 버전은 `main`, 베타는 `beta` 브랜치):
```
curl -fsSL INSTALL_URL | sudo bash
```
베타 버전을 먼저 써 보려면 `https://raw.githubusercontent.com/EricWijesinghe/malkkeum-install/beta/install.sh` 를 쓰세요.
(설치 후에도 `sudo dahae channel beta` 로 바꿀 수 있어요.)

## 릴리스 확인
`CHANNEL` 파일은 이 브랜치의 채널, `VERSION` 파일은 배포된 버전이에요.

## 스토어 등록 자료
- 앱 이름·설명: [store/listing-ko.md](store/listing-ko.md)
- Google Play 데이터 보안 답변: [store/data-safety.md](store/data-safety.md)

## 업데이트
서버는 매주 월요일 새벽 자동으로 업데이트돼요 (실패하면 이전 버전으로 자동 복구). 바로 하려면 서버에서 `sudo dahae update`.
백업, 되돌리기, 제거 같은 관리 명령은 [운영 명령어](guide/07-운영-명령어.md)에 있어요. 안내서 전체 목록: [guide/README.md](guide/README.md)
앱 업데이트는 개발자가 스토어에 올려요.
