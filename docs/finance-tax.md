# 세무 기능 안내 / Tax features guide

Status: **WIP, untested against live services.** Every feature below is off or unverified until the items in
"Accountant checklist" are confirmed and the PortOne sandbox run is done. Audience: owner and accountant.

---

## 한국어

### 1. 기능 요약

| 영역 | 무엇을 하나 | 기본 상태 | 설정 |
|---|---|---|---|
| 현금영수증 | 체크아웃에서 고객이 소득공제용(휴대폰) / 지출증빙용(사업자번호)을 선택하면 결제 완료 시 PortOne V2로 발급, 전액 환불 시 취소 | **꺼짐** | `PORTONE_CASH_RECEIPTS=1` |
| 세금계산서 | 사업자 고객이 체크아웃에서 사업자 정보를 입력하면 결제 완료 후 사장 큐에 등록, 홈택스 업로드용 CSV 내보내기, 발행 승인번호 기록 | 항상 켜짐(요청 시에만 동작) | — |
| 파트너 원천징수 | 파트너별 세무 유형(`freelancer` / `business` / `unset`)에 따라 지급 시 사업소득 3.3% 원천징수 | `unset` = 원천징수 적용(보수적 기본값) | 콘솔에서 파트너 유형 지정 |
| 부가세 요약 | 분기별 결제수단 매출, 환불, 플랫폼수수료 및 부가세 추정 CSV | 항상 켜짐 | — |
| 지급명세서 | 지급 완료된 원천징수 대상 파트너 지급 내역 CSV(간이지급명세서 월별, 지급명세서 연간 모두 같은 형식) | 항상 켜짐 | — |

### 2. 시스템이 하는 일 (상세)

**현금영수증**
- 요청: `PUT /v1/checkouts/{id}/cash-receipt` (고객). 계좌이체 / 가상계좌 결제에만 허용. 휴대폰번호(`PERSONAL`) 또는 사업자등록번호(`CORPORATE`)를 검증한 뒤 **암호화하여 저장**한다. 목록에는 뒤 4자리만 보인다.
- 발급: 결제가 확정되면 PortOne `POST /cash-receipts` 호출. 발급 실패는 결제를 되돌리지 않고 `failed` 상태로 기록되며, 콘솔에서 재발급할 수 있다.
- 취소: 전액 환불 시 `POST /payments/{paymentId}/cash-receipt/cancel`. 부분 환불은 자동 취소하지 않는다 (ACCOUNTANT 확인 필요).
- 콘솔: `GET /v1/admin/finance/cash-receipts?from&to`, `POST /v1/admin/finance/cash-receipts/{id}/reissue`.
- 요청 형식 출처: `@portone/server-sdk` 0.19.0 타입 정의 (`IssueCashReceiptBody`, `IssueCashReceiptCustomerInput`, `CashReceiptClient`). 응답 구조와 오류 응답은 **샌드박스 검증 전**이다.

**세금계산서**
- 요청: `PUT /v1/checkouts/{id}/tax-invoice` (고객). 사업자등록번호(체크섬 검증), 상호, 대표자, 업태, 종목, 주소, 이메일.
- 결제 완료 시 사장 큐(`requested`)에 등록된다.
- 내보내기: `GET /v1/admin/finance/export/tax-invoices?from&to`. 내보낸 건은 `exported_at`이 찍힌다.
- 발행 기록: `POST /v1/admin/finance/tax-invoices/{id}/issued` (승인번호, 발행일). 홈택스에서 발행한 뒤에만 기록한다.
- **홈택스 업로드 양식은 확인되지 않았다.** `domain::tax::TAX_INVOICE_HEADERS` 한 곳에 정의된 열 순서를 실제 다운로드한 일괄작성 양식에 맞춰 수정해야 한다.

**파트너 원천징수**
- 세무 유형: `freelancer`(사업소득자, 3.3% 원천징수), `business`(사업자등록, 세금계산서·현금영수증으로 처리, 원천징수 없음), `unset`(미분류, 원천징수 적용).
- 지정: `POST /v1/admin/settlements/partners/{pro_id}/tax-type`. 지정 후 **새로 만들어지는 지급분부터** 적용된다. 이미 만들어진 지급은 생성 시점 값을 유지한다.
- 계산 (`domain::tax::business_withholding`): 소득세 = 지급총액 × 3%, 원 단위 절사. 지방소득세 = 소득세 × 10%, 10원 단위 절사. 실지급액 = 지급총액 − 소득세 − 지방소득세.
- 지급 금액(송금액)은 **실지급액**이다. `payouts.amount`는 정산 합계(총액)로 유지하여 기존 정산 대조 로직을 바꾸지 않았다.
- 기존 지급 내역은 `untracked`(원천징수 기록 없음, 0원)으로 표시된다. 이미 지급된 금액을 소급 계산하지 않는다.
- 파트너 앱 수입 화면: `GET /v1/partner/earnings`에 `tax_type`, `estimated_income_tax`, `estimated_local_tax`, `estimated_net`(미지급 합계 기준 추정)이 추가되었다. **앱 화면 표시는 아직 구현되지 않았다.**

