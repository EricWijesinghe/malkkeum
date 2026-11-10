# AI support agent: console inbox/wizard and the customer and partner chat labels.
# Columns: ko, en, ja, zh, vi. Extra languages (fil, id, km, mn, ne, ru, si, th, uz) in X.
S = {
  "aiLabel": ["AI 상담원", "AI assistant", "AIアシスタント", "AI 助手", "Trợ lý AI"],
  "aiBadge": ["AI", "AI", "AI", "AI", "AI"],
  "aiCardHint": ["고객 채팅에 자동으로 답변해요. 메시지마다 API 요금이 발생해요.", "Answers customer chats automatically. Each message costs API fees.", "お客様のチャットに自動で返信します。メッセージごとにAPI料金がかかります。", "自动回复客户聊天。每条消息都会产生 API 费用。", "Tự động trả lời chat của khách. Mỗi tin nhắn đều phát sinh phí API."],
  "aiModeOffline": ["상담원이 없을 때만 답변", "Answer only when staff are away", "担当者不在時のみ回答", "仅在无人值班时回答", "Chỉ trả lời khi không có nhân viên"],
  "aiModeAlways": ["항상 AI가 먼저 답변", "AI answers first, always", "常にAIが先に回答", "始终由 AI 先回答", "AI luôn trả lời trước"],
  "aiPause": ["AI 일시중지", "Pause AI", "AI を一時停止", "暂停 AI", "Tạm dừng AI"],
  "aiResume": ["AI 재개", "Resume AI", "AI を再開", "恢复 AI", "Tiếp tục AI"],
  "aiPausedNote": ["AI가 이 대화에 답변하지 않아요", "AI is paused for this chat", "この会話ではAIが返信しません", "此对话已暂停 AI", "AI đang tạm dừng trong cuộc trò chuyện này"],
  "aiUsageMonth": ["이번 달 AI 호출 {count}회", "AI calls this month: {count}", "今月のAI呼び出し {count} 回", "本月 AI 调用 {count} 次", "Lượt gọi AI tháng này: {count}"],
  "aiNotConfigured": ["AI 상담원이 꺼져 있어요", "AI support is off", "AIサポートはオフです", "AI 客服未开启", "Trợ lý AI đang tắt"],
}

