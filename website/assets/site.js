// Website behaviour: language, theme, live brand + prices from the API, card tilt,
// before/after slider, scroll reveal. No framework, no build step.
const API = location.hostname === 'localhost' || location.hostname === '127.0.0.1' ? 'http://127.0.0.1:8080' : '';

// Fair Trade Commission seller lookup; takes the 10-digit 사업자등록번호 without dashes.
const FTC_LOOKUP = 'https://www.ftc.go.kr/bizCommPop.do?wrkr_no=';
const BIZ_NO_DIGITS = 10;

const LANGS = { ko: '한국어', en: 'English', ja: '日本語', zh: '中文', vi: 'Tiếng Việt', ru: 'Русский', ne: 'नेपाली', si: 'සිංහල', th: 'ไทย', id: 'Bahasa Indonesia', mn: 'Монгол', uz: "O'zbek", fil: 'Filipino', km: 'ខ្មែរ' };

const COPY = {
  ko: {
    proof_title: '다해 이야기', proof_homes: '이번 달 {n}집을 청소했어요', proof_rating: '평균 평점 {r}점 · 후기 {n}개',
    nav_services: '서비스', nav_how: '이용 방법', nav_faq: '자주 묻는 질문', nav_partner: '파트너 지원',
    eyebrow: '오늘 예약하면 내일 방문', h1a: '집안일은 맡기고,', h1b: '반짝이는 하루를.',
    lead: '검증된 청소 전문가가 욕실부터 이사 청소까지. 앱에서 가격 확인하고 1분 만에 예약하세요.',
    cta_book: '앱으로 예약하기', cta_prices: '가격 보기', chip_a: '✨ 검증된 전문가', chip_b: '💳 간편 결제',
    svc_title: '필요한 청소만, 투명한 가격으로', svc_sub: '아래 가격은 실시간으로 반영돼요.', from: '부터', quote: '방문 견적',
    how_title: '예약은 1분, 나머지는 저희가', how_1t: '서비스 선택', how_1: '필요한 청소와 집 크기를 고르면 가격이 바로 나와요.',
    how_2t: '날짜 선택', how_2: '내일부터 60일 안의 원하는 시간으로.', how_3t: '간편 결제', how_3: '카드, 카카오페이, 네이버페이, 토스페이 등 원하는 방법으로.',
    how_4t: '방문 · 완료', how_4: '전문가가 방문해 청소하고, 전후 사진으로 확인해요.',
    ba_title: '차이를 직접 밀어서 확인하세요', ba_before: '청소 전', ba_after: '청소 후',
    trust_title: '믿고 맡길 수 있는 이유', t1t: '신원 확인된 전문가', t1: '모든 파트너는 본인 인증과 심사를 거쳐요.',
    t2t: '방문 2일 전까지 무료 취소', t2: '일정이 바뀌어도 부담 없이.', t3t: '전후 사진 리포트', t3: '작업이 끝나면 사진으로 꼼꼼히 확인해요.',
    faq_title: '자주 묻는 질문',
    q1: '취소는 언제까지 무료인가요?', a1: '방문 2일 전까지는 전액 환불돼요.',
    q2: '어떤 결제 수단을 쓸 수 있나요?', a2: '신용·체크카드, 카카오페이, 네이버페이, 토스페이, 페이코, 삼성페이, 애플페이, 계좌이체, 가상계좌, 휴대폰 결제를 지원해요.',
    q3: '이사 청소 견적은 어떻게 받나요?', a3: '앱에서 집 정보를 입력하면 전문가 견적을 받아보고 마음에 드는 견적을 선택할 수 있어요.',
    q4: '청소 도구는 따로 준비해야 하나요?', a4: '전문가가 전용 장비와 세제를 가져와요.',
    band_title: '지금 앱을 내려받고 첫 예약 쿠폰을 받으세요', band_sub: '가입하면 바로 쓸 수 있는 쿠폰을 드려요.',
    partner_title: '청소 전문가로 함께해요', partner_sub: '원하는 지역과 시간에 일하고, 매주 수요일 정산받으세요.', partner_cta: '파트너 앱 받기',
    f_privacy: '개인정보처리방침', f_terms: '이용약관', f_delete: '계정 삭제 안내', f_support: '고객센터',
    c_ceo: '대표', c_reg: '사업자등록번호', c_mail: '통신판매업 신고', c_addr: '주소', c_privacy: '개인정보 보호책임자', c_host: '호스팅 제공자', c_bizcheck: '사업자정보확인',
    store_soon: '곧 출시',
  },
  en: {
    proof_title: 'Dahae in numbers', proof_homes: '{n} homes cleaned this month', proof_rating: 'Average {r} stars · {n} reviews',
    nav_services: 'Services', nav_how: 'How it works', nav_faq: 'FAQ', nav_partner: 'Become a pro',
    eyebrow: 'Book today, cleaned tomorrow', h1a: 'Hand over the chores,', h1b: 'keep the sparkle.',
    lead: 'Verified cleaning pros for everything from bathrooms to move-in cleans. See the price in the app and book in a minute.',
    cta_book: 'Book in the app', cta_prices: 'See prices', chip_a: '✨ Verified pros', chip_b: '💳 Easy payment',
    svc_title: 'Only the cleaning you need, clear prices', svc_sub: 'Prices below are live.', from: 'from', quote: 'On-site quote',
    how_title: 'One minute to book. We handle the rest.', how_1t: 'Pick a service', how_1: 'Choose the job and home size; the price appears instantly.',
    how_2t: 'Pick a date', how_2: 'Any time from tomorrow up to 60 days ahead.', how_3t: 'Pay your way', how_3: 'Card, KakaoPay, Naver Pay, Toss Pay and more.',
    how_4t: 'Visit & done', how_4: 'A pro cleans and you check the before/after photos.',
    ba_title: 'Slide to see the difference', ba_before: 'Before', ba_after: 'After',
    trust_title: 'Why people trust us', t1t: 'ID-verified pros', t1: 'Every partner passes identity checks and review.',
    t2t: 'Free cancellation up to 2 days before', t2: 'Plans change. No stress.', t3t: 'Before & after report', t3: 'Photos of every finished job.',
    faq_title: 'Frequently asked questions',
    q1: 'Until when can I cancel for free?', a1: 'Full refund up to 2 days before the visit.',
    q2: 'How can I pay?', a2: 'Credit/debit card, KakaoPay, Naver Pay, Toss Pay, PAYCO, Samsung Pay, Apple Pay, bank transfer, virtual account and phone billing.',
    q3: 'How do move-in quotes work?', a3: 'Describe your home in the app, receive quotes from pros and pick the one you like.',
    q4: 'Do I need to prepare supplies?', a4: 'No. Pros bring their own equipment and detergents.',
    band_title: 'Get the app and your first-booking coupons', band_sub: 'Coupons are ready the moment you sign up.',
    partner_title: 'Work with us as a cleaning pro', partner_sub: 'Choose your areas and hours; get paid every Wednesday.', partner_cta: 'Get the partner app',
    f_privacy: 'Privacy policy', f_terms: 'Terms of service', f_delete: 'Delete your account', f_support: 'Support',
    c_ceo: 'CEO', c_reg: 'Business reg. no.', c_mail: 'Mail-order reg.', c_addr: 'Address', c_privacy: 'Privacy officer', c_host: 'Hosting provider', c_bizcheck: 'Verify business registration',
    store_soon: 'Coming soon',
  },
  ja: {
    proof_title: 'ダヘの実績', proof_homes: '今月 {n}件のお宅を清掃しました', proof_rating: '平均評価 {r}点 · レビュー{n}件',
    nav_services: 'サービス', nav_how: 'ご利用方法', nav_faq: 'よくある質問', nav_partner: 'パートナー募集',
    eyebrow: '今日予約、明日訪問', h1a: '家事はおまかせ、', h1b: '輝く毎日を。',
    lead: '審査済みの清掃のプロが浴室から引越し清掃まで。アプリで料金を確認して1分で予約。',
    cta_book: 'アプリで予約', cta_prices: '料金を見る', chip_a: '✨ 審査済みのプロ', chip_b: '💳 かんたん決済',
    svc_title: '必要な清掃だけ、明確な料金で', svc_sub: '料金はリアルタイムで反映されます。', from: '〜', quote: '訪問見積',
    how_title: '予約は1分、あとはおまかせ', how_1t: 'サービス選択', how_1: '清掃内容と広さを選ぶとすぐに料金が出ます。',
    how_2t: '日程選択', how_2: '明日から60日先まで。', how_3t: 'かんたん決済', how_3: 'カード、KakaoPay、Naver Pay など。',
    how_4t: '訪問・完了', how_4: 'プロが清掃し、ビフォーアフター写真で確認。',
    ba_title: 'スライドして違いを確認', ba_before: 'ビフォー', ba_after: 'アフター',
    trust_title: '安心して任せられる理由', t1t: '本人確認済みのプロ', t1: 'すべてのパートナーが本人確認と審査を通過。',
    t2t: '訪問2日前まで無料キャンセル', t2: '予定が変わっても安心。', t3t: '作業写真レポート', t3: '終了後に写真で確認できます。',
    faq_title: 'よくある質問',
    q1: '無料キャンセルはいつまで？', a1: '訪問の2日前まで全額返金されます。',
    q2: '支払い方法は？', a2: 'カード、KakaoPay、Naver Pay、Toss Pay、PAYCO、Samsung Pay、Apple Pay、振込、仮想口座、携帯決済。',
    q3: '引越し清掃の見積は？', a3: 'アプリで住まいの情報を入力すると、プロの見積を比べて選べます。',
    q4: '道具の準備は必要？', a4: 'プロが専用の道具と洗剤を持参します。',
    band_title: 'アプリをダウンロードして初回クーポンを', band_sub: '登録するとすぐ使えるクーポンを差し上げます。',
    partner_title: '清掃のプロとして一緒に', partner_sub: '好きな地域と時間で働き、毎週水曜日に精算。', partner_cta: 'パートナーアプリ',
    f_privacy: 'プライバシーポリシー', f_terms: '利用規約', f_delete: 'アカウント削除', f_support: 'サポート',
    c_ceo: '代表', c_reg: '事業者登録番号', c_mail: '通信販売業届出', c_addr: '住所', c_privacy: '個人情報保護責任者', c_host: 'ホスティング事業者', c_bizcheck: '事業者情報の確認',
    store_soon: '近日公開',
  },
  zh: {
    proof_title: 'Dahae 的口碑', proof_homes: '本月已清洁 {n} 户', proof_rating: '平均 {r} 分 · {n} 条评价',
    nav_services: '服务', nav_how: '使用方法', nav_faq: '常见问题', nav_partner: '成为服务者',
    eyebrow: '今天预约，明天上门', h1a: '家务交给我们，', h1b: '生活焕然一新。',
    lead: '经过认证的保洁专家，从浴室到搬家保洁。应用内查看价格，一分钟完成预约。',
    cta_book: '在应用中预约', cta_prices: '查看价格', chip_a: '✨ 认证专家', chip_b: '💳 便捷支付',
    svc_title: '只选需要的保洁，价格透明', svc_sub: '以下价格实时更新。', from: '起', quote: '上门报价',
    how_title: '一分钟预约，其余交给我们', how_1t: '选择服务', how_1: '选择项目和面积，立即显示价格。',
    how_2t: '选择日期', how_2: '明天起 60 天内任选时间。', how_3t: '便捷支付', how_3: '银行卡、KakaoPay、Naver Pay、Toss Pay 等。',
    how_4t: '上门完成', how_4: '专家上门保洁，并提供前后对比照片。',
    ba_title: '滑动查看前后对比', ba_before: '保洁前', ba_after: '保洁后',
    trust_title: '值得信赖的理由', t1t: '实名认证专家', t1: '所有服务者均通过身份认证与审核。',
    t2t: '上门前 2 天可免费取消', t2: '计划有变也不用担心。', t3t: '前后照片报告', t3: '完成后用照片确认每个细节。',
    faq_title: '常见问题',
    q1: '什么时候可以免费取消？', a1: '上门前 2 天内全额退款。',
    q2: '支持哪些支付方式？', a2: '银行卡、KakaoPay、Naver Pay、Toss Pay、PAYCO、Samsung Pay、Apple Pay、转账、虚拟账户、手机支付。',
    q3: '搬家保洁如何报价？', a3: '在应用中填写房屋信息，即可比较专家报价并选择。',
    q4: '需要准备工具吗？', a4: '不需要，专家自带设备和清洁剂。',
    band_title: '下载应用，领取首单优惠券', band_sub: '注册即可使用优惠券。',
    partner_title: '成为保洁专家', partner_sub: '自选区域和时间，每周三结算。', partner_cta: '下载服务者应用',
    f_privacy: '隐私政策', f_terms: '服务条款', f_delete: '删除账号', f_support: '客服',
    c_ceo: '代表', c_reg: '营业执照号', c_mail: '电商备案', c_addr: '地址', c_privacy: '个人信息负责人', c_host: '托管服务商', c_bizcheck: '核实经营者信息',
    store_soon: '即将上线',
  },
  vi: {
    proof_title: 'Dahae qua con số', proof_homes: 'Tháng này đã dọn {n} nhà', proof_rating: 'Trung bình {r} sao · {n} đánh giá',
    nav_services: 'Dịch vụ', nav_how: 'Cách dùng', nav_faq: 'Hỏi đáp', nav_partner: 'Trở thành đối tác',
    eyebrow: 'Đặt hôm nay, đến ngày mai', h1a: 'Việc nhà để chúng tôi lo,', h1b: 'bạn giữ niềm vui.',
    lead: 'Chuyên gia vệ sinh đã xác minh, từ phòng tắm đến dọn nhà mới. Xem giá trong ứng dụng và đặt trong một phút.',
    cta_book: 'Đặt trong ứng dụng', cta_prices: 'Xem giá', chip_a: '✨ Chuyên gia xác minh', chip_b: '💳 Thanh toán dễ',
    svc_title: 'Chỉ dịch vụ bạn cần, giá rõ ràng', svc_sub: 'Giá được cập nhật trực tiếp.', from: 'từ', quote: 'Báo giá tại nhà',
    how_title: 'Một phút để đặt, phần còn lại chúng tôi lo', how_1t: 'Chọn dịch vụ', how_1: 'Chọn công việc và diện tích, giá hiện ngay.',
    how_2t: 'Chọn ngày', how_2: 'Từ ngày mai đến 60 ngày tới.', how_3t: 'Thanh toán', how_3: 'Thẻ, KakaoPay, Naver Pay, Toss Pay...',
    how_4t: 'Đến & xong', how_4: 'Chuyên gia dọn dẹp, bạn xem ảnh trước/sau.',
    ba_title: 'Kéo để thấy khác biệt', ba_before: 'Trước', ba_after: 'Sau',
    trust_title: 'Vì sao bạn yên tâm', t1t: 'Chuyên gia đã xác minh', t1: 'Mọi đối tác đều qua xác minh danh tính và xét duyệt.',
    t2t: 'Hủy miễn phí trước 2 ngày', t2: 'Thay đổi kế hoạch không lo.', t3t: 'Báo cáo ảnh trước/sau', t3: 'Ảnh cho mỗi lần hoàn thành.',
    faq_title: 'Câu hỏi thường gặp',
    q1: 'Hủy miễn phí đến khi nào?', a1: 'Hoàn tiền đầy đủ đến 2 ngày trước lịch hẹn.',
    q2: 'Thanh toán thế nào?', a2: 'Thẻ, KakaoPay, Naver Pay, Toss Pay, PAYCO, Samsung Pay, Apple Pay, chuyển khoản, tài khoản ảo, thanh toán qua điện thoại.',
    q3: 'Báo giá dọn nhà mới thế nào?', a3: 'Nhập thông tin nhà trong ứng dụng, nhận báo giá và chọn.',
    q4: 'Tôi có cần chuẩn bị dụng cụ?', a4: 'Không, chuyên gia mang theo thiết bị và chất tẩy rửa.',
    band_title: 'Tải ứng dụng, nhận phiếu cho lần đặt đầu', band_sub: 'Phiếu dùng ngay khi đăng ký.',
    partner_title: 'Trở thành chuyên gia vệ sinh', partner_sub: 'Chọn khu vực và giờ làm, nhận tiền mỗi thứ Tư.', partner_cta: 'Tải ứng dụng đối tác',
    f_privacy: 'Chính sách bảo mật', f_terms: 'Điều khoản', f_delete: 'Xóa tài khoản', f_support: 'Hỗ trợ',
    c_ceo: 'Đại diện', c_reg: 'Mã số kinh doanh', c_mail: 'Đăng ký bán hàng', c_addr: 'Địa chỉ', c_privacy: 'Phụ trách bảo mật', c_host: 'Nhà cung cấp hosting', c_bizcheck: 'Tra cứu thông tin doanh nghiệp',
    store_soon: 'Sắp ra mắt',
  },
};

