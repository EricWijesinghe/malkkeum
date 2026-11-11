# Generates the website's legal and partner pages from one shared layout.
# Run from the repo root:  python -I scripts/build_legal.py website
# Business details (상호, 대표, 사업자번호 ...) are filled in the browser from /v1/brand,
# i.e. from what the owner typed in the console setup wizard. No editing needed here.
import os
import pathlib
import sys

OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent)
EFFECTIVE = "2026년 11월 17일"
# Retention windows shown in the policy; keep equal to the server defaults (AI_CHAT_RETENTION_DAYS, UPLOAD_ORPHAN_DAYS).
AI_DAYS = os.environ.get("AI_CHAT_RETENTION_DAYS", "180")
ORPHAN_DAYS = os.environ.get("UPLOAD_ORPHAN_DAYS", "30")

HEAD = """<!doctype html>
<html lang="ko" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>{title} · 말끔</title>
  <link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css">
  <link rel="stylesheet" href="assets/site.css">
  <script>try {{ const t = localStorage.getItem('site.theme'); if (t) document.documentElement.dataset.theme = t; }} catch (e) {{}}</script>
  <script defer src="assets/site.js"></script>
</head>
<body>
  <div class="aurora" aria-hidden="true"><i></i><i></i><i></i></div>
  <header class="nav"><div class="wrap">
    <a class="logo" href="/"><span class="logo-mark" aria-hidden="true"></span><span data-brand-name>말끔</span></a>
    <div class="tools"><select id="lang" class="lang" aria-label="Language"></select><button id="theme" class="icon-btn" type="button" aria-label="Light mode">☀️</button></div>
  </div></header>
  <main class="wrap doc">
"""

FOOT = """  </main>
  <footer><div class="wrap cols">
    <div><p class="company" id="company"></p><p>© <span id="year"></span> <span data-brand-name>말끔</span></p></div>
    <div><b data-t="f_support">고객센터</b><br><a data-support-phone href="#"></a><br><a data-support-email href="#"></a></div>
    <div><a href="privacy.html" data-t="f_privacy">개인정보처리방침</a><br><a href="terms.html" data-t="f_terms">이용약관</a><br>
      <a href="location.html" data-t="f_location">위치기반서비스 이용약관</a><br><a href="delete-account.html" data-t="f_delete">계정 삭제 안내</a></div>
  </div></footer>
</body>
</html>
"""

CO = '<span data-fill="company.legal_name">[상호]</span>'
SVC = '<span data-brand-name>말끔</span>'
OFFICER = '<span data-fill="company.privacy_officer">[개인정보 보호책임자]</span>'
CONTACT = '<a data-support-email href="#"></a> · <a data-support-phone href="#"></a>'

