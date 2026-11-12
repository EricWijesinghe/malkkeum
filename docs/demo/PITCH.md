# 말끔 피치 (10장) / Malkkeum pitch (10 slides)

Korean first, English second. 각 슬라이드: 화면에 넣을 내용 + 발표자 노트.
Rule for the speaker: say only what exists. Items marked **(준비 중 / planned)** are not built yet.

---

## 한국어

### 1. 문제
**화면**
- 청소 업체 예약은 아직 전화·카톡 문의가 대부분: 가격 문의, 일정 조율, 입금 확인
- 파트너(청소 팀) 관리와 주간 정산은 엑셀과 계좌 이체로 수작업
- 한 번 온 고객이 다시 오게 만드는 장치가 없음 (쿠폰·후기·재예약)

**발표자 노트**
"사장님들 하루 시간 대부분이 상담 전화와 일정 맞추기, 정산 엑셀에 들어갑니다. 그리고 한 번 청소한 고객에게 다시 연락할 방법이 마땅치 않습니다. 말끔은 이 세 가지를 하나의 시스템으로 묶습니다."

### 2. 해결: 앱 3개 + 서버 1개
**화면**
- 고객 앱 (안드로이드·아이폰·웹): 1분 예약, 결제, 진행 상황, 채팅, 후기
- 파트너 앱: 우리 동네 일감 받기, 견적, 일정, 완료 사진, 수입
- 사장님 콘솔 (PC·휴대폰·웹): 예약, 견적, 상담, 파트너, 정산, 재무, 마케팅, 설정
- 사장님 소유 서버 (서울 리전 클라우드), 14개 언어

**발표자 노트**
"세 개의 앱이 같은 서버를 씁니다. 서버는 사장님 명의로 빌리는 클라우드 서버라 데이터도 사장님 것입니다. 한국어가 기본이고 영어·중국어·베트남어·일본어 등 14개 언어를 지원합니다. 몽골어·싱할라어·네팔어·우즈베크어·크메르어·필리핀어는 원어민 검수가 남아 있습니다."

### 3. 시연 하이라이트
**화면**
- 휴대폰 번호 로그인 → 정찰제 가격 → 남은 자리 표시 → 저장 카드로 한 번에 결제
- 결제 즉시 콘솔에 예약 도착 → [팀 배정] → 고객 앱 진행 단계가 실시간으로 바뀜
- 완료 → 후기 요청 → "같은 조건으로 다시 예약"
- 이사·입주 청소: 파트너 여러 팀이 견적 → 사장님이 최종 금액 → 예약금 10% 결제 시 자동 배정

**발표자 노트**
"방금 보신 흐름이 실제 서비스 흐름 그대로입니다. 오늘은 데모 서버라 결제와 문자만 가짜로 처리했습니다."

### 4. 고객이 다시 오는 이유
**화면**
- 홈에 다가오는 예약, 쓸 수 있는 쿠폰, 지난 서비스 "다시 예약하기" 카드
- 가입 축하 쿠폰 2장, 첫 예약 할인, 친구 초대 쿠폰
- 전후 사진 리포트와 후기, 앱 채팅 상담, 방문 2일 전까지 무료 취소
- 전체 고객 쿠폰 발급, 홈 배너·공지 (14개 언어 편집)
- **(준비 중)** 청소 포인트 적립 (화면만 있음), 정기 청소 구독, 알림톡 재예약 알림

**발표자 노트**
"재방문은 세 가지로 만듭니다. 기억나게 하고(홈 카드, 알림), 이유를 주고(쿠폰, 첫 예약 할인, 친구 초대), 믿게 합니다(사진 리포트, 후기, 무료 취소). 포인트와 정기 구독은 사장님과 적립 규칙·할인율을 정한 뒤 붙일 계획입니다."

### 5. 파트너 품질
**화면**
- 가입 후 사장님 승인 전에는 일감을 받지 못함, 문제 시 즉시 중지
- 파트너별 평점·완료 건수, 후기 관리(숨기기)
- 수락 전에는 고객 개인정보 가림, 받을 금액과 수수료 먼저 표시
- 완료 시 전후 사진 + 체크리스트 제출
- 최신 버전: 현장 도착 체크인, 노쇼 감지, 사고·분쟁 사건 관리, 출입 비밀번호 암호화 후 24시간 뒤 삭제

**발표자 노트**
"파트너 심사는 휴대폰 인증과 사장님 승인으로 합니다. 신원 조회나 보험 확인 같은 외부 검증은 시스템이 대신하지 않으니, 승인 전에 사장님이 직접 확인하는 절차를 정하시면 됩니다. 체크인과 사건 관리는 최신 빌드에 들어 있고 오늘 키트에는 없습니다."