// Tile tints per service (recognition); the 3D art itself is palette-coloured.
const HUES = { studio: '#1E9EBA', kitchen: '#FF7A59', bathroom: '#19C39A', mattress: '#8B5CF6', aircon: '#0EA5E9', sofa: '#E11D74', move_out: '#F59E0B', move_in: '#10B981' };
// Service code -> rendered art in /assets/icons3d/ (ids follow the app's Icon3D ids).
const ART = { move_in: 'svc_move', move_out: 'svc_move' };
const art = (code) => `/assets/icons3d/${ART[code] || (HUES[code] ? `svc_${code}` : 'svc_studio')}.webp`;

const store = { get(k) { try { return localStorage.getItem(k); } catch { return null; } }, set(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode */ } } };

function pickLang() {
  const saved = store.get('site.lang');
  if (saved && LANGS[saved]) return saved;
  const nav = (navigator.language || 'ko').toLowerCase().split('-')[0];
  return LANGS[nav] ? nav : 'ko';
}

let lang = pickLang();
let services = [];
let names = {};
let webCopy = {};
function applyWebCopy() {
  const per = webCopy[lang] || webCopy.en || {};
  document.querySelectorAll("[data-web-t]").forEach((el) => { if (per[el.dataset.webT]) el.textContent = per[el.dataset.webT]; });
}
fetch("assets/web_copy.json").then((r) => r.json()).then((j) => { webCopy = j; applyWebCopy(); }).catch(() => {});
const text = (k) => (COPY[lang] && COPY[lang][k]) || COPY.en[k] || COPY.ko[k] || '';
const won = (n) => new Intl.NumberFormat(lang === 'ko' ? 'ko-KR' : lang, { style: 'currency', currency: 'KRW', maximumFractionDigits: 0 }).format(n);

