// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class TKm extends T {
  TKm([String locale = 'km']) : super(locale);

  @override
  String get apSocialOr => 'ឬ';

  @override
  String get apSocialSignIn => 'ចូលរហ័ស';

  @override
  String get apLoginKakao => 'បន្តជាមួយ Kakao';

  @override
  String get apLoginNaver => 'បន្តជាមួយ Naver';

  @override
  String get apLoginGoogle => 'បន្តជាមួយ Google';

  @override
  String get apLoginApple => 'បន្តជាមួយ Apple';

  @override
  String get apDevSocialNote =>
      'នេះជាមុខងារសាកល្បង។ ការចូលប្រើប្រាស់គណនីសាកល្បង មិនមែនគណនីបណ្តាញសង្គមពិតទេ។';

  @override
  String get apSocialFailed => 'ការចូលរហ័សបានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get apProviderNotConfigured => 'វិធីចូលនេះមិនទាន់អាចប្រើបានទេ';

  @override
  String get apPhoneTaken => 'លេខនេះត្រូវបានភ្ជាប់ជាមួយគណនីផ្សេងរួចហើយ';

  @override
  String get apPhoneAttachTitle => 'សូមផ្ទៀងផ្ទាត់លេខទូរស័ព្ទរបស់អ្នក';

  @override
  String get apPhoneAttachBody =>
      'លេខនេះប្រើសម្រាប់ការកក់ និងទំនាក់ទំនងជាមួយអ្នកបម្រើ។ ផ្ទៀងផ្ទាត់តែម្តងប៉ុណ្ណោះ។';

  @override
  String get apPayAllTitle => 'ជ្រើសរើសវិធីបង់ប្រាក់';

  @override
  String get apPaySavedTitle => 'វិធីបង់ប្រាក់ដែលបានរក្សាទុក';

  @override
  String get apPayMoreTitle => 'វិធីបង់ប្រាក់ទាំងអស់';

  @override
  String get apPayBillingHint => 'ចុះឈ្មោះតែម្តង លើកក្រោយបង់ដោយចុចតែមួយ';

  @override
  String get apPayCheckoutHint => 'បញ្ចប់នៅក្នុងផ្ទាំងបង់ប្រាក់';

  @override
  String get apPayRegistering => 'កំពុងចុះឈ្មោះ…';

  @override
  String get apPayManageHint =>
      'បង់ប្រាក់ដោយចុចតែមួយ ជាមួយវិធីដែលបានរក្សាទុក។ អាចបន្ថែមវិធីបង់ប្រាក់រហ័សនៅទីនេះ។';

  @override
  String get apMethodCard => 'កាតឥណទាន និងកាត debit';

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
  String get apMethodTransfer => 'ផ្ទេរប្រាក់តាមធនាគារ';

  @override
  String get apMethodVirtual => 'គណនីនិម្មិត';

  @override
  String get apMethodPhone => 'បង់តាមវិក្កយបត្រទូរស័ព្ទ';

  @override
  String get apMethodUnknown => 'វិធីផ្សេង';

  @override
  String get apVaTitle => 'គណនីដាក់ប្រាក់កក់របស់អ្នករួចរាល់ហើយ';

  @override
  String get apVaWaiting => 'កំពុងរង់ចាំប្រាក់កក់';

  @override
  String get apVaBody =>
      'ការកក់នឹងត្រូវបានបញ្ជាក់ នៅពេលប្រាក់កក់ចូលមកមុនកំណត់។ ប្រព័ន្ធនឹងពិនិត្យដោយស្វ័យប្រវត្តិ។';

  @override
  String get apVaBank => 'ធនាគារ';

  @override
  String get apVaAccount => 'លេខគណនី';

  @override
  String get apVaHolder => 'ម្ចាស់គណនី';

  @override
  String get apVaAmount => 'ចំនួនទឹកប្រាក់';

  @override
  String apVaDue(String due) {
    return 'សូមដាក់ប្រាក់មុនថ្ងៃ $due';
  }

  @override
  String get apVaCopy => 'ចម្លង';

  @override
  String get apVaCopied => 'បានចម្លងលេខគណនីហើយ';

  @override
  String get apVaBannerTitle => 'មានការកក់ដែលកំពុងរង់ចាំប្រាក់កក់';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · មុនថ្ងៃ $due';
  }

  @override
  String get apVaBannerAction => 'មើលគណនី';

  @override
  String get apPgTitle => 'ផ្ទាំងបង់ប្រាក់';

  @override
  String get apPgDevNote =>
      'នេះជាការក្លែងធ្វើការបង់ប្រាក់សម្រាប់បរិស្ថានអភិវឌ្ឍន៍ប៉ុណ្ណោះ។ គ្មានការចំណាយប្រាក់ពិតទេ។';

  @override
  String apPgPay(String amount) {
    return 'បង់ $amount';
  }

  @override
  String get apPgIssue => 'ទទួលលេខគណនី';

  @override
  String get apPgCancel => 'បោះបង់ការបង់ប្រាក់';

  @override
  String get apErrSlotFullRefunded =>
      'ម៉ោងនោះទើបតែពេញ ដូច្នេះការបង់ប្រាក់ត្រូវបានបោះបង់ និងសងប្រាក់វិញដោយស្វ័យប្រវត្តិ';

  @override
  String get apErrCheckoutExpired =>
      'ផ្ទាំងបង់ប្រាក់បានផុតកំណត់។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get apIdentityTitle => 'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណ (PASS)';

  @override
  String get apIdentityBody =>
      'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណតាមឈ្មោះលេខទូរស័ព្ទ។ ប្រើសម្រាប់ប្រតិបត្តិការ និងការទូទាត់ប្រកបដោយសុវត្ថិភាព។';

  @override
  String get apIdentityAction => 'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណ';

  @override
  String get apIdentityDone => 'បានផ្ទៀងផ្ទាត់អត្តសញ្ញាណរួចរាល់';

  @override
  String get apIdentityVerified => 'បានផ្ទៀងផ្ទាត់';

  @override
  String get apIdentityUnverified => 'មិនទាន់ផ្ទៀងផ្ទាត់';

  @override
  String get apIdentityDevTitle => 'ការផ្ទៀងផ្ទាត់អត្តសញ្ញាណសាកល្បង';

  @override
  String get apIdentityDevBody =>
      'នៅបរិស្ថានអភិវឌ្ឍន៍ វានឹងឆ្លងកាត់ដោយមិនមានការផ្ទៀងផ្ទាត់ពិតទេ។';

  @override
  String get apIdentityDevPass => 'ឆ្លងកាត់';

  @override
  String get apPayManageTitle => 'ចុះឈ្មោះបង់ប្រាក់រហ័ស';

  @override
  String get cTitle => 'កុងសូលប្រតិបត្តិការ';

  @override
  String get cEmail => 'អ៊ីមែល';

  @override
  String get cPassword => 'ពាក្យសម្ងាត់';

  @override
  String get cLogin => 'ចូល';

  @override
  String get cLoginFailed => 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ';

  @override
  String get cDashboard => 'ផ្ទាំងគ្រប់គ្រង';

  @override
  String get cBookings => 'ការកក់';

  @override
  String get cQuoteDesk => 'តុតម្លៃ';

  @override
  String get cInbox => 'ប្រអប់សារ';

  @override
  String get cCatalog => 'បញ្ជីសេវា · តម្លៃ';

  @override
  String get cMarketing => 'កូប៉ុង · មាតិកា';

  @override
  String get cPartners => 'ដៃគូ';

  @override
  String get cSettlements => 'ការទូទាត់';

  @override
  String get cCustomers => 'អតិថិជន';

  @override
  String get cStaff => 'បុគ្គលិក';

  @override
  String get cSearchCommand => 'ស្វែងរក · បញ្ជា';

  @override
  String get cPaletteHint => 'វាយឈ្មោះផ្នែក ឬលេខកក់';

  @override
  String get cTodayJobs => 'ការងារថ្ងៃនេះ';

  @override
  String get cOpenQuotes => 'តម្លៃដែលកំពុងរង់ចាំ';

  @override
  String get cUnassigned => 'មិនទាន់កំណត់';

  @override
  String get cUnreadThreads => 'ការសន្ទនាមិនទាន់អាន';

  @override
  String get cRevenue30 => 'ប្រាក់ចំណូល ៣០ ថ្ងៃ';

  @override
  String get cBookings30 => 'ការកក់ ៣០ ថ្ងៃ';

  @override
  String get cByService => 'ការកក់តាមសេវា (៣០ ថ្ងៃ)';

  @override
  String get cAllStatus => 'ស្ថានភាពទាំងអស់';

  @override
  String get cAllServices => 'សេវាទាំងអស់';

  @override
  String get cSearch => 'ស្វែងរក (លេខ ទូរស័ព្ទ ឈ្មោះ អាសយដ្ឋាន)';

  @override
  String get cNoResults => 'គ្មានលទ្ធផល';

  @override
  String get cNumber => 'លេខ';

  @override
  String get cVisit => 'ការមក';

  @override
  String get cService => 'សេវា';

  @override
  String get cStatus => 'ស្ថានភាព';

  @override
  String get cTeam => 'ក្រុម';

  @override
  String get cAmount => 'ចំនួនទឹកប្រាក់';

  @override
  String get cCustomer => 'អតិថិជន';

  @override
  String get cPayments => 'ការបង់ប្រាក់';

  @override
  String get cChangeStatus => 'ផ្លាស់ប្តូរស្ថានភាព';

  @override
  String get cTeamName => 'ឈ្មោះក្រុមដែលបានកំណត់';

  @override
  String get cAssign => 'កំណត់ក្រុម';

  @override
  String get cMarkDone => 'សម្គាល់ថាបានបញ្ចប់';

  @override
  String get cConfirm => 'សម្គាល់ថាបានបញ្ជាក់';

  @override
  String get cCancelRefund => 'បោះបង់ · សងប្រាក់វិញ';

  @override
  String get cRefundAmount => 'ចំនួនសងវិញ (ទុកទទេ = ពេញចំនួន)';

  @override
  String get cDone => 'បានដំណើរការ';

  @override
  String get cAnswers => 'ចម្លើយរបស់អតិថិជន';

  @override
  String get cEstimateCalc => 'ការគណនាស្វ័យប្រវត្តិ';

  @override
  String get cBase => 'មូលដ្ឋាន';

  @override
  String get cExtras => 'បន្ថែម';

  @override
  String get cSurcharge => 'ថ្លៃបន្ថែម';

  @override
  String get cBeforeVat => 'មុនពន្ធ VAT';

  @override
  String get cProQuotes => 'តម្លៃពីដៃគូ';

  @override
  String get cNoProQuotes => 'មិនទាន់មានតម្លៃពីដៃគូទេ';

  @override
  String get cFinalPrice => 'តម្លៃចុងក្រោយសម្រាប់អតិថិជន';

  @override
  String get cQuoteNote => 'កំណត់ចំណាំសម្រាប់អតិថិជន';

  @override
  String get cSendQuote => 'ផ្ញើតម្លៃទៅអតិថិជន';

  @override
  String get cQuoteSent => 'បានផ្ញើតម្លៃហើយ';

  @override
  String get cCustomerChats => 'អតិថិជន';

  @override
  String get cPartnerChats => 'ដៃគូ';

  @override
  String get cSelectBooking => 'សូមជ្រើសរើសការកក់';

  @override
  String get cRefunded => 'បានសងវិញ';

  @override
  String get cPartRefunded => 'បានសងវិញមួយផ្នែក';

  @override
  String get cFailed => 'បរាជ័យ';

  @override
  String get cSelectThread => 'សូមជ្រើសរើសការសន្ទនា';

  @override
  String get cReplyHint => 'វាយចម្លើយ · Ctrl+Enter ដើម្បីផ្ញើ';

  @override
  String get cOpenBooking => 'បើកការកក់';

  @override
  String get cShortcuts => 'J/K រំកិល · Ctrl+K បញ្ជា';

  @override
  String get cPricing => 'តម្លៃ';

  @override
  String get cMinutes => 'រយៈពេល (នាទី)';

  @override
  String get cActive => 'កំពុងលក់';

  @override
  String get cSaved => 'បានរក្សាទុក';

  @override
  String get cSlotCapacity => 'សមត្ថភាពក្នុងម៉ោងមកដល់នីមួយៗ';

  @override
  String get cUnlimited => 'គ្មានកម្រិត';

  @override
  String get cFormula => 'រូបមន្តគណនាតម្លៃ';

  @override
  String get f_base_studio => 'មូលដ្ឋាន៖ ស្ទូឌីយ៉ូ';

  @override
  String get f_base_one_and_half => 'មូលដ្ឋាន៖ ១.៥ បន្ទប់';

  @override
  String get f_base_two_rooms => 'មូលដ្ឋាន៖ ២ បន្ទប់';

  @override
  String get f_base_three_rooms => 'មូលដ្ឋាន៖ ៣ បន្ទប់';

  @override
  String get f_base_four_plus => 'មូលដ្ឋាន៖ ៤ បន្ទប់ឡើង';

  @override
  String get f_per_extra_bathroom => 'ក្នុងមួយបន្ទប់ទឹកបន្ថែម';

  @override
  String get f_per_balcony => 'ក្នុងមួយបាល់ខុង';

  @override
  String get f_duplex => 'ផ្ទះពីរជាន់';

  @override
  String get f_no_elevator_high_floor => 'គ្មានកង់យន្ត + ជាន់ទី ៣ ឡើង';

  @override
  String get cIssueCoupon => 'ចេញកូប៉ុង';

  @override
  String get cCouponName => 'ឈ្មោះកូប៉ុង';

  @override
  String get cCouponPhones => 'លេខទូរស័ព្ទ (មួយបន្ទាត់ក្នុងមួយលេខ)';

  @override
  String get cAllCustomers => 'ទៅអតិថិជនទាំងអស់';

  @override
  String cIssued(String n) {
    return 'បានចេញ $n សន្លឹក';
  }

  @override
  String get cContent => 'មាតិកា';

  @override
  String get cKind_notice => 'សេចក្តីជូនដំណឹង';

  @override
  String get cKind_tip => 'គន្លឹះ';

  @override
  String get cKind_faq => 'សំណួរញឹកញាប់';

  @override
  String get cKind_banner => 'បាណឺ';

  @override
  String get cKind_legal => 'ច្បាប់';

  @override
  String get cNewContent => 'មាតិកាថ្មី';

  @override
  String get cTitleField => 'ចំណងជើង';

  @override
  String get cBodyField => 'ខ្លឹមសារ';

  @override
  String get cSlug => 'លេខកូដ (ច្បាប់៖ privacy / terms)';

  @override
  String get cVerify => 'អនុម័ត';

  @override
  String get cSuspend => 'ផ្អាក';

  @override
  String get cPro_pending => 'កំពុងរង់ចាំការអនុម័ត';

  @override
  String get cPro_verified => 'កំពុងដំណើរការ';

  @override
  String get cPro_suspended => 'ត្រូវបានផ្អាក';

  @override
  String get cCompleted => 'បានបញ្ចប់';

  @override
  String get cCancelledN => 'បានបោះបង់';

  @override
  String get cRating => 'ការវាយតម្លៃ';

  @override
  String get cFeeRate => 'ថ្លៃសេវា %';

  @override
  String get cRunPayouts => 'ដំណើរការការបង់ប្រាក់';

  @override
  String get cPayoutDate => 'កាលបរិច្ឆេទបង់ប្រាក់ (រហូតដល់)';

  @override
  String cPayoutDone(String n) {
    return 'បានបង់ប្រាក់ដល់ដៃគូ $n នាក់';
  }

  @override
  String get cHold => 'ផ្អាកប្រាក់';

  @override
  String get cRelease => 'ដោះលែងប្រាក់';

  @override
  String get cNet => 'ចំនួនបង់ប្រាក់សុទ្ធ';

  @override
  String get cAddStaff => 'បន្ថែមបុគ្គលិក';

  @override
  String get cRoleAdmin => 'អ្នកគ្រប់គ្រង';

  @override
  String get cRoleConsultant => 'អ្នកផ្តល់ដំបូន្មាន';

  @override
  String get cDeactivate => 'បិទដំណើរការ';

  @override
  String get cActivate => 'បើកដំណើរការ';

  @override
  String get cPasswordRule => 'យ៉ាងតិច ១២ តួអក្សរ';

  @override
  String get cAdminOnly => 'សម្រាប់អ្នកគ្រប់គ្រងតែប៉ុណ្ណោះ';

  @override
  String cBookingsCount(String n) {
    return 'ការកក់ $n';
  }

  @override
  String get cJoined => 'ចូលរួមនៅ';

  @override
  String get cNewBooking => 'មានការកក់ថ្មី';

  @override
  String get cNewMessage => 'សារថ្មី';

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get next => 'បន្ទាប់';

  @override
  String get close => 'បិទ';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get delete => 'លុប';

  @override
  String get edit => 'កែសម្រួល';

  @override
  String get change => 'ផ្លាស់ប្តូរ';

  @override
  String get retry => 'ព្យាយាមម្តងទៀត';

  @override
  String get yes => 'បាទ/ចាស';

  @override
  String get no => 'ទេ';

  @override
  String get required => 'ត្រូវការ';

  @override
  String get viewAll => 'មើលទាំងអស់';

  @override
  String get today => 'ថ្ងៃនេះ';

  @override
  String get errorGeneric =>
      'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀតក្នុងពេលបន្តិចទៀត។';

  @override
  String get errorNetwork => 'សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិតរបស់អ្នក';

  @override
  String get err_invalid_phone => 'សូមពិនិត្យលេខទូរស័ព្ទរបស់អ្នក';

  @override
  String get err_otp_invalid => 'លេខកូដផ្ទៀងផ្ទាត់មិនត្រឹមត្រូវ';

  @override
  String get err_otp_expired => 'លេខកូដផ្ទៀងផ្ទាត់បានផុតកំណត់។ សូមស្នើសុំថ្មី។';

  @override
  String get err_rate_limited =>
      'ការព្យាយាមច្រើនពេក។ សូមព្យាយាមម្តងទៀតពេលក្រោយ។';

  @override
  String get err_studio_too_large =>
      'សេវាសម្អាតស្ទូឌីយ៉ូ ទទួលបានតែផ្ទះដល់ ១០ ពយ៉ុងប៉ុណ្ណោះ';

  @override
  String get err_date_out_of_range =>
      'សូមជ្រើសរើសកាលបរិច្ឆេទចាប់ពីថ្ងៃស្អែក ដល់ក្នុង ៦០ ថ្ងៃ';

  @override
  String get err_slot_full => 'ម៉ោងនោះពេញហើយ។ សូមជ្រើសរើសម៉ោងផ្សេង។';

  @override
  String get err_coupon_expired => 'កូប៉ុងនេះបានផុតកំណត់';

  @override
  String get err_coupon_used => 'កូប៉ុងនេះត្រូវបានប្រើរួចហើយ';

  @override
  String get err_coupon_wrong_service =>
      'កូប៉ុងនេះមិនអាចប្រើសម្រាប់សេវានេះបានទេ';

  @override
  String get err_payment_failed =>
      'ការបង់ប្រាក់មិនត្រូវបានអនុម័ត។ សូមប្រើវិធីបង់ប្រាក់ផ្សេង។';

  @override
  String get err_payment_method_required => 'សូមជ្រើសរើសវិធីបង់ប្រាក់';

  @override
  String get err_cancellation_window_closed =>
      'ចាប់ពី ២ ថ្ងៃមុនថ្ងៃមក អាចបោះបង់តាមរយៈក្រុមការងាររបស់យើងប៉ុណ្ណោះ';

  @override
  String get err_address_required => 'សូមបញ្ចូលអាសយដ្ឋានសម្រាប់ការមក';

  @override
  String get err_already_taken => 'អ្នកបម្រើផ្សេងបានទទួលយកជាមុនហើយ';

  @override
  String get err_invalid_address => 'សូមបំពេញព័ត៌មានអាសយដ្ឋានឱ្យគ្រប់ចន្លោះ';

  @override
  String get tabHome => 'ទំព័រដើម';

  @override
  String get tabBookings => 'ការកក់';

  @override
  String get tabChat => 'សន្ទនា';

  @override
  String get tabMore => 'ផ្សេងទៀត';

  @override
  String get introTitle => 'កក់ការសម្អាតដោយអ្នកជំនាញ\nឱ្យងាយស្រួលបំផុត';

  @override
  String get introBody =>
      'តម្លៃច្បាស់លាស់ · ក្រុមដែលបានផ្ទៀងផ្ទាត់ · វឌ្ឍនភាពផ្ទាល់';

  @override
  String get introStart => 'ចាប់ផ្តើមដោយលេខទូរស័ព្ទ';

  @override
  String get loginPhoneTitle => 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក';

  @override
  String get loginPhoneHint => '012 000 000';

  @override
  String get loginSendCode => 'ទទួលលេខកូដ';

  @override
  String get loginCodeTitle => 'សូមបញ្ចូលលេខកូដ ៦ ខ្ទង់';

  @override
  String loginCodeSentTo(String phone) {
    return 'បានផ្ញើទៅ $phone ហើយ';
  }

  @override
  String get loginResend => 'ផ្ញើម្តងទៀត';

  @override
  String get loginVerify => 'ផ្ទៀងផ្ទាត់';

  @override
  String get loginTerms =>
      'ដោយបន្ត អ្នកយល់ព្រមតាមលក្ខខណ្ឌប្រើប្រាស់ និងគោលការណ៍ឯកជនភាព';

  @override
  String get profileTitle => 'សូមប្រាប់ឈ្មោះរបស់អ្នក';

  @override
  String get profileNameHint => 'ឈ្មោះ';

  @override
  String get profileDone => 'ចាប់ផ្តើម';

  @override
  String get welcomeToast =>
      'មានកូប៉ុងស្វាគមន៍ ២ សន្លឹកនៅក្នុងកាបូបរបស់អ្នកហើយ';

  @override
  String get svc_studio => 'សម្អាតស្ទូឌីយ៉ូ';

  @override
  String get svc_kitchen => 'សម្អាតផ្ទះបាយ';

  @override
  String get svc_bathroom => 'សម្អាតបន្ទប់ទឹក';

  @override
  String get svc_mattress => 'សម្អាតម៉ាទ្រីស';

  @override
  String get svc_aircon => 'សម្អាតម៉ាស៊ីនត្រជាក់';

  @override
  String get svc_sofa => 'សម្អាតសូហ្វា';

  @override
  String get svc_move_out => 'សម្អាតពេលចាកចេញ';

  @override
  String get svc_move_in => 'សម្អាតពេលចូលរស់នៅ';

  @override
  String get svcShort_studio => 'ស្ទូឌីយ៉ូ';

  @override
  String get svcShort_kitchen => 'ផ្ទះបាយ';

  @override
  String get svcShort_bathroom => 'បន្ទប់ទឹក';

  @override
  String get svcShort_mattress => 'ម៉ាទ្រីស';

  @override
  String get svcShort_aircon => 'ម៉ាស៊ីនត្រជាក់';

  @override
  String get svcShort_sofa => 'សូហ្វា';

  @override
  String get svcShort_move_out => 'ចាកចេញ';

  @override
  String get svcShort_move_in => 'ចូលរស់នៅ';

  @override
  String get svcDesc_studio =>
      'សម្អាតស្ទូឌីយ៉ូដល់ ១០ ពយ៉ុង ដែលមាន ១ បន្ទប់ និង ១ បន្ទប់ទឹក យ៉ាងល្អិតល្អន់ ក្នុងរយៈពេល ២ ម៉ោង។';

  @override
  String get svcDesc_kitchen =>
      'សម្អាតផ្ទះបាយជាពិសេស៖ អាងលាង ចង្ក្រាន ផ្ទៃក្រៅម៉ាស៊ីនបូមផ្សែង និងតុផ្ទៃ។';

  @override
  String get svcDesc_bathroom =>
      'សម្អាតធ្នើរ ម៉ាស៊ីនបើកទឹក អាងលាង និងបង្គន់ ទាំងខាងក្នុងនិងខាងក្រៅ រួចធ្វើឱ្យឥដ្ឋស្ងួត។';

  @override
  String get svcDesc_mattress =>
      'ម៉ាស៊ីនឯកទេសស្រូបធូលី សត្វមីក្រូ និងស្នាម រួចសម្លាប់មេរោគដោយចំហាយទឹក។';

  @override
  String get svcDesc_aircon =>
      'ដោះដំឡើង រួចលាងសម្ពាធខ្ពស់ លើកង់កំដៅ ផ្នែកត្រជាក់ និងតម្រង ហើយសម្លាប់មេរោគ។';

  @override
  String get svcDesc_sofa =>
      'ប្រើជាតិសាប៊ូសមស្របនឹងក្រណាត់ បំបែកភាពកខ្វក់ រួចលាងដោយវិធីស្រូបទឹក។';

  @override
  String get svcDesc_move_out =>
      'មុនចាកចេញ ក្រុមអ្នកជំនាញនឹងមកជាមួយឧបករណ៍ សម្អាតផ្ទះទទេ។';

  @override
  String get svcDesc_move_in =>
      'មុនចូលរស់នៅផ្ទះថ្មី ក្រុមអ្នកជំនាញនឹងមកជាមួយឧបករណ៍ សម្អាតផ្ទៃខាងក្នុង។';

  @override
  String get svcNotes_bathroom =>
      'ប្រសិនបើលូ ឬបង្គន់ស្ទះ សេវាអាចត្រូវកំណត់\nមិនមានការសម្អាតដោយប្រើគីមីពិសេស ពិដាន ឬប្រព័ន្ធខ្យល់\nផ្សិត និងកខ្វក់ចាស់ អាចនឹងមិនដកចេញទាំងស្រុង';

  @override
  String get svcNotes_mattress =>
      'តម្លៃដូចគ្នាចាប់ពីទំហំតូចដល់ទំហំ king\nស្ងួតពេញលេញក្នុងរយៈពេល ៤–៦ ម៉ោង\nការខូចខាតស្ព្រីង ឬការរលុង មិនអាចជួសជុលបានទេ';

  @override
  String get svcNotes_aircon =>
      'ម៉ាស៊ីនដែលមានអាយុលើស ១០ ឆ្នាំ អាចពិបាកដោះដំឡើង\nមិនរួមបញ្ចូលការសម្អាតឯកតាខាងក្រៅ\nយើងពិនិត្យថាម៉ាស៊ីនដំណើរការធម្មតាមុន និងក្រោយការសម្អាត';

  @override
  String get svcNotes_sofa =>
      'សូហ្វាស្បែកត្រូវសម្អាត និងកូតសំណើម\nស្នាមចាស់ ឬការប្រែពណ៌ អាចនឹងមិនដកចេញទាំងស្រុង\nស្ងួតពេញលេញក្នុងរយៈពេល ៤–៦ ម៉ោង';

  @override
  String get unitTitle_bathroom => 'ចំនួនបន្ទប់ទឹក';

  @override
  String get unitTitle_mattress => 'ចំនួនម៉ាទ្រីស';

  @override
  String get unitTitle_aircon => 'ប្រភេទម៉ាស៊ីនត្រជាក់';

  @override
  String get unitTitle_sofa => 'ទំហំសូហ្វា';

  @override
  String unit_count(String n) {
    return '$n';
  }

  @override
  String get unit_wall => 'ភ្ជាប់ជញ្ជាំង ១ គ្រឿង';

  @override
  String get unit_stand => 'ឈរដាច់ដោយឡែក ១ គ្រឿង';

  @override
  String get unit_two_in_one => '២ក្នុង១ (ឈរ + ជញ្ជាំង)';

  @override
  String get unit_ceiling => 'ភ្ជាប់ពិដាន ១ គ្រឿង';

  @override
  String get unit_seat_1_2 => '១–២ កៅអី';

  @override
  String get unit_seat_3 => '៣ កៅអី';

  @override
  String get unit_seat_4_plus => '៤ កៅអីឡើង';

  @override
  String get unit_l_shape => 'រាង L · គ្រែសូហ្វា';

  @override
  String durH(String h) {
    return '$h ម៉ោង';
  }

  @override
  String durHM(String h, String m) {
    return '$h ម៉ោង $m នាទី';
  }

  @override
  String durM(String m) {
    return '$m នាទី';
  }

  @override
  String about(String value) {
    return 'ប្រហែល $value';
  }

  @override
  String fromPrice(String price) {
    return 'ចាប់ពី $price';
  }

  @override
  String get quoteBadge => 'តម្លៃ';

  @override
  String get status0 => 'កំពុងពិគ្រោះយោបល់';

  @override
  String get status1 => 'បានបញ្ជាក់ការកក់';

  @override
  String get status2 => 'បានកំណត់ក្រុមហើយ';

  @override
  String get status3 => 'សម្អាតរួចរាល់';

  @override
  String get statusCancelled => 'បានបោះបង់';

  @override
  String homeGreeting(String name) {
    return '$name សួស្តី,\nថ្ងៃនេះចង់សម្អាតកន្លែងណា?';
  }

  @override
  String get homeGreetingAnon => 'ថ្ងៃនេះចង់សម្អាត\nកន្លែងណាដែរ?';

  @override
  String get homeUpcoming => 'ការកក់ដែលនឹងមកដល់';

  @override
  String dDay(String days) {
    return 'នៅសល់ $days ថ្ងៃ';
  }

  @override
  String get homeServices => 'តើអ្នកត្រូវការសម្អាតអ្វីខ្លះ?';

  @override
  String get homeAddAddress =>
      'បញ្ចូលអាសយដ្ឋានដើម្បីមើលសេវា និងតម្លៃដែលអាចប្រើបានភ្លាម';

  @override
  String get homeAddAddressCta => 'បញ្ចូលអាសយដ្ឋាន';

  @override
  String homeRebook(String service) {
    return 'កក់ $service ម្តងទៀត';
  }

  @override
  String get homeRebookBody => 'កក់រហ័សដោយប្រើលក្ខខណ្ឌដូចលើកមុន';

  @override
  String get homeNotices => 'ព័ត៌មានថ្មី';

  @override
  String get trustVat =>
      'រួមបញ្ចូលពន្ធ VAT\nតម្លៃដែលបានបង្ហាញគឺជាតម្លៃចុងក្រោយ';

  @override
  String get trustCancel => 'បោះបង់ដោយឥតគិតថ្លៃ\nរហូតដល់ ២ ថ្ងៃមុនថ្ងៃមក';

  @override
  String get trustCard =>
      'ព័ត៌មានកាតរបស់អ្នក\nត្រូវបានរក្សាទុកតែនៅក្រុមហ៊ុនបង់ប្រាក់ប៉ុណ្ណោះ';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'ជ្រើសរើសកាលបរិច្ឆេទ';

  @override
  String get notIncluded => 'សូមពិនិត្យមើលព័ត៌មាននេះ';

  @override
  String studioBlockedTitle(String size) {
    return 'ផ្ទៃ $size ពយ៉ុង ធំពេកសម្រាប់សេវាសម្អាតស្ទូឌីយ៉ូ';
  }

  @override
  String get studioBlockedBody =>
      'ក្រុមពិគ្រោះយោបល់របស់យើងនឹងណែនាំសេវាដែលសមនឹងផ្ទះរបស់អ្នក។';

  @override
  String get consultCta => 'សួរក្រុមពិគ្រោះយោបល់';

  @override
  String get addressTitle => 'តើយើងគួរទៅកន្លែងណា?';

  @override
  String get addressAdd => 'បន្ថែមអាសយដ្ឋានថ្មី';

  @override
  String get addressLabel => 'ឈ្មោះ';

  @override
  String get addressLabelHint => 'ឧ. ផ្ទះរបស់ខ្ញុំ';

  @override
  String get addressDistrict => 'ស្រុក/ខណ្ឌ';

  @override
  String get addressRoad => 'អាសយដ្ឋានផ្លូវ';

  @override
  String get addressDetail => 'លេខផ្ទះ / ជាន់';

  @override
  String get addressSize => 'ទំហំផ្ទះ (ពយ៉ុង)';

  @override
  String get addressSizeHelp => 'តាមផ្ទៃប្រើប្រាស់ជាក់ស្តែង · ១ ពយ៉ុង ≈ ៣.៣ ម²';

  @override
  String get addressHome => 'ផ្ទះ';

  @override
  String get addressOffice => 'ការិយាល័យ';

  @override
  String get addressEmpty => 'មិនមានអាសយដ្ឋានដែលបានរក្សាទុក';

  @override
  String get addressSaved => 'បានរក្សាទុកអាសយដ្ឋានហើយ';

  @override
  String pyeong(String n) {
    return '$n ពយ៉ុង';
  }

  @override
  String get scheduleTitle => 'តើយើងគួរមកពេលណា?';

  @override
  String get scheduleArrival => 'ម៉ោងមកដល់';

  @override
  String get scheduleFull => 'ពេញ';

  @override
  String scheduleWindow(String start, String end) {
    return 'មកដល់ $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · ប្រហែលបញ្ចប់ម៉ោង $time';
  }

  @override
  String get scheduleRange => 'អាចកក់បានចាប់ពីថ្ងៃស្អែក ដល់ក្នុង ៦០ ថ្ងៃ';

  @override
  String get morning => 'ព្រឹក';

  @override
  String get afternoon => 'រសៀល';

  @override
  String get scheduleQuoteNote =>
      'ម៉ោងមកដល់ច្បាស់លាស់ នឹងត្រូវបានជម្រាបជូនតាមរយៈសន្ទនា';

  @override
  String get goToPayment => 'ទៅបង់ប្រាក់';

  @override
  String get prepTitle => 'សូមរៀបចំមុនពេលមក';

  @override
  String get prepBody => 'បើមិនបានរៀបចំ អាចមានការកំណត់ការងារមួយចំនួន';

  @override
  String get prepAsk => 'បើមិនអាចរៀបចំបាន សូមជម្រាបក្រុមពិគ្រោះយោបល់ជាមុន';

  @override
  String get tool_vacuum => 'ម៉ាស៊ីនស្រូបធូលី';

  @override
  String get tool_trash => 'ថង់សំរាម';

  @override
  String get tool_mop => 'ម៉ុប';

  @override
  String get tool_cloth => 'ក្រណាត់ជូត';

  @override
  String get tool_gloves => 'ស្រោមដៃកៅស៊ូ';

  @override
  String get tool_sponge => 'ផ្ទាំងលាង';

  @override
  String get tool_spray => 'សារធាតុសម្អាតពហុប្រយោជន៍';

  @override
  String get checkoutTitle => 'បង់ប្រាក់';

  @override
  String get coupon => 'កូប៉ុង';

  @override
  String get couponNone => 'មិនប្រើ';

  @override
  String couponAvailable(String count) {
    return 'មាន $count សន្លឹក';
  }

  @override
  String get paymentMethod => 'វិធីបង់ប្រាក់';

  @override
  String get addPaymentMethod => 'បន្ថែមវិធីបង់ប្រាក់';

  @override
  String get methodCard => 'កាតឥណទាន / debit';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'បានបញ្ចូល';

  @override
  String get methodAdded => 'បានបន្ថែមវិធីបង់ប្រាក់ហើយ';

  @override
  String get listPrice => 'តម្លៃសេវា';

  @override
  String get discount => 'បញ្ចុះតម្លៃកូប៉ុង';

  @override
  String get total => 'ចំនួនបង់សរុប';

  @override
  String get vatIncluded => 'រួមបញ្ចូលពន្ធ VAT';

  @override
  String payAmount(String amount) {
    return 'បង់ $amount';
  }

  @override
  String get needMethod => 'សូមបន្ថែមវិធីបង់ប្រាក់ជាមុនសិន';

  @override
  String freeCancelUntil(String date) {
    return 'បោះបង់ដោយឥតគិតថ្លៃរហូតដល់ $date';
  }

  @override
  String get doneTitle => 'បានកក់ហើយ!';

  @override
  String get doneBody => 'យើងនឹងជម្រាបអ្នកភ្លាមៗ នៅពេលមានក្រុមត្រូវបានកំណត់';

  @override
  String get doneQuoteTitle => 'បានទទួលសំណើរួចរាល់';

  @override
  String get doneQuoteBody =>
      'ក្រុមពិគ្រោះយោបល់របស់យើងនឹងពិនិត្យ រួចផ្ញើតម្លៃចុងក្រោយ។ អ្នកអាចមើលនៅផ្ទាំងសន្ទនា។';

  @override
  String get goHome => 'ទៅទំព័រដើម';

  @override
  String get viewBooking => 'មើលការកក់';

  @override
  String get bookingsTitle => 'ការកក់';

  @override
  String get bookingsUpcoming => 'ដែលនឹងមកដល់';

  @override
  String get bookingsPast => 'ដែលបានកន្លងផុត';

  @override
  String get bookingsEmpty => 'មិនទាន់មានការកក់ទេ';

  @override
  String get bookingsEmptyBody =>
      'កូប៉ុងស្វាគមន៍កំពុងរង់ចាំការកក់ដំបូងរបស់អ្នក';

  @override
  String get bookNow => 'កក់ការសម្អាត';

  @override
  String get detailTitle => 'ព័ត៌មានលម្អិតនៃការកក់';

  @override
  String get stepRequested => 'បានទទួលសំណើ';

  @override
  String get stepConfirmed => 'បានបញ្ជាក់ការកក់';

  @override
  String get stepAssigned => 'បានកំណត់ក្រុម';

  @override
  String get stepCompleted => 'សម្អាតរួចរាល់';

  @override
  String teamVisiting(String team) {
    return '$team កំពុងមក';
  }

  @override
  String get photosSoon => 'រូបថតមុន-ក្រោយ នឹងបង្ហាញនៅទីនេះ នៅពេលបញ្ចប់';

  @override
  String get before => 'មុនសម្អាត';

  @override
  String get after => 'បន្ទាប់ពីសម្អាត';

  @override
  String get prepCheck => 'បញ្ជីរៀបចំ';

  @override
  String get prepAllSet => 'រៀបចំរួចរាល់ទាំងអស់';

  @override
  String get visitAddress => 'អាសយដ្ឋាន';

  @override
  String get paid => 'បានបង់';

  @override
  String get askTeam => 'ផ្ញើសារទៅក្រុម';

  @override
  String get cancelBooking => 'បោះបង់ការកក់';

  @override
  String get cancelTitle => 'តើអ្នកចង់បោះបង់ការកក់នេះមែនទេ?';

  @override
  String get cancelFree =>
      'បើបោះបង់ឥឡូវនេះ អ្នកនឹងទទួលបានប្រាក់សងវិញពេញចំនួន ហើយកូប៉ុងក៏នឹងត្រលប់មកវិញ។';

  @override
  String get cancelKeep => 'រក្សាទុក';

  @override
  String get cancelled => 'បានបោះបង់ការកក់';

  @override
  String get reschedule => 'ប្តូរម៉ោង';

  @override
  String get rescheduled => 'បានប្តូរម៉ោងហើយ';

  @override
  String get visitNotes => 'កំណត់ចំណាំសម្រាប់ក្រុម';

  @override
  String get notesEntry => 'វិធីចូលផ្ទះ (លេខកូដទ្វារ ។ល។)';

  @override
  String get notesParking => 'ចតរថយន្ត';

  @override
  String get notesOther => 'ផ្សេងៗ';

  @override
  String get notesSaved => 'បានរក្សាទុកកំណត់ចំណាំ';

  @override
  String depositDue(String amount) {
    return 'បើបង់ប្រាក់កក់ $amount ការកក់នឹងត្រូវបានបញ្ជាក់';
  }

  @override
  String get payDeposit => 'បង់ប្រាក់កក់';

  @override
  String get waitingQuote => 'ក្រុមពិគ្រោះយោបល់របស់យើងកំពុងរៀបចំតម្លៃ';

  @override
  String get estimate => 'តម្លៃប៉ាន់ស្មាន';

  @override
  String get finalPrice => 'តម្លៃចុងក្រោយ';

  @override
  String get deposit => 'ប្រាក់កក់';

  @override
  String get balance => 'ប្រាក់នៅសល់';

  @override
  String balanceDue(String amount) {
    return 'សូមបង់ប្រាក់នៅសល់ $amount';
  }

  @override
  String get payBalance => 'បង់ប្រាក់នៅសល់';

  @override
  String get reviewTitle => 'ការសម្អាតទៅយ៉ាងណាដែរ?';

  @override
  String get reviewHint => 'សូមប្រាប់យើងពីចំណុចល្អ ឬចំណុចដែលអាចកែលម្អ';

  @override
  String ratingStars(String n) {
    return '$n ផ្កាយ';
  }

  @override
  String get reviewSubmit => 'ផ្ញើការវាយតម្លៃ';

  @override
  String get reviewThanks => 'អរគុណសម្រាប់ការវាយតម្លៃ';

  @override
  String get bookAgain => 'កក់ឡើងវិញដោយលក្ខខណ្ឌដូចគ្នា';

  @override
  String get chatTitle => 'សន្ទនា';

  @override
  String get chatTeam => 'ក្រុមជំនួយ';

  @override
  String get chatHours => 'ថ្ងៃធ្វើការ ០៩:០០–១៨:០០';

  @override
  String get chatEmpty => 'មានសំណួរ? សួរយើងបានគ្រប់ពេល';

  @override
  String get chatNew => 'សន្ទនាថ្មី';

  @override
  String get chatTopicTitle => 'តើអ្នកចង់សួរអំពីអ្វី?';

  @override
  String get topicOther => 'សំណួរផ្សេង';

  @override
  String get chatHint => 'វាយសារ';

  @override
  String get chatSend => 'ផ្ញើ';

  @override
  String get chatPhoto => 'ផ្ញើរូបថត';

  @override
  String get chatTyping => 'ក្រុមកំពុងវាយ…';

  @override
  String get quick_confirm => 'សូមបញ្ជាក់ការកក់';

  @override
  String get quick_price => 'សួរអំពីតម្លៃ';

  @override
  String get quick_date => 'ចង់ប្តូរកាលបរិច្ឆេទ';

  @override
  String get quick_parking => 'តើមានកន្លែងចតរថយន្តទេ?';

  @override
  String get quick_hello => 'សួស្តី';

  @override
  String get quick_duration => 'តើត្រូវចំណាយពេលប៉ុន្មាន?';

  @override
  String get quoteArrived => 'តម្លៃចុងក្រោយបានមកដល់ហើយ';

  @override
  String get quoteDepositNow => 'ប្រាក់កក់ឥឡូវនេះ ១០%';

  @override
  String get quoteBalanceLater => 'ប្រាក់នៅសល់បន្ទាប់ពីការងារ';

  @override
  String get quotePay => 'បង់ប្រាក់កក់ និងបញ្ជាក់';

  @override
  String get quotePaid => 'បានបង់';

  @override
  String get requestCard => 'សំណើតម្លៃ';

  @override
  String get sys_consultation_received => 'សំណើពិគ្រោះយោបល់របស់អ្នកបានទទួលហើយ';

  @override
  String sys_deposit_paid(String amount) {
    return 'បានបង់ប្រាក់កក់ $amount ហើយ។ ការកក់ត្រូវបានបញ្ជាក់។';
  }

  @override
  String get sys_booking_cancelled => 'ការកក់ត្រូវបានបោះបង់';

  @override
  String sys_status_changed(String status) {
    return 'ស្ថានភាពការកក់បានផ្លាស់ប្តូរទៅ \'$status\'';
  }

  @override
  String get sys_job_completed => 'សម្អាតរួចរាល់ហើយ! សូមមើលរូបថតមុន-ក្រោយ។';

  @override
  String sys_rescheduled(String date) {
    return 'បានប្តូរម៉ោងទៅ $date';
  }

  @override
  String get sys_reschedule_declined =>
      'អ្នកបម្រើមិនអាចមកក្នុងម៉ោងថ្មីបានទេ។ ក្រុមរបស់យើងនឹងសម្របសម្រួលឡើងវិញ។';

  @override
  String get moreTitle => 'ផ្សេងទៀត';

  @override
  String get moreScope => 'វិសាលភាពសេវា';

  @override
  String get morePayments => 'ការគ្រប់គ្រងវិធីបង់ប្រាក់';

  @override
  String get moreCoupons => 'កូប៉ុង';

  @override
  String get morePoints => 'ពិន្ទុសម្អាត';

  @override
  String get moreAccount => 'ព័ត៌មានគណនី';

  @override
  String get moreAddresses => 'ការគ្រប់គ្រងអាសយដ្ឋាន';

  @override
  String get moreNotices => 'សេចក្តីជូនដំណឹង';

  @override
  String get moreTips => 'គន្លឹះសម្អាត';

  @override
  String get moreFaq => 'សំណួរដែលសួរញឹកញាប់';

  @override
  String get morePartner => 'ទំនាក់ទំនងសហការជាមួយយើង';

  @override
  String get moreLanguage => 'ភាសា';

  @override
  String get langSystem => 'ធ្វើតាមការកំណត់ឧបករណ៍';

  @override
  String moreVersion(String v) {
    return 'កំណែ $v';
  }

  @override
  String get morePrivacy => 'គោលការណ៍ឯកជនភាព';

  @override
  String get moreTerms => 'លក្ខខណ្ឌប្រើប្រាស់';

  @override
  String get moreLicenses => 'អាជ្ញាប័ណ្ណប្រភពបើកចំហ';

  @override
  String get logout => 'ចេញពីគណនី';

  @override
  String get deleteAccount => 'លុបគណនី';

  @override
  String get deleteAccountBody =>
      'ទិន្នន័យផ្ទាល់ខ្លួនរបស់អ្នកនឹងត្រូវលុប ហើយមិនអាចយកមកវិញបានទេ។ សូមបោះបង់ការកក់ដែលកំពុងដំណើរការជាមុនសិន។';

  @override
  String get couponsEmpty => 'មិនមានកូប៉ុងទេ';

  @override
  String couponUntil(String date) {
    return 'រហូតដល់ $date';
  }

  @override
  String get couponUsed => 'បានប្រើរួច';

  @override
  String get couponExpired => 'ផុតកំណត់';

  @override
  String get couponAnyService => 'សេវាទាំងអស់';

  @override
  String get coupon_welcome_studio => 'កូប៉ុងស្វាគមន៍ស្ទូឌីយ៉ូ';

  @override
  String get coupon_welcome_any => 'កូប៉ុងស្វាគមន៍';

  @override
  String get pointsBalance => 'ពិន្ទុរបស់អ្នក';

  @override
  String get pointsEmpty => 'មិនមានប្រវត្តិពិន្ទុទេ';

  @override
  String get accountName => 'ឈ្មោះ';

  @override
  String get accountPhone => 'លេខទូរស័ព្ទ';

  @override
  String get accountEmail => 'អ៊ីមែល';

  @override
  String get accountLogin => 'វិធីចូល';

  @override
  String get accountLoginPhone => 'ផ្ទៀងផ្ទាត់តាមទូរស័ព្ទ';

  @override
  String get methodsEmpty => 'មិនមានវិធីបង់ប្រាក់ទេ';

  @override
  String get noContent => 'មិនទាន់មានមាតិកានៅទីនេះទេ';

  @override
  String get quoteTypeTitle => 'តើអ្នកត្រូវការសម្អាតប្រភេទណា?';

  @override
  String get type_standard => 'សម្អាតពេលចាកចេញ';

  @override
  String get type_same_day_move => 'ផ្លាស់ទីលំនៅថ្ងៃដដែល';

  @override
  String get type_some_luggage_left => 'នៅសល់ទំនិញមួយចំនួន';

  @override
  String get type_normal_move_in => 'ចូលរស់នៅធម្មតា';

  @override
  String get type_after_interior => 'បន្ទាប់ពីជួសជុលផ្ទះ';

  @override
  String get type_lived_in_deep_clean => 'សម្អាតយ៉ាងម៉ត់ចត់ពេលមានអ្នករស់នៅ';

  @override
  String get luggageTitle => 'តើទំនិញនៅក្នុងផ្ទះស្ថិតក្នុងស្ថានភាពណា?';

  @override
  String get luggage_empty => 'គ្មានទំនិញ';

  @override
  String get luggage_partly_unpacked => 'កំពុងរៀបចំមួយផ្នែក';

  @override
  String get luggage_fully_lived_in => 'មានទំនិញពេញ';

  @override
  String get luggage_unknown => 'មិនប្រាកដ';

  @override
  String get quoteBasicTitle => 'សូមប្រាប់អំពីរចនាសម្ព័ន្ធផ្ទះ';

  @override
  String get buildingType => 'ប្រភេទអាគារ';

  @override
  String get building_apartment => 'ផ្ទះល្វែង';

  @override
  String get building_villa => 'វីឡា / អាគារទាប';

  @override
  String get building_officetel => 'អុហ្វីសតែល';

  @override
  String get building_house => 'ផ្ទះដាច់ដោយឡែក';

  @override
  String get building_other => 'ផ្សេងៗ';

  @override
  String get layoutTitle => 'ប្លង់';

  @override
  String get layout_studio => 'ស្ទូឌីយ៉ូ';

  @override
  String get layout_one_and_half => '១.៥ បន្ទប់';

  @override
  String get layout_two_rooms => '២ បន្ទប់';

  @override
  String get layout_three_rooms => '៣ បន្ទប់';

  @override
  String get layout_four_plus => '៤ បន្ទប់ឡើង';

  @override
  String get duplexTitle => 'តើជាផ្ទះពីរជាន់មែនទេ?';

  @override
  String get quoteSpaceTitle => 'សូមប្រាប់បន្ថែមអំពីលំហ';

  @override
  String get bathroomsLabel => 'បន្ទប់ទឹក';

  @override
  String get balconiesLabel => 'បាល់ខុង · បន្ទប់ប្រើប្រាស់';

  @override
  String get elevatorTitle => 'តើមានកង់យន្តទេ?';

  @override
  String get floor3Label => 'ជាន់ទី ៣ ឡើង';

  @override
  String get quoteEstimateTitle => 'នេះជាតម្លៃប៉ាន់ស្មានរបស់អ្នក';

  @override
  String get quoteEstimateBody =>
      'តម្លៃចុងក្រោយនឹងត្រូវកំណត់នៅក្នុងការពិគ្រោះយោបល់ បន្ទាប់ពីយើងពិនិត្យរូបថត និងស្ថានភាព';

  @override
  String get quoteG1 => 'តម្លៃចុងក្រោយនឹងត្រូវបញ្ជាក់ជាមួយអ្នកតាមសន្ទនា';

  @override
  String get quoteG2 =>
      'ប្រាក់កក់ ១០% ដើម្បីបញ្ជាក់ ហើយប្រាក់ដែលនៅសល់បង់បន្ទាប់ពីការសម្អាត';

  @override
  String get quoteG3 => 'អាចបោះបង់ដោយឥតគិតថ្លៃមុនពេលបញ្ជាក់';

  @override
  String get quoteConfirmTitle => 'សូមពិនិត្យសំណើរបស់អ្នក';

  @override
  String get quoteRequest => 'ផ្ញើសំណើពិគ្រោះយោបល់';

  @override
  String get quoteNoPayNow => 'មិនទាន់ត្រូវបង់ប្រាក់ឥឡូវនេះទេ';

  @override
  String get summaryType => 'ប្រភេទសម្អាត';

  @override
  String get summaryHome => 'ព័ត៌មានផ្ទះ';

  @override
  String get summaryDate => 'ការមក';

  @override
  String get themeTitle => 'ធីម';

  @override
  String get themeDark => 'ងងឹត';

  @override
  String get themeLight => 'ភ្លឺ';

  @override
  String get themeSystem => 'ប្រព័ន្ធ';

  @override
  String get themeTip => 'ប្តូរធីម';

  @override
  String get pTabJobs => 'ការងារ';

  @override
  String get pTabQuotes => 'តម្លៃរបស់ខ្ញុំ';

  @override
  String get pTabSchedule => 'កាលវិភាគ';

  @override
  String get pIntroTitle =>
      'ការងារ កាលវិភាគ និងការបង់ប្រាក់\nសម្រាប់អ្នកជំនាញសម្អាត';

  @override
  String get pIntroBody =>
      'ធ្វើការតែកន្លែង និងម៉ោងដែលអ្នកចង់បាន ទទួលប្រាក់រាល់សប្តាហ៍';

  @override
  String get pOnbTitle => 'សូមប្រាប់អំពីអ្នក';

  @override
  String get pOnbName => 'ឈ្មោះអ្នកតំណាង';

  @override
  String get pOnbTeam => 'ឈ្មោះក្រុម';

  @override
  String get pOnbServices => 'សេវាដែលអ្នកអាចផ្តល់';

  @override
  String get pOnbAreas => 'តំបន់ធ្វើការ';

  @override
  String get pOnbDone => 'ដាក់ពាក្យ';

  @override
  String get pPendingTitle => 'កំពុងរង់ចាំការអនុម័តគណនី';

  @override
  String get pPendingBody =>
      'យើងនឹងជម្រាបអ្នកនៅពេលក្រុមប្រតិបត្តិការអនុម័ត។ ក្នុងពេលរង់ចាំ សូមចុះឈ្មោះគណនីបង់ប្រាក់របស់អ្នក។';

  @override
  String get pSuspended =>
      'គណនីរបស់អ្នកត្រូវបានផ្អាកជាបណ្តោះអាសន្ន។ សូមទាក់ទងក្រុមប្រតិបត្តិការ។';

  @override
  String get pDirect => 'កក់ផ្ទាល់';

  @override
  String get pQuoteReq => 'សំណើតម្លៃ';

  @override
  String get pShowClosed => 'បង្ហាញការងារដែលបានបិទផងដែរ';

  @override
  String get pSortNewest => 'ថ្មីបំផុត';

  @override
  String get pSortVisit => 'ថ្ងៃមកដែលជិតបំផុត';

  @override
  String get pSortAmount => 'តម្លៃខ្ពស់ជាងគេ';

  @override
  String get pNoJobs => 'មិនមានការងារដែលសមនឹងឥឡូវនេះទេ';

  @override
  String get pNoJobsBody =>
      'ពង្រីកសេវា តំបន់ ឬម៉ោងធ្វើការ ដើម្បីមើលការងារបន្ថែម';

  @override
  String get pPayout => 'ប្រាក់ដែលនឹងទទួល';

  @override
  String get pCustomerEstimate => 'តម្លៃប៉ាន់ស្មានរបស់អតិថិជន';

  @override
  String get pNew => 'ថ្មី';

  @override
  String get pClosed => 'បានបិទ';

  @override
  String get pPrivacyNote =>
      'អាសយដ្ឋានពិត និងព័ត៌មានអតិថិជននឹងបង្ហាញបន្ទាប់ពីអ្នកទទួលយក';

  @override
  String get pAccept => 'ទទួលយកការងារ';

  @override
  String get pAcceptConfirm => 'តើអ្នកចង់ទទួលយកការងារនេះមែនទេ?';

  @override
  String get pAcceptBody =>
      'បន្ទាប់ពីទទួលយក ការងារនេះនឹងបន្ថែមទៅកាលវិភាគរបស់អ្នក ហើយអតិថិជននឹងទទួលការជូនដំណឹងថាបានកំណត់ក្រុម។ ចាប់ពី ២ ថ្ងៃមុនថ្ងៃមក មិនអាចបោះបង់បានទេ។';

  @override
  String get pAccepted => 'បានទទួលយកការងារ';

  @override
  String get pSendQuote => 'ផ្ញើតម្លៃ';

  @override
  String get pQuotePrice => 'តម្លៃដែលអតិថិជនបង់';

  @override
  String get pQuoteNote => 'កំណត់ចំណាំសម្រាប់ក្រុម';

  @override
  String get pQuoteSent => 'បានផ្ញើតម្លៃហើយ';

  @override
  String pFee(String rate) {
    return 'ថ្លៃសេវា $rate%';
  }

  @override
  String get pYouGet => 'អ្នកនឹងទទួលបាន';

  @override
  String get pQuoteAll => 'ទាំងអស់';

  @override
  String get pQ_waiting => 'កំពុងរង់ចាំ';

  @override
  String get pQ_selected => 'បានជ្រើសរើស';

  @override
  String get pQ_rejected => 'មិនបានជ្រើសរើស';

  @override
  String get pQ_closed => 'បានបិទ';

  @override
  String get pUnseenOnly => 'លទ្ធផលថ្មីតែប៉ុណ្ណោះ';

  @override
  String get pNoQuotes => 'មិនទាន់មានតម្លៃដែលបានផ្ញើទេ';

  @override
  String get pMyQuote => 'តម្លៃរបស់ខ្ញុំ';

  @override
  String get pWithdraw => 'ដកតម្លៃវិញ';

  @override
  String get pWithdrawn => 'បានដកតម្លៃវិញហើយ';

  @override
  String get pOnlyMine => 'របស់ខ្ញុំតែប៉ុណ្ណោះ';

  @override
  String pJobsCount(String n) {
    return 'ការងារ $n';
  }

  @override
  String get pNoSchedule => 'ថ្ងៃនេះមិនមានកាលវិភាគទេ';

  @override
  String get pCancelledBanner =>
      'អតិថិជនបានបោះបង់ការងារនេះ។ មិនអាចសម្គាល់ថាបានបញ្ចប់បានទេ។';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'សំណើប្តូរម៉ោង៖ $from → $to';
  }

  @override
  String get pRescheduleOk => 'ខ្ញុំអាចមកបាន';

  @override
  String get pRescheduleNo => 'ខ្ញុំមិនអាចមកបាន';

  @override
  String get pCustomer => 'អតិថិជន';

  @override
  String get pCall => 'ហៅតាមលេខសម្ងាត់';

  @override
  String get pCallSoon => 'ការហៅតាមលេខសម្ងាត់នឹងបើកដំណើរការនៅពេលចាប់ផ្តើមសេវា';

  @override
  String get pQuietHours => 'សូមកុំហៅទូរស័ព្ទបន្ទាប់ពីម៉ោង ២០:០០';

  @override
  String get pAssignee => 'អ្នកទទួលខុសត្រូវ';

  @override
  String get pChangeAssignee => 'ផ្លាស់ប្តូរអ្នកទទួលខុសត្រូវ';

  @override
  String get pCustomerRequests => 'សំណើរបស់អតិថិជន';

  @override
  String get pTeamMemo => 'កំណត់ចំណាំក្រុម (អតិថិជនមិនអាចមើលឃើញ)';

  @override
  String get pMemoSaved => 'បានរក្សាទុកកំណត់ចំណាំ';

  @override
  String get pPayoutBreakdown => 'លម្អិតការបង់ប្រាក់';

  @override
  String get pAfterBalance => 'នឹងបង់ប្រាក់បន្ទាប់ពីអតិថិជនបង់ប្រាក់នៅសល់';

  @override
  String get pChatOps => 'ឆាតជាមួយក្រុមប្រតិបត្តិការ';

  @override
  String get pComplete => 'សម្គាល់ការងារថាបានបញ្ចប់';

  @override
  String get pBeforePhotos => 'រូបថតមុនសម្អាត';

  @override
  String get pAfterPhotos => 'រូបថតក្រោយសម្អាត';

  @override
  String get pAddPhoto => 'បន្ថែមរូបថត';

  @override
  String get pChecklist => 'បញ្ជីពិនិត្យ';

  @override
  String get pCheck1 => 'បានសម្អាតគ្រប់កន្លែងដែលបានស្នើសុំ';

  @override
  String get pCheck2 => 'បានចោលសំរាម និងប្រមូលឧបករណ៍រួច';

  @override
  String get pCheck3 => 'បានពិនិត្យបង្អួច ចរន្តអគ្គិសនី និងទឹក';

  @override
  String get pCheck4 => 'បានបំពេញសំណើរបស់អតិថិជន';

  @override
  String get pCompleteCta => 'សម្គាល់ថាបានបញ្ចប់';

  @override
  String get pCompleteNeed =>
      'សូមបញ្ចូលរូបថតយ៉ាងតិច ១ សន្លឹកសម្រាប់ផ្នែកនីមួយៗ ហើយធីកគ្រប់ចំណុចទាំងអស់';

  @override
  String get pCompleted => 'អរគុណសម្រាប់ការងារល្អ!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount នឹងត្រូវបង់នៅថ្ងៃ $date';
  }

  @override
  String get pPayoutWaiting =>
      'កាលបរិច្ឆេទបង់ប្រាក់នឹងត្រូវកំណត់បន្ទាប់ពីអតិថិជនបង់ប្រាក់នៅសល់';

  @override
  String get pPendingPayout => 'ចំនួនប្រាក់ដែលនឹងបង់';

  @override
  String get pSettlements => 'ការទូទាត់';

  @override
  String get pS_waiting_balance => 'កំពុងរង់ចាំប្រាក់នៅសល់';

  @override
  String get pS_pending => 'បានកំណត់ពេល';

  @override
  String get pS_paid => 'បានបង់';

  @override
  String get pS_held => 'បានផ្អាក';

  @override
  String get pReviews => 'ការវាយតម្លៃពីអតិថិជន';

  @override
  String get pNoReviews => 'មិនទាន់មានការវាយតម្លៃទេ';

  @override
  String get pReplyLater => 'មុខងារឆ្លើយតបនឹងបើកដំណើរការឆាប់ៗនេះ';

  @override
  String get pServicesAreas => 'សេវា · តំបន់';

  @override
  String get pPayoutAccount => 'គណនីទទួលប្រាក់';

  @override
  String get pBank => 'ធនាគារ';

  @override
  String get pAccountNumber => 'លេខគណនី';

  @override
  String get pHolder => 'ម្ចាស់គណនី';

  @override
  String get pVerified => 'បានផ្ទៀងផ្ទាត់';

  @override
  String get pUnverified => 'កំពុងផ្ទៀងផ្ទាត់';

  @override
  String get pAccountSaved =>
      'បានរក្សាទុកគណនី។ បើមានការផ្លាស់ប្តូរ នឹងត្រូវផ្ទៀងផ្ទាត់ឡើងវិញ។';

  @override
  String get pWorkSchedule => 'កាលវិភាគធ្វើការ';

  @override
  String get pWeekdays => 'ថ្ងៃធ្វើការ';

  @override
  String get pDayParts => 'ម៉ោងធ្វើការ';

  @override
  String get pDaysOff => 'ថ្ងៃឈប់សម្រាក';

  @override
  String get pAddDayOff => 'បន្ថែមថ្ងៃឈប់សម្រាក';

  @override
  String get pSaved => 'បានរក្សាទុក';

  @override
  String get pTeam => 'សមាជិកក្រុម';

  @override
  String get pOwner => 'ម្ចាស់';

  @override
  String get pInvited => 'បានអញ្ជើញ';

  @override
  String get pInvite => 'អញ្ជើញសមាជិកក្រុម';

  @override
  String get pInviteSent => 'បានផ្ញើសារអញ្ជើញហើយ';

  @override
  String get pRemove => 'ដកចេញ';

  @override
  String get pNotifications => 'ការជូនដំណឹង';

  @override
  String get pNotifyDirect => 'ការងារកក់ផ្ទាល់ថ្មី';

  @override
  String get pNotifyQuotes => 'សំណើតម្លៃ · លទ្ធផល';

  @override
  String get pNotifyChat => 'សារពីក្រុមប្រតិបត្តិការ';

  @override
  String get pQuietNight => 'រំខានតិចពេលយប់ (២២:០០–០៨:០០)';

  @override
  String get pNewInquiry => 'សំណួរថ្មី';

  @override
  String get pTopic_settlement => 'ការបង់ប្រាក់';

  @override
  String get pTopic_reschedule => 'ប្តូរម៉ោង · បោះបង់';

  @override
  String get pTopic_app => 'ជំនួយកម្មវិធី';

  @override
  String get pOpsTeam => 'ប្រតិបត្តិការ';

  @override
  String get pViewJob => 'មើលការងារ';

  @override
  String pBookingNo(String n) {
    return 'ការកក់ $n';
  }

  @override
  String get pSize => 'ទំហំ';

  @override
  String get pSchedule => 'កាលវិភាគ';

  @override
  String get pSpace => 'ព័ត៌មានលំហ';

  @override
  String get cSetup => 'ការកំណត់';

  @override
  String get cSetupTitle => 'ត្រៀមដាក់ឱ្យដំណើរការ';

  @override
  String cSetupProgress(String done, String total) {
    return 'រួចរាល់ $done/$total';
  }

  @override
  String get cSetupAllDone => 'អ្វីៗទាំងអស់រួចរាល់!';

  @override
  String get cSetupBusiness => 'ព័ត៌មានអាជីវកម្ម';

  @override
  String get cSetupBusinessName => 'ឈ្មោះសេវា';

  @override
  String get cSetupSupportPhone => 'ទូរស័ព្ទជំនួយ';

  @override
  String get cSetupSupportEmail => 'អ៊ីមែលជំនួយ';

  @override
  String get cSetupSupportHours => 'ម៉ោងជំនួយ';

  @override
  String get cSetupColor => 'ពណ៌ម៉ាក';

  @override
  String get cSetupLogo => 'ផ្ទុកឡូហ្គោ';

  @override
  String get cSetupCompany =>
      'ព័ត៌មានក្រុមហ៊ុន (បង្ហាញខាងក្រោមកម្មវិធី និងគេហទំព័រ)';

  @override
  String get cSetupLegalName => 'ឈ្មោះផ្លូវច្បាប់';

  @override
  String get cSetupCeo => 'អ្នកតំណាង';

  @override
  String get cSetupRegNo => 'លេខចុះបញ្ជី';

  @override
  String get cSetupMailOrderNo => 'លេខចុះបញ្ជីលក់អនឡាញ';

  @override
  String get cSetupAddress => 'អាសយដ្ឋាន';

  @override
  String get cSetupPrivacyOfficer => 'មន្ត្រីការពារទិន្នន័យ';

  @override
  String get cSetupStoreLinks => 'តំណហាង (ប៊ូតុងលើគេហទំព័រនឹងដំណើរការពេលបំពេញ)';

  @override
  String get cSetupCustomerApp => 'កម្មវិធីអតិថិជន';

  @override
  String get cSetupPartnerApp => 'កម្មវិធីដៃគូ';

  @override
  String get cSetupPayMethods => 'វិធីបង់ប្រាក់';

  @override
  String get cSetupPayMethodsHint =>
      'បើក ឬបិទវិធីបង់ប្រាក់ដែលអតិថិជនឃើញ។ មានប្រសិទ្ធភាពភ្លាមៗ។';

  @override
  String get cReviewTitle => 'គណនីសាកល្បងសម្រាប់ការពិនិត្យហាង';

  @override
  String get cReviewHint =>
      'អ្នកពិនិត្យមិនអាចទទួល SMS កូរ៉េបានទេ។ សូមសរសេរលេខ និងលេខកូដ ៦ ខ្ទង់ក្នុងកំណត់ចំណាំ។ បិទដោយស្វ័យប្រវត្តិ។';

  @override
  String get cReviewPhone => 'លេខទូរស័ព្ទសាកល្បង';

  @override
  String get cReviewCode => 'លេខកូដថេរ (៦ ខ្ទង់)';

  @override
  String cReviewActiveUntil(String date) {
    return 'ប្រើបានដល់ $date';
  }

  @override
  String get cReviewEnable => 'បើក (១៤ ថ្ងៃ)';

  @override
  String get pDeleteAccountBody =>
      'ក្រុម និងទិន្នន័យផ្ទាល់ខ្លួននឹងត្រូវលុបជាអចិន្ត្រៃយ៍។ សូមបញ្ចប់ការងារ និងការទូទាត់ដែលនៅសល់ជាមុន។';

  @override
  String get err_has_active_jobs =>
      'អ្នកនៅមានការងារដែលបានចាត់តាំង។ សូមបញ្ចប់ ឬស្នើជំនួយផ្ទេរ។';

  @override
  String get err_pending_payouts =>
      'នៅមានការទូទាត់មិនទាន់បង់។ អាចលុបបានបន្ទាប់ពីបង់រួច។';

  @override
  String get err_phone_required => 'សូមផ្ទៀងផ្ទាត់លេខទូរស័ព្ទមុនទទួលការងារ។';

  @override
  String get nAlerts => 'ការជូនដំណឹង';

  @override
  String get nEmpty => 'មិនទាន់មានការជូនដំណឹង';

  @override
  String nUnread(String count) {
    return 'មិនទាន់អាន $count';
  }

  @override
  String get pVerifyPhone => 'ផ្ទៀងផ្ទាត់';

  @override
  String get cSetupSave => 'រក្សាទុក';

  @override
  String get cSetupSaved => 'បានរក្សាទុក';

  @override
  String get cSetupTest => 'សាកល្បងការតភ្ជាប់';

  @override
  String get cSetupClear => 'ផ្ដាច់';

  @override
  String get cSetupConnected => 'បានតភ្ជាប់';

  @override
  String get cSetupNotConnected => 'មិនទាន់តភ្ជាប់';

  @override
  String get cSetupFromEnv => 'កំពុងប្រើការកំណត់ម៉ាស៊ីនមេ';

  @override
  String get cSetupCheckInApp => 'បានរក្សាទុក · បញ្ជាក់ដោយចូលពីកម្មវិធី';

  @override
  String get cSetupInvalidKey =>
      'កូនសោត្រូវបានបដិសេធ។ សូមពិនិត្យតម្លៃដែលបានចម្លង';

  @override
  String get cSetupUnreachable => 'មិនអាចភ្ជាប់សេវាបានទេ។ សូមព្យាយាមម្តងទៀត';

  @override
  String get cSetupKeepValue => 'បានរក្សាទុក (វាយតែពេលចង់ប្តូរ)';

  @override
  String get cSetupGuide => 'របៀបកំណត់';

  @override
  String get cSetupOpenSite => 'បើកគេហទំព័រ';

  @override
  String get cSetupWebhook => 'អាសយដ្ឋាន Webhook (បិទភ្ជាប់ក្នុង PortOne)';

  @override
  String get cCopied => 'បានចម្លង';

  @override
  String get cSetupDevMode => 'របៀបសាកល្បង៖ គ្មានការបង់ប្រាក់ ឬសារពិត';

  @override
  String get cSetupOptional => 'ស្រេចចិត្ត';

  @override
  String get cIntPortone => 'ការបង់ប្រាក់ (PortOne)';

  @override
  String get cIntSolapi => 'SMS និង KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'ការជូនដំណឹងកម្មវិធី (Firebase)';

  @override
  String get cIntKakao => 'ចូលដោយ Kakao';

  @override
  String get cIntNaver => 'ចូលដោយ Naver';

  @override
  String get cIntGoogle => 'ចូលដោយ Google';

  @override
  String get cIntApple => 'ចូលដោយ Apple';

  @override
  String get cFirstRunTitle => 'សូមស្វាគមន៍! បង្កើតគណនីម្ចាស់';

  @override
  String get cFirstRunBody =>
      'បញ្ចូលលេខកូដ ១២ តួដែលបង្ហាញពេលដំឡើង។ គណនីនេះគ្រប់គ្រងការកំណត់ទាំងអស់។';

  @override
  String get cFirstRunCode => 'លេខកូដដំឡើង';

  @override
  String get cName => 'ឈ្មោះ';

  @override
  String get cFirstRunCreate => 'បង្កើតគណនី ហើយចាប់ផ្ដើម';

  @override
  String get cWrongSetupCode => 'លេខកូដដំឡើងមិនត្រឹមត្រូវ';

  @override
  String get cWeakPassword => 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ១២ តួ';

  @override
  String get cInvalidValue => 'សូមពិនិត្យតម្លៃដែលបានបញ្ចូល';
}