### 6. 사장님 도구
**화면**
- 대시보드: 오늘 작업, 견적 대기, 미배정, 안 읽은 상담, 서비스별 예약, 평균 평점
- 상담함: 고객·파트너 채팅, 단축키 / AI 상담원 (Claude, 키를 넣으면 켜짐, 대화별 일시중지, 월 사용량 표시)
- 카탈로그·가격: 저장하면 앱과 웹사이트 가격이 바로 바뀜
- 시스템 상태(초록·노랑·빨강), 문제 시 사장님 휴대폰 문자, 자동 백업과 외부 백업
- 한 줄 설치, 업데이트 실패 시 자동 되돌리기, 안정/베타 채널

**발표자 노트**
"사장님은 아침 5분 대시보드만 보시면 됩니다. AI 상담원은 Claude API 키를 넣으면 켜지고, 비용은 쓴 만큼 나오며 콘솔에 사용량이 보입니다."

### 7. 재무와 세무
**화면**
- 재무: 매출, 환불, 순매출, 플랫폼 수수료, 파트너 지급, 결제수단별, 부가세 추정
- 세무사용 CSV: 결제 원장, 월별 요약, 정산 내역 (엑셀에서 한글 깨짐 없음)
- 최신 버전: 현금영수증(PortOne), 세금계산서 요청 큐 + 홈택스용 CSV, 파트너 사업소득 3.3% 원천징수, 분기 부가세 요약, 지급명세서 CSV
- 출시 전: PortOne 테스트와 세무사 확인 (체크리스트 12개 항목 준비됨)

**발표자 노트**
"세무 기능은 만들어져 있지만 실제 결제사와 세무사 확인 전에는 켜지 않습니다. 홈택스 양식 열 순서, 원천징수 기준 금액, 플랫폼이 판매자인지 중개자인지 같은 질문을 정리해 두었으니 세무사님과 한 번 미팅하면 됩니다."

### 8. 출시 계획
**화면**
- 1단계: 사업자등록·통신판매업 신고 → 서버(월 1.5~3만 원)와 도메인 → 한 줄 설치
- 2단계: PortOne 가입과 PG 심사(3~10일), 문자(Solapi) 발신번호 등록, 카카오 비즈니스 채널(알림톡, 선택)
- 3단계: Google Play(조직 계정 $25, 내부 테스트) · App Store($99/년, D-U-N-S, TestFlight) · Microsoft Store(Partner Center, 앱 3개)
- 스토어 설명문 5개 언어, 스크린샷, 개인정보 답변 준비 완료

**발표자 노트**
"앱 빌드와 업로드는 개발자가 합니다. 사장님은 사업자 명의로 계정을 만들고 개발자를 초대하시면 됩니다. 심사는 보통 애플 1~3일, 구글 1~7일입니다. 현재 남은 기술 작업은 실제 결제 키로 테스트하는 것과, 깃허브 자동 빌드가 대기 중인 문제(결제 한도 확인)를 푸는 것입니다."

### 9. 왜 지금, 왜 말끔
**화면**
- 이미 동작하는 전체 흐름: 예약 → 결제 → 배정 → 완료 → 후기 → 정산 → 세무 자료
- 사장님 소유 서버와 데이터, 업체 이름·로고 교체 가능
- 테스트: 서버 177개 이상, 앱 200개 이상, 14개 언어 × 작은 화면 검사

**발표자 노트**
"아이디어 단계가 아니라 오늘 보신 것처럼 돌아가는 시스템입니다. 남은 것은 계약과 등록입니다."

### 10. 요청
**화면**
- 파일럿 업체 1곳: 실제 사업자 정보와 PortOne 계약으로 4주 운영
- 결정할 것: 서비스 가격, 파트너 수수료율, 쿠폰·포인트 규칙, 브랜드 이름·로고
- 연락처: (발표자 정보 기입)

**발표자 노트**
"첫 업체와 함께 4주 동안 실제 예약을 받아 보고 싶습니다. 계약과 계정 준비는 저희가 체크리스트로 안내해 드립니다."

---

## English

### 1. Problem
**Slide**
- Cleaning bookings still run on phone calls and KakaoTalk: price questions, scheduling, payment checks
- Partner (cleaning team) management and weekly payouts are manual spreadsheets and transfers
- Nothing brings a one-time customer back (coupons, reviews, rebooking)

**Speaker notes**
"Owners spend their day on calls, scheduling and payout spreadsheets, and have no easy way to reach a past customer again. Malkkeum puts all three into one system."

### 2. Solution: three apps, one server
**Slide**
- Customer app (Android, iPhone, web): book in a minute, pay, track, chat, review
- Partner app: local jobs, quotes, schedule, completion photos, earnings
- Owner console (PC, phone, web): bookings, quotes, inbox, partners, payouts, finance, marketing, setup
- Owner-owned server (Seoul-region cloud), 14 languages