function applyCopy() {
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-t]').forEach((el) => { el.textContent = text(el.dataset.t); });
  renderServices();
  renderProof();
  applyWebCopy();
}

// Real numbers from /v1/public/proof. The API nulls any count that is too small to persuade; a null hides its line.
let proof = null;
function renderProof() {
  const section = document.getElementById('proof');
  if (!section || !proof) return;
  const { homes_this_month: homes, rating, review_count: count, reviews = [] } = proof;
  if (homes == null && rating == null && reviews.length === 0) return;
  document.getElementById('proof-homes').textContent = homes == null ? '' : text('proof_homes').replace('{n}', homes);
  document.getElementById('proof-rating').textContent = rating == null || count == null ? '' : text('proof_rating').replace('{r}', rating.toFixed(1)).replace('{n}', count);
  const list = document.getElementById('proof-reviews');
  list.replaceChildren(...reviews.map((r) => { const li = document.createElement('li'); li.textContent = `★${r.rating} ${r.body} — ${r.name}`; return li; }));
  section.hidden = false;
}

function fromPrice(s) {
  const p = s.pricing || {};
  if (p.type === 'fixed') return p.price;
  if (p.type === 'unit' && p.units && p.units.length) return Math.min(...p.units.map((u) => u.price));
  return null;
}