X = {
  "fil": {
    "aiLabel": "AI na katulong", "aiBadge": "AI", "aiCardHint": "Awtomatikong sumasagot sa chat ng mga customer. May bayad sa API ang bawat mensahe.",
    "aiModeOffline": "Sumagot lang kapag walang staff", "aiModeAlways": "Laging unang sumasagot ang AI", "aiPause": "I-pause ang AI",
    "aiResume": "Ipagpatuloy ang AI", "aiPausedNote": "Naka-pause ang AI sa chat na ito", "aiUsageMonth": "Mga tawag sa AI ngayong buwan: {count}",
    "aiNotConfigured": "Naka-off ang AI na tagasagot",
  },
  "id": {
    "aiLabel": "Asisten AI", "aiBadge": "AI", "aiCardHint": "Menjawab chat pelanggan secara otomatis. Setiap pesan dikenai biaya API.",
    "aiModeOffline": "Jawab hanya saat staf tidak ada", "aiModeAlways": "AI selalu menjawab lebih dulu", "aiPause": "Jeda AI",
    "aiResume": "Lanjutkan AI", "aiPausedNote": "AI dijeda untuk chat ini", "aiUsageMonth": "Panggilan AI bulan ini: {count}",
    "aiNotConfigured": "AI pendamping mati",
  },
  "km": {
    "aiLabel": "ជំនួយការ AI", "aiBadge": "AI", "aiCardHint": "ឆ្លើយការជជែករបស់អតិថិជនដោយស្វ័យប្រវត្តិ។ សារនីមួយៗមានថ្លៃ API។",
    "aiModeOffline": "ឆ្លើយតែពេលគ្មានបុគ្គលិក", "aiModeAlways": "AI តែងឆ្លើយមុនគេ", "aiPause": "ផ្អាក AI",
    "aiResume": "បន្ត AI", "aiPausedNote": "AI ត្រូវបានផ្អាកសម្រាប់ការជជែកនេះ", "aiUsageMonth": "ការហៅ AI ខែនេះ៖ {count}",
    "aiNotConfigured": "AI មិនទាន់បើក",
  },
  "mn": {
    "aiLabel": "AI туслах", "aiBadge": "AI", "aiCardHint": "Хэрэглэгчийн чатад автоматаар хариулна. Мессеж бүр API төлбөртэй.",
    "aiModeOffline": "Ажилтан байхгүй үед л хариулна", "aiModeAlways": "AI үргэлж эхлээд хариулна", "aiPause": "AI-г түр зогсоох",
    "aiResume": "AI-г үргэлжлүүлэх", "aiPausedNote": "Энэ чатад AI түр зогссон", "aiUsageMonth": "Энэ сарын AI дуудалт: {count}",
    "aiNotConfigured": "AI туслагч идэвхгүй байна",
  },
  "ne": {
    "aiLabel": "AI सहायक", "aiBadge": "AI", "aiCardHint": "ग्राहकको च्याटमा स्वतः जवाफ दिन्छ। प्रत्येक सन्देशमा API शुल्क लाग्छ।",
    "aiModeOffline": "कर्मचारी नभएको बेला मात्र जवाफ दिन्छ", "aiModeAlways": "AI सधैं पहिले जवाफ दिन्छ", "aiPause": "AI रोक्नुहोस्",
    "aiResume": "AI पुनः सुरु गर्नुहोस्", "aiPausedNote": "यो च्याटमा AI रोकिएको छ", "aiUsageMonth": "यस महिनाको AI कल: {count}",
    "aiNotConfigured": "AI सहायक बन्द छ",
  },
  "ru": {
    "aiLabel": "ИИ-ассистент", "aiBadge": "ИИ", "aiCardHint": "Автоматически отвечает в чатах клиентов. Каждое сообщение оплачивается по тарифу API.",
    "aiModeOffline": "Отвечает, только когда сотрудников нет", "aiModeAlways": "ИИ всегда отвечает первым", "aiPause": "Пауза для ИИ",
    "aiResume": "Возобновить ИИ", "aiPausedNote": "ИИ приостановлен для этого чата", "aiUsageMonth": "Вызовов ИИ в этом месяце: {count}",
    "aiNotConfigured": "ИИ-ассистент выключен",
  },
  "si": {
    "aiLabel": "AI සහායක", "aiBadge": "AI", "aiCardHint": "පාරිභෝගික කථාවලට ස්වයංක්‍රීයව පිළිතුරු දෙයි. සෑම පණිවිඩයකටම API ගාස්තු අයවේ.",
    "aiModeOffline": "කාර්ය මණ්ඩලය නැති විට පමණක් පිළිතුරු දෙයි", "aiModeAlways": "AI සෑම විටම පළමුව පිළිතුරු දෙයි", "aiPause": "AI විරාම ගන්වන්න",
    "aiResume": "AI නැවත ආරම්භ කරන්න", "aiPausedNote": "මෙම කථාවට AI විරාම ගන්වා ඇත", "aiUsageMonth": "මෙම මාසයේ AI ඇමතුම්: {count}",
    "aiNotConfigured": "AI සහායක ක්‍රියාවිරහිතයි",
  },
  "th": {
    "aiLabel": "ผู้ช่วย AI", "aiBadge": "AI", "aiCardHint": "ตอบแชทลูกค้าโดยอัตโนมัติ ทุกข้อความมีค่า API",
    "aiModeOffline": "ตอบเฉพาะตอนไม่มีเจ้าหน้าที่", "aiModeAlways": "AI ตอบก่อนเสมอ", "aiPause": "หยุด AI ชั่วคราว",
    "aiResume": "เปิด AI อีกครั้ง", "aiPausedNote": "หยุด AI ชั่วคราวในแชทนี้", "aiUsageMonth": "การเรียก AI เดือนนี้: {count} ครั้ง",
    "aiNotConfigured": "ยังไม่ได้เปิดผู้ช่วย AI",
  },
  "uz": {
    "aiLabel": "AI yordamchi", "aiBadge": "AI", "aiCardHint": "Mijozlar chatiga avtomatik javob beradi. Har bir xabar uchun API to'lovi olinadi.",
    "aiModeOffline": "Faqat xodimlar bo'lmaganda javob beradi", "aiModeAlways": "AI doim birinchi javob beradi", "aiPause": "AI ni to'xtatish",
    "aiResume": "AI ni davom ettirish", "aiPausedNote": "Bu chatda AI to'xtatilgan", "aiUsageMonth": "Bu oydagi AI chaqiruvlari: {count}",
    "aiNotConfigured": "AI yordamchi o'chirilgan",
  },
}
