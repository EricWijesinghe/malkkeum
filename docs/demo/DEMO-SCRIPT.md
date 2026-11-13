# 말끔 10분 시연 대본 / Malkkeum 10-minute demo script

Korean first, English second. 한국어가 먼저, 영어는 아래에 있어요.

---

## 한국어

### 0. 꼭 먼저 읽어 주세요 (시연 전 확인)

바탕화면 키트(`Malkkeum Demo`)의 앱·서버 파일은 **11월 11일 오후에 만든 빌드**예요. 그 뒤에 코드에 들어간 기능
(파트너 체크인, 지도 앱 연결, 사진 오프라인 저장, 안전 사건 관리, 세무 탭, 취소 수수료 정책, 집 정보, 직원 2단계 인증)은
**키트에 없어요.** 이 대본은 키트에 실제로 들어 있는 화면만 써요. 새 기능을 보여 주려면 키트를 다시 빌드해야 해요.

**시연 중 누르지 말 것**
| 화면 | 이유 |
|---|---|
| 결제 단계에서 카카오페이·네이버페이·토스페이 등 **새 결제수단으로 결제** | 키트 앱은 서버 주소가 `172.25.243.168` 로 빌드돼서 데모 결제창 대신 실제 PortOne 결제 페이지를 열려고 해요. 그 페이지는 데모 서버에 없어요. **저장된 "데모 카드 1234"로만 결제하세요.** 결제수단 목록을 펼쳐서 보여 주는 것까지는 괜찮아요. |
| 더보기 → 청소 포인트 | 화면만 있고 적립 기능은 아직 없어요 (0 P 로 표시) |
| 콘솔 상담함의 AI 상담원 | 데모 서버에는 Claude API 키가 없어서 "AI 상담원이 꺼져 있어요" 로 보여요 |
| 본인인증(PASS), 카카오·네이버 로그인 | 실제 계약 키가 필요해요. 키트에는 버튼이 나오지 않아요 |

**시연 30분 전**
1. 바탕화면 `Malkkeum Demo` 폴더에서 **`Malkkeum Demo.cmd`** 더블클릭.
2. 검은 창에 초록색 **"Demo ready"** 가 나올 때까지 기다려요 (처음이면 몇 분, 에뮬레이터를 처음 만들면 더 걸려요).
   - "Malkkeum Server" 창이 따로 열려요. **시연 끝날 때까지 닫지 마세요.**
3. 브라우저에 콘솔 `http://localhost:8081` 이 열려요. **owner@demo.local / malkkeum-demo-2026** 로 로그인해서 대시보드가 보이는지 확인.
4. 에뮬레이터에 고객 앱 **말끔** 이 열려 있는지 확인. 안 열렸으면 에뮬레이터에서 말끔 아이콘을 누르세요.
5. 화면 배치: 왼쪽에 콘솔(브라우저), 오른쪽에 에뮬레이터. 글씨가 잘 보이게 브라우저 확대(Ctrl + +) 125%.
6. 리허설에서 만든 예약은 데이터베이스에 남아요. 그대로 두어도 시연에 문제없어요.

**로그인 번호 (중요)**
- 고객: **010-0000-0001** (예시 데이터 속 단골 고객이에요. 주소·저장 카드·쿠폰·예약 내역이 이미 있어요.)
  다른 번호로도 로그인은 되지만 새 고객이라 저장 카드가 없어서 결제를 보여 줄 수 없어요.
- 파트너(선택): **010-0001-0001** (김태현 · 말끔케어 강남팀, 승인된 파트너)
- 인증번호: 데모 모드에서는 문자가 가지 않고, 6자리 코드가 **입력칸에 자동으로 채워져요.** [확인]만 누르면 돼요.

### 1. 오프닝 — 0:00 ~ 0:40

| | |
|---|---|
| **클릭** | 콘솔 [대시보드] 화면을 띄운 채로 시작 |
| **말하기** | "말끔은 고객 앱, 청소 파트너 앱, 사장님 관리 화면이 하나로 연결된 홈클리닝 플랫폼입니다. 오늘 10분 동안 고객이 예약하고, 사장님이 처리하고, 돈이 정산되는 과정을 처음부터 끝까지 보여 드리겠습니다." |
| **보여 줄 것** | 오늘 작업 · 견적 대기 · 미배정 · 안 읽은 상담 숫자, 서비스별 예약 (30일), 평균 평점. "지금 숫자는 예시 데이터"라고 먼저 말하세요. |
| **문제가 생기면** | 콘솔이 하얗게 나오면 F5. 로그인 화면이 다시 나오면 다시 로그인. |

