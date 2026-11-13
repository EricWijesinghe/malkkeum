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
}
