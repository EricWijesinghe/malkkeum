// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class TKo extends T {
  TKo([String locale = 'ko']) : super(locale);

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
}