### 2. 고객 로그인과 홈 — 0:40 ~ 1:40

| | |
|---|---|
| **클릭** | 에뮬레이터 말끔 앱 → [휴대폰 번호로 시작하기] → `01000000001` 입력 → [인증번호 받기] → 코드가 채워지면 [확인] |
| **말하기** | "가입은 휴대폰 번호 하나면 끝납니다. 실제 서비스에서는 문자로 인증번호가 가고, 카카오·네이버·구글·애플 간편 로그인도 붙어 있습니다." |
| **보여 줄 것** | 홈: 이름 인사, **다가오는 예약** 카드, 서비스 8종 그리드 (원룸·주방·화장실·매트리스·에어컨·소파·이사·입주), 쿠폰 배너, 친구 초대 카드, 아래쪽 신뢰 문구 ("방문 2일 전까지 무료 취소", 부가세 포함 가격). |
| **강조** | "다시 찾아온 고객에게는 다가오는 예약과 쓸 수 있는 쿠폰이 바로 보입니다. 다음 예약이 없으면 지난번 서비스를 '다시 예약하기' 카드로 띄워서 재방문을 유도합니다." |
| **문제가 생기면** | "오류"가 뜨면: "Malkkeum Server" 창이 열려 있는지 확인 → 닫혀 있으면 `Malkkeum Demo.cmd` 를 다시 더블클릭 (서버만 다시 켜져요). 인증번호가 안 채워지면 [인증번호 받기]를 한 번 더. |

### 3. 예약과 결제 — 1:40 ~ 3:40

| | |
|---|---|
| **클릭** | 홈에서 **[에어컨 청소]** → 종류 선택 (예: 벽걸이) → [다음] → 날짜와 도착 시간 선택 → [다음] → 준비 안내 확인 → [결제하러 가기] |
| **말하기** | "가격이 처음부터 정해져 있어서 고객이 전화로 물어볼 필요가 없습니다. 남은 자리 수가 보여서 고객이 미루지 않고 바로 예약하게 됩니다." |
| **보여 줄 것** | 단계 표시 (몇 단계 중 몇 번째), 시간대마다 "N자리 남음", 주소 단계는 저장된 주소가 하나면 자동으로 건너뜀. |
| **결제 화면** | 쿠폰이 자동으로 적용된 할인 금액, 합계, "부가세 포함", "○○까지 무료 취소". 결제수단 목록을 펼쳐 카드·카카오페이·네이버페이·토스페이·페이코·삼성페이·계좌이체·가상계좌가 있다는 것을 **보여만 주고**, **"데모 카드 1234"** 를 고른 뒤 **[○○원 결제하기]**. |
| **말하기** | "실제 서비스에서는 PortOne을 통해 한국 고객이 쓰는 결제수단을 모두 받습니다. 한 번 등록한 카드는 다음부터 한 번 누르면 결제됩니다. 오늘은 데모라 실제 돈은 나가지 않습니다." |
| **보여 줄 것** | "예약이 완료됐어요" 화면 → [예약 보기] → 진행 단계(예약 확정 → 청소팀 배정 → 청소 완료) |
| **문제가 생기면** | 결제 실패 문구가 나오면 뒤로 가서 "데모 카드 1234"가 선택됐는지 확인하고 한 번 더. 그래도 안 되면 하단 [예약] 탭에서 기존 예약을 열어 진행 단계 화면을 보여 주고 다음 단계로 넘어가세요. 시간대가 모두 마감이면 다른 날짜를 고르세요. |

### 4. 사장님이 처리 — 3:40 ~ 4:50 (실시간 연결)

