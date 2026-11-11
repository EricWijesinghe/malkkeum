# Partner payout screen (owner console). Columns: ko, en, ja, zh, vi.
# X gives the nine extra languages (fil, id, km, mn, ne, ru, si, th, uz) the English text until they are translated.
S = {
  "poTabSettlements": ["정산", "Settlements", "精算", "结算", "Quyết toán"],
  "poTabPayouts": ["지급 내역", "Payouts", "支払い", "支付记录", "Chi trả"],
  "poState_requested": ["요청됨", "Requested", "依頼済み", "已请求", "Đã yêu cầu"],
  "poState_sent": ["전송됨", "Sent", "送信済み", "已发送", "Đã gửi"],
  "poState_paid": ["지급 완료", "Paid", "支払い済み", "已支付", "Đã trả"],
  "poState_failed": ["실패", "Failed", "失敗", "失败", "Thất bại"],
  "poProviderManual": ["직접 이체", "Manual transfer", "手動振込", "手动转账", "Chuyển khoản tay"],
  "poProviderToss": ["토스 지급대행", "Toss payouts", "Toss 支払い代行", "Toss 代付", "Toss chi hộ"],
  "poShowAccount": ["계좌 보기", "Show account", "口座を表示", "查看账户", "Xem tài khoản"],
  "poAccountTitle": ["이체 정보", "Transfer details", "振込先情報", "转账信息", "Thông tin chuyển khoản"],
  "poAccountBody": ["{holder} · {bank} · {account}\n{amount}원을 위 계좌로 보낸 뒤 확인을 눌러 주세요.", "Send {amount} won to {holder} · {bank} · {account}, then tap confirm.", "{holder}・{bank}・{account} に{amount}ウォンを振り込んだら確認を押してください。", "请向 {holder} · {bank} · {account} 转账 {amount} 韩元，然后点击确认。", "Chuyển {amount} won tới {holder} · {bank} · {account}, rồi bấm xác nhận."],
  "poConfirmPaid": ["이체 완료로 표시", "Mark as transferred", "振込完了にする", "标记为已转账", "Đánh dấu đã chuyển"],
  "poMarkFailed": ["실패로 표시", "Mark as failed", "失敗にする", "标记为失败", "Đánh dấu thất bại"],
  "poReasonTitle": ["실패 사유", "Failure reason", "失敗理由", "失败原因", "Lý do thất bại"],
  "poReasonHint": ["예: 계좌 오류, 이체 취소", "e.g. wrong account, transfer cancelled", "例: 口座誤り、振込取消", "例如：账户错误、转账取消", "VD: sai tài khoản, đã hủy"],
  "poSend": ["토스로 지급 요청", "Send via Toss", "Tossで支払い", "通过 Toss 发送", "Gửi qua Toss"],
  "poSync": ["상태 확인", "Check status", "状態を確認", "查询状态", "Kiểm tra trạng thái"],
  "poRetry": ["다시 시도", "Retry", "再試行", "重试", "Thử lại"],
  "poNoPayouts": ["지급 내역이 없어요", "No payouts yet", "支払いはまだありません", "暂无支付记录", "Chưa có khoản chi trả"],
  "poRequestedToast": ["지급 요청 {n}건을 만들었어요", "Created {n} payout requests", "支払い依頼を{n}件作成しました", "已创建 {n} 笔支付请求", "Đã tạo {n} yêu cầu chi trả"],
  "poReasonRequired": ["사유를 입력해 주세요", "Enter a reason", "理由を入力してください", "请输入原因", "Nhập lý do"],
  "poRevealNote": ["계좌 정보는 조회 기록에 남아요", "Viewing account details is logged", "口座情報の閲覧は記録されます", "查看账户信息会被记录", "Việc xem tài khoản được ghi lại"],
}

X = {c: {k: v[1] for k, v in S.items()} for c in ["fil", "id", "km", "mn", "ne", "ru", "si", "th", "uz"]}
