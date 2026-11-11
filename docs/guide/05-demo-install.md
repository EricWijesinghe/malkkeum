# 5. 체험용 설치 (이미지 파일로, GitHub 없이)

GitHub 에서 이미지를 내려받지 않고, 미리 만들어 둔 **이미지 파일(.tar) 하나**로 말끔 서버를 설치해요.
친구 집이나 발표 장소처럼 인터넷이 불안한 곳에서 시연할 때 써요. 설치가 끝나면 서비스는 인터넷 없이도 돌아요.

> English summary: build the two images on your own PC, `docker save` them into one `.tar`,
> copy it (with `install.sh`) to an Ubuntu machine, and run
> `sudo MALKKEUM_IMAGES_TAR=/path/malkkeum-demo.tar MALKKEUM_DOMAIN=malkkeum.localhost MALKKEUM_TLS=internal bash install.sh`.
> Later updates use `malkkeum load <tar>` then `malkkeum update <tag>`. Details below.

## 준비물
| 준비물 | 어디서 |
|---|---|
| 이미지 파일 `malkkeum-demo.tar` (아래 A 에서 만들어요) | 개발 PC |
| Ubuntu 24.04 또는 Debian 12 (메모리 4GB 이상) | 노트북의 VM, 체험용 미니 PC, 또는 클라우드 서버 |
| `install.sh` (저장소의 `deploy/install.sh`) | 같이 USB 에 복사 |

> 설치 과정에서 Docker 와 기본 패키지(apt)를 받으니, **설치하는 순간에는 인터넷이 필요해요.**
> 설치가 끝난 뒤에는 인터넷 없이 돌아가요. 이미지가 전부 그 서버 안에 있으니까요.

## A. 개발 PC 에서 이미지 파일 만들기 (집에서 미리)

Docker Desktop 이 켜져 있어야 해요. 저장소 최상위 폴더(`F:\EC`)에서 실행하세요.

```
docker build -f backend/Dockerfile --build-arg APP_VERSION=demo -t ghcr.io/ericwijesinghe/malkkeum-api:demo backend
docker build -f deploy/web.Dockerfile --build-arg APP_VERSION=demo -t ghcr.io/ericwijesinghe/malkkeum-web:demo .
docker pull postgres:17
docker save -o malkkeum-demo.tar ghcr.io/ericwijesinghe/malkkeum-api:demo ghcr.io/ericwijesinghe/malkkeum-web:demo postgres:17
```

- 처음 빌드는 40분 이상 걸릴 수 있어요. 메모리가 부족하면 `--build-arg CARGO_BUILD_JOBS=2` 를 API 빌드 줄에 붙이세요 (동시 컴파일 수를 줄여요).
- `postgres:17` 은 데이터베이스 이미지예요. 빼면 설치할 때 인터넷에서 받아요.
- 만든 `malkkeum-demo.tar` 와 `deploy/install.sh` 를 USB 에 복사하세요. 파일 이름의 `demo` 는 버전 이름이에요. 나중에 업데이트할 때 다른 이름(예: `demo2`)으로 한 번 더 만들면 돼요.

## B. 설치 (체험 서버에서)

1. Ubuntu 에 로그인하고 USB 를 꽂아 두세요. 예: `/media/usb` 에 있다고 할게요.
2. 아래 명령을 실행해요. 도메인은 `malkkeum.localhost` 처럼 **로컬 주소**를 써요 (인터넷 도메인이 없어도 돼요).
   ```
   sudo MALKKEUM_IMAGES_TAR=/media/usb/malkkeum-demo.tar \
        MALKKEUM_VERSION=demo \
        MALKKEUM_DOMAIN=malkkeum.localhost \
        MALKKEUM_EMAIL=demo@example.com \
        MALKKEUM_TLS=internal \
        bash /media/usb/install.sh
   ```
   - `MALKKEUM_TLS=internal` 은 인증서를 이 서버 안에서 만들어요. 그래서 브라우저에서 "안전하지 않음" 경고가 한 번 나와요. **고급 → 계속** 을 누르면 돼요.
   - 인터넷에 나갈 수 없는 상태라면 apt 단계에서 멈춰요. 그때는 인터넷 되는 곳에서 설치하세요.
