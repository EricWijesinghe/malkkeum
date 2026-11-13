# -*- coding: utf-8 -*-
# Dahae More tab (U6). Columns: ko (source), en, ja, zh (Simplified), vi. Extra languages in X (9 codes).
# Placeholder: {brand} is the app's display name. Provider names stay as the brands write them.
S = {
  "moreGreeting": ["오늘도 집안일은 {brand}에 맡기세요.", "Leave today's chores to {brand}.", "今日も家事は{brand}におまかせください", "今天的家务也交给{brand}吧", "Hôm nay cũng hãy giao việc nhà cho {brand}"],
  "moreBrandTips": ["{brand} 팁", "{brand} tips", "{brand}のコツ", "{brand}小贴士", "Mẹo từ {brand}"],
  "moreContact": ["상담하기", "Chat with us", "相談する", "在线咨询", "Tư vấn"],
  "moreVersionInfo": ["버전 정보", "Version", "バージョン情報", "版本信息", "Thông tin phiên bản"],
  "payAvailableTitle": ["사용할 수 있는 결제수단", "Available payment methods", "利用できる支払い方法", "可用的付款方式", "Phương thức thanh toán khả dụng"],
  "accountLoginKakao": ["카카오", "Kakao", "Kakao", "Kakao", "Kakao"],
  "accountLoginNaver": ["네이버", "Naver", "Naver", "Naver", "Naver"],
  "accountLoginApple": ["Apple", "Apple", "Apple", "Apple", "Apple"],
  "accountLoginGoogle": ["Google", "Google", "Google", "Google", "Google"],
}

_BRANDS = {"accountLoginKakao": "Kakao", "accountLoginNaver": "Naver", "accountLoginApple": "Apple", "accountLoginGoogle": "Google"}

X = {
  "fil": {
    "moreGreeting": "Ipaubaya sa {brand} ang gawaing-bahay ngayon", "moreBrandTips": "Mga tip ng {brand}",
    "moreContact": "Makipag-ugnayan", "moreVersionInfo": "Bersyon", "payAvailableTitle": "Mga magagamit na paraan ng bayad",
  },
  "id": {
    "moreGreeting": "Serahkan pekerjaan rumah hari ini kepada {brand}", "moreBrandTips": "Tips {brand}",
    "moreContact": "Hubungi kami", "moreVersionInfo": "Info versi", "payAvailableTitle": "Metode pembayaran tersedia",
  },
  "km": {
    "moreGreeting": "ថ្ងៃនេះក៏ទុកកិច្ចការផ្ទះឱ្យ {brand} ដែរ", "moreBrandTips": "គន្លឹះពី {brand}",
    "moreContact": "ទាក់ទងយើង", "moreVersionInfo": "ព័ត៌មានកំណែ", "payAvailableTitle": "វិធីបង់ប្រាក់ដែលអាចប្រើបាន",
  },
  "mn": {
    "moreGreeting": "Өнөөдөр ч гэрийн ажлаа {brand}-д даатгаарай", "moreBrandTips": "{brand} зөвлөгөө",
    "moreContact": "Холбоо барих", "moreVersionInfo": "Хувилбарын мэдээлэл", "payAvailableTitle": "Боломжтой төлбөрийн хэрэгсэл",
  },
  "ne": {
    "moreGreeting": "आज पनि घरको काम {brand}लाई छोड्नुहोस्", "moreBrandTips": "{brand} सुझावहरू",
    "moreContact": "सम्पर्क गर्नुहोस्", "moreVersionInfo": "संस्करण जानकारी", "payAvailableTitle": "उपलब्ध भुक्तानी विधिहरू",
  },
  "ru": {
    "moreGreeting": "Доверьте домашние дела {brand} и сегодня", "moreBrandTips": "Советы {brand}",
    "moreContact": "Связаться с нами", "moreVersionInfo": "Версия", "payAvailableTitle": "Доступные способы оплаты",
  },
  "si": {
    "moreGreeting": "අදත් ගෙදර වැඩ {brand} වෙත භාර දෙන්න", "moreBrandTips": "{brand} ඉඟි",
    "moreContact": "අප අමතන්න", "moreVersionInfo": "අනුවාද තොරතුරු", "payAvailableTitle": "ලබා ගත හැකි ගෙවීම් ක්‍රම",
  },
  "th": {
    "moreGreeting": "วันนี้ก็ฝากงานบ้านไว้กับ {brand} นะคะ", "moreBrandTips": "เคล็ดลับจาก {brand}",
    "moreContact": "ติดต่อเรา", "moreVersionInfo": "ข้อมูลเวอร์ชัน", "payAvailableTitle": "วิธีชำระเงินที่ใช้ได้",
  },
  "uz": {
    "moreGreeting": "Bugun ham uy ishlarini {brand}ga topshiring", "moreBrandTips": "{brand} maslahatlari",
    "moreContact": "Biz bilan bogʻlanish", "moreVersionInfo": "Versiya haqida", "payAvailableTitle": "Mavjud toʻlov usullari",
  },
}
for _texts in X.values():
  _texts.update(_BRANDS)

