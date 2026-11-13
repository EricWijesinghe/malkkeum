# App Store 답안: 개인정보 라벨 · 연령 등급 · 수출 규정

App Store Connect 에 입력할 답을 한곳에 모았어요. 고객 앱(다해)과 파트너 앱(다해 파트너)은 **따로** 입력해요.
Google Play 쪽 같은 내용은 `data-safety.md` 예요. 한쪽을 고치면 다른 쪽도 고치세요. 두 문서 모두 v1.4.0 출시 빌드 기준이에요.

근거: 서버 `backend/migrations/`, `backend/crates/api/src/`, 앱 `app/packages/core/lib/src/`, iOS `app/apps/*/ios/Runner/PrivacyInfo.xcprivacy`, `Info.plist`.

## 1. 개인정보 라벨 (App Privacy)

위치: App Store Connect → 앱 → [앱 개인 정보 보호].

Apple 의 기준 (2026-11 확인, https://developer.apple.com/app-store/app-privacy-details/):
- **수집** = 데이터를 기기 밖으로 보내서, 요청을 처리하는 데 필요한 시간보다 오래 우리나 협력사가 볼 수 있게 하는 것.
- **추적** = 우리 앱 데이터를 다른 회사 데이터와 묶어 맞춤 광고·광고 측정에 쓰거나 데이터 중개업자에게 넘기는 것. 다해는 하지 않아요.
- 결제 정보는 결제 서비스 화면에서 입력하고 개발자가 볼 수 없으면 수집이 아니에요. 다해는 카드 번호는 받지 않지만 자동결제 키를 저장하므로 "결제 정보"를 적어요.

### 공통
| 질문 | 답 |
|---|---|
| 이 앱에서 데이터를 수집하나요? | 예 |
| 추적(Tracking)에 쓰나요? | **아니요** (광고 식별자 IDFA 미사용, ATT 요청 없음, 광고 SDK 없음, `NSPrivacyTracking = false`) |
| 개인정보처리방침 URL | `https://도메인/privacy.html` |
| 계정 삭제 | 앱 [더보기] → [계정] → [회원 탈퇴]. 웹 안내: `https://도메인/delete-account.html` |

### 고객 앱 (다해)
| Apple 분류 | 데이터 | 근거 (테이블/컬럼) | 사용자에게 연결 | 추적 | 목적 |
|---|---|---|---|---|---|
| 연락처 정보 · 이름 | 이름 | `users.name` | 예 | 아니요 | 앱 기능 |
| 연락처 정보 · 이메일 주소 | 이메일 (소셜 로그인, 세금계산서 요청 시) | `users.email`, `user_identities.email`, `tax_invoice_requests.email` | 예 | 아니요 | 앱 기능 |
| 연락처 정보 · 전화번호 | 휴대폰 번호 | `users.phone` | 예 | 아니요 | 앱 기능, **개발자의 광고 또는 마케팅** (마케팅 수신 동의 시 광고 문자, `marketing.rs`) |
| 연락처 정보 · 실제 주소 | 도로명·상세 주소, 평수, 집 정보 | `addresses` | 예 | 아니요 | 앱 기능 |
| 금융 정보 · 결제 정보 | 자동결제 키(빌링키), 카드 표시명, 현금영수증 번호(암호화) | `payment_methods`, `cash_receipts` | 예 | 아니요 | 앱 기능 |
| 구입 항목 · 구입 내역 | 예약, 결제, 환불, 정기 청소, 팁, 쿠폰, 포인트 | `bookings`, `payments`, `checkouts`, `subscriptions`, `booking_tips`, `points_ledger` | 예 | 아니요 | 앱 기능 |
| 식별자 · 사용자 ID | 내부 ID, 소셜 제공자 ID, 본인확인 CI 해시 | `users.id`, `user_identities.provider_user_id`, `users.ci_hash` | 예 | 아니요 | 앱 기능 |
| 식별자 · 기기 ID | 푸시 토큰 | `push_tokens` | 예 | 아니요 | 앱 기능, **개발자의 광고 또는 마케팅** (마케팅 수신 동의 시 광고 푸시) |
| 식별자 · 기기 ID | 분석용 설치 ID (임의 값) | `analytics_events.anon_id` | **아니요** | 아니요 | **분석** |
| 사용 데이터 · 제품 상호작용 | 정해진 이벤트 8가지(앱 열기, 가입, 견적 보기, 예약, 결제, 후기), 화면 이름 | `analytics_events` | **아니요** | 아니요 | **분석** |
| 사용자 콘텐츠 · 사진 또는 비디오 | 상담·후기·사고 접수 사진 | `uploads`, `reviews.photos`, `cases.photos` | 예 | 아니요 | 앱 기능 |
| 사용자 콘텐츠 · 고객 지원 | 운영팀·AI 상담 채팅 | `chat_messages` | 예 | 아니요 | 앱 기능 |
| 사용자 콘텐츠 · 기타 사용자 콘텐츠 | 후기, 방문 메모·출입 방법, 사고 접수 내용 | `reviews`, `bookings.visit_notes`, `bookings.access_code_enc`, `cases` | 예 | 아니요 | 앱 기능 |
| 진단 · 충돌 데이터 | 앱이 직접 보내는 오류 보고(외부 SDK 없음): 오류 메시지·스택·앱 버전, 14일 뒤 삭제 | `client_errors` | **아니요** | 아니요 | 앱 기능 |

기기 ID 는 App Store Connect 에서 한 줄이에요. "연결됨"을 **예**(푸시 토큰이 계정에 연결되므로)로 하고, 목적에 **앱 기능 · 분석 · 개발자의 광고 또는 마케팅** 세 가지를 모두 고르세요.

분석 이벤트는 사용자가 "마케팅 정보 수신"에 동의한 경우에만 보내요. 계정 ID 없이 설치마다 만든 임의 값으로만 모으고 90일 뒤 지워요 (`analytics.dart`, `analytics.rs`). 그래도 Apple 은 선택 사항이라는 이유로 빼 주지 않으므로 적어야 해요.

**수집하지 않음** 으로 두는 항목: 건강·피트니스, 민감한 정보, 연락처(주소록), 검색 기록, 방문 기록, 오디오, 광고 데이터, **위치**.

**위치**: 고객 앱은 주소 입력 화면에서 [현재 위치로 찾기]를 누를 때만 "앱 사용 중" 위치 권한을 요청해요 (`NSLocationWhenInUseUsageDescription`, 14개 언어). 좌표는 iPhone 의 주소 변환 기능에만 넘기고 다해 서버로 보내지 않아요. Apple 의 "수집" 정의(우리나 협력사가 볼 수 있게 기기 밖으로 보냄)에 해당하지 않으므로 **위치: 수집하지 않음**이에요. 저장되는 것은 사용자가 확인한 주소(위 "실제 주소")뿐이에요.

**AI 상담 (Anthropic)**: 운영자가 AI 상담을 켠 경우, 고객이 쓴 상담 문장과 해당 예약 요약이 Anthropic API 로 전송돼 답변을 만들어요 (`backend/crates/api/src/ai.rs`). 라벨에서는 "고객 지원" 줄에 들어 있어요. 심사 지침 5.1.2(i) 는 제3자 AI 에 개인정보를 보낼 때 이를 밝히고 동의를 받으라고 해요. 다해는 가입 때 국외 이전 동의(받는 자: Anthropic, Google)를 받고 `privacy.html` 5·6항에 적어요.

### 파트너 앱 (다해 파트너)
분석 이벤트가 없고 위치 권한도 없어요.

| Apple 분류 | 데이터 | 근거 | 사용자에게 연결 | 추적 | 목적 |
|---|---|---|---|---|---|
| 연락처 정보 · 이름 | 파트너·팀원 이름, 팀 이름 | `pros`, `team_members` | 예 | 아니요 | 앱 기능 |
| 연락처 정보 · 이메일 주소 | 이메일 (소셜 로그인 시) | `user_identities.email` | 예 | 아니요 | 앱 기능 |
| 연락처 정보 · 전화번호 | 파트너·팀원 휴대폰 번호 | `pros.phone`, `team_members.phone` | 예 | 아니요 | 앱 기능 |
| 금융 정보 · 기타 금융 정보 | 정산 계좌(암호화, 끝 4자리만 표시), 세금 유형 | `payout_accounts`, `pros.tax_type` | 예 | 아니요 | 앱 기능 |
| 구입 항목 · 구입 내역 | 정산·지급 내역 | `settlements`, `payouts` | 예 | 아니요 | 앱 기능 |
| 식별자 · 사용자 ID | 내부 ID, 소셜 제공자 ID | `pros.id`, `user_identities` | 예 | 아니요 | 앱 기능 |
| 식별자 · 기기 ID | 푸시 토큰 | `push_tokens` | 예 | 아니요 | 앱 기능 |
| 사용자 콘텐츠 · 사진 또는 비디오 | 작업 전후 사진 | `completion_reports`, `uploads` | 예 | 아니요 | 앱 기능 |
| 사용자 콘텐츠 · 고객 지원 | 운영팀 채팅 | `chat_messages` | 예 | 아니요 | 앱 기능 |
| 사용자 콘텐츠 · 기타 사용자 콘텐츠 | 견적, 완료 보고 메모 | `quotes`, `completion_reports` | 예 | 아니요 | 앱 기능 |
| 진단 · 충돌 데이터 | 앱이 직접 보내는 오류 보고(외부 SDK 없음): 오류 메시지·스택·앱 버전, 14일 뒤 삭제 | `client_errors` | **아니요** | 아니요 | 앱 기능 |

### 앱 안의 개인정보 매니페스트와 맞추기 (개발자용)
Apple 은 `PrivacyInfo.xcprivacy` 와 위 라벨이 같기를 기대해요. 고객·파트너 앱 매니페스트(`app/apps/*/ios/Runner/PrivacyInfo.xcprivacy`)는 위 표와 같아요. 충돌 데이터는 `NSPrivacyCollectedDataTypeCrashData` (연결 false, 추적 false, 목적 AppFunctionality) 로 적혀 있고, `scripts/ci/check-native.py` 가 빠지지 않았는지 검사해요.

외부 SDK(Firebase, Google Sign-In, Kakao 등)의 매니페스트는 실제 iOS 빌드의 Xcode "Generate Privacy Report" 로만 확인할 수 있어요. 빌드 뒤 한 번 확인하세요.

## 2. 연령 등급 (Age Rating)

위치: App Store Connect → 앱 → [앱 정보] → [연령 등급]. 2025년에 바뀐 새 설문 기준이에요 (등급: 4+, 9+, 13+, 16+, 18+. https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions). 두 앱의 답이 같아요.

| 묶음 | 질문 | 답 | 이유 |
|---|---|---|---|
| 앱 내 제어 | 보호자 통제 (Parental Controls) | 아니요 | 그런 기능이 없어요 |
| 앱 내 제어 | 연령 확인 (Age Assurance) | 아니요 | PASS 본인확인은 예약자 확인용이고 나이로 콘텐츠를 막는 기능이 아니에요 |
| 기능 | 제한 없는 웹 접근 (Unrestricted Web Access) | 아니요 | 앱 안 웹 화면은 결제대행사 결제 페이지만 열어요. 약관 링크는 외부 브라우저로 열려요 |
| 기능 | 사용자 생성 콘텐츠 (User-Generated Content) | 고객 앱 **예** · 파트너 앱 **예** | 고객 후기(글·사진)가 다른 이용자에게 보여요. 파트너 앱에서도 후기를 보고 신고할 수 있어요 |
| 기능 | 소셜 미디어 | 아니요 | |
| 기능 | 메시지 및 채팅 (Messaging and Chat) | **예** | 운영팀과의 상담 채팅이 있어요. 이용자끼리는 대화하지 않지만, 채팅 기능이 있으므로 넓게 답해요 (등급은 그대로 4+) |
| 기능 | 광고 (Advertising) | 아니요 | 앱 안에 유료 광고가 없어요. 자체 쿠폰·공지 배너는 광고가 아니에요 |
| 성숙한 주제 | 비속어, 공포, 술·담배·약물 | 모두 없음 | |
| 의료·웰니스 | 의료·치료 정보, 건강·웰니스 주제 | 모두 없음 | |
| 성·노출 | 전 항목 | 모두 없음 | |
| 폭력 | 전 항목 | 모두 없음 | |
| 확률 기반 활동 | 도박, 모의 도박, 경연(Contests), 확률형 아이템 | 모두 없음 | 친구 초대 혜택은 순위·경쟁이 아니에요 |

예상 결과: **4+**. 대한민국 스토어용 등급도 같은 답으로 자동 계산돼요. 후기에 부적절한 글이 올라올 수 있으므로 신고·숨김 기능을 유지해야 해요 (`review-notes.md` 6항).

Google Play 와 Microsoft Store 의 등급 설문(IARC)은 `play-declarations.md` 5항에 있어요.

## 3. 수출 규정 (Export Compliance)

| 질문 | 답 |
|---|---|
| 앱이 암호화를 사용하나요? | 운영체제가 제공하는 표준 암호화만 써요 (HTTPS/TLS, 키체인). 자체 암호 알고리즘이 없어요 |
| `Info.plist` 설정 | `ITSAppUsesNonExemptEncryption = false` (두 앱 모두, `app/apps/*/ios/Runner/Info.plist`) |
| 업로드할 때마다 질문이 뜨나요? | 아니요. 위 설정이 있으면 App Store Connect 가 묻지 않아요 |
| 제출 서류(미국 수출 분류, 프랑스 신고서) | 면제 대상이라 내지 않아요 |

근거: 앱은 `http` 패키지와 `flutter_secure_storage`(iOS 키체인)만 써요. 계좌번호 등의 암호화(AES-256-GCM)는 **서버**에서 하고 앱에는 들어 있지 않아요. 앱에 자체 암호화 코드를 넣게 되면 이 답을 다시 확인하세요.

## 4. 판단이 필요한 항목
1. **CI 해시**: 본인확인 CI 는 SHA-256 해시만 저장해요. 사람을 구분하는 값이라 "사용자 ID"에 넣었어요.
2. **기기 ID 의 "연결됨"**: 분석용 설치 ID 는 계정과 연결하지 않지만 푸시 토큰은 연결돼요. App Store Connect 는 유형당 한 번만 답하므로 **예**로 답해요.
3. **유입 경로(UTM)**: 웹 가입에서만 저장해요. iOS 앱은 이 값을 받는 경로가 없어 라벨에 넣지 않았어요 (`data-safety.md` 5항 3번).
4. **운영체제 주소 변환**: 좌표를 주소로 바꾸는 일은 Apple 의 기능이 해요. 다해와 협력사가 좌표를 받지 않으므로 수집이 아니에요. 좌표를 서버로 보내는 기능을 넣으면 "정확한 위치"를 추가하세요.

## 5. 바뀌면 같이 고칠 곳
- 새 테이블·컬럼에 개인정보가 들어가면 이 표, `data-safety.md`, `website/privacy.html`, `PrivacyInfo.xcprivacy` 를 같이 고쳐요.
- 광고·분석·크래시 **외부 SDK** 를 붙이면 그 SDK 가 모으는 데이터와 "추적" 여부를 다시 답해야 해요.