PRIVACY = f"""
    <h1>개인정보처리방침</h1>
    <p class="note">{CO}(이하 "회사")는 「개인정보 보호법」에 따라 이용자의 개인정보를 보호하고 고충을 신속히 처리하기 위해 다음과 같이 개인정보처리방침을 둡니다. 시행일: {EFFECTIVE}</p>
    <h2>1. 수집하는 개인정보 항목</h2>
    <table>
      <tr><th>구분</th><th>항목</th><th>수집 방법</th></tr>
      <tr><td>고객 회원가입</td><td>휴대전화번호, 이름(선택), 소셜 로그인 식별자(카카오·네이버·구글·애플), 이메일(소셜 제공 시)</td><td>앱 입력, 소셜 로그인</td></tr>
      <tr><td>예약·서비스 제공</td><td>주소(도로명주소 검색 결과 포함), 집 크기·구조 정보, 방문 메모, 청소 전후 사진, 상담 내용</td><td>앱 입력</td></tr>
      <tr><td>AI 상담</td><td>고객이 AI 상담에 입력한 문장과 AI 응답, 상담 기록</td><td>앱 입력</td></tr>
      <tr><td>결제</td><td>결제 수단 종류, 결제 승인 정보, 가상계좌 입금 정보, 자동결제 키(카드번호는 결제대행사가 처리하며 회사는 저장하지 않음)</td><td>결제대행사</td></tr>
      <tr><td>본인인증(선택)</td><td>이름, 생년월일, 연계정보(CI는 해시값으로만 저장)</td><td>본인인증기관</td></tr>
      <tr><td>동의 기록</td><td>약관·방침 버전, 동의 또는 철회 여부와 일시, 마케팅 수신 동의 여부</td><td>앱 입력</td></tr>
      <tr><td>파트너(청소 전문가)</td><td>이름, 휴대전화번호, 활동 지역, 정산 계좌(암호화 저장), 팀원 정보</td><td>파트너 앱 입력</td></tr>
      <tr><td>자동 수집</td><td>푸시 알림 토큰, 기기 종류, 접속 IP, 접속 기록, 언어 설정</td><td>서비스 이용 과정</td></tr>
    </table>
    <p>회사는 기기의 실시간 위치(GPS)를 수집하지 않습니다. 주소는 이용자가 직접 입력하거나 검색해 고른 값만 사용합니다.</p>
    <h2>2. 이용 목적</h2>
    <ul><li>회원 식별, 로그인, 부정 이용 방지</li><li>예약, 견적, 파트너 배정, 방문 서비스 제공과 상담(AI 상담 포함)</li><li>결제, 환불, 정산</li><li>예약 알림(문자, 카카오 알림톡, 앱 푸시) 발송</li><li>마케팅 정보 발송 (마케팅 수신에 동의한 고객에 한함, 언제든지 철회 가능)</li><li>분쟁 처리, 민원 응대, 법령상 의무 이행, 동의 사실 증빙</li></ul>
    <h2>3. 보유 및 이용 기간</h2>
    <p>회원 탈퇴 시 지체 없이 파기합니다. 다만 관계 법령에 따라 다음 정보는 정해진 기간 동안 보관합니다.</p>
    <table><tr><th>정보</th><th>보유 기간</th><th>근거</th></tr>
      <tr><td>계약·청약철회, 대금결제, 재화 등의 공급 기록</td><td>5년</td><td>전자상거래법</td></tr>
      <tr><td>소비자 불만·분쟁처리 기록</td><td>3년</td><td>전자상거래법</td></tr>
      <tr><td>접속 기록</td><td>3개월</td><td>통신비밀보호법</td></tr>
      <tr><td>동의 기록(버전, 일시, 동의·철회 여부)</td><td>탈퇴 후 5년</td><td>동의 사실 증빙(회사 내부 기준)</td></tr>
      <tr><td>AI 상담 대화 내용</td><td>상담일로부터 {AI_DAYS}일</td><td>회사 운영 기준 (설정값)</td></tr>
      <tr><td>연결되지 않은 업로드 사진</td><td>업로드일로부터 {ORPHAN_DAYS}일</td><td>회사 운영 기준 (설정값)</td></tr>
      <tr><td>인증번호(OTP)</td><td>발급일로부터 1일</td><td>회사 운영 기준</td></tr>
    </table>
    <h2>4. 제3자 제공</h2>
    <table><tr><th>받는 자</th><th>목적</th><th>항목</th><th>보유 기간</th></tr>
      <tr><td>배정된 청소 파트너</td><td>방문 서비스 수행</td><td>예약 정보, 주소, 이름(일부 가림), 방문 메모</td><td>작업 완료 후 30일</td></tr></table>
    <h2>5. 처리 위탁</h2>
    <table><tr><th>수탁자</th><th>위탁 업무</th><th>처리 장소</th></tr>
      <tr><td>PortOne 및 각 결제대행사</td><td>결제 처리, 자동결제 키 관리, 본인인증</td><td>국내</td></tr>
      <tr><td>Solapi</td><td>문자 메시지·카카오 알림톡 발송</td><td>국내</td></tr>
      <tr><td>도로명주소 개발자센터(행정안전부, 주소 검색 API)</td><td>주소 검색</td><td>국내</td></tr>
      <tr><td>Google LLC (Firebase Cloud Messaging)</td><td>앱 푸시 알림 발송</td><td>미국 (국외 이전, 아래 6항)</td></tr>
      <tr><td>Anthropic, PBC</td><td>AI 상담 응답 생성</td><td>미국 (국외 이전, 아래 6항)</td></tr>
      <tr><td>서버 호스팅 사업자</td><td>서비스 운영 데이터 보관</td><td>국내</td></tr>
      <tr><td>백업 저장소 사업자(S3 호환)</td><td>데이터베이스 백업 보관</td><td>운영자가 설정한 저장소 위치 (국외일 수 있음, 아래 6항)</td></tr></table>
    <p>소셜 로그인(카카오, 네이버, 구글, 애플)은 이용자가 선택한 경우에 한해 각 사에서 본인 확인을 받기 위해 사용하며, 각 사의 개인정보처리방침이 적용됩니다.</p>
    <h2>6. 개인정보의 국외 이전</h2>
    <table><tr><th>이전받는 자</th><th>이전 국가</th><th>이전 항목</th><th>이전 목적</th><th>이전 방법·시기</th><th>보유 기간</th></tr>
      <tr><td>Google LLC (Firebase)</td><td>미국</td><td>푸시 토큰, 알림 제목·본문</td><td>앱 푸시 알림 발송</td><td>서비스 이용 중 네트워크 전송</td><td>푸시 토큰은 앱 삭제 또는 탈퇴 시까지</td></tr>
      <tr><td>Anthropic, PBC</td><td>미국</td><td>AI 상담 중 고객이 입력한 문장과 상담 맥락</td><td>AI 상담 응답 생성</td><td>AI 상담 이용 시 네트워크 전송</td><td>회사 보관 기간과 동일(AI 상담 보관 기간 참고). 제공자 정책에 따라 처리</td></tr>
      <tr><td>백업 저장소 사업자</td><td>운영자 설정에 따름</td><td>데이터베이스 백업 파일(AES-256-GCM 암호화)</td><td>장애 복구</td><td>정기 백업 실행 시 전송</td><td>백업 보관 기간(운영자 설정, 기본 30일)</td></tr></table>
    <p>이용자는 국외 이전에 동의하지 않을 권리가 있습니다. 동의하지 않으면 해당 기능(푸시 알림, AI 상담)을 사용할 수 없고, 필요한 경우 문자 알림이나 상담원 상담으로 대신합니다. 국외 이전 동의는 앱의 [더보기 → 계정 → 동의 관리]에서 확인하고 철회할 수 있습니다.</p>
    <h2>7. 파기</h2>
    <p>보유 기간이 끝나거나 목적이 달성된 개인정보는 복구할 수 없는 방법으로 지체 없이 파기합니다. 파기는 매일 자동으로 실행되는 정리 작업으로 처리하며, 데이터베이스 백업은 보관 기간이 지나면 자동 삭제합니다.</p>
    <h2>8. 이용자의 권리와 행사 방법</h2>
    <p>이용자는 언제든지 개인정보의 열람, 정정, 삭제, 처리 정지, 동의 철회를 요구할 수 있습니다.</p>
    <ul><li>열람: 앱 [더보기 → 계정 → 내 데이터 내려받기]에서 JSON 파일로 받을 수 있습니다.</li><li>마케팅 수신 동의 철회: 앱 [더보기 → 계정 → 동의 관리]</li><li>정정·삭제·탈퇴: 앱 [더보기 → 계정 → 회원 탈퇴] 또는 <a href="delete-account.html">계정 삭제 안내</a></li></ul>
    <p>앱을 쓸 수 없는 경우 고객센터로 요청할 수 있으며, 회사는 10일 이내에 처리 결과를 알려 드립니다.</p>
    <h2>9. 안전성 확보 조치</h2>
    <ul><li>전 구간 암호화 통신(HTTPS)</li><li>정산 계좌·연동 키 암호화 저장(AES-256-GCM), 자동결제 키와 본인확인 정보(CI) 해시 저장</li><li>관리자 비밀번호 해시 저장, 로그인 실패 잠금, 권한 최소화</li><li>직원의 고객 연락처·정산 계좌 조회 기록 보관, 정기 점검</li><li>개인정보 보관 기간이 지난 정보의 자동 파기</li></ul>
    <h2>10. 개인정보 보호책임자</h2>
    <p>성명: {OFFICER}<br>연락처: {CONTACT}</p>
    <p>개인정보침해신고센터(privacy.kisa.or.kr, 118), 개인정보분쟁조정위원회(www.kopico.go.kr, 1833-6972)에 문의할 수도 있습니다.</p>
    <h2>11. 변경 고지</h2>
    <p>이 방침이 바뀌면 시행 7일 전부터 앱과 웹사이트에 공지합니다. 국외 이전 항목이나 필수 동의 내용이 바뀌면 다시 동의를 받습니다.</p>
"""

