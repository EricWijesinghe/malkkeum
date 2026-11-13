# 청중 예상 질문 15개 / 15 likely audience questions

Korean first, English second. 짧고 정직하게. 모르는 건 "확인해서 알려 드리겠습니다".
Sources: `docs/guide/*`, `docs/finance-tax.md`, `docs/privacy-retention.md`, `docs/store/*`.

---

## 한국어

**1. 운영 비용이 얼마나 드나요?**
고정비는 서버 월 1.5~3만 원, 도메인 연 1~2만 원 정도예요. 쓰는 만큼 나가는 비용은 결제 수수료(PortOne·PG사 계약에 따라 달라요), 문자 요금(Solapi), AI 상담원을 켜면 Claude API 사용료(콘솔에 월 사용량 표시), 외부 백업(월 몇 천 원 수준)이에요. 스토어 등록비는 구글 1회 $25, 애플 연 $99, Microsoft Store 등록비가 따로 있어요.

**2. 고객 정보는 어디에 저장되나요? 개인정보보호법(PIPA)은요?**
사장님 명의 서버(서울 리전 권장)의 데이터베이스에 저장돼요. 약관·개인정보·국외이전 동의는 기록으로 남고, 마케팅 수신 동의는 고객이 언제든 철회할 수 있어요. 고객은 앱에서 계정을 삭제할 수 있고(최신 버전은 내 정보 내려받기도 지원), 결제·예약 기록은 전자상거래법에 따라 5년 보관해요. 직원이 고객 연락처를 볼 때마다 기록이 남아요. 출시 전에 개인정보처리방침은 변호사 검토를 권해요.

**3. 카드번호를 저장하나요?**
아니요. 카드번호는 PortOne(결제사)이 보관하고, 저희 서버에는 결제용 토큰(빌링키)과 "카드 1234" 같은 표시 이름만 있어요. 파트너 계좌번호는 암호화해서 저장하고 화면에는 뒤 4자리만 보여요.

**4. 결제는 어떻게 되나요? 진짜 돈이 들어오나요?**
PortOne V2를 통해 카드, 카카오페이, 네이버페이, 토스페이, 페이코, 삼성페이, 애플페이, 계좌이체, 가상계좌, 휴대폰 결제를 받아요. 결제사 알림은 서명을 검사하고, 결제는 됐는데 처리가 실패한 건은 자동 대조로 복구해요. 오늘 시연은 데모 서버라 실제 돈은 움직이지 않았어요. 실제 PortOne 계정으로 테스트하는 단계가 출시 전에 남아 있어요.

**5. 결제 수수료는 얼마예요?**
PortOne과 PG사 계약 조건에 따라 달라서 지금 숫자를 말씀드리기 어려워요. 계약할 때 확인하시면 돼요. 플랫폼이 파트너에게서 받는 수수료율은 사장님이 파트너별로 정해요 (예시 데이터는 20%).

**6. 청소 파트너는 어떻게 검증하나요?**
파트너는 휴대폰 인증으로 가입하고, 사장님이 콘솔에서 승인해야 일감을 받을 수 있어요. 문제가 있으면 즉시 중지할 수 있고, 평점과 후기, 작업 전후 사진과 체크리스트로 품질을 봐요. 신원 조회나 보험 확인 같은 외부 검증은 시스템이 대신하지 않아요. 승인 전에 사장님이 직접 확인하는 절차를 정해 두시는 걸 권해요.

**7. 청소 중 사고나 분쟁이 생기면요?**
최신 버전에는 파손·분실·불만·노쇼·안전·결제 분쟁을 기록하고 처리 기한을 관리하는 사건 관리 화면이 있어요 (오늘 시연 키트에는 없는 버전이에요). 환불은 콘솔에서 예약 취소·환불로 처리해요. 보상 기준과 보험은 사장님이 정하셔야 해요.

