// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class TMn extends T {
  TMn([String locale = 'mn']) : super(locale);

  @override
  String get addressSearch => 'Хаяг хайх';

  @override
  String get addressSearchHint =>
      'Замын нэр, барилга эсвэл хашааны дугаараар хайх';

  @override
  String get addressSearchButton => 'Хайх';

  @override
  String get addressSearchMinChars => 'Дор хаяж 2 тэмдэгт оруулна уу';

  @override
  String get addressNoResults => 'Үр дүн олдсонгүй. Өөр үгээр оролдоно уу.';

  @override
  String get addressManualEntry => 'Гараар оруулах';

  @override
  String get cardRegisterTitle => 'Карт бүртгэх';

  @override
  String get cIntJuso => 'Хаяг хайлт (juso.go.kr)';

  @override
  String get aiLabel => 'AI туслах';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Хэрэглэгчийн чатад автоматаар хариулна. Мессеж бүр API төлбөртэй.';

  @override
  String get aiModeOffline => 'Ажилтан байхгүй үед л хариулна';

  @override
  String get aiModeAlways => 'AI үргэлж эхлээд хариулна';

  @override
  String get aiPause => 'AI-г түр зогсоох';

  @override
  String get aiResume => 'AI-г үргэлжлүүлэх';

  @override
  String get aiPausedNote => 'Энэ чатад AI түр зогссон';

  @override
  String aiUsageMonth(String count) {
    return 'Энэ сарын AI дуудалт: $count';
  }

  @override
  String get aiNotConfigured => 'AI туслагч идэвхгүй байна';

  @override
  String get aiCapThreadLabel => 'Чатад цагт хариулах хязгаар';

  @override
  String get aiCapMemberLabel => 'Харилцагч тутамд өдөрт хариулах хязгаар';

  @override
  String get aiCapDailyLabel => 'Өдөрт нийт хариулах хязгаар';

  @override
  String get aiCapHint =>
      'Зөвхөн тоо оруулна. Хоосон орхивол анхдагч утга ашиглана.';

  @override
  String get apSocialOr => 'эсвэл';

  @override
  String get apSocialSignIn => 'Хурдан нэвтрэх';

  @override
  String get apLoginKakao => 'Kakao-гаар үргэлжлүүлэх';

  @override
  String get apLoginNaver => 'Naver-ээр үргэлжлүүлэх';

  @override
  String get apLoginGoogle => 'Google-ээр үргэлжлүүлэх';

  @override
  String get apLoginApple => 'Apple-ээр үргэлжлүүлэх';

  @override
  String get apDevSocialNote =>
      'Хөгжүүлэлтийн горим. Жинхэнэ сошиал бүртгэлээр биш, туршилтын бүртгэлээр нэвтэрнэ.';

  @override
  String get apSocialFailed =>
      'Хурдан нэвтрэлт амжилтгүй боллоо. Дахин оролдоно уу.';

  @override
  String get apProviderNotConfigured =>
      'Энэ нэвтрэх арга одоогоор бэлэн биш байна';

  @override
  String get apPhoneTaken => 'Энэ дугаар өөр бүртгэлд холбогдсон байна';

  @override
  String get apPhoneAttachTitle => 'Утасны дугаараа баталгаажуулна уу';

  @override
  String get apPhoneAttachBody =>
      'Энэ дугаарыг захиалга болон мэргэжилтэнтэй холбогдоход ашигладаг. Нэг удаа баталгаажуулахад хангалттай.';

  @override
  String get apPayAllTitle => 'Төлбөрийн хэрэгсэл сонгох';

  @override
  String get apPaySavedTitle => 'Хадгалсан хэрэгслүүд';

  @override
  String get apPayMoreTitle => 'Бүх төлбөрийн хэрэгсэл';

  @override
  String get apPayBillingHint =>
      'Нэг удаа бүртгээд, дараа нь нэг товшилтоор төлнө';

  @override
  String get apPayCheckoutHint => 'Төлбөрийн цонхонд дуусгана уу';

  @override
  String get apPayRegistering => 'Бүртгэж байна…';

  @override
  String get apPayManageHint =>
      'Хадгалсан хэрэгслээр нэг товшилтоор төлнө. Хурдан төлбөрийн хэрэгслийг эндээс нэмнэ.';

  @override
  String get apMethodCard => 'Кредит ба дебит карт';

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
  String get apMethodTransfer => 'Дансаар шилжүүлэг';

  @override
  String get apMethodVirtual => 'Виртуал данс';

  @override
  String get apMethodPhone => 'Утасны дансаар төлөх';

  @override
  String get apMethodUnknown => 'Бусад';

  @override
  String get apVaTitle => 'Урьдчилгаа төлөх дансны мэдээлэл бэлэн боллоо';

  @override
  String get apVaWaiting => 'Урьдчилгаа хүлээгдэж байна';

  @override
  String get apVaBody =>
      'Урьдчилгаа орж ирснээр захиалга баталгаажина. Шилжүүлгийг автоматаар шалгана.';

  @override
  String get apVaBank => 'Банк';

  @override
  String get apVaAccount => 'Дансны дугаар';

  @override
  String get apVaHolder => 'Данс эзэмшигч';

  @override
  String get apVaAmount => 'Дүн';

  @override
  String apVaDue(String due) {
    return '$due гэхээс өмнө шилжүүлнэ үү';
  }

  @override
  String get apVaCopy => 'Хуулах';

  @override
  String get apVaCopied => 'Дансны дугаарыг хууллаа';

  @override
  String get apVaBannerTitle => 'Урьдчилгаа хүлээгдэж буй захиалга бий';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due хүртэл';
  }

  @override
  String get apVaBannerAction => 'Данс харах';

  @override
  String get apPgTitle => 'Төлбөрийн цонх';

  @override
  String get apPgDevNote =>
      'Зөвхөн хөгжүүлэлтийн орчны төлбөрийн туршилт. Бодит төлбөр хасагдахгүй.';

  @override
  String apPgPay(String amount) {
    return '$amount төлөх';
  }

  @override
  String get apPgIssue => 'Дансны дугаар авах';

  @override
  String get apPgCancel => 'Төлбөрийг цуцлах';

  @override
  String get apErrSlotFullRefunded =>
      'Энэ цаг дөнгөж дүүрсэн тул төлбөрийг автоматаар цуцаллаа';

  @override
  String get apErrCheckoutExpired =>
      'Төлбөрийн хугацаа дууслаа. Дахин оролдоно уу.';

  @override
  String get apIdentityTitle => 'Иргэний баталгаажуулалт (PASS)';

  @override
  String get apIdentityBody =>
      'Утасны компаниараа дамжуулан таныг баталгаажуулна. Аюулгүй гүйлгээ, төлбөр тооцоонд ашиглана.';

  @override
  String get apIdentityAction => 'Баталгаажуулах';

  @override
  String get apIdentityDone => 'Таны баталгаажуулалт амжилттай боллоо';

  @override
  String get apIdentityVerified => 'Баталгаажсан';

  @override
  String get apIdentityUnverified => 'Одоогоор баталгаажаагүй';

  @override
  String get apIdentityDevTitle => 'Туршилтын баталгаажуулалт';

  @override
  String get apIdentityDevBody =>
      'Хөгжүүлэлтийн орчинд бодит шалгалтгүйгээр автоматаар тэнцэнэ.';

  @override
  String get apIdentityDevPass => 'Тэнцсэн';

  @override
  String get apPayManageTitle => 'Хурдан төлбөр бүртгэх';

  @override
  String get bizInfoTitle => 'Бизнесийн мэдээлэл';

  @override
  String get bizInfoVerify => 'Бизнесийн бүртгэлийг шалгах';

  @override
  String get cSetupHostingProvider => 'Хостинг үйлчилгээ үзүүлэгч';

  @override
  String get cTitle => 'Үйл ажиллагааны консол';

  @override
  String get cEmail => 'Имэйл';

  @override
  String get cPassword => 'Нууц үг';

  @override
  String get cLogin => 'Нэвтрэх';

  @override
  String get cLoginFailed => 'Имэйл эсвэл нууц үг буруу байна';

  @override
  String get cDashboard => 'Хяналтын самбар';

  @override
  String get cBookings => 'Захиалга';

  @override
  String get cQuoteDesk => 'Үнийн санал';

  @override
  String get cInbox => 'Ирсэн хайрцаг';

  @override
  String get cCatalog => 'Каталог · үнэ';

  @override
  String get cMarketing => 'Купон · контент';

  @override
  String get cPartners => 'Хамтрагчид';

  @override
  String get cSettlements => 'Тооцоо';

  @override
  String get cCustomers => 'Үйлчлүүлэгчид';

  @override
  String get cStaff => 'Ажилтан';

  @override
  String get cSearchCommand => 'Хайх · шилжих';

  @override
  String get cPaletteHint => 'Цэсний нэр эсвэл захиалгын дугаар бичнэ үү';

  @override
  String get cTodayJobs => 'Өнөөдрийн ажил';

  @override
  String get cOpenQuotes => 'Хүлээгдэж буй үнийн санал';

  @override
  String get cUnassigned => 'Оноогоогүй';

  @override
  String get cUnreadThreads => 'Уншаагүй чат';

  @override
  String get cRevenue30 => '30 хоногийн орлого';

  @override
  String get cBookings30 => '30 хоногийн захиалга';

  @override
  String get cByService => 'Үйлчилгээгээр захиалга (30 хоног)';

  @override
  String get cAllStatus => 'Бүх төлөв';

  @override
  String get cAllServices => 'Бүх үйлчилгээ';

  @override
  String get cSearch => 'Хайх (дугаар, утас, нэр, хаяг)';

  @override
  String get cNoResults => 'Үр дүн алга';

  @override
  String get cNumber => 'Дугаар';

  @override
  String get cVisit => 'Очих өдөр';

  @override
  String get cService => 'Үйлчилгээ';

  @override
  String get cStatus => 'Төлөв';

  @override
  String get cTeam => 'Баг';

  @override
  String get cAmount => 'Дүн';

  @override
  String get cCustomer => 'Үйлчлүүлэгч';

  @override
  String get cPayments => 'Төлбөр';

  @override
  String get cChangeStatus => 'Төлөв өөрчлөх';

  @override
  String get cTeamName => 'Оноосон баг';

  @override
  String get cAssign => 'Баг оноох';

  @override
  String get cMarkDone => 'Дууссан гэж тэмдэглэх';

  @override
  String get cConfirm => 'Баталгаажсан гэж тэмдэглэх';

  @override
  String get cCancelRefund => 'Цуцлах · буцаан олгох';

  @override
  String get cRefundAmount => 'Буцаах дүн (хоосон бол бүтнээр)';

  @override
  String get cDone => 'Боловсруулсан';

  @override
  String get cAnswers => 'Үйлчлүүлэгчийн хариулт';

  @override
  String get cEstimateCalc => 'Автоматаар тооцсон';

  @override
  String get cBase => 'Үндсэн';

  @override
  String get cExtras => 'Нэмэлт';

  @override
  String get cSurcharge => 'Нэмэгдэл';

  @override
  String get cBeforeVat => 'НӨАТ-гүй';

  @override
  String get cProQuotes => 'Хамтрагчдын үнийн санал';

  @override
  String get cNoProQuotes => 'Одоогоор ирсэн үнийн санал алга';

  @override
  String get cFinalPrice => 'Үйлчлүүлэгчид эцсийн үнэ';

  @override
  String get cQuoteNote => 'Үйлчлүүлэгчид очих тэмдэглэл';

  @override
  String get cSendQuote => 'Үйлчлүүлэгчид үнийн санал илгээх';

  @override
  String get cQuoteSent => 'Үнийн санал илгээгдлээ';

  @override
  String get cCustomerChats => 'Үйлчлүүлэгчид';

  @override
  String get cPartnerChats => 'Хамтрагчид';

  @override
  String get cSelectBooking => 'Захиалга сонгоно уу';

  @override
  String get cRefunded => 'Буцаагдсан';

  @override
  String get cPartRefunded => 'Хэсэгчлэн буцаагдсан';

  @override
  String get cFailed => 'Амжилтгүй';

  @override
  String get cSelectThread => 'Харилцаа сонгоно уу';

  @override
  String get cReplyHint => 'Хариу бичнэ үү · Ctrl+Enter илгээнэ';

  @override
  String get cOpenBooking => 'Захиалга нээх';

  @override
  String get cShortcuts => 'J/K шилжих · Ctrl+K команд';

  @override
  String get cPricing => 'Үнэ';

  @override
  String get cMinutes => 'Үргэлжлэх хугацаа (мин)';

  @override
  String get cActive => 'Борлуулалтад';

  @override
  String get cSaved => 'Хадгалагдлаа';

  @override
  String get cSlotCapacity => 'Ирэх цаг бүрийн багтаамж';

  @override
  String get cUnlimited => 'Хязгааргүй';

  @override
  String get cFormula => 'Үнийн санал тооцох томьёо';

  @override
  String get cTabCancelPolicy => 'Цуцлалтын бодлого';

  @override
  String get cPolicyDefaultBanner =>
      'Энэ бол анхдагч тохиргоо. Шалгаад хадгалж баталгаажуулна уу.';

  @override
  String get cPolicyDaysBefore => 'Айлчлалаас хэдэн өдрийн өмнөөс (эхлэх)';

  @override
  String get cPolicyPercent => 'Шимтгэл % (хоосон = аппаар цуцлах боломжгүй)';

  @override
  String get cPolicyMinFee => 'Доод шимтгэл (KRW)';

  @override
  String get cPolicyReschedule =>
      'Цаг товлолт өөрчлөх (айлчлалаас хэдэн өдрийн өмнө)';

  @override
  String get cPolicyHint =>
      'Үйлчлүүлэгчийн аппын цуцлах дэлгэцэд шууд хэрэгжинэ. Нөхцөл дараагийн хуулийн build-д шинэчлэгдэнэ.';

  @override
  String get f_base_studio => 'Үндсэн: студио';

  @override
  String get f_base_one_and_half => 'Үндсэн: 1.5 өрөө';

  @override
  String get f_base_two_rooms => 'Үндсэн: 2 өрөө';

  @override
  String get f_base_three_rooms => 'Үндсэн: 3 өрөө';

  @override
  String get f_base_four_plus => 'Үндсэн: 4+ өрөө';

  @override
  String get f_per_extra_bathroom => 'Ванны өрөө нэмэгдэх бүр';

  @override
  String get f_per_balcony => 'Тагт бүр';

  @override
  String get f_duplex => 'Дуплекс';

  @override
  String get f_no_elevator_high_floor => 'Лифтгүй + 3-р давхар ба дээш';

  @override
  String get cIssueCoupon => 'Купон олгох';

  @override
  String get cCouponName => 'Купоны нэр';

  @override
  String get cCouponPhones => 'Утасны дугаарууд (мөр бүрт нэг)';

  @override
  String get cAllCustomers => 'Бүх үйлчлүүлэгчид';

  @override
  String cIssued(String n) {
    return '$n купон олгогдлоо';
  }

  @override
  String get cContent => 'Контент';

  @override
  String get cKind_notice => 'Мэдэгдэл';

  @override
  String get cKind_tip => 'Зөвлөмж';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Баннер';

  @override
  String get cKind_legal => 'Нөхцөл';

  @override
  String get cNewContent => 'Шинэ контент';

  @override
  String get cTitleField => 'Гарчиг';

  @override
  String get cBodyField => 'Агуулга';

  @override
  String get cSlug => 'Слаг (нөхцөл: privacy / terms)';

  @override
  String get cVerify => 'Зөвшөөрөх';

  @override
  String get cSuspend => 'Түр зогсоох';

  @override
  String get cPro_pending => 'Хүлээгдэж буй';

  @override
  String get cPro_verified => 'Идэвхтэй';

  @override
  String get cPro_suspended => 'Түр зогссон';

  @override
  String get cCompleted => 'Дууссан';

  @override
  String get cCancelledN => 'Цуцлагдсан';

  @override
  String get cRating => 'Үнэлгээ';

  @override
  String get cFeeRate => 'Шимтгэл %';

  @override
  String get cRunPayouts => 'Тооцоо хийх';

  @override
  String get cPayoutDate => 'Тооцоолох огноо хүртэл';

  @override
  String cPayoutDone(String n) {
    return '$n хамтрагчид тооцоо хийгдлээ';
  }

  @override
  String get cHold => 'Түр саатуулах';

  @override
  String get cRelease => 'Саатлыг тайлах';

  @override
  String get cNet => 'Цэвэр дүн';

  @override
  String get cAddStaff => 'Ажилтан нэмэх';

  @override
  String get cRoleAdmin => 'Админ';

  @override
  String get cRoleConsultant => 'Зөвлөх';

  @override
  String get cDeactivate => 'Идэвхгүй болгох';

  @override
  String get cActivate => 'Идэвхжүүлэх';

  @override
  String get cPasswordRule => '12-оос дээш тэмдэгт';

  @override
  String get cAdminOnly => 'Зөвхөн админ хийнэ';

  @override
  String cBookingsCount(String n) {
    return '$n захиалга';
  }

  @override
  String get cJoined => 'Бүртгүүлсэн';

  @override
  String get cNewBooking => 'Шинэ захиалга ирлээ';

  @override
  String get cNewMessage => 'Шинэ зурвас';

  @override
  String get cConfirmAsk => 'Итгэлтэй байна уу?';

  @override
  String get cServerTitle => 'Серверийн хаяг оруулах';

  @override
  String get cServerBody =>
      'Суулгалтын тэмдэглэлд өгсөн https:// гэж эхэлсэн серверийн хаягийг оруулна уу. Зөвхөн нэг удаа оруулна.';

  @override
  String get cServerSave => 'Хадгалаад үргэлжлүүлэх';

  @override
  String get cServerInvalid =>
      'Хаяг буруу байна. https:// гэж эхэлсэн серверийн хаяг оруулна уу.';

  @override
  String get cServerChange => 'Серверийн хаяг солих';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Болих';

  @override
  String get next => 'Дараах';

  @override
  String get close => 'Хаах';

  @override
  String get save => 'Хадгалах';

  @override
  String get delete => 'Устгах';

  @override
  String get edit => 'Засах';

  @override
  String get change => 'Солих';

  @override
  String get retry => 'Дахин оролдох';

  @override
  String get yes => 'Тийм';

  @override
  String get no => 'Үгүй';

  @override
  String get required => 'Заавал';

  @override
  String get viewAll => 'Бүгдийг харах';

  @override
  String get today => 'Өнөөдөр';

  @override
  String get errorGeneric =>
      'Алдаа гарлаа. Хэсэг хугацааны дараа дахин оролдоно уу.';

  @override
  String get errorNetwork => 'Интернэт холболтоо шалгана уу';

  @override
  String get err_invalid_phone => 'Утасны дугаараа шалгана уу';

  @override
  String get err_otp_invalid => 'Баталгаажуулах код буруу байна';

  @override
  String get err_otp_expired => 'Кодын хугацаа дууссан. Шинэ код авна уу.';

  @override
  String get err_rate_limited =>
      'Оролдлого хэт олон боллоо. Хэсэг хугацааны дараа оролдоно уу.';

  @override
  String get err_studio_too_large =>
      'Студиог цэвэрлэх үйлчилгээ 10 пён хүртэлх орон сууцанд зориулагдсан';

  @override
  String get err_date_out_of_range =>
      'Маргаашаас эхлээд 60 хоногийн дотор огноо сонгоно уу';

  @override
  String get err_slot_full => 'Энэ цаг дөнгөж дүүрлээ. Өөр цаг сонгоно уу.';

  @override
  String get err_coupon_expired => 'Энэ купоны хугацаа дууссан';

  @override
  String get err_coupon_used => 'Энэ купоныг аль хэдийн ашигласан';

  @override
  String get err_coupon_wrong_service =>
      'Энэ купоныг энэ үйлчилгээнд ашиглах боломжгүй';

  @override
  String get err_payment_failed =>
      'Төлбөрийг зөвшөөрөөгүй. Өөр хэрэгсэл ашиглаад үзнэ үү.';

  @override
  String get err_payment_method_required => 'Төлбөрийн хэрэгсэл сонгоно уу';

  @override
  String get err_cancellation_window_closed =>
      'Энэ захиалгыг аппликейшнээр цуцлах боломжгүй. Манай багтай холбогдоно уу';

  @override
  String get err_address_required => 'Очих хаягаа бүртгэнэ үү';

  @override
  String get err_already_taken => 'Өөр хамтрагч түрүүлж хүлээн авлаа';

  @override
  String get err_invalid_address => 'Хаягийн бүх талбарыг бөглөнө үү';

  @override
  String get tabHome => 'Нүүр';

  @override
  String get tabBookings => 'Миний захиалга';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabMore => 'Бусад';

  @override
  String get introTitle =>
      'Мэргэжлийн цэвэрлэгээг\nхамгийн хялбараар захиалаарай';

  @override
  String get introBody => 'Тогтмол үнэ · Баталгаат баг · Бодит цагийн явц';

  @override
  String get introStart => 'Утасны дугаараар эхлэх';

  @override
  String get loginPhoneTitle => 'Утасны дугаараа хэлнэ үү';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'Код авах';

  @override
  String get loginCodeTitle => '6 оронтой кодыг оруулна уу';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone руу илгээлээ';
  }

  @override
  String get loginResend => 'Дахин авах';

  @override
  String get loginVerify => 'Баталгаажуулах';

  @override
  String get loginTerms =>
      'Үргэлжлүүлснээр та Үйлчилгээний нөхцөл ба Нууцлалын бодлогыг зөвшөөрч байна';

  @override
  String get profileTitle => 'Танд ямар нэрээр хандах вэ?';

  @override
  String get profileNameHint => 'Нэр';

  @override
  String get profileDone => 'Эхлэх';

  @override
  String get welcomeToast => 'Танд угтах купон 2 ширхэг олгогдлоо';

  @override
  String get svc_studio => 'Студио цэвэрлэгээ';

  @override
  String get svc_kitchen => 'Гал тогоо цэвэрлэгээ';

  @override
  String get svc_bathroom => 'Угаалгын өрөө цэвэрлэгээ';

  @override
  String get svc_mattress => 'Матрас цэвэрлэгээ';

  @override
  String get svc_aircon => 'Кондиционер цэвэрлэгээ';

  @override
  String get svc_sofa => 'Диван цэвэрлэгээ';

  @override
  String get svc_move_out => 'Нүүхийн өмнөх цэвэрлэгээ';

  @override
  String get svc_move_in => 'Нүүж орохын өмнөх цэвэрлэгээ';

  @override
  String get svcShort_studio => 'Студио';

  @override
  String get svcShort_kitchen => 'Гал тогоо';

  @override
  String get svcShort_bathroom => 'Угаалгын өрөө';

  @override
  String get svcShort_mattress => 'Матрас';

  @override
  String get svcShort_aircon => 'Кондиционер';

  @override
  String get svcShort_sofa => 'Диван';

  @override
  String get svcShort_move_out => 'Нүүх';

  @override
  String get svcShort_move_in => 'Нүүж орох';

  @override
  String get svcDesc_studio =>
      '10 пён хүртэлх студиог (нэг өрөө, нэг угаалгын өрөөтэй) 2 цагийн турш нарийвчлан цэвэрлэнэ.';

  @override
  String get svcDesc_kitchen =>
      'Гал тогооны гол хэсгийг төвлөрүүлэн цэвэрлэнэ: угаалтуур, плита, сорогчийн гадна тал, ширээний тавцан.';

  @override
  String get svcDesc_bathroom =>
      'Тавиур, усны кран, угаалтуур, бие засах суудлыг дотор, гадна талаас нь цэвэрлээд, шалыг хатаана.';

  @override
  String get svcDesc_mattress =>
      'Мэргэжлийн төхөөрөмжөөр тоос, хачиг, толбыг соруулж, уураар халдваргүйтгэнэ.';

  @override
  String get svcDesc_aircon =>
      'Задлаад, дулаан солилцогч, сэнс, шүүлтүүрийг өндөр даралтаар угааж, халдваргүйтгэнэ.';

  @override
  String get svcDesc_sofa =>
      'Материалд тохирсон бодисоор бохирдлыг задалж, норгоод соруулах аргаар цэвэрлэнэ.';

  @override
  String get svcDesc_move_out =>
      'Нүүхээсээ өмнө мэргэжлийн баг төхөөрөмжтэйгээр ирж, эд зүйлгүй орон сууцыг цэвэрлэнэ.';

  @override
  String get svcDesc_move_in =>
      'Шинэ орон сууцандаа орохын өмнө мэргэжлийн баг төхөөрөмжтэйгээр ирж, дотоодыг цэвэрлэнэ.';

  @override
  String get svcNotes_bathroom =>
      'Бохир ус эсвэл бие засах суудал бөглөрсөн бол үйлчилгээ хязгаарлагдаж магадгүй\nТусгай химийн бодис шаарддаг цэвэрлэгээ, тааз, агааржуулагчийн цэвэрлэгээг оруулаагүй\nХуучин мөөг болон нэвт шингэсэн бохирдол бүрэн арилахгүй байж магадгүй';

  @override
  String get svcNotes_mattress =>
      'Энгийнээс кинг хэмжээ хүртэл адил үнэтэй\nУгаасны дараа 4–6 цагт бүрэн хатна\nПүрш гэмтэх, живэх зэрэг бүтцийн асуудлыг засах боломжгүй';

  @override
  String get svcNotes_aircon =>
      '10 жилээс дээш настай төхөөрөмжийг задлан угаах нь аюултай байж магадгүй\nГадна нэгжийн цэвэрлэгээг оруулаагүй\nЦэвэрлэгээний өмнө, дараа нь ажиллагааг нь шалгана';

  @override
  String get svcNotes_sofa =>
      'Арьсан диваныг цэвэрлэж, чийгшүүлэх бүрхүүлтэй хийнэ\nХуучин толбо эсвэл будгийн шилжилт бүрэн арилахгүй байж магадгүй\nБүрэн хатахад 4–6 цаг шаардагдана';

  @override
  String get unitTitle_bathroom => 'Угаалгын өрөөний тоо';

  @override
  String get unitTitle_mattress => 'Матрасны тоо';

  @override
  String get unitTitle_aircon => 'Агаарын зуухны төрөл';

  @override
  String get unitTitle_sofa => 'Дивааны хэмжээ';

  @override
  String unit_count(String n) {
    return '$n ширхэг';
  }

  @override
  String get unit_wall => 'Ханан дээрх 1';

  @override
  String get unit_stand => 'Шалан дээрх 1';

  @override
  String get unit_two_in_one => '2in1 (шалан дээрх + ханан дээрх)';

  @override
  String get unit_ceiling => 'Тааз суурилуулсан 1';

  @override
  String get unit_seat_1_2 => '1–2 суудалтай';

  @override
  String get unit_seat_3 => '3 суудалтай';

  @override
  String get unit_seat_4_plus => '4+ суудалтай';

  @override
  String get unit_l_shape => 'L хэлбэр · буйдан';

  @override
  String durH(String h) {
    return '$h цаг';
  }

  @override
  String durHM(String h, String m) {
    return '$h цаг $m мин';
  }

  @override
  String durM(String m) {
    return '$m мин';
  }

  @override
  String about(String value) {
    return 'ойролцоогоор $value';
  }

  @override
  String fromPrice(String price) {
    return '$price-ээс';
  }

  @override
  String get quoteBadge => 'Үнийн санал';

  @override
  String get status0 => 'Зөвлөгөө авч байна';

  @override
  String get status1 => 'Захиалга баталгаажсан';

  @override
  String get status2 => 'Баг оноогдсон';

  @override
  String get status3 => 'Цэвэрлэгээ дууссан';

  @override
  String get statusCancelled => 'Цуцлагдсан';

  @override
  String homeGreeting(String name) {
    return 'Сайн байна уу, $name\nӨнөөдөр аль хэсгээ цэвэрлэх вэ?';
  }

  @override
  String get homeGreetingAnon => 'Өнөөдөр аль хэсгээ\nцэвэрлэх вэ?';

  @override
  String get homeUpcoming => 'Ирэх захиалга';

  @override
  String dDay(String days) {
    return 'D-$days';
  }

  @override
  String get homeServices => 'Ямар цэвэрлэгээ хэрэгтэй вэ?';

  @override
  String get homeAddAddress =>
      'Хаягаа бүртгэвэл боломжтой үйлчилгээ, үнийг шууд харуулна';

  @override
  String get homeAddAddressCta => 'Хаяг бүртгэх';

  @override
  String homeRebook(String service) {
    return '$service-ийг дахин захиалах';
  }

  @override
  String get homeRebookBody => 'Өмнөх нөхцөлөөр хурдан захиална, хоёр товшилт';

  @override
  String get homeNotices => 'Шинэ мэдээ';

  @override
  String get trustVat => 'НӨАТ багтсан\nХарагдаж буй үнэ яг тэр хэвээрээ';

  @override
  String get trustCancel => 'Үнэгүй цуцлах\nочихоос 2 хоногийн өмнөх хүртэл';

  @override
  String get trustCard =>
      'Картын мэдээллийг зөвхөн\nтөлбөр хүлээн авагч компани хадгална';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'Огноо сонгох';

  @override
  String get notIncluded => 'Анхаарна уу';

  @override
  String studioBlockedTitle(String size) {
    return '$size пён нь студиогийн цэвэрлэгээнд хэт том байна';
  }

  @override
  String get studioBlockedBody =>
      'Зөвлөх багийн манай хүмүүс таны орон сууцад тохирох үйлчилгээг санал болгоно.';

  @override
  String get consultCta => 'Зөвлөх багт асуух';

  @override
  String get addressTitle => 'Хаана очих вэ?';

  @override
  String get addressAdd => 'Шинэ хаяг нэмэх';

  @override
  String get addressLabel => 'Нэр';

  @override
  String get addressLabelHint => 'Жишээ: Гэр';

  @override
  String get addressDistrict => 'Дүүрэг';

  @override
  String get addressRoad => 'Гудамжны хаяг';

  @override
  String get addressDetail => 'Дэлгэрэнгүй (орц, давхар, тоот)';

  @override
  String get addressSize => 'Орон сууцны хэмжээ (пён)';

  @override
  String get addressSizeHelp => 'Ашиглах талбай · 1 пён ≈ 3.3 м²';

  @override
  String get addressHome => 'Гэр';

  @override
  String get addressOffice => 'Оффис';

  @override
  String get addressEmpty => 'Хадгалсан хаяг алга';

  @override
  String get addressSaved => 'Хаяг хадгалагдлаа';

  @override
  String pyeong(String n) {
    return '$n пён';
  }

  @override
  String get scheduleTitle => 'Хэзээ очих вэ?';

  @override
  String get scheduleArrival => 'Очих цаг';

  @override
  String get scheduleFull => 'Дүүрсэн';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end цагт очно';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · ойролцоогоор $time-д дуусна';
  }

  @override
  String get scheduleRange => 'Маргаашаас эхлэн 60 хоногийн дотор захиална';

  @override
  String get morning => 'Өглөө';

  @override
  String get afternoon => 'Өдөр';

  @override
  String get scheduleQuoteNote => 'Очих яг цагийг чатаар баталгаажуулна';

  @override
  String get goToPayment => 'Төлбөр рүү үргэлжлүүлэх';

  @override
  String get prepTitle => 'Очихын өмнө эдгээрийг бэлдэнэ үү';

  @override
  String get prepBody => 'Эдгээр байхгүй бол зарим ажлыг хязгаарлаж магадгүй';

  @override
  String get prepAsk => 'Бэлдэх боломжгүй юу? Манай багт мэдэгдээрэй';

  @override
  String get tool_vacuum => 'Тоос сорогч';

  @override
  String get tool_trash => 'Хогны уут';

  @override
  String get tool_mop => 'Шалны моп';

  @override
  String get tool_cloth => 'Алчуур';

  @override
  String get tool_gloves => 'Резинэн бээлий';

  @override
  String get tool_sponge => 'Сивэн';

  @override
  String get tool_spray => 'Олон зориулалтын угаагч';

  @override
  String get checkoutTitle => 'Төлбөр';

  @override
  String get coupon => 'Купон';

  @override
  String get couponNone => 'Ашиглахгүй';

  @override
  String couponAvailable(String count) {
    return '$count ашиглах боломжтой';
  }

  @override
  String get paymentMethod => 'Төлбөрийн хэрэгсэл';

  @override
  String get addPaymentMethod => 'Төлбөрийн хэрэгсэл нэмэх';

  @override
  String get methodCard => 'Кредит / дебит карт';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Нэмэгдсэн';

  @override
  String get methodAdded => 'Төлбөрийн хэрэгсэл нэмэгдлээ';

  @override
  String get listPrice => 'Үйлчилгээний үнэ';

  @override
  String get discount => 'Купоны хөнгөлөлт';

  @override
  String get total => 'Төлөх дүн';

  @override
  String get vatIncluded => 'НӨАТ багтсан';

  @override
  String payAmount(String amount) {
    return '$amount төлөх';
  }

  @override
  String get needMethod => 'Эхлээд төлбөрийн хэрэгсэл нэмнэ үү';

  @override
  String freeCancelUntil(String date) {
    return '$date хүртэл үнэгүй цуцлах боломжтой';
  }

  @override
  String get doneTitle => 'Захиалга амжилттай боллоо!';

  @override
  String get doneBody => 'Баг оноогдмогц бид танд нэн даруй мэдэгдэнэ';

  @override
  String get doneQuoteTitle => 'Зөвлөгөөний хүсэлт хүлээн авлаа';

  @override
  String get doneQuoteBody =>
      'Зөвлөх баг шалгаад эцсийн үнийн саналыг илгээнэ. Үнийн саналаа Чат таб дээрээс харж болно.';

  @override
  String get goHome => 'Нүүр хуудас';

  @override
  String get viewBooking => 'Захиалга харах';

  @override
  String get bookingsTitle => 'Захиалга';

  @override
  String get bookingsUpcoming => 'Ирэх';

  @override
  String get bookingsPast => 'Өнгөрсөн';

  @override
  String get bookingsEmpty => 'Одоогоор захиалга алга';

  @override
  String get bookingsEmptyBody =>
      'Анхны захиалгадаа ашиглах угтах купон хүлээж байна';

  @override
  String get bookNow => 'Цэвэрлэгээ захиалах';

  @override
  String get detailTitle => 'Захиалгын дэлгэрэнгүй';

  @override
  String get stepRequested => 'Хүсэлт хүлээн авсан';

  @override
  String get stepConfirmed => 'Захиалга баталгаажсан';

  @override
  String get stepAssigned => 'Баг оноогдсон';

  @override
  String get stepCompleted => 'Цэвэрлэгээ дууссан';

  @override
  String teamVisiting(String team) {
    return '$team очиж байна';
  }

  @override
  String get photosSoon => 'Цэвэрлэгээний өмнөх, дараах зургууд энд гарна';

  @override
  String photoThumb(String n) {
    return 'Зураг $n';
  }

  @override
  String get before => 'Өмнө';

  @override
  String get after => 'Дараа';

  @override
  String get prepCheck => 'Бэлтгэх жагсаалт';

  @override
  String get prepAllSet => 'Бүгд бэлэн';

  @override
  String get visitAddress => 'Хаяг';

  @override
  String get paid => 'Төлсөн';

  @override
  String get askTeam => 'Манай багт бичих';

  @override
  String get cancelBooking => 'Захиалга цуцлах';

  @override
  String get cancelTitle => 'Энэ захиалгыг цуцлах уу?';

  @override
  String get cancelFree =>
      'Одоо цуцалбал төлсөн дүнг бүрэн буцааж, купоныг нь эргүүлнэ.';

  @override
  String get cancelKeep => 'Хэвээр үлдээх';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Одоо цуцлавал $fee шимтгэл төлөгдөж, $refund буцаан олгогдоно.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return '$fee шимтгэлийг зөвшөөрч цуцлах';
  }

  @override
  String get cancelled => 'Захиалга цуцлагдлаа';

  @override
  String get reschedule => 'Цаг солих';

  @override
  String get rescheduled => 'Цаг солигдлоо';

  @override
  String get visitNotes => 'Багт хэлэх зүйл';

  @override
  String get notesEntry => 'Орох арга (орцны код гэх мэт)';

  @override
  String get notesParking => 'Зогсоол';

  @override
  String get notesOther => 'Бусад';

  @override
  String get notesSaved => 'Тэмдэглэл хадгалагдлаа';

  @override
  String depositDue(String amount) {
    return 'Захиалгаа баталгаажуулахын тулд $amount урьдчилгаа төлнө үү';
  }

  @override
  String get payDeposit => 'Урьдчилгаа төлөх';

  @override
  String get waitingQuote => 'Зөвлөх баг таны үнийн саналыг бэлдэж байна';

  @override
  String get estimate => 'Урьдчилсан үнэ';

  @override
  String get finalPrice => 'Эцсийн үнэ';

  @override
  String get deposit => 'Урьдчилгаа';

  @override
  String get balance => 'Үлдэгдэл';

  @override
  String balanceDue(String amount) {
    return '$amount үлдэгдлийг төлнө үү';
  }

  @override
  String get payBalance => 'Үлдэгдэл төлөх';

  @override
  String get reviewTitle => 'Цэвэрлэгээ ямар байна?';

  @override
  String get reviewHint => 'Сайн талаа эсвэл сайжруулах зүйлээ бидэнд хэлээрэй';

  @override
  String ratingStars(String n) {
    return '$n одтой';
  }

  @override
  String get reviewSubmit => 'Сэтгэгдэл илгээх';

  @override
  String get reviewThanks => 'Сэтгэгдэлд баярлалаа';

  @override
  String get bookAgain => 'Дахин захиалах';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatTeam => 'Зөвлөх баг';

  @override
  String get chatHours => 'Ажлын өдрүүд 09:00–18:00';

  @override
  String get chatEmpty => 'Асуулт байна уу? Хүссэн үедээ асууж болно';

  @override
  String get chatNew => 'Шинэ чат';

  @override
  String get chatTopicTitle => 'Юу сонирхож байна вэ?';

  @override
  String get topicOther => 'Бусад асуулт';

  @override
  String get chatHint => 'Зурвас бичнэ үү';

  @override
  String get chatSend => 'Илгээх';

  @override
  String get chatPhoto => 'Зураг илгээх';

  @override
  String get chatTyping => 'Зөвлөх баг бичиж байна…';

  @override
  String get quick_confirm => 'Захиалгаа баталгаажуулъя';

  @override
  String get quick_price => 'Үнийн талаар асуух';

  @override
  String get quick_date => 'Огноо солихыг хүсэж байна';

  @override
  String get quick_parking => 'Зогсоол байгаа юу?';

  @override
  String get quick_hello => 'Сайн байна уу';

  @override
  String get quick_duration => 'Хэр удах вэ?';

  @override
  String get quoteArrived => 'Эцсийн үнийн санал ирлээ';

  @override
  String get quoteDepositNow => 'Одоо 10% урьдчилгаа';

  @override
  String get quoteBalanceLater => 'Цэвэрлэгээний дараа үлдэгдэл';

  @override
  String get quotePay => 'Урьдчилгаа төлөөд баталгаажуулах';

  @override
  String get quotePaid => 'Төлөгдсөн';

  @override
  String get requestCard => 'Үнийн саналын хүсэлт';

  @override
  String get sys_consultation_received => 'Таны хүсэлт хүлээн авагдлаа';

  @override
  String sys_deposit_paid(String amount) {
    return '$amount урьдчилгаа төлөгдлөө. Захиалга баталгаажлаа.';
  }

  @override
  String get sys_booking_cancelled => 'Захиалга цуцлагдлаа';

  @override
  String sys_status_changed(String status) {
    return 'Төлөв \'$status\' болж өөрчлөгдлөө';
  }

  @override
  String get sys_job_completed =>
      'Цэвэрлэгээ дууслаа. Өмнөх, дараах зургуудыг харна уу.';

  @override
  String sys_rescheduled(String date) {
    return 'Огноо $date болж солигдлоо';
  }

  @override
  String get sys_reschedule_declined =>
      'Хамтрагч шинэ цагт очиж чадахгүй байна. Манай зөвлөх баг дахин зохицуулна.';

  @override
  String get moreTitle => 'Бусад';

  @override
  String get moreScope => 'Үйлчилгээний хүрээ';

  @override
  String get morePayments => 'Төлбөрийн хэрэгсэл';

  @override
  String get moreCoupons => 'Купон';

  @override
  String get morePoints => 'Оноо';

  @override
  String get moreAccount => 'Бүртгэлийн мэдээлэл';

  @override
  String get moreAddresses => 'Хаяг';

  @override
  String get moreNotices => 'Мэдэгдэл';

  @override
  String get moreTips => 'Цэвэрлэгээний зөвлөмж';

  @override
  String get moreFaq => 'Түгээмэл асуулт';

  @override
  String get morePartner => 'Хамтын ажиллагаа';

  @override
  String get brandTagline => 'Гэрийн ажлыг бидэнд даатга';

  @override
  String get moreLanguage => 'Хэл';

  @override
  String get langSystem => 'Төхөөрөмжийн тохиргоог дагах';

  @override
  String moreVersion(String v) {
    return 'Хувилбар $v';
  }

  @override
  String get morePrivacy => 'Нууцлалын бодлого';

  @override
  String get moreTerms => 'Үйлчилгээний нөхцөл';

  @override
  String get moreLicenses => 'Нээлттэй эхийн лиценз';

  @override
  String get logout => 'Гарах';

  @override
  String get deleteAccount => 'Бүртгэл устгах';

  @override
  String get deleteAccountBody =>
      'Таны хувийн мэдээлэл устах бөгөөд сэргээх боломжгүй. Идэвхтэй захиалгуудаа эхлээд цуцална уу.';

  @override
  String get couponsEmpty => 'Одоогоор купон алга';

  @override
  String couponUntil(String date) {
    return '$date хүртэл';
  }

  @override
  String get couponUsed => 'Ашигласан';

  @override
  String get couponExpired => 'Хугацаа дууссан';

  @override
  String get couponAnyService => 'Бүх үйлчилгээнд';

  @override
  String get coupon_welcome_studio => 'Угтах купон: студио';

  @override
  String get coupon_welcome_any => 'Угтах купон';

  @override
  String get pointsBalance => 'Таны оноо';

  @override
  String get pointsEmpty => 'Оноо гүйлгээний түүх алга';

  @override
  String get accountName => 'Нэр';

  @override
  String get accountPhone => 'Утас';

  @override
  String get accountEmail => 'Имэйл';

  @override
  String get accountLogin => 'Нэвтрэх арга';

  @override
  String get accountLoginPhone => 'Утасны баталгаажуулалт';

  @override
  String get methodsEmpty => 'Бүртгэлтэй төлбөрийн хэрэгсэл алга';

  @override
  String get noContent => 'Одоогоор агуулга алга';

  @override
  String get quoteTypeTitle => 'Ямар цэвэрлэгээ хэрэгтэй вэ?';

  @override
  String get type_standard => 'Стандарт нүүхийн цэвэрлэгээ';

  @override
  String get type_same_day_move => 'Нүүх өдрийн цэвэрлэгээ';

  @override
  String get type_some_luggage_left => 'Зарим эд зүйл үлдсэн';

  @override
  String get type_normal_move_in => 'Энгийн нүүж орох';

  @override
  String get type_after_interior => 'Засвар хийсний дараа';

  @override
  String get type_lived_in_deep_clean => 'Амьдарч байхад бүрэн цэвэрлэгээ';

  @override
  String get luggageTitle => 'Орон сууцанд эд зүйл хэр байна вэ?';

  @override
  String get luggage_empty => 'Эд зүйлгүй';

  @override
  String get luggage_partly_unpacked => 'Хэсэгчлэн байрлуулсан';

  @override
  String get luggage_fully_lived_in => 'Бүрэн амьдарч байгаа';

  @override
  String get luggage_unknown => 'Мэдэхгүй байна';

  @override
  String get quoteBasicTitle => 'Орон сууцныхаа талаар хэлнэ үү';

  @override
  String get buildingType => 'Барилгын төрөл';

  @override
  String get building_apartment => 'Орон сууц';

  @override
  String get building_villa => 'Бага өндрийн барилга';

  @override
  String get building_officetel => 'Офистел';

  @override
  String get building_house => 'Хувийн байшин';

  @override
  String get building_other => 'Бусад';

  @override
  String get layoutTitle => 'Өрөөний тоо';

  @override
  String get layout_studio => 'Студио';

  @override
  String get layout_one_and_half => '1.5 өрөө';

  @override
  String get layout_two_rooms => '2 өрөө';

  @override
  String get layout_three_rooms => '3 өрөө';

  @override
  String get layout_four_plus => '4+ өрөө';

  @override
  String get duplexTitle => 'Дуплекс мөн үү?';

  @override
  String get quoteSpaceTitle => 'Талбайн талаар нэмэлт мэдээлэл';

  @override
  String get bathroomsLabel => 'Угаалгын өрөө';

  @override
  String get balconiesLabel => 'Тагт · угаалгын өрөө';

  @override
  String get elevatorTitle => 'Лифт байгаа юу?';

  @override
  String get floor3Label => '3-р давхар ба дээш';

  @override
  String get quoteEstimateTitle => 'Таны урьдчилсан үнэ';

  @override
  String get quoteEstimateBody =>
      'Эцсийн үнийг зургийг харсны дараа чатаар тогтооно';

  @override
  String get quoteG1 => 'Эцсийн үнийг чатаар тохирно';

  @override
  String get quoteG2 =>
      'Баталгаажуулахад 10% урьдчилгаа, үлдэгдлийг цэвэрлэгээний дараа';

  @override
  String get quoteG3 => 'Баталгаажуулахаас өмнө үнэгүй цуцална';

  @override
  String get quoteConfirmTitle => 'Хүсэлтээ шалгана уу';

  @override
  String get quoteRequest => 'Зөвлөгөөний хүсэлт илгээх';

  @override
  String get quoteNoPayNow => 'Одоо төлөх зүйл алга';

  @override
  String get summaryType => 'Төрөл';

  @override
  String get summaryHome => 'Орон сууц';

  @override
  String get summaryDate => 'Очих өдөр';

  @override
  String get cpTitle => 'Цуцлалтын бодлого';

  @override
  String cpWhen(String days) {
    return 'Айлчлалаас $days ба түүнээс дээш өдрийн өмнө';
  }

  @override
  String get cpWhenSameDay => 'Айлчлах өдөр';

  @override
  String get cpFree => 'Бүрэн буцаан олголт';

  @override
  String cpFee(String percent, String fee, String refund) {
    return '$percent% шимтгэл ($fee), буцаан олголт $refund';
  }

  @override
  String get cpClosed => 'Аппаар цуцлах боломжгүй (баг шалгана)';

  @override
  String get hhTitle => 'Өрхийн мэдээлэл';

  @override
  String get hhAddPet => 'Амьтан нэмэх';

  @override
  String get hhPetCount => 'Тоо';

  @override
  String get hhFloorLabel => 'Давхар (хашаанд сөрөг)';

  @override
  String get hhElevator => 'Лифттэй';

  @override
  String get hhNotes => 'Тэмдэглэл';

  @override
  String get hhHint =>
      'Энэ хаягт хадгалагдах бөгөөд захиалга бүрт өөрчлөх боломжтой.';

  @override
  String get bkStepConsult => 'Зөвлөгөө хүссэн';

  @override
  String get bkStepConfirmed => 'Захиалга баталгаажсан';

  @override
  String get bkStepMatched => 'Баг томилогдсон';

  @override
  String get bkStepCompleted => 'Үйлчилгээ дууссан';

  @override
  String get bkViewWeek => 'Долоо хоногоор харах';

  @override
  String get bkViewMonth => 'Сараар харах';

  @override
  String get chatHoursTitle => 'Зөвлөгөөний цаг';

  @override
  String get chatReplyFast => 'Ихэвчлэн 10 минутын дотор хариулна';

  @override
  String get quoteVisit => 'Ирэх хуваарь';

  @override
  String get quoteKind => 'Төрөл';

  @override
  String quotePayAmount(String amount) {
    return 'Урьдчилгаа төлөх $amount';
  }

  @override
  String get quoteSuperseded => 'Шинэ үнийн саналаар солигдсон';

  @override
  String get quick_quote => 'Үнийн саналын талаар';

  @override
  String get cQuoteOverride => 'Тооцооноос их зөрүүтэй үнийн санал илгээх';

  @override
  String cQuoteOverrideBody(String price, String estimate, String ratio) {
    return 'Үнийн санал $price · тооцоо $estimate · $ratio×. Илгээх үү?';
  }

  @override
  String get cQuoteNeedsAdmin =>
      'Үнэ тооцооноос их зөрүүтэй: админ зөвшөөрөх шаардлагатай';

  @override
  String get quick_reschedule => 'Хуваарь өөрчлөх';

  @override
  String get dfScopeDusting => 'Тавилгын тоос арчих';

  @override
  String get dfScopeVacuum => 'Шал тоос сорж, угаах';

  @override
  String get dfScopeDishes => 'Аяга таваг, угаалтуур угаах';

  @override
  String get dfScopeBathroom => 'Цорго, угаалтуур, жорлон дотор гадна';

  @override
  String get dfScopeTrash => 'Хог ангилж гаргах';

  @override
  String get dfScopeBedding => 'Ор дэрийг цэгцлэх';

  @override
  String get dfScopeTidy => 'Эд зүйлсийг байранд нь тавих';

  @override
  String get dfScopeStove => 'Плитка, тавцан арчих';

  @override
  String get dfScopeFridge => 'Хөргөгчийн гадна арчих';

  @override
  String get dfScopeTiles => 'Угаалгын өрөөний шал, ханын хавтан';

  @override
  String get dfScopeMold => 'Хөгц, шохойжилт арилгах';

  @override
  String get dfScopeHood => 'Сорогч, плитканы тос арилгах';

  @override
  String get dfScopeCabinets => 'Суурилуулсан шүүгээний дотор';

  @override
  String get dfScopeWindows => 'Цонхны хүрээний тоос арчих';

  @override
  String get dfScopeShoes => 'Гутлын шүүгээний дотор';

  @override
  String get dfScopeEntrance => 'Үүдний шал';

  @override
  String get dfBasicService => 'Үндсэн үйлчилгээ';

  @override
  String get dfNotProvided => 'Ороогүй үйлчилгээ';

  @override
  String get dfNp1 => 'Угаалга, хувцас эвхэх';

  @override
  String get dfNp2 => 'Гар хүрэхгүй газар';

  @override
  String get dfNp3 => 'Тусгай цэвэрлэгээ';

  @override
  String get dfNp4 => 'Цэвэрлэгээнээс бусад гэрийн ажил';

  @override
  String get dfRoom => 'Өрөө';

  @override
  String get dfKitchen => 'Гал тогоо';

  @override
  String get dfBath => 'Угаалгын өрөө';

  @override
  String get dfEntrance => 'Үүд';

  @override
  String get dfEntranceTrash => 'Үүд / хог';

  @override
  String get dfScopeMove => 'Нүүлтийн цэвэрлэгээ';

  @override
  String get dfScopeBathKitchen => 'Угаалгын өрөө ба гал тогоо';

  @override
  String get dfDuration => 'Үргэлжлэх хугацаа';

  @override
  String get dfPriceVat => 'Үнэ (НӨАТ орсон)';

  @override
  String dfStudioNote(String max) {
    return '※ $max pyeong-оос том байр студи цэвэрлэгээ захиалах боломжгүй. Тохирох үйлчилгээг чатаар санал болгоно.';
  }

  @override
  String get dfBookNow => 'Захиалах';

  @override
  String get dfMustCheck => 'Заавал шалгана уу';

  @override
  String get dfAddressTitle => 'Захиалах хаягаа сонгоно уу.';

  @override
  String get dfEdit => 'Засах';

  @override
  String dfStudioToast(String service, String max, String label, String size) {
    return '$service нь $max pyeong хүртэлх байранд. $label ($size pyeong)-д чатаар туслана.';
  }

  @override
  String dfOverPyeong(String max) {
    return 'Зөвхөн $max pyeong хүртэлх байр';
  }

  @override
  String get dfDateTitle => 'Огноо, цагаа сонгоно уу.';

  @override
  String get dfManagerIntro => 'Сургалтад хамрагдсан менежер очно.';

  @override
  String get dfServiceTime => 'Үйлчилгээний хугацаа';

  @override
  String get dfChange => 'Өөрчлөх';

  @override
  String get dfVisitDay => 'Очих өдөр';

  @override
  String get dfVisitTime => 'Очих цаг';

  @override
  String get dfSelect => 'Сонгох';

  @override
  String get dfSlotClosed => 'Дүүрсэн';

  @override
  String get dfSelectDone => 'Болсон';

  @override
  String get dfDateNote => 'Зарим өдөр, цагт нэмэлт төлбөртэй.';

  @override
  String get dfAmVisit => 'Өглөөний айлчлал';

  @override
  String get dfPmVisit => 'Үдээс хойших айлчлал';

  @override
  String dfArrive(String range) {
    return '$range ирнэ';
  }

  @override
  String dfPrepHeader(String name) {
    return '$name\nүйлчилгээний өмнө бэлдээрэй!';
  }

  @override
  String get dfPrepTools => 'Бэлдэх цэвэрлэгээний хэрэгсэл';

  @override
  String get dfNoTools => 'Хэрэгсэл дутуу юу?';

  @override
  String get dfNoToolsBody => 'Багаас юу бэлдэхийг асуугаарай';

  @override
  String get dfPayTitle => 'Хямдрал, төлбөрөө сонгоно уу.';

  @override
  String get dfPoints => 'Оноо';

  @override
  String get dfPointsFirst => 'Оноогоо түрүүлж ашиглах';

  @override
  String get dfPointsOff => 'Хэрэглээгүй';

  @override
  String get dfPointsNone => 'Ашиглах оноо алга';

  @override
  String get dfPayMethod => 'Төлбөрийн хэрэгсэл';

  @override
  String dfBaseAmount(String duration) {
    return 'Үндсэн үнэ ($duration)';
  }

  @override
  String get dfCouponDiscount => 'Купоны хөнгөлөлт';

  @override
  String get dfDue => 'Төлөх дүн';

  @override
  String get dfPgNotice =>
      'Төлбөрийг төлбөрийн үйлчилгээ үзүүлэгч (PG) боловсруулна. Төлснөөр та үйлчилгээний нөхцөл болон цуцлалт, буцаан олголтын журмыг зөвшөөрнө.';

  @override
  String get dfRefundPolicy => 'Цуцлалт ба буцаан олголтын журам';

  @override
  String get dfSummaryService => 'Үйлчилгээ';

  @override
  String get dfSummaryWhen => 'Очих огноо';

  @override
  String get dfSummaryAddress => 'Хаяг';

  @override
  String get dfSummaryPaid => 'Төлсөн';

  @override
  String get luggage_not_unpacked => 'Ачаагаа задлаагүй';

  @override
  String get dfReviewsTitle => 'Хэрэглэгчдийн сэтгэгдэл.';

  @override
  String get dfBasicBody => 'Заавал шаардлагатай, үнэд нөлөөлж болно.';

  @override
  String get building_commercial => 'Худалдааны талбай';

  @override
  String get dfBldVillaHouse => 'Вилла / байшин';

  @override
  String get dfLayoutOneHalf => '1.5 өрөө (тусгаарласан / зочны + 1)';

  @override
  String get dfLayoutTwo => 'Зочны + 2 өрөө';

  @override
  String get dfLayoutThree => 'Зочны + 3 өрөө';

  @override
  String get dfLayoutFour => 'Зочны + 4-өөс дээш';

  @override
  String get dfDuplexTitle => 'Хоёр давхар';

  @override
  String get dfNone => 'Үгүй';

  @override
  String get dfHas => 'Тийм';

  @override
  String get dfPleaseSelect => 'Сонгоно уу';

  @override
  String get dfBathCount => 'Угаалгын өрөөний тоо';

  @override
  String get dfBalconyCount => 'Тагт / ахуйн өрөөний тоо';

  @override
  String dfCountN(String n) {
    return '$n';
  }

  @override
  String get dfElevatorTitle => 'Лифт';

  @override
  String get dfFloor3 => '3-р давхар ба түүнээс дээш';

  @override
  String get dfAcAddonBanner => 'Агааржуулагч цэвэрлэгээ нэмбэл хямдарна';

  @override
  String get dfAcAddonBody => 'Шинэ байрандаа цэвэр агааржуулагчтай орно уу.';

  @override
  String get dfAcAddonAdd => 'Нэмэх';

  @override
  String dfAcAddonAdded(String count) {
    return '$count агааржуулагч нэмэгдсэн';
  }

  @override
  String get dfAcAddonNote => 'Хямдарсан үнэ үнийн санал дээр харагдана';

  @override
  String dfEstAddons(String pct) {
    return 'Агааржуулагч цэвэрлэгээ нэмэх ($pct% хямдрал)';
  }

  @override
  String dfCountUnits(String count) {
    return '$count ширхэг';
  }

  @override
  String get f_ac_addon_discount_bps =>
      'Агааржуулагч нэмэлтийн хямдрал (bps, 1000 = 10%)';

  @override
  String get dfQuoteMethodTitle =>
      'Үнийн саналын аргыг шалгаад\nүргэлжлүүлнэ үү.';

  @override
  String get dfSafeBooking => 'Dahae найдвартай захиалга';

  @override
  String get dfRecommended => 'Санал болгох';

  @override
  String get dfEstimateVat => 'Урьдчилсан үнэ (НӨАТ орсон) · өөрчлөгдөж болно';

  @override
  String get dfBenefit1 => 'Сургалттай, баталгаат баг';

  @override
  String get dfBenefit2 => 'Үйлчилгээний дараа 7 хоног үнэгүй засвар';

  @override
  String get dfBenefit3 => 'Явцыг чатаар шууд хянах';

  @override
  String get dfBenefit4 => 'Байгальд ээлтэй угаалгын бодис';

  @override
  String get dfBenefit5 => 'Сэтгэгдэл бичвэл оноо';

  @override
  String dfDepositNote(String pct) {
    return '※ Одоо төлбөр авахгүй. Үнийг чатаар тохирсны дараа $pct% урьдчилгаа төлж баталгаажуулна.';
  }

  @override
  String dfReviewHeader(String date) {
    return '$date\nЗахиалгаа дуусгана уу.';
  }

  @override
  String dfVisitTimeLine(String slot) {
    return 'Очих цаг: $slot';
  }

  @override
  String get dfReviewNote =>
      '※ Хүсэлт илгээсний дараа чат нээгдэнэ. Үнэ, хуваарийг тохироод урьдчилгаа төлнө.';

  @override
  String get dfHomeInfo => 'Байрны мэдээлэл';

  @override
  String get dfName => 'Нэр';

  @override
  String get dfBasicInfo => 'Үндсэн мэдээлэл';

  @override
  String get dfCleanType => 'Цэвэрлэгээний төрөл';

  @override
  String get dfBuilding => 'Барилга';

  @override
  String get dfSpaceInfo => 'Орон зай';

  @override
  String get dfPayInfo => 'Төлбөрийн мэдээлэл';

  @override
  String get dfEstAmount => 'Урьдчилсан үнэ';

  @override
  String get dfDepositOnConfirm => 'Урьдчилгаа (баталгаажуулахад)';

  @override
  String get dfNotes => 'Анхаарах зүйл';

  @override
  String get dfNote1 =>
      'Зөвлөгөөний үеэр эсвэл 2 хоногийн өмнө үнэгүй цуцална.';

  @override
  String get dfNote2 =>
      'Эцсийн үнийг чатаар тохирч, үлдэгдлийг дараа нь төлнө.';

  @override
  String get dfNote3 =>
      'Холбогдож чадахгүй бол баг 30 минутын дараа явна. Орох аргаа урьдчилан шалгана уу.';

  @override
  String get dfNoteWarn =>
      'Менежер шууд төлбөр шаардвал тусламжийн төвд даруй мэдэгдэнэ үү.';

  @override
  String get dfSubmitRequest => 'Захиалгын хүсэлт илгээх';

  @override
  String get dfRequested => 'Зөвлөгөө хүссэн.';

  @override
  String get dfStatusNote =>
      '※ Баг эцсийн үнийг чатаар илгээнэ. Урьдчилгаа төлж баталгаажуулна.';

  @override
  String dfPayInfoBody(String pct) {
    return 'Үнэ өөрчлөгдөж болно. Урьдчилгаа нь тохирсон үнийн $pct%.';
  }

  @override
  String get dfQuoteMethod => 'Үнийн саналын төрөл';

  @override
  String get dfDeposit => 'Урьдчилгаа';

  @override
  String get dfAwaitingPay => 'Төлбөр хүлээгдэж буй';

  @override
  String get dfServiceInfo => 'Үйлчилгээний мэдээлэл';

  @override
  String get dfSpace => 'Орон зай';

  @override
  String get dfChat => 'Зөвлөгөөний чат';

  @override
  String get dfRequestDone => 'Хүсэлт илгээгдлээ';

  @override
  String get dfRequestDoneBody => 'Чат нээгдлээ.\nБаг эцсийн үнийг илгээнэ.';

  @override
  String get dfAcUpsell => 'Нүүсний дараа агааржуулагчаа цэвэрлэх үү?';

  @override
  String get dfAcUpsellCta => 'Агааржуулагч цэвэрлэгээ захиалах';

  @override
  String get dfViewChat => 'Чат нээх';

  @override
  String get dhHomeRecommended => 'Санал болгох үйлчилгээ';

  @override
  String get dhHomeNews => 'Dahae мэдээ';

  @override
  String get dhSvcMove => 'Нүүж орох / гарах цэвэрлэгээ';

  @override
  String get dhSvcMoveShort => 'Нүүлт';

  @override
  String get dhMovePickTitle => 'Танд аль цэвэрлэгээ хэрэгтэй вэ?';

  @override
  String get cKind_news => 'Мэдээ';

  @override
  String get cLink => 'Холбоос (coupons, service/move_in, https://…)';

  @override
  String get welcomePackTitle => 'Бүртгэлийн угтах купон';

  @override
  String get welcomePackBody =>
      'Хэрэглэгч бүртгэлээ дуусгахад нэг удаа олгоно. Бүгдийг устгавал олгохгүй.';

  @override
  String get welcomePackAmount => 'Купоны дүн (KRW)';

  @override
  String get welcomePackAdd => 'Купон нэмэх';

  @override
  String get welcomePackRemove => 'Купон устгах';

  @override
  String moreGreeting(String brand) {
    return 'Өнөөдөр ч гэрийн ажлаа $brand-д даатгаарай';
  }

  @override
  String moreBrandTips(String brand) {
    return '$brand зөвлөгөө';
  }

  @override
  String get moreContact => 'Холбоо барих';

  @override
  String get moreVersionInfo => 'Хувилбарын мэдээлэл';

  @override
  String get payAvailableTitle => 'Боломжтой төлбөрийн хэрэгсэл';

  @override
  String get accountLoginKakao => 'Kakao';

  @override
  String get accountLoginNaver => 'Naver';

  @override
  String get accountLoginApple => 'Apple';

  @override
  String get accountLoginGoogle => 'Google';

  @override
  String get themeTitle => 'Загвар';

  @override
  String get themeDark => 'Харанхуй';

  @override
  String get themeLight => 'Гэрэлтэй';

  @override
  String get themeSystem => 'Системийн';

  @override
  String get themeTip => 'Загвар солих';

  @override
  String get err_price_changed =>
      'Үнэ өөрчлөгдсөн байна. Шинэ үнийн саналаа шалгаад дахин оролдоно уу.';

  @override
  String get err_checkout_closed =>
      'Энэ төлбөр хаагдсан байна. Дахин эхлүүлнэ үү.';

  @override
  String get err_checkout_refunded =>
      'Энэ төлбөрийг цуцалж, буцаан олгосон байна.';

  @override
  String get err_already_paid => 'Энэ төлбөр аль хэдийн төлөгдсөн байна.';

  @override
  String get err_quote_not_payable =>
      'Энэ үнийн саналыг одоохондоо төлөх боломжгүй байна. Манай багтай холбогдоно уу.';

  @override
  String get err_payment_method_disabled =>
      'Энэ төлбөрийн хэрэгсэл одоогоор боломжгүй байна.';

  @override
  String get err_invalid_payment_method =>
      'Сонгосон төлбөрийн хэрэгсэл ашиглах боломжгүй байна. Өөрийг сонгоно уу.';

  @override
  String get err_balance_not_due =>
      'Үлдэгдэл төлбөр одоогоор төлөх хугацаа болоогүй байна.';

  @override
  String get err_invalid_slot =>
      'Энэ үйлчилгээнд сонгосон цаг боломжгүй байна.';

  @override
  String get err_booking_changed =>
      'Захиалга өөрчлөгдсөн байна. Шинэчилж дэлгэрэнгүйг шалгана уу.';

  @override
  String get err_booking_closed => 'Энэ захиалгыг цаашид өөрчлөх боломжгүй.';

  @override
  String get err_reschedule_closed =>
      'Одоо очих өдрийг өөрчлөх боломжгүй. Манай багтай холбогдоно уу.';

  @override
  String get err_too_many_open_requests =>
      'Нээлттэй хүсэлт хэт олон байна. Эхлээд нэгийг дуусгана уу.';

  @override
  String get err_already_reviewed =>
      'Та энэ үйлчилгээнд аль хэдийн сэтгэгдэл үлдээсэн байна.';

  @override
  String get err_identity_not_verified =>
      'Эхлээд иргэний үнэмлэхийн баталгаажуулалтаа дуусгана уу.';

  @override
  String get err_email_taken => 'Энэ имэйл аль хэдийн ашиглагдсан байна.';

  @override
  String get err_invalid_email => 'Имэйл хаягаа шалгана уу.';

  @override
  String get err_file_too_large =>
      'Файл хэт том байна. Илүү жижиг файл оруулна уу.';

  @override
  String get err_unsupported_image =>
      'Энэ зургийн формат дэмжигдэхгүй. JPG эсвэл PNG оруулна уу.';

  @override
  String get err_upload_quota =>
      'Өнөөдрийн байршуулалтын хязгаарт хүрсэн байна. Маргааш дахин оролдоно уу.';

  @override
  String get err_provider_unreachable =>
      'Үйлчилгээтэй холбогдож чадсангүй. Удахгүй дахин оролдоно уу.';

  @override
  String get err_invalid_token =>
      'Нэвтрэлт амжилтгүй боллоо. Дахин оролдоно уу.';

  @override
  String get err_invalid_transition =>
      'Төлөвийг одоо ийм байдлаар өөрчлөх боломжгүй.';

  @override
  String get err_job_not_started => 'Эхлээд ажлаа эхлүүлнэ үү.';

  @override
  String get err_job_not_active => 'Энэ ажил идэвхгүй байна.';

  @override
  String get err_quote_locked => 'Үнийн санал түгжигдсэн тул засах боломжгүй.';

  @override
  String get err_request_closed => 'Энэ хүсэлт хаагдсан байна.';

  @override
  String get err_team_full => 'Баг дүүрсэн байна.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret нь whsec_-ээр эхлэх ёстой.';

  @override
  String get err_invalid_endpoint => 'Endpoint нь https://-ээр эхлэх ёстой.';

  @override
  String get err_invalid_bucket => 'Bucket-ийн нэр буруу байна.';

  @override
  String get err_invalid_region => 'Бүс буруу байна.';

  @override
  String get err_invalid_retention =>
      'Хадгалах хугацаа хязгаараас гадуур байна.';

  @override
  String get err_invalid_service_account => 'Service account файл буруу байна.';

  @override
  String get err_invalid_mode => 'Зөв AI горим сонгоно уу.';

  @override
  String get err_invalid_model => 'AI загварын нэр буруу байна.';

  @override
  String get err_missing_field => 'Шаардлагатай бүх талбарыг бөглөнө үү.';

  @override
  String get err_invalid_amount => 'Зөв дүн оруулна уу.';

  @override
  String get err_cannot_deactivate_self =>
      'Өөрийн бүртгэлээ идэвхгүй болгох боломжгүй.';

  @override
  String get err_invalid_coupon => 'Энэ купон буруу байна.';

  @override
  String get err_settlement_state => 'Тооцоог одоо өөрчлөх боломжгүй.';

  @override
  String get err_deposit_required =>
      'Эхлээд урьдчилгаа төлбөр төлөх шаардлагатай.';

  @override
  String get err_payout_state =>
      'Төлбөрийн төлөв өөрчлөгдсөн байна. Шинэчилж дахин шалгана уу.';

  @override
  String get err_payout_provider =>
      'Энэ төлбөрийн арга одоогоор боломжгүй байна.';

  @override
  String get err_unsupported_bank => 'Энэ банкад төлбөр шилжүүлэх боломжгүй.';

  @override
  String get err_toss_unverified =>
      'Toss төлбөр одоогоор боломжгүй. Гараар шилжүүлэг ашиглана уу.';

  @override
  String get err_invalid_cap => 'Зөвшөөрөгдсөн хязгаарт багтах тоо оруулна уу.';

  @override
  String get err_invalid_capacity => 'Зөв багтаамж оруулна уу.';

  @override
  String get err_seller_declined =>
      'Toss худалдагчийн бүртгэлийг зөвшөөрөөгүй. Бизнесийн мэдээллээ шалгана уу.';

  @override
  String get err_payout_account_unverified =>
      'Энэ хамтрагч баталгаажсан төлбөрийн дансгүй байна. Эхлээд дансаа баталгаажуулна уу.';

  @override
  String get guestSheetTitle => 'Үргэлжлүүлэхийн тулд нэвтэрнэ үү';

  @override
  String get guestSheetBody =>
      'Таны оруулсан мэдээлэл хадгалагдана. Яг сүүлд зогссон газраасаа үргэлжилнэ.';

  @override
  String get greetMorning => 'Өглөөний мэнд';

  @override
  String get greetAfternoon => 'Өдрийн мэнд';

  @override
  String get greetEvening => 'Оройн мэнд';

  @override
  String get feedHeading => 'Танд зориулсан';

  @override
  String get feedTitleDue => 'Дараагийн цэвэрлэгээний цаг боллоо';

  @override
  String get feedTitleRebook => '5 одтой мэргэжилтнээ дахин захиалаарай';

  @override
  String get feedTitleDraft => 'Эхэлсэн үнийн саналаа үргэлжлүүлэх';

  @override
  String get feedTitleSeasonal => 'Энэ улиралд тохирох цэвэрлэгээ';

  @override
  String get feedTitleSize => 'Хадгалсан байрны хэмжээгээр үнэ';

  @override
  String get feedTitleSubscription => 'Захиалгаар илүү хэмнэ';

  @override
  String get feedTitleDistrict => 'Хөршүүд ч захиалж байна';

  @override
  String feedWhyCadence(String days) {
    return 'Сүүлийн цэвэрлэгээнээс хойш $days хоног өнгөрлөө';
  }

  @override
  String feedWhyRated(String days) {
    return 'Та энэ мэргэжилтнийг $days хоногийн өмнө 5 одоор үнэлсэн';
  }

  @override
  String get feedWhyDraft =>
      'Та энэ төхөөрөмжид үнийн саналаа дуусгаагүй байна';

  @override
  String get feedWhySummer =>
      'Зуны өмнө агаар сэрүүлэгчээ цэвэрлүүлэх сайн цаг';

  @override
  String get feedWhyMoving => 'Нүүлт, орох улирал эрчимтэй байна';

  @override
  String feedWhyHoliday(String days) {
    return 'Баярын өмнөх том цэвэрлэгээ хүртэл $days хоног';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'Хадгалсан $pyeong пёнг байрнаас шууд үнэ';
  }

  @override
  String get feedWhyRepeat => 'Тогтмол захиалдаг бол захиалга илүү хямд';

  @override
  String feedWhyDistrict(String district, String count) {
    return 'Энэ долоо хоногт $district-д $count байр захиалсан';
  }

  @override
  String get fFinance => 'Санхүү';

  @override
  String get fPeriodDay => 'Өдөр';

  @override
  String get fPeriodWeek => 'Долоо хоног';

  @override
  String get fPeriodMonth => 'Сар';

  @override
  String get fPeriodCustom => 'Хугацаа';

  @override
  String get fFrom => 'Эхлэх';

  @override
  String get fTo => 'Дуусах';

  @override
  String get fGross => 'Нийт төлбөр';

  @override
  String get fRefunds => 'Буцаалт';

  @override
  String get fNetRevenue => 'Цэвэр орлого';

  @override
  String get fPlatformFee => 'Платформын шимтгэл';

  @override
  String get fPaidOut => 'Хамтрагчдад шилжсэн';

  @override
  String get fPendingOut => 'Шилжүүлэх хүлээгдэж буй';

  @override
  String get fHeldOut => 'Түр зогсоосон';

  @override
  String get fVatEstimate => 'НӨАТ (тооцоолол)';

  @override
  String get fVatNote =>
      'Платформын шимтгэлийн 10%-иар тооцсон таамаглал. Нягтлагчтайгаа баталгаажуулна уу.';

  @override
  String get fAov => 'Захиалгын дундаж дүн';

  @override
  String get fBookings => 'Захиалга';

  @override
  String get fCancelRate => 'Цуцлалтын хувь';

  @override
  String get fDiscounts => 'Хөнгөлөлт, купон';

  @override
  String get fMethods => 'Төлбөрийн хэлбэр';

  @override
  String get fTrend => 'Чиг хандлага';

  @override
  String fRangeDays(String n) {
    return 'Сүүлийн $n өдөр';
  }

  @override
  String get fRangeWeeks => 'Сүүлийн 12 долоо хоног';

  @override
  String get fRangeMonths => 'Сүүлийн 12 сар';

  @override
  String get fByPartner => 'Хамтрагчаар орлого';

  @override
  String get fByService => 'Үйлчилгээгээр орлого';

  @override
  String get fExportTitle => 'Нягтлангийн экспорт';

  @override
  String get fExportLedger => 'Төлбөрийн бүртгэл CSV';

  @override
  String get fExportSettlements => 'Тооцооны CSV';

  @override
  String get fExportMonthly => 'Сарын тойм CSV (нягтлан)';

  @override
  String get fDownload => 'CSV татах';

  @override
  String get fDownloadWebOnly => 'CSV-ийг вэб консолоос татна уу';

  @override
  String get fDownloadFailed => 'Татаж чадсангүй';

  @override
  String get fNoRecords => 'Энэ хугацаанд бүртгэл алга';

  @override
  String get fLoadFailed => 'Санхүүгийн мэдээлэл ачаалагдсангүй';

  @override
  String get fRetry => 'Дахин оролдох';

  @override
  String get fColPartner => 'Хамтрагч';

  @override
  String get fColJobs => 'Тоо';

  @override
  String get fColSettled => 'Нийт тооцоо';

  @override
  String get fColFee => 'Шимтгэл';

  @override
  String get fColNet => 'Цэвэр';

  @override
  String get pEarnings => 'Орлого';

  @override
  String get pNextPayout => 'Дараагийн шилжүүлэг';

  @override
  String pNextPayoutOn(String date) {
    return '$date-нд шилжүүлнэ';
  }

  @override
  String get pNoPayout => 'Товлосон шилжүүлэг алга';

  @override
  String get pPendingTotal => 'Шилжүүлэх хүлээгдэж буй';

  @override
  String get pPaidTotal => 'Шилжүүлсэн';

  @override
  String get pWeekly => 'Долоо хоногоор';

  @override
  String get pMonthly => 'Сараар';

  @override
  String proofHomes(String count) {
    return 'Энэ сард $count гэр цэвэрлэсэн';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Дундаж $rating од · $count сэтгэгдэл';
  }

  @override
  String get proofReviewsTitle => 'Сүүлийн сэтгэгдэл';

  @override
  String get rebookTitle => 'Сүүлийн үйлчилгээгээ дахин захиалах уу?';

  @override
  String rebookBody(String service, String date) {
    return '$service · сүүлд $date';
  }

  @override
  String get rebookButton => 'Дахин захиалах';

  @override
  String seatsLeft(String count) {
    return '$count суудал үлдсэн';
  }

  @override
  String get reviewSheetTitle => 'Энэ цэвэрлэгээ ямар байсан бэ?';

  @override
  String get reviewPhotosAdd => 'Зураг нэмэх';

  @override
  String get reviewPhotosHint => 'Дээд тал нь 5 зураг';

  @override
  String get reviewSaved => 'Сэтгэгдэл өгсөнд баярлалаа';

  @override
  String get reviewPhotoFailed =>
      'Зургийг илгээж чадсангүй. Дахин оролдоно уу.';

  @override
  String get referralTitle => 'Найзаа урьж купон аваарай';

  @override
  String referralBody(String amount) {
    return 'Найз тань анхны захиалгаа дуусгахад та хоёулаа $amount купон авна';
  }

  @override
  String get referralCopy => 'Кодыг хуулах';

  @override
  String get referralCopied => 'Урилгын код хуулагдлаа';

  @override
  String get referralClaimTitle => 'Урилгын кодтой юу?';

  @override
  String get referralClaimField => 'Урилгын код оруулах';

  @override
  String get referralClaimButton => 'Бүртгэх';

  @override
  String get referralClaimed => 'Урилгын код бүртгэгдлээ';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited урьсан · $rewarded шагнал';
  }

  @override
  String get err_self_referral => 'Өөрийн кодыг ашиглах боломжгүй';

  @override
  String get err_referee_already_booked =>
      'Кодыг зөвхөн анхны захиалгын өмнө оруулна';

  @override
  String get err_already_referred => 'Урилгын код аль хэдийн бүртгэгдсэн';

  @override
  String get err_invalid_referral_code => 'Урилгын кодоо шалгана уу';

  @override
  String get err_referral_disabled => 'Одоогоор урилга түр зогссон';

  @override
  String get err_invalid_photos =>
      'Зөвхөн Dahae апп-аар байршуулсан зургийг хавсаргана';

  @override
  String get welcomeOfferTitle => 'Анхны захиалгын хөнгөлөлт';

  @override
  String get welcomeOfferBody =>
      'Шинэ үйлчлүүлэгчийн анхны захиалгад автоматаар хэрэглэгдэнэ. Купонтой хамт болохгүй.';

  @override
  String get offerKindAmount => 'Тогтмол (вон)';

  @override
  String get offerKindPercent => 'Хувиар (%)';

  @override
  String get offerValue => 'Хөнгөлөлтийн утга';

  @override
  String get offerEnabled => 'Асаах';

  @override
  String get offerSaved => 'Хадгалагдлаа';

  @override
  String get referralSettingsTitle => 'Найз урьсны шагнал';

  @override
  String get referralSettingsBody =>
      'Найзын анхны захиалга дуусаж, төлбөр хийгдсэний дараа олгоно. Өөрийгөө урих, ижил дугаарыг хориглоно.';

  @override
  String get referralRewardAmount => 'Шагналын дүн (вон)';

  @override
  String get reviewsModerationTitle => 'Сэтгэгдлийн удирдлага';

  @override
  String get reviewHide => 'Нуух';

  @override
  String get reviewShow => 'Дахин харуулах';

  @override
  String get reviewHiddenTag => 'Нуусан';

  @override
  String get growthAverageRating => 'Дундаж үнэлгээ';

  @override
  String growthReviewCount(String count) {
    return '$count сэтгэгдэл';
  }

  @override
  String get growthReferralConversion => 'Урилгын хувиргалт';

  @override
  String get growthTab => 'Өсөлт';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$invited-с $rewarded';
  }

  @override
  String get locUseCurrent => 'Одоогийн байршлаа ашиглах';

  @override
  String get locConsentTitle => 'Байршилд суурилсан үйлчилгээний нөхцөл';

  @override
  String get locConsentBody =>
      'Одоогийн байршлаасаа хаягаа олохын тулд байршилд суурилсан үйлчилгээний нөхцөлийг зөвшөөрнө үү. Бид таны байршлыг зөвхөн \"Одоогийн байршлаа ашиглах\" товчийг дарах үед нэг удаа шалгаж, зөвхөн хаяг санал болгоход ашиглана. Координатыг манай серверт хадгалахгүй. Та зөвшөөрлөө Зөвшөөрлийн тохиргооноос хүссэн үедээ цуцалж болно.';

  @override
  String get locConsentAgree => 'Зөвшөөрөөд үргэлжлүүлэх';

  @override
  String get locSuggestionTitle => 'Энэ таны хаяг мөн үү?';

  @override
  String get locUseAddress => 'Энэ хаягийг ашиглах';

  @override
  String get locDenied => 'Байршлын зөвшөөрөл алга. Хаягаа гараар оруулна уу.';

  @override
  String get locServicesOff =>
      'Төхөөрөмжийн байршлын үйлчилгээ унтраалттай байна. Хаягаа гараар оруулна уу.';

  @override
  String get locTimeout =>
      'Байршил тогтооход хэт удаж байна. Хаягаа гараар оруулна уу.';

  @override
  String get locNoAddress =>
      'Таны байршлын хаяг олдсонгүй. Хаягаа гараар оруулна уу.';

  @override
  String get uMaintenanceTitle => 'Засвар хийгдэж байна';

  @override
  String get uMaintenanceBody =>
      'Бид үйлчилгээгээ сайжруулахаар засвар хийж байна. Удахгүй дахин оролдоно уу.';

  @override
  String get cmTab => 'Кампанит ажил';

  @override
  String get cmNew => 'Шинэ кампанит ажил';

  @override
  String get cmAudience => 'Хүлээн авагчид';

  @override
  String get cmSegAll => 'Бүх харилцагч';

  @override
  String get cmSegNever => 'Захиалга хийгээгүй';

  @override
  String cmSegLapsed(String days) {
    return 'Сүүлд захиалснаас $days+ хоног өнгөрсөн';
  }

  @override
  String get cmDays => 'Хоногийн тоо';

  @override
  String cmConsentCount(String total, String consented) {
    return '$total-с $consented нь маркетингийн зөвшөөрөлтэй';
  }

  @override
  String get cmChannel => 'Суваг';

  @override
  String get cmPush => 'Апп мэдэгдэл';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'Гарчиг';

  @override
  String get cmBody => 'Агуулга';

  @override
  String get cmOptout => 'Татгалзах дугаар (080)';

  @override
  String get cmPreview => 'Урьдчилан харах';

  @override
  String get cmSchedule => 'Илгээх цаг';

  @override
  String get cmSendNow => 'Одоо илгээх';

  @override
  String get cmTestSend => 'Өөрийн дугаарт туршилт илгээх';

  @override
  String get cmCreate => 'Кампанит ажил хадгалах';

  @override
  String get cmNeedOptout => 'SMS-д 080 татгалзах дугаар шаардлагатай';

  @override
  String get cmLog => 'Илгээлтийн бүртгэл';

  @override
  String cmStatSent(String count) {
    return 'Илгээсэн $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'Зөвшөөрөлгүй $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'Амжилтгүй $count';
  }

  @override
  String get cmSaved => 'Кампанит ажил хадгалагдлаа';

  @override
  String anFunnel(String days) {
    return 'Бүртгэлийн воронк (сүүлийн $days хоног)';
  }

  @override
  String get anInstalls => 'Апп нээсэн (зөвшөөрсөн)';

  @override
  String get anSignedUp => 'Бүртгүүлсэн';

  @override
  String get anQuoted => 'Үнийн санал авсан';

  @override
  String get anBooked => 'Захиалсан';

  @override
  String get anPaid => 'Төлсөн';

  @override
  String get anRepeat => 'Давтан (2+)';

  @override
  String get anCohorts =>
      'Долоо хоногийн бүлэг (бүртгүүлсэн долоо хоногоор захиалгын хувь)';

  @override
  String anCohortSize(String count) {
    return 'Бүртгэл $count';
  }

  @override
  String anWeekAfter(String n) {
    return '$n дахь долоо хоногт захиалсан';
  }

  @override
  String get cOps => 'Системийн төлөв';

  @override
  String get oLevelGreen => 'Хэвийн';

  @override
  String get oLevelYellow => 'Шалгах';

  @override
  String get oLevelRed => 'Шаардлагатай';

  @override
  String get oOverall => 'Серверийн төлөв';

  @override
  String get oRefresh => 'Шинэчлэх';

  @override
  String get oVersion => 'Хувилбар';

  @override
  String get oUptime => 'Ажилласан хугацаа';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours цаг $minutes минут';
  }

  @override
  String get oChecks => 'Шалгалтууд';

  @override
  String get oCheckDb => 'Өгөгдлийн сан';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Хариу $ms ms · хэмжээ $mb MB';
  }

  @override
  String get oCheckDisk => 'Серверийн диск';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% чөлөөтэй';
  }

  @override
  String get oCheckBackup => 'Автомат нөөцлөлт';

  @override
  String oCheckBackupValue(String hours) {
    return 'Сүүлийн нөөцлөлт $hours цагийн өмнө';
  }

  @override
  String get oCheckBackupNone => 'Нөөцлөлт хараахан байхгүй';

  @override
  String get oCheckErrors => 'Серверийн алдаа (24 цаг)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Шалгах төлбөр';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 цаг)';
  }

  @override
  String get oCheckWebhook => 'Төлбөрийн мэдэгдэл (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Гарын үсэг буруу $count (24 цаг)';
  }

  @override
  String get oIntegrations => 'Гадаад үйлчилгээ';

  @override
  String get oIntNotSet => 'Тохируулаагүй';

  @override
  String oIntLastOk(String at) {
    return 'Сүүлд амжилттай $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Сүүлд алдаатай $at ($code)';
  }

  @override
  String get oIntNever => 'Ашиглалт хараахан байхгүй';

  @override
  String get oActDb =>
      'Өгөгдлийн сантай холбогдож чадсангүй. Серверт malkkeum logs ажиллуулж, үргэлжлэвэл дахин эхлүүлнэ үү.';

  @override
  String get oActDisk =>
      'Диск чөлөөт орон 10%-иас доош байна. Хуучин нөөцийг устгах эсвэл дискээ нэмнэ үү.';

  @override
  String get oActBackup =>
      'Автомат нөөцлөлт хоцорсон. Серверт malkkeum backup ажиллуулж, backups/backup.log-ийг шалгана уу.';

  @override
  String get oActErrors =>
      'Серверийн алдаа олон байна. malkkeum logs-ийн error мөрүүдийг шалгаж, давтагдвал хөгжүүлэгчид илгээнэ үү.';

  @override
  String get oActPayments =>
      'Төлбөр хийгдсэн ч автоматаар боловсрогдоогүй байж магадгүй. PortOne дээр шалгаад шаардлагатай бол буцаан олгоно уу.';

  @override
  String get oActWebhook =>
      'Төлбөрийн мэдэгдлийн гарын үсгийн шалгалт амжилтгүй. Тохиргоо > Төлбөр (PortOne) дээр webhook secret-ээ дахин оруулна уу.';

  @override
  String get oActIntegration =>
      'Энэ холболт амжилтгүй байна. Тохиргоон дахь түлхүүрүүдээ шалгаад Test connection дарна уу.';

  @override
  String get oActNotSet =>
      'Хараахан тохируулаагүй. Тохиргоонд түлхүүр оруулна уу.';

  @override
  String get oAlerts => 'Сэрэмжлүүлгийн тохиргоо';

  @override
  String get oAlertsHint =>
      'Асуудал гарвал хүлээн авах хайрцагт болон эзэмшигчийн утсанд SMS-ээр мэдэгдэнэ. Нэг асуудлыг 6 цаг тутамд нэг удаа илгээнэ.';

  @override
  String get oRuleSms => 'SMS илгээх алдаатай';

  @override
  String get oRulePush => 'Push мэдэгдэл алдаатай';

  @override
  String get oRulePayment => 'Төлбөрийн холболт алдаатай';

  @override
  String get oRuleStuck => 'Төлбөр автоматаар боловсрогдохгүй';

  @override
  String get oRuleSocial => 'Нийгмийн сүлжээгээр нэвтрэлт алдаатай';

  @override
  String get oRuleBackup => 'Автомат нөөцлөлт алгассан';

  @override
  String get oRuleDisk => 'Диск дүүрэх дөхсөн';

  @override
  String get oRuleAuth => 'Сэжигтэй нэвтрэлт';

  @override
  String get oQuietHours => 'Тайван цаг';

  @override
  String get oQuietFrom => 'Эхлэх';

  @override
  String get oQuietTo => 'Дуусах';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'Эдгээр цагт мэдэгдэхгүй; дууссаны дараа нэг мэдэгдэл очно.';

  @override
  String get oAlertPhone => 'Мэдэгдэл авах утас';

  @override
  String get oAlertPhoneHint =>
      'Хоосон орхивол бизнесийн мэдээлэл дэх дэмжлэгийн дугаар руу илгээнэ.';

  @override
  String get oSave => 'Хадгалах';

  @override
  String get oSaved => 'Сэрэмжлүүлгийн тохиргоог хадгаллаа';

  @override
  String get oSaveFailed => 'Хадгалж чадсангүй. Оруулсан утгаа шалгана уу.';

  @override
  String get oLoadFailed => 'Төлөвийг ачаалж чадсангүй';

  @override
  String get oBackupOffsite => 'Гадаад нөөцлөлт (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Унтарсан. Тохиргоо > Гадаад нөөцлөлт дээр асаана уу.';

  @override
  String get oLastBackup => 'Сүүлийн нөөцлөлт';

  @override
  String get oDiskFree => 'Чөлөөт орон';

  @override
  String get oNoData => 'Өгөгдөл хараахан байхгүй';

  @override
  String get cIntBackup => 'Гадаад нөөцлөлт (S3-тай нийцтэй)';

  @override
  String get pTabJobs => 'Ажил';

  @override
  String get pTabQuotes => 'Миний үнийн санал';

  @override
  String get pTabSchedule => 'Хуваарь';

  @override
  String get pIntroTitle =>
      'Ажил, хуваарь, төлбөр\nцэвэрлэгээний мэргэжилтнүүдэд';

  @override
  String get pIntroBody =>
      'Хүссэн бүс, цагтаа л ажиллана. Долоо хоног бүр цалинжина.';

  @override
  String get pOnbTitle => 'Таны талаар хэлнэ үү';

  @override
  String get pOnbName => 'Таны нэр';

  @override
  String get pOnbTeam => 'Багийн нэр';

  @override
  String get pOnbServices => 'Санал болгох үйлчилгээ';

  @override
  String get pOnbAreas => 'Ажиллах бүс';

  @override
  String get pOnbDone => 'Бүртгүүлэх';

  @override
  String get pPendingTitle => 'Таны бүртгэл шалгагдаж байна';

  @override
  String get pPendingBody =>
      'Баталгаажмагц мэдэгдэл илгээнэ. Тэр хүртэл төлбөр хүлээн авах дансаа бүртгэнэ үү.';

  @override
  String get pSuspended =>
      'Таны бүртгэл түр зогссон байна. Үйл ажиллагааны багт холбогдоно уу.';

  @override
  String get pDirect => 'Шууд захиалга';

  @override
  String get pQuoteReq => 'Үнийн саналын хүсэлт';

  @override
  String get pShowClosed => 'Хаагдсан ажлыг харуулах';

  @override
  String get pSortNewest => 'Шинэ нь эхэнд';

  @override
  String get pSortVisit => 'Ойрын очих өдөр';

  @override
  String get pSortAmount => 'Дүн ихээс';

  @override
  String get pNoJobs => 'Одоогоор тохирох ажил алга';

  @override
  String get pNoJobsBody =>
      'Үйлчилгээ, бүс, ажлын цагаа өргөтгөвөл илүү ажил харагдана';

  @override
  String get pPayout => 'Таны орлого';

  @override
  String get pCustomerEstimate => 'Үйлчлүүлэгчийн урьдчилсан үнэ';

  @override
  String get pNew => 'ШИНЭ';

  @override
  String get pClosed => 'Хаагдсан';

  @override
  String get pPrivacyNote =>
      'Яг хаяг, үйлчлүүлэгчийн мэдээлэл хүлээн авсны дараа харагдана';

  @override
  String get pAccept => 'Ажил авах';

  @override
  String get pAcceptConfirm => 'Энэ ажлыг авах уу?';

  @override
  String get pAcceptBody =>
      'Ажил таны хуваарьт нэмэгдэж, үйлчлүүлэгчид баг оноогдсон тухай мэдэгдэл очно. Очихоос 2 хоногийн дотор цуцлахад хязгаарлалт бий.';

  @override
  String get pAccepted => 'Ажил авлаа';

  @override
  String get pSendQuote => 'Үнийн санал илгээх';

  @override
  String get pQuotePrice => 'Үйлчлүүлэгчийн төлөх дүн';

  @override
  String get pQuoteNote => 'Зөвлөх багт үлдээх тэмдэглэл';

  @override
  String get pQuoteSent => 'Үнийн санал илгээгдлээ';

  @override
  String pFee(String rate) {
    return 'Шимтгэл $rate%';
  }

  @override
  String get pYouGet => 'Таны авах дүн';

  @override
  String get pQuoteAll => 'Бүгд';

  @override
  String get pQ_waiting => 'Хүлээгдэж байна';

  @override
  String get pQ_selected => 'Сонгогдсон';

  @override
  String get pQ_rejected => 'Сонгогдоогүй';

  @override
  String get pQ_closed => 'Хаагдсан';

  @override
  String get pUnseenOnly => 'Зөвхөн шинэ үр дүн';

  @override
  String get pNoQuotes => 'Илгээсэн үнийн санал алга';

  @override
  String get pMyQuote => 'Миний үнийн санал';

  @override
  String get pWithdraw => 'Үнийн саналаа буцаах';

  @override
  String get pWithdrawn => 'Үнийн санал буцаагдлаа';

  @override
  String get pOnlyMine => 'Зөвхөн миний';

  @override
  String pJobsCount(String n) {
    return '$n ажил';
  }

  @override
  String get pNoSchedule => 'Энэ өдөр хуваарь алга';

  @override
  String get pCancelledBanner =>
      'Үйлчлүүлэгч энэ ажлыг цуцалсан. Дууссан гэж тэмдэглэх боломжгүй.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Цаг солих хүсэлт: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Очиж чадна';

  @override
  String get pRescheduleNo => 'Очиж чадахгүй';

  @override
  String get pCustomer => 'Үйлчлүүлэгч';

  @override
  String get pCall => 'Нууц дугаараар залгах';

  @override
  String get pCallSoon =>
      'Нууц дугаараар залгах үйлчилгээ нээлтийн үед идэвхжинэ';

  @override
  String get pQuietHours => '20 цагаас хойш залгахгүй байхыг хүсье';

  @override
  String get pAssignee => 'Хариуцагч';

  @override
  String get pChangeAssignee => 'Хариуцагч солих';

  @override
  String get pCustomerRequests => 'Үйлчлүүлэгчийн хүсэлт';

  @override
  String get pHousehold => 'Өрхийн мэдээлэл';

  @override
  String get pPets => 'Гэр оронд амьтан';

  @override
  String get pPetDog => 'Нохой';

  @override
  String get pPetCat => 'Муур';

  @override
  String get pPetBird => 'Шувуу';

  @override
  String get pPetFish => 'Загас';

  @override
  String get pPetOther => 'Бусад амьтан';

  @override
  String get pAllergies => 'Харшил ба мэдрэмж';

  @override
  String get pPreferredProducts => 'Дуртай бүтээгдэхүүн';

  @override
  String get pParking => 'Зогсоол';

  @override
  String pFloor(String floor) {
    return '$floor давхар';
  }

  @override
  String get pElevatorYes => 'Лифттэй';

  @override
  String get pElevatorNo => 'Лифтгүй';

  @override
  String get pTeamMemo => 'Багийн тэмдэглэл (үйлчлүүлэгчид харагдахгүй)';

  @override
  String get pMemoSaved => 'Тэмдэглэл хадгалагдлаа';

  @override
  String get pPayoutBreakdown => 'Төлбөрийн задаргаа';

  @override
  String get pAfterBalance => 'Үйлчлүүлэгч үлдэгдлээ төлсний дараа цалинжина';

  @override
  String get pChatOps => 'Үйл ажиллагааны багтай чатлах';

  @override
  String get pComplete => 'Ажлыг дуусгах';

  @override
  String get pBeforePhotos => 'Цэвэрлэгээний өмнөх зураг';

  @override
  String get pAfterPhotos => 'Цэвэрлэгээний дараах зураг';

  @override
  String get pAddPhoto => 'Зураг нэмэх';

  @override
  String get pChecklist => 'Шалгах жагсаалт';

  @override
  String get pCheck1 => 'Хүссэн бүх талбайг цэвэрлэсэн';

  @override
  String get pCheck2 => 'Хогийг зайлуулж, багажаа цуглуулсан';

  @override
  String get pCheck3 => 'Цонх, цахилгаан, усыг шалгасан';

  @override
  String get pCheck4 => 'Үйлчлүүлэгчийн хүсэлтийг биелүүлсэн';

  @override
  String get pCompleteCta => 'Дууссан гэж тэмдэглэх';

  @override
  String get pCompleteNeed =>
      'Төрөл бүрт дор хаяж 1 зураг оруулж, бүх зүйлийг тэмдэглээрэй';

  @override
  String get pCompleted => 'Сайн ажиллалаа!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$date-нд $amount цалинжина';
  }

  @override
  String get pPayoutWaiting =>
      'Цалингийн өдрийг үйлчлүүлэгч төлсний дараа тогтооно';

  @override
  String get pPendingPayout => 'Хүлээгдэж буй цалин';

  @override
  String get pSettlements => 'Тооцооны түүх';

  @override
  String get pS_waiting_balance => 'Үлдэгдэл хүлээж байна';

  @override
  String get pS_pending => 'Төлөх хуваарьтай';

  @override
  String get pS_paid => 'Төлөгдсөн';

  @override
  String get pS_held => 'Түр зогсоосон';

  @override
  String get pReviews => 'Үйлчлүүлэгчийн сэтгэгдэл';

  @override
  String get pNoReviews => 'Одоогоор сэтгэгдэл алга';

  @override
  String get pReplyLater => 'Хариу бичих боломж удахгүй нээгдэнэ';

  @override
  String get pServicesAreas => 'Үйлчилгээ · бүс';

  @override
  String get pPayoutAccount => 'Цалин хүлээн авах данс';

  @override
  String get pBank => 'Банк';

  @override
  String get pAccountNumber => 'Дансны дугаар';

  @override
  String get pHolder => 'Данс эзэмшигч';

  @override
  String get pVerified => 'Баталгаажсан';

  @override
  String get pUnverified => 'Шалгагдаж байна';

  @override
  String get pAccountSaved => 'Данс хадгалагдлаа. Өөрчлөгдвөл дахин шалгана.';

  @override
  String get pWorkSchedule => 'Ажлын хуваарь';

  @override
  String get pWeekdays => 'Ажлын өдрүүд';

  @override
  String get pDayParts => 'Ажлын цаг';

  @override
  String get pDaysOff => 'Амралтын өдрүүд';

  @override
  String get pAddDayOff => 'Амралтын өдөр нэмэх';

  @override
  String get pSaved => 'Хадгалагдлаа';

  @override
  String get pTeam => 'Багийн гишүүд';

  @override
  String get pOwner => 'Эзэн';

  @override
  String get pInvited => 'Урилга илгээсэн';

  @override
  String get pInvite => 'Гишүүн урих';

  @override
  String get pInviteSent => 'Урилга илгээгдлээ';

  @override
  String get pRemove => 'Хасах';

  @override
  String get pNotifications => 'Мэдэгдлийн тохиргоо';

  @override
  String get pNotifyDirect => 'Шинэ шууд захиалгын ажил';

  @override
  String get pNotifyQuotes => 'Үнийн саналын хүсэлт · үр дүн';

  @override
  String get pNotifyChat => 'Үйл ажиллагааны зурвас';

  @override
  String get pQuietNight => 'Шөнийн дуу чимээгүй горим (22–08)';

  @override
  String get pNewInquiry => 'Шинэ асуулт';

  @override
  String get pTopic_settlement => 'Цалин';

  @override
  String get pTopic_reschedule => 'Цаг солих · цуцлах';

  @override
  String get pTopic_app => 'Аппын тусламж';

  @override
  String get pOpsTeam => 'Үйл ажиллагаа';

  @override
  String get pViewJob => 'Ажил харах';

  @override
  String pBookingNo(String n) {
    return 'Захиалга $n';
  }

  @override
  String get pSize => 'Талбай';

  @override
  String get pSchedule => 'Хуваарь';

  @override
  String get pSpace => 'Талбайн мэдээлэл';

  @override
  String get pNavigate => 'Чиглэл';

  @override
  String get pNavHint =>
      'Очих хаягийг газрын зургийн аппликейшнд нээнэ. Аппгүй бол вэб газрын зураг нээгдэнэ.';

  @override
  String get pOfflineSaved =>
      'Дохио алга. Хадгалсан, интернэт холбогдоход автоматаар илгээнэ.';

  @override
  String get pPhotoRetry => 'Дахин илгээх';

  @override
  String get pPhotoWaiting =>
      'Илгээгдээгүй зургууд интернэт холбогдоход автоматаар илгээгдэнэ.';

  @override
  String pUploadedCount(String total, String done) {
    return '$total-с $done илгээсэн';
  }

  @override
  String get apPgPickMethod => 'Төлбөрийн хэрэгслээ сонгоно уу';

  @override
  String get apPgConfirmTitle => 'Төлбөрийн мэдээлэл шалгах';

  @override
  String get apPgConfirmBtn => 'Төлбөрөө баталгаажуулах';

  @override
  String get apPgProcessing => 'Төлбөрийг боловсруулж байна…';

  @override
  String get apPgDoneTitle => 'Төлбөр амжилттай';

  @override
  String get apPgReceiptTitle => 'Цахим баримт';

  @override
  String get apPgReceiptApproval => 'Зөвшөөрлийн дугаар';

  @override
  String get apPgReceiptMethod => 'Хэрэгсэл';

  @override
  String get apPgReceiptAmount => 'Дүн';

  @override
  String get apPgReceiptDone => 'Дуусгах';

  @override
  String get apPgVaIssued => 'Виртуал данс нээгдлээ (туршилтын данс)';

  @override
  String get apPgTestBadge => 'ТУРШИЛТ';

  @override
  String get cIntPayout => 'Түншийн төлбөр';

  @override
  String get poTabSettlements => 'Тооцоо';

  @override
  String get poTabPayouts => 'Төлбөр олголт';

  @override
  String get poState_requested => 'Хүсэлт илгээсэн';

  @override
  String get poState_sent => 'Илгээсэн';

  @override
  String get poState_paid => 'Төлсөн';

  @override
  String get poState_failed => 'Амжилтгүй';

  @override
  String get poProviderManual => 'Гараар шилжүүлэг';

  @override
  String get poProviderToss => 'Toss-оор төлбөр';

  @override
  String get poShowAccount => 'Дансыг харуулах';

  @override
  String get poAccountTitle => 'Шилжүүлгийн мэдээлэл';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '$holder · $bank · $account руу $amount вон илгээгээд баталгаажуулна уу.';
  }

  @override
  String get poConfirmPaid => 'Шилжүүлсэн гэж тэмдэглэх';

  @override
  String get poMarkFailed => 'Амжилтгүй гэж тэмдэглэх';

  @override
  String get poReasonTitle => 'Амжилтгүйн шалтгаан';

  @override
  String get poReasonHint => 'жнь: буруу данс, шилжүүлэг цуцлагдсан';

  @override
  String get poSend => 'Toss-оор илгээх';

  @override
  String get poSync => 'Төлөв шалгах';

  @override
  String get poRetry => 'Дахин оролдох';

  @override
  String get poNoPayouts => 'Одоогоор төлбөр алга';

  @override
  String poRequestedToast(String n) {
    return '$n төлбөрийн хүсэлт үүсгэлээ';
  }

  @override
  String get poReasonRequired => 'Шалтгаанаа оруулна уу';

  @override
  String get poRevealNote => 'Дансны мэдээллийг үзсэн нь бүртгэгдэнэ';

  @override
  String get poSellerAction => 'Худалдагч бүртгэх';

  @override
  String get poSellerTitle => 'Toss худалдагчаар бүртгүүлэх';

  @override
  String get poSellerHint =>
      'Хамтрагчийн баталгаажсан данс ашиглана. Зөвхөн бизнесийн мэдээлэл оруулна уу.';

  @override
  String get poSellerIndividual => 'Хувь хүн';

  @override
  String get poSellerCompany => 'Байгууллага';

  @override
  String get poSellerName => 'Нэр';

  @override
  String get poSellerRepresentative => 'Төлөөлөгчийн нэр';

  @override
  String get poSellerRegNo => 'Бизнесийн бүртгэлийн дугаар (10 оронтой)';

  @override
  String get poSellerEmail => 'Тооцооны имэйл';

  @override
  String get poSellerPhone => 'Утас';

  @override
  String get poSellerSubmit => 'Бүртгэх';

  @override
  String poSellerDone(String status) {
    return 'Худалдагчийн төлөв: $status';
  }

  @override
  String get oFlags => 'Функцийн асаалт унтраалт';

  @override
  String get oFlagBooking => 'Захиалга';

  @override
  String get oFlagChat => 'Чат';

  @override
  String get oFlagAi => 'AI туслах';

  @override
  String get oFlagPayments => 'Төлбөр';

  @override
  String get oMaintenance => 'Засварын горим';

  @override
  String get oMaintenanceHint =>
      'Асаахад харилцагч, түнш аппууд засварын дэлгэц харуулна. Консол ажиллана.';

  @override
  String get oMaintenanceMessage => 'Засварын мэдэгдэл';

  @override
  String get oClientErrors => 'Аппын алдааны тайлан';

  @override
  String get oClientErrorsHint =>
      'Веб, Windows, консолоос ирсэн сүүлийн алдаанууд. Хувийн мэдээлэл автоматаар нуугдана.';

  @override
  String get oClientErrorsEmpty => 'Сүүлийн алдаа байхгүй';

  @override
  String get oHeartbeat => 'Ажиллагааны heartbeat';

  @override
  String get oHeartbeatOn =>
      'Холбогдсон. Сервер ажиллаж байх үед гадаад үйлчилгээнд мэдэгдэнэ.';

  @override
  String get oHeartbeatOff =>
      'Тохируулаагүй: install.sh-д MALKKEUM_HEARTBEAT_URL нэмнэ үү.';

  @override
  String get pvManage => 'Зөвшөөрлийн тохиргоо';

  @override
  String get pvOptional => 'Сонгомол';

  @override
  String get pvTerms => 'Үйлчилгээний нөхцөлд зөвшөөрөх';

  @override
  String get pvPrivacy => 'Хувийн мэдээлэл цуглуулах, ашиглахад зөвшөөрөх';

  @override
  String get pvOverseas => 'Хувийн мэдээллийг гадаад руу шилжүүлэхэд зөвшөөрөх';

  @override
  String get pvMarketing => 'Маркетингийн мэдээлэл';

  @override
  String get pvMarketingHint =>
      'Купон болон арга хэмжээний мэдээллийг SMS, KakaoTalk, аппын мэдэгдлээр авна. Хүссэн үедээ унтрааж болно.';

  @override
  String get pvReconsent =>
      'Нууцлалын бодлого өөрчлөгдлөө. Дахин үзэж зөвшөөрнө үү.';

  @override
  String get pvSaved => 'Зөвшөөрлийн тохиргоог хадгаллаа';

  @override
  String get pvExport => 'Миний мэдээллийг татах';

  @override
  String get pvExportHint =>
      'Таны талаар бидний хадгалсан бүх мэдээллийг JSON хэлбэрээр харуулна. Хуулж хадгалж болно.';

  @override
  String get pvCopy => 'Хуулах';

  @override
  String get pvCopied => 'Хуулагдлаа';

  @override
  String get pvExportFailed =>
      'Таны мэдээллийг ачаалж чадсангүй. Хэсэг хугацааны дараа дахин оролдоно уу.';

  @override
  String get safetyEmergency => 'Яаралтай холбоо барих';

  @override
  String get emergencyPolice => '112 Цагдаа';

  @override
  String get emergencyFire => '119 Гал түймэр ба аврах';

  @override
  String get emergencyShop => 'Харилцагчийн үйлчилгээ';

  @override
  String get caseReportAction => 'Асуудал мэдээлэх';

  @override
  String get caseReportTitle => 'Юу болсон бэ?';

  @override
  String get caseKindDamage => 'Гэмтэл';

  @override
  String get caseKindLoss => 'Алдсан';

  @override
  String get caseKindComplaint => 'Гомдол';

  @override
  String get caseKindNoShow => 'Цэвэрлэгч ирээгүй';

  @override
  String get caseKindSafety => 'Аюулгүй байдлын асуудал';

  @override
  String get caseKindPayment => 'Төлбөрийн маргаан';

  @override
  String get caseSummaryHint =>
      'Юу болсныг тайлбарлана уу (300 тэмдэгт хүртэл)';

  @override
  String get caseSubmit => 'Илгээх';

  @override
  String get caseSubmitted => 'Хүлээн авлаа. Баг 24 цагийн дотор хариулна.';

  @override
  String get caseFailed => 'Илгээж чадсангүй. Дахин оролдоно уу.';

  @override
  String get checkInAction => 'Бүртгүүлэх';

  @override
  String get checkOutAction => 'Гарах бүртгэл';

  @override
  String checkedInAt(String time) {
    return 'Ирсэн $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Гарсан $time';
  }

  @override
  String get entryCodeAction => 'Орцны код харах';

  @override
  String get entryCodeTitle => 'Орцны код';

  @override
  String get entryCodeNotToday => 'Зөвхөн үйлчилгээний өдөр харагдана';

  @override
  String get entryCodeEmpty => 'Орцны код бүртгэгдээгүй';

  @override
  String get actionFailed => 'Хийж чадсангүй. Дахин оролдоно уу.';

  @override
  String get consoleCasesTitle => 'Хэргийн дараалал';

  @override
  String get consoleCasesEmpty => 'Нээлттэй хэрэг алга';

  @override
  String get caseOverdue => 'Хугацаа хэтэрсэн';

  @override
  String get caseStatusOpen => 'Нээлттэй';

  @override
  String get caseStatusInvestigating => 'Шалгаж байна';

  @override
  String get caseStatusResolved => 'Шийдсэн';

  @override
  String get caseStatusRejected => 'Татгалзсан';

  @override
  String get caseReassign => 'Ажилтан дахин оноох';

  @override
  String get caseRefund => 'Буцаан олгох';

  @override
  String get caseHold => 'Тооцоог түр зогсоох';

  @override
  String get caseNoteHint => 'Дотоод тэмдэглэл';

  @override
  String get caseSave => 'Хадгалах';

  @override
  String get cSetup => 'Тохиргоо';

  @override
  String get cSetupTitle => 'Эхлүүлэхэд бэлтгэх';

  @override
  String cSetupProgress(String done, String total) {
    return '$total-с $done дууссан';
  }

  @override
  String get cSetupAllDone => 'Бүх зүйл бэлэн!';

  @override
  String get cSetupBusiness => 'Бизнесийн мэдээлэл';

  @override
  String get cSetupBusinessName => 'Үйлчилгээний нэр';

  @override
  String get cSetupSupportPhone => 'Тусламжийн утас';

  @override
  String get cSetupSupportEmail => 'Тусламжийн имэйл';

  @override
  String get cSetupSupportHours => 'Тусламжийн цаг';

  @override
  String get cSetupColor => 'Брэндийн өнгө';

  @override
  String get cSetupLogo => 'Лого байршуулах';

  @override
  String get cSetupCompany => 'Компанийн мэдээлэл (апп, вэбийн доод хэсэгт)';

  @override
  String get cSetupLegalName => 'Хуулийн нэр';

  @override
  String get cSetupCeo => 'Төлөөлөгч';

  @override
  String get cSetupRegNo => 'Бүртгэлийн дугаар';

  @override
  String get cSetupMailOrderNo => 'Онлайн худалдааны бүртгэл';

  @override
  String get cSetupAddress => 'Хаяг';

  @override
  String get cSetupPrivacyOfficer => 'Нууцлалын хариуцагч';

  @override
  String get cSetupStoreLinks =>
      'Апп дэлгүүрийн холбоос (бөглөсний дараа вэбийн товч идэвхжинэ)';

  @override
  String get cSetupCustomerApp => 'Хэрэглэгчийн апп';

  @override
  String get cSetupPartnerApp => 'Түншийн апп';

  @override
  String get cSetupPayMethods => 'Төлбөрийн арга';

  @override
  String get cSetupPayMethodsHint =>
      'Хэрэглэгчдэд харагдах төлбөрийн аргыг асаах/унтраах. Шууд хэрэгжинэ.';

  @override
  String get cReviewTitle => 'Дэлгүүрийн шалгалтын демо бүртгэл';

  @override
  String get cReviewHint =>
      'Шалгагч Солонгос SMS хүлээж авахгүй. Дугаар болон 6 оронтой кодыг шалгалтын тэмдэглэлд бичнэ үү. Автоматаар унтарна.';

  @override
  String get cReviewPhone => 'Демо утасны дугаар';

  @override
  String get cReviewCode => 'Тогтмол код (6 орон)';

  @override
  String cReviewActiveUntil(String date) {
    return '$date хүртэл идэвхтэй';
  }

  @override
  String get cReviewEnable => 'Асаах (14 хоног)';

  @override
  String get pDeleteAccountBody =>
      'Таны баг болон хувийн мэдээлэл бүрмөсөн устна. Эхлээд хуваарилсан ажил, үлдэгдэл төлбөрөө дуусгана уу.';

  @override
  String get err_has_active_jobs =>
      'Танд хуваарилсан ажил байна. Дуусгах эсвэл тусламжаас шилжүүлэхийг хүснэ үү.';

  @override
  String get err_pending_payouts =>
      'Төлөгдөөгүй төлбөр байна. Төлсний дараа устгаж болно.';

  @override
  String get err_phone_required =>
      'Ажил авахаас өмнө утасны дугаараа баталгаажуулна уу.';

  @override
  String get nAlerts => 'Мэдэгдэл';

  @override
  String get nEmpty => 'Мэдэгдэл алга';

  @override
  String nUnread(String count) {
    return 'Уншаагүй $count';
  }

  @override
  String get pVerifyPhone => 'Баталгаажуулах';

  @override
  String get mMyJobs => 'Миний ажил';

  @override
  String get mNoJobs =>
      'Хуваарилсан ажил алга. Багийн ахлагчийн өгсөн ажил энд харагдана.';

  @override
  String mTeam(String team) {
    return '$team-н гишүүн';
  }

  @override
  String get cSetupSave => 'Хадгалах';

  @override
  String get cSetupSaved => 'Хадгалсан';

  @override
  String get cSetupTest => 'Холболт шалгах';

  @override
  String get cSetupClear => 'Салгах';

  @override
  String get cSetupConnected => 'Холбогдсон';

  @override
  String get cSetupNotConnected => 'Холбогдоогүй';

  @override
  String get cSetupFromEnv => 'Серверийн тохиргоог ашиглаж байна';

  @override
  String get cSetupCheckInApp => 'Хадгалсан · аппаас нэвтэрч шалгана уу';

  @override
  String get cSetupInvalidKey => 'Түлхүүр буруу. Хуулсан утгаа шалгана уу';

  @override
  String get cSetupUnreachable =>
      'Үйлчилгээнд холбогдож чадсангүй. Дараа дахин оролдоно уу';

  @override
  String get cSetupKeepValue => 'Хадгалсан (солих үед л оруулна)';

  @override
  String get cSetupGuide => 'Тохируулах заавар';

  @override
  String get cSetupOpenSite => 'Сайт нээх';

  @override
  String get cSetupWebhook => 'Webhook хаяг (PortOne консолд буулгана)';

  @override
  String get cCopied => 'Хуулсан';

  @override
  String get cSetupDevMode => 'Туршилтын горим: бодит төлбөр, мессеж явахгүй';

  @override
  String get cSetupOptional => 'Заавал биш';

  @override
  String get cIntPortone => 'Төлбөр (PortOne)';

  @override
  String get cIntSolapi => 'SMS ба KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Аппын мэдэгдэл (Firebase)';

  @override
  String get cIntKakao => 'Kakao нэвтрэлт';

  @override
  String get cIntNaver => 'Naver нэвтрэлт';

  @override
  String get cIntGoogle => 'Google нэвтрэлт';

  @override
  String get cIntApple => 'Apple нэвтрэлт';

  @override
  String get cFirstRunTitle => 'Тавтай морил! Эзэмшигчийн бүртгэл үүсгэнэ үү';

  @override
  String get cFirstRunBody =>
      'Суулгах үед гарсан 12 тэмдэгт кодыг оруулна уу. Энэ бүртгэл бүх тохиргоог удирдана.';

  @override
  String get cFirstRunCode => 'Суулгацын код';

  @override
  String get cName => 'Нэр';

  @override
  String get cFirstRunCreate => 'Бүртгэл үүсгээд эхлэх';

  @override
  String get cWrongSetupCode => 'Суулгацын код буруу';

  @override
  String get cWeakPassword => 'Нууц үг хамгийн багадаа 12 тэмдэгт байна';

  @override
  String get cInvalidValue => 'Оруулсан утгаа шалгана уу';

  @override
  String get cMfaTitle => 'Хоёр шаттай нэвтрэлт';

  @override
  String get cMfaCode => 'Баталгаажуулагчийн аппаас 6 оронтой код';

  @override
  String get cMfaRecovery => 'Сэргээх код';

  @override
  String get cMfaUseRecovery => 'Оронд нь сэргээх код ашиглах';

  @override
  String get cMfaUseCode => 'Оронд нь баталгаажуулагчийн код ашиглах';

  @override
  String get cMfaVerify => 'Баталгаажуулах';

  @override
  String get cMfaBack => 'Нэвтрэх рүү буцах';

  @override
  String get cMfaEnrolTitle => 'Хоёр шаттай нэвтрэлтийг тохируулах';

  @override
  String get cMfaEnrolBody =>
      'Админд баталгаажуулах апп хэрэгтэй. Доорх түлхүүрийг Google Authenticator, 1Password гэх мэт апп-д нэмээд, тэнд гарсан 6 оронтой кодыг оруулна уу.';

  @override
  String get cMfaSecret => 'Тохируулах түлхүүр';

  @override
  String get cMfaLink => 'Тохируулах холбоос (otpauth)';

  @override
  String get cMfaCopy => 'Хуулах';

  @override
  String get cMfaCopied => 'Хуулагдлаа';

  @override
  String get cMfaConfirm => 'Баталгаажуулж асаах';

  @override
  String get cMfaCodesTitle => 'Сэргээх кодоо хадгалаарай';

  @override
  String get cMfaCodesBody =>
      'Баталгаажуулагчаа алдвал код бүр нэвтрэхэд нэг удаа ашиглагдана. Эдгээрийг одоо л харуулна.';

  @override
  String get cMfaDownload => 'Татах';

  @override
  String get cMfaSaveFailed =>
      'Энэ төхөөрөмж файл хадгалж чадахгүй. Кодыг хуулж аюулгүй газар хадгална уу.';

  @override
  String get cMfaContinue => 'Консол руу үргэлжлүүлэх';

  @override
  String get cMfaInvalid =>
      'Код таарахгүй байна. Утасныхаа цагийг шалгаад дахин оролдоно уу.';

  @override
  String get cMfaExpired =>
      'Нэвтрэлтийн хугацаа дууссан. Нууц үгийн алхмаас дахин эхлүүлнэ үү.';

  @override
  String get cMfaLocked =>
      'Оролдлого хэт олон боллоо. Хэдэн минутын дараа дахин оролдоно уу.';

  @override
  String get cStaffReset => 'Нууц үг шинэчлэх';

  @override
  String get cStaffResetConfirm =>
      'Энэ ажилтны нууц үгийг шинэчлэх үү? Бүх төхөөрөмжөөс гаргана.';

  @override
  String get cStaffResetTitle => 'Шинэчлэх токен';

  @override
  String get cStaffResetBody =>
      'Энэ токеныг ажилтанд өгнө үү. Нэг удаа, 30 минутын дотор ашиглагдана. Хаасны дараа дахин харах боломжгүй.';

  @override
  String get subTitle => 'Тогтмол цэвэрлэгээ';

  @override
  String get subNew => 'Захиалга эхлүүлэх';

  @override
  String get subCadence => 'Давтамж';

  @override
  String get subWeekly => 'Долоо хоног бүр';

  @override
  String get subBiweekly => '2 долоо хоног тутам';

  @override
  String get subEvery4Weeks => '4 долоо хоног тутам';

  @override
  String get subWeekday => 'Гариг';

  @override
  String get subHour => 'Ирэх цаг';

  @override
  String subDiscountNote(String percent) {
    return 'Ирэлт бүр $percent% хөнгөлөлттэй';
  }

  @override
  String get subChargeNote =>
      'Ирэлтээс нэг өдрийн өмнө хадгалсан картаас төлнө';

  @override
  String get subCreate => 'Захиалах';

  @override
  String get subCreated => 'Захиалга эхэллээ';

  @override
  String get subNeedAddress => 'Эхлээд хаяг нэмнэ үү';

  @override
  String get subListEmpty => 'Захиалга одоогоор алга';

  @override
  String get subStatusActive => 'Идэвхтэй';

  @override
  String get subStatusPaused => 'Түр зогсоосон';

  @override
  String get subStatusCancelled => 'Цуцалсан';

  @override
  String subNextVisit(String date) {
    return 'Дараагийн ирэлт $date';
  }

  @override
  String get subPause => 'Түр зогсоох';

  @override
  String get subResume => 'Үргэлжлүүлэх';

  @override
  String get subCancelSub => 'Захиалгаа цуцлах';

  @override
  String get subCancelConfirm =>
      'Цаашдын ирэлтүүд цуцлагдана. Захиалсан ирэлтийг тусад нь цуцална уу.';

  @override
  String get subSkip => 'Энэ ирэлтийг алгасах';

  @override
  String get subMove => 'Огноо солих';

  @override
  String get subVisitLocked => 'Ирэлтийн өмнөх өдрөөс хойш өөрчлөх боломжгүй';

  @override
  String get subPausedPayment =>
      'Төлбөр дараалан амжилтгүй болсонд түр зогсоосон. Картаа солиод үргэлжлүүлнэ үү.';

  @override
  String get subStatePlanned => 'Товлосон';

  @override
  String get subStateBooked => 'Захиалсан';

  @override
  String get subStateSkipped => 'Алгассан';

  @override
  String get subStateMissed => 'Өнгөрсөн';

  @override
  String get pSubsTitle => 'Тогтмол үйлчлүүлэгчид';

  @override
  String get pSubsEmpty => 'Тогтмол үйлчлүүлэгч одоогоор алга';

  @override
  String get cSubsTitle => 'Захиалгууд';

  @override
  String get cSubsEdit => 'Үйлчлүүлэгчийн оронд засах';

  @override
  String get cMrr => 'Сарын давтагдах орлого (MRR)';

  @override
  String get cChurn => 'Цуцалтын хувь';

  @override
  String get cActiveSubs => 'Идэвхтэй захиалга';

  @override
  String get cRecognized => 'Тухайн хугацаанд хүлээн зөвшөөрсөн орлого';

  @override
  String get cSubsLoadFailed => 'Захиалгыг ачаалж чадсангүй';

  @override
  String get tTaxSection => 'Татвар';

  @override
  String tVatQuarter(String q) {
    return 'Q$q НӨАТ CSV';
  }

  @override
  String get tVatYear => 'Жил';

  @override
  String get tExportWithholding => 'Суутгалын тайлан CSV';

  @override
  String get tExportTaxInvoices => 'Татварын нэхэмжлэх байршуулах CSV';

  @override
  String get tTaxLayoutNote =>
      'Байршуулахаас өмнө 홈택스-ийн загвартай багануудыг шалгана уу. Бүтэц баталгаажаагүй.';

  @override
  String get tCashReceipts => 'Бэлэн мөнгөний баримт';

  @override
  String get tCashIssued => 'Олгосон';

  @override
  String get tCashFailed => 'Амжилтгүй';

  @override
  String get tCashPending => 'Хүлээгдэж буй';

  @override
  String get tCashCancelled => 'Цуцлагдсан';

  @override
  String get tReissue => 'Дахин олгох';

  @override
  String get tTaxInvoices => 'Татварын нэхэмжлэх';

  @override
  String get tApprovalNumber => 'Зөвшөөрлийн дугаар';

  @override
  String get tIssuedOn => 'Олгосон огноо';

  @override
  String get tMarkIssued => 'Олгосон гэж тэмдэглэх';

  @override
  String get tQueueEmpty => 'Хүлээгдэж буй хүсэлт алга';

  @override
  String get tWithholdingLabel => 'Суутгал';

  @override
  String get tGrossAmount => 'Нийт дүн';

  @override
  String get tIncomeTax => 'Орлогын татвар';

  @override
  String get tLocalTax => 'Орон нутгийн орлогын татвар';

  @override
  String get tNetAmount => 'Гарт авах дүн';

  @override
  String get tNoWithholding => 'Суутгалгүй (бүртгэлтэй бизнес)';

  @override
  String get tEstWithholding => 'Тооцоолсон суутгал (хүлээгдэж буй)';

  @override
  String get tReceiptOptions => 'Баримтын сонголт';

  @override
  String get tWantCashReceipt => 'Бэлэн мөнгөний баримт авах';

  @override
  String get tCashForIncome => 'Татвар хасалтад (утасны дугаар)';

  @override
  String get tCashForBusiness => 'Бизнесийн зардалд (бизнесийн дугаар)';

  @override
  String get tWantTaxInvoice => 'Татварын нэхэмжлэх авах (бизнес)';

  @override
  String get tPhoneForReceipt => 'Утасны дугаар';

  @override
  String get tBusinessNumber => 'Бизнесийн бүртгэлийн дугаар';

  @override
  String get tCompanyName => 'Компанийн нэр';

  @override
  String get tRepresentative => 'Төлөөлөгч';

  @override
  String get tInvoiceEmail => 'Нэхэмжлэх хүлээн авах имэйл';

  @override
  String get tReceiptSave => 'Хадгалаад төлөх';

  @override
  String get tReceiptSaveFailed => 'Баримтын мэдээллийг хадгалж чадсангүй';

  @override
  String get tTaxType => 'Татварын төрөл';

  @override
  String get tTaxFreelancer => 'Фрилансер (суутгалтай)';

  @override
  String get tTaxBusiness => 'Бүртгэлтэй бизнес (суутгалгүй)';

  @override
  String get tReceiptSettings => 'Баримтын тохиргоо';

  @override
  String get reviewRuleLine =>
      'Доромжлол, хувийн мэдээлэл, худал эсвэл сурталчилгаатай агуулга хориотой. Мэдээлэгдсэн сэтгэгдлийг нуух болно.';

  @override
  String get reportAction => 'Мэдээлэх';

  @override
  String get reportSheetTitle => 'Энэ сэтгэгдлийг мэдээлэх үү?';

  @override
  String get reportReasonSpam => 'Спам эсвэл сурталчилгаа';

  @override
  String get reportReasonOffensive => 'Доромжлол эсвэл үзэн ядалт';

  @override
  String get reportReasonPersonal => 'Хувийн мэдээлэл агуулсан';

  @override
  String get reportReasonOther => 'Бусад';

  @override
  String get reportNoteHint => 'Дэлгэрэнгүй (сонголттой, 300 тэмдэгт хүртэл)';

  @override
  String get reportSubmit => 'Мэдээлэл илгээх';

  @override
  String get reportThanks => 'Баярлалаа. Манай баг шалгана.';

  @override
  String get reportAlready => 'Та энэ сэтгэгдлийг аль хэдийн мэдээлсэн';

  @override
  String get reportFailed => 'Мэдээлэл илгээж чадсангүй. Дахин оролдоно уу.';

  @override
  String get reviewBlocked =>
      'Энэ бүртгэлээр сэтгэгдэл бичих боломжгүй. Дэмжлэгт хандана уу.';

  @override
  String get modTitle => 'Мэдээлэгдсэн сэтгэгдлүүд';

  @override
  String get modEmpty => 'Хүлээгдэж буй мэдээлэл алга';

  @override
  String modReports(String count) {
    return '$count мэдээлэл';
  }

  @override
  String get modKeep => 'Үлдээх';

  @override
  String get modHide => 'Нуух';

  @override
  String get modDelete => 'Устгах';

  @override
  String get modBlockAuthor => 'Зохиогчийг хязгаарлах';

  @override
  String get modUnblockAuthor => 'Хязгаарлалтыг цуцлах';

  @override
  String get modDone => 'Боллоо';

  @override
  String get modFailed => 'Боловсруулж чадсангүй. Дахин оролдоно уу.';

  @override
  String get modHidden => 'Нуугдсан сэтгэгдэл';

  @override
  String uUpdateBanner(String version) {
    return 'Шинэ хувилбар $version гарлаа';
  }

  @override
  String get uUpdateNow => 'Шинэчлэх';

  @override
  String get uUpdateLater => 'Дараа';

  @override
  String get uUpdateRequiredTitle => 'Шинэчлэх шаардлагатай';

  @override
  String get uUpdateRequiredBody =>
      'Энэ хувилбарыг дэмжихээ больсон. Дэлгүүрээс шинэчилнэ үү.';

  @override
  String get uUpdateStore => 'Дэлгүүрээс шинэчлэх';

  @override
  String get uUpdateStoreMissing =>
      'Шинэчлэх холбоос бэлэн болоогүй байна. Дараа дахин оролдоно уу.';

  @override
  String uCurrentVersion(String version) {
    return 'Одоогийн хувилбар $version';
  }

  @override
  String get uAppVersionTitle => 'Аппын хувилбарууд';

  @override
  String get uAppVersionHint =>
      'Хамгийн бага хувилбараас доош аппууд шинэчлэх дэлгэцэд зогсоно. Жишээ: 1.2.0';

  @override
  String get uMinVersion => 'Хамгийн бага хувилбар';

  @override
  String get uLatestVersion => 'Хамгийн сүүлийн хувилбар';

  @override
  String get walletTitle => 'Оноогоо хэтэвч';

  @override
  String get walletBalance => 'Ашиглах боломжтой оноо';

  @override
  String walletPoints(String count) {
    return '$count P';
  }

  @override
  String walletExpiring(String days, String count) {
    return '$days хоногийн дотор $count P дуусна';
  }

  @override
  String get walletOff => 'Оноо цуглуулах хөтөлбөр хараахан нээгдээгүй';

  @override
  String get walletEmpty => 'Оноогийн түүх одоохондоо алга';

  @override
  String get walletHistory => 'Сүүлийн үйл явдал';

  @override
  String get walletKindEarn => 'Захиалгын буцаан олголт';

  @override
  String get walletKindWelcome => 'Тавтай морилсон оноо';

  @override
  String get walletKindReferral => 'Найз урилгын шагнал';

  @override
  String get walletKindRefund => 'Цуцлалтаар буцаасан оноо';

  @override
  String get walletKindSpend => 'Захиалгад зарцуулсан';

  @override
  String get walletKindExpire => 'Хугацаа дууссан';

  @override
  String get walletKindOther => 'Оноо тохируулга';

  @override
  String get moreWallet => 'Оноогоо хэтэвч';

  @override
  String get payHistoryTitle => 'Төлбөрийн түүх';

  @override
  String get payHistoryEmpty => 'Төлбөр одоохондоо алга';

  @override
  String get payStatusPaid => 'Төлсөн';

  @override
  String get payStatusRefunded => 'Буцаан олгосон';

  @override
  String get payStatusPending => 'Төлбөр хүлээгдэж байна';

  @override
  String get payStatusClosed => 'Төлөгдөөгүй';

  @override
  String get receiptTitle => 'Цахим баримт';

  @override
  String get receiptLegal => 'Байгууллагын нэр';

  @override
  String get receiptRegNo => 'Бүртгэлийн дугаар';

  @override
  String get receiptAddr => 'Хаяг';

  @override
  String get receiptPhone => 'Харилцагчийн үйлчилгээ';

  @override
  String get receiptDate => 'Төлсөн огноо';

  @override
  String get receiptCopy => 'Баримтыг хуулах';

  @override
  String get receiptCopied => 'Баримтыг хуулсан';

  @override
  String get receiptNote =>
      'Зөвхөн төлбөрийн баталгаа. Татварын нэхэмжлэх хэрэгтэй бол захиалгын мэдээллээс хүсэлт гаргана уу.';

  @override
  String get checkoutPointsUse => 'Оноо ашиглах';

  @override
  String checkoutPointsAvail(String count, String max) {
    return '$count P байна · энэ төлбөрт дээд тал нь $max P';
  }

  @override
  String get checkoutPointsNeedsWindow =>
      'Оноог төлбөрийн цонхоор төлөхөд ашиглана';

  @override
  String get pointsLedgerTitle => 'Онооны дэвтэр';

  @override
  String get pointsAdjustAmount => 'Оноо (хасах бол сөрөг тоо)';

  @override
  String get pointsAdjustReason => 'Тохируулгын шалтгаан';

  @override
  String get pointsAdjustInvalid => '0-ээс өөр оноо болон шалтгаан оруулна уу';

  @override
  String get pointsAdjustDone => 'Оноог тохирууллаа';

  @override
  String get err_points_insufficient =>
      'Оноо хүрэлцэхгүй байна. Ашиглах оноогоо багасгана уу.';

  @override
  String get err_points_over_cap =>
      'Энэ төлбөрт ашиглах онооны дээд хэмжээнээс хэтэрлээ.';

  @override
  String get err_points_cover_total =>
      'Нийт дүнг зөвхөн оноогоор төлөх боломжгүй. Бага зэрэг багасгана уу.';

  @override
  String get webBookNow => 'Вэбээр шууд захиалах';

  @override
  String get webBookSub => 'Аппликейшн суулгах шаардлагагүй';

  @override
  String get apPgBrowserNote =>
      'Төлбөрөө браузер дээр дуусгаад, энд буцаж ирээд доорх товчийг дарна уу.';

  @override
  String get apPgBrowserDone => 'Би төлбөрөө төлсөн';
}