| | |
|---|---|
| **클릭** | 콘솔 [예약] → 맨 위의 방금 만든 예약 클릭 (또는 Ctrl + K 에서 예약번호 입력) → 오른쪽 상세에서 팀 이름 입력 (예: `말끔케어 강남팀`) → **[팀 배정]** |
| **말하기** | "고객이 결제하는 순간 사장님 화면에 예약이 들어옵니다. 배정 버튼을 누르면—" (에뮬레이터를 가리키며) "—고객 앱의 진행 단계가 바로 바뀝니다." |
| **보여 줄 것** | 고객 앱 예약 상세가 새로고침 없이 **"청소팀 배정"**, "말끔케어 강남팀이(가) 방문해요" 로 바뀌는 순간. 콘솔 상세의 결제 내역(금액·상태). |
| **문제가 생기면** | 고객 앱이 바로 안 바뀌면 화면을 아래로 당겨 새로고침. 콘솔 목록에 새 예약이 안 보이면 [예약] 메뉴를 다시 누르세요. |

### 5. 완료와 후기 — 4:50 ~ 5:40 (재방문의 시작)

| | |
|---|---|
| **클릭** | 콘솔 같은 예약에서 **[완료 처리]** → 에뮬레이터: "청소는 어떠셨나요?" 카드 → 별 5개 → 한 줄 후기 → **[후기 남기기]** |
| **말하기** | "청소가 끝나면 고객에게 바로 후기를 요청합니다. 실제 작업에서는 파트너가 전후 사진과 체크리스트를 올려서 고객이 결과를 사진으로 확인합니다. 좋은 후기는 새 고객을 데려오고, 같은 화면의 '같은 조건으로 다시 예약' 버튼이 재방문을 만듭니다." |
| **보여 줄 것** | 완료 단계, 후기 저장 알림, 예약 상세의 "같은 조건으로 다시 예약" 버튼. |
| **문제가 생기면** | 후기 카드가 안 보이면 예약 상세를 아래로 당겨 새로고침. 그래도 없으면 건너뛰고 6번으로. |

### 6. 견적 데스크 (이사·입주 청소) — 5:40 ~ 6:30

| | |
|---|---|
| **클릭** | 콘솔 **[견적 데스크]** → 예시 요청 하나 선택 |
| **말하기** | "이사·입주 청소처럼 금액이 큰 일은 고객이 집 정보를 입력하면 파트너 여러 팀이 견적을 냅니다. 사장님은 견적을 비교해 최종 금액을 보내고, 고객이 예약금 10%를 내면 그 팀에 자동 배정됩니다." |
| **보여 줄 것** | 고객 답변(평형·방 구조 등), 자동 추정 금액, 파트너별 견적과 메모, [견적 보내기] 버튼 (누르지 않아도 돼요). |
| **문제가 생기면** | 목록이 비어 있으면 [예약] 화면 상단 상태 필터로 견적 상태를 고르거나, 말로만 설명하고 넘어가세요. |

### 7. 파트너 품질과 정산 — 6:30 ~ 7:30

| | |
|---|---|
| **클릭** | 콘솔 **[파트너]** → 파트너 한 명 (평점·완료 건수·수수료율) → **[정산]** → 지급 예정 목록과 [지급 내역] 탭 |
| **말하기** | "새 파트너는 가입해도 사장님이 승인해야 일감을 받습니다. 문제가 생기면 바로 중지할 수 있습니다. 파트너별 수수료율이 정해져 있어서 매 건마다 플랫폼 수익이 자동으로 계산되고, 정산은 매주 수요일 목록으로 한 번에 처리합니다." |
| **보여 줄 것** | 승인/중지 버튼, 수수료율 (예시 데이터는 20%), 정산 총액·수수료·지급액, 계좌번호는 가려져 있고 [계좌 보기]를 눌러야 보이며 기록이 남는다는 점. |
| **문제가 생기면** | [정산 지급 실행]은 누르지 않아도 돼요. 화면이 느리면 다음 단계로. |

### 8. 재무와 세무 자료 — 7:30 ~ 8:20

| | |
|---|---|
| **클릭** | 콘솔 **[재무]** → 기간 [월] → 추이 차트 → 아래 [회계 자료 내려받기] |
| **말하기** | "매출, 환불, 플랫폼 수수료, 파트너 지급액, 결제수단별 비율, 부가세 추정까지 한 화면에 나옵니다. 세무사님께는 월별 요약 CSV를 그대로 보내시면 됩니다." |
| **보여 줄 것** | 순매출 · 플랫폼 수수료 · 부가세 추정, 서비스별/파트너별 표, CSV 3종 (결제 원장, 월별 요약(세무사용), 정산 내역). |
| **정직하게** | "현금영수증·세금계산서·원천징수 3.3% 기능은 최신 버전에 들어가 있고, 실제 결제사 테스트와 세무사 확인을 거쳐 켭니다." |
| **문제가 생기면** | 다운로드가 막히면 "브라우저 다운로드 허용" 후 다시. 안 되면 화면 숫자만 보여 주세요. |