function renderServices() {
  const grid = document.getElementById('services-grid');
  if (!grid) return;
  const list = services.length ? services : Object.keys(HUES).map((code) => ({ code, pricing: {} }));
  const per = names[lang] || names.en || {};
  grid.innerHTML = '';
  for (const s of list) {
    const n = per[s.code] || {};
    const price = fromPrice(s);
    const card = document.createElement('article');
    card.className = 'card reveal in';
    card.style.setProperty('--hue', HUES[s.code] || 'var(--brand)');
    card.innerHTML = `<div class="shine"></div>
      <div class="glyph" aria-hidden="true"><img class="icon3d" src="${art(s.code)}" alt="" width="72" height="72" loading="lazy" decoding="async"></div>
      <h3></h3><p></p><div class="price"></div>`;
    card.querySelector('h3').textContent = n.name || s.code;
    card.querySelector('p').textContent = n.desc || '';
    const priceEl = card.querySelector('.price');
    if (price != null) {
      priceEl.textContent = won(price) + ' ';
      const small = document.createElement('small');
      small.textContent = text('from');
      priceEl.append(small);
    } else if (s.pricing && s.pricing.type) {
      priceEl.textContent = text('quote');
    }
    tilt(card);
    grid.append(card);
  }
}

function tilt(el) {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height;
    el.style.transform = `perspective(900px) rotateX(${(0.5 - y) * 12}deg) rotateY(${(x - 0.5) * 14}deg) translateZ(6px)`;
    el.style.setProperty('--mx', `${x * 100}%`);
    el.style.setProperty('--my', `${y * 100}%`);
  });
  el.addEventListener('pointerleave', () => { el.style.transform = ''; });
}

