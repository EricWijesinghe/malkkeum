import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of T
/// returned by `T.of(context)`.
///
/// Applications need to include `T.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: T.localizationsDelegates,
///   supportedLocales: T.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the T.supportedLocales
/// property.
abstract class T {
  T(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static T of(BuildContext context) {
    return Localizations.of<T>(context, T)!;
  }

  static const LocalizationsDelegate<T> delegate = _TDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get change;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In ko, this message translates to:
  /// **'예'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ko, this message translates to:
  /// **'아니요'**
  String get no;

  /// No description provided for @required.
  ///
  /// In ko, this message translates to:
  /// **'필수'**
  String get required;

  /// No description provided for @viewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get viewAll;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'문제가 생겼어요. 잠시 후 다시 시도해 주세요.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인해 주세요'**
  String get errorNetwork;

  /// No description provided for @err_invalid_phone.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호를 확인해 주세요'**
  String get err_invalid_phone;

  /// No description provided for @err_otp_invalid.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 맞지 않아요'**
  String get err_otp_invalid;

  /// No description provided for @err_otp_expired.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 만료됐어요. 다시 받아 주세요.'**
  String get err_otp_expired;

  /// No description provided for @err_rate_limited.
  ///
  /// In ko, this message translates to:
  /// **'요청이 너무 많아요. 잠시 후 다시 시도해 주세요.'**
  String get err_rate_limited;

  /// No description provided for @err_studio_too_large.
  ///
  /// In ko, this message translates to:
  /// **'원룸 청소는 10평 이하 집만 가능해요'**
  String get err_studio_too_large;

  /// No description provided for @err_date_out_of_range.
  ///
  /// In ko, this message translates to:
  /// **'내일부터 60일 이내로 골라 주세요'**
  String get err_date_out_of_range;

  /// No description provided for @err_slot_full.
  ///
  /// In ko, this message translates to:
  /// **'그 시간은 마감됐어요. 다른 시간을 골라 주세요.'**
  String get err_slot_full;

  /// No description provided for @err_coupon_expired.
  ///
  /// In ko, this message translates to:
  /// **'기간이 지난 쿠폰이에요'**
  String get err_coupon_expired;

  /// No description provided for @err_coupon_used.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용한 쿠폰이에요'**
  String get err_coupon_used;

  /// No description provided for @err_coupon_wrong_service.
  ///
  /// In ko, this message translates to:
  /// **'이 서비스에는 쓸 수 없는 쿠폰이에요'**
  String get err_coupon_wrong_service;

  /// No description provided for @err_payment_failed.
  ///
  /// In ko, this message translates to:
  /// **'결제가 승인되지 않았어요. 다른 결제수단을 써 주세요.'**
  String get err_payment_failed;

  /// No description provided for @err_payment_method_required.
  ///
  /// In ko, this message translates to:
  /// **'결제수단을 선택해 주세요'**
  String get err_payment_method_required;

  /// No description provided for @err_cancellation_window_closed.
  ///
  /// In ko, this message translates to:
  /// **'방문 2일 전부터는 상담팀을 통해 취소할 수 있어요'**
  String get err_cancellation_window_closed;

  /// No description provided for @err_address_required.
  ///
  /// In ko, this message translates to:
  /// **'방문할 주소를 등록해 주세요'**
  String get err_address_required;

  /// No description provided for @err_already_taken.
  ///
  /// In ko, this message translates to:
  /// **'다른 파트너가 먼저 수락했어요'**
  String get err_already_taken;

  /// No description provided for @err_invalid_address.
  ///
  /// In ko, this message translates to:
  /// **'주소 정보를 모두 입력해 주세요'**
  String get err_invalid_address;

  /// No description provided for @tabHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get tabHome;

  /// No description provided for @tabBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get tabBookings;

  /// No description provided for @tabChat.
  ///
  /// In ko, this message translates to:
  /// **'상담'**
  String get tabChat;

  /// No description provided for @tabMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get tabMore;

  /// No description provided for @introTitle.
  ///
  /// In ko, this message translates to:
  /// **'전문가의 청소를\n가장 쉽게 예약하세요'**
  String get introTitle;

  /// No description provided for @introBody.
  ///
  /// In ko, this message translates to:
  /// **'정찰 가격 · 검증된 청소팀 · 실시간 진행 상황'**
  String get introBody;

  /// No description provided for @introStart.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호로 시작하기'**
  String get introStart;

  /// No description provided for @loginPhoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호를 알려주세요'**
  String get loginPhoneTitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'010-0000-0000'**
  String get loginPhoneHint;

  /// No description provided for @loginSendCode.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 받기'**
  String get loginSendCode;

  /// No description provided for @loginCodeTitle.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 6자리를 입력해 주세요'**
  String get loginCodeTitle;

  /// No description provided for @loginCodeSentTo.
  ///
  /// In ko, this message translates to:
  /// **'{phone}(으)로 보냈어요'**
  String loginCodeSentTo(String phone);

  /// No description provided for @loginResend.
  ///
  /// In ko, this message translates to:
  /// **'다시 받기'**
  String get loginResend;

  /// No description provided for @loginVerify.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get loginVerify;

  /// No description provided for @loginTerms.
  ///
  /// In ko, this message translates to:
  /// **'계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요'**
  String get loginTerms;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름을 알려주세요'**
  String get profileTitle;

  /// No description provided for @profileNameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get profileNameHint;

  /// No description provided for @profileDone.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get profileDone;

  /// No description provided for @welcomeToast.
  ///
  /// In ko, this message translates to:
  /// **'가입 축하 쿠폰 2장을 드렸어요'**
  String get welcomeToast;

  /// No description provided for @svc_studio.
  ///
  /// In ko, this message translates to:
  /// **'원룸 청소'**
  String get svc_studio;

  /// No description provided for @svc_kitchen.
  ///
  /// In ko, this message translates to:
  /// **'주방 청소'**
  String get svc_kitchen;

  /// No description provided for @svc_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'화장실 청소'**
  String get svc_bathroom;

  /// No description provided for @svc_mattress.
  ///
  /// In ko, this message translates to:
  /// **'매트리스 청소'**
  String get svc_mattress;

  /// No description provided for @svc_aircon.
  ///
  /// In ko, this message translates to:
  /// **'에어컨 청소'**
  String get svc_aircon;

  /// No description provided for @svc_sofa.
  ///
  /// In ko, this message translates to:
  /// **'소파 청소'**
  String get svc_sofa;

  /// No description provided for @svc_move_out.
  ///
  /// In ko, this message translates to:
  /// **'이사 청소'**
  String get svc_move_out;

  /// No description provided for @svc_move_in.
  ///
  /// In ko, this message translates to:
  /// **'입주 청소'**
  String get svc_move_in;

  /// No description provided for @svcShort_studio.
  ///
  /// In ko, this message translates to:
  /// **'원룸'**
  String get svcShort_studio;

  /// No description provided for @svcShort_kitchen.
  ///
  /// In ko, this message translates to:
  /// **'주방'**
  String get svcShort_kitchen;

  /// No description provided for @svcShort_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'화장실'**
  String get svcShort_bathroom;

  /// No description provided for @svcShort_mattress.
  ///
  /// In ko, this message translates to:
  /// **'매트리스'**
  String get svcShort_mattress;

  /// No description provided for @svcShort_aircon.
  ///
  /// In ko, this message translates to:
  /// **'에어컨'**
  String get svcShort_aircon;

  /// No description provided for @svcShort_sofa.
  ///
  /// In ko, this message translates to:
  /// **'소파'**
  String get svcShort_sofa;

  /// No description provided for @svcShort_move_out.
  ///
  /// In ko, this message translates to:
  /// **'이사'**
  String get svcShort_move_out;

  /// No description provided for @svcShort_move_in.
  ///
  /// In ko, this message translates to:
  /// **'입주'**
  String get svcShort_move_in;

  /// No description provided for @svcDesc_studio.
  ///
  /// In ko, this message translates to:
  /// **'방 1개, 화장실 1개인 10평 이하 원룸을 2시간 동안 꼼꼼히 청소해요.'**
  String get svcDesc_studio;

  /// No description provided for @svcDesc_kitchen.
  ///
  /// In ko, this message translates to:
  /// **'싱크대, 가스레인지, 후드 겉면, 상판을 중심으로 주방을 집중 청소해요.'**
  String get svcDesc_kitchen;

  /// No description provided for @svcDesc_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'선반, 수전, 세면대와 변기의 안팎을 청소하고 바닥 물기까지 정리해요.'**
  String get svcDesc_bathroom;

  /// No description provided for @svcDesc_mattress.
  ///
  /// In ko, this message translates to:
  /// **'전문 장비로 먼지, 진드기, 얼룩을 흡입하고 스팀으로 살균 세척해요.'**
  String get svcDesc_mattress;

  /// No description provided for @svcDesc_aircon.
  ///
  /// In ko, this message translates to:
  /// **'분해 후 열교환기, 송풍팬, 필터를 고압 세척하고 살균으로 마무리해요.'**
  String get svcDesc_aircon;

  /// No description provided for @svcDesc_sofa.
  ///
  /// In ko, this message translates to:
  /// **'소재에 맞는 세제로 오염을 분해하고 습식 추출 방식으로 세척해요.'**
  String get svcDesc_sofa;

  /// No description provided for @svcDesc_move_out.
  ///
  /// In ko, this message translates to:
  /// **'이사 나가기 전, 짐을 뺀 집을 전문 청소팀이 장비를 가지고 방문해 청소해요.'**
  String get svcDesc_move_out;

  /// No description provided for @svcDesc_move_in.
  ///
  /// In ko, this message translates to:
  /// **'새 집에 들어가기 전, 전문 청소팀이 장비를 가지고 방문해 실내를 청소해요.'**
  String get svcDesc_move_in;

  /// No description provided for @svcNotes_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'배수구·변기 막힘이 있으면 서비스가 제한될 수 있어요\n특수 약품이 필요한 청소, 천장·환풍기 청소는 제공하지 않아요\n오래된 곰팡이·찌든 때는 완전히 제거되지 않을 수 있어요'**
  String get svcNotes_bathroom;

  /// No description provided for @svcNotes_mattress.
  ///
  /// In ko, this message translates to:
  /// **'싱글부터 킹 사이즈까지 같은 금액이에요\n세척 후 완전 건조까지 4~6시간 걸려요\n스프링 손상, 꺼짐 등 구조적인 문제는 개선되지 않아요'**
  String get svcNotes_mattress;

  /// No description provided for @svcNotes_aircon.
  ///
  /// In ko, this message translates to:
  /// **'제조 10년 이상 제품은 분해 세척이 어려울 수 있어요\n실외기 청소는 포함되지 않아요\n세척 전후 정상 작동 여부를 함께 확인해요'**
  String get svcNotes_aircon;

  /// No description provided for @svcNotes_sofa.
  ///
  /// In ko, this message translates to:
  /// **'가죽 소파는 클리닝과 보습 코팅으로 진행돼요\n오래된 얼룩·이염은 완전히 제거되지 않을 수 있어요\n완전 건조까지 4~6시간 걸려요'**
  String get svcNotes_sofa;

  /// No description provided for @unitTitle_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'화장실 개수'**
  String get unitTitle_bathroom;

  /// No description provided for @unitTitle_mattress.
  ///
  /// In ko, this message translates to:
  /// **'매트리스 개수'**
  String get unitTitle_mattress;

  /// No description provided for @unitTitle_aircon.
  ///
  /// In ko, this message translates to:
  /// **'에어컨 종류'**
  String get unitTitle_aircon;

  /// No description provided for @unitTitle_sofa.
  ///
  /// In ko, this message translates to:
  /// **'소파 크기'**
  String get unitTitle_sofa;

  /// No description provided for @unit_count.
  ///
  /// In ko, this message translates to:
  /// **'{n}개'**
  String unit_count(String n);

  /// No description provided for @unit_wall.
  ///
  /// In ko, this message translates to:
  /// **'벽걸이 1대'**
  String get unit_wall;

  /// No description provided for @unit_stand.
  ///
  /// In ko, this message translates to:
  /// **'스탠드 1대'**
  String get unit_stand;

  /// No description provided for @unit_two_in_one.
  ///
  /// In ko, this message translates to:
  /// **'2in1 (스탠드+벽걸이)'**
  String get unit_two_in_one;

  /// No description provided for @unit_ceiling.
  ///
  /// In ko, this message translates to:
  /// **'천장형 1대'**
  String get unit_ceiling;

  /// No description provided for @unit_seat_1_2.
  ///
  /// In ko, this message translates to:
  /// **'1~2인용'**
  String get unit_seat_1_2;

  /// No description provided for @unit_seat_3.
  ///
  /// In ko, this message translates to:
  /// **'3인용'**
  String get unit_seat_3;

  /// No description provided for @unit_seat_4_plus.
  ///
  /// In ko, this message translates to:
  /// **'4인용 이상'**
  String get unit_seat_4_plus;

  /// No description provided for @unit_l_shape.
  ///
  /// In ko, this message translates to:
  /// **'L자 · 카우치'**
  String get unit_l_shape;

  /// No description provided for @durH.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간'**
  String durH(String h);

  /// No description provided for @durHM.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분'**
  String durHM(String h, String m);

  /// No description provided for @durM.
  ///
  /// In ko, this message translates to:
  /// **'{m}분'**
  String durM(String m);

  /// No description provided for @about.
  ///
  /// In ko, this message translates to:
  /// **'약 {value}'**
  String about(String value);

  /// No description provided for @fromPrice.
  ///
  /// In ko, this message translates to:
  /// **'{price}~'**
  String fromPrice(String price);

  /// No description provided for @quoteBadge.
  ///
  /// In ko, this message translates to:
  /// **'견적'**
  String get quoteBadge;

  /// No description provided for @status0.
  ///
  /// In ko, this message translates to:
  /// **'상담 중'**
  String get status0;

  /// No description provided for @status1.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정'**
  String get status1;

  /// No description provided for @status2.
  ///
  /// In ko, this message translates to:
  /// **'팀 배정 완료'**
  String get status2;

  /// No description provided for @status3.
  ///
  /// In ko, this message translates to:
  /// **'청소 완료'**
  String get status3;

  /// No description provided for @statusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get statusCancelled;

  /// No description provided for @homeGreeting.
  ///
  /// In ko, this message translates to:
  /// **'{name}님,\n오늘은 어디를 깨끗하게 할까요?'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingAnon.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 어디를\n깨끗하게 할까요?'**
  String get homeGreetingAnon;

  /// No description provided for @homeUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 예약'**
  String get homeUpcoming;

  /// No description provided for @dDay.
  ///
  /// In ko, this message translates to:
  /// **'D-{days}'**
  String dDay(String days);

  /// No description provided for @homeServices.
  ///
  /// In ko, this message translates to:
  /// **'어떤 청소가 필요하세요?'**
  String get homeServices;

  /// No description provided for @homeAddAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소를 등록하면 가능한 서비스와 가격을 바로 보여드려요'**
  String get homeAddAddress;

  /// No description provided for @homeAddAddressCta.
  ///
  /// In ko, this message translates to:
  /// **'주소 등록'**
  String get homeAddAddressCta;

  /// No description provided for @homeRebook.
  ///
  /// In ko, this message translates to:
  /// **'{service} 다시 예약하기'**
  String homeRebook(String service);

  /// No description provided for @homeRebookBody.
  ///
  /// In ko, this message translates to:
  /// **'지난번과 같은 조건으로 빠르게 예약해요'**
  String get homeRebookBody;

  /// No description provided for @homeNotices.
  ///
  /// In ko, this message translates to:
  /// **'새 소식'**
  String get homeNotices;

  /// No description provided for @trustVat.
  ///
  /// In ko, this message translates to:
  /// **'부가세 포함\n표시된 가격 그대로'**
  String get trustVat;

  /// No description provided for @trustCancel.
  ///
  /// In ko, this message translates to:
  /// **'방문 2일 전까지\n무료 취소'**
  String get trustCancel;

  /// No description provided for @trustCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 정보는\n결제사에만 보관'**
  String get trustCard;

  /// No description provided for @stepOf.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String stepOf(String current, String total);

  /// No description provided for @chooseDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 고르기'**
  String get chooseDate;

  /// No description provided for @notIncluded.
  ///
  /// In ko, this message translates to:
  /// **'꼭 확인해 주세요'**
  String get notIncluded;

  /// No description provided for @studioBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{size}평은 원룸 청소 대상이 아니에요'**
  String studioBlockedTitle(String size);

  /// No description provided for @studioBlockedBody.
  ///
  /// In ko, this message translates to:
  /// **'상담팀이 집에 맞는 서비스를 추천해 드릴게요.'**
  String get studioBlockedBody;

  /// No description provided for @consultCta.
  ///
  /// In ko, this message translates to:
  /// **'상담으로 문의하기'**
  String get consultCta;

  /// No description provided for @addressTitle.
  ///
  /// In ko, this message translates to:
  /// **'어디로 방문할까요?'**
  String get addressTitle;

  /// No description provided for @addressAdd.
  ///
  /// In ko, this message translates to:
  /// **'새 주소 추가'**
  String get addressAdd;

  /// No description provided for @addressLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 우리집'**
  String get addressLabelHint;

  /// No description provided for @addressDistrict.
  ///
  /// In ko, this message translates to:
  /// **'구'**
  String get addressDistrict;

  /// No description provided for @addressRoad.
  ///
  /// In ko, this message translates to:
  /// **'도로명 주소'**
  String get addressRoad;

  /// No description provided for @addressDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 주소'**
  String get addressDetail;

  /// No description provided for @addressSize.
  ///
  /// In ko, this message translates to:
  /// **'집 크기 (평)'**
  String get addressSize;

  /// No description provided for @addressSizeHelp.
  ///
  /// In ko, this message translates to:
  /// **'전용면적 기준 · 1평 ≈ 3.3㎡'**
  String get addressSizeHelp;

  /// No description provided for @addressHome.
  ///
  /// In ko, this message translates to:
  /// **'집'**
  String get addressHome;

  /// No description provided for @addressOffice.
  ///
  /// In ko, this message translates to:
  /// **'사무실'**
  String get addressOffice;

  /// No description provided for @addressEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장된 주소가 없어요'**
  String get addressEmpty;

  /// No description provided for @addressSaved.
  ///
  /// In ko, this message translates to:
  /// **'주소를 저장했어요'**
  String get addressSaved;

  /// No description provided for @pyeong.
  ///
  /// In ko, this message translates to:
  /// **'{n}평'**
  String pyeong(String n);

  /// No description provided for @scheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'언제 방문할까요?'**
  String get scheduleTitle;

  /// No description provided for @scheduleArrival.
  ///
  /// In ko, this message translates to:
  /// **'도착 시간'**
  String get scheduleArrival;

  /// No description provided for @scheduleFull.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get scheduleFull;

  /// No description provided for @scheduleWindow.
  ///
  /// In ko, this message translates to:
  /// **'{start}–{end} 도착'**
  String scheduleWindow(String start, String end);

  /// No description provided for @scheduleEnds.
  ///
  /// In ko, this message translates to:
  /// **'{duration} 소요 · {time}쯤 끝나요'**
  String scheduleEnds(String duration, String time);

  /// No description provided for @scheduleRange.
  ///
  /// In ko, this message translates to:
  /// **'내일부터 60일 이내로 예약할 수 있어요'**
  String get scheduleRange;

  /// No description provided for @morning.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get afternoon;

  /// No description provided for @scheduleQuoteNote.
  ///
  /// In ko, this message translates to:
  /// **'정확한 도착 시간은 상담에서 안내해 드려요'**
  String get scheduleQuoteNote;

  /// No description provided for @goToPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제하러 가기'**
  String get goToPayment;

  /// No description provided for @prepTitle.
  ///
  /// In ko, this message translates to:
  /// **'방문 전에 준비해 주세요'**
  String get prepTitle;

  /// No description provided for @prepBody.
  ///
  /// In ko, this message translates to:
  /// **'준비되지 않으면 일부 작업이 제한될 수 있어요'**
  String get prepBody;

  /// No description provided for @prepAsk.
  ///
  /// In ko, this message translates to:
  /// **'준비가 어렵다면 상담으로 미리 알려 주세요'**
  String get prepAsk;

  /// No description provided for @tool_vacuum.
  ///
  /// In ko, this message translates to:
  /// **'청소기'**
  String get tool_vacuum;

  /// No description provided for @tool_trash.
  ///
  /// In ko, this message translates to:
  /// **'쓰레기봉투'**
  String get tool_trash;

  /// No description provided for @tool_mop.
  ///
  /// In ko, this message translates to:
  /// **'막대걸레'**
  String get tool_mop;

  /// No description provided for @tool_cloth.
  ///
  /// In ko, this message translates to:
  /// **'손걸레'**
  String get tool_cloth;

  /// No description provided for @tool_gloves.
  ///
  /// In ko, this message translates to:
  /// **'고무장갑'**
  String get tool_gloves;

  /// No description provided for @tool_sponge.
  ///
  /// In ko, this message translates to:
  /// **'수세미'**
  String get tool_sponge;

  /// No description provided for @tool_spray.
  ///
  /// In ko, this message translates to:
  /// **'다목적세제'**
  String get tool_spray;

  /// No description provided for @checkoutTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get checkoutTitle;

  /// No description provided for @coupon.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰'**
  String get coupon;

  /// No description provided for @couponNone.
  ///
  /// In ko, this message translates to:
  /// **'사용 안 함'**
  String get couponNone;

  /// No description provided for @couponAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능 {count}장'**
  String couponAvailable(String count);

  /// No description provided for @paymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get paymentMethod;

  /// No description provided for @addPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 등록'**
  String get addPaymentMethod;

  /// No description provided for @methodCard.
  ///
  /// In ko, this message translates to:
  /// **'신용·체크카드'**
  String get methodCard;

  /// No description provided for @methodKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오페이'**
  String get methodKakao;

  /// No description provided for @methodNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버페이'**
  String get methodNaver;

  /// No description provided for @methodToss.
  ///
  /// In ko, this message translates to:
  /// **'토스페이'**
  String get methodToss;

  /// No description provided for @methodRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록됨'**
  String get methodRegistered;

  /// No description provided for @methodAdded.
  ///
  /// In ko, this message translates to:
  /// **'결제수단을 등록했어요'**
  String get methodAdded;

  /// No description provided for @listPrice.
  ///
  /// In ko, this message translates to:
  /// **'서비스 금액'**
  String get listPrice;

  /// No description provided for @discount.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 할인'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액'**
  String get total;

  /// No description provided for @vatIncluded.
  ///
  /// In ko, this message translates to:
  /// **'부가세 포함'**
  String get vatIncluded;

  /// No description provided for @payAmount.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 결제하기'**
  String payAmount(String amount);

  /// No description provided for @needMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단을 등록해 주세요'**
  String get needMethod;

  /// No description provided for @freeCancelUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 무료 취소'**
  String freeCancelUntil(String date);

  /// No description provided for @doneTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약이 완료됐어요'**
  String get doneTitle;

  /// No description provided for @doneBody.
  ///
  /// In ko, this message translates to:
  /// **'청소팀이 배정되면 바로 알려드릴게요'**
  String get doneBody;

  /// No description provided for @doneQuoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'상담 요청이 접수됐어요'**
  String get doneQuoteTitle;

  /// No description provided for @doneQuoteBody.
  ///
  /// In ko, this message translates to:
  /// **'상담팀이 확인 후 최종 견적을 보내드려요. 견적은 상담 탭에서 확인할 수 있어요.'**
  String get doneQuoteBody;

  /// No description provided for @goHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get goHome;

  /// No description provided for @viewBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약 보기'**
  String get viewBooking;

  /// No description provided for @bookingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get bookingsTitle;

  /// No description provided for @bookingsUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 예약'**
  String get bookingsUpcoming;

  /// No description provided for @bookingsPast.
  ///
  /// In ko, this message translates to:
  /// **'지난 예약'**
  String get bookingsPast;

  /// No description provided for @bookingsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 예약이 없어요'**
  String get bookingsEmpty;

  /// No description provided for @bookingsEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'첫 예약에 쓸 수 있는 쿠폰이 준비돼 있어요'**
  String get bookingsEmptyBody;

  /// No description provided for @bookNow.
  ///
  /// In ko, this message translates to:
  /// **'청소 예약하기'**
  String get bookNow;

  /// No description provided for @detailTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 상세'**
  String get detailTitle;

  /// No description provided for @stepRequested.
  ///
  /// In ko, this message translates to:
  /// **'상담 접수'**
  String get stepRequested;

  /// No description provided for @stepConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정'**
  String get stepConfirmed;

  /// No description provided for @stepAssigned.
  ///
  /// In ko, this message translates to:
  /// **'청소팀 배정'**
  String get stepAssigned;

  /// No description provided for @stepCompleted.
  ///
  /// In ko, this message translates to:
  /// **'청소 완료'**
  String get stepCompleted;

  /// No description provided for @teamVisiting.
  ///
  /// In ko, this message translates to:
  /// **'{team}이(가) 방문해요'**
  String teamVisiting(String team);

  /// No description provided for @photosSoon.
  ///
  /// In ko, this message translates to:
  /// **'끝나면 전후 사진이 여기에 올라와요'**
  String get photosSoon;

  /// No description provided for @before.
  ///
  /// In ko, this message translates to:
  /// **'청소 전'**
  String get before;

  /// No description provided for @after.
  ///
  /// In ko, this message translates to:
  /// **'청소 후'**
  String get after;

  /// No description provided for @prepCheck.
  ///
  /// In ko, this message translates to:
  /// **'준비물 체크'**
  String get prepCheck;

  /// No description provided for @prepAllSet.
  ///
  /// In ko, this message translates to:
  /// **'모두 준비됐어요'**
  String get prepAllSet;

  /// No description provided for @visitAddress.
  ///
  /// In ko, this message translates to:
  /// **'방문 주소'**
  String get visitAddress;

  /// No description provided for @paid.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get paid;

  /// No description provided for @askTeam.
  ///
  /// In ko, this message translates to:
  /// **'상담팀에 문의하기'**
  String get askTeam;

  /// No description provided for @cancelBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약 취소'**
  String get cancelBooking;

  /// No description provided for @cancelTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약을 취소할까요?'**
  String get cancelTitle;

  /// No description provided for @cancelFree.
  ///
  /// In ko, this message translates to:
  /// **'지금 취소하면 결제 금액 전액이 환불되고 쿠폰도 돌려드려요.'**
  String get cancelFree;

  /// No description provided for @cancelKeep.
  ///
  /// In ko, this message translates to:
  /// **'유지하기'**
  String get cancelKeep;

  /// No description provided for @cancelled.
  ///
  /// In ko, this message translates to:
  /// **'예약이 취소됐어요'**
  String get cancelled;

  /// No description provided for @reschedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 변경'**
  String get reschedule;

  /// No description provided for @rescheduled.
  ///
  /// In ko, this message translates to:
  /// **'일정을 변경했어요'**
  String get rescheduled;

  /// No description provided for @visitNotes.
  ///
  /// In ko, this message translates to:
  /// **'방문 요청사항'**
  String get visitNotes;

  /// No description provided for @notesEntry.
  ///
  /// In ko, this message translates to:
  /// **'출입 방법 (공동현관 비밀번호 등)'**
  String get notesEntry;

  /// No description provided for @notesParking.
  ///
  /// In ko, this message translates to:
  /// **'주차'**
  String get notesParking;

  /// No description provided for @notesOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get notesOther;

  /// No description provided for @notesSaved.
  ///
  /// In ko, this message translates to:
  /// **'요청사항을 저장했어요'**
  String get notesSaved;

  /// No description provided for @depositDue.
  ///
  /// In ko, this message translates to:
  /// **'예약금 {amount}을(를) 결제하면 예약이 확정돼요'**
  String depositDue(String amount);

  /// No description provided for @payDeposit.
  ///
  /// In ko, this message translates to:
  /// **'예약금 결제하기'**
  String get payDeposit;

  /// No description provided for @waitingQuote.
  ///
  /// In ko, this message translates to:
  /// **'상담팀이 견적을 준비하고 있어요'**
  String get waitingQuote;

  /// No description provided for @estimate.
  ///
  /// In ko, this message translates to:
  /// **'예상 금액'**
  String get estimate;

  /// No description provided for @finalPrice.
  ///
  /// In ko, this message translates to:
  /// **'최종 견적'**
  String get finalPrice;

  /// No description provided for @deposit.
  ///
  /// In ko, this message translates to:
  /// **'예약금'**
  String get deposit;

  /// No description provided for @balance.
  ///
  /// In ko, this message translates to:
  /// **'잔금'**
  String get balance;

  /// No description provided for @balanceDue.
  ///
  /// In ko, this message translates to:
  /// **'잔금 {amount}을(를) 결제해 주세요'**
  String balanceDue(String amount);

  /// No description provided for @payBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔금 결제하기'**
  String get payBalance;

  /// No description provided for @reviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'청소는 어떠셨나요?'**
  String get reviewTitle;

  /// No description provided for @reviewHint.
  ///
  /// In ko, this message translates to:
  /// **'좋았던 점이나 아쉬운 점을 알려 주세요'**
  String get reviewHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In ko, this message translates to:
  /// **'후기 남기기'**
  String get reviewSubmit;

  /// No description provided for @reviewThanks.
  ///
  /// In ko, this message translates to:
  /// **'소중한 후기 고마워요'**
  String get reviewThanks;

  /// No description provided for @bookAgain.
  ///
  /// In ko, this message translates to:
  /// **'같은 조건으로 다시 예약'**
  String get bookAgain;

  /// No description provided for @chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'상담'**
  String get chatTitle;

  /// No description provided for @chatTeam.
  ///
  /// In ko, this message translates to:
  /// **'상담팀'**
  String get chatTeam;

  /// No description provided for @chatHours.
  ///
  /// In ko, this message translates to:
  /// **'평일 09:00–18:00'**
  String get chatHours;

  /// No description provided for @chatEmpty.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 점이 있으면 언제든 물어보세요'**
  String get chatEmpty;

  /// No description provided for @chatNew.
  ///
  /// In ko, this message translates to:
  /// **'새 상담'**
  String get chatNew;

  /// No description provided for @chatTopicTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 궁금하세요?'**
  String get chatTopicTitle;

  /// No description provided for @topicOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 문의'**
  String get topicOther;

  /// No description provided for @chatHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get chatSend;

  /// No description provided for @chatPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 보내기'**
  String get chatPhoto;

  /// No description provided for @chatTyping.
  ///
  /// In ko, this message translates to:
  /// **'상담팀이 입력 중'**
  String get chatTyping;

  /// No description provided for @quick_confirm.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정할게요'**
  String get quick_confirm;

  /// No description provided for @quick_price.
  ///
  /// In ko, this message translates to:
  /// **'가격이 궁금해요'**
  String get quick_price;

  /// No description provided for @quick_date.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 바꾸고 싶어요'**
  String get quick_date;

  /// No description provided for @quick_parking.
  ///
  /// In ko, this message translates to:
  /// **'주차가 가능한가요?'**
  String get quick_parking;

  /// No description provided for @quick_hello.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요'**
  String get quick_hello;

  /// No description provided for @quick_duration.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 걸리나요?'**
  String get quick_duration;

  /// No description provided for @quoteArrived.
  ///
  /// In ko, this message translates to:
  /// **'최종 견적이 도착했어요'**
  String get quoteArrived;

  /// No description provided for @quoteDepositNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 예약금 10%'**
  String get quoteDepositNow;

  /// No description provided for @quoteBalanceLater.
  ///
  /// In ko, this message translates to:
  /// **'청소 후 잔금'**
  String get quoteBalanceLater;

  /// No description provided for @quotePay.
  ///
  /// In ko, this message translates to:
  /// **'예약금 결제하고 확정하기'**
  String get quotePay;

  /// No description provided for @quotePaid.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get quotePaid;

  /// No description provided for @requestCard.
  ///
  /// In ko, this message translates to:
  /// **'견적 요청'**
  String get requestCard;

  /// No description provided for @sys_consultation_received.
  ///
  /// In ko, this message translates to:
  /// **'상담이 접수됐어요'**
  String get sys_consultation_received;

  /// No description provided for @sys_deposit_paid.
  ///
  /// In ko, this message translates to:
  /// **'예약금 {amount}이(가) 결제됐어요. 예약이 확정됐어요.'**
  String sys_deposit_paid(String amount);

  /// No description provided for @sys_booking_cancelled.
  ///
  /// In ko, this message translates to:
  /// **'예약이 취소됐어요'**
  String get sys_booking_cancelled;

  /// No description provided for @sys_status_changed.
  ///
  /// In ko, this message translates to:
  /// **'예약 상태가 \'{status}\'(으)로 바뀌었어요'**
  String sys_status_changed(String status);

  /// No description provided for @sys_job_completed.
  ///
  /// In ko, this message translates to:
  /// **'청소가 끝났어요. 전후 사진을 확인해 보세요.'**
  String get sys_job_completed;

  /// No description provided for @sys_rescheduled.
  ///
  /// In ko, this message translates to:
  /// **'일정이 {date}(으)로 변경됐어요'**
  String sys_rescheduled(String date);

  /// No description provided for @sys_reschedule_declined.
  ///
  /// In ko, this message translates to:
  /// **'파트너가 변경된 일정에 방문이 어려워요. 상담팀이 다시 조율할게요.'**
  String get sys_reschedule_declined;

  /// No description provided for @moreTitle.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get moreTitle;

  /// No description provided for @moreScope.
  ///
  /// In ko, this message translates to:
  /// **'서비스 범위'**
  String get moreScope;

  /// No description provided for @morePayments.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 관리'**
  String get morePayments;

  /// No description provided for @moreCoupons.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰'**
  String get moreCoupons;

  /// No description provided for @morePoints.
  ///
  /// In ko, this message translates to:
  /// **'청소 포인트'**
  String get morePoints;

  /// No description provided for @moreAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 정보'**
  String get moreAccount;

  /// No description provided for @moreAddresses.
  ///
  /// In ko, this message translates to:
  /// **'주소 관리'**
  String get moreAddresses;

  /// No description provided for @moreNotices.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get moreNotices;

  /// No description provided for @moreTips.
  ///
  /// In ko, this message translates to:
  /// **'청소 팁'**
  String get moreTips;

  /// No description provided for @moreFaq.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get moreFaq;

  /// No description provided for @morePartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너 제휴 문의'**
  String get morePartner;

  /// No description provided for @moreLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get moreLanguage;

  /// No description provided for @langSystem.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정 따르기'**
  String get langSystem;

  /// No description provided for @moreVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {v}'**
  String moreVersion(String v);

  /// No description provided for @morePrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get morePrivacy;

  /// No description provided for @moreTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get moreTerms;

  /// No description provided for @moreLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get moreLicenses;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ko, this message translates to:
  /// **'개인정보가 삭제되고 되돌릴 수 없어요. 진행 중인 예약은 먼저 취소해 주세요.'**
  String get deleteAccountBody;

  /// No description provided for @couponsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'보유한 쿠폰이 없어요'**
  String get couponsEmpty;

  /// No description provided for @couponUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지'**
  String couponUntil(String date);

  /// No description provided for @couponUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용 완료'**
  String get couponUsed;

  /// No description provided for @couponExpired.
  ///
  /// In ko, this message translates to:
  /// **'기간 만료'**
  String get couponExpired;

  /// No description provided for @couponAnyService.
  ///
  /// In ko, this message translates to:
  /// **'모든 서비스'**
  String get couponAnyService;

  /// No description provided for @coupon_welcome_studio.
  ///
  /// In ko, this message translates to:
  /// **'가입 축하 원룸 쿠폰'**
  String get coupon_welcome_studio;

  /// No description provided for @coupon_welcome_any.
  ///
  /// In ko, this message translates to:
  /// **'가입 축하 쿠폰'**
  String get coupon_welcome_any;

  /// No description provided for @pointsBalance.
  ///
  /// In ko, this message translates to:
  /// **'보유 포인트'**
  String get pointsBalance;

  /// No description provided for @pointsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'포인트 내역이 없어요'**
  String get pointsEmpty;

  /// No description provided for @accountName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get accountName;

  /// No description provided for @accountPhone.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호'**
  String get accountPhone;

  /// No description provided for @accountEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get accountEmail;

  /// No description provided for @accountLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인 방식'**
  String get accountLogin;

  /// No description provided for @accountLoginPhone.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 인증'**
  String get accountLoginPhone;

  /// No description provided for @methodsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 결제수단이 없어요'**
  String get methodsEmpty;

  /// No description provided for @noContent.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 내용이 없어요'**
  String get noContent;

  /// No description provided for @quoteTypeTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 청소가 필요하세요?'**
  String get quoteTypeTitle;

  /// No description provided for @type_standard.
  ///
  /// In ko, this message translates to:
  /// **'퇴거 청소'**
  String get type_standard;

  /// No description provided for @type_same_day_move.
  ///
  /// In ko, this message translates to:
  /// **'이사 당일 청소'**
  String get type_same_day_move;

  /// No description provided for @type_some_luggage_left.
  ///
  /// In ko, this message translates to:
  /// **'짐 일부 남음'**
  String get type_some_luggage_left;

  /// No description provided for @type_normal_move_in.
  ///
  /// In ko, this message translates to:
  /// **'일반 입주'**
  String get type_normal_move_in;

  /// No description provided for @type_after_interior.
  ///
  /// In ko, this message translates to:
  /// **'인테리어 후'**
  String get type_after_interior;

  /// No description provided for @type_lived_in_deep_clean.
  ///
  /// In ko, this message translates to:
  /// **'거주 중 대청소'**
  String get type_lived_in_deep_clean;

  /// No description provided for @luggageTitle.
  ///
  /// In ko, this message translates to:
  /// **'짐은 어떤 상태인가요?'**
  String get luggageTitle;

  /// No description provided for @luggage_empty.
  ///
  /// In ko, this message translates to:
  /// **'짐 없음'**
  String get luggage_empty;

  /// No description provided for @luggage_partly_unpacked.
  ///
  /// In ko, this message translates to:
  /// **'일부 정리 중'**
  String get luggage_partly_unpacked;

  /// No description provided for @luggage_fully_lived_in.
  ///
  /// In ko, this message translates to:
  /// **'생활 중'**
  String get luggage_fully_lived_in;

  /// No description provided for @luggage_unknown.
  ///
  /// In ko, this message translates to:
  /// **'잘 모르겠어요'**
  String get luggage_unknown;

  /// No description provided for @quoteBasicTitle.
  ///
  /// In ko, this message translates to:
  /// **'집 구조를 알려주세요'**
  String get quoteBasicTitle;

  /// No description provided for @buildingType.
  ///
  /// In ko, this message translates to:
  /// **'건물 유형'**
  String get buildingType;

  /// No description provided for @building_apartment.
  ///
  /// In ko, this message translates to:
  /// **'아파트'**
  String get building_apartment;

  /// No description provided for @building_villa.
  ///
  /// In ko, this message translates to:
  /// **'빌라'**
  String get building_villa;

  /// No description provided for @building_officetel.
  ///
  /// In ko, this message translates to:
  /// **'오피스텔'**
  String get building_officetel;

  /// No description provided for @building_house.
  ///
  /// In ko, this message translates to:
  /// **'단독주택'**
  String get building_house;

  /// No description provided for @building_other.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get building_other;

  /// No description provided for @layoutTitle.
  ///
  /// In ko, this message translates to:
  /// **'구조'**
  String get layoutTitle;

  /// No description provided for @layout_studio.
  ///
  /// In ko, this message translates to:
  /// **'원룸'**
  String get layout_studio;

  /// No description provided for @layout_one_and_half.
  ///
  /// In ko, this message translates to:
  /// **'1.5룸'**
  String get layout_one_and_half;

  /// No description provided for @layout_two_rooms.
  ///
  /// In ko, this message translates to:
  /// **'방 2개'**
  String get layout_two_rooms;

  /// No description provided for @layout_three_rooms.
  ///
  /// In ko, this message translates to:
  /// **'방 3개'**
  String get layout_three_rooms;

  /// No description provided for @layout_four_plus.
  ///
  /// In ko, this message translates to:
  /// **'방 4개 이상'**
  String get layout_four_plus;

  /// No description provided for @duplexTitle.
  ///
  /// In ko, this message translates to:
  /// **'복층인가요?'**
  String get duplexTitle;

  /// No description provided for @quoteSpaceTitle.
  ///
  /// In ko, this message translates to:
  /// **'공간을 알려주세요'**
  String get quoteSpaceTitle;

  /// No description provided for @bathroomsLabel.
  ///
  /// In ko, this message translates to:
  /// **'화장실'**
  String get bathroomsLabel;

  /// No description provided for @balconiesLabel.
  ///
  /// In ko, this message translates to:
  /// **'발코니 · 다용도실'**
  String get balconiesLabel;

  /// No description provided for @elevatorTitle.
  ///
  /// In ko, this message translates to:
  /// **'엘리베이터가 있나요?'**
  String get elevatorTitle;

  /// No description provided for @floor3Label.
  ///
  /// In ko, this message translates to:
  /// **'3층 이상이에요'**
  String get floor3Label;

  /// No description provided for @quoteEstimateTitle.
  ///
  /// In ko, this message translates to:
  /// **'예상 견적이에요'**
  String get quoteEstimateTitle;

  /// No description provided for @quoteEstimateBody.
  ///
  /// In ko, this message translates to:
  /// **'상담에서 사진과 상황을 확인한 뒤 최종 금액이 정해져요'**
  String get quoteEstimateBody;

  /// No description provided for @quoteG1.
  ///
  /// In ko, this message translates to:
  /// **'최종 금액은 상담에서 확정해요'**
  String get quoteG1;

  /// No description provided for @quoteG2.
  ///
  /// In ko, this message translates to:
  /// **'예약금 10%로 확정, 잔금은 청소 후'**
  String get quoteG2;

  /// No description provided for @quoteG3.
  ///
  /// In ko, this message translates to:
  /// **'확정 전에는 언제든 무료 취소'**
  String get quoteG3;

  /// No description provided for @quoteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'요청 내용을 확인해 주세요'**
  String get quoteConfirmTitle;

  /// No description provided for @quoteRequest.
  ///
  /// In ko, this message translates to:
  /// **'상담 요청하기'**
  String get quoteRequest;

  /// No description provided for @quoteNoPayNow.
  ///
  /// In ko, this message translates to:
  /// **'지금은 결제하지 않아요'**
  String get quoteNoPayNow;

  /// No description provided for @summaryType.
  ///
  /// In ko, this message translates to:
  /// **'청소 종류'**
  String get summaryType;

  /// No description provided for @summaryHome.
  ///
  /// In ko, this message translates to:
  /// **'집 정보'**
  String get summaryHome;

  /// No description provided for @summaryDate.
  ///
  /// In ko, this message translates to:
  /// **'방문 일정'**
  String get summaryDate;

  /// No description provided for @pTabJobs.
  ///
  /// In ko, this message translates to:
  /// **'일감'**
  String get pTabJobs;

  /// No description provided for @pTabQuotes.
  ///
  /// In ko, this message translates to:
  /// **'내 견적'**
  String get pTabQuotes;

  /// No description provided for @pTabSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get pTabSchedule;

  /// No description provided for @pIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'청소 전문가를 위한\n일감 · 일정 · 정산'**
  String get pIntroTitle;

  /// No description provided for @pIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'원하는 지역과 시간에만 일하고, 매주 정산 받으세요'**
  String get pIntroBody;

  /// No description provided for @pOnbTitle.
  ///
  /// In ko, this message translates to:
  /// **'파트너 정보를 알려주세요'**
  String get pOnbTitle;

  /// No description provided for @pOnbName.
  ///
  /// In ko, this message translates to:
  /// **'대표자 이름'**
  String get pOnbName;

  /// No description provided for @pOnbTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 이름'**
  String get pOnbTeam;

  /// No description provided for @pOnbServices.
  ///
  /// In ko, this message translates to:
  /// **'할 수 있는 서비스'**
  String get pOnbServices;

  /// No description provided for @pOnbAreas.
  ///
  /// In ko, this message translates to:
  /// **'활동 지역'**
  String get pOnbAreas;

  /// No description provided for @pOnbDone.
  ///
  /// In ko, this message translates to:
  /// **'가입 신청'**
  String get pOnbDone;

  /// No description provided for @pPendingTitle.
  ///
  /// In ko, this message translates to:
  /// **'승인을 기다리고 있어요'**
  String get pPendingTitle;

  /// No description provided for @pPendingBody.
  ///
  /// In ko, this message translates to:
  /// **'운영팀이 확인 후 승인하면 알림을 보내드려요. 그동안 정산 계좌를 등록해 주세요.'**
  String get pPendingBody;

  /// No description provided for @pSuspended.
  ///
  /// In ko, this message translates to:
  /// **'계정이 일시 중지됐어요. 운영팀에 문의해 주세요.'**
  String get pSuspended;

  /// No description provided for @pDirect.
  ///
  /// In ko, this message translates to:
  /// **'바로 예약'**
  String get pDirect;

  /// No description provided for @pQuoteReq.
  ///
  /// In ko, this message translates to:
  /// **'견적 요청'**
  String get pQuoteReq;

  /// No description provided for @pShowClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감된 일감도 보기'**
  String get pShowClosed;

  /// No description provided for @pSortNewest.
  ///
  /// In ko, this message translates to:
  /// **'최신 요청순'**
  String get pSortNewest;

  /// No description provided for @pSortVisit.
  ///
  /// In ko, this message translates to:
  /// **'가까운 방문일순'**
  String get pSortVisit;

  /// No description provided for @pSortAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 높은순'**
  String get pSortAmount;

  /// No description provided for @pNoJobs.
  ///
  /// In ko, this message translates to:
  /// **'지금 맞는 일감이 없어요'**
  String get pNoJobs;

  /// No description provided for @pNoJobsBody.
  ///
  /// In ko, this message translates to:
  /// **'서비스·지역·근무 시간을 넓히면 더 많은 일감을 볼 수 있어요'**
  String get pNoJobsBody;

  /// No description provided for @pPayout.
  ///
  /// In ko, this message translates to:
  /// **'예상 정산'**
  String get pPayout;

  /// No description provided for @pCustomerEstimate.
  ///
  /// In ko, this message translates to:
  /// **'고객 예상가'**
  String get pCustomerEstimate;

  /// No description provided for @pNew.
  ///
  /// In ko, this message translates to:
  /// **'NEW'**
  String get pNew;

  /// No description provided for @pClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get pClosed;

  /// No description provided for @pPrivacyNote.
  ///
  /// In ko, this message translates to:
  /// **'정확한 주소와 고객 정보는 수락 후에 보여요'**
  String get pPrivacyNote;

  /// No description provided for @pAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락하기'**
  String get pAccept;

  /// No description provided for @pAcceptConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 일감을 수락할까요?'**
  String get pAcceptConfirm;

  /// No description provided for @pAcceptBody.
  ///
  /// In ko, this message translates to:
  /// **'수락하면 일정에 추가되고 고객에게 팀 배정 알림이 가요. 방문 2일 전부터는 취소가 어려워요.'**
  String get pAcceptBody;

  /// No description provided for @pAccepted.
  ///
  /// In ko, this message translates to:
  /// **'일감을 수락했어요'**
  String get pAccepted;

  /// No description provided for @pSendQuote.
  ///
  /// In ko, this message translates to:
  /// **'견적 보내기'**
  String get pSendQuote;

  /// No description provided for @pQuotePrice.
  ///
  /// In ko, this message translates to:
  /// **'고객 결제 금액'**
  String get pQuotePrice;

  /// No description provided for @pQuoteNote.
  ///
  /// In ko, this message translates to:
  /// **'상담팀에 전할 메모'**
  String get pQuoteNote;

  /// No description provided for @pQuoteSent.
  ///
  /// In ko, this message translates to:
  /// **'견적을 보냈어요'**
  String get pQuoteSent;

  /// No description provided for @pFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료 {rate}%'**
  String pFee(String rate);

  /// No description provided for @pYouGet.
  ///
  /// In ko, this message translates to:
  /// **'받을 금액'**
  String get pYouGet;

  /// No description provided for @pQuoteAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get pQuoteAll;

  /// No description provided for @pQ_waiting.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get pQ_waiting;

  /// No description provided for @pQ_selected.
  ///
  /// In ko, this message translates to:
  /// **'선택됨'**
  String get pQ_selected;

  /// No description provided for @pQ_rejected.
  ///
  /// In ko, this message translates to:
  /// **'미선택'**
  String get pQ_rejected;

  /// No description provided for @pQ_closed.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get pQ_closed;

  /// No description provided for @pUnseenOnly.
  ///
  /// In ko, this message translates to:
  /// **'새 결과만'**
  String get pUnseenOnly;

  /// No description provided for @pNoQuotes.
  ///
  /// In ko, this message translates to:
  /// **'보낸 견적이 없어요'**
  String get pNoQuotes;

  /// No description provided for @pMyQuote.
  ///
  /// In ko, this message translates to:
  /// **'내 견적'**
  String get pMyQuote;

  /// No description provided for @pWithdraw.
  ///
  /// In ko, this message translates to:
  /// **'견적 철회'**
  String get pWithdraw;

  /// No description provided for @pWithdrawn.
  ///
  /// In ko, this message translates to:
  /// **'견적을 철회했어요'**
  String get pWithdrawn;

  /// No description provided for @pOnlyMine.
  ///
  /// In ko, this message translates to:
  /// **'내 일정만'**
  String get pOnlyMine;

  /// No description provided for @pJobsCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}건'**
  String pJobsCount(String n);

  /// No description provided for @pNoSchedule.
  ///
  /// In ko, this message translates to:
  /// **'이 날은 일정이 없어요'**
  String get pNoSchedule;

  /// No description provided for @pCancelledBanner.
  ///
  /// In ko, this message translates to:
  /// **'고객이 취소한 일감이에요. 완료 처리할 수 없어요.'**
  String get pCancelledBanner;

  /// No description provided for @pRescheduleBanner.
  ///
  /// In ko, this message translates to:
  /// **'일정 변경 요청: {from} → {to}'**
  String pRescheduleBanner(String from, String to);

  /// No description provided for @pRescheduleOk.
  ///
  /// In ko, this message translates to:
  /// **'가능해요'**
  String get pRescheduleOk;

  /// No description provided for @pRescheduleNo.
  ///
  /// In ko, this message translates to:
  /// **'어려워요'**
  String get pRescheduleNo;

  /// No description provided for @pCustomer.
  ///
  /// In ko, this message translates to:
  /// **'고객'**
  String get pCustomer;

  /// No description provided for @pCall.
  ///
  /// In ko, this message translates to:
  /// **'안심번호로 전화'**
  String get pCall;

  /// No description provided for @pCallSoon.
  ///
  /// In ko, this message translates to:
  /// **'안심번호 연결은 서비스 개시 시 활성화돼요'**
  String get pCallSoon;

  /// No description provided for @pQuietHours.
  ///
  /// In ko, this message translates to:
  /// **'20시 이후에는 전화하지 말아 주세요'**
  String get pQuietHours;

  /// No description provided for @pAssignee.
  ///
  /// In ko, this message translates to:
  /// **'담당자'**
  String get pAssignee;

  /// No description provided for @pChangeAssignee.
  ///
  /// In ko, this message translates to:
  /// **'담당자 변경'**
  String get pChangeAssignee;

  /// No description provided for @pCustomerRequests.
  ///
  /// In ko, this message translates to:
  /// **'고객 요청사항'**
  String get pCustomerRequests;

  /// No description provided for @pTeamMemo.
  ///
  /// In ko, this message translates to:
  /// **'팀 메모 (고객에게 보이지 않아요)'**
  String get pTeamMemo;

  /// No description provided for @pMemoSaved.
  ///
  /// In ko, this message translates to:
  /// **'메모를 저장했어요'**
  String get pMemoSaved;

  /// No description provided for @pPayoutBreakdown.
  ///
  /// In ko, this message translates to:
  /// **'정산 내역'**
  String get pPayoutBreakdown;

  /// No description provided for @pAfterBalance.
  ///
  /// In ko, this message translates to:
  /// **'고객 잔금 결제 후 정산돼요'**
  String get pAfterBalance;

  /// No description provided for @pChatOps.
  ///
  /// In ko, this message translates to:
  /// **'운영팀과 채팅'**
  String get pChatOps;

  /// No description provided for @pComplete.
  ///
  /// In ko, this message translates to:
  /// **'작업 완료 체크'**
  String get pComplete;

  /// No description provided for @pBeforePhotos.
  ///
  /// In ko, this message translates to:
  /// **'청소 전 사진'**
  String get pBeforePhotos;

  /// No description provided for @pAfterPhotos.
  ///
  /// In ko, this message translates to:
  /// **'청소 후 사진'**
  String get pAfterPhotos;

  /// No description provided for @pAddPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get pAddPhoto;

  /// No description provided for @pChecklist.
  ///
  /// In ko, this message translates to:
  /// **'확인 항목'**
  String get pChecklist;

  /// No description provided for @pCheck1.
  ///
  /// In ko, this message translates to:
  /// **'요청한 모든 공간을 청소했어요'**
  String get pCheck1;

  /// No description provided for @pCheck2.
  ///
  /// In ko, this message translates to:
  /// **'쓰레기를 정리하고 도구를 회수했어요'**
  String get pCheck2;

  /// No description provided for @pCheck3.
  ///
  /// In ko, this message translates to:
  /// **'창문·전기·수도를 확인했어요'**
  String get pCheck3;

  /// No description provided for @pCheck4.
  ///
  /// In ko, this message translates to:
  /// **'고객 요청사항을 반영했어요'**
  String get pCheck4;

  /// No description provided for @pCompleteCta.
  ///
  /// In ko, this message translates to:
  /// **'완료 처리'**
  String get pCompleteCta;

  /// No description provided for @pCompleteNeed.
  ///
  /// In ko, this message translates to:
  /// **'사진을 각 1장 이상 올리고 모든 항목을 체크해 주세요'**
  String get pCompleteNeed;

  /// No description provided for @pCompleted.
  ///
  /// In ko, this message translates to:
  /// **'수고하셨어요!'**
  String get pCompleted;

  /// No description provided for @pPayoutOn.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 {amount} 정산 예정'**
  String pPayoutOn(String date, String amount);

  /// No description provided for @pPayoutWaiting.
  ///
  /// In ko, this message translates to:
  /// **'고객 잔금 결제 후 정산일이 정해져요'**
  String get pPayoutWaiting;

  /// No description provided for @pPendingPayout.
  ///
  /// In ko, this message translates to:
  /// **'정산 예정 금액'**
  String get pPendingPayout;

  /// No description provided for @pSettlements.
  ///
  /// In ko, this message translates to:
  /// **'정산 내역'**
  String get pSettlements;

  /// No description provided for @pS_waiting_balance.
  ///
  /// In ko, this message translates to:
  /// **'잔금 대기'**
  String get pS_waiting_balance;

  /// No description provided for @pS_pending.
  ///
  /// In ko, this message translates to:
  /// **'정산 예정'**
  String get pS_pending;

  /// No description provided for @pS_paid.
  ///
  /// In ko, this message translates to:
  /// **'지급 완료'**
  String get pS_paid;

  /// No description provided for @pS_held.
  ///
  /// In ko, this message translates to:
  /// **'보류'**
  String get pS_held;

  /// No description provided for @pReviews.
  ///
  /// In ko, this message translates to:
  /// **'고객 리뷰'**
  String get pReviews;

  /// No description provided for @pNoReviews.
  ///
  /// In ko, this message translates to:
  /// **'아직 리뷰가 없어요'**
  String get pNoReviews;

  /// No description provided for @pReplyLater.
  ///
  /// In ko, this message translates to:
  /// **'답글 기능은 곧 열려요'**
  String get pReplyLater;

  /// No description provided for @pServicesAreas.
  ///
  /// In ko, this message translates to:
  /// **'서비스 · 지역'**
  String get pServicesAreas;

  /// No description provided for @pPayoutAccount.
  ///
  /// In ko, this message translates to:
  /// **'정산 계좌'**
  String get pPayoutAccount;

  /// No description provided for @pBank.
  ///
  /// In ko, this message translates to:
  /// **'은행'**
  String get pBank;

  /// No description provided for @pAccountNumber.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호'**
  String get pAccountNumber;

  /// No description provided for @pHolder.
  ///
  /// In ko, this message translates to:
  /// **'예금주'**
  String get pHolder;

  /// No description provided for @pVerified.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료'**
  String get pVerified;

  /// No description provided for @pUnverified.
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get pUnverified;

  /// No description provided for @pAccountSaved.
  ///
  /// In ko, this message translates to:
  /// **'계좌를 저장했어요. 변경 시 다시 확인돼요.'**
  String get pAccountSaved;

  /// No description provided for @pWorkSchedule.
  ///
  /// In ko, this message translates to:
  /// **'근무 일정'**
  String get pWorkSchedule;

  /// No description provided for @pWeekdays.
  ///
  /// In ko, this message translates to:
  /// **'근무 요일'**
  String get pWeekdays;

  /// No description provided for @pDayParts.
  ///
  /// In ko, this message translates to:
  /// **'근무 시간대'**
  String get pDayParts;

  /// No description provided for @pDaysOff.
  ///
  /// In ko, this message translates to:
  /// **'쉬는 날'**
  String get pDaysOff;

  /// No description provided for @pAddDayOff.
  ///
  /// In ko, this message translates to:
  /// **'쉬는 날 추가'**
  String get pAddDayOff;

  /// No description provided for @pSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get pSaved;

  /// No description provided for @pTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀원'**
  String get pTeam;

  /// No description provided for @pOwner.
  ///
  /// In ko, this message translates to:
  /// **'대표'**
  String get pOwner;

  /// No description provided for @pInvited.
  ///
  /// In ko, this message translates to:
  /// **'초대됨'**
  String get pInvited;

  /// No description provided for @pInvite.
  ///
  /// In ko, this message translates to:
  /// **'팀원 초대'**
  String get pInvite;

  /// No description provided for @pInviteSent.
  ///
  /// In ko, this message translates to:
  /// **'초대 문자를 보냈어요'**
  String get pInviteSent;

  /// No description provided for @pRemove.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get pRemove;

  /// No description provided for @pNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get pNotifications;

  /// No description provided for @pNotifyDirect.
  ///
  /// In ko, this message translates to:
  /// **'새 바로 예약 일감'**
  String get pNotifyDirect;

  /// No description provided for @pNotifyQuotes.
  ///
  /// In ko, this message translates to:
  /// **'견적 요청 · 결과'**
  String get pNotifyQuotes;

  /// No description provided for @pNotifyChat.
  ///
  /// In ko, this message translates to:
  /// **'운영팀 메시지'**
  String get pNotifyChat;

  /// No description provided for @pQuietNight.
  ///
  /// In ko, this message translates to:
  /// **'야간 방해 금지 (22–08시)'**
  String get pQuietNight;

  /// No description provided for @pNewInquiry.
  ///
  /// In ko, this message translates to:
  /// **'새 문의'**
  String get pNewInquiry;

  /// No description provided for @pTopic_settlement.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get pTopic_settlement;

  /// No description provided for @pTopic_reschedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 변경 · 취소'**
  String get pTopic_reschedule;

  /// No description provided for @pTopic_app.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용'**
  String get pTopic_app;

  /// No description provided for @pOpsTeam.
  ///
  /// In ko, this message translates to:
  /// **'운영팀'**
  String get pOpsTeam;

  /// No description provided for @pViewJob.
  ///
  /// In ko, this message translates to:
  /// **'일감 보기'**
  String get pViewJob;

  /// No description provided for @pBookingNo.
  ///
  /// In ko, this message translates to:
  /// **'예약번호 {n}'**
  String pBookingNo(String n);

  /// No description provided for @pSize.
  ///
  /// In ko, this message translates to:
  /// **'면적'**
  String get pSize;

  /// No description provided for @pSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get pSchedule;

  /// No description provided for @pSpace.
  ///
  /// In ko, this message translates to:
  /// **'공간 정보'**
  String get pSpace;
}

class _TDelegate extends LocalizationsDelegate<T> {
  const _TDelegate();

  @override
  Future<T> load(Locale locale) {
    return SynchronousFuture<T>(lookupT(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_TDelegate old) => false;
}

T lookupT(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TEn();
    case 'ja':
      return TJa();
    case 'ko':
      return TKo();
    case 'vi':
      return TVi();
    case 'zh':
      return TZh();
  }

  throw FlutterError(
    'T.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
