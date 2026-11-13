# Points wallet, payment history and receipt. Columns: ko (source), en.
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
# Placeholders: {count} points, {days} days, {date} yyyy.mm.dd.
S = {
  "walletTitle": ["포인트 지갑", "Points wallet"],
  "walletBalance": ["사용 가능한 포인트", "Available points"],
  "walletPoints": ["{count} P", "{count} pts"],
  "walletExpiring": ["{days}일 안에 {count} P가 사라져요", "{count} pts expire within {days} days"],
  "walletOff": ["포인트 적립은 아직 열리지 않았어요", "Points rewards are not open yet"],
  "walletEmpty": ["아직 포인트 내역이 없어요", "No points activity yet"],
  "walletHistory": ["최근 내역", "Recent activity"],
  "walletKindEarn": ["예약 적립", "Booking cashback"],
  "walletKindWelcome": ["가입 환영 포인트", "Welcome points"],
  "walletKindReferral": ["친구 추천 보상", "Referral reward"],
  "walletKindRefund": ["취소로 돌려받은 포인트", "Points returned after cancellation"],
  "walletKindSpend": ["예약 결제에 사용", "Used for a booking"],
  "walletKindExpire": ["기간 만료로 소멸", "Expired"],
  "walletKindOther": ["포인트 조정", "Points adjustment"],
  "moreWallet": ["포인트 지갑", "Points wallet"],
  "payHistoryTitle": ["결제 내역", "Payment history"],
  "payHistoryEmpty": ["결제 내역이 없어요", "No payments yet"],
  "payStatusPaid": ["결제 완료", "Paid"],
  "payStatusRefunded": ["환불 완료", "Refunded"],
  "payStatusRefundPending": ["환불 진행 중", "Refund in progress"],
  "payStatusPending": ["결제·입금 대기", "Awaiting payment"],
  "payStatusClosed": ["결제되지 않음", "Not paid"],
  "receiptTitle": ["전자 영수증", "Receipt"],
  "receiptLegal": ["상호", "Business name"],
  "receiptRegNo": ["사업자등록번호", "Business reg. no."],
  "receiptAddr": ["사업장 주소", "Address"],
  "receiptPhone": ["고객센터", "Support"],
  "receiptDate": ["결제일", "Paid on"],
  "receiptCopy": ["영수증 내용 복사", "Copy receipt"],
  "receiptCopied": ["영수증 내용을 복사했어요", "Receipt copied"],
  "receiptNote": ["결제 확인용 영수증이에요. 세금계산서가 필요하면 예약 상세에서 따로 신청해 주세요.", "Proof of payment only. For a tax invoice, request one from the booking details."],
}

# Points at checkout (customer) and the console ledger with manual adjustment.
# Placeholders: {count} balance, {max} most points this payment accepts.
S.update({
  "checkoutPointsUse": ["포인트 사용", "Use points"],
  "checkoutPointsAvail": ["보유 {count} P · 이번 결제에 최대 {max} P", "{count} pts available · up to {max} on this payment"],
  "checkoutPointsNeedsWindow": ["포인트는 결제창으로 결제할 때 쓸 수 있어요", "Points can be used when you pay in the payment window"],
  "pointsLedgerTitle": ["포인트 원장", "Points ledger"],
  "pointsAdjustAmount": ["포인트 (차감은 음수로 입력)", "Points (negative to deduct)"],
  "pointsAdjustReason": ["조정 사유", "Reason for adjustment"],
  "pointsAdjustInvalid": ["0이 아닌 포인트와 사유를 입력해 주세요", "Enter a non-zero amount and a reason"],
  "pointsAdjustDone": ["포인트를 조정했어요", "Points adjusted"],
})

# Server refusals when paying with points (T.error / checkoutFailure look these up by code).
S.update({
  "err_points_insufficient": ["포인트가 부족해요. 사용할 포인트를 줄여 주세요.", "You don't have enough points. Lower the points to use."],
  "err_points_over_cap": ["이번 결제에 쓸 수 있는 포인트 한도를 넘었어요.", "That is more points than this payment allows."],
  "err_points_cover_total": ["포인트로 전액을 결제할 수는 없어요. 조금 줄여 주세요.", "Points can't cover the whole amount. Use a little less."],
})