### 9. 마케팅으로 고객 붙잡기 — 8:20 ~ 9:15

| | |
|---|---|
| **클릭** | 콘솔 **[쿠폰 · 콘텐츠]** → 쿠폰 발급 (전체 고객에게) 화면 보여 주기 → **[성장]** 탭: 첫 예약 할인, 친구 추천 보상, 후기 관리 |
| **말하기** | "비수기에는 전체 고객에게 쿠폰을 한 번에 보내고, 첫 예약 할인과 친구 추천 보상으로 신규 고객을 데려옵니다. 방금 받은 후기도 여기서 관리합니다." |
| **추가 (여유 있으면)** | 에뮬레이터 [더보기] → [언어] → English → 앱 전체가 영어로 바뀜 → 다시 한국어. "영어도 지원해서 외국인 고객도 받을 수 있습니다." |
| **문제가 생기면** | 쿠폰 발급 버튼은 누르지 않아도 돼요 (실제로 예시 고객 전체에게 발급돼요). |

### 10. 운영 준비와 마무리 — 9:15 ~ 10:00

| | |
|---|---|
| **클릭** | 콘솔 **[설정]** (서비스 시작 준비, 완료 개수) → **[시스템 상태]** (초록·노랑·빨강) |
| **말하기** | "실제 오픈 때는 이 설정 화면에서 사업자 정보, PortOne 결제, 문자, 간편 로그인 키를 차례로 넣고 [연결 테스트]로 확인합니다. 서버 상태와 백업은 이 화면에서 색으로 보이고, 문제가 생기면 사장님 휴대폰으로 문자가 갑니다. 업데이트는 명령 한 줄이고, 실패하면 자동으로 이전 버전으로 돌아갑니다." |
| **마무리 한 마디** | "고객은 1분 만에 예약하고, 사장님은 한 화면에서 예약·파트너·정산·세무 자료를 관리합니다. 다음 단계는 PortOne 계약과 스토어 등록입니다." |
| **문제가 생기면** | [시스템 상태]에 데모라 노랑/빨강(백업 없음 등)이 보일 수 있어요. "데모 PC라 백업을 꺼 두었습니다"라고 설명하세요. |

### (선택) 파트너 앱 — 시간이 남을 때 1분

에뮬레이터 홈 → 앱 목록 → **말끔 파트너** → `01000010001` 로 로그인 → [일감] 탭.
"파트너는 자기 동네와 가능한 시간에 맞는 일만 받습니다. 수락하기 전에는 고객 개인정보가 가려지고, 받을 금액과 수수료가 먼저 보입니다."
[수입]에서 주간·월간 수입과 다음 지급일. 일감이 비어 있으면 "오늘 이 지역 일감은 다 배정됐네요" 라고 하고 넘어가세요.

### 크게 꼬였을 때 (순서대로)

1. **앱이 "오류"만 보여요** → 작업 표시줄에서 "Malkkeum Server" 창 확인. 빨간 글씨가 있거나 창이 없으면 그 창을 닫고 `Malkkeum Demo.cmd` 를 다시 더블클릭. "Demo ready" 까지 기다린 뒤 앱에서 아래로 당겨 새로고침.
2. **"Another emulator is running"** → 다른 에뮬레이터 창을 닫고 다시 실행.
3. **"The emulator cannot reach…"** → Windows 방화벽 창에서 api.exe 를 "개인 네트워크" 허용 → 다시 실행.
4. **앱이 앞으로 안 나와요** → 에뮬레이터에서 말끔 아이콘을 직접 누르세요.
5. **폴더 파일이 망가진 것 같아요** → 바탕화면 **`Malkkeum Demo (backup - works)`** 폴더의 `Malkkeum Demo.cmd` 를 실행. 먼저 기존 "Malkkeum Server" 창을 닫으세요. 백업 폴더도 같은 데이터베이스를 쓰기 때문에, 데이터 문제는 백업으로 해결되지 않아요.
6. **그래도 안 되면** → 콘솔만으로 계속하세요. 대시보드 → 예약(기존 예시 예약) → 견적 데스크 → 파트너 → 정산 → 재무 순서로 보여 주고, 고객 앱은 `docs/store/screenshots/customer/android/ko/` 의 스토어 화면 사진(홈·서비스·일정·결제·진행·채팅)으로 설명하세요.

