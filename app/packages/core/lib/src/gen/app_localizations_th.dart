// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class TTh extends T {
  TTh([String locale = 'th']) : super(locale);

  @override
  String get addressSearch => 'ค้นหาที่อยู่';

  @override
  String get addressSearchHint => 'ค้นหาด้วยชื่อถนน อาคาร หรือเลขที่แปลง';

  @override
  String get addressSearchButton => 'ค้นหา';

  @override
  String get addressSearchMinChars => 'กรุณาพิมพ์อย่างน้อย 2 ตัวอักษร';

  @override
  String get addressNoResults => 'ไม่พบผลลัพธ์ ลองใช้คำอื่น';

  @override
  String get addressManualEntry => 'กรอกเอง';

  @override
  String get cardRegisterTitle => 'ลงทะเบียนบัตร';

  @override
  String get cIntJuso => 'ค้นหาที่อยู่ (juso.go.kr)';

  @override
  String get aiLabel => 'ผู้ช่วย AI';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint => 'ตอบแชทลูกค้าโดยอัตโนมัติ ทุกข้อความมีค่า API';

  @override
  String get aiModeOffline => 'ตอบเฉพาะตอนไม่มีเจ้าหน้าที่';

  @override
  String get aiModeAlways => 'AI ตอบก่อนเสมอ';

  @override
  String get aiPause => 'หยุด AI ชั่วคราว';

  @override
  String get aiResume => 'เปิด AI อีกครั้ง';

  @override
  String get aiPausedNote => 'หยุด AI ชั่วคราวในแชทนี้';

  @override
  String aiUsageMonth(String count) {
    return 'การเรียก AI เดือนนี้: $count ครั้ง';
  }

  @override
  String get aiNotConfigured => 'ยังไม่ได้เปิดผู้ช่วย AI';

  @override
  String get aiCapThreadLabel => 'จำกัดคำตอบต่อแชทต่อชั่วโมง';

  @override
  String get aiCapMemberLabel => 'จำกัดคำตอบต่อลูกค้าต่อวัน';

  @override
  String get aiCapDailyLabel => 'จำกัดคำตอบต่อวันทุกแชท';

  @override
  String get aiCapHint => 'กรอกเฉพาะตัวเลข เว้นว่างเพื่อใช้ค่าเริ่มต้น';

  @override
  String get apSocialOr => 'หรือ';

  @override
  String get apSocialSignIn => 'เข้าสู่ระบบด่วน';

  @override
  String get apLoginKakao => 'ดำเนินการต่อด้วย Kakao';

  @override
  String get apLoginNaver => 'ดำเนินการต่อด้วย Naver';

  @override
  String get apLoginGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get apLoginApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get apDevSocialNote =>
      'โหมดพัฒนา จะเข้าสู่ระบบด้วยบัญชีทดสอบ ไม่ใช่บัญชีโซเชียลจริง';

  @override
  String get apSocialFailed => 'เข้าสู่ระบบด่วนไม่สำเร็จ กรุณาลองอีกครั้ง';

  @override
  String get apProviderNotConfigured => 'วิธีเข้าสู่ระบบนี้ยังไม่พร้อมใช้งาน';

  @override
  String get apPhoneTaken => 'หมายเลขนี้ถูกผูกกับบัญชีอื่นแล้ว';

  @override
  String get apPhoneAttachTitle => 'กรุณายืนยันหมายเลขโทรศัพท์มือถือของคุณ';

  @override
  String get apPhoneAttachBody =>
      'ใช้หมายเลขนี้สำหรับการจองและการติดต่อผู้ให้บริการ ยืนยันเพียงครั้งเดียว';

  @override
  String get apPayAllTitle => 'เลือกวิธีชำระเงิน';

  @override
  String get apPaySavedTitle => 'วิธีที่บันทึกไว้';

  @override
  String get apPayMoreTitle => 'วิธีชำระเงินทั้งหมด';

  @override
  String get apPayBillingHint =>
      'บันทึกครั้งเดียว ครั้งต่อไปชำระได้ในคลิกเดียว';

  @override
  String get apPayCheckoutHint => 'ดำเนินการต่อในหน้าชำระเงิน';

  @override
  String get apPayRegistering => 'กำลังลงทะเบียน…';

  @override
  String get apPayManageHint =>
      'ชำระด้วยวิธีที่บันทึกไว้ในคลิกเดียว เพิ่มวิธีชำระเงินด่วนได้ที่นี่';

  @override
  String get apMethodCard => 'บัตรเครดิต/เดบิต';

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
  String get apMethodTransfer => 'โอนผ่านบัญชีธนาคาร';

  @override
  String get apMethodVirtual => 'บัญชีเสมือน';

  @override
  String get apMethodPhone => 'เรียกเก็บผ่านบิลโทรศัพท์';

  @override
  String get apMethodUnknown => 'วิธีอื่น';

  @override
  String get apVaTitle => 'บัญชีสำหรับโอนมัดจำพร้อมแล้ว';

  @override
  String get apVaWaiting => 'รอการโอนมัดจำ';

  @override
  String get apVaBody =>
      'การจองจะได้รับการยืนยันเมื่อได้รับเงินมัดจำ เราตรวจสอบการโอนให้อัตโนมัติ';

  @override
  String get apVaBank => 'ธนาคาร';

  @override
  String get apVaAccount => 'เลขที่บัญชี';

  @override
  String get apVaHolder => 'ชื่อบัญชี';

  @override
  String get apVaAmount => 'จำนวนเงิน';

  @override
  String apVaDue(String due) {
    return 'กรุณาโอนภายใน $due';
  }

  @override
  String get apVaCopy => 'คัดลอก';

  @override
  String get apVaCopied => 'คัดลอกเลขที่บัญชีแล้ว';

  @override
  String get apVaBannerTitle => 'มีการจองที่รอการโอนมัดจำ';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · ภายใน $due';
  }

  @override
  String get apVaBannerAction => 'ดูบัญชี';

  @override
  String get apPgTitle => 'หน้าชำระเงิน';

  @override
  String get apPgDevNote =>
      'การจำลองการชำระเงินสำหรับโหมดพัฒนาเท่านั้น จะไม่มีการตัดเงินจริง';

  @override
  String apPgPay(String amount) {
    return 'ชำระ $amount';
  }

  @override
  String get apPgIssue => 'รับเลขที่บัญชี';

  @override
  String get apPgCancel => 'ยกเลิกการชำระเงิน';

  @override
  String get apErrSlotFullRefunded =>
      'เวลานี้เพิ่งเต็ม จึงยกเลิกการชำระเงินให้อัตโนมัติ';

  @override
  String get apErrCheckoutExpired => 'หมดเวลาชำระเงินแล้ว กรุณาลองอีกครั้ง';

  @override
  String get apIdentityTitle => 'ยืนยันตัวตน (PASS)';

  @override
  String get apIdentityBody =>
      'ยืนยันตัวตนผ่านผู้ให้บริการโทรศัพท์มือถือ ใช้เพื่อความปลอดภัยในการทำธุรกรรมและการจ่ายเงิน';

  @override
  String get apIdentityAction => 'ยืนยันตัวตน';

  @override
  String get apIdentityDone => 'ยืนยันตัวตนเรียบร้อยแล้ว';

  @override
  String get apIdentityVerified => 'ยืนยันแล้ว';

  @override
  String get apIdentityUnverified => 'ยังไม่ได้ยืนยัน';

  @override
  String get apIdentityDevTitle => 'ยืนยันตัวตนทดสอบ';

  @override
  String get apIdentityDevBody =>
      'ในโหมดพัฒนา จะผ่านการยืนยันโดยไม่ตรวจสอบจริง';

  @override
  String get apIdentityDevPass => 'ผ่าน';

  @override
  String get apPayManageTitle => 'ลงทะเบียนชำระเงินด่วน';

  @override
  String get cTitle => 'คอนโซลผู้ดูแลระบบ';

  @override
  String get cEmail => 'อีเมล';

  @override
  String get cPassword => 'รหัสผ่าน';

  @override
  String get cLogin => 'เข้าสู่ระบบ';

  @override
  String get cLoginFailed => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get cDashboard => 'แดชบอร์ด';

  @override
  String get cBookings => 'การจอง';

  @override
  String get cQuoteDesk => 'ฝ่ายใบเสนอราคา';

  @override
  String get cInbox => 'กล่องข้อความ';

  @override
  String get cCatalog => 'แคตตาล็อก · ราคา';

  @override
  String get cMarketing => 'คูปอง · คอนเทนต์';

  @override
  String get cPartners => 'พาร์ทเนอร์';

  @override
  String get cSettlements => 'การจ่ายเงินพาร์ทเนอร์';

  @override
  String get cCustomers => 'ลูกค้า';

  @override
  String get cStaff => 'พนักงาน';

  @override
  String get cSearchCommand => 'ค้นหา · คำสั่ง';

  @override
  String get cPaletteHint => 'พิมพ์ชื่อเมนูหรือหมายเลขการจอง';

  @override
  String get cTodayJobs => 'งานวันนี้';

  @override
  String get cOpenQuotes => 'รอใบเสนอราคา';

  @override
  String get cUnassigned => 'ยังไม่มอบหมาย';

  @override
  String get cUnreadThreads => 'แชทที่ยังไม่อ่าน';

  @override
  String get cRevenue30 => 'ยอดชำระ 30 วัน';

  @override
  String get cBookings30 => 'การจอง 30 วัน';

  @override
  String get cByService => 'การจองแยกตามบริการ (30 วัน)';

  @override
  String get cAllStatus => 'ทุกสถานะ';

  @override
  String get cAllServices => 'ทุกบริการ';

  @override
  String get cSearch => 'ค้นหา (หมายเลข, โทรศัพท์, ชื่อ, ที่อยู่)';

  @override
  String get cNoResults => 'ไม่พบผลลัพธ์';

  @override
  String get cNumber => 'หมายเลข';

  @override
  String get cVisit => 'เข้าบริการ';

  @override
  String get cService => 'บริการ';

  @override
  String get cStatus => 'สถานะ';

  @override
  String get cTeam => 'ทีม';

  @override
  String get cAmount => 'จำนวนเงิน';

  @override
  String get cCustomer => 'ลูกค้า';

  @override
  String get cPayments => 'การชำระเงิน';

  @override
  String get cChangeStatus => 'เปลี่ยนสถานะ';

  @override
  String get cTeamName => 'ชื่อทีมที่มอบหมาย';

  @override
  String get cAssign => 'มอบหมายทีม';

  @override
  String get cMarkDone => 'ทำเครื่องหมายว่าเสร็จสิ้น';

  @override
  String get cConfirm => 'ทำเครื่องหมายว่ายืนยันแล้ว';

  @override
  String get cCancelRefund => 'ยกเลิก · คืนเงิน';

  @override
  String get cRefundAmount => 'จำนวนเงินที่คืน (เว้นว่าง = คืนเต็มจำนวน)';

  @override
  String get cDone => 'ดำเนินการแล้ว';

  @override
  String get cAnswers => 'คำตอบจากลูกค้า';

  @override
  String get cEstimateCalc => 'คำนวณอัตโนมัติ';

  @override
  String get cBase => 'พื้นฐาน';

  @override
  String get cExtras => 'เพิ่มเติม';

  @override
  String get cSurcharge => 'ค่าธรรมเนียมเพิ่ม';

  @override
  String get cBeforeVat => 'ก่อนภาษีมูลค่าเพิ่ม';

  @override
  String get cProQuotes => 'ใบเสนอราคาจากพาร์ทเนอร์';

  @override
  String get cNoProQuotes => 'ยังไม่มีใบเสนอราคาที่ได้รับ';

  @override
  String get cFinalPrice => 'ราคาสุดท้ายสำหรับลูกค้า';

  @override
  String get cQuoteNote => 'ข้อความถึงลูกค้า';

  @override
  String get cSendQuote => 'ส่งใบเสนอราคาให้ลูกค้า';

  @override
  String get cQuoteSent => 'ส่งใบเสนอราคาแล้ว';

  @override
  String get cCustomerChats => 'ลูกค้า';

  @override
  String get cPartnerChats => 'พาร์ทเนอร์';

  @override
  String get cSelectBooking => 'เลือกการจอง';

  @override
  String get cRefunded => 'คืนเงินแล้ว';

  @override
  String get cPartRefunded => 'คืนเงินบางส่วน';

  @override
  String get cFailed => 'ล้มเหลว';

  @override
  String get cSelectThread => 'เลือกการสนทนา';

  @override
  String get cReplyHint => 'พิมพ์ตอบกลับ · Ctrl+Enter เพื่อส่ง';

  @override
  String get cOpenBooking => 'เปิดการจอง';

  @override
  String get cShortcuts => 'J/K เลื่อน · Ctrl+K คำสั่ง';

  @override
  String get cPricing => 'ราคา';

  @override
  String get cMinutes => 'ระยะเวลา (นาที)';

  @override
  String get cActive => 'กำลังขาย';

  @override
  String get cSaved => 'บันทึกแล้ว';

  @override
  String get cSlotCapacity => 'จำนวนรับต่อช่วงเวลาเข้าบริการ';

  @override
  String get cUnlimited => 'ไม่จำกัด';

  @override
  String get cFormula => 'สูตรคำนวณใบเสนอราคา';

  @override
  String get cTabCancelPolicy => 'นโยบายการยกเลิก';

  @override
  String get cPolicyDefaultBanner =>
      'นี่คือค่าเริ่มต้น กรุณาตรวจสอบและบันทึกเพื่อยืนยัน';

  @override
  String get cPolicyDaysBefore => 'ก่อนวันเข้าบริการกี่วัน (ตั้งแต่)';

  @override
  String get cPolicyPercent => 'ค่าธรรมเนียม % (ว่าง = ยกเลิกในแอปไม่ได้)';

  @override
  String get cPolicyMinFee => 'ค่าธรรมเนียมขั้นต่ำ (KRW)';

  @override
  String get cPolicyReschedule => 'เลื่อนนัดได้ (ก่อนวันเข้าบริการกี่วัน)';

  @override
  String get cPolicyHint =>
      'มีผลทันทีบนหน้าจอยกเลิกของแอปลูกค้า ข้อกำหนดจะอัปเดตในบิลด์กฎหมายครั้งถัดไป';

  @override
  String get f_base_studio => 'ฐาน: สตูดิโอ';

  @override
  String get f_base_one_and_half => 'ฐาน: 1.5 ห้อง';

  @override
  String get f_base_two_rooms => 'ฐาน: 2 ห้อง';

  @override
  String get f_base_three_rooms => 'ฐาน: 3 ห้อง';

  @override
  String get f_base_four_plus => 'ฐาน: 4 ห้องขึ้นไป';

  @override
  String get f_per_extra_bathroom => 'ต่อห้องน้ำเพิ่ม 1 ห้อง';

  @override
  String get f_per_balcony => 'ต่อระเบียง 1 แห่ง';

  @override
  String get f_duplex => 'ดูเพล็กซ์ (2 ชั้น)';

  @override
  String get f_no_elevator_high_floor => 'ไม่มีลิฟต์ + ชั้น 3 ขึ้นไป';

  @override
  String get cIssueCoupon => 'ออกคูปอง';

  @override
  String get cCouponName => 'ชื่อคูปอง';

  @override
  String get cCouponPhones => 'เบอร์โทรที่รับสิทธิ์ (แยกบรรทัด)';

  @override
  String get cAllCustomers => 'ให้ลูกค้าทุกคน';

  @override
  String cIssued(String n) {
    return 'ออกแล้ว $n ใบ';
  }

  @override
  String get cContent => 'คอนเทนต์';

  @override
  String get cKind_notice => 'ประกาศ';

  @override
  String get cKind_tip => 'เคล็ดลับ';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'แบนเนอร์';

  @override
  String get cKind_legal => 'ข้อกำหนด';

  @override
  String get cNewContent => 'คอนเทนต์ใหม่';

  @override
  String get cTitleField => 'หัวข้อ';

  @override
  String get cBodyField => 'เนื้อหา';

  @override
  String get cSlug => 'ตัวระบุ (ข้อกำหนด: privacy / terms)';

  @override
  String get cVerify => 'อนุมัติ';

  @override
  String get cSuspend => 'ระงับ';

  @override
  String get cPro_pending => 'รออนุมัติ';

  @override
  String get cPro_verified => 'ใช้งานอยู่';

  @override
  String get cPro_suspended => 'ถูกระงับ';

  @override
  String get cCompleted => 'เสร็จสิ้น';

  @override
  String get cCancelledN => 'ยกเลิกแล้ว';

  @override
  String get cRating => 'คะแนน';

  @override
  String get cFeeRate => 'อัตราค่าธรรมเนียม %';

  @override
  String get cRunPayouts => 'เริ่มการจ่ายเงินพาร์ทเนอร์';

  @override
  String get cPayoutDate => 'จ่ายถึงวันที่';

  @override
  String cPayoutDone(String n) {
    return 'จ่ายเงินให้พาร์ทเนอร์ $n ราย แล้ว';
  }

  @override
  String get cHold => 'พักการจ่าย';

  @override
  String get cRelease => 'ปลดพัก';

  @override
  String get cNet => 'ยอดสุทธิ';

  @override
  String get cAddStaff => 'เพิ่มพนักงาน';

  @override
  String get cRoleAdmin => 'ผู้ดูแลระบบ';

  @override
  String get cRoleConsultant => 'ที่ปรึกษา';

  @override
  String get cDeactivate => 'ปิดใช้งาน';

  @override
  String get cActivate => 'เปิดใช้งาน';

  @override
  String get cPasswordRule => 'อย่างน้อย 12 ตัวอักษร';

  @override
  String get cAdminOnly => 'เฉพาะผู้ดูแลระบบเท่านั้น';

  @override
  String cBookingsCount(String n) {
    return 'การจอง $n รายการ';
  }

  @override
  String get cJoined => 'เข้าร่วมเมื่อ';

  @override
  String get cNewBooking => 'มีการจองใหม่';

  @override
  String get cNewMessage => 'ข้อความใหม่';

  @override
  String get cConfirmAsk => 'แน่ใจหรือไม่?';

  @override
  String get ok => 'ตกลง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get next => 'ถัดไป';

  @override
  String get close => 'ปิด';

  @override
  String get save => 'บันทึก';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่ใช่';

  @override
  String get required => 'จำเป็น';

  @override
  String get viewAll => 'ดูทั้งหมด';

  @override
  String get today => 'วันนี้';

  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด กรุณาลองอีกครั้งในภายหลัง';

  @override
  String get errorNetwork => 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get err_invalid_phone => 'กรุณาตรวจสอบหมายเลขโทรศัพท์มือถือ';

  @override
  String get err_otp_invalid => 'รหัสยืนยันไม่ถูกต้อง';

  @override
  String get err_otp_expired => 'รหัสยืนยันหมดอายุแล้ว กรุณาขอรหัสใหม่';

  @override
  String get err_rate_limited => 'ส่งคำขอมากเกินไป กรุณาลองใหม่ในภายหลัง';

  @override
  String get err_studio_too_large =>
      'บริการทำความสะอาดสตูดิโอใช้ได้กับบ้านไม่เกิน 10 พยอง';

  @override
  String get err_date_out_of_range =>
      'กรุณาเลือกวันที่ตั้งแต่พรุ่งนี้ ไม่เกิน 60 วันข้างหน้า';

  @override
  String get err_slot_full => 'เวลานั้นเต็มแล้ว กรุณาเลือกเวลาอื่น';

  @override
  String get err_coupon_expired => 'คูปองนี้หมดอายุแล้ว';

  @override
  String get err_coupon_used => 'คูปองนี้ถูกใช้ไปแล้ว';

  @override
  String get err_coupon_wrong_service => 'คูปองนี้ใช้กับบริการนี้ไม่ได้';

  @override
  String get err_payment_failed =>
      'การชำระเงินไม่ได้รับการอนุมัติ กรุณาใช้วิธีอื่น';

  @override
  String get err_payment_method_required => 'กรุณาเลือกวิธีชำระเงิน';

  @override
  String get err_cancellation_window_closed =>
      'ไม่สามารถยกเลิกการจองนี้ในแอปได้แล้ว กรุณาติดต่อทีมงานของเรา';

  @override
  String get err_address_required => 'กรุณาเพิ่มที่อยู่สำหรับเข้าบริการ';

  @override
  String get err_already_taken => 'มีพาร์ทเนอร์อื่นรับงานนี้ไปก่อนแล้ว';

  @override
  String get err_invalid_address => 'กรุณากรอกข้อมูลที่อยู่ให้ครบทุกช่อง';

  @override
  String get tabHome => 'หน้าหลัก';

  @override
  String get tabBookings => 'การจอง';

  @override
  String get tabChat => 'แชท';

  @override
  String get tabMore => 'เพิ่มเติม';

  @override
  String get introTitle => 'จองบริการทำความสะอาดมืออาชีพ\nได้ในไม่กี่นาที';

  @override
  String get introBody =>
      'ราคาชัดเจน · ทีมที่ผ่านการตรวจสอบ · ติดตามความคืบหน้าแบบเรียลไทม์';

  @override
  String get introStart => 'เริ่มต้นด้วยหมายเลขโทรศัพท์';

  @override
  String get loginPhoneTitle => 'กรุณาระบุหมายเลขโทรศัพท์มือถือ';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'ขอรหัสยืนยัน';

  @override
  String get loginCodeTitle => 'กรอกรหัสยืนยัน 6 หลัก';

  @override
  String loginCodeSentTo(String phone) {
    return 'ส่งไปยัง $phone แล้ว';
  }

  @override
  String get loginResend => 'ส่งอีกครั้ง';

  @override
  String get loginVerify => 'ยืนยัน';

  @override
  String get loginTerms =>
      'เมื่อดำเนินการต่อ แสดงว่าคุณยอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว';

  @override
  String get profileTitle => 'ขอทราบชื่อของคุณหน่อย';

  @override
  String get profileNameHint => 'ชื่อ';

  @override
  String get profileDone => 'เริ่มต้นใช้งาน';

  @override
  String get welcomeToast => 'เราได้มอบคูปองต้อนรับ 2 ใบให้คุณแล้ว';

  @override
  String get svc_studio => 'ทำความสะอาดสตูดิโอ';

  @override
  String get svc_kitchen => 'ทำความสะอาดห้องครัว';

  @override
  String get svc_bathroom => 'ทำความสะอาดห้องน้ำ';

  @override
  String get svc_mattress => 'ทำความสะอาดที่นอน';

  @override
  String get svc_aircon => 'ทำความสะอาดแอร์';

  @override
  String get svc_sofa => 'ทำความสะอาดโซฟา';

  @override
  String get svc_move_out => 'ทำความสะอาดก่อนย้ายออก';

  @override
  String get svc_move_in => 'ทำความสะอาดก่อนย้ายเข้า';

  @override
  String get svcShort_studio => 'สตูดิโอ';

  @override
  String get svcShort_kitchen => 'ครัว';

  @override
  String get svcShort_bathroom => 'ห้องน้ำ';

  @override
  String get svcShort_mattress => 'ที่นอน';

  @override
  String get svcShort_aircon => 'แอร์';

  @override
  String get svcShort_sofa => 'โซฟา';

  @override
  String get svcShort_move_out => 'ย้ายออก';

  @override
  String get svcShort_move_in => 'ย้ายเข้า';

  @override
  String get svcDesc_studio =>
      'ทำความสะอาดสตูดิโอขนาดไม่เกิน 10 พยอง (1 ห้อง 1 ห้องน้ำ) อย่างละเอียดในเวลา 2 ชั่วโมง';

  @override
  String get svcDesc_kitchen =>
      'ทำความสะอาดห้องครัวแบบเจาะจง: อ่างล้างจาน เตาแก๊ส ด้านนอกของเครื่องดูดควัน และหน้าท็อป';

  @override
  String get svcDesc_bathroom =>
      'ทำความสะอาดชั้นวาง ก๊อกน้ำ อ่างล้างหน้า และโถสุขภัณฑ์ทั้งด้านในและด้านนอก พร้อมเช็ดพื้นให้แห้ง';

  @override
  String get svcDesc_mattress =>
      'ใช้อุปกรณ์มืออาชีพดูดฝุ่น ไรฝุ่น และคราบ แล้วฆ่าเชื้อด้วยไอน้ำ';

  @override
  String get svcDesc_aircon =>
      'ถอดประกอบ แล้วล้างแรงดันสูงที่คอยล์ พัดลม และฟิลเตอร์ ปิดท้ายด้วยการฆ่าเชื้อ';

  @override
  String get svcDesc_sofa =>
      'ใช้น้ำยาที่เหมาะกับวัสดุเพื่อย่อยคราบสกปรก แล้วดูดออกด้วยวิธีซักแบบเปียก';

  @override
  String get svcDesc_move_out =>
      'ก่อนย้ายออก ทีมมืออาชีพนำอุปกรณ์มาทำความสะอาดบ้านที่ขนของออกแล้ว';

  @override
  String get svcDesc_move_in =>
      'ก่อนย้ายเข้า ทีมมืออาชีพนำอุปกรณ์มาทำความสะอาดภายในบ้านใหม่';

  @override
  String get svcNotes_bathroom =>
      'หากท่อระบายน้ำหรือโถสุขภัณฑ์อุดตัน บริการอาจถูกจำกัด\nไม่รวมการทำความสะอาดที่ต้องใช้สารเคมีพิเศษ เพดาน หรือพัดลมระบายอากาศ\nเชื้อราเก่าและคราบฝังลึกอาจไม่หลุดออกทั้งหมด';

  @override
  String get svcNotes_mattress =>
      'ราคาเดียวกันตั้งแต่ขนาดเดี่ยวถึงคิงไซส์\nใช้เวลาแห้งสนิท 4–6 ชั่วโมงหลังซัก\nความเสียหายของสปริงหรือที่นอนยุบไม่สามารถแก้ไขได้';

  @override
  String get svcNotes_aircon =>
      'เครื่องที่ผลิตเกิน 10 ปี อาจถอดล้างได้ยาก\nไม่รวมการทำความสะอาดคอยล์ร้อนภายนอก\nเราตรวจสอบการทำงานก่อนและหลังการล้าง';

  @override
  String get svcNotes_sofa =>
      'โซฟาหนังจะทำความสะอาดและเคลือบบำรุง\nคราบเก่าหรือการย้อมสีที่ซึมอาจไม่หลุดออกทั้งหมด\nใช้เวลาแห้งสนิท 4–6 ชั่วโมง';

  @override
  String get unitTitle_bathroom => 'จำนวนห้องน้ำ';

  @override
  String get unitTitle_mattress => 'จำนวนที่นอน';

  @override
  String get unitTitle_aircon => 'ประเภทแอร์';

  @override
  String get unitTitle_sofa => 'ขนาดโซฟา';

  @override
  String unit_count(String n) {
    return '$n ชิ้น';
  }

  @override
  String get unit_wall => 'แบบติดผนัง 1 เครื่อง';

  @override
  String get unit_stand => 'แบบตั้งพื้น 1 เครื่อง';

  @override
  String get unit_two_in_one => '2in1 (ตั้งพื้น+ติดผนัง)';

  @override
  String get unit_ceiling => 'แบบฝังเพดาน 1 เครื่อง';

  @override
  String get unit_seat_1_2 => '1–2 ที่นั่ง';

  @override
  String get unit_seat_3 => '3 ที่นั่ง';

  @override
  String get unit_seat_4_plus => '4 ที่นั่งขึ้นไป';

  @override
  String get unit_l_shape => 'แบบตัวแอล · คัช';

  @override
  String durH(String h) {
    return '$h ชั่วโมง';
  }

  @override
  String durHM(String h, String m) {
    return '$h ชั่วโมง $m นาที';
  }

  @override
  String durM(String m) {
    return '$m นาที';
  }

  @override
  String about(String value) {
    return 'ประมาณ $value';
  }

  @override
  String fromPrice(String price) {
    return 'เริ่มต้น $price';
  }

  @override
  String get quoteBadge => 'ใบเสนอราคา';

  @override
  String get status0 => 'กำลังปรึกษา';

  @override
  String get status1 => 'ยืนยันการจองแล้ว';

  @override
  String get status2 => 'มอบหมายทีมแล้ว';

  @override
  String get status3 => 'ทำความสะอาดเสร็จแล้ว';

  @override
  String get statusCancelled => 'ยกเลิกแล้ว';

  @override
  String homeGreeting(String name) {
    return 'สวัสดี $name\nวันนี้อยากให้ทำความสะอาดส่วนไหนดี';
  }

  @override
  String get homeGreetingAnon => 'วันนี้อยากให้ทำความสะอาด\nส่วนไหนดี';

  @override
  String get homeUpcoming => 'การจองที่กำลังจะถึง';

  @override
  String dDay(String days) {
    return 'D-$days';
  }

  @override
  String get homeServices => 'ต้องการบริการแบบไหน';

  @override
  String get homeAddAddress =>
      'เพิ่มที่อยู่เพื่อดูบริการและราคาที่ให้บริการได้ทันที';

  @override
  String get homeAddAddressCta => 'เพิ่มที่อยู่';

  @override
  String homeRebook(String service) {
    return 'จองบริการ $service อีกครั้ง';
  }

  @override
  String get homeRebookBody =>
      'ใช้ตัวเลือกเดิมจากครั้งที่แล้ว จองได้ในไม่กี่คลิก';

  @override
  String get homeNotices => 'ข่าวสาร';

  @override
  String get trustVat => 'รวมภาษีมูลค่าเพิ่มแล้ว\nราคาตามที่แสดงทั้งหมด';

  @override
  String get trustCancel => 'ยกเลิกฟรี\nจนถึง 2 วันก่อนวันเข้าบริการ';

  @override
  String get trustCard =>
      'ข้อมูลบัตรจะเก็บไว้\nกับผู้ให้บริการชำระเงินเท่านั้น';

  @override
  String stepOf(String current, String total) {
    return '$current / $total';
  }

  @override
  String get chooseDate => 'เลือกวันที่';

  @override
  String get notIncluded => 'โปรดทราบ';

  @override
  String studioBlockedTitle(String size) {
    return 'ขนาด $size พยอง ไม่อยู่ในขอบเขตบริการสตูดิโอ';
  }

  @override
  String get studioBlockedBody =>
      'ทีมที่ปรึกษาจะแนะนำบริการที่เหมาะกับบ้านของคุณ';

  @override
  String get consultCta => 'สอบถามทีมที่ปรึกษา';

  @override
  String get addressTitle => 'จะให้ไปที่ไหนดี';

  @override
  String get addressAdd => 'เพิ่มที่อยู่ใหม่';

  @override
  String get addressLabel => 'ชื่อที่อยู่';

  @override
  String get addressLabelHint => 'เช่น บ้าน';

  @override
  String get addressDistrict => 'เขต';

  @override
  String get addressRoad => 'ที่อยู่ (ถนน)';

  @override
  String get addressDetail => 'รายละเอียด (ห้อง / ชั้น)';

  @override
  String get addressSize => 'ขนาดบ้าน (พยอง)';

  @override
  String get addressSizeHelp => 'พื้นที่ใช้สอย · 1 พยอง ≈ 3.3 ㎡';

  @override
  String get addressHome => 'บ้าน';

  @override
  String get addressOffice => 'ออฟฟิศ';

  @override
  String get addressEmpty => 'ยังไม่มีที่อยู่ที่บันทึกไว้';

  @override
  String get addressSaved => 'บันทึกที่อยู่แล้ว';

  @override
  String pyeong(String n) {
    return '$n พยอง';
  }

  @override
  String get scheduleTitle => 'จะให้ไปเข้าบริการเมื่อไหร่ดี';

  @override
  String get scheduleArrival => 'เวลาเข้าบริการ';

  @override
  String get scheduleFull => 'เต็ม';

  @override
  String scheduleWindow(String start, String end) {
    return 'เข้าบริการระหว่าง $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · คาดว่าเสร็จประมาณ $time';
  }

  @override
  String get scheduleRange => 'จองได้ตั้งแต่พรุ่งนี้ ไม่เกิน 60 วันข้างหน้า';

  @override
  String get morning => 'ช่วงเช้า';

  @override
  String get afternoon => 'ช่วงบ่าย';

  @override
  String get scheduleQuoteNote => 'เวลาเข้าบริการที่แน่นอนจะยืนยันในแชท';

  @override
  String get goToPayment => 'ไปหน้าชำระเงิน';

  @override
  String get prepTitle => 'กรุณาเตรียมสิ่งเหล่านี้ไว้ก่อนเข้าบริการ';

  @override
  String get prepBody => 'หากไม่มีอุปกรณ์เหล่านี้ บางงานอาจทำได้จำกัด';

  @override
  String get prepAsk => 'เตรียมไม่ได้ใช่ไหม แจ้งทีมงานของเราล่วงหน้าได้เลย';

  @override
  String get tool_vacuum => 'เครื่องดูดฝุ่น';

  @override
  String get tool_trash => 'ถุงขยะ';

  @override
  String get tool_mop => 'ไม้ถูพื้น';

  @override
  String get tool_cloth => 'ผ้าขี้ริ้ว';

  @override
  String get tool_gloves => 'ถุงมือยาง';

  @override
  String get tool_sponge => 'ฟองน้ำขัด';

  @override
  String get tool_spray => 'น้ำยาทำความสะอาดอเนกประสงค์';

  @override
  String get checkoutTitle => 'ชำระเงิน';

  @override
  String get coupon => 'คูปอง';

  @override
  String get couponNone => 'ไม่ใช้';

  @override
  String couponAvailable(String count) {
    return 'ใช้ได้ $count ใบ';
  }

  @override
  String get paymentMethod => 'วิธีชำระเงิน';

  @override
  String get addPaymentMethod => 'เพิ่มวิธีชำระเงิน';

  @override
  String get methodCard => 'บัตรเครดิต / เดบิต';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'NaverPay';

  @override
  String get methodToss => 'TossPay';

  @override
  String get methodRegistered => 'เพิ่มแล้ว';

  @override
  String get methodAdded => 'เพิ่มวิธีชำระเงินแล้ว';

  @override
  String get listPrice => 'ค่าบริการ';

  @override
  String get discount => 'ส่วนลดคูปอง';

  @override
  String get total => 'ยอดชำระ';

  @override
  String get vatIncluded => 'รวมภาษีมูลค่าเพิ่มแล้ว';

  @override
  String payAmount(String amount) {
    return 'ชำระ $amount';
  }

  @override
  String get needMethod => 'กรุณาเพิ่มวิธีชำระเงินก่อน';

  @override
  String freeCancelUntil(String date) {
    return 'ยกเลิกฟรีจนถึง $date';
  }

  @override
  String get doneTitle => 'จองสำเร็จแล้ว';

  @override
  String get doneBody => 'เราจะแจ้งให้ทราบทันทีที่มอบหมายทีมเข้าบริการ';

  @override
  String get doneQuoteTitle => 'ได้รับคำขอปรึกษาแล้ว';

  @override
  String get doneQuoteBody =>
      'ทีมที่ปรึกษาจะตรวจสอบและส่งใบเสนอราคาสุดท้ายให้ คุณดูได้ในแท็บแชท';

  @override
  String get goHome => 'กลับหน้าหลัก';

  @override
  String get viewBooking => 'ดูการจอง';

  @override
  String get bookingsTitle => 'การจอง';

  @override
  String get bookingsUpcoming => 'ที่กำลังจะถึง';

  @override
  String get bookingsPast => 'ที่ผ่านมา';

  @override
  String get bookingsEmpty => 'ยังไม่มีการจอง';

  @override
  String get bookingsEmptyBody =>
      'มีคูปองต้อนรับรอให้ใช้กับการจองครั้งแรกของคุณ';

  @override
  String get bookNow => 'จองบริการทำความสะอาด';

  @override
  String get detailTitle => 'รายละเอียดการจอง';

  @override
  String get stepRequested => 'รับคำขอปรึกษา';

  @override
  String get stepConfirmed => 'ยืนยันการจอง';

  @override
  String get stepAssigned => 'มอบหมายทีม';

  @override
  String get stepCompleted => 'ทำความสะอาดเสร็จ';

  @override
  String teamVisiting(String team) {
    return '$team กำลังเดินทางไปเข้าบริการ';
  }

  @override
  String get photosSoon => 'ภาพก่อนและหลังการทำความสะอาดจะแสดงที่นี่เมื่อเสร็จ';

  @override
  String photoThumb(String n) {
    return 'รูปที่ $n';
  }

  @override
  String get before => 'ก่อนทำความสะอาด';

  @override
  String get after => 'หลังทำความสะอาด';

  @override
  String get prepCheck => 'เช็กลิสต์สิ่งที่ต้องเตรียม';

  @override
  String get prepAllSet => 'เตรียมพร้อมแล้ว';

  @override
  String get visitAddress => 'ที่อยู่';

  @override
  String get paid => 'ชำระแล้ว';

  @override
  String get askTeam => 'ส่งข้อความถึงทีมงาน';

  @override
  String get cancelBooking => 'ยกเลิกการจอง';

  @override
  String get cancelTitle => 'ยืนยันยกเลิกการจองนี้ไหม';

  @override
  String get cancelFree =>
      'หากยกเลิกตอนนี้ คุณจะได้รับเงินคืนเต็มจำนวน และคูปองจะถูกคืนให้ด้วย';

  @override
  String get cancelKeep => 'ไม่ยกเลิก';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'หากยกเลิกตอนนี้ จะมีค่าธรรมเนียม $fee และคืนเงิน $refund';
  }

  @override
  String cancelFeeAccept(String fee) {
    return 'ยอมรับค่าธรรมเนียม $fee และยกเลิก';
  }

  @override
  String get cancelled => 'ยกเลิกการจองแล้ว';

  @override
  String get reschedule => 'เปลี่ยนวันเวลา';

  @override
  String get rescheduled => 'เปลี่ยนวันเวลาแล้ว';

  @override
  String get visitNotes => 'ข้อความถึงทีมงาน';

  @override
  String get notesEntry => 'วิธีเข้าอาคาร (รหัสประตู ฯลฯ)';

  @override
  String get notesParking => 'ที่จอดรถ';

  @override
  String get notesOther => 'อื่น ๆ';

  @override
  String get notesSaved => 'บันทึกข้อความแล้ว';

  @override
  String depositDue(String amount) {
    return 'ชำระเงินมัดจำ $amount เพื่อยืนยันการจอง';
  }

  @override
  String get payDeposit => 'ชำระเงินมัดจำ';

  @override
  String get waitingQuote => 'ทีมที่ปรึกษากำลังเตรียมใบเสนอราคาให้คุณ';

  @override
  String get estimate => 'ราคาประมาณการ';

  @override
  String get finalPrice => 'ใบเสนอราคาสุดท้าย';

  @override
  String get deposit => 'มัดจำ';

  @override
  String get balance => 'ยอดคงเหลือ';

  @override
  String balanceDue(String amount) {
    return 'กรุณาชำระยอดคงเหลือ $amount';
  }

  @override
  String get payBalance => 'ชำระยอดคงเหลือ';

  @override
  String get reviewTitle => 'การทำความสะอาดเป็นอย่างไรบ้าง';

  @override
  String get reviewHint => 'บอกเราว่าประทับใจอะไรหรือควรปรับปรุงอะไร';

  @override
  String ratingStars(String n) {
    return '$n ดาว';
  }

  @override
  String get reviewSubmit => 'ส่งรีวิว';

  @override
  String get reviewThanks => 'ขอบคุณสำหรับรีวิว';

  @override
  String get bookAgain => 'จองอีกครั้งด้วยตัวเลือกเดิม';

  @override
  String get chatTitle => 'แชท';

  @override
  String get chatTeam => 'ทีมที่ปรึกษา';

  @override
  String get chatHours => 'วันธรรมดา 09:00–18:00';

  @override
  String get chatEmpty => 'มีคำถามไหม ถามเราได้ตลอดเวลา';

  @override
  String get chatNew => 'แชทใหม่';

  @override
  String get chatTopicTitle => 'สอบถามเรื่องอะไรดี';

  @override
  String get topicOther => 'เรื่องอื่น ๆ';

  @override
  String get chatHint => 'พิมพ์ข้อความ';

  @override
  String get chatSend => 'ส่ง';

  @override
  String get chatPhoto => 'ส่งรูปภาพ';

  @override
  String get chatTyping => 'ทีมที่ปรึกษากำลังพิมพ์…';

  @override
  String get quick_confirm => 'ขอยืนยันการจอง';

  @override
  String get quick_price => 'อยากทราบราคา';

  @override
  String get quick_date => 'อยากเปลี่ยนวัน';

  @override
  String get quick_parking => 'มีที่จอดรถไหม';

  @override
  String get quick_hello => 'สวัสดี';

  @override
  String get quick_duration => 'ใช้เวลาประมาณเท่าไร';

  @override
  String get quoteArrived => 'ได้รับใบเสนอราคาสุดท้ายแล้ว';

  @override
  String get quoteDepositNow => 'มัดจำ 10% ตอนนี้';

  @override
  String get quoteBalanceLater => 'ยอดคงเหลือหลังทำความสะอาด';

  @override
  String get quotePay => 'ชำระมัดจำและยืนยัน';

  @override
  String get quotePaid => 'ชำระแล้ว';

  @override
  String get requestCard => 'ขอใบเสนอราคา';

  @override
  String get sys_consultation_received => 'ได้รับคำขอปรึกษาแล้ว';

  @override
  String sys_deposit_paid(String amount) {
    return 'ชำระเงินมัดจำ $amount แล้ว การจองได้รับการยืนยันแล้ว';
  }

  @override
  String get sys_booking_cancelled => 'การจองถูกยกเลิกแล้ว';

  @override
  String sys_status_changed(String status) {
    return 'สถานะเปลี่ยนเป็น \'$status\' แล้ว';
  }

  @override
  String get sys_job_completed => 'ทำความสะอาดเสร็จแล้ว ดูภาพก่อนและหลังได้เลย';

  @override
  String sys_rescheduled(String date) {
    return 'เปลี่ยนวันเป็น $date แล้ว';
  }

  @override
  String get sys_reschedule_declined =>
      'พาร์ทเนอร์ไม่สามารถเข้าบริการในเวลาที่เปลี่ยนได้ ทีมที่ปรึกษาจะประสานงานให้อีกครั้ง';

  @override
  String get moreTitle => 'เพิ่มเติม';

  @override
  String get moreScope => 'ขอบเขตบริการ';

  @override
  String get morePayments => 'จัดการวิธีชำระเงิน';

  @override
  String get moreCoupons => 'คูปอง';

  @override
  String get morePoints => 'คะแนนสะสม';

  @override
  String get moreAccount => 'ข้อมูลบัญชี';

  @override
  String get moreAddresses => 'จัดการที่อยู่';

  @override
  String get moreNotices => 'ประกาศ';

  @override
  String get moreTips => 'เคล็ดลับการทำความสะอาด';

  @override
  String get moreFaq => 'คำถามที่พบบ่อย';

  @override
  String get morePartner => 'ร่วมเป็นพาร์ทเนอร์';

  @override
  String get moreLanguage => 'ภาษา';

  @override
  String get langSystem => 'ตามการตั้งค่าเครื่อง';

  @override
  String moreVersion(String v) {
    return 'เวอร์ชัน $v';
  }

  @override
  String get morePrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get moreTerms => 'ข้อกำหนดการใช้งาน';

  @override
  String get moreLicenses => 'ใบอนุญาตซอฟต์แวร์โอเพนซอร์ส';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get deleteAccountBody =>
      'ข้อมูลส่วนตัวของคุณจะถูกลบและไม่สามารถกู้คืนได้ กรุณายกเลิกการจองที่ยังดำเนินการอยู่ก่อน';

  @override
  String get couponsEmpty => 'ยังไม่มีคูปอง';

  @override
  String couponUntil(String date) {
    return 'ถึง $date';
  }

  @override
  String get couponUsed => 'ใช้แล้ว';

  @override
  String get couponExpired => 'หมดอายุ';

  @override
  String get couponAnyService => 'ใช้ได้ทุกบริการ';

  @override
  String get coupon_welcome_studio => 'คูปองต้อนรับ: สตูดิโอ';

  @override
  String get coupon_welcome_any => 'คูปองต้อนรับ';

  @override
  String get pointsBalance => 'คะแนนของคุณ';

  @override
  String get pointsEmpty => 'ไม่มีประวัติคะแนน';

  @override
  String get accountName => 'ชื่อ';

  @override
  String get accountPhone => 'โทรศัพท์มือถือ';

  @override
  String get accountEmail => 'อีเมล';

  @override
  String get accountLogin => 'วิธีเข้าสู่ระบบ';

  @override
  String get accountLoginPhone => 'ยืนยันด้วยเบอร์โทร';

  @override
  String get methodsEmpty => 'ยังไม่มีวิธีชำระเงิน';

  @override
  String get noContent => 'ยังไม่มีเนื้อหา';

  @override
  String get quoteTypeTitle => 'ต้องการทำความสะอาดแบบไหน';

  @override
  String get type_standard => 'ทำความสะอาดเมื่อย้ายออก (มาตรฐาน)';

  @override
  String get type_same_day_move => 'ย้ายออกวันเดียวกัน';

  @override
  String get type_some_luggage_left => 'ยังมีข้าวของเหลืออยู่บ้าง';

  @override
  String get type_normal_move_in => 'ทั่วไปก่อนย้ายเข้า';

  @override
  String get type_after_interior => 'หลังการตกแต่งภายใน';

  @override
  String get type_lived_in_deep_clean => 'ทำความสะอาดใหญ่ขณะยังอาศัยอยู่';

  @override
  String get luggageTitle => 'สภาพข้าวของในบ้านเป็นอย่างไร';

  @override
  String get luggage_empty => 'ไม่มีข้าวของ';

  @override
  String get luggage_partly_unpacked => 'จัดเก็บบางส่วน';

  @override
  String get luggage_fully_lived_in => 'มีข้าวของครบ (ยังอาศัยอยู่)';

  @override
  String get luggage_unknown => 'ไม่แน่ใจ';

  @override
  String get quoteBasicTitle => 'บอกเราเกี่ยวกับโครงสร้างบ้านหน่อย';

  @override
  String get buildingType => 'ประเภทอาคาร';

  @override
  String get building_apartment => 'อพาร์ตเมนต์';

  @override
  String get building_villa => 'อาคารขนาดเล็ก (วิลล่า)';

  @override
  String get building_officetel => 'ออฟฟิศเทล';

  @override
  String get building_house => 'บ้านเดี่ยว';

  @override
  String get building_other => 'อื่น ๆ';

  @override
  String get layoutTitle => 'ห้องแบบไหน';

  @override
  String get layout_studio => 'สตูดิโอ';

  @override
  String get layout_one_and_half => '1.5 ห้อง';

  @override
  String get layout_two_rooms => '2 ห้อง';

  @override
  String get layout_three_rooms => '3 ห้อง';

  @override
  String get layout_four_plus => '4 ห้องขึ้นไป';

  @override
  String get duplexTitle => 'เป็นดูเพล็กซ์ (2 ชั้น) ไหม';

  @override
  String get quoteSpaceTitle => 'ขอทราบรายละเอียดพื้นที่เพิ่มเติม';

  @override
  String get bathroomsLabel => 'ห้องน้ำ';

  @override
  String get balconiesLabel => 'ระเบียง · ห้องซักล้าง';

  @override
  String get elevatorTitle => 'มีลิฟต์ไหม';

  @override
  String get floor3Label => 'อยู่ชั้น 3 ขึ้นไป';

  @override
  String get quoteEstimateTitle => 'นี่คือราคาประมาณการ';

  @override
  String get quoteEstimateBody =>
      'ราคาสุดท้ายจะยืนยันในแชท หลังจากเราดูรูปภาพและสภาพบ้านแล้ว';

  @override
  String get quoteG1 => 'ราคาสุดท้ายจะตกลงกันในแชท';

  @override
  String get quoteG2 => 'มัดจำ 10% เพื่อยืนยัน ที่เหลือชำระหลังทำความสะอาด';

  @override
  String get quoteG3 => 'ยกเลิกได้ฟรีก่อนยืนยัน';

  @override
  String get quoteConfirmTitle => 'ตรวจสอบรายละเอียดคำขอ';

  @override
  String get quoteRequest => 'ส่งคำขอปรึกษา';

  @override
  String get quoteNoPayNow => 'ยังไม่ต้องชำระตอนนี้';

  @override
  String get summaryType => 'ประเภทการทำความสะอาด';

  @override
  String get summaryHome => 'ข้อมูลบ้าน';

  @override
  String get summaryDate => 'วันเข้าบริการ';

  @override
  String get cpTitle => 'นโยบายการยกเลิก';

  @override
  String cpWhen(String days) {
    return 'ก่อนวันเข้าบริการ $days วันขึ้นไป';
  }

  @override
  String get cpWhenSameDay => 'ในวันเข้าบริการ';

  @override
  String get cpFree => 'คืนเงินเต็มจำนวน';

  @override
  String cpFee(String percent, String fee, String refund) {
    return 'ค่าธรรมเนียม $percent% ($fee) คืนเงิน $refund';
  }

  @override
  String get cpClosed => 'ยกเลิกในแอปไม่ได้ (ทีมงานตรวจสอบ)';

  @override
  String get hhTitle => 'ข้อมูลครัวเรือน';

  @override
  String get hhAddPet => 'เพิ่มสัตว์เลี้ยง';

  @override
  String get hhPetCount => 'จำนวน';

  @override
  String get hhFloorLabel => 'ชั้น (ใส่ค่าลบสำหรับชั้นใต้ดิน)';

  @override
  String get hhElevator => 'มีลิฟต์';

  @override
  String get hhNotes => 'บันทึก';

  @override
  String get hhHint => 'บันทึกไว้กับที่อยู่นี้ และแก้ไขได้ในแต่ละการจอง';

  @override
  String get themeTitle => 'ธีม';

  @override
  String get themeDark => 'มืด';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeSystem => 'ตามระบบ';

  @override
  String get themeTip => 'เปลี่ยนธีม';

  @override
  String get err_price_changed =>
      'ราคาเปลี่ยนแล้ว กรุณาตรวจสอบใบเสนอราคาใหม่แล้วลองอีกครั้ง';

  @override
  String get err_checkout_closed => 'การชำระเงินนี้ปิดแล้ว กรุณาเริ่มใหม่';

  @override
  String get err_checkout_refunded => 'การชำระเงินนี้ถูกยกเลิกและคืนเงินแล้ว';

  @override
  String get err_already_paid => 'ชำระเงินแล้ว';

  @override
  String get err_quote_not_payable =>
      'ยังชำระใบเสนอราคานี้ไม่ได้ กรุณาติดต่อทีมงาน';

  @override
  String get err_payment_method_disabled => 'วิธีชำระเงินนี้ใช้ไม่ได้ในขณะนี้';

  @override
  String get err_invalid_payment_method =>
      'ใช้วิธีชำระเงินที่เลือกไม่ได้ กรุณาเลือกวิธีอื่น';

  @override
  String get err_balance_not_due => 'ยังไม่ถึงกำหนดชำระยอดคงเหลือ';

  @override
  String get err_invalid_slot => 'บริการนี้ไม่มีเวลาที่เลือก';

  @override
  String get err_booking_changed =>
      'การจองมีการเปลี่ยนแปลง กรุณารีเฟรชและตรวจสอบรายละเอียด';

  @override
  String get err_booking_closed => 'ไม่สามารถเปลี่ยนแปลงการจองนี้ได้อีก';

  @override
  String get err_reschedule_closed =>
      'ตอนนี้เลื่อนวันเข้าบริการไม่ได้ กรุณาติดต่อทีมงาน';

  @override
  String get err_too_many_open_requests =>
      'มีคำขอที่ยังไม่เสร็จมากเกินไป กรุณาทำให้เสร็จหนึ่งรายการก่อน';

  @override
  String get err_already_reviewed => 'คุณรีวิวการเข้าบริการนี้ไปแล้ว';

  @override
  String get err_identity_not_verified => 'กรุณายืนยันตัวตนให้เสร็จก่อน';

  @override
  String get err_email_taken => 'อีเมลนี้ถูกใช้แล้ว';

  @override
  String get err_invalid_email => 'กรุณาตรวจสอบอีเมล';

  @override
  String get err_file_too_large =>
      'ไฟล์มีขนาดใหญ่เกินไป กรุณาอัปโหลดไฟล์ที่เล็กกว่า';

  @override
  String get err_unsupported_image =>
      'ไม่รองรับรูปแบบรูปภาพนี้ กรุณาอัปโหลด JPG หรือ PNG';

  @override
  String get err_upload_quota =>
      'ถึงขีดจำกัดการอัปโหลดของวันนี้แล้ว กรุณาลองพรุ่งนี้';

  @override
  String get err_provider_unreachable =>
      'เชื่อมต่อบริการไม่ได้ กรุณาลองอีกครั้งในไม่กี่นาที';

  @override
  String get err_invalid_token => 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองอีกครั้ง';

  @override
  String get err_invalid_transition => 'ไม่สามารถเปลี่ยนสถานะแบบนี้ได้ในตอนนี้';

  @override
  String get err_job_not_started => 'กรุณาเริ่มงานก่อน';

  @override
  String get err_job_not_active => 'งานนี้ไม่ได้อยู่ในสถานะดำเนินการ';

  @override
  String get err_quote_locked => 'ใบเสนอราคาถูกล็อกแล้ว แก้ไขไม่ได้';

  @override
  String get err_request_closed => 'คำขอนี้ปิดแล้ว';

  @override
  String get err_team_full => 'ทีมเต็มแล้ว';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret ต้องขึ้นต้นด้วย whsec_';

  @override
  String get err_invalid_endpoint => 'Endpoint ต้องขึ้นต้นด้วย https://';

  @override
  String get err_invalid_bucket => 'ชื่อ bucket ไม่ถูกต้อง';

  @override
  String get err_invalid_region => 'ภูมิภาคไม่ถูกต้อง';

  @override
  String get err_invalid_retention => 'ระยะเวลาเก็บข้อมูลอยู่นอกช่วงที่กำหนด';

  @override
  String get err_invalid_service_account => 'ไฟล์ service account ไม่ถูกต้อง';

  @override
  String get err_invalid_mode => 'กรุณาเลือกโหมด AI ที่ถูกต้อง';

  @override
  String get err_invalid_model => 'ชื่อโมเดล AI ไม่ถูกต้อง';

  @override
  String get err_missing_field => 'กรุณากรอกข้อมูลที่จำเป็นให้ครบ';

  @override
  String get err_invalid_amount => 'กรุณากรอกจำนวนเงินที่ถูกต้อง';

  @override
  String get err_cannot_deactivate_self =>
      'ไม่สามารถปิดใช้งานบัญชีของตัวเองได้';

  @override
  String get err_invalid_coupon => 'คูปองนี้ไม่ถูกต้อง';

  @override
  String get err_settlement_state =>
      'ตอนนี้ไม่สามารถเปลี่ยนสถานะการชำระเงินได้';

  @override
  String get err_deposit_required => 'ต้องชำระเงินมัดจำก่อน';

  @override
  String get err_payout_state =>
      'สถานะการจ่ายเงินเปลี่ยนแล้ว กรุณารีเฟรชแล้วตรวจสอบอีกครั้ง';

  @override
  String get err_payout_provider => 'วิธีจ่ายเงินนี้ใช้ไม่ได้ในขณะนี้';

  @override
  String get err_unsupported_bank => 'ธนาคารนี้ยังไม่รองรับการจ่ายเงิน';

  @override
  String get err_toss_unverified =>
      'ยังใช้ Toss จ่ายเงินไม่ได้ กรุณาโอนเงินเอง';

  @override
  String get err_invalid_cap => 'กรุณาใส่ตัวเลขในช่วงที่อนุญาต';

  @override
  String get err_invalid_capacity => 'กรุณากรอกความจุที่ถูกต้อง';

  @override
  String get err_seller_declined =>
      'Toss ไม่อนุมัติการลงทะเบียนผู้ขาย กรุณาตรวจสอบข้อมูลธุรกิจ';

  @override
  String get err_payout_account_unverified =>
      'พาร์ทเนอร์นี้ยังไม่มีบัญชีรับเงินที่ยืนยันแล้ว กรุณายืนยันบัญชีก่อน';

  @override
  String get guestSheetTitle => 'เข้าสู่ระบบเพื่อดำเนินการต่อ';

  @override
  String get guestSheetBody =>
      'ข้อมูลที่คุณกรอกไว้จะถูกเก็บไว้ และดำเนินการต่อจากจุดเดิมทันที';

  @override
  String get greetMorning => 'สวัสดีตอนเช้า';

  @override
  String get greetAfternoon => 'สวัสดีตอนบ่าย';

  @override
  String get greetEvening => 'สวัสดีตอนเย็น';

  @override
  String get feedHeading => 'แนะนำสำหรับคุณ';

  @override
  String get feedTitleDue => 'ถึงเวลานัดทำความสะอาดครั้งต่อไปแล้ว';

  @override
  String get feedTitleRebook => 'จองพาร์ทเนอร์ 5 ดาวอีกครั้ง';

  @override
  String get feedTitleDraft => 'กลับไปดูใบเสนอราคาที่ค้างไว้';

  @override
  String get feedTitleSeasonal => 'การทำความสะอาดที่เหมาะกับฤดูนี้';

  @override
  String get feedTitleSize => 'ใบเสนอราคาจากขนาดบ้านที่บันทึกไว้';

  @override
  String get feedTitleSubscription => 'ประหยัดกว่าด้วยการสมัครสมาชิก';

  @override
  String get feedTitleDistrict => 'เพื่อนบ้านก็กำลังจองกันอยู่';

  @override
  String feedWhyCadence(String days) {
    return 'ผ่านมา $days วันนับจากการทำความสะอาดครั้งล่าสุด';
  }

  @override
  String feedWhyRated(String days) {
    return 'คุณให้พาร์ทเนอร์นี้ 5 ดาวเมื่อ $days วันก่อน';
  }

  @override
  String get feedWhyDraft => 'คุณมีใบเสนอราคาที่ยังไม่เสร็จในเครื่องนี้';

  @override
  String get feedWhySummer => 'เวลาที่ดีในการล้างแอร์ก่อนหน้าร้อน';

  @override
  String get feedWhyMoving => 'ช่วงย้ายเข้าและย้ายบ้านกำลังคึกคัก';

  @override
  String feedWhyHoliday(String days) {
    return 'อีก $days วันถึงการทำความสะอาดใหญ่ก่อนวันหยุด';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'ใบเสนอราคาทันทีสำหรับบ้าน $pyeong พยองที่บันทึกไว้';
  }

  @override
  String get feedWhyRepeat => 'ถ้าจองบ่อย การสมัครสมาชิกจะถูกกว่า';

  @override
  String feedWhyDistrict(String district, String count) {
    return 'สัปดาห์นี้มี $count บ้านใน $district จองแล้ว';
  }

  @override
  String get fFinance => 'การเงิน';

  @override
  String get fPeriodDay => 'วัน';

  @override
  String get fPeriodWeek => 'สัปดาห์';

  @override
  String get fPeriodMonth => 'เดือน';

  @override
  String get fPeriodCustom => 'กำหนดเอง';

  @override
  String get fFrom => 'เริ่ม';

  @override
  String get fTo => 'ถึง';

  @override
  String get fGross => 'ยอดชำระรวม';

  @override
  String get fRefunds => 'คืนเงิน';

  @override
  String get fNetRevenue => 'รายได้สุทธิ';

  @override
  String get fPlatformFee => 'ค่าธรรมเนียมแพลตฟอร์ม';

  @override
  String get fPaidOut => 'จ่ายให้พาร์ทเนอร์แล้ว';

  @override
  String get fPendingOut => 'รอจ่าย';

  @override
  String get fHeldOut => 'พักไว้';

  @override
  String get fVatEstimate => 'VAT (ประมาณการ)';

  @override
  String get fVatNote =>
      'ประมาณการจาก 10% ของค่าธรรมเนียมแพลตฟอร์ม โปรดตรวจสอบกับนักบัญชี';

  @override
  String get fAov => 'มูลค่าออเดอร์เฉลี่ย';

  @override
  String get fBookings => 'การจอง';

  @override
  String get fCancelRate => 'อัตราการยกเลิก';

  @override
  String get fDiscounts => 'ส่วนลดและคูปอง';

  @override
  String get fMethods => 'วิธีชำระเงิน';

  @override
  String get fTrend => 'แนวโน้ม';

  @override
  String fRangeDays(String n) {
    return '$n วันล่าสุด';
  }

  @override
  String get fRangeWeeks => '12 สัปดาห์ล่าสุด';

  @override
  String get fRangeMonths => '12 เดือนล่าสุด';

  @override
  String get fByPartner => 'รายได้ตามพาร์ทเนอร์';

  @override
  String get fByService => 'รายได้ตามบริการ';

  @override
  String get fExportTitle => 'ส่งออกข้อมูลบัญชี';

  @override
  String get fExportLedger => 'CSV สมุดรายการชำระเงิน';

  @override
  String get fExportSettlements => 'CSV การชำระบัญชี';

  @override
  String get fExportMonthly => 'CSV สรุปรายเดือน (นักบัญชี)';

  @override
  String get fDownload => 'ดาวน์โหลด CSV';

  @override
  String get fDownloadWebOnly => 'ดาวน์โหลด CSV ได้ที่คอนโซลเว็บ';

  @override
  String get fDownloadFailed => 'ดาวน์โหลดไม่สำเร็จ';

  @override
  String get fNoRecords => 'ไม่มีข้อมูลในช่วงนี้';

  @override
  String get fLoadFailed => 'โหลดข้อมูลการเงินไม่ได้';

  @override
  String get fRetry => 'ลองอีกครั้ง';

  @override
  String get fColPartner => 'พาร์ทเนอร์';

  @override
  String get fColJobs => 'งาน';

  @override
  String get fColSettled => 'ยอดชำระรวม';

  @override
  String get fColFee => 'ค่าธรรมเนียม';

  @override
  String get fColNet => 'สุทธิ';

  @override
  String get pEarnings => 'รายได้';

  @override
  String get pNextPayout => 'การจ่ายเงินครั้งถัดไป';

  @override
  String pNextPayoutOn(String date) {
    return 'จ่ายวันที่ $date';
  }

  @override
  String get pNoPayout => 'ยังไม่มีการจ่ายเงินที่กำหนดไว้';

  @override
  String get pPendingTotal => 'รอจ่าย';

  @override
  String get pPaidTotal => 'จ่ายแล้ว';

  @override
  String get pWeekly => 'รายสัปดาห์';

  @override
  String get pMonthly => 'รายเดือน';

  @override
  String proofHomes(String count) {
    return 'เดือนนี้ทำความสะอาดแล้ว $count หลัง';
  }

  @override
  String proofRating(String rating, String count) {
    return 'คะแนนเฉลี่ย $rating ดาว · รีวิว $count รายการ';
  }

  @override
  String get proofReviewsTitle => 'รีวิวล่าสุด';

  @override
  String get rebookTitle => 'จองบริการครั้งก่อนอีกครั้งไหม?';

  @override
  String rebookBody(String service, String date) {
    return '$service · เข้าบริการล่าสุด $date';
  }

  @override
  String get rebookButton => 'จองอีกครั้ง';

  @override
  String seatsLeft(String count) {
    return 'เหลือ $count ที่';
  }

  @override
  String get reviewSheetTitle => 'การทำความสะอาดครั้งนี้เป็นอย่างไรบ้าง?';

  @override
  String get reviewPhotosAdd => 'เพิ่มรูปภาพ';

  @override
  String get reviewPhotosHint => 'สูงสุด 5 รูป';

  @override
  String get reviewSaved => 'ขอบคุณสำหรับรีวิวของคุณ';

  @override
  String get reviewPhotoFailed => 'อัปโหลดรูปไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get referralTitle => 'ชวนเพื่อน รับคูปอง';

  @override
  String referralBody(String amount) {
    return 'เมื่อเพื่อนของคุณจองครั้งแรกเสร็จ คุณทั้งคู่จะได้คูปอง $amount';
  }

  @override
  String get referralCopy => 'คัดลอกรหัส';

  @override
  String get referralCopied => 'คัดลอกรหัสแนะนำแล้ว';

  @override
  String get referralClaimTitle => 'มีรหัสแนะนำไหม?';

  @override
  String get referralClaimField => 'กรอกรหัสแนะนำ';

  @override
  String get referralClaimButton => 'ใช้รหัส';

  @override
  String get referralClaimed => 'ใช้รหัสแนะนำแล้ว';

  @override
  String referralStats(String invited, String rewarded) {
    return 'ชวนแล้ว $invited คน · รับรางวัล $rewarded ครั้ง';
  }

  @override
  String get err_self_referral => 'ใช้รหัสของตัวเองไม่ได้';

  @override
  String get err_referee_already_booked =>
      'กรอกรหัสได้ก่อนการจองครั้งแรกเท่านั้น';

  @override
  String get err_already_referred => 'ใช้รหัสแนะนำไปแล้ว';

  @override
  String get err_invalid_referral_code => 'ตรวจสอบรหัสแนะนำอีกครั้ง';

  @override
  String get err_referral_disabled => 'ตอนนี้ปิดระบบแนะนำเพื่อน';

  @override
  String get err_invalid_photos => 'แนบได้เฉพาะรูปที่อัปโหลดผ่าน Malkkeum';

  @override
  String get welcomeOfferTitle => 'ส่วนลดการจองครั้งแรก';

  @override
  String get welcomeOfferBody =>
      'ใช้อัตโนมัติกับการจองครั้งแรกของลูกค้าใหม่ ไม่รวมกับคูปอง';

  @override
  String get offerKindAmount => 'จำนวนเงินคงที่ (วอน)';

  @override
  String get offerKindPercent => 'เปอร์เซ็นต์ (%)';

  @override
  String get offerValue => 'มูลค่าส่วนลด';

  @override
  String get offerEnabled => 'เปิดใช้';

  @override
  String get offerSaved => 'บันทึกแล้ว';

  @override
  String get referralSettingsTitle => 'รางวัลแนะนำเพื่อน';

  @override
  String get referralSettingsBody =>
      'จ่ายเมื่อการจองครั้งแรกของเพื่อนเสร็จและชำระเงินแล้ว บล็อกการแนะนำตัวเองและเบอร์ซ้ำ';

  @override
  String get referralRewardAmount => 'มูลค่ารางวัล (วอน)';

  @override
  String get reviewsModerationTitle => 'จัดการรีวิว';

  @override
  String get reviewHide => 'ซ่อน';

  @override
  String get reviewShow => 'แสดงอีกครั้ง';

  @override
  String get reviewHiddenTag => 'ซ่อนอยู่';

  @override
  String get growthAverageRating => 'คะแนนเฉลี่ย';

  @override
  String growthReviewCount(String count) {
    return 'รีวิว $count รายการ';
  }

  @override
  String get growthReferralConversion => 'อัตราการแนะนำสำเร็จ';

  @override
  String get growthTab => 'การเติบโต';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded จาก $invited';
  }

  @override
  String get locUseCurrent => 'ใช้ตำแหน่งปัจจุบันของฉัน';

  @override
  String get locConsentTitle => 'ข้อกำหนดบริการที่ใช้ตำแหน่งที่ตั้ง';

  @override
  String get locConsentBody =>
      'หากต้องการค้นหาที่อยู่จากตำแหน่งปัจจุบัน โปรดยอมรับข้อกำหนดบริการที่ใช้ตำแหน่งที่ตั้ง เราตรวจสอบตำแหน่งของคุณเพียงครั้งเดียวเมื่อคุณแตะ \"ใช้ตำแหน่งปัจจุบันของฉัน\" และใช้เพื่อแนะนำที่อยู่เท่านั้น พิกัดจะไม่ถูกจัดเก็บบนเซิร์ฟเวอร์ของเรา คุณถอนความยินยอมได้ทุกเมื่อในการตั้งค่าความยินยอม';

  @override
  String get locConsentAgree => 'ยอมรับและดำเนินการต่อ';

  @override
  String get locSuggestionTitle => 'นี่คือที่อยู่ของคุณใช่ไหม';

  @override
  String get locUseAddress => 'ใช้ที่อยู่นี้';

  @override
  String get locDenied => 'ไม่มีสิทธิ์เข้าถึงตำแหน่ง โปรดกรอกที่อยู่ด้วยตนเอง';

  @override
  String get locServicesOff =>
      'บริการตำแหน่งของอุปกรณ์ปิดอยู่ โปรดกรอกที่อยู่ด้วยตนเอง';

  @override
  String get locTimeout =>
      'การค้นหาตำแหน่งใช้เวลานานเกินไป โปรดกรอกที่อยู่ด้วยตนเอง';

  @override
  String get locNoAddress =>
      'ไม่พบที่อยู่สำหรับตำแหน่งของคุณ โปรดกรอกที่อยู่ด้วยตนเอง';

  @override
  String get uMaintenanceTitle => 'กำลังปิดปรับปรุงระบบ';

  @override
  String get uMaintenanceBody =>
      'เรากำลังปรับปรุงระบบเพื่อให้บริการดียิ่งขึ้น กรุณากลับมาใหม่ในภายหลัง';

  @override
  String get cmTab => 'แคมเปญ';

  @override
  String get cmNew => 'แคมเปญใหม่';

  @override
  String get cmAudience => 'กลุ่มลูกค้า';

  @override
  String get cmSegAll => 'ลูกค้าทั้งหมด';

  @override
  String get cmSegNever => 'ไม่เคยจอง';

  @override
  String cmSegLapsed(String days) {
    return 'จองครั้งล่าสุดเกิน $days วัน';
  }

  @override
  String get cmDays => 'จำนวนวัน';

  @override
  String cmConsentCount(String total, String consented) {
    return 'มีความยินยอมรับการตลาด $consented จาก $total คน';
  }

  @override
  String get cmChannel => 'ช่องทาง';

  @override
  String get cmPush => 'แจ้งเตือนในแอป';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'หัวข้อ';

  @override
  String get cmBody => 'ข้อความ';

  @override
  String get cmOptout => 'หมายเลขยกเลิกรับ (080)';

  @override
  String get cmPreview => 'ตัวอย่าง';

  @override
  String get cmSchedule => 'เวลาส่ง';

  @override
  String get cmSendNow => 'ส่งทันที';

  @override
  String get cmTestSend => 'ส่งทดสอบไปยังเบอร์ของฉัน';

  @override
  String get cmCreate => 'บันทึกแคมเปญ';

  @override
  String get cmNeedOptout => 'SMS ต้องมีหมายเลขยกเลิกรับ 080';

  @override
  String get cmLog => 'บันทึกการส่ง';

  @override
  String cmStatSent(String count) {
    return 'ส่งแล้ว $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'ไม่ยินยอม $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'ล้มเหลว $count';
  }

  @override
  String get cmSaved => 'บันทึกแคมเปญแล้ว';

  @override
  String anFunnel(String days) {
    return 'ฟันเนลหลังสมัคร (ย้อนหลัง $days วัน)';
  }

  @override
  String get anInstalls => 'เปิดแอป (ยินยอม)';

  @override
  String get anSignedUp => 'สมัครแล้ว';

  @override
  String get anQuoted => 'ขอใบเสนอราคา';

  @override
  String get anBooked => 'จองแล้ว';

  @override
  String get anPaid => 'ชำระแล้ว';

  @override
  String get anRepeat => 'ซื้อซ้ำ (2 ครั้งขึ้นไป)';

  @override
  String get anCohorts => 'กลุ่มรายสัปดาห์ (อัตราการจองตามสัปดาห์ที่สมัคร)';

  @override
  String anCohortSize(String count) {
    return 'สมัคร $count';
  }

  @override
  String anWeekAfter(String n) {
    return 'จองในสัปดาห์ที่ $n';
  }

  @override
  String get cOps => 'สถานะระบบ';

  @override
  String get oLevelGreen => 'ปกติ';

  @override
  String get oLevelYellow => 'ควรตรวจสอบ';

  @override
  String get oLevelRed => 'ต้องดำเนินการ';

  @override
  String get oOverall => 'สถานะเซิร์ฟเวอร์';

  @override
  String get oRefresh => 'รีเฟรช';

  @override
  String get oVersion => 'เวอร์ชัน';

  @override
  String get oUptime => 'ทำงานมาแล้ว';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours ชม. $minutes นาที';
  }

  @override
  String get oChecks => 'รายการตรวจสอบ';

  @override
  String get oCheckDb => 'ฐานข้อมูล';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'ตอบสนอง $ms ms · ขนาด $mb MB';
  }

  @override
  String get oCheckDisk => 'ดิสก์เซิร์ฟเวอร์';

  @override
  String oCheckDiskValue(String pct) {
    return 'ว่าง $pct%';
  }

  @override
  String get oCheckBackup => 'สำรองข้อมูลอัตโนมัติ';

  @override
  String oCheckBackupValue(String hours) {
    return 'สำรองล่าสุดเมื่อ $hours ชม. ที่แล้ว';
  }

  @override
  String get oCheckBackupNone => 'ยังไม่มีการสำรองข้อมูล';

  @override
  String get oCheckErrors => 'ข้อผิดพลาดของเซิร์ฟเวอร์ (24 ชม.)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'การชำระเงินที่ต้องตรวจ';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 ชม.)';
  }

  @override
  String get oCheckWebhook => 'แจ้งเตือนการชำระเงิน (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'ลายเซ็นไม่ผ่าน $count (24 ชม.)';
  }

  @override
  String get oIntegrations => 'บริการภายนอก';

  @override
  String get oIntNotSet => 'ยังไม่ได้ตั้งค่า';

  @override
  String oIntLastOk(String at) {
    return 'สำเร็จล่าสุด $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'ล้มเหลวล่าสุด $at ($code)';
  }

  @override
  String get oIntNever => 'ยังไม่มีการใช้งาน';

  @override
  String get oActDb =>
      'เชื่อมต่อฐานข้อมูลไม่ได้ รัน malkkeum logs บนเซิร์ฟเวอร์ และรีสตาร์ตหากยังเกิดซ้ำ';

  @override
  String get oActDisk =>
      'พื้นที่ว่างในดิสก์น้อยกว่า 10% ลบไฟล์สำรองเก่าหรือเพิ่มพื้นที่ดิสก์';

  @override
  String get oActBackup =>
      'การสำรองข้อมูลอัตโนมัติเลยกำหนด รัน malkkeum backup บนเซิร์ฟเวอร์และตรวจ backups/backup.log';

  @override
  String get oActErrors =>
      'มีข้อผิดพลาดของเซิร์ฟเวอร์มาก ดูบรรทัด error ใน malkkeum logs และส่งให้ผู้พัฒนาหากเกิดซ้ำ';

  @override
  String get oActPayments =>
      'อาจชำระเงินสำเร็จแล้วแต่ยังไม่ได้ดำเนินการอัตโนมัติ ตรวจใน PortOne และคืนเงินเองหากจำเป็น';

  @override
  String get oActWebhook =>
      'การตรวจลายเซ็นการแจ้งเตือนการชำระเงินไม่ผ่าน ใส่ webhook secret ใหม่ที่ ตั้งค่า > การชำระเงิน (PortOne)';

  @override
  String get oActIntegration =>
      'การเชื่อมต่อนี้ล้มเหลว ตรวจคีย์ในหน้าตั้งค่าแล้วกด Test connection';

  @override
  String get oActNotSet => 'ยังไม่ได้ตั้งค่า ใส่คีย์ในหน้าตั้งค่า';

  @override
  String get oAlerts => 'การตั้งค่าการแจ้งเตือน';

  @override
  String get oAlertsHint =>
      'หากมีปัญหา จะแจ้งในกล่องข้อความและส่ง SMS ถึงโทรศัพท์เจ้าของ ปัญหาเดิมจะส่งทุก 6 ชั่วโมง';

  @override
  String get oRuleSms => 'ส่ง SMS ไม่สำเร็จ';

  @override
  String get oRulePush => 'แจ้งเตือนแบบพุชไม่สำเร็จ';

  @override
  String get oRulePayment => 'การเชื่อมต่อการชำระเงินไม่สำเร็จ';

  @override
  String get oRuleStuck => 'การชำระเงินไม่ได้ดำเนินการอัตโนมัติ';

  @override
  String get oRuleSocial => 'เข้าสู่ระบบด้วยโซเชียลไม่สำเร็จ';

  @override
  String get oRuleBackup => 'ข้ามการสำรองข้อมูลอัตโนมัติ';

  @override
  String get oRuleDisk => 'ดิสก์เกือบเต็ม';

  @override
  String get oRuleAuth => 'กิจกรรมเข้าสู่ระบบที่น่าสงสัย';

  @override
  String get oQuietHours => 'ช่วงเวลาเงียบ';

  @override
  String get oQuietFrom => 'ตั้งแต่';

  @override
  String get oQuietTo => 'ถึง';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'ไม่แจ้งเตือนในช่วงนี้ และจะส่งหนึ่งข้อความหลังจบช่วง';

  @override
  String get oAlertPhone => 'โทรศัพท์รับการแจ้งเตือน';

  @override
  String get oAlertPhoneHint =>
      'เว้นว่างเพื่อใช้เบอร์ฝ่ายสนับสนุนในข้อมูลธุรกิจ';

  @override
  String get oSave => 'บันทึก';

  @override
  String get oSaved => 'บันทึกการตั้งค่าการแจ้งเตือนแล้ว';

  @override
  String get oSaveFailed => 'บันทึกไม่สำเร็จ ตรวจสอบค่าที่กรอก';

  @override
  String get oLoadFailed => 'โหลดสถานะไม่สำเร็จ';

  @override
  String get oBackupOffsite => 'สำรองข้อมูลภายนอก (S3)';

  @override
  String get oBackupOffsiteOff =>
      'ปิดอยู่ เปิดได้ที่ ตั้งค่า > สำรองข้อมูลภายนอก';

  @override
  String get oLastBackup => 'สำรองล่าสุด';

  @override
  String get oDiskFree => 'พื้นที่ว่าง';

  @override
  String get oNoData => 'ยังไม่มีข้อมูล';

  @override
  String get cIntBackup => 'สำรองข้อมูลภายนอก (รองรับ S3)';

  @override
  String get pTabJobs => 'งาน';

  @override
  String get pTabQuotes => 'ใบเสนอราคาของฉัน';

  @override
  String get pTabSchedule => 'ตารางงาน';

  @override
  String get pIntroTitle =>
      'งาน · ตารางงาน · การจ่ายเงิน\nสำหรับผู้เชี่ยวชาญด้านการทำความสะอาด';

  @override
  String get pIntroBody =>
      'ทำงานเฉพาะพื้นที่และเวลาที่คุณต้องการ รับเงินทุกสัปดาห์';

  @override
  String get pOnbTitle => 'ขอทราบข้อมูลของคุณหน่อย';

  @override
  String get pOnbName => 'ชื่อผู้ประกอบการ';

  @override
  String get pOnbTeam => 'ชื่อทีม';

  @override
  String get pOnbServices => 'บริการที่รับทำได้';

  @override
  String get pOnbAreas => 'พื้นที่ที่ให้บริการ';

  @override
  String get pOnbDone => 'สมัคร';

  @override
  String get pPendingTitle => 'บัญชีของคุณอยู่ระหว่างตรวจสอบ';

  @override
  String get pPendingBody =>
      'เราจะแจ้งเตือนเมื่อได้รับการอนุมัติ ระหว่างนี้กรุณาเพิ่มบัญชีรับเงิน';

  @override
  String get pSuspended =>
      'บัญชีของคุณถูกระงับชั่วคราว กรุณาติดต่อฝ่ายปฏิบัติการ';

  @override
  String get pDirect => 'จองทันที';

  @override
  String get pQuoteReq => 'คำขอใบเสนอราคา';

  @override
  String get pShowClosed => 'แสดงงานที่ปิดรับแล้ว';

  @override
  String get pSortNewest => 'ล่าสุดก่อน';

  @override
  String get pSortVisit => 'วันเข้าบริการใกล้ที่สุด';

  @override
  String get pSortAmount => 'ยอดสูงสุดก่อน';

  @override
  String get pNoJobs => 'ตอนนี้ยังไม่มีงานที่เหมาะกับคุณ';

  @override
  String get pNoJobsBody =>
      'ลองขยายบริการ พื้นที่ หรือเวลาทำงาน เพื่อดูงานได้มากขึ้น';

  @override
  String get pPayout => 'รายได้ที่คาดว่าจะได้รับ';

  @override
  String get pCustomerEstimate => 'ราคาประมาณการของลูกค้า';

  @override
  String get pNew => 'ใหม่';

  @override
  String get pClosed => 'ปิดรับแล้ว';

  @override
  String get pPrivacyNote =>
      'ที่อยู่ที่แน่นอนและข้อมูลลูกค้าจะแสดงหลังจากคุณรับงาน';

  @override
  String get pAccept => 'รับงาน';

  @override
  String get pAcceptConfirm => 'ต้องการรับงานนี้ไหม';

  @override
  String get pAcceptBody =>
      'งานจะถูกเพิ่มในตารางงานของคุณ และระบบจะแจ้งลูกค้าว่ามอบหมายทีมแล้ว หากยกเลิกภายใน 2 วันก่อนวันเข้าบริการจะถูกจำกัด';

  @override
  String get pAccepted => 'รับงานแล้ว';

  @override
  String get pSendQuote => 'ส่งใบเสนอราคา';

  @override
  String get pQuotePrice => 'ยอดที่ลูกค้าชำระ';

  @override
  String get pQuoteNote => 'ข้อความถึงทีมที่ปรึกษา';

  @override
  String get pQuoteSent => 'ส่งใบเสนอราคาแล้ว';

  @override
  String pFee(String rate) {
    return 'ค่าธรรมเนียม $rate%';
  }

  @override
  String get pYouGet => 'ยอดที่ได้รับ';

  @override
  String get pQuoteAll => 'ทั้งหมด';

  @override
  String get pQ_waiting => 'รอดำเนินการ';

  @override
  String get pQ_selected => 'ได้รับเลือก';

  @override
  String get pQ_rejected => 'ไม่ได้รับเลือก';

  @override
  String get pQ_closed => 'สิ้นสุดแล้ว';

  @override
  String get pUnseenOnly => 'เฉพาะผลลัพธ์ใหม่';

  @override
  String get pNoQuotes => 'ยังไม่มีใบเสนอราคาที่ส่ง';

  @override
  String get pMyQuote => 'ใบเสนอราคาของฉัน';

  @override
  String get pWithdraw => 'ถอนใบเสนอราคา';

  @override
  String get pWithdrawn => 'ถอนใบเสนอราคาแล้ว';

  @override
  String get pOnlyMine => 'เฉพาะของฉัน';

  @override
  String pJobsCount(String n) {
    return '$n งาน';
  }

  @override
  String get pNoSchedule => 'ไม่มีงานในวันนี้';

  @override
  String get pCancelledBanner =>
      'ลูกค้ายกเลิกงานนี้แล้ว ไม่สามารถทำเครื่องหมายว่าเสร็จได้';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'ขอเปลี่ยนวัน: $from → $to';
  }

  @override
  String get pRescheduleOk => 'เข้าบริการได้';

  @override
  String get pRescheduleNo => 'เข้าบริการไม่ได้';

  @override
  String get pCustomer => 'ลูกค้า';

  @override
  String get pCall => 'โทรผ่านหมายเลขปลอดภัย';

  @override
  String get pCallSoon => 'การโทรผ่านหมายเลขปลอดภัยจะเปิดใช้งานเมื่อเปิดบริการ';

  @override
  String get pQuietHours => 'กรุณาอย่าโทรหลัง 20:00 น.';

  @override
  String get pAssignee => 'ผู้รับผิดชอบ';

  @override
  String get pChangeAssignee => 'เปลี่ยนผู้รับผิดชอบ';

  @override
  String get pCustomerRequests => 'ความต้องการของลูกค้า';

  @override
  String get pHousehold => 'ข้อมูลครัวเรือน';

  @override
  String get pPets => 'สัตว์เลี้ยง';

  @override
  String get pPetDog => 'สุนัข';

  @override
  String get pPetCat => 'แมว';

  @override
  String get pPetBird => 'นก';

  @override
  String get pPetFish => 'ปลา';

  @override
  String get pPetOther => 'สัตว์อื่น';

  @override
  String get pAllergies => 'อาการแพ้และความไว';

  @override
  String get pPreferredProducts => 'ผลิตภัณฑ์ที่ต้องการ';

  @override
  String get pParking => 'ที่จอดรถ';

  @override
  String pFloor(String floor) {
    return 'ชั้น $floor';
  }

  @override
  String get pElevatorYes => 'มีลิฟต์';

  @override
  String get pElevatorNo => 'ไม่มีลิฟต์';

  @override
  String get pTeamMemo => 'บันทึกของทีม (ลูกค้าจะไม่เห็น)';

  @override
  String get pMemoSaved => 'บันทึกโน้ตแล้ว';

  @override
  String get pPayoutBreakdown => 'รายละเอียดการจ่ายเงิน';

  @override
  String get pAfterBalance => 'จ่ายเงินหลังลูกค้าชำระยอดคงเหลือ';

  @override
  String get pChatOps => 'แชทกับฝ่ายปฏิบัติการ';

  @override
  String get pComplete => 'เช็กลิสต์ปิดงาน';

  @override
  String get pBeforePhotos => 'รูปก่อนทำความสะอาด';

  @override
  String get pAfterPhotos => 'รูปหลังทำความสะอาด';

  @override
  String get pAddPhoto => 'เพิ่มรูป';

  @override
  String get pChecklist => 'รายการตรวจสอบ';

  @override
  String get pCheck1 => 'ทำความสะอาดทุกพื้นที่ที่ลูกค้าขอแล้ว';

  @override
  String get pCheck2 => 'จัดการขยะและเก็บอุปกรณ์เรียบร้อยแล้ว';

  @override
  String get pCheck3 => 'ตรวจสอบหน้าต่าง ไฟฟ้า และน้ำแล้ว';

  @override
  String get pCheck4 => 'ดำเนินการตามความต้องการของลูกค้าแล้ว';

  @override
  String get pCompleteCta => 'ทำเครื่องหมายว่าเสร็จ';

  @override
  String get pCompleteNeed =>
      'กรุณาอัปโหลดรูปอย่างน้อยอย่างละ 1 รูป และติ๊กรายการทุกข้อ';

  @override
  String get pCompleted => 'เยี่ยมมาก ขอบคุณสำหรับการทำงาน!';

  @override
  String pPayoutOn(String date, String amount) {
    return 'จะจ่าย $amount ในวันที่ $date';
  }

  @override
  String get pPayoutWaiting => 'กำหนดวันจ่ายเงินหลังลูกค้าชำระยอดคงเหลือ';

  @override
  String get pPendingPayout => 'ยอดรอจ่าย';

  @override
  String get pSettlements => 'ประวัติการจ่ายเงิน';

  @override
  String get pS_waiting_balance => 'รอยอดคงเหลือ';

  @override
  String get pS_pending => 'กำหนดจ่าย';

  @override
  String get pS_paid => 'จ่ายแล้ว';

  @override
  String get pS_held => 'พักการจ่าย';

  @override
  String get pReviews => 'รีวิวจากลูกค้า';

  @override
  String get pNoReviews => 'ยังไม่มีรีวิว';

  @override
  String get pReplyLater => 'ฟังก์ชันตอบกลับรีวิวจะเปิดเร็ว ๆ นี้';

  @override
  String get pServicesAreas => 'บริการ · พื้นที่';

  @override
  String get pPayoutAccount => 'บัญชีรับเงิน';

  @override
  String get pBank => 'ธนาคาร';

  @override
  String get pAccountNumber => 'เลขที่บัญชี';

  @override
  String get pHolder => 'ชื่อบัญชี';

  @override
  String get pVerified => 'ยืนยันแล้ว';

  @override
  String get pUnverified => 'กำลังตรวจสอบ';

  @override
  String get pAccountSaved =>
      'บันทึกบัญชีแล้ว เมื่อมีการเปลี่ยนแปลงจะตรวจสอบอีกครั้ง';

  @override
  String get pWorkSchedule => 'ตารางการทำงาน';

  @override
  String get pWeekdays => 'วันที่ทำงาน';

  @override
  String get pDayParts => 'ช่วงเวลาทำงาน';

  @override
  String get pDaysOff => 'วันหยุด';

  @override
  String get pAddDayOff => 'เพิ่มวันหยุด';

  @override
  String get pSaved => 'บันทึกแล้ว';

  @override
  String get pTeam => 'สมาชิกทีม';

  @override
  String get pOwner => 'หัวหน้าทีม';

  @override
  String get pInvited => 'ส่งคำเชิญแล้ว';

  @override
  String get pInvite => 'เชิญสมาชิก';

  @override
  String get pInviteSent => 'ส่งข้อความเชิญแล้ว';

  @override
  String get pRemove => 'นำออก';

  @override
  String get pNotifications => 'การแจ้งเตือน';

  @override
  String get pNotifyDirect => 'งานจองทันทีใหม่';

  @override
  String get pNotifyQuotes => 'คำขอใบเสนอราคา · ผลลัพธ์';

  @override
  String get pNotifyChat => 'ข้อความจากฝ่ายปฏิบัติการ';

  @override
  String get pQuietNight => 'ปิดการแจ้งเตือนตอนกลางคืน (22:00–08:00)';

  @override
  String get pNewInquiry => 'คำถามใหม่';

  @override
  String get pTopic_settlement => 'การจ่ายเงิน';

  @override
  String get pTopic_reschedule => 'เปลี่ยนวัน · ยกเลิก';

  @override
  String get pTopic_app => 'ความช่วยเหลือการใช้แอป';

  @override
  String get pOpsTeam => 'ฝ่ายปฏิบัติการ';

  @override
  String get pViewJob => 'ดูงาน';

  @override
  String pBookingNo(String n) {
    return 'การจองหมายเลข $n';
  }

  @override
  String get pSize => 'ขนาดพื้นที่';

  @override
  String get pSchedule => 'ตารางงาน';

  @override
  String get pSpace => 'ข้อมูลพื้นที่';

  @override
  String get pNavigate => 'เส้นทาง';

  @override
  String get pNavHint =>
      'เปิดที่อยู่ในแอปแผนที่ ถ้าไม่มีแอป จะเปิดแผนที่บนเว็บ';

  @override
  String get pOfflineSaved =>
      'ไม่มีสัญญาณ บันทึกไว้แล้วและจะส่งเมื่อกลับมาออนไลน์';

  @override
  String get pPhotoRetry => 'อัปโหลดอีกครั้ง';

  @override
  String get pPhotoWaiting =>
      'รูปที่อัปโหลดไม่สำเร็จจะส่งอัตโนมัติเมื่อออนไลน์';

  @override
  String pUploadedCount(String total, String done) {
    return 'อัปโหลดแล้ว $done/$total';
  }

  @override
  String get apPgPickMethod => 'เลือกวิธีการชำระเงิน';

  @override
  String get apPgConfirmTitle => 'ตรวจสอบการชำระเงิน';

  @override
  String get apPgConfirmBtn => 'ยืนยันการชำระเงิน';

  @override
  String get apPgProcessing => 'กำลังดำเนินการชำระเงิน…';

  @override
  String get apPgDoneTitle => 'ชำระเงินสำเร็จ';

  @override
  String get apPgReceiptTitle => 'ใบเสร็จรับเงินอิเล็กทรอนิกส์';

  @override
  String get apPgReceiptApproval => 'หมายเลขอนุมัติ';

  @override
  String get apPgReceiptMethod => 'วิธีการ';

  @override
  String get apPgReceiptAmount => 'จำนวนเงิน';

  @override
  String get apPgReceiptDone => 'เสร็จสิ้น';

  @override
  String get apPgVaIssued => 'ออกบัญชีเสมือนแล้ว (บัญชีทดสอบ)';

  @override
  String get apPgTestBadge => 'ทดสอบ';

  @override
  String get cIntPayout => 'การจ่ายเงินพาร์ทเนอร์';

  @override
  String get poTabSettlements => 'การชำระเงิน';

  @override
  String get poTabPayouts => 'การจ่ายเงิน';

  @override
  String get poState_requested => 'ขอแล้ว';

  @override
  String get poState_sent => 'ส่งแล้ว';

  @override
  String get poState_paid => 'จ่ายแล้ว';

  @override
  String get poState_failed => 'ล้มเหลว';

  @override
  String get poProviderManual => 'โอนด้วยตนเอง';

  @override
  String get poProviderToss => 'จ่ายผ่าน Toss';

  @override
  String get poShowAccount => 'แสดงบัญชี';

  @override
  String get poAccountTitle => 'รายละเอียดการโอน';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'โอนเงิน $amount วอน ไปยัง $holder · $bank · $account แล้วแตะยืนยัน';
  }

  @override
  String get poConfirmPaid => 'ทำเครื่องหมายว่าโอนแล้ว';

  @override
  String get poMarkFailed => 'ทำเครื่องหมายว่าล้มเหลว';

  @override
  String get poReasonTitle => 'สาเหตุที่ล้มเหลว';

  @override
  String get poReasonHint => 'เช่น บัญชีผิด, ยกเลิกการโอน';

  @override
  String get poSend => 'ส่งผ่าน Toss';

  @override
  String get poSync => 'ตรวจสอบสถานะ';

  @override
  String get poRetry => 'ลองอีกครั้ง';

  @override
  String get poNoPayouts => 'ยังไม่มีการจ่ายเงิน';

  @override
  String poRequestedToast(String n) {
    return 'สร้างคำขอจ่ายเงิน $n รายการแล้ว';
  }

  @override
  String get poReasonRequired => 'กรุณาใส่สาเหตุ';

  @override
  String get poRevealNote => 'การดูรายละเอียดบัญชีจะถูกบันทึกไว้';

  @override
  String get poSellerAction => 'ลงทะเบียนผู้ขาย';

  @override
  String get poSellerTitle => 'ลงทะเบียนเป็นผู้ขาย Toss';

  @override
  String get poSellerHint =>
      'ใช้บัญชีรับเงินที่ยืนยันแล้วของพาร์ทเนอร์ กรอกเฉพาะข้อมูลธุรกิจ';

  @override
  String get poSellerIndividual => 'บุคคลธรรมดา';

  @override
  String get poSellerCompany => 'ธุรกิจ';

  @override
  String get poSellerName => 'ชื่อ';

  @override
  String get poSellerRepresentative => 'ชื่อผู้แทน';

  @override
  String get poSellerRegNo => 'เลขทะเบียนธุรกิจ (10 หลัก)';

  @override
  String get poSellerEmail => 'อีเมลสำหรับการชำระ';

  @override
  String get poSellerPhone => 'โทรศัพท์';

  @override
  String get poSellerSubmit => 'ลงทะเบียน';

  @override
  String poSellerDone(String status) {
    return 'สถานะผู้ขาย: $status';
  }

  @override
  String get oFlags => 'สวิตช์ฟีเจอร์';

  @override
  String get oFlagBooking => 'การจอง';

  @override
  String get oFlagChat => 'แชต';

  @override
  String get oFlagAi => 'ผู้ช่วย AI';

  @override
  String get oFlagPayments => 'การชำระเงิน';

  @override
  String get oMaintenance => 'โหมดปิดปรับปรุง';

  @override
  String get oMaintenanceHint =>
      'เมื่อเปิด แอปลูกค้าและพาร์ทเนอร์จะแสดงหน้าปรับปรุงระบบ คอนโซลยังใช้งานได้';

  @override
  String get oMaintenanceMessage => 'ข้อความแจ้งปรับปรุงระบบ';

  @override
  String get oClientErrors => 'รายงานข้อผิดพลาดของแอป';

  @override
  String get oClientErrorsHint =>
      'ข้อผิดพลาดล่าสุดจากเว็บ Windows และคอนโซล ข้อมูลส่วนตัวถูกซ่อนอัตโนมัติ';

  @override
  String get oClientErrorsEmpty => 'ไม่มีข้อผิดพลาดล่าสุด';

  @override
  String get oHeartbeat => 'Heartbeat ตรวจสถานะ';

  @override
  String get oHeartbeatOn =>
      'เชื่อมแล้ว ระบบภายนอกจะได้รับสัญญาณขณะเซิร์ฟเวอร์ทำงาน';

  @override
  String get oHeartbeatOff =>
      'ยังไม่ตั้งค่า: เพิ่ม MALKKEUM_HEARTBEAT_URL ใน install.sh';

  @override
  String get pvManage => 'จัดการความยินยอม';

  @override
  String get pvOptional => 'ไม่บังคับ';

  @override
  String get pvTerms => 'ยอมรับข้อกำหนดการใช้บริการ';

  @override
  String get pvPrivacy => 'ยินยอมให้เก็บและใช้ข้อมูลส่วนบุคคล';

  @override
  String get pvOverseas => 'ยินยอมให้โอนข้อมูลส่วนบุคคลไปต่างประเทศ';

  @override
  String get pvMarketing => 'รับข้อความการตลาด';

  @override
  String get pvMarketingHint =>
      'รับข่าวคูปองและกิจกรรมทาง SMS, KakaoTalk และแจ้งเตือนในแอป ปิดได้ทุกเมื่อ';

  @override
  String get pvReconsent =>
      'นโยบายความเป็นส่วนตัวของเราเปลี่ยนแปลงแล้ว กรุณาตรวจสอบและยอมรับอีกครั้ง';

  @override
  String get pvSaved => 'บันทึกการตั้งค่าความยินยอมแล้ว';

  @override
  String get pvExport => 'ดาวน์โหลดข้อมูลของฉัน';

  @override
  String get pvExportHint =>
      'แสดงข้อมูลทั้งหมดที่เราเก็บเกี่ยวกับคุณในรูปแบบ JSON คัดลอกและเก็บไว้ได้';

  @override
  String get pvCopy => 'คัดลอก';

  @override
  String get pvCopied => 'คัดลอกแล้ว';

  @override
  String get pvExportFailed =>
      'ไม่สามารถโหลดข้อมูลของคุณได้ กรุณาลองใหม่อีกครั้งภายหลัง';

  @override
  String get safetyEmergency => 'ติดต่อฉุกเฉิน';

  @override
  String get emergencyPolice => '112 ตำรวจ';

  @override
  String get emergencyFire => '119 ดับเพลิงและกู้ภัย';

  @override
  String get emergencyShop => 'ฝ่ายบริการลูกค้า';

  @override
  String get caseReportAction => 'แจ้งปัญหา';

  @override
  String get caseReportTitle => 'เกิดอะไรขึ้น?';

  @override
  String get caseKindDamage => 'ความเสียหาย';

  @override
  String get caseKindLoss => 'สูญหาย';

  @override
  String get caseKindComplaint => 'ร้องเรียน';

  @override
  String get caseKindNoShow => 'ทีมทำความสะอาดไม่มา';

  @override
  String get caseKindSafety => 'ปัญหาความปลอดภัย';

  @override
  String get caseKindPayment => 'ข้อพิพาทการชำระเงิน';

  @override
  String get caseSummaryHint => 'อธิบายสิ่งที่เกิดขึ้น (ไม่เกิน 300 ตัวอักษร)';

  @override
  String get caseSubmit => 'ส่ง';

  @override
  String get caseSubmitted => 'รับเรื่องแล้ว ทีมงานจะตอบกลับภายใน 24 ชั่วโมง';

  @override
  String get caseFailed => 'ส่งไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get checkInAction => 'เช็คอิน';

  @override
  String get checkOutAction => 'เช็คเอาต์';

  @override
  String checkedInAt(String time) {
    return 'มาถึง $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'ออกเมื่อ $time';
  }

  @override
  String get entryCodeAction => 'แสดงรหัสเข้าอาคาร';

  @override
  String get entryCodeTitle => 'รหัสเข้าอาคาร';

  @override
  String get entryCodeNotToday => 'ดูได้เฉพาะวันที่เข้าบริการ';

  @override
  String get entryCodeEmpty => 'ยังไม่มีรหัสเข้าอาคาร';

  @override
  String get actionFailed => 'ดำเนินการไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get consoleCasesTitle => 'คิวเคส';

  @override
  String get consoleCasesEmpty => 'ไม่มีเคสที่เปิดอยู่';

  @override
  String get caseOverdue => 'เกินกำหนด';

  @override
  String get caseStatusOpen => 'เปิดแล้ว';

  @override
  String get caseStatusInvestigating => 'กำลังตรวจสอบ';

  @override
  String get caseStatusResolved => 'แก้ไขแล้ว';

  @override
  String get caseStatusRejected => 'ปฏิเสธ';

  @override
  String get caseReassign => 'มอบหมายพาร์ทเนอร์ใหม่';

  @override
  String get caseRefund => 'คืนเงิน';

  @override
  String get caseHold => 'พักการโอนเงิน';

  @override
  String get caseNoteHint => 'บันทึกภายใน';

  @override
  String get caseSave => 'บันทึก';

  @override
  String get cSetup => 'ตั้งค่า';

  @override
  String get cSetupTitle => 'เตรียมพร้อมเปิดบริการ';

  @override
  String cSetupProgress(String done, String total) {
    return 'เสร็จแล้ว $done/$total';
  }

  @override
  String get cSetupAllDone => 'ทุกอย่างพร้อมแล้ว!';

  @override
  String get cSetupBusiness => 'ข้อมูลธุรกิจ';

  @override
  String get cSetupBusinessName => 'ชื่อบริการ';

  @override
  String get cSetupSupportPhone => 'โทรศัพท์ฝ่ายบริการ';

  @override
  String get cSetupSupportEmail => 'อีเมลฝ่ายบริการ';

  @override
  String get cSetupSupportHours => 'เวลาให้บริการ';

  @override
  String get cSetupColor => 'สีแบรนด์';

  @override
  String get cSetupLogo => 'อัปโหลดโลโก้';

  @override
  String get cSetupCompany => 'ข้อมูลบริษัท (แสดงท้ายแอปและเว็บไซต์)';

  @override
  String get cSetupLegalName => 'ชื่อนิติบุคคล';

  @override
  String get cSetupCeo => 'ผู้แทน';

  @override
  String get cSetupRegNo => 'เลขทะเบียนธุรกิจ';

  @override
  String get cSetupMailOrderNo => 'เลขทะเบียนพาณิชย์อิเล็กทรอนิกส์';

  @override
  String get cSetupAddress => 'ที่อยู่';

  @override
  String get cSetupPrivacyOfficer => 'เจ้าหน้าที่คุ้มครองข้อมูล';

  @override
  String get cSetupStoreLinks =>
      'ลิงก์ร้านค้าแอป (กรอกแล้วปุ่มบนเว็บจะเปิดใช้)';

  @override
  String get cSetupCustomerApp => 'แอปลูกค้า';

  @override
  String get cSetupPartnerApp => 'แอปพาร์ทเนอร์';

  @override
  String get cSetupPayMethods => 'วิธีชำระเงิน';

  @override
  String get cSetupPayMethodsHint =>
      'เปิดหรือปิดวิธีชำระเงินที่ลูกค้าเห็น มีผลทันที';

  @override
  String get cReviewTitle => 'บัญชีเดโมสำหรับการตรวจสอบแอป';

  @override
  String get cReviewHint =>
      'ผู้ตรวจสอบรับ SMS เกาหลีไม่ได้ ใส่หมายเลขและรหัส 6 หลักในบันทึกการตรวจสอบ ปิดอัตโนมัติเมื่อหมดเวลา';

  @override
  String get cReviewPhone => 'เบอร์โทรเดโม';

  @override
  String get cReviewCode => 'รหัสคงที่ (6 หลัก)';

  @override
  String cReviewActiveUntil(String date) {
    return 'ใช้ได้ถึง $date';
  }

  @override
  String get cReviewEnable => 'เปิด (14 วัน)';

  @override
  String get pDeleteAccountBody =>
      'ทีมและข้อมูลส่วนตัวจะถูกลบถาวร กรุณาทำงานที่ได้รับและยอดค้างจ่ายให้เสร็จก่อน';

  @override
  String get err_has_active_jobs =>
      'คุณยังมีงานที่ได้รับอยู่ ทำให้เสร็จหรือขอให้ฝ่ายบริการโอนงาน';

  @override
  String get err_pending_payouts =>
      'ยังมียอดค้างจ่าย ลบบัญชีได้หลังได้รับเงินแล้ว';

  @override
  String get err_phone_required => 'ยืนยันเบอร์โทรก่อนรับงาน';

  @override
  String get nAlerts => 'การแจ้งเตือน';

  @override
  String get nEmpty => 'ยังไม่มีการแจ้งเตือน';

  @override
  String nUnread(String count) {
    return 'ยังไม่อ่าน $count รายการ';
  }

  @override
  String get pVerifyPhone => 'ยืนยัน';

  @override
  String get mMyJobs => 'งานของฉัน';

  @override
  String get mNoJobs =>
      'ยังไม่มีงานที่ได้รับ งานที่หัวหน้าทีมมอบหมายจะแสดงที่นี่';

  @override
  String mTeam(String team) {
    return 'สมาชิกของ $team';
  }

  @override
  String get cSetupSave => 'บันทึก';

  @override
  String get cSetupSaved => 'บันทึกแล้ว';

  @override
  String get cSetupTest => 'ทดสอบการเชื่อมต่อ';

  @override
  String get cSetupClear => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get cSetupConnected => 'เชื่อมต่อแล้ว';

  @override
  String get cSetupNotConnected => 'ยังไม่เชื่อมต่อ';

  @override
  String get cSetupFromEnv => 'ใช้การตั้งค่าเซิร์ฟเวอร์';

  @override
  String get cSetupCheckInApp => 'บันทึกแล้ว · ยืนยันโดยเข้าสู่ระบบจากแอป';

  @override
  String get cSetupInvalidKey => 'คีย์ไม่ถูกต้อง โปรดตรวจสอบค่าที่คัดลอก';

  @override
  String get cSetupUnreachable => 'เชื่อมต่อบริการไม่ได้ ลองใหม่ภายหลัง';

  @override
  String get cSetupKeepValue => 'บันทึกแล้ว (กรอกเฉพาะเมื่อต้องการเปลี่ยน)';

  @override
  String get cSetupGuide => 'วิธีตั้งค่า';

  @override
  String get cSetupOpenSite => 'เปิดเว็บไซต์';

  @override
  String get cSetupWebhook => 'ที่อยู่ Webhook (วางในคอนโซล PortOne)';

  @override
  String get cCopied => 'คัดลอกแล้ว';

  @override
  String get cSetupDevMode => 'โหมดทดสอบ: ไม่มีการชำระเงินหรือส่งข้อความจริง';

  @override
  String get cSetupOptional => 'ไม่บังคับ';

  @override
  String get cIntPortone => 'การชำระเงิน (PortOne)';

  @override
  String get cIntSolapi => 'SMS และ KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'การแจ้งเตือนแอป (Firebase)';

  @override
  String get cIntKakao => 'เข้าสู่ระบบด้วย Kakao';

  @override
  String get cIntNaver => 'เข้าสู่ระบบด้วย Naver';

  @override
  String get cIntGoogle => 'เข้าสู่ระบบด้วย Google';

  @override
  String get cIntApple => 'เข้าสู่ระบบด้วย Apple';

  @override
  String get cFirstRunTitle => 'ยินดีต้อนรับ! สร้างบัญชีเจ้าของ';

  @override
  String get cFirstRunBody =>
      'กรอกรหัส 12 ตัวที่แสดงตอนติดตั้ง บัญชีนี้จัดการการตั้งค่าทั้งหมด';

  @override
  String get cFirstRunCode => 'รหัสติดตั้ง';

  @override
  String get cName => 'ชื่อ';

  @override
  String get cFirstRunCreate => 'สร้างบัญชีและเริ่ม';

  @override
  String get cWrongSetupCode => 'รหัสติดตั้งไม่ถูกต้อง';

  @override
  String get cWeakPassword => 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร';

  @override
  String get cInvalidValue => 'โปรดตรวจสอบค่าที่กรอก';

  @override
  String get cMfaTitle => 'การยืนยันสองขั้นตอน';

  @override
  String get cMfaCode => 'รหัส 6 หลักจากแอปยืนยันตัวตน';

  @override
  String get cMfaRecovery => 'รหัสกู้คืน';

  @override
  String get cMfaUseRecovery => 'ใช้รหัสกู้คืนแทน';

  @override
  String get cMfaUseCode => 'ใช้รหัสจากแอปยืนยันตัวตนแทน';

  @override
  String get cMfaVerify => 'ยืนยัน';

  @override
  String get cMfaBack => 'กลับไปหน้าเข้าสู่ระบบ';

  @override
  String get cMfaEnrolTitle => 'ตั้งค่าการยืนยันสองขั้นตอน';

  @override
  String get cMfaEnrolBody =>
      'ผู้ดูแลต้องใช้แอปยืนยันตัวตน เพิ่มคีย์ด้านล่างลงใน Google Authenticator, 1Password หรือแอปที่คล้ายกัน แล้วกรอกรหัส 6 หลักที่แอปแสดง';

  @override
  String get cMfaSecret => 'คีย์ตั้งค่า';

  @override
  String get cMfaLink => 'ลิงก์ตั้งค่า (otpauth)';

  @override
  String get cMfaCopy => 'คัดลอก';

  @override
  String get cMfaCopied => 'คัดลอกแล้ว';

  @override
  String get cMfaConfirm => 'ยืนยันและเปิดใช้งาน';

  @override
  String get cMfaCodesTitle => 'บันทึกรหัสกู้คืนของคุณ';

  @override
  String get cMfaCodesBody =>
      'หากทำแอปยืนยันตัวตนหาย แต่ละรหัสใช้เข้าสู่ระบบได้หนึ่งครั้ง แสดงเพียงครั้งเดียวตอนนี้';

  @override
  String get cMfaDownload => 'ดาวน์โหลด';

  @override
  String get cMfaSaveFailed =>
      'อุปกรณ์นี้บันทึกไฟล์ไม่ได้ กรุณาคัดลอกรหัสและเก็บไว้ให้ปลอดภัย';

  @override
  String get cMfaContinue => 'ไปที่คอนโซล';

  @override
  String get cMfaInvalid =>
      'รหัสไม่ตรงกัน ตรวจสอบว่านาฬิกาในโทรศัพท์ถูกต้อง แล้วลองอีกครั้ง';

  @override
  String get cMfaExpired =>
      'การเข้าสู่ระบบหมดอายุ เริ่มใหม่ตั้งแต่ขั้นตอนรหัสผ่าน';

  @override
  String get cMfaLocked => 'พยายามหลายครั้งเกินไป รอสักครู่แล้วลองอีกครั้ง';

  @override
  String get cStaffReset => 'รีเซ็ตรหัสผ่าน';

  @override
  String get cStaffResetConfirm =>
      'รีเซ็ตรหัสผ่านของพนักงานคนนี้ไหม? พนักงานจะถูกออกจากระบบทุกที่';

  @override
  String get cStaffResetTitle => 'โทเคนรีเซ็ต';

  @override
  String get cStaffResetBody =>
      'ส่งโทเคนนี้ให้พนักงาน ใช้ได้ครั้งเดียวภายใน 30 นาที ปิดหน้านี้แล้วจะดูอีกไม่ได้';

  @override
  String get subTitle => 'ทำความสะอาดประจำ';

  @override
  String get subNew => 'สมัครบริการ';

  @override
  String get subCadence => 'ความถี่';

  @override
  String get subWeekly => 'ทุกสัปดาห์';

  @override
  String get subBiweekly => 'ทุก 2 สัปดาห์';

  @override
  String get subEvery4Weeks => 'ทุก 4 สัปดาห์';

  @override
  String get subWeekday => 'วัน';

  @override
  String get subHour => 'เวลาที่มาถึง';

  @override
  String subDiscountNote(String percent) {
    return 'ลด $percent% ทุกครั้งที่เข้าบริการ';
  }

  @override
  String get subChargeNote =>
      'เรียกเก็บเงินจากบัตรที่บันทึกไว้ล่วงหน้า 1 วันก่อนเข้าบริการ';

  @override
  String get subCreate => 'สมัคร';

  @override
  String get subCreated => 'เริ่มการสมัครแล้ว';

  @override
  String get subNeedAddress => 'กรุณาเพิ่มที่อยู่สำหรับเข้าบริการก่อน';

  @override
  String get subListEmpty => 'ยังไม่มีการสมัคร';

  @override
  String get subStatusActive => 'ใช้งานอยู่';

  @override
  String get subStatusPaused => 'หยุดชั่วคราว';

  @override
  String get subStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String subNextVisit(String date) {
    return 'การเข้าบริการครั้งถัดไป $date';
  }

  @override
  String get subPause => 'หยุดชั่วคราว';

  @override
  String get subResume => 'ดำเนินการต่อ';

  @override
  String get subCancelSub => 'ยกเลิกการสมัคร';

  @override
  String get subCancelConfirm =>
      'การเข้าบริการที่จะถึงจะถูกยกเลิก การเข้าบริการที่จองไว้ต้องยกเลิกแยก';

  @override
  String get subSkip => 'ข้ามครั้งนี้';

  @override
  String get subMove => 'เลื่อนวัน';

  @override
  String get subVisitLocked => 'เปลี่ยนไม่ได้ตั้งแต่วันก่อนเข้าบริการ';

  @override
  String get subPausedPayment =>
      'หยุดชั่วคราวเพราะชำระเงินไม่สำเร็จหลายครั้ง เปลี่ยนบัตรแล้วดำเนินการต่อ';

  @override
  String get subStatePlanned => 'กำหนดไว้';

  @override
  String get subStateBooked => 'จองแล้ว';

  @override
  String get subStateSkipped => 'ข้ามแล้ว';

  @override
  String get subStateMissed => 'พลาดไป';

  @override
  String get pSubsTitle => 'ลูกค้าประจำ';

  @override
  String get pSubsEmpty => 'ยังไม่มีลูกค้าประจำ';

  @override
  String get cSubsTitle => 'การสมัครใช้บริการ';

  @override
  String get cSubsEdit => 'แก้ไขแทนลูกค้า';

  @override
  String get cMrr => 'รายได้ประจำต่อเดือน (MRR)';

  @override
  String get cChurn => 'อัตราการยกเลิก';

  @override
  String get cActiveSubs => 'การสมัครที่ใช้งานอยู่';

  @override
  String get cRecognized => 'รายได้ที่รับรู้ในช่วงเวลา';

  @override
  String get cSubsLoadFailed => 'โหลดการสมัครไม่สำเร็จ';

  @override
  String get tTaxSection => 'ภาษี';

  @override
  String tVatQuarter(String q) {
    return 'CSV ภาษีมูลค่าเพิ่ม ไตรมาส $q';
  }

  @override
  String get tVatYear => 'ปี';

  @override
  String get tExportWithholding => 'CSV หนังสือรับรองการหักภาษี';

  @override
  String get tExportTaxInvoices => 'CSV สำหรับอัปโหลดใบกำกับภาษี';

  @override
  String get tTaxLayoutNote =>
      'ตรวจคอลัมน์กับแม่แบบ 홈택스 ก่อนอัปโหลด ยังไม่ได้ยืนยันรูปแบบ';

  @override
  String get tCashReceipts => 'ใบเสร็จเงินสด';

  @override
  String get tCashIssued => 'ออกแล้ว';

  @override
  String get tCashFailed => 'ล้มเหลว';

  @override
  String get tCashPending => 'รอดำเนินการ';

  @override
  String get tCashCancelled => 'ยกเลิกแล้ว';

  @override
  String get tReissue => 'ออกใหม่';

  @override
  String get tTaxInvoices => 'ใบกำกับภาษี';

  @override
  String get tApprovalNumber => 'เลขที่อนุมัติ';

  @override
  String get tIssuedOn => 'วันที่ออก';

  @override
  String get tMarkIssued => 'ทำเครื่องหมายว่าออกแล้ว';

  @override
  String get tQueueEmpty => 'ไม่มีคำขอที่รอดำเนินการ';

  @override
  String get tWithholdingLabel => 'หัก ณ ที่จ่าย';

  @override
  String get tGrossAmount => 'ยอดรวม';

  @override
  String get tIncomeTax => 'ภาษีเงินได้';

  @override
  String get tLocalTax => 'ภาษีเงินได้ท้องถิ่น';

  @override
  String get tNetAmount => 'ยอดสุทธิ';

  @override
  String get tNoWithholding => 'ไม่หัก ณ ที่จ่าย (ธุรกิจจดทะเบียน)';

  @override
  String get tEstWithholding => 'ประมาณการหัก ณ ที่จ่าย (รอจ่าย)';

  @override
  String get tReceiptOptions => 'ตัวเลือกใบเสร็จ';

  @override
  String get tWantCashReceipt => 'ขอใบเสร็จเงินสด';

  @override
  String get tCashForIncome => 'สำหรับลดหย่อนภาษี (เบอร์โทร)';

  @override
  String get tCashForBusiness => 'สำหรับค่าใช้จ่ายธุรกิจ (เลขธุรกิจ)';

  @override
  String get tWantTaxInvoice => 'ขอใบกำกับภาษี (ธุรกิจ)';

  @override
  String get tPhoneForReceipt => 'เบอร์โทรศัพท์';

  @override
  String get tBusinessNumber => 'เลขทะเบียนธุรกิจ';

  @override
  String get tCompanyName => 'ชื่อบริษัท';

  @override
  String get tRepresentative => 'ผู้แทน';

  @override
  String get tInvoiceEmail => 'อีเมลสำหรับใบกำกับภาษี';

  @override
  String get tReceiptSave => 'บันทึกและชำระเงิน';

  @override
  String get tReceiptSaveFailed => 'บันทึกข้อมูลใบเสร็จไม่สำเร็จ';

  @override
  String get tTaxType => 'ประเภทภาษี';

  @override
  String get tTaxFreelancer => 'ฟรีแลนซ์ (หักภาษี)';

  @override
  String get tTaxBusiness => 'ธุรกิจจดทะเบียน (ไม่หักภาษี)';

  @override
  String get tReceiptSettings => 'การตั้งค่าใบเสร็จ';

  @override
  String get reviewRuleLine =>
      'ห้ามใช้ถ้อยคำหยาบคาย ข้อมูลส่วนบุคคล เนื้อหาปลอมหรือโฆษณา รีวิวที่ถูกรายงานจะถูกซ่อน';

  @override
  String get reportAction => 'รายงาน';

  @override
  String get reportSheetTitle => 'รายงานรีวิวนี้ใช่ไหม';

  @override
  String get reportReasonSpam => 'สแปมหรือโฆษณา';

  @override
  String get reportReasonOffensive => 'ดูหมิ่นหรือเกลียดชัง';

  @override
  String get reportReasonPersonal => 'มีข้อมูลส่วนบุคคล';

  @override
  String get reportReasonOther => 'อื่นๆ';

  @override
  String get reportNoteHint => 'รายละเอียด (ไม่บังคับ ไม่เกิน 300 ตัวอักษร)';

  @override
  String get reportSubmit => 'ส่งรายงาน';

  @override
  String get reportThanks => 'ขอบคุณ ทีมงานจะตรวจสอบ';

  @override
  String get reportAlready => 'คุณรายงานรีวิวนี้ไปแล้ว';

  @override
  String get reportFailed => 'ส่งรายงานไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get reviewBlocked => 'บัญชีนี้ถูกจำกัดการรีวิว โปรดติดต่อฝ่ายสนับสนุน';

  @override
  String get modTitle => 'รีวิวที่ถูกรายงาน';

  @override
  String get modEmpty => 'ไม่มีรายงานที่รอดำเนินการ';

  @override
  String modReports(String count) {
    return '$count รายงาน';
  }

  @override
  String get modKeep => 'คงไว้';

  @override
  String get modHide => 'ซ่อน';

  @override
  String get modDelete => 'ลบ';

  @override
  String get modBlockAuthor => 'จำกัดผู้เขียน';

  @override
  String get modUnblockAuthor => 'ยกเลิกการจำกัด';

  @override
  String get modDone => 'เสร็จแล้ว';

  @override
  String get modFailed => 'ดำเนินการไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get modHidden => 'รีวิวที่ซ่อนอยู่';

  @override
  String uUpdateBanner(String version) {
    return 'มีเวอร์ชันใหม่ $version';
  }

  @override
  String get uUpdateNow => 'อัปเดต';

  @override
  String get uUpdateLater => 'ไว้ทีหลัง';

  @override
  String get uUpdateRequiredTitle => 'ต้องอัปเดตแอป';

  @override
  String get uUpdateRequiredBody =>
      'เวอร์ชันนี้ไม่รองรับแล้ว กรุณาอัปเดตจากสโตร์';

  @override
  String get uUpdateStore => 'อัปเดตจากสโตร์';

  @override
  String get uUpdateStoreMissing =>
      'ลิงก์อัปเดตยังไม่พร้อม กรุณาลองใหม่ภายหลัง';

  @override
  String uCurrentVersion(String version) {
    return 'เวอร์ชันปัจจุบัน $version';
  }

  @override
  String get uAppVersionTitle => 'เวอร์ชันแอป';

  @override
  String get uAppVersionHint =>
      'แอปที่ต่ำกว่าเวอร์ชันขั้นต่ำจะค้างที่หน้าอัปเดต ตัวอย่าง: 1.2.0';

  @override
  String get uMinVersion => 'เวอร์ชันขั้นต่ำ';

  @override
  String get uLatestVersion => 'เวอร์ชันล่าสุด';

  @override
  String get walletTitle => 'กระเป๋าพอยท์';

  @override
  String get walletBalance => 'พอยท์ที่ใช้ได้';

  @override
  String walletPoints(String count) {
    return '$count P';
  }

  @override
  String walletExpiring(String days, String count) {
    return 'พอยท์ $count P จะหมดอายุภายใน $days วัน';
  }

  @override
  String get walletOff => 'ยังไม่เปิดโปรแกรมพอยท์';

  @override
  String get walletEmpty => 'ยังไม่มีรายการพอยท์';

  @override
  String get walletHistory => 'รายการล่าสุด';

  @override
  String get walletKindEarn => 'คืนเงินจากการจอง';

  @override
  String get walletKindWelcome => 'พอยท์ต้อนรับ';

  @override
  String get walletKindReferral => 'รางวัลแนะนำเพื่อน';

  @override
  String get walletKindRefund => 'พอยท์คืนหลังยกเลิก';

  @override
  String get walletKindSpend => 'ใช้กับการจอง';

  @override
  String get walletKindExpire => 'หมดอายุ';

  @override
  String get walletKindOther => 'ปรับยอดพอยท์';

  @override
  String get moreWallet => 'กระเป๋าพอยท์';

  @override
  String get payHistoryTitle => 'ប្រវត្តិការបង់ប្រាក់';

  @override
  String get payHistoryEmpty => 'ยังไม่มีการชำระเงิน';

  @override
  String get payStatusPaid => 'ชำระแล้ว';

  @override
  String get payStatusRefunded => 'คืนเงินแล้ว';

  @override
  String get payStatusPending => 'รอชำระเงิน';

  @override
  String get payStatusClosed => 'ยังไม่ได้ชำระ';

  @override
  String get receiptTitle => 'ใบเสร็จอิเล็กทรอนิกส์';

  @override
  String get receiptLegal => 'ชื่อกิจการ';

  @override
  String get receiptRegNo => 'เลขทะเบียนธุรกิจ';

  @override
  String get receiptAddr => 'ที่อยู่';

  @override
  String get receiptPhone => 'ฝ่ายช่วยเหลือลูกค้า';

  @override
  String get receiptDate => 'วันที่ชำระ';

  @override
  String get receiptCopy => 'คัดลอกใบเสร็จ';

  @override
  String get receiptCopied => 'คัดลอกใบเสร็จแล้ว';

  @override
  String get receiptNote =>
      'ใช้เป็นหลักฐานการชำระเงินเท่านั้น หากต้องการใบกำกับภาษี ขอได้จากรายละเอียดการจอง';

  @override
  String get checkoutPointsUse => 'ใช้คะแนน';

  @override
  String checkoutPointsAvail(String count, String max) {
    return 'มี $count P · ใช้ได้สูงสุด $max P ในครั้งนี้';
  }

  @override
  String get checkoutPointsNeedsWindow =>
      'ใช้คะแนนได้เมื่อชำระผ่านหน้าต่างชำระเงิน';

  @override
  String get pointsLedgerTitle => 'บัญชีคะแนน';

  @override
  String get pointsAdjustAmount => 'คะแนน (ใส่ค่าลบเพื่อหัก)';

  @override
  String get pointsAdjustReason => 'เหตุผลในการปรับ';

  @override
  String get pointsAdjustInvalid => 'กรอกคะแนนที่ไม่ใช่ 0 และเหตุผล';

  @override
  String get pointsAdjustDone => 'ปรับคะแนนแล้ว';

  @override
  String get err_points_insufficient => 'คะแนนไม่พอ กรุณาลดคะแนนที่ใช้';

  @override
  String get err_points_over_cap =>
      'เกินจำนวนคะแนนที่ใช้ได้สำหรับการชำระครั้งนี้';

  @override
  String get err_points_cover_total =>
      'ใช้คะแนนชำระเต็มจำนวนไม่ได้ กรุณาลดลงเล็กน้อย';

  @override
  String get webBookNow => 'จองบนเว็บเลย';

  @override
  String get webBookSub => 'ไม่ต้องติดตั้งแอป';

  @override
  String get apPgBrowserNote =>
      'ชำระเงินในเบราว์เซอร์ให้เสร็จ แล้วกลับมาที่นี่และกดปุ่มด้านล่าง';

  @override
  String get apPgBrowserDone => 'ชำระเงินแล้ว';
}
