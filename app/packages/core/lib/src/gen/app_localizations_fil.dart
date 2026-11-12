// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class TFil extends T {
  TFil([String locale = 'fil']) : super(locale);

  @override
  String get addressSearch => 'Maghanap ng address';

  @override
  String get addressSearchHint =>
      'Maghanap sa pangalan ng kalsada, gusali o lot';

  @override
  String get addressSearchButton => 'Hanapin';

  @override
  String get addressSearchMinChars => 'Maglagay ng hindi bababa sa 2 karakter';

  @override
  String get addressNoResults => 'Walang resulta. Subukan ang ibang salita.';

  @override
  String get addressManualEntry => 'Ilagay nang manwal';

  @override
  String get cardRegisterTitle => 'Magrehistro ng card';

  @override
  String get cIntJuso => 'Paghahanap ng address (juso.go.kr)';

  @override
  String get aiLabel => 'AI na katulong';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Awtomatikong sumasagot sa chat ng mga customer. May bayad sa API ang bawat mensahe.';

  @override
  String get aiModeOffline => 'Sumagot lang kapag walang staff';

  @override
  String get aiModeAlways => 'Laging unang sumasagot ang AI';

  @override
  String get aiPause => 'I-pause ang AI';

  @override
  String get aiResume => 'Ipagpatuloy ang AI';

  @override
  String get aiPausedNote => 'Naka-pause ang AI sa chat na ito';

  @override
  String aiUsageMonth(String count) {
    return 'Mga tawag sa AI ngayong buwan: $count';
  }

  @override
  String get aiNotConfigured => 'Naka-off ang AI na tagasagot';

  @override
  String get aiCapThreadLabel => 'Limitasyon ng sagot kada chat bawat oras';

  @override
  String get aiCapMemberLabel => 'Limitasyon ng sagot kada customer bawat araw';

  @override
  String get aiCapDailyLabel => 'Limitasyon ng sagot bawat araw, lahat ng chat';

  @override
  String get aiCapHint => 'Numero lang. Iwan na blangko para sa default.';

  @override
  String get apSocialOr => 'o';

  @override
  String get apSocialSignIn => 'Mabilis na pag-sign in';

  @override
  String get apLoginKakao => 'Magpatuloy gamit ang Kakao';

  @override
  String get apLoginNaver => 'Magpatuloy gamit ang Naver';

  @override
  String get apLoginGoogle => 'Magpatuloy gamit ang Google';

  @override
  String get apLoginApple => 'Magpatuloy gamit ang Apple';

  @override
  String get apDevSocialNote =>
      'Dev mode po ito. Test account ang gagamitin sa pag-login, hindi totoong social account.';

  @override
  String get apSocialFailed =>
      'Hindi natuloy ang mabilis na pag-sign in. Pakisubukang muli.';

  @override
  String get apProviderNotConfigured =>
      'Hindi pa available ang paraan ng pag-login na ito';

  @override
  String get apPhoneTaken => 'Nakakabit na sa ibang account ang numerong ito';

  @override
  String get apPhoneAttachTitle => 'I-verify ang iyong mobile number';

  @override
  String get apPhoneAttachBody =>
      'Ginagamit ang numerong ito para sa booking at pakikipag-ugnayan sa pro. One-time check lang po ito.';

  @override
  String get apPayAllTitle => 'Pumili ng paraan ng bayad';

  @override
  String get apPaySavedTitle => 'Mga naka-save na paraan';

  @override
  String get apPayMoreTitle => 'Lahat ng paraan ng bayad';

  @override
  String get apPayBillingHint =>
      'I-save minsan, tapos isang tap na lang sa susunod';

  @override
  String get apPayCheckoutHint => 'Tapusin sa payment window';

  @override
  String get apPayRegistering => 'Nire-register…';

  @override
  String get apPayManageHint =>
      'Mag-bayad nang isang tap gamit ang naka-save na paraan. Dito mo maidadagdag ang mga quick-pay.';

  @override
  String get apMethodCard => 'Credit at debit card';

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
  String get apMethodTransfer => 'Paglipat sa bangko';

  @override
  String get apMethodVirtual => 'Virtual na account';

  @override
  String get apMethodPhone => 'Bayad sa mobile bill';

  @override
  String get apMethodUnknown => 'Iba pa';

  @override
  String get apVaTitle => 'Handa na ang deposit account mo';

  @override
  String get apVaWaiting => 'Naghihintay ng deposit';

  @override
  String get apVaBody =>
      'Makukumpirma ang booking kapag pumasok ang deposit sa loob ng takdang oras. Awtomatiko itong chine-check.';

  @override
  String get apVaBank => 'Bangko';

  @override
  String get apVaAccount => 'Numero ng account';

  @override
  String get apVaHolder => 'May-ari ng account';

  @override
  String get apVaAmount => 'Halaga';

  @override
  String apVaDue(String due) {
    return 'Mag-deposit bago ang $due';
  }

  @override
  String get apVaCopy => 'Kopyahin';

  @override
  String get apVaCopied => 'Nakopya na ang account number';

  @override
  String get apVaBannerTitle => 'May booking na naghihintay ng deposit';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · bago ang $due';
  }

  @override
  String get apVaBannerAction => 'Tingnan ang account';

  @override
  String get apPgTitle => 'Bintana ng bayad';

  @override
  String get apPgDevNote =>
      'Simulation lang ito ng bayad para sa dev environment. Walang totoong sisingilin.';

  @override
  String apPgPay(String amount) {
    return 'Bayaran ang $amount';
  }

  @override
  String get apPgIssue => 'Kunin ang account number';

  @override
  String get apPgCancel => 'Kanselahin ang bayad';

  @override
  String get apErrSlotFullRefunded =>
      'Napuno na ang oras na iyon, kaya awtomatikong kinansela ang bayad mo';

  @override
  String get apErrCheckoutExpired =>
      'Nag-expire na ang payment window. Pakisubukang muli.';

  @override
  String get apIdentityTitle => 'Pagpapatunay ng pagkakakilanlan (PASS)';

  @override
  String get apIdentityBody =>
      'Kinukumpirma ka gamit ang pangalan sa mobile carrier mo. Ginagamit ito para sa ligtas na transaksyon at bayad.';

  @override
  String get apIdentityAction => 'I-verify ang identity';

  @override
  String get apIdentityDone => 'Na-verify na ang identity';

  @override
  String get apIdentityVerified => 'Napatunayan';

  @override
  String get apIdentityUnverified => 'Hindi pa na-verify';

  @override
  String get apIdentityDevTitle => 'Test na pagpapatunay ng pagkakakilanlan';

  @override
  String get apIdentityDevBody =>
      'Sa dev environment, pumapasa ito nang walang totoong check.';

  @override
  String get apIdentityDevPass => 'Ipasa';

  @override
  String get apPayManageTitle => 'Magparehistro ng quick-pay';

  @override
  String get cTitle => 'Console ng operasyon';

  @override
  String get cEmail => 'Email';

  @override
  String get cPassword => 'Password';

  @override
  String get cLogin => 'Mag-sign in';

  @override
  String get cLoginFailed => 'Mali ang email o password';

  @override
  String get cDashboard => 'Dashboard';

  @override
  String get cBookings => 'Mga booking';

  @override
  String get cQuoteDesk => 'Desk ng quote';

  @override
  String get cInbox => 'Mga mensahe';

  @override
  String get cCatalog => 'Catalog at presyo';

  @override
  String get cMarketing => 'Coupons at content';

  @override
  String get cPartners => 'Mga partner';

  @override
  String get cSettlements => 'Mga settlement';

  @override
  String get cCustomers => 'Mga customer';

  @override
  String get cStaff => 'Tauhan';

  @override
  String get cSearchCommand => 'Maghanap o lumipat';

  @override
  String get cPaletteHint => 'I-type ang section o booking number';

  @override
  String get cTodayJobs => 'Trabaho ngayon';

  @override
  String get cOpenQuotes => 'Mga bukas na quote';

  @override
  String get cUnassigned => 'Walang naka-assign';

  @override
  String get cUnreadThreads => 'Mga hindi pa nababasang chat';

  @override
  String get cRevenue30 => 'Kita sa nakaraang 30 araw';

  @override
  String get cBookings30 => 'Booking sa nakaraang 30 araw';

  @override
  String get cByService => 'Booking kada serbisyo (30 araw)';

  @override
  String get cAllStatus => 'Lahat ng status';

  @override
  String get cAllServices => 'Lahat ng serbisyo';

  @override
  String get cSearch => 'Maghanap (number, phone, pangalan, address)';

  @override
  String get cNoResults => 'Walang resulta';

  @override
  String get cNumber => 'Numero';

  @override
  String get cVisit => 'Bisita';

  @override
  String get cService => 'Serbisyo';

  @override
  String get cStatus => 'Katayuan';

  @override
  String get cTeam => 'Koponan';

  @override
  String get cAmount => 'Halaga';

  @override
  String get cCustomer => 'Kliyente';

  @override
  String get cPayments => 'Mga bayad';

  @override
  String get cChangeStatus => 'Palitan ang status';

  @override
  String get cTeamName => 'Pangalan ng naka-assign na team';

  @override
  String get cAssign => 'I-assign ang team';

  @override
  String get cMarkDone => 'Markahan bilang tapos';

  @override
  String get cConfirm => 'Markahan bilang kumpirmado';

  @override
  String get cCancelRefund => 'Kanselahin at i-refund';

  @override
  String get cRefundAmount => 'Halaga ng refund (iwanang blangko para sa buo)';

  @override
  String get cDone => 'Tapos na';

  @override
  String get cAnswers => 'Mga sagot ng customer';

  @override
  String get cEstimateCalc => 'Awtomatikong kalkulasyon';

  @override
  String get cBase => 'Batayan';

  @override
  String get cExtras => 'Dagdag';

  @override
  String get cSurcharge => 'Dagdag na singil';

  @override
  String get cBeforeVat => 'Bago ang VAT';

  @override
  String get cProQuotes => 'Mga quote ng partner';

  @override
  String get cNoProQuotes => 'Wala pang quote mula sa partner';

  @override
  String get cFinalPrice => 'Final na presyo sa customer';

  @override
  String get cQuoteNote => 'Note para sa customer';

  @override
  String get cSendQuote => 'Ipadala ang quote sa customer';

  @override
  String get cQuoteSent => 'Naipadala na ang quote';

  @override
  String get cCustomerChats => 'Chat ng customer';

  @override
  String get cPartnerChats => 'Chat ng partner';

  @override
  String get cSelectBooking => 'Pumili ng booking';

  @override
  String get cRefunded => 'Na-refund';

  @override
  String get cPartRefunded => 'Bahagyang na-refund';

  @override
  String get cFailed => 'Pumalya';

  @override
  String get cSelectThread => 'Pumili ng usapan';

  @override
  String get cReplyHint => 'Mag-reply · Ctrl+Enter para ipadala';

  @override
  String get cOpenBooking => 'Buksan ang booking';

  @override
  String get cShortcuts => 'J/K gumalaw · Ctrl+K command';

  @override
  String get cPricing => 'Presyo';

  @override
  String get cMinutes => 'Tagal (min)';

  @override
  String get cActive => 'Aktibo';

  @override
  String get cSaved => 'Na-save';

  @override
  String get cSlotCapacity => 'Kapasidad kada arrival slot';

  @override
  String get cUnlimited => 'Walang limitasyon';

  @override
  String get cFormula => 'Formula ng quote';

  @override
  String get cTabCancelPolicy => 'Patakaran sa pagkansela';

  @override
  String get cPolicyDefaultBanner =>
      'Ito ang default. Pakisuri at i-save para makumpirma.';

  @override
  String get cPolicyDaysBefore => 'Ilang araw bago ang bisita (mula)';

  @override
  String get cPolicyPercent =>
      'Bayad % (blangko = hindi maaaring kanselahin sa app)';

  @override
  String get cPolicyMinFee => 'Pinakamababang bayad (KRW)';

  @override
  String get cPolicyReschedule =>
      'Puwedeng i-reschedule (ilang araw bago ang bisita)';

  @override
  String get cPolicyHint =>
      'Agad itong makikita sa cancel screen ng app ng customer. Ma-a-update ang mga tuntunin sa susunod na legal build.';

  @override
  String get f_base_studio => 'Batayan: studio';

  @override
  String get f_base_one_and_half => 'Batayan: 1.5 kuwarto';

  @override
  String get f_base_two_rooms => 'Batayan: 2 kuwarto';

  @override
  String get f_base_three_rooms => 'Batayan: 3 kuwarto';

  @override
  String get f_base_four_plus => 'Batayan: 4+ kuwarto';

  @override
  String get f_per_extra_bathroom => 'Kada karagdagang banyo';

  @override
  String get f_per_balcony => 'Kada balkonahe';

  @override
  String get f_duplex => 'Duplex';

  @override
  String get f_no_elevator_high_floor => 'Walang elevator at 3rd floor pataas';

  @override
  String get cIssueCoupon => 'Mag-issue ng coupon';

  @override
  String get cCouponName => 'Pangalan ng coupon';

  @override
  String get cCouponPhones => 'Mga phone number (isa kada linya)';

  @override
  String get cAllCustomers => 'Lahat ng customer';

  @override
  String cIssued(String n) {
    return '$n ang na-issue';
  }

  @override
  String get cContent => 'Nilalaman';

  @override
  String get cKind_notice => 'Paunawa';

  @override
  String get cKind_tip => 'Payo';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Banner';

  @override
  String get cKind_legal => 'Tuntunin';

  @override
  String get cNewContent => 'Bagong content';

  @override
  String get cTitleField => 'Pamagat';

  @override
  String get cBodyField => 'Nilalaman';

  @override
  String get cSlug => 'Slug (tuntunin: privacy / terms)';

  @override
  String get cVerify => 'I-approve';

  @override
  String get cSuspend => 'I-suspend';

  @override
  String get cPro_pending => 'Naghihintay ng approval';

  @override
  String get cPro_verified => 'Aktibo';

  @override
  String get cPro_suspended => 'Na-suspend';

  @override
  String get cCompleted => 'Tapos';

  @override
  String get cCancelledN => 'Kinansela';

  @override
  String get cRating => 'Rating';

  @override
  String get cFeeRate => 'Bayarin %';

  @override
  String get cRunPayouts => 'Patakbuhin ang payouts';

  @override
  String get cPayoutDate => 'Petsa ng payout (hanggang)';

  @override
  String cPayoutDone(String n) {
    return 'Na-process ang payout para sa $n partner';
  }

  @override
  String get cHold => 'I-hold';

  @override
  String get cRelease => 'I-release';

  @override
  String get cNet => 'Net na payout';

  @override
  String get cAddStaff => 'Magdagdag ng staff';

  @override
  String get cRoleAdmin => 'Tagapamahala';

  @override
  String get cRoleConsultant => 'Konsultant';

  @override
  String get cDeactivate => 'I-deactivate';

  @override
  String get cActivate => 'I-activate';

  @override
  String get cPasswordRule => 'Hindi bababa sa 12 character';

  @override
  String get cAdminOnly => 'Para sa admin lang';

  @override
  String cBookingsCount(String n) {
    return '$n na booking';
  }

  @override
  String get cJoined => 'Sumali noong';

  @override
  String get cNewBooking => 'May bagong booking';

  @override
  String get cNewMessage => 'Bagong mensahe';

  @override
  String get cConfirmAsk => 'Sigurado ka ba?';

  @override
  String get ok => 'Sige';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get next => 'Susunod';

  @override
  String get close => 'Isara';

  @override
  String get save => 'I-save';

  @override
  String get delete => 'Burahin';

  @override
  String get edit => 'I-edit';

  @override
  String get change => 'Palitan';

  @override
  String get retry => 'Subukan ulit';

  @override
  String get yes => 'Oo';

  @override
  String get no => 'Hindi';

  @override
  String get required => 'Kailangan';

  @override
  String get viewAll => 'Tingnan lahat';

  @override
  String get today => 'Ngayon';

  @override
  String get errorGeneric =>
      'May nangyaring problema. Pakisubukan ulit maya-maya.';

  @override
  String get errorNetwork => 'Pakitingnan ang internet connection mo';

  @override
  String get err_invalid_phone => 'Pakitingnan ang mobile number mo';

  @override
  String get err_otp_invalid => 'Mali ang verification code';

  @override
  String get err_otp_expired =>
      'Nag-expire na ang verification code. Humingi ng bago.';

  @override
  String get err_rate_limited =>
      'Sobrang dami ng attempt. Subukan ulit maya-maya.';

  @override
  String get err_studio_too_large =>
      'Para lang sa bahay na hanggang 10 pyeong ang studio cleaning';

  @override
  String get err_date_out_of_range =>
      'Pumili ng petsa mula bukas hanggang 60 araw';

  @override
  String get err_slot_full => 'Napuno na ang oras na iyon. Pumili ng iba.';

  @override
  String get err_coupon_expired => 'Expired na ang coupon na ito';

  @override
  String get err_coupon_used => 'Nagamit na ang coupon na ito';

  @override
  String get err_coupon_wrong_service =>
      'Hindi puwedeng gamitin ang coupon na ito sa serbisyong ito';

  @override
  String get err_payment_failed =>
      'Hindi inaprubahan ang bayad. Subukan ang ibang paraan ng bayad.';

  @override
  String get err_payment_method_required => 'Pumili ng paraan ng bayad';

  @override
  String get err_cancellation_window_closed =>
      'Hindi na puwedeng magkansela sa app para sa booking na ito. Makipag-ugnayan po sa aming team';

  @override
  String get err_address_required => 'Maglagay ng address para sa bisita';

  @override
  String get err_already_taken => 'Naunahan ka ng ibang pro sa pag-accept';

  @override
  String get err_invalid_address => 'Pakisagutan lahat ng field ng address';

  @override
  String get tabHome => 'Simula';

  @override
  String get tabBookings => 'Mga booking';

  @override
  String get tabChat => 'Usapan';

  @override
  String get tabMore => 'Iba pa';

  @override
  String get introTitle =>
      'Mag-book ng propesyonal na paglilinis\nnang mas madali';

  @override
  String get introBody =>
      'Malinaw na presyo · Vetted na team · Live na progress';

  @override
  String get introStart => 'Magsimula gamit ang mobile number';

  @override
  String get loginPhoneTitle => 'Ano po ang mobile number ninyo?';

  @override
  String get loginPhoneHint => '0917 000 0000';

  @override
  String get loginSendCode => 'Kunin ang code';

  @override
  String get loginCodeTitle => 'I-enter ang 6-digit na code';

  @override
  String loginCodeSentTo(String phone) {
    return 'Naipadala sa $phone';
  }

  @override
  String get loginResend => 'Ipadala ulit';

  @override
  String get loginVerify => 'I-verify';

  @override
  String get loginTerms =>
      'Sa pagpapatuloy, sumasang-ayon ka sa Terms of Service at Privacy Policy';

  @override
  String get profileTitle => 'Ano po ang pangalan ninyo?';

  @override
  String get profileNameHint => 'Pangalan';

  @override
  String get profileDone => 'Magsimula';

  @override
  String get welcomeToast => 'May 2 welcome coupon na sa wallet mo';

  @override
  String get svc_studio => 'Paglilinis ng studio';

  @override
  String get svc_kitchen => 'Paglilinis ng kusina';

  @override
  String get svc_bathroom => 'Paglilinis ng banyo';

  @override
  String get svc_mattress => 'Paglilinis ng kutson';

  @override
  String get svc_aircon => 'Aircon cleaning';

  @override
  String get svc_sofa => 'Paglilinis ng sofa';

  @override
  String get svc_move_out => 'Paglilinis sa paglipat-labas';

  @override
  String get svc_move_in => 'Paglilinis bago lumipat';

  @override
  String get svcShort_studio => 'Studio';

  @override
  String get svcShort_kitchen => 'Kusina';

  @override
  String get svcShort_bathroom => 'Banyo';

  @override
  String get svcShort_mattress => 'Kutson';

  @override
  String get svcShort_aircon => 'Aircon';

  @override
  String get svcShort_sofa => 'Sofa';

  @override
  String get svcShort_move_out => 'Paglipat-labas';

  @override
  String get svcShort_move_in => 'Paglipat-pasok';

  @override
  String get svcDesc_studio =>
      '2 oras na masusing paglilinis ng studio na hanggang 10 pyeong, may isang kuwarto at isang banyo.';

  @override
  String get svcDesc_kitchen =>
      'Nakatutok na paglilinis ng kitchen: lababo, kalan, labas ng hood at countertop.';

  @override
  String get svcDesc_bathroom =>
      'Nililinis ang shelves, gripo, lababo at toilet sa loob at labas, at pinatutuyo ang sahig.';

  @override
  String get svcDesc_mattress =>
      'Sinisipsip ng pro equipment ang alikabok, mites at mantsa, saka sinasanitize gamit ang steam.';

  @override
  String get svcDesc_aircon =>
      'Binubuwag, saka hinuhugasan sa high pressure ang coil, fan at filter, at sinasanitize.';

  @override
  String get svcDesc_sofa =>
      'Binubuwag ng panlinis na akma sa tela ang dumi, saka hinuhugasan gamit ang wet extraction.';

  @override
  String get svcDesc_move_out =>
      'Bago kayo umalis, pupunta ang pro team na may dalang kagamitan para linisin ang walang laman na bahay.';

  @override
  String get svcDesc_move_in =>
      'Bago kayo pumasok sa bagong bahay, pupunta ang pro team na may dalang kagamitan para linisin ang loob.';

  @override
  String get svcNotes_bathroom =>
      'Puwedeng ma-limit ang serbisyo kung may barado na drain o toilet\nWalang special-chemical cleaning, ceiling o vent cleaning\nHindi man lubusang matanggal ang lumang amag at matigas na dumi';

  @override
  String get svcNotes_mattress =>
      'Iisang presyo mula single hanggang king size\nMatutuyo nang lubusan sa loob ng 4–6 na oras\nHindi maaayos ang sira ng spring o paglubog ng kutson';

  @override
  String get svcNotes_aircon =>
      'Maaaring mahirap buwagin ang units na mahigit 10 taon na\nHindi kasama ang paglilinis ng outdoor unit\nChine-check namin kung gumagana bago at pagkatapos';

  @override
  String get svcNotes_sofa =>
      'Leather sofa ay may cleaning at moisturizing coating\nHindi man lubusang matanggal ang lumang mantsa o pagkapuwing ng kulay\nMatutuyo nang lubusan sa loob ng 4–6 na oras';

  @override
  String get unitTitle_bathroom => 'Bilang ng banyo';

  @override
  String get unitTitle_mattress => 'Bilang ng mattress';

  @override
  String get unitTitle_aircon => 'Uri ng aircon';

  @override
  String get unitTitle_sofa => 'Laki ng sofa';

  @override
  String unit_count(String n) {
    return '$n';
  }

  @override
  String get unit_wall => 'Wall-mounted, 1 unit';

  @override
  String get unit_stand => 'Stand, 1 unit';

  @override
  String get unit_two_in_one => '2-in-1 (stand + nakasabit)';

  @override
  String get unit_ceiling => 'Ceiling cassette, 1 unit';

  @override
  String get unit_seat_1_2 => '1–2 upuan';

  @override
  String get unit_seat_3 => '3 upuan';

  @override
  String get unit_seat_4_plus => '4+ upuan';

  @override
  String get unit_l_shape => 'Hugis-L · couch';

  @override
  String durH(String h) {
    return '$h oras';
  }

  @override
  String durHM(String h, String m) {
    return '$h oras $m minuto';
  }

  @override
  String durM(String m) {
    return '$m minuto';
  }

  @override
  String about(String value) {
    return 'mga $value';
  }

  @override
  String fromPrice(String price) {
    return 'mula $price';
  }

  @override
  String get quoteBadge => 'Presyo';

  @override
  String get status0 => 'Nasa konsultasyon';

  @override
  String get status1 => 'Kumpirmado ang booking';

  @override
  String get status2 => 'Naka-assign na ang team';

  @override
  String get status3 => 'Tapos na ang paglilinis';

  @override
  String get statusCancelled => 'Kinansela';

  @override
  String homeGreeting(String name) {
    return 'Kumusta, $name!\nSaan natin lilinisin ngayon?';
  }

  @override
  String get homeGreetingAnon => 'Saan natin\nlilinisin ngayon?';

  @override
  String get homeUpcoming => 'Paparating na booking';

  @override
  String dDay(String days) {
    return '$days araw na lang';
  }

  @override
  String get homeServices => 'Anong paglilinis ang kailangan mo?';

  @override
  String get homeAddAddress =>
      'I-add ang address mo para makita agad ang available na serbisyo at presyo';

  @override
  String get homeAddAddressCta => 'Mag-add ng address';

  @override
  String homeRebook(String service) {
    return 'I-book ulit ang $service';
  }

  @override
  String get homeRebookBody => 'Kaparehong setup ng huli, dalawang tap lang';

  @override
  String get homeNotices => 'Mga balita';

  @override
  String get trustVat => 'Kasama na ang VAT\nEksaktong presyo ang nakikita mo';

  @override
  String get trustCancel =>
      'Libreng kanselasyon\nhanggang 2 araw bago ang bisita';

  @override
  String get trustCard => 'Ang detalye ng card\nay nasa payment provider lang';

  @override
  String stepOf(String current, String total) {
    return '$current ng $total';
  }

  @override
  String get chooseDate => 'Pumili ng petsa';

  @override
  String get notIncluded => 'Pakitingnan po ito';

  @override
  String studioBlockedTitle(String size) {
    return 'Masyadong malaki ang $size pyeong para sa studio cleaning';
  }

  @override
  String get studioBlockedBody =>
      'Magmumungkahi ang team namin ng tamang serbisyo para sa bahay ninyo.';

  @override
  String get consultCta => 'Magtanong sa team';

  @override
  String get addressTitle => 'Saan po kami pupunta?';

  @override
  String get addressAdd => 'Magdagdag ng bagong address';

  @override
  String get addressLabel => 'Pangalan';

  @override
  String get addressLabelHint => 'hal. Bahay';

  @override
  String get addressDistrict => 'Distrito';

  @override
  String get addressRoad => 'Address sa kalsada';

  @override
  String get addressDetail => 'Unit / palapag';

  @override
  String get addressSize => 'Laki ng bahay (pyeong)';

  @override
  String get addressSizeHelp => 'Batay sa net floor area · 1 pyeong ≈ 3.3 m²';

  @override
  String get addressHome => 'Bahay';

  @override
  String get addressOffice => 'Opisina';

  @override
  String get addressEmpty => 'Walang naka-save na address';

  @override
  String get addressSaved => 'Na-save ang address';

  @override
  String pyeong(String n) {
    return '$n pyeong';
  }

  @override
  String get scheduleTitle => 'Kailan po kami pupunta?';

  @override
  String get scheduleArrival => 'Oras ng dating';

  @override
  String get scheduleFull => 'Puno';

  @override
  String scheduleWindow(String start, String end) {
    return 'Dadating $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · matatapos bandang $time';
  }

  @override
  String get scheduleRange =>
      'Puwede kang mag-book mula bukas hanggang 60 araw';

  @override
  String get morning => 'Umaga';

  @override
  String get afternoon => 'Hapon';

  @override
  String get scheduleQuoteNote =>
      'Kukumpirmahin namin ang eksaktong oras sa chat';

  @override
  String get goToPayment => 'Magpatuloy sa bayad';

  @override
  String get prepTitle => 'Pakihanda bago kami dumating';

  @override
  String get prepBody =>
      'Maaaring ma-limit ang ilang gawain kapag hindi ito handa';

  @override
  String get prepAsk => 'Hindi ba kayo makakapaghanda? Ipaalam sa chat';

  @override
  String get tool_vacuum => 'Vacuum';

  @override
  String get tool_trash => 'Basurahan';

  @override
  String get tool_mop => 'Mop';

  @override
  String get tool_cloth => 'Basahan';

  @override
  String get tool_gloves => 'Gomang guwantes';

  @override
  String get tool_sponge => 'Espongha';

  @override
  String get tool_spray => 'Panlinis na pangkalahatan';

  @override
  String get checkoutTitle => 'Bayad';

  @override
  String get coupon => 'Kupon';

  @override
  String get couponNone => 'Hindi gagamitin';

  @override
  String couponAvailable(String count) {
    return '$count ang available';
  }

  @override
  String get paymentMethod => 'Paraan ng bayad';

  @override
  String get addPaymentMethod => 'Magdagdag ng paraan ng bayad';

  @override
  String get methodCard => 'Kard (credit / debit)';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Naka-add na';

  @override
  String get methodAdded => 'Naidagdag na ang paraan ng bayad';

  @override
  String get listPrice => 'Serbisyo';

  @override
  String get discount => 'Coupon discount';

  @override
  String get total => 'Kabuuang bayad';

  @override
  String get vatIncluded => 'Kasama ang VAT';

  @override
  String payAmount(String amount) {
    return 'Bayaran ang $amount';
  }

  @override
  String get needMethod => 'Magdagdag muna ng paraan ng bayad';

  @override
  String freeCancelUntil(String date) {
    return 'Libreng kanselasyon hanggang $date';
  }

  @override
  String get doneTitle => 'Kumpirmado na ang booking!';

  @override
  String get doneBody => 'Ipapaalam namin agad kapag may naka-assign nang team';

  @override
  String get doneQuoteTitle => 'Natanggap ang request';

  @override
  String get doneQuoteBody =>
      'Kukumpirmahin ng team namin at magpapadala ng final quote. Makikita ito sa Chat tab.';

  @override
  String get goHome => 'Pumunta sa Home';

  @override
  String get viewBooking => 'Tingnan ang booking';

  @override
  String get bookingsTitle => 'Mga booking';

  @override
  String get bookingsUpcoming => 'Paparating';

  @override
  String get bookingsPast => 'Nakaraan';

  @override
  String get bookingsEmpty => 'Wala pang booking';

  @override
  String get bookingsEmptyBody =>
      'May mga coupon na naghihintay para sa first booking mo';

  @override
  String get bookNow => 'Mag-book ng paglilinis';

  @override
  String get detailTitle => 'Detalye ng booking';

  @override
  String get stepRequested => 'Natanggap ang request';

  @override
  String get stepConfirmed => 'Kumpirmado';

  @override
  String get stepAssigned => 'Naka-assign na ang team';

  @override
  String get stepCompleted => 'Tapos na ang paglilinis';

  @override
  String teamVisiting(String team) {
    return 'Pupunta ang $team';
  }

  @override
  String get photosSoon => 'Lalabas dito ang before at after photos pagtapos';

  @override
  String photoThumb(String n) {
    return 'Larawan $n';
  }

  @override
  String get before => 'Bago';

  @override
  String get after => 'Pagkatapos';

  @override
  String get prepCheck => 'Checklist ng dapat ihanda';

  @override
  String get prepAllSet => 'Handa na lahat';

  @override
  String get visitAddress => 'Lugar ng pagbisita';

  @override
  String get paid => 'Bayad na';

  @override
  String get askTeam => 'Mag-message sa team';

  @override
  String get cancelBooking => 'Kanselahin ang booking';

  @override
  String get cancelTitle => 'Kanselahin ang booking na ito?';

  @override
  String get cancelFree =>
      'Kapag kinansela mo ngayon, buong refund ng bayad ang makukuha mo at ibabalik din ang coupon mo.';

  @override
  String get cancelKeep => 'Ituloy';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Kung kakanselahin mo ngayon, may bayad na $fee at ibabalik ang $refund.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return 'Tanggapin ang bayad na $fee at kanselahin';
  }

  @override
  String get cancelled => 'Kinansela na ang booking';

  @override
  String get reschedule => 'I-reschedule';

  @override
  String get rescheduled => 'Na-reschedule na';

  @override
  String get visitNotes => 'Mga note para sa team';

  @override
  String get notesEntry => 'Paano makapasok (door code atbp.)';

  @override
  String get notesParking => 'Paradahan';

  @override
  String get notesOther => 'Iba pa';

  @override
  String get notesSaved => 'Na-save ang mga note';

  @override
  String depositDue(String amount) {
    return 'Kapag nabayaran ang $amount na deposit, makukumpirma ang booking';
  }

  @override
  String get payDeposit => 'Bayaran ang deposit';

  @override
  String get waitingQuote => 'Inihahanda ng team namin ang quote';

  @override
  String get estimate => 'Tinatayang halaga';

  @override
  String get finalPrice => 'Huling presyo';

  @override
  String get deposit => 'Paunang bayad';

  @override
  String get balance => 'Natitirang bayad';

  @override
  String balanceDue(String amount) {
    return 'Pakibayaran ang $amount na balance';
  }

  @override
  String get payBalance => 'Bayaran ang balance';

  @override
  String get reviewTitle => 'Kumusta ang paglilinis?';

  @override
  String get reviewHint =>
      'Sabihin sa amin ang magaling at ang puwedeng mapabuti';

  @override
  String ratingStars(String n) {
    return '$n na bituin';
  }

  @override
  String get reviewSubmit => 'Ipadala ang review';

  @override
  String get reviewThanks => 'Salamat sa review mo';

  @override
  String get bookAgain => 'Mag-book ulit ng ganoon';

  @override
  String get chatTitle => 'Usapan';

  @override
  String get chatTeam => 'Team ng suporta';

  @override
  String get chatHours => 'Lunes–Biyernes 09:00–18:00';

  @override
  String get chatEmpty => 'May tanong? Puwede mo kaming tanungin anytime';

  @override
  String get chatNew => 'Bagong chat';

  @override
  String get chatTopicTitle => 'Ano po ang itatanong ninyo?';

  @override
  String get topicOther => 'Iba pang tanong';

  @override
  String get chatHint => 'Mag-type ng mensahe';

  @override
  String get chatSend => 'Ipadala';

  @override
  String get chatPhoto => 'Mag-send ng photo';

  @override
  String get chatTyping => 'Nagta-type ang team…';

  @override
  String get quick_confirm => 'Kumpirmahin na natin';

  @override
  String get quick_price => 'Magkano po ang presyo?';

  @override
  String get quick_date => 'Gusto ko sanang palitan ang petsa';

  @override
  String get quick_parking => 'May available bang parking?';

  @override
  String get quick_hello => 'Hello po';

  @override
  String get quick_duration => 'Gaano katagal?';

  @override
  String get quoteArrived => 'Dumating na ang final quote';

  @override
  String get quoteDepositNow => 'Deposit ngayon: 10%';

  @override
  String get quoteBalanceLater => 'Balance pagkatapos ng trabaho';

  @override
  String get quotePay => 'Bayaran ang deposit at kumpirmahin';

  @override
  String get quotePaid => 'Bayad na';

  @override
  String get requestCard => 'Hiling na quote';

  @override
  String get sys_consultation_received => 'Natanggap na ang request ninyo';

  @override
  String sys_deposit_paid(String amount) {
    return 'Nabayaran na ang $amount na deposit. Kumpirmado na ang booking.';
  }

  @override
  String get sys_booking_cancelled => 'Kinansela na ang booking';

  @override
  String sys_status_changed(String status) {
    return 'Naging \'$status\' ang status ng booking';
  }

  @override
  String get sys_job_completed =>
      'Tapos na ang paglilinis! Tingnan ang before at after photos.';

  @override
  String sys_rescheduled(String date) {
    return 'Na-reschedule sa $date';
  }

  @override
  String get sys_reschedule_declined =>
      'Hindi makakapunta ang pro sa bagong oras. Aayusin ito ng team namin.';

  @override
  String get moreTitle => 'Iba pa';

  @override
  String get moreScope => 'Saklaw ng serbisyo';

  @override
  String get morePayments => 'Mga paraan ng bayad';

  @override
  String get moreCoupons => 'Mga kupon';

  @override
  String get morePoints => 'Puntos sa paglilinis';

  @override
  String get moreAccount => 'Impormasyon ng account';

  @override
  String get moreAddresses => 'Mga address';

  @override
  String get moreNotices => 'Mga anunsyo';

  @override
  String get moreTips => 'Mga tip sa paglilinis';

  @override
  String get moreFaq => 'Mga madalas itanong';

  @override
  String get morePartner => 'Maging partner';

  @override
  String get moreLanguage => 'Wika';

  @override
  String get langSystem => 'Sundin ang device setting';

  @override
  String moreVersion(String v) {
    return 'Bersyon $v';
  }

  @override
  String get morePrivacy => 'Patakaran sa privacy';

  @override
  String get moreTerms => 'Mga tuntunin ng serbisyo';

  @override
  String get moreLicenses => 'Mga lisensya ng open-source';

  @override
  String get logout => 'Mag-sign out';

  @override
  String get deleteAccount => 'Burahin ang account';

  @override
  String get deleteAccountBody =>
      'Mabubura ang personal data ninyo at hindi na ito maibabalik. Pakikansela muna ang mga aktibong booking.';

  @override
  String get couponsEmpty => 'Wala ka pang coupon';

  @override
  String couponUntil(String date) {
    return 'Hanggang $date';
  }

  @override
  String get couponUsed => 'Nagamit na';

  @override
  String get couponExpired => 'Nag-expire na';

  @override
  String get couponAnyService => 'Lahat ng serbisyo';

  @override
  String get coupon_welcome_studio => 'Welcome coupon para sa studio';

  @override
  String get coupon_welcome_any => 'Kupon sa pagsali';

  @override
  String get pointsBalance => 'Points mo';

  @override
  String get pointsEmpty => 'Wala pang points history';

  @override
  String get accountName => 'Pangalan';

  @override
  String get accountPhone => 'Numero ng cellphone';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountLogin => 'Paraan ng pag-login';

  @override
  String get accountLoginPhone => 'Pagpapatunay sa telepono';

  @override
  String get methodsEmpty => 'Walang paraan ng bayad';

  @override
  String get noContent => 'Wala pang nakalagay dito';

  @override
  String get quoteTypeTitle => 'Anong paglilinis ang kailangan ninyo?';

  @override
  String get type_standard => 'Move-out cleaning';

  @override
  String get type_same_day_move => 'Paglilinis sa mismong araw ng lipat';

  @override
  String get type_some_luggage_left => 'May natitirang gamit';

  @override
  String get type_normal_move_in => 'Regular na move-in';

  @override
  String get type_after_interior => 'Pagkatapos ng renovation';

  @override
  String get type_lived_in_deep_clean =>
      'Malalim na paglilinis habang nakatira';

  @override
  String get luggageTitle => 'Ano po ang kalagayan ng gamit?';

  @override
  String get luggage_empty => 'Walang gamit';

  @override
  String get luggage_partly_unpacked => 'Bahagyang naayos na';

  @override
  String get luggage_fully_lived_in => 'Nakatira pa rin';

  @override
  String get luggage_unknown => 'Hindi sigurado';

  @override
  String get quoteBasicTitle => 'Sabihin po ang tungkol sa bahay';

  @override
  String get buildingType => 'Uri ng gusali';

  @override
  String get building_apartment => 'Apartment';

  @override
  String get building_villa => 'Mababang gusali';

  @override
  String get building_officetel => 'Officetel';

  @override
  String get building_house => 'Bahay na solo';

  @override
  String get building_other => 'Iba pa';

  @override
  String get layoutTitle => 'Ayos ng kuwarto';

  @override
  String get layout_studio => 'Studio';

  @override
  String get layout_one_and_half => '1.5 kuwarto';

  @override
  String get layout_two_rooms => '2 kuwarto';

  @override
  String get layout_three_rooms => '3 kuwarto';

  @override
  String get layout_four_plus => '4+ kuwarto';

  @override
  String get duplexTitle => 'Duplex po ba ito?';

  @override
  String get quoteSpaceTitle => 'Sabihin po ang tungkol sa espasyo';

  @override
  String get bathroomsLabel => 'Banyo';

  @override
  String get balconiesLabel => 'Balkonahe / utility';

  @override
  String get elevatorTitle => 'May elevator po ba?';

  @override
  String get floor3Label => '3rd floor pataas po';

  @override
  String get quoteEstimateTitle => 'Ito po ang tinatayang presyo';

  @override
  String get quoteEstimateBody =>
      'Pagkatapos naming makita ang mga litrato at sitwasyon sa chat, saka pa mapagkakasunduan ang final na presyo';

  @override
  String get quoteG1 => 'Ang final na presyo ay pagkakasunduan sa chat';

  @override
  String get quoteG2 =>
      '10% deposit para kumpirmahin, ang natitira ay pagkatapos ng trabaho';

  @override
  String get quoteG3 => 'Libre ang kanselasyon bago ka mag-confirm';

  @override
  String get quoteConfirmTitle => 'Pakitingnan ang request ninyo';

  @override
  String get quoteRequest => 'Ipadala ang request';

  @override
  String get quoteNoPayNow => 'Wala pang babayaran ngayon';

  @override
  String get summaryType => 'Uri ng paglilinis';

  @override
  String get summaryHome => 'Impormasyon ng bahay';

  @override
  String get summaryDate => 'Bisita';

  @override
  String get cpTitle => 'Patakaran sa pagkansela';

  @override
  String cpWhen(String days) {
    return '$days araw o higit pa bago ang bisita';
  }

  @override
  String get cpWhenSameDay => 'Sa mismong araw ng bisita';

  @override
  String get cpFree => 'Buong refund';

  @override
  String cpFee(String percent, String fee, String refund) {
    return 'Bayad $percent% ($fee), refund $refund';
  }

  @override
  String get cpClosed =>
      'Hindi maaaring kanselahin sa app (sisiyasatin ng team)';

  @override
  String get hhTitle => 'Impormasyon ng sambahayan';

  @override
  String get hhAddPet => 'Magdagdag ng alagang hayop';

  @override
  String get hhPetCount => 'Bilang';

  @override
  String get hhFloorLabel => 'Palapag (negatibo para sa basement)';

  @override
  String get hhElevator => 'May elevator';

  @override
  String get hhNotes => 'Mga tala';

  @override
  String get hhHint =>
      'Naka-save sa address na ito at puwedeng baguhin sa bawat booking.';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeDark => 'Madilim';

  @override
  String get themeLight => 'Maliwanag';

  @override
  String get themeSystem => 'Ayon sa system';

  @override
  String get themeTip => 'Palitan ang theme';

  @override
  String get err_price_changed =>
      'Nagbago ang presyo. Tingnan ang bagong quote at subukan ulit.';

  @override
  String get err_checkout_closed =>
      'Tapos na ang bayad na ito. Magsimula ulit.';

  @override
  String get err_checkout_refunded =>
      'Nakansela na ang bayad na ito at na-refund na.';

  @override
  String get err_already_paid => 'Bayad na ito.';

  @override
  String get err_quote_not_payable =>
      'Hindi pa puwedeng bayaran ang quote na ito. Makipag-ugnayan sa team.';

  @override
  String get err_payment_method_disabled =>
      'Hindi available ang paraan ng bayad na ito ngayon.';

  @override
  String get err_invalid_payment_method =>
      'Hindi magamit ang napiling paraan ng bayad. Pumili ng iba.';

  @override
  String get err_balance_not_due => 'Hindi pa due ang balanse.';

  @override
  String get err_invalid_slot =>
      'Hindi available ang oras na ito para sa serbisyong ito.';

  @override
  String get err_booking_changed =>
      'Nagbago ang booking. I-refresh at tingnan ulit ang detalye.';

  @override
  String get err_booking_closed =>
      'Hindi na puwedeng baguhin ang booking na ito.';

  @override
  String get err_reschedule_closed =>
      'Hindi na puwedeng ilipat ang petsa ngayon. Makipag-ugnayan sa team.';

  @override
  String get err_too_many_open_requests =>
      'Masyado nang maraming bukas na request. Tapusin muna ang isa.';

  @override
  String get err_already_reviewed =>
      'Nakapag-review ka na para sa visit na ito.';

  @override
  String get err_identity_not_verified =>
      'Kumpletuhin muna ang pag-verify ng pagkakakilanlan.';

  @override
  String get err_email_taken => 'Ginagamit na ang email na ito.';

  @override
  String get err_invalid_email => 'Pakitingnan ang email address.';

  @override
  String get err_file_too_large =>
      'Masyadong malaki ang file. Mag-upload ng mas maliit.';

  @override
  String get err_unsupported_image =>
      'Hindi suportado ang format ng larawang ito. Mag-upload ng JPG o PNG.';

  @override
  String get err_upload_quota =>
      'Naabot na ang limitasyon sa upload ngayong araw. Subukan bukas.';

  @override
  String get err_provider_unreachable =>
      'Hindi maabot ang serbisyo. Subukan ulit maya-maya.';

  @override
  String get err_invalid_token =>
      'Hindi natuloy ang pag-sign in. Subukan ulit.';

  @override
  String get err_invalid_transition =>
      'Hindi puwedeng baguhin sa ganitong paraan ang status ngayon.';

  @override
  String get err_job_not_started => 'Simulan muna ang trabaho.';

  @override
  String get err_job_not_active => 'Hindi aktibo ang trabahong ito.';

  @override
  String get err_quote_locked => 'Naka-lock ang quote at hindi na mae-edit.';

  @override
  String get err_request_closed => 'Sarado na ang request na ito.';

  @override
  String get err_team_full => 'Puno na ang team.';

  @override
  String get err_invalid_webhook_secret =>
      'Dapat magsimula sa whsec_ ang webhook secret.';

  @override
  String get err_invalid_endpoint =>
      'Dapat magsimula sa https:// ang endpoint.';

  @override
  String get err_invalid_bucket => 'Hindi valid ang pangalan ng bucket.';

  @override
  String get err_invalid_region => 'Hindi valid ang region.';

  @override
  String get err_invalid_retention => 'Wala sa saklaw ang haba ng pag-iimbak.';

  @override
  String get err_invalid_service_account =>
      'Hindi valid ang file ng service account.';

  @override
  String get err_invalid_mode => 'Pumili ng valid na AI mode.';

  @override
  String get err_invalid_model => 'Hindi valid ang pangalan ng AI model.';

  @override
  String get err_missing_field => 'Punan ang lahat ng kinakailangang field.';

  @override
  String get err_invalid_amount => 'Maglagay ng valid na halaga.';

  @override
  String get err_cannot_deactivate_self =>
      'Hindi mo puwedeng i-deactivate ang sarili mong account.';

  @override
  String get err_invalid_coupon => 'Hindi valid ang coupon na ito.';

  @override
  String get err_settlement_state =>
      'Hindi puwedeng baguhin ang settlement ngayon.';

  @override
  String get err_deposit_required => 'Kailangan munang bayaran ang deposito.';

  @override
  String get err_payout_state =>
      'Nagbago ang status ng bayad. I-refresh at tingnan ulit.';

  @override
  String get err_payout_provider =>
      'Hindi available ang paraan ng bayad na ito ngayon.';

  @override
  String get err_unsupported_bank =>
      'Hindi suportado ang bangkong ito para sa bayad.';

  @override
  String get err_toss_unverified =>
      'Hindi pa available ang Toss payouts. Gumamit ng manual na transfer.';

  @override
  String get err_invalid_cap => 'Maglagay ng numero sa pinapayagang saklaw.';

  @override
  String get err_invalid_capacity => 'Maglagay ng valid na kapasidad.';

  @override
  String get err_seller_declined =>
      'Hindi inaprubahan ng Toss ang pagpaparehistro ng seller. Suriin ang impormasyon ng negosyo.';

  @override
  String get err_payout_account_unverified =>
      'Walang na-verify na payout account ang partner na ito. I-verify muna ang account.';

  @override
  String get guestSheetTitle => 'Mag-sign in para magpatuloy';

  @override
  String get guestSheetBody =>
      'Nakatago ang mga nilagay mo. Didiretso ka agad kung saan ka tumigil.';

  @override
  String get greetMorning => 'Magandang umaga';

  @override
  String get greetAfternoon => 'Magandang hapon';

  @override
  String get greetEvening => 'Magandang gabi';

  @override
  String get feedHeading => 'Para sa iyo';

  @override
  String get feedTitleDue => 'Oras na para sa susunod na paglilinis';

  @override
  String get feedTitleRebook => 'I-book muli ang iyong 5-star na partner';

  @override
  String get feedTitleDraft => 'Tapusin ang quote na sinimulan mo';

  @override
  String get feedTitleSeasonal => 'Paglilinis na bagay sa panahong ito';

  @override
  String get feedTitleSize => 'Quote batay sa naka-save mong laki ng bahay';

  @override
  String get feedTitleSubscription => 'Mas tipid sa subscription';

  @override
  String get feedTitleDistrict => 'Nagpapa-book din ang mga kapitbahay';

  @override
  String feedWhyCadence(String days) {
    return '$days araw na mula nang huli kang magpalinis';
  }

  @override
  String feedWhyRated(String days) {
    return 'Binigyan mo ng 5 bituin ang partner na ito $days araw na ang nakalipas';
  }

  @override
  String get feedWhyDraft => 'May quote kang hindi natapos sa device na ito';

  @override
  String get feedWhySummer =>
      'Magandang panahon para linisin ang aircon bago ang tag-init';

  @override
  String get feedWhyMoving => 'Abala ang panahon ng paglipat at pag-move in';

  @override
  String feedWhyHoliday(String days) {
    return '$days araw bago ang malalim na paglilinis para sa holiday';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'Agad na quote para sa naka-save mong $pyeong pyeong na bahay';
  }

  @override
  String get feedWhyRepeat =>
      'Mas mura ang subscription kung madalas ka mag-book';

  @override
  String feedWhyDistrict(String district, String count) {
    return '$count bahay sa $district ang nag-book ngayong linggo';
  }

  @override
  String get fFinance => 'Pananalapi';

  @override
  String get fPeriodDay => 'Araw';

  @override
  String get fPeriodWeek => 'Linggo';

  @override
  String get fPeriodMonth => 'Buwan';

  @override
  String get fPeriodCustom => 'Pasadya';

  @override
  String get fFrom => 'Mula';

  @override
  String get fTo => 'Hanggang';

  @override
  String get fGross => 'Kabuuang bayad';

  @override
  String get fRefunds => 'Refund';

  @override
  String get fNetRevenue => 'Netong kita';

  @override
  String get fPlatformFee => 'Bayad sa platform';

  @override
  String get fPaidOut => 'Nabayaran sa partners';

  @override
  String get fPendingOut => 'Nakabinbing bayad';

  @override
  String get fHeldOut => 'Naka-hold';

  @override
  String get fVatEstimate => 'Tinatayang VAT';

  @override
  String get fVatNote =>
      'Tinatayang 10% ng bayad sa platform. Kumpirmahin sa iyong accountant.';

  @override
  String get fAov => 'Average na order';

  @override
  String get fBookings => 'Mga booking';

  @override
  String get fCancelRate => 'Rate ng pagkansela';

  @override
  String get fDiscounts => 'Diskwento at kupon';

  @override
  String get fMethods => 'Paraan ng bayad';

  @override
  String get fTrend => 'Takbo';

  @override
  String fRangeDays(String n) {
    return 'Nakaraang $n araw';
  }

  @override
  String get fRangeWeeks => 'Nakaraang 12 linggo';

  @override
  String get fRangeMonths => 'Nakaraang 12 buwan';

  @override
  String get fByPartner => 'Kita kada partner';

  @override
  String get fByService => 'Kita kada serbisyo';

  @override
  String get fExportTitle => 'Export para sa accounting';

  @override
  String get fExportLedger => 'CSV ng talaan ng bayad';

  @override
  String get fExportSettlements => 'CSV ng settlements';

  @override
  String get fExportMonthly => 'CSV ng buwanang buod (accountant)';

  @override
  String get fDownload => 'I-download ang CSV';

  @override
  String get fDownloadWebOnly => 'Sa web console lang maida-download ang CSV';

  @override
  String get fDownloadFailed => 'Hindi na-download';

  @override
  String get fNoRecords => 'Walang record sa panahong ito';

  @override
  String get fLoadFailed => 'Hindi ma-load ang datos ng pananalapi';

  @override
  String get fRetry => 'Subukan muli';

  @override
  String get fColPartner => 'Kasosyo';

  @override
  String get fColJobs => 'Bilang';

  @override
  String get fColSettled => 'Kabuuang settled';

  @override
  String get fColFee => 'Bayad';

  @override
  String get fColNet => 'Netong bayad';

  @override
  String get pEarnings => 'Kita';

  @override
  String get pNextPayout => 'Susunod na bayad';

  @override
  String pNextPayoutOn(String date) {
    return 'Babayaran sa $date';
  }

  @override
  String get pNoPayout => 'Walang nakatakdang bayad';

  @override
  String get pPendingTotal => 'Naghihintay bayaran';

  @override
  String get pPaidTotal => 'Nabayaran na';

  @override
  String get pWeekly => 'Lingguhan';

  @override
  String get pMonthly => 'Buwanan';

  @override
  String proofHomes(String count) {
    return '$count bahay ang nalinis ngayong buwan';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Average na $rating bituin · $count review';
  }

  @override
  String get proofReviewsTitle => 'Mga kamakailang review';

  @override
  String get rebookTitle => 'I-book ulit ang huling serbisyo?';

  @override
  String rebookBody(String service, String date) {
    return '$service · huling bisita $date';
  }

  @override
  String get rebookButton => 'I-book ulit';

  @override
  String seatsLeft(String count) {
    return '$count na lang ang natitira';
  }

  @override
  String get reviewSheetTitle => 'Kumusta ang paglilinis?';

  @override
  String get reviewPhotosAdd => 'Magdagdag ng larawan';

  @override
  String get reviewPhotosHint => 'Hanggang 5 larawan';

  @override
  String get reviewSaved => 'Salamat sa iyong review';

  @override
  String get reviewPhotoFailed => 'Hindi na-upload ang larawan. Subukan ulit.';

  @override
  String get referralTitle => 'Mag-imbita ng kaibigan, makakuha ng kupon';

  @override
  String referralBody(String amount) {
    return 'Kapag natapos ng kaibigan mo ang unang booking, kayong dalawa ay makakakuha ng $amount na kupon';
  }

  @override
  String get referralCopy => 'Kopyahin ang code';

  @override
  String get referralCopied => 'Nakopya ang referral code';

  @override
  String get referralClaimTitle => 'May referral code ka ba?';

  @override
  String get referralClaimField => 'Ilagay ang referral code';

  @override
  String get referralClaimButton => 'Ilapat';

  @override
  String get referralClaimed => 'Nailapat ang referral code';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited na inimbita · $rewarded na gantimpala';
  }

  @override
  String get err_self_referral => 'Hindi mo magagamit ang sarili mong code';

  @override
  String get err_referee_already_booked =>
      'Mailalagay lang ang code bago ang unang booking';

  @override
  String get err_already_referred => 'May referral code ka na';

  @override
  String get err_invalid_referral_code => 'Pakitingnan ang referral code';

  @override
  String get err_referral_disabled => 'Pansamantalang naka-pause ang referral';

  @override
  String get err_invalid_photos =>
      'Mga larawang galing sa Malkkeum lang ang maaaring ilakip';

  @override
  String get welcomeOfferTitle => 'Diskuwento sa unang booking';

  @override
  String get welcomeOfferBody =>
      'Awtomatikong ilalapat sa unang booking ng bagong customer. Hindi kasama ang kupon.';

  @override
  String get offerKindAmount => 'Nakapirmi (won)';

  @override
  String get offerKindPercent => 'Porsiyento (%)';

  @override
  String get offerValue => 'Halaga ng diskuwento';

  @override
  String get offerEnabled => 'Gamitin';

  @override
  String get offerSaved => 'Na-save';

  @override
  String get referralSettingsTitle => 'Gantimpala sa referral';

  @override
  String get referralSettingsBody =>
      'Ibibigay kapag natapos at nabayaran ang unang booking ng kaibigan. Hinaharang ang sariling referral at paulit na numero.';

  @override
  String get referralRewardAmount => 'Halaga ng gantimpala (won)';

  @override
  String get reviewsModerationTitle => 'Pamamahala ng review';

  @override
  String get reviewHide => 'Itago';

  @override
  String get reviewShow => 'Ipakita ulit';

  @override
  String get reviewHiddenTag => 'Nakatago';

  @override
  String get growthAverageRating => 'Average na rating';

  @override
  String growthReviewCount(String count) {
    return '$count na review';
  }

  @override
  String get growthReferralConversion => 'Conversion ng referral';

  @override
  String get growthTab => 'Paglago';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded sa $invited';
  }

  @override
  String get locUseCurrent => 'Gamitin ang kasalukuyan kong lokasyon';

  @override
  String get locConsentTitle => 'Mga tuntunin ng serbisyong batay sa lokasyon';

  @override
  String get locConsentBody =>
      'Para mahanap ang address mula sa kasalukuyan mong lokasyon, pakisang-ayunan ang mga tuntunin ng serbisyong batay sa lokasyon. Isang beses lang namin tinitingnan ang lokasyon mo, kapag pinindot mo ang \"Gamitin ang kasalukuyan kong lokasyon\", at ginagamit lang ito para magmungkahi ng address. Hindi iniimbak sa aming server ang mga coordinate. Maaari mong bawiin ang pahintulot anumang oras sa Mga pahintulot.';

  @override
  String get locConsentAgree => 'Sumang-ayon at magpatuloy';

  @override
  String get locSuggestionTitle => 'Ito ba ang address mo?';

  @override
  String get locUseAddress => 'Gamitin ang address na ito';

  @override
  String get locDenied =>
      'Walang pahintulot sa lokasyon. Pakilagay nang manwal ang address.';

  @override
  String get locServicesOff =>
      'Naka-off ang location services ng device. Pakilagay nang manwal ang address.';

  @override
  String get locTimeout =>
      'Masyadong matagal ang paghahanap ng lokasyon. Pakilagay nang manwal ang address.';

  @override
  String get locNoAddress =>
      'Walang nahanap na address para sa lokasyon mo. Pakilagay nang manwal ang address.';

  @override
  String get uMaintenanceTitle => 'Under maintenance';

  @override
  String get uMaintenanceBody =>
      'Pinapaganda namin ang serbisyo. Pakibalik-balikan mamaya.';

  @override
  String get cmTab => 'Kampanya';

  @override
  String get cmNew => 'Bagong kampanya';

  @override
  String get cmAudience => 'Target na customer';

  @override
  String get cmSegAll => 'Lahat ng customer';

  @override
  String get cmSegNever => 'Walang booking kailanman';

  @override
  String cmSegLapsed(String days) {
    return 'Huling booking $days+ araw na ang nakalipas';
  }

  @override
  String get cmDays => 'Bilang ng araw';

  @override
  String cmConsentCount(String total, String consented) {
    return '$consented sa $total ang pumayag sa marketing';
  }

  @override
  String get cmChannel => 'Channel';

  @override
  String get cmPush => 'App push';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'Pamagat';

  @override
  String get cmBody => 'Mensahe';

  @override
  String get cmOptout => 'Opt-out number (080)';

  @override
  String get cmPreview => 'Preview';

  @override
  String get cmSchedule => 'Oras ng pagpapadala';

  @override
  String get cmSendNow => 'Ipadala ngayon';

  @override
  String get cmTestSend => 'Subukang ipadala sa aking numero';

  @override
  String get cmCreate => 'I-save ang kampanya';

  @override
  String get cmNeedOptout => 'Kailangan ng SMS ng 080 opt-out number';

  @override
  String get cmLog => 'Talaan ng pagpapadala';

  @override
  String cmStatSent(String count) {
    return 'Naipadala $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'Walang consent $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'Bigo $count';
  }

  @override
  String get cmSaved => 'Na-save ang kampanya';

  @override
  String anFunnel(String days) {
    return 'Signup funnel (huling $days araw)';
  }

  @override
  String get anInstalls => 'Nagbukas ng app (pumayag)';

  @override
  String get anSignedUp => 'Nag-signup';

  @override
  String get anQuoted => 'Humingi ng quote';

  @override
  String get anBooked => 'Nakapag-book';

  @override
  String get anPaid => 'Nagbayad';

  @override
  String get anRepeat => 'Paulit-ulit (2+)';

  @override
  String get anCohorts =>
      'Lingguhang cohort (booking rate ayon sa linggo ng signup)';

  @override
  String anCohortSize(String count) {
    return 'Signup $count';
  }

  @override
  String anWeekAfter(String n) {
    return 'Nag-book sa linggo $n';
  }

  @override
  String get cOps => 'Katayuan ng sistema';

  @override
  String get oLevelGreen => 'Maayos';

  @override
  String get oLevelYellow => 'Tingnan';

  @override
  String get oLevelRed => 'Kailangan ng aksyon';

  @override
  String get oOverall => 'Katayuan ng server';

  @override
  String get oRefresh => 'I-refresh';

  @override
  String get oVersion => 'Bersyon';

  @override
  String get oUptime => 'Tagal ng pagtakbo';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours oras $minutes minuto';
  }

  @override
  String get oChecks => 'Mga tseke';

  @override
  String get oCheckDb => 'Database';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Tugon $ms ms · laki $mb MB';
  }

  @override
  String get oCheckDisk => 'Disk ng server';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% ang bakante';
  }

  @override
  String get oCheckBackup => 'Awtomatikong backup';

  @override
  String oCheckBackupValue(String hours) {
    return 'Huling backup $hours oras na ang nakalipas';
  }

  @override
  String get oCheckBackupNone => 'Wala pang backup';

  @override
  String get oCheckErrors => 'Error ng server (24 oras)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Bayad na dapat tingnan';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 oras)';
  }

  @override
  String get oCheckWebhook => 'Abiso ng bayad (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Maling pirma $count (24 oras)';
  }

  @override
  String get oIntegrations => 'Mga external na serbisyo';

  @override
  String get oIntNotSet => 'Hindi pa naka-set up';

  @override
  String oIntLastOk(String at) {
    return 'Huling tagumpay $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Huling pagkabigo $at ($code)';
  }

  @override
  String get oIntNever => 'Wala pang gumamit';

  @override
  String get oActDb =>
      'Hindi makakonekta sa database. Patakbuhin ang malkkeum logs sa server; i-restart kung paulit-ulit.';

  @override
  String get oActDisk =>
      'Wala pang 10% ang bakanteng disk. Burahin ang lumang backup o dagdagan ang disk.';

  @override
  String get oActBackup =>
      'Lampas na sa oras ang awtomatikong backup. Patakbuhin ang malkkeum backup sa server at tingnan ang backups/backup.log.';

  @override
  String get oActErrors =>
      'Maraming error ng server. Tingnan ang error sa malkkeum logs at ipasa sa developer kung paulit-ulit.';

  @override
  String get oActPayments =>
      'Maaaring nabayaran na pero hindi naproseso nang awtomatiko. Tingnan sa PortOne at mag-refund nang manwal kung kailangan.';

  @override
  String get oActWebhook =>
      'Pumapalya ang pagsusuri ng pirma ng abiso ng bayad. Ilagay muli ang webhook secret sa Setup > Payments (PortOne).';

  @override
  String get oActIntegration =>
      'Pumapalya ang koneksyon na ito. Tingnan ang mga key sa Setup at pindutin ang Test connection.';

  @override
  String get oActNotSet =>
      'Hindi pa naka-set up. Maglagay ng mga key sa Setup.';

  @override
  String get oAlerts => 'Mga setting ng alerto';

  @override
  String get oAlertsHint =>
      'Ipapaalam sa inbox at sa telepono ng may-ari sa SMS ang mga problema. Isang beses lang kada 6 na oras ang parehong problema.';

  @override
  String get oRuleSms => 'Pumapalya ang pagpapadala ng SMS';

  @override
  String get oRulePush => 'Pumapalya ang push notification';

  @override
  String get oRulePayment => 'Pumapalya ang koneksyon sa bayad';

  @override
  String get oRuleStuck => 'Hindi awtomatikong naproseso ang bayad';

  @override
  String get oRuleSocial => 'Pumapalya ang social sign-in';

  @override
  String get oRuleBackup => 'Nalaktawan ang awtomatikong backup';

  @override
  String get oRuleDisk => 'Halos puno ang disk';

  @override
  String get oRuleAuth => 'Kahina-hinalang aktibidad sa pag-login';

  @override
  String get oQuietHours => 'Tahimik na oras';

  @override
  String get oQuietFrom => 'Mula';

  @override
  String get oQuietTo => 'Hanggang';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'Walang alerto sa mga oras na ito; isang mensahe ang ipapadala pagkatapos.';

  @override
  String get oAlertPhone => 'Telepono para sa alerto';

  @override
  String get oAlertPhoneHint =>
      'Iwanang blangko para sa numero ng suporta sa business info.';

  @override
  String get oSave => 'I-save';

  @override
  String get oSaved => 'Na-save ang mga setting ng alerto';

  @override
  String get oSaveFailed => 'Hindi na-save. Suriin ang mga inilagay.';

  @override
  String get oLoadFailed => 'Hindi ma-load ang katayuan';

  @override
  String get oBackupOffsite => 'External na backup (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Naka-off. I-on sa Setup > External na backup.';

  @override
  String get oLastBackup => 'Huling backup';

  @override
  String get oDiskFree => 'Bakanteng espasyo';

  @override
  String get oNoData => 'Wala pang datos';

  @override
  String get cIntBackup => 'External na backup (S3-compatible)';

  @override
  String get pTabJobs => 'Trabaho';

  @override
  String get pTabQuotes => 'Mga quote ko';

  @override
  String get pTabSchedule => 'Iskedyul';

  @override
  String get pIntroTitle =>
      'Trabaho, schedule at payout\npara sa mga cleaning pro';

  @override
  String get pIntroBody =>
      'Magtrabaho kung saan at kailan mo gusto. Sumahod linggo-linggo.';

  @override
  String get pOnbTitle => 'Sabihin po ang tungkol sa inyo';

  @override
  String get pOnbName => 'Pangalan ng may-ari';

  @override
  String get pOnbTeam => 'Pangalan ng team';

  @override
  String get pOnbServices => 'Mga serbisyong kaya ninyo';

  @override
  String get pOnbAreas => 'Saan kayo nagtatrabaho';

  @override
  String get pOnbDone => 'Mag-apply';

  @override
  String get pPendingTitle => 'Naghihintay ng approval ang account ninyo';

  @override
  String get pPendingBody =>
      'Magpapadala kami ng notification kapag na-approve na ng operations team. Habang naghihintay, i-register na ang payout account ninyo.';

  @override
  String get pSuspended =>
      'Pansamantalang na-suspend ang account ninyo. Pakikontak ang operations team.';

  @override
  String get pDirect => 'Direktang booking';

  @override
  String get pQuoteReq => 'Mga quote request';

  @override
  String get pShowClosed => 'Ipakita rin ang mga sarado nang trabaho';

  @override
  String get pSortNewest => 'Pinakabago';

  @override
  String get pSortVisit => 'Pinakamalapit na bisita';

  @override
  String get pSortAmount => 'Pinakamataas ang halaga';

  @override
  String get pNoJobs => 'Walang angkop na trabaho ngayon';

  @override
  String get pNoJobsBody =>
      'Palawakin ang serbisyo, lugar o oras para makakita ng mas maraming trabaho';

  @override
  String get pPayout => 'Inaasahang payout';

  @override
  String get pCustomerEstimate => 'Estimate ng customer';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => 'Sarado';

  @override
  String get pPrivacyNote =>
      'Lalabas ang eksaktong address at detalye ng customer pagkatapos mong mag-accept';

  @override
  String get pAccept => 'Mag-accept';

  @override
  String get pAcceptConfirm => 'I-accept ang trabahong ito?';

  @override
  String get pAcceptBody =>
      'Idaragdag ito sa schedule mo at makakatanggap ng notification ang customer na naka-assign na ang team. Hindi na puwedeng kanselahin kapag dalawang araw na lang bago ang bisita.';

  @override
  String get pAccepted => 'Na-accept ang trabaho';

  @override
  String get pSendQuote => 'Magpadala ng quote';

  @override
  String get pQuotePrice => 'Presyo para sa customer';

  @override
  String get pQuoteNote => 'Note para sa team';

  @override
  String get pQuoteSent => 'Naipadala na ang quote';

  @override
  String pFee(String rate) {
    return 'Fee $rate%';
  }

  @override
  String get pYouGet => 'Matatanggap mo';

  @override
  String get pQuoteAll => 'Lahat';

  @override
  String get pQ_waiting => 'Naghihintay';

  @override
  String get pQ_selected => 'Napili';

  @override
  String get pQ_rejected => 'Hindi napili';

  @override
  String get pQ_closed => 'Sarado';

  @override
  String get pUnseenOnly => 'Bagong resulta lang';

  @override
  String get pNoQuotes => 'Wala ka pang naipadalang quote';

  @override
  String get pMyQuote => 'Quote ko';

  @override
  String get pWithdraw => 'I-withdraw';

  @override
  String get pWithdrawn => 'Na-withdraw na ang quote';

  @override
  String get pOnlyMine => 'Ang akin lang';

  @override
  String pJobsCount(String n) {
    return '$n na trabaho';
  }

  @override
  String get pNoSchedule => 'Walang schedule sa araw na ito';

  @override
  String get pCancelledBanner =>
      'Kinansela ng customer ang trabahong ito. Hindi ito puwedeng markahang tapos.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Request na i-reschedule: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Puwede ako';

  @override
  String get pRescheduleNo => 'Hindi ako puwede';

  @override
  String get pCustomer => 'Kliyente';

  @override
  String get pCall => 'Tumawag gamit ang masked number';

  @override
  String get pCallSoon =>
      'Magiging aktibo ang masked calling pagbukas ng serbisyo';

  @override
  String get pQuietHours => 'Pakisuyong huwag tumawag pagkatapos ng 8 pm';

  @override
  String get pAssignee => 'Naka-assign';

  @override
  String get pChangeAssignee => 'Palitan ang naka-assign';

  @override
  String get pCustomerRequests => 'Mga request ng customer';

  @override
  String get pHousehold => 'Impormasyon ng sambahayan';

  @override
  String get pPets => 'Alagang hayop';

  @override
  String get pPetDog => 'Aso';

  @override
  String get pPetCat => 'Pusa';

  @override
  String get pPetBird => 'Ibon';

  @override
  String get pPetFish => 'Isda';

  @override
  String get pPetOther => 'Iba pang hayop';

  @override
  String get pAllergies => 'Allergy at sensitibidad';

  @override
  String get pPreferredProducts => 'Gustong produkto';

  @override
  String get pParking => 'Paradahan';

  @override
  String pFloor(String floor) {
    return 'Palapag $floor';
  }

  @override
  String get pElevatorYes => 'May elevator';

  @override
  String get pElevatorNo => 'Walang elevator';

  @override
  String get pTeamMemo => 'Team memo (hindi ito makikita ng customer)';

  @override
  String get pMemoSaved => 'Na-save ang memo';

  @override
  String get pPayoutBreakdown => 'Breakdown ng payout';

  @override
  String get pAfterBalance =>
      'Ibabayad pagkatapos bayaran ng customer ang balance';

  @override
  String get pChatOps => 'Mag-chat sa operations';

  @override
  String get pComplete => 'Markahang tapos ang trabaho';

  @override
  String get pBeforePhotos => 'Mga larawan bago linisin';

  @override
  String get pAfterPhotos => 'Mga larawan pagkatapos linisin';

  @override
  String get pAddPhoto => 'Magdagdag ng photo';

  @override
  String get pChecklist => 'Listahan ng gagawin';

  @override
  String get pCheck1 => 'Nalinis na ang lahat ng hiniling na lugar';

  @override
  String get pCheck2 => 'Naitapon ang basura at nakuha ang mga gamit';

  @override
  String get pCheck3 => 'Na-check ang bintana, kuryente at tubig';

  @override
  String get pCheck4 => 'Naasikaso ang mga request ng customer';

  @override
  String get pCompleteCta => 'Markahang tapos';

  @override
  String get pCompleteNeed =>
      'Maglagay ng kahit isang photo sa bawat kategorya at i-check ang lahat ng item';

  @override
  String get pCompleted => 'Salamat po sa inyong trabaho!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount ang ipapadala sa $date';
  }

  @override
  String get pPayoutWaiting =>
      'Matatakda ang petsa ng payout pagkatapos bayaran ng customer ang balance';

  @override
  String get pPendingPayout => 'Naghihintay na payout';

  @override
  String get pSettlements => 'Kasaysayan ng bayad';

  @override
  String get pS_waiting_balance => 'Naghihintay ng balance';

  @override
  String get pS_pending => 'Nakaiskedyul';

  @override
  String get pS_paid => 'Bayad na';

  @override
  String get pS_held => 'Naka-hold';

  @override
  String get pReviews => 'Mga review ng customer';

  @override
  String get pNoReviews => 'Wala pang review';

  @override
  String get pReplyLater => 'Malapit nang buksan ang pag-reply';

  @override
  String get pServicesAreas => 'Mga serbisyo at lugar';

  @override
  String get pPayoutAccount => 'Account para sa bayad';

  @override
  String get pBank => 'Bangko';

  @override
  String get pAccountNumber => 'Numero ng account';

  @override
  String get pHolder => 'May-ari ng account';

  @override
  String get pVerified => 'Napatunayan';

  @override
  String get pUnverified => 'Sini-verify';

  @override
  String get pAccountSaved =>
      'Na-save ang account. Kapag may binago, muling ive-verify ito.';

  @override
  String get pWorkSchedule => 'Iskedyul ng trabaho';

  @override
  String get pWeekdays => 'Mga araw ng trabaho';

  @override
  String get pDayParts => 'Mga oras ng trabaho';

  @override
  String get pDaysOff => 'Mga araw off';

  @override
  String get pAddDayOff => 'Magdagdag ng day off';

  @override
  String get pSaved => 'Na-save';

  @override
  String get pTeam => 'Mga miyembro';

  @override
  String get pOwner => 'May-ari';

  @override
  String get pInvited => 'Inimbitahan';

  @override
  String get pInvite => 'Mag-imbita ng miyembro';

  @override
  String get pInviteSent => 'Naipadala na ang imbitasyon';

  @override
  String get pRemove => 'Alisin';

  @override
  String get pNotifications => 'Mga notification';

  @override
  String get pNotifyDirect => 'Mga bagong direct na trabaho';

  @override
  String get pNotifyQuotes => 'Mga quote request at resulta';

  @override
  String get pNotifyChat => 'Mga mensahe mula sa operations';

  @override
  String get pQuietNight => 'Quiet mode sa gabi (22:00–08:00)';

  @override
  String get pNewInquiry => 'Bagong tanong';

  @override
  String get pTopic_settlement => 'Bayad';

  @override
  String get pTopic_reschedule => 'Reschedule / kanselasyon';

  @override
  String get pTopic_app => 'Tulong sa app';

  @override
  String get pOpsTeam => 'Team ng operasyon';

  @override
  String get pViewJob => 'Tingnan ang trabaho';

  @override
  String pBookingNo(String n) {
    return 'Booking #$n';
  }

  @override
  String get pSize => 'Laki';

  @override
  String get pSchedule => 'Iskedyul';

  @override
  String get pSpace => 'Impormasyon ng espasyo';

  @override
  String get pNavigate => 'Mga direksyon';

  @override
  String get pNavHint =>
      'Bubuksan ang address ng bisita sa map app. Kung walang app, bubuksan ang web map.';

  @override
  String get pOfflineSaved =>
      'Walang signal. Naka-save at ipapadala kapag may koneksyon na.';

  @override
  String get pPhotoRetry => 'Subukan ulit';

  @override
  String get pPhotoWaiting =>
      'Ang mga larawang hindi na-upload ay awtomatikong ipapadala kapag may koneksyon.';

  @override
  String pUploadedCount(String total, String done) {
    return '$done sa $total ang na-upload';
  }

  @override
  String get cIntPayout => 'Bayad sa mga partner';

  @override
  String get poTabSettlements => 'Mga settlement';

  @override
  String get poTabPayouts => 'Mga bayad';

  @override
  String get poState_requested => 'Hiniling';

  @override
  String get poState_sent => 'Naipadala';

  @override
  String get poState_paid => 'Nabayaran';

  @override
  String get poState_failed => 'Nabigo';

  @override
  String get poProviderManual => 'Manu-manong paglipat';

  @override
  String get poProviderToss => 'Bayad sa Toss';

  @override
  String get poShowAccount => 'Ipakita ang account';

  @override
  String get poAccountTitle => 'Detalye ng transfer';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'Ipadala ang $amount won kay $holder · $bank · $account, saka i-tap ang kumpirmasyon.';
  }

  @override
  String get poConfirmPaid => 'Markahang nailipat';

  @override
  String get poMarkFailed => 'Markahang nabigo';

  @override
  String get poReasonTitle => 'Dahilan ng pagkabigo';

  @override
  String get poReasonHint => 'hal. maling account, nakansela ang transfer';

  @override
  String get poSend => 'Ipadala sa pamamagitan ng Toss';

  @override
  String get poSync => 'Tingnan ang status';

  @override
  String get poRetry => 'Subukan muli';

  @override
  String get poNoPayouts => 'Wala pang bayad';

  @override
  String poRequestedToast(String n) {
    return 'Gumawa ng $n na kahilingan sa bayad';
  }

  @override
  String get poReasonRequired => 'Maglagay ng dahilan';

  @override
  String get poRevealNote => 'Naitatala ang pagtingin sa detalye ng account';

  @override
  String get poSellerAction => 'Irehistro bilang Toss seller';

  @override
  String get poSellerTitle => 'Irehistro bilang Toss seller';

  @override
  String get poSellerHint =>
      'Gagamitin ang na-verify na payout account ng partner. Ilagay lang ang impormasyon ng negosyo.';

  @override
  String get poSellerIndividual => 'Indibidwal';

  @override
  String get poSellerCompany => 'Negosyo';

  @override
  String get poSellerName => 'Pangalan';

  @override
  String get poSellerRepresentative => 'Pangalan ng kinatawan';

  @override
  String get poSellerRegNo => 'Numero ng pagpaparehistro ng negosyo (10 digit)';

  @override
  String get poSellerEmail => 'Email para sa settlement';

  @override
  String get poSellerPhone => 'Telepono';

  @override
  String get poSellerSubmit => 'Irehistro';

  @override
  String poSellerDone(String status) {
    return 'Katayuan ng seller: $status';
  }

  @override
  String get oFlags => 'Mga switch ng feature';

  @override
  String get oFlagBooking => 'Mga booking';

  @override
  String get oFlagChat => 'Chat';

  @override
  String get oFlagAi => 'AI assistant';

  @override
  String get oFlagPayments => 'Mga bayad';

  @override
  String get oMaintenance => 'Maintenance mode';

  @override
  String get oMaintenanceHint =>
      'Kapag naka-on, magpapakita ng maintenance screen ang customer at partner app. Gumagana pa rin ang console.';

  @override
  String get oMaintenanceMessage => 'Mensahe sa maintenance';

  @override
  String get oClientErrors => 'Mga ulat ng error sa app';

  @override
  String get oClientErrorsHint =>
      'Mga kamakailang error mula sa web, Windows at console. Awtomatikong tinatakpan ang personal na impormasyon.';

  @override
  String get oClientErrorsEmpty => 'Walang kamakailang error';

  @override
  String get oHeartbeat => 'Uptime heartbeat';

  @override
  String get oHeartbeatOn =>
      'Nakakonekta. Naaabisuhan ang panlabas na serbisyo habang gumagana ang server.';

  @override
  String get oHeartbeatOff =>
      'Hindi pa nakatakda: idagdag ang MALKKEUM_HEARTBEAT_URL sa install.sh.';

  @override
  String get pvManage => 'Mga pahintulot';

  @override
  String get pvOptional => 'Opsyonal';

  @override
  String get pvTerms => 'Pagsang-ayon sa Mga Tuntunin ng Serbisyo';

  @override
  String get pvPrivacy =>
      'Pagsang-ayon sa pagkolekta at paggamit ng personal na datos';

  @override
  String get pvOverseas =>
      'Pagsang-ayon sa pagpapadala ng personal na datos sa ibang bansa';

  @override
  String get pvMarketing => 'Mga mensaheng pang-marketing';

  @override
  String get pvMarketingHint =>
      'Makakatanggap ng balita tungkol sa coupon at event sa SMS, KakaoTalk, at app push. Maaari mo itong i-off anumang oras.';

  @override
  String get pvReconsent =>
      'Nagbago ang aming patakaran sa privacy. Pakisuri at sumang-ayon muli.';

  @override
  String get pvSaved => 'Na-save ang mga pahintulot';

  @override
  String get pvExport => 'I-download ang aking data';

  @override
  String get pvExportHint =>
      'Ipinapakita ang lahat ng hawak naming datos tungkol sa iyo bilang JSON. Maaari mo itong kopyahin at itago.';

  @override
  String get pvCopy => 'Kopyahin';

  @override
  String get pvCopied => 'Nakopya';

  @override
  String get pvExportFailed =>
      'Hindi ma-load ang iyong datos. Subukan muli mamaya.';

  @override
  String get safetyEmergency => 'Mga emergency contact';

  @override
  String get emergencyPolice => '112 Pulis';

  @override
  String get emergencyFire => '119 Bumbero at rescue';

  @override
  String get emergencyShop => 'Customer support';

  @override
  String get caseReportAction => 'I-report ang problema';

  @override
  String get caseReportTitle => 'Ano ang nangyari?';

  @override
  String get caseKindDamage => 'Pinsala';

  @override
  String get caseKindLoss => 'Nawala';

  @override
  String get caseKindComplaint => 'Reklamo';

  @override
  String get caseKindNoShow => 'Hindi dumating ang cleaner';

  @override
  String get caseKindSafety => 'Alalahanin sa kaligtasan';

  @override
  String get caseKindPayment => 'Dispute sa bayad';

  @override
  String get caseSummaryHint => 'Ilarawan ang nangyari (hanggang 300 karakter)';

  @override
  String get caseSubmit => 'Isumite';

  @override
  String get caseSubmitted =>
      'Natanggap na. Sasagot ang team sa loob ng 24 na oras.';

  @override
  String get caseFailed => 'Hindi naipadala. Subukan ulit.';

  @override
  String get checkInAction => 'Mag-check in';

  @override
  String get checkOutAction => 'Mag-check out';

  @override
  String checkedInAt(String time) {
    return 'Dumating $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Umalis $time';
  }

  @override
  String get entryCodeAction => 'Ipakita ang entry code';

  @override
  String get entryCodeTitle => 'Entry code';

  @override
  String get entryCodeNotToday => 'Sa araw lang ng pagbisita makikita';

  @override
  String get entryCodeEmpty => 'Walang nakalagay na entry code';

  @override
  String get actionFailed => 'Hindi natapos. Subukan ulit.';

  @override
  String get consoleCasesTitle => 'Pila ng mga kaso';

  @override
  String get consoleCasesEmpty => 'Walang bukas na kaso';

  @override
  String get caseOverdue => 'Lampas sa takda';

  @override
  String get caseStatusOpen => 'Bukas';

  @override
  String get caseStatusInvestigating => 'Iniimbestigahan';

  @override
  String get caseStatusResolved => 'Nalutas';

  @override
  String get caseStatusRejected => 'Tinanggihan';

  @override
  String get caseReassign => 'Ilipat ang partner';

  @override
  String get caseRefund => 'Refund';

  @override
  String get caseHold => 'I-hold ang settlement';

  @override
  String get caseNoteHint => 'Internal na tala';

  @override
  String get caseSave => 'I-save';

  @override
  String get cSetup => 'Pag-setup';

  @override
  String get cSetupTitle => 'Paghahanda sa paglulunsad';

  @override
  String cSetupProgress(String done, String total) {
    return '$done sa $total tapos';
  }

  @override
  String get cSetupAllDone => 'Handa na ang lahat!';

  @override
  String get cSetupBusiness => 'Profile ng negosyo';

  @override
  String get cSetupBusinessName => 'Pangalan ng serbisyo';

  @override
  String get cSetupSupportPhone => 'Telepono ng suporta';

  @override
  String get cSetupSupportEmail => 'Email ng suporta';

  @override
  String get cSetupSupportHours => 'Oras ng suporta';

  @override
  String get cSetupColor => 'Kulay ng brand';

  @override
  String get cSetupLogo => 'Mag-upload ng logo';

  @override
  String get cSetupCompany =>
      'Detalye ng kumpanya (makikita sa ibaba ng app at website)';

  @override
  String get cSetupLegalName => 'Legal na pangalan';

  @override
  String get cSetupCeo => 'Kinatawan';

  @override
  String get cSetupRegNo => 'Numero ng rehistro';

  @override
  String get cSetupMailOrderNo => 'Numero ng online sales registration';

  @override
  String get cSetupAddress => 'Address';

  @override
  String get cSetupPrivacyOfficer => 'Opisyal ng privacy';

  @override
  String get cSetupStoreLinks =>
      'Mga store link (gagana ang mga button sa website kapag napunan)';

  @override
  String get cSetupCustomerApp => 'App ng customer';

  @override
  String get cSetupPartnerApp => 'App ng partner';

  @override
  String get cSetupPayMethods => 'Mga paraan ng bayad';

  @override
  String get cSetupPayMethodsHint =>
      'I-on o i-off ang mga paraang nakikita ng customer. Agad na epekto.';

  @override
  String get cReviewTitle => 'Demo account para sa store review';

  @override
  String get cReviewHint =>
      'Hindi nakakatanggap ng Korean SMS ang reviewer. Ilagay ang numero at 6-digit na code sa review notes. Kusang mag-o-off.';

  @override
  String get cReviewPhone => 'Demo na numero';

  @override
  String get cReviewCode => 'Nakapirming code (6 digit)';

  @override
  String cReviewActiveUntil(String date) {
    return 'Aktibo hanggang $date';
  }

  @override
  String get cReviewEnable => 'I-on (14 araw)';

  @override
  String get pDeleteAccountBody =>
      'Permanenteng mabubura ang team at personal na data. Tapusin muna ang mga naka-assign na trabaho at nakabinbing bayad.';

  @override
  String get err_has_active_jobs =>
      'May naka-assign ka pang trabaho. Tapusin o hilingin sa support na ilipat.';

  @override
  String get err_pending_payouts =>
      'May nakabinbing bayad pa. Maaaring burahin pagkatapos mabayaran.';

  @override
  String get err_phone_required =>
      'I-verify muna ang numero bago tumanggap ng trabaho.';

  @override
  String get nAlerts => 'Mga alerto';

  @override
  String get nEmpty => 'Wala pang alerto';

  @override
  String nUnread(String count) {
    return '$count hindi pa nababasa';
  }

  @override
  String get pVerifyPhone => 'I-verify';

  @override
  String get mMyJobs => 'Mga trabaho ko';

  @override
  String get mNoJobs =>
      'Wala pang naka-assign. Lalabas dito ang mga trabahong ibibigay ng team lead.';

  @override
  String mTeam(String team) {
    return 'Miyembro ng $team';
  }

  @override
  String get cSetupSave => 'I-save';

  @override
  String get cSetupSaved => 'Na-save';

  @override
  String get cSetupTest => 'Subukan ang koneksyon';

  @override
  String get cSetupClear => 'Idiskonekta';

  @override
  String get cSetupConnected => 'Nakakonekta';

  @override
  String get cSetupNotConnected => 'Hindi nakakonekta';

  @override
  String get cSetupFromEnv => 'Gamit ang server settings';

  @override
  String get cSetupCheckInApp =>
      'Na-save · kumpirmahin sa pag-sign in mula sa app';

  @override
  String get cSetupInvalidKey =>
      'Tinanggihan ang key. Suriin ang kinopyang value';

  @override
  String get cSetupUnreachable =>
      'Hindi maabot ang serbisyo. Subukan muli mamaya';

  @override
  String get cSetupKeepValue => 'Naka-save (i-type lang kung papalitan)';

  @override
  String get cSetupGuide => 'Paano i-setup';

  @override
  String get cSetupOpenSite => 'Buksan ang site';

  @override
  String get cSetupWebhook => 'Webhook URL (i-paste sa PortOne console)';

  @override
  String get cCopied => 'Nakopya';

  @override
  String get cSetupDevMode => 'Test mode: walang totoong bayad o mensahe';

  @override
  String get cSetupOptional => 'Opsyonal';

  @override
  String get cIntPortone => 'Bayad (PortOne)';

  @override
  String get cIntSolapi => 'SMS at KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Push ng app (Firebase)';

  @override
  String get cIntKakao => 'Login gamit ang Kakao';

  @override
  String get cIntNaver => 'Login gamit ang Naver';

  @override
  String get cIntGoogle => 'Login gamit ang Google';

  @override
  String get cIntApple => 'Login gamit ang Apple';

  @override
  String get cFirstRunTitle =>
      'Maligayang pagdating! Gumawa ng account ng may-ari';

  @override
  String get cFirstRunBody =>
      'Ilagay ang 12-character na code na ipinakita sa pag-install. Ang account na ito ang mamamahala sa lahat ng setting.';

  @override
  String get cFirstRunCode => 'Code sa pag-setup';

  @override
  String get cName => 'Pangalan';

  @override
  String get cFirstRunCreate => 'Gumawa ng account at magsimula';

  @override
  String get cWrongSetupCode => 'Mali ang setup code';

  @override
  String get cWeakPassword =>
      'Kailangan ng hindi bababa sa 12 character ang password';

  @override
  String get cInvalidValue => 'Pakisuri ang inilagay na value';

  @override
  String get cMfaTitle => 'Dalawang-hakbang na pag-sign in';

  @override
  String get cMfaCode => '6-digit na code mula sa authenticator app';

  @override
  String get cMfaRecovery => 'Recovery code';

  @override
  String get cMfaUseRecovery => 'Gumamit ng recovery code';

  @override
  String get cMfaUseCode => 'Gumamit ng code mula sa authenticator';

  @override
  String get cMfaVerify => 'I-verify';

  @override
  String get cMfaBack => 'Bumalik sa sign-in';

  @override
  String get cMfaEnrolTitle => 'I-set up ang dalawang-hakbang na sign-in';

  @override
  String get cMfaEnrolBody =>
      'Kailangan ng admin ng authenticator app. Idagdag ang key sa ibaba sa Google Authenticator, 1Password o katulad, pagkatapos ilagay ang 6-digit na code na ipinapakita nito.';

  @override
  String get cMfaSecret => 'Setup key';

  @override
  String get cMfaLink => 'Setup link (otpauth)';

  @override
  String get cMfaCopy => 'Kopyahin';

  @override
  String get cMfaCopied => 'Nakopya';

  @override
  String get cMfaConfirm => 'Kumpirmahin at i-on';

  @override
  String get cMfaCodesTitle => 'I-save ang iyong recovery codes';

  @override
  String get cMfaCodesBody =>
      'Kung mawala ang authenticator, bawat code ay magagamit nang isang beses sa pag-sign in. Ipinapakita lamang ang mga ito ngayon.';

  @override
  String get cMfaDownload => 'I-download';

  @override
  String get cMfaSaveFailed =>
      'Hindi maisave ang file sa device na ito. Kopyahin ang mga code at itago nang ligtas.';

  @override
  String get cMfaContinue => 'Magpatuloy sa console';

  @override
  String get cMfaInvalid =>
      'Hindi tugma ang code. Tiyaking tama ang oras ng telepono at subukan muli.';

  @override
  String get cMfaExpired =>
      'Nag-expire ang sign-in. Magsimulang muli sa hakbang ng password.';

  @override
  String get cMfaLocked =>
      'Napakaraming pagsubok. Maghintay ng ilang minuto at subukan muli.';

  @override
  String get cStaffReset => 'I-reset ang password';

  @override
  String get cStaffResetConfirm =>
      'I-reset ang password ng staff na ito? Made-log out siya sa lahat ng lugar.';

  @override
  String get cStaffResetTitle => 'Reset token';

  @override
  String get cStaffResetBody =>
      'Ibigay ang token na ito sa staff. Isang beses lang magagamit, sa loob ng 30 minuto. Hindi na ito makikita pagkasara.';

  @override
  String get subTitle => 'Regular na paglilinis';

  @override
  String get subNew => 'Mag-subscribe';

  @override
  String get subCadence => 'Gaano kadalas';

  @override
  String get subWeekly => 'Kada linggo';

  @override
  String get subBiweekly => 'Kada 2 linggo';

  @override
  String get subEvery4Weeks => 'Kada 4 linggo';

  @override
  String get subWeekday => 'Araw ng linggo';

  @override
  String get subHour => 'Oras ng dating';

  @override
  String subDiscountNote(String percent) {
    return '$percent% diskuwento sa bawat bisita';
  }

  @override
  String get subChargeNote =>
      'Sisingilin ang naka-save na card isang araw bago ang bisita';

  @override
  String get subCreate => 'Mag-subscribe';

  @override
  String get subCreated => 'Nagsimula na ang subscription';

  @override
  String get subNeedAddress => 'Magdagdag muna ng address';

  @override
  String get subListEmpty => 'Wala pang subscription';

  @override
  String get subStatusActive => 'Aktibo';

  @override
  String get subStatusPaused => 'Naka-pause';

  @override
  String get subStatusCancelled => 'Kinansela';

  @override
  String subNextVisit(String date) {
    return 'Susunod na bisita $date';
  }

  @override
  String get subPause => 'I-pause';

  @override
  String get subResume => 'Ituloy';

  @override
  String get subCancelSub => 'Kanselahin ang subscription';

  @override
  String get subCancelConfirm =>
      'Makakansela ang mga susunod na bisita. Kanselahin nang hiwalay ang mga nakareserba na.';

  @override
  String get subSkip => 'Laktawan ang bisitang ito';

  @override
  String get subMove => 'Ilipat ang petsa';

  @override
  String get subVisitLocked =>
      'Hindi na mababago mula isang araw bago ang bisita';

  @override
  String get subPausedPayment =>
      'Naka-pause dahil paulit-ulit na nabigo ang bayad. Palitan ang card at ituloy.';

  @override
  String get subStatePlanned => 'Nakaplano';

  @override
  String get subStateBooked => 'Naka-book';

  @override
  String get subStateSkipped => 'Nilaktawan';

  @override
  String get subStateMissed => 'Hindi natuloy';

  @override
  String get pSubsTitle => 'Mga regular na customer';

  @override
  String get pSubsEmpty => 'Wala pang regular na customer';

  @override
  String get cSubsTitle => 'Mga subscription';

  @override
  String get cSubsEdit => 'I-edit para sa customer';

  @override
  String get cMrr => 'Buwanang paulit-ulit na kita (MRR)';

  @override
  String get cChurn => 'Churn';

  @override
  String get cActiveSubs => 'Aktibong subscription';

  @override
  String get cRecognized => 'Kinilalang kita sa panahon';

  @override
  String get cSubsLoadFailed => 'Hindi ma-load ang mga subscription';

  @override
  String get tTaxSection => 'Buwis';

  @override
  String tVatQuarter(String q) {
    return 'VAT CSV Q$q';
  }

  @override
  String get tVatYear => 'Taon';

  @override
  String get tExportWithholding => 'CSV ng withholding statement';

  @override
  String get tExportTaxInvoices => 'CSV para sa tax invoice upload';

  @override
  String get tTaxLayoutNote =>
      'I-check sa aktuwal na template ng 홈택스 bago mag-upload. Hindi pa beripikado ang layout.';

  @override
  String get tCashReceipts => 'Cash receipts';

  @override
  String get tCashIssued => 'Naibigay na';

  @override
  String get tCashFailed => 'Nabigo';

  @override
  String get tCashPending => 'Naghihintay';

  @override
  String get tCashCancelled => 'Kinansela';

  @override
  String get tReissue => 'Muling ibigay';

  @override
  String get tTaxInvoices => 'Tax invoices';

  @override
  String get tApprovalNumber => 'Approval no.';

  @override
  String get tIssuedOn => 'Petsa ng isyu';

  @override
  String get tMarkIssued => 'Markahang naibigay';

  @override
  String get tQueueEmpty => 'Walang nakabinbing request';

  @override
  String get tWithholdingLabel => 'Withholding';

  @override
  String get tGrossAmount => 'Kabuuan';

  @override
  String get tIncomeTax => 'Buwis sa kita';

  @override
  String get tLocalTax => 'Lokal na buwis sa kita';

  @override
  String get tNetAmount => 'Netong natanggap';

  @override
  String get tNoWithholding => 'Walang withholding (rehistradong negosyo)';

  @override
  String get tEstWithholding => 'Tinatayang withholding (nakabinbin)';

  @override
  String get tReceiptOptions => 'Mga opsyon sa resibo';

  @override
  String get tWantCashReceipt => 'Kumuha ng cash receipt';

  @override
  String get tCashForIncome => 'Para sa tax deduction (numero ng telepono)';

  @override
  String get tCashForBusiness => 'Para sa gastos ng negosyo (business no.)';

  @override
  String get tWantTaxInvoice => 'Kumuha ng tax invoice (negosyo)';

  @override
  String get tPhoneForReceipt => 'Numero ng telepono';

  @override
  String get tBusinessNumber => 'Business registration no.';

  @override
  String get tCompanyName => 'Pangalan ng kumpanya';

  @override
  String get tRepresentative => 'Kinatawan';

  @override
  String get tInvoiceEmail => 'Email para sa invoice';

  @override
  String get tReceiptSave => 'I-save at magbayad';

  @override
  String get tReceiptSaveFailed => 'Hindi na-save ang detalye ng resibo';

  @override
  String get tTaxType => 'Uri ng buwis';

  @override
  String get tTaxFreelancer => 'Freelancer (may withholding)';

  @override
  String get tTaxBusiness => 'Rehistradong negosyo (walang withholding)';

  @override
  String get tReceiptSettings => 'Mga setting ng resibo';

  @override
  String get reviewRuleLine =>
      'Bawal ang panlalait, personal na impormasyon, peke o promotional na nilalaman. Itatago ang mga na-report na review.';

  @override
  String get reportAction => 'I-report';

  @override
  String get reportSheetTitle => 'I-report ang review na ito?';

  @override
  String get reportReasonSpam => 'Spam o ad';

  @override
  String get reportReasonOffensive => 'Pang-iinsulto o poot';

  @override
  String get reportReasonPersonal => 'May personal na impormasyon';

  @override
  String get reportReasonOther => 'Iba pa';

  @override
  String get reportNoteHint => 'Mga detalye (opsyonal, hanggang 300 karakter)';

  @override
  String get reportSubmit => 'Ipadala ang report';

  @override
  String get reportThanks =>
      'Salamat sa pag-report. Titingnan ito ng aming team.';

  @override
  String get reportAlready => 'Na-report mo na ang review na ito';

  @override
  String get reportFailed => 'Hindi naipadala ang report. Subukan ulit.';

  @override
  String get reviewBlocked =>
      'Limitado ang pag-review sa account na ito. Makipag-ugnayan sa suporta.';

  @override
  String get modTitle => 'Mga na-report na review';

  @override
  String get modEmpty => 'Walang naghihintay na report';

  @override
  String modReports(String count) {
    return '$count report';
  }

  @override
  String get modKeep => 'Panatilihin';

  @override
  String get modHide => 'Itago';

  @override
  String get modDelete => 'Burahin';

  @override
  String get modBlockAuthor => 'Limitahan ang author';

  @override
  String get modUnblockAuthor => 'Alisin ang limitasyon';

  @override
  String get modDone => 'Tapos na';

  @override
  String get modFailed => 'Hindi naayos. Subukan ulit.';

  @override
  String get modHidden => 'Nakatagong review';

  @override
  String uUpdateBanner(String version) {
    return 'May bagong bersyon $version';
  }

  @override
  String get uUpdateNow => 'I-update';

  @override
  String get uUpdateLater => 'Mamaya';

  @override
  String get uUpdateRequiredTitle => 'Kailangan ng bagong bersyon';

  @override
  String get uUpdateRequiredBody =>
      'Hindi na suportado ang bersyong ito. Mag-update mula sa tindahan para magpatuloy.';

  @override
  String get uUpdateStore => 'Mag-update sa tindahan';

  @override
  String get uUpdateStoreMissing =>
      'Inihahanda pa ang link ng update. Subukan ulit mamaya.';

  @override
  String uCurrentVersion(String version) {
    return 'Kasalukuyang bersyon $version';
  }

  @override
  String get uAppVersionTitle => 'Mga bersyon ng app';

  @override
  String get uAppVersionHint =>
      'Hihinto sa screen ng update ang app na mas mababa sa minimum. Makakakita ng banner ang mas luma sa pinakabago. Halimbawa: 1.2.0';

  @override
  String get uMinVersion => 'Pinakamababang bersyon';

  @override
  String get uLatestVersion => 'Pinakabagong bersyon';

  @override
  String get webBookNow => 'Mag-book sa web';

  @override
  String get webBookSub => 'Walang kailangang i-install na app';

  @override
  String get apPgBrowserNote =>
      'Tapusin ang bayad sa browser, pagkatapos bumalik dito at pindutin ang button sa ibaba.';

  @override
  String get apPgBrowserDone => 'Tapos na akong magbayad';
}