---

## English

### 0. Read first (before the demo)

The desktop kit (`Malkkeum Demo`) holds the **build from the afternoon of 11 November**. Features merged after that
(partner check-in, map hand-off, offline photo queue, safety cases, the tax tab, cancellation-fee policy, household profile,
staff two-factor sign-in) are **not in the kit**. This script only uses screens the kit really has. Rebuild the kit to show the newer features.

**Do not tap during the demo**
| Screen | Why |
|---|---|
| Paying with a **new** method (KakaoPay, NaverPay, TossPay, ...) at checkout | The kit apps were built against `172.25.243.168`, so instead of the demo payment sheet they try to open the real PortOne page, which the demo server does not host. **Pay only with the saved "데모 카드 1234".** Opening the method list to show it is fine. |
| More → 청소 포인트 (Points) | Screen only, no earning logic yet (shows 0 P) |
| AI agent in the console inbox | No Claude API key on the demo server, so it shows "AI support is off" |
| PASS identity check, Kakao/Naver sign-in | Need real contract keys; the kit does not show these buttons |

**30 minutes before**
1. Double-click **`Malkkeum Demo.cmd`** in the desktop `Malkkeum Demo` folder.
2. Wait for the green **"Demo ready"** (a few minutes; longer if the emulator is created for the first time).
   A separate "Malkkeum Server" window opens. **Keep it open until the end.**
3. The console opens at `http://localhost:8081`. Sign in with **owner@demo.local / malkkeum-demo-2026** and check the dashboard loads.
4. Check the **말끔** customer app is open on the emulator; if not, tap its icon.
5. Layout: console (browser) left, emulator right. Browser zoom 125% (Ctrl +).
6. Bookings made during rehearsal stay in the database. That is fine.

**Sign-in numbers**
- Customer: **010-0000-0001** — a regular customer in the sample data with an address, a saved card, coupons and booking history.
  Any other number signs in too, but as a new customer with no saved card, so payment cannot be shown.
- Partner (optional): **010-0001-0001** (김태현, 말끔케어 강남팀, approved).
- Code: in demo mode no SMS is sent; the 6-digit code **fills in automatically**. Just tap [확인].

### Timeline (10 minutes)