TERMS = f"""
    <h1>서비스 이용약관</h1>
    <p class="note">시행일: {EFFECTIVE}</p>
    <h2>제1조 (목적)</h2><p>이 약관은 {CO}(이하 "회사")가 제공하는 {SVC} 홈클리닝 서비스(이하 "서비스")의 이용 조건, 회사와 이용자의 권리와 의무를 정합니다.</p>
    <h2>제2조 (서비스 내용)</h2><p>회사는 고객과 청소 전문가(이하 "파트너")를 연결하고 예약, 결제, 상담, 정산 기능을 제공합니다. 방문 청소는 회사의 기준으로 심사된 파트너가 수행합니다.</p>
    <h2>제3조 (회원가입)</h2><p>휴대전화 인증 또는 소셜 로그인으로 가입하며 정확한 정보를 제공해야 합니다. 만 14세 미만은 가입할 수 없습니다.</p>
    <h2>제4조 (예약과 결제)</h2><p>예약은 결제가 완료된 때 확정됩니다. 견적형 서비스(이사·입주 청소 등)는 견적 확인 후 예약금 결제로 확정되고, 잔금은 작업 완료 후 결제합니다.</p>
    <h2>제5조 (취소와 환불)</h2><ul><li>방문일 2일 전까지 취소: 전액 환불</li><li>그 이후 취소: 앱에 안내된 취소 수수료 기준에 따름</li><li>회사 또는 파트너 사정으로 서비스가 제공되지 못한 경우: 전액 환불</li></ul>
    <h2>제6조 (이용자의 의무)</h2><p>방문 주소와 작업 환경 정보를 정확히 제공하고 파트너가 안전하게 작업할 수 있도록 협조해야 합니다.</p>
    <h2>제7조 (손해배상)</h2><p>파트너의 고의 또는 과실로 손해가 생기면 회사는 관련 법령과 회사의 보상 기준에 따라 처리를 돕습니다. 작업 전후 사진은 확인 자료로 쓰일 수 있습니다.</p>
    <h2>제8조 (서비스 변경·중단)</h2><p>설비 점검 등 부득이한 경우 서비스를 일시 중단할 수 있으며 미리 공지합니다.</p>
    <h2>제9조 (분쟁 해결)</h2><p>분쟁은 고객센터를 통해 먼저 협의하며, 협의가 안 되면 관할 법원은 민사소송법에 따릅니다.</p>
    <h2>사업자 정보</h2><p>상호 {CO} · 대표 <span data-fill="company.ceo">[대표자]</span> · 사업자등록번호 <span data-fill="company.registration_no">[번호]</span> · 통신판매업 신고 <span data-fill="company.mail_order_no">[번호]</span> · 주소 <span data-fill="company.address">[주소]</span></p>
"""