**부가세 요약**
- `GET /v1/admin/finance/export/vat?year=&quarter=`: 결제수단별 건수·결제액, 합계, 환불액, 플랫폼수수료, 부가세 추정(수수료의 10%).
- 현금영수증·세금계산서 발행 구분 열은 아직 없다 (추가 필요).

**지급명세서**
- `GET /v1/admin/finance/export/withholding?from&to`: 지급 완료 + 원천징수 대상 파트너만. 열: 지급일, 상호, 팀명, 소득구분(사업소득), 지급총액, 소득세, 지방소득세, 실지급액.
- **주민등록번호(또는 사업자번호)를 수집하지 않는다.** 지급명세서는 소득자 식별번호가 필요하므로 이 기능만으로는 제출할 수 없다 (아래 체크리스트 1번).

### 3. 확인이 필요한 결정 (Accountant checklist)

1. **지급명세서 식별번호**: 프리랜서 파트너의 주민등록번호를 어떻게 수집·보관할지 (암호화, 접근 권한, 보관기간). 현재 시스템에 없다.
2. **홈택스 양식**: 세금계산서 일괄작성 양식과 지급명세서(간이지급명세서 포함) 전자파일 양식의 실제 열 구성. 현재 CSV 열은 임시안이다.
3. **사업소득 원천징수 기준**: 과세 기준 금액이 총액(고객 결제액 기준)인지, 플랫폼 수수료 차감 후 금액인지. 세율 3%와 지방소득세 10%, 원 단위 절사 규칙.
4. **세무 유형 기본값**: 미분류(`unset`)를 원천징수 대상으로 둘지. 현재는 보수적으로 원천징수한다.
5. **플랫폼의 지위**: 플랫폼이 판매자인지(매출 전액 과세표준) 중개자인지(수수료만 과세표준) 여부. 현재 부가세 요약은 플랫폼수수료 기준 추정이다.
6. **부가세 기준 날짜**: 환불을 결제일 기준으로 집계하는지, 환불일 기준으로 집계하는지. 현재는 결제일 기준.
7. **현금영수증 의무발행**: 청소 서비스가 의무발행 업종에 해당하는지, 10만원 이상 현금거래 기준을 어떻게 적용할지. 계좌이체·가상계좌를 현금거래로 볼지.
8. **현금영수증 부분 환불**: 부분 환불 시 취소 여부와 절차.
9. **세금계산서 작성일자와 공급가액 계산**: 현재 부가세는 총액 ÷ 11 (원 단위 절사), 공급가액은 나머지. 발행 규칙과 일치하는지.
10. **세금계산서 공급자 정보**: 홈택스 일괄작성 시 공급자 정보를 어디서 채울지 (CSV에는 포함하지 않음).
11. **신고·제출 기한**: 간이지급명세서 월별 제출 기한, 지급명세서 연간 제출 기한, 부가세 신고 기한.
12. **과거 지급분**: `untracked` 지급에 원천징수를 소급하지 않는 처리가 맞는지.

#### 포인트(Malkkeum 포인트) 법적 성격

- 포인트는 **구매 적립·추가 혜택(로열티)** 이며, 이용자가 돈을 충전해 쌓는 **선불 수단이 아니다.** 현금 충전 경로가 없고, 포인트를 현금으로 환급하지 않는다.
- 따라서 「전자금융거래법」상 선불전자지급수단 등록 대상이 되지 않는 구조로 설계했다. 충전 기능을 추가하거나 포인트를 현금으로 바꿔 주면 이 전제가 깨지므로, 그 전에 반드시 재검토한다.
- 포인트 사용은 예약 결제의 일부(포인트 + PG 결제)로만 가능하고, 예약 취소 시 전액 반환된다(이 경우 새 적립 항목으로 되돌림, 유효기간 재산정).
- 적립은 실제로 현금 결제된 금액(`paid_amount`)에만 적용하며, 포인트로 낸 부분에는 적립하지 않는다.
- 유효기간은 기본 1년이고, 만료 30일 전 알림 대상이 된다. 만료 시 `expire` 항목으로 소멸 처리하며 원장에서 삭제하지 않는다.
- 회계·세무 확인 항목: 포인트 적립금의 수익 인식 시점(매출 차감 여부), 포인트 소멸분 처리, 부가세 과세표준 조정 여부.

### 4. 설정과 검증 절차

