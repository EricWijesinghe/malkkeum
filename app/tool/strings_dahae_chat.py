# Dahae chat (U4): list header, quote card rows and the quote-thread quick replies. Columns: ko, en, ja, zh, vi.
S = {
  "chatHoursTitle": ["상담 가능 시간", "Chat hours", "相談可能時間", "咨询时间", "Giờ tư vấn"],
  "chatReplyFast": ["보통 10분 안에 답변해요", "Usually replies within 10 minutes", "通常10分以内に返信", "通常10分钟内回复", "Thường trả lời trong 10 phút"],
  "quoteVisit": ["방문 일정", "Visit", "訪問日程", "上门时间", "Lịch đến"],
  "quoteKind": ["유형", "Type", "タイプ", "类型", "Loại"],
  "quotePayAmount": ["예약금 결제 {amount}", "Pay deposit {amount}", "予約金を支払う {amount}", "支付定金 {amount}", "Trả cọc {amount}"],
  "quoteSuperseded": ["새 견적으로 바뀌었어요", "Replaced by a newer quote", "新しい見積に更新されました", "已被新报价取代", "Đã có báo giá mới hơn"],
  "quick_quote": ["견적이 궁금해요", "About the quote", "見積について", "想了解报价", "Hỏi về báo giá"],
  "cQuoteOverride": ["예상 금액과 크게 다른 견적 보내기", "Send a quote far from the estimate", "概算と大きく異なる見積を送る", "发送与预估差距很大的报价", "Gửi báo giá chênh lệch lớn so với ước tính"],
  "cQuoteOverrideBody": ["견적 {price} · 예상 금액 {estimate} · {ratio}배. 그래도 보낼까요?", "Quote {price} · estimate {estimate} · {ratio}×. Send anyway?", "見積 {price}・概算 {estimate}・{ratio}倍。送信しますか？", "报价 {price} · 预估 {estimate} · {ratio}倍。仍要发送吗？", "Báo giá {price} · ước tính {estimate} · {ratio}×. Vẫn gửi?"],
  "cQuoteNeedsAdmin": ["예상 금액과 차이가 커서 관리자 승인이 필요해요", "This price is far from the estimate: an admin needs to approve it", "概算との差が大きいため、管理者の承認が必要です", "与预估差距过大，需要管理员批准", "Giá chênh lệch lớn so với ước tính: cần quản trị viên duyệt"],
  "quick_reschedule": ["일정 변경할래요", "Change the schedule", "日程を変更したい", "想改时间", "Muốn đổi lịch"],
}

