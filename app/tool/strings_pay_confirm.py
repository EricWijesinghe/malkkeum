# Payment confirmation wait (customer app): the PG approved but the server's answer is late.
# Columns: ko (source), en, ja, zh (Simplified), vi. X adds fil, id, km, mn, ne, ru, si, th, uz.
# Only ko and en are written; the other languages carry the English copy.

_EN = {
  "payConfirmingTitle": "Checking your payment",
  "payConfirmingBody": "Your payment went through to the card company and we're confirming it. Don't pay again. You can leave this screen; the booking shows up in your bookings once it's confirmed.",
}

_KO = {
  "payConfirmingTitle": "결제 확인 중",
  "payConfirmingBody": "결제가 카드사에 접수되어 확인하고 있어요. 다시 결제하지 마세요. 이 화면을 나가도 확인이 끝나면 예약 내역에 표시돼요.",
}

S = {k: [_KO[k], v, v, v, v] for k, v in _EN.items()}

X = {code: dict(_EN) for code in ["fil", "id", "km", "mn", "ne", "ru", "si", "th", "uz"]}
