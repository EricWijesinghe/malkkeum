import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_km.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_mn.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_si.dart';
import 'app_localizations_th.dart';
import 'app_localizations_uz.dart';
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
    Locale('fil'),
    Locale('id'),
    Locale('ja'),
    Locale('km'),
    Locale('ko'),
    Locale('mn'),
    Locale('ne'),
    Locale('ru'),
    Locale('si'),
    Locale('th'),
    Locale('uz'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @addressSearch.
  ///
  /// In ko, this message translates to:
  /// **'주소 검색'**
  String get addressSearch;

  /// No description provided for @addressSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'도로명, 건물명, 지번으로 검색'**
  String get addressSearchHint;

  /// No description provided for @addressSearchButton.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get addressSearchButton;

  /// No description provided for @addressSearchMinChars.
  ///
  /// In ko, this message translates to:
  /// **'두 글자 이상 입력해 주세요'**
  String get addressSearchMinChars;

  /// No description provided for @addressNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요. 다른 단어로 검색해 보세요.'**
  String get addressNoResults;

  /// No description provided for @addressManualEntry.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get addressManualEntry;

  /// No description provided for @cardRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 등록'**
  String get cardRegisterTitle;

  /// No description provided for @cIntJuso.
  ///
  /// In ko, this message translates to:
  /// **'주소 검색 (도로명주소)'**
  String get cIntJuso;

  /// No description provided for @aiLabel.
  ///
  /// In ko, this message translates to:
  /// **'AI 상담원'**
  String get aiLabel;

  /// No description provided for @aiBadge.
  ///
  /// In ko, this message translates to:
  /// **'AI'**
  String get aiBadge;

  /// No description provided for @aiCardHint.
  ///
  /// In ko, this message translates to:
  /// **'고객 채팅에 자동으로 답변해요. 메시지마다 API 요금이 발생해요.'**
  String get aiCardHint;

  /// No description provided for @aiModeOffline.
  ///
  /// In ko, this message translates to:
  /// **'상담원이 없을 때만 답변'**
  String get aiModeOffline;

  /// No description provided for @aiModeAlways.
  ///
  /// In ko, this message translates to:
  /// **'항상 AI가 먼저 답변'**
  String get aiModeAlways;

  /// No description provided for @aiPause.
  ///
  /// In ko, this message translates to:
  /// **'AI 일시중지'**
  String get aiPause;

  /// No description provided for @aiResume.
  ///
  /// In ko, this message translates to:
  /// **'AI 재개'**
  String get aiResume;

  /// No description provided for @aiPausedNote.
  ///
  /// In ko, this message translates to:
  /// **'AI가 이 대화에 답변하지 않아요'**
  String get aiPausedNote;

  /// No description provided for @aiUsageMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 AI 호출 {count}회'**
  String aiUsageMonth(String count);

  /// No description provided for @aiNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'AI 상담원이 꺼져 있어요'**
  String get aiNotConfigured;

  /// No description provided for @aiCapThreadLabel.
  ///
  /// In ko, this message translates to:
  /// **'대화당 시간당 답변 한도'**
  String get aiCapThreadLabel;

  /// No description provided for @aiCapMemberLabel.
  ///
  /// In ko, this message translates to:
  /// **'고객 한 명당 하루 답변 한도'**
  String get aiCapMemberLabel;

  /// No description provided for @aiCapDailyLabel.
  ///
  /// In ko, this message translates to:
  /// **'하루 전체 답변 한도'**
  String get aiCapDailyLabel;

  /// No description provided for @aiCapHint.
  ///
  /// In ko, this message translates to:
  /// **'숫자만 입력해요. 비워두면 기본값을 써요.'**
  String get aiCapHint;

  /// No description provided for @apSocialOr.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get apSocialOr;

  /// No description provided for @apSocialSignIn.
  ///
  /// In ko, this message translates to:
  /// **'간편 로그인'**
  String get apSocialSignIn;

  /// No description provided for @apLoginKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 계속하기'**
  String get apLoginKakao;

  /// No description provided for @apLoginNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버로 계속하기'**
  String get apLoginNaver;

  /// No description provided for @apLoginGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get apLoginGoogle;

  /// No description provided for @apLoginApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get apLoginApple;

  /// No description provided for @apDevSocialNote.
  ///
  /// In ko, this message translates to:
  /// **'개발 모드예요. 실제 소셜 계정이 아니라 테스트 계정으로 로그인해요.'**
  String get apDevSocialNote;

  /// No description provided for @apSocialFailed.
  ///
  /// In ko, this message translates to:
  /// **'간편 로그인에 실패했어요. 다시 시도해 주세요.'**
  String get apSocialFailed;

  /// No description provided for @apProviderNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'이 로그인 수단은 아직 준비 중이에요'**
  String get apProviderNotConfigured;

  /// No description provided for @apPhoneTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 다른 계정에 등록된 번호예요'**
  String get apPhoneTaken;

  /// No description provided for @apPhoneAttachTitle.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호를 인증해 주세요'**
  String get apPhoneAttachTitle;

  /// No description provided for @apPhoneAttachBody.
  ///
  /// In ko, this message translates to:
  /// **'예약과 기사 연락에 쓰는 번호예요. 한 번만 인증하면 돼요.'**
  String get apPhoneAttachBody;

  /// No description provided for @apPayAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 선택'**
  String get apPayAllTitle;

  /// No description provided for @apPaySavedTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장한 결제수단'**
  String get apPaySavedTitle;

  /// No description provided for @apPayMoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 결제수단'**
  String get apPayMoreTitle;

  /// No description provided for @apPayBillingHint.
  ///
  /// In ko, this message translates to:
  /// **'한 번 등록하면 다음부터 한 번에 결제해요'**
  String get apPayBillingHint;

  /// No description provided for @apPayCheckoutHint.
  ///
  /// In ko, this message translates to:
  /// **'결제창에서 마무리해요'**
  String get apPayCheckoutHint;

  /// No description provided for @apPayRegistering.
  ///
  /// In ko, this message translates to:
  /// **'등록하는 중이에요'**
  String get apPayRegistering;

  /// No description provided for @apPayManageHint.
  ///
  /// In ko, this message translates to:
  /// **'등록한 결제수단으로 한 번에 결제해요. 간편결제는 여기서 추가할 수 있어요.'**
  String get apPayManageHint;

  /// No description provided for @apMethodCard.
  ///
  /// In ko, this message translates to:
  /// **'신용·체크카드'**
  String get apMethodCard;

  /// No description provided for @apMethodKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오페이'**
  String get apMethodKakao;

  /// No description provided for @apMethodNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버페이'**
  String get apMethodNaver;

  /// No description provided for @apMethodToss.
  ///
  /// In ko, this message translates to:
  /// **'토스페이'**
  String get apMethodToss;

  /// No description provided for @apMethodPayco.
  ///
  /// In ko, this message translates to:
  /// **'페이코'**
  String get apMethodPayco;

  /// No description provided for @apMethodSamsung.
  ///
  /// In ko, this message translates to:
  /// **'삼성페이'**
  String get apMethodSamsung;

  /// No description provided for @apMethodApple.
  ///
  /// In ko, this message translates to:
  /// **'애플페이'**
  String get apMethodApple;

  /// No description provided for @apMethodTransfer.
  ///
  /// In ko, this message translates to:
  /// **'계좌이체'**
  String get apMethodTransfer;

  /// No description provided for @apMethodVirtual.
  ///
  /// In ko, this message translates to:
  /// **'가상계좌'**
  String get apMethodVirtual;

  /// No description provided for @apMethodPhone.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 결제'**
  String get apMethodPhone;

  /// No description provided for @apMethodUnknown.
  ///
  /// In ko, this message translates to:
  /// **'기타 결제'**
  String get apMethodUnknown;

  /// No description provided for @apVaTitle.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌가 준비됐어요'**
  String get apVaTitle;

  /// No description provided for @apVaWaiting.
  ///
  /// In ko, this message translates to:
  /// **'입금 대기 중'**
  String get apVaWaiting;

  /// No description provided for @apVaBody.
  ///
  /// In ko, this message translates to:
  /// **'기한 안에 입금하면 예약이 확정돼요. 입금은 자동으로 확인돼요.'**
  String get apVaBody;

  /// No description provided for @apVaBank.
  ///
  /// In ko, this message translates to:
  /// **'은행'**
  String get apVaBank;

  /// No description provided for @apVaAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호'**
  String get apVaAccount;

  /// No description provided for @apVaHolder.
  ///
  /// In ko, this message translates to:
  /// **'예금주'**
  String get apVaHolder;

  /// No description provided for @apVaAmount.
  ///
  /// In ko, this message translates to:
  /// **'입금 금액'**
  String get apVaAmount;

  /// No description provided for @apVaDue.
  ///
  /// In ko, this message translates to:
  /// **'{due}까지 입금해 주세요'**
  String apVaDue(String due);

  /// No description provided for @apVaCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get apVaCopy;

  /// No description provided for @apVaCopied.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호를 복사했어요'**
  String get apVaCopied;

  /// No description provided for @apVaBannerTitle.
  ///
  /// In ko, this message translates to:
  /// **'입금 대기 중인 예약이 있어요'**
  String get apVaBannerTitle;

  /// No description provided for @apVaBannerBody.
  ///
  /// In ko, this message translates to:
  /// **'{amount} · {due}까지'**
  String apVaBannerBody(String amount, String due);

  /// No description provided for @apVaBannerAction.
  ///
  /// In ko, this message translates to:
  /// **'계좌 보기'**
  String get apVaBannerAction;

  /// No description provided for @apPgTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제창'**
  String get apPgTitle;

  /// No description provided for @apPgDevNote.
  ///
  /// In ko, this message translates to:
  /// **'개발 환경 전용 결제 시뮬레이션이에요. 실제 결제는 일어나지 않아요.'**
  String get apPgDevNote;

  /// No description provided for @apPgPay.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 결제하기'**
  String apPgPay(String amount);

  /// No description provided for @apPgIssue.
  ///
  /// In ko, this message translates to:
  /// **'계좌 발급받기'**
  String get apPgIssue;

  /// No description provided for @apPgCancel.
  ///
  /// In ko, this message translates to:
  /// **'결제 취소'**
  String get apPgCancel;

  /// No description provided for @apErrSlotFullRefunded.
  ///
  /// In ko, this message translates to:
  /// **'방금 그 시간이 마감돼서 결제가 자동 취소됐어요'**
  String get apErrSlotFullRefunded;

  /// No description provided for @apErrCheckoutExpired.
  ///
  /// In ko, this message translates to:
  /// **'결제 시간이 지났어요. 다시 시도해 주세요.'**
  String get apErrCheckoutExpired;

  /// No description provided for @apIdentityTitle.
  ///
  /// In ko, this message translates to:
  /// **'본인인증 (PASS)'**
  String get apIdentityTitle;

  /// No description provided for @apIdentityBody.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 명의로 본인을 확인해요. 안전한 거래와 정산에 쓰여요.'**
  String get apIdentityBody;

  /// No description provided for @apIdentityAction.
  ///
  /// In ko, this message translates to:
  /// **'본인인증하기'**
  String get apIdentityAction;

  /// No description provided for @apIdentityDone.
  ///
  /// In ko, this message translates to:
  /// **'본인인증이 완료됐어요'**
  String get apIdentityDone;

  /// No description provided for @apIdentityVerified.
  ///
  /// In ko, this message translates to:
  /// **'인증 완료'**
  String get apIdentityVerified;

  /// No description provided for @apIdentityUnverified.
  ///
  /// In ko, this message translates to:
  /// **'아직 인증하지 않았어요'**
  String get apIdentityUnverified;

  /// No description provided for @apIdentityDevTitle.
  ///
  /// In ko, this message translates to:
  /// **'테스트 본인인증'**
  String get apIdentityDevTitle;

  /// No description provided for @apIdentityDevBody.
  ///
  /// In ko, this message translates to:
  /// **'개발 환경에서는 실제 인증 없이 통과해요.'**
  String get apIdentityDevBody;

  /// No description provided for @apIdentityDevPass.
  ///
  /// In ko, this message translates to:
  /// **'통과 처리'**
  String get apIdentityDevPass;

  /// No description provided for @apPayManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'간편결제 등록'**
  String get apPayManageTitle;

  /// No description provided for @cTitle.
  ///
  /// In ko, this message translates to:
  /// **'운영 콘솔'**
  String get cTitle;

  /// No description provided for @cEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get cEmail;

  /// No description provided for @cPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get cPassword;

  /// No description provided for @cLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get cLogin;

  /// No description provided for @cLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 맞지 않아요'**
  String get cLoginFailed;

  /// No description provided for @cDashboard.
  ///
  /// In ko, this message translates to:
  /// **'대시보드'**
  String get cDashboard;

  /// No description provided for @cBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get cBookings;

  /// No description provided for @cQuoteDesk.
  ///
  /// In ko, this message translates to:
  /// **'견적 데스크'**
  String get cQuoteDesk;

  /// No description provided for @cInbox.
  ///
  /// In ko, this message translates to:
  /// **'상담함'**
  String get cInbox;

  /// No description provided for @cCatalog.
  ///
  /// In ko, this message translates to:
  /// **'카탈로그 · 가격'**
  String get cCatalog;

  /// No description provided for @cMarketing.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 · 콘텐츠'**
  String get cMarketing;

  /// No description provided for @cPartners.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get cPartners;

  /// No description provided for @cSettlements.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get cSettlements;

  /// No description provided for @cCustomers.
  ///
  /// In ko, this message translates to:
  /// **'고객'**
  String get cCustomers;

  /// No description provided for @cStaff.
  ///
  /// In ko, this message translates to:
  /// **'직원'**
  String get cStaff;

  /// No description provided for @cSearchCommand.
  ///
  /// In ko, this message translates to:
  /// **'검색 · 명령'**
  String get cSearchCommand;

  /// No description provided for @cPaletteHint.
  ///
  /// In ko, this message translates to:
  /// **'메뉴 이름이나 예약번호를 입력하세요'**
  String get cPaletteHint;

  /// No description provided for @cTodayJobs.
  ///
  /// In ko, this message translates to:
  /// **'오늘 작업'**
  String get cTodayJobs;

  /// No description provided for @cOpenQuotes.
  ///
  /// In ko, this message translates to:
  /// **'견적 대기'**
  String get cOpenQuotes;

  /// No description provided for @cUnassigned.
  ///
  /// In ko, this message translates to:
  /// **'미배정'**
  String get cUnassigned;

  /// No description provided for @cUnreadThreads.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 상담'**
  String get cUnreadThreads;

  /// No description provided for @cRevenue30.
  ///
  /// In ko, this message translates to:
  /// **'30일 결제액'**
  String get cRevenue30;

  /// No description provided for @cBookings30.
  ///
  /// In ko, this message translates to:
  /// **'30일 예약'**
  String get cBookings30;

  /// No description provided for @cByService.
  ///
  /// In ko, this message translates to:
  /// **'서비스별 예약 (30일)'**
  String get cByService;

  /// No description provided for @cAllStatus.
  ///
  /// In ko, this message translates to:
  /// **'전체 상태'**
  String get cAllStatus;

  /// No description provided for @cAllServices.
  ///
  /// In ko, this message translates to:
  /// **'전체 서비스'**
  String get cAllServices;

  /// No description provided for @cSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색 (예약번호, 전화, 이름, 주소)'**
  String get cSearch;

  /// No description provided for @cNoResults.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get cNoResults;

  /// No description provided for @cNumber.
  ///
  /// In ko, this message translates to:
  /// **'예약번호'**
  String get cNumber;

  /// No description provided for @cVisit.
  ///
  /// In ko, this message translates to:
  /// **'방문'**
  String get cVisit;

  /// No description provided for @cService.
  ///
  /// In ko, this message translates to:
  /// **'서비스'**
  String get cService;

  /// No description provided for @cStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get cStatus;

  /// No description provided for @cTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get cTeam;

  /// No description provided for @cAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get cAmount;

  /// No description provided for @cCustomer.
  ///
  /// In ko, this message translates to:
  /// **'고객'**
  String get cCustomer;

  /// No description provided for @cPayments.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get cPayments;

  /// No description provided for @cChangeStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태 변경'**
  String get cChangeStatus;

  /// No description provided for @cTeamName.
  ///
  /// In ko, this message translates to:
  /// **'배정 팀 이름'**
  String get cTeamName;

  /// No description provided for @cAssign.
  ///
  /// In ko, this message translates to:
  /// **'팀 배정'**
  String get cAssign;

  /// No description provided for @cMarkDone.
  ///
  /// In ko, this message translates to:
  /// **'완료 처리'**
  String get cMarkDone;

  /// No description provided for @cConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확정 처리'**
  String get cConfirm;

  /// No description provided for @cCancelRefund.
  ///
  /// In ko, this message translates to:
  /// **'취소 · 환불'**
  String get cCancelRefund;

  /// No description provided for @cRefundAmount.
  ///
  /// In ko, this message translates to:
  /// **'환불 금액 (비우면 전액)'**
  String get cRefundAmount;

  /// No description provided for @cDone.
  ///
  /// In ko, this message translates to:
  /// **'처리했어요'**
  String get cDone;

  /// No description provided for @cAnswers.
  ///
  /// In ko, this message translates to:
  /// **'고객 답변'**
  String get cAnswers;

  /// No description provided for @cEstimateCalc.
  ///
  /// In ko, this message translates to:
  /// **'자동 산정'**
  String get cEstimateCalc;

  /// No description provided for @cBase.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get cBase;

  /// No description provided for @cExtras.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get cExtras;

  /// No description provided for @cSurcharge.
  ///
  /// In ko, this message translates to:
  /// **'할증'**
  String get cSurcharge;

  /// No description provided for @cBeforeVat.
  ///
  /// In ko, this message translates to:
  /// **'부가세 전'**
  String get cBeforeVat;

  /// No description provided for @cProQuotes.
  ///
  /// In ko, this message translates to:
  /// **'파트너 견적'**
  String get cProQuotes;

  /// No description provided for @cNoProQuotes.
  ///
  /// In ko, this message translates to:
  /// **'아직 받은 견적이 없어요'**
  String get cNoProQuotes;

  /// No description provided for @cFinalPrice.
  ///
  /// In ko, this message translates to:
  /// **'고객 최종 금액'**
  String get cFinalPrice;

  /// No description provided for @cQuoteNote.
  ///
  /// In ko, this message translates to:
  /// **'고객에게 보낼 메모'**
  String get cQuoteNote;

  /// No description provided for @cSendQuote.
  ///
  /// In ko, this message translates to:
  /// **'고객에게 견적 보내기'**
  String get cSendQuote;

  /// No description provided for @cQuoteSent.
  ///
  /// In ko, this message translates to:
  /// **'견적을 보냈어요'**
  String get cQuoteSent;

  /// No description provided for @cCustomerChats.
  ///
  /// In ko, this message translates to:
  /// **'고객'**
  String get cCustomerChats;

  /// No description provided for @cPartnerChats.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get cPartnerChats;

  /// No description provided for @cSelectBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약을 선택하세요'**
  String get cSelectBooking;

  /// No description provided for @cRefunded.
  ///
  /// In ko, this message translates to:
  /// **'환불됨'**
  String get cRefunded;

  /// No description provided for @cPartRefunded.
  ///
  /// In ko, this message translates to:
  /// **'부분 환불'**
  String get cPartRefunded;

  /// No description provided for @cFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get cFailed;

  /// No description provided for @cSelectThread.
  ///
  /// In ko, this message translates to:
  /// **'대화를 선택하세요'**
  String get cSelectThread;

  /// No description provided for @cReplyHint.
  ///
  /// In ko, this message translates to:
  /// **'답장 입력 · Ctrl+Enter 전송'**
  String get cReplyHint;

  /// No description provided for @cOpenBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약 열기'**
  String get cOpenBooking;

  /// No description provided for @cShortcuts.
  ///
  /// In ko, this message translates to:
  /// **'J/K 이동 · Ctrl+K 명령'**
  String get cShortcuts;

  /// No description provided for @cPricing.
  ///
  /// In ko, this message translates to:
  /// **'가격'**
  String get cPricing;

  /// No description provided for @cMinutes.
  ///
  /// In ko, this message translates to:
  /// **'소요(분)'**
  String get cMinutes;

  /// No description provided for @cActive.
  ///
  /// In ko, this message translates to:
  /// **'판매 중'**
  String get cActive;

  /// No description provided for @cSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get cSaved;

  /// No description provided for @cSlotCapacity.
  ///
  /// In ko, this message translates to:
  /// **'시간대별 수용량'**
  String get cSlotCapacity;

  /// No description provided for @cUnlimited.
  ///
  /// In ko, this message translates to:
  /// **'제한 없음'**
  String get cUnlimited;

  /// No description provided for @cFormula.
  ///
  /// In ko, this message translates to:
  /// **'견적 산정식'**
  String get cFormula;

  /// No description provided for @cTabCancelPolicy.
  ///
  /// In ko, this message translates to:
  /// **'취소 정책'**
  String get cTabCancelPolicy;

  /// No description provided for @cPolicyDefaultBanner.
  ///
  /// In ko, this message translates to:
  /// **'기본값이에요. 아래 내용을 확인하고 저장해 주세요.'**
  String get cPolicyDefaultBanner;

  /// No description provided for @cPolicyDaysBefore.
  ///
  /// In ko, this message translates to:
  /// **'방문 며칠 전부터 (일)'**
  String get cPolicyDaysBefore;

  /// No description provided for @cPolicyPercent.
  ///
  /// In ko, this message translates to:
  /// **'수수료 % (비우면 앱 취소 불가)'**
  String get cPolicyPercent;

  /// No description provided for @cPolicyMinFee.
  ///
  /// In ko, this message translates to:
  /// **'최소 수수료 (원)'**
  String get cPolicyMinFee;

  /// No description provided for @cPolicyReschedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 변경 가능 (방문 며칠 전부터)'**
  String get cPolicyReschedule;

  /// No description provided for @cPolicyHint.
  ///
  /// In ko, this message translates to:
  /// **'고객 앱 취소 화면에 바로 반영돼요. 이용약관은 빌드 후 갱신돼요.'**
  String get cPolicyHint;

  /// No description provided for @f_base_studio.
  ///
  /// In ko, this message translates to:
  /// **'원룸 기본'**
  String get f_base_studio;

  /// No description provided for @f_base_one_and_half.
  ///
  /// In ko, this message translates to:
  /// **'1.5룸 기본'**
  String get f_base_one_and_half;

  /// No description provided for @f_base_two_rooms.
  ///
  /// In ko, this message translates to:
  /// **'방 2개 기본'**
  String get f_base_two_rooms;

  /// No description provided for @f_base_three_rooms.
  ///
  /// In ko, this message translates to:
  /// **'방 3개 기본'**
  String get f_base_three_rooms;

  /// No description provided for @f_base_four_plus.
  ///
  /// In ko, this message translates to:
  /// **'방 4개 이상 기본'**
  String get f_base_four_plus;

  /// No description provided for @f_per_extra_bathroom.
  ///
  /// In ko, this message translates to:
  /// **'욕실 추가당'**
  String get f_per_extra_bathroom;

  /// No description provided for @f_per_balcony.
  ///
  /// In ko, this message translates to:
  /// **'발코니당'**
  String get f_per_balcony;

  /// No description provided for @f_duplex.
  ///
  /// In ko, this message translates to:
  /// **'복층'**
  String get f_duplex;

  /// No description provided for @f_no_elevator_high_floor.
  ///
  /// In ko, this message translates to:
  /// **'엘리베이터 없음 + 3층 이상'**
  String get f_no_elevator_high_floor;

  /// No description provided for @cIssueCoupon.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 발급'**
  String get cIssueCoupon;

  /// No description provided for @cCouponName.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 이름'**
  String get cCouponName;

  /// No description provided for @cCouponPhones.
  ///
  /// In ko, this message translates to:
  /// **'대상 전화번호 (줄바꿈으로 구분)'**
  String get cCouponPhones;

  /// No description provided for @cAllCustomers.
  ///
  /// In ko, this message translates to:
  /// **'전체 고객에게'**
  String get cAllCustomers;

  /// No description provided for @cIssued.
  ///
  /// In ko, this message translates to:
  /// **'{n}장 발급했어요'**
  String cIssued(String n);

  /// No description provided for @cContent.
  ///
  /// In ko, this message translates to:
  /// **'콘텐츠'**
  String get cContent;

  /// No description provided for @cKind_notice.
  ///
  /// In ko, this message translates to:
  /// **'공지'**
  String get cKind_notice;

  /// No description provided for @cKind_tip.
  ///
  /// In ko, this message translates to:
  /// **'팁'**
  String get cKind_tip;

  /// No description provided for @cKind_faq.
  ///
  /// In ko, this message translates to:
  /// **'FAQ'**
  String get cKind_faq;

  /// No description provided for @cKind_banner.
  ///
  /// In ko, this message translates to:
  /// **'배너'**
  String get cKind_banner;

  /// No description provided for @cKind_legal.
  ///
  /// In ko, this message translates to:
  /// **'약관'**
  String get cKind_legal;

  /// No description provided for @cNewContent.
  ///
  /// In ko, this message translates to:
  /// **'새 콘텐츠'**
  String get cNewContent;

  /// No description provided for @cTitleField.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get cTitleField;

  /// No description provided for @cBodyField.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get cBodyField;

  /// No description provided for @cSlug.
  ///
  /// In ko, this message translates to:
  /// **'식별자 (약관: privacy / terms)'**
  String get cSlug;

  /// No description provided for @cVerify.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get cVerify;

  /// No description provided for @cSuspend.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get cSuspend;

  /// No description provided for @cPro_pending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get cPro_pending;

  /// No description provided for @cPro_verified.
  ///
  /// In ko, this message translates to:
  /// **'활동 중'**
  String get cPro_verified;

  /// No description provided for @cPro_suspended.
  ///
  /// In ko, this message translates to:
  /// **'중지됨'**
  String get cPro_suspended;

  /// No description provided for @cCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get cCompleted;

  /// No description provided for @cCancelledN.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cCancelledN;

  /// No description provided for @cRating.
  ///
  /// In ko, this message translates to:
  /// **'평점'**
  String get cRating;

  /// No description provided for @cFeeRate.
  ///
  /// In ko, this message translates to:
  /// **'수수료율 %'**
  String get cFeeRate;

  /// No description provided for @cRunPayouts.
  ///
  /// In ko, this message translates to:
  /// **'정산 지급 실행'**
  String get cRunPayouts;

  /// No description provided for @cPayoutDate.
  ///
  /// In ko, this message translates to:
  /// **'지급 기준일'**
  String get cPayoutDate;

  /// No description provided for @cPayoutDone.
  ///
  /// In ko, this message translates to:
  /// **'{n}명에게 지급 처리했어요'**
  String cPayoutDone(String n);

  /// No description provided for @cHold.
  ///
  /// In ko, this message translates to:
  /// **'보류'**
  String get cHold;

  /// No description provided for @cRelease.
  ///
  /// In ko, this message translates to:
  /// **'보류 해제'**
  String get cRelease;

  /// No description provided for @cNet.
  ///
  /// In ko, this message translates to:
  /// **'지급액'**
  String get cNet;

  /// No description provided for @cAddStaff.
  ///
  /// In ko, this message translates to:
  /// **'직원 추가'**
  String get cAddStaff;

  /// No description provided for @cRoleAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get cRoleAdmin;

  /// No description provided for @cRoleConsultant.
  ///
  /// In ko, this message translates to:
  /// **'상담원'**
  String get cRoleConsultant;

  /// No description provided for @cDeactivate.
  ///
  /// In ko, this message translates to:
  /// **'비활성화'**
  String get cDeactivate;

  /// No description provided for @cActivate.
  ///
  /// In ko, this message translates to:
  /// **'활성화'**
  String get cActivate;

  /// No description provided for @cPasswordRule.
  ///
  /// In ko, this message translates to:
  /// **'12자 이상'**
  String get cPasswordRule;

  /// No description provided for @cAdminOnly.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 할 수 있어요'**
  String get cAdminOnly;

  /// No description provided for @cBookingsCount.
  ///
  /// In ko, this message translates to:
  /// **'예약 {n}건'**
  String cBookingsCount(String n);

  /// No description provided for @cJoined.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get cJoined;

  /// No description provided for @cNewBooking.
  ///
  /// In ko, this message translates to:
  /// **'새 예약이 들어왔어요'**
  String get cNewBooking;

  /// No description provided for @cNewMessage.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지'**
  String get cNewMessage;

  /// No description provided for @cConfirmAsk.
  ///
  /// In ko, this message translates to:
  /// **'정말 진행할까요?'**
  String get cConfirmAsk;

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
  /// **'이 시점부터는 앱에서 취소할 수 없어요. 상담팀에 문의해 주세요'**
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

  /// No description provided for @photoThumb.
  ///
  /// In ko, this message translates to:
  /// **'사진 {n}'**
  String photoThumb(String n);

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

  /// No description provided for @cancelFeeNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 취소하면 취소 수수료 {fee}이 적용되고 {refund}이 환불돼요.'**
  String cancelFeeNow(String fee, String refund);

  /// No description provided for @cancelFeeAccept.
  ///
  /// In ko, this message translates to:
  /// **'수수료 {fee} 확인하고 취소'**
  String cancelFeeAccept(String fee);

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

  /// No description provided for @ratingStars.
  ///
  /// In ko, this message translates to:
  /// **'{n}점'**
  String ratingStars(String n);

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

  /// No description provided for @cpTitle.
  ///
  /// In ko, this message translates to:
  /// **'취소·변경 정책'**
  String get cpTitle;

  /// No description provided for @cpWhen.
  ///
  /// In ko, this message translates to:
  /// **'방문 {days}일 이상 전'**
  String cpWhen(String days);

  /// No description provided for @cpWhenSameDay.
  ///
  /// In ko, this message translates to:
  /// **'방문 당일'**
  String get cpWhenSameDay;

  /// No description provided for @cpFree.
  ///
  /// In ko, this message translates to:
  /// **'전액 환불'**
  String get cpFree;

  /// No description provided for @cpFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료 {percent}% ({fee}), 환불 {refund}'**
  String cpFee(String percent, String fee, String refund);

  /// No description provided for @cpClosed.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 취소 불가 (상담팀 확인)'**
  String get cpClosed;

  /// No description provided for @hhTitle.
  ///
  /// In ko, this message translates to:
  /// **'가구 정보'**
  String get hhTitle;

  /// No description provided for @hhAddPet.
  ///
  /// In ko, this message translates to:
  /// **'반려동물 추가'**
  String get hhAddPet;

  /// No description provided for @hhPetCount.
  ///
  /// In ko, this message translates to:
  /// **'마리 수'**
  String get hhPetCount;

  /// No description provided for @hhFloorLabel.
  ///
  /// In ko, this message translates to:
  /// **'층 (지하는 음수)'**
  String get hhFloorLabel;

  /// No description provided for @hhElevator.
  ///
  /// In ko, this message translates to:
  /// **'엘리베이터 있음'**
  String get hhElevator;

  /// No description provided for @hhNotes.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get hhNotes;

  /// No description provided for @hhHint.
  ///
  /// In ko, this message translates to:
  /// **'주소에 저장되고, 예약마다 바꿀 수 있어요.'**
  String get hhHint;

  /// No description provided for @themeTitle.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeTitle;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get themeSystem;

  /// No description provided for @themeTip.
  ///
  /// In ko, this message translates to:
  /// **'테마 바꾸기'**
  String get themeTip;

  /// No description provided for @err_price_changed.
  ///
  /// In ko, this message translates to:
  /// **'가격이 바뀌었어요. 새 견적을 확인하고 다시 시도해 주세요.'**
  String get err_price_changed;

  /// No description provided for @err_checkout_closed.
  ///
  /// In ko, this message translates to:
  /// **'이 결제는 이미 종료됐어요. 다시 시작해 주세요.'**
  String get err_checkout_closed;

  /// No description provided for @err_checkout_refunded.
  ///
  /// In ko, this message translates to:
  /// **'이 결제는 취소되어 환불됐어요.'**
  String get err_checkout_refunded;

  /// No description provided for @err_already_paid.
  ///
  /// In ko, this message translates to:
  /// **'이미 결제가 끝났어요.'**
  String get err_already_paid;

  /// No description provided for @err_quote_not_payable.
  ///
  /// In ko, this message translates to:
  /// **'아직 결제할 수 없는 견적이에요. 상담팀에 확인해 주세요.'**
  String get err_quote_not_payable;

  /// No description provided for @err_payment_method_disabled.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 결제수단을 쓸 수 없어요.'**
  String get err_payment_method_disabled;

  /// No description provided for @err_invalid_payment_method.
  ///
  /// In ko, this message translates to:
  /// **'선택한 결제수단을 쓸 수 없어요. 다른 방법을 골라 주세요.'**
  String get err_invalid_payment_method;

  /// No description provided for @err_balance_not_due.
  ///
  /// In ko, this message translates to:
  /// **'잔금은 아직 결제할 시기가 아니에요.'**
  String get err_balance_not_due;

  /// No description provided for @err_invalid_slot.
  ///
  /// In ko, this message translates to:
  /// **'이 서비스에서는 고를 수 없는 시간이에요.'**
  String get err_invalid_slot;

  /// No description provided for @err_booking_changed.
  ///
  /// In ko, this message translates to:
  /// **'예약 내용이 바뀌었어요. 새로고침 후 다시 확인해 주세요.'**
  String get err_booking_changed;

  /// No description provided for @err_booking_closed.
  ///
  /// In ko, this message translates to:
  /// **'이 예약은 더 이상 바꿀 수 없어요.'**
  String get err_booking_closed;

  /// No description provided for @err_reschedule_closed.
  ///
  /// In ko, this message translates to:
  /// **'방문 날짜는 지금 변경할 수 없어요. 상담팀에 문의해 주세요.'**
  String get err_reschedule_closed;

  /// No description provided for @err_too_many_open_requests.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 요청이 너무 많아요. 하나를 마무리한 뒤 다시 시도해 주세요.'**
  String get err_too_many_open_requests;

  /// No description provided for @err_already_reviewed.
  ///
  /// In ko, this message translates to:
  /// **'이미 후기를 남긴 방문이에요.'**
  String get err_already_reviewed;

  /// No description provided for @err_identity_not_verified.
  ///
  /// In ko, this message translates to:
  /// **'본인인증을 먼저 완료해 주세요.'**
  String get err_identity_not_verified;

  /// No description provided for @err_email_taken.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일이에요.'**
  String get err_email_taken;

  /// No description provided for @err_invalid_email.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소를 확인해 주세요.'**
  String get err_invalid_email;

  /// No description provided for @err_file_too_large.
  ///
  /// In ko, this message translates to:
  /// **'파일이 너무 커요. 더 작은 파일을 올려 주세요.'**
  String get err_file_too_large;

  /// No description provided for @err_unsupported_image.
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 사진 형식이에요. JPG나 PNG로 올려 주세요.'**
  String get err_unsupported_image;

  /// No description provided for @err_upload_quota.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 업로드 한도에 도달했어요. 내일 다시 시도해 주세요.'**
  String get err_upload_quota;

  /// No description provided for @err_provider_unreachable.
  ///
  /// In ko, this message translates to:
  /// **'서비스에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.'**
  String get err_provider_unreachable;

  /// No description provided for @err_invalid_token.
  ///
  /// In ko, this message translates to:
  /// **'로그인 정보가 올바르지 않아요. 다시 시도해 주세요.'**
  String get err_invalid_token;

  /// No description provided for @err_invalid_transition.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 상태로 바꿀 수 없어요.'**
  String get err_invalid_transition;

  /// No description provided for @err_job_not_started.
  ///
  /// In ko, this message translates to:
  /// **'먼저 작업을 시작해 주세요.'**
  String get err_job_not_started;

  /// No description provided for @err_job_not_active.
  ///
  /// In ko, this message translates to:
  /// **'지금은 진행할 수 없는 작업이에요.'**
  String get err_job_not_active;

  /// No description provided for @err_quote_locked.
  ///
  /// In ko, this message translates to:
  /// **'확정된 견적이라 수정할 수 없어요.'**
  String get err_quote_locked;

  /// No description provided for @err_request_closed.
  ///
  /// In ko, this message translates to:
  /// **'이미 마감된 요청이에요.'**
  String get err_request_closed;

  /// No description provided for @err_team_full.
  ///
  /// In ko, this message translates to:
  /// **'팀 인원이 가득 찼어요.'**
  String get err_team_full;

  /// No description provided for @err_invalid_webhook_secret.
  ///
  /// In ko, this message translates to:
  /// **'웹훅 시크릿은 whsec_로 시작해야 해요.'**
  String get err_invalid_webhook_secret;

  /// No description provided for @err_invalid_endpoint.
  ///
  /// In ko, this message translates to:
  /// **'엔드포인트는 https://로 시작해야 해요.'**
  String get err_invalid_endpoint;

  /// No description provided for @err_invalid_bucket.
  ///
  /// In ko, this message translates to:
  /// **'버킷 이름이 올바르지 않아요.'**
  String get err_invalid_bucket;

  /// No description provided for @err_invalid_region.
  ///
  /// In ko, this message translates to:
  /// **'리전 값이 올바르지 않아요.'**
  String get err_invalid_region;

  /// No description provided for @err_invalid_retention.
  ///
  /// In ko, this message translates to:
  /// **'보관 기간 값이 범위를 벗어났어요.'**
  String get err_invalid_retention;

  /// No description provided for @err_invalid_service_account.
  ///
  /// In ko, this message translates to:
  /// **'서비스 계정 파일이 올바르지 않아요.'**
  String get err_invalid_service_account;

  /// No description provided for @err_invalid_mode.
  ///
  /// In ko, this message translates to:
  /// **'AI 응답 모드를 다시 골라 주세요.'**
  String get err_invalid_mode;

  /// No description provided for @err_invalid_model.
  ///
  /// In ko, this message translates to:
  /// **'AI 모델 이름이 올바르지 않아요.'**
  String get err_invalid_model;

  /// No description provided for @err_missing_field.
  ///
  /// In ko, this message translates to:
  /// **'필수 항목을 모두 입력해 주세요.'**
  String get err_missing_field;

  /// No description provided for @err_invalid_amount.
  ///
  /// In ko, this message translates to:
  /// **'금액을 올바르게 입력해 주세요.'**
  String get err_invalid_amount;

  /// No description provided for @err_cannot_deactivate_self.
  ///
  /// In ko, this message translates to:
  /// **'본인 계정은 비활성화할 수 없어요.'**
  String get err_cannot_deactivate_self;

  /// No description provided for @err_invalid_coupon.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰 정보가 올바르지 않아요.'**
  String get err_invalid_coupon;

  /// No description provided for @err_settlement_state.
  ///
  /// In ko, this message translates to:
  /// **'지금은 정산 상태를 바꿀 수 없어요.'**
  String get err_settlement_state;

  /// No description provided for @err_deposit_required.
  ///
  /// In ko, this message translates to:
  /// **'예약금을 먼저 받아야 해요.'**
  String get err_deposit_required;

  /// No description provided for @err_payout_state.
  ///
  /// In ko, this message translates to:
  /// **'정산 상태가 바뀌었어요. 새로고침 후 다시 확인해 주세요.'**
  String get err_payout_state;

  /// No description provided for @err_payout_provider.
  ///
  /// In ko, this message translates to:
  /// **'이 지급 방식은 지금 쓸 수 없어요.'**
  String get err_payout_provider;

  /// No description provided for @err_unsupported_bank.
  ///
  /// In ko, this message translates to:
  /// **'이 은행은 지급을 지원하지 않아요.'**
  String get err_unsupported_bank;

  /// No description provided for @err_toss_unverified.
  ///
  /// In ko, this message translates to:
  /// **'토스 지급대행은 아직 연결할 수 없어요. 직접 이체를 써 주세요.'**
  String get err_toss_unverified;

  /// No description provided for @err_invalid_cap.
  ///
  /// In ko, this message translates to:
  /// **'한도는 정해진 범위 안의 숫자로 입력해 주세요.'**
  String get err_invalid_cap;

  /// No description provided for @err_invalid_capacity.
  ///
  /// In ko, this message translates to:
  /// **'정원은 숫자로 입력해 주세요.'**
  String get err_invalid_capacity;

  /// No description provided for @err_seller_declined.
  ///
  /// In ko, this message translates to:
  /// **'토스가 판매자 등록을 승인하지 않았어요. 사업자 정보를 확인해 주세요.'**
  String get err_seller_declined;

  /// No description provided for @err_payout_account_unverified.
  ///
  /// In ko, this message translates to:
  /// **'확인된 정산 계좌가 없어요. 먼저 계좌를 확인해 주세요.'**
  String get err_payout_account_unverified;

  /// No description provided for @guestSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'계속하려면 전화번호로 로그인하세요'**
  String get guestSheetTitle;

  /// No description provided for @guestSheetBody.
  ///
  /// In ko, this message translates to:
  /// **'입력하신 내용은 그대로 남아 있어요. 인증 후 바로 이어서 진행됩니다.'**
  String get guestSheetBody;

  /// No description provided for @greetMorning.
  ///
  /// In ko, this message translates to:
  /// **'좋은 아침이에요'**
  String get greetMorning;

  /// No description provided for @greetAfternoon.
  ///
  /// In ko, this message translates to:
  /// **'좋은 오후예요'**
  String get greetAfternoon;

  /// No description provided for @greetEvening.
  ///
  /// In ko, this message translates to:
  /// **'좋은 저녁이에요'**
  String get greetEvening;

  /// No description provided for @feedHeading.
  ///
  /// In ko, this message translates to:
  /// **'회원님을 위한 추천'**
  String get feedHeading;

  /// No description provided for @feedTitleDue.
  ///
  /// In ko, this message translates to:
  /// **'다음 청소 시기가 됐어요'**
  String get feedTitleDue;

  /// No description provided for @feedTitleRebook.
  ///
  /// In ko, this message translates to:
  /// **'지난번 파트너를 다시 예약하세요'**
  String get feedTitleRebook;

  /// No description provided for @feedTitleDraft.
  ///
  /// In ko, this message translates to:
  /// **'작성 중이던 견적을 이어서 보세요'**
  String get feedTitleDraft;

  /// No description provided for @feedTitleSeasonal.
  ///
  /// In ko, this message translates to:
  /// **'지금 계절에 꼭 필요한 청소예요'**
  String get feedTitleSeasonal;

  /// No description provided for @feedTitleSize.
  ///
  /// In ko, this message translates to:
  /// **'저장된 집 크기로 바로 견적 보기'**
  String get feedTitleSize;

  /// No description provided for @feedTitleSubscription.
  ///
  /// In ko, this message translates to:
  /// **'정기 구독으로 더 저렴하게'**
  String get feedTitleSubscription;

  /// No description provided for @feedTitleDistrict.
  ///
  /// In ko, this message translates to:
  /// **'우리 동네에서도 예약이 이어지고 있어요'**
  String get feedTitleDistrict;

  /// No description provided for @feedWhyCadence.
  ///
  /// In ko, this message translates to:
  /// **'마지막 청소 후 {days}일이 지났어요'**
  String feedWhyCadence(String days);

  /// No description provided for @feedWhyRated.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전 5점을 드린 파트너예요'**
  String feedWhyRated(String days);

  /// No description provided for @feedWhyDraft.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 견적을 끝내지 않았어요'**
  String get feedWhyDraft;

  /// No description provided for @feedWhySummer.
  ///
  /// In ko, this message translates to:
  /// **'여름 전에 에어컨을 청소하기 좋은 때예요'**
  String get feedWhySummer;

  /// No description provided for @feedWhyMoving.
  ///
  /// In ko, this message translates to:
  /// **'입주·이사가 몰리는 시기예요'**
  String get feedWhyMoving;

  /// No description provided for @feedWhyHoliday.
  ///
  /// In ko, this message translates to:
  /// **'명절 대청소까지 {days}일 남았어요'**
  String feedWhyHoliday(String days);

  /// No description provided for @feedWhySize.
  ///
  /// In ko, this message translates to:
  /// **'저장된 {pyeong}평 기준으로 바로 견적을 볼 수 있어요'**
  String feedWhySize(String pyeong);

  /// No description provided for @feedWhyRepeat.
  ///
  /// In ko, this message translates to:
  /// **'자주 예약하신다면 구독이 더 저렴해요'**
  String get feedWhyRepeat;

  /// No description provided for @feedWhyDistrict.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 {district}에서 {count}집이 예약했어요'**
  String feedWhyDistrict(String district, String count);

  /// No description provided for @fFinance.
  ///
  /// In ko, this message translates to:
  /// **'재무'**
  String get fFinance;

  /// No description provided for @fPeriodDay.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get fPeriodDay;

  /// No description provided for @fPeriodWeek.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get fPeriodWeek;

  /// No description provided for @fPeriodMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get fPeriodMonth;

  /// No description provided for @fPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get fPeriodCustom;

  /// No description provided for @fFrom.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get fFrom;

  /// No description provided for @fTo.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get fTo;

  /// No description provided for @fGross.
  ///
  /// In ko, this message translates to:
  /// **'총결제액'**
  String get fGross;

  /// No description provided for @fRefunds.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get fRefunds;

  /// No description provided for @fNetRevenue.
  ///
  /// In ko, this message translates to:
  /// **'순매출'**
  String get fNetRevenue;

  /// No description provided for @fPlatformFee.
  ///
  /// In ko, this message translates to:
  /// **'플랫폼 수수료'**
  String get fPlatformFee;

  /// No description provided for @fPaidOut.
  ///
  /// In ko, this message translates to:
  /// **'파트너 지급 완료'**
  String get fPaidOut;

  /// No description provided for @fPendingOut.
  ///
  /// In ko, this message translates to:
  /// **'지급 예정'**
  String get fPendingOut;

  /// No description provided for @fHeldOut.
  ///
  /// In ko, this message translates to:
  /// **'보류'**
  String get fHeldOut;

  /// No description provided for @fVatEstimate.
  ///
  /// In ko, this message translates to:
  /// **'부가세 추정'**
  String get fVatEstimate;

  /// No description provided for @fVatNote.
  ///
  /// In ko, this message translates to:
  /// **'플랫폼 수수료의 10%로 계산한 추정치예요. 세무사와 확인하세요.'**
  String get fVatNote;

  /// No description provided for @fAov.
  ///
  /// In ko, this message translates to:
  /// **'평균 주문액'**
  String get fAov;

  /// No description provided for @fBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get fBookings;

  /// No description provided for @fCancelRate.
  ///
  /// In ko, this message translates to:
  /// **'취소율'**
  String get fCancelRate;

  /// No description provided for @fDiscounts.
  ///
  /// In ko, this message translates to:
  /// **'할인·쿠폰'**
  String get fDiscounts;

  /// No description provided for @fMethods.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get fMethods;

  /// No description provided for @fTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get fTrend;

  /// No description provided for @fRangeDays.
  ///
  /// In ko, this message translates to:
  /// **'최근 {n}일'**
  String fRangeDays(String n);

  /// No description provided for @fRangeWeeks.
  ///
  /// In ko, this message translates to:
  /// **'최근 12주'**
  String get fRangeWeeks;

  /// No description provided for @fRangeMonths.
  ///
  /// In ko, this message translates to:
  /// **'최근 12개월'**
  String get fRangeMonths;

  /// No description provided for @fByPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너별 정산'**
  String get fByPartner;

  /// No description provided for @fByService.
  ///
  /// In ko, this message translates to:
  /// **'서비스별 매출'**
  String get fByService;

  /// No description provided for @fExportTitle.
  ///
  /// In ko, this message translates to:
  /// **'회계 자료 내려받기'**
  String get fExportTitle;

  /// No description provided for @fExportLedger.
  ///
  /// In ko, this message translates to:
  /// **'결제 원장 CSV'**
  String get fExportLedger;

  /// No description provided for @fExportSettlements.
  ///
  /// In ko, this message translates to:
  /// **'정산 내역 CSV'**
  String get fExportSettlements;

  /// No description provided for @fExportMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월별 요약 CSV (세무사용)'**
  String get fExportMonthly;

  /// No description provided for @fDownload.
  ///
  /// In ko, this message translates to:
  /// **'CSV 내려받기'**
  String get fDownload;

  /// No description provided for @fDownloadWebOnly.
  ///
  /// In ko, this message translates to:
  /// **'CSV 내려받기는 웹 콘솔에서 할 수 있어요'**
  String get fDownloadWebOnly;

  /// No description provided for @fDownloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'내려받지 못했어요'**
  String get fDownloadFailed;

  /// No description provided for @fNoRecords.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 기록이 없어요'**
  String get fNoRecords;

  /// No description provided for @fLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'재무 자료를 불러오지 못했어요'**
  String get fLoadFailed;

  /// No description provided for @fRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get fRetry;

  /// No description provided for @fColPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get fColPartner;

  /// No description provided for @fColJobs.
  ///
  /// In ko, this message translates to:
  /// **'건수'**
  String get fColJobs;

  /// No description provided for @fColSettled.
  ///
  /// In ko, this message translates to:
  /// **'정산 총액'**
  String get fColSettled;

  /// No description provided for @fColFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get fColFee;

  /// No description provided for @fColNet.
  ///
  /// In ko, this message translates to:
  /// **'지급액'**
  String get fColNet;

  /// No description provided for @pEarnings.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get pEarnings;

  /// No description provided for @pNextPayout.
  ///
  /// In ko, this message translates to:
  /// **'다음 지급'**
  String get pNextPayout;

  /// No description provided for @pNextPayoutOn.
  ///
  /// In ko, this message translates to:
  /// **'{date} 지급 예정'**
  String pNextPayoutOn(String date);

  /// No description provided for @pNoPayout.
  ///
  /// In ko, this message translates to:
  /// **'예정된 지급이 없어요'**
  String get pNoPayout;

  /// No description provided for @pPendingTotal.
  ///
  /// In ko, this message translates to:
  /// **'지급 대기'**
  String get pPendingTotal;

  /// No description provided for @pPaidTotal.
  ///
  /// In ko, this message translates to:
  /// **'지급 완료'**
  String get pPaidTotal;

  /// No description provided for @pWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get pWeekly;

  /// No description provided for @pMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get pMonthly;

  /// No description provided for @proofHomes.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {count}집을 청소했어요'**
  String proofHomes(String count);

  /// No description provided for @proofRating.
  ///
  /// In ko, this message translates to:
  /// **'평균 평점 {rating}점 · 후기 {count}개'**
  String proofRating(String rating, String count);

  /// No description provided for @proofReviewsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 후기'**
  String get proofReviewsTitle;

  /// No description provided for @rebookTitle.
  ///
  /// In ko, this message translates to:
  /// **'지난번 서비스를 다시 예약할까요?'**
  String get rebookTitle;

  /// No description provided for @rebookBody.
  ///
  /// In ko, this message translates to:
  /// **'{service} · 지난 방문 {date}'**
  String rebookBody(String service, String date);

  /// No description provided for @rebookButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 예약하기'**
  String get rebookButton;

  /// No description provided for @seatsLeft.
  ///
  /// In ko, this message translates to:
  /// **'{count}자리 남음'**
  String seatsLeft(String count);

  /// No description provided for @reviewSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 청소는 어떠셨나요?'**
  String get reviewSheetTitle;

  /// No description provided for @reviewPhotosAdd.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get reviewPhotosAdd;

  /// No description provided for @reviewPhotosHint.
  ///
  /// In ko, this message translates to:
  /// **'사진은 최대 5장까지 올릴 수 있어요'**
  String get reviewPhotosHint;

  /// No description provided for @reviewSaved.
  ///
  /// In ko, this message translates to:
  /// **'후기를 남겨 주셔서 고마워요'**
  String get reviewSaved;

  /// No description provided for @reviewPhotoFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진을 올리지 못했어요. 다시 시도해 주세요.'**
  String get reviewPhotoFailed;

  /// No description provided for @referralTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구를 초대하면 쿠폰을 드려요'**
  String get referralTitle;

  /// No description provided for @referralBody.
  ///
  /// In ko, this message translates to:
  /// **'친구가 첫 예약을 마치면 두 분 모두 {amount} 쿠폰을 받아요'**
  String referralBody(String amount);

  /// No description provided for @referralCopy.
  ///
  /// In ko, this message translates to:
  /// **'코드 복사'**
  String get referralCopy;

  /// No description provided for @referralCopied.
  ///
  /// In ko, this message translates to:
  /// **'추천 코드를 복사했어요'**
  String get referralCopied;

  /// No description provided for @referralClaimTitle.
  ///
  /// In ko, this message translates to:
  /// **'추천 코드가 있나요?'**
  String get referralClaimTitle;

  /// No description provided for @referralClaimField.
  ///
  /// In ko, this message translates to:
  /// **'추천 코드 입력'**
  String get referralClaimField;

  /// No description provided for @referralClaimButton.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get referralClaimButton;

  /// No description provided for @referralClaimed.
  ///
  /// In ko, this message translates to:
  /// **'추천 코드가 등록됐어요'**
  String get referralClaimed;

  /// No description provided for @referralStats.
  ///
  /// In ko, this message translates to:
  /// **'초대 {invited}명 · 보상 {rewarded}건'**
  String referralStats(String invited, String rewarded);

  /// No description provided for @err_self_referral.
  ///
  /// In ko, this message translates to:
  /// **'내 추천 코드는 쓸 수 없어요'**
  String get err_self_referral;

  /// No description provided for @err_referee_already_booked.
  ///
  /// In ko, this message translates to:
  /// **'예약 이후에는 추천 코드를 등록할 수 없어요'**
  String get err_referee_already_booked;

  /// No description provided for @err_already_referred.
  ///
  /// In ko, this message translates to:
  /// **'이미 추천 코드를 등록했어요'**
  String get err_already_referred;

  /// No description provided for @err_invalid_referral_code.
  ///
  /// In ko, this message translates to:
  /// **'추천 코드를 확인해 주세요'**
  String get err_invalid_referral_code;

  /// No description provided for @err_referral_disabled.
  ///
  /// In ko, this message translates to:
  /// **'지금은 친구 추천을 받지 않아요'**
  String get err_referral_disabled;

  /// No description provided for @err_invalid_photos.
  ///
  /// In ko, this message translates to:
  /// **'사진은 말끔이 올린 파일만 첨부할 수 있어요'**
  String get err_invalid_photos;

  /// No description provided for @welcomeOfferTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 예약 할인'**
  String get welcomeOfferTitle;

  /// No description provided for @welcomeOfferBody.
  ///
  /// In ko, this message translates to:
  /// **'신규 고객의 첫 예약에 자동으로 적용돼요. 쿠폰과는 중복되지 않아요.'**
  String get welcomeOfferBody;

  /// No description provided for @offerKindAmount.
  ///
  /// In ko, this message translates to:
  /// **'정액(원)'**
  String get offerKindAmount;

  /// No description provided for @offerKindPercent.
  ///
  /// In ko, this message translates to:
  /// **'정률(%)'**
  String get offerKindPercent;

  /// No description provided for @offerValue.
  ///
  /// In ko, this message translates to:
  /// **'할인 값'**
  String get offerValue;

  /// No description provided for @offerEnabled.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get offerEnabled;

  /// No description provided for @offerSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get offerSaved;

  /// No description provided for @referralSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 추천 보상'**
  String get referralSettingsTitle;

  /// No description provided for @referralSettingsBody.
  ///
  /// In ko, this message translates to:
  /// **'친구가 첫 예약을 완료하고 결제까지 끝나면 지급돼요. 본인 추천, 같은 번호 중복은 막아요.'**
  String get referralSettingsBody;

  /// No description provided for @referralRewardAmount.
  ///
  /// In ko, this message translates to:
  /// **'보상 금액(원)'**
  String get referralRewardAmount;

  /// No description provided for @reviewsModerationTitle.
  ///
  /// In ko, this message translates to:
  /// **'후기 관리'**
  String get reviewsModerationTitle;

  /// No description provided for @reviewHide.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get reviewHide;

  /// No description provided for @reviewShow.
  ///
  /// In ko, this message translates to:
  /// **'다시 보이기'**
  String get reviewShow;

  /// No description provided for @reviewHiddenTag.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get reviewHiddenTag;

  /// No description provided for @growthAverageRating.
  ///
  /// In ko, this message translates to:
  /// **'평균 평점'**
  String get growthAverageRating;

  /// No description provided for @growthReviewCount.
  ///
  /// In ko, this message translates to:
  /// **'후기 {count}개'**
  String growthReviewCount(String count);

  /// No description provided for @growthReferralConversion.
  ///
  /// In ko, this message translates to:
  /// **'친구 추천 전환'**
  String get growthReferralConversion;

  /// No description provided for @growthTab.
  ///
  /// In ko, this message translates to:
  /// **'성장'**
  String get growthTab;

  /// No description provided for @growthReferralValue.
  ///
  /// In ko, this message translates to:
  /// **'{rewarded}/{invited}명'**
  String growthReferralValue(String rewarded, String invited);

  /// No description provided for @uMaintenanceTitle.
  ///
  /// In ko, this message translates to:
  /// **'점검 중이에요'**
  String get uMaintenanceTitle;

  /// No description provided for @uMaintenanceBody.
  ///
  /// In ko, this message translates to:
  /// **'더 나은 서비스를 위해 점검하고 있어요. 잠시 후 다시 열어 주세요.'**
  String get uMaintenanceBody;

  /// No description provided for @cmTab.
  ///
  /// In ko, this message translates to:
  /// **'캠페인'**
  String get cmTab;

  /// No description provided for @cmNew.
  ///
  /// In ko, this message translates to:
  /// **'새 캠페인'**
  String get cmNew;

  /// No description provided for @cmAudience.
  ///
  /// In ko, this message translates to:
  /// **'대상 고객'**
  String get cmAudience;

  /// No description provided for @cmSegAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 고객'**
  String get cmSegAll;

  /// No description provided for @cmSegNever.
  ///
  /// In ko, this message translates to:
  /// **'예약 이력 없음'**
  String get cmSegNever;

  /// No description provided for @cmSegLapsed.
  ///
  /// In ko, this message translates to:
  /// **'마지막 예약 {days}일 이상 전'**
  String cmSegLapsed(String days);

  /// No description provided for @cmDays.
  ///
  /// In ko, this message translates to:
  /// **'일 수'**
  String get cmDays;

  /// No description provided for @cmConsentCount.
  ///
  /// In ko, this message translates to:
  /// **'전체 {total}명 중 마케팅 동의 {consented}명'**
  String cmConsentCount(String total, String consented);

  /// No description provided for @cmChannel.
  ///
  /// In ko, this message translates to:
  /// **'발송 채널'**
  String get cmChannel;

  /// No description provided for @cmPush.
  ///
  /// In ko, this message translates to:
  /// **'앱 푸시'**
  String get cmPush;

  /// No description provided for @cmSms.
  ///
  /// In ko, this message translates to:
  /// **'문자(SMS)'**
  String get cmSms;

  /// No description provided for @cmTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get cmTitle;

  /// No description provided for @cmBody.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get cmBody;

  /// No description provided for @cmOptout.
  ///
  /// In ko, this message translates to:
  /// **'수신거부 번호 (080)'**
  String get cmOptout;

  /// No description provided for @cmPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get cmPreview;

  /// No description provided for @cmSchedule.
  ///
  /// In ko, this message translates to:
  /// **'발송 시각'**
  String get cmSchedule;

  /// No description provided for @cmSendNow.
  ///
  /// In ko, this message translates to:
  /// **'바로 발송'**
  String get cmSendNow;

  /// No description provided for @cmTestSend.
  ///
  /// In ko, this message translates to:
  /// **'내 번호로 테스트 발송'**
  String get cmTestSend;

  /// No description provided for @cmCreate.
  ///
  /// In ko, this message translates to:
  /// **'캠페인 저장'**
  String get cmCreate;

  /// No description provided for @cmNeedOptout.
  ///
  /// In ko, this message translates to:
  /// **'문자 발송에는 080 수신거부 번호가 필요해요'**
  String get cmNeedOptout;

  /// No description provided for @cmLog.
  ///
  /// In ko, this message translates to:
  /// **'발송 기록'**
  String get cmLog;

  /// No description provided for @cmStatSent.
  ///
  /// In ko, this message translates to:
  /// **'발송 {count}'**
  String cmStatSent(String count);

  /// No description provided for @cmStatSkipped.
  ///
  /// In ko, this message translates to:
  /// **'동의 없음 {count}'**
  String cmStatSkipped(String count);

  /// No description provided for @cmStatFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패 {count}'**
  String cmStatFailed(String count);

  /// No description provided for @cmSaved.
  ///
  /// In ko, this message translates to:
  /// **'캠페인을 만들었어요'**
  String get cmSaved;

  /// No description provided for @anFunnel.
  ///
  /// In ko, this message translates to:
  /// **'가입 후 퍼널 (최근 {days}일)'**
  String anFunnel(String days);

  /// No description provided for @anInstalls.
  ///
  /// In ko, this message translates to:
  /// **'앱 실행 (동의)'**
  String get anInstalls;

  /// No description provided for @anSignedUp.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get anSignedUp;

  /// No description provided for @anQuoted.
  ///
  /// In ko, this message translates to:
  /// **'견적 요청'**
  String get anQuoted;

  /// No description provided for @anBooked.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get anBooked;

  /// No description provided for @anPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get anPaid;

  /// No description provided for @anRepeat.
  ///
  /// In ko, this message translates to:
  /// **'재구매 (2회 이상)'**
  String get anRepeat;

  /// No description provided for @anCohorts.
  ///
  /// In ko, this message translates to:
  /// **'주간 코호트 (가입 주 기준 예약률)'**
  String get anCohorts;

  /// No description provided for @anCohortSize.
  ///
  /// In ko, this message translates to:
  /// **'가입 {count}'**
  String anCohortSize(String count);

  /// No description provided for @anWeekAfter.
  ///
  /// In ko, this message translates to:
  /// **'{n}주 후 예약'**
  String anWeekAfter(String n);

  /// No description provided for @cOps.
  ///
  /// In ko, this message translates to:
  /// **'시스템 상태'**
  String get cOps;

  /// No description provided for @oLevelGreen.
  ///
  /// In ko, this message translates to:
  /// **'정상'**
  String get oLevelGreen;

  /// No description provided for @oLevelYellow.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get oLevelYellow;

  /// No description provided for @oLevelRed.
  ///
  /// In ko, this message translates to:
  /// **'조치 필요'**
  String get oLevelRed;

  /// No description provided for @oOverall.
  ///
  /// In ko, this message translates to:
  /// **'서버 상태'**
  String get oOverall;

  /// No description provided for @oRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get oRefresh;

  /// No description provided for @oVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get oVersion;

  /// No description provided for @oUptime.
  ///
  /// In ko, this message translates to:
  /// **'가동 시간'**
  String get oUptime;

  /// No description provided for @oUptimeValue.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String oUptimeValue(String hours, String minutes);

  /// No description provided for @oChecks.
  ///
  /// In ko, this message translates to:
  /// **'점검 항목'**
  String get oChecks;

  /// No description provided for @oCheckDb.
  ///
  /// In ko, this message translates to:
  /// **'데이터베이스'**
  String get oCheckDb;

  /// No description provided for @oCheckDbValue.
  ///
  /// In ko, this message translates to:
  /// **'응답 {ms}ms · 용량 {mb}MB'**
  String oCheckDbValue(String ms, String mb);

  /// No description provided for @oCheckDisk.
  ///
  /// In ko, this message translates to:
  /// **'서버 디스크'**
  String get oCheckDisk;

  /// No description provided for @oCheckDiskValue.
  ///
  /// In ko, this message translates to:
  /// **'여유 {pct}%'**
  String oCheckDiskValue(String pct);

  /// No description provided for @oCheckBackup.
  ///
  /// In ko, this message translates to:
  /// **'자동 백업'**
  String get oCheckBackup;

  /// No description provided for @oCheckBackupValue.
  ///
  /// In ko, this message translates to:
  /// **'마지막 백업 {hours}시간 전'**
  String oCheckBackupValue(String hours);

  /// No description provided for @oCheckBackupNone.
  ///
  /// In ko, this message translates to:
  /// **'백업 기록이 없어요'**
  String get oCheckBackupNone;

  /// No description provided for @oCheckErrors.
  ///
  /// In ko, this message translates to:
  /// **'서버 오류 (24시간)'**
  String get oCheckErrors;

  /// No description provided for @oCheckErrorsValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String oCheckErrorsValue(String count);

  /// No description provided for @oCheckPayments.
  ///
  /// In ko, this message translates to:
  /// **'결제 확인 필요'**
  String get oCheckPayments;

  /// No description provided for @oCheckPaymentsValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 (24시간)'**
  String oCheckPaymentsValue(String count);

  /// No description provided for @oCheckWebhook.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림 (웹훅)'**
  String get oCheckWebhook;

  /// No description provided for @oCheckWebhookValue.
  ///
  /// In ko, this message translates to:
  /// **'서명 실패 {count}건 (24시간)'**
  String oCheckWebhookValue(String count);

  /// No description provided for @oIntegrations.
  ///
  /// In ko, this message translates to:
  /// **'외부 서비스'**
  String get oIntegrations;

  /// No description provided for @oIntNotSet.
  ///
  /// In ko, this message translates to:
  /// **'설정 안 됨'**
  String get oIntNotSet;

  /// No description provided for @oIntLastOk.
  ///
  /// In ko, this message translates to:
  /// **'마지막 성공 {at}'**
  String oIntLastOk(String at);

  /// No description provided for @oIntLastFail.
  ///
  /// In ko, this message translates to:
  /// **'마지막 실패 {at} ({code})'**
  String oIntLastFail(String at, String code);

  /// No description provided for @oIntNever.
  ///
  /// In ko, this message translates to:
  /// **'아직 사용 기록이 없어요'**
  String get oIntNever;

  /// No description provided for @oActDb.
  ///
  /// In ko, this message translates to:
  /// **'데이터베이스에 연결하지 못했어요. 서버에서 malkkeum logs 로 원인을 보고, 계속되면 서버를 재시작하세요.'**
  String get oActDb;

  /// No description provided for @oActDisk.
  ///
  /// In ko, this message translates to:
  /// **'디스크 여유 공간이 10% 아래예요. 오래된 백업 파일을 지우거나 서버 디스크를 늘려 주세요.'**
  String get oActDisk;

  /// No description provided for @oActBackup.
  ///
  /// In ko, this message translates to:
  /// **'자동 백업이 오래됐어요. 서버에서 malkkeum backup 을 실행하고 backups/backup.log 를 확인하세요.'**
  String get oActBackup;

  /// No description provided for @oActErrors.
  ///
  /// In ko, this message translates to:
  /// **'서버 오류가 많아요. malkkeum logs 에서 error 줄을 확인하고, 반복되면 개발사에 전달하세요.'**
  String get oActErrors;

  /// No description provided for @oActPayments.
  ///
  /// In ko, this message translates to:
  /// **'결제는 됐지만 자동 처리가 안 됐을 수 있어요. PortOne 관리자 화면에서 해당 결제를 확인하고 필요하면 직접 환불하세요.'**
  String get oActPayments;

  /// No description provided for @oActWebhook.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림의 서명 검사가 실패했어요. 설정 > 결제(PortOne)에서 웹훅 시크릿을 다시 입력하세요.'**
  String get oActWebhook;

  /// No description provided for @oActIntegration.
  ///
  /// In ko, this message translates to:
  /// **'연동이 실패하고 있어요. 설정 화면에서 키를 다시 확인하고 [연결 테스트] 를 누르세요.'**
  String get oActIntegration;

  /// No description provided for @oActNotSet.
  ///
  /// In ko, this message translates to:
  /// **'아직 설정되지 않았어요. 설정 화면에서 키를 입력하세요.'**
  String get oActNotSet;

  /// No description provided for @oAlerts.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get oAlerts;

  /// No description provided for @oAlertsHint.
  ///
  /// In ko, this message translates to:
  /// **'문제가 생기면 상담함과 사장님 휴대폰(문자)으로 알려 드려요. 같은 문제는 6시간에 한 번만 보내요.'**
  String get oAlertsHint;

  /// No description provided for @oRuleSms.
  ///
  /// In ko, this message translates to:
  /// **'문자(SMS) 발송 실패'**
  String get oRuleSms;

  /// No description provided for @oRulePush.
  ///
  /// In ko, this message translates to:
  /// **'앱 알림(푸시) 실패'**
  String get oRulePush;

  /// No description provided for @oRulePayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 연동 실패'**
  String get oRulePayment;

  /// No description provided for @oRuleStuck.
  ///
  /// In ko, this message translates to:
  /// **'결제 자동 처리 실패'**
  String get oRuleStuck;

  /// No description provided for @oRuleSocial.
  ///
  /// In ko, this message translates to:
  /// **'소셜 로그인 실패'**
  String get oRuleSocial;

  /// No description provided for @oRuleBackup.
  ///
  /// In ko, this message translates to:
  /// **'자동 백업 누락'**
  String get oRuleBackup;

  /// No description provided for @oRuleDisk.
  ///
  /// In ko, this message translates to:
  /// **'디스크 부족'**
  String get oRuleDisk;

  /// No description provided for @oRuleAuth.
  ///
  /// In ko, this message translates to:
  /// **'계정 보안 이상(로그인 잠금 등)'**
  String get oRuleAuth;

  /// No description provided for @oQuietHours.
  ///
  /// In ko, this message translates to:
  /// **'조용한 시간'**
  String get oQuietHours;

  /// No description provided for @oQuietFrom.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get oQuietFrom;

  /// No description provided for @oQuietTo.
  ///
  /// In ko, this message translates to:
  /// **'끝'**
  String get oQuietTo;

  /// No description provided for @oHour.
  ///
  /// In ko, this message translates to:
  /// **'{hour}시'**
  String oHour(String hour);

  /// No description provided for @oQuietHint.
  ///
  /// In ko, this message translates to:
  /// **'이 시간에는 알림을 보내지 않고, 끝난 뒤에 한 번 알려 드려요.'**
  String get oQuietHint;

  /// No description provided for @oAlertPhone.
  ///
  /// In ko, this message translates to:
  /// **'알림 받을 휴대폰'**
  String get oAlertPhone;

  /// No description provided for @oAlertPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'비워 두면 사업자 정보의 고객센터 번호로 보내요.'**
  String get oAlertPhoneHint;

  /// No description provided for @oSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get oSave;

  /// No description provided for @oSaved.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정을 저장했어요'**
  String get oSaved;

  /// No description provided for @oSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 입력값을 확인해 주세요.'**
  String get oSaveFailed;

  /// No description provided for @oLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'상태를 불러오지 못했어요'**
  String get oLoadFailed;

  /// No description provided for @oBackupOffsite.
  ///
  /// In ko, this message translates to:
  /// **'외부 백업 (S3)'**
  String get oBackupOffsite;

  /// No description provided for @oBackupOffsiteOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼져 있어요. 설정 > 외부 백업 에서 켤 수 있어요.'**
  String get oBackupOffsiteOff;

  /// No description provided for @oLastBackup.
  ///
  /// In ko, this message translates to:
  /// **'마지막 백업'**
  String get oLastBackup;

  /// No description provided for @oDiskFree.
  ///
  /// In ko, this message translates to:
  /// **'여유 공간'**
  String get oDiskFree;

  /// No description provided for @oNoData.
  ///
  /// In ko, this message translates to:
  /// **'아직 데이터가 없어요'**
  String get oNoData;

  /// No description provided for @cIntBackup.
  ///
  /// In ko, this message translates to:
  /// **'외부 백업 (S3 호환)'**
  String get cIntBackup;

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

  /// No description provided for @pHousehold.
  ///
  /// In ko, this message translates to:
  /// **'가구 정보'**
  String get pHousehold;

  /// No description provided for @pPets.
  ///
  /// In ko, this message translates to:
  /// **'반려동물'**
  String get pPets;

  /// No description provided for @pPetDog.
  ///
  /// In ko, this message translates to:
  /// **'강아지'**
  String get pPetDog;

  /// No description provided for @pPetCat.
  ///
  /// In ko, this message translates to:
  /// **'고양이'**
  String get pPetCat;

  /// No description provided for @pPetBird.
  ///
  /// In ko, this message translates to:
  /// **'새'**
  String get pPetBird;

  /// No description provided for @pPetFish.
  ///
  /// In ko, this message translates to:
  /// **'물고기'**
  String get pPetFish;

  /// No description provided for @pPetOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 동물'**
  String get pPetOther;

  /// No description provided for @pAllergies.
  ///
  /// In ko, this message translates to:
  /// **'알레르기·민감 사항'**
  String get pAllergies;

  /// No description provided for @pPreferredProducts.
  ///
  /// In ko, this message translates to:
  /// **'선호 제품'**
  String get pPreferredProducts;

  /// No description provided for @pParking.
  ///
  /// In ko, this message translates to:
  /// **'주차'**
  String get pParking;

  /// No description provided for @pFloor.
  ///
  /// In ko, this message translates to:
  /// **'{floor}층'**
  String pFloor(String floor);

  /// No description provided for @pElevatorYes.
  ///
  /// In ko, this message translates to:
  /// **'엘리베이터 있음'**
  String get pElevatorYes;

  /// No description provided for @pElevatorNo.
  ///
  /// In ko, this message translates to:
  /// **'엘리베이터 없음'**
  String get pElevatorNo;

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

  /// No description provided for @pNavigate.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get pNavigate;

  /// No description provided for @pNavHint.
  ///
  /// In ko, this message translates to:
  /// **'방문 주소를 지도 앱에서 열어요. 앱이 없으면 웹 지도가 열려요.'**
  String get pNavHint;

  /// No description provided for @pOfflineSaved.
  ///
  /// In ko, this message translates to:
  /// **'신호가 없어요. 저장해 두고 연결되면 자동으로 보낼게요.'**
  String get pOfflineSaved;

  /// No description provided for @pPhotoRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 올리기'**
  String get pPhotoRetry;

  /// No description provided for @pPhotoWaiting.
  ///
  /// In ko, this message translates to:
  /// **'올리지 못한 사진은 신호가 돌아오면 자동으로 올라가요.'**
  String get pPhotoWaiting;

  /// No description provided for @pUploadedCount.
  ///
  /// In ko, this message translates to:
  /// **'{total}장 중 {done}장 업로드됨'**
  String pUploadedCount(String total, String done);

  /// No description provided for @cIntPayout.
  ///
  /// In ko, this message translates to:
  /// **'파트너 지급'**
  String get cIntPayout;

  /// No description provided for @poTabSettlements.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get poTabSettlements;

  /// No description provided for @poTabPayouts.
  ///
  /// In ko, this message translates to:
  /// **'지급 내역'**
  String get poTabPayouts;

  /// No description provided for @poState_requested.
  ///
  /// In ko, this message translates to:
  /// **'요청됨'**
  String get poState_requested;

  /// No description provided for @poState_sent.
  ///
  /// In ko, this message translates to:
  /// **'전송됨'**
  String get poState_sent;

  /// No description provided for @poState_paid.
  ///
  /// In ko, this message translates to:
  /// **'지급 완료'**
  String get poState_paid;

  /// No description provided for @poState_failed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get poState_failed;

  /// No description provided for @poProviderManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 이체'**
  String get poProviderManual;

  /// No description provided for @poProviderToss.
  ///
  /// In ko, this message translates to:
  /// **'토스 지급대행'**
  String get poProviderToss;

  /// No description provided for @poShowAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌 보기'**
  String get poShowAccount;

  /// No description provided for @poAccountTitle.
  ///
  /// In ko, this message translates to:
  /// **'이체 정보'**
  String get poAccountTitle;

  /// No description provided for @poAccountBody.
  ///
  /// In ko, this message translates to:
  /// **'{holder} · {bank} · {account}\n{amount}원을 위 계좌로 보낸 뒤 확인을 눌러 주세요.'**
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  );

  /// No description provided for @poConfirmPaid.
  ///
  /// In ko, this message translates to:
  /// **'이체 완료로 표시'**
  String get poConfirmPaid;

  /// No description provided for @poMarkFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패로 표시'**
  String get poMarkFailed;

  /// No description provided for @poReasonTitle.
  ///
  /// In ko, this message translates to:
  /// **'실패 사유'**
  String get poReasonTitle;

  /// No description provided for @poReasonHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 계좌 오류, 이체 취소'**
  String get poReasonHint;

  /// No description provided for @poSend.
  ///
  /// In ko, this message translates to:
  /// **'토스로 지급 요청'**
  String get poSend;

  /// No description provided for @poSync.
  ///
  /// In ko, this message translates to:
  /// **'상태 확인'**
  String get poSync;

  /// No description provided for @poRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get poRetry;

  /// No description provided for @poNoPayouts.
  ///
  /// In ko, this message translates to:
  /// **'지급 내역이 없어요'**
  String get poNoPayouts;

  /// No description provided for @poRequestedToast.
  ///
  /// In ko, this message translates to:
  /// **'지급 요청 {n}건을 만들었어요'**
  String poRequestedToast(String n);

  /// No description provided for @poReasonRequired.
  ///
  /// In ko, this message translates to:
  /// **'사유를 입력해 주세요'**
  String get poReasonRequired;

  /// No description provided for @poRevealNote.
  ///
  /// In ko, this message translates to:
  /// **'계좌 정보는 조회 기록에 남아요'**
  String get poRevealNote;

  /// No description provided for @poSellerAction.
  ///
  /// In ko, this message translates to:
  /// **'판매자 등록'**
  String get poSellerAction;

  /// No description provided for @poSellerTitle.
  ///
  /// In ko, this message translates to:
  /// **'토스 판매자 등록'**
  String get poSellerTitle;

  /// No description provided for @poSellerHint.
  ///
  /// In ko, this message translates to:
  /// **'이 파트너의 확인된 정산 계좌로 등록해요. 사업자 정보만 입력해 주세요.'**
  String get poSellerHint;

  /// No description provided for @poSellerIndividual.
  ///
  /// In ko, this message translates to:
  /// **'개인'**
  String get poSellerIndividual;

  /// No description provided for @poSellerCompany.
  ///
  /// In ko, this message translates to:
  /// **'사업자'**
  String get poSellerCompany;

  /// No description provided for @poSellerName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get poSellerName;

  /// No description provided for @poSellerRepresentative.
  ///
  /// In ko, this message translates to:
  /// **'대표자명'**
  String get poSellerRepresentative;

  /// No description provided for @poSellerRegNo.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록번호 (숫자 10자리)'**
  String get poSellerRegNo;

  /// No description provided for @poSellerEmail.
  ///
  /// In ko, this message translates to:
  /// **'정산 이메일'**
  String get poSellerEmail;

  /// No description provided for @poSellerPhone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get poSellerPhone;

  /// No description provided for @poSellerSubmit.
  ///
  /// In ko, this message translates to:
  /// **'등록하기'**
  String get poSellerSubmit;

  /// No description provided for @poSellerDone.
  ///
  /// In ko, this message translates to:
  /// **'판매자 상태: {status}'**
  String poSellerDone(String status);

  /// No description provided for @oFlags.
  ///
  /// In ko, this message translates to:
  /// **'기능 스위치'**
  String get oFlags;

  /// No description provided for @oFlagBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get oFlagBooking;

  /// No description provided for @oFlagChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get oFlagChat;

  /// No description provided for @oFlagAi.
  ///
  /// In ko, this message translates to:
  /// **'AI 상담'**
  String get oFlagAi;

  /// No description provided for @oFlagPayments.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get oFlagPayments;

  /// No description provided for @oMaintenance.
  ///
  /// In ko, this message translates to:
  /// **'점검 모드'**
  String get oMaintenance;

  /// No description provided for @oMaintenanceHint.
  ///
  /// In ko, this message translates to:
  /// **'켜면 고객·파트너 앱이 점검 화면을 보여줘요. 콘솔은 계속 쓸 수 있어요.'**
  String get oMaintenanceHint;

  /// No description provided for @oMaintenanceMessage.
  ///
  /// In ko, this message translates to:
  /// **'점검 안내 문구'**
  String get oMaintenanceMessage;

  /// No description provided for @oClientErrors.
  ///
  /// In ko, this message translates to:
  /// **'앱 오류 보고'**
  String get oClientErrors;

  /// No description provided for @oClientErrorsHint.
  ///
  /// In ko, this message translates to:
  /// **'웹·Windows·콘솔에서 보고된 최근 오류예요. 개인정보는 자동으로 가려져요.'**
  String get oClientErrorsHint;

  /// No description provided for @oClientErrorsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 오류가 없어요'**
  String get oClientErrorsEmpty;

  /// No description provided for @oHeartbeat.
  ///
  /// In ko, this message translates to:
  /// **'업타임 하트비트'**
  String get oHeartbeat;

  /// No description provided for @oHeartbeatOn.
  ///
  /// In ko, this message translates to:
  /// **'연결됨. 서버가 살아 있으면 외부에서 알려줘요.'**
  String get oHeartbeatOn;

  /// No description provided for @oHeartbeatOff.
  ///
  /// In ko, this message translates to:
  /// **'설정 필요: install.sh 에 MALKKEUM_HEARTBEAT_URL 을 넣어주세요.'**
  String get oHeartbeatOff;

  /// No description provided for @pvManage.
  ///
  /// In ko, this message translates to:
  /// **'동의 관리'**
  String get pvManage;

  /// No description provided for @pvOptional.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get pvOptional;

  /// No description provided for @pvTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관 동의'**
  String get pvTerms;

  /// No description provided for @pvPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용 동의'**
  String get pvPrivacy;

  /// No description provided for @pvOverseas.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 국외 이전 동의'**
  String get pvOverseas;

  /// No description provided for @pvMarketing.
  ///
  /// In ko, this message translates to:
  /// **'마케팅 정보 수신 동의'**
  String get pvMarketing;

  /// No description provided for @pvMarketingHint.
  ///
  /// In ko, this message translates to:
  /// **'쿠폰과 이벤트 소식을 문자, 알림톡, 앱 푸시로 받아요. 언제든지 끌 수 있어요.'**
  String get pvMarketingHint;

  /// No description provided for @pvReconsent.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침이 바뀌었어요. 다시 확인하고 동의해 주세요.'**
  String get pvReconsent;

  /// No description provided for @pvSaved.
  ///
  /// In ko, this message translates to:
  /// **'동의 내용을 저장했어요'**
  String get pvSaved;

  /// No description provided for @pvExport.
  ///
  /// In ko, this message translates to:
  /// **'내 데이터 내려받기'**
  String get pvExport;

  /// No description provided for @pvExportHint.
  ///
  /// In ko, this message translates to:
  /// **'회원님의 정보를 JSON 형식으로 보여 드려요. 복사해서 보관할 수 있어요.'**
  String get pvExportHint;

  /// No description provided for @pvCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get pvCopy;

  /// No description provided for @pvCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get pvCopied;

  /// No description provided for @pvExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get pvExportFailed;

  /// No description provided for @safetyEmergency.
  ///
  /// In ko, this message translates to:
  /// **'긴급 연락처'**
  String get safetyEmergency;

  /// No description provided for @emergencyPolice.
  ///
  /// In ko, this message translates to:
  /// **'112 경찰·응급'**
  String get emergencyPolice;

  /// No description provided for @emergencyFire.
  ///
  /// In ko, this message translates to:
  /// **'119 소방·구급'**
  String get emergencyFire;

  /// No description provided for @emergencyShop.
  ///
  /// In ko, this message translates to:
  /// **'고객센터'**
  String get emergencyShop;

  /// No description provided for @caseReportAction.
  ///
  /// In ko, this message translates to:
  /// **'문제 신고하기'**
  String get caseReportAction;

  /// No description provided for @caseReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 문제가 있었나요?'**
  String get caseReportTitle;

  /// No description provided for @caseKindDamage.
  ///
  /// In ko, this message translates to:
  /// **'파손'**
  String get caseKindDamage;

  /// No description provided for @caseKindLoss.
  ///
  /// In ko, this message translates to:
  /// **'분실'**
  String get caseKindLoss;

  /// No description provided for @caseKindComplaint.
  ///
  /// In ko, this message translates to:
  /// **'불만·서비스 문제'**
  String get caseKindComplaint;

  /// No description provided for @caseKindNoShow.
  ///
  /// In ko, this message translates to:
  /// **'청소팀이 오지 않았어요'**
  String get caseKindNoShow;

  /// No description provided for @caseKindSafety.
  ///
  /// In ko, this message translates to:
  /// **'안전 문제'**
  String get caseKindSafety;

  /// No description provided for @caseKindPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 이의'**
  String get caseKindPayment;

  /// No description provided for @caseSummaryHint.
  ///
  /// In ko, this message translates to:
  /// **'자세히 적어 주세요 (300자 이내)'**
  String get caseSummaryHint;

  /// No description provided for @caseSubmit.
  ///
  /// In ko, this message translates to:
  /// **'접수하기'**
  String get caseSubmit;

  /// No description provided for @caseSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'접수했어요. 담당자가 24시간 안에 확인할게요.'**
  String get caseSubmitted;

  /// No description provided for @caseFailed.
  ///
  /// In ko, this message translates to:
  /// **'접수하지 못했어요. 다시 시도해 주세요.'**
  String get caseFailed;

  /// No description provided for @checkInAction.
  ///
  /// In ko, this message translates to:
  /// **'도착 체크인'**
  String get checkInAction;

  /// No description provided for @checkOutAction.
  ///
  /// In ko, this message translates to:
  /// **'작업 완료 체크아웃'**
  String get checkOutAction;

  /// No description provided for @checkedInAt.
  ///
  /// In ko, this message translates to:
  /// **'도착 {time}'**
  String checkedInAt(String time);

  /// No description provided for @checkedOutAt.
  ///
  /// In ko, this message translates to:
  /// **'종료 {time}'**
  String checkedOutAt(String time);

  /// No description provided for @entryCodeAction.
  ///
  /// In ko, this message translates to:
  /// **'출입 비밀번호 보기'**
  String get entryCodeAction;

  /// No description provided for @entryCodeTitle.
  ///
  /// In ko, this message translates to:
  /// **'출입 비밀번호'**
  String get entryCodeTitle;

  /// No description provided for @entryCodeNotToday.
  ///
  /// In ko, this message translates to:
  /// **'방문 당일에만 볼 수 있어요'**
  String get entryCodeNotToday;

  /// No description provided for @entryCodeEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 비밀번호가 없어요'**
  String get entryCodeEmpty;

  /// No description provided for @actionFailed.
  ///
  /// In ko, this message translates to:
  /// **'처리하지 못했어요. 다시 시도해 주세요.'**
  String get actionFailed;

  /// No description provided for @consoleCasesTitle.
  ///
  /// In ko, this message translates to:
  /// **'사건 접수함'**
  String get consoleCasesTitle;

  /// No description provided for @consoleCasesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'열린 사건이 없어요'**
  String get consoleCasesEmpty;

  /// No description provided for @caseOverdue.
  ///
  /// In ko, this message translates to:
  /// **'기한 초과'**
  String get caseOverdue;

  /// No description provided for @caseStatusOpen.
  ///
  /// In ko, this message translates to:
  /// **'접수'**
  String get caseStatusOpen;

  /// No description provided for @caseStatusInvestigating.
  ///
  /// In ko, this message translates to:
  /// **'조사 중'**
  String get caseStatusInvestigating;

  /// No description provided for @caseStatusResolved.
  ///
  /// In ko, this message translates to:
  /// **'해결'**
  String get caseStatusResolved;

  /// No description provided for @caseStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'기각'**
  String get caseStatusRejected;

  /// No description provided for @caseReassign.
  ///
  /// In ko, this message translates to:
  /// **'기사 재배정'**
  String get caseReassign;

  /// No description provided for @caseRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get caseRefund;

  /// No description provided for @caseHold.
  ///
  /// In ko, this message translates to:
  /// **'정산 보류'**
  String get caseHold;

  /// No description provided for @caseNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'내부 메모'**
  String get caseNoteHint;

  /// No description provided for @caseSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get caseSave;

  /// No description provided for @cSetup.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get cSetup;

  /// No description provided for @cSetupTitle.
  ///
  /// In ko, this message translates to:
  /// **'서비스 시작 준비'**
  String get cSetupTitle;

  /// No description provided for @cSetupProgress.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total} 완료'**
  String cSetupProgress(String done, String total);

  /// No description provided for @cSetupAllDone.
  ///
  /// In ko, this message translates to:
  /// **'모든 준비가 끝났어요!'**
  String get cSetupAllDone;

  /// No description provided for @cSetupBusiness.
  ///
  /// In ko, this message translates to:
  /// **'사업장 정보'**
  String get cSetupBusiness;

  /// No description provided for @cSetupBusinessName.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이름'**
  String get cSetupBusinessName;

  /// No description provided for @cSetupSupportPhone.
  ///
  /// In ko, this message translates to:
  /// **'고객센터 전화'**
  String get cSetupSupportPhone;

  /// No description provided for @cSetupSupportEmail.
  ///
  /// In ko, this message translates to:
  /// **'고객센터 이메일'**
  String get cSetupSupportEmail;

  /// No description provided for @cSetupSupportHours.
  ///
  /// In ko, this message translates to:
  /// **'상담 시간'**
  String get cSetupSupportHours;

  /// No description provided for @cSetupColor.
  ///
  /// In ko, this message translates to:
  /// **'대표 색상'**
  String get cSetupColor;

  /// No description provided for @cSetupLogo.
  ///
  /// In ko, this message translates to:
  /// **'로고 올리기'**
  String get cSetupLogo;

  /// No description provided for @cSetupCompany.
  ///
  /// In ko, this message translates to:
  /// **'사업자 정보 (앱·웹사이트 하단에 표시)'**
  String get cSetupCompany;

  /// No description provided for @cSetupLegalName.
  ///
  /// In ko, this message translates to:
  /// **'상호(법인명)'**
  String get cSetupLegalName;

  /// No description provided for @cSetupCeo.
  ///
  /// In ko, this message translates to:
  /// **'대표자'**
  String get cSetupCeo;

  /// No description provided for @cSetupRegNo.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록번호'**
  String get cSetupRegNo;

  /// No description provided for @cSetupMailOrderNo.
  ///
  /// In ko, this message translates to:
  /// **'통신판매업 신고번호'**
  String get cSetupMailOrderNo;

  /// No description provided for @cSetupAddress.
  ///
  /// In ko, this message translates to:
  /// **'사업장 주소'**
  String get cSetupAddress;

  /// No description provided for @cSetupPrivacyOfficer.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 보호책임자'**
  String get cSetupPrivacyOfficer;

  /// No description provided for @cSetupStoreLinks.
  ///
  /// In ko, this message translates to:
  /// **'앱 스토어 주소 (출시 후 입력하면 웹사이트 버튼이 켜져요)'**
  String get cSetupStoreLinks;

  /// No description provided for @cSetupCustomerApp.
  ///
  /// In ko, this message translates to:
  /// **'고객 앱'**
  String get cSetupCustomerApp;

  /// No description provided for @cSetupPartnerApp.
  ///
  /// In ko, this message translates to:
  /// **'파트너 앱'**
  String get cSetupPartnerApp;

  /// No description provided for @cSetupPayMethods.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단'**
  String get cSetupPayMethods;

  /// No description provided for @cSetupPayMethodsHint.
  ///
  /// In ko, this message translates to:
  /// **'고객 앱에 보여줄 결제 수단을 켜고 꺼요. 바로 적용돼요.'**
  String get cSetupPayMethodsHint;

  /// No description provided for @cReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'스토어 심사용 데모 계정'**
  String get cReviewTitle;

  /// No description provided for @cReviewHint.
  ///
  /// In ko, this message translates to:
  /// **'앱 심사원은 한국 문자를 받을 수 없어요. 아래 번호와 6자리 코드를 심사 메모에 적어 주세요. 기간이 지나면 자동으로 꺼져요.'**
  String get cReviewHint;

  /// No description provided for @cReviewPhone.
  ///
  /// In ko, this message translates to:
  /// **'데모 전화번호'**
  String get cReviewPhone;

  /// No description provided for @cReviewCode.
  ///
  /// In ko, this message translates to:
  /// **'고정 인증 코드 (숫자 6자리)'**
  String get cReviewCode;

  /// No description provided for @cReviewActiveUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 사용 가능'**
  String cReviewActiveUntil(String date);

  /// No description provided for @cReviewEnable.
  ///
  /// In ko, this message translates to:
  /// **'켜기 (14일)'**
  String get cReviewEnable;

  /// No description provided for @pDeleteAccountBody.
  ///
  /// In ko, this message translates to:
  /// **'팀과 개인정보가 삭제되고 되돌릴 수 없어요. 배정된 작업이 있거나 정산이 남아 있으면 먼저 마무리해 주세요.'**
  String get pDeleteAccountBody;

  /// No description provided for @err_has_active_jobs.
  ///
  /// In ko, this message translates to:
  /// **'배정된 작업이 있어요. 작업을 마치거나 상담원에게 이관을 요청해 주세요.'**
  String get err_has_active_jobs;

  /// No description provided for @err_pending_payouts.
  ///
  /// In ko, this message translates to:
  /// **'아직 정산이 남아 있어요. 지급이 끝난 뒤 탈퇴할 수 있어요.'**
  String get err_pending_payouts;

  /// No description provided for @err_phone_required.
  ///
  /// In ko, this message translates to:
  /// **'작업을 받으려면 먼저 휴대폰 번호를 인증해 주세요.'**
  String get err_phone_required;

  /// No description provided for @nAlerts.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get nAlerts;

  /// No description provided for @nEmpty.
  ///
  /// In ko, this message translates to:
  /// **'새 알림이 없어요'**
  String get nEmpty;

  /// No description provided for @nUnread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 알림 {count}개'**
  String nUnread(String count);

  /// No description provided for @pVerifyPhone.
  ///
  /// In ko, this message translates to:
  /// **'번호 인증'**
  String get pVerifyPhone;

  /// No description provided for @mMyJobs.
  ///
  /// In ko, this message translates to:
  /// **'내 작업'**
  String get mMyJobs;

  /// No description provided for @mNoJobs.
  ///
  /// In ko, this message translates to:
  /// **'배정된 작업이 없어요. 팀장이 작업을 배정하면 여기에 보여요.'**
  String get mNoJobs;

  /// No description provided for @mTeam.
  ///
  /// In ko, this message translates to:
  /// **'{team} 팀원'**
  String mTeam(String team);

  /// No description provided for @cSetupSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get cSetupSave;

  /// No description provided for @cSetupSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get cSetupSaved;

  /// No description provided for @cSetupTest.
  ///
  /// In ko, this message translates to:
  /// **'연결 테스트'**
  String get cSetupTest;

  /// No description provided for @cSetupClear.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get cSetupClear;

  /// No description provided for @cSetupConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get cSetupConnected;

  /// No description provided for @cSetupNotConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get cSetupNotConnected;

  /// No description provided for @cSetupFromEnv.
  ///
  /// In ko, this message translates to:
  /// **'서버 설정 사용 중'**
  String get cSetupFromEnv;

  /// No description provided for @cSetupCheckInApp.
  ///
  /// In ko, this message translates to:
  /// **'저장됨 · 앱에서 로그인해 확인하세요'**
  String get cSetupCheckInApp;

  /// No description provided for @cSetupInvalidKey.
  ///
  /// In ko, this message translates to:
  /// **'키가 올바르지 않아요. 복사한 값을 다시 확인해 주세요'**
  String get cSetupInvalidKey;

  /// No description provided for @cSetupUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'서비스에 연결할 수 없어요. 잠시 후 다시 시도해 주세요'**
  String get cSetupUnreachable;

  /// No description provided for @cSetupKeepValue.
  ///
  /// In ko, this message translates to:
  /// **'저장된 값 유지 (바꿀 때만 입력)'**
  String get cSetupKeepValue;

  /// No description provided for @cSetupGuide.
  ///
  /// In ko, this message translates to:
  /// **'따라 하기'**
  String get cSetupGuide;

  /// No description provided for @cSetupOpenSite.
  ///
  /// In ko, this message translates to:
  /// **'사이트 열기'**
  String get cSetupOpenSite;

  /// No description provided for @cSetupWebhook.
  ///
  /// In ko, this message translates to:
  /// **'웹훅 주소 (PortOne 콘솔에 붙여넣기)'**
  String get cSetupWebhook;

  /// No description provided for @cCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get cCopied;

  /// No description provided for @cSetupDevMode.
  ///
  /// In ko, this message translates to:
  /// **'테스트 모드예요. 실제 결제·문자는 나가지 않아요'**
  String get cSetupDevMode;

  /// No description provided for @cSetupOptional.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get cSetupOptional;

  /// No description provided for @cIntPortone.
  ///
  /// In ko, this message translates to:
  /// **'결제 (PortOne)'**
  String get cIntPortone;

  /// No description provided for @cIntSolapi.
  ///
  /// In ko, this message translates to:
  /// **'문자 · 알림톡 (Solapi)'**
  String get cIntSolapi;

  /// No description provided for @cIntPush.
  ///
  /// In ko, this message translates to:
  /// **'앱 푸시 알림 (Firebase)'**
  String get cIntPush;

  /// No description provided for @cIntKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인'**
  String get cIntKakao;

  /// No description provided for @cIntNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버 로그인'**
  String get cIntNaver;

  /// No description provided for @cIntGoogle.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인'**
  String get cIntGoogle;

  /// No description provided for @cIntApple.
  ///
  /// In ko, this message translates to:
  /// **'애플 로그인'**
  String get cIntApple;

  /// No description provided for @cFirstRunTitle.
  ///
  /// In ko, this message translates to:
  /// **'환영합니다! 사장님 계정을 만들어 주세요'**
  String get cFirstRunTitle;

  /// No description provided for @cFirstRunBody.
  ///
  /// In ko, this message translates to:
  /// **'설치할 때 화면에 나온 12자리 설치 코드를 입력하세요. 이 계정으로 모든 설정을 관리해요.'**
  String get cFirstRunBody;

  /// No description provided for @cFirstRunCode.
  ///
  /// In ko, this message translates to:
  /// **'설치 코드'**
  String get cFirstRunCode;

  /// No description provided for @cName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get cName;

  /// No description provided for @cFirstRunCreate.
  ///
  /// In ko, this message translates to:
  /// **'계정 만들고 시작하기'**
  String get cFirstRunCreate;

  /// No description provided for @cWrongSetupCode.
  ///
  /// In ko, this message translates to:
  /// **'설치 코드가 맞지 않아요'**
  String get cWrongSetupCode;

  /// No description provided for @cWeakPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 12자 이상이어야 해요'**
  String get cWeakPassword;

  /// No description provided for @cInvalidValue.
  ///
  /// In ko, this message translates to:
  /// **'입력값을 확인해 주세요'**
  String get cInvalidValue;

  /// No description provided for @cMfaTitle.
  ///
  /// In ko, this message translates to:
  /// **'2단계 인증'**
  String get cMfaTitle;

  /// No description provided for @cMfaCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 앱의 6자리 코드'**
  String get cMfaCode;

  /// No description provided for @cMfaRecovery.
  ///
  /// In ko, this message translates to:
  /// **'복구 코드'**
  String get cMfaRecovery;

  /// No description provided for @cMfaUseRecovery.
  ///
  /// In ko, this message translates to:
  /// **'복구 코드 사용'**
  String get cMfaUseRecovery;

  /// No description provided for @cMfaUseCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 앱 코드 사용'**
  String get cMfaUseCode;

  /// No description provided for @cMfaVerify.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get cMfaVerify;

  /// No description provided for @cMfaBack.
  ///
  /// In ko, this message translates to:
  /// **'로그인 화면으로'**
  String get cMfaBack;

  /// No description provided for @cMfaEnrolTitle.
  ///
  /// In ko, this message translates to:
  /// **'2단계 인증 설정'**
  String get cMfaEnrolTitle;

  /// No description provided for @cMfaEnrolBody.
  ///
  /// In ko, this message translates to:
  /// **'관리자는 인증 앱 사용이 필요해요. Google Authenticator, 1Password 같은 앱에 아래 키를 추가한 뒤 앱에 표시된 6자리 코드를 입력하세요.'**
  String get cMfaEnrolBody;

  /// No description provided for @cMfaSecret.
  ///
  /// In ko, this message translates to:
  /// **'설정 키'**
  String get cMfaSecret;

  /// No description provided for @cMfaLink.
  ///
  /// In ko, this message translates to:
  /// **'설정 링크 (otpauth)'**
  String get cMfaLink;

  /// No description provided for @cMfaCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get cMfaCopy;

  /// No description provided for @cMfaCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get cMfaCopied;

  /// No description provided for @cMfaConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인하고 2단계 인증 켜기'**
  String get cMfaConfirm;

  /// No description provided for @cMfaCodesTitle.
  ///
  /// In ko, this message translates to:
  /// **'복구 코드를 저장하세요'**
  String get cMfaCodesTitle;

  /// No description provided for @cMfaCodesBody.
  ///
  /// In ko, this message translates to:
  /// **'인증 앱을 잃어버리면 각 코드를 한 번씩 쓸 수 있어요. 이 화면에서만 보여요.'**
  String get cMfaCodesBody;

  /// No description provided for @cMfaDownload.
  ///
  /// In ko, this message translates to:
  /// **'파일로 저장'**
  String get cMfaDownload;

  /// No description provided for @cMfaSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 파일을 저장할 수 없어요. 복사해서 보관하세요.'**
  String get cMfaSaveFailed;

  /// No description provided for @cMfaContinue.
  ///
  /// In ko, this message translates to:
  /// **'콘솔로 들어가기'**
  String get cMfaContinue;

  /// No description provided for @cMfaInvalid.
  ///
  /// In ko, this message translates to:
  /// **'코드가 맞지 않아요. 휴대폰 시간이 맞는지 확인하고 다시 입력하세요.'**
  String get cMfaInvalid;

  /// No description provided for @cMfaExpired.
  ///
  /// In ko, this message translates to:
  /// **'로그인 시간이 지났어요. 비밀번호부터 다시 입력하세요.'**
  String get cMfaExpired;

  /// No description provided for @cMfaLocked.
  ///
  /// In ko, this message translates to:
  /// **'시도가 너무 많아요. 몇 분 뒤에 다시 시도하세요.'**
  String get cMfaLocked;

  /// No description provided for @cStaffReset.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get cStaffReset;

  /// No description provided for @cStaffResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 직원의 비밀번호를 재설정할까요? 모든 기기에서 로그아웃돼요.'**
  String get cStaffResetConfirm;

  /// No description provided for @cStaffResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'재설정 토큰'**
  String get cStaffResetTitle;

  /// No description provided for @cStaffResetBody.
  ///
  /// In ko, this message translates to:
  /// **'이 토큰을 직원에게 전달하세요. 한 번만 쓸 수 있고 30분 동안 유효해요. 이 화면을 닫으면 다시 볼 수 없어요.'**
  String get cStaffResetBody;

  /// No description provided for @subTitle.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소'**
  String get subTitle;

  /// No description provided for @subNew.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소 신청'**
  String get subNew;

  /// No description provided for @subCadence.
  ///
  /// In ko, this message translates to:
  /// **'주기'**
  String get subCadence;

  /// No description provided for @subWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get subWeekly;

  /// No description provided for @subBiweekly.
  ///
  /// In ko, this message translates to:
  /// **'2주마다'**
  String get subBiweekly;

  /// No description provided for @subEvery4Weeks.
  ///
  /// In ko, this message translates to:
  /// **'4주마다'**
  String get subEvery4Weeks;

  /// No description provided for @subWeekday.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get subWeekday;

  /// No description provided for @subHour.
  ///
  /// In ko, this message translates to:
  /// **'시작 시간'**
  String get subHour;

  /// No description provided for @subDiscountNote.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소는 방문마다 {percent}% 할인돼요'**
  String subDiscountNote(String percent);

  /// No description provided for @subChargeNote.
  ///
  /// In ko, this message translates to:
  /// **'방문 하루 전에 등록된 카드로 결제해요'**
  String get subChargeNote;

  /// No description provided for @subCreate.
  ///
  /// In ko, this message translates to:
  /// **'신청하기'**
  String get subCreate;

  /// No description provided for @subCreated.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소를 신청했어요'**
  String get subCreated;

  /// No description provided for @subNeedAddress.
  ///
  /// In ko, this message translates to:
  /// **'방문할 주소를 먼저 등록해 주세요'**
  String get subNeedAddress;

  /// No description provided for @subListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 정기 청소가 없어요'**
  String get subListEmpty;

  /// No description provided for @subStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'이용 중'**
  String get subStatusActive;

  /// No description provided for @subStatusPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시 정지'**
  String get subStatusPaused;

  /// No description provided for @subStatusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'해지됨'**
  String get subStatusCancelled;

  /// No description provided for @subNextVisit.
  ///
  /// In ko, this message translates to:
  /// **'다음 방문 {date}'**
  String subNextVisit(String date);

  /// No description provided for @subPause.
  ///
  /// In ko, this message translates to:
  /// **'일시 정지'**
  String get subPause;

  /// No description provided for @subResume.
  ///
  /// In ko, this message translates to:
  /// **'다시 시작'**
  String get subResume;

  /// No description provided for @subCancelSub.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소 해지'**
  String get subCancelSub;

  /// No description provided for @subCancelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'앞으로의 정기 방문이 취소돼요. 이미 예약된 방문은 따로 취소해 주세요.'**
  String get subCancelConfirm;

  /// No description provided for @subSkip.
  ///
  /// In ko, this message translates to:
  /// **'이번 방문 건너뛰기'**
  String get subSkip;

  /// No description provided for @subMove.
  ///
  /// In ko, this message translates to:
  /// **'날짜 변경'**
  String get subMove;

  /// No description provided for @subVisitLocked.
  ///
  /// In ko, this message translates to:
  /// **'방문 하루 전부터는 변경할 수 없어요'**
  String get subVisitLocked;

  /// No description provided for @subPausedPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제가 계속 실패해 멈췄어요. 카드를 바꾼 뒤 다시 시작해 주세요.'**
  String get subPausedPayment;

  /// No description provided for @subStatePlanned.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get subStatePlanned;

  /// No description provided for @subStateBooked.
  ///
  /// In ko, this message translates to:
  /// **'예약됨'**
  String get subStateBooked;

  /// No description provided for @subStateSkipped.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get subStateSkipped;

  /// No description provided for @subStateMissed.
  ///
  /// In ko, this message translates to:
  /// **'놓침'**
  String get subStateMissed;

  /// No description provided for @pSubsTitle.
  ///
  /// In ko, this message translates to:
  /// **'정기 고객'**
  String get pSubsTitle;

  /// No description provided for @pSubsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'정기 고객이 아직 없어요'**
  String get pSubsEmpty;

  /// No description provided for @cSubsTitle.
  ///
  /// In ko, this message translates to:
  /// **'정기 청소 구독'**
  String get cSubsTitle;

  /// No description provided for @cSubsEdit.
  ///
  /// In ko, this message translates to:
  /// **'고객 대신 수정'**
  String get cSubsEdit;

  /// No description provided for @cMrr.
  ///
  /// In ko, this message translates to:
  /// **'월 반복 매출 (MRR)'**
  String get cMrr;

  /// No description provided for @cChurn.
  ///
  /// In ko, this message translates to:
  /// **'해지율'**
  String get cChurn;

  /// No description provided for @cActiveSubs.
  ///
  /// In ko, this message translates to:
  /// **'이용 중 구독'**
  String get cActiveSubs;

  /// No description provided for @cRecognized.
  ///
  /// In ko, this message translates to:
  /// **'기간 인식 매출'**
  String get cRecognized;

  /// No description provided for @cSubsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'구독 목록을 불러오지 못했어요'**
  String get cSubsLoadFailed;

  /// No description provided for @tTaxSection.
  ///
  /// In ko, this message translates to:
  /// **'세무'**
  String get tTaxSection;

  /// No description provided for @tVatQuarter.
  ///
  /// In ko, this message translates to:
  /// **'{q}분기 부가세 CSV'**
  String tVatQuarter(String q);

  /// No description provided for @tVatYear.
  ///
  /// In ko, this message translates to:
  /// **'연도'**
  String get tVatYear;

  /// No description provided for @tExportWithholding.
  ///
  /// In ko, this message translates to:
  /// **'지급명세서 CSV'**
  String get tExportWithholding;

  /// No description provided for @tExportTaxInvoices.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 업로드 CSV'**
  String get tExportTaxInvoices;

  /// No description provided for @tTaxLayoutNote.
  ///
  /// In ko, this message translates to:
  /// **'홈택스 실제 양식과 대조한 뒤 올려주세요. 열 구성은 아직 확인되지 않았어요.'**
  String get tTaxLayoutNote;

  /// No description provided for @tCashReceipts.
  ///
  /// In ko, this message translates to:
  /// **'현금영수증'**
  String get tCashReceipts;

  /// No description provided for @tCashIssued.
  ///
  /// In ko, this message translates to:
  /// **'발급 완료'**
  String get tCashIssued;

  /// No description provided for @tCashFailed.
  ///
  /// In ko, this message translates to:
  /// **'발급 실패'**
  String get tCashFailed;

  /// No description provided for @tCashPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get tCashPending;

  /// No description provided for @tCashCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get tCashCancelled;

  /// No description provided for @tReissue.
  ///
  /// In ko, this message translates to:
  /// **'재발급'**
  String get tReissue;

  /// No description provided for @tTaxInvoices.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서'**
  String get tTaxInvoices;

  /// No description provided for @tApprovalNumber.
  ///
  /// In ko, this message translates to:
  /// **'승인번호'**
  String get tApprovalNumber;

  /// No description provided for @tIssuedOn.
  ///
  /// In ko, this message translates to:
  /// **'발행일'**
  String get tIssuedOn;

  /// No description provided for @tMarkIssued.
  ///
  /// In ko, this message translates to:
  /// **'발행 완료 표시'**
  String get tMarkIssued;

  /// No description provided for @tQueueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 요청이 없어요'**
  String get tQueueEmpty;

  /// No description provided for @tWithholdingLabel.
  ///
  /// In ko, this message translates to:
  /// **'원천징수'**
  String get tWithholdingLabel;

  /// No description provided for @tGrossAmount.
  ///
  /// In ko, this message translates to:
  /// **'지급총액'**
  String get tGrossAmount;

  /// No description provided for @tIncomeTax.
  ///
  /// In ko, this message translates to:
  /// **'소득세'**
  String get tIncomeTax;

  /// No description provided for @tLocalTax.
  ///
  /// In ko, this message translates to:
  /// **'지방소득세'**
  String get tLocalTax;

  /// No description provided for @tNetAmount.
  ///
  /// In ko, this message translates to:
  /// **'실지급액'**
  String get tNetAmount;

  /// No description provided for @tNoWithholding.
  ///
  /// In ko, this message translates to:
  /// **'원천징수 없음 (사업자 등록)'**
  String get tNoWithholding;

  /// No description provided for @tEstWithholding.
  ///
  /// In ko, this message translates to:
  /// **'예상 원천징수 (미지급분 기준)'**
  String get tEstWithholding;

  /// No description provided for @tReceiptOptions.
  ///
  /// In ko, this message translates to:
  /// **'영수증 선택'**
  String get tReceiptOptions;

  /// No description provided for @tWantCashReceipt.
  ///
  /// In ko, this message translates to:
  /// **'현금영수증 받기'**
  String get tWantCashReceipt;

  /// No description provided for @tCashForIncome.
  ///
  /// In ko, this message translates to:
  /// **'소득공제용 (휴대폰 번호)'**
  String get tCashForIncome;

  /// No description provided for @tCashForBusiness.
  ///
  /// In ko, this message translates to:
  /// **'지출증빙용 (사업자번호)'**
  String get tCashForBusiness;

  /// No description provided for @tWantTaxInvoice.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 받기 (사업자)'**
  String get tWantTaxInvoice;

  /// No description provided for @tPhoneForReceipt.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호'**
  String get tPhoneForReceipt;

  /// No description provided for @tBusinessNumber.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록번호'**
  String get tBusinessNumber;

  /// No description provided for @tCompanyName.
  ///
  /// In ko, this message translates to:
  /// **'상호'**
  String get tCompanyName;

  /// No description provided for @tRepresentative.
  ///
  /// In ko, this message translates to:
  /// **'대표자'**
  String get tRepresentative;

  /// No description provided for @tInvoiceEmail.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 받을 이메일'**
  String get tInvoiceEmail;

  /// No description provided for @tReceiptSave.
  ///
  /// In ko, this message translates to:
  /// **'저장하고 결제'**
  String get tReceiptSave;

  /// No description provided for @tReceiptSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'영수증 정보를 저장하지 못했어요'**
  String get tReceiptSaveFailed;

  /// No description provided for @tTaxType.
  ///
  /// In ko, this message translates to:
  /// **'세무 유형'**
  String get tTaxType;

  /// No description provided for @tTaxFreelancer.
  ///
  /// In ko, this message translates to:
  /// **'프리랜서 (원천징수)'**
  String get tTaxFreelancer;

  /// No description provided for @tTaxBusiness.
  ///
  /// In ko, this message translates to:
  /// **'사업자 등록 (원천징수 없음)'**
  String get tTaxBusiness;

  /// No description provided for @tReceiptSettings.
  ///
  /// In ko, this message translates to:
  /// **'영수증 설정'**
  String get tReceiptSettings;

  /// No description provided for @reviewRuleLine.
  ///
  /// In ko, this message translates to:
  /// **'욕설, 개인정보, 허위·광고 내용은 금지되며 신고된 후기는 숨겨집니다.'**
  String get reviewRuleLine;

  /// No description provided for @reportAction.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get reportAction;

  /// No description provided for @reportSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 후기를 신고할까요?'**
  String get reportSheetTitle;

  /// No description provided for @reportReasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'광고·스팸'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOffensive.
  ///
  /// In ko, this message translates to:
  /// **'욕설·혐오 표현'**
  String get reportReasonOffensive;

  /// No description provided for @reportReasonPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 포함'**
  String get reportReasonPersonal;

  /// No description provided for @reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportReasonOther;

  /// No description provided for @reportNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'자세한 내용 (선택, 300자 이내)'**
  String get reportNoteHint;

  /// No description provided for @reportSubmit.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportSubmit;

  /// No description provided for @reportThanks.
  ///
  /// In ko, this message translates to:
  /// **'신고해 주셔서 감사해요. 운영팀이 확인할게요.'**
  String get reportThanks;

  /// No description provided for @reportAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 후기예요'**
  String get reportAlready;

  /// No description provided for @reportFailed.
  ///
  /// In ko, this message translates to:
  /// **'신고하지 못했어요. 다시 시도해 주세요.'**
  String get reportFailed;

  /// No description provided for @reviewBlocked.
  ///
  /// In ko, this message translates to:
  /// **'후기 작성이 제한된 계정이에요. 고객센터에 문의해 주세요.'**
  String get reviewBlocked;

  /// No description provided for @modTitle.
  ///
  /// In ko, this message translates to:
  /// **'후기 신고 관리'**
  String get modTitle;

  /// No description provided for @modEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 신고가 없어요'**
  String get modEmpty;

  /// No description provided for @modReports.
  ///
  /// In ko, this message translates to:
  /// **'신고 {count}건'**
  String modReports(String count);

  /// No description provided for @modKeep.
  ///
  /// In ko, this message translates to:
  /// **'유지'**
  String get modKeep;

  /// No description provided for @modHide.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get modHide;

  /// No description provided for @modDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get modDelete;

  /// No description provided for @modBlockAuthor.
  ///
  /// In ko, this message translates to:
  /// **'작성자 후기 제한'**
  String get modBlockAuthor;

  /// No description provided for @modUnblockAuthor.
  ///
  /// In ko, this message translates to:
  /// **'제한 해제'**
  String get modUnblockAuthor;

  /// No description provided for @modDone.
  ///
  /// In ko, this message translates to:
  /// **'처리했어요'**
  String get modDone;

  /// No description provided for @modFailed.
  ///
  /// In ko, this message translates to:
  /// **'처리하지 못했어요. 다시 시도해 주세요.'**
  String get modFailed;

  /// No description provided for @modHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨겨진 후기'**
  String get modHidden;

  /// No description provided for @uUpdateBanner.
  ///
  /// In ko, this message translates to:
  /// **'새 버전 {version}이 나왔어요'**
  String uUpdateBanner(String version);

  /// No description provided for @uUpdateNow.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get uUpdateNow;

  /// No description provided for @uUpdateLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get uUpdateLater;

  /// No description provided for @uUpdateRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 필요해요'**
  String get uUpdateRequiredTitle;

  /// No description provided for @uUpdateRequiredBody.
  ///
  /// In ko, this message translates to:
  /// **'이 버전은 더 이상 쓸 수 없어요. 스토어에서 최신 버전으로 업데이트해 주세요.'**
  String get uUpdateRequiredBody;

  /// No description provided for @uUpdateStore.
  ///
  /// In ko, this message translates to:
  /// **'스토어에서 업데이트'**
  String get uUpdateStore;

  /// No description provided for @uUpdateStoreMissing.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 주소를 준비 중이에요. 잠시 후 다시 열어 주세요.'**
  String get uUpdateStoreMissing;

  /// No description provided for @uCurrentVersion.
  ///
  /// In ko, this message translates to:
  /// **'현재 버전 {version}'**
  String uCurrentVersion(String version);

  /// No description provided for @uAppVersionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전 관리'**
  String get uAppVersionTitle;

  /// No description provided for @uAppVersionHint.
  ///
  /// In ko, this message translates to:
  /// **'최소 버전보다 낮은 앱은 업데이트 화면에서 멈춰요. 최신 버전보다 낮으면 안내 배너가 떠요. 형식: 1.2.0'**
  String get uAppVersionHint;

  /// No description provided for @uMinVersion.
  ///
  /// In ko, this message translates to:
  /// **'최소 버전'**
  String get uMinVersion;

  /// No description provided for @uLatestVersion.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전'**
  String get uLatestVersion;

  /// No description provided for @webBookNow.
  ///
  /// In ko, this message translates to:
  /// **'웹에서 바로 예약'**
  String get webBookNow;

  /// No description provided for @webBookSub.
  ///
  /// In ko, this message translates to:
  /// **'앱 설치 없이 바로 예약해요'**
  String get webBookSub;

  /// No description provided for @apPgBrowserNote.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 결제를 마친 뒤 이 화면으로 돌아와 아래 버튼을 눌러 주세요.'**
  String get apPgBrowserNote;

  /// No description provided for @apPgBrowserDone.
  ///
  /// In ko, this message translates to:
  /// **'결제를 마쳤어요'**
  String get apPgBrowserDone;
}

class _TDelegate extends LocalizationsDelegate<T> {
  const _TDelegate();

  @override
  Future<T> load(Locale locale) {
    return SynchronousFuture<T>(lookupT(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'fil',
    'id',
    'ja',
    'km',
    'ko',
    'mn',
    'ne',
    'ru',
    'si',
    'th',
    'uz',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_TDelegate old) => false;
}

T lookupT(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TEn();
    case 'fil':
      return TFil();
    case 'id':
      return TId();
    case 'ja':
      return TJa();
    case 'km':
      return TKm();
    case 'ko':
      return TKo();
    case 'mn':
      return TMn();
    case 'ne':
      return TNe();
    case 'ru':
      return TRu();
    case 'si':
      return TSi();
    case 'th':
      return TTh();
    case 'uz':
      return TUz();
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
