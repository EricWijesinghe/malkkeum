# -*- coding: utf-8 -*-
# Dahae More tab (U6). Columns: ko (source), en, ja, zh (Simplified), vi. Extra languages in X (9 codes).
# Placeholder: {brand} is the app's display name. Provider names stay as the brands write them.
S = {
  "moreGreeting": ["오늘도 집안일은 {brand}에게 맡기세요", "Leave today's chores to {brand}", "今日も家事は{brand}におまかせください", "今天的家务也交给{brand}吧", "Hôm nay cũng hãy giao việc nhà cho {brand}"],
  "moreBrandTips": ["{brand} 팁", "{brand} tips", "{brand}のコツ", "{brand}小贴士", "Mẹo từ {brand}"],
  "moreContact": ["문의하기", "Contact us", "お問い合わせ", "联系我们", "Liên hệ"],
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