**8. 오픈하려면 뭐가 필요한가요?**
① 사업자등록증과 통신판매업 신고증 ② PortOne 가입과 PG사 심사(3~10일) ③ 문자 발신번호 등록(Solapi, 1~2일) ④ 서버와 도메인 ⑤ 앱 스토어 계정(구글 Play·애플·Microsoft, 사업자 명의). 선택으로 카카오 비즈니스 채널(알림톡), 카카오·네이버·구글·애플 로그인 개발자 계정이 있어요. 콘솔 [설정]에서 순서대로 넣고 [연결 테스트]로 확인해요.

**9. 카카오톡 알림도 되나요?**
문자 서비스(Solapi)에 카카오 채널과 승인된 알림톡 템플릿을 연결하면 보낼 수 있게 설정 칸이 있어요. 카카오 비즈니스 채널 개설과 템플릿 승인이 먼저 필요해요. 앱 푸시 알림은 Firebase 설정 후 동작해요.

**10. 스토어에는 언제 올라가나요?**
계정이 준비되면 개발자가 빌드해서 아이폰은 TestFlight, 안드로이드는 Play 내부 테스트로 먼저 보내 드려요. 확인 후 심사 제출, 심사는 보통 애플 1~3일, 구글 1~7일이에요. 스토어 설명문(5개 언어), 스크린샷, 개인정보 답변은 준비돼 있어요.

**11. 세금 처리(부가세, 현금영수증, 원천징수)는요?**
지금 키트에서는 재무 화면의 부가세 추정과 세무사용 CSV(결제 원장, 월별 요약, 정산 내역)를 볼 수 있어요. 최신 버전에는 현금영수증, 세금계산서 요청 관리와 홈택스용 CSV, 파트너 3.3% 원천징수, 분기 부가세 요약이 들어 있어요. 다만 실제 결제사 테스트와 세무사 확인 전에는 켜지 않아요. 확인할 질문 12개를 정리해 두었어요.

**12. 포인트나 정기 구독도 되나요?**
아직이에요. 앱에 포인트 화면 자리만 있고 적립 기능은 없어요. 정기 청소 구독도 없어요. 지금 재방문 장치는 쿠폰(가입 축하, 첫 예약 할인, 전체 발급), 친구 초대, "다시 예약하기", 후기예요. 포인트·구독 규칙을 정해 주시면 다음 단계로 넣을 수 있어요.

**13. 서버가 멈추면 어떻게 하나요?**
콘솔 [시스템 상태]에서 서버·데이터베이스·디스크·백업·결제 상태를 색으로 보여 주고, 문제가 반복되면 사장님 휴대폰으로 문자가 가요(같은 문제는 6시간에 한 번, 조용한 시간 설정 가능). 매일 자동 백업하고, 외부 저장소 백업도 켤 수 있어요. 업데이트가 실패하면 자동으로 이전 버전으로 돌아가요.

**14. 직원이 여러 명이어도 되나요?**
네. 콘솔에서 직원 계정을 만들 수 있고, 상담원은 예약·상담만, 관리자는 모든 설정까지 볼 수 있어요. 최신 버전은 직원 2단계 인증(OTP 앱)도 지원해요. 파트너 쪽은 팀장이 팀원을 초대해 작업을 나눌 수 있어요.

**15. 외국인 고객이나 외국인 파트너도 쓸 수 있나요?**
네. 고객·파트너 앱과 콘솔 모두 한국어와 영어를 지원하고, 알림과 문자도 받는 사람의 언어로 가요. 다른 12개 언어는 보관해 두었다가 필요하면 다시 켤 수 있어요.

---

## English

**1. What does it cost to run?**
Fixed: a server at about ₩15–30k/month and a domain at about ₩10–20k/year. Usage-based: payment fees (depend on the PortOne/PG contract), SMS (Solapi), Claude API if the AI agent is on (monthly usage shown in the console), offsite backup (a few thousand won/month). Store fees: Google $25 once, Apple $99/year, plus the Microsoft Store registration fee.

