# -*- coding: utf-8 -*-
# Dahae More tab (U6). Columns: ko (source), en.
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
# Placeholder: {brand} is the app's display name. Provider names stay as the brands write them.
S = {
  "moreGreeting": ["오늘도 집안일은 {brand}에 맡기세요.", "Leave today's chores to {brand}."],
  "moreBrandTips": ["{brand} 팁", "{brand} tips"],
  "moreContact": ["상담하기", "Chat with us"],
  "moreVersionInfo": ["버전 정보", "Version"],
  "payAvailableTitle": ["사용할 수 있는 결제수단", "Available payment methods"],
  "accountLoginKakao": ["카카오", "Kakao"],
  "accountLoginNaver": ["네이버", "Naver"],
  "accountLoginApple": ["Apple", "Apple"],
  "accountLoginGoogle": ["Google", "Google"],
}

# FX-c (PDF p05, p23-p27): More header and strip, coupon sections, payment note, account header, address note, FAQ chips.
_FXC = {
  "moreNameSuffix": ["{name}님", "{name}"],
  "moreCouponCount": ["{n}장", "{n}"],
  "couponsAvailableTitle": ["사용 가능한 쿠폰", "Available coupons"],
  "couponsUsedTitle": ["사용한 쿠폰", "Used coupons"],
  "couponsNote": ["※ 예약 1건에 쿠폰 1장만 쓸 수 있어요.", "※ One coupon per booking."],
  "payCardNote": ["※ 카드 번호는 {brand}에 저장되지 않고 결제대행사가 안전하게 보관해요.", "※ Card numbers are never stored by {brand}; the payment provider keeps them securely."],
  "accountJoined": ["{date} 가입", "Joined {date}"],
  "addressPyeongNote": ["평수는 꼭 입력해 주세요. 원룸 청소는 {max}평 이하만 예약할 수 있어요.", "Size is required. Studio cleaning is for homes up to {max} pyeong."],
  "faqAll": ["전체", "All"],
  "faqCat_booking": ["예약·변경", "Booking & changes"],
  "faqCat_payment": ["결제·쿠폰", "Payment & coupons"],
  "faqCat_move": ["이사·입주", "Move-in & move-out"],
}
S.update(_FXC)