3. 끝나면 이런 화면이 나와요. **설치 코드**(12자리)를 꼭 적어 두세요.
   ```
   ✔ 설치가 끝났어요!
   1) 브라우저에서 이 주소를 여세요:   https://malkkeum.localhost/admin/
   2) 설치 코드:  ABCD-2345-EFGH
   ```
4. 같은 컴퓨터의 브라우저에서 `https://malkkeum.localhost/admin/` 을 열어요.
   설치 코드를 입력하고 사장님 계정을 만들면 설정 마법사가 시작돼요.
   다른 기기(예: 발표용 태블릿)에서 보려면 서버의 IP 를 `MALKKEUM_DOMAIN` 에 넣고 설치하세요. 이 경우 같은 Wi-Fi 에서만 열려요.

## C. 체험 데이터 넣기 · 지우기

```
sudo malkkeum demo load      # 예약·손님·파트너 샘플을 넣어요 (실제 데이터가 있으면 넣지 않아요)
sudo malkkeum demo clear     # 샘플만 지워요. 실제 고객·예약·정산은 건드리지 않아요. "yes" 를 입력해야 해요.
```

## D. 업데이트 · 되돌리기 (인터넷 없이)

새 버전 파일을 만들어 USB 로 옮긴 뒤 (A 와 같은 방법, 태그만 `demo2` 로):

```
sudo malkkeum load /media/usb/malkkeum-demo2.tar     # 파일을 불러와요. 화면에 Loaded image 태그가 나와요
sudo malkkeum update demo2                            # 백업 → demo2 로 바꾸기 → 응답 확인
```

- 새 버전이 응답하지 않으면 자동으로 이전 버전으로 되돌려요.
- 직접 되돌리려면 `sudo malkkeum rollback` 을 써요 (바로 전 버전으로 돌아가요).
- 자주 쓰는 명령: `malkkeum status`, `malkkeum version`, `malkkeum logs`, `malkkeum backup`.

## E. 체험이 끝나면

```
sudo malkkeum demo clear     # 샘플 데이터 지우기
```

서버를 통째로 버리려면 VM 을 지우면 끝이에요. 이 설치가 만든 것은 `/opt/malkkeum` 폴더, `malkkeum` 명령, `/etc/cron.d/malkkeum` 이에요.

## 자주 막히는 곳
| 증상 | 해결 |
|---|---|
| `이미지 파일을 찾을 수 없어요` | USB 경로가 맞는지 확인 (`ls /media/usb`). |
| `이미지 파일에 ... 이 없어요` | 파일 안의 태그가 `MALKKEUM_VERSION` 과 다른 경우예요. 만들 때 쓴 태그(`demo`)를 `MALKKEUM_VERSION=demo` 로 같이 넣으세요. 안 넣으면 기본값 `local` 을 찾아요. |
| 브라우저 경고 | `MALKKEUM_TLS=internal` 이라서 정상이에요. 고급 → 계속. |
| 응답이 없어요 | `sudo malkkeum logs` 로 원인을 확인하세요. `docker` 가 실행 중인지 `systemctl status docker` 도 확인. |

---

## 개발자 메모 (설치 테스트)

- `deploy/install.sh` 의 `MALKKEUM_IMAGES_TAR` 가 설치 때 `docker load` 를 하고, 기본 경로(GHCR 에서 내려받기)는 그대로예요.
- `.env` 의 `IMAGE_SOURCE=local` 이면 `malkkeum update` 가 저장소에서 내려받지 않아요. 한 번 로컬로 설치하면 계속 로컬 모드예요.
- 이미지 이름은 `ghcr.io/ericwijesinghe/malkkeum-api:<태그>` 형식이어야 해요 (installer 와 `malkkeum` 명령이 이 이름으로 찾아요). 저장소 주소를 바꿨다면 `MALKKEUM_IMAGES` 도 같이 지정하세요.