| Time | Step | Click | Say (retention / revenue) | Audience should notice | Fallback |
|---|---|---|---|---|---|
| 0:00–0:40 | Opening | Console [대시보드] | "One platform: customer app, cleaner app and the owner's console, all connected. In ten minutes you'll see a booking go from tap to payout." | Today's jobs, open quotes, unassigned, unread chats, bookings by service, average rating. Say the numbers are sample data. | Blank page: F5. Login screen: sign in again. |
| 0:40–1:40 | Customer sign-in + home | 말끔 → [휴대폰 번호로 시작하기] → `01000000001` → [인증번호 받기] → [확인] | "Sign-up is just a phone number. A returning customer immediately sees their next visit and usable coupons; with no upcoming visit we show 'book again' to bring them back." | Greeting, upcoming booking, 8 services, coupon banner, invite-a-friend card, "free cancellation up to 2 days before", VAT-inclusive prices. | "Error": check the Malkkeum Server window; if closed, rerun `Malkkeum Demo.cmd`. No code: tap send again. |
| 1:40–3:40 | Booking + payment | [에어컨 청소] → type → [다음] → date + arrival time → [다음] → prep notes → [결제하러 가기] → open method list (show only) → pick **데모 카드 1234** → [○○원 결제하기] | "Fixed prices mean no phone calls; seats-left nudges customers to book now. In production PortOne accepts every Korean payment method, and a saved card pays in one tap. No real money moves today." | Step counter, "N left" per slot, address step skipped, coupon applied, VAT included, free-cancel date, "예약이 완료됐어요", timeline. | Payment error: check the saved card is selected, retry. Else open an existing booking from the [예약] tab. Slots full: pick another day. |
| 3:40–4:50 | Owner assigns (live) | Console [예약] → new booking (or Ctrl+K + number) → team name `말끔케어 강남팀` → [팀 배정] | "The booking lands in the console the moment the customer pays. One click to assign, and the customer's app updates instantly." | Customer timeline switches to "청소팀 배정 / 말끔케어 강남팀이(가) 방문해요" without refresh; payment rows in the console. | Pull down to refresh the app; reopen [예약]. |
| 4:50–5:40 | Complete + review | Console [완료 처리] → app "청소는 어떠셨나요?" → 5 stars → text → [후기 남기기] | "Right after the job we ask for a review. In real jobs the partner uploads before/after photos and a checklist. Reviews bring new customers; 'book again' brings the old ones back." | Completed step, review saved, "같은 조건으로 다시 예약" button. | Pull to refresh; if still missing, skip. |
| 5:40–6:30 | Quote desk | Console [견적 데스크] → one request | "For big jobs like move-in cleaning, several teams quote. The owner picks, sends a final price, and the 10% deposit auto-assigns the team." | Customer answers, auto estimate, partner quotes with notes, [견적 보내기] (no need to press). | Empty: describe it and move on. |
| 6:30–7:30 | Partner quality + payouts | [파트너] → one partner → [정산] → [지급 내역] | "New partners get no jobs until the owner approves them, and can be suspended instantly. Each partner has a fee rate, so platform revenue is computed per job; payouts run weekly from one list." | Approve/suspend, fee rate (20% in sample data), gross/fee/net, masked bank account with logged reveal. | Do not press [정산 지급 실행]. |
| 7:30–8:20 | Finance | [재무] → [월] → trend → [회계 자료 내려받기] | "Revenue, refunds, platform fee, partner payouts, payment-method mix and a VAT estimate on one screen. Send the monthly CSV straight to your accountant." | Net revenue, platform fee, VAT estimate, by service/partner, 3 CSVs. Be honest: cash receipts, tax invoices and 3.3% withholding are in the newest build and switch on after PortOne sandbox tests and accountant sign-off. | Download blocked: allow downloads, or just show numbers. |
| 8:20–9:15 | Marketing | [쿠폰 · 콘텐츠] → coupon issue form → [성장] tab | "In slow months send everyone a coupon at once; first-booking offers and referral rewards bring new customers. The review you just saw is moderated here." Optional: app [더보기] → [언어] → English and back: "English too, for foreign residents." | Issue-to-all form, first-booking offer, referral reward, review moderation. | Don't press issue (it really issues to all sample customers). |
| 9:15–10:00 | Launch readiness + close | [설정] → [시스템 상태] | "At launch you paste business info, PortOne, SMS and social-login keys here and press Test connection. Health and backups show as colours, problems text your phone, and updates roll back automatically if they fail." Close: "Customers book in a minute; the owner runs bookings, partners, payouts and tax exports from one screen. Next step: PortOne contract and store listings." | Setup progress, green/yellow/red checks. | Yellow/red on the demo PC (no backups): "backups are off on this demo PC". |

**Optional partner app (1 min):** emulator app drawer → **말끔 파트너** → `01000010001` → [일감]. "Partners only get jobs in their areas and hours; customer details stay masked until they accept, and the payout and fee show first." [수입] shows weekly/monthly earnings and the next payout date.

### When things go badly wrong (in order)
1. **App shows only errors** → find the "Malkkeum Server" window. If it shows red text or is gone, close it and rerun `Malkkeum Demo.cmd`; wait for "Demo ready"; pull to refresh.
2. **"Another emulator is running"** → close the other emulator, run again.
3. **"The emulator cannot reach…"** → allow api.exe on Private networks in Windows Firewall, run again.
4. **App not in front** → tap the 말끔 icon.
5. **Kit files look broken** → close the Malkkeum Server window, then run `Malkkeum Demo.cmd` in **`Malkkeum Demo (backup - works)`**. Both folders use the same database, so the backup does not fix data problems.
6. **Still broken** → continue in the console only (dashboard → existing bookings → quote desk → partners → payouts → finance) and show the customer app with the store screenshots in `docs/store/screenshots/customer/android/ko/`.