# FX-c (PDF p05, p23-p27): More header and strip, coupon sections, payment note, account header, address note, FAQ chips.
_FXC = {
  "moreNameSuffix": ["{name}님", "{name}", "{name}様", "{name}", "{name}"],
  "moreCouponCount": ["{n}장", "{n}", "{n}枚", "{n}张", "{n}"],
  "couponsAvailableTitle": ["사용 가능한 쿠폰", "Available coupons", "使えるクーポン", "可用优惠券", "Phiếu có thể dùng"],
  "couponsUsedTitle": ["사용한 쿠폰", "Used coupons", "使用済みクーポン", "已用优惠券", "Phiếu đã dùng"],
  "couponsNote": ["※ 예약 1건에 쿠폰 1장만 쓸 수 있어요.", "※ One coupon per booking.", "※ 予約1件につきクーポンは1枚まで使えます。", "※ 每笔预约仅可使用一张优惠券。", "※ Mỗi lượt đặt chỉ dùng được 1 phiếu."],
  "payCardNote": ["※ 카드 번호는 {brand}에 저장되지 않고 결제대행사가 안전하게 보관해요.", "※ Card numbers are never stored by {brand}; the payment provider keeps them securely.", "※ カード番号は{brand}に保存されず、決済代行会社が安全に保管します。", "※ 卡号不会保存在{brand}，由支付服务商安全保管。", "※ Số thẻ không được lưu tại {brand}; đơn vị thanh toán lưu giữ an toàn."],
  "accountJoined": ["{date} 가입", "Joined {date}", "{date} 登録", "{date} 注册", "Tham gia {date}"],
  "addressPyeongNote": ["평수는 꼭 입력해 주세요. 원룸 청소는 {max}평 이하만 예약할 수 있어요.", "Size is required. Studio cleaning is for homes up to {max} pyeong.", "広さは必ず入力してください。ワンルーム清掃は{max}坪以下のみ予約できます。", "请务必填写面积。单间清洁仅限{max}坪以下。", "Bắt buộc nhập diện tích. Dọn phòng studio chỉ áp dụng cho nhà tối đa {max} pyeong."],
  "faqAll": ["전체", "All", "すべて", "全部", "Tất cả"],
  "faqCat_booking": ["예약·변경", "Booking & changes", "予約・変更", "预约·变更", "Đặt lịch · Thay đổi"],
  "faqCat_payment": ["결제·쿠폰", "Payment & coupons", "支払い・クーポン", "支付·优惠券", "Thanh toán · Phiếu"],
  "faqCat_move": ["이사·입주", "Move-in & move-out", "引越し・入居", "搬家·入住", "Chuyển nhà"],
}
S.update(_FXC)
# First column re-translates moreContact ("상담하기"): the chat row, not a generic contact form.
_FXC_X = {
  "fil": ["Kumonsulta", "{name}", "{n}", "Magagamit na kupon", "Nagamit na kupon", "※ Isang kupon lang bawat booking.", "※ Hindi itinatago ng {brand} ang numero ng card; ligtas itong iniingatan ng payment provider.", "Sumali {date}", "Kailangan ang laki. Ang studio cleaning ay para sa bahay na hanggang {max} pyeong.", "Lahat", "Booking at pagbabago", "Bayad at kupon", "Paglipat"],
  "id": ["Konsultasi", "{name}", "{n}", "Kupon tersedia", "Kupon terpakai", "※ Satu kupon per pesanan.", "※ Nomor kartu tidak disimpan oleh {brand}; penyedia pembayaran menyimpannya dengan aman.", "Bergabung {date}", "Ukuran wajib diisi. Pembersihan studio hanya untuk hunian hingga {max} pyeong.", "Semua", "Pemesanan & perubahan", "Pembayaran & kupon", "Pindahan"],
  "km": ["ពិគ្រោះយោបល់", "{name}", "{n}", "គូប៉ុងដែលអាចប្រើបាន", "គូប៉ុងដែលបានប្រើ", "※ គូប៉ុងមួយសម្រាប់ការកក់មួយ។", "※ លេខកាតមិនត្រូវបានរក្សាទុកដោយ {brand} ទេ អ្នកផ្តល់សេវាបង់ប្រាក់រក្សាទុកដោយសុវត្ថិភាព។", "ចូលរួម {date}", "ត្រូវបញ្ចូលទំហំ។ ការសម្អាតបន្ទប់ស្ទូឌីយោសម្រាប់ផ្ទះមិនលើស {max} pyeong។", "ទាំងអស់", "ការកក់ និងការផ្លាស់ប្តូរ", "ការបង់ប្រាក់ និងគូប៉ុង", "ការផ្លាស់ទីលំនៅ"],
  "mn": ["Зөвлөгөө авах", "{name}", "{n}", "Ашиглах боломжтой купон", "Ашигласан купон", "※ Нэг захиалгад нэг купон.", "※ Картын дугаарыг {brand} хадгалдаггүй; төлбөрийн үйлчилгээ үзүүлэгч аюулгүй хадгална.", "{date} бүртгүүлсэн", "Талбайг заавал оруулна уу. Студи цэвэрлэгээ {max} пёнгоос ихгүй байранд.", "Бүгд", "Захиалга, өөрчлөлт", "Төлбөр, купон", "Нүүлт, орох"],
  "ne": ["परामर्श लिनुहोस्", "{name}", "{n}", "प्रयोग गर्न मिल्ने कुपन", "प्रयोग गरिएका कुपन", "※ एउटा बुकिङमा एउटा कुपन मात्र।", "※ कार्ड नम्बर {brand} मा सुरक्षित गरिँदैन; भुक्तानी सेवा प्रदायकले सुरक्षित राख्छ।", "{date} मा सामेल", "आकार अनिवार्य छ। स्टुडियो सफाई {max} प्योङसम्मका घरका लागि मात्र।", "सबै", "बुकिङ र परिवर्तन", "भुक्तानी र कुपन", "सर्ने र बस्ने"],
  "ru": ["Консультация", "{name}", "{n}", "Доступные купоны", "Использованные купоны", "※ Один купон на заказ.", "※ {brand} не хранит номера карт: их надёжно хранит платёжный провайдер.", "С нами с {date}", "Укажите площадь. Уборка студии — только для жилья до {max} пхён.", "Все", "Заказ и изменения", "Оплата и купоны", "Переезд и заселение"],
  "si": ["උපදෙස් ලබා ගන්න", "{name}", "{n}", "භාවිත කළ හැකි කූපන්", "භාවිත කළ කූපන්", "※ එක් වෙන්කිරීමකට එක් කූපනයක් පමණි.", "※ කාඩ්පත් අංක {brand} හි ගබඩා නොකෙරේ; ගෙවීම් සේවා සපයන්නා ආරක්ෂිතව තබා ගනී.", "{date} සම්බන්ධ විය", "ප්‍රමාණය අනිවාර්යයි. ස්ටුඩියෝ පිරිසිදු කිරීම {max} pyeong දක්වා නිවෙස් සඳහා පමණි.", "සියල්ල", "වෙන්කිරීම් සහ වෙනස්කම්", "ගෙවීම් සහ කූපන්", "නිවාස මාරුව"],
  "th": ["ปรึกษา", "{name}", "{n}", "คูปองที่ใช้ได้", "คูปองที่ใช้แล้ว", "※ ใช้คูปองได้ 1 ใบต่อการจอง 1 ครั้ง", "※ {brand} ไม่เก็บหมายเลขบัตร ผู้ให้บริการชำระเงินเก็บรักษาอย่างปลอดภัย", "สมัครเมื่อ {date}", "ต้องกรอกขนาดพื้นที่ ทำความสะอาดห้องสตูดิโอได้เฉพาะไม่เกิน {max} พยอง", "ทั้งหมด", "การจองและการเปลี่ยนแปลง", "การชำระเงินและคูปอง", "ย้ายเข้า·ย้ายออก"],
  "uz": ["Maslahat olish", "{name}", "{n}", "Mavjud kuponlar", "Ishlatilgan kuponlar", "※ Har bir buyurtmaga bitta kupon.", "※ Karta raqami {brand}da saqlanmaydi; toʻlov provayderi uni xavfsiz saqlaydi.", "{date} roʻyxatdan oʻtgan", "Maydonni kiritish shart. Studiya tozalash faqat {max} pxyongacha boʻlgan uylar uchun.", "Hammasi", "Buyurtma va oʻzgartirish", "Toʻlov va kuponlar", "Koʻchish"],
}
for _code, _vals in _FXC_X.items():
  X[_code].update(zip(["moreContact", *_FXC], _vals))
