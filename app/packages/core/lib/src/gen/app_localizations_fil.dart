// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class TFil extends T {
  TFil([String locale = 'fil']) : super(locale);

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
  String get apMethodTransfer => 'Bank transfer';

  @override
  String get apMethodVirtual => 'Virtual account';

  @override
  String get apMethodPhone => 'Mobile bill';

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
  String get apVaAccount => 'Account number';

  @override
  String get apVaHolder => 'Account holder';

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
  String get apPgTitle => 'Payment window';

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
  String get apIdentityTitle => 'Identity check (PASS)';

  @override
  String get apIdentityBody =>
      'Kinukumpirma ka gamit ang pangalan sa mobile carrier mo. Ginagamit ito para sa ligtas na transaksyon at bayad.';

  @override
  String get apIdentityAction => 'I-verify ang identity';

  @override
  String get apIdentityDone => 'Na-verify na ang identity';

  @override
  String get apIdentityVerified => 'Verified';

  @override
  String get apIdentityUnverified => 'Hindi pa na-verify';

  @override
  String get apIdentityDevTitle => 'Test identity check';

  @override
  String get apIdentityDevBody =>
      'Sa dev environment, pumapasa ito nang walang totoong check.';

  @override
  String get apIdentityDevPass => 'Ipasa';

  @override
  String get apPayManageTitle => 'Magparehistro ng quick-pay';

  @override
  String get cTitle => 'Operations console';

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
  String get cQuoteDesk => 'Quote desk';

  @override
  String get cInbox => 'Inbox';

  @override
  String get cCatalog => 'Catalog at presyo';

  @override
  String get cMarketing => 'Coupons at content';

  @override
  String get cPartners => 'Partners';

  @override
  String get cSettlements => 'Settlements';

  @override
  String get cCustomers => 'Customers';

  @override
  String get cStaff => 'Staff';

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
  String get cNumber => 'Number';

  @override
  String get cVisit => 'Bisita';

  @override
  String get cService => 'Serbisyo';

  @override
  String get cStatus => 'Status';

  @override
  String get cTeam => 'Team';

  @override
  String get cAmount => 'Halaga';

  @override
  String get cCustomer => 'Customer';

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
  String get cBase => 'Base';

  @override
  String get cExtras => 'Dagdag';

  @override
  String get cSurcharge => 'Surcharge';

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
  String get cCustomerChats => 'Customers';

  @override
  String get cPartnerChats => 'Partners';

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
  String get f_base_studio => 'Base: studio';

  @override
  String get f_base_one_and_half => 'Base: 1.5 rooms';

  @override
  String get f_base_two_rooms => 'Base: 2 rooms';

  @override
  String get f_base_three_rooms => 'Base: 3 rooms';

  @override
  String get f_base_four_plus => 'Base: 4+ rooms';

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
  String get cContent => 'Content';

  @override
  String get cKind_notice => 'Notice';

  @override
  String get cKind_tip => 'Tip';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Banner';

  @override
  String get cKind_legal => 'Legal';

  @override
  String get cNewContent => 'Bagong content';

  @override
  String get cTitleField => 'Pamagat';

  @override
  String get cBodyField => 'Nilalaman';

  @override
  String get cSlug => 'Slug (legal: privacy / terms)';

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
  String get cFeeRate => 'Fee %';

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
  String get cRoleAdmin => 'Admin';

  @override
  String get cRoleConsultant => 'Consultant';

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
  String get ok => 'OK';

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
      'Dalawang araw bago ang bisita, sa team natin na lang puwedeng magkansela';

  @override
  String get err_address_required => 'Maglagay ng address para sa bisita';

  @override
  String get err_already_taken => 'Naunahan ka ng ibang pro sa pag-accept';

  @override
  String get err_invalid_address => 'Pakisagutan lahat ng field ng address';

  @override
  String get tabHome => 'Home';

  @override
  String get tabBookings => 'Mga booking';

  @override
  String get tabChat => 'Chat';

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
  String get svc_studio => 'Studio cleaning';

  @override
  String get svc_kitchen => 'Kitchen cleaning';

  @override
  String get svc_bathroom => 'Bathroom cleaning';

  @override
  String get svc_mattress => 'Mattress cleaning';

  @override
  String get svc_aircon => 'Aircon cleaning';

  @override
  String get svc_sofa => 'Sofa cleaning';

  @override
  String get svc_move_out => 'Move-out cleaning';

  @override
  String get svc_move_in => 'Move-in cleaning';

  @override
  String get svcShort_studio => 'Studio';

  @override
  String get svcShort_kitchen => 'Kitchen';

  @override
  String get svcShort_bathroom => 'Banyo';

  @override
  String get svcShort_mattress => 'Mattress';

  @override
  String get svcShort_aircon => 'Aircon';

  @override
  String get svcShort_sofa => 'Sofa';

  @override
  String get svcShort_move_out => 'Move-out';

  @override
  String get svcShort_move_in => 'Move-in';

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
  String get unit_two_in_one => '2-in-1 (stand + wall)';

  @override
  String get unit_ceiling => 'Ceiling cassette, 1 unit';

  @override
  String get unit_seat_1_2 => '1–2 upuan';

  @override
  String get unit_seat_3 => '3 upuan';

  @override
  String get unit_seat_4_plus => '4+ upuan';

  @override
  String get unit_l_shape => 'L-shape / couch';

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
  String get quoteBadge => 'Quote';

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
  String get addressLabel => 'Label';

  @override
  String get addressLabelHint => 'hal. Bahay';

  @override
  String get addressDistrict => 'Distrito';

  @override
  String get addressRoad => 'Street address';

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
  String get tool_gloves => 'Rubber gloves';

  @override
  String get tool_sponge => 'Scrubber';

  @override
  String get tool_spray => 'All-purpose cleaner';

  @override
  String get checkoutTitle => 'Bayad';

  @override
  String get coupon => 'Coupon';

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
  String get methodCard => 'Credit / debit card';

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
  String get before => 'Bago';

  @override
  String get after => 'Pagkatapos';

  @override
  String get prepCheck => 'Checklist ng dapat ihanda';

  @override
  String get prepAllSet => 'Handa na lahat';

  @override
  String get visitAddress => 'Address';

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
  String get notesParking => 'Parking';

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
  String get finalPrice => 'Final quote';

  @override
  String get deposit => 'Deposit';

  @override
  String get balance => 'Balance';

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
  String get chatTitle => 'Chat';

  @override
  String get chatTeam => 'Support team';

  @override
  String get chatHours => 'Weekdays 09:00–18:00';

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
  String get requestCard => 'Quote request';

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
  String get moreCoupons => 'Coupons';

  @override
  String get morePoints => 'Points';

  @override
  String get moreAccount => 'Account';

  @override
  String get moreAddresses => 'Mga address';

  @override
  String get moreNotices => 'Mga anunsyo';

  @override
  String get moreTips => 'Mga tip sa paglilinis';

  @override
  String get moreFaq => 'FAQ';

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
  String get morePrivacy => 'Privacy policy';

  @override
  String get moreTerms => 'Terms of service';

  @override
  String get moreLicenses => 'Open-source licenses';

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
  String get couponExpired => 'Expired';

  @override
  String get couponAnyService => 'Lahat ng serbisyo';

  @override
  String get coupon_welcome_studio => 'Welcome coupon para sa studio';

  @override
  String get coupon_welcome_any => 'Welcome coupon';

  @override
  String get pointsBalance => 'Points mo';

  @override
  String get pointsEmpty => 'Wala pang points history';

  @override
  String get accountName => 'Pangalan';

  @override
  String get accountPhone => 'Mobile';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountLogin => 'Paraan ng pag-login';

  @override
  String get accountLoginPhone => 'Phone verification';

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
  String get building_villa => 'Low-rise';

  @override
  String get building_officetel => 'Officetel';

  @override
  String get building_house => 'Bahay na solo';

  @override
  String get building_other => 'Iba pa';

  @override
  String get layoutTitle => 'Layout';

  @override
  String get layout_studio => 'Studio';

  @override
  String get layout_one_and_half => '1.5 rooms';

  @override
  String get layout_two_rooms => '2 rooms';

  @override
  String get layout_three_rooms => '3 rooms';

  @override
  String get layout_four_plus => '4+ rooms';

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
  String get themeTitle => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeTip => 'Palitan ang theme';

  @override
  String get pTabJobs => 'Trabaho';

  @override
  String get pTabQuotes => 'Mga quote ko';

  @override
  String get pTabSchedule => 'Schedule';

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
  String get pDirect => 'Direct';

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
  String get pCustomer => 'Customer';

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
  String get pBeforePhotos => 'Before photos';

  @override
  String get pAfterPhotos => 'After photos';

  @override
  String get pAddPhoto => 'Magdagdag ng photo';

  @override
  String get pChecklist => 'Checklist';

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
  String get pSettlements => 'Settlements';

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
  String get pPayoutAccount => 'Payout account';

  @override
  String get pBank => 'Bangko';

  @override
  String get pAccountNumber => 'Account number';

  @override
  String get pHolder => 'Account holder';

  @override
  String get pVerified => 'Verified';

  @override
  String get pUnverified => 'Sini-verify';

  @override
  String get pAccountSaved =>
      'Na-save ang account. Kapag may binago, muling ive-verify ito.';

  @override
  String get pWorkSchedule => 'Work schedule';

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
  String get pOwner => 'Owner';

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
  String get pTopic_settlement => 'Payouts';

  @override
  String get pTopic_reschedule => 'Reschedule / kanselasyon';

  @override
  String get pTopic_app => 'Tulong sa app';

  @override
  String get pOpsTeam => 'Operations';

  @override
  String get pViewJob => 'Tingnan ang trabaho';

  @override
  String pBookingNo(String n) {
    return 'Booking $n';
  }

  @override
  String get pSize => 'Laki';

  @override
  String get pSchedule => 'Schedule';

  @override
  String get pSpace => 'Impormasyon ng espasyo';

  @override
  String get cSetup => 'Setup';

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
  String get cSetupPrivacyOfficer => 'Privacy officer';

  @override
  String get cSetupStoreLinks =>
      'Mga store link (gagana ang mga button sa website kapag napunan)';

  @override
  String get cSetupCustomerApp => 'App ng customer';

  @override
  String get cSetupPartnerApp => 'App ng partner';

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
  String get cIntKakao => 'Kakao login';

  @override
  String get cIntNaver => 'Naver login';

  @override
  String get cIntGoogle => 'Google login';

  @override
  String get cIntApple => 'Apple login';

  @override
  String get cFirstRunTitle =>
      'Maligayang pagdating! Gumawa ng account ng may-ari';

  @override
  String get cFirstRunBody =>
      'Ilagay ang 12-character na code na ipinakita sa pag-install. Ang account na ito ang mamamahala sa lahat ng setting.';

  @override
  String get cFirstRunCode => 'Setup code';

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
}
