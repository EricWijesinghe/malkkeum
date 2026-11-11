//! Server-sent text (push, inbox, SMS) in the recipient's language.
//!
//! Call sites keep writing the Korean source text; [`tr`] looks it up here. Unknown text (booking
//! numbers, amounts, chat previews) passes through unchanged. AlimTalk keeps Korean: its templates
//! are pre-approved word for word.

use sqlx::PgPool;
use uuid::Uuid;

use crate::realtime::Recipient;

/// Column order of [`TABLE`] after the Korean key.
const LANGS: [&str; 13] = ["en", "zh", "vi", "ja", "ru", "ne", "si", "th", "id", "mn", "uz", "fil", "km"];

/// Korean source -> translations in [`LANGS`] order. Status codes are keys too (body of pro.status).
const TABLE: &[(&str, [&str; 13])] = &[
    ("계정 상태", ["Account status", "账户状态", "Trạng thái tài khoản", "アカウント状態", "Статус аккаунта", "खाताको स्थिति", "ගිණුමේ තත්ත්වය", "สถานะบัญชี", "Status akun", "Бүртгэлийн төлөв", "Hisob holati", "Status ng account", "ស្ថានភាពគណនី"]),
    ("verified", ["Your account is approved", "您的账户已通过审核", "Tài khoản đã được duyệt", "アカウントが承認されました", "Аккаунт одобрен", "तपाईंको खाता स्वीकृत भयो", "ඔබගේ ගිණුම අනුමත විය", "บัญชีของคุณได้รับการอนุมัติแล้ว", "Akun Anda telah disetujui", "Таны бүртгэл баталгаажлаа", "Hisobingiz tasdiqlandi", "Naaprubahan na ang account mo", "គណនីរបស់អ្នកត្រូវបានអនុម័ត"]),
    ("suspended", ["Your account is suspended", "您的账户已被暂停", "Tài khoản đã bị tạm ngưng", "アカウントが停止されました", "Аккаунт приостановлен", "तपाईंको खाता निलम्बित भयो", "ඔබගේ ගිණුම අත්හිටුවා ඇත", "บัญชีของคุณถูกระงับ", "Akun Anda ditangguhkan", "Таны бүртгэл түр хаагдлаа", "Hisobingiz to‘xtatildi", "Nasuspinde ang account mo", "គណនីរបស់អ្នកត្រូវបានផ្អាក"]),
    ("pending", ["Your account is under review", "您的账户正在审核中", "Tài khoản đang được xét duyệt", "アカウントを審査中です", "Аккаунт на проверке", "तपाईंको खाता समीक्षामा छ", "ඔබගේ ගිණුම සමාලෝචනය වෙමින් පවතී", "บัญชีของคุณอยู่ระหว่างตรวจสอบ", "Akun Anda sedang ditinjau", "Таны бүртгэлийг шалгаж байна", "Hisobingiz ko‘rib chiqilmoqda", "Sinusuri pa ang account mo", "គណនីរបស់អ្នកកំពុងត្រូវបានពិនិត្យ"]),
    ("정산 완료", ["Payout sent", "结算已完成", "Đã thanh toán thu nhập", "精算が完了しました", "Выплата отправлена", "भुक्तानी पठाइयो", "ගෙවීම යවන ලදී", "โอนเงินรายได้แล้ว", "Pembayaran terkirim", "Төлбөр шилжүүллээ", "To‘lov yuborildi", "Naipadala na ang bayad", "បានផ្ញើប្រាក់ទូទាត់"]),
    ("견적 요청", ["New quote request", "新的报价请求", "Yêu cầu báo giá mới", "見積もり依頼", "Новый запрос сметы", "नयाँ मूल्य अनुरोध", "නව මිල ගණන් ඉල්ලීමක්", "คำขอใบเสนอราคาใหม่", "Permintaan penawaran baru", "Шинэ үнийн санал хүсэлт", "Yangi narx so‘rovi", "Bagong hiling ng quote", "សំណើតម្លៃថ្មី"]),
    ("예약 취소", ["Booking cancelled", "预约已取消", "Đã hủy lịch hẹn", "予約がキャンセルされました", "Бронь отменена", "बुकिङ रद्द भयो", "වෙන්කිරීම අවලංගු විය", "การจองถูกยกเลิก", "Pemesanan dibatalkan", "Захиалга цуцлагдлаа", "Buyurtma bekor qilindi", "Kinansela ang booking", "ការកក់ត្រូវបានលុបចោល"]),
    ("예약이 취소됐어요", ["Your booking was cancelled", "您的预约已取消", "Lịch hẹn của bạn đã bị hủy", "予約がキャンセルされました", "Ваша бронь отменена", "तपाईंको बुकिङ रद्द भयो", "ඔබගේ වෙන්කිරීම අවලංගු විය", "การจองของคุณถูกยกเลิกแล้ว", "Pemesanan Anda dibatalkan", "Таны захиалга цуцлагдлаа", "Buyurtmangiz bekor qilindi", "Nakansela ang booking mo", "ការកក់របស់អ្នកត្រូវបានលុបចោល"]),
    ("일정 변경 요청", ["Reschedule request", "改期请求", "Yêu cầu đổi lịch", "日程変更のリクエスト", "Запрос на перенос", "समय परिवर्तन अनुरोध", "කාලය වෙනස් කිරීමේ ඉල්ලීම", "คำขอเปลี่ยนวันเวลา", "Permintaan ubah jadwal", "Хуваарь өөрчлөх хүсэлт", "Vaqtni o‘zgartirish so‘rovi", "Hiling na palitan ang iskedyul", "សំណើប្តូរកាលវិភាគ"]),
    ("견적이 선택됐어요", ["Your quote was accepted", "您的报价已被选中", "Báo giá của bạn đã được chọn", "見積もりが選ばれました", "Ваша смета выбрана", "तपाईंको मूल्य प्रस्ताव छानियो", "ඔබගේ මිල ගණන තෝරා ගන්නා ලදී", "ใบเสนอราคาของคุณได้รับเลือก", "Penawaran Anda dipilih", "Таны үнийн санал сонгогдлоо", "Narx taklifingiz tanlandi", "Napili ang quote mo", "តម្លៃស្នើរបស់អ្នកត្រូវបានជ្រើសរើស"]),
    ("예약금 결제", ["Pay the deposit", "请支付订金", "Thanh toán tiền đặt cọc", "予約金のお支払い", "Оплатите предоплату", "अग्रिम रकम तिर्नुहोस्", "අත්තිකාරම ගෙවන්න", "ชำระเงินมัดจำ", "Bayar uang muka", "Урьдчилгаа төлөх", "Oldindan to‘lov qiling", "Bayaran ang deposit", "បង់ប្រាក់កក់"]),
    ("새 예약", ["New booking", "新预约", "Lịch hẹn mới", "新しい予約", "Новая бронь", "नयाँ बुकिङ", "නව වෙන්කිරීමක්", "การจองใหม่", "Pemesanan baru", "Шинэ захиалга", "Yangi buyurtma", "Bagong booking", "ការកក់ថ្មី"]),
    ("상담팀", ["Support team", "客服团队", "Đội hỗ trợ", "サポートチーム", "Служба поддержки", "सहायता टोली", "සහාය කණ්ඩායම", "ทีมดูแลลูกค้า", "Tim dukungan", "Тусламжийн баг", "Yordam jamoasi", "Support team", "ក្រុមជំនួយ"]),
    ("청소가 끝났어요", ["Cleaning is done", "清洁已完成", "Đã dọn dẹp xong", "清掃が完了しました", "Уборка завершена", "सफाइ सकियो", "පිරිසිදු කිරීම අවසන්", "ทำความสะอาดเสร็จแล้ว", "Pembersihan selesai", "Цэвэрлэгээ дууслаа", "Tozalash tugadi", "Tapos na ang paglilinis", "ការសម្អាតបានបញ្ចប់"]),
    ("전후 사진을 확인하고 후기를 남겨 주세요", ["Check the before and after photos and leave a review", "查看清洁前后的照片并留下评价", "Xem ảnh trước và sau rồi để lại đánh giá", "ビフォー・アフター写真をご確認のうえ、レビューをお残しください", "Посмотрите фото до и после и оставьте отзыв", "अघि र पछिका फोटो हेरेर समीक्षा लेख्नुहोस्", "පෙර සහ පසු ඡායාරූප බලා සමාලෝචනයක් ලියන්න", "ดูรูปก่อนและหลังทำความสะอาด แล้วเขียนรีวิวได้เลย", "Lihat foto sebelum dan sesudah, lalu tulis ulasan", "Өмнө ба дараах зургийг харж, сэтгэгдэл үлдээнэ үү", "Oldin va keyingi suratlarni ko‘rib, sharh qoldiring", "Tingnan ang before at after na litrato at mag-iwan ng review", "មើលរូបថតមុន និងក្រោយ ហើយផ្តល់ការវាយតម្លៃ"]),
    ("청소팀이 도착했어요", ["The cleaning team has arrived", "清洁团队已到达", "Đội vệ sinh đã đến", "清掃チームが到着しました", "Бригада уборки прибыла", "सफाई टोली आइपुग्यो", "පිරිසිදු කිරීමේ කණ්ඩායම ළඟා වුණා", "ทีมทำความสะอาดมาถึงแล้ว", "Tim pembersih sudah tiba", "Цэвэрлэгээний баг ирлээ", "Tozalash jamoasi yetib keldi", "Dumating na ang cleaning team", "ក្រុមសម្អាតបានមកដល់ហើយ"]),
    ("결제가 완료됐어요", ["Payment complete", "付款已完成", "Thanh toán đã hoàn tất", "お支払いが完了しました", "Оплата завершена", "भुक्तानी सम्पन्न भयो", "ගෙවීම සම්පූර්ණයි", "ชำระเงินเรียบร้อยแล้ว", "Pembayaran selesai", "Төлбөр амжилттай боллоо", "To‘lov yakunlandi", "Kumpleto na ang bayad", "ការទូទាត់បានបញ្ចប់"]),
    ("결제 내역은 예약 상세에서 확인할 수 있어요", ["You can check the payment details in your booking", "可在预约详情中查看付款明细", "Bạn có thể xem chi tiết thanh toán trong đặt lịch", "予約詳細でお支払い内容をご確認いただけます", "Сведения об оплате можно посмотреть в деталях брони", "भुक्तानी विवरण बुकिङ विवरणमा हेर्न सकिन्छ", "ගෙවීම් විස්තර වෙන්කිරීම් විස්තරයෙන් බලාගත හැක", "ดูรายละเอียดการชำระเงินได้ในรายละเอียดการจอง", "Anda bisa melihat detail pembayaran di detail pemesanan", "Төлбөрийн дэлгэрэнгүйг захиалгын мэдээллээс харна уу", "To‘lov tafsilotlarini buyurtma tafsilotlarida ko‘rishingiz mumkin", "Ilagay ang detalye ng bayad sa booking mo", "ការទូទាត់អាចមើលបានក្នុងព័ត៌មានការកក់"]),
    ("예약 상태가 바뀌었어요", ["Your booking status changed", "预约状态已更新", "Trạng thái lịch hẹn đã thay đổi", "予約の状況が変わりました", "Статус брони изменился", "बुकिङको स्थिति बदलियो", "වෙන්කිරීමේ තත්ත්වය වෙනස් විය", "สถานะการจองเปลี่ยนแปลงแล้ว", "Status pemesanan berubah", "Захиалгын төлөв өөрчлөгдлөө", "Buyurtma holati o‘zgardi", "Nagbago ang status ng booking", "ស្ថានភាពការកក់បានផ្លាស់ប្តូរ"]),
    ("결제가 자동으로 취소됐어요", ["Your payment was cancelled automatically", "您的付款已自动取消", "Thanh toán đã tự động bị hủy", "お支払いが自動でキャンセルされました", "Платёж автоматически отменён", "तपाईंको भुक्तानी स्वतः रद्द भयो", "ඔබගේ ගෙවීම ස්වයංක්‍රීයව අවලංගු විය", "การชำระเงินถูกยกเลิกโดยอัตโนมัติ", "Pembayaran dibatalkan otomatis", "Төлбөр автоматаар цуцлагдлаа", "To‘lov avtomatik bekor qilindi", "Awtomatikong nakansela ang bayad", "ការទូទាត់ត្រូវបានលុបចោលដោយស្វ័យប្រវត្តិ"]),
    ("예약 조건이 바뀌어 결제 금액을 환불했어요", ["The booking changed, so we refunded your payment", "预约条件有变，已为您退款", "Lịch hẹn đã thay đổi nên chúng tôi đã hoàn tiền", "予約条件が変わったため、お支払いを返金しました", "Условия брони изменились, мы вернули оплату", "बुकिङ परिवर्तन भएकाले भुक्तानी फिर्ता गरियो", "වෙන්කිරීම වෙනස් වූ නිසා ගෙවීම ආපසු ලබා දුනිමු", "การจองมีการเปลี่ยนแปลง เราจึงคืนเงินให้แล้ว", "Pemesanan berubah, jadi pembayaran Anda dikembalikan", "Захиалга өөрчлөгдсөн тул төлбөрийг буцаалаа", "Buyurtma o‘zgargani uchun to‘lov qaytarildi", "Nagbago ang booking kaya ibinalik namin ang bayad mo", "ការកក់បានផ្លាស់ប្តូរ ដូច្នេះយើងបានបង្វិលប្រាក់វិញ"]),
    ("청소팀이 배정됐어요", ["Your cleaning team is assigned", "已为您分配清洁团队", "Đã phân công đội dọn dẹp", "清掃チームが決まりました", "Команда уборщиков назначена", "तपाईंको सफाइ टोली तोकियो", "ඔබගේ පිරිසිදු කිරීමේ කණ්ඩායම පවරා ඇත", "จัดทีมทำความสะอาดให้คุณแล้ว", "Tim kebersihan sudah ditugaskan", "Цэвэрлэгээний баг томилогдлоо", "Tozalash jamoasi tayinlandi", "May naka-assign nang cleaning team", "ក្រុមសម្អាតត្រូវបានចាត់តាំង"]),
    ("새 작업이 배정됐어요", ["You have a new job", "您有新的工作", "Bạn có công việc mới", "新しい作業が割り当てられました", "Вам назначена новая работа", "तपाईंलाई नयाँ काम तोकियो", "ඔබට නව රැකියාවක් පවරා ඇත", "คุณได้รับงานใหม่", "Anda mendapat pekerjaan baru", "Танд шинэ ажил оноогдлоо", "Sizga yangi ish tayinlandi", "May bago kang trabaho", "អ្នកមានការងារថ្មី"]),
    ("앱에서 일정과 주소를 확인하세요", ["Check the time and address in the app", "请在应用中查看时间和地址", "Xem thời gian và địa chỉ trong ứng dụng", "アプリで日時と住所をご確認ください", "Проверьте время и адрес в приложении", "एपमा समय र ठेगाना हेर्नुहोस्", "යෙදුමේ වේලාව සහ ලිපිනය බලන්න", "ดูเวลาและที่อยู่ในแอป", "Cek waktu dan alamat di aplikasi", "Цаг, хаягийг аппаас шалгана уу", "Vaqt va manzilni ilovada ko‘ring", "Tingnan ang oras at address sa app", "ពិនិត្យម៉ោង និងអាសយដ្ឋានក្នុងកម្មវិធី"]),
    ("변경된 일정이 확정됐어요", ["Your new schedule is confirmed", "新的时间已确认", "Lịch mới đã được xác nhận", "変更後の日程が確定しました", "Новое время подтверждено", "नयाँ समय पक्का भयो", "නව කාලසටහන තහවුරු විය", "ยืนยันวันเวลาใหม่แล้ว", "Jadwal baru dikonfirmasi", "Шинэ хуваарь баталгаажлаа", "Yangi vaqt tasdiqlandi", "Kumpirmado na ang bagong iskedyul", "កាលវិភាគថ្មីត្រូវបានបញ្ជាក់"]),
    ("인증번호", ["Verification code", "验证码", "Mã xác minh", "認証番号", "Код подтверждения", "प्रमाणीकरण कोड", "සත්‍යාපන කේතය", "รหัสยืนยัน", "Kode verifikasi", "Баталгаажуулах код", "Tasdiqlash kodi", "Verification code", "លេខកូដផ្ទៀងផ្ទាត់"]),
    ("팀원으로 초대됐어요. 파트너 앱을 설치해 주세요.", ["You were invited to a cleaning team. Please install the partner app.", "您已被邀请加入团队，请安装合作伙伴应用。", "Bạn được mời vào nhóm. Hãy cài ứng dụng đối tác.", "チームに招待されました。パートナーアプリをインストールしてください。", "Вас пригласили в команду. Установите приложение для партнёров.", "तपाईंलाई टोलीमा निम्तो दिइयो। कृपया पार्टनर एप इन्स्टल गर्नुहोस्।", "ඔබට කණ්ඩායමකට ආරාධනා ලැබී ඇත. කරුණාකර හවුල්කරු යෙදුම ස්ථාපනය කරන්න.", "คุณได้รับเชิญเข้าทีม โปรดติดตั้งแอปพาร์ทเนอร์", "Anda diundang ke tim. Silakan pasang aplikasi mitra.", "Таныг багт урилаа. Түншийн аппыг суулгана уу.", "Siz jamoaga taklif qilindingiz. Hamkor ilovasini o‘rnating.", "Inimbitahan ka sa isang team. Paki-install ang partner app.", "អ្នកត្រូវបានអញ្ជើញចូលក្រុម។ សូមដំឡើងកម្មវិធីដៃគូ។"]),
    ("내일 청소 예정이에요", ["Your cleaning is tomorrow", "明天有清洁服务", "Ngày mai có lịch dọn dẹp", "明日清掃の予定があります", "Завтра уборка", "भोलि सफाइ छ", "හෙට පිරිසිදු කිරීමක් ඇත", "พรุ่งนี้มีนัดทำความสะอาด", "Pembersihan besok", "Маргааш цэвэрлэгээ байна", "Ertaga tozalash bor", "Bukas ang iyong paglilinis", "ថ្ងៃស្អែកមានការសម្អាត"]),
    ("다음 청소를 예약해 보세요", ["Book your next cleaning", "预约下一次清洁吧", "Đặt lịch dọn dẹp lần tiếp theo", "次回の清掃を予約しましょう", "Забронируйте следующую уборку", "अर्को सफाई बुक गर्नुहोस्", "ඊළඟ පිරිසිදු කිරීම වෙන්කරන්න", "จองการทำความสะอาดครั้งต่อไป", "Pesan pembersihan berikutnya", "Дараагийн цэвэрлэгээгээ захиалаарай", "Keyingi tozalashni buyurtma qiling", "I-book ang susunod mong paglilinis", "កក់ការសម្អាតលើកក្រោយ"]),
    ("지난번과 같은 조건으로 빠르게 예약할 수 있어요", ["Rebook with the same settings in a few taps", "用相同设置快速再次预约", "Đặt lại với cùng thiết lập chỉ vài thao tác", "同じ条件で数タップで予約できます", "Повторите бронь с теми же настройками в несколько нажатий", "उही सेटिङमा केही ट्यापमा फेरि बुक गर्नुहोस्", "එකම සැකසුම් සමඟ තට්ටු කිහිපයකින් නැවත වෙන්කරන්න", "จองซ้ำด้วยการตั้งค่าเดิมได้ในไม่กี่ครั้ง", "Pesan ulang dengan pengaturan yang sama hanya dengan beberapa ketukan", "Ижил тохиргоотойгоор хэдхэн товшилтоор дахин захиална уу", "Bir necha bosishda xuddi shu sozlamalar bilan qayta buyurtma qiling", "I-rebook gamit ang parehong settings sa ilang tap lang", "កក់ឡើងវិញដោយការកំណត់ដូចគ្នាក្នុងពីរបីដង"]),
    ("견적 요청이 아직 남아 있어요", ["Your quote request is still open", "您的报价请求仍在进行中", "Yêu cầu báo giá của bạn vẫn đang mở", "見積もり依頼がまだ残っています", "Ваш запрос сметы всё ещё открыт", "तपाईंको मूल्य अनुरोध अझै खुला छ", "ඔබේ මිල ගණන් ඉල්ලීම තවමත් විවෘතයි", "คำขอใบเสนอราคาของคุณยังเปิดอยู่", "Permintaan penawaran Anda masih terbuka", "Үнийн санал хүсэлт тань нээлттэй хэвээр байна", "Narx so‘rovingiz hali ochiq", "Bukas pa ang iyong hiling sa quote", "សំណើតម្លៃរបស់អ្នកនៅតែបើកចំហ"]),
    ("원하는 시간에 청소팀을 바로 받아 보세요", ["Get a cleaning team quote for your time slot", "为您的时段获取清洁团队报价", "Nhận báo giá đội dọn dẹp cho khung giờ của bạn", "ご希望の時間帯の清掃チームの見積もりを受け取れます", "Получите смету от команды уборщиков на удобное время", "तपाईंको समयको लागि सफाई टोलीको मूल्य हेर्नुहोस्", "ඔබේ වේලාවට පිරිසිදු කිරීමේ කණ්ඩායමේ මිල ගණන් ලබා ගන්න", "รับใบเสนอราคาจากทีมทำความสะอาดสำหรับเวลาที่คุณเลือก", "Dapatkan penawaran tim pembersihan untuk waktu Anda", "Таны цагт тохирох цэвэрлэгээний багийн үнийн саналыг авна уу", "Qulay vaqtingiz uchun tozalash jamoasi narxini oling", "Kumuha ng quote ng cleaning team para sa iyong oras", "ទទួលបានតម្លៃពីក្រុមសម្អាតសម្រាប់ពេលវេលារបស់អ្នក"]),
];