**2. Where is customer data stored? What about PIPA?**
In the database on the owner's own server (Seoul region recommended). Consent to terms, privacy and overseas transfer is recorded; marketing consent can be withdrawn at any time. Customers can delete their account in the app (the newest build also lets them export their data); booking and payment records are kept 5 years under the E-Commerce Act. Every staff view of customer contact details is logged. We recommend a lawyer reviews the privacy policy before launch.

**3. Do you store card numbers?**
No. PortOne holds the card; our server stores only a billing token and a label like "card 1234". Partner bank account numbers are encrypted and shown as the last 4 digits.

**4. How do payments work? Is it real money?**
Through PortOne V2: card, KakaoPay, NaverPay, TossPay, PAYCO, Samsung Pay, Apple Pay, bank transfer, virtual account, mobile billing. Gateway webhooks are signature-checked, and paid-but-unprocessed payments are recovered by automatic reconciliation. Today's demo server moved no real money. A test run with a real PortOne account is still to be done before launch.

**5. What are the payment fees?**
They depend on the PortOne and PG contract, so we can't quote a number today. The platform's fee from partners is set per partner by the owner (20% in the sample data).

**6. How are cleaners vetted?**
Partners sign up with phone verification and receive no jobs until the owner approves them in the console. They can be suspended instantly; quality is tracked through ratings, reviews, before/after photos and a checklist. The system does not do background or insurance checks — the owner should define that step before approving.

**7. What about accidents or disputes?**
The newest build has a case screen for damage, loss, complaints, no-shows, safety and payment disputes with response deadlines (not in today's demo kit). Refunds are handled in the console via cancel/refund. Compensation rules and insurance are the owner's decision.

**8. What is needed to launch?**
(1) Business registration and mail-order sales report, (2) PortOne sign-up and PG review (3–10 days), (3) SMS sender-number registration (Solapi, 1–2 days), (4) a server and domain, (5) store accounts (Google Play, Apple, Microsoft) in the business's name. Optional: a Kakao business channel (AlimTalk) and Kakao/Naver/Google/Apple developer accounts for social login. Enter them in console [설정] and press Test connection.

**9. Can it send KakaoTalk messages?**
Yes, once a Kakao channel and approved AlimTalk templates are connected through Solapi (fields exist in setup). The Kakao business channel and template approval come first. Push notifications work after Firebase setup.

**10. When will it be in the stores?**
Once the accounts exist, the developer builds and sends TestFlight (iPhone) and Play internal-test (Android) links first. After your check it goes to review: usually 1–3 days at Apple, 1–7 at Google. Store text (Korean and English), screenshots and privacy answers are ready.

**11. Tax: VAT, cash receipts, withholding?**
Today's kit shows a VAT estimate and accountant CSVs (payments ledger, monthly summary, settlements). The newest build adds cash receipts, tax-invoice requests with a Hometax CSV, 3.3% partner withholding and a quarterly VAT summary. These stay off until tested with the real gateway and confirmed by an accountant; 12 open questions are written up.

**12. Points or subscriptions?**
Not yet. The app has a points screen but no earning logic, and no recurring subscription. Today's retention tools are coupons (welcome, first-booking offer, send-to-all), invite-a-friend, "book again" and reviews. Points and subscriptions can follow once the rules are decided.

**13. What if the server goes down?**
Console [시스템 상태] shows server, database, disk, backup and payment health as colours; repeated problems text the owner (once per 6 hours per issue, quiet hours configurable). Backups run daily, offsite backup can be switched on, and a failed update rolls back automatically.

**14. Can several staff use it?**
Yes. The console has staff accounts: consultants see bookings and chats, admins see all settings. The newest build adds staff two-factor sign-in (authenticator app). On the partner side, a team owner can invite members and split jobs.

**15. Foreign customers or partners?**
Yes. All three apps support Korean and English, and notifications and SMS go out in the recipient's language. Twelve more languages are archived and can be switched back on.