function setTheme(t) {
  document.documentElement.dataset.theme = t;
  store.set('site.theme', t);
  const b = document.getElementById('theme');
  if (b) { b.textContent = t === 'light' ? '🌙' : '☀️'; b.setAttribute('aria-label', t === 'light' ? 'Dark mode' : 'Light mode'); }
}

async function getJson(path) {
  const r = await fetch(API + path, { headers: { Accept: 'application/json' } });
  if (!r.ok) throw new Error(String(r.status));
  return r.json();
}

function applyBrand(b) {
  if (!b) return;
  if (b.primary_color) document.documentElement.style.setProperty('--brand', b.primary_color);
  if (b.name) {
    document.querySelectorAll('[data-brand-name]').forEach((el) => { el.textContent = b.name; });
    document.title = document.title.replace(/^[^·|]+/, `${b.name} `);
  }
  if (b.logo_url) document.querySelectorAll('.logo-mark').forEach((el) => { el.innerHTML = ''; el.style.background = 'none'; const img = new Image(); img.alt = ''; img.src = b.logo_url; el.append(img); });
  if (b.support_phone) document.querySelectorAll('[data-support-phone]').forEach((el) => { el.textContent = b.support_phone; el.href = `tel:${b.support_phone.replace(/[^0-9+]/g, '')}`; });
  if (b.support_email) document.querySelectorAll('[data-support-email]').forEach((el) => { el.textContent = b.support_email; el.href = `mailto:${b.support_email}`; });
  for (const key of ['app_store_url', 'play_store_url', 'partner_play_store_url', 'partner_app_store_url']) {
    if (b[key]) document.querySelectorAll(`[data-link="${key}"]`).forEach((a) => { a.href = b[key]; a.removeAttribute('aria-disabled'); a.querySelector('[data-t="store_soon"]')?.remove(); });
  }
  // Chat buttons (Kakao channel, Naver Talk Talk) appear only once the owner has configured them.
  for (const key of ['kakao_channel_url', 'naver_talk_url']) {
    if (b[key]) document.querySelectorAll(`[data-link="${key}"]`).forEach((a) => { a.href = b[key]; a.hidden = false; });
  }
  const c = b.company || {};
  const box = document.getElementById('company');
  if (box) {
    box.innerHTML = '';
    const rows = [[b.name || c.legal_name, ''], [c.legal_name, ''], [c.ceo, 'c_ceo'], [c.registration_no, 'c_reg'], [c.mail_order_no, 'c_mail'], [c.address, 'c_addr'], [c.privacy_officer, 'c_privacy'], [c.hosting_provider, 'c_host']];
    const seen = new Set();
    for (const [v, k] of rows) {
      if (!v || seen.has(v)) continue;
      seen.add(v);
      const span = document.createElement('span');
      span.textContent = k ? `${text(k)} ${v}` : v;
      box.append(span);
    }
  }
  // 전자상거래법 제10조: link to the FTC lookup so a buyer can verify the seller's registration.
  const regNo = String(c.registration_no || '').replace(/\D/g, '');
  if (regNo.length === BIZ_NO_DIGITS) {
    document.querySelectorAll('[data-bizcheck]').forEach((a) => { a.href = FTC_LOOKUP + regNo; a.hidden = false; });
  }
  document.querySelectorAll('[data-fill]').forEach((el) => {
    const v = el.dataset.fill.split('.').reduce((o, k) => (o ? o[k] : undefined), b);
    if (v) el.textContent = v;
  });
}

