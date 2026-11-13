# Tax and receipt strings: owner console (VAT, withholding, cash receipts, tax invoices), partner earnings and the
# customer checkout receipt options. Columns: ko (source), en.
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
S = {
  "tTaxSection": ["세무", "Tax"],
  "tVatQuarter": ["{q}분기 부가세 CSV", "Q{q} VAT CSV"],
  "tVatYear": ["연도", "Year"],
  "tExportWithholding": ["지급명세서 CSV", "Withholding statement CSV"],
  "tExportTaxInvoices": ["세금계산서 업로드 CSV", "Tax invoice upload CSV"],
  "tTaxLayoutNote": ["홈택스 실제 양식과 대조한 뒤 올려주세요. 열 구성은 아직 확인되지 않았어요.", "Check the columns against the 홈택스 template before uploading. Layout not yet verified."],
  "tCashReceipts": ["현금영수증", "Cash receipts"],
  "tCashIssued": ["발급 완료", "Issued"],
  "tCashFailed": ["발급 실패", "Failed"],
  "tCashPending": ["대기", "Pending"],
  "tCashCancelled": ["취소됨", "Cancelled"],
  "tReissue": ["재발급", "Reissue"],
  "tTaxInvoices": ["세금계산서", "Tax invoices"],
  "tApprovalNumber": ["승인번호", "Approval no."],
  "tIssuedOn": ["발행일", "Issued on"],
  "tMarkIssued": ["발행 완료 표시", "Mark as issued"],
  "tQueueEmpty": ["대기 중인 요청이 없어요", "No requests waiting"],
  "tWithholdingLabel": ["원천징수", "Withholding"],
  "tGrossAmount": ["지급총액", "Gross"],
  "tIncomeTax": ["소득세", "Income tax"],
  "tLocalTax": ["지방소득세", "Local income tax"],
  "tNetAmount": ["실지급액", "Net"],
  "tNoWithholding": ["원천징수 없음 (사업자 등록)", "No withholding (registered business)"],
  "tEstWithholding": ["예상 원천징수 (미지급분 기준)", "Estimated withholding (pending)"],
  "tReceiptOptions": ["영수증 선택", "Receipt options"],
  "tWantCashReceipt": ["현금영수증 받기", "Get a cash receipt"],
  "tCashForIncome": ["소득공제용 (휴대폰 번호)", "For tax deduction (phone number)"],
  "tCashForBusiness": ["지출증빙용 (사업자번호)", "For business expense (business no.)"],
  "tWantTaxInvoice": ["세금계산서 받기 (사업자)", "Get a tax invoice (business)"],
  "tPhoneForReceipt": ["휴대폰 번호", "Phone number"],
  "tBusinessNumber": ["사업자등록번호", "Business registration no."],
  "tCompanyName": ["상호", "Company name"],
  "tRepresentative": ["대표자", "Representative"],
  "tInvoiceEmail": ["세금계산서 받을 이메일", "Email for the invoice"],
  "tReceiptSave": ["저장하고 결제", "Save and pay"],
  "tReceiptSaveFailed": ["영수증 정보를 저장하지 못했어요", "Could not save the receipt details"],
}

# Partner tax-type control (owner console payout card).
S.update({
  "tTaxType": ["세무 유형", "Tax type"],
  "tTaxFreelancer": ["프리랜서 (원천징수)", "Freelancer (withheld)"],
  "tTaxBusiness": ["사업자 등록 (원천징수 없음)", "Registered business (no withholding)"],
})

# Receipt settings line in the payment picker (customer app).
S["tReceiptSettings"] = ["영수증 설정", "Receipt settings"]
