# Dahae chat (U4): list header, quote card rows and the quote-thread quick replies. Columns: ko (source), en.
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
S = {
  "chatHoursTitle": ["상담 가능 시간", "Chat hours"],
  "chatReplyFast": ["보통 10분 안에 답변해요", "Usually replies within 10 minutes"],
  "quoteVisit": ["방문 일정", "Visit"],
  "quoteKind": ["유형", "Type"],
  "quotePayAmount": ["예약금 결제 {amount}", "Pay deposit {amount}"],
  "quoteSuperseded": ["새 견적으로 바뀌었어요", "Replaced by a newer quote"],
  "quick_quote": ["견적이 궁금해요", "About the quote"],
  "cQuoteOverride": ["예상 금액과 크게 다른 견적 보내기", "Send a quote far from the estimate"],
  "cQuoteOverrideBody": ["견적 {price} · 예상 금액 {estimate} · {ratio}배. 그래도 보낼까요?", "Quote {price} · estimate {estimate} · {ratio}×. Send anyway?"],
  "cQuoteNeedsAdmin": ["예상 금액과 차이가 커서 관리자 승인이 필요해요", "This price is far from the estimate: an admin needs to approve it"],
  "quick_reschedule": ["일정 변경할래요", "Change the schedule"],
}


# FX-c (PDF p03/p04): thread titles, relative day, date divider, request card and the restyled quote card.
_FXC = {
  "chatThreadConsult": ["{service} 상담", "{service} consultation"],
  "chatThreadAsk": ["{service} 문의", "{service} question"],
  "chatYesterday": ["어제", "Yesterday"],
  "chatDayReceived": ["상담이 접수됐어요", "Request received"],
  "chatRequestTitle": ["{service} 예약 요청", "{service} booking request"],
  "quoteConfirmedTitle": ["확정 견적", "Final quote"],
  "quoteDepositLine": ["예약금 {pct}% · {amount}을 결제하면 예약이 확정돼요.", "Pay the {pct}% deposit ({amount}) to confirm your booking."],
  "quotePayDeposit": ["예약금 결제하기", "Pay deposit"],
}
S.update(_FXC)
