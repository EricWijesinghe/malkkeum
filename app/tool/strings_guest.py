# Guest sign-in reasons and the guest account hints (customer app).
# Columns: ko (source), en.
# {name} placeholders must match across languages (checked by gen_arb.py).

S = {
  # sign-in sheet title per protected action (the body stays guestSheetBody)
  "guestReasonQuote": ["견적을 저장하고 예약하려면 로그인하세요", "Sign in to save this quote and book"],
  "guestReasonBook": ["예약을 확정하려면 로그인하세요", "Sign in to confirm your booking"],
  "guestReasonChat": ["상담원과 대화하려면 로그인하세요", "Sign in to chat with our team"],
  "guestReasonAccount": ["내 쿠폰·포인트·예약은 로그인 후 볼 수 있어요", "Sign in to see your coupons, points and bookings"],
  # shown in place of a member-only value for a guest
  "guestAccountHint": ["로그인하면 확인할 수 있어요", "Sign in to view"],
  # quote price before the address step (no sign-up needed to see it)
  "guestPriceLine": ["예상 금액 {amount} · 가입 없이 확인한 견적이에요", "Estimated {amount} · no sign-up needed"],
  "guestPeakNote": ["방문 시간대에 따라 피크 요금이 더해질 수 있어요", "Peak-hour visits may add a surcharge"],
  "guestBookWithQuote": ["이 견적으로 예약하기", "Book with this quote"],
  "guestSeePrices": ["가입 없이 가격 확인", "See prices without signing up"],
  # guest bookings tab: how a booking works (static sample, no account data)
  "guestFlowTitle": ["예약 후 이렇게 진행돼요", "Here is how a booking works"],
  "guestFlowQuote": ["견적", "Quote"],
  "guestFlowQuoteBody": ["집 조건을 알려주면 가격을 바로 보여드려요", "Tell us about your home and see the price right away"],
  "guestFlowConfirm": ["예약 확정", "Booking confirmed"],
  "guestFlowConfirmBody": ["날짜와 시간을 고르면 예약이 확정돼요", "Pick a date and time to confirm"],
  "guestFlowVisit": ["방문", "Visit"],
  "guestFlowVisitBody": ["약속한 시간에 담당 전문가가 방문해요", "Your pro arrives at the agreed time"],
  "guestFlowDone": ["완료·리뷰", "Done and review"],
  "guestFlowDoneBody": ["작업 사진을 확인하고 후기를 남길 수 있어요", "Check the photos and leave a review"],
  "guestFirstQuoteCta": ["첫 청소 견적 보기", "Get your first quote"],
  # guest chat tab
  "guestFaqTitle": ["자주 묻는 질문", "Frequently asked questions"],
  "guestChatCta": ["상담원과 대화하기 (로그인 필요)", "Chat with our team (sign-in required)"],
  # guest offers (values come from /public/offers; a line is hidden when its offer is off)
  "welcomeOfferLine": ["첫 예약 {value} 할인 · 가입 후 첫 예약 1회 · 발급일로부터 {days}일", "{value} off your first booking · once, after sign-up · valid {days} days"],
  "referralOfferLine": ["친구 초대 시 둘 다 {amount}", "You and a friend each get {amount}"],
}
