# Dahae chat (U4): list header, quote card rows and the quote-thread quick replies. Columns: ko, en, ja, zh, vi.
S = {
  "chatHoursTitle": ["상담 운영시간", "Chat hours", "相談受付時間", "咨询时间", "Giờ tư vấn"],
  "chatReplyFast": ["보통 10분 내 답변", "Usually replies within 10 min", "通常10分以内に返信", "通常10分钟内回复", "Thường trả lời trong 10 phút"],
  "quoteVisit": ["방문 일정", "Visit", "訪問日程", "上门时间", "Lịch đến"],
  "quoteKind": ["유형", "Type", "タイプ", "类型", "Loại"],
  "quotePayAmount": ["예약금 결제 {amount}", "Pay deposit {amount}", "予約金を支払う {amount}", "支付定金 {amount}", "Trả cọc {amount}"],
  "quoteSuperseded": ["새 견적으로 바뀌었어요", "Replaced by a newer quote", "新しい見積に更新されました", "已被新报价取代", "Đã có báo giá mới hơn"],
  "quick_quote": ["견적이 궁금해요", "About the quote", "見積について", "想了解报价", "Hỏi về báo giá"],
  "cQuoteOverride": ["예상 금액과 크게 다른 견적 보내기", "Send a quote far from the estimate", "概算と大きく異なる見積を送る", "发送与预估差距很大的报价", "Gửi báo giá chênh lệch lớn so với ước tính"],
  "quick_reschedule": ["일정 변경할래요", "Change the schedule", "日程を変更したい", "想改时间", "Muốn đổi lịch"],
}

# Extra languages (fil, id, km, mn, ne, ru, si, th, uz). Same keys as S.
X = {
  "fil": {"cQuoteOverride": "Ipadala ang quote na malayo sa tantya", "chatHoursTitle": "Oras ng chat", "chatReplyFast": "Karaniwang sumasagot sa loob ng 10 minuto", "quoteVisit": "Pagbisita", "quoteKind": "Uri", "quotePayAmount": "Bayaran ang deposito {amount}", "quoteSuperseded": "Pinalitan ng mas bagong quote", "quick_quote": "Tungkol sa quote", "quick_reschedule": "Palitan ang iskedyul"},
  "id": {"cQuoteOverride": "Kirim penawaran yang jauh dari perkiraan", "chatHoursTitle": "Jam layanan chat", "chatReplyFast": "Biasanya membalas dalam 10 menit", "quoteVisit": "Kunjungan", "quoteKind": "Jenis", "quotePayAmount": "Bayar DP {amount}", "quoteSuperseded": "Diganti penawaran yang lebih baru", "quick_quote": "Tanya soal penawaran", "quick_reschedule": "Ubah jadwal"},
  "km": {"cQuoteOverride": "ផ្ញើសម្រង់តម្លៃដែលខុសឆ្ងាយពីការប៉ាន់ស្មាន", "chatHoursTitle": "ម៉ោងពិគ្រោះ", "chatReplyFast": "ជាធម្មតាឆ្លើយក្នុង 10 នាទី", "quoteVisit": "ការមកដល់", "quoteKind": "ប្រភេទ", "quotePayAmount": "បង់ប្រាក់កក់ {amount}", "quoteSuperseded": "ត្រូវបានជំនួសដោយសម្រង់តម្លៃថ្មី", "quick_quote": "សួរអំពីសម្រង់តម្លៃ", "quick_reschedule": "ប្តូរកាលវិភាគ"},
  "mn": {"cQuoteOverride": "Тооцооноос их зөрүүтэй үнийн санал илгээх", "chatHoursTitle": "Зөвлөгөөний цаг", "chatReplyFast": "Ихэвчлэн 10 минутын дотор хариулна", "quoteVisit": "Ирэх хуваарь", "quoteKind": "Төрөл", "quotePayAmount": "Урьдчилгаа төлөх {amount}", "quoteSuperseded": "Шинэ үнийн саналаар солигдсон", "quick_quote": "Үнийн саналын талаар", "quick_reschedule": "Хуваарь өөрчлөх"},
  "ne": {"cQuoteOverride": "अनुमानभन्दा धेरै फरक उद्धरण पठाउनुहोस्", "chatHoursTitle": "परामर्श समय", "chatReplyFast": "प्रायः १० मिनेटभित्र जवाफ", "quoteVisit": "भ्रमण", "quoteKind": "प्रकार", "quotePayAmount": "अग्रिम भुक्तानी {amount}", "quoteSuperseded": "नयाँ उद्धरणले बदलियो", "quick_quote": "उद्धरणबारे", "quick_reschedule": "समय परिवर्तन गर्न चाहन्छु"},
  "ru": {"cQuoteOverride": "Отправить смету, сильно отличающуюся от оценки", "chatHoursTitle": "Часы работы чата", "chatReplyFast": "Обычно отвечаем за 10 минут", "quoteVisit": "Визит", "quoteKind": "Тип", "quotePayAmount": "Оплатить предоплату {amount}", "quoteSuperseded": "Заменено новой сметой", "quick_quote": "Вопрос по смете", "quick_reschedule": "Изменить время"},
  "si": {"cQuoteOverride": "ඇස්තමේන්තුවෙන් බොහෝ වෙනස් මිල ගණනක් යවන්න", "chatHoursTitle": "උපදේශන වේලාව", "chatReplyFast": "සාමාන්‍යයෙන් මිනිත්තු 10ක් ඇතුළත පිළිතුරු", "quoteVisit": "පැමිණීම", "quoteKind": "වර්ගය", "quotePayAmount": "අත්තිකාරම ගෙවන්න {amount}", "quoteSuperseded": "නව මිල ගණනකින් ප්‍රතිස්ථාපනය විය", "quick_quote": "මිල ගණන ගැන", "quick_reschedule": "කාලසටහන වෙනස් කරන්න"},
  "th": {"cQuoteOverride": "ส่งใบเสนอราคาที่ต่างจากราคาประเมินมาก", "chatHoursTitle": "เวลาให้คำปรึกษา", "chatReplyFast": "ปกติตอบภายใน 10 นาที", "quoteVisit": "วันเข้าบริการ", "quoteKind": "ประเภท", "quotePayAmount": "ชำระมัดจำ {amount}", "quoteSuperseded": "มีใบเสนอราคาใหม่แทนแล้ว", "quick_quote": "สอบถามใบเสนอราคา", "quick_reschedule": "ขอเปลี่ยนนัด"},
  "uz": {"cQuoteOverride": "Taxmindan ancha farq qiladigan narx taklifini yuborish", "chatHoursTitle": "Maslahat vaqti", "chatReplyFast": "Odatda 10 daqiqada javob beramiz", "quoteVisit": "Tashrif", "quoteKind": "Turi", "quotePayAmount": "Oldindan toʻlov {amount}", "quoteSuperseded": "Yangi narx taklifi bilan almashtirildi", "quick_quote": "Narx taklifi haqida", "quick_reschedule": "Jadvalni oʻzgartirish"},
}
