# Growth strings: social proof, re-booking, referrals, review photos, welcome offer, review moderation.
# Columns: ko (source), en.
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
# {name} placeholders must match across languages (checked by gen_arb.py).

S = {
  # social proof (customer home + website)
  "proofHomes": ["이번 달 {count}집을 청소했어요", "{count} homes cleaned this month"],
  "proofRating": ["평균 평점 {rating}점 · 후기 {count}개", "Average {rating} stars · {count} reviews"],
  "proofReviewsTitle": ["최근 후기", "Recent reviews"],
  # re-booking nudge
  "rebookTitle": ["지난번 서비스를 다시 예약할까요?", "Book the last service again?"],
  "rebookBody": ["{service} · 지난 방문 {date}", "{service} · last visit {date}"],
  "rebookButton": ["다시 예약하기", "Book again"],
  # honest scarcity
  "seatsLeft": ["{count}자리 남음", "{count} left"],
  # review sheet
  "reviewSheetTitle": ["이번 청소는 어떠셨나요?", "How was this clean?"],
  "reviewPhotosAdd": ["사진 추가", "Add photos"],
  "reviewPhotosHint": ["사진은 최대 5장까지 올릴 수 있어요", "Up to 5 photos"],
  "reviewSaved": ["후기를 남겨 주셔서 고마워요", "Thanks for your review"],
  "reviewPhotoFailed": ["사진을 올리지 못했어요. 다시 시도해 주세요.", "Couldn't upload the photo. Try again."],
  # referrals
  "referralTitle": ["친구를 초대하면 쿠폰을 드려요", "Invite a friend, get a coupon"],
  "referralBody": ["친구가 첫 예약을 마치면 두 분 모두 {amount} 쿠폰을 받아요", "When your friend completes a first booking, you both get a {amount} coupon"],
  "referralCopy": ["코드 복사", "Copy code"],
  "referralCopied": ["추천 코드를 복사했어요", "Referral code copied"],
  "referralClaimTitle": ["추천 코드가 있나요?", "Have a referral code?"],
  "referralClaimField": ["추천 코드 입력", "Enter referral code"],
  "referralClaimButton": ["등록", "Apply"],
  "referralClaimed": ["추천 코드가 등록됐어요", "Referral code applied"],
  "referralStats": ["초대 {invited}명 · 보상 {rewarded}건", "{invited} invited · {rewarded} rewarded"],
  "err_self_referral": ["내 추천 코드는 쓸 수 없어요", "You can't use your own code"],
  "err_referee_already_booked": ["예약 이후에는 추천 코드를 등록할 수 없어요", "Codes can only be added before your first booking"],
  "err_already_referred": ["이미 추천 코드를 등록했어요", "A referral code is already applied"],
  "err_invalid_referral_code": ["추천 코드를 확인해 주세요", "Check the referral code"],
  "err_referral_disabled": ["지금은 친구 추천을 받지 않아요", "Referrals are paused right now"],
  "err_invalid_photos": ["사진은 다해에 올린 파일만 첨부할 수 있어요", "Only photos uploaded through Dahae can be attached"],
  # console: welcome offer, referral settings, review moderation, dashboard tiles
  "welcomeOfferTitle": ["첫 예약 할인", "First-booking offer"],
  "welcomeOfferBody": ["신규 고객의 첫 예약에 자동으로 적용돼요. 쿠폰과는 중복되지 않아요.", "Applied automatically to a new customer's first booking. Not combined with coupons."],
  "offerKindAmount": ["정액(원)", "Fixed (won)"],
  "offerKindPercent": ["정률(%)", "Percent (%)"],
  "offerValue": ["할인 값", "Discount value"],
  "offerEnabled": ["사용", "On"],
  "offerSaved": ["저장했어요", "Saved"],
  "referralSettingsTitle": ["친구 추천 보상", "Referral reward"],
  "referralSettingsBody": ["친구가 첫 예약을 완료하고 결제까지 끝나면 지급돼요. 본인 추천, 같은 번호 중복은 막아요.", "Paid once a friend's first booking is completed and paid. Self-referrals and duplicate phones are blocked."],
  "referralRewardAmount": ["보상 금액(원)", "Reward amount (won)"],
  "reviewsModerationTitle": ["후기 관리", "Review moderation"],
  "reviewHide": ["숨기기", "Hide"],
  "reviewShow": ["다시 보이기", "Show again"],
  "reviewHiddenTag": ["숨김", "Hidden"],
  "growthAverageRating": ["평균 평점", "Average rating"],
  "growthReviewCount": ["후기 {count}개", "{count} reviews"],
  "growthReferralConversion": ["친구 추천 전환", "Referral conversion"],
  "growthTab": ["성장", "Growth"],
  "growthReferralValue": ["{rewarded}/{invited}명", "{rewarded} of {invited}"],
}