# Extra languages (fil, id, km, mn, ne, ru, si, th, uz). Same keys as S.
X = {
  "fil": {"cQuoteOverrideBody": "Quote {price} · tantya {estimate} · {ratio}×. Ipadala pa rin?", "cQuoteNeedsAdmin": "Malayo ang presyo sa tantya: kailangan ng admin na mag-apruba", "cQuoteOverride": "Ipadala ang quote na malayo sa tantya", "chatHoursTitle": "Oras ng chat", "chatReplyFast": "Karaniwang sumasagot sa loob ng 10 minuto", "quoteVisit": "Pagbisita", "quoteKind": "Uri", "quotePayAmount": "Bayaran ang deposito {amount}", "quoteSuperseded": "Pinalitan ng mas bagong quote", "quick_quote": "Tungkol sa quote", "quick_reschedule": "Palitan ang iskedyul"},
  "id": {"cQuoteOverrideBody": "Penawaran {price} · perkiraan {estimate} · {ratio}×. Tetap kirim?", "cQuoteNeedsAdmin": "Harga jauh dari perkiraan: perlu persetujuan admin", "cQuoteOverride": "Kirim penawaran yang jauh dari perkiraan", "chatHoursTitle": "Jam layanan chat", "chatReplyFast": "Biasanya membalas dalam 10 menit", "quoteVisit": "Kunjungan", "quoteKind": "Jenis", "quotePayAmount": "Bayar DP {amount}", "quoteSuperseded": "Diganti penawaran yang lebih baru", "quick_quote": "Tanya soal penawaran", "quick_reschedule": "Ubah jadwal"},
  "km": {"cQuoteOverrideBody": "សម្រង់តម្លៃ {price} · ប៉ាន់ស្មាន {estimate} · {ratio}×។ នៅតែផ្ញើ?", "cQuoteNeedsAdmin": "តម្លៃខុសឆ្ងាយពីការប៉ាន់ស្មាន៖ ត្រូវការការអនុម័តពីអ្នកគ្រប់គ្រង", "cQuoteOverride": "ផ្ញើសម្រង់តម្លៃដែលខុសឆ្ងាយពីការប៉ាន់ស្មាន", "chatHoursTitle": "ម៉ោងពិគ្រោះ", "chatReplyFast": "ជាធម្មតាឆ្លើយក្នុង 10 នាទី", "quoteVisit": "ការមកដល់", "quoteKind": "ប្រភេទ", "quotePayAmount": "បង់ប្រាក់កក់ {amount}", "quoteSuperseded": "ត្រូវបានជំនួសដោយសម្រង់តម្លៃថ្មី", "quick_quote": "សួរអំពីសម្រង់តម្លៃ", "quick_reschedule": "ប្តូរកាលវិភាគ"},
  "mn": {"cQuoteOverrideBody": "Үнийн санал {price} · тооцоо {estimate} · {ratio}×. Илгээх үү?", "cQuoteNeedsAdmin": "Үнэ тооцооноос их зөрүүтэй: админ зөвшөөрөх шаардлагатай", "cQuoteOverride": "Тооцооноос их зөрүүтэй үнийн санал илгээх", "chatHoursTitle": "Зөвлөгөөний цаг", "chatReplyFast": "Ихэвчлэн 10 минутын дотор хариулна", "quoteVisit": "Ирэх хуваарь", "quoteKind": "Төрөл", "quotePayAmount": "Урьдчилгаа төлөх {amount}", "quoteSuperseded": "Шинэ үнийн саналаар солигдсон", "quick_quote": "Үнийн саналын талаар", "quick_reschedule": "Хуваарь өөрчлөх"},
  "ne": {"cQuoteOverrideBody": "उद्धरण {price} · अनुमान {estimate} · {ratio}×। पठाउने?", "cQuoteNeedsAdmin": "मूल्य अनुमानभन्दा धेरै फरक छ: एडमिनको स्वीकृति चाहिन्छ", "cQuoteOverride": "अनुमानभन्दा धेरै फरक उद्धरण पठाउनुहोस्", "chatHoursTitle": "परामर्श समय", "chatReplyFast": "प्रायः १० मिनेटभित्र जवाफ", "quoteVisit": "भ्रमण", "quoteKind": "प्रकार", "quotePayAmount": "अग्रिम भुक्तानी {amount}", "quoteSuperseded": "नयाँ उद्धरणले बदलियो", "quick_quote": "उद्धरणबारे", "quick_reschedule": "समय परिवर्तन गर्न चाहन्छु"},
  "ru": {"cQuoteOverrideBody": "Смета {price} · оценка {estimate} · {ratio}×. Всё равно отправить?", "cQuoteNeedsAdmin": "Цена сильно отличается от оценки: нужно одобрение администратора", "cQuoteOverride": "Отправить смету, сильно отличающуюся от оценки", "chatHoursTitle": "Часы работы чата", "chatReplyFast": "Обычно отвечаем за 10 минут", "quoteVisit": "Визит", "quoteKind": "Тип", "quotePayAmount": "Оплатить предоплату {amount}", "quoteSuperseded": "Заменено новой сметой", "quick_quote": "Вопрос по смете", "quick_reschedule": "Изменить время"},
  "si": {"cQuoteOverrideBody": "මිල ගණන {price} · ඇස්තමේන්තුව {estimate} · {ratio}×. තවමත් යවන්නද?", "cQuoteNeedsAdmin": "මිල ඇස්තමේන්තුවෙන් බොහෝ වෙනස්: පරිපාලක අනුමැතිය අවශ්‍යයි", "cQuoteOverride": "ඇස්තමේන්තුවෙන් බොහෝ වෙනස් මිල ගණනක් යවන්න", "chatHoursTitle": "උපදේශන වේලාව", "chatReplyFast": "සාමාන්‍යයෙන් මිනිත්තු 10ක් ඇතුළත පිළිතුරු", "quoteVisit": "පැමිණීම", "quoteKind": "වර්ගය", "quotePayAmount": "අත්තිකාරම ගෙවන්න {amount}", "quoteSuperseded": "නව මිල ගණනකින් ප්‍රතිස්ථාපනය විය", "quick_quote": "මිල ගණන ගැන", "quick_reschedule": "කාලසටහන වෙනස් කරන්න"},
  "th": {"cQuoteOverrideBody": "ใบเสนอราคา {price} · ประเมิน {estimate} · {ratio}× ยังจะส่งไหม?", "cQuoteNeedsAdmin": "ราคาต่างจากที่ประเมินมาก ต้องให้ผู้ดูแลอนุมัติ", "cQuoteOverride": "ส่งใบเสนอราคาที่ต่างจากราคาประเมินมาก", "chatHoursTitle": "เวลาให้คำปรึกษา", "chatReplyFast": "ปกติตอบภายใน 10 นาที", "quoteVisit": "วันเข้าบริการ", "quoteKind": "ประเภท", "quotePayAmount": "ชำระมัดจำ {amount}", "quoteSuperseded": "มีใบเสนอราคาใหม่แทนแล้ว", "quick_quote": "สอบถามใบเสนอราคา", "quick_reschedule": "ขอเปลี่ยนนัด"},
  "uz": {"cQuoteOverrideBody": "Narx taklifi {price} · taxmin {estimate} · {ratio}×. Baribir yuborilsinmi?", "cQuoteNeedsAdmin": "Narx taxmindan ancha farq qiladi: admin tasdiqlashi kerak", "cQuoteOverride": "Taxmindan ancha farq qiladigan narx taklifini yuborish", "chatHoursTitle": "Maslahat vaqti", "chatReplyFast": "Odatda 10 daqiqada javob beramiz", "quoteVisit": "Tashrif", "quoteKind": "Turi", "quotePayAmount": "Oldindan toʻlov {amount}", "quoteSuperseded": "Yangi narx taklifi bilan almashtirildi", "quick_quote": "Narx taklifi haqida", "quick_reschedule": "Jadvalni oʻzgartirish"},
}

