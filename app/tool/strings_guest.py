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
}