LOCATION = f"""
    <h1>위치기반서비스 이용약관</h1>
    <p class="note">시행일: {EFFECTIVE}</p>
    <h2>제1조 (목적)</h2><p>이 약관은 {CO}가 제공하는 위치기반서비스의 이용 조건을 「위치정보의 보호 및 이용 등에 관한 법률」에 따라 정합니다.</p>
    <h2>제2조 (서비스 내용)</h2><ul><li>고객이 입력한 주소로 서비스 가능 지역 확인과 파트너 배정</li><li>파트너가 설정한 활동 지역에 맞는 작업 목록 제공</li></ul>
    <p>회사는 기기의 실시간 위치(GPS)를 수집하지 않고, 이용자가 직접 입력한 주소만 이용합니다.</p>
    <h2>제3조 (보유 기간)</h2><p>주소 정보는 회원 탈퇴 시 파기하며, 거래 기록은 관련 법령에 따른 기간 동안 보관합니다.</p>
    <h2>제4조 (이용자의 권리)</h2><p>언제든지 주소 정보 삭제를 요청하거나 동의를 철회할 수 있습니다.</p>
    <h2>제5조 (위치정보관리책임자)</h2><p>{OFFICER} · {CONTACT}</p>
"""

DELETE = f"""
    <h1>계정 삭제 안내 · Delete your account</h1>
    <h2>앱에서 바로 삭제하기</h2>
    <ol><li>{SVC} 앱을 열고 [더보기] 탭으로 이동합니다.</li><li>[계정] → [회원 탈퇴]를 누릅니다.</li><li>안내를 확인하고 [탈퇴하기]를 누르면 계정과 개인정보가 삭제됩니다.</li></ol>
    <h2>앱을 쓸 수 없을 때</h2>
    <p>가입한 휴대전화번호로 고객센터({CONTACT})에 요청하면 본인 확인 후 10일 안에 처리합니다.</p>
    <h2>삭제되는 정보와 보관되는 정보</h2>
    <p>이름·이메일·휴대전화번호, 주소, 자동결제 카드 키, 푸시 토큰, 알림 기록은 삭제됩니다. 상담 대화는 고객을 식별할 수 없도록 연결을 끊고, AI 상담 기록은 보관 기간이 지나면 삭제됩니다. 예약·결제·환불 기록은 전자상거래법에 따라 5년간 따로 보관한 뒤 파기합니다.</p>
    <h2>In English</h2>
    <p>Open the app → More → Account → Delete account. If you cannot use the app, contact support from the phone number you signed up with and we delete the account within 10 days. Payment records are kept for 5 years as Korean e-commerce law requires. Anything still needed for legal retention is kept only as long as the law requires.</p>
"""