# FX-c (PDF p03/p04): thread titles, relative day, date divider, request card and the restyled quote card.
_FXC = {
  "chatThreadConsult": ["{service} 상담", "{service} consultation", "{service}のご相談", "{service}咨询", "Tư vấn {service}"],
  "chatThreadAsk": ["{service} 문의", "{service} question", "{service}のお問い合わせ", "关于{service}的问题", "Hỏi về {service}"],
  "chatYesterday": ["어제", "Yesterday", "昨日", "昨天", "Hôm qua"],
  "chatDayReceived": ["상담이 접수됐어요", "Request received", "相談を受け付けました", "已收到咨询", "Đã nhận yêu cầu tư vấn"],
  "chatRequestTitle": ["{service} 예약 요청", "{service} booking request", "{service}の予約リクエスト", "{service}预约请求", "Yêu cầu đặt {service}"],
  "quoteConfirmedTitle": ["확정 견적", "Final quote", "確定見積", "确定报价", "Báo giá chốt"],
  "quoteDepositLine": ["예약금 {pct}% · {amount}을 결제하면 예약이 확정돼요.", "Pay the {pct}% deposit ({amount}) to confirm your booking.", "予約金{pct}%・{amount}を支払うと予約が確定します。", "支付{pct}%定金（{amount}）即可确认预约。", "Thanh toán tiền cọc {pct}% · {amount} để xác nhận đặt lịch."],
  "quotePayDeposit": ["예약금 결제하기", "Pay deposit", "予約金を支払う", "支付定金", "Thanh toán tiền cọc"],
}
S.update(_FXC)
_FXC_X = {
  "fil": ["Konsultasyon sa {service}", "Tanong tungkol sa {service}", "Kahapon", "Natanggap ang kahilingan", "Kahilingan sa booking: {service}", "Pinal na quote", "Bayaran ang {pct}% na deposito ({amount}) para makumpirma ang booking.", "Bayaran ang deposito"],
  "id": ["Konsultasi {service}", "Pertanyaan {service}", "Kemarin", "Permintaan diterima", "Permintaan pesanan {service}", "Penawaran final", "Bayar DP {pct}% ({amount}) untuk mengonfirmasi pesanan.", "Bayar DP"],
  "km": ["ការពិគ្រោះ {service}", "សំណួរអំពី {service}", "ម្សិលមិញ", "បានទទួលសំណើ", "សំណើកក់ {service}", "តម្លៃចុងក្រោយ", "បង់ប្រាក់កក់ {pct}% ({amount}) ដើម្បីបញ្ជាក់ការកក់។", "បង់ប្រាក់កក់"],
  "mn": ["{service} зөвлөгөө", "{service} асуулт", "Өчигдөр", "Хүсэлт хүлээн авлаа", "{service} захиалгын хүсэлт", "Эцсийн үнийн санал", "Захиалгаа баталгаажуулахын тулд {pct}% урьдчилгаа ({amount}) төлнө үү.", "Урьдчилгаа төлөх"],
  "ne": ["{service} परामर्श", "{service} सम्बन्धी प्रश्न", "हिजो", "अनुरोध प्राप्त भयो", "{service} बुकिङ अनुरोध", "अन्तिम उद्धरण", "बुकिङ पक्का गर्न {pct}% अग्रिम ({amount}) तिर्नुहोस्।", "अग्रिम तिर्नुहोस्"],
  "ru": ["Консультация: {service}", "Вопрос: {service}", "Вчера", "Заявка получена", "Заявка: {service}", "Итоговая смета", "Внесите предоплату {pct}% ({amount}), чтобы подтвердить заказ.", "Внести предоплату"],
  "si": ["{service} උපදේශනය", "{service} විමසීම", "ඊයේ", "ඉල්ලීම ලැබිණි", "{service} වෙන්කිරීමේ ඉල්ලීම", "අවසාන මිල ගණන", "වෙන්කිරීම තහවුරු කිරීමට {pct}% අත්තිකාරම ({amount}) ගෙවන්න.", "අත්තිකාරම ගෙවන්න"],
  "th": ["ปรึกษา{service}", "สอบถาม{service}", "เมื่อวาน", "ได้รับคำขอแล้ว", "คำขอจอง{service}", "ใบเสนอราคาสุดท้าย", "ชำระมัดจำ {pct}% ({amount}) เพื่อยืนยันการจอง", "ชำระมัดจำ"],
  "uz": ["{service} boʻyicha maslahat", "{service} boʻyicha savol", "Kecha", "Soʻrov qabul qilindi", "{service} buyurtma soʻrovi", "Yakuniy narx", "Buyurtmani tasdiqlash uchun {pct}% oldindan toʻlov ({amount}) qiling.", "Oldindan toʻlash"],
}
for _code, _vals in _FXC_X.items():
  X[_code].update(zip(_FXC, _vals))