**Speaker notes**
"All three apps share one server that the owner rents in their own name, so the data is theirs. Korean is the default; 14 languages in total. Mongolian, Sinhala, Nepali, Uzbek, Khmer and Filipino still need native-speaker review."

### 3. Demo highlights
**Slide**
- Phone sign-in → fixed prices → seats left → one-tap payment with a saved card
- Booking reaches the console on payment → [Assign team] → customer timeline updates live
- Complete → review request → "Book again with the same options"
- Move-in/out: several teams quote → owner sets the final price → 10% deposit auto-assigns

**Speaker notes**
"This is the production flow. Only payment and SMS were simulated today because this is a demo server."

### 4. Why customers stay
**Slide**
- Home shows the next visit, usable coupons, and a "book again" card for the last service
- 2 welcome coupons, first-booking offer, invite-a-friend coupon
- Before/after photo report, reviews, in-app chat, free cancellation up to 2 days before
- Coupons to all customers at once, home banners and notices (edited in 14 languages)
- **(Planned)** points earning (screen exists, no logic), recurring subscriptions, AlimTalk rebooking reminders

**Speaker notes**
"Retention comes from reminding (home cards, notifications), giving a reason (coupons, first-booking offer, referrals) and earning trust (photo reports, reviews, free cancellation). Points and subscriptions come after we agree the earning rules and discount rates."

### 5. Partner quality
**Slide**
- No jobs until the owner approves; instant suspension
- Per-partner rating and completed jobs; review moderation (hide)
- Customer details masked until a partner accepts; payout and fee shown first
- Before/after photos + checklist on completion
- Newest build: on-site check-in, no-show detection, incident/dispute cases, door codes encrypted and deleted 24 h after the job

**Speaker notes**
"Vetting is phone verification plus the owner's approval. The system does not run background or insurance checks; the owner should define that step before approving. Check-in and cases are in the newest build, not in today's kit."

### 6. Owner tools
**Slide**
- Dashboard: today's jobs, open quotes, unassigned, unread chats, bookings by service, average rating
- Inbox: customer and partner chats, shortcuts / AI agent (Claude; on once a key is added; pause per thread; monthly usage)
- Catalog and prices: saving updates the apps and website at once
- System status (green/yellow/red), SMS alerts to the owner, automatic and offsite backups
- One-line install, automatic rollback on a failed update, stable/beta channels

**Speaker notes**
"Five minutes on the dashboard each morning is enough. The AI agent runs once a Claude API key is entered; it is pay-per-use and the console shows usage."

### 7. Finance and tax
**Slide**
- Finance: gross, refunds, net revenue, platform fee, partner payouts, payment-method mix, VAT estimate
- Accountant CSVs: payments ledger, monthly summary, settlements (Excel-safe Korean)
- Newest build: cash receipts (PortOne), tax-invoice queue + Hometax CSV, 3.3% partner withholding, quarterly VAT summary, withholding statement CSV
- Before launch: PortOne sandbox run and accountant sign-off (12-item checklist ready)

**Speaker notes**
"The tax features are built but stay off until tested with the real gateway and confirmed by an accountant. Open questions — Hometax column order, the withholding base, whether the platform is seller or intermediary — are written up for one meeting."

### 8. Launch plan
**Slide**
- Step 1: business registration and mail-order sales report → server (₩15–30k/month) and domain → one-line install
- Step 2: PortOne sign-up and PG review (3–10 days), Solapi sender-number registration, Kakao business channel (AlimTalk, optional)
- Step 3: Google Play (organisation account, $25, internal testing) · App Store ($99/year, D-U-N-S, TestFlight) · Microsoft Store (Partner Center, 3 apps)
- Store text in 5 languages, screenshots and privacy answers are ready

**Speaker notes**
"The developer builds and uploads the apps; the owner creates the accounts in the business's name and invites the developer. Review usually takes 1–3 days at Apple and 1–7 at Google. Remaining technical work: a test run with real payment keys, and unblocking the queued GitHub builds (billing limit)."

### 9. Why now, why Malkkeum
**Slide**
- The whole loop works today: book → pay → assign → complete → review → payout → tax exports
- Owner-owned server and data; brand name and logo are swappable
- Tests: 177+ server, 200+ app, 14 languages × small-screen sweeps

**Speaker notes**
"This is not an idea deck; you just saw it run. What's left is contracts and registrations."

### 10. The ask
**Slide**
- One pilot business: 4 weeks live with real business details and a PortOne contract
- Decisions: service prices, partner fee rate, coupon/points rules, brand name and logo
- Contact: (fill in presenter details)

**Speaker notes**
"We'd like to run four weeks of real bookings with a first business. We'll guide the contracts and accounts with a checklist."