1. PortOne 샌드박스에서 `PORTONE_CASH_RECEIPTS=1`로 발급·취소를 실행하고, 응답 구조(`cashReceipt.status`, `issueNumber`, `url`)와 오류 응답을 확인한다. 확인 전에는 켜지 않는다.
2. 홈택스 일괄작성 양식을 내려받아 `TAX_INVOICE_HEADERS`를 맞춘다.
3. 지급명세서 전자파일 양식을 확인한 뒤 열 구성을 맞춘다.

### 5. 출처

- PortOne V2 현금영수증 API 타입: `@portone/server-sdk` 0.19.0 (`dist/generated/payment/cashReceipt/`). https://unpkg.com/@portone/server-sdk@0.19.0
- PortOne 현금영수증 API 문서: https://developers.portone.io/api/rest-v2/payment.cashReceipt?v=v2 (요청 필드 전체 목록은 페이지가 잘려 확인하지 못함)
- 홈택스 일괄작성 양식: 검색으로 확인하지 못함. 블로그 자료는 열 구성을 확인해 주지 않았다.
- 세법 조문 (소득세법, 부가가치세법, 지방세법): **이 문서 작성 중 확인하지 않았다.** 코드 주석의 조문 번호는 추정이며 회계사가 확인해야 한다.

---

## English

### 1. What it does

| Area | Behaviour | Default | Setting |
|---|---|---|---|
| Cash receipt (현금영수증) | Customer picks personal (phone) or business (business number) at checkout. Issued via PortOne V2 on settlement; cancelled on full refund. | **Off** | `PORTONE_CASH_RECEIPTS=1` |
| Tax invoice (세금계산서) | Business customer enters company details at checkout. Queued for the owner after settlement; exported as CSV for 홈택스 upload; owner records the NTS approval number. | On (only acts on requests) | — |
| Partner withholding | Per partner tax type (`freelancer` / `business` / `unset`). Freelancers withheld 3.3% (3% income tax + 10% local tax). | `unset` = withheld | Owner sets type in console |
| VAT summary | Quarterly: sales by payment method, refunds, platform fee, estimated VAT. | On | — |
| Withholding statement | Paid withheld payouts with gross, income tax, local tax and net. Same layout for the monthly 간이지급명세서 and annual 지급명세서. | On | — |

### 2. Behaviour in detail

- **Cash receipts**: the identity number is validated (phone format; business number check digit) and encrypted at rest. Issue failures do not undo the payment; they are marked `failed` and the owner can reissue. Only full refunds cancel automatically; partial refunds are left for the accountant (see checklist).
- **Tax invoices**: the request is stored when the customer submits it. The owner exports the `requested` queue (which marks the rows exported) and records the approval number after issuing on 홈택스. The upload layout is unverified.
- **Withholding**: `payouts.amount` stays the gross settlement total. The transfer amount is gross minus withholding, computed from a tax type snapshotted on each payout. Payouts created before this rule are `untracked` and carry no withholding.
- **Partner earnings** (`GET /v1/partner/earnings`) add `tax_type` and an estimate of withholding on the pending total. App screens do not show it yet.
- **Endpoints**: `/v1/admin/finance/export/vat`, `/v1/admin/finance/export/withholding`, `/v1/admin/finance/export/tax-invoices`, `/v1/admin/finance/cash-receipts`, `/v1/admin/settlements/partners/{pro_id}/tax-type`.

### 3. Decisions the owner and accountant must confirm

See the Korean checklist above (items 1 to 12). In short: resident registration number collection for withholding statements, the real 홈택스 layouts, the withholding base and rounding, the default for unclassified partners, whether the platform is seller or intermediary for VAT, the VAT refund basis, the cash receipt mandatory-issue rules and partial refunds, the tax invoice VAT split, supplier data on invoices, filing deadlines, and whether historical payouts should stay untracked.

### 4. Before enabling

1. Run cash receipt issue and cancel in the PortOne sandbox with `PORTONE_CASH_RECEIPTS=1`. Confirm the response shape and error bodies. Leave it off until then.
2. Download the 홈택스 bulk-issue template and align `TAX_INVOICE_HEADERS`.
3. Confirm the withholding statement layout and align `WITHHOLDING_HEADERS`.

### 5. Sources

- PortOne V2 cash receipt request types: `@portone/server-sdk` 0.19.0 generated typings (`dist/generated/payment/cashReceipt/`), https://unpkg.com/@portone/server-sdk@0.19.0
- PortOne cash receipt API reference: https://developers.portone.io/api/rest-v2/payment.cashReceipt?v=v2 (the full request field list was not visible on the fetched page)
- 홈택스 bulk-issue template: not verified.
- Korean tax statutes: **not checked in this work.** Article references in code comments are unverified and must be confirmed by the accountant.
