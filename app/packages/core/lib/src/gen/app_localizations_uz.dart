// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class TUz extends T {
  TUz([String locale = 'uz']) : super(locale);

  @override
  String get addressSearch => 'Manzil qidirish';

  @override
  String get addressSearchHint =>
      'Ko\'cha nomi, bino yoki uchastka raqami bo\'yicha qidiring';

  @override
  String get addressSearchButton => 'Qidirish';

  @override
  String get addressSearchMinChars => 'Kamida 2 ta belgi kiriting';

  @override
  String get addressNoResults =>
      'Natija topilmadi. Boshqa so\'zlar bilan urinib ko\'ring.';

  @override
  String get addressManualEntry => 'Qo\'lda kiritish';

  @override
  String get cardRegisterTitle => 'Karta ro\'yxatdan o\'tkazish';

  @override
  String get cIntJuso => 'Manzil qidiruv (juso.go.kr)';

  @override
  String get aiLabel => 'AI yordamchi';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Mijozlar chatiga avtomatik javob beradi. Har bir xabar uchun API to\'lovi olinadi.';

  @override
  String get aiModeOffline => 'Faqat xodimlar bo\'lmaganda javob beradi';

  @override
  String get aiModeAlways => 'AI doim birinchi javob beradi';

  @override
  String get aiPause => 'AI ni to\'xtatish';

  @override
  String get aiResume => 'AI ni davom ettirish';

  @override
  String get aiPausedNote => 'Bu chatda AI to\'xtatilgan';

  @override
  String aiUsageMonth(String count) {
    return 'Bu oydagi AI chaqiruvlari: $count';
  }

  @override
  String get aiNotConfigured => 'AI yordamchi o\'chirilgan';

  @override
  String get aiCapThreadLabel => 'Har suhbatda soatiga javoblar chegarasi';

  @override
  String get aiCapMemberLabel => 'Har mijozga kunlik javoblar chegarasi';

  @override
  String get aiCapDailyLabel =>
      'Barcha suhbatlar bo\'yicha kunlik javoblar chegarasi';

  @override
  String get aiCapHint =>
      'Faqat raqam kiriting. Standart uchun bo\'sh qoldiring.';

  @override
  String get apSocialOr => 'yoki';

  @override
  String get apSocialSignIn => 'Tezkor kirish';

  @override
  String get apLoginKakao => 'Kakao orqali davom etish';

  @override
  String get apLoginNaver => 'Naver orqali davom etish';

  @override
  String get apLoginGoogle => 'Google orqali davom etish';

  @override
  String get apLoginApple => 'Apple orqali davom etish';

  @override
  String get apDevSocialNote =>
      'Ishlab chiqish rejimi. Haqiqiy ijtimoiy hisob emas, sinov hisobi orqali kirasiz.';

  @override
  String get apSocialFailed =>
      'Tezkor kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.';

  @override
  String get apProviderNotConfigured => 'Bu kirish usuli hali tayyor emas';

  @override
  String get apPhoneTaken => 'Bu raqam boshqa hisobga ulangan';

  @override
  String get apPhoneAttachTitle => 'Telefon raqamingizni tasdiqlang';

  @override
  String get apPhoneAttachBody =>
      'Bu raqam bron qilish va usta bilan aloqa uchun ishlatiladi. Faqat bir marta tasdiqlanadi.';

  @override
  String get apPayAllTitle => 'To\'lov usulini tanlang';

  @override
  String get apPaySavedTitle => 'Saqlangan usullar';

  @override
  String get apPayMoreTitle => 'Barcha to\'lov usullari';

  @override
  String get apPayBillingHint =>
      'Bir marta ulang, keyingi safar bir bosishda to\'lang';

  @override
  String get apPayCheckoutHint => 'To\'lov oynasida yakunlang';

  @override
  String get apPayRegistering => 'Ro\'yxatga olinmoqda…';

  @override
  String get apPayManageHint =>
      'Ulangan usullar bilan bir bosishda to\'lang. Tezkor to\'lov usullarini shu yerda qo\'shishingiz mumkin.';

  @override
  String get apMethodCard => 'Kredit va debet karta';

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
  String get apMethodTransfer => 'Bank o\'tkazmasi';

  @override
  String get apMethodVirtual => 'Virtual hisob raqami';

  @override
  String get apMethodPhone => 'Mobil hisob orqali';

  @override
  String get apMethodUnknown => 'Boshqa to\'lov';

  @override
  String get apVaTitle => 'Depozit hisob raqami tayyor';

  @override
  String get apVaWaiting => 'Depozit kutilmoqda';

  @override
  String get apVaBody =>
      'Muddat ichida depozit tushsa, bron tasdiqlanadi. Depozit avtomatik tekshiriladi.';

  @override
  String get apVaBank => 'Bank';

  @override
  String get apVaAccount => 'Hisob raqami';

  @override
  String get apVaHolder => 'Hisobvaraq egasi';

  @override
  String get apVaAmount => 'Summa';

  @override
  String apVaDue(String due) {
    return '$due gacha to\'lang';
  }

  @override
  String get apVaCopy => 'Nusxalash';

  @override
  String get apVaCopied => 'Hisob raqami nusxalandi';

  @override
  String get apVaBannerTitle => 'Depozit kutilayotgan bron bor';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due gacha';
  }

  @override
  String get apVaBannerAction => 'Hisobni ko\'rish';

  @override
  String get apPgTitle => 'To\'lov oynasi';

  @override
  String get apPgDevNote =>
      'Faqat ishlab chiqish muhiti uchun to\'lov simulyatsiyasi. Haqiqiy to\'lov amalga oshmaydi.';

  @override
  String apPgPay(String amount) {
    return '$amount to\'lash';
  }

  @override
  String get apPgIssue => 'Hisob raqamini olish';

  @override
  String get apPgCancel => 'To\'lovni bekor qilish';

  @override
  String get apErrSlotFullRefunded =>
      'Bu vaqt endi band bo\'ldi, shuning uchun to\'lov avtomatik bekor qilindi';

  @override
  String get apErrCheckoutExpired =>
      'To\'lov vaqti tugadi. Iltimos, qayta urinib ko\'ring.';

  @override
  String get apIdentityTitle => 'Shaxsni tasdiqlash (PASS)';

  @override
  String get apIdentityBody =>
      'Telefon operatoringiz orqali shaxsingiz tasdiqlanadi. Xavfsiz savdo va to\'lovlar uchun ishlatiladi.';

  @override
  String get apIdentityAction => 'Shaxsni tasdiqlash';

  @override
  String get apIdentityDone => 'Shaxs tasdiqlandi';

  @override
  String get apIdentityVerified => 'Tasdiqlangan';

  @override
  String get apIdentityUnverified => 'Hali tasdiqlanmagan';

  @override
  String get apIdentityDevTitle => 'Sinov shaxsni tasdiqlash';

  @override
  String get apIdentityDevBody =>
      'Ishlab chiqish muhitida haqiqiy tekshiruvsiz o\'tadi.';

  @override
  String get apIdentityDevPass => 'O\'tkazish';

  @override
  String get apPayManageTitle => 'Tezkor to\'lovni ulash';

  @override
  String get cTitle => 'Operatsion konsol';

  @override
  String get cEmail => 'Elektron pochta';

  @override
  String get cPassword => 'Parol';

  @override
  String get cLogin => 'Kirish';

  @override
  String get cLoginFailed => 'Email yoki parol noto\'g\'ri';

  @override
  String get cDashboard => 'Boshqaruv paneli';

  @override
  String get cBookings => 'Bronlar';

  @override
  String get cQuoteDesk => 'Narx bo\'limi';

  @override
  String get cInbox => 'Xabarlar';

  @override
  String get cCatalog => 'Katalog · narxlar';

  @override
  String get cMarketing => 'Kuponlar · kontent';

  @override
  String get cPartners => 'Hamkorlar';

  @override
  String get cSettlements => 'Hisob-kitoblar';

  @override
  String get cCustomers => 'Mijozlar';

  @override
  String get cStaff => 'Xodimlar';

  @override
  String get cSearchCommand => 'Qidirish · buyruq';

  @override
  String get cPaletteHint => 'Bo\'lim nomi yoki bron raqamini kiriting';

  @override
  String get cTodayJobs => 'Bugungi ishlar';

  @override
  String get cOpenQuotes => 'Kutilayotgan narxlar';

  @override
  String get cUnassigned => 'Biriktirilmagan';

  @override
  String get cUnreadThreads => 'O\'qilmagan suhbatlar';

  @override
  String get cRevenue30 => '30 kunlik to\'lovlar';

  @override
  String get cBookings30 => '30 kunlik bronlar';

  @override
  String get cByService => 'Xizmat bo\'yicha bronlar (30 kun)';

  @override
  String get cAllStatus => 'Barcha holatlar';

  @override
  String get cAllServices => 'Barcha xizmatlar';

  @override
  String get cSearch => 'Qidirish (raqam, telefon, ism, manzil)';

  @override
  String get cNoResults => 'Natija topilmadi';

  @override
  String get cNumber => 'Raqam';

  @override
  String get cVisit => 'Tashrif';

  @override
  String get cService => 'Xizmat';

  @override
  String get cStatus => 'Holat';

  @override
  String get cTeam => 'Jamoa';

  @override
  String get cAmount => 'Summa';

  @override
  String get cCustomer => 'Mijoz';

  @override
  String get cPayments => 'To\'lovlar';

  @override
  String get cChangeStatus => 'Holatni o\'zgartirish';

  @override
  String get cTeamName => 'Biriktirilgan jamoa nomi';

  @override
  String get cAssign => 'Jamoa biriktirish';

  @override
  String get cMarkDone => 'Bajarilgan deb belgilash';

  @override
  String get cConfirm => 'Tasdiqlangan deb belgilash';

  @override
  String get cCancelRefund => 'Bekor qilish · qaytarish';

  @override
  String get cRefundAmount =>
      'Qaytariladigan summa (bo\'sh qoldirilsa — to\'liq)';

  @override
  String get cDone => 'Bajarildi';

  @override
  String get cAnswers => 'Mijoz javoblari';

  @override
  String get cEstimateCalc => 'Avtomatik hisob';

  @override
  String get cBase => 'Asosiy';

  @override
  String get cExtras => 'Qo\'shimcha';

  @override
  String get cSurcharge => 'Ustama';

  @override
  String get cBeforeVat => 'QQS dan oldin';

  @override
  String get cProQuotes => 'Hamkor narxlari';

  @override
  String get cNoProQuotes => 'Hali narx takliflari yo\'q';

  @override
  String get cFinalPrice => 'Mijoz uchun yakuniy summa';

  @override
  String get cQuoteNote => 'Mijozga yuboriladigan izoh';

  @override
  String get cSendQuote => 'Mijozga narx yuborish';

  @override
  String get cQuoteSent => 'Narx yuborildi';

  @override
  String get cCustomerChats => 'Mijozlar';

  @override
  String get cPartnerChats => 'Hamkorlar';

  @override
  String get cSelectBooking => 'Bronni tanlang';

  @override
  String get cRefunded => 'Qaytarildi';

  @override
  String get cPartRefunded => 'Qisman qaytarildi';

  @override
  String get cFailed => 'Muvaffaqiyatsiz';

  @override
  String get cSelectThread => 'Suhbatni tanlang';

  @override
  String get cReplyHint => 'Javob yozing · Ctrl+Enter yuborish';

  @override
  String get cOpenBooking => 'Bronni ochish';

  @override
  String get cShortcuts => 'J/K siljitish · Ctrl+K buyruq';

  @override
  String get cPricing => 'Narx';

  @override
  String get cMinutes => 'Davomiylik (daq.)';

  @override
  String get cActive => 'Sotuvda';

  @override
  String get cSaved => 'Saqlandi';

  @override
  String get cSlotCapacity => 'Har bir kelish vaqti uchun sig\'im';

  @override
  String get cUnlimited => 'Cheklovsiz';

  @override
  String get cFormula => 'Narx hisoblash formulasi';

  @override
  String get cTabCancelPolicy => 'Bekor qilish siyosati';

  @override
  String get cPolicyDefaultBanner =>
      'Bu standart sozlama. Ko‘rib chiqing va tasdiqlash uchun saqlang.';

  @override
  String get cPolicyDaysBefore => 'Tashrifdan necha kun oldin (dan)';

  @override
  String get cPolicyPercent =>
      'To‘lov % (bo‘sh = ilovada bekor qilib bo‘lmaydi)';

  @override
  String get cPolicyMinFee => 'Minimal to‘lov (KRW)';

  @override
  String get cPolicyReschedule =>
      'Qayta rejalashtirish mumkin (tashrifdan necha kun oldin)';

  @override
  String get cPolicyHint =>
      'Mijoz ilovasidagi bekor qilish ekranida darhol qo‘llanadi. Shartlar keyingi huquqiy buildda yangilanadi.';

  @override
  String get f_base_studio => 'Studiya asosiy narxi';

  @override
  String get f_base_one_and_half => '1.5 xona asosiy narxi';

  @override
  String get f_base_two_rooms => '2 xona asosiy narxi';

  @override
  String get f_base_three_rooms => '3 xona asosiy narxi';

  @override
  String get f_base_four_plus => '4+ xona asosiy narxi';

  @override
  String get f_per_extra_bathroom => 'Har qo\'shimcha hammom uchun';

  @override
  String get f_per_balcony => 'Har balkon uchun';

  @override
  String get f_duplex => 'Ikki qavatli';

  @override
  String get f_no_elevator_high_floor => 'Lift yo\'q + 3-qavat va undan yuqori';

  @override
  String get cIssueCoupon => 'Kupon berish';

  @override
  String get cCouponName => 'Kupon nomi';

  @override
  String get cCouponPhones => 'Telefon raqamlari (har qatorga bittadan)';

  @override
  String get cAllCustomers => 'Barcha mijozlarga';

  @override
  String cIssued(String n) {
    return '$n ta berildi';
  }

  @override
  String get cContent => 'Kontent';

  @override
  String get cKind_notice => 'E\'lon';

  @override
  String get cKind_tip => 'Maslahat';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Reklama';

  @override
  String get cKind_legal => 'Huquqiy';

  @override
  String get cNewContent => 'Yangi kontent';

  @override
  String get cTitleField => 'Sarlavha';

  @override
  String get cBodyField => 'Matn';

  @override
  String get cSlug => 'Identifikator (huquqiy: privacy / terms)';

  @override
  String get cVerify => 'Tasdiqlash';

  @override
  String get cSuspend => 'To\'xtatish';

  @override
  String get cPro_pending => 'Tasdiqlash kutilmoqda';

  @override
  String get cPro_verified => 'Faol';

  @override
  String get cPro_suspended => 'To\'xtatilgan';

  @override
  String get cCompleted => 'Bajarildi';

  @override
  String get cCancelledN => 'Bekor qilindi';

  @override
  String get cRating => 'Reyting';

  @override
  String get cFeeRate => 'Komissiya %';

  @override
  String get cRunPayouts => 'To\'lovlarni o\'tkazish';

  @override
  String get cPayoutDate => 'To\'lov sanasigacha';

  @override
  String cPayoutDone(String n) {
    return '$n ta hamkorga to\'lov amalga oshirildi';
  }

  @override
  String get cHold => 'Ushlab turish';

  @override
  String get cRelease => 'Ushlab turishni bekor qilish';

  @override
  String get cNet => 'To\'lov summasi';

  @override
  String get cAddStaff => 'Xodim qo\'shish';

  @override
  String get cRoleAdmin => 'Administrator';

  @override
  String get cRoleConsultant => 'Maslahatchi';

  @override
  String get cDeactivate => 'O\'chirib qo\'yish';

  @override
  String get cActivate => 'Faollashtirish';

  @override
  String get cPasswordRule => 'Kamida 12 ta belgi';

  @override
  String get cAdminOnly => 'Faqat administratorlar uchun';

  @override
  String cBookingsCount(String n) {
    return '$n ta bron';
  }

  @override
  String get cJoined => 'Qo\'shilgan';

  @override
  String get cNewBooking => 'Yangi bron keldi';

  @override
  String get cNewMessage => 'Yangi xabar';

  @override
  String get cConfirmAsk => 'Ishonchingiz komilmi?';

  @override
  String get ok => 'Tayyor';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get next => 'Keyingi';

  @override
  String get close => 'Yopish';

  @override
  String get save => 'Saqlash';

  @override
  String get delete => 'O\'chirish';

  @override
  String get edit => 'Tahrirlash';

  @override
  String get change => 'O\'zgartirish';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get yes => 'Ha';

  @override
  String get no => 'Yo\'q';

  @override
  String get required => 'Majburiy';

  @override
  String get viewAll => 'Hammasini ko\'rish';

  @override
  String get today => 'Bugun';

  @override
  String get errorGeneric =>
      'Xatolik yuz berdi. Iltimos, biroz keyin qayta urinib ko\'ring.';

  @override
  String get errorNetwork => 'Internet ulanishini tekshiring';

  @override
  String get err_invalid_phone => 'Telefon raqamini tekshiring';

  @override
  String get err_otp_invalid => 'Tasdiqlash kodi noto\'g\'ri';

  @override
  String get err_otp_expired =>
      'Tasdiqlash kodining muddati tugadi. Yangisini so\'rang.';

  @override
  String get err_rate_limited =>
      'Urinishlar juda ko\'p. Iltimos, keyinroq qayta urinib ko\'ring.';

  @override
  String get err_studio_too_large =>
      'Studiya tozalash faqat 10 pyeonggacha bo\'lgan uylar uchun';

  @override
  String get err_date_out_of_range =>
      'Ertadan boshlab 60 kun ichidagi sanani tanlang';

  @override
  String get err_slot_full => 'Bu vaqt band bo\'ldi. Boshqa vaqtni tanlang.';

  @override
  String get err_coupon_expired => 'Kupon muddati o\'tgan';

  @override
  String get err_coupon_used => 'Bu kupon allaqachon ishlatilgan';

  @override
  String get err_coupon_wrong_service =>
      'Bu kupon ushbu xizmat uchun amal qilmaydi';

  @override
  String get err_payment_failed =>
      'To\'lov tasdiqlanmadi. Boshqa to\'lov usulini tanlang.';

  @override
  String get err_payment_method_required => 'To\'lov usulini tanlang';

  @override
  String get err_cancellation_window_closed =>
      'Bu bronni ilovada bekor qilib bo‘lmaydi. Iltimos, jamoamizga murojaat qiling';

  @override
  String get err_address_required => 'Tashrif manzilini kiriting';

  @override
  String get err_already_taken =>
      'Boshqa hamkor buyurtmani birinchi bo\'lib qabul qildi';

  @override
  String get err_invalid_address => 'Manzil maydonlarini to\'liq to\'ldiring';

  @override
  String get tabHome => 'Bosh sahifa';

  @override
  String get tabBookings => 'Bronlar';

  @override
  String get tabChat => 'Suhbat';

  @override
  String get tabMore => 'Yana';

  @override
  String get introTitle => 'Mutaxassis tozalashini\neng oson bron qiling';

  @override
  String get introBody =>
      'Aniq narxlar · Tekshirilgan jamoalar · Jarayon real vaqtda';

  @override
  String get introStart => 'Telefon raqami bilan boshlash';

  @override
  String get loginPhoneTitle => 'Telefon raqamingizni kiriting';

  @override
  String get loginPhoneHint => '+998 90 000 00 00';

  @override
  String get loginSendCode => 'Kod olish';

  @override
  String get loginCodeTitle => '6 xonali kodni kiriting';

  @override
  String loginCodeSentTo(String phone) {
    return '$phone raqamiga yuborildi';
  }

  @override
  String get loginResend => 'Qayta yuborish';

  @override
  String get loginVerify => 'Tasdiqlash';

  @override
  String get loginTerms =>
      'Davom etish orqali Foydalanish shartlari va Maxfiylik siyosatiga rozilik bildirasiz';

  @override
  String get profileTitle => 'Ismingizni kiriting';

  @override
  String get profileNameHint => 'Ism';

  @override
  String get profileDone => 'Boshlash';

  @override
  String get welcomeToast => 'Xush kelibsiz uchun 2 ta kupon hamyoningizda';

  @override
  String get svc_studio => 'Studiya tozalash';

  @override
  String get svc_kitchen => 'Oshxona tozalash';

  @override
  String get svc_bathroom => 'Hammom tozalash';

  @override
  String get svc_mattress => 'Matras tozalash';

  @override
  String get svc_aircon => 'Konditsioner tozalash';

  @override
  String get svc_sofa => 'Divan tozalash';

  @override
  String get svc_move_out => 'Ko\'chib chiqish tozalashi';

  @override
  String get svc_move_in => 'Ko\'chib kirish tozalashi';

  @override
  String get svcShort_studio => 'Studiya';

  @override
  String get svcShort_kitchen => 'Oshxona';

  @override
  String get svcShort_bathroom => 'Hammom';

  @override
  String get svcShort_mattress => 'Matras';

  @override
  String get svcShort_aircon => 'Konditsioner';

  @override
  String get svcShort_sofa => 'Divan';

  @override
  String get svcShort_move_out => 'Chiqish';

  @override
  String get svcShort_move_in => 'Kirish';

  @override
  String get svcDesc_studio =>
      '10 pyeonggacha, 1 xona va 1 hammomli studiyani 2 soat davomida puxta tozalaymiz.';

  @override
  String get svcDesc_kitchen =>
      'Asosan lavabo, plita, vytyajka tashqi qismi va ish stollarini tozalaymiz.';

  @override
  String get svcDesc_bathroom =>
      'Javonlar, kranlar, lavabo va unitazning ichki va tashqi qismini tozalab, polni quritamiz.';

  @override
  String get svcDesc_mattress =>
      'Maxsus asbob bilan chang, kana va dog\'larni so\'rib olamiz, bug\' bilan zararsizlantiramiz.';

  @override
  String get svcDesc_aircon =>
      'Ajratib, issiqlik almashtirgich, ventilyator va filtrni bosim ostida yuvib, zararsizlantiramiz.';

  @override
  String get svcDesc_sofa =>
      'Matoga mos vosita bilan iflosliklarni parchalaymiz va nam ekstraksiya usulida yuvamiz.';

  @override
  String get svcDesc_move_out =>
      'Ko\'chib chiqishdan oldin bo\'sh uyni mutaxassis jamoa asbob-uskunalar bilan kelib tozalaydi.';

  @override
  String get svcDesc_move_in =>
      'Yangi uyga kirishdan oldin mutaxassis jamoa asbob-uskunalar bilan kelib ichki qismni tozalaydi.';

  @override
  String get svcNotes_bathroom =>
      'Drenaj yoki unitaz tiqilib qolgan bo\'lsa, xizmat cheklanishi mumkin\nMaxsus kimyoviy vositalarni talab qiladigan tozalash hamda shift va ventilyatorni tozalash ko\'rsatilmaydi\nEski zamburug\' va qotib qolgan kir butunlay ketmasligi mumkin';

  @override
  String get svcNotes_mattress =>
      'Yakkadan king o\'lchamigacha bir xil narx\nTo\'liq quruq bo\'lishi 4–6 soat davom etadi\nPrujina shikastlanishi yoki cho\'kish kabi konstruktiv nuqsonlar tuzatilmaydi';

  @override
  String get svcNotes_aircon =>
      '10 yildan eski modellarni ajratib yuvish qiyin bo\'lishi mumkin\nTashqi blok tozalanmaydi\nYuvishdan oldin va keyin ishlash holatini tekshiramiz';

  @override
  String get svcNotes_sofa =>
      'Charm divanlar tozalash va namlovchi qoplash bilan amalga oshiriladi\nEski dog\' va rang o\'tishi to\'liq ketmasligi mumkin\nTo\'liq quruq bo\'lishi 4–6 soat davom etadi';

  @override
  String get unitTitle_bathroom => 'Hammomlar soni';

  @override
  String get unitTitle_mattress => 'Matraslar soni';

  @override
  String get unitTitle_aircon => 'Konditsioner turi';

  @override
  String get unitTitle_sofa => 'Divan o\'lchami';

  @override
  String unit_count(String n) {
    return '$n ta';
  }

  @override
  String get unit_wall => 'Devorga osiladigan 1 ta';

  @override
  String get unit_stand => 'Polga qo\'yiladigan 1 ta';

  @override
  String get unit_two_in_one => '2 in 1 (polga + devorga)';

  @override
  String get unit_ceiling => 'Shiftga o\'rnatiladigan 1 ta';

  @override
  String get unit_seat_1_2 => '1–2 kishilik';

  @override
  String get unit_seat_3 => '3 kishilik';

  @override
  String get unit_seat_4_plus => '4 va undan ortiq kishilik';

  @override
  String get unit_l_shape => 'L-shakl · kushetka';

  @override
  String durH(String h) {
    return '$h soat';
  }

  @override
  String durHM(String h, String m) {
    return '$h soat $m daqiqa';
  }

  @override
  String durM(String m) {
    return '$m daqiqa';
  }

  @override
  String about(String value) {
    return 'taxminan $value';
  }

  @override
  String fromPrice(String price) {
    return '$price dan';
  }

  @override
  String get quoteBadge => 'Taklif';

  @override
  String get status0 => 'Maslahat jarayonida';

  @override
  String get status1 => 'Bron tasdiqlandi';

  @override
  String get status2 => 'Jamoa biriktirildi';

  @override
  String get status3 => 'Tozalash tugadi';

  @override
  String get statusCancelled => 'Bekor qilindi';

  @override
  String homeGreeting(String name) {
    return '$name, xush kelibsiz!\nBugun qaysi joyni tozalaymiz?';
  }

  @override
  String get homeGreetingAnon => 'Bugun qaysi joyni\ntozalaymiz?';

  @override
  String get homeUpcoming => 'Yaqinlashayotgan bronlar';

  @override
  String dDay(String days) {
    return '$days kun qoldi';
  }

  @override
  String get homeServices => 'Qanday tozalash kerak?';

  @override
  String get homeAddAddress =>
      'Manzilingizni qo\'shing — mavjud xizmatlar va narxlarni darhol ko\'rsatamiz';

  @override
  String get homeAddAddressCta => 'Manzil qo\'shish';

  @override
  String homeRebook(String service) {
    return '$service xizmatini qayta bron qilish';
  }

  @override
  String get homeRebookBody =>
      'Oldingi safardagi shartlar bilan tezda bron qiling';

  @override
  String get homeNotices => 'Yangiliklar';

  @override
  String get trustVat => 'QQS kiritilgan\nko\'rsatilgan narx aynan shu';

  @override
  String get trustCancel => 'Tashrifga 2 kun qolgunicha\nbepul bekor qilish';

  @override
  String get trustCard =>
      'Karta ma\'lumotlari\nfaqat to\'lov kompaniyasida saqlanadi';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'Sanani tanlang';

  @override
  String get notIncluded => 'Iltimos, buni tekshiring';

  @override
  String studioBlockedTitle(String size) {
    return '$size pyeong studiya tozalash uchun mos emas';
  }

  @override
  String get studioBlockedBody =>
      'Maslahat jamoamiz uyingizga mos xizmatni tavsiya qiladi.';

  @override
  String get consultCta => 'Maslahat so\'rash';

  @override
  String get addressTitle => 'Qayerga kelaylik?';

  @override
  String get addressAdd => 'Yangi manzil qo\'shish';

  @override
  String get addressLabel => 'Nomi';

  @override
  String get addressLabelHint => 'masalan: Uyim';

  @override
  String get addressDistrict => 'Tuman';

  @override
  String get addressRoad => 'Ko\'cha manzili';

  @override
  String get addressDetail => 'Uy / qavat / xonadon';

  @override
  String get addressSize => 'Uy maydoni (pyeong)';

  @override
  String get addressSizeHelp => 'Foydali maydon bo\'yicha · 1 pyeong ≈ 3,3 m²';

  @override
  String get addressHome => 'Uy';

  @override
  String get addressOffice => 'Ofis';

  @override
  String get addressEmpty => 'Saqlangan manzil yo\'q';

  @override
  String get addressSaved => 'Manzil saqlandi';

  @override
  String pyeong(String n) {
    return '$n pyeong';
  }

  @override
  String get scheduleTitle => 'Qachon kelaylik?';

  @override
  String get scheduleArrival => 'Kelish vaqti';

  @override
  String get scheduleFull => 'Band';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end oralig\'ida keladi';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · taxminan $time da tugaydi';
  }

  @override
  String get scheduleRange =>
      'Ertadan boshlab 60 kun ichida bron qilishingiz mumkin';

  @override
  String get morning => 'Ertalab';

  @override
  String get afternoon => 'Tushdan keyin';

  @override
  String get scheduleQuoteNote => 'Aniq kelish vaqtini maslahatda aytamiz';

  @override
  String get goToPayment => 'To\'lovga o\'tish';

  @override
  String get prepTitle => 'Tashrifdan oldin tayyorlang';

  @override
  String get prepBody =>
      'Bular tayyor bo\'lmasa, ayrim ishlar cheklanishi mumkin';

  @override
  String get prepAsk => 'Tayyorlab bo\'lmasa, maslahatda oldindan xabar bering';

  @override
  String get tool_vacuum => 'Changyutgich';

  @override
  String get tool_trash => 'Chiqindi xaltalari';

  @override
  String get tool_mop => 'Shvabra';

  @override
  String get tool_cloth => 'Latta';

  @override
  String get tool_gloves => 'Rezina qo\'lqop';

  @override
  String get tool_sponge => 'Mochalka';

  @override
  String get tool_spray => 'Universal vosita';

  @override
  String get checkoutTitle => 'To\'lov';

  @override
  String get coupon => 'Kupon';

  @override
  String get couponNone => 'Ishlatilmaydi';

  @override
  String couponAvailable(String count) {
    return '$count ta mavjud';
  }

  @override
  String get paymentMethod => 'To\'lov usuli';

  @override
  String get addPaymentMethod => 'To\'lov usulini qo\'shish';

  @override
  String get methodCard => 'Kredit / debet karta';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'NaverPay';

  @override
  String get methodToss => 'TossPay';

  @override
  String get methodRegistered => 'Qo\'shilgan';

  @override
  String get methodAdded => 'To\'lov usuli qo\'shildi';

  @override
  String get listPrice => 'Xizmat narxi';

  @override
  String get discount => 'Kupon chegirmasi';

  @override
  String get total => 'Jami to\'lov';

  @override
  String get vatIncluded => 'QQS kiritilgan';

  @override
  String payAmount(String amount) {
    return '$amount to\'lash';
  }

  @override
  String get needMethod => 'Avval to\'lov usulini qo\'shing';

  @override
  String freeCancelUntil(String date) {
    return '$date gacha bepul bekor qilish';
  }

  @override
  String get doneTitle => 'Bron qilindi!';

  @override
  String get doneBody => 'Jamoa biriktirilishi bilanoq sizga xabar beramiz';

  @override
  String get doneQuoteTitle => 'So\'rov qabul qilindi';

  @override
  String get doneQuoteBody =>
      'Jamoamiz tekshirib, yakuniy narxni yuboradi. Narxni Chat bo\'limida ko\'rishingiz mumkin.';

  @override
  String get goHome => 'Bosh sahifaga';

  @override
  String get viewBooking => 'Bronni ko\'rish';

  @override
  String get bookingsTitle => 'Bronlar';

  @override
  String get bookingsUpcoming => 'Yaqinlashayotgan';

  @override
  String get bookingsPast => 'O\'tgan';

  @override
  String get bookingsEmpty => 'Hali bronlar yo\'q';

  @override
  String get bookingsEmptyBody => 'Birinchi bron uchun kuponlar tayyor';

  @override
  String get bookNow => 'Tozalashga bron qilish';

  @override
  String get detailTitle => 'Bron tafsilotlari';

  @override
  String get stepRequested => 'So\'rov qabul qilindi';

  @override
  String get stepConfirmed => 'Bron tasdiqlandi';

  @override
  String get stepAssigned => 'Jamoa biriktirildi';

  @override
  String get stepCompleted => 'Tozalash tugadi';

  @override
  String teamVisiting(String team) {
    return '$team tashrif buyuradi';
  }

  @override
  String get photosSoon => 'Tugagach, oldin-keyin suratlar shu yerda chiqadi';

  @override
  String photoThumb(String n) {
    return 'Foto $n';
  }

  @override
  String get before => 'Oldin';

  @override
  String get after => 'Keyin';

  @override
  String get prepCheck => 'Tayyorgarlik ro\'yxati';

  @override
  String get prepAllSet => 'Hammasi tayyor';

  @override
  String get visitAddress => 'Manzil';

  @override
  String get paid => 'To\'langan';

  @override
  String get askTeam => 'Jamoaga savol berish';

  @override
  String get cancelBooking => 'Bronni bekor qilish';

  @override
  String get cancelTitle => 'Bu bronni bekor qilasizmi?';

  @override
  String get cancelFree =>
      'Hozir bekor qilsangiz, to\'lovning to\'liq summasi va kuponingiz qaytariladi.';

  @override
  String get cancelKeep => 'Qoldirish';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Hozir bekor qilsangiz $fee to‘lov olinadi va $refund qaytariladi.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return '$fee to‘lovga rozi bo‘lib bekor qilish';
  }

  @override
  String get cancelled => 'Bron bekor qilindi';

  @override
  String get reschedule => 'Vaqtni o\'zgartirish';

  @override
  String get rescheduled => 'Vaqt o\'zgartirildi';

  @override
  String get visitNotes => 'Jamoa uchun izohlar';

  @override
  String get notesEntry => 'Kirish usuli (kod va hokazo)';

  @override
  String get notesParking => 'Avtoturargoh';

  @override
  String get notesOther => 'Boshqa';

  @override
  String get notesSaved => 'Izohlar saqlandi';

  @override
  String depositDue(String amount) {
    return '$amount depozitni to\'lasangiz, bron tasdiqlanadi';
  }

  @override
  String get payDeposit => 'Depozit to\'lash';

  @override
  String get waitingQuote => 'Jamoamiz narxni tayyorlamoqda';

  @override
  String get estimate => 'Taxminiy summa';

  @override
  String get finalPrice => 'Yakuniy narx';

  @override
  String get deposit => 'Depozit';

  @override
  String get balance => 'Qoldiq';

  @override
  String balanceDue(String amount) {
    return '$amount qoldiqni to\'lang';
  }

  @override
  String get payBalance => 'Qoldiqni to\'lash';

  @override
  String get reviewTitle => 'Tozalash qanday o\'tdi?';

  @override
  String get reviewHint => 'Yaxshi tomonlari yoki kamchiliklarini yozing';

  @override
  String ratingStars(String n) {
    return '$n ball';
  }

  @override
  String get reviewSubmit => 'Sharh qoldirish';

  @override
  String get reviewThanks => 'Sharhingiz uchun rahmat';

  @override
  String get bookAgain => 'Xuddi shunday qayta bron qilish';

  @override
  String get chatTitle => 'Suhbat';

  @override
  String get chatTeam => 'Qo\'llab-quvvatlash jamoasi';

  @override
  String get chatHours => 'Ish kunlari 09:00–18:00';

  @override
  String get chatEmpty => 'Savollaringiz bo\'lsa, istalgan vaqtda yozing';

  @override
  String get chatNew => 'Yangi suhbat';

  @override
  String get chatTopicTitle => 'Nima haqida?';

  @override
  String get topicOther => 'Boshqa savol';

  @override
  String get chatHint => 'Xabar yozing';

  @override
  String get chatSend => 'Yuborish';

  @override
  String get chatPhoto => 'Rasm yuborish';

  @override
  String get chatTyping => 'Jamoa yozmoqda…';

  @override
  String get quick_confirm => 'Bronni tasdiqlaymiz';

  @override
  String get quick_price => 'Narx haqida savol';

  @override
  String get quick_date => 'Sanani o\'zgartirmoqchiman';

  @override
  String get quick_parking => 'Avtoturargoh bormi?';

  @override
  String get quick_hello => 'Salom';

  @override
  String get quick_duration => 'Qancha vaqt oladi?';

  @override
  String get quoteArrived => 'Yakuniy narx keldi';

  @override
  String get quoteDepositNow => 'Hozir depozit: 10%';

  @override
  String get quoteBalanceLater => 'Ishdan keyin qoldiq';

  @override
  String get quotePay => 'Depozit to\'lab tasdiqlash';

  @override
  String get quotePaid => 'To\'landi';

  @override
  String get requestCard => 'Narx so\'rovi';

  @override
  String get sys_consultation_received => 'Maslahat so\'rovingiz qabul qilindi';

  @override
  String sys_deposit_paid(String amount) {
    return '$amount depozit to\'landi. Bron tasdiqlandi.';
  }

  @override
  String get sys_booking_cancelled => 'Bron bekor qilindi';

  @override
  String sys_status_changed(String status) {
    return 'Bron holati \'$status\' ga o\'zgardi';
  }

  @override
  String get sys_job_completed =>
      'Tozalash tugadi. Oldin-keyin suratlarni ko\'ring.';

  @override
  String sys_rescheduled(String date) {
    return 'Vaqt $date ga o\'zgartirildi';
  }

  @override
  String get sys_reschedule_declined =>
      'Hamkor yangi vaqtda kela olmaydi. Jamoamiz qayta kelishib oladi.';

  @override
  String get moreTitle => 'Yana';

  @override
  String get moreScope => 'Xizmat doirasi';

  @override
  String get morePayments => 'To\'lov usullari';

  @override
  String get moreCoupons => 'Kuponlar';

  @override
  String get morePoints => 'Tozalash ballari';

  @override
  String get moreAccount => 'Hisob ma\'lumotlari';

  @override
  String get moreAddresses => 'Manzillar';

  @override
  String get moreNotices => 'E\'lonlar';

  @override
  String get moreTips => 'Tozalash maslahatlari';

  @override
  String get moreFaq => 'Ko\'p so\'raladigan savollar';

  @override
  String get morePartner => 'Hamkor bo\'lish';

  @override
  String get moreLanguage => 'Til';

  @override
  String get langSystem => 'Qurilma sozlamasiga ko\'ra';

  @override
  String moreVersion(String v) {
    return 'Versiya $v';
  }

  @override
  String get morePrivacy => 'Maxfiylik siyosati';

  @override
  String get moreTerms => 'Foydalanish shartlari';

  @override
  String get moreLicenses => 'Ochiq manba litsenziyalari';

  @override
  String get logout => 'Chiqish';

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get deleteAccountBody =>
      'Shaxsiy ma\'lumotlaringiz o\'chiriladi va buni qaytarib bo\'lmaydi. Avval faol bronlarni bekor qiling.';

  @override
  String get couponsEmpty => 'Kuponlaringiz yo\'q';

  @override
  String couponUntil(String date) {
    return '$date gacha';
  }

  @override
  String get couponUsed => 'Ishlatilgan';

  @override
  String get couponExpired => 'Muddati tugagan';

  @override
  String get couponAnyService => 'Barcha xizmatlar';

  @override
  String get coupon_welcome_studio => 'Xush kelibsiz: studiya kuponi';

  @override
  String get coupon_welcome_any => 'Xush kelibsiz kuponi';

  @override
  String get pointsBalance => 'Ballaringiz';

  @override
  String get pointsEmpty => 'Ballar tarixi yo\'q';

  @override
  String get accountName => 'Ism';

  @override
  String get accountPhone => 'Telefon';

  @override
  String get accountEmail => 'Elektron pochta';

  @override
  String get accountLogin => 'Kirish usuli';

  @override
  String get accountLoginPhone => 'Telefon orqali tasdiqlash';

  @override
  String get methodsEmpty => 'To\'lov usullari yo\'q';

  @override
  String get noContent => 'Hali bu yerda ma\'lumot yo\'q';

  @override
  String get quoteTypeTitle => 'Qanday tozalash kerak?';

  @override
  String get type_standard => 'Chiqishda tozalash';

  @override
  String get type_same_day_move => 'Ko\'chish kuni tozalash';

  @override
  String get type_some_luggage_left => 'Ba\'zi buyumlar qolgan';

  @override
  String get type_normal_move_in => 'Oddiy kirish';

  @override
  String get type_after_interior => 'Remontdan keyin';

  @override
  String get type_lived_in_deep_clean => 'Yashab turgan uyni chuqur tozalash';

  @override
  String get luggageTitle => 'Uyda buyumlar qanday?';

  @override
  String get luggage_empty => 'Buyum yo\'q';

  @override
  String get luggage_partly_unpacked => 'Qisman joylashtirilgan';

  @override
  String get luggage_fully_lived_in => 'Yashab turilgan';

  @override
  String get luggage_unknown => 'Bilmayman';

  @override
  String get quoteBasicTitle => 'Uy tuzilishini ayting';

  @override
  String get buildingType => 'Bino turi';

  @override
  String get building_apartment => 'Kvartira';

  @override
  String get building_villa => 'Villa / kam qavatli';

  @override
  String get building_officetel => 'Ofistel';

  @override
  String get building_house => 'Xususiy uy';

  @override
  String get building_other => 'Boshqa';

  @override
  String get layoutTitle => 'Planirovka';

  @override
  String get layout_studio => 'Studiya';

  @override
  String get layout_one_and_half => '1.5 xona';

  @override
  String get layout_two_rooms => '2 xona';

  @override
  String get layout_three_rooms => '3 xona';

  @override
  String get layout_four_plus => '4 va undan ortiq xona';

  @override
  String get duplexTitle => 'Ikki qavatlimi?';

  @override
  String get quoteSpaceTitle => 'Joy haqida ma\'lumot bering';

  @override
  String get bathroomsLabel => 'Hammom';

  @override
  String get balconiesLabel => 'Balkon · xo\'jalik xonasi';

  @override
  String get elevatorTitle => 'Lift bormi?';

  @override
  String get floor3Label => '3-qavat va undan yuqori';

  @override
  String get quoteEstimateTitle => 'Taxminiy narx';

  @override
  String get quoteEstimateBody =>
      'Yakuniy summa suratlar va vaziyat ko\'rib chiqilgach, maslahatda belgilanadi';

  @override
  String get quoteG1 => 'Yakuniy summa maslahatda kelishiladi';

  @override
  String get quoteG2 => 'Tasdiqlash uchun 10% depozit, qolgani ishdan keyin';

  @override
  String get quoteG3 =>
      'Tasdiqlashdan oldin istalgan vaqtda bepul bekor qilish';

  @override
  String get quoteConfirmTitle => 'So\'rovingizni tekshiring';

  @override
  String get quoteRequest => 'Maslahat so\'rash';

  @override
  String get quoteNoPayNow => 'Hozir to\'lov yo\'q';

  @override
  String get summaryType => 'Tozalash turi';

  @override
  String get summaryHome => 'Uy ma\'lumoti';

  @override
  String get summaryDate => 'Tashrif';

  @override
  String get cpTitle => 'Bekor qilish siyosati';

  @override
  String cpWhen(String days) {
    return 'Tashrifdan $days kun yoki undan oldin';
  }

  @override
  String get cpWhenSameDay => 'Tashrif kuni';

  @override
  String get cpFree => 'To‘liq qaytarish';

  @override
  String cpFee(String percent, String fee, String refund) {
    return '$percent% to‘lov ($fee), qaytarish $refund';
  }

  @override
  String get cpClosed => 'Ilovada bekor qilib bo‘lmaydi (jamoa ko‘rib chiqadi)';

  @override
  String get hhTitle => 'Uy ma’lumotlari';

  @override
  String get hhAddPet => 'Uy hayvonini qo‘shish';

  @override
  String get hhPetCount => 'Soni';

  @override
  String get hhFloorLabel => 'Qavat (yerto‘la uchun manfiy)';

  @override
  String get hhElevator => 'Lift bor';

  @override
  String get hhNotes => 'Eslatma';

  @override
  String get hhHint =>
      'Ushbu manzilga saqlanadi va har bir buyurtmada o‘zgartirish mumkin.';

  @override
  String get themeTitle => 'Mavzu';

  @override
  String get themeDark => 'Tungi';

  @override
  String get themeLight => 'Kunduzgi';

  @override
  String get themeSystem => 'Tizim';

  @override
  String get themeTip => 'Mavzuni o\'zgartirish';

  @override
  String get err_price_changed =>
      'Narx o‘zgardi. Yangi taklifni ko‘rib, qayta urinib ko‘ring.';

  @override
  String get err_checkout_closed => 'Bu to‘lov yopilgan. Qaytadan boshlang.';

  @override
  String get err_checkout_refunded =>
      'Bu to‘lov bekor qilingan va pul qaytarilgan.';

  @override
  String get err_already_paid => 'Bu to‘lov allaqachon to‘langan.';

  @override
  String get err_quote_not_payable =>
      'Bu taklif hozircha to‘lanmaydi. Jamoamiz bilan bog‘laning.';

  @override
  String get err_payment_method_disabled =>
      'Bu to‘lov usuli hozircha mavjud emas.';

  @override
  String get err_invalid_payment_method =>
      'Tanlangan to‘lov usulidan foydalanib bo‘lmaydi. Boshqasini tanlang.';

  @override
  String get err_balance_not_due => 'Qoldiq to‘lov hali muddati kelmagan.';

  @override
  String get err_invalid_slot => 'Bu xizmat uchun tanlangan vaqt mavjud emas.';

  @override
  String get err_booking_changed =>
      'Buyurtma o‘zgargan. Yangilab, tafsilotlarni tekshiring.';

  @override
  String get err_booking_closed => 'Bu buyurtmani endi o‘zgartirib bo‘lmaydi.';

  @override
  String get err_reschedule_closed =>
      'Hozir tashrif sanasini o‘zgartirib bo‘lmaydi. Jamoamiz bilan bog‘laning.';

  @override
  String get err_too_many_open_requests =>
      'Ochiq so‘rovlar juda ko‘p. Avval bittasini yakunlang.';

  @override
  String get err_already_reviewed =>
      'Siz bu tashrif uchun allaqachon sharh qoldirgansiz.';

  @override
  String get err_identity_not_verified =>
      'Avval shaxsni tasdiqlashni yakunlang.';

  @override
  String get err_email_taken => 'Bu elektron pochta allaqachon band.';

  @override
  String get err_invalid_email => 'Elektron pochta manzilini tekshiring.';

  @override
  String get err_file_too_large => 'Fayl juda katta. Kichikroq fayl yuklang.';

  @override
  String get err_unsupported_image =>
      'Bu rasm formati qo‘llab-quvvatlanmaydi. JPG yoki PNG yuklang.';

  @override
  String get err_upload_quota =>
      'Bugungi yuklash limiti tugadi. Ertaga qayta urining.';

  @override
  String get err_provider_unreachable =>
      'Xizmatga ulanib bo‘lmadi. Biroz keyin qayta urinib ko‘ring.';

  @override
  String get err_invalid_token =>
      'Kirish amalga oshmadi. Qayta urinib ko‘ring.';

  @override
  String get err_invalid_transition =>
      'Holatni hozir bunday o‘zgartirib bo‘lmaydi.';

  @override
  String get err_job_not_started => 'Avval ishni boshlang.';

  @override
  String get err_job_not_active => 'Bu ish faol emas.';

  @override
  String get err_quote_locked => 'Taklif qulflangan, tahrirlab bo‘lmaydi.';

  @override
  String get err_request_closed => 'Bu so‘rov yopilgan.';

  @override
  String get err_team_full => 'Jamoa to‘lgan.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret whsec_ bilan boshlanishi kerak.';

  @override
  String get err_invalid_endpoint =>
      'Endpoint https:// bilan boshlanishi kerak.';

  @override
  String get err_invalid_bucket => 'Bucket nomi noto‘g‘ri.';

  @override
  String get err_invalid_region => 'Hudud noto‘g‘ri.';

  @override
  String get err_invalid_retention =>
      'Saqlash muddati ruxsat etilgan chegaradan tashqarida.';

  @override
  String get err_invalid_service_account => 'Service account fayli noto‘g‘ri.';

  @override
  String get err_invalid_mode => 'To‘g‘ri AI rejimini tanlang.';

  @override
  String get err_invalid_model => 'AI model nomi noto‘g‘ri.';

  @override
  String get err_missing_field => 'Barcha majburiy maydonlarni to‘ldiring.';

  @override
  String get err_invalid_amount => 'To‘g‘ri summani kiriting.';

  @override
  String get err_cannot_deactivate_self =>
      'O‘z hisobingizni o‘chirib bo‘lmaydi.';

  @override
  String get err_invalid_coupon => 'Bu kupon yaroqsiz.';

  @override
  String get err_settlement_state =>
      'Hisob-kitobni hozir o‘zgartirib bo‘lmaydi.';

  @override
  String get err_deposit_required => 'Avval depozit to‘lanishi kerak.';

  @override
  String get err_payout_state =>
      'To‘lov holati o‘zgardi. Yangilab, qayta tekshiring.';

  @override
  String get err_payout_provider => 'Bu to‘lov usuli hozircha mavjud emas.';

  @override
  String get err_unsupported_bank =>
      'Bu bank to‘lovlar uchun qo‘llab-quvvatlanmaydi.';

  @override
  String get err_toss_unverified =>
      'Toss to‘lovlari hozircha mavjud emas. Qo‘lda o‘tkazmadan foydalaning.';

  @override
  String get err_invalid_cap => 'Ruxsat etilgan oraliqdagi sonni kiriting.';

  @override
  String get err_invalid_capacity => 'To‘g‘ri sig‘imni kiriting.';

  @override
  String get err_seller_declined =>
      'Toss sotuvchini ro‘yxatdan o‘tkazishni tasdiqlamadi. Biznes ma’lumotlarini tekshiring.';

  @override
  String get err_payout_account_unverified =>
      'Bu hamkorda hali tasdiqlangan to‘lov hisobi yo‘q. Avval hisobni tasdiqlang.';

  @override
  String get fFinance => 'Moliya';

  @override
  String get fPeriodDay => 'Kun';

  @override
  String get fPeriodWeek => 'Hafta';

  @override
  String get fPeriodMonth => 'Oy';

  @override
  String get fPeriodCustom => 'Boshqa';

  @override
  String get fFrom => 'Boshlanishi';

  @override
  String get fTo => 'Tugashi';

  @override
  String get fGross => 'Jami to\'lovlar';

  @override
  String get fRefunds => 'Qaytarishlar';

  @override
  String get fNetRevenue => 'Sof daromad';

  @override
  String get fPlatformFee => 'Platforma komissiyasi';

  @override
  String get fPaidOut => 'Hamkorlarga to\'langan';

  @override
  String get fPendingOut => 'To\'lash kutilmoqda';

  @override
  String get fHeldOut => 'Ushlab qolingan';

  @override
  String get fVatEstimate => 'QQS (taxminiy)';

  @override
  String get fVatNote =>
      'Platforma komissiyasining 10% asosida taxminiy. Buxgalter bilan tekshiring.';

  @override
  String get fAov => 'O\'rtacha buyurtma';

  @override
  String get fBookings => 'Buyurtmalar';

  @override
  String get fCancelRate => 'Bekor qilish foizi';

  @override
  String get fDiscounts => 'Chegirma va kuponlar';

  @override
  String get fMethods => 'To\'lov usullari';

  @override
  String get fTrend => 'Tendensiya';

  @override
  String fRangeDays(String n) {
    return 'So\'nggi $n kun';
  }

  @override
  String get fRangeWeeks => 'So\'nggi 12 hafta';

  @override
  String get fRangeMonths => 'So\'nggi 12 oy';

  @override
  String get fByPartner => 'Hamkorlar bo\'yicha daromad';

  @override
  String get fByService => 'Xizmat bo\'yicha daromad';

  @override
  String get fExportTitle => 'Buxgalteriya eksporti';

  @override
  String get fExportLedger => 'To\'lovlar jurnali CSV';

  @override
  String get fExportSettlements => 'Hisob-kitoblar CSV';

  @override
  String get fExportMonthly => 'Oylik xulosa CSV (buxgalter)';

  @override
  String get fDownload => 'CSV yuklab olish';

  @override
  String get fDownloadWebOnly => 'CSV faqat veb konsolda yuklanadi';

  @override
  String get fDownloadFailed => 'Yuklab bo\'lmadi';

  @override
  String get fNoRecords => 'Bu davrda yozuv yo\'q';

  @override
  String get fLoadFailed => 'Moliya ma\'lumotlarini yuklab bo\'lmadi';

  @override
  String get fRetry => 'Qayta urinish';

  @override
  String get fColPartner => 'Hamkor';

  @override
  String get fColJobs => 'Soni';

  @override
  String get fColSettled => 'Jami hisob-kitob';

  @override
  String get fColFee => 'Komissiya';

  @override
  String get fColNet => 'Sof';

  @override
  String get pEarnings => 'Daromad';

  @override
  String get pNextPayout => 'Keyingi to\'lov';

  @override
  String pNextPayoutOn(String date) {
    return '$date sanasida to\'lanadi';
  }

  @override
  String get pNoPayout => 'Rejalashtirilgan to\'lov yo\'q';

  @override
  String get pPendingTotal => 'To\'lash kutilmoqda';

  @override
  String get pPaidTotal => 'To\'langan';

  @override
  String get pWeekly => 'Haftalik';

  @override
  String get pMonthly => 'Oylik';

  @override
  String proofHomes(String count) {
    return 'Shu oy $count ta uy tozalandi';
  }

  @override
  String proofRating(String rating, String count) {
    return 'O‘rtacha $rating yulduz · $count ta sharh';
  }

  @override
  String get proofReviewsTitle => 'So‘nggi sharhlar';

  @override
  String get rebookTitle => 'Oxirgi xizmatni qayta bronlaysizmi?';

  @override
  String rebookBody(String service, String date) {
    return '$service · oxirgi tashrif $date';
  }

  @override
  String get rebookButton => 'Qayta bron qilish';

  @override
  String seatsLeft(String count) {
    return '$count ta joy qoldi';
  }

  @override
  String get reviewSheetTitle => 'Tozalash qanday o‘tdi?';

  @override
  String get reviewPhotosAdd => 'Surat qo‘shish';

  @override
  String get reviewPhotosHint => 'Eng ko‘pi 5 ta surat';

  @override
  String get reviewSaved => 'Sharhingiz uchun rahmat';

  @override
  String get reviewPhotoFailed =>
      'Suratni yuklab bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get referralTitle => 'Do‘stni taklif qiling, kupon oling';

  @override
  String referralBody(String amount) {
    return 'Do‘stingiz birinchi buyurtmasini yakunlasa, ikkingiz ham $amount kupon olasiz';
  }

  @override
  String get referralCopy => 'Kodni nusxalash';

  @override
  String get referralCopied => 'Taklif kodi nusxalandi';

  @override
  String get referralClaimTitle => 'Taklif kodingiz bormi?';

  @override
  String get referralClaimField => 'Taklif kodini kiriting';

  @override
  String get referralClaimButton => 'Qo‘llash';

  @override
  String get referralClaimed => 'Taklif kodi qo‘llandi';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited ta taklif · $rewarded ta mukofot';
  }

  @override
  String get err_self_referral =>
      'O‘zingizning kodingizdan foydalanib bo‘lmaydi';

  @override
  String get err_referee_already_booked =>
      'Kodni faqat birinchi buyurtmadan oldin kiritish mumkin';

  @override
  String get err_already_referred => 'Taklif kodi allaqachon qo‘llangan';

  @override
  String get err_invalid_referral_code => 'Taklif kodini tekshiring';

  @override
  String get err_referral_disabled => 'Hozircha taklif dasturi to‘xtatilgan';

  @override
  String get err_invalid_photos =>
      'Faqat Malkkeum orqali yuklangan suratlarni biriktirish mumkin';

  @override
  String get welcomeOfferTitle => 'Birinchi buyurtma chegirmasi';

  @override
  String get welcomeOfferBody =>
      'Yangi mijozning birinchi buyurtmasiga avtomatik qo‘llanadi. Kupon bilan birga ishlamaydi.';

  @override
  String get offerKindAmount => 'Belgilangan (so‘m)';

  @override
  String get offerKindPercent => 'Foiz (%)';

  @override
  String get offerValue => 'Chegirma qiymati';

  @override
  String get offerEnabled => 'Yoqish';

  @override
  String get offerSaved => 'Saqlandi';

  @override
  String get referralSettingsTitle => 'Taklif mukofoti';

  @override
  String get referralSettingsBody =>
      'Do‘stning birinchi buyurtmasi yakunlanib, to‘lov qilingach beriladi. O‘z-o‘zini taklif qilish va bir xil raqam bloklanadi.';

  @override
  String get referralRewardAmount => 'Mukofot miqdori (so‘m)';

  @override
  String get reviewsModerationTitle => 'Sharhlarni boshqarish';

  @override
  String get reviewHide => 'Yashirish';

  @override
  String get reviewShow => 'Qayta ko‘rsatish';

  @override
  String get reviewHiddenTag => 'Yashirilgan';

  @override
  String get growthAverageRating => 'O‘rtacha reyting';

  @override
  String growthReviewCount(String count) {
    return '$count ta sharh';
  }

  @override
  String get growthReferralConversion => 'Taklif konversiyasi';

  @override
  String get growthTab => 'O‘sish';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$invited tadan $rewarded';
  }

  @override
  String get uMaintenanceTitle => 'Texnik xizmat ko\'rsatilmoqda';

  @override
  String get uMaintenanceBody =>
      'Xizmatni yaxshilash uchun texnik ishlar olib borilmoqda. Iltimos, keyinroq qayta urinib ko\'ring.';

  @override
  String get cOps => 'Tizim holati';

  @override
  String get oLevelGreen => 'Yaxshi';

  @override
  String get oLevelYellow => 'Tekshiring';

  @override
  String get oLevelRed => 'Harakat kerak';

  @override
  String get oOverall => 'Server holati';

  @override
  String get oRefresh => 'Yangilash';

  @override
  String get oVersion => 'Versiya';

  @override
  String get oUptime => 'Ishlash vaqti';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours soat $minutes daqiqa';
  }

  @override
  String get oChecks => 'Tekshiruvlar';

  @override
  String get oCheckDb => 'Ma’lumotlar bazasi';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Javob $ms ms · hajmi $mb MB';
  }

  @override
  String get oCheckDisk => 'Server diski';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% bo‘sh';
  }

  @override
  String get oCheckBackup => 'Avtomatik zaxira';

  @override
  String oCheckBackupValue(String hours) {
    return 'Oxirgi zaxira $hours soat oldin';
  }

  @override
  String get oCheckBackupNone => 'Hali zaxira yo‘q';

  @override
  String get oCheckErrors => 'Server xatolari (24 soat)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Tekshirilishi kerak bo‘lgan to‘lovlar';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 soat)';
  }

  @override
  String get oCheckWebhook => 'To‘lov bildirishnomalari (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Imzo xatosi $count (24 soat)';
  }

  @override
  String get oIntegrations => 'Tashqi xizmatlar';

  @override
  String get oIntNotSet => 'Sozlanmagan';

  @override
  String oIntLastOk(String at) {
    return 'Oxirgi muvaffaqiyat $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Oxirgi xato $at ($code)';
  }

  @override
  String get oIntNever => 'Hali foydalanilmagan';

  @override
  String get oActDb =>
      'Ma’lumotlar bazasiga ulanib bo‘lmadi. Serverda malkkeum logs ni ishga tushiring; davom etsa qayta ishga tushiring.';

  @override
  String get oActDisk =>
      'Diskda bo‘sh joy 10% dan kam. Eski zaxiralarni o‘chiring yoki diskni kengaytiring.';

  @override
  String get oActBackup =>
      'Avtomatik zaxira kechikdi. Serverda malkkeum backup ni ishga tushiring va backups/backup.log ni tekshiring.';

  @override
  String get oActErrors =>
      'Server xatolari ko‘p. malkkeum logs dagi error qatorlarini ko‘ring; takrorlansa dasturchiga yuboring.';

  @override
  String get oActPayments =>
      'To‘lov o‘tgan bo‘lishi mumkin, lekin avtomatik qayta ishlanmagan. PortOne da tekshiring va kerak bo‘lsa qo‘lda qaytaring.';

  @override
  String get oActWebhook =>
      'To‘lov bildirishnomasi imzosini tekshirish xato. Sozlash > To‘lov (PortOne) da webhook secret ni qayta kiriting.';

  @override
  String get oActIntegration =>
      'Bu ulanish ishlamayapti. Sozlashdagi kalitlarni tekshirib, Test connection ni bosing.';

  @override
  String get oActNotSet => 'Hali sozlanmagan. Sozlashda kalitlarni kiriting.';

  @override
  String get oAlerts => 'Ogohlantirish sozlamalari';

  @override
  String get oAlertsHint =>
      'Muammolar kiruvchi xabarlar va egasining telefoniga SMS orqali yuboriladi. Bir xil muammo 6 soatda bir marta yuboriladi.';

  @override
  String get oRuleSms => 'SMS yuborish xato';

  @override
  String get oRulePush => 'Push bildirishnomalar xato';

  @override
  String get oRulePayment => 'To‘lov ulanishi xato';

  @override
  String get oRuleStuck => 'To‘lov avtomatik qayta ishlanmadi';

  @override
  String get oRuleSocial => 'Ijtimoiy tarmoq orqali kirish xato';

  @override
  String get oRuleBackup => 'Avtomatik zaxira o‘tkazib yuborildi';

  @override
  String get oRuleDisk => 'Disk deyarli to‘lgan';

  @override
  String get oQuietHours => 'Jim soatlar';

  @override
  String get oQuietFrom => 'Dan';

  @override
  String get oQuietTo => 'Gacha';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'Shu soatlarda bildirishnoma yuborilmaydi; tugagach bitta xabar keladi.';

  @override
  String get oAlertPhone => 'Ogohlantirish telefoni';

  @override
  String get oAlertPhoneHint =>
      'Bo‘sh qoldirsangiz biznes ma’lumotidagi yordam raqamiga yuboriladi.';

  @override
  String get oSave => 'Saqlash';

  @override
  String get oSaved => 'Ogohlantirish sozlamalari saqlandi';

  @override
  String get oSaveFailed =>
      'Saqlab bo‘lmadi. Kiritilgan qiymatlarni tekshiring.';

  @override
  String get oLoadFailed => 'Holatni yuklab bo‘lmadi';

  @override
  String get oBackupOffsite => 'Tashqi zaxira (S3)';

  @override
  String get oBackupOffsiteOff =>
      'O‘chirilgan. Sozlash > Tashqi zaxirada yoqing.';

  @override
  String get oLastBackup => 'Oxirgi zaxira';

  @override
  String get oDiskFree => 'Bo‘sh joy';

  @override
  String get oNoData => 'Hali ma’lumot yo‘q';

  @override
  String get cIntBackup => 'Tashqi zaxira (S3 mos)';

  @override
  String get pTabJobs => 'Ishlar';

  @override
  String get pTabQuotes => 'Mening takliflarim';

  @override
  String get pTabSchedule => 'Jadval';

  @override
  String get pIntroTitle =>
      'Tozalash mutaxassislari uchun\nishlar · jadval · to\'lovlar';

  @override
  String get pIntroBody =>
      'Xohlagan hudud va vaqtda ishlang, har hafta to\'lov oling';

  @override
  String get pOnbTitle => 'Hamkor ma\'lumotlarini kiriting';

  @override
  String get pOnbName => 'Rahbar ismi';

  @override
  String get pOnbTeam => 'Jamoa nomi';

  @override
  String get pOnbServices => 'Ko\'rsatadigan xizmatlar';

  @override
  String get pOnbAreas => 'Ish hududi';

  @override
  String get pOnbDone => 'Ariza topshirish';

  @override
  String get pPendingTitle => 'Tasdiqlanishini kutmoqda';

  @override
  String get pPendingBody =>
      'Operatsiya jamoasi tekshirib tasdiqlagach, xabar yuboramiz. Shu orada to\'lov hisobingizni ulang.';

  @override
  String get pSuspended =>
      'Hisobingiz vaqtincha to\'xtatildi. Iltimos, operatsiya jamoasiga murojaat qiling.';

  @override
  String get pDirect => 'Darhol bron';

  @override
  String get pQuoteReq => 'Narx so\'rovlari';

  @override
  String get pShowClosed => 'Yopilgan ishlarni ham ko\'rsatish';

  @override
  String get pSortNewest => 'Eng yangi so\'rov';

  @override
  String get pSortVisit => 'Eng yaqin tashrif';

  @override
  String get pSortAmount => 'Summasi katta';

  @override
  String get pNoJobs => 'Hozircha mos ish yo\'q';

  @override
  String get pNoJobsBody =>
      'Xizmat, hudud yoki ish vaqtini kengaytirsangiz, ko\'proq ish ko\'rasiz';

  @override
  String get pPayout => 'Kutilayotgan to\'lov';

  @override
  String get pCustomerEstimate => 'Mijoz taxmini';

  @override
  String get pNew => 'YANGI';

  @override
  String get pClosed => 'Yopilgan';

  @override
  String get pPrivacyNote =>
      'Aniq manzil va mijoz ma\'lumotlari qabul qilingandan keyin ko\'rinadi';

  @override
  String get pAccept => 'Qabul qilish';

  @override
  String get pAcceptConfirm => 'Bu ishni qabul qilasizmi?';

  @override
  String get pAcceptBody =>
      'Qabul qilsangiz, jadvalingizga qo\'shiladi va mijozga jamoa biriktirilgani haqida xabar boradi. Tashrifga 2 kun qolganda bekor qilish cheklanadi.';

  @override
  String get pAccepted => 'Ish qabul qilindi';

  @override
  String get pSendQuote => 'Narx yuborish';

  @override
  String get pQuotePrice => 'Mijoz to\'lovi';

  @override
  String get pQuoteNote => 'Jamoaga yetkaziladigan izoh';

  @override
  String get pQuoteSent => 'Narx yuborildi';

  @override
  String pFee(String rate) {
    return 'Komissiya $rate%';
  }

  @override
  String get pYouGet => 'Olasiz';

  @override
  String get pQuoteAll => 'Barchasi';

  @override
  String get pQ_waiting => 'Kutilmoqda';

  @override
  String get pQ_selected => 'Tanlangan';

  @override
  String get pQ_rejected => 'Tanlanmagan';

  @override
  String get pQ_closed => 'Yakunlangan';

  @override
  String get pUnseenOnly => 'Faqat yangi natijalar';

  @override
  String get pNoQuotes => 'Yuborilgan narx yo\'q';

  @override
  String get pMyQuote => 'Mening narxim';

  @override
  String get pWithdraw => 'Narxni qaytarib olish';

  @override
  String get pWithdrawn => 'Narx qaytarib olindi';

  @override
  String get pOnlyMine => 'Faqat o\'zimniki';

  @override
  String pJobsCount(String n) {
    return '$n ta ish';
  }

  @override
  String get pNoSchedule => 'Bu kunda jadvalda hech narsa yo\'q';

  @override
  String get pCancelledBanner =>
      'Mijoz bu ishni bekor qildi. Uni bajarilgan deb belgilab bo\'lmaydi.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Vaqtni o\'zgartirish so\'rovi: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Kela olaman';

  @override
  String get pRescheduleNo => 'Kela olmayman';

  @override
  String get pCustomer => 'Mijoz';

  @override
  String get pCall => 'Maxfiy raqam orqali qo\'ng\'iroq';

  @override
  String get pCallSoon =>
      'Maxfiy raqam orqali aloqa xizmat ishga tushganda faollashadi';

  @override
  String get pQuietHours => 'Soat 20:00 dan keyin qo\'ng\'iroq qilmang';

  @override
  String get pAssignee => 'Mas\'ul';

  @override
  String get pChangeAssignee => 'Mas\'ulni o\'zgartirish';

  @override
  String get pCustomerRequests => 'Mijoz so\'rovlari';

  @override
  String get pHousehold => 'Uy ma’lumotlari';

  @override
  String get pPets => 'Uy hayvonlari';

  @override
  String get pPetDog => 'It';

  @override
  String get pPetCat => 'Mushuk';

  @override
  String get pPetBird => 'Qush';

  @override
  String get pPetFish => 'Baliq';

  @override
  String get pPetOther => 'Boshqa hayvon';

  @override
  String get pAllergies => 'Allergiya va sezgirlik';

  @override
  String get pPreferredProducts => 'Afzal mahsulotlar';

  @override
  String get pParking => 'Parkovka';

  @override
  String pFloor(String floor) {
    return '$floor-qavat';
  }

  @override
  String get pElevatorYes => 'Lift bor';

  @override
  String get pElevatorNo => 'Lift yo‘q';

  @override
  String get pTeamMemo => 'Jamoa eslatmasi (mijozga ko\'rinmaydi)';

  @override
  String get pMemoSaved => 'Eslatma saqlandi';

  @override
  String get pPayoutBreakdown => 'To\'lov tafsiloti';

  @override
  String get pAfterBalance => 'Mijoz qoldiqni to\'lagach, hisob-kitob qilinadi';

  @override
  String get pChatOps => 'Operatsiya jamoasi bilan chat';

  @override
  String get pComplete => 'Ishni yakunlash';

  @override
  String get pBeforePhotos => 'Tozalashdan oldingi suratlar';

  @override
  String get pAfterPhotos => 'Tozalashdan keyingi suratlar';

  @override
  String get pAddPhoto => 'Surat qo\'shish';

  @override
  String get pChecklist => 'Tekshiruv ro\'yxati';

  @override
  String get pCheck1 => 'So\'ralgan barcha joylar tozalandi';

  @override
  String get pCheck2 => 'Chiqindi olib tashlandi, asboblar yig\'ildi';

  @override
  String get pCheck3 => 'Derazalar, elektr va suv tekshirildi';

  @override
  String get pCheck4 => 'Mijoz so\'rovlari bajarildi';

  @override
  String get pCompleteCta => 'Bajarildi deb belgilash';

  @override
  String get pCompleteNeed =>
      'Har biridan kamida 1 ta surat yuklang va barcha bandlarni belgilang';

  @override
  String get pCompleted => 'Barakalla!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount $date kuni to\'lanadi';
  }

  @override
  String get pPayoutWaiting =>
      'Mijoz qoldiqni to\'lagach, to\'lov sanasi belgilanadi';

  @override
  String get pPendingPayout => 'Kutilayotgan to\'lov summasi';

  @override
  String get pSettlements => 'Hisob-kitoblar';

  @override
  String get pS_waiting_balance => 'Qoldiq kutilmoqda';

  @override
  String get pS_pending => 'Rejalashtirilgan';

  @override
  String get pS_paid => 'To\'landi';

  @override
  String get pS_held => 'Ushlab turilgan';

  @override
  String get pReviews => 'Mijoz sharhlari';

  @override
  String get pNoReviews => 'Hali sharhlar yo\'q';

  @override
  String get pReplyLater => 'Javob berish imkoniyati tez orada ochiladi';

  @override
  String get pServicesAreas => 'Xizmatlar · hududlar';

  @override
  String get pPayoutAccount => 'To\'lov hisobi';

  @override
  String get pBank => 'Bank';

  @override
  String get pAccountNumber => 'Hisob raqami';

  @override
  String get pHolder => 'Hisobvaraq egasi';

  @override
  String get pVerified => 'Tasdiqlangan';

  @override
  String get pUnverified => 'Tekshirilmoqda';

  @override
  String get pAccountSaved =>
      'Hisob saqlandi. O\'zgartirilganda qayta tekshiriladi.';

  @override
  String get pWorkSchedule => 'Ish jadvali';

  @override
  String get pWeekdays => 'Ish kunlari';

  @override
  String get pDayParts => 'Ish vaqti';

  @override
  String get pDaysOff => 'Dam olish kunlari';

  @override
  String get pAddDayOff => 'Dam olish kuni qo\'shish';

  @override
  String get pSaved => 'Saqlandi';

  @override
  String get pTeam => 'Jamoa a\'zolari';

  @override
  String get pOwner => 'Rahbar';

  @override
  String get pInvited => 'Taklif qilingan';

  @override
  String get pInvite => 'Jamoa a\'zosini taklif qilish';

  @override
  String get pInviteSent => 'Taklif SMS yuborildi';

  @override
  String get pRemove => 'Chiqarish';

  @override
  String get pNotifications => 'Bildirishnomalar';

  @override
  String get pNotifyDirect => 'Yangi darhol bron ishlari';

  @override
  String get pNotifyQuotes => 'Narx so\'rovlari · natijalar';

  @override
  String get pNotifyChat => 'Operatsiya xabarlari';

  @override
  String get pQuietNight => 'Tungi tinch rejim (22:00–08:00)';

  @override
  String get pNewInquiry => 'Yangi so\'rov';

  @override
  String get pTopic_settlement => 'To\'lovlar';

  @override
  String get pTopic_reschedule => 'Vaqtni o\'zgartirish · bekor qilish';

  @override
  String get pTopic_app => 'Ilova bo\'yicha yordam';

  @override
  String get pOpsTeam => 'Operatsiya';

  @override
  String get pViewJob => 'Ishni ko\'rish';

  @override
  String pBookingNo(String n) {
    return 'Bron raqami $n';
  }

  @override
  String get pSize => 'Maydon';

  @override
  String get pSchedule => 'Jadval';

  @override
  String get pSpace => 'Joy ma\'lumoti';

  @override
  String get pNavigate => 'Yo\'nalish';

  @override
  String get pNavHint =>
      'Manzilni xarita ilovasida ochadi. Ilova bo\'lmasa, veb-xarita ochiladi.';

  @override
  String get pOfflineSaved =>
      'Signal yo\'q. Saqlandi, ulanish qaytgach yuboriladi.';

  @override
  String get pPhotoRetry => 'Qayta yuklash';

  @override
  String get pPhotoWaiting =>
      'Yuklanmagan suratlar ulanish qaytgach avtomatik yuboriladi.';

  @override
  String pUploadedCount(String total, String done) {
    return '$total tadan $done yuklandi';
  }

  @override
  String get cIntPayout => 'Hamkor to‘lovlari';

  @override
  String get poTabSettlements => 'Hisob-kitoblar';

  @override
  String get poTabPayouts => 'To‘lovlar';

  @override
  String get poState_requested => 'So‘ralgan';

  @override
  String get poState_sent => 'Yuborilgan';

  @override
  String get poState_paid => 'To‘langan';

  @override
  String get poState_failed => 'Muvaffaqiyatsiz';

  @override
  String get poProviderManual => 'Qo‘lda o‘tkazma';

  @override
  String get poProviderToss => 'Toss orqali to‘lovlar';

  @override
  String get poShowAccount => 'Hisobni ko‘rsatish';

  @override
  String get poAccountTitle => 'O‘tkazma tafsilotlari';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '$holder · $bank · $account ga $amount von yuboring, so‘ng tasdiqlashni bosing.';
  }

  @override
  String get poConfirmPaid => 'O‘tkazilgan deb belgilash';

  @override
  String get poMarkFailed => 'Muvaffaqiyatsiz deb belgilash';

  @override
  String get poReasonTitle => 'Muvaffaqiyatsizlik sababi';

  @override
  String get poReasonHint => 'masalan: noto‘g‘ri hisob, o‘tkazma bekor qilindi';

  @override
  String get poSend => 'Toss orqali yuborish';

  @override
  String get poSync => 'Holatni tekshirish';

  @override
  String get poRetry => 'Qayta urinish';

  @override
  String get poNoPayouts => 'Hozircha to‘lovlar yo‘q';

  @override
  String poRequestedToast(String n) {
    return '$n ta to‘lov so‘rovi yaratildi';
  }

  @override
  String get poReasonRequired => 'Sababni kiriting';

  @override
  String get poRevealNote => 'Hisob tafsilotlarini ko‘rish qayd etiladi';

  @override
  String get poSellerAction => 'Sotuvchi ro‘yxatdan o‘tkazish';

  @override
  String get poSellerTitle => 'Toss sotuvchi sifatida ro‘yxatdan o‘tish';

  @override
  String get poSellerHint =>
      'Hamkorning tasdiqlangan to‘lov hisobi ishlatiladi. Faqat biznes ma’lumotlarini kiriting.';

  @override
  String get poSellerIndividual => 'Jismoniy shaxs';

  @override
  String get poSellerCompany => 'Tadbirkor';

  @override
  String get poSellerName => 'Ism';

  @override
  String get poSellerRepresentative => 'Vakil ismi';

  @override
  String get poSellerRegNo => 'Biznes ro‘yxat raqami (10 raqam)';

  @override
  String get poSellerEmail => 'Hisob-kitob uchun email';

  @override
  String get poSellerPhone => 'Telefon';

  @override
  String get poSellerSubmit => 'Ro‘yxatdan o‘tkazish';

  @override
  String poSellerDone(String status) {
    return 'Sotuvchi holati: $status';
  }

  @override
  String get pvManage => 'Rozilik sozlamalari';

  @override
  String get pvOptional => 'Ixtiyoriy';

  @override
  String get pvTerms => 'Xizmat shartlariga rozilik';

  @override
  String get pvPrivacy =>
      'Shaxsiy ma\'lumotlarni yig\'ish va foydalanishga rozilik';

  @override
  String get pvOverseas => 'Shaxsiy ma\'lumotlarni chet elga uzatishga rozilik';

  @override
  String get pvMarketing => 'Marketing xabarlari';

  @override
  String get pvMarketingHint =>
      'Kupon va tadbirlar yangiliklarini SMS, KakaoTalk va ilova bildirishnomalari orqali olasiz. Istalgan vaqtda o\'chirishingiz mumkin.';

  @override
  String get pvReconsent =>
      'Maxfiylik siyosatimiz o\'zgardi. Iltimos, qayta ko\'rib chiqing va rozilik bering.';

  @override
  String get pvSaved => 'Rozilik sozlamalari saqlandi';

  @override
  String get pvExport => 'Ma\'lumotlarimni yuklab olish';

  @override
  String get pvExportHint =>
      'Biz siz haqingizda saqlayotgan barcha ma\'lumotlar JSON ko\'rinishida ko\'rsatiladi. Nusxalab saqlashingiz mumkin.';

  @override
  String get pvCopy => 'Nusxalash';

  @override
  String get pvCopied => 'Nusxalandi';

  @override
  String get pvExportFailed =>
      'Ma\'lumotlaringizni yuklab bo\'lmadi. Keyinroq qayta urinib ko\'ring.';

  @override
  String get safetyEmergency => 'Favqulodda aloqa';

  @override
  String get emergencyPolice => '112 Politsiya';

  @override
  String get emergencyFire => '119 Yong\'in va qutqaruv';

  @override
  String get emergencyShop => 'Mijozlar xizmati';

  @override
  String get caseReportAction => 'Muammo haqida xabar berish';

  @override
  String get caseReportTitle => 'Nima bo\'ldi?';

  @override
  String get caseKindDamage => 'Shikastlanish';

  @override
  String get caseKindLoss => 'Yo\'qolish';

  @override
  String get caseKindComplaint => 'Shikoyat';

  @override
  String get caseKindNoShow => 'Tozalovchi kelmadi';

  @override
  String get caseKindSafety => 'Xavfsizlik masalasi';

  @override
  String get caseKindPayment => 'To\'lov nizosi';

  @override
  String get caseSummaryHint => 'Nima bo\'lganini yozing (300 belgigacha)';

  @override
  String get caseSubmit => 'Yuborish';

  @override
  String get caseSubmitted =>
      'Qabul qilindi. Jamoa 24 soat ichida javob beradi.';

  @override
  String get caseFailed => 'Yuborib bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get checkInAction => 'Kelganini qayd etish';

  @override
  String get checkOutAction => 'Ketganini qayd etish';

  @override
  String checkedInAt(String time) {
    return 'Kelgan vaqt $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Ketgan vaqt $time';
  }

  @override
  String get entryCodeAction => 'Kirish kodini ko\'rsatish';

  @override
  String get entryCodeTitle => 'Kirish kodi';

  @override
  String get entryCodeNotToday => 'Faqat tashrif kunida ko\'rinadi';

  @override
  String get entryCodeEmpty => 'Kirish kodi kiritilmagan';

  @override
  String get actionFailed => 'Bajarib bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get consoleCasesTitle => 'Holatlar navbati';

  @override
  String get consoleCasesEmpty => 'Ochiq holatlar yo\'q';

  @override
  String get caseOverdue => 'Muddati o\'tgan';

  @override
  String get caseStatusOpen => 'Ochiq';

  @override
  String get caseStatusInvestigating => 'Tekshirilmoqda';

  @override
  String get caseStatusResolved => 'Hal qilindi';

  @override
  String get caseStatusRejected => 'Rad etildi';

  @override
  String get caseReassign => 'Hamkorni qayta tayinlash';

  @override
  String get caseRefund => 'Qaytarish';

  @override
  String get caseHold => 'To\'lovni to\'xtatish';

  @override
  String get caseNoteHint => 'Ichki eslatma';

  @override
  String get caseSave => 'Saqlash';

  @override
  String get cSetup => 'Sozlash';

  @override
  String get cSetupTitle => 'Ishga tushirishga tayyorgarlik';

  @override
  String cSetupProgress(String done, String total) {
    return '$total dan $done tasi tayyor';
  }

  @override
  String get cSetupAllDone => 'Hammasi tayyor!';

  @override
  String get cSetupBusiness => 'Biznes ma\'lumotlari';

  @override
  String get cSetupBusinessName => 'Xizmat nomi';

  @override
  String get cSetupSupportPhone => 'Yordam telefoni';

  @override
  String get cSetupSupportEmail => 'Yordam emaili';

  @override
  String get cSetupSupportHours => 'Yordam vaqti';

  @override
  String get cSetupColor => 'Brend rangi';

  @override
  String get cSetupLogo => 'Logotip yuklash';

  @override
  String get cSetupCompany => 'Kompaniya ma\'lumotlari (ilova va sayt pastida)';

  @override
  String get cSetupLegalName => 'Yuridik nom';

  @override
  String get cSetupCeo => 'Rahbar';

  @override
  String get cSetupRegNo => 'Ro\'yxat raqami';

  @override
  String get cSetupMailOrderNo => 'Onlayn savdo ro\'yxat raqami';

  @override
  String get cSetupAddress => 'Manzil';

  @override
  String get cSetupPrivacyOfficer => 'Maxfiylik mas\'uli';

  @override
  String get cSetupStoreLinks =>
      'Do\'kon havolalari (to\'ldirilgach sayt tugmalari yoqiladi)';

  @override
  String get cSetupCustomerApp => 'Mijoz ilovasi';

  @override
  String get cSetupPartnerApp => 'Hamkor ilovasi';

  @override
  String get cSetupPayMethods => 'To\'lov usullari';

  @override
  String get cSetupPayMethodsHint =>
      'Mijozlar ko\'radigan usullarni yoqing yoki o\'chiring. Darhol qo\'llanadi.';

  @override
  String get cReviewTitle => 'Do\'kon tekshiruvi uchun demo hisob';

  @override
  String get cReviewHint =>
      'Tekshiruvchilar Koreya SMS\'ini olmaydi. Raqam va 6 xonali kodni tekshiruv izohiga yozing. O\'zi o\'chadi.';

  @override
  String get cReviewPhone => 'Demo telefon raqami';

  @override
  String get cReviewCode => 'Doimiy kod (6 raqam)';

  @override
  String cReviewActiveUntil(String date) {
    return '$date gacha faol';
  }

  @override
  String get cReviewEnable => 'Yoqish (14 kun)';

  @override
  String get pDeleteAccountBody =>
      'Jamoangiz va shaxsiy ma\'lumotlar butunlay o\'chiriladi. Avval tayinlangan ishlar va to\'lovlarni yakunlang.';

  @override
  String get err_has_active_jobs =>
      'Sizda tayinlangan ishlar bor. Ularni tugating yoki yordamdan o\'tkazishni so\'rang.';

  @override
  String get err_pending_payouts =>
      'To\'lov hali kutilmoqda. To\'langandan keyin o\'chirish mumkin.';

  @override
  String get err_phone_required =>
      'Ish olishdan oldin telefon raqamingizni tasdiqlang.';

  @override
  String get nAlerts => 'Bildirishnomalar';

  @override
  String get nEmpty => 'Hozircha bildirishnoma yo\'q';

  @override
  String nUnread(String count) {
    return '$count ta o\'qilmagan';
  }

  @override
  String get pVerifyPhone => 'Tasdiqlash';

  @override
  String get mMyJobs => 'Mening ishlarim';

  @override
  String get mNoJobs =>
      'Hozircha tayinlangan ish yo\'q. Jamoa rahbari bergan ishlar shu yerda ko\'rinadi.';

  @override
  String mTeam(String team) {
    return '$team a\'zosi';
  }

  @override
  String get cSetupSave => 'Saqlash';

  @override
  String get cSetupSaved => 'Saqlandi';

  @override
  String get cSetupTest => 'Ulanishni tekshirish';

  @override
  String get cSetupClear => 'Uzish';

  @override
  String get cSetupConnected => 'Ulangan';

  @override
  String get cSetupNotConnected => 'Ulanmagan';

  @override
  String get cSetupFromEnv => 'Server sozlamalari ishlatilmoqda';

  @override
  String get cSetupCheckInApp => 'Saqlandi · ilovadan kirib tasdiqlang';

  @override
  String get cSetupInvalidKey =>
      'Kalit rad etildi. Nusxalangan qiymatni tekshiring';

  @override
  String get cSetupUnreachable =>
      'Xizmatga ulanib bo\'lmadi. Keyinroq urinib ko\'ring';

  @override
  String get cSetupKeepValue => 'Saqlangan (faqat almashtirish uchun kiriting)';

  @override
  String get cSetupGuide => 'Qanday sozlash';

  @override
  String get cSetupOpenSite => 'Saytni ochish';

  @override
  String get cSetupWebhook => 'Webhook manzili (PortOne konsoliga joylang)';

  @override
  String get cCopied => 'Nusxalandi';

  @override
  String get cSetupDevMode =>
      'Sinov rejimi: haqiqiy to\'lov yoki xabar yuborilmaydi';

  @override
  String get cSetupOptional => 'Ixtiyoriy';

  @override
  String get cIntPortone => 'To\'lovlar (PortOne)';

  @override
  String get cIntSolapi => 'SMS va KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Ilova bildirishnomalari (Firebase)';

  @override
  String get cIntKakao => 'Kakao orqali kirish';

  @override
  String get cIntNaver => 'Naver orqali kirish';

  @override
  String get cIntGoogle => 'Google orqali kirish';

  @override
  String get cIntApple => 'Apple orqali kirish';

  @override
  String get cFirstRunTitle => 'Xush kelibsiz! Egasi hisobini yarating';

  @override
  String get cFirstRunBody =>
      'O\'rnatishda ko\'rsatilgan 12 belgili kodni kiriting. Bu hisob barcha sozlamalarni boshqaradi.';

  @override
  String get cFirstRunCode => 'O\'rnatish kodi';

  @override
  String get cName => 'Ism';

  @override
  String get cFirstRunCreate => 'Hisob yaratib boshlash';

  @override
  String get cWrongSetupCode => 'O\'rnatish kodi noto\'g\'ri';

  @override
  String get cWeakPassword => 'Parol kamida 12 belgidan iborat bo\'lishi kerak';

  @override
  String get cInvalidValue => 'Kiritilgan qiymatni tekshiring';

  @override
  String get subTitle => 'Muntazam tozalash';

  @override
  String get subNew => 'Obuna boshlash';

  @override
  String get subCadence => 'Necha marta';

  @override
  String get subWeekly => 'Har hafta';

  @override
  String get subBiweekly => 'Har 2 haftada';

  @override
  String get subEvery4Weeks => 'Har 4 haftada';

  @override
  String get subWeekday => 'Hafta kuni';

  @override
  String get subHour => 'Kelish vaqti';

  @override
  String subDiscountNote(String percent) {
    return 'Har bir tashrif uchun $percent% chegirma';
  }

  @override
  String get subChargeNote =>
      'Har tashrifdan bir kun oldin saqlangan kartadan to\'lanadi';

  @override
  String get subCreate => 'Obuna bo\'lish';

  @override
  String get subCreated => 'Obuna boshlandi';

  @override
  String get subNeedAddress => 'Avval tashrif manzilini qo\'shing';

  @override
  String get subListEmpty => 'Hozircha obuna yo\'q';

  @override
  String get subStatusActive => 'Faol';

  @override
  String get subStatusPaused => 'To\'xtatilgan';

  @override
  String get subStatusCancelled => 'Bekor qilingan';

  @override
  String subNextVisit(String date) {
    return 'Keyingi tashrif $date';
  }

  @override
  String get subPause => 'To\'xtatish';

  @override
  String get subResume => 'Davom ettirish';

  @override
  String get subCancelSub => 'Obunani bekor qilish';

  @override
  String get subCancelConfirm =>
      'Kelgusi tashriflar bekor qilinadi. Band qilingan tashriflarni alohida bekor qiling.';

  @override
  String get subSkip => 'Bu tashrifni o\'tkazib yuborish';

  @override
  String get subMove => 'Sanani o\'zgartirish';

  @override
  String get subVisitLocked =>
      'Tashrifdan bir kun oldin o\'zgartirib bo\'lmaydi';

  @override
  String get subPausedPayment =>
      'Takroriy to\'lov xatolari tufayli to\'xtatildi. Kartani almashtirib, davom ettiring.';

  @override
  String get subStatePlanned => 'Rejalashtirilgan';

  @override
  String get subStateBooked => 'Band qilingan';

  @override
  String get subStateSkipped => 'O\'tkazib yuborilgan';

  @override
  String get subStateMissed => 'O\'tkazib yuborilgan (o\'tmagan)';

  @override
  String get pSubsTitle => 'Doimiy mijozlar';

  @override
  String get pSubsEmpty => 'Hozircha doimiy mijozlar yo\'q';

  @override
  String get cSubsTitle => 'Obunalar';

  @override
  String get cSubsEdit => 'Mijoz o\'rniga tahrirlash';

  @override
  String get cMrr => 'Oylik takroriy daromad (MRR)';

  @override
  String get cChurn => 'Churn';

  @override
  String get cActiveSubs => 'Faol obunalar';

  @override
  String get cRecognized => 'Davrda e\'tirof etilgan daromad';

  @override
  String get cSubsLoadFailed => 'Obunalarni yuklab bo\'lmadi';

  @override
  String get tTaxSection => 'Soliq';

  @override
  String tVatQuarter(String q) {
    return 'Q$q QQS CSV';
  }

  @override
  String get tVatYear => 'Yil';

  @override
  String get tExportWithholding => 'Ushlab qolish hisoboti CSV';

  @override
  String get tExportTaxInvoices => 'Soliq hisob-fakturasini yuklash CSV';

  @override
  String get tTaxLayoutNote =>
      'Yuklashdan oldin ustunlarni 홈택스 shabloni bilan tekshiring. Tuzilma hali tasdiqlanmagan.';

  @override
  String get tCashReceipts => 'Naqd kvitansiyalar';

  @override
  String get tCashIssued => 'Berilgan';

  @override
  String get tCashFailed => 'Xatolik';

  @override
  String get tCashPending => 'Kutilmoqda';

  @override
  String get tCashCancelled => 'Bekor qilingan';

  @override
  String get tReissue => 'Qayta berish';

  @override
  String get tTaxInvoices => 'Soliq hisob-fakturalari';

  @override
  String get tApprovalNumber => 'Tasdiqlash raqami';

  @override
  String get tIssuedOn => 'Berilgan sana';

  @override
  String get tMarkIssued => 'Berilgan deb belgilash';

  @override
  String get tQueueEmpty => 'Kutilayotgan so‘rovlar yo‘q';

  @override
  String get tWithholdingLabel => 'Ushlab qolish';

  @override
  String get tGrossAmount => 'Yalpi summa';

  @override
  String get tIncomeTax => 'Daromad solig‘i';

  @override
  String get tLocalTax => 'Mahalliy daromad solig‘i';

  @override
  String get tNetAmount => 'Sof summa';

  @override
  String get tNoWithholding => 'Ushlab qolinmaydi (ro‘yxatdan o‘tgan biznes)';

  @override
  String get tEstWithholding => 'Taxminiy ushlab qolish (to‘lanmagan)';

  @override
  String get tReceiptOptions => 'Kvitansiya sozlamalari';

  @override
  String get tWantCashReceipt => 'Naqd kvitansiya olish';

  @override
  String get tCashForIncome => 'Soliq chegirmasi uchun (telefon raqami)';

  @override
  String get tCashForBusiness => 'Biznes xarajatlari uchun (biznes raqami)';

  @override
  String get tWantTaxInvoice => 'Soliq hisob-fakturasi olish (biznes)';

  @override
  String get tPhoneForReceipt => 'Telefon raqami';

  @override
  String get tBusinessNumber => 'Biznes ro‘yxat raqami';

  @override
  String get tCompanyName => 'Kompaniya nomi';

  @override
  String get tRepresentative => 'Vakil';

  @override
  String get tInvoiceEmail => 'Hisob-faktura uchun email';

  @override
  String get tReceiptSave => 'Saqlab to‘lash';

  @override
  String get tReceiptSaveFailed => 'Kvitansiya ma’lumotlari saqlanmadi';

  @override
  String get tTaxType => 'Soliq turi';

  @override
  String get tTaxFreelancer => 'Frilanser (ushlab qolinadi)';

  @override
  String get tTaxBusiness => 'Ro‘yxatdan o‘tgan biznes (ushlanmaydi)';

  @override
  String get tReceiptSettings => 'Kvitansiya sozlamalari';

  @override
  String get reviewRuleLine =>
      'Haqorat, shaxsiy ma\'lumot, soxta yoki reklama mazmuni taqiqlanadi. Shikoyat qilingan sharhlar yashiriladi.';

  @override
  String get reportAction => 'Shikoyat';

  @override
  String get reportSheetTitle => 'Ushbu sharhni shikoyat qilasizmi?';

  @override
  String get reportReasonSpam => 'Spam yoki reklama';

  @override
  String get reportReasonOffensive => 'Haqorat yoki nafrat';

  @override
  String get reportReasonPersonal => 'Shaxsiy ma\'lumot bor';

  @override
  String get reportReasonOther => 'Boshqa';

  @override
  String get reportNoteHint => 'Batafsil (ixtiyoriy, 300 belgigacha)';

  @override
  String get reportSubmit => 'Yuborish';

  @override
  String get reportThanks => 'Rahmat. Jamoamiz ko\'rib chiqadi.';

  @override
  String get reportAlready => 'Siz bu sharhni allaqachon shikoyat qilgansiz';

  @override
  String get reportFailed => 'Shikoyat yuborilmadi. Qayta urinib ko\'ring.';

  @override
  String get reviewBlocked =>
      'Bu hisobdan sharh yozish cheklangan. Qo\'llab-quvvatlashga murojaat qiling.';

  @override
  String get modTitle => 'Shikoyat qilingan sharhlar';

  @override
  String get modEmpty => 'Kutilayotgan shikoyat yo\'q';

  @override
  String modReports(String count) {
    return '$count shikoyat';
  }

  @override
  String get modKeep => 'Qoldirish';

  @override
  String get modHide => 'Yashirish';

  @override
  String get modDelete => 'O\'chirish';

  @override
  String get modBlockAuthor => 'Muallifni cheklash';

  @override
  String get modUnblockAuthor => 'Cheklovni olib tashlash';

  @override
  String get modDone => 'Bajarildi';

  @override
  String get modFailed => 'Bajarilmadi. Qayta urinib ko\'ring.';

  @override
  String get modHidden => 'Yashirilgan sharh';

  @override
  String uUpdateBanner(String version) {
    return 'Yangi versiya $version chiqdi';
  }

  @override
  String get uUpdateNow => 'Yangilash';

  @override
  String get uUpdateLater => 'Keyinroq';

  @override
  String get uUpdateRequiredTitle => 'Yangilash talab qilinadi';

  @override
  String get uUpdateRequiredBody =>
      'Bu versiya endi qo\'llab-quvvatlanmaydi. Do\'kondan yangilang.';

  @override
  String get uUpdateStore => 'Do\'konda yangilash';

  @override
  String get uUpdateStoreMissing =>
      'Yangilash havolasi hali tayyor emas. Keyinroq urinib ko\'ring.';

  @override
  String uCurrentVersion(String version) {
    return 'Joriy versiya $version';
  }

  @override
  String get uAppVersionTitle => 'Ilova versiyalari';

  @override
  String get uAppVersionHint =>
      'Minimal versiyadan past ilovalar yangilash ekranida to\'xtaydi. Misol: 1.2.0';

  @override
  String get uMinVersion => 'Minimal versiya';

  @override
  String get uLatestVersion => 'So\'nggi versiya';

  @override
  String get webBookNow => 'Veb orqali darhol band qiling';

  @override
  String get webBookSub => 'Ilovani o\'rnatmasdan';

  @override
  String get apPgBrowserNote =>
      'To\'lovni brauzerda yakunlang, so\'ng bu yerga qaytib, pastdagi tugmani bosing.';

  @override
  String get apPgBrowserDone => 'To\'lovni amalga oshirdim';
}
