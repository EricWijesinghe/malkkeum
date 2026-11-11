// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class TSi extends T {
  TSi([String locale = 'si']) : super(locale);

  @override
  String get addressSearch => 'ලිපිනය සොයන්න';

  @override
  String get addressSearchHint => 'මාර්ග නම, ගොඩනැගිල්ල හෝ ලොට් අංකයෙන් සොයන්න';

  @override
  String get addressSearchButton => 'සොයන්න';

  @override
  String get addressSearchMinChars =>
      'අක්ෂර 2ක් හෝ වැඩි ප්‍රමාණයක් ඇතුළු කරන්න';

  @override
  String get addressNoResults => 'ප්‍රතිඵල නැත. වෙනත් වචන උත්සාහ කරන්න.';

  @override
  String get addressManualEntry => 'අතින් ඇතුළු කරන්න';

  @override
  String get cardRegisterTitle => 'කාඩ්පත ලියාපදිංචි කරන්න';

  @override
  String get cIntJuso => 'ලිපින සෙවීම (juso.go.kr)';

  @override
  String get aiLabel => 'AI සහායක';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'පාරිභෝගික කථාවලට ස්වයංක්‍රීයව පිළිතුරු දෙයි. සෑම පණිවිඩයකටම API ගාස්තු අයවේ.';

  @override
  String get aiModeOffline => 'කාර්ය මණ්ඩලය නැති විට පමණක් පිළිතුරු දෙයි';

  @override
  String get aiModeAlways => 'AI සෑම විටම පළමුව පිළිතුරු දෙයි';

  @override
  String get aiPause => 'AI විරාම ගන්වන්න';

  @override
  String get aiResume => 'AI නැවත ආරම්භ කරන්න';

  @override
  String get aiPausedNote => 'මෙම කථාවට AI විරාම ගන්වා ඇත';

  @override
  String aiUsageMonth(String count) {
    return 'මෙම මාසයේ AI ඇමතුම්: $count';
  }

  @override
  String get aiNotConfigured => 'AI සහායක ක්‍රියාවිරහිතයි';

  @override
  String get aiCapThreadLabel => 'කථාවකට පැයකට පිළිතුරු සීමාව';

  @override
  String get aiCapMemberLabel => 'පාරිභෝගිකයෙකුට දිනකට පිළිතුරු සීමාව';

  @override
  String get aiCapDailyLabel => 'සියලු කථාවලට දිනකට පිළිතුරු සීමාව';

  @override
  String get aiCapHint =>
      'ඉලක්කම් පමණක් ඇතුළත් කරන්න. පෙරනිමිය සඳහා හිස්ව තබන්න.';

  @override
  String get apSocialOr => 'හෝ';

  @override
  String get apSocialSignIn => 'ඉක්මන් පිවිසීම';

  @override
  String get apLoginKakao => 'Kakao මගින් දිගටම කරගෙන යන්න';

  @override
  String get apLoginNaver => 'Naver මගින් දිගටම කරගෙන යන්න';

  @override
  String get apLoginGoogle => 'Google මගින් දිගටම කරගෙන යන්න';

  @override
  String get apLoginApple => 'Apple මගින් දිගටම කරගෙන යන්න';

  @override
  String get apDevSocialNote =>
      'මෙය සංවර්ධන ප්‍රකාරයයි. සැබෑ සමාජ ගිණුමක් වෙනුවට පරීක්ෂණ ගිණුමකට ඇතුළු වේ.';

  @override
  String get apSocialFailed =>
      'ඉක්මන් පිවිසීම අසාර්ථක විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get apProviderNotConfigured =>
      'මෙම පිවිසුම් ක්‍රමය තවමත් සූදානම් වෙමින් පවතී';

  @override
  String get apPhoneTaken =>
      'මෙම දුරකථන අංකය වෙනත් ගිණුමකට දැනටමත් සම්බන්ධ කර ඇත';

  @override
  String get apPhoneAttachTitle => 'කරුණාකර ඔබේ ජංගම අංකය සත්‍යාපනය කරන්න';

  @override
  String get apPhoneAttachBody =>
      'මෙම අංකය වෙන්කිරීම් සහ වෘත්තිකයා සම්බන්ධ කර ගැනීම සඳහා භාවිත කරයි. එක් වරක් සත්‍යාපනය කිරීම ප්‍රමාණවත්ය.';

  @override
  String get apPayAllTitle => 'ගෙවීම් ක්‍රමයක් තෝරන්න';

  @override
  String get apPaySavedTitle => 'සුරැකි ගෙවීම් ක්‍රම';

  @override
  String get apPayMoreTitle => 'සියලු ගෙවීම් ක්‍රම';

  @override
  String get apPayBillingHint =>
      'එක් වරක් ලියාපදිංචි කරන්න, ඊළඟ වාරයේ එක් ස්පර්ශයකින් ගෙවන්න';

  @override
  String get apPayCheckoutHint => 'ගෙවීම් කවුළුවෙන් අවසන් කරන්න';

  @override
  String get apPayRegistering => 'ලියාපදිංචි වෙමින්…';

  @override
  String get apPayManageHint =>
      'සුරැකි ක්‍රමවලින් එක් ස්පර්ශයකින් ගෙවන්න. ඉක්මන් ගෙවීම් ක්‍රම මෙහි එකතු කළ හැක.';

  @override
  String get apMethodCard => 'ණය සහ හර කාඩ්පත';

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
  String get apMethodTransfer => 'බැංකු මාරුව';

  @override
  String get apMethodVirtual => 'අතථ්‍ය ගිණුම';

  @override
  String get apMethodPhone => 'දුරකථන බිල ගෙවීම';

  @override
  String get apMethodUnknown => 'වෙනත්';

  @override
  String get apVaTitle => 'ඔබේ තැන්පතු ගිණුම සූදානම්ය';

  @override
  String get apVaWaiting => 'තැන්පතුව බලා සිටී';

  @override
  String get apVaBody =>
      'නියමිත කාලය තුළ තැන්පතුව ලැබුණු පසු වෙන්කිරීම තහවුරු වේ. තැන්පතුව ස්වයංක්‍රීයව පරීක්ෂා කරයි.';

  @override
  String get apVaBank => 'බැංකුව';

  @override
  String get apVaAccount => 'ගිණුම් අංකය';

  @override
  String get apVaHolder => 'ගිණුම් හිමිකරු';

  @override
  String get apVaAmount => 'තැන්පත් කළ යුතු මුදල';

  @override
  String apVaDue(String due) {
    return '$due වන විට තැන්පත් කරන්න';
  }

  @override
  String get apVaCopy => 'පිටපත් කරන්න';

  @override
  String get apVaCopied => 'ගිණුම් අංකය පිටපත් කරන ලදී';

  @override
  String get apVaBannerTitle => 'තැන්පතුව බලා සිටින වෙන්කිරීමක් ඇත';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due දක්වා';
  }

  @override
  String get apVaBannerAction => 'ගිණුම බලන්න';

  @override
  String get apPgTitle => 'ගෙවීම් කවුළුව';

  @override
  String get apPgDevNote =>
      'මෙය සංවර්ධන පරිසරය සඳහා පමණක් වූ ගෙවීම් අනුකරණයකි. සැබෑ මුදල් අයකිරීමක් සිදු නොවේ.';

  @override
  String apPgPay(String amount) {
    return '$amount ගෙවන්න';
  }

  @override
  String get apPgIssue => 'ගිණුම් අංකය ලබාගන්න';

  @override
  String get apPgCancel => 'ගෙවීම අවලංගු කරන්න';

  @override
  String get apErrSlotFullRefunded =>
      'එම වේලාව දැන් පිරී ගියේය, එබැවින් ගෙවීම ස්වයංක්‍රීයව අවලංගු කරන ලදී';

  @override
  String get apErrCheckoutExpired =>
      'ගෙවීම් කාලය ඉක්මවා ගියේය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get apIdentityTitle => 'අනන්‍යතා සත්‍යාපනය (PASS)';

  @override
  String get apIdentityBody =>
      'ඔබේ දුරකථන සේවා සපයන්නා හරහා ඔබව තහවුරු කරයි. ආරක්ෂිත ගනුදෙනු සහ ගෙවීම් සඳහා භාවිත වේ.';

  @override
  String get apIdentityAction => 'අනන්‍යතාව සත්‍යාපනය කරන්න';

  @override
  String get apIdentityDone => 'අනන්‍යතාව සත්‍යාපනය විය';

  @override
  String get apIdentityVerified => 'සත්‍යාපිතයි';

  @override
  String get apIdentityUnverified => 'තවම සත්‍යාපනය වී නැත';

  @override
  String get apIdentityDevTitle => 'පරීක්ෂණ අනන්‍යතා සත්‍යාපනය';

  @override
  String get apIdentityDevBody =>
      'සංවර්ධන පරිසරයේ සැබෑ පරීක්ෂාවකින් තොරව මෙය සමත් වේ.';

  @override
  String get apIdentityDevPass => 'සමත් කරන්න';

  @override
  String get apPayManageTitle => 'ඉක්මන් ගෙවීම ලියාපදිංචි කරන්න';

  @override
  String get cTitle => 'මෙහෙයුම් කොන්සෝලය';

  @override
  String get cEmail => 'ඊමේල්';

  @override
  String get cPassword => 'මුරපදය';

  @override
  String get cLogin => 'පිවිසෙන්න';

  @override
  String get cLoginFailed => 'ඊමේල් හෝ මුරපදය වැරදියි';

  @override
  String get cDashboard => 'උපකරණ පුවරුව';

  @override
  String get cBookings => 'වෙන්කිරීම්';

  @override
  String get cQuoteDesk => 'මිල ගණන් ඩෙස්ක්';

  @override
  String get cInbox => 'උපදේශන පෙට්ටිය';

  @override
  String get cCatalog => 'නාමාවලිය · මිල';

  @override
  String get cMarketing => 'කූපන් · අන්තර්ගතය';

  @override
  String get cPartners => 'හවුල්කරුවන්';

  @override
  String get cSettlements => 'ගෙවීම් පියවීම්';

  @override
  String get cCustomers => 'පාරිභෝගිකයන්';

  @override
  String get cStaff => 'කාර්ය මණ්ඩලය';

  @override
  String get cSearchCommand => 'සොයන්න · විධාන';

  @override
  String get cPaletteHint => 'කොටසේ නම හෝ වෙන්කිරීම් අංකය ටයිප් කරන්න';

  @override
  String get cTodayJobs => 'අද කාර්යයන්';

  @override
  String get cOpenQuotes => 'බලාපොරොත්තු මිල ගණන්';

  @override
  String get cUnassigned => 'පවරා නැත';

  @override
  String get cUnreadThreads => 'නොකියවූ සංවාද';

  @override
  String get cRevenue30 => 'දින 30 ආදායම';

  @override
  String get cBookings30 => 'දින 30 වෙන්කිරීම්';

  @override
  String get cByService => 'සේවා අනුව වෙන්කිරීම් (දින 30)';

  @override
  String get cAllStatus => 'සියලු තත්ත්ව';

  @override
  String get cAllServices => 'සියලු සේවා';

  @override
  String get cSearch => 'සොයන්න (අංකය, දුරකථනය, නම, ලිපිනය)';

  @override
  String get cNoResults => 'ප්‍රතිඵල නැත';

  @override
  String get cNumber => 'අංකය';

  @override
  String get cVisit => 'පැමිණීම';

  @override
  String get cService => 'සේවාව';

  @override
  String get cStatus => 'තත්ත්වය';

  @override
  String get cTeam => 'කණ්ඩායම';

  @override
  String get cAmount => 'මුදල';

  @override
  String get cCustomer => 'පාරිභෝගිකයා';

  @override
  String get cPayments => 'ගෙවීම්';

  @override
  String get cChangeStatus => 'තත්ත්වය වෙනස් කරන්න';

  @override
  String get cTeamName => 'පවරන ලද කණ්ඩායම';

  @override
  String get cAssign => 'කණ්ඩායම පවරන්න';

  @override
  String get cMarkDone => 'සම්පූර්ණ ලෙස සලකුණු කරන්න';

  @override
  String get cConfirm => 'තහවුරු ලෙස සලකුණු කරන්න';

  @override
  String get cCancelRefund => 'අවලංගු · ආපසු ගෙවීම';

  @override
  String get cRefundAmount => 'ආපසු ගෙවීමේ මුදල (හිස් = සම්පූර්ණ)';

  @override
  String get cDone => 'සම්පූර්ණ කළා';

  @override
  String get cAnswers => 'පාරිභෝගික පිළිතුරු';

  @override
  String get cEstimateCalc => 'ස්වයංක්‍රීය ගණනය';

  @override
  String get cBase => 'මූලික';

  @override
  String get cExtras => 'අමතර';

  @override
  String get cSurcharge => 'අතිරේක ගාස්තුව';

  @override
  String get cBeforeVat => 'VAT ට පෙර';

  @override
  String get cProQuotes => 'හවුල්කරු මිල ගණන්';

  @override
  String get cNoProQuotes => 'තවම හවුල්කරුවන්ගෙන් මිල ගණන් නැත';

  @override
  String get cFinalPrice => 'පාරිභෝගිකයාගේ අවසාන මිල';

  @override
  String get cQuoteNote => 'පාරිභෝගිකයාට සටහන';

  @override
  String get cSendQuote => 'පාරිභෝගිකයාට මිල ගණන් යවන්න';

  @override
  String get cQuoteSent => 'මිල ගණන් යවන ලදී';

  @override
  String get cCustomerChats => 'පාරිභෝගිකයන්';

  @override
  String get cPartnerChats => 'හවුල්කරුවන්';

  @override
  String get cSelectBooking => 'වෙන්කිරීමක් තෝරන්න';

  @override
  String get cRefunded => 'ආපසු ගෙවන ලදී';

  @override
  String get cPartRefunded => 'කොටසින් ආපසු ගෙවීම';

  @override
  String get cFailed => 'අසාර්ථකයි';

  @override
  String get cSelectThread => 'සංවාදයක් තෝරන්න';

  @override
  String get cReplyHint => 'පිළිතුර ටයිප් කරන්න · යැවීමට Ctrl+Enter';

  @override
  String get cOpenBooking => 'වෙන්කිරීම විවෘත කරන්න';

  @override
  String get cShortcuts => 'J/K ගමන · Ctrl+K විධානය';

  @override
  String get cPricing => 'මිල';

  @override
  String get cMinutes => 'කාලය (මිනිත්තු)';

  @override
  String get cActive => 'අලෙවියේ';

  @override
  String get cSaved => 'සුරකින ලදී';

  @override
  String get cSlotCapacity => 'පැමිණීමේ වේලාව අනුව ධාරිතාව';

  @override
  String get cUnlimited => 'සීමාවක් නැත';

  @override
  String get cFormula => 'මිල ගණන් සූත්‍රය';

  @override
  String get cTabCancelPolicy => 'අවලංගු කිරීමේ ප්‍රතිපත්තිය';

  @override
  String get cPolicyDefaultBanner =>
      'මෙය පෙරනිශ්චිත අගයයි. පරීක්ෂා කර සුරකින්න.';

  @override
  String get cPolicyDaysBefore => 'පැමිණීමට දින කීයකට පෙර (සිට)';

  @override
  String get cPolicyPercent => 'ගාස්තුව % (හිස් = යෙදුමෙන් අවලංගු කළ නොහැක)';

  @override
  String get cPolicyMinFee => 'අවම ගාස්තුව (KRW)';

  @override
  String get cPolicyReschedule => 'දින වෙනස් කළ හැක (පැමිණීමට දින කීයකට පෙර)';

  @override
  String get cPolicyHint =>
      'ගනුදෙනුකරු යෙදුමේ අවලංගු තිරයට වහාම අදාළ වේ. නියමයන් ඊළඟ නෛතික build එකෙන් යාවත්කාලීන වේ.';

  @override
  String get f_base_studio => 'මූලික: ස්ටුඩියෝ';

  @override
  String get f_base_one_and_half => 'මූලික: කාමර 1.5';

  @override
  String get f_base_two_rooms => 'මූලික: කාමර 2';

  @override
  String get f_base_three_rooms => 'මූලික: කාමර 3';

  @override
  String get f_base_four_plus => 'මූලික: කාමර 4+';

  @override
  String get f_per_extra_bathroom => 'අමතර නාන කාමරයකට';

  @override
  String get f_per_balcony => 'බැල්කනියකට';

  @override
  String get f_duplex => 'ද්විත්ව මහල';

  @override
  String get f_no_elevator_high_floor => 'ලිෆ්ට් නැත + මහල 3 හෝ ඊට ඉහළ';

  @override
  String get cIssueCoupon => 'කූපන් නිකුත් කරන්න';

  @override
  String get cCouponName => 'කූපන් නම';

  @override
  String get cCouponPhones => 'ඉලක්ක දුරකථන අංක (එක් පේළියකට එකක්)';

  @override
  String get cAllCustomers => 'සියලු පාරිභෝගිකයන්ට';

  @override
  String cIssued(String n) {
    return '$n ක් නිකුත් කළා';
  }

  @override
  String get cContent => 'අන්තර්ගතය';

  @override
  String get cKind_notice => 'නිවේදනය';

  @override
  String get cKind_tip => 'ඉඟිය';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'බැනරය';

  @override
  String get cKind_legal => 'නීතිමය';

  @override
  String get cNewContent => 'නව අන්තර්ගතය';

  @override
  String get cTitleField => 'මාතෘකාව';

  @override
  String get cBodyField => 'අන්තර්ගතය';

  @override
  String get cSlug => 'හඳුනාගැනීම (නීතිමය: privacy / terms)';

  @override
  String get cVerify => 'අනුමත කරන්න';

  @override
  String get cSuspend => 'අත්හිටුවන්න';

  @override
  String get cPro_pending => 'අනුමැතිය බලා සිටී';

  @override
  String get cPro_verified => 'සක්‍රියයි';

  @override
  String get cPro_suspended => 'අත්හිටුවා ඇත';

  @override
  String get cCompleted => 'සම්පූර්ණයි';

  @override
  String get cCancelledN => 'අවලංගුයි';

  @override
  String get cRating => 'ශ්‍රේණිය';

  @override
  String get cFeeRate => 'ගාස්තුව %';

  @override
  String get cRunPayouts => 'ගෙවීම් ක්‍රියාත්මක කරන්න';

  @override
  String get cPayoutDate => 'ගෙවීම් දිනය (දක්වා)';

  @override
  String cPayoutDone(String n) {
    return 'හවුල්කරුවන් $n දෙනාට ගෙවීම් සිදු කළා';
  }

  @override
  String get cHold => 'රඳවන්න';

  @override
  String get cRelease => 'රඳවීම නිදහස් කරන්න';

  @override
  String get cNet => 'ගෙවිය යුතු මුදල';

  @override
  String get cAddStaff => 'කාර්ය මණ්ඩලය එකතු කරන්න';

  @override
  String get cRoleAdmin => 'පරිපාලක';

  @override
  String get cRoleConsultant => 'උපදේශක';

  @override
  String get cDeactivate => 'අක්‍රිය කරන්න';

  @override
  String get cActivate => 'සක්‍රිය කරන්න';

  @override
  String get cPasswordRule => 'අක්ෂර 12ක් හෝ වැඩි';

  @override
  String get cAdminOnly => 'පරිපාලකයන්ට පමණයි';

  @override
  String cBookingsCount(String n) {
    return 'වෙන්කිරීම් $n';
  }

  @override
  String get cJoined => 'එක්වූ දිනය';

  @override
  String get cNewBooking => 'නව වෙන්කිරීමක් ලැබුණා';

  @override
  String get cNewMessage => 'නව පණිවිඩයක්';

  @override
  String get cConfirmAsk => 'ඔබට විශ්වාසද?';

  @override
  String get ok => 'හරි';

  @override
  String get cancel => 'අවලංගු කරන්න';

  @override
  String get next => 'ඊළඟ';

  @override
  String get close => 'වසන්න';

  @override
  String get save => 'සුරකින්න';

  @override
  String get delete => 'මකන්න';

  @override
  String get edit => 'සංස්කරණය';

  @override
  String get change => 'වෙනස් කරන්න';

  @override
  String get retry => 'නැවත උත්සාහ කරන්න';

  @override
  String get yes => 'ඔව්';

  @override
  String get no => 'නැත';

  @override
  String get required => 'අනිවාර්යයි';

  @override
  String get viewAll => 'සියල්ල බලන්න';

  @override
  String get today => 'අද';

  @override
  String get errorGeneric =>
      'යම් ගැටලුවක් ඇතිවිය. කරුණාකර මද වේලාවකින් නැවත උත්සාහ කරන්න.';

  @override
  String get errorNetwork => 'කරුණාකර අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කරන්න';

  @override
  String get err_invalid_phone => 'කරුණාකර ජංගම අංකය පරීක්ෂා කරන්න';

  @override
  String get err_otp_invalid => 'සත්‍යාපන කේතය වැරදියි';

  @override
  String get err_otp_expired =>
      'සත්‍යාපන කේතයේ කල් ඉකුත් වී ඇත. කරුණාකර නව කේතයක් ඉල්ලන්න.';

  @override
  String get err_rate_limited =>
      'උත්සාහයන් ඉතා වැඩියි. කරුණාකර පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get err_studio_too_large =>
      'ස්ටුඩියෝ පිරිසිදු කිරීම පියොං 10 දක්වා නිවාස සඳහා පමණි';

  @override
  String get err_date_out_of_range => 'හෙට සිට දින 60ක් ඇතුළත දිනයක් තෝරන්න';

  @override
  String get err_slot_full => 'එම වේලාව පිරී ගියේය. වෙනත් වේලාවක් තෝරන්න.';

  @override
  String get err_coupon_expired => 'මෙම කූපනයේ කල් ඉකුත් වී ඇත';

  @override
  String get err_coupon_used => 'මෙම කූපනය දැනටමත් භාවිත කර ඇත';

  @override
  String get err_coupon_wrong_service =>
      'මෙම සේවාව සඳහා මෙම කූපනය භාවිත කළ නොහැක';

  @override
  String get err_payment_failed =>
      'ගෙවීම අනුමත නොවීය. වෙනත් ක්‍රමයක් උත්සාහ කරන්න.';

  @override
  String get err_payment_method_required => 'කරුණාකර ගෙවීම් ක්‍රමයක් තෝරන්න';

  @override
  String get err_cancellation_window_closed =>
      'මෙම වෙන්කිරීම දැන් යෙදුම හරහා අවලංගු කළ නොහැක. කරුණාකර අපේ කණ්ඩායම අමතන්න';

  @override
  String get err_address_required => 'පැමිණීමේ ලිපිනය එකතු කරන්න';

  @override
  String get err_already_taken => 'වෙනත් හවුල්කරුවෙක් පළමුව පිළිගත්තා';

  @override
  String get err_invalid_address => 'ලිපිනයේ සියලු තොරතුරු පුරවන්න';

  @override
  String get tabHome => 'මුල්පිටුව';

  @override
  String get tabBookings => 'වෙන්කිරීම්';

  @override
  String get tabChat => 'උපදේශනය';

  @override
  String get tabMore => 'තවත්';

  @override
  String get introTitle => 'වෘත්තීය පිරිසිදු කිරීම\nමිනිත්තුවකින් වෙන් කරන්න';

  @override
  String get introBody =>
      'පෙර නිශ්චිත මිල · සත්‍යාපිත කණ්ඩායම් · සජීවී ප්‍රගතිය';

  @override
  String get introStart => 'දුරකථන අංකයෙන් ආරම්භ කරන්න';

  @override
  String get loginPhoneTitle => 'ඔබේ ජංගම අංකය කුමක්ද?';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'කේතය ලබා ගන්න';

  @override
  String get loginCodeTitle => 'ඉලක්කම් 6 කේතය ඇතුළත් කරන්න';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone වෙත යවා ඇත';
  }

  @override
  String get loginResend => 'නැවත යවන්න';

  @override
  String get loginVerify => 'තහවුරු කරන්න';

  @override
  String get loginTerms =>
      'දිගටම කරගෙන යාමෙන් ඔබ සේවා කොන්දේසි සහ පෞද්ගලිකත්ව ප්‍රතිපත්තියට එකඟ වේ';

  @override
  String get profileTitle => 'අපි ඔබව කුමන නමින් ඇමතිය යුතුද?';

  @override
  String get profileNameHint => 'නම';

  @override
  String get profileDone => 'ආරම්භ කරන්න';

  @override
  String get welcomeToast => 'සාදරයෙන් පිළිගැනීමේ කූපන් 2ක් ඔබේ පසුම්බියේ ඇත';

  @override
  String get svc_studio => 'ස්ටුඩියෝ පිරිසිදු කිරීම';

  @override
  String get svc_kitchen => 'මුළුතැන්ගෙය පිරිසිදු කිරීම';

  @override
  String get svc_bathroom => 'නාන කාමර පිරිසිදු කිරීම';

  @override
  String get svc_mattress => 'මෑට්‍රස් පිරිසිදු කිරීම';

  @override
  String get svc_aircon => 'වායු සමීකරණ පිරිසිදු කිරීම';

  @override
  String get svc_sofa => 'සෝෆා පිරිසිදු කිරීම';

  @override
  String get svc_move_out => 'ගෙදර හැර යාමේ පිරිසිදු කිරීම';

  @override
  String get svc_move_in => 'ගෙදරට ඇතුළුවීමේ පිරිසිදු කිරීම';

  @override
  String get svcShort_studio => 'ස්ටුඩියෝ';

  @override
  String get svcShort_kitchen => 'මුළුතැන්ගෙය';

  @override
  String get svcShort_bathroom => 'නාන කාමරය';

  @override
  String get svcShort_mattress => 'මෑට්‍රස්';

  @override
  String get svcShort_aircon => 'වායු සමීකරණය';

  @override
  String get svcShort_sofa => 'සෝෆාව';

  @override
  String get svcShort_move_out => 'ගෙදර හැරයාම';

  @override
  String get svcShort_move_in => 'ගෙදරට ඇතුළුවීම';

  @override
  String get svcDesc_studio =>
      'පියොං 10 දක්වා ස්ටුඩියෝවක් (කාමරය 1ක්, නාන කාමරය 1ක්) පැය 2ක් පුරා සවිස්තරාත්මකව පිරිසිදු කරයි.';

  @override
  String get svcDesc_kitchen =>
      'සින්ක්, ගෑස් උදුන, චිමනියේ පිටත කොටස සහ මේස් මුදුන කේන්ද්‍රගත කරමින් මුළුතැන්ගෙය පිරිසිදු කරයි.';

  @override
  String get svcDesc_bathroom =>
      'රාක්ක, ජලනළ, මුට්ටිය සහ වැසිකිළියේ ඇතුළත සහ පිට පිරිසිදු කර, බිම වියළි කර අවසන් කරයි.';

  @override
  String get svcDesc_mattress =>
      'විශේෂ උපකරණවලින් දූවිලි, ක්ෂුද්‍ර ජීවීන් සහ කරකි ඉවත් කර, වාෂ්පයෙන් විෂබීජ නාශනය කරයි.';

  @override
  String get svcDesc_aircon =>
      'වෙන් කර, සිසිලන දඟර, සුළං පංකාව සහ පෙරහන පීඩනයෙන් සෝදා විෂබීජ නාශනයෙන් අවසන් කරයි.';

  @override
  String get svcDesc_sofa =>
      'රෙදි වර්ගයට ගැලපෙන ද්‍රව්‍යයකින් අපද්‍රව්‍ය බිඳ දමා, තෙත් නිස්සාරණ ක්‍රමයෙන් ඉවත් කරයි.';

  @override
  String get svcDesc_move_out =>
      'ගෙදර හැර යාමට පෙර, විශේෂ උපකරණ සහිත වෘත්තීය කණ්ඩායමක් හිස් නිවස පිරිසිදු කරයි.';

  @override
  String get svcDesc_move_in =>
      'නව ගෙදරට ඇතුළුවීමට පෙර, විශේෂ උපකරණ සහිත වෘත්තීය කණ්ඩායමක් නිවස පිරිසිදු කරයි.';

  @override
  String get svcNotes_bathroom =>
      'ජල බැස යාම හෝ වැසිකිළිය අවහිර වී ඇත්නම් සේවාව සීමා විය හැක\nවිශේෂ රසායනික, සිවිලිම හෝ වෙන්ටිලේටර් පිරිසිදු කිරීම ලබා නොදේ\nපැරණි දිලීර සහ ඇලී ඇති මළ සම්පූර්ණයෙන් ඉවත් නොවිය හැක';

  @override
  String get svcNotes_mattress =>
      'තනි සිට කිං ප්‍රමාණය දක්වා එකම මිල\nසම්පූර්ණයෙන් වියළීමට පැය 4–6ක් ගත වේ\nස්ප්‍රිං හානි හෝ ඇද වැටීම නිවැරදි කළ නොහැක';

  @override
  String get svcNotes_aircon =>
      'වසර 10කට වැඩි පැරණි උපකරණ වෙන් කිරීම ආරක්ෂිත නොවිය හැක\nබාහිර ඒකකය පිරිසිදු කිරීම ඇතුළත් නොවේ\nපිරිසිදු කිරීමට පෙර සහ පසු එය නිසි ලෙස ක්‍රියා කරන බව පරීක්ෂා කරයි';

  @override
  String get svcNotes_sofa =>
      'සම් සෝෆා පිරිසිදු කර ආර්ද්‍රතා ආලේපනයක් ලබා දේ\nපැරණි කැළැල් හෝ වර්ණ මාරුවීම සම්පූර්ණයෙන් ඉවත් නොවිය හැක\nසම්පූර්ණයෙන් වියළීමට පැය 4–6ක් ගත වේ';

  @override
  String get unitTitle_bathroom => 'නාන කාමර ගණන';

  @override
  String get unitTitle_mattress => 'මෑට්‍රස් ගණන';

  @override
  String get unitTitle_aircon => 'වායු සමීකරණ වර්ගය';

  @override
  String get unitTitle_sofa => 'සෝෆා ප්‍රමාණය';

  @override
  String unit_count(String n) {
    return '$n ක්';
  }

  @override
  String get unit_wall => 'බිත්තියට සවි කරන, 1 ක්';

  @override
  String get unit_stand => 'බිම තබන, 1 ක්';

  @override
  String get unit_two_in_one => '2in1 (බිම් + බිත්ති)';

  @override
  String get unit_ceiling => 'සිවිලිමට සවි කරන, 1 ක්';

  @override
  String get unit_seat_1_2 => 'ආසන 1–2';

  @override
  String get unit_seat_3 => 'ආසන 3';

  @override
  String get unit_seat_4_plus => 'ආසන 4 හෝ වැඩි';

  @override
  String get unit_l_shape => 'L හැඩය · කවුච්';

  @override
  String durH(String h) {
    return 'පැය $h';
  }

  @override
  String durHM(String h, String m) {
    return 'පැය $h මිනිත්තු $m';
  }

  @override
  String durM(String m) {
    return 'මිනිත්තු $m';
  }

  @override
  String about(String value) {
    return 'දළ වශයෙන් $value';
  }

  @override
  String fromPrice(String price) {
    return '$price සිට';
  }

  @override
  String get quoteBadge => 'මිල ගණන්';

  @override
  String get status0 => 'උපදේශනයේ';

  @override
  String get status1 => 'වෙන්කිරීම තහවුරු විය';

  @override
  String get status2 => 'කණ්ඩායම පවරා ඇත';

  @override
  String get status3 => 'පිරිසිදු කිරීම සම්පූර්ණයි';

  @override
  String get statusCancelled => 'අවලංගු විය';

  @override
  String homeGreeting(String name) {
    return '$name,\nඅද අපි කොහේ පිරිසිදු කරමු?';
  }

  @override
  String get homeGreetingAnon => 'අද අපි කොහේ\nපිරිසිදු කරමු?';

  @override
  String get homeUpcoming => 'ඉදිරි වෙන්කිරීම්';

  @override
  String dDay(String days) {
    return 'දින $days කින්';
  }

  @override
  String get homeServices => 'ඔබට කුමන පිරිසිදු කිරීමක් අවශ්‍යද?';

  @override
  String get homeAddAddress =>
      'ලිපිනය එකතු කරන්න, ලබා ගත හැකි සේවා සහ මිල වහාම පෙන්වමු';

  @override
  String get homeAddAddressCta => 'ලිපිනය එකතු කරන්න';

  @override
  String homeRebook(String service) {
    return '$service නැවත වෙන්කරන්න';
  }

  @override
  String get homeRebookBody =>
      'පසුගිය වතාවේ මෙන්ම එම කොන්දේසි යටතේ ඉක්මනින් වෙන් කරන්න';

  @override
  String get homeNotices => 'නව පුවත්';

  @override
  String get trustVat => 'VAT ඇතුළත්\nපෙන්වන මිල එලෙසම';

  @override
  String get trustCancel => 'පැමිණීමට දින 2කට පෙර\nනොමිලේ අවලංගු කරන්න';

  @override
  String get trustCard => 'කාඩ්පත් තොරතුරු\nගෙවීම් සමාගම තුළ පමණක් තබයි';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'දිනයක් තෝරන්න';

  @override
  String get notIncluded => 'කරුණාකර පරීක්ෂා කරන්න';

  @override
  String studioBlockedTitle(String size) {
    return 'පියොං $size ස්ටුඩියෝ පිරිසිදු කිරීමට විශාලයි';
  }

  @override
  String get studioBlockedBody =>
      'අපගේ උපදේශක කණ්ඩායම ඔබේ නිවසට ගැළපෙන සේවාව යෝජනා කරයි.';

  @override
  String get consultCta => 'උපදේශනයෙන් විමසන්න';

  @override
  String get addressTitle => 'කොහේ පැමිණිය යුතුද?';

  @override
  String get addressAdd => 'නව ලිපිනයක් එකතු කරන්න';

  @override
  String get addressLabel => 'නම';

  @override
  String get addressLabelHint => 'උදා: අපේ ගෙදර';

  @override
  String get addressDistrict => 'දිස්ත්‍රික්කය';

  @override
  String get addressRoad => 'මාර්ග ලිපිනය';

  @override
  String get addressDetail => 'නිවස / මහල';

  @override
  String get addressSize => 'නිවසේ ප්‍රමාණය (පියොං)';

  @override
  String get addressSizeHelp => 'භාවිත ප්‍රදේශය · 1 පියොං ≈ 3.3 m²';

  @override
  String get addressHome => 'ගෙදර';

  @override
  String get addressOffice => 'කාර්යාලය';

  @override
  String get addressEmpty => 'සුරකින ලද ලිපින නැත';

  @override
  String get addressSaved => 'ලිපිනය සුරකින ලදී';

  @override
  String pyeong(String n) {
    return 'පියොං $n';
  }

  @override
  String get scheduleTitle => 'කවදා පැමිණිය යුතුද?';

  @override
  String get scheduleArrival => 'පැමිණෙන වේලාව';

  @override
  String get scheduleFull => 'පිරී ඇත';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end අතර පැමිණේ';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · දළ වශයෙන් $time ට අවසන් වේ';
  }

  @override
  String get scheduleRange => 'හෙට සිට දින 60ක් ඇතුළත වෙන් කළ හැක';

  @override
  String get morning => 'උදේ';

  @override
  String get afternoon => 'දහවල්';

  @override
  String get scheduleQuoteNote =>
      'නිශ්චිත පැමිණෙන වේලාව උපදේශනයේදී තහවුරු කරමු';

  @override
  String get goToPayment => 'ගෙවීමට යන්න';

  @override
  String get prepTitle => 'කරුණාකර මේවා සූදානම් කර තබන්න';

  @override
  String get prepBody => 'මේවා නොමැතිව සමහර කාර්යයන් සීමා විය හැක';

  @override
  String get prepAsk => 'සූදානම් කළ නොහැකිද? අපේ කණ්ඩායමට දන්වන්න';

  @override
  String get tool_vacuum => 'වැක්කුම් යන්ත්‍රය';

  @override
  String get tool_trash => 'කසල බෑග්';

  @override
  String get tool_mop => 'මොප්';

  @override
  String get tool_cloth => 'රෙදි';

  @override
  String get tool_gloves => 'රබර් අත්වැසුම්';

  @override
  String get tool_sponge => 'ස්පොන්ජ්';

  @override
  String get tool_spray => 'බහු-අරමුණු ක්ලීනර්';

  @override
  String get checkoutTitle => 'ගෙවීම';

  @override
  String get coupon => 'කූපනය';

  @override
  String get couponNone => 'භාවිත නොකරන්න';

  @override
  String couponAvailable(String count) {
    return '$count ක් ලබා ගත හැක';
  }

  @override
  String get paymentMethod => 'ගෙවීම් ක්‍රමය';

  @override
  String get addPaymentMethod => 'ගෙවීම් ක්‍රමයක් එකතු කරන්න';

  @override
  String get methodCard => 'ණය / හර කාඩ්පත';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'එකතු කළා';

  @override
  String get methodAdded => 'ගෙවීම් ක්‍රමය එකතු කළා';

  @override
  String get listPrice => 'සේවා මිල';

  @override
  String get discount => 'කූපන් වට්ටම';

  @override
  String get total => 'මුළු මුදල';

  @override
  String get vatIncluded => 'VAT ඇතුළත්';

  @override
  String payAmount(String amount) {
    return '$amount ගෙවන්න';
  }

  @override
  String get needMethod => 'පළමුව ගෙවීම් ක්‍රමයක් එකතු කරන්න';

  @override
  String freeCancelUntil(String date) {
    return '$date දක්වා නොමිලේ අවලංගු කළ හැක';
  }

  @override
  String get doneTitle => 'වෙන්කිරීම සම්පූර්ණයි!';

  @override
  String get doneBody => 'කණ්ඩායමක් පවරන වහාම අපි ඔබට දන්වන්නෙමු';

  @override
  String get doneQuoteTitle => 'උපදේශන ඉල්ලීම ලැබිණි';

  @override
  String get doneQuoteBody =>
      'අපගේ කණ්ඩායම පරීක්ෂා කර අවසාන මිල ගණන් යවයි. එය උපදේශනය ටැබයේ බලන්න.';

  @override
  String get goHome => 'මුල්පිටුවට';

  @override
  String get viewBooking => 'වෙන්කිරීම බලන්න';

  @override
  String get bookingsTitle => 'වෙන්කිරීම්';

  @override
  String get bookingsUpcoming => 'ඉදිරි';

  @override
  String get bookingsPast => 'අතීත';

  @override
  String get bookingsEmpty => 'තවම වෙන්කිරීම් නැත';

  @override
  String get bookingsEmptyBody =>
      'ඔබේ පළමු වෙන්කිරීම සඳහා සාදරයෙන් පිළිගැනීමේ කූපන් ඔබ වෙනුවෙන් රැඳී සිටී';

  @override
  String get bookNow => 'පිරිසිදු කිරීමක් වෙන් කරන්න';

  @override
  String get detailTitle => 'වෙන්කිරීම';

  @override
  String get stepRequested => 'උපදේශනය ඉල්ලන ලදී';

  @override
  String get stepConfirmed => 'වෙන්කිරීම තහවුරු විය';

  @override
  String get stepAssigned => 'කණ්ඩායම පවරා ඇත';

  @override
  String get stepCompleted => 'පිරිසිදු කිරීම සම්පූර්ණයි';

  @override
  String teamVisiting(String team) {
    return '$team පැමිණෙමින් සිටී';
  }

  @override
  String get photosSoon => 'අවසන් වූ පසු කලින් සහ පසු ඡායාරූප මෙහි දිස් වේ';

  @override
  String photoThumb(String n) {
    return 'ඡායාරූපය $n';
  }

  @override
  String get before => 'පිරිසිදු කිරීමට පෙර';

  @override
  String get after => 'පිරිසිදු කිරීමෙන් පසු';

  @override
  String get prepCheck => 'සූදානම් ලැයිස්තුව';

  @override
  String get prepAllSet => 'සියල්ල සූදානම්';

  @override
  String get visitAddress => 'ලිපිනය';

  @override
  String get paid => 'ගෙවා ඇත';

  @override
  String get askTeam => 'අපගේ කණ්ඩායමට පණිවිඩයක්';

  @override
  String get cancelBooking => 'වෙන්කිරීම අවලංගු කරන්න';

  @override
  String get cancelTitle => 'මෙම වෙන්කිරීම අවලංගු කරන්නද?';

  @override
  String get cancelFree =>
      'දැන් අවලංගු කළහොත් ගෙවූ මුළු මුදලම ආපසු ලැබෙන අතර කූපනයද ලැබෙනු ඇත.';

  @override
  String get cancelKeep => 'තබා ගන්න';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'දැන් අවලංගු කළහොත් $fee ගාස්තුවක් අය කරන අතර $refund ආපසු ලැබේ.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return '$fee ගාස්තුව පිළිගෙන අවලංගු කරන්න';
  }

  @override
  String get cancelled => 'වෙන්කිරීම අවලංගු විය';

  @override
  String get reschedule => 'වේලාව වෙනස් කරන්න';

  @override
  String get rescheduled => 'වේලාව වෙනස් කළා';

  @override
  String get visitNotes => 'කණ්ඩායමට ඉල්ලීම්';

  @override
  String get notesEntry => 'ඇතුළු වන ආකාරය (දොර කේතය ආදිය)';

  @override
  String get notesParking => 'වාහන නැවැත්වීම';

  @override
  String get notesOther => 'වෙනත්';

  @override
  String get notesSaved => 'ඉල්ලීම් සුරකින ලදී';

  @override
  String depositDue(String amount) {
    return '$amount අත්තිකාරම ගෙවූ පසු වෙන්කිරීම තහවුරු වේ';
  }

  @override
  String get payDeposit => 'අත්තිකාරම ගෙවන්න';

  @override
  String get waitingQuote => 'උපදේශක කණ්ඩායම ඔබගේ මිල ගණන් සකස් කරමින් සිටී';

  @override
  String get estimate => 'දළ මුදල';

  @override
  String get finalPrice => 'අවසාන මිල ගණන';

  @override
  String get deposit => 'අත්තිකාරම';

  @override
  String get balance => 'ශේෂය';

  @override
  String balanceDue(String amount) {
    return 'කරුණාකර $amount ශේෂය ගෙවන්න';
  }

  @override
  String get payBalance => 'ශේෂය ගෙවන්න';

  @override
  String get reviewTitle => 'පිරිසිදු කිරීම කෙසේ වීද?';

  @override
  String get reviewHint => 'හොඳ වූ දේ හෝ වැඩි දියුණු කළ හැකි දේ අපට කියන්න';

  @override
  String ratingStars(String n) {
    return '$n ලකුණු';
  }

  @override
  String get reviewSubmit => 'සමාලෝචනය යවන්න';

  @override
  String get reviewThanks => 'ඔබේ සමාලෝචනයට ස්තූතියි!';

  @override
  String get bookAgain => 'නැවත වෙන් කරන්න';

  @override
  String get chatTitle => 'උපදේශනය';

  @override
  String get chatTeam => 'සහාය කණ්ඩායම';

  @override
  String get chatHours => 'සඳුදා–සිකුරාදා 09:00–18:00';

  @override
  String get chatEmpty => 'ප්‍රශ්න ඇත්දැයි? ඕනෑම වේලාවක අසන්න';

  @override
  String get chatNew => 'නව උපදේශනයක්';

  @override
  String get chatTopicTitle => 'ඔබට කුමක් ගැන දැනගැනීමට අවශ්‍යද?';

  @override
  String get topicOther => 'වෙනත් විමසීමක්';

  @override
  String get chatHint => 'පණිවිඩය ටයිප් කරන්න';

  @override
  String get chatSend => 'යවන්න';

  @override
  String get chatPhoto => 'ඡායාරූපයක් යවන්න';

  @override
  String get chatTyping => 'කණ්ඩායම ටයිප් කරමින් සිටී';

  @override
  String get quick_confirm => 'කරුණාකර වෙන්කිරීම තහවුරු කරන්න';

  @override
  String get quick_price => 'මිල ගැන දැනගන්න ඕනේ';

  @override
  String get quick_date => 'දිනය වෙනස් කරන්න ඕනේ';

  @override
  String get quick_parking => 'වාහන නැවැත්වීමට ඉඩ තිබේද?';

  @override
  String get quick_hello => 'ආයුබෝවන්';

  @override
  String get quick_duration => 'කොපමණ වේලාවක් ගතවේද?';

  @override
  String get quoteArrived => 'අවසාන මිල ගණන් ලැබී ඇත';

  @override
  String get quoteDepositNow => 'දැන් අත්තිකාරම 10%';

  @override
  String get quoteBalanceLater => 'පිරිසිදු කිරීමෙන් පසු ශේෂය';

  @override
  String get quotePay => 'අත්තිකාරම ගෙවා වෙන්කිරීම තහවුරු කරන්න';

  @override
  String get quotePaid => 'ගෙවා ඇත';

  @override
  String get requestCard => 'මිල ගණන් ඉල්ලීම';

  @override
  String get sys_consultation_received => 'උපදේශන ඉල්ලීම ලැබිණි';

  @override
  String sys_deposit_paid(String amount) {
    return '$amount අත්තිකාරම ලැබිණි. වෙන්කිරීම තහවුරු විය.';
  }

  @override
  String get sys_booking_cancelled => 'වෙන්කිරීම අවලංගු විය';

  @override
  String sys_status_changed(String status) {
    return 'තත්ත්වය \'$status\' ලෙස වෙනස් විය';
  }

  @override
  String get sys_job_completed =>
      'පිරිසිදු කිරීම අවසන්! කලින් සහ පසු ඡායාරූප බලන්න.';

  @override
  String sys_rescheduled(String date) {
    return 'වේලාව $date ට වෙනස් කළා';
  }

  @override
  String get sys_reschedule_declined =>
      'හවුල්කරුවාට වෙනස් කළ වේලාවට පැමිණීමට නොහැක. අපගේ කණ්ඩායම එය නැවත සකස් කරයි.';

  @override
  String get moreTitle => 'තවත්';

  @override
  String get moreScope => 'සේවා විෂය පථය';

  @override
  String get morePayments => 'ගෙවීම් ක්‍රම කළමනාකරණය';

  @override
  String get moreCoupons => 'කූපන්';

  @override
  String get morePoints => 'පිරිසිදු කිරීමේ ලකුණු';

  @override
  String get moreAccount => 'ගිණුම් තොරතුරු';

  @override
  String get moreAddresses => 'ලිපින කළමනාකරණය';

  @override
  String get moreNotices => 'නිවේදන';

  @override
  String get moreTips => 'පිරිසිදු කිරීමේ ඉඟි';

  @override
  String get moreFaq => 'නිතර ඇසෙන ප්‍රශ්න';

  @override
  String get morePartner => 'හවුල්කරුවෙකු වන්න';

  @override
  String get moreLanguage => 'භාෂාව';

  @override
  String get langSystem => 'උපාංග සැකසුම් අනුගමනය කරන්න';

  @override
  String moreVersion(String v) {
    return 'අනුවාදය $v';
  }

  @override
  String get morePrivacy => 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය';

  @override
  String get moreTerms => 'සේවා කොන්දේසි';

  @override
  String get moreLicenses => 'විවෘත මූලාශ්‍ර බලපත්‍ර';

  @override
  String get logout => 'පිටවෙන්න';

  @override
  String get deleteAccount => 'ගිණුම මකන්න';

  @override
  String get deleteAccountBody =>
      'පුද්ගලික දත්ත මැකෙන අතර එය අහෝසි කළ නොහැක. පළමුව සක්‍රිය වෙන්කිරීම් අවලංගු කරන්න.';

  @override
  String get couponsEmpty => 'තවම කූපන් නැත';

  @override
  String couponUntil(String date) {
    return '$date දක්වා';
  }

  @override
  String get couponUsed => 'භාවිත කළා';

  @override
  String get couponExpired => 'කල් ඉකුත්';

  @override
  String get couponAnyService => 'ඕනෑම සේවාවක්';

  @override
  String get coupon_welcome_studio => 'සාදරයෙන් පිළිගැනීමේ ස්ටුඩියෝ කූපනය';

  @override
  String get coupon_welcome_any => 'සාදරයෙන් පිළිගැනීමේ කූපනය';

  @override
  String get pointsBalance => 'ඔබේ ලකුණු';

  @override
  String get pointsEmpty => 'ලකුණු ඉතිහාසයක් නැත';

  @override
  String get accountName => 'නම';

  @override
  String get accountPhone => 'ජංගම';

  @override
  String get accountEmail => 'ඊමේල්';

  @override
  String get accountLogin => 'පිවිසුම් ක්‍රමය';

  @override
  String get accountLoginPhone => 'දුරකථන සත්‍යාපනය';

  @override
  String get methodsEmpty => 'ගෙවීම් ක්‍රම නැත';

  @override
  String get noContent => 'මෙහි තවම කිසිවක් නැත';

  @override
  String get quoteTypeTitle => 'ඔබට කුමන පිරිසිදු කිරීමක් අවශ්‍යද?';

  @override
  String get type_standard => 'ගෙදර හැර යාමේ පිරිසිදු කිරීම';

  @override
  String get type_same_day_move => 'ගෙදර මාරු වන දිනයේ පිරිසිදු කිරීම';

  @override
  String get type_some_luggage_left => 'භාණ්ඩ කොටසක් ඉතිරිව ඇත';

  @override
  String get type_normal_move_in => 'සාමාන්‍ය ගෙදරට ඇතුළුවීම';

  @override
  String get type_after_interior => 'අභ්‍යන්තර නවීකරණයෙන් පසු';

  @override
  String get type_lived_in_deep_clean => 'වාසය කරන ගෙදර ගැඹුරු පිරිසිදු කිරීම';

  @override
  String get luggageTitle => 'ගෙදරේ භාණ්ඩ තත්ත්වය කෙසේද?';

  @override
  String get luggage_empty => 'හිස්';

  @override
  String get luggage_partly_unpacked => 'කොටසක් අසුරා ඇත';

  @override
  String get luggage_fully_lived_in => 'සම්පූර්ණයෙන් භාවිත වේ';

  @override
  String get luggage_unknown => 'විශ්වාස නැත';

  @override
  String get quoteBasicTitle => 'නිවසේ ව්‍යුහය ගැන කියන්න';

  @override
  String get buildingType => 'ගොඩනැගිල්ලේ වර්ගය';

  @override
  String get building_apartment => 'අපාර්ට්මන්ට්';

  @override
  String get building_villa => 'විලා';

  @override
  String get building_officetel => 'ඔෆිස්ටෙල්';

  @override
  String get building_house => 'තනි නිවස';

  @override
  String get building_other => 'වෙනත්';

  @override
  String get layoutTitle => 'සැලැස්ම';

  @override
  String get layout_studio => 'ස්ටුඩියෝ';

  @override
  String get layout_one_and_half => 'කාමර 1.5';

  @override
  String get layout_two_rooms => 'කාමර 2';

  @override
  String get layout_three_rooms => 'කාමර 3';

  @override
  String get layout_four_plus => 'කාමර 4 හෝ වැඩි';

  @override
  String get duplexTitle => 'මෙය ද්විත්ව මහල් නිවසක්ද?';

  @override
  String get quoteSpaceTitle => 'ඉඩ ගැන තව ටිකක් කියන්න';

  @override
  String get bathroomsLabel => 'නාන කාමර';

  @override
  String get balconiesLabel => 'බැල්කනි · උපයෝගිතා කාමරය';

  @override
  String get elevatorTitle => 'ලිෆ්ට් එකක් තිබේද?';

  @override
  String get floor3Label => 'මහල 3 හෝ ඊට ඉහළ';

  @override
  String get quoteEstimateTitle => 'ඔබේ දළ මිල ගණන්';

  @override
  String get quoteEstimateBody =>
      'ඡායාරූප බැලීමෙන් පසු උපදේශනයේදී අවසාන මුදල තීරණය වේ';

  @override
  String get quoteG1 => 'අවසාන මුදල උපදේශනයේදී ඔබ සමඟ තීරණය කරයි';

  @override
  String get quoteG2 =>
      'තහවුරු කිරීමට අත්තිකාරම 10%, ඉතිරිය පිරිසිදු කිරීමෙන් පසු';

  @override
  String get quoteG3 => 'තහවුරු කිරීමට පෙර ඕනෑම වේලාවක නොමිලේ අවලංගු කළ හැක';

  @override
  String get quoteConfirmTitle => 'ඔබේ ඉල්ලීම පරීක්ෂා කරන්න';

  @override
  String get quoteRequest => 'උපදේශන ඉල්ලීම යවන්න';

  @override
  String get quoteNoPayNow => 'දැන් ගෙවීමක් නැත';

  @override
  String get summaryType => 'පිරිසිදු කිරීමේ වර්ගය';

  @override
  String get summaryHome => 'නිවස';

  @override
  String get summaryDate => 'පැමිණීම';

  @override
  String get cpTitle => 'අවලංගු කිරීමේ ප්‍රතිපත්තිය';

  @override
  String cpWhen(String days) {
    return 'පැමිණීමට දින $days හෝ ඊට වැඩි කාලයකට පෙර';
  }

  @override
  String get cpWhenSameDay => 'පැමිණෙන දිනයේ';

  @override
  String get cpFree => 'සම්පූර්ණ ආපසු ගෙවීම';

  @override
  String cpFee(String percent, String fee, String refund) {
    return '$percent% ගාස්තුව ($fee), ආපසු $refund';
  }

  @override
  String get cpClosed => 'යෙදුමෙන් අවලංගු කළ නොහැක (කණ්ඩායම සමාලෝචනය)';

  @override
  String get hhTitle => 'නිවසේ තොරතුරු';

  @override
  String get hhAddPet => 'සුරතල් සත්වයෙකු එක් කරන්න';

  @override
  String get hhPetCount => 'ගණන';

  @override
  String get hhFloorLabel => 'මහල (බේස්මන්ට් සඳහා සෘණ)';

  @override
  String get hhElevator => 'ලිෆ්ට් ඇත';

  @override
  String get hhNotes => 'සටහන්';

  @override
  String get hhHint => 'මෙම ලිපිනයට සුරැකෙන අතර සෑම වෙන්කිරීමකම වෙනස් කළ හැක.';

  @override
  String get themeTitle => 'තේමාව';

  @override
  String get themeDark => 'අඳුරු';

  @override
  String get themeLight => 'දීප්තිමත්';

  @override
  String get themeSystem => 'පද්ධති සැකසුම';

  @override
  String get themeTip => 'තේමාව වෙනස් කරන්න';

  @override
  String get err_price_changed =>
      'මිල වෙනස් වී ඇත. නව මිල ගණන පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get err_checkout_closed => 'මෙම ගෙවීම දැන් වසා ඇත. නැවත ආරම්භ කරන්න.';

  @override
  String get err_checkout_refunded => 'මෙම ගෙවීම අවලංගු කර මුදල ආපසු ගෙවා ඇත.';

  @override
  String get err_already_paid => 'මෙම ගෙවීම දැනටමත් සම්පූර්ණ කර ඇත.';

  @override
  String get err_quote_not_payable =>
      'මෙම මිල ගණන දැනට ගෙවිය නොහැක. අපගේ කණ්ඩායම සම්බන්ධ කරගන්න.';

  @override
  String get err_payment_method_disabled =>
      'මෙම ගෙවීම් ක්‍රමය දැනට ලබා ගත නොහැක.';

  @override
  String get err_invalid_payment_method =>
      'තේරූ ගෙවීම් ක්‍රමය භාවිත කළ නොහැක. වෙනත් එකක් තෝරන්න.';

  @override
  String get err_balance_not_due => 'ශේෂය ගෙවීමට තවම කල් ඉකුත් වී නැත.';

  @override
  String get err_invalid_slot => 'මෙම සේවාව සඳහා එම වේලාව ලබා දෙන්නේ නැත.';

  @override
  String get err_booking_changed =>
      'වෙන්කිරීම වෙනස් වී ඇත. නැවුම් කර විස්තර පරීක්ෂා කරන්න.';

  @override
  String get err_booking_closed => 'මෙම වෙන්කිරීම තවදුරටත් වෙනස් කළ නොහැක.';

  @override
  String get err_reschedule_closed =>
      'දැන් සංචාර දිනය වෙනස් කළ නොහැක. අපගේ කණ්ඩායම සම්බන්ධ කරගන්න.';

  @override
  String get err_too_many_open_requests =>
      'විවෘත ඉල්ලීම් ගණන වැඩියි. පළමුව එකක් සම්පූර්ණ කරන්න.';

  @override
  String get err_already_reviewed =>
      'ඔබ මෙම සංචාරය සඳහා දැනටමත් සමාලෝචනයක් ලියා ඇත.';

  @override
  String get err_identity_not_verified =>
      'පළමුව අනන්‍යතා තහවුරු කිරීම සම්පූර්ණ කරන්න.';

  @override
  String get err_email_taken => 'මෙම ඊමේල් ලිපිනය දැනටමත් භාවිතයේ ඇත.';

  @override
  String get err_invalid_email => 'ඊමේල් ලිපිනය පරීක්ෂා කරන්න.';

  @override
  String get err_file_too_large =>
      'ගොනුව වැඩිය විශාලයි. කුඩා ගොනුවක් උඩුගත කරන්න.';

  @override
  String get err_unsupported_image =>
      'මෙම ඡායාරූප ආකෘතිය සහාය නොදක්වයි. JPG හෝ PNG උඩුගත කරන්න.';

  @override
  String get err_upload_quota =>
      'අද දින උඩුගත කිරීමේ සීමාවට ළඟා වී ඇත. හෙට නැවත උත්සාහ කරන්න.';

  @override
  String get err_provider_unreachable =>
      'සේවාව වෙත සම්බන්ධ විය නොහැක. මඳ වේලාවකින් නැවත උත්සාහ කරන්න.';

  @override
  String get err_invalid_token => 'පිවිසීම සාර්ථක නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get err_invalid_transition => 'දැන් තත්ත්වය එසේ වෙනස් කළ නොහැක.';

  @override
  String get err_job_not_started => 'පළමුව වැඩ ආරම්භ කරන්න.';

  @override
  String get err_job_not_active => 'මෙම වැඩ සක්‍රිය නොවේ.';

  @override
  String get err_quote_locked =>
      'මිල ගණන අගුලු දමා ඇති නිසා සංස්කරණය කළ නොහැක.';

  @override
  String get err_request_closed => 'මෙම ඉල්ලීම වසා ඇත.';

  @override
  String get err_team_full => 'කණ්ඩායම පිරී ඇත.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret එක whsec_ න් ආරම්භ විය යුතුය.';

  @override
  String get err_invalid_endpoint => 'Endpoint එක https:// න් ආරම්භ විය යුතුය.';

  @override
  String get err_invalid_bucket => 'Bucket නම වලංගු නොවේ.';

  @override
  String get err_invalid_region => 'කලාපය වලංගු නොවේ.';

  @override
  String get err_invalid_retention => 'රඳවා තබා ගැනීමේ කාලය සීමාවෙන් පිටය.';

  @override
  String get err_invalid_service_account => 'Service account ගොනුව වලංගු නොවේ.';

  @override
  String get err_invalid_mode => 'වලංගු AI mode එකක් තෝරන්න.';

  @override
  String get err_invalid_model => 'AI model නම වලංගු නොවේ.';

  @override
  String get err_missing_field => 'අවශ්‍ය සියලු ක්ෂේත්‍ර පුරවන්න.';

  @override
  String get err_invalid_amount => 'වලංගු මුදලක් ඇතුළත් කරන්න.';

  @override
  String get err_cannot_deactivate_self => 'ඔබේම ගිණුම අක්‍රිය කළ නොහැක.';

  @override
  String get err_invalid_coupon => 'මෙම කූපනය වලංගු නොවේ.';

  @override
  String get err_settlement_state => 'දැන් පියවර වෙනස් කළ නොහැක.';

  @override
  String get err_deposit_required => 'පළමුව තැන්පතුව ගෙවිය යුතුය.';

  @override
  String get err_payout_state =>
      'ගෙවීම් තත්ත්වය වෙනස් වී ඇත. නැවුම් කර නැවත පරීක්ෂා කරන්න.';

  @override
  String get err_payout_provider => 'මෙම ගෙවීම් ක්‍රමය දැනට ලබා ගත නොහැක.';

  @override
  String get err_unsupported_bank => 'මෙම බැංකුවට ගෙවීම් සඳහා සහාය නොදක්වයි.';

  @override
  String get err_toss_unverified =>
      'Toss ගෙවීම් තවම ලබා ගත නොහැක. අතින් මුදල් යැවීම භාවිත කරන්න.';

  @override
  String get err_invalid_cap => 'අවසර ලත් පරාසය තුළ අංකයක් ඇතුළත් කරන්න.';

  @override
  String get err_invalid_capacity => 'වලංගු ධාරිතාවක් ඇතුළත් කරන්න.';

  @override
  String get err_seller_declined =>
      'Toss මගින් විකුණුම්කරු ලියාපදිංචිය අනුමත කළේ නැත. ව්‍යාපාර තොරතුරු පරීක්ෂා කරන්න.';

  @override
  String get err_payout_account_unverified =>
      'මෙම partner ට තවමත් සත්‍යාපිත ගෙවීම් ගිණුමක් නැත. පළමුව ගිණුම සත්‍යාපනය කරන්න.';

  @override
  String get fFinance => 'මූල්‍ය';

  @override
  String get fPeriodDay => 'දිනය';

  @override
  String get fPeriodWeek => 'සතිය';

  @override
  String get fPeriodMonth => 'මාසය';

  @override
  String get fPeriodCustom => 'රිතිය';

  @override
  String get fFrom => 'සිට';

  @override
  String get fTo => 'දක්වා';

  @override
  String get fGross => 'මුළු ගෙවීම්';

  @override
  String get fRefunds => 'ආපසු ගෙවීම්';

  @override
  String get fNetRevenue => 'ශුද්ධ ආදායම';

  @override
  String get fPlatformFee => 'වේදිකා ගාස්තුව';

  @override
  String get fPaidOut => 'හවුල්කරුවන්ට ගෙවූ';

  @override
  String get fPendingOut => 'ගෙවීම් බලාපොරොත්තුවෙන්';

  @override
  String get fHeldOut => 'රඳවා ඇත';

  @override
  String get fVatEstimate => 'VAT ඇස්තමේන්තුව';

  @override
  String get fVatNote =>
      'වේදිකා ගාස්තුවෙන් 10%ක ඇස්තමේන්තුවකි. ගණකාධිකාරී සමඟ තහවුරු කරන්න.';

  @override
  String get fAov => 'සාමාන්‍ය ඇණවුම් අගය';

  @override
  String get fBookings => 'වෙන්කිරීම්';

  @override
  String get fCancelRate => 'අවලංගු කිරීමේ අනුපාතය';

  @override
  String get fDiscounts => 'වට්ටම් සහ කූපන්';

  @override
  String get fMethods => 'ගෙවීම් ක්‍රම';

  @override
  String get fTrend => 'ප්‍රවණතාව';

  @override
  String fRangeDays(String n) {
    return 'අවසන් දින $n';
  }

  @override
  String get fRangeWeeks => 'අවසන් සති 12';

  @override
  String get fRangeMonths => 'අවසන් මාස 12';

  @override
  String get fByPartner => 'හවුල්කරුවා අනුව ඉපයීම්';

  @override
  String get fByService => 'සේවාව අනුව ආදායම';

  @override
  String get fExportTitle => 'ගිණුම්කරණ නිර්යාත';

  @override
  String get fExportLedger => 'ගෙවීම් ලෙජරය CSV';

  @override
  String get fExportSettlements => 'පියවීම් CSV';

  @override
  String get fExportMonthly => 'මාසික සාරාංශය CSV (ගණකාධිකාරී)';

  @override
  String get fDownload => 'CSV බාගන්න';

  @override
  String get fDownloadWebOnly => 'CSV බාගත හැක්කේ වෙබ් කොන්සෝලයෙන්';

  @override
  String get fDownloadFailed => 'බාගත කළ නොහැකි විය';

  @override
  String get fNoRecords => 'මෙම කාලයේ වාර්තා නැත';

  @override
  String get fLoadFailed => 'මූල්‍ය දත්ත පූරණය කළ නොහැකි විය';

  @override
  String get fRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get fColPartner => 'හවුල්කරු';

  @override
  String get fColJobs => 'ගණන';

  @override
  String get fColSettled => 'මුළු පියවීම';

  @override
  String get fColFee => 'ගාස්තුව';

  @override
  String get fColNet => 'ශුද්ධ';

  @override
  String get pEarnings => 'ඉපයීම්';

  @override
  String get pNextPayout => 'ඊළඟ ගෙවීම';

  @override
  String pNextPayoutOn(String date) {
    return '$date ගෙවීම';
  }

  @override
  String get pNoPayout => 'නියමිත ගෙවීම් නැත';

  @override
  String get pPendingTotal => 'ගෙවීමට බලාපොරොත්තුවෙන්';

  @override
  String get pPaidTotal => 'ගෙවා ඇත';

  @override
  String get pWeekly => 'සතිපතා';

  @override
  String get pMonthly => 'මාසික';

  @override
  String proofHomes(String count) {
    return 'මෙ මාසයේ නිවාස $countක් පිරිසිදු කළා';
  }

  @override
  String proofRating(String rating, String count) {
    return 'සාමාන්‍ය තරු $rating · සමාලෝචන $count';
  }

  @override
  String get proofReviewsTitle => 'මෑත සමාලෝචන';

  @override
  String get rebookTitle => 'පසුගිය සේවාව නැවත වෙන් කරන්නද?';

  @override
  String rebookBody(String service, String date) {
    return '$service · අවසන් පැමිණීම $date';
  }

  @override
  String get rebookButton => 'නැවත වෙන් කරන්න';

  @override
  String seatsLeft(String count) {
    return 'ඉතිරි ස්ථාන $countයි';
  }

  @override
  String get reviewSheetTitle => 'මෙම පිරිසිදු කිරීම කෙසේ වීද?';

  @override
  String get reviewPhotosAdd => 'ඡායාරූප එක් කරන්න';

  @override
  String get reviewPhotosHint => 'ඡායාරූප 5 දක්වා';

  @override
  String get reviewSaved => 'සමාලෝචනයට ස්තූතියි';

  @override
  String get reviewPhotoFailed =>
      'ඡායාරූපය උඩුගත කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get referralTitle => 'මිතුරෙකු ආරාධනා කර කූපනයක් ලබාගන්න';

  @override
  String referralBody(String amount) {
    return 'මිතුරා පළමු වෙන්කිරීම නිම කළ විට ඔබ දෙදෙනාටම $amount කූපනයක් ලැබේ';
  }

  @override
  String get referralCopy => 'කේතය පිටපත් කරන්න';

  @override
  String get referralCopied => 'යොමු කේතය පිටපත් කළා';

  @override
  String get referralClaimTitle => 'යොමු කේතයක් තිබේද?';

  @override
  String get referralClaimField => 'යොමු කේතය ඇතුළත් කරන්න';

  @override
  String get referralClaimButton => 'යොදන්න';

  @override
  String get referralClaimed => 'යොමු කේතය යොදන ලදී';

  @override
  String referralStats(String invited, String rewarded) {
    return 'ආරාධනා $invited · ප්‍රතිලාභ $rewarded';
  }

  @override
  String get err_self_referral => 'ඔබේම කේතය භාවිත කළ නොහැක';

  @override
  String get err_referee_already_booked =>
      'පළමු වෙන්කිරීමට පෙර පමණක් කේතය ඇතුළත් කළ හැක';

  @override
  String get err_already_referred => 'යොමු කේතය දැනටමත් යොදා ඇත';

  @override
  String get err_invalid_referral_code => 'යොමු කේතය පරීක්ෂා කරන්න';

  @override
  String get err_referral_disabled => 'දැනට යොමු කිරීම් විරාම කර ඇත';

  @override
  String get err_invalid_photos =>
      'Malkkeum හරහා උඩුගත කළ ඡායාරූප පමණක් අමුණන්න පුළුවන්';

  @override
  String get welcomeOfferTitle => 'පළමු වෙන්කිරීම් වට්ටම';

  @override
  String get welcomeOfferBody =>
      'නව පාරිභෝගිකයාගේ පළමු වෙන්කිරීමට ස්වයංක්‍රීයව යොදයි. කූපන සමග එකතු නොවේ.';

  @override
  String get offerKindAmount => 'ස්ථිර (වොන්)';

  @override
  String get offerKindPercent => 'ප්‍රතිශතය (%)';

  @override
  String get offerValue => 'වට්ටම් අගය';

  @override
  String get offerEnabled => 'ක්‍රියාත්මක';

  @override
  String get offerSaved => 'සුරකින ලදී';

  @override
  String get referralSettingsTitle => 'යොමු කිරීමේ ප්‍රතිලාභය';

  @override
  String get referralSettingsBody =>
      'මිතුරාගේ පළමු වෙන්කිරීම නිම වී ගෙවූ පසු ලබා දේ. ස්වයං-යොමු සහ එකම දුරකථන අංකය අවහිර වේ.';

  @override
  String get referralRewardAmount => 'ප්‍රතිලාභ මුදල (වොන්)';

  @override
  String get reviewsModerationTitle => 'සමාලෝචන මෙහෙයවීම';

  @override
  String get reviewHide => 'සඟවන්න';

  @override
  String get reviewShow => 'නැවත පෙන්වන්න';

  @override
  String get reviewHiddenTag => 'සඟවා ඇත';

  @override
  String get growthAverageRating => 'සාමාන්‍ය ශ්‍රේණිය';

  @override
  String growthReviewCount(String count) {
    return 'සමාලෝචන $count';
  }

  @override
  String get growthReferralConversion => 'යොමු පරිවර්තනය';

  @override
  String get growthTab => 'වර්ධනය';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$invited න් $rewarded';
  }

  @override
  String get uMaintenanceTitle => 'නඩත්තු කටයුතු සිදුවෙමින් පවතී';

  @override
  String get uMaintenanceBody =>
      'සේවාව වැඩිදියුණු කිරීම සඳහා නඩත්තු කරමින් සිටිමු. ටික වේලාවකින් නැවත උත්සාහ කරන්න.';

  @override
  String get cOps => 'පද්ධති තත්ත්වය';

  @override
  String get oLevelGreen => 'සාමාන්‍යයි';

  @override
  String get oLevelYellow => 'පරීක්ෂා කරන්න';

  @override
  String get oLevelRed => 'ක්‍රියාමාර්ගය අවශ්‍යයි';

  @override
  String get oOverall => 'සේවාදායක තත්ත්වය';

  @override
  String get oRefresh => 'නැවුම් කරන්න';

  @override
  String get oVersion => 'අනුවාදය';

  @override
  String get oUptime => 'ක්‍රියාත්මක කාලය';

  @override
  String oUptimeValue(String hours, String minutes) {
    return 'පැය $hours මිනිත්තු $minutes';
  }

  @override
  String get oChecks => 'පරීක්ෂා';

  @override
  String get oCheckDb => 'දත්ත ගබඩාව';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'ප්‍රතිචාරය $ms ms · ප්‍රමාණය $mb MB';
  }

  @override
  String get oCheckDisk => 'සේවාදායක තැටිය';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% නිදහස්';
  }

  @override
  String get oCheckBackup => 'ස්වයංක්‍රීය උපස්ථය';

  @override
  String oCheckBackupValue(String hours) {
    return 'අවසන් උපස්ථය පැය $hours කට පෙර';
  }

  @override
  String get oCheckBackupNone => 'උපස්ථ තවම නැත';

  @override
  String get oCheckErrors => 'සේවාදායක දෝෂ (පැය 24)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'පරීක්ෂා කළ යුතු ගෙවීම්';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (පැය 24)';
  }

  @override
  String get oCheckWebhook => 'ගෙවීම් දැනුම්දීම් (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'අත්සන් අසමත් $count (පැය 24)';
  }

  @override
  String get oIntegrations => 'බාහිර සේවා';

  @override
  String get oIntNotSet => 'සකසා නැත';

  @override
  String oIntLastOk(String at) {
    return 'අවසන් සාර්ථකත්වය $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'අවසන් අසමත්වීම $at ($code)';
  }

  @override
  String get oIntNever => 'භාවිතයක් තවම නැත';

  @override
  String get oActDb =>
      'දත්ත ගබඩාවට සම්බන්ධ විය නොහැක. සේවාදායකයේ malkkeum logs ධාවනය කරන්න; දිගටම නම් නැවත ආරම්භ කරන්න.';

  @override
  String get oActDisk =>
      'තැටියේ නිදහස් ඉඩ 10% ට අඩුයි. පැරණි උපස්ථ මකන්න හෝ තැටිය වැඩි කරන්න.';

  @override
  String get oActBackup =>
      'ස්වයංක්‍රීය උපස්ථය ප්‍රමාද වී ඇත. සේවාදායකයේ malkkeum backup ධාවනය කර backups/backup.log පරීක්ෂා කරන්න.';

  @override
  String get oActErrors =>
      'සේවාදායක දෝෂ බොහොමයි. malkkeum logs හි error පේළි බලා නැවත නැවත වේ නම් සංවර්ධකයාට යවන්න.';

  @override
  String get oActPayments =>
      'ගෙවීම සිදු වී ඇති නමුත් ස්වයංක්‍රීයව සකසා නැත. PortOne හි පරීක්ෂා කර අවශ්‍ය නම් අතින් ආපසු ගෙවන්න.';

  @override
  String get oActWebhook =>
      'ගෙවීම් දැනුම්දීමේ අත්සන් පරීක්ෂාව අසමත් වේ. සැකසුම් > ගෙවීම් (PortOne) හි webhook secret නැවත ඇතුළු කරන්න.';

  @override
  String get oActIntegration =>
      'මෙම සම්බන්ධතාවය අසමත් වේ. සැකසුම් හි යතුරු පරීක්ෂා කර Test connection ඔබන්න.';

  @override
  String get oActNotSet => 'තවම සකසා නැත. සැකසුම් හි යතුරු ඇතුළු කරන්න.';

  @override
  String get oAlerts => 'ඇඟවීම් සැකසුම්';

  @override
  String get oAlertsHint =>
      'ගැටලු ඇති වූ විට inbox සහ හිමිකරුගේ දුරකථනයට SMS මගින් දන්වයි. එම ගැටලුව පැය 6 කට වරක් පමණි.';

  @override
  String get oRuleSms => 'SMS යැවීම අසමත්';

  @override
  String get oRulePush => 'පුෂ් දැනුම්දීම් අසමත්';

  @override
  String get oRulePayment => 'ගෙවීම් සම්බන්ධතාවය අසමත්';

  @override
  String get oRuleStuck => 'ගෙවීම ස්වයංක්‍රීයව සකසා නැත';

  @override
  String get oRuleSocial => 'සමාජ ජාල පිවිසීම අසමත්';

  @override
  String get oRuleBackup => 'ස්වයංක්‍රීය උපස්ථය මඟ හැරී ඇත';

  @override
  String get oRuleDisk => 'තැටිය පිරී ආසන්නයි';

  @override
  String get oQuietHours => 'නිශ්ශබ්ද වේලා';

  @override
  String get oQuietFrom => 'සිට';

  @override
  String get oQuietTo => 'දක්වා';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'මෙම වේලාවන්හි දැනුම්දීම් නැත; අවසන් වූ පසු එක් පණිවිඩයක් යයි.';

  @override
  String get oAlertPhone => 'ඇඟවීම් ලැබෙන දුරකථනය';

  @override
  String get oAlertPhoneHint => 'හිස්ව තබන්න; ව්‍යාපාර තොරතුරේ සහාය අංකයට යයි.';

  @override
  String get oSave => 'සුරකින්න';

  @override
  String get oSaved => 'ඇඟවීම් සැකසුම් සුරකින ලදි';

  @override
  String get oSaveFailed => 'සුරැකිය නොහැක. අගයන් පරීක්ෂා කරන්න.';

  @override
  String get oLoadFailed => 'තත්ත්වය පූරණය කළ නොහැක';

  @override
  String get oBackupOffsite => 'බාහිර උපස්ථය (S3)';

  @override
  String get oBackupOffsiteOff =>
      'ක්‍රියාවිරහිතයි. සැකසුම් > බාහිර උපස්ථය තුළ ක්‍රියාත්මක කරන්න.';

  @override
  String get oLastBackup => 'අවසන් උපස්ථය';

  @override
  String get oDiskFree => 'නිදහස් ඉඩ';

  @override
  String get oNoData => 'දත්ත තවම නැත';

  @override
  String get cIntBackup => 'බාහිර උපස්ථය (S3 අනුකූල)';

  @override
  String get pTabJobs => 'කාර්යයන්';

  @override
  String get pTabQuotes => 'මගේ මිල ගණන්';

  @override
  String get pTabSchedule => 'කාලසටහන';

  @override
  String get pIntroTitle =>
      'පිරිසිදු කිරීමේ වෘත්තිකයන් සඳහා\nකාර්යයන් · කාලසටහන · ගෙවීම්';

  @override
  String get pIntroBody =>
      'ඔබට අවශ්‍ය ස්ථානයේ සහ වේලාවේදී පමණක් වැඩ කරන්න. සතිපතා ගෙවීම් ලබා ගන්න.';

  @override
  String get pOnbTitle => 'ඔබ ගැන කියන්න';

  @override
  String get pOnbName => 'නායකයාගේ නම';

  @override
  String get pOnbTeam => 'කණ්ඩායමේ නම';

  @override
  String get pOnbServices => 'ඔබ ලබා දෙන සේවා';

  @override
  String get pOnbAreas => 'ඔබ වැඩ කරන ප්‍රදේශ';

  @override
  String get pOnbDone => 'අයදුම්පත යවන්න';

  @override
  String get pPendingTitle => 'ඔබගේ ගිණුම සමාලෝචනය වෙමින් පවතී';

  @override
  String get pPendingBody =>
      'අනුමත වූ පසු අපි ඔබට දන්වන්නෙමු. ඒ දක්වා ගෙවීම් ගිණුම එකතු කරන්න.';

  @override
  String get pSuspended =>
      'ඔබගේ ගිණුම තාවකාලිකව අත්හිටුවා ඇත. කරුණාකර මෙහෙයුම් කණ්ඩායමට සම්බන්ධ වන්න.';

  @override
  String get pDirect => 'සෘජු වෙන්කිරීම';

  @override
  String get pQuoteReq => 'මිල ගණන් ඉල්ලීම්';

  @override
  String get pShowClosed => 'වසා ඇති කාර්යයන් ද පෙන්වන්න';

  @override
  String get pSortNewest => 'අලුත්ම පළමුව';

  @override
  String get pSortVisit => 'ළඟම පැමිණීමේ දිනය පළමුව';

  @override
  String get pSortAmount => 'ඉහළ මුදල පළමුව';

  @override
  String get pNoJobs => 'දැනට ගැළපෙන කාර්යයන් නැත';

  @override
  String get pNoJobsBody =>
      'සේවා, ප්‍රදේශ හෝ වැඩ කරන වේලා පුළුල් කර තවත් කාර්යයන් බලන්න';

  @override
  String get pPayout => 'අපේක්ෂිත ගෙවීම';

  @override
  String get pCustomerEstimate => 'පාරිභෝගික දළ මිල';

  @override
  String get pNew => 'නව';

  @override
  String get pClosed => 'වසා ඇත';

  @override
  String get pPrivacyNote =>
      'නිශ්චිත ලිපිනය සහ පාරිභෝගික විස්තර පිළිගැනීමෙන් පසු පෙන්වයි';

  @override
  String get pAccept => 'කාර්යය පිළිගන්න';

  @override
  String get pAcceptConfirm => 'මෙම කාර්යය පිළිගන්නද?';

  @override
  String get pAcceptBody =>
      'පිළිගත් පසු එය ඔබේ කාලසටහනට එක් වන අතර පාරිභෝගිකයාට කණ්ඩායම පවරා ඇති බව දැනුම් දෙයි. පැමිණීමට දින 2කට පෙර අවලංගු කිරීම සීමිතය.';

  @override
  String get pAccepted => 'කාර්යය පිළිගන්නා ලදී';

  @override
  String get pSendQuote => 'මිල ගණන් යවන්න';

  @override
  String get pQuotePrice => 'පාරිභෝගික මිල';

  @override
  String get pQuoteNote => 'කණ්ඩායමට සටහන';

  @override
  String get pQuoteSent => 'මිල ගණන් යවන ලදී';

  @override
  String pFee(String rate) {
    return 'ගාස්තුව $rate%';
  }

  @override
  String get pYouGet => 'ඔබට ලැබෙන මුදල';

  @override
  String get pQuoteAll => 'සියල්ල';

  @override
  String get pQ_waiting => 'බලා සිටී';

  @override
  String get pQ_selected => 'තෝරා ගත්තා';

  @override
  String get pQ_rejected => 'තෝරා නොගත්තා';

  @override
  String get pQ_closed => 'වසා ඇත';

  @override
  String get pUnseenOnly => 'නව ප්‍රතිඵල පමණි';

  @override
  String get pNoQuotes => 'තවම මිල ගණන් නැත';

  @override
  String get pMyQuote => 'මගේ මිල ගණන';

  @override
  String get pWithdraw => 'මිල ගණන ආපසු ගන්න';

  @override
  String get pWithdrawn => 'මිල ගණන ආපසු ගන්නා ලදී';

  @override
  String get pOnlyMine => 'මගේ පමණයි';

  @override
  String pJobsCount(String n) {
    return 'කාර්යයන් $n';
  }

  @override
  String get pNoSchedule => 'මෙදින කිසිම කාලසටහනක් නැත';

  @override
  String get pCancelledBanner =>
      'පාරිභෝගිකයා මෙම කාර්යය අවලංගු කර ඇත. එය සම්පූර්ණ ලෙස සලකුණු කළ නොහැක.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'වේලාව වෙනස් කිරීමේ ඉල්ලීම: $from → $to';
  }

  @override
  String get pRescheduleOk => 'පැමිණිය හැක';

  @override
  String get pRescheduleNo => 'පැමිණිය නොහැක';

  @override
  String get pCustomer => 'පාරිභෝගිකයා';

  @override
  String get pCall => 'ආරක්ෂිත අංකයෙන් ඇමතුමක්';

  @override
  String get pCallSoon => 'සේවාව ආරම්භ වන විට ආරක්ෂිත ඇමතුම් සක්‍රිය වේ';

  @override
  String get pQuietHours => 'පස් වරුවට පසු ඇමතුම් නොගන්න';

  @override
  String get pAssignee => 'වගකීම් භාර තැනැත්තා';

  @override
  String get pChangeAssignee => 'වගකීම් භාර තැනැත්තා වෙනස් කරන්න';

  @override
  String get pCustomerRequests => 'පාරිභෝගික ඉල්ලීම්';

  @override
  String get pHousehold => 'නිවසේ තොරතුරු';

  @override
  String get pPets => 'සුරතල් සත්ව';

  @override
  String get pPetDog => 'බල්ලා';

  @override
  String get pPetCat => 'බළලා';

  @override
  String get pPetBird => 'කුරුල්ලා';

  @override
  String get pPetFish => 'මාළු';

  @override
  String get pPetOther => 'වෙනත් සත්ව';

  @override
  String get pAllergies => 'අසාත්මිකතා සහ සංවේදීතා';

  @override
  String get pPreferredProducts => 'කැමති නිෂ්පාදන';

  @override
  String get pParking => 'වාහන නැවැත්වීම';

  @override
  String pFloor(String floor) {
    return 'මහල $floor';
  }

  @override
  String get pElevatorYes => 'ලිෆ්ට් ඇත';

  @override
  String get pElevatorNo => 'ලිෆ්ට් නැත';

  @override
  String get pTeamMemo => 'කණ්ඩායම් සටහන (පාරිභෝගිකයාට නොපෙනේ)';

  @override
  String get pMemoSaved => 'සටහන සුරකින ලදී';

  @override
  String get pPayoutBreakdown => 'ගෙවීම';

  @override
  String get pAfterBalance => 'පාරිභෝගිකයා ශේෂය ගෙවීමෙන් පසු ගෙවේ';

  @override
  String get pChatOps => 'මෙහෙයුම් කණ්ඩායම සමඟ කතාබස්';

  @override
  String get pComplete => 'කාර්යය සම්පූර්ණ කරන්න';

  @override
  String get pBeforePhotos => 'පිරිසිදු කිරීමට පෙර ඡායාරූප';

  @override
  String get pAfterPhotos => 'පිරිසිදු කිරීමෙන් පසු ඡායාරූප';

  @override
  String get pAddPhoto => 'ඡායාරූපයක් එකතු කරන්න';

  @override
  String get pChecklist => 'පරීක්ෂා ලැයිස්තුව';

  @override
  String get pCheck1 => 'ඉල්ලූ සියලු ප්‍රදේශ පිරිසිදු කළා';

  @override
  String get pCheck2 => 'කසල කළමනාකරණය කර උපකරණ එකතු කළා';

  @override
  String get pCheck3 => 'ජනෙල්, විදුලිය සහ ජලය පරීක්ෂා කළා';

  @override
  String get pCheck4 => 'පාරිභෝගික ඉල්ලීම් ඉටු කළා';

  @override
  String get pCompleteCta => 'සම්පූර්ණ ලෙස සලකුණු කරන්න';

  @override
  String get pCompleteNeed =>
      'එක් එක් වර්ගයේ ඡායාරූප අවම වශයෙන් 1 බැගින් එකතු කර සියලු අයිතම සලකුණු කරන්න';

  @override
  String get pCompleted => 'විශිෂ්ට වැඩ!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$date ට $amount ගෙවනු ඇත';
  }

  @override
  String get pPayoutWaiting =>
      'පාරිභෝගිකයා ශේෂය ගෙවීමෙන් පසු ගෙවීම් දිනය තීරණය වේ';

  @override
  String get pPendingPayout => 'අපේක්ෂිත ගෙවීම';

  @override
  String get pSettlements => 'ගෙවීම් විස්තර';

  @override
  String get pS_waiting_balance => 'ශේෂය බලා සිටී';

  @override
  String get pS_pending => 'නියමිත';

  @override
  String get pS_paid => 'ගෙවා ඇත';

  @override
  String get pS_held => 'රඳවා ඇත';

  @override
  String get pReviews => 'පාරිභෝගික සමාලෝචන';

  @override
  String get pNoReviews => 'තවම සමාලෝචන නැත';

  @override
  String get pReplyLater => 'සමාලෝචනවලට පිළිතුරු දීමේ පහසුකම ඉක්මනින් එයි';

  @override
  String get pServicesAreas => 'සේවා · ප්‍රදේශ';

  @override
  String get pPayoutAccount => 'ගෙවීම් බැංකු ගිණුම';

  @override
  String get pBank => 'බැංකුව';

  @override
  String get pAccountNumber => 'ගිණුම් අංකය';

  @override
  String get pHolder => 'ගිණුම් හිමිකරු';

  @override
  String get pVerified => 'තහවුරු විය';

  @override
  String get pUnverified => 'පරීක්ෂා වෙමින්';

  @override
  String get pAccountSaved => 'ගිණුම සුරකින ලදී. වෙනස් කළ විට නැවත පරීක්ෂා වේ.';

  @override
  String get pWorkSchedule => 'වැඩ කාලසටහන';

  @override
  String get pWeekdays => 'වැඩ දින';

  @override
  String get pDayParts => 'වැඩ වේලා';

  @override
  String get pDaysOff => 'නිවාඩු දින';

  @override
  String get pAddDayOff => 'නිවාඩු දිනයක් එකතු කරන්න';

  @override
  String get pSaved => 'සුරකින ලදී';

  @override
  String get pTeam => 'කණ්ඩායමේ සාමාජිකයන්';

  @override
  String get pOwner => 'හිමිකරු';

  @override
  String get pInvited => 'ආරාධිතයි';

  @override
  String get pInvite => 'සාමාජිකයෙකු ආරාධනා කරන්න';

  @override
  String get pInviteSent => 'ආරාධනා පණිවිඩය යවන ලදී';

  @override
  String get pRemove => 'ඉවත් කරන්න';

  @override
  String get pNotifications => 'දැනුම්දීම් සැකසුම්';

  @override
  String get pNotifyDirect => 'නව සෘජු වෙන්කිරීම් කාර්යයන්';

  @override
  String get pNotifyQuotes => 'මිල ගණන් ඉල්ලීම් · ප්‍රතිඵල';

  @override
  String get pNotifyChat => 'මෙහෙයුම් කණ්ඩායමේ පණිවිඩ';

  @override
  String get pQuietNight => 'රාත්‍රී නිශ්ශබ්ද කාලය (22–08)';

  @override
  String get pNewInquiry => 'නව විමසීමක්';

  @override
  String get pTopic_settlement => 'ගෙවීම්';

  @override
  String get pTopic_reschedule => 'වේලාව වෙනස් කිරීම · අවලංගු කිරීම';

  @override
  String get pTopic_app => 'යෙදුම් සහාය';

  @override
  String get pOpsTeam => 'මෙහෙයුම් කණ්ඩායම';

  @override
  String get pViewJob => 'කාර්යය බලන්න';

  @override
  String pBookingNo(String n) {
    return 'වෙන්කිරීම $n';
  }

  @override
  String get pSize => 'ප්‍රදේශය';

  @override
  String get pSchedule => 'කාලසටහන';

  @override
  String get pSpace => 'ඉඩ තොරතුරු';

  @override
  String get pNavigate => 'දිශානතිය';

  @override
  String get pNavHint =>
      'සිතියම් යෙදුමේ ගමන් ලිපිනය විවෘත කරයි. යෙදුම නැත්නම් වෙබ් සිතියම විවෘත වේ.';

  @override
  String get pOfflineSaved =>
      'සංඥාව නැත. සුරකින ලද අතර සම්බන්ධ වූ විට යවනු ඇත.';

  @override
  String get pPhotoRetry => 'නැවත උඩුගත කරන්න';

  @override
  String get pPhotoWaiting =>
      'උඩුගත නොවූ ඡායාරූප සම්බන්ධ වූ විට ස්වයංක්‍රීයව යවනු ඇත.';

  @override
  String pUploadedCount(String total, String done) {
    return '$total න් $done උඩුගත කර ඇත';
  }

  @override
  String get cIntPayout => 'හවුල්කරු ගෙවීම්';

  @override
  String get poTabSettlements => 'ගෙවීම්';

  @override
  String get poTabPayouts => 'ගෙවීම් ලබාදීම්';

  @override
  String get poState_requested => 'ඉල්ලුම් කළා';

  @override
  String get poState_sent => 'යවා ඇත';

  @override
  String get poState_paid => 'ගෙවා ඇත';

  @override
  String get poState_failed => 'අසමත්';

  @override
  String get poProviderManual => 'අතින් මාරු කිරීම';

  @override
  String get poProviderToss => 'Toss හරහා ගෙවීම්';

  @override
  String get poShowAccount => 'ගිණුම පෙන්වන්න';

  @override
  String get poAccountTitle => 'මාරු කිරීමේ විස්තර';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '$holder · $bank · $account වෙත $amount වොන් යවා, තහවුරු කරන්න ඔබන්න.';
  }

  @override
  String get poConfirmPaid => 'මාරු කළ ලෙස සලකුණු කරන්න';

  @override
  String get poMarkFailed => 'අසමත් ලෙස සලකුණු කරන්න';

  @override
  String get poReasonTitle => 'අසමත් වීමේ හේතුව';

  @override
  String get poReasonHint => 'උදා: වැරදි ගිණුම, මාරුව අවලංගු';

  @override
  String get poSend => 'Toss හරහා යවන්න';

  @override
  String get poSync => 'තත්ත්වය පරීක්ෂා කරන්න';

  @override
  String get poRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get poNoPayouts => 'තවම ගෙවීම් නැත';

  @override
  String poRequestedToast(String n) {
    return 'ගෙවීම් ඉල්ලීම් $nක් සාදන ලදී';
  }

  @override
  String get poReasonRequired => 'හේතුව ඇතුළත් කරන්න';

  @override
  String get poRevealNote => 'ගිණුම් විස්තර බැලීම සටහන් වේ';

  @override
  String get poSellerAction => 'විකුණුම්කරු ලියාපදිංචි කරන්න';

  @override
  String get poSellerTitle => 'Toss විකුණුම්කරු ලෙස ලියාපදිංචිය';

  @override
  String get poSellerHint =>
      'partner ගේ සත්‍යාපිත ගෙවීම් ගිණුම භාවිතා වේ. ව්‍යාපාර තොරතුරු පමණක් ඇතුළු කරන්න.';

  @override
  String get poSellerIndividual => 'පුද්ගලික';

  @override
  String get poSellerCompany => 'ව්‍යාපාර';

  @override
  String get poSellerName => 'නම';

  @override
  String get poSellerRepresentative => 'නියෝජිතයාගේ නම';

  @override
  String get poSellerRegNo => 'ව්‍යාපාර ලියාපදිංචි අංකය (ඉලක්කම් 10)';

  @override
  String get poSellerEmail => 'ගෙවීම් ඊමේල්';

  @override
  String get poSellerPhone => 'දුරකථන';

  @override
  String get poSellerSubmit => 'ලියාපදිංචි කරන්න';

  @override
  String poSellerDone(String status) {
    return 'විකුණුම්කරුගේ තත්ත්වය: $status';
  }

  @override
  String get pvManage => 'එකඟතා කළමනාකරණය';

  @override
  String get pvOptional => 'විකල්ප';

  @override
  String get pvTerms => 'සේවා නියම එකඟතාව';

  @override
  String get pvPrivacy => 'පුද්ගලික දත්ත එකතු කිරීම සහ භාවිතය සඳහා එකඟතාව';

  @override
  String get pvOverseas => 'පුද්ගලික දත්ත විදේශයට මාරු කිරීම සඳහා එකඟතාව';

  @override
  String get pvMarketing => 'අලෙවිකරණ පණිවිඩ';

  @override
  String get pvMarketingHint =>
      'කූපන් සහ සිදුවීම් පිළිබඳ පණිවිඩ SMS, KakaoTalk සහ යෙදුම් push මගින් ලැබේ. ඕනෑම වේලාවක නවත්වා ගත හැකිය.';

  @override
  String get pvReconsent =>
      'අපේ රහස්‍යතා ප්‍රතිපත්තිය වෙනස් වී ඇත. කරුණාකර නැවත බලා එකඟ වන්න.';

  @override
  String get pvSaved => 'එකඟතා සැකසුම් සුරකින ලදී';

  @override
  String get pvExport => 'මගේ දත්ත බාගන්න';

  @override
  String get pvExportHint =>
      'අප සතු ඔබ පිළිබඳ සියලු දත්ත JSON ආකාරයෙන් පෙන්වයි. පිටපත් කර තබාගත හැකිය.';

  @override
  String get pvCopy => 'පිටපත් කරන්න';

  @override
  String get pvCopied => 'පිටපත් කරන ලදී';

  @override
  String get pvExportFailed =>
      'ඔබේ දත්ත පූරණය කළ නොහැකි විය. කරුණාකර පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get safetyEmergency => 'හදිසි සම්බන්ධතා';

  @override
  String get emergencyPolice => '112 පොලිසිය';

  @override
  String get emergencyFire => '119 ගින්නෙන් ආරක්ෂාව';

  @override
  String get emergencyShop => 'පාරිභෝගික සේවාව';

  @override
  String get caseReportAction => 'ගැටළුවක් වාර්තා කරන්න';

  @override
  String get caseReportTitle => 'කුමක් සිදුවුණාද?';

  @override
  String get caseKindDamage => 'හානි';

  @override
  String get caseKindLoss => 'නැතිවීම';

  @override
  String get caseKindComplaint => 'පැමිණිල්ල';

  @override
  String get caseKindNoShow => 'පිරිසිදුකරු පැමිණියේ නැත';

  @override
  String get caseKindSafety => 'ආරක්ෂක ගැටළුව';

  @override
  String get caseKindPayment => 'ගෙවීම් ආරවුල';

  @override
  String get caseSummaryHint => 'සිදුවූ දේ විස්තර කරන්න (අක්ෂර 300 දක්වා)';

  @override
  String get caseSubmit => 'ඉදිරිපත් කරන්න';

  @override
  String get caseSubmitted => 'ලැබුණා. කණ්ඩායම පැය 24ක් ඇතුළත පිළිතුරු දෙයි.';

  @override
  String get caseFailed => 'යැවිය නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get checkInAction => 'පැමිණීම සටහන් කරන්න';

  @override
  String get checkOutAction => 'ඉවත්වීම සටහන් කරන්න';

  @override
  String checkedInAt(String time) {
    return 'පැමිණියේ $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'ඉවත්වූයේ $time';
  }

  @override
  String get entryCodeAction => 'ඇතුළත් කේතය පෙන්වන්න';

  @override
  String get entryCodeTitle => 'ඇතුළත් කේතය';

  @override
  String get entryCodeNotToday => 'සේවා දිනයේ පමණක් බැලිය හැක';

  @override
  String get entryCodeEmpty => 'ඇතුළත් කේතයක් නැත';

  @override
  String get actionFailed => 'සම්පූර්ණ කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get consoleCasesTitle => 'නඩු පෝලිමය';

  @override
  String get consoleCasesEmpty => 'විවෘත නඩු නැත';

  @override
  String get caseOverdue => 'කල් ඉක්මවා ඇත';

  @override
  String get caseStatusOpen => 'විවෘත';

  @override
  String get caseStatusInvestigating => 'විමර්ශනය වෙමින්';

  @override
  String get caseStatusResolved => 'විසඳා ඇත';

  @override
  String get caseStatusRejected => 'ප්‍රතික්ෂේප කළා';

  @override
  String get caseReassign => 'හවුල්කරු නැවත පවරන්න';

  @override
  String get caseRefund => 'ආපසු ගෙවීම';

  @override
  String get caseHold => 'ගෙවීම රඳවන්න';

  @override
  String get caseNoteHint => 'අභ්‍යන්තර සටහන';

  @override
  String get caseSave => 'සුරකින්න';

  @override
  String get cSetup => 'සැකසුම';

  @override
  String get cSetupTitle => 'දියත් කිරීමට සූදානම';

  @override
  String cSetupProgress(String done, String total) {
    return '$total න් $done ක් අවසන්';
  }

  @override
  String get cSetupAllDone => 'සියල්ල සූදානම්!';

  @override
  String get cSetupBusiness => 'ව්‍යාපාර තොරතුරු';

  @override
  String get cSetupBusinessName => 'සේවාවේ නම';

  @override
  String get cSetupSupportPhone => 'සහාය දුරකථනය';

  @override
  String get cSetupSupportEmail => 'සහාය ඊමේල්';

  @override
  String get cSetupSupportHours => 'සහාය වේලාව';

  @override
  String get cSetupColor => 'සන්නාම වර්ණය';

  @override
  String get cSetupLogo => 'ලාංඡනය උඩුගත කරන්න';

  @override
  String get cSetupCompany => 'සමාගම් තොරතුරු (යෙදුමේ සහ වෙබ් අඩවියේ පහළ)';

  @override
  String get cSetupLegalName => 'නීතිමය නම';

  @override
  String get cSetupCeo => 'නියෝජිත';

  @override
  String get cSetupRegNo => 'ලියාපදිංචි අංකය';

  @override
  String get cSetupMailOrderNo => 'මාර්ගගත විකුණුම් ලියාපදිංචි අංකය';

  @override
  String get cSetupAddress => 'ලිපිනය';

  @override
  String get cSetupPrivacyOfficer => 'පෞද්ගලිකත්ව නිලධාරී';

  @override
  String get cSetupStoreLinks =>
      'ස්ටෝර් සබැඳි (පුරවූ පසු වෙබ් බොත්තම් සක්‍රිය වේ)';

  @override
  String get cSetupCustomerApp => 'පාරිභෝගික යෙදුම';

  @override
  String get cSetupPartnerApp => 'හවුල්කරු යෙදුම';

  @override
  String get cSetupPayMethods => 'ගෙවීම් ක්‍රම';

  @override
  String get cSetupPayMethodsHint =>
      'පාරිභෝගිකයන්ට පෙනෙන ගෙවීම් ක්‍රම සක්‍රිය/අක්‍රිය කරන්න. වහාම යෙදේ.';

  @override
  String get cReviewTitle => 'ස්ටෝර් සමාලෝචන ආදර්ශ ගිණුම';

  @override
  String get cReviewHint =>
      'සමාලෝචකයින්ට කොරියානු SMS ලැබෙන්නේ නැත. අංකය සහ ඉලක්කම් 6 කේතය සමාලෝචන සටහනේ ලියන්න. ස්වයංක්‍රීයව අක්‍රිය වේ.';

  @override
  String get cReviewPhone => 'ආදර්ශ දුරකථන අංකය';

  @override
  String get cReviewCode => 'ස්ථිර කේතය (ඉලක්කම් 6)';

  @override
  String cReviewActiveUntil(String date) {
    return '$date දක්වා සක්‍රිය';
  }

  @override
  String get cReviewEnable => 'සක්‍රිය කරන්න (දින 14)';

  @override
  String get pDeleteAccountBody =>
      'ඔබේ කණ්ඩායම සහ පුද්ගලික දත්ත ස්ථිරවම මැකේ. පවරා ඇති කාර්ය සහ ඉතිරි ගෙවීම් පළමුව අවසන් කරන්න.';

  @override
  String get err_has_active_jobs =>
      'ඔබට පවරා ඇති කාර්ය තිබේ. ඒවා අවසන් කරන්න හෝ සහාය ලබාගන්න.';

  @override
  String get err_pending_payouts =>
      'ගෙවීමක් තවම ඉතිරිය. ගෙවූ පසු ගිණුම මැකිය හැක.';

  @override
  String get err_phone_required =>
      'කාර්ය ලබා ගැනීමට පෙර දුරකථන අංකය තහවුරු කරන්න.';

  @override
  String get nAlerts => 'දැනුම්දීම්';

  @override
  String get nEmpty => 'තවම දැනුම්දීම් නැත';

  @override
  String nUnread(String count) {
    return 'නොකියවූ $count';
  }

  @override
  String get pVerifyPhone => 'තහවුරු කරන්න';

  @override
  String get mMyJobs => 'මගේ කාර්ය';

  @override
  String get mNoJobs =>
      'තවම පවරා ඇති කාර්ය නැත. කණ්ඩායම් නායකයා පවරන කාර්ය මෙහි පෙන්වයි.';

  @override
  String mTeam(String team) {
    return '$team සාමාජික';
  }

  @override
  String get cSetupSave => 'සුරකින්න';

  @override
  String get cSetupSaved => 'සුරැකිණි';

  @override
  String get cSetupTest => 'සම්බන්ධතාව පරීක්ෂා කරන්න';

  @override
  String get cSetupClear => 'විසන්ධි කරන්න';

  @override
  String get cSetupConnected => 'සම්බන්ධයි';

  @override
  String get cSetupNotConnected => 'සම්බන්ධ නැත';

  @override
  String get cSetupFromEnv => 'සේවාදායක සැකසුම් භාවිතයේ';

  @override
  String get cSetupCheckInApp => 'සුරැකිණි · යෙදුමෙන් පිවිසී තහවුරු කරන්න';

  @override
  String get cSetupInvalidKey =>
      'යතුර ප්‍රතික්ෂේප විය. පිටපත් කළ අගය පරීක්ෂා කරන්න';

  @override
  String get cSetupUnreachable => 'සේවාවට ළඟා විය නොහැක. පසුව උත්සාහ කරන්න';

  @override
  String get cSetupKeepValue => 'සුරැකිණි (වෙනස් කිරීමට පමණක් ඇතුළත් කරන්න)';

  @override
  String get cSetupGuide => 'සකසන ආකාරය';

  @override
  String get cSetupOpenSite => 'අඩවිය විවෘත කරන්න';

  @override
  String get cSetupWebhook => 'Webhook ලිපිනය (PortOne කොන්සෝලයට අලවන්න)';

  @override
  String get cCopied => 'පිටපත් විය';

  @override
  String get cSetupDevMode => 'පරීක්ෂණ මාදිලිය: සැබෑ ගෙවීම් හෝ පණිවිඩ නොයවයි';

  @override
  String get cSetupOptional => 'විකල්ප';

  @override
  String get cIntPortone => 'ගෙවීම් (PortOne)';

  @override
  String get cIntSolapi => 'SMS සහ KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'යෙදුම් දැනුම්දීම් (Firebase)';

  @override
  String get cIntKakao => 'Kakao පිවිසුම';

  @override
  String get cIntNaver => 'Naver පිවිසුම';

  @override
  String get cIntGoogle => 'Google පිවිසුම';

  @override
  String get cIntApple => 'Apple පිවිසුම';

  @override
  String get cFirstRunTitle => 'සාදරයෙන් පිළිගනිමු! හිමිකරු ගිණුම සාදන්න';

  @override
  String get cFirstRunBody =>
      'ස්ථාපනයේදී පෙන්වූ අකුරු 12 කේතය ඇතුළත් කරන්න. මෙම ගිණුම සියලු සැකසුම් කළමනාකරණය කරයි.';

  @override
  String get cFirstRunCode => 'සැකසුම් කේතය';

  @override
  String get cName => 'නම';

  @override
  String get cFirstRunCreate => 'ගිණුම සාදා අරඹන්න';

  @override
  String get cWrongSetupCode => 'සැකසුම් කේතය වැරදියි';

  @override
  String get cWeakPassword => 'මුරපදයට අවම අකුරු 12 ක් අවශ්‍යයි';

  @override
  String get cInvalidValue => 'කරුණාකර අගය පරීක්ෂා කරන්න';

  @override
  String get subTitle => 'නිතිපතා පිරිසිදු කිරීම';

  @override
  String get subNew => 'දායකත්වය ආරම්භ කරන්න';

  @override
  String get subCadence => 'කෙතරම් නිතර ද';

  @override
  String get subWeekly => 'සෑම සතියකම';

  @override
  String get subBiweekly => 'සෑම සති 2කට වරක්';

  @override
  String get subEvery4Weeks => 'සෑම සති 4කට වරක්';

  @override
  String get subWeekday => 'සතියේ දිනය';

  @override
  String get subHour => 'පැමිණෙන වේලාව';

  @override
  String subDiscountNote(String percent) {
    return 'සෑම පැමිණීමකටම $percent% වට්ටමක්';
  }

  @override
  String get subChargeNote => 'පැමිණීමට දින 1කට පෙර සුරකින ලද කාඩ්පතෙන් ගෙවයි';

  @override
  String get subCreate => 'දායක වන්න';

  @override
  String get subCreated => 'දායකත්වය ආරම්භ විය';

  @override
  String get subNeedAddress => 'මුලින් පැමිණෙන ලිපිනය එක් කරන්න';

  @override
  String get subListEmpty => 'දායකත්ව තවම නැත';

  @override
  String get subStatusActive => 'සක්‍රිය';

  @override
  String get subStatusPaused => 'විරාමයි';

  @override
  String get subStatusCancelled => 'අවලංගු කළා';

  @override
  String subNextVisit(String date) {
    return 'ඊළඟ පැමිණීම $date';
  }

  @override
  String get subPause => 'විරාම ගන්න';

  @override
  String get subResume => 'නැවත ආරම්භ කරන්න';

  @override
  String get subCancelSub => 'දායකත්වය අවලංගු කරන්න';

  @override
  String get subCancelConfirm =>
      'ඉදිරි පැමිණීම් අවලංගු වේ. වෙන්කළ පැමිණීම් වෙනමම අවලංගු කළ යුතුයි.';

  @override
  String get subSkip => 'මෙම පැමිණීම මඟ හරින්න';

  @override
  String get subMove => 'දිනය වෙනස් කරන්න';

  @override
  String get subVisitLocked => 'පැමිණීමට පෙර දිනයේ සිට වෙනස් කළ නොහැක';

  @override
  String get subPausedPayment =>
      'නැවත නැවත ගෙවීම් අසාර්ථක වීමෙන් විරාමයි. කාඩ්පත වෙනස් කර නැවත ආරම්භ කරන්න.';

  @override
  String get subStatePlanned => 'සැලසුම් කළ';

  @override
  String get subStateBooked => 'වෙන් කළ';

  @override
  String get subStateSkipped => 'මඟ හැරියා';

  @override
  String get subStateMissed => 'මග ඇරුණා';

  @override
  String get pSubsTitle => 'නිතිපතා පාරිභෝගිකයින්';

  @override
  String get pSubsEmpty => 'නිතිපතා පාරිභෝගිකයින් තවම නැත';

  @override
  String get cSubsTitle => 'දායකත්ව';

  @override
  String get cSubsEdit => 'පාරිභෝගිකයා වෙනුවෙන් සංස්කරණය';

  @override
  String get cMrr => 'මාසික නැවත එන ආදායම (MRR)';

  @override
  String get cChurn => 'අහිමි වීමේ අනුපාතය';

  @override
  String get cActiveSubs => 'සක්‍රිය දායකත්ව';

  @override
  String get cRecognized => 'කාලසීමාවේ පිළිගත් ආදායම';

  @override
  String get cSubsLoadFailed => 'දායකත්ව පූරණය කළ නොහැකි විය';

  @override
  String get tTaxSection => 'බදු';

  @override
  String tVatQuarter(String q) {
    return 'Q$q VAT CSV';
  }

  @override
  String get tVatYear => 'වර්ෂය';

  @override
  String get tExportWithholding => 'අය කිරීම් ප්‍රකාශය CSV';

  @override
  String get tExportTaxInvoices => 'බදු ඉන්වොයිසි උඩුගත කිරීම CSV';

  @override
  String get tTaxLayoutNote =>
      'උඩුගත කිරීමට පෙර 홈택스 සැකිල්ල සමඟ තීරු පරීක්ෂා කරන්න. පිරිසැලසුම තවම තහවුරු වී නැත.';

  @override
  String get tCashReceipts => 'මුදල් රිසිට්පත්';

  @override
  String get tCashIssued => 'නිකුත් කළා';

  @override
  String get tCashFailed => 'අසාර්ථකයි';

  @override
  String get tCashPending => 'බලාපොරොත්තුවෙන්';

  @override
  String get tCashCancelled => 'අවලංගු කළා';

  @override
  String get tReissue => 'නැවත නිකුත් කරන්න';

  @override
  String get tTaxInvoices => 'බදු ඉන්වොයිසි';

  @override
  String get tApprovalNumber => 'අනුමැතිය අංකය';

  @override
  String get tIssuedOn => 'නිකුත් කළ දිනය';

  @override
  String get tMarkIssued => 'නිකුත් කළ ලෙස සලකුණු කරන්න';

  @override
  String get tQueueEmpty => 'බලාපොරොත්තු ඉල්ලීම් නැත';

  @override
  String get tWithholdingLabel => 'අය කිරීම';

  @override
  String get tGrossAmount => 'සමස්ත';

  @override
  String get tIncomeTax => 'ආදායම් බදු';

  @override
  String get tLocalTax => 'දේශීය ආදායම් බදු';

  @override
  String get tNetAmount => 'ශුද්ධ';

  @override
  String get tNoWithholding => 'අය කිරීමක් නැත (ලියාපදිංචි ව්‍යාපාරය)';

  @override
  String get tEstWithholding => 'ඇස්තමේන්තුගත අය කිරීම (ගෙවීමට ඇති)';

  @override
  String get tReceiptOptions => 'රිසිට්පත් විකල්ප';

  @override
  String get tWantCashReceipt => 'මුදල් රිසිට්පතක් ලබාගන්න';

  @override
  String get tCashForIncome => 'බදු අඩුකිරීම සඳහා (දුරකථන අංකය)';

  @override
  String get tCashForBusiness => 'ව්‍යාපාර වියදම් සඳහා (ව්‍යාපාර අංකය)';

  @override
  String get tWantTaxInvoice => 'බදු ඉන්වොයිසියක් ලබාගන්න (ව්‍යාපාර)';

  @override
  String get tPhoneForReceipt => 'දුරකථන අංකය';

  @override
  String get tBusinessNumber => 'ව්‍යාපාර ලියාපදිංචි අංකය';

  @override
  String get tCompanyName => 'සමාගමේ නම';

  @override
  String get tRepresentative => 'නියෝජිතයා';

  @override
  String get tInvoiceEmail => 'ඉන්වොයිසිය සඳහා ඊමේල්';

  @override
  String get tReceiptSave => 'සුරකිත් ගෙවන්න';

  @override
  String get tReceiptSaveFailed => 'රිසිට්පත් විස්තර සුරැකීමට නොහැකි විය';

  @override
  String get tTaxType => 'බදු වර්ගය';

  @override
  String get tTaxFreelancer => 'ස්වාධීන (අය කිරීමෙන්)';

  @override
  String get tTaxBusiness => 'ලියාපදිංචි ව්‍යාපාරය (අය කිරීමක් නැත)';

  @override
  String get tReceiptSettings => 'රිසිට්පත් සැකසුම්';

  @override
  String get reviewRuleLine =>
      'අපහාසාත්මක වචන, පෞද්ගලික තොරතුරු, ව්‍යාජ හෝ ප්‍රචාරක අන්තර්ගතය තහනම්ය. වාර්තා කළ සමාලෝචන සඟවනු ඇත.';

  @override
  String get reportAction => 'වාර්තා කරන්න';

  @override
  String get reportSheetTitle => 'මෙම සමාලෝචනය වාර්තා කරන්නද?';

  @override
  String get reportReasonSpam => 'අවශ්‍ය නැති තැපැල් හෝ දැන්වීම';

  @override
  String get reportReasonOffensive => 'අපහාස හෝ වෛරය';

  @override
  String get reportReasonPersonal => 'පෞද්ගලික තොරතුරු අඩංගුයි';

  @override
  String get reportReasonOther => 'වෙනත්';

  @override
  String get reportNoteHint => 'විස්තර (විකල්ප, අක්ෂර 300 දක්වා)';

  @override
  String get reportSubmit => 'වාර්තාව යවන්න';

  @override
  String get reportThanks => 'ස්තූතියි. අපගේ කණ්ඩායම එය සමාලෝචනය කරයි.';

  @override
  String get reportAlready => 'ඔබ මෙම සමාලෝචනය දැනටමත් වාර්තා කර ඇත';

  @override
  String get reportFailed => 'වාර්තාව යැවීම අසාර්ථකයි. නැවත උත්සාහ කරන්න.';

  @override
  String get reviewBlocked =>
      'මෙම ගිණුමෙන් සමාලෝචන කළ නොහැක. සහාය සමග සම්බන්ධ වන්න.';

  @override
  String get modTitle => 'වාර්තා කළ සමාලෝචන';

  @override
  String get modEmpty => 'බලාපොරොත්තු වන වාර්තා නොමැත';

  @override
  String modReports(String count) {
    return 'වාර්තා $count';
  }

  @override
  String get modKeep => 'තබන්න';

  @override
  String get modHide => 'සඟවන්න';

  @override
  String get modDelete => 'මකන්න';

  @override
  String get modBlockAuthor => 'කර්තෘ සීමා කරන්න';

  @override
  String get modUnblockAuthor => 'සීමාව ඉවත් කරන්න';

  @override
  String get modDone => 'නිමයි';

  @override
  String get modFailed => 'සිදු කළ නොහැක. නැවත උත්සාහ කරන්න.';

  @override
  String get modHidden => 'සඟවන ලද සමාලෝචනය';

  @override
  String uUpdateBanner(String version) {
    return 'නව අනුවාදය $version ලැබී ඇත';
  }

  @override
  String get uUpdateNow => 'යාවත්කාලීන කරන්න';

  @override
  String get uUpdateLater => 'පසුව';

  @override
  String get uUpdateRequiredTitle => 'යාවත්කාලීනයක් අවශ්‍යයි';

  @override
  String get uUpdateRequiredBody =>
      'මෙම අනුවාදය තවදුරටත් සහාය නොදක්වයි. කරුණාකර ගබඩාවෙන් යාවත්කාලීන කරන්න.';

  @override
  String get uUpdateStore => 'ගබඩාවෙන් යාවත්කාලීන කරන්න';

  @override
  String get uUpdateStoreMissing =>
      'යාවත්කාලීන සබැඳිය තවම සූදානම් නැත. පසුව නැවත උත්සාහ කරන්න.';

  @override
  String uCurrentVersion(String version) {
    return 'වත්මන් අනුවාදය $version';
  }

  @override
  String get uAppVersionTitle => 'යෙදුම් අනුවාද';

  @override
  String get uAppVersionHint =>
      'අවම අනුවාදයට පහළ යෙදුම් යාවත්කාලීන තිරයේ නතර වේ. උදාහරණ: 1.2.0';

  @override
  String get uMinVersion => 'අවම අනුවාදය';

  @override
  String get uLatestVersion => 'නවතම අනුවාදය';

  @override
  String get webBookNow => 'වෙබ් අඩවියෙන් වහාම වෙන් කරන්න';

  @override
  String get webBookSub => 'යෙදුම ස්ථාපනය නොකර';

  @override
  String get apPgBrowserNote =>
      'බ්‍රව්සරයෙන් ගෙවීම සම්පූර්ණ කර, මෙතැනට ආපසු ඇවිත් පහත බොත්තම ඔබන්න.';

  @override
  String get apPgBrowserDone => 'ගෙවීම අවසන් කළෙමි';
}
