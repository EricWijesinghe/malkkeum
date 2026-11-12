// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class TNe extends T {
  TNe([String locale = 'ne']) : super(locale);

  @override
  String get addressSearch => 'ठेगाना खोज्नुहोस्';

  @override
  String get addressSearchHint => 'सडकको नाम, भवन वा लट नम्बरले खोज्नुहोस्';

  @override
  String get addressSearchButton => 'खोज्नुहोस्';

  @override
  String get addressSearchMinChars => 'कम्तीमा २ अक्षर लेख्नुहोस्';

  @override
  String get addressNoResults =>
      'कुनै नतिजा भेटिएन। अर्को शब्द प्रयास गर्नुहोस्।';

  @override
  String get addressManualEntry => 'आफै लेख्नुहोस्';

  @override
  String get cardRegisterTitle => 'कार्ड दर्ता गर्नुहोस्';

  @override
  String get cIntJuso => 'ठेगाना खोज (juso.go.kr)';

  @override
  String get aiLabel => 'AI सहायक';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'ग्राहकको च्याटमा स्वतः जवाफ दिन्छ। प्रत्येक सन्देशमा API शुल्क लाग्छ।';

  @override
  String get aiModeOffline => 'कर्मचारी नभएको बेला मात्र जवाफ दिन्छ';

  @override
  String get aiModeAlways => 'AI सधैं पहिले जवाफ दिन्छ';

  @override
  String get aiPause => 'AI रोक्नुहोस्';

  @override
  String get aiResume => 'AI पुनः सुरु गर्नुहोस्';

  @override
  String get aiPausedNote => 'यो च्याटमा AI रोकिएको छ';

  @override
  String aiUsageMonth(String count) {
    return 'यस महिनाको AI कल: $count';
  }

  @override
  String get aiNotConfigured => 'AI सहायक बन्द छ';

  @override
  String get aiCapThreadLabel => 'प्रति च्याट प्रति घण्टा जवाफ सीमा';

  @override
  String get aiCapMemberLabel => 'प्रति ग्राहक प्रति दिन जवाफ सीमा';

  @override
  String get aiCapDailyLabel => 'सबै च्याटमा दैनिक जवाफ सीमा';

  @override
  String get aiCapHint =>
      'संख्या मात्र लेख्नुहोस्। पूर्वनिर्धारित मानका लागि खाली छोड्नुहोस्।';

  @override
  String get apSocialOr => 'वा';

  @override
  String get apSocialSignIn => 'छिटो साइन इन';

  @override
  String get apLoginKakao => 'Kakao बाट जारी राख्नुहोस्';

  @override
  String get apLoginNaver => 'Naver बाट जारी राख्नुहोस्';

  @override
  String get apLoginGoogle => 'Google बाट जारी राख्नुहोस्';

  @override
  String get apLoginApple => 'Apple बाट जारी राख्नुहोस्';

  @override
  String get apDevSocialNote =>
      'यो विकास मोड हो। वास्तविक सामाजिक खाताको सट्टा परीक्षण खातामा साइन इन हुन्छ।';

  @override
  String get apSocialFailed =>
      'छिटो साइन इन असफल भयो। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get apProviderNotConfigured => 'यो साइन इन विधि अझै तयार हुँदैछ';

  @override
  String get apPhoneTaken => 'यो नम्बर अर्को खातासँग पहिले नै दर्ता छ';

  @override
  String get apPhoneAttachTitle =>
      'कृपया आफ्नो मोबाइल नम्बर प्रमाणित गर्नुहोस्';

  @override
  String get apPhoneAttachBody =>
      'यो नम्बर बुकिङ र पार्टनर सम्पर्कका लागि प्रयोग हुन्छ। एक पटक मात्र प्रमाणित गर्नु पर्छ।';

  @override
  String get apPayAllTitle => 'भुक्तानी विधि छान्नुहोस्';

  @override
  String get apPaySavedTitle => 'सुरक्षित गरिएका विधिहरू';

  @override
  String get apPayMoreTitle => 'सबै भुक्तानी विधिहरू';

  @override
  String get apPayBillingHint =>
      'एक पटक दर्ता गर्नुहोस्, त्यसपछि एक ट्यापमा भुक्तानी गर्नुहोस्';

  @override
  String get apPayCheckoutHint => 'भुक्तानी विन्डोमा पूरा गर्नुहोस्';

  @override
  String get apPayRegistering => 'दर्ता गर्दै…';

  @override
  String get apPayManageHint =>
      'सुरक्षित विधिहरूबाट एक ट्यापमा भुक्तानी गर्नुहोस्। छिटो भुक्तानी विधि यहाँ थप्न सकिन्छ।';

  @override
  String get apMethodCard => 'क्रेडिट र डेबिट कार्ड';

  @override
  String get apMethodKakao => 'KakaoPay';

  @override
  String get apMethodNaver => 'NaverPay';

  @override
  String get apMethodToss => 'TossPay';

  @override
  String get apMethodPayco => 'PAYCO';

  @override
  String get apMethodSamsung => 'Samsung Pay';

  @override
  String get apMethodApple => 'Apple Pay';

  @override
  String get apMethodTransfer => 'बैंक ट्रान्सफर';

  @override
  String get apMethodVirtual => 'भर्चुअल खाता';

  @override
  String get apMethodPhone => 'मोबाइल बिल भुक्तानी';

  @override
  String get apMethodUnknown => 'अन्य';

  @override
  String get apVaTitle => 'जम्मा गर्ने खाता तयार छ';

  @override
  String get apVaWaiting => 'रकम जम्मा हुन बाँकी छ';

  @override
  String get apVaBody =>
      'म्याद भित्र रकम जम्मा भएपछि बुकिङ पुष्टि हुन्छ। जम्मा स्वचालित रूपमा जाँच गरिन्छ।';

  @override
  String get apVaBank => 'बैंक';

  @override
  String get apVaAccount => 'खाता नम्बर';

  @override
  String get apVaHolder => 'खाता धनी';

  @override
  String get apVaAmount => 'जम्मा गर्ने रकम';

  @override
  String apVaDue(String due) {
    return '$due भित्र जम्मा गर्नुहोस्';
  }

  @override
  String get apVaCopy => 'कपी गर्नुहोस्';

  @override
  String get apVaCopied => 'खाता नम्बर कपी भयो';

  @override
  String get apVaBannerTitle => 'एउटा बुकिङ जम्मा हुन बाँकी छ';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due सम्म';
  }

  @override
  String get apVaBannerAction => 'खाता हेर्नुहोस्';

  @override
  String get apPgTitle => 'भुक्तानी विन्डो';

  @override
  String get apPgDevNote =>
      'यो विकास वातावरणका लागि मात्र भुक्तानी सिमुलेसन हो। वास्तविक भुक्तानी हुँदैन।';

  @override
  String apPgPay(String amount) {
    return '$amount भुक्तानी गर्नुहोस्';
  }

  @override
  String get apPgIssue => 'खाता नम्बर लिनुहोस्';

  @override
  String get apPgCancel => 'भुक्तानी रद्द गर्नुहोस्';

  @override
  String get apErrSlotFullRefunded =>
      'त्यो समय भर्ने भएकोले भुक्तानी स्वतः रद्द गरियो';

  @override
  String get apErrCheckoutExpired =>
      'भुक्तानीको समय सकियो। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get apIdentityTitle => 'पहिचान प्रमाणीकरण (PASS)';

  @override
  String get apIdentityBody =>
      'तपाईंको फोन सेवा प्रदायकमार्फत पहिचान पुष्टि गरिन्छ। सुरक्षित कारोबार र भुक्तानीका लागि प्रयोग हुन्छ।';

  @override
  String get apIdentityAction => 'पहिचान प्रमाणित गर्नुहोस्';

  @override
  String get apIdentityDone => 'पहिचान प्रमाणित भयो';

  @override
  String get apIdentityVerified => 'प्रमाणित';

  @override
  String get apIdentityUnverified => 'अझै प्रमाणित भएको छैन';

  @override
  String get apIdentityDevTitle => 'परीक्षण पहिचान प्रमाणीकरण';

  @override
  String get apIdentityDevBody =>
      'विकास वातावरणमा वास्तविक जाँच बिना नै पास हुन्छ।';

  @override
  String get apIdentityDevPass => 'पास गर्नुहोस्';

  @override
  String get apPayManageTitle => 'छिटो भुक्तानी दर्ता गर्नुहोस्';

  @override
  String get bizInfoTitle => 'व्यवसाय जानकारी';

  @override
  String get bizInfoVerify => 'व्यवसाय दर्ता जाँच्नुहोस्';

  @override
  String get cSetupHostingProvider => 'होस्टिङ सेवा प्रदायक';

  @override
  String get cTitle => 'सञ्चालन कन्सोल';

  @override
  String get cEmail => 'इमेल';

  @override
  String get cPassword => 'पासवर्ड';

  @override
  String get cLogin => 'साइन इन';

  @override
  String get cLoginFailed => 'इमेल वा पासवर्ड मिलेन';

  @override
  String get cDashboard => 'ड्यासबोर्ड';

  @override
  String get cBookings => 'बुकिङ';

  @override
  String get cQuoteDesk => 'मूल्य अनुमान डेस्क';

  @override
  String get cInbox => 'परामर्श इनबक्स';

  @override
  String get cCatalog => 'सूची · मूल्य';

  @override
  String get cMarketing => 'कुपन · सामग्री';

  @override
  String get cPartners => 'पार्टनर';

  @override
  String get cSettlements => 'भुक्तानी फर्छ्यौट';

  @override
  String get cCustomers => 'ग्राहक';

  @override
  String get cStaff => 'कर्मचारी';

  @override
  String get cSearchCommand => 'खोज · आदेश';

  @override
  String get cPaletteHint => 'खण्डको नाम वा बुकिङ नम्बर टाइप गर्नुहोस्';

  @override
  String get cTodayJobs => 'आजका काम';

  @override
  String get cOpenQuotes => 'मूल्य अनुमान बाँकी';

  @override
  String get cUnassigned => 'नतोकिएको';

  @override
  String get cUnreadThreads => 'नपढिएका परामर्श';

  @override
  String get cRevenue30 => '३० दिनको भुक्तानी';

  @override
  String get cBookings30 => '३० दिनका बुकिङ';

  @override
  String get cByService => 'सेवाअनुसार बुकिङ (३० दिन)';

  @override
  String get cAllStatus => 'सबै स्थिति';

  @override
  String get cAllServices => 'सबै सेवा';

  @override
  String get cSearch => 'खोज (नम्बर, फोन, नाम, ठेगाना)';

  @override
  String get cNoResults => 'कुनै नतिजा भेटिएन';

  @override
  String get cNumber => 'नम्बर';

  @override
  String get cVisit => 'भ्रमण';

  @override
  String get cService => 'सेवा';

  @override
  String get cStatus => 'स्थिति';

  @override
  String get cTeam => 'टोली';

  @override
  String get cAmount => 'रकम';

  @override
  String get cCustomer => 'ग्राहक';

  @override
  String get cPayments => 'भुक्तानी';

  @override
  String get cChangeStatus => 'स्थिति बदल्नुहोस्';

  @override
  String get cTeamName => 'तोकिएको टोली';

  @override
  String get cAssign => 'टोली तोक्नुहोस्';

  @override
  String get cMarkDone => 'सम्पन्न चिन्ह लगाउनुहोस्';

  @override
  String get cConfirm => 'पुष्टि चिन्ह लगाउनुहोस्';

  @override
  String get cCancelRefund => 'रद्द · फिर्ता';

  @override
  String get cRefundAmount => 'फिर्ता रकम (खाली = पूरा)';

  @override
  String get cDone => 'भयो';

  @override
  String get cAnswers => 'ग्राहकका जवाफ';

  @override
  String get cEstimateCalc => 'स्वचालित गणना';

  @override
  String get cBase => 'आधार';

  @override
  String get cExtras => 'थप';

  @override
  String get cSurcharge => 'अतिरिक्त शुल्क';

  @override
  String get cBeforeVat => 'VAT अगाडि';

  @override
  String get cProQuotes => 'पार्टनरका मूल्य अनुमान';

  @override
  String get cNoProQuotes => 'पार्टनरबाट अहिलेसम्म कुनै अनुमान आएको छैन';

  @override
  String get cFinalPrice => 'ग्राहकलाई अन्तिम मूल्य';

  @override
  String get cQuoteNote => 'ग्राहकलाई पठाउने नोट';

  @override
  String get cSendQuote => 'ग्राहकलाई मूल्य अनुमान पठाउनुहोस्';

  @override
  String get cQuoteSent => 'मूल्य अनुमान पठाइयो';

  @override
  String get cCustomerChats => 'ग्राहक';

  @override
  String get cPartnerChats => 'पार्टनर';

  @override
  String get cSelectBooking => 'बुकिङ छान्नुहोस्';

  @override
  String get cRefunded => 'फिर्ता भयो';

  @override
  String get cPartRefunded => 'आंशिक फिर्ता';

  @override
  String get cFailed => 'असफल';

  @override
  String get cSelectThread => 'कुराकानी छान्नुहोस्';

  @override
  String get cReplyHint => 'जवाफ लेख्नुहोस् · पठाउन Ctrl+Enter';

  @override
  String get cOpenBooking => 'बुकिङ खोल्नुहोस्';

  @override
  String get cShortcuts => 'J/K सार्नुहोस् · Ctrl+K आदेश';

  @override
  String get cPricing => 'मूल्य';

  @override
  String get cMinutes => 'समय (मिनेट)';

  @override
  String get cActive => 'बिक्रीमा';

  @override
  String get cSaved => 'सुरक्षित भयो';

  @override
  String get cSlotCapacity => 'आगमन समयअनुसार क्षमता';

  @override
  String get cUnlimited => 'असीमित';

  @override
  String get cFormula => 'मूल्य गणना सूत्र';

  @override
  String get cTabCancelPolicy => 'रद्द नीति';

  @override
  String get cPolicyDefaultBanner =>
      'यो पूर्वनिर्धारित सेटिङ हो। जाँचेर सुरक्षित गरी पुष्टि गर्नुहोस्।';

  @override
  String get cPolicyDaysBefore => 'भ्रमणभन्दा कति दिन अगाडिदेखि';

  @override
  String get cPolicyPercent => 'शुल्क % (खाली = एपमा रद्द गर्न मिल्दैन)';

  @override
  String get cPolicyMinFee => 'न्यूनतम शुल्क (KRW)';

  @override
  String get cPolicyReschedule =>
      'तालिका परिवर्तन गर्न मिल्ने (भ्रमणभन्दा कति दिन अगाडि)';

  @override
  String get cPolicyHint =>
      'ग्राहक एपको रद्द स्क्रिनमा तुरुन्तै लागू हुन्छ। सर्तहरू अर्को कानुनी बिल्डमा अद्यावधिक हुनेछन्।';

  @override
  String get f_base_studio => 'आधार: स्टुडियो';

  @override
  String get f_base_one_and_half => 'आधार: १.५ कोठा';

  @override
  String get f_base_two_rooms => 'आधार: २ कोठा';

  @override
  String get f_base_three_rooms => 'आधार: ३ कोठा';

  @override
  String get f_base_four_plus => 'आधार: ४ वा बढी कोठा';

  @override
  String get f_per_extra_bathroom => 'थप बाथरुम प्रति';

  @override
  String get f_per_balcony => 'बालकोनी प्रति';

  @override
  String get f_duplex => 'डुप्लेक्स';

  @override
  String get f_no_elevator_high_floor => 'लिफ्ट छैन + ३ तल वा माथि';

  @override
  String get cIssueCoupon => 'कुपन जारी गर्नुहोस्';

  @override
  String get cCouponName => 'कुपनको नाम';

  @override
  String get cCouponPhones => 'लक्षित फोन नम्बर (प्रति लाइन एउटा)';

  @override
  String get cAllCustomers => 'सबै ग्राहकलाई';

  @override
  String cIssued(String n) {
    return '$n वटा जारी भयो';
  }

  @override
  String get cContent => 'सामग्री';

  @override
  String get cKind_notice => 'सूचना';

  @override
  String get cKind_tip => 'सुझाव';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'ब्यानर';

  @override
  String get cKind_legal => 'नियम';

  @override
  String get cNewContent => 'नयाँ सामग्री';

  @override
  String get cTitleField => 'शीर्षक';

  @override
  String get cBodyField => 'विवरण';

  @override
  String get cSlug => 'पहिचानकर्ता (नियम: privacy / terms)';

  @override
  String get cVerify => 'स्वीकृत';

  @override
  String get cSuspend => 'निलम्बन';

  @override
  String get cPro_pending => 'स्वीकृति बाँकी';

  @override
  String get cPro_verified => 'सक्रिय';

  @override
  String get cPro_suspended => 'निलम्बित';

  @override
  String get cCompleted => 'सम्पन्न';

  @override
  String get cCancelledN => 'रद्द';

  @override
  String get cRating => 'मूल्याङ्कन';

  @override
  String get cFeeRate => 'शुल्क %';

  @override
  String get cRunPayouts => 'भुक्तानी फर्छ्यौट चलाउनुहोस्';

  @override
  String get cPayoutDate => 'भुक्तानी मिति (सम्मको)';

  @override
  String cPayoutDone(String n) {
    return '$n जना पार्टनरलाई भुक्तानी गरियो';
  }

  @override
  String get cHold => 'रोक्नुहोस्';

  @override
  String get cRelease => 'रोक हटाउनुहोस्';

  @override
  String get cNet => 'भुक्तानी रकम';

  @override
  String get cAddStaff => 'कर्मचारी थप्नुहोस्';

  @override
  String get cRoleAdmin => 'एडमिन';

  @override
  String get cRoleConsultant => 'परामर्शदाता';

  @override
  String get cDeactivate => 'निष्क्रिय गर्नुहोस्';

  @override
  String get cActivate => 'सक्रिय गर्नुहोस्';

  @override
  String get cPasswordRule => 'कम्तीमा १२ अक्षर';

  @override
  String get cAdminOnly => 'एडमिनले मात्र गर्न सक्छन्';

  @override
  String cBookingsCount(String n) {
    return '$n वटा बुकिङ';
  }

  @override
  String get cJoined => 'सामेल भएको';

  @override
  String get cNewBooking => 'नयाँ बुकिङ आएको छ';

  @override
  String get cNewMessage => 'नयाँ सन्देश';

  @override
  String get cConfirmAsk => 'के तपाईं निश्चित हुनुहुन्छ?';

  @override
  String get ok => 'ठिक छ';

  @override
  String get cancel => 'रद्द';

  @override
  String get next => 'अर्को';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get delete => 'मेटाउनुहोस्';

  @override
  String get edit => 'सम्पादन';

  @override
  String get change => 'परिवर्तन';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String get yes => 'हो';

  @override
  String get no => 'होइन';

  @override
  String get required => 'अनिवार्य';

  @override
  String get viewAll => 'सबै हेर्नुहोस्';

  @override
  String get today => 'आज';

  @override
  String get errorGeneric =>
      'केही समस्या भयो। केही बेरपछि फेरि प्रयास गर्नुहोस्।';

  @override
  String get errorNetwork => 'इन्टरनेट जडान जाँच गर्नुहोस्';

  @override
  String get err_invalid_phone => 'मोबाइल नम्बर जाँच गर्नुहोस्';

  @override
  String get err_otp_invalid => 'प्रमाणीकरण कोड मिलेन';

  @override
  String get err_otp_expired => 'कोडको म्याद सकियो। नयाँ कोड माग्नुहोस्।';

  @override
  String get err_rate_limited =>
      'धेरै प्रयास भए। केही बेरपछि फेरि प्रयास गर्नुहोस्।';

  @override
  String get err_studio_too_large =>
      'स्टुडियो सफाइ १० प्योङसम्मको घरका लागि मात्र हो';

  @override
  String get err_date_out_of_range => 'भोलिदेखि ६० दिनभित्रको मिति छान्नुहोस्';

  @override
  String get err_slot_full => 'त्यो समय भरिइसक्यो। अर्को समय छान्नुहोस्।';

  @override
  String get err_coupon_expired => 'यो कुपनको म्याद सकियो';

  @override
  String get err_coupon_used => 'यो कुपन पहिले नै प्रयोग भइसकेको छ';

  @override
  String get err_coupon_wrong_service =>
      'यो सेवाका लागि यो कुपन प्रयोग गर्न मिल्दैन';

  @override
  String get err_payment_failed =>
      'भुक्तानी स्वीकृत भएन। अर्को विधि प्रयोग गर्नुहोस्।';

  @override
  String get err_payment_method_required => 'भुक्तानी विधि छान्नुहोस्';

  @override
  String get err_cancellation_window_closed =>
      'यो बुकिङ अब एपबाट रद्द गर्न सकिँदैन। कृपया हाम्रो टोलीसँग सम्पर्क गर्नुहोस्';

  @override
  String get err_address_required => 'भ्रमण ठेगाना थप्नुहोस्';

  @override
  String get err_already_taken => 'अर्को पार्टनरले पहिले स्वीकार गर्नुभयो';

  @override
  String get err_invalid_address => 'सबै ठेगाना विवरण भर्नुहोस्';

  @override
  String get tabHome => 'होम';

  @override
  String get tabBookings => 'बुकिङ';

  @override
  String get tabChat => 'परामर्श';

  @override
  String get tabMore => 'थप';

  @override
  String get introTitle => 'विज्ञ सफाइ\nएक मिनेटमै बुक गर्नुहोस्';

  @override
  String get introBody =>
      'अग्रिम मूल्य · जाँचिएका सफाइ टोली · प्रत्यक्ष प्रगति';

  @override
  String get introStart => 'फोन नम्बरबाट सुरु गर्नुहोस्';

  @override
  String get loginPhoneTitle => 'तपाईंको मोबाइल नम्बर के हो?';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'कोड पठाउनुहोस्';

  @override
  String get loginCodeTitle => '६ अंकको कोड हाल्नुहोस्';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone मा पठाइयो';
  }

  @override
  String get loginResend => 'फेरि पठाउनुहोस्';

  @override
  String get loginVerify => 'पुष्टि गर्नुहोस्';

  @override
  String get loginTerms =>
      'जारी राखेर तपाईं सेवाका सर्त र गोपनीयता नीतिमा सहमत हुनुहुन्छ';

  @override
  String get profileTitle => 'हामीले तपाईंलाई के भनेर बोलाऊँ?';

  @override
  String get profileNameHint => 'नाम';

  @override
  String get profileDone => 'सुरु गर्नुहोस्';

  @override
  String get welcomeToast => 'स्वागत कुपन २ वटा तपाईंको वालेटमा राखिएको छ';

  @override
  String get svc_studio => 'स्टुडियो सफाइ';

  @override
  String get svc_kitchen => 'भान्छा सफाइ';

  @override
  String get svc_bathroom => 'बाथरुम सफाइ';

  @override
  String get svc_mattress => 'म्याट्रेस सफाइ';

  @override
  String get svc_aircon => 'एयरकन्डिसनर सफाइ';

  @override
  String get svc_sofa => 'सोफा सफाइ';

  @override
  String get svc_move_out => 'घर सार्दाको सफाइ';

  @override
  String get svc_move_in => 'नयाँ घर पस्नुअघिको सफाइ';

  @override
  String get svcShort_studio => 'स्टुडियो';

  @override
  String get svcShort_kitchen => 'भान्छा';

  @override
  String get svcShort_bathroom => 'बाथरुम';

  @override
  String get svcShort_mattress => 'म्याट्रेस';

  @override
  String get svcShort_aircon => 'एसी';

  @override
  String get svcShort_sofa => 'सोफा';

  @override
  String get svcShort_move_out => 'घर छाड्ने';

  @override
  String get svcShort_move_in => 'घर पस्ने';

  @override
  String get svcDesc_studio =>
      '१० प्योङसम्मको स्टुडियो (एउटा कोठा, एउटा बाथरुम) २ घण्टामा राम्रोसँग सफा गरिन्छ।';

  @override
  String get svcDesc_kitchen =>
      'सिंक, ग्यास चुल्हो, चिम्नीको बाहिरी भाग र काउन्टरमा केन्द्रित भान्छा सफाइ।';

  @override
  String get svcDesc_bathroom =>
      'सेल्फ, नल, वाशबेसिन र शौचालयको भित्र-बाहिर सफा गरी भुइँ सुकाएर सकाइन्छ।';

  @override
  String get svcDesc_mattress =>
      'विशेष उपकरणले धुलो, किर्ना र दाग निकालिन्छ, त्यसपछि स्टिमले जीवाणुरहित गरिन्छ।';

  @override
  String get svcDesc_aircon =>
      'खोलेर कन्डेन्सर, फ्यान र फिल्टर उच्च दबाबमा धोइ जीवाणुरहित गरिन्छ।';

  @override
  String get svcDesc_sofa =>
      'कपडाअनुसारको क्लिनरले फोहोर फुकाइन्छ, त्यसपछि भिजो एक्स्ट्र्याक्सन विधिले सफा गरिन्छ।';

  @override
  String get svcDesc_move_out =>
      'घर छाड्नुअघि सामान निकालिएको घर उपकरणसहित विशेष सफाइ टोलीले सफा गर्छ।';

  @override
  String get svcDesc_move_in =>
      'नयाँ घरमा बस्नुअघि उपकरणसहित विशेष सफाइ टोलीले भित्री भाग सफा गर्छ।';

  @override
  String get svcNotes_bathroom =>
      'ड्रेन वा शौचालय जाम भएमा सेवा सीमित हुन सक्छ\nविशेष रसायन, छत वा भेन्ट सफाइ प्रदान गरिँदैन\nपुरानो ढुसी र टाँसिएको फोहोर पूर्ण रूपमा नहट्न सक्छ';

  @override
  String get svcNotes_mattress =>
      'सिंगलदेखि किङ साइजसम्म एउटै मूल्य\nधोएपछि पूर्ण सुक्न ४–६ घण्टा लाग्छ\nस्प्रिङ बिग्रिएको वा ओह्रालिएको जस्ता संरचनात्मक समस्या सुधार गरिँदैन';

  @override
  String get svcNotes_aircon =>
      '१० वर्षभन्दा पुराना उपकरण खोल्न कठिन हुन सक्छ\nबाहिरी युनिट सफाइ समावेश छैन\nसफाइअघि र पछि सामान्य रूपमा चलेको छ कि छैन भनी जाँच गरिन्छ';

  @override
  String get svcNotes_sofa =>
      'छालाको सोफा सफाइ र चिल्लो बनाउने कोटिङसहित गरिन्छ\nपुराना दाग वा रङ सर्ने समस्या पूर्ण रूपमा नहट्न सक्छ\nपूर्ण सुक्न ४–६ घण्टा लाग्छ';

  @override
  String get unitTitle_bathroom => 'बाथरुमको संख्या';

  @override
  String get unitTitle_mattress => 'म्याट्रेसको संख्या';

  @override
  String get unitTitle_aircon => 'एसीको प्रकार';

  @override
  String get unitTitle_sofa => 'सोफाको साइज';

  @override
  String unit_count(String n) {
    return '$n वटा';
  }

  @override
  String get unit_wall => 'भित्तामा झुण्ड्याइने, १ वटा';

  @override
  String get unit_stand => 'भुइँमा राखिने, १ वटा';

  @override
  String get unit_two_in_one => '२ इन १ (स्ट्यान्ड + भित्ता)';

  @override
  String get unit_ceiling => 'छतमा जडान, १ वटा';

  @override
  String get unit_seat_1_2 => '१–२ जनाको';

  @override
  String get unit_seat_3 => '३ जनाको';

  @override
  String get unit_seat_4_plus => '४ जना वा बढी';

  @override
  String get unit_l_shape => 'L आकार · काउच';

  @override
  String durH(String h) {
    return '$h घण्टा';
  }

  @override
  String durHM(String h, String m) {
    return '$h घण्टा $m मिनेट';
  }

  @override
  String durM(String m) {
    return '$m मिनेट';
  }

  @override
  String about(String value) {
    return 'लगभग $value';
  }

  @override
  String fromPrice(String price) {
    return '$price बाट';
  }

  @override
  String get quoteBadge => 'मूल्य अनुमान';

  @override
  String get status0 => 'परामर्शमा';

  @override
  String get status1 => 'बुकिङ पुष्टि भयो';

  @override
  String get status2 => 'टोली तोकियो';

  @override
  String get status3 => 'सफाइ सम्पन्न';

  @override
  String get statusCancelled => 'रद्द भयो';

  @override
  String homeGreeting(String name) {
    return '$name जी,\nआज कुन ठाउँ सफा गरौँ?';
  }

  @override
  String get homeGreetingAnon => 'आज कुन ठाउँ\nसफा गरौँ?';

  @override
  String get homeUpcoming => 'आगामी बुकिङ';

  @override
  String dDay(String days) {
    return '$days दिनमा';
  }

  @override
  String get homeServices => 'तपाईंलाई कुन सफाइ चाहिन्छ?';

  @override
  String get homeAddAddress =>
      'ठेगाना दर्ता गर्नुहोस्, उपलब्ध सेवा र मूल्य तुरुन्तै देखाउँछौँ';

  @override
  String get homeAddAddressCta => 'ठेगाना दर्ता गर्नुहोस्';

  @override
  String homeRebook(String service) {
    return '$service फेरि बुक गर्नुहोस्';
  }

  @override
  String get homeRebookBody => 'गत पटकजस्तै सर्तमा छिटो बुक गर्नुहोस्';

  @override
  String get homeNotices => 'नयाँ समाचार';

  @override
  String get trustVat => 'VAT समावेश\nदेखाइएकै मूल्य';

  @override
  String get trustCancel => 'भ्रमणको २ दिनअघिसम्म\nनिःशुल्क रद्द';

  @override
  String get trustCard => 'कार्डको विवरण\nभुक्तानी कम्पनीमा मात्र सुरक्षित';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'मिति छान्नुहोस्';

  @override
  String get notIncluded => 'कृपया जाँच गर्नुहोस्';

  @override
  String studioBlockedTitle(String size) {
    return '$size प्योङ स्टुडियो सफाइका लागि ठूलो छ';
  }

  @override
  String get studioBlockedBody =>
      'हाम्रो परामर्श टोलीले तपाईंको घरका लागि उपयुक्त सेवा सुझाउनेछ।';

  @override
  String get consultCta => 'परामर्शमा सोध्नुहोस्';

  @override
  String get addressTitle => 'कहाँ आउनु पर्ने हो?';

  @override
  String get addressAdd => 'नयाँ ठेगाना थप्नुहोस्';

  @override
  String get addressLabel => 'नाम';

  @override
  String get addressLabelHint => 'जस्तै: घर';

  @override
  String get addressDistrict => 'जिल्ला';

  @override
  String get addressRoad => 'सडक ठेगाना';

  @override
  String get addressDetail => 'फ्ल्याट / तल्ला';

  @override
  String get addressSize => 'घरको साइज (प्योङ)';

  @override
  String get addressSizeHelp => 'प्रयोग योग्य क्षेत्रफल · १ प्योङ ≈ ३.३ m²';

  @override
  String get addressHome => 'घर';

  @override
  String get addressOffice => 'अफिस';

  @override
  String get addressEmpty => 'कुनै ठेगाना सुरक्षित गरिएको छैन';

  @override
  String get addressSaved => 'ठेगाना सुरक्षित भयो';

  @override
  String pyeong(String n) {
    return '$n प्योङ';
  }

  @override
  String get scheduleTitle => 'कहिले आउने?';

  @override
  String get scheduleArrival => 'आगमन समय';

  @override
  String get scheduleFull => 'भरियो';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end बीच आगमन';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · लगभग $time मा सकिन्छ';
  }

  @override
  String get scheduleRange => 'भोलिदेखि ६० दिनभित्र बुक गर्न सकिन्छ';

  @override
  String get morning => 'बिहान';

  @override
  String get afternoon => 'दिउँसो';

  @override
  String get scheduleQuoteNote => 'सटीक आगमन समय परामर्शमा पुष्टि गरिनेछ';

  @override
  String get goToPayment => 'भुक्तानीमा जानुहोस्';

  @override
  String get prepTitle => 'भ्रमणअघि यी तयार राख्नुहोस्';

  @override
  String get prepBody => 'यी नभए केही काम सीमित हुन सक्छ';

  @override
  String get prepAsk =>
      'तयार गर्न नसकिने भए परामर्शमा पहिले नै जानकारी दिनुहोस्';

  @override
  String get tool_vacuum => 'भ्याकुम';

  @override
  String get tool_trash => 'फोहोर झोला';

  @override
  String get tool_mop => 'मप';

  @override
  String get tool_cloth => 'कपडा';

  @override
  String get tool_gloves => 'रबर पञ्जा';

  @override
  String get tool_sponge => 'स्क्रबर';

  @override
  String get tool_spray => 'बहुउद्देश्य क्लिनर';

  @override
  String get checkoutTitle => 'भुक्तानी';

  @override
  String get coupon => 'कुपन';

  @override
  String get couponNone => 'प्रयोग नगर्ने';

  @override
  String couponAvailable(String count) {
    return '$count वटा उपलब्ध';
  }

  @override
  String get paymentMethod => 'भुक्तानी विधि';

  @override
  String get addPaymentMethod => 'भुक्तानी विधि थप्नुहोस्';

  @override
  String get methodCard => 'क्रेडिट / डेबिट कार्ड';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'दर्ता भयो';

  @override
  String get methodAdded => 'भुक्तानी विधि थपियो';

  @override
  String get listPrice => 'सेवा शुल्क';

  @override
  String get discount => 'कुपन छुट';

  @override
  String get total => 'जम्मा रकम';

  @override
  String get vatIncluded => 'VAT समावेश';

  @override
  String payAmount(String amount) {
    return '$amount भुक्तानी गर्नुहोस्';
  }

  @override
  String get needMethod => 'पहिले भुक्तानी विधि दर्ता गर्नुहोस्';

  @override
  String freeCancelUntil(String date) {
    return '$date सम्म निःशुल्क रद्द';
  }

  @override
  String get doneTitle => 'बुकिङ सम्पन्न भयो!';

  @override
  String get doneBody => 'टोली तोकिनासाथ हामी तपाईंलाई खबर गर्नेछौँ';

  @override
  String get doneQuoteTitle => 'परामर्श अनुरोध प्राप्त भयो';

  @override
  String get doneQuoteBody =>
      'हाम्रो टोलीले जाँचपछि अन्तिम मूल्य अनुमान पठाउनेछ। यो परामर्श ट्याबमा हेर्न सकिन्छ।';

  @override
  String get goHome => 'होममा जानुहोस्';

  @override
  String get viewBooking => 'बुकिङ हेर्नुहोस्';

  @override
  String get bookingsTitle => 'बुकिङ';

  @override
  String get bookingsUpcoming => 'आगामी';

  @override
  String get bookingsPast => 'विगतका';

  @override
  String get bookingsEmpty => 'अहिलेसम्म कुनै बुकिङ छैन';

  @override
  String get bookingsEmptyBody => 'तपाईंको पहिलो बुकिङका लागि कुपनहरू तयार छन्';

  @override
  String get bookNow => 'सफाइ बुक गर्नुहोस्';

  @override
  String get detailTitle => 'बुकिङ विवरण';

  @override
  String get stepRequested => 'परामर्श अनुरोध';

  @override
  String get stepConfirmed => 'बुकिङ पुष्टि';

  @override
  String get stepAssigned => 'टोली तोकियो';

  @override
  String get stepCompleted => 'सफाइ सम्पन्न';

  @override
  String teamVisiting(String team) {
    return '$team भ्रमण गर्दै हुनुहुन्छ';
  }

  @override
  String get photosSoon => 'सफाइपछि अघि र पछिका फोटो यहाँ देखिनेछन्';

  @override
  String photoThumb(String n) {
    return 'फोटो $n';
  }

  @override
  String get before => 'सफाइअघि';

  @override
  String get after => 'सफाइपछि';

  @override
  String get prepCheck => 'तयारी सूची';

  @override
  String get prepAllSet => 'सबै तयार छ';

  @override
  String get visitAddress => 'भ्रमण ठेगाना';

  @override
  String get paid => 'भुक्तानी भयो';

  @override
  String get askTeam => 'हाम्रो टोलीलाई सोध्नुहोस्';

  @override
  String get cancelBooking => 'बुकिङ रद्द गर्नुहोस्';

  @override
  String get cancelTitle => 'यो बुकिङ रद्द गर्ने हो?';

  @override
  String get cancelFree =>
      'अहिले रद्द गर्दा भुक्तानी रकम पूरा फिर्ता हुनेछ र कुपन पनि फिर्ता दिइनेछ।';

  @override
  String get cancelKeep => 'राख्नुहोस्';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'अहिले रद्द गर्दा $fee शुल्क लाग्छ र $refund फिर्ता हुनेछ।';
  }

  @override
  String cancelFeeAccept(String fee) {
    return '$fee शुल्क स्वीकार गरी रद्द गर्नुहोस्';
  }

  @override
  String get cancelled => 'बुकिङ रद्द भयो';

  @override
  String get reschedule => 'मिति परिवर्तन';

  @override
  String get rescheduled => 'मिति परिवर्तन भयो';

  @override
  String get visitNotes => 'टोलीका लागि अनुरोध';

  @override
  String get notesEntry => 'भित्र कसरी पस्ने (ढोकाको कोड आदि)';

  @override
  String get notesParking => 'पार्किङ';

  @override
  String get notesOther => 'अन्य';

  @override
  String get notesSaved => 'अनुरोध सुरक्षित भयो';

  @override
  String depositDue(String amount) {
    return '$amount अग्रिम भुक्तानी गरेपछि बुकिङ पुष्टि हुन्छ';
  }

  @override
  String get payDeposit => 'अग्रिम भुक्तानी गर्नुहोस्';

  @override
  String get waitingQuote => 'परामर्श टोलीले तपाईंको मूल्य अनुमान तयार गर्दैछ';

  @override
  String get estimate => 'अनुमानित रकम';

  @override
  String get finalPrice => 'अन्तिम मूल्य अनुमान';

  @override
  String get deposit => 'अग्रिम रकम';

  @override
  String get balance => 'बाँकी रकम';

  @override
  String balanceDue(String amount) {
    return 'कृपया $amount बाँकी रकम भुक्तानी गर्नुहोस्';
  }

  @override
  String get payBalance => 'बाँकी रकम भुक्तानी गर्नुहोस्';

  @override
  String get reviewTitle => 'सफाइ कस्तो भयो?';

  @override
  String get reviewHint => 'राम्रो लागेका वा सुधार्न सकिने कुरा बताउनुहोस्';

  @override
  String ratingStars(String n) {
    return '$n अंक';
  }

  @override
  String get reviewSubmit => 'समीक्षा पठाउनुहोस्';

  @override
  String get reviewThanks => 'तपाईंको समीक्षाका लागि धन्यवाद!';

  @override
  String get bookAgain => 'फेरि बुक गर्नुहोस्';

  @override
  String get chatTitle => 'परामर्श';

  @override
  String get chatTeam => 'सहयोग टोली';

  @override
  String get chatHours => 'सोमबार–शुक्रबार ०९:००–१८:००';

  @override
  String get chatEmpty => 'कुनै प्रश्न छ? जुनसुकै बेला सोध्नुहोस्';

  @override
  String get chatNew => 'नयाँ परामर्श';

  @override
  String get chatTopicTitle => 'तपाईंलाई के जान्न मन छ?';

  @override
  String get topicOther => 'अन्य सोधपुछ';

  @override
  String get chatHint => 'सन्देश लेख्नुहोस्';

  @override
  String get chatSend => 'पठाउनुहोस्';

  @override
  String get chatPhoto => 'फोटो पठाउनुहोस्';

  @override
  String get chatTyping => 'टोली टाइप गर्दैछ';

  @override
  String get quick_confirm => 'कृपया बुकिङ पुष्टि गरिदिनुहोस्';

  @override
  String get quick_price => 'मूल्यबारे जान्न चाहन्छु';

  @override
  String get quick_date => 'मिति परिवर्तन गर्न चाहन्छु';

  @override
  String get quick_parking => 'पार्किङ उपलब्ध छ?';

  @override
  String get quick_hello => 'नमस्ते';

  @override
  String get quick_duration => 'कति समय लाग्छ?';

  @override
  String get quoteArrived => 'अन्तिम मूल्य अनुमान आइपुग्यो';

  @override
  String get quoteDepositNow => 'अहिले अग्रिम १०%';

  @override
  String get quoteBalanceLater => 'सफाइपछि बाँकी रकम';

  @override
  String get quotePay => 'अग्रिम भुक्तानी गरी पुष्टि गर्नुहोस्';

  @override
  String get quotePaid => 'भुक्तानी भयो';

  @override
  String get requestCard => 'मूल्य अनुमान अनुरोध';

  @override
  String get sys_consultation_received => 'परामर्श अनुरोध प्राप्त भयो';

  @override
  String sys_deposit_paid(String amount) {
    return '$amount अग्रिम भुक्तानी भयो। बुकिङ पुष्टि भयो।';
  }

  @override
  String get sys_booking_cancelled => 'बुकिङ रद्द भयो';

  @override
  String sys_status_changed(String status) {
    return 'स्थिति \'$status\' मा परिवर्तन भयो';
  }

  @override
  String get sys_job_completed => 'सफाइ सकियो। अघि र पछिका फोटो हेर्नुहोस्।';

  @override
  String sys_rescheduled(String date) {
    return 'मिति $date मा परिवर्तन भयो';
  }

  @override
  String get sys_reschedule_declined =>
      'पार्टनरले परिवर्तित मितिमा आउन सक्दैनन्। हाम्रो टोलीले मिलाउनेछ।';

  @override
  String get moreTitle => 'थप';

  @override
  String get moreScope => 'सेवा दायरा';

  @override
  String get morePayments => 'भुक्तानी विधि व्यवस्थापन';

  @override
  String get moreCoupons => 'कुपन';

  @override
  String get morePoints => 'सफाइ पोइन्ट';

  @override
  String get moreAccount => 'खाताको जानकारी';

  @override
  String get moreAddresses => 'ठेगाना व्यवस्थापन';

  @override
  String get moreNotices => 'सूचना';

  @override
  String get moreTips => 'सफाइका सुझाव';

  @override
  String get moreFaq => 'बारम्बार सोधिने प्रश्न';

  @override
  String get morePartner => 'पार्टनरसँग सम्पर्क';

  @override
  String get moreLanguage => 'भाषा';

  @override
  String get langSystem => 'यन्त्रको सेटिङ अनुसार';

  @override
  String moreVersion(String v) {
    return 'संस्करण $v';
  }

  @override
  String get morePrivacy => 'गोपनीयता नीति';

  @override
  String get moreTerms => 'सेवाका सर्त';

  @override
  String get moreLicenses => 'ओपन-सोर्स लाइसेन्स';

  @override
  String get logout => 'साइन आउट';

  @override
  String get deleteAccount => 'खाता मेटाउनुहोस्';

  @override
  String get deleteAccountBody =>
      'व्यक्तिगत डेटा मेटिनेछ र यो फिर्ता हुँदैन। पहिले सक्रिय बुकिङ रद्द गर्नुहोस्।';

  @override
  String get couponsEmpty => 'अहिलेसम्म कुनै कुपन छैन';

  @override
  String couponUntil(String date) {
    return '$date सम्म';
  }

  @override
  String get couponUsed => 'प्रयोग भयो';

  @override
  String get couponExpired => 'म्याद सकियो';

  @override
  String get couponAnyService => 'जुनसुकै सेवा';

  @override
  String get coupon_welcome_studio => 'स्वागत स्टुडियो कुपन';

  @override
  String get coupon_welcome_any => 'स्वागत कुपन';

  @override
  String get pointsBalance => 'तपाईंका पोइन्ट';

  @override
  String get pointsEmpty => 'पोइन्ट इतिहास छैन';

  @override
  String get accountName => 'नाम';

  @override
  String get accountPhone => 'मोबाइल';

  @override
  String get accountEmail => 'इमेल';

  @override
  String get accountLogin => 'साइन इन तरिका';

  @override
  String get accountLoginPhone => 'फोन प्रमाणीकरण';

  @override
  String get methodsEmpty => 'कुनै भुक्तानी विधि छैन';

  @override
  String get noContent => 'यहाँ अहिले केही छैन';

  @override
  String get quoteTypeTitle => 'तपाईंलाई कुन प्रकारको सफाइ चाहिन्छ?';

  @override
  String get type_standard => 'घर छाड्दाको सफाइ';

  @override
  String get type_same_day_move => 'सार्ने दिनको सफाइ';

  @override
  String get type_some_luggage_left => 'केही सामान बाँकी';

  @override
  String get type_normal_move_in => 'सामान्य घर पस्ने';

  @override
  String get type_after_interior => 'इन्टेरियर पछि';

  @override
  String get type_lived_in_deep_clean => 'बसोबासमा रहेको घरको गहिरो सफाइ';

  @override
  String get luggageTitle => 'घरमा सामानको अवस्था कस्तो छ?';

  @override
  String get luggage_empty => 'सामान छैन';

  @override
  String get luggage_partly_unpacked => 'केही सामान मिलाउँदै';

  @override
  String get luggage_fully_lived_in => 'पूर्ण रूपमा बसोबासमा';

  @override
  String get luggage_unknown => 'थाहा छैन';

  @override
  String get quoteBasicTitle => 'घरको बनोट बताउनुहोस्';

  @override
  String get buildingType => 'भवनको प्रकार';

  @override
  String get building_apartment => 'अपार्टमेन्ट';

  @override
  String get building_villa => 'भिला';

  @override
  String get building_officetel => 'अफिसटेल';

  @override
  String get building_house => 'एकल घर';

  @override
  String get building_other => 'अन्य';

  @override
  String get layoutTitle => 'बनोट';

  @override
  String get layout_studio => 'स्टुडियो';

  @override
  String get layout_one_and_half => '१.५ कोठा';

  @override
  String get layout_two_rooms => '२ कोठा';

  @override
  String get layout_three_rooms => '३ कोठा';

  @override
  String get layout_four_plus => '४ वा बढी कोठा';

  @override
  String get duplexTitle => 'यो डुप्लेक्स हो?';

  @override
  String get quoteSpaceTitle => 'ठाउँबारे अलि बताउनुहोस्';

  @override
  String get bathroomsLabel => 'बाथरुम';

  @override
  String get balconiesLabel => 'बालकोनी · युटिलिटी कोठा';

  @override
  String get elevatorTitle => 'लिफ्ट छ?';

  @override
  String get floor3Label => '३ तल वा माथि';

  @override
  String get quoteEstimateTitle => 'यो तपाईंको अनुमानित मूल्य हो';

  @override
  String get quoteEstimateBody => 'फोटो हेरेपछि परामर्शमा अन्तिम रकम तोकिन्छ';

  @override
  String get quoteG1 => 'अन्तिम रकम परामर्शमा तपाईंसँग सहमति गरेर तय हुन्छ';

  @override
  String get quoteG2 => 'पुष्टिका लागि १०% अग्रिम, बाँकी सफाइपछि';

  @override
  String get quoteG3 =>
      'पुष्टि गर्नुअघि जुनसुकै बेला निःशुल्क रद्द गर्न सकिन्छ';

  @override
  String get quoteConfirmTitle => 'तपाईंको अनुरोध जाँच गर्नुहोस्';

  @override
  String get quoteRequest => 'परामर्श अनुरोध गर्नुहोस्';

  @override
  String get quoteNoPayNow => 'अहिले भुक्तानी गर्नु पर्दैन';

  @override
  String get summaryType => 'सफाइको प्रकार';

  @override
  String get summaryHome => 'घरको जानकारी';

  @override
  String get summaryDate => 'भ्रमण मिति';

  @override
  String get cpTitle => 'रद्द नीति';

  @override
  String cpWhen(String days) {
    return 'भ्रमणभन्दा $days दिन वा सो भन्दा अगाडि';
  }

  @override
  String get cpWhenSameDay => 'भ्रमणको दिन';

  @override
  String get cpFree => 'पूरा फिर्ता';

  @override
  String cpFee(String percent, String fee, String refund) {
    return '$percent% शुल्क ($fee), फिर्ता $refund';
  }

  @override
  String get cpClosed => 'एपमा रद्द गर्न मिल्दैन (टोलीले हेर्छ)';

  @override
  String get hhTitle => 'घरपरिवारको जानकारी';

  @override
  String get hhAddPet => 'घरपालुवा जनावर थप्नुहोस्';

  @override
  String get hhPetCount => 'संख्या';

  @override
  String get hhFloorLabel => 'तला (तहखानाका लागि ऋणात्मक)';

  @override
  String get hhElevator => 'लिफ्ट छ';

  @override
  String get hhNotes => 'टिप्पणी';

  @override
  String get hhHint =>
      'यो ठेगानामा सुरक्षित हुन्छ र प्रत्येक बुकिङमा परिवर्तन गर्न सकिन्छ।';

  @override
  String get dhHomeRecommended => 'सिफारिस गरिएका सेवा';

  @override
  String get dhHomeNews => 'Dahae समाचार';

  @override
  String get dhSvcMove => 'सर्दा गरिने सरसफाइ (भित्र / बाहिर)';

  @override
  String get dhSvcMoveShort => 'घर सराइ';

  @override
  String get dhMovePickTitle => 'तपाईंलाई कुन सरसफाइ चाहिन्छ?';

  @override
  String get cKind_news => 'समाचार';

  @override
  String get cLink => 'लिङ्क (coupons, service/move_in, https://…)';

  @override
  String get welcomePackTitle => 'साइन-अप स्वागत कुपन';

  @override
  String get welcomePackBody =>
      'ग्राहकले साइन-अप पूरा गर्दा एक पटक दिइन्छ। बन्द गर्न सबै हटाउनुहोस्।';

  @override
  String get welcomePackAmount => 'कुपन रकम (KRW)';

  @override
  String get welcomePackAdd => 'कुपन थप्नुहोस्';

  @override
  String get welcomePackRemove => 'कुपन हटाउनुहोस्';

  @override
  String get themeTitle => 'थिम';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeSystem => 'सिस्टम सेटिङ';

  @override
  String get themeTip => 'थिम परिवर्तन गर्नुहोस्';

  @override
  String get err_price_changed =>
      'मूल्य परिवर्तन भयो। नयाँ कोटेसन हेरेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get err_checkout_closed =>
      'यो भुक्तानी बन्द भइसक्यो। फेरि सुरु गर्नुहोस्।';

  @override
  String get err_checkout_refunded => 'यो भुक्तानी रद्द भई रकम फिर्ता भइसक्यो।';

  @override
  String get err_already_paid => 'यो भुक्तानी पहिल्यै भइसकेको छ।';

  @override
  String get err_quote_not_payable =>
      'यो कोटेसन अहिले भुक्तानी गर्न मिल्दैन। हाम्रो टोलीसँग सम्पर्क गर्नुहोस्।';

  @override
  String get err_payment_method_disabled =>
      'यो भुक्तानी विधि अहिले उपलब्ध छैन।';

  @override
  String get err_invalid_payment_method =>
      'छानिएको भुक्तानी विधि प्रयोग गर्न मिल्दैन। अर्को छान्नुहोस्।';

  @override
  String get err_balance_not_due =>
      'ब्यालेन्स भुक्तानी गर्ने मिति अझै आएको छैन।';

  @override
  String get err_invalid_slot => 'यो सेवाको लागि त्यो समय उपलब्ध छैन।';

  @override
  String get err_booking_changed =>
      'बुकिङ परिवर्तन भयो। रिफ्रेस गरेर विवरण जाँच गर्नुहोस्।';

  @override
  String get err_booking_closed => 'यो बुकिङ अब परिवर्तन गर्न मिल्दैन।';

  @override
  String get err_reschedule_closed =>
      'अहिले भ्रमण मिति परिवर्तन गर्न मिल्दैन। हाम्रो टोलीलाई सम्पर्क गर्नुहोस्।';

  @override
  String get err_too_many_open_requests =>
      'खुला अनुरोधहरू धेरै छन्। पहिले एउटा सम्पन्न गर्नुहोस्।';

  @override
  String get err_already_reviewed =>
      'तपाईंले यो भ्रमणको समीक्षा पहिल्यै गरिसक्नुभएको छ।';

  @override
  String get err_identity_not_verified =>
      'पहिले पहिचान प्रमाणीकरण पूरा गर्नुहोस्।';

  @override
  String get err_email_taken => 'यो इमेल पहिल्यै प्रयोगमा छ।';

  @override
  String get err_invalid_email => 'इमेल ठेगाना जाँच गर्नुहोस्।';

  @override
  String get err_file_too_large =>
      'फाइल धेरै ठूलो छ। सानो फाइल अपलोड गर्नुहोस्।';

  @override
  String get err_unsupported_image =>
      'यो फोटोको ढाँचा समर्थित छैन। JPG वा PNG अपलोड गर्नुहोस्।';

  @override
  String get err_upload_quota =>
      'आजको अपलोड सीमा पुगिसक्यो। भोलि फेरि प्रयास गर्नुहोस्।';

  @override
  String get err_provider_unreachable =>
      'सेवामा जडान हुन सकेन। केही बेरपछि फेरि प्रयास गर्नुहोस्।';

  @override
  String get err_invalid_token => 'साइन इन सफल भएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get err_invalid_transition =>
      'स्थिति अहिले यसरी परिवर्तन गर्न मिल्दैन।';

  @override
  String get err_job_not_started => 'पहिले काम सुरु गर्नुहोस्।';

  @override
  String get err_job_not_active => 'यो काम सक्रिय छैन।';

  @override
  String get err_quote_locked => 'कोटेसन लक गरिएको छ, सम्पादन गर्न मिल्दैन।';

  @override
  String get err_request_closed => 'यो अनुरोध बन्द भइसकेको छ।';

  @override
  String get err_team_full => 'टोली भरिसकेको छ।';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret whsec_ बाट सुरु हुनुपर्छ।';

  @override
  String get err_invalid_endpoint => 'Endpoint https:// बाट सुरु हुनुपर्छ।';

  @override
  String get err_invalid_bucket => 'Bucket नाम मान्य छैन।';

  @override
  String get err_invalid_region => 'Region मान्य छैन।';

  @override
  String get err_invalid_retention => 'अवधारण अवधि सीमाभन्दा बाहिर छ।';

  @override
  String get err_invalid_service_account => 'Service account फाइल मान्य छैन।';

  @override
  String get err_invalid_mode => 'मान्य AI mode छान्नुहोस्।';

  @override
  String get err_invalid_model => 'AI model नाम मान्य छैन।';

  @override
  String get err_missing_field => 'आवश्यक सबै फिल्ड भर्नुहोस्।';

  @override
  String get err_invalid_amount => 'मान्य रकम प्रविष्ट गर्नुहोस्।';

  @override
  String get err_cannot_deactivate_self =>
      'तपाईं आफ्नो खाता निष्क्रिय गर्न सक्नुहुन्न।';

  @override
  String get err_invalid_coupon => 'यो कुपन मान्य छैन।';

  @override
  String get err_settlement_state => 'सेटलमेन्ट अहिले परिवर्तन गर्न मिल्दैन।';

  @override
  String get err_deposit_required => 'पहिले धरौटी रकम तिर्नुपर्छ।';

  @override
  String get err_payout_state =>
      'भुक्तानी स्थिति परिवर्तन भयो। रिफ्रेस गरेर फेरि जाँच गर्नुहोस्।';

  @override
  String get err_payout_provider => 'यो भुक्तानी विधि अहिले उपलब्ध छैन।';

  @override
  String get err_unsupported_bank => 'यो बैंकमा भुक्तानी गर्न समर्थित छैन।';

  @override
  String get err_toss_unverified =>
      'Toss भुक्तानी अहिले उपलब्ध छैन। म्यानुअल ट्रान्सफर प्रयोग गर्नुहोस्।';

  @override
  String get err_invalid_cap => 'अनुमति दिइएको दायराभित्रको संख्या लेख्नुहोस्।';

  @override
  String get err_invalid_capacity => 'मान्य क्षमता प्रविष्ट गर्नुहोस्।';

  @override
  String get err_seller_declined =>
      'Toss ले विक्रेता दर्ता स्वीकृत गरेन। व्यवसायको विवरण जाँच गर्नुहोस्।';

  @override
  String get err_payout_account_unverified =>
      'यो साझेदारसँग प्रमाणित भुक्तानी खाता छैन। पहिले खाता प्रमाणित गर्नुहोस्।';

  @override
  String get guestSheetTitle => 'जारी राख्न साइन इन गर्नुहोस्';

  @override
  String get guestSheetBody =>
      'तपाईंले भरेको सबै जानकारी सुरक्षित रहन्छ। जहाँ छाड्नुभयो त्यहीँबाट जारी रहन्छ।';

  @override
  String get greetMorning => 'सुप्रभात';

  @override
  String get greetAfternoon => 'शुभ दिउँसो';

  @override
  String get greetEvening => 'शुभ साँझ';

  @override
  String get feedHeading => 'तपाईंका लागि छनोट';

  @override
  String get feedTitleDue => 'अर्को सफाइको समय भयो';

  @override
  String get feedTitleRebook => '५ तारे पार्टनरलाई फेरि बुक गर्नुहोस्';

  @override
  String get feedTitleDraft => 'सुरु गरेको कोटेशन पूरा गर्नुहोस्';

  @override
  String get feedTitleSeasonal => 'यस मौसमका लागि उपयुक्त सफाइ';

  @override
  String get feedTitleSize => 'सुरक्षित घरको आकारअनुसार कोटेशन';

  @override
  String get feedTitleSubscription => 'सदस्यतामार्फत बढी बचत गर्नुहोस्';

  @override
  String get feedTitleDistrict => 'छिमेकीहरूले पनि बुक गरिरहेका छन्';

  @override
  String feedWhyCadence(String days) {
    return 'अन्तिम सफाइपछि $days दिन भयो';
  }

  @override
  String feedWhyRated(String days) {
    return 'तपाईंले $days दिन अघि यो पार्टनरलाई ५ तारा दिनुभएको थियो';
  }

  @override
  String get feedWhyDraft => 'यो यन्त्रमा तपाईंको कोटेशन अधूरो छ';

  @override
  String get feedWhySummer =>
      'गर्मी सुरु हुनुअघि एयरकन्डिसन सफा गर्ने राम्रो समय हो';

  @override
  String get feedWhyMoving => 'घर सर्ने र सार्ने समय व्यस्त छ';

  @override
  String feedWhyHoliday(String days) {
    return 'चाडपर्वको ठूलो सफाइसम्म $days दिन बाँकी छ';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'सुरक्षित $pyeong पियोङ घरका लागि तुरुन्त कोटेशन';
  }

  @override
  String get feedWhyRepeat => 'बारम्बार बुक गर्नुहुन्छ भने सदस्यता सस्तो पर्छ';

  @override
  String feedWhyDistrict(String district, String count) {
    return 'यो हप्ता $district मा $count घरले बुक गरे';
  }

  @override
  String get fFinance => 'वित्त';

  @override
  String get fPeriodDay => 'दिन';

  @override
  String get fPeriodWeek => 'हप्ता';

  @override
  String get fPeriodMonth => 'महिना';

  @override
  String get fPeriodCustom => 'अनुकूल';

  @override
  String get fFrom => 'देखि';

  @override
  String get fTo => 'सम्म';

  @override
  String get fGross => 'कुल बुकिङ रकम';

  @override
  String get fRefunds => 'फिर्ता';

  @override
  String get fNetRevenue => 'खुद आम्दानी';

  @override
  String get fPlatformFee => 'प्लेटफर्म शुल्क';

  @override
  String get fPaidOut => 'साझेदारलाई भुक्तानी';

  @override
  String get fPendingOut => 'भुक्तानी बाँकी';

  @override
  String get fHeldOut => 'रोकिएको';

  @override
  String get fVatEstimate => 'VAT अनुमान';

  @override
  String get fVatNote =>
      'प्लेटफर्म शुल्कको १०% अनुमान हो। लेखापालसँग पुष्टि गर्नुहोस्।';

  @override
  String get fAov => 'औसत अर्डर मूल्य';

  @override
  String get fBookings => 'बुकिङ';

  @override
  String get fCancelRate => 'रद्द दर';

  @override
  String get fDiscounts => 'छुट र कुपन';

  @override
  String get fMethods => 'भुक्तानी विधि';

  @override
  String get fTrend => 'प्रवृत्ति';

  @override
  String fRangeDays(String n) {
    return 'अन्तिम $n दिन';
  }

  @override
  String get fRangeWeeks => 'अन्तिम १२ हप्ता';

  @override
  String get fRangeMonths => 'अन्तिम १२ महिना';

  @override
  String get fByPartner => 'साझेदार अनुसार कमाइ';

  @override
  String get fByService => 'सेवा अनुसार आम्दानी';

  @override
  String get fExportTitle => 'लेखा निर्यात';

  @override
  String get fExportLedger => 'भुक्तानी खाता CSV';

  @override
  String get fExportSettlements => 'सेटलमेन्ट CSV';

  @override
  String get fExportMonthly => 'मासिक सारांश CSV (लेखापाल)';

  @override
  String get fDownload => 'CSV डाउनलोड';

  @override
  String get fDownloadWebOnly => 'CSV डाउनलोड वेब कन्सोलबाट गर्नुहोस्';

  @override
  String get fDownloadFailed => 'डाउनलोड भएन';

  @override
  String get fNoRecords => 'यस अवधिमा कुनै रेकर्ड छैन';

  @override
  String get fLoadFailed => 'वित्तीय डाटा लोड हुन सकेन';

  @override
  String get fRetry => 'फेरि प्रयास';

  @override
  String get fColPartner => 'साझेदार';

  @override
  String get fColJobs => 'संख्या';

  @override
  String get fColSettled => 'कुल सेटल';

  @override
  String get fColFee => 'शुल्क';

  @override
  String get fColNet => 'खुद';

  @override
  String get pEarnings => 'कमाइ';

  @override
  String get pNextPayout => 'अर्को भुक्तानी';

  @override
  String pNextPayoutOn(String date) {
    return '$date मा भुक्तानी';
  }

  @override
  String get pNoPayout => 'कुनै भुक्तानी तालिकामा छैन';

  @override
  String get pPendingTotal => 'भुक्तानी पर्खँदै';

  @override
  String get pPaidTotal => 'भुक्तानी भइसक्यो';

  @override
  String get pWeekly => 'साप्ताहिक';

  @override
  String get pMonthly => 'मासिक';

  @override
  String proofHomes(String count) {
    return 'यस महिना $count घर सफा गरियो';
  }

  @override
  String proofRating(String rating, String count) {
    return 'औसत $rating स्टार · $count समीक्षा';
  }

  @override
  String get proofReviewsTitle => 'हालका समीक्षा';

  @override
  String get rebookTitle => 'अघिल्लो सेवा फेरि बुक गर्ने हो?';

  @override
  String rebookBody(String service, String date) {
    return '$service · अन्तिम भ्रमण $date';
  }

  @override
  String get rebookButton => 'फेरि बुक गर्नुहोस्';

  @override
  String seatsLeft(String count) {
    return '$count स्थान बाँकी';
  }

  @override
  String get reviewSheetTitle => 'यो सफाइ कस्तो भयो?';

  @override
  String get reviewPhotosAdd => 'फोटो थप्नुहोस्';

  @override
  String get reviewPhotosHint => 'अधिकतम ५ फोटो';

  @override
  String get reviewSaved => 'समीक्षाका लागि धन्यवाद';

  @override
  String get reviewPhotoFailed => 'फोटो अपलोड भएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get referralTitle => 'साथीलाई निम्ता दिनुहोस्, कुपन पाउनुहोस्';

  @override
  String referralBody(String amount) {
    return 'साथीले पहिलो बुकिङ पूरा गर्दा तपाईं दुवैले $amount कुपन पाउनुहुन्छ';
  }

  @override
  String get referralCopy => 'कोड कपी गर्नुहोस्';

  @override
  String get referralCopied => 'रेफरल कोड कपी भयो';

  @override
  String get referralClaimTitle => 'रेफरल कोड छ?';

  @override
  String get referralClaimField => 'रेफरल कोड लेख्नुहोस्';

  @override
  String get referralClaimButton => 'लागू गर्नुहोस्';

  @override
  String get referralClaimed => 'रेफरल कोड लागू भयो';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited जनालाई निम्ता · $rewarded पुरस्कार';
  }

  @override
  String get err_self_referral => 'आफ्नै कोड प्रयोग गर्न मिल्दैन';

  @override
  String get err_referee_already_booked =>
      'पहिलो बुकिङ अघि मात्र कोड थप्न सकिन्छ';

  @override
  String get err_already_referred => 'रेफरल कोड पहिल्यै लागू भइसकेको छ';

  @override
  String get err_invalid_referral_code => 'रेफरल कोड जाँच गर्नुहोस्';

  @override
  String get err_referral_disabled => 'अहिले रेफरल रोकिएको छ';

  @override
  String get err_invalid_photos =>
      'Malkkeum मार्फत अपलोड गरिएका फोटो मात्र संलग्न गर्न सकिन्छ';

  @override
  String get welcomeOfferTitle => 'पहिलो बुकिङ छुट';

  @override
  String get welcomeOfferBody =>
      'नयाँ ग्राहकको पहिलो बुकिङमा स्वतः लागू हुन्छ। कुपनसँग मिलाइँदैन।';

  @override
  String get offerKindAmount => 'निश्चित रकम (वोन)';

  @override
  String get offerKindPercent => 'प्रतिशत (%)';

  @override
  String get offerValue => 'छुट मान';

  @override
  String get offerEnabled => 'सक्रिय';

  @override
  String get offerSaved => 'सुरक्षित भयो';

  @override
  String get referralSettingsTitle => 'रेफरल इनाम';

  @override
  String get referralSettingsBody =>
      'साथीको पहिलो बुकिङ पूरा भई भुक्तानी भएपछि दिइन्छ। आफैलाई रेफर र दोहोरिएको फोन नम्बर रोकिन्छ।';

  @override
  String get referralRewardAmount => 'इनाम रकम (वोन)';

  @override
  String get reviewsModerationTitle => 'समीक्षा व्यवस्थापन';

  @override
  String get reviewHide => 'लुकाउनुहोस्';

  @override
  String get reviewShow => 'फेरि देखाउनुहोस्';

  @override
  String get reviewHiddenTag => 'लुकाइएको';

  @override
  String get growthAverageRating => 'औसत मूल्याङ्कन';

  @override
  String growthReviewCount(String count) {
    return '$count समीक्षा';
  }

  @override
  String get growthReferralConversion => 'रेफरल रूपान्तरण';

  @override
  String get growthTab => 'वृद्धि';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$invited मध्ये $rewarded';
  }

  @override
  String get locUseCurrent => 'मेरो हालको स्थान प्रयोग गर्नुहोस्';

  @override
  String get locConsentTitle => 'स्थानमा आधारित सेवाका सर्तहरू';

  @override
  String get locConsentBody =>
      'हालको स्थानबाट ठेगाना खोज्न, कृपया स्थानमा आधारित सेवाका सर्तहरूमा सहमत हुनुहोस्। हामी तपाईंको स्थान \"मेरो हालको स्थान प्रयोग गर्नुहोस्\" थिच्दा एक पटक मात्र जाँच्छौं र ठेगाना सुझाव दिन मात्र प्रयोग गर्छौं। निर्देशांकहरू हाम्रो सर्भरमा भण्डारण गरिँदैन। तपाईं सहमति सेटिङमा जुनसुकै बेला यो सहमति फिर्ता लिन सक्नुहुन्छ।';

  @override
  String get locConsentAgree => 'सहमत भई जारी राख्नुहोस्';

  @override
  String get locSuggestionTitle => 'के यो तपाईंको ठेगाना हो?';

  @override
  String get locUseAddress => 'यो ठेगाना प्रयोग गर्नुहोस्';

  @override
  String get locDenied => 'स्थान अनुमति छैन। कृपया ठेगाना आफैं लेख्नुहोस्।';

  @override
  String get locServicesOff =>
      'यस यन्त्रको स्थान सेवा बन्द छ। कृपया ठेगाना आफैं लेख्नुहोस्।';

  @override
  String get locTimeout =>
      'स्थान पत्ता लगाउन धेरै समय लाग्यो। कृपया ठेगाना आफैं लेख्नुहोस्।';

  @override
  String get locNoAddress =>
      'तपाईंको स्थानको ठेगाना भेटिएन। कृपया ठेगाना आफैं लेख्नुहोस्।';

  @override
  String get uMaintenanceTitle => 'मर्मत हुँदैछ';

  @override
  String get uMaintenanceBody =>
      'हामी सेवा सुधार्न मर्मत गरिरहेका छौं। केही समयपछि फेरि आउनुहोस्।';

  @override
  String get cmTab => 'अभियान';

  @override
  String get cmNew => 'नयाँ अभियान';

  @override
  String get cmAudience => 'लक्षित ग्राहक';

  @override
  String get cmSegAll => 'सबै ग्राहक';

  @override
  String get cmSegNever => 'कहिल्यै बुक नगरेका';

  @override
  String cmSegLapsed(String days) {
    return 'अन्तिम बुकिङ $days+ दिन अघि';
  }

  @override
  String get cmDays => 'दिनको संख्या';

  @override
  String cmConsentCount(String total, String consented) {
    return '$total मध्ये $consented जनाले मार्केटिङ सहमति दिएका छन्';
  }

  @override
  String get cmChannel => 'च्यानल';

  @override
  String get cmPush => 'एप पुश';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'शीर्षक';

  @override
  String get cmBody => 'सन्देश';

  @override
  String get cmOptout => 'अप्ट-आउट नम्बर (080)';

  @override
  String get cmPreview => 'पूर्वावलोकन';

  @override
  String get cmSchedule => 'पठाउने समय';

  @override
  String get cmSendNow => 'अहिले पठाउनुहोस्';

  @override
  String get cmTestSend => 'मेरो नम्बरमा परीक्षण पठाउनुहोस्';

  @override
  String get cmCreate => 'अभियान सुरक्षित गर्नुहोस्';

  @override
  String get cmNeedOptout => 'SMS का लागि 080 अप्ट-आउट नम्बर आवश्यक छ';

  @override
  String get cmLog => 'पठाउने लग';

  @override
  String cmStatSent(String count) {
    return 'पठाइएको $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'सहमति छैन $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'असफल $count';
  }

  @override
  String get cmSaved => 'अभियान सुरक्षित भयो';

  @override
  String anFunnel(String days) {
    return 'दर्ता फनेल (पछिल्ला $days दिन)';
  }

  @override
  String get anInstalls => 'एप खोल्ने (सहमति दिएका)';

  @override
  String get anSignedUp => 'दर्ता गरेका';

  @override
  String get anQuoted => 'मूल्याङ्कन माग्ने';

  @override
  String get anBooked => 'बुक गरेका';

  @override
  String get anPaid => 'भुक्तानी गरेका';

  @override
  String get anRepeat => 'दोहोर्याउने (२+)';

  @override
  String get anCohorts => 'साप्ताहिक समूह (दर्ता हप्ताअनुसार बुकिङ दर)';

  @override
  String anCohortSize(String count) {
    return 'दर्ता $count';
  }

  @override
  String anWeekAfter(String n) {
    return 'हप्ता $n मा बुक';
  }

  @override
  String get cOps => 'प्रणाली स्थिति';

  @override
  String get oLevelGreen => 'सामान्य';

  @override
  String get oLevelYellow => 'जाँच गर्नुहोस्';

  @override
  String get oLevelRed => 'कारबाही चाहियो';

  @override
  String get oOverall => 'सर्भर स्थिति';

  @override
  String get oRefresh => 'ताजा गर्नुहोस्';

  @override
  String get oVersion => 'संस्करण';

  @override
  String get oUptime => 'चलेको समय';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours घण्टा $minutes मिनेट';
  }

  @override
  String get oChecks => 'जाँचहरू';

  @override
  String get oCheckDb => 'डेटाबेस';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'प्रतिक्रिया $ms ms · आकार $mb MB';
  }

  @override
  String get oCheckDisk => 'सर्भर डिस्क';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% खाली';
  }

  @override
  String get oCheckBackup => 'स्वचालित ब्याकअप';

  @override
  String oCheckBackupValue(String hours) {
    return 'अन्तिम ब्याकअप $hours घण्टा अगाडि';
  }

  @override
  String get oCheckBackupNone => 'अहिलेसम्म ब्याकअप छैन';

  @override
  String get oCheckErrors => 'सर्भर त्रुटि (२४ घण्टा)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'जाँच गर्नुपर्ने भुक्तानी';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (२४ घण्टा)';
  }

  @override
  String get oCheckWebhook => 'भुक्तानी सूचना (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'हस्ताक्षर असफल $count (२४ घण्टा)';
  }

  @override
  String get oIntegrations => 'बाह्य सेवाहरू';

  @override
  String get oIntNotSet => 'सेटअप भएको छैन';

  @override
  String oIntLastOk(String at) {
    return 'अन्तिम सफलता $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'अन्तिम असफलता $at ($code)';
  }

  @override
  String get oIntNever => 'अहिलेसम्म प्रयोग भएको छैन';

  @override
  String get oActDb =>
      'डेटाबेससँग जडान हुन सकेन। सर्भरमा malkkeum logs चलाउनुहोस्; जारी रहेमा पुनः सुरु गर्नुहोस्।';

  @override
  String get oActDisk =>
      'डिस्कमा १०% भन्दा कम खाली ठाउँ छ। पुराना ब्याकअप मेटाउनुहोस् वा डिस्क थप्नुहोस्।';

  @override
  String get oActBackup =>
      'स्वचालित ब्याकअप ढिलो भएको छ। सर्भरमा malkkeum backup चलाउनुहोस् र backups/backup.log हेर्नुहोस्।';

  @override
  String get oActErrors =>
      'सर्भर त्रुटि धेरै छन्। malkkeum logs मा error लाइनहरू हेर्नुहोस्; दोहोरिए विकासकर्तालाई पठाउनुहोस्।';

  @override
  String get oActPayments =>
      'भुक्तानी भएको हुन सक्छ तर स्वचालित रूपमा प्रशोधन भएको छैन। PortOne मा जाँच गर्नुहोस् र आवश्यक परे म्यानुअल रिफन्ड गर्नुहोस्।';

  @override
  String get oActWebhook =>
      'भुक्तानी सूचनाको हस्ताक्षर जाँच असफल भयो। सेटअप > भुक्तानी (PortOne) मा webhook secret फेरि राख्नुहोस्।';

  @override
  String get oActIntegration =>
      'यो जडान असफल भइरहेको छ। सेटअपमा कुञ्जीहरू जाँच गरी Test connection थिच्नुहोस्।';

  @override
  String get oActNotSet =>
      'अहिलेसम्म सेटअप भएको छैन। सेटअपमा कुञ्जी राख्नुहोस्।';

  @override
  String get oAlerts => 'सूचना सेटिङ';

  @override
  String get oAlertsHint =>
      'समस्या भएमा इनबक्स र मालिकको फोनमा SMS पठाइन्छ। उही समस्या हरेक ६ घण्टामा एक पटक मात्र पठाइन्छ।';

  @override
  String get oRuleSms => 'SMS पठाउन असफल';

  @override
  String get oRulePush => 'पुश सूचना असफल';

  @override
  String get oRulePayment => 'भुक्तानी जडान असफल';

  @override
  String get oRuleStuck => 'भुक्तानी स्वचालित रूपमा प्रशोधन भएन';

  @override
  String get oRuleSocial => 'सामाजिक लगइन असफल';

  @override
  String get oRuleBackup => 'स्वचालित ब्याकअप छुट्यो';

  @override
  String get oRuleDisk => 'डिस्क लगभग भरियो';

  @override
  String get oRuleAuth => 'शंकास्पद लगइन गतिविधि';

  @override
  String get oQuietHours => 'शान्त समय';

  @override
  String get oQuietFrom => 'सुरु';

  @override
  String get oQuietTo => 'सम्म';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'यो समयमा सूचना पठाइँदैन; समाप्त भएपछि एक पटक पठाइन्छ।';

  @override
  String get oAlertPhone => 'सूचना पाउने फोन';

  @override
  String get oAlertPhoneHint =>
      'खाली छोडे व्यवसाय जानकारीमा भएको सहायता नम्बरमा पठाइन्छ।';

  @override
  String get oSave => 'सेभ';

  @override
  String get oSaved => 'सूचना सेटिङ सेभ भयो';

  @override
  String get oSaveFailed => 'सेभ गर्न सकिएन। मानहरू जाँच गर्नुहोस्।';

  @override
  String get oLoadFailed => 'स्थिति लोड गर्न सकिएन';

  @override
  String get oBackupOffsite => 'बाह्य ब्याकअप (S3)';

  @override
  String get oBackupOffsiteOff => 'बन्द छ। सेटअप > बाह्य ब्याकअपमा खोल्नुहोस्।';

  @override
  String get oLastBackup => 'अन्तिम ब्याकअप';

  @override
  String get oDiskFree => 'खाली ठाउँ';

  @override
  String get oNoData => 'अहिलेसम्म डेटा छैन';

  @override
  String get cIntBackup => 'बाह्य ब्याकअप (S3-सँग मिल्ने)';

  @override
  String get pTabJobs => 'काम';

  @override
  String get pTabQuotes => 'मेरा मूल्य अनुमान';

  @override
  String get pTabSchedule => 'तालिका';

  @override
  String get pIntroTitle => 'सफाइ विज्ञहरूका लागि\nकाम · तालिका · भुक्तानी';

  @override
  String get pIntroBody =>
      'तपाईंले चाहनु भएको ठाउँ र समयमा मात्र काम गर्नुहोस्, साप्ताहिक भुक्तानी पाउनुहोस्।';

  @override
  String get pOnbTitle => 'पार्टनरको जानकारी दिनुहोस्';

  @override
  String get pOnbName => 'प्रमुखको नाम';

  @override
  String get pOnbTeam => 'टोलीको नाम';

  @override
  String get pOnbServices => 'तपाईंले दिन सक्ने सेवा';

  @override
  String get pOnbAreas => 'काम गर्ने क्षेत्र';

  @override
  String get pOnbDone => 'आवेदन पठाउनुहोस्';

  @override
  String get pPendingTitle => 'स्वीकृतिको पर्खाइमा छ';

  @override
  String get pPendingBody =>
      'स्वीकृत भएपछि हामी सूचना पठाउनेछौँ। तबसम्म भुक्तानी खाता दर्ता गर्नुहोस्।';

  @override
  String get pSuspended =>
      'तपाईंको खाता अस्थायी रूपमा रोकिएको छ। कृपया सञ्चालन टोलीलाई सम्पर्क गर्नुहोस्।';

  @override
  String get pDirect => 'सिधा बुकिङ';

  @override
  String get pQuoteReq => 'मूल्य अनुमान अनुरोध';

  @override
  String get pShowClosed => 'बन्द भएका काम पनि देखाउनुहोस्';

  @override
  String get pSortNewest => 'नयाँ अनुरोध पहिले';

  @override
  String get pSortVisit => 'नजिकको भ्रमण मिति पहिले';

  @override
  String get pSortAmount => 'उच्च रकम पहिले';

  @override
  String get pNoJobs => 'अहिले मिल्ने कुनै काम छैन';

  @override
  String get pNoJobsBody =>
      'सेवा, क्षेत्र वा कामका घण्टा फराकिलो पार्दा थप काम देख्न सक्नुहुन्छ';

  @override
  String get pPayout => 'अनुमानित भुक्तानी';

  @override
  String get pCustomerEstimate => 'ग्राहकको अनुमानित मूल्य';

  @override
  String get pNew => 'नयाँ';

  @override
  String get pClosed => 'बन्द';

  @override
  String get pPrivacyNote =>
      'सटीक ठेगाना र ग्राहकको विवरण स्वीकार गरेपछि देखिन्छ';

  @override
  String get pAccept => 'काम स्वीकार गर्नुहोस्';

  @override
  String get pAcceptConfirm => 'यो काम स्वीकार गर्ने हो?';

  @override
  String get pAcceptBody =>
      'स्वीकार गर्दा यो तपाईंको तालिकामा थपिनेछ र ग्राहकलाई टोली तोकिएको सूचना जानेछ। भ्रमणको २ दिनअघिदेखि रद्द गर्न कठिन हुन्छ।';

  @override
  String get pAccepted => 'काम स्वीकार गरियो';

  @override
  String get pSendQuote => 'मूल्य अनुमान पठाउनुहोस्';

  @override
  String get pQuotePrice => 'ग्राहकको भुक्तानी रकम';

  @override
  String get pQuoteNote => 'टोलीलाई दिने नोट';

  @override
  String get pQuoteSent => 'मूल्य अनुमान पठाइयो';

  @override
  String pFee(String rate) {
    return 'शुल्क $rate%';
  }

  @override
  String get pYouGet => 'तपाईंले पाउने रकम';

  @override
  String get pQuoteAll => 'सबै';

  @override
  String get pQ_waiting => 'पर्खाइमा';

  @override
  String get pQ_selected => 'चयन भयो';

  @override
  String get pQ_rejected => 'चयन भएन';

  @override
  String get pQ_closed => 'बन्द';

  @override
  String get pUnseenOnly => 'नयाँ नतिजा मात्र';

  @override
  String get pNoQuotes => 'कुनै मूल्य अनुमान छैन';

  @override
  String get pMyQuote => 'मेरो मूल्य अनुमान';

  @override
  String get pWithdraw => 'मूल्य अनुमान फिर्ता लिनुहोस्';

  @override
  String get pWithdrawn => 'मूल्य अनुमान फिर्ता लियो';

  @override
  String get pOnlyMine => 'मेरो मात्र';

  @override
  String pJobsCount(String n) {
    return '$n वटा काम';
  }

  @override
  String get pNoSchedule => 'यस दिन कुनै तालिका छैन';

  @override
  String get pCancelledBanner =>
      'ग्राहकले यो काम रद्द गर्नुभएको छ। सम्पन्न चिन्ह लगाउन सकिँदैन।';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'मिति परिवर्तन अनुरोध: $from → $to';
  }

  @override
  String get pRescheduleOk => 'आउन सक्छु';

  @override
  String get pRescheduleNo => 'आउन सक्दिन';

  @override
  String get pCustomer => 'ग्राहक';

  @override
  String get pCall => 'सुरक्षित नम्बरमा फोन';

  @override
  String get pCallSoon => 'सेवा सुरु हुँदा सुरक्षित कल सक्रिय हुनेछ';

  @override
  String get pQuietHours => 'राति ८ बजेपछि फोन नगर्नुहोस्';

  @override
  String get pAssignee => 'जिम्मेवार व्यक्ति';

  @override
  String get pChangeAssignee => 'जिम्मेवार व्यक्ति परिवर्तन';

  @override
  String get pCustomerRequests => 'ग्राहकका अनुरोध';

  @override
  String get pHousehold => 'घरपरिवारको जानकारी';

  @override
  String get pPets => 'घरपालुवा जनावर';

  @override
  String get pPetDog => 'कुकुर';

  @override
  String get pPetCat => 'बिरालो';

  @override
  String get pPetBird => 'चरा';

  @override
  String get pPetFish => 'माछा';

  @override
  String get pPetOther => 'अन्य जनावर';

  @override
  String get pAllergies => 'एलर्जी र संवेदनशीलता';

  @override
  String get pPreferredProducts => 'मनपर्ने उत्पादन';

  @override
  String get pParking => 'पार्किङ';

  @override
  String pFloor(String floor) {
    return '$floor तला';
  }

  @override
  String get pElevatorYes => 'लिफ्ट छ';

  @override
  String get pElevatorNo => 'लिफ्ट छैन';

  @override
  String get pTeamMemo => 'टोली नोट (ग्राहकले देख्दैनन्)';

  @override
  String get pMemoSaved => 'नोट सुरक्षित भयो';

  @override
  String get pPayoutBreakdown => 'भुक्तानी विवरण';

  @override
  String get pAfterBalance => 'ग्राहकले बाँकी रकम तिरेपछि भुक्तानी हुन्छ';

  @override
  String get pChatOps => 'सञ्चालन टोलीसँग कुराकानी';

  @override
  String get pComplete => 'काम सम्पन्न जनाउनुहोस्';

  @override
  String get pBeforePhotos => 'सफाइअघिका फोटो';

  @override
  String get pAfterPhotos => 'सफाइपछिका फोटो';

  @override
  String get pAddPhoto => 'फोटो थप्नुहोस्';

  @override
  String get pChecklist => 'जाँच सूची';

  @override
  String get pCheck1 => 'अनुरोध गरिएका सबै ठाउँ सफा गरियो';

  @override
  String get pCheck2 => 'फोहोर व्यवस्थापन गरियो र सामान सङ्कलन गरियो';

  @override
  String get pCheck3 => 'झ्याल, बिजुली र पानी जाँच गरियो';

  @override
  String get pCheck4 => 'ग्राहकका अनुरोध पूरा गरियो';

  @override
  String get pCompleteCta => 'सम्पन्न चिन्ह लगाउनुहोस्';

  @override
  String get pCompleteNeed =>
      'हरेक प्रकारको कम्तीमा १ फोटो राख्नुहोस् र सबै वस्तु जाँच गर्नुहोस्';

  @override
  String get pCompleted => 'उत्कृष्ट काम!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$date मा $amount भुक्तानी हुनेछ';
  }

  @override
  String get pPayoutWaiting =>
      'ग्राहकले बाँकी रकम तिरेपछि भुक्तानी मिति तय हुन्छ';

  @override
  String get pPendingPayout => 'भुक्तानी पर्खाइमा रकम';

  @override
  String get pSettlements => 'भुक्तानी विवरण';

  @override
  String get pS_waiting_balance => 'बाँकी रकम पर्खाइमा';

  @override
  String get pS_pending => 'तालिकामा';

  @override
  String get pS_paid => 'भुक्तानी भयो';

  @override
  String get pS_held => 'रोकिएको';

  @override
  String get pReviews => 'ग्राहक समीक्षा';

  @override
  String get pNoReviews => 'अहिलेसम्म कुनै समीक्षा छैन';

  @override
  String get pReplyLater => 'समीक्षामा जवाफ दिने सुविधा चाँडै आउँदैछ';

  @override
  String get pServicesAreas => 'सेवा · क्षेत्र';

  @override
  String get pPayoutAccount => 'भुक्तानी बैंक खाता';

  @override
  String get pBank => 'बैंक';

  @override
  String get pAccountNumber => 'खाता नम्बर';

  @override
  String get pHolder => 'खाता धनी';

  @override
  String get pVerified => 'पुष्टि भयो';

  @override
  String get pUnverified => 'जाँच हुँदैछ';

  @override
  String get pAccountSaved =>
      'खाता सुरक्षित भयो। परिवर्तन गर्दा फेरि जाँच हुन्छ।';

  @override
  String get pWorkSchedule => 'कामको तालिका';

  @override
  String get pWeekdays => 'कामका दिन';

  @override
  String get pDayParts => 'कामका समय';

  @override
  String get pDaysOff => 'बिदाका दिन';

  @override
  String get pAddDayOff => 'बिदाको दिन थप्नुहोस्';

  @override
  String get pSaved => 'सुरक्षित भयो';

  @override
  String get pTeam => 'टोली सदस्य';

  @override
  String get pOwner => 'प्रमुख';

  @override
  String get pInvited => 'निमन्त्रणा पठाइयो';

  @override
  String get pInvite => 'टोली सदस्य निम्तो दिनुहोस्';

  @override
  String get pInviteSent => 'निमन्त्रणा सन्देश पठाइयो';

  @override
  String get pRemove => 'हटाउनुहोस्';

  @override
  String get pNotifications => 'सूचना सेटिङ';

  @override
  String get pNotifyDirect => 'नयाँ सिधा बुकिङ काम';

  @override
  String get pNotifyQuotes => 'मूल्य अनुमान अनुरोध · नतिजा';

  @override
  String get pNotifyChat => 'सञ्चालन टोलीका सन्देश';

  @override
  String get pQuietNight => 'राति शान्त समय (२२–०८)';

  @override
  String get pNewInquiry => 'नयाँ सोधपुछ';

  @override
  String get pTopic_settlement => 'भुक्तानी';

  @override
  String get pTopic_reschedule => 'मिति परिवर्तन · रद्द';

  @override
  String get pTopic_app => 'एप सहायता';

  @override
  String get pOpsTeam => 'सञ्चालन टोली';

  @override
  String get pViewJob => 'काम हेर्नुहोस्';

  @override
  String pBookingNo(String n) {
    return 'बुकिङ $n';
  }

  @override
  String get pSize => 'क्षेत्रफल';

  @override
  String get pSchedule => 'तालिका';

  @override
  String get pSpace => 'ठाउँको जानकारी';

  @override
  String get pNavigate => 'दिशानिर्देश';

  @override
  String get pNavHint =>
      'नक्सा एपमा भ्रमण ठेगाना खुल्छ। एप नभए वेब नक्सा खुल्छ।';

  @override
  String get pOfflineSaved => 'सिग्नल छैन। सुरक्षित गरियो, जडान भएपछि पठाइनेछ।';

  @override
  String get pPhotoRetry => 'फेरि अपलोड';

  @override
  String get pPhotoWaiting => 'अपलोड नभएका फोटोहरू जडान भएपछि स्वतः पठाइनेछन्।';

  @override
  String pUploadedCount(String total, String done) {
    return '$total मध्ये $done अपलोड';
  }

  @override
  String get apPgPickMethod => 'भुक्तानी विधि छान्नुहोस्';

  @override
  String get apPgConfirmTitle => 'भुक्तानी जाँच गर्नुहोस्';

  @override
  String get apPgConfirmBtn => 'भुक्तानी पुष्टि गर्नुहोस्';

  @override
  String get apPgProcessing => 'भुक्तानी प्रशोधन हुँदैछ…';

  @override
  String get apPgDoneTitle => 'भुक्तानी सम्पन्न भयो';

  @override
  String get apPgReceiptTitle => 'इलेक्ट्रोनिक रसिद';

  @override
  String get apPgReceiptApproval => 'स्वीकृति नम्बर';

  @override
  String get apPgReceiptMethod => 'विधि';

  @override
  String get apPgReceiptAmount => 'रकम';

  @override
  String get apPgReceiptDone => 'सम्पन्न';

  @override
  String get apPgVaIssued => 'भर्चुअल खाता जारी भयो (परीक्षण खाता)';

  @override
  String get apPgTestBadge => 'परीक्षण';

  @override
  String get cIntPayout => 'साझेदार भुक्तानी';

  @override
  String get poTabSettlements => 'सेटलमेन्ट';

  @override
  String get poTabPayouts => 'भुक्तानी';

  @override
  String get poState_requested => 'अनुरोध गरिएको';

  @override
  String get poState_sent => 'पठाइयो';

  @override
  String get poState_paid => 'भुक्तानी भयो';

  @override
  String get poState_failed => 'असफल';

  @override
  String get poProviderManual => 'म्यानुअल ट्रान्सफर';

  @override
  String get poProviderToss => 'Toss मार्फत भुक्तानी';

  @override
  String get poShowAccount => 'खाता देखाउनुहोस्';

  @override
  String get poAccountTitle => 'ट्रान्सफर विवरण';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '$holder · $bank · $account मा $amount वोन पठाउनुहोस्, त्यसपछि पुष्टि थिच्नुहोस्।';
  }

  @override
  String get poConfirmPaid => 'ट्रान्सफर भएको चिन्ह लगाउनुहोस्';

  @override
  String get poMarkFailed => 'असफल चिन्ह लगाउनुहोस्';

  @override
  String get poReasonTitle => 'असफलताको कारण';

  @override
  String get poReasonHint => 'जस्तै: गलत खाता, ट्रान्सफर रद्द';

  @override
  String get poSend => 'Toss मार्फत पठाउनुहोस्';

  @override
  String get poSync => 'स्थिति जाँच गर्नुहोस्';

  @override
  String get poRetry => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get poNoPayouts => 'अहिलेसम्म कुनै भुक्तानी छैन';

  @override
  String poRequestedToast(String n) {
    return '$n भुक्तानी अनुरोध सिर्जना गरियो';
  }

  @override
  String get poReasonRequired => 'कारण लेख्नुहोस्';

  @override
  String get poRevealNote => 'खाता विवरण हेर्ने कार्य लग गरिन्छ';

  @override
  String get poSellerAction => 'विक्रेता दर्ता गर्नुहोस्';

  @override
  String get poSellerTitle => 'Toss विक्रेताको रूपमा दर्ता गर्नुहोस्';

  @override
  String get poSellerHint =>
      'साझेदारको प्रमाणित भुक्तानी खाता प्रयोग हुन्छ। व्यवसायको विवरण मात्र भर्नुहोस्।';

  @override
  String get poSellerIndividual => 'व्यक्तिगत';

  @override
  String get poSellerCompany => 'व्यवसाय';

  @override
  String get poSellerName => 'नाम';

  @override
  String get poSellerRepresentative => 'प्रतिनिधिको नाम';

  @override
  String get poSellerRegNo => 'व्यवसाय दर्ता नम्बर (१० अंक)';

  @override
  String get poSellerEmail => 'भुक्तानी इमेल';

  @override
  String get poSellerPhone => 'फोन';

  @override
  String get poSellerSubmit => 'दर्ता गर्नुहोस्';

  @override
  String poSellerDone(String status) {
    return 'विक्रेता स्थिति: $status';
  }

  @override
  String get oFlags => 'सुविधा स्विच';

  @override
  String get oFlagBooking => 'बुकिङ';

  @override
  String get oFlagChat => 'च्याट';

  @override
  String get oFlagAi => 'AI सहायक';

  @override
  String get oFlagPayments => 'भुक्तानी';

  @override
  String get oMaintenance => 'मर्मत मोड';

  @override
  String get oMaintenanceHint =>
      'खुला हुँदा ग्राहक र साझेदार एपमा मर्मत स्क्रिन देखिन्छ। कन्सोल चलिरहन्छ।';

  @override
  String get oMaintenanceMessage => 'मर्मत सूचना';

  @override
  String get oClientErrors => 'एप त्रुटि रिपोर्ट';

  @override
  String get oClientErrorsHint =>
      'वेब, Windows र कन्सोलबाट भर्खरका त्रुटिहरू। व्यक्तिगत जानकारी स्वतः लुकाइन्छ।';

  @override
  String get oClientErrorsEmpty => 'हालैका त्रुटि छैनन्';

  @override
  String get oHeartbeat => 'अपटाइम हार्टबिट';

  @override
  String get oHeartbeatOn =>
      'जडान भयो। सर्भर चल्दा बाहिरी सेवालाई सूचना जान्छ।';

  @override
  String get oHeartbeatOff =>
      'सेट गरिएको छैन: install.sh मा MALKKEUM_HEARTBEAT_URL थप्नुहोस्।';

  @override
  String get pvManage => 'सहमति व्यवस्थापन';

  @override
  String get pvOptional => 'ऐच्छिक';

  @override
  String get pvTerms => 'सेवा सर्तहरूमा सहमति';

  @override
  String get pvPrivacy => 'व्यक्तिगत डेटा सङ्कलन र प्रयोगमा सहमति';

  @override
  String get pvOverseas => 'व्यक्तिगत डेटा विदेश पठाउने सहमति';

  @override
  String get pvMarketing => 'मार्केटिङ सन्देश';

  @override
  String get pvMarketingHint =>
      'कुपन र कार्यक्रमका समाचार SMS, KakaoTalk र एप पुशमार्फत पाउनुहुनेछ। जुनसुकै बेला बन्द गर्न सकिन्छ।';

  @override
  String get pvReconsent =>
      'हाम्रो गोपनीयता नीति परिवर्तन भएको छ। कृपया फेरि समीक्षा गरी सहमति दिनुहोस्।';

  @override
  String get pvSaved => 'सहमति सेटिङ सुरक्षित गरियो';

  @override
  String get pvExport => 'मेरो डेटा डाउनलोड गर्नुहोस्';

  @override
  String get pvExportHint =>
      'हामीसँग तपाईंबारे भएका सबै डेटा JSON मा देखाइन्छ। कपी गरेर राख्न सकिन्छ।';

  @override
  String get pvCopy => 'कपी गर्नुहोस्';

  @override
  String get pvCopied => 'कपी गरियो';

  @override
  String get pvExportFailed =>
      'तपाईंको डेटा लोड गर्न सकिएन। कृपया पछि फेरि प्रयास गर्नुहोस्।';

  @override
  String get safetyEmergency => 'आपतकालीन सम्पर्क';

  @override
  String get emergencyPolice => '112 प्रहरी';

  @override
  String get emergencyFire => '119 दमकल र उद्धार';

  @override
  String get emergencyShop => 'ग्राहक सेवा';

  @override
  String get caseReportAction => 'समस्या रिपोर्ट गर्नुहोस्';

  @override
  String get caseReportTitle => 'के भयो?';

  @override
  String get caseKindDamage => 'क्षति';

  @override
  String get caseKindLoss => 'हराएको';

  @override
  String get caseKindComplaint => 'गुनासो';

  @override
  String get caseKindNoShow => 'सफाइकर्मी आएनन्';

  @override
  String get caseKindSafety => 'सुरक्षा चिन्ता';

  @override
  String get caseKindPayment => 'भुक्तानी विवाद';

  @override
  String get caseSummaryHint => 'के भयो वर्णन गर्नुहोस् (300 अक्षरसम्म)';

  @override
  String get caseSubmit => 'पेश गर्नुहोस्';

  @override
  String get caseSubmitted => 'प्राप्त भयो। टोलीले २४ घण्टाभित्र जवाफ दिनेछ।';

  @override
  String get caseFailed => 'पठाउन सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get checkInAction => 'चेक इन';

  @override
  String get checkOutAction => 'चेक आउट';

  @override
  String checkedInAt(String time) {
    return 'आइपुग्यो $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'निस्कियो $time';
  }

  @override
  String get entryCodeAction => 'प्रवेश कोड देखाउनुहोस्';

  @override
  String get entryCodeTitle => 'प्रवेश कोड';

  @override
  String get entryCodeNotToday => 'भ्रमणको दिनमा मात्र देखिन्छ';

  @override
  String get entryCodeEmpty => 'प्रवेश कोड दर्ता छैन';

  @override
  String get actionFailed => 'सम्पन्न गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get consoleCasesTitle => 'केस सूची';

  @override
  String get consoleCasesEmpty => 'कुनै खुला केस छैन';

  @override
  String get caseOverdue => 'म्याद नाघेको';

  @override
  String get caseStatusOpen => 'खुला';

  @override
  String get caseStatusInvestigating => 'अनुसन्धानमा';

  @override
  String get caseStatusResolved => 'समाधान भयो';

  @override
  String get caseStatusRejected => 'अस्वीकृत';

  @override
  String get caseReassign => 'साझेदार पुनः तोक्नुहोस्';

  @override
  String get caseRefund => 'रिफन्ड';

  @override
  String get caseHold => 'भुक्तानी रोक्नुहोस्';

  @override
  String get caseNoteHint => 'आन्तरिक टिप्पणी';

  @override
  String get caseSave => 'सेभ गर्नुहोस्';

  @override
  String get cSetup => 'सेटअप';

  @override
  String get cSetupTitle => 'सुरु गर्न तयारी';

  @override
  String cSetupProgress(String done, String total) {
    return '$total मध्ये $done पूरा';
  }

  @override
  String get cSetupAllDone => 'सबै तयार छ!';

  @override
  String get cSetupBusiness => 'व्यवसाय विवरण';

  @override
  String get cSetupBusinessName => 'सेवाको नाम';

  @override
  String get cSetupSupportPhone => 'सहायता फोन';

  @override
  String get cSetupSupportEmail => 'सहायता इमेल';

  @override
  String get cSetupSupportHours => 'सहायता समय';

  @override
  String get cSetupColor => 'ब्रान्ड रङ';

  @override
  String get cSetupLogo => 'लोगो अपलोड';

  @override
  String get cSetupCompany => 'कम्पनी विवरण (एप र वेबसाइटको तल देखिन्छ)';

  @override
  String get cSetupLegalName => 'कानुनी नाम';

  @override
  String get cSetupCeo => 'प्रतिनिधि';

  @override
  String get cSetupRegNo => 'दर्ता नम्बर';

  @override
  String get cSetupMailOrderNo => 'अनलाइन बिक्री दर्ता नम्बर';

  @override
  String get cSetupAddress => 'ठेगाना';

  @override
  String get cSetupPrivacyOfficer => 'गोपनीयता अधिकारी';

  @override
  String get cSetupStoreLinks =>
      'एप स्टोर लिङ्क (भरेपछि वेबसाइटका बटन सक्रिय हुन्छन्)';

  @override
  String get cSetupCustomerApp => 'ग्राहक एप';

  @override
  String get cSetupPartnerApp => 'साझेदार एप';

  @override
  String get cSetupPayMethods => 'भुक्तानी विधि';

  @override
  String get cSetupPayMethodsHint =>
      'ग्राहकले देख्ने भुक्तानी विधि खोल्नुहोस् वा बन्द गर्नुहोस्। तुरुन्तै लागू हुन्छ।';

  @override
  String get cReviewTitle => 'स्टोर समीक्षाका लागि डेमो खाता';

  @override
  String get cReviewHint =>
      'समीक्षकले कोरियाली SMS पाउँदैनन्। यो नम्बर र ६ अङ्कको कोड समीक्षा नोटमा लेख्नुहोस्। आफैं बन्द हुन्छ।';

  @override
  String get cReviewPhone => 'डेमो फोन नम्बर';

  @override
  String get cReviewCode => 'स्थिर कोड (६ अङ्क)';

  @override
  String cReviewActiveUntil(String date) {
    return '$date सम्म सक्रिय';
  }

  @override
  String get cReviewEnable => 'सक्रिय (१४ दिन)';

  @override
  String get pDeleteAccountBody =>
      'तपाईंको टोली र व्यक्तिगत विवरण स्थायी रूपमा मेटिन्छ। पहिले तोकिएका काम र बाँकी भुक्तानी पूरा गर्नुहोस्।';

  @override
  String get err_has_active_jobs =>
      'तपाईंसँग तोकिएका काम बाँकी छन्। पूरा गर्नुहोस् वा सहायतालाई हस्तान्तरण गर्न भन्नुहोस्।';

  @override
  String get err_pending_payouts =>
      'भुक्तानी बाँकी छ। भुक्तानीपछि खाता मेटाउन सकिन्छ।';

  @override
  String get err_phone_required => 'काम लिनु अघि फोन नम्बर प्रमाणित गर्नुहोस्।';

  @override
  String get nAlerts => 'सूचना';

  @override
  String get nEmpty => 'अहिलेसम्म सूचना छैन';

  @override
  String nUnread(String count) {
    return '$count नपढिएका सूचना';
  }

  @override
  String get pVerifyPhone => 'प्रमाणित गर्नुहोस्';

  @override
  String get mMyJobs => 'मेरा काम';

  @override
  String get mNoJobs =>
      'अहिले कुनै काम तोकिएको छैन। टोली प्रमुखले तोकेपछि यहाँ देखिन्छ।';

  @override
  String mTeam(String team) {
    return '$team सदस्य';
  }

  @override
  String get cSetupSave => 'सेभ';

  @override
  String get cSetupSaved => 'सेभ भयो';

  @override
  String get cSetupTest => 'जडान जाँच';

  @override
  String get cSetupClear => 'विच्छेद';

  @override
  String get cSetupConnected => 'जडान भयो';

  @override
  String get cSetupNotConnected => 'जडान छैन';

  @override
  String get cSetupFromEnv => 'सर्भर सेटिङ प्रयोगमा';

  @override
  String get cSetupCheckInApp => 'सेभ भयो · एपबाट लगइन गरेर पुष्टि गर्नुहोस्';

  @override
  String get cSetupInvalidKey =>
      'कुञ्जी अस्वीकार भयो। कपी गरेको मान जाँच्नुहोस्';

  @override
  String get cSetupUnreachable =>
      'सेवामा पुग्न सकिएन। केही बेरपछि प्रयास गर्नुहोस्';

  @override
  String get cSetupKeepValue => 'सेभ गरिएको (बदल्न मात्र लेख्नुहोस्)';

  @override
  String get cSetupGuide => 'कसरी सेटअप गर्ने';

  @override
  String get cSetupOpenSite => 'साइट खोल्नुहोस्';

  @override
  String get cSetupWebhook => 'Webhook ठेगाना (PortOne कन्सोलमा टाँस्नुहोस्)';

  @override
  String get cCopied => 'कपी भयो';

  @override
  String get cSetupDevMode => 'परीक्षण मोड: वास्तविक भुक्तानी वा सन्देश जाँदैन';

  @override
  String get cSetupOptional => 'ऐच्छिक';

  @override
  String get cIntPortone => 'भुक्तानी (PortOne)';

  @override
  String get cIntSolapi => 'SMS र KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'एप सूचना (Firebase)';

  @override
  String get cIntKakao => 'Kakao लगइन';

  @override
  String get cIntNaver => 'Naver लगइन';

  @override
  String get cIntGoogle => 'Google लगइन';

  @override
  String get cIntApple => 'Apple लगइन';

  @override
  String get cFirstRunTitle => 'स्वागत छ! मालिकको खाता बनाउनुहोस्';

  @override
  String get cFirstRunBody =>
      'स्थापना गर्दा देखिएको १२ अक्षरको कोड लेख्नुहोस्। यो खाताले सबै सेटिङ व्यवस्थापन गर्छ।';

  @override
  String get cFirstRunCode => 'सेटअप कोड';

  @override
  String get cName => 'नाम';

  @override
  String get cFirstRunCreate => 'खाता बनाएर सुरु गर्नुहोस्';

  @override
  String get cWrongSetupCode => 'सेटअप कोड मिलेन';

  @override
  String get cWeakPassword => 'पासवर्ड कम्तीमा १२ अक्षरको हुनुपर्छ';

  @override
  String get cInvalidValue => 'कृपया मान जाँच्नुहोस्';

  @override
  String get cMfaTitle => 'दुई-चरण साइन-इन';

  @override
  String get cMfaCode => 'प्रमाणिकरण एपबाट ६ अंकको कोड';

  @override
  String get cMfaRecovery => 'रिकभरी कोड';

  @override
  String get cMfaUseRecovery => 'बरु रिकभरी कोड प्रयोग गर्नुहोस्';

  @override
  String get cMfaUseCode => 'बरु प्रमाणिकरण एपको कोड प्रयोग गर्नुहोस्';

  @override
  String get cMfaVerify => 'प्रमाणित गर्नुहोस्';

  @override
  String get cMfaBack => 'साइन-इनमा फर्कनुहोस्';

  @override
  String get cMfaEnrolTitle => 'दुई-चरण साइन-इन सेटअप गर्नुहोस्';

  @override
  String get cMfaEnrolBody =>
      'एडमिनलाई प्रमाणिकरण एप चाहिन्छ। तलको कुञ्जी Google Authenticator, 1Password वा त्यस्तै एपमा थप्नुहोस्, त्यसपछि देखिएको ६ अंकको कोड हाल्नुहोस्।';

  @override
  String get cMfaSecret => 'सेटअप कुञ्जी';

  @override
  String get cMfaLink => 'सेटअप लिङ्क (otpauth)';

  @override
  String get cMfaCopy => 'प्रतिलिपि गर्नुहोस्';

  @override
  String get cMfaCopied => 'प्रतिलिपि गरियो';

  @override
  String get cMfaConfirm => 'पुष्टि गरेर सक्रिय गर्नुहोस्';

  @override
  String get cMfaCodesTitle => 'तपाईंका रिकभरी कोडहरू सुरक्षित गर्नुहोस्';

  @override
  String get cMfaCodesBody =>
      'प्रमाणिकरण एप हराएमा प्रत्येक कोडले एक पटक साइन-इन गर्न दिन्छ। यी अहिले मात्र देखिन्छन्।';

  @override
  String get cMfaDownload => 'डाउनलोड गर्नुहोस्';

  @override
  String get cMfaSaveFailed =>
      'यो उपकरणमा फाइल सुरक्षित गर्न सकिँदैन। कोडहरू प्रतिलिपि गरी सुरक्षित राख्नुहोस्।';

  @override
  String get cMfaContinue => 'कन्सोलमा जानुहोस्';

  @override
  String get cMfaInvalid =>
      'कोड मिलेन। फोनको समय सही छ कि छैन जाँचेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get cMfaExpired =>
      'साइन-इनको समय सकियो। पासवर्ड चरणबाट फेरि सुरु गर्नुहोस्।';

  @override
  String get cMfaLocked =>
      'धेरै प्रयासहरू भए। केही मिनेट पर्खेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get cStaffReset => 'पासवर्ड रिसेट गर्नुहोस्';

  @override
  String get cStaffResetConfirm =>
      'यस कर्मचारीको पासवर्ड रिसेट गर्ने हो? उनीहरू सबै ठाउँबाट साइन-आउट हुनेछन्।';

  @override
  String get cStaffResetTitle => 'रिसेट टोकन';

  @override
  String get cStaffResetBody =>
      'यो टोकन कर्मचारीलाई दिनुहोस्। यो एक पटक, ३० मिनेटभित्र मात्र काम गर्छ। बन्द गरेपछि फेरि देखिँदैन।';

  @override
  String get subTitle => 'नियमित सफाइ';

  @override
  String get subNew => 'सदस्यता सुरु गर्नुहोस्';

  @override
  String get subCadence => 'कति बेला';

  @override
  String get subWeekly => 'हरेक हप्ता';

  @override
  String get subBiweekly => 'हरेक २ हप्ता';

  @override
  String get subEvery4Weeks => 'हरेक ४ हप्ता';

  @override
  String get subWeekday => 'वार';

  @override
  String get subHour => 'आइपुग्ने समय';

  @override
  String subDiscountNote(String percent) {
    return 'हरेक भ्रमणमा $percent% छुट';
  }

  @override
  String get subChargeNote =>
      'भ्रमणको एक दिन अगाडि सेभ गरिएको कार्डबाट शुल्क लाग्छ';

  @override
  String get subCreate => 'सदस्यता लिनुहोस्';

  @override
  String get subCreated => 'सदस्यता सुरु भयो';

  @override
  String get subNeedAddress => 'पहिले भ्रमण ठेगाना थप्नुहोस्';

  @override
  String get subListEmpty => 'अहिलेसम्म सदस्यता छैन';

  @override
  String get subStatusActive => 'सक्रिय';

  @override
  String get subStatusPaused => 'रोकिएको';

  @override
  String get subStatusCancelled => 'रद्द गरिएको';

  @override
  String subNextVisit(String date) {
    return 'अर्को भ्रमण $date';
  }

  @override
  String get subPause => 'रोक्नुहोस्';

  @override
  String get subResume => 'फेरि सुरु गर्नुहोस्';

  @override
  String get subCancelSub => 'सदस्यता रद्द गर्नुहोस्';

  @override
  String get subCancelConfirm =>
      'आगामी भ्रमणहरू रद्द हुनेछन्। बुक भइसकेका भ्रमण छुट्टै रद्द गर्नुपर्छ।';

  @override
  String get subSkip => 'यो भ्रमण छोड्नुहोस्';

  @override
  String get subMove => 'मिति सार्नुहोस्';

  @override
  String get subVisitLocked => 'भ्रमणको एक दिन अगाडिदेखि परिवर्तन गर्न मिल्दैन';

  @override
  String get subPausedPayment =>
      'बारम्बार भुक्तानी असफल भएकाले रोकियो। कार्ड बदलेर फेरि सुरु गर्नुहोस्।';

  @override
  String get subStatePlanned => 'तय गरिएको';

  @override
  String get subStateBooked => 'बुक गरिएको';

  @override
  String get subStateSkipped => 'छोडिएको';

  @override
  String get subStateMissed => 'छुटेको';

  @override
  String get pSubsTitle => 'नियमित ग्राहक';

  @override
  String get pSubsEmpty => 'अहिलेसम्म नियमित ग्राहक छैनन्';

  @override
  String get cSubsTitle => 'सदस्यताहरू';

  @override
  String get cSubsEdit => 'ग्राहकको तर्फबाट सम्पादन';

  @override
  String get cMrr => 'मासिक दोहोरिने आम्दानी (MRR)';

  @override
  String get cChurn => 'च्युर्न';

  @override
  String get cActiveSubs => 'सक्रिय सदस्यता';

  @override
  String get cRecognized => 'अवधिमा मान्यता प्राप्त आम्दानी';

  @override
  String get cSubsLoadFailed => 'सदस्यता लोड गर्न सकिएन';

  @override
  String get tTaxSection => 'कर';

  @override
  String tVatQuarter(String q) {
    return 'Q$q VAT CSV';
  }

  @override
  String get tVatYear => 'वर्ष';

  @override
  String get tExportWithholding => 'कर कट्टी विवरण CSV';

  @override
  String get tExportTaxInvoices => 'कर बिल अपलोड CSV';

  @override
  String get tTaxLayoutNote =>
      'अपलोड गर्नु अघि 홈택스 टेम्प्लेटसँग स्तम्भ जाँच गर्नुहोस्। बनोट अझै प्रमाणित भएको छैन।';

  @override
  String get tCashReceipts => 'नगद रसिद';

  @override
  String get tCashIssued => 'जारी भयो';

  @override
  String get tCashFailed => 'असफल';

  @override
  String get tCashPending => 'पर्खाइमा';

  @override
  String get tCashCancelled => 'रद्द भयो';

  @override
  String get tReissue => 'पुनः जारी';

  @override
  String get tTaxInvoices => 'कर बिल';

  @override
  String get tApprovalNumber => 'स्वीकृति नम्बर';

  @override
  String get tIssuedOn => 'जारी मिति';

  @override
  String get tMarkIssued => 'जारी भएको चिन्ह लगाउनुहोस्';

  @override
  String get tQueueEmpty => 'पर्खिरहेको अनुरोध छैन';

  @override
  String get tWithholdingLabel => 'कर कट्टी';

  @override
  String get tGrossAmount => 'कुल रकम';

  @override
  String get tIncomeTax => 'आयकर';

  @override
  String get tLocalTax => 'स्थानीय आयकर';

  @override
  String get tNetAmount => 'खुद रकम';

  @override
  String get tNoWithholding => 'कर कट्टी छैन (दर्ता व्यवसाय)';

  @override
  String get tEstWithholding => 'अनुमानित कर कट्टी (बाँकी)';

  @override
  String get tReceiptOptions => 'रसिद विकल्पहरू';

  @override
  String get tWantCashReceipt => 'नगद रसिद चाहियो';

  @override
  String get tCashForIncome => 'कर छुट का लागि (फोन नम्बर)';

  @override
  String get tCashForBusiness => 'व्यावसायिक खर्चका लागि (व्यवसाय नम्बर)';

  @override
  String get tWantTaxInvoice => 'कर बिल चाहियो (व्यवसाय)';

  @override
  String get tPhoneForReceipt => 'फोन नम्बर';

  @override
  String get tBusinessNumber => 'व्यवसाय दर्ता नम्बर';

  @override
  String get tCompanyName => 'कम्पनीको नाम';

  @override
  String get tRepresentative => 'प्रतिनिधि';

  @override
  String get tInvoiceEmail => 'बिलका लागि इमेल';

  @override
  String get tReceiptSave => 'सुरक्षित गरेर भुक्तानी गर्नुहोस्';

  @override
  String get tReceiptSaveFailed => 'रसिद विवरण सुरक्षित गर्न सकिएन';

  @override
  String get tTaxType => 'कर प्रकार';

  @override
  String get tTaxFreelancer => 'फ्रीलान्सर (कर कट्टी)';

  @override
  String get tTaxBusiness => 'दर्ता व्यवसाय (कर कट्टी छैन)';

  @override
  String get tReceiptSettings => 'रसिद सेटिङ';

  @override
  String get reviewRuleLine =>
      'अपमानजनक भाषा, व्यक्तिगत जानकारी, झुटो वा विज्ञापनयुक्त सामग्री निषेधित छ। रिपोर्ट गरिएका समीक्षा लुकाइनेछन्।';

  @override
  String get reportAction => 'रिपोर्ट';

  @override
  String get reportSheetTitle => 'यो समीक्षा रिपोर्ट गर्ने?';

  @override
  String get reportReasonSpam => 'स्प्याम वा विज्ञापन';

  @override
  String get reportReasonOffensive => 'अपमान वा घृणा';

  @override
  String get reportReasonPersonal => 'व्यक्तिगत जानकारी समावेश';

  @override
  String get reportReasonOther => 'अन्य';

  @override
  String get reportNoteHint => 'विवरण (ऐच्छिक, ३०० अक्षरसम्म)';

  @override
  String get reportSubmit => 'रिपोर्ट पठाउनुहोस्';

  @override
  String get reportThanks => 'धन्यवाद। हाम्रो टोलीले समीक्षा गर्नेछ।';

  @override
  String get reportAlready =>
      'तपाईंले यो समीक्षा पहिले नै रिपोर्ट गरिसक्नुभएको छ';

  @override
  String get reportFailed => 'रिपोर्ट पठाउन सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get reviewBlocked =>
      'यो खाताबाट समीक्षा गर्न मिल्दैन। सहायतामा सम्पर्क गर्नुहोस्।';

  @override
  String get modTitle => 'रिपोर्ट गरिएका समीक्षाहरू';

  @override
  String get modEmpty => 'कुनै रिपोर्ट बाँकी छैन';

  @override
  String modReports(String count) {
    return '$count रिपोर्ट';
  }

  @override
  String get modKeep => 'राख्नुहोस्';

  @override
  String get modHide => 'लुकाउनुहोस्';

  @override
  String get modDelete => 'मेटाउनुहोस्';

  @override
  String get modBlockAuthor => 'लेखकलाई सीमित गर्नुहोस्';

  @override
  String get modUnblockAuthor => 'सीमा हटाउनुहोस्';

  @override
  String get modDone => 'सम्पन्न';

  @override
  String get modFailed => 'प्रशोधन गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get modHidden => 'लुकाइएको समीक्षा';

  @override
  String uUpdateBanner(String version) {
    return 'नयाँ संस्करण $version उपलब्ध छ';
  }

  @override
  String get uUpdateNow => 'अपडेट गर्नुहोस्';

  @override
  String get uUpdateLater => 'पछि';

  @override
  String get uUpdateRequiredTitle => 'अपडेट आवश्यक छ';

  @override
  String get uUpdateRequiredBody =>
      'यो संस्करण अब समर्थित छैन। कृपया स्टोरबाट अपडेट गर्नुहोस्।';

  @override
  String get uUpdateStore => 'स्टोरमा अपडेट गर्नुहोस्';

  @override
  String get uUpdateStoreMissing =>
      'अपडेट लिंक अझै तयार छैन। पछि फेरि प्रयास गर्नुहोस्।';

  @override
  String uCurrentVersion(String version) {
    return 'हालको संस्करण $version';
  }

  @override
  String get uAppVersionTitle => 'एप संस्करणहरू';

  @override
  String get uAppVersionHint =>
      'न्यूनतम संस्करणभन्दा तल्लो एप अपडेट स्क्रिनमा रोकिनेछ। उदाहरण: 1.2.0';

  @override
  String get uMinVersion => 'न्यूनतम संस्करण';

  @override
  String get uLatestVersion => 'नवीनतम संस्करण';

  @override
  String get walletTitle => 'पोइन्ट वालेट';

  @override
  String get walletBalance => 'प्रयोग गर्न मिल्ने पोइन्ट';

  @override
  String walletPoints(String count) {
    return '$count P';
  }

  @override
  String walletExpiring(String days, String count) {
    return '$days दिनभित्र $count P सकिनेछ';
  }

  @override
  String get walletOff => 'पोइन्ट कार्यक्रम अहिले खुलेको छैन';

  @override
  String get walletEmpty => 'अहिलेसम्म पोइन्ट गतिविधि छैन';

  @override
  String get walletHistory => 'हालैका गतिविधि';

  @override
  String get walletKindEarn => 'बुकिङ क्यासब्याक';

  @override
  String get walletKindWelcome => 'स्वागत पोइन्ट';

  @override
  String get walletKindReferral => 'रेफरल पुरस्कार';

  @override
  String get walletKindRefund => 'रद्दबाट फिर्ता भएको पोइन्ट';

  @override
  String get walletKindSpend => 'बुकिङमा प्रयोग';

  @override
  String get walletKindExpire => 'म्याद सकियो';

  @override
  String get walletKindOther => 'पोइन्ट समायोजन';

  @override
  String get moreWallet => 'पोइन्ट वालेट';

  @override
  String get payHistoryTitle => 'भुक्तानी इतिहास';

  @override
  String get payHistoryEmpty => 'अहिलेसम्म भुक्तानी छैन';

  @override
  String get payStatusPaid => 'भुक्तानी भयो';

  @override
  String get payStatusRefunded => 'फिर्ता भयो';

  @override
  String get payStatusPending => 'भुक्तानी बाँकी';

  @override
  String get payStatusClosed => 'भुक्तानी भएन';

  @override
  String get receiptTitle => 'इलेक्ट्रोनिक रसिद';

  @override
  String get receiptLegal => 'व्यवसायको नाम';

  @override
  String get receiptRegNo => 'व्यवसाय दर्ता नम्बर';

  @override
  String get receiptAddr => 'ठेगाना';

  @override
  String get receiptPhone => 'ग्राहक सेवा';

  @override
  String get receiptDate => 'भुक्तानी मिति';

  @override
  String get receiptCopy => 'रसिद प्रतिलिपि गर्नुहोस्';

  @override
  String get receiptCopied => 'रसिद प्रतिलिपि गरियो';

  @override
  String get receiptNote =>
      'यो भुक्तानी प्रमाण मात्र हो। कर इनभ्वाइसका लागि बुकिङ विवरणबाट अनुरोध गर्नुहोस्।';

  @override
  String get checkoutPointsUse => 'पोइन्ट प्रयोग गर्नुहोस्';

  @override
  String checkoutPointsAvail(String count, String max) {
    return '$count P उपलब्ध · यो भुक्तानीमा बढीमा $max P';
  }

  @override
  String get checkoutPointsNeedsWindow =>
      'भुक्तानी विन्डोबाट तिर्दा पोइन्ट प्रयोग गर्न सकिन्छ';

  @override
  String get pointsLedgerTitle => 'पोइन्ट खाता';

  @override
  String get pointsAdjustAmount => 'पोइन्ट (घटाउन ऋणात्मक)';

  @override
  String get pointsAdjustReason => 'समायोजनको कारण';

  @override
  String get pointsAdjustInvalid => '0 बाहेकको पोइन्ट र कारण लेख्नुहोस्';

  @override
  String get pointsAdjustDone => 'पोइन्ट समायोजन भयो';

  @override
  String get err_points_insufficient =>
      'पोइन्ट पुगेन। प्रयोग गर्ने पोइन्ट घटाउनुहोस्।';

  @override
  String get err_points_over_cap =>
      'यो भुक्तानीमा प्रयोग गर्न मिल्ने पोइन्टको सीमा नाघ्यो।';

  @override
  String get err_points_cover_total =>
      'पूरै रकम पोइन्टले तिर्न मिल्दैन। अलि घटाउनुहोस्।';

  @override
  String get webBookNow => 'वेबमा तुरुन्त बुक गर्नुहोस्';

  @override
  String get webBookSub => 'एप इन्स्टल नगरी बुक गर्नुहोस्';

  @override
  String get apPgBrowserNote =>
      'ब्राउजरमा भुक्तानी पूरा गर्नुहोस्, त्यसपछि यहाँ फर्केर तलको बटन थिच्नुहोस्।';

  @override
  String get apPgBrowserDone => 'मैले भुक्तानी गरिसकें';
}