/// Korean text for status-code keys, which aren't Korean themselves.
fn korean_for_code(key: &str) -> Option<&'static str> {
    match key {
        "verified" => Some("계정이 승인됐어요"),
        "suspended" => Some("계정이 일시 중지됐어요"),
        "pending" => Some("계정을 검토하고 있어요"),
        _ => None,
    }
}

/// `source` in `locale`. Korean (and unknown locales) get the Korean text; unknown text is returned as is.
pub fn tr(locale: &str, source: &str) -> String {
    if locale == "ko" {
        return korean_for_code(source).unwrap_or(source).to_string();
    }
    let Some(col) = LANGS.iter().position(|l| *l == locale) else {
        return korean_for_code(source).unwrap_or(source).to_string();
    };
    TABLE
        .iter()
        .find(|(ko, _)| *ko == source)
        .map(|(_, t)| t[col].to_string())
        .unwrap_or_else(|| source.to_string())
}

/// The recipient's account language; staff read Korean. Team members follow their team owner.
pub async fn locale_of(db: &PgPool, to: Recipient) -> String {
    let q = match to {
        Recipient::User(_) => "SELECT locale FROM users WHERE id = $1",
        Recipient::Pro(_) => "SELECT locale FROM pros WHERE id = $1",
        Recipient::Member(_) => "SELECT p.locale FROM team_members m JOIN pros p ON p.id = m.pro_id WHERE m.id = $1",
        Recipient::Staff => return "ko".into(),
    };
    let id: Uuid = match to {
        Recipient::User(id) | Recipient::Pro(id) | Recipient::Member(id) => id,
        Recipient::Staff => unreachable!(),
    };
    match sqlx::query_scalar::<_, String>(q).bind(id).fetch_optional(db).await {
        Ok(l) => l.unwrap_or_else(|| "ko".into()),
        Err(e) => {
            tracing::warn!(error = %e, "locale lookup failed; using Korean");
            "ko".into()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn translates_known_text_and_passes_through_the_rest() {
        assert_eq!(tr("en", "청소가 끝났어요"), "Cleaning is done");
        assert_eq!(tr("vi", "새 예약"), "Lịch hẹn mới");
        assert_eq!(tr("ko", "청소가 끝났어요"), "청소가 끝났어요");
        assert_eq!(tr("en", "B-20261111-0042"), "B-20261111-0042");
        assert_eq!(tr("xx", "새 예약"), "새 예약");
        assert_eq!(tr("ko", "verified"), "계정이 승인됐어요");
        assert_eq!(tr("en", "verified"), "Your account is approved");
    }

    #[test]
    fn table_covers_every_supported_locale_without_blanks() {
        let supported = crate::routes::me::SUPPORTED_LOCALES;
        for l in LANGS {
            assert!(supported.contains(&l), "{l} not supported");
        }
        assert_eq!(LANGS.len() + 1, supported.len());
        for (ko, row) in TABLE {
            assert!(row.iter().all(|t| !t.trim().is_empty()), "blank translation for {ko}");
        }
    }
}