function beforeAfter() {
  const ba = document.querySelector('.ba');
  if (!ba) return;
  const input = ba.querySelector('input');
  const set = () => ba.style.setProperty('--split', `${input.value}%`);
  input.addEventListener('input', set);
  set();
}

function reveal() {
  const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: 0.12 });
  document.querySelectorAll('.reveal').forEach((el) => io.observe(el));
}

function langPicker() {
  const sel = document.getElementById('lang');
  if (!sel) return;
  for (const [code, label] of Object.entries(LANGS)) {
    const o = document.createElement('option');
    o.value = code; o.textContent = label;
    sel.append(o);
  }
  sel.value = lang;
  sel.addEventListener('change', () => { lang = sel.value; store.set('site.lang', lang); applyCopy(); });
}

// The 3D hero (three.js) loads only where it is cheap enough and motion is welcome; everywhere else the CSS illustration stays.
function loadHeroIfCapable() {
  if (!document.getElementById('hero-3d') || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if ((navigator.hardwareConcurrency || 4) < 4 || (navigator.deviceMemory || 4) < 4 || navigator.connection?.saveData) return;
  import('./hero3d.js').catch(() => { /* CSS illustration remains */ });
}

// First-touch campaign params, kept for this tab only (sessionStorage: no cookie, nothing shared).
// Appended to /app/ links so the booking app can read them on signup.
const ATTR_KEYS = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term', 'ref'];
function captureAttribution() {
  try {
    const saved = JSON.parse(sessionStorage.getItem('mk.attr') || 'null');
    if (saved) return saved;
    const q = new URLSearchParams(location.search);
    const found = Object.fromEntries(ATTR_KEYS.filter((k) => q.get(k)).map((k) => [k, q.get(k).slice(0, 80)]));
    if (!Object.keys(found).length) return null;
    sessionStorage.setItem('mk.attr', JSON.stringify(found));
    return found;
  } catch { return null; }
}
function decorateAppLinks(attr) {
  if (!attr) return;
  document.querySelectorAll('a[href^="/app/"]').forEach((a) => {
    const u = new URL(a.getAttribute('href'), location.href);
    for (const [k, v] of Object.entries(attr)) if (!u.searchParams.has(k)) u.searchParams.set(k, v);
    a.setAttribute('href', u.pathname + u.search + u.hash);
  });
}

document.addEventListener('DOMContentLoaded', async () => {
  setTheme(store.get('site.theme') || 'dark');
  loadHeroIfCapable();
  decorateAppLinks(captureAttribution());
  document.getElementById('theme')?.addEventListener('click', () => setTheme(document.documentElement.dataset.theme === 'light' ? 'dark' : 'light'));
  langPicker();
  beforeAfter();
  reveal();
  const year = document.getElementById('year');
  if (year) year.textContent = String(new Date().getFullYear());
  const [n, svc, brand] = await Promise.allSettled([fetch('/assets/services.json').then((r) => r.json()), getJson('/v1/services'), getJson('/v1/brand')]);
  if (n.status === 'fulfilled') names = n.value;
  if (svc.status === 'fulfilled' && Array.isArray(svc.value)) services = svc.value;
  applyCopy();
  if (brand.status === 'fulfilled') applyBrand(brand.value);
  try { proof = await getJson('/v1/public/proof'); renderProof(); } catch { /* optional section stays hidden */ }
});
