// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class TKo extends T {
  TKo([String locale = 'ko']) : super(locale);

  @override
  String get addressSearch => '주소 검색';

  @override
  String get addressSearchHint => '도로명, 건물명, 지번으로 검색';

  @override
  String get addressSearchButton => '검색';

  @override
  String get addressSearchMinChars => '두 글자 이상 입력해 주세요';

  @override
  String get addressNoResults => '검색 결과가 없어요. 다른 단어로 검색해 보세요.';

  @override
  String get addressManualEntry => '직접 입력';

  @override
  String get cardRegisterTitle => '카드 등록';

  @override
  String get cIntJuso => '주소 검색 (도로명주소)';

  @override
  String get aiLabel => 'AI 상담원';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint => '고객 채팅에 자동으로 답변해요. 메시지마다 API 요금이 발생해요.';

  @override
  String get aiModeOffline => '상담원이 없을 때만 답변';

  @override
  String get aiModeAlways => '항상 AI가 먼저 답변';

  @override
  String get aiPause => 'AI 일시중지';

  @override
  String get aiResume => 'AI 재개';

  @override
  String get aiPausedNote => 'AI가 이 대화에 답변하지 않아요';

  @override
  String aiUsageMonth(String count) {
    return '이번 달 AI 호출 $count회';
  }

  @override
  String get aiNotConfigured => 'AI 상담원이 꺼져 있어요';

  @override
  String get aiCapThreadLabel => '대화당 시간당 답변 한도';

  @override
  String get aiCapMemberLabel => '고객 한 명당 하루 답변 한도';

  @override
  String get aiCapDailyLabel => '하루 전체 답변 한도';

  @override
  String get aiCapHint => '숫자만 입력해요. 비워두면 기본값을 써요.';

  @override
  String get apSocialOr => '또는';

  @override
  String get apSocialSignIn => '간편 로그인';

  @override
  String get apLoginKakao => '카카오로 계속하기';

  @override
  String get apLoginNaver => '네이버로 계속하기';

  @override
  String get apLoginGoogle => 'Google로 계속하기';

  @override
  String get apLoginApple => 'Apple로 계속하기';

  @override
  String get apDevSocialNote => '개발 모드예요. 실제 소셜 계정이 아니라 테스트 계정으로 로그인해요.';

  @override
  String get apSocialFailed => '간편 로그인에 실패했어요. 다시 시도해 주세요.';

  @override
  String get apProviderNotConfigured => '이 로그인 수단은 아직 준비 중이에요';

  @override
  String get apPhoneTaken => '이미 다른 계정에 등록된 번호예요';

  @override
  String get apPhoneAttachTitle => '휴대폰 번호를 인증해 주세요';

  @override
  String get apPhoneAttachBody => '예약과 기사 연락에 쓰는 번호예요. 한 번만 인증하면 돼요.';

  @override
  String get apPayAllTitle => '결제수단 선택';

  @override
  String get apPaySavedTitle => '저장한 결제수단';

  @override
  String get apPayMoreTitle => '모든 결제수단';

  @override
  String get apPayBillingHint => '한 번 등록하면 다음부터 한 번에 결제해요';

  @override
  String get apPayCheckoutHint => '결제창에서 마무리해요';

  @override
  String get apPayRegistering => '등록하는 중이에요';

  @override
  String get apPayManageHint => '등록한 결제수단으로 한 번에 결제해요. 간편결제는 여기서 추가할 수 있어요.';

  @override
  String get apMethodCard => '신용·체크카드';

  @override
  String get apMethodKakao => '카카오페이';

  @override
  String get apMethodNaver => '네이버페이';

  @override
  String get apMethodToss => '토스페이';

  @override
  String get apMethodPayco => '페이코';

  @override
  String get apMethodSamsung => '삼성페이';

  @override
  String get apMethodApple => '애플페이';

  @override
  String get apMethodTransfer => '계좌이체';

  @override
  String get apMethodVirtual => '가상계좌';

  @override
  String get apMethodPhone => '휴대폰 결제';

  @override
  String get apMethodUnknown => '기타 결제';

  @override
  String get apVaTitle => '입금 계좌가 준비됐어요';

  @override
  String get apVaWaiting => '입금 대기 중';

  @override
  String get apVaBody => '기한 안에 입금하면 예약이 확정돼요. 입금은 자동으로 확인돼요.';

  @override
  String get apVaBank => '은행';

  @override
  String get apVaAccount => '계좌번호';

  @override
  String get apVaHolder => '예금주';

  @override
  String get apVaAmount => '입금 금액';

  @override
  String apVaDue(String due) {
    return '$due까지 입금해 주세요';
  }

  @override
  String get apVaCopy => '복사';

  @override
  String get apVaCopied => '계좌번호를 복사했어요';

  @override
  String get apVaBannerTitle => '입금 대기 중인 예약이 있어요';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due까지';
  }

  @override
  String get apVaBannerAction => '계좌 보기';

  @override
  String get apPgTitle => '결제창';

  @override
  String get apPgDevNote => '개발 환경 전용 결제 시뮬레이션이에요. 실제 결제는 일어나지 않아요.';

  @override
  String apPgPay(String amount) {
    return '$amount 결제하기';
  }

  @override
  String get apPgIssue => '계좌 발급받기';

  @override
  String get apPgCancel => '결제 취소';

  @override
  String get apPgBrowserNote => '브라우저에서 결제를 마친 뒤 이 화면으로 돌아와 아래 버튼을 눌러 주세요.';

  @override
  String get apPgBrowserDone => '결제를 마쳤어요';

  @override
  String get apErrSlotFullRefunded => '방금 그 시간이 마감돼서 결제가 자동 취소됐어요';

  @override
  String get apErrCheckoutExpired => '결제 시간이 지났어요. 다시 시도해 주세요.';

  @override
  String get apIdentityTitle => '본인인증 (PASS)';

  @override
  String get apIdentityBody => '휴대폰 명의로 본인을 확인해요. 안전한 거래와 정산에 쓰여요.';

  @override
  String get apIdentityAction => '본인인증하기';

  @override
  String get apIdentityDone => '본인인증이 완료됐어요';

  @override
  String get apIdentityVerified => '인증 완료';

  @override
  String get apIdentityUnverified => '아직 인증하지 않았어요';

  @override
  String get apIdentityDevTitle => '테스트 본인인증';

  @override
  String get apIdentityDevBody => '개발 환경에서는 실제 인증 없이 통과해요.';

  @override
  String get apIdentityDevPass => '통과 처리';

  @override
  String get apPayManageTitle => '간편결제 등록';

  @override
  String get cTitle => '운영 콘솔';

  @override
  String get cEmail => '이메일';

  @override
  String get cPassword => '비밀번호';

  @override
  String get cLogin => '로그인';

  @override
  String get cLoginFailed => '이메일 또는 비밀번호가 맞지 않아요';

  @override
  String get cDashboard => '대시보드';

  @override
  String get cBookings => '예약';

  @override
  String get cQuoteDesk => '견적 데스크';

  @override
  String get cInbox => '상담함';

  @override
  String get cCatalog => '카탈로그 · 가격';

  @override
  String get cMarketing => '쿠폰 · 콘텐츠';

  @override
  String get cPartners => '파트너';

  @override
  String get cSettlements => '정산';

  @override
  String get cCustomers => '고객';

  @override
  String get cStaff => '직원';

  @override
  String get cSearchCommand => '검색 · 명령';

  @override
  String get cPaletteHint => '메뉴 이름이나 예약번호를 입력하세요';

  @override
  String get cTodayJobs => '오늘 작업';

  @override
  String get cOpenQuotes => '견적 대기';

  @override
  String get cUnassigned => '미배정';

  @override
  String get cUnreadThreads => '안 읽은 상담';

  @override
  String get cRevenue30 => '30일 결제액';

  @override
  String get cBookings30 => '30일 예약';

  @override
  String get cByService => '서비스별 예약 (30일)';

  @override
  String get cAllStatus => '전체 상태';

  @override
  String get cAllServices => '전체 서비스';

  @override
  String get cSearch => '검색 (예약번호, 전화, 이름, 주소)';

  @override
  String get cNoResults => '결과가 없어요';

  @override
  String get cNumber => '예약번호';

  @override
  String get cVisit => '방문';

  @override
  String get cService => '서비스';

  @override
  String get cStatus => '상태';

  @override
  String get cTeam => '팀';

  @override
  String get cAmount => '금액';

  @override
  String get cCustomer => '고객';

  @override
  String get cPayments => '결제';

  @override
  String get cChangeStatus => '상태 변경';

  @override
  String get cTeamName => '배정 팀 이름';

  @override
  String get cAssign => '팀 배정';

  @override
  String get cMarkDone => '완료 처리';

  @override
  String get cConfirm => '확정 처리';

  @override
  String get cCancelRefund => '취소 · 환불';

  @override
  String get cRefundAmount => '환불 금액 (비우면 전액)';

  @override
  String get cDone => '처리했어요';

  @override
  String get cAnswers => '고객 답변';

  @override
  String get cEstimateCalc => '자동 산정';

  @override
  String get cBase => '기본';

  @override
  String get cExtras => '추가';

  @override
  String get cSurcharge => '할증';

  @override
  String get cBeforeVat => '부가세 전';

  @override
  String get cProQuotes => '파트너 견적';

  @override
  String get cNoProQuotes => '아직 받은 견적이 없어요';

  @override
  String get cFinalPrice => '고객 최종 금액';

  @override
  String get cQuoteNote => '고객에게 보낼 메모';

  @override
  String get cSendQuote => '고객에게 견적 보내기';

  @override
  String get cQuoteSent => '견적을 보냈어요';

  @override
  String get cCustomerChats => '고객';

  @override
  String get cPartnerChats => '파트너';

  @override
  String get cSelectBooking => '예약을 선택하세요';

  @override
  String get cRefunded => '환불됨';

  @override
  String get cPartRefunded => '부분 환불';

  @override
  String get cFailed => '실패';

  @override
  String get cSelectThread => '대화를 선택하세요';

  @override
  String get cReplyHint => '답장 입력 · Ctrl+Enter 전송';

  @override
  String get cOpenBooking => '예약 열기';

  @override
  String get cShortcuts => 'J/K 이동 · Ctrl+K 명령';

  @override
  String get cPricing => '가격';

  @override
  String get cMinutes => '소요(분)';

  @override
  String get cActive => '판매 중';

  @override
  String get cSaved => '저장했어요';

  @override
  String get cSlotCapacity => '시간대별 수용량';

  @override
  String get cUnlimited => '제한 없음';

  @override
  String get cFormula => '견적 산정식';

  @override
  String get f_base_studio => '원룸 기본';

  @override
  String get f_base_one_and_half => '1.5룸 기본';

  @override
  String get f_base_two_rooms => '방 2개 기본';

  @override
  String get f_base_three_rooms => '방 3개 기본';

  @override
  String get f_base_four_plus => '방 4개 이상 기본';

  @override
  String get f_per_extra_bathroom => '욕실 추가당';

  @override
  String get f_per_balcony => '발코니당';

  @override
  String get f_duplex => '복층';

  @override
  String get f_no_elevator_high_floor => '엘리베이터 없음 + 3층 이상';

  @override
  String get cIssueCoupon => '쿠폰 발급';

  @override
  String get cCouponName => '쿠폰 이름';

  @override
  String get cCouponPhones => '대상 전화번호 (줄바꿈으로 구분)';

  @override
  String get cAllCustomers => '전체 고객에게';

  @override
  String cIssued(String n) {
    return '$n장 발급했어요';
  }

  @override
  String get cContent => '콘텐츠';

  @override
  String get cKind_notice => '공지';

  @override
  String get cKind_tip => '팁';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => '배너';

  @override
  String get cKind_legal => '약관';

  @override
  String get cNewContent => '새 콘텐츠';

  @override
  String get cTitleField => '제목';

  @override
  String get cBodyField => '본문';

  @override
  String get cSlug => '식별자 (약관: privacy / terms)';

  @override
  String get cVerify => '승인';

  @override
  String get cSuspend => '중지';

  @override
  String get cPro_pending => '승인 대기';

  @override
  String get cPro_verified => '활동 중';

  @override
  String get cPro_suspended => '중지됨';

  @override
  String get cCompleted => '완료';

  @override
  String get cCancelledN => '취소';

  @override
  String get cRating => '평점';

  @override
  String get cFeeRate => '수수료율 %';

  @override
  String get cRunPayouts => '정산 지급 실행';

  @override
  String get cPayoutDate => '지급 기준일';

  @override
  String cPayoutDone(String n) {
    return '$n명에게 지급 처리했어요';
  }

  @override
  String get cHold => '보류';

  @override
  String get cRelease => '보류 해제';

  @override
  String get cNet => '지급액';

  @override
  String get cAddStaff => '직원 추가';

  @override
  String get cRoleAdmin => '관리자';

  @override
  String get cRoleConsultant => '상담원';

  @override
  String get cDeactivate => '비활성화';

  @override
  String get cActivate => '활성화';

  @override
  String get cPasswordRule => '12자 이상';

  @override
  String get cAdminOnly => '관리자만 할 수 있어요';

  @override
  String cBookingsCount(String n) {
    return '예약 $n건';
  }

  @override
  String get cJoined => '가입';

  @override
  String get cNewBooking => '새 예약이 들어왔어요';

  @override
  String get cNewMessage => '새 메시지';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get next => '다음';

  @override
  String get close => '닫기';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get change => '변경';

  @override
  String get retry => '다시 시도';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get required => '필수';

  @override
  String get viewAll => '전체 보기';

  @override
  String get today => '오늘';

  @override
  String get errorGeneric => '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorNetwork => '인터넷 연결을 확인해 주세요';

  @override
  String get err_invalid_phone => '휴대폰 번호를 확인해 주세요';

  @override
  String get err_otp_invalid => '인증번호가 맞지 않아요';

  @override
  String get err_otp_expired => '인증번호가 만료됐어요. 다시 받아 주세요.';

  @override
  String get err_rate_limited => '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';

  @override
  String get err_studio_too_large => '원룸 청소는 10평 이하 집만 가능해요';

  @override
  String get err_date_out_of_range => '내일부터 60일 이내로 골라 주세요';

  @override
  String get err_slot_full => '그 시간은 마감됐어요. 다른 시간을 골라 주세요.';

  @override
  String get err_coupon_expired => '기간이 지난 쿠폰이에요';

  @override
  String get err_coupon_used => '이미 사용한 쿠폰이에요';

  @override
  String get err_coupon_wrong_service => '이 서비스에는 쓸 수 없는 쿠폰이에요';

  @override
  String get err_payment_failed => '결제가 승인되지 않았어요. 다른 결제수단을 써 주세요.';

  @override
  String get err_payment_method_required => '결제수단을 선택해 주세요';

  @override
  String get err_cancellation_window_closed => '방문 2일 전부터는 상담팀을 통해 취소할 수 있어요';

  @override
  String get err_address_required => '방문할 주소를 등록해 주세요';

  @override
  String get err_already_taken => '다른 파트너가 먼저 수락했어요';

  @override
  String get err_invalid_address => '주소 정보를 모두 입력해 주세요';

  @override
  String get tabHome => '홈';

  @override
  String get tabBookings => '예약';

  @override
  String get tabChat => '상담';

  @override
  String get tabMore => '더보기';

  @override
  String get introTitle => '전문가의 청소를\n가장 쉽게 예약하세요';

  @override
  String get introBody => '정찰 가격 · 검증된 청소팀 · 실시간 진행 상황';

  @override
  String get introStart => '휴대폰 번호로 시작하기';

  @override
  String get loginPhoneTitle => '휴대폰 번호를 알려주세요';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => '인증번호 받기';

  @override
  String get loginCodeTitle => '인증번호 6자리를 입력해 주세요';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone(으)로 보냈어요';
  }

  @override
  String get loginResend => '다시 받기';

  @override
  String get loginVerify => '확인';

  @override
  String get loginTerms => '계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요';

  @override
  String get profileTitle => '이름을 알려주세요';

  @override
  String get profileNameHint => '이름';

  @override
  String get profileDone => '시작하기';

  @override
  String get welcomeToast => '가입 축하 쿠폰 2장을 드렸어요';

  @override
  String get svc_studio => '원룸 청소';

  @override
  String get svc_kitchen => '주방 청소';

  @override
  String get svc_bathroom => '화장실 청소';

  @override
  String get svc_mattress => '매트리스 청소';

  @override
  String get svc_aircon => '에어컨 청소';

  @override
  String get svc_sofa => '소파 청소';

  @override
  String get svc_move_out => '이사 청소';

  @override
  String get svc_move_in => '입주 청소';

  @override
  String get svcShort_studio => '원룸';

  @override
  String get svcShort_kitchen => '주방';

  @override
  String get svcShort_bathroom => '화장실';

  @override
  String get svcShort_mattress => '매트리스';

  @override
  String get svcShort_aircon => '에어컨';

  @override
  String get svcShort_sofa => '소파';

  @override
  String get svcShort_move_out => '이사';

  @override
  String get svcShort_move_in => '입주';

  @override
  String get svcDesc_studio => '방 1개, 화장실 1개인 10평 이하 원룸을 2시간 동안 꼼꼼히 청소해요.';

  @override
  String get svcDesc_kitchen => '싱크대, 가스레인지, 후드 겉면, 상판을 중심으로 주방을 집중 청소해요.';

  @override
  String get svcDesc_bathroom => '선반, 수전, 세면대와 변기의 안팎을 청소하고 바닥 물기까지 정리해요.';

  @override
  String get svcDesc_mattress => '전문 장비로 먼지, 진드기, 얼룩을 흡입하고 스팀으로 살균 세척해요.';

  @override
  String get svcDesc_aircon => '분해 후 열교환기, 송풍팬, 필터를 고압 세척하고 살균으로 마무리해요.';

  @override
  String get svcDesc_sofa => '소재에 맞는 세제로 오염을 분해하고 습식 추출 방식으로 세척해요.';

  @override
  String get svcDesc_move_out => '이사 나가기 전, 짐을 뺀 집을 전문 청소팀이 장비를 가지고 방문해 청소해요.';

  @override
  String get svcDesc_move_in => '새 집에 들어가기 전, 전문 청소팀이 장비를 가지고 방문해 실내를 청소해요.';

  @override
  String get svcNotes_bathroom =>
      '배수구·변기 막힘이 있으면 서비스가 제한될 수 있어요\n특수 약품이 필요한 청소, 천장·환풍기 청소는 제공하지 않아요\n오래된 곰팡이·찌든 때는 완전히 제거되지 않을 수 있어요';

  @override
  String get svcNotes_mattress =>
      '싱글부터 킹 사이즈까지 같은 금액이에요\n세척 후 완전 건조까지 4~6시간 걸려요\n스프링 손상, 꺼짐 등 구조적인 문제는 개선되지 않아요';

  @override
  String get svcNotes_aircon =>
      '제조 10년 이상 제품은 분해 세척이 어려울 수 있어요\n실외기 청소는 포함되지 않아요\n세척 전후 정상 작동 여부를 함께 확인해요';

  @override
  String get svcNotes_sofa =>
      '가죽 소파는 클리닝과 보습 코팅으로 진행돼요\n오래된 얼룩·이염은 완전히 제거되지 않을 수 있어요\n완전 건조까지 4~6시간 걸려요';

  @override
  String get unitTitle_bathroom => '화장실 개수';

  @override
  String get unitTitle_mattress => '매트리스 개수';

  @override
  String get unitTitle_aircon => '에어컨 종류';

  @override
  String get unitTitle_sofa => '소파 크기';

  @override
  String unit_count(String n) {
    return '$n개';
  }

  @override
  String get unit_wall => '벽걸이 1대';

  @override
  String get unit_stand => '스탠드 1대';

  @override
  String get unit_two_in_one => '2in1 (스탠드+벽걸이)';

  @override
  String get unit_ceiling => '천장형 1대';

  @override
  String get unit_seat_1_2 => '1~2인용';

  @override
  String get unit_seat_3 => '3인용';

  @override
  String get unit_seat_4_plus => '4인용 이상';

  @override
  String get unit_l_shape => 'L자 · 카우치';

  @override
  String durH(String h) {
    return '$h시간';
  }

  @override
  String durHM(String h, String m) {
    return '$h시간 $m분';
  }

  @override
  String durM(String m) {
    return '$m분';
  }

  @override
  String about(String value) {
    return '약 $value';
  }

  @override
  String fromPrice(String price) {
    return '$price~';
  }

  @override
  String get quoteBadge => '견적';

  @override
  String get status0 => '상담 중';

  @override
  String get status1 => '예약 확정';

  @override
  String get status2 => '팀 배정 완료';

  @override
  String get status3 => '청소 완료';

  @override
  String get statusCancelled => '취소됨';

  @override
  String homeGreeting(String name) {
    return '$name님,\n오늘은 어디를 깨끗하게 할까요?';
  }

  @override
  String get homeGreetingAnon => '오늘은 어디를\n깨끗하게 할까요?';

  @override
  String get homeUpcoming => '다가오는 예약';

  @override
  String dDay(String days) {
    return 'D-$days';
  }

  @override
  String get homeServices => '어떤 청소가 필요하세요?';

  @override
  String get homeAddAddress => '주소를 등록하면 가능한 서비스와 가격을 바로 보여드려요';

  @override
  String get homeAddAddressCta => '주소 등록';

  @override
  String homeRebook(String service) {
    return '$service 다시 예약하기';
  }

  @override
  String get homeRebookBody => '지난번과 같은 조건으로 빠르게 예약해요';

  @override
  String get homeNotices => '새 소식';

  @override
  String get trustVat => '부가세 포함\n표시된 가격 그대로';

  @override
  String get trustCancel => '방문 2일 전까지\n무료 취소';

  @override
  String get trustCard => '카드 정보는\n결제사에만 보관';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => '날짜 고르기';

  @override
  String get notIncluded => '꼭 확인해 주세요';

  @override
  String studioBlockedTitle(String size) {
    return '$size평은 원룸 청소 대상이 아니에요';
  }

  @override
  String get studioBlockedBody => '상담팀이 집에 맞는 서비스를 추천해 드릴게요.';

  @override
  String get consultCta => '상담으로 문의하기';

  @override
  String get addressTitle => '어디로 방문할까요?';

  @override
  String get addressAdd => '새 주소 추가';

  @override
  String get addressLabel => '이름';

  @override
  String get addressLabelHint => '예: 우리집';

  @override
  String get addressDistrict => '구';

  @override
  String get addressRoad => '도로명 주소';

  @override
  String get addressDetail => '상세 주소';

  @override
  String get addressSize => '집 크기 (평)';

  @override
  String get addressSizeHelp => '전용면적 기준 · 1평 ≈ 3.3㎡';

  @override
  String get addressHome => '집';

  @override
  String get addressOffice => '사무실';

  @override
  String get addressEmpty => '저장된 주소가 없어요';

  @override
  String get addressSaved => '주소를 저장했어요';

  @override
  String pyeong(String n) {
    return '$n평';
  }

  @override
  String get scheduleTitle => '언제 방문할까요?';

  @override
  String get scheduleArrival => '도착 시간';

  @override
  String get scheduleFull => '마감';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end 도착';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration 소요 · $time쯤 끝나요';
  }

  @override
  String get scheduleRange => '내일부터 60일 이내로 예약할 수 있어요';

  @override
  String get morning => '오전';

  @override
  String get afternoon => '오후';

  @override
  String get scheduleQuoteNote => '정확한 도착 시간은 상담에서 안내해 드려요';

  @override
  String get goToPayment => '결제하러 가기';

  @override
  String get prepTitle => '방문 전에 준비해 주세요';

  @override
  String get prepBody => '준비되지 않으면 일부 작업이 제한될 수 있어요';

  @override
  String get prepAsk => '준비가 어렵다면 상담으로 미리 알려 주세요';

  @override
  String get tool_vacuum => '청소기';

  @override
  String get tool_trash => '쓰레기봉투';

  @override
  String get tool_mop => '막대걸레';

  @override
  String get tool_cloth => '손걸레';

  @override
  String get tool_gloves => '고무장갑';

  @override
  String get tool_sponge => '수세미';

  @override
  String get tool_spray => '다목적세제';

  @override
  String get checkoutTitle => '결제';

  @override
  String get coupon => '쿠폰';

  @override
  String get couponNone => '사용 안 함';

  @override
  String couponAvailable(String count) {
    return '사용 가능 $count장';
  }

  @override
  String get paymentMethod => '결제수단';

  @override
  String get addPaymentMethod => '결제수단 등록';

  @override
  String get methodCard => '신용·체크카드';

  @override
  String get methodKakao => '카카오페이';

  @override
  String get methodNaver => '네이버페이';

  @override
  String get methodToss => '토스페이';

  @override
  String get methodRegistered => '등록됨';

  @override
  String get methodAdded => '결제수단을 등록했어요';

  @override
  String get listPrice => '서비스 금액';

  @override
  String get discount => '쿠폰 할인';

  @override
  String get total => '결제 금액';

  @override
  String get vatIncluded => '부가세 포함';

  @override
  String payAmount(String amount) {
    return '$amount 결제하기';
  }

  @override
  String get needMethod => '결제수단을 등록해 주세요';

  @override
  String freeCancelUntil(String date) {
    return '$date까지 무료 취소';
  }

  @override
  String get doneTitle => '예약이 완료됐어요';

  @override
  String get doneBody => '청소팀이 배정되면 바로 알려드릴게요';

  @override
  String get doneQuoteTitle => '상담 요청이 접수됐어요';

  @override
  String get doneQuoteBody => '상담팀이 확인 후 최종 견적을 보내드려요. 견적은 상담 탭에서 확인할 수 있어요.';

  @override
  String get goHome => '홈으로';

  @override
  String get viewBooking => '예약 보기';

  @override
  String get bookingsTitle => '예약';

  @override
  String get bookingsUpcoming => '다가오는 예약';

  @override
  String get bookingsPast => '지난 예약';

  @override
  String get bookingsEmpty => '아직 예약이 없어요';

  @override
  String get bookingsEmptyBody => '첫 예약에 쓸 수 있는 쿠폰이 준비돼 있어요';

  @override
  String get bookNow => '청소 예약하기';

  @override
  String get detailTitle => '예약 상세';

  @override
  String get stepRequested => '상담 접수';

  @override
  String get stepConfirmed => '예약 확정';

  @override
  String get stepAssigned => '청소팀 배정';

  @override
  String get stepCompleted => '청소 완료';

  @override
  String teamVisiting(String team) {
    return '$team이(가) 방문해요';
  }

  @override
  String get photosSoon => '끝나면 전후 사진이 여기에 올라와요';

  @override
  String get before => '청소 전';

  @override
  String get after => '청소 후';

  @override
  String get prepCheck => '준비물 체크';

  @override
  String get prepAllSet => '모두 준비됐어요';

  @override
  String get visitAddress => '방문 주소';

  @override
  String get paid => '결제';

  @override
  String get askTeam => '상담팀에 문의하기';

  @override
  String get cancelBooking => '예약 취소';

  @override
  String get cancelTitle => '예약을 취소할까요?';

  @override
  String get cancelFree => '지금 취소하면 결제 금액 전액이 환불되고 쿠폰도 돌려드려요.';

  @override
  String get cancelKeep => '유지하기';

  @override
  String get cancelled => '예약이 취소됐어요';

  @override
  String get reschedule => '일정 변경';

  @override
  String get rescheduled => '일정을 변경했어요';

  @override
  String get visitNotes => '방문 요청사항';

  @override
  String get notesEntry => '출입 방법 (공동현관 비밀번호 등)';

  @override
  String get notesParking => '주차';

  @override
  String get notesOther => '기타';

  @override
  String get notesSaved => '요청사항을 저장했어요';

  @override
  String depositDue(String amount) {
    return '예약금 $amount을(를) 결제하면 예약이 확정돼요';
  }

  @override
  String get payDeposit => '예약금 결제하기';

  @override
  String get waitingQuote => '상담팀이 견적을 준비하고 있어요';

  @override
  String get estimate => '예상 금액';

  @override
  String get finalPrice => '최종 견적';

  @override
  String get deposit => '예약금';

  @override
  String get balance => '잔금';

  @override
  String balanceDue(String amount) {
    return '잔금 $amount을(를) 결제해 주세요';
  }

  @override
  String get payBalance => '잔금 결제하기';

  @override
  String get reviewTitle => '청소는 어떠셨나요?';

  @override
  String get reviewHint => '좋았던 점이나 아쉬운 점을 알려 주세요';

  @override
  String ratingStars(String n) {
    return '$n점';
  }

  @override
  String get reviewSubmit => '후기 남기기';

  @override
  String get reviewThanks => '소중한 후기 고마워요';

  @override
  String get bookAgain => '같은 조건으로 다시 예약';

  @override
  String get chatTitle => '상담';

  @override
  String get chatTeam => '상담팀';

  @override
  String get chatHours => '평일 09:00–18:00';

  @override
  String get chatEmpty => '궁금한 점이 있으면 언제든 물어보세요';

  @override
  String get chatNew => '새 상담';

  @override
  String get chatTopicTitle => '무엇이 궁금하세요?';

  @override
  String get topicOther => '기타 문의';

  @override
  String get chatHint => '메시지를 입력하세요';

  @override
  String get chatSend => '보내기';

  @override
  String get chatPhoto => '사진 보내기';

  @override
  String get chatTyping => '상담팀이 입력 중';

  @override
  String get quick_confirm => '예약 확정할게요';

  @override
  String get quick_price => '가격이 궁금해요';

  @override
  String get quick_date => '날짜를 바꾸고 싶어요';

  @override
  String get quick_parking => '주차가 가능한가요?';

  @override
  String get quick_hello => '안녕하세요';

  @override
  String get quick_duration => '얼마나 걸리나요?';

  @override
  String get quoteArrived => '최종 견적이 도착했어요';

  @override
  String get quoteDepositNow => '지금 예약금 10%';

  @override
  String get quoteBalanceLater => '청소 후 잔금';

  @override
  String get quotePay => '예약금 결제하고 확정하기';

  @override
  String get quotePaid => '결제 완료';

  @override
  String get requestCard => '견적 요청';

  @override
  String get sys_consultation_received => '상담이 접수됐어요';

  @override
  String sys_deposit_paid(String amount) {
    return '예약금 $amount이(가) 결제됐어요. 예약이 확정됐어요.';
  }

  @override
  String get sys_booking_cancelled => '예약이 취소됐어요';

  @override
  String sys_status_changed(String status) {
    return '예약 상태가 \'$status\'(으)로 바뀌었어요';
  }

  @override
  String get sys_job_completed => '청소가 끝났어요. 전후 사진을 확인해 보세요.';

  @override
  String sys_rescheduled(String date) {
    return '일정이 $date(으)로 변경됐어요';
  }

  @override
  String get sys_reschedule_declined => '파트너가 변경된 일정에 방문이 어려워요. 상담팀이 다시 조율할게요.';

  @override
  String get moreTitle => '더보기';

  @override
  String get moreScope => '서비스 범위';

  @override
  String get morePayments => '결제수단 관리';

  @override
  String get moreCoupons => '쿠폰';

  @override
  String get morePoints => '청소 포인트';

  @override
  String get moreAccount => '계정 정보';

  @override
  String get moreAddresses => '주소 관리';

  @override
  String get moreNotices => '공지사항';

  @override
  String get moreTips => '청소 팁';

  @override
  String get moreFaq => '자주 묻는 질문';

  @override
  String get morePartner => '파트너 제휴 문의';

  @override
  String get moreLanguage => '언어';

  @override
  String get langSystem => '기기 설정 따르기';

  @override
  String moreVersion(String v) {
    return '버전 $v';
  }

  @override
  String get morePrivacy => '개인정보 처리방침';

  @override
  String get moreTerms => '이용약관';

  @override
  String get moreLicenses => '오픈소스 라이선스';

  @override
  String get logout => '로그아웃';

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get deleteAccountBody => '개인정보가 삭제되고 되돌릴 수 없어요. 진행 중인 예약은 먼저 취소해 주세요.';

  @override
  String get couponsEmpty => '보유한 쿠폰이 없어요';

  @override
  String couponUntil(String date) {
    return '$date까지';
  }

  @override
  String get couponUsed => '사용 완료';

  @override
  String get couponExpired => '기간 만료';

  @override
  String get couponAnyService => '모든 서비스';

  @override
  String get coupon_welcome_studio => '가입 축하 원룸 쿠폰';

  @override
  String get coupon_welcome_any => '가입 축하 쿠폰';

  @override
  String get pointsBalance => '보유 포인트';

  @override
  String get pointsEmpty => '포인트 내역이 없어요';

  @override
  String get accountName => '이름';

  @override
  String get accountPhone => '휴대폰 번호';

  @override
  String get accountEmail => '이메일';

  @override
  String get accountLogin => '로그인 방식';

  @override
  String get accountLoginPhone => '휴대폰 인증';

  @override
  String get methodsEmpty => '등록된 결제수단이 없어요';

  @override
  String get noContent => '아직 등록된 내용이 없어요';

  @override
  String get quoteTypeTitle => '어떤 청소가 필요하세요?';

  @override
  String get type_standard => '퇴거 청소';

  @override
  String get type_same_day_move => '이사 당일 청소';

  @override
  String get type_some_luggage_left => '짐 일부 남음';

  @override
  String get type_normal_move_in => '일반 입주';

  @override
  String get type_after_interior => '인테리어 후';

  @override
  String get type_lived_in_deep_clean => '거주 중 대청소';

  @override
  String get luggageTitle => '짐은 어떤 상태인가요?';

  @override
  String get luggage_empty => '짐 없음';

  @override
  String get luggage_partly_unpacked => '일부 정리 중';

  @override
  String get luggage_fully_lived_in => '생활 중';

  @override
  String get luggage_unknown => '잘 모르겠어요';

  @override
  String get quoteBasicTitle => '집 구조를 알려주세요';

  @override
  String get buildingType => '건물 유형';

  @override
  String get building_apartment => '아파트';

  @override
  String get building_villa => '빌라';

  @override
  String get building_officetel => '오피스텔';

  @override
  String get building_house => '단독주택';

  @override
  String get building_other => '기타';

  @override
  String get layoutTitle => '구조';

  @override
  String get layout_studio => '원룸';

  @override
  String get layout_one_and_half => '1.5룸';

  @override
  String get layout_two_rooms => '방 2개';

  @override
  String get layout_three_rooms => '방 3개';

  @override
  String get layout_four_plus => '방 4개 이상';

  @override
  String get duplexTitle => '복층인가요?';

  @override
  String get quoteSpaceTitle => '공간을 알려주세요';

  @override
  String get bathroomsLabel => '화장실';

  @override
  String get balconiesLabel => '발코니 · 다용도실';

  @override
  String get elevatorTitle => '엘리베이터가 있나요?';

  @override
  String get floor3Label => '3층 이상이에요';

  @override
  String get quoteEstimateTitle => '예상 견적이에요';

  @override
  String get quoteEstimateBody => '상담에서 사진과 상황을 확인한 뒤 최종 금액이 정해져요';

  @override
  String get quoteG1 => '최종 금액은 상담에서 확정해요';

  @override
  String get quoteG2 => '예약금 10%로 확정, 잔금은 청소 후';

  @override
  String get quoteG3 => '확정 전에는 언제든 무료 취소';

  @override
  String get quoteConfirmTitle => '요청 내용을 확인해 주세요';

  @override
  String get quoteRequest => '상담 요청하기';

  @override
  String get quoteNoPayNow => '지금은 결제하지 않아요';

  @override
  String get summaryType => '청소 종류';

  @override
  String get summaryHome => '집 정보';

  @override
  String get summaryDate => '방문 일정';

  @override
  String get themeTitle => '테마';

  @override
  String get themeDark => '다크';

  @override
  String get themeLight => '라이트';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeTip => '테마 바꾸기';

  @override
  String get err_price_changed => '가격이 바뀌었어요. 새 견적을 확인하고 다시 시도해 주세요.';

  @override
  String get err_checkout_closed => '이 결제는 이미 종료됐어요. 다시 시작해 주세요.';

  @override
  String get err_checkout_refunded => '이 결제는 취소되어 환불됐어요.';

  @override
  String get err_already_paid => '이미 결제가 끝났어요.';

  @override
  String get err_quote_not_payable => '아직 결제할 수 없는 견적이에요. 상담팀에 확인해 주세요.';

  @override
  String get err_payment_method_disabled => '지금은 이 결제수단을 쓸 수 없어요.';

  @override
  String get err_invalid_payment_method => '선택한 결제수단을 쓸 수 없어요. 다른 방법을 골라 주세요.';

  @override
  String get err_balance_not_due => '잔금은 아직 결제할 시기가 아니에요.';

  @override
  String get err_invalid_slot => '이 서비스에서는 고를 수 없는 시간이에요.';

  @override
  String get err_booking_changed => '예약 내용이 바뀌었어요. 새로고침 후 다시 확인해 주세요.';

  @override
  String get err_booking_closed => '이 예약은 더 이상 바꿀 수 없어요.';

  @override
  String get err_reschedule_closed => '방문 날짜는 지금 변경할 수 없어요. 상담팀에 문의해 주세요.';

  @override
  String get err_too_many_open_requests =>
      '진행 중인 요청이 너무 많아요. 하나를 마무리한 뒤 다시 시도해 주세요.';

  @override
  String get err_already_reviewed => '이미 후기를 남긴 방문이에요.';

  @override
  String get err_identity_not_verified => '본인인증을 먼저 완료해 주세요.';

  @override
  String get err_email_taken => '이미 사용 중인 이메일이에요.';

  @override
  String get err_invalid_email => '이메일 주소를 확인해 주세요.';

  @override
  String get err_file_too_large => '파일이 너무 커요. 더 작은 파일을 올려 주세요.';

  @override
  String get err_unsupported_image => '지원하지 않는 사진 형식이에요. JPG나 PNG로 올려 주세요.';

  @override
  String get err_upload_quota => '오늘은 업로드 한도에 도달했어요. 내일 다시 시도해 주세요.';

  @override
  String get err_provider_unreachable => '서비스에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get err_invalid_token => '로그인 정보가 올바르지 않아요. 다시 시도해 주세요.';

  @override
  String get err_invalid_transition => '지금은 이 상태로 바꿀 수 없어요.';

  @override
  String get err_job_not_started => '먼저 작업을 시작해 주세요.';

  @override
  String get err_job_not_active => '지금은 진행할 수 없는 작업이에요.';

  @override
  String get err_quote_locked => '확정된 견적이라 수정할 수 없어요.';

  @override
  String get err_request_closed => '이미 마감된 요청이에요.';

  @override
  String get err_team_full => '팀 인원이 가득 찼어요.';

  @override
  String get err_invalid_webhook_secret => '웹훅 시크릿은 whsec_로 시작해야 해요.';

  @override
  String get err_invalid_endpoint => '엔드포인트는 https://로 시작해야 해요.';

  @override
  String get err_invalid_bucket => '버킷 이름이 올바르지 않아요.';

  @override
  String get err_invalid_region => '리전 값이 올바르지 않아요.';

  @override
  String get err_invalid_retention => '보관 기간 값이 범위를 벗어났어요.';

  @override
  String get err_invalid_service_account => '서비스 계정 파일이 올바르지 않아요.';

  @override
  String get err_invalid_mode => 'AI 응답 모드를 다시 골라 주세요.';

  @override
  String get err_invalid_model => 'AI 모델 이름이 올바르지 않아요.';

  @override
  String get err_missing_field => '필수 항목을 모두 입력해 주세요.';

  @override
  String get err_invalid_amount => '금액을 올바르게 입력해 주세요.';

  @override
  String get err_cannot_deactivate_self => '본인 계정은 비활성화할 수 없어요.';

  @override
  String get err_invalid_coupon => '쿠폰 정보가 올바르지 않아요.';

  @override
  String get err_settlement_state => '지금은 정산 상태를 바꿀 수 없어요.';

  @override
  String get err_deposit_required => '예약금을 먼저 받아야 해요.';

  @override
  String get err_payout_state => '정산 상태가 바뀌었어요. 새로고침 후 다시 확인해 주세요.';

  @override
  String get err_payout_provider => '이 지급 방식은 지금 쓸 수 없어요.';

  @override
  String get err_unsupported_bank => '이 은행은 지급을 지원하지 않아요.';

  @override
  String get err_toss_unverified => '토스 지급대행은 아직 연결할 수 없어요. 직접 이체를 써 주세요.';

  @override
  String get err_invalid_cap => '한도는 정해진 범위 안의 숫자로 입력해 주세요.';

  @override
  String get err_invalid_capacity => '정원은 숫자로 입력해 주세요.';

  @override
  String get fFinance => '재무';

  @override
  String get fPeriodDay => '일';

  @override
  String get fPeriodWeek => '주';

  @override
  String get fPeriodMonth => '월';

  @override
  String get fPeriodCustom => '기간';

  @override
  String get fFrom => '시작';

  @override
  String get fTo => '종료';

  @override
  String get fGross => '총결제액';

  @override
  String get fRefunds => '환불';

  @override
  String get fNetRevenue => '순매출';

  @override
  String get fPlatformFee => '플랫폼 수수료';

  @override
  String get fPaidOut => '파트너 지급 완료';

  @override
  String get fPendingOut => '지급 예정';

  @override
  String get fHeldOut => '보류';

  @override
  String get fVatEstimate => '부가세 추정';

  @override
  String get fVatNote => '플랫폼 수수료의 10%로 계산한 추정치예요. 세무사와 확인하세요.';

  @override
  String get fAov => '평균 주문액';

  @override
  String get fBookings => '예약';

  @override
  String get fCancelRate => '취소율';

  @override
  String get fDiscounts => '할인·쿠폰';

  @override
  String get fMethods => '결제수단';

  @override
  String get fTrend => '추이';

  @override
  String fRangeDays(String n) {
    return '최근 $n일';
  }

  @override
  String get fRangeWeeks => '최근 12주';

  @override
  String get fRangeMonths => '최근 12개월';

  @override
  String get fByPartner => '파트너별 정산';

  @override
  String get fByService => '서비스별 매출';

  @override
  String get fExportTitle => '회계 자료 내려받기';

  @override
  String get fExportLedger => '결제 원장 CSV';

  @override
  String get fExportSettlements => '정산 내역 CSV';

  @override
  String get fExportMonthly => '월별 요약 CSV (세무사용)';

  @override
  String get fDownload => 'CSV 내려받기';

  @override
  String get fDownloadWebOnly => 'CSV 내려받기는 웹 콘솔에서 할 수 있어요';

  @override
  String get fDownloadFailed => '내려받지 못했어요';

  @override
  String get fNoRecords => '이 기간에 기록이 없어요';

  @override
  String get fLoadFailed => '재무 자료를 불러오지 못했어요';

  @override
  String get fRetry => '다시 시도';

  @override
  String get fColPartner => '파트너';

  @override
  String get fColJobs => '건수';

  @override
  String get fColSettled => '정산 총액';

  @override
  String get fColFee => '수수료';

  @override
  String get fColNet => '지급액';

  @override
  String get pEarnings => '수입';

  @override
  String get pNextPayout => '다음 지급';

  @override
  String pNextPayoutOn(String date) {
    return '$date 지급 예정';
  }

  @override
  String get pNoPayout => '예정된 지급이 없어요';

  @override
  String get pPendingTotal => '지급 대기';

  @override
  String get pPaidTotal => '지급 완료';

  @override
  String get pWeekly => '주간';

  @override
  String get pMonthly => '월간';

  @override
  String proofHomes(String count) {
    return '이번 달 $count집을 청소했어요';
  }

  @override
  String proofRating(String rating, String count) {
    return '평균 평점 $rating점 · 후기 $count개';
  }

  @override
  String get proofReviewsTitle => '최근 후기';

  @override
  String get rebookTitle => '지난번 서비스를 다시 예약할까요?';

  @override
  String rebookBody(String service, String date) {
    return '$service · 지난 방문 $date';
  }

  @override
  String get rebookButton => '다시 예약하기';

  @override
  String seatsLeft(String count) {
    return '$count자리 남음';
  }

  @override
  String get reviewSheetTitle => '이번 청소는 어떠셨나요?';

  @override
  String get reviewPhotosAdd => '사진 추가';

  @override
  String get reviewPhotosHint => '사진은 최대 5장까지 올릴 수 있어요';

  @override
  String get reviewSaved => '후기를 남겨 주셔서 고마워요';

  @override
  String get reviewPhotoFailed => '사진을 올리지 못했어요. 다시 시도해 주세요.';

  @override
  String get referralTitle => '친구를 초대하면 쿠폰을 드려요';

  @override
  String referralBody(String amount) {
    return '친구가 첫 예약을 마치면 두 분 모두 $amount 쿠폰을 받아요';
  }

  @override
  String get referralCopy => '코드 복사';

  @override
  String get referralCopied => '추천 코드를 복사했어요';

  @override
  String get referralClaimTitle => '추천 코드가 있나요?';

  @override
  String get referralClaimField => '추천 코드 입력';

  @override
  String get referralClaimButton => '등록';

  @override
  String get referralClaimed => '추천 코드가 등록됐어요';

  @override
  String referralStats(String invited, String rewarded) {
    return '초대 $invited명 · 보상 $rewarded건';
  }

  @override
  String get err_self_referral => '내 추천 코드는 쓸 수 없어요';

  @override
  String get err_referee_already_booked => '예약 이후에는 추천 코드를 등록할 수 없어요';

  @override
  String get err_already_referred => '이미 추천 코드를 등록했어요';

  @override
  String get err_invalid_referral_code => '추천 코드를 확인해 주세요';

  @override
  String get err_referral_disabled => '지금은 친구 추천을 받지 않아요';

  @override
  String get err_invalid_photos => '사진은 말끔이 올린 파일만 첨부할 수 있어요';

  @override
  String get welcomeOfferTitle => '첫 예약 할인';

  @override
  String get welcomeOfferBody => '신규 고객의 첫 예약에 자동으로 적용돼요. 쿠폰과는 중복되지 않아요.';

  @override
  String get offerKindAmount => '정액(원)';

  @override
  String get offerKindPercent => '정률(%)';

  @override
  String get offerValue => '할인 값';

  @override
  String get offerEnabled => '사용';

  @override
  String get offerSaved => '저장했어요';

  @override
  String get referralSettingsTitle => '친구 추천 보상';

  @override
  String get referralSettingsBody =>
      '친구가 첫 예약을 완료하고 결제까지 끝나면 지급돼요. 본인 추천, 같은 번호 중복은 막아요.';

  @override
  String get referralRewardAmount => '보상 금액(원)';

  @override
  String get reviewsModerationTitle => '후기 관리';

  @override
  String get reviewHide => '숨기기';

  @override
  String get reviewShow => '다시 보이기';

  @override
  String get reviewHiddenTag => '숨김';

  @override
  String get growthAverageRating => '평균 평점';

  @override
  String growthReviewCount(String count) {
    return '후기 $count개';
  }

  @override
  String get growthReferralConversion => '친구 추천 전환';

  @override
  String get growthTab => '성장';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded/$invited명';
  }

  @override
  String get cOps => '시스템 상태';

  @override
  String get oLevelGreen => '정상';

  @override
  String get oLevelYellow => '확인 필요';

  @override
  String get oLevelRed => '조치 필요';

  @override
  String get oOverall => '서버 상태';

  @override
  String get oRefresh => '새로고침';

  @override
  String get oVersion => '버전';

  @override
  String get oUptime => '가동 시간';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get oChecks => '점검 항목';

  @override
  String get oCheckDb => '데이터베이스';

  @override
  String oCheckDbValue(String ms, String mb) {
    return '응답 ${ms}ms · 용량 ${mb}MB';
  }

  @override
  String get oCheckDisk => '서버 디스크';

  @override
  String oCheckDiskValue(String pct) {
    return '여유 $pct%';
  }

  @override
  String get oCheckBackup => '자동 백업';

  @override
  String oCheckBackupValue(String hours) {
    return '마지막 백업 $hours시간 전';
  }

  @override
  String get oCheckBackupNone => '백업 기록이 없어요';

  @override
  String get oCheckErrors => '서버 오류 (24시간)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count건';
  }

  @override
  String get oCheckPayments => '결제 확인 필요';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count건 (24시간)';
  }

  @override
  String get oCheckWebhook => '결제 알림 (웹훅)';

  @override
  String oCheckWebhookValue(String count) {
    return '서명 실패 $count건 (24시간)';
  }

  @override
  String get oIntegrations => '외부 서비스';

  @override
  String get oIntNotSet => '설정 안 됨';

  @override
  String oIntLastOk(String at) {
    return '마지막 성공 $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return '마지막 실패 $at ($code)';
  }

  @override
  String get oIntNever => '아직 사용 기록이 없어요';

  @override
  String get oActDb =>
      '데이터베이스에 연결하지 못했어요. 서버에서 malkkeum logs 로 원인을 보고, 계속되면 서버를 재시작하세요.';

  @override
  String get oActDisk => '디스크 여유 공간이 10% 아래예요. 오래된 백업 파일을 지우거나 서버 디스크를 늘려 주세요.';

  @override
  String get oActBackup =>
      '자동 백업이 오래됐어요. 서버에서 malkkeum backup 을 실행하고 backups/backup.log 를 확인하세요.';

  @override
  String get oActErrors =>
      '서버 오류가 많아요. malkkeum logs 에서 error 줄을 확인하고, 반복되면 개발사에 전달하세요.';

  @override
  String get oActPayments =>
      '결제는 됐지만 자동 처리가 안 됐을 수 있어요. PortOne 관리자 화면에서 해당 결제를 확인하고 필요하면 직접 환불하세요.';

  @override
  String get oActWebhook =>
      '결제 알림의 서명 검사가 실패했어요. 설정 > 결제(PortOne)에서 웹훅 시크릿을 다시 입력하세요.';

  @override
  String get oActIntegration =>
      '연동이 실패하고 있어요. 설정 화면에서 키를 다시 확인하고 [연결 테스트] 를 누르세요.';

  @override
  String get oActNotSet => '아직 설정되지 않았어요. 설정 화면에서 키를 입력하세요.';

  @override
  String get oAlerts => '알림 설정';

  @override
  String get oAlertsHint =>
      '문제가 생기면 상담함과 사장님 휴대폰(문자)으로 알려 드려요. 같은 문제는 6시간에 한 번만 보내요.';

  @override
  String get oRuleSms => '문자(SMS) 발송 실패';

  @override
  String get oRulePush => '앱 알림(푸시) 실패';

  @override
  String get oRulePayment => '결제 연동 실패';

  @override
  String get oRuleStuck => '결제 자동 처리 실패';

  @override
  String get oRuleSocial => '소셜 로그인 실패';

  @override
  String get oRuleBackup => '자동 백업 누락';

  @override
  String get oRuleDisk => '디스크 부족';

  @override
  String get oQuietHours => '조용한 시간';

  @override
  String get oQuietFrom => '시작';

  @override
  String get oQuietTo => '끝';

  @override
  String oHour(String hour) {
    return '$hour시';
  }

  @override
  String get oQuietHint => '이 시간에는 알림을 보내지 않고, 끝난 뒤에 한 번 알려 드려요.';

  @override
  String get oAlertPhone => '알림 받을 휴대폰';

  @override
  String get oAlertPhoneHint => '비워 두면 사업자 정보의 고객센터 번호로 보내요.';

  @override
  String get oSave => '저장';

  @override
  String get oSaved => '알림 설정을 저장했어요';

  @override
  String get oSaveFailed => '저장하지 못했어요. 입력값을 확인해 주세요.';

  @override
  String get oLoadFailed => '상태를 불러오지 못했어요';

  @override
  String get oBackupOffsite => '외부 백업 (S3)';

  @override
  String get oBackupOffsiteOff => '꺼져 있어요. 설정 > 외부 백업 에서 켤 수 있어요.';

  @override
  String get oLastBackup => '마지막 백업';

  @override
  String get oDiskFree => '여유 공간';

  @override
  String get oNoData => '아직 데이터가 없어요';

  @override
  String get cIntBackup => '외부 백업 (S3 호환)';

  @override
  String get pTabJobs => '일감';

  @override
  String get pTabQuotes => '내 견적';

  @override
  String get pTabSchedule => '일정';

  @override
  String get pIntroTitle => '청소 전문가를 위한\n일감 · 일정 · 정산';

  @override
  String get pIntroBody => '원하는 지역과 시간에만 일하고, 매주 정산 받으세요';

  @override
  String get pOnbTitle => '파트너 정보를 알려주세요';

  @override
  String get pOnbName => '대표자 이름';

  @override
  String get pOnbTeam => '팀 이름';

  @override
  String get pOnbServices => '할 수 있는 서비스';

  @override
  String get pOnbAreas => '활동 지역';

  @override
  String get pOnbDone => '가입 신청';

  @override
  String get pPendingTitle => '승인을 기다리고 있어요';

  @override
  String get pPendingBody => '운영팀이 확인 후 승인하면 알림을 보내드려요. 그동안 정산 계좌를 등록해 주세요.';

  @override
  String get pSuspended => '계정이 일시 중지됐어요. 운영팀에 문의해 주세요.';

  @override
  String get pDirect => '바로 예약';

  @override
  String get pQuoteReq => '견적 요청';

  @override
  String get pShowClosed => '마감된 일감도 보기';

  @override
  String get pSortNewest => '최신 요청순';

  @override
  String get pSortVisit => '가까운 방문일순';

  @override
  String get pSortAmount => '금액 높은순';

  @override
  String get pNoJobs => '지금 맞는 일감이 없어요';

  @override
  String get pNoJobsBody => '서비스·지역·근무 시간을 넓히면 더 많은 일감을 볼 수 있어요';

  @override
  String get pPayout => '예상 정산';

  @override
  String get pCustomerEstimate => '고객 예상가';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => '마감';

  @override
  String get pPrivacyNote => '정확한 주소와 고객 정보는 수락 후에 보여요';

  @override
  String get pAccept => '수락하기';

  @override
  String get pAcceptConfirm => '이 일감을 수락할까요?';

  @override
  String get pAcceptBody =>
      '수락하면 일정에 추가되고 고객에게 팀 배정 알림이 가요. 방문 2일 전부터는 취소가 어려워요.';

  @override
  String get pAccepted => '일감을 수락했어요';

  @override
  String get pSendQuote => '견적 보내기';

  @override
  String get pQuotePrice => '고객 결제 금액';

  @override
  String get pQuoteNote => '상담팀에 전할 메모';

  @override
  String get pQuoteSent => '견적을 보냈어요';

  @override
  String pFee(String rate) {
    return '수수료 $rate%';
  }

  @override
  String get pYouGet => '받을 금액';

  @override
  String get pQuoteAll => '전체';

  @override
  String get pQ_waiting => '대기';

  @override
  String get pQ_selected => '선택됨';

  @override
  String get pQ_rejected => '미선택';

  @override
  String get pQ_closed => '종료';

  @override
  String get pUnseenOnly => '새 결과만';

  @override
  String get pNoQuotes => '보낸 견적이 없어요';

  @override
  String get pMyQuote => '내 견적';

  @override
  String get pWithdraw => '견적 철회';

  @override
  String get pWithdrawn => '견적을 철회했어요';

  @override
  String get pOnlyMine => '내 일정만';

  @override
  String pJobsCount(String n) {
    return '$n건';
  }

  @override
  String get pNoSchedule => '이 날은 일정이 없어요';

  @override
  String get pCancelledBanner => '고객이 취소한 일감이에요. 완료 처리할 수 없어요.';

  @override
  String pRescheduleBanner(String from, String to) {
    return '일정 변경 요청: $from → $to';
  }

  @override
  String get pRescheduleOk => '가능해요';

  @override
  String get pRescheduleNo => '어려워요';

  @override
  String get pCustomer => '고객';

  @override
  String get pCall => '안심번호로 전화';

  @override
  String get pCallSoon => '안심번호 연결은 서비스 개시 시 활성화돼요';

  @override
  String get pQuietHours => '20시 이후에는 전화하지 말아 주세요';

  @override
  String get pAssignee => '담당자';

  @override
  String get pChangeAssignee => '담당자 변경';

  @override
  String get pCustomerRequests => '고객 요청사항';

  @override
  String get pTeamMemo => '팀 메모 (고객에게 보이지 않아요)';

  @override
  String get pMemoSaved => '메모를 저장했어요';

  @override
  String get pPayoutBreakdown => '정산 내역';

  @override
  String get pAfterBalance => '고객 잔금 결제 후 정산돼요';

  @override
  String get pChatOps => '운영팀과 채팅';

  @override
  String get pComplete => '작업 완료 체크';

  @override
  String get pBeforePhotos => '청소 전 사진';

  @override
  String get pAfterPhotos => '청소 후 사진';

  @override
  String get pAddPhoto => '사진 추가';

  @override
  String get pChecklist => '확인 항목';

  @override
  String get pCheck1 => '요청한 모든 공간을 청소했어요';

  @override
  String get pCheck2 => '쓰레기를 정리하고 도구를 회수했어요';

  @override
  String get pCheck3 => '창문·전기·수도를 확인했어요';

  @override
  String get pCheck4 => '고객 요청사항을 반영했어요';

  @override
  String get pCompleteCta => '완료 처리';

  @override
  String get pCompleteNeed => '사진을 각 1장 이상 올리고 모든 항목을 체크해 주세요';

  @override
  String get pCompleted => '수고하셨어요!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$date에 $amount 정산 예정';
  }

  @override
  String get pPayoutWaiting => '고객 잔금 결제 후 정산일이 정해져요';

  @override
  String get pPendingPayout => '정산 예정 금액';

  @override
  String get pSettlements => '정산 내역';

  @override
  String get pS_waiting_balance => '잔금 대기';

  @override
  String get pS_pending => '정산 예정';

  @override
  String get pS_paid => '지급 완료';

  @override
  String get pS_held => '보류';

  @override
  String get pReviews => '고객 리뷰';

  @override
  String get pNoReviews => '아직 리뷰가 없어요';

  @override
  String get pReplyLater => '답글 기능은 곧 열려요';

  @override
  String get pServicesAreas => '서비스 · 지역';

  @override
  String get pPayoutAccount => '정산 계좌';

  @override
  String get pBank => '은행';

  @override
  String get pAccountNumber => '계좌번호';

  @override
  String get pHolder => '예금주';

  @override
  String get pVerified => '확인 완료';

  @override
  String get pUnverified => '확인 중';

  @override
  String get pAccountSaved => '계좌를 저장했어요. 변경 시 다시 확인돼요.';

  @override
  String get pWorkSchedule => '근무 일정';

  @override
  String get pWeekdays => '근무 요일';

  @override
  String get pDayParts => '근무 시간대';

  @override
  String get pDaysOff => '쉬는 날';

  @override
  String get pAddDayOff => '쉬는 날 추가';

  @override
  String get pSaved => '저장했어요';

  @override
  String get pTeam => '팀원';

  @override
  String get pOwner => '대표';

  @override
  String get pInvited => '초대됨';

  @override
  String get pInvite => '팀원 초대';

  @override
  String get pInviteSent => '초대 문자를 보냈어요';

  @override
  String get pRemove => '내보내기';

  @override
  String get pNotifications => '알림 설정';

  @override
  String get pNotifyDirect => '새 바로 예약 일감';

  @override
  String get pNotifyQuotes => '견적 요청 · 결과';

  @override
  String get pNotifyChat => '운영팀 메시지';

  @override
  String get pQuietNight => '야간 방해 금지 (22–08시)';

  @override
  String get pNewInquiry => '새 문의';

  @override
  String get pTopic_settlement => '정산';

  @override
  String get pTopic_reschedule => '일정 변경 · 취소';

  @override
  String get pTopic_app => '앱 사용';

  @override
  String get pOpsTeam => '운영팀';

  @override
  String get pViewJob => '일감 보기';

  @override
  String pBookingNo(String n) {
    return '예약번호 $n';
  }

  @override
  String get pSize => '면적';

  @override
  String get pSchedule => '일정';

  @override
  String get pSpace => '공간 정보';

  @override
  String get cIntPayout => '파트너 지급';

  @override
  String get poTabSettlements => '정산';

  @override
  String get poTabPayouts => '지급 내역';

  @override
  String get poState_requested => '요청됨';

  @override
  String get poState_sent => '전송됨';

  @override
  String get poState_paid => '지급 완료';

  @override
  String get poState_failed => '실패';

  @override
  String get poProviderManual => '직접 이체';

  @override
  String get poProviderToss => '토스 지급대행';

  @override
  String get poShowAccount => '계좌 보기';

  @override
  String get poAccountTitle => '이체 정보';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '$holder · $bank · $account\n$amount원을 위 계좌로 보낸 뒤 확인을 눌러 주세요.';
  }

  @override
  String get poConfirmPaid => '이체 완료로 표시';

  @override
  String get poMarkFailed => '실패로 표시';

  @override
  String get poReasonTitle => '실패 사유';

  @override
  String get poReasonHint => '예: 계좌 오류, 이체 취소';

  @override
  String get poSend => '토스로 지급 요청';

  @override
  String get poSync => '상태 확인';

  @override
  String get poRetry => '다시 시도';

  @override
  String get poNoPayouts => '지급 내역이 없어요';

  @override
  String poRequestedToast(String n) {
    return '지급 요청 $n건을 만들었어요';
  }

  @override
  String get poReasonRequired => '사유를 입력해 주세요';

  @override
  String get poRevealNote => '계좌 정보는 조회 기록에 남아요';

  @override
  String get cSetup => '설정';

  @override
  String get cSetupTitle => '서비스 시작 준비';

  @override
  String cSetupProgress(String done, String total) {
    return '$done/$total 완료';
  }

  @override
  String get cSetupAllDone => '모든 준비가 끝났어요!';

  @override
  String get cSetupBusiness => '사업장 정보';

  @override
  String get cSetupBusinessName => '서비스 이름';

  @override
  String get cSetupSupportPhone => '고객센터 전화';

  @override
  String get cSetupSupportEmail => '고객센터 이메일';

  @override
  String get cSetupSupportHours => '상담 시간';

  @override
  String get cSetupColor => '대표 색상';

  @override
  String get cSetupLogo => '로고 올리기';

  @override
  String get cSetupCompany => '사업자 정보 (앱·웹사이트 하단에 표시)';

  @override
  String get cSetupLegalName => '상호(법인명)';

  @override
  String get cSetupCeo => '대표자';

  @override
  String get cSetupRegNo => '사업자등록번호';

  @override
  String get cSetupMailOrderNo => '통신판매업 신고번호';

  @override
  String get cSetupAddress => '사업장 주소';

  @override
  String get cSetupPrivacyOfficer => '개인정보 보호책임자';

  @override
  String get cSetupStoreLinks => '앱 스토어 주소 (출시 후 입력하면 웹사이트 버튼이 켜져요)';

  @override
  String get cSetupCustomerApp => '고객 앱';

  @override
  String get cSetupPartnerApp => '파트너 앱';

  @override
  String get cSetupPayMethods => '결제 수단';

  @override
  String get cSetupPayMethodsHint => '고객 앱에 보여줄 결제 수단을 켜고 꺼요. 바로 적용돼요.';

  @override
  String get cReviewTitle => '스토어 심사용 데모 계정';

  @override
  String get cReviewHint =>
      '앱 심사원은 한국 문자를 받을 수 없어요. 아래 번호와 6자리 코드를 심사 메모에 적어 주세요. 기간이 지나면 자동으로 꺼져요.';

  @override
  String get cReviewPhone => '데모 전화번호';

  @override
  String get cReviewCode => '고정 인증 코드 (숫자 6자리)';

  @override
  String cReviewActiveUntil(String date) {
    return '$date까지 사용 가능';
  }

  @override
  String get cReviewEnable => '켜기 (14일)';

  @override
  String get pDeleteAccountBody =>
      '팀과 개인정보가 삭제되고 되돌릴 수 없어요. 배정된 작업이 있거나 정산이 남아 있으면 먼저 마무리해 주세요.';

  @override
  String get err_has_active_jobs => '배정된 작업이 있어요. 작업을 마치거나 상담원에게 이관을 요청해 주세요.';

  @override
  String get err_pending_payouts => '아직 정산이 남아 있어요. 지급이 끝난 뒤 탈퇴할 수 있어요.';

  @override
  String get err_phone_required => '작업을 받으려면 먼저 휴대폰 번호를 인증해 주세요.';

  @override
  String get nAlerts => '알림';

  @override
  String get nEmpty => '새 알림이 없어요';

  @override
  String nUnread(String count) {
    return '안 읽은 알림 $count개';
  }

  @override
  String get pVerifyPhone => '번호 인증';

  @override
  String get mMyJobs => '내 작업';

  @override
  String get mNoJobs => '배정된 작업이 없어요. 팀장이 작업을 배정하면 여기에 보여요.';

  @override
  String mTeam(String team) {
    return '$team 팀원';
  }

  @override
  String get cSetupSave => '저장';

  @override
  String get cSetupSaved => '저장했어요';

  @override
  String get cSetupTest => '연결 테스트';

  @override
  String get cSetupClear => '연결 해제';

  @override
  String get cSetupConnected => '연결됨';

  @override
  String get cSetupNotConnected => '연결 안 됨';

  @override
  String get cSetupFromEnv => '서버 설정 사용 중';

  @override
  String get cSetupCheckInApp => '저장됨 · 앱에서 로그인해 확인하세요';

  @override
  String get cSetupInvalidKey => '키가 올바르지 않아요. 복사한 값을 다시 확인해 주세요';

  @override
  String get cSetupUnreachable => '서비스에 연결할 수 없어요. 잠시 후 다시 시도해 주세요';

  @override
  String get cSetupKeepValue => '저장된 값 유지 (바꿀 때만 입력)';

  @override
  String get cSetupGuide => '따라 하기';

  @override
  String get cSetupOpenSite => '사이트 열기';

  @override
  String get cSetupWebhook => '웹훅 주소 (PortOne 콘솔에 붙여넣기)';

  @override
  String get cCopied => '복사했어요';

  @override
  String get cSetupDevMode => '테스트 모드예요. 실제 결제·문자는 나가지 않아요';

  @override
  String get cSetupOptional => '선택';

  @override
  String get cIntPortone => '결제 (PortOne)';

  @override
  String get cIntSolapi => '문자 · 알림톡 (Solapi)';

  @override
  String get cIntPush => '앱 푸시 알림 (Firebase)';

  @override
  String get cIntKakao => '카카오 로그인';

  @override
  String get cIntNaver => '네이버 로그인';

  @override
  String get cIntGoogle => '구글 로그인';

  @override
  String get cIntApple => '애플 로그인';

  @override
  String get cFirstRunTitle => '환영합니다! 사장님 계정을 만들어 주세요';

  @override
  String get cFirstRunBody =>
      '설치할 때 화면에 나온 12자리 설치 코드를 입력하세요. 이 계정으로 모든 설정을 관리해요.';

  @override
  String get cFirstRunCode => '설치 코드';

  @override
  String get cName => '이름';

  @override
  String get cFirstRunCreate => '계정 만들고 시작하기';

  @override
  String get cWrongSetupCode => '설치 코드가 맞지 않아요';

  @override
  String get cWeakPassword => '비밀번호는 12자 이상이어야 해요';

  @override
  String get cInvalidValue => '입력값을 확인해 주세요';

  @override
  String uUpdateBanner(String version) {
    return '새 버전 $version이 나왔어요';
  }

  @override
  String get uUpdateNow => '업데이트';

  @override
  String get uUpdateLater => '나중에';

  @override
  String get uUpdateRequiredTitle => '새 버전이 필요해요';

  @override
  String get uUpdateRequiredBody =>
      '이 버전은 더 이상 쓸 수 없어요. 스토어에서 최신 버전으로 업데이트해 주세요.';

  @override
  String get uUpdateStore => '스토어에서 업데이트';

  @override
  String get uUpdateStoreMissing => '업데이트 주소를 준비 중이에요. 잠시 후 다시 열어 주세요.';

  @override
  String uCurrentVersion(String version) {
    return '현재 버전 $version';
  }

  @override
  String get uAppVersionTitle => '앱 버전 관리';

  @override
  String get uAppVersionHint =>
      '최소 버전보다 낮은 앱은 업데이트 화면에서 멈춰요. 최신 버전보다 낮으면 안내 배너가 떠요. 형식: 1.2.0';

  @override
  String get uMinVersion => '최소 버전';

  @override
  String get uLatestVersion => '최신 버전';

  @override
  String get webBookNow => '웹에서 바로 예약';

  @override
  String get webBookSub => '앱 설치 없이 바로 예약해요';
}
