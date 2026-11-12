# VPS 설치 한 페이지 · Deploy on a VPS (one page)

## 한국어

**준비물**
- Ubuntu 24.04 / 22.04 또는 Debian 12 서버 (메모리 4GB 이상, 공인 IP 1개)
- 도메인 (예: `malkkeum.example.kr`) 과 DNS **A 레코드**를 서버 IP 로 지정
- 방화벽에서 **80, 443** 포트 열기 (HTTPS 인증서 발급에 필요)
- 이 폴더의 `install.sh` 와 `malkkeum-demo.tar` (이미지 묶음) 를 서버로 복사

**설치 (서버에서 실행)**
```
sudo MALKKEUM_IMAGES_TAR=/root/malkkeum-demo.tar \
     MALKKEUM_VERSION=demo \
     MALKKEUM_DOMAIN=malkkeum.example.kr \
     MALKKEUM_EMAIL=you@example.kr \
     bash /root/install.sh
```
- 설치 중 Docker 와 기본 패키지를 받으므로 이 순간에는 인터넷이 필요해요.
- 끝나면 화면에 나오는 **설치 코드** 를 적어 두세요. `https://<도메인>/admin/` 을 열고 코드를 입력한 뒤 사장님 계정을 만들면 설정 마법사가 시작돼요.
- 로컬 주소 (`malkkeum.localhost`) 로 시험할 때만 `MALKKEUM_TLS=internal` 을 추가하세요. 실제 도메인에는 넣지 않아요 (자동 HTTPS 를 씁니다).

**확인과 관리**
- 상태: `malkkeum status` / 로그: `malkkeum logs` / 업데이트: `malkkeum load <파일.tar>` 후 `malkkeum update <태그>`
- 매일 백업이 자동으로 돌아요. 복구 방법은 `docs/DEPLOY.md` (6-Docs 폴더) 를 보세요.
- 체험용 이미지 (`demo`) 는 시연용이에요. 정식 운영은 릴리스된 이미지 (`MALKKEUM_CHANNEL=stable`) 로 설치하세요.

**문제가 생기면**: 설치 로그를 보내 주세요. 설치 코드와 개인정보는 로그에 적지 않아요.

## English

**You need**
- An Ubuntu 24.04 / 22.04 or Debian 12 server (4 GB RAM or more, one public IPv4)
- A domain (for example `malkkeum.example.kr`) whose DNS **A record** points at the server IP
- Ports **80 and 443** open in the firewall (needed for the HTTPS certificate)
- Copy `install.sh` and `malkkeum-demo.tar` from this folder to the server

**Install (run on the server)**
```
sudo MALKKEUM_IMAGES_TAR=/root/malkkeum-demo.tar \
     MALKKEUM_VERSION=demo \
     MALKKEUM_DOMAIN=malkkeum.example.kr \
     MALKKEUM_EMAIL=you@example.kr \
     bash /root/install.sh
```
- Docker and base packages are downloaded during install, so the internet is needed at that step only.
- Write down the **setup code** printed at the end. Open `https://<domain>/admin/`, enter the code, create the owner account; the setup wizard starts.
- Add `MALKKEUM_TLS=internal` only for a local test domain (`*.localhost`). Never for a real domain.

**Operate**
- Status: `malkkeum status`; logs: `malkkeum logs`; update: `malkkeum load <file.tar>` then `malkkeum update <tag>`.
- Daily backups run automatically. Restore steps: `docs/DEPLOY.md` (folder 6-Docs).
- The `demo` images are for trials. For real operation install the released images (`MALKKEUM_CHANNEL=stable`).

**Problems:** send the install log. The setup code and personal data are never written to it.