PARTNERS = f"""
    <h1>{SVC} 파트너가 되어 주세요</h1>
    <p class="lead">원하는 지역과 시간에 일하고, 완료한 작업은 매주 수요일에 정산받아요.</p>
    <div class="trust" style="margin:32px 0">
      <div class="item"><span class="emoji" aria-hidden="true">🗺️</span><b>원하는 지역만</b><p>서울 25개 구 가운데 활동 지역을 직접 골라요.</p></div>
      <div class="item"><span class="emoji" aria-hidden="true">⏰</span><b>원하는 시간만</b><p>가능한 요일과 시간대를 정하면 맞는 작업만 보여요.</p></div>
      <div class="item"><span class="emoji" aria-hidden="true">💸</span><b>매주 정산</b><p>완료한 작업은 수수료를 뺀 금액이 매주 수요일에 입금돼요.</p></div>
    </div>
    <h2>지원 방법</h2>
    <ol><li>파트너 앱을 내려받아 휴대전화로 가입합니다.</li><li>팀 이름, 활동 지역, 가능 시간을 입력합니다.</li><li>심사가 끝나면 바로 작업을 받을 수 있어요.</li></ol>
    <div class="store-badges" style="margin-top:24px">
      <a class="store" data-link="partner_app_store_url" href="#" aria-disabled="true"><span><small data-t="store_soon">곧 출시</small><b>App Store</b></span></a>
      <a class="store" data-link="partner_play_store_url" href="#" aria-disabled="true"><span><small data-t="store_soon">곧 출시</small><b>Google Play</b></span></a>
    </div>
"""

PAGES = {
    "privacy.html": ("개인정보처리방침", PRIVACY),
    "terms.html": ("이용약관", TERMS),
    "location.html": ("위치기반서비스 이용약관", LOCATION),
    "delete-account.html": ("계정 삭제 안내", DELETE),
    "partners.html": ("파트너 지원", PARTNERS),
}

if __name__ == "__main__":
    for name, (title, body) in PAGES.items():
        (OUT / name).write_text(HEAD.format(title=title) + body + FOOT, encoding="utf-8")
        print("wrote", name)
