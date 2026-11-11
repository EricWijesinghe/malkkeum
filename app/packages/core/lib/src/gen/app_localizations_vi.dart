// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class TVi extends T {
  TVi([String locale = 'vi']) : super(locale);

  @override
  String get addressSearch => 'Tìm địa chỉ';

  @override
  String get addressSearchHint => 'Tìm theo tên đường, tòa nhà hoặc số thửa';

  @override
  String get addressSearchButton => 'Tìm';

  @override
  String get addressSearchMinChars => 'Nhập ít nhất 2 ký tự';

  @override
  String get addressNoResults => 'Không có kết quả. Hãy thử từ khác.';

  @override
  String get addressManualEntry => 'Nhập thủ công';

  @override
  String get cardRegisterTitle => 'Đăng ký thẻ';

  @override
  String get cIntJuso => 'Tìm địa chỉ (juso.go.kr)';

  @override
  String get aiLabel => 'Trợ lý AI';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Tự động trả lời chat của khách. Mỗi tin nhắn đều phát sinh phí API.';

  @override
  String get aiModeOffline => 'Chỉ trả lời khi không có nhân viên';

  @override
  String get aiModeAlways => 'AI luôn trả lời trước';

  @override
  String get aiPause => 'Tạm dừng AI';

  @override
  String get aiResume => 'Tiếp tục AI';

  @override
  String get aiPausedNote => 'AI đang tạm dừng trong cuộc trò chuyện này';

  @override
  String aiUsageMonth(String count) {
    return 'Lượt gọi AI tháng này: $count';
  }

  @override
  String get aiNotConfigured => 'Trợ lý AI đang tắt';

  @override
  String get aiCapThreadLabel => 'Giới hạn trả lời mỗi chat mỗi giờ';

  @override
  String get aiCapMemberLabel => 'Giới hạn trả lời mỗi khách mỗi ngày';

  @override
  String get aiCapDailyLabel => 'Giới hạn trả lời mỗi ngày, mọi chat';

  @override
  String get aiCapHint => 'Chỉ nhập số. Để trống sẽ dùng giá trị mặc định.';

  @override
  String get apSocialOr => 'hoặc';

  @override
  String get apSocialSignIn => 'Đăng nhập nhanh';

  @override
  String get apLoginKakao => 'Tiếp tục với Kakao';

  @override
  String get apLoginNaver => 'Tiếp tục với Naver';

  @override
  String get apLoginGoogle => 'Tiếp tục với Google';

  @override
  String get apLoginApple => 'Tiếp tục với Apple';

  @override
  String get apDevSocialNote =>
      'Chế độ phát triển: đăng nhập bằng tài khoản thử, không phải tài khoản mạng xã hội thật.';

  @override
  String get apSocialFailed => 'Đăng nhập nhanh thất bại. Vui lòng thử lại.';

  @override
  String get apProviderNotConfigured =>
      'Phương thức đăng nhập này chưa sẵn sàng';

  @override
  String get apPhoneTaken => 'Số này đã được gắn với tài khoản khác';

  @override
  String get apPhoneAttachTitle => 'Xác minh số điện thoại của bạn';

  @override
  String get apPhoneAttachBody =>
      'Số này dùng cho lịch hẹn và liên hệ với đối tác. Chỉ cần xác minh một lần.';

  @override
  String get apPayAllTitle => 'Chọn phương thức thanh toán';

  @override
  String get apPaySavedTitle => 'Phương thức đã lưu';

  @override
  String get apPayMoreTitle => 'Tất cả phương thức';

  @override
  String get apPayBillingHint =>
      'Lưu một lần, lần sau thanh toán chỉ với một chạm';

  @override
  String get apPayCheckoutHint => 'Hoàn tất trong cửa sổ thanh toán';

  @override
  String get apPayRegistering => 'Đang đăng ký…';

  @override
  String get apPayManageHint =>
      'Thanh toán một chạm bằng phương thức đã lưu. Thêm phương thức thanh toán nhanh tại đây.';

  @override
  String get apMethodCard => 'Thẻ tín dụng & ghi nợ';

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
  String get apMethodTransfer => 'Chuyển khoản';

  @override
  String get apMethodVirtual => 'Tài khoản ảo';

  @override
  String get apMethodPhone => 'Thanh toán qua điện thoại';

  @override
  String get apMethodUnknown => 'Khác';

  @override
  String get apVaTitle => 'Tài khoản nhận tiền đã sẵn sàng';

  @override
  String get apVaWaiting => 'Đang chờ chuyển khoản';

  @override
  String get apVaBody =>
      'Đặt lịch được xác nhận khi nhận đủ tiền trước hạn. Hệ thống tự động kiểm tra.';

  @override
  String get apVaBank => 'Ngân hàng';

  @override
  String get apVaAccount => 'Số tài khoản';

  @override
  String get apVaHolder => 'Chủ tài khoản';

  @override
  String get apVaAmount => 'Số tiền';

  @override
  String apVaDue(String due) {
    return 'Vui lòng chuyển khoản trước $due';
  }

  @override
  String get apVaCopy => 'Sao chép';

  @override
  String get apVaCopied => 'Đã sao chép số tài khoản';

  @override
  String get apVaBannerTitle => 'Có lịch hẹn đang chờ chuyển khoản';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · trước $due';
  }

  @override
  String get apVaBannerAction => 'Xem tài khoản';

  @override
  String get apPgTitle => 'Cửa sổ thanh toán';

  @override
  String get apPgDevNote =>
      'Mô phỏng thanh toán chỉ dùng khi phát triển. Không có giao dịch thật.';

  @override
  String apPgPay(String amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get apPgIssue => 'Lấy số tài khoản';

  @override
  String get apPgCancel => 'Hủy thanh toán';

  @override
  String get apErrSlotFullRefunded =>
      'Khung giờ vừa kín nên thanh toán đã được hủy tự động';

  @override
  String get apErrCheckoutExpired =>
      'Phiên thanh toán đã hết hạn. Vui lòng thử lại.';

  @override
  String get apIdentityTitle => 'Xác minh danh tính (PASS)';

  @override
  String get apIdentityBody =>
      'Xác minh bằng tên chính chủ điện thoại. Dùng để đảm bảo giao dịch và thanh toán an toàn.';

  @override
  String get apIdentityAction => 'Xác minh';

  @override
  String get apIdentityDone => 'Đã xác minh danh tính';

  @override
  String get apIdentityVerified => 'Đã xác minh';

  @override
  String get apIdentityUnverified => 'Chưa xác minh';

  @override
  String get apIdentityDevTitle => 'Xác minh thử nghiệm';

  @override
  String get apIdentityDevBody =>
      'Khi phát triển, bước này được bỏ qua mà không cần xác minh thật.';

  @override
  String get apIdentityDevPass => 'Cho qua';

  @override
  String get apPayManageTitle => 'Đăng ký thanh toán nhanh';

  @override
  String get cTitle => 'Bảng điều hành';

  @override
  String get cEmail => 'Thư điện tử';

  @override
  String get cPassword => 'Mật khẩu';

  @override
  String get cLogin => 'Đăng nhập';

  @override
  String get cLoginFailed => 'Sai email hoặc mật khẩu';

  @override
  String get cDashboard => 'Tổng quan';

  @override
  String get cBookings => 'Lịch hẹn';

  @override
  String get cQuoteDesk => 'Bàn báo giá';

  @override
  String get cInbox => 'Hộp thư';

  @override
  String get cCatalog => 'Danh mục & giá';

  @override
  String get cMarketing => 'Phiếu & nội dung';

  @override
  String get cPartners => 'Đối tác';

  @override
  String get cSettlements => 'Thanh toán';

  @override
  String get cCustomers => 'Khách hàng';

  @override
  String get cStaff => 'Nhân viên';

  @override
  String get cSearchCommand => 'Tìm hoặc chuyển';

  @override
  String get cPaletteHint => 'Nhập mục hoặc mã đặt';

  @override
  String get cTodayJobs => 'Việc hôm nay';

  @override
  String get cOpenQuotes => 'Chờ báo giá';

  @override
  String get cUnassigned => 'Chưa giao';

  @override
  String get cUnreadThreads => 'Chat chưa đọc';

  @override
  String get cRevenue30 => 'Doanh thu 30 ngày';

  @override
  String get cBookings30 => 'Lịch 30 ngày';

  @override
  String get cByService => 'Theo dịch vụ (30 ngày)';

  @override
  String get cAllStatus => 'Mọi trạng thái';

  @override
  String get cAllServices => 'Mọi dịch vụ';

  @override
  String get cSearch => 'Tìm (mã, SĐT, tên, địa chỉ)';

  @override
  String get cNoResults => 'Không có kết quả';

  @override
  String get cNumber => 'Mã';

  @override
  String get cVisit => 'Lịch';

  @override
  String get cService => 'Dịch vụ';

  @override
  String get cStatus => 'Trạng thái';

  @override
  String get cTeam => 'Đội';

  @override
  String get cAmount => 'Số tiền';

  @override
  String get cCustomer => 'Khách';

  @override
  String get cPayments => 'Thanh toán';

  @override
  String get cChangeStatus => 'Đổi trạng thái';

  @override
  String get cTeamName => 'Đội được giao';

  @override
  String get cAssign => 'Giao đội';

  @override
  String get cMarkDone => 'Đánh dấu xong';

  @override
  String get cConfirm => 'Đánh dấu xác nhận';

  @override
  String get cCancelRefund => 'Hủy & hoàn tiền';

  @override
  String get cRefundAmount => 'Số tiền hoàn (trống = toàn bộ)';

  @override
  String get cDone => 'Đã xong';

  @override
  String get cAnswers => 'Trả lời của khách';

  @override
  String get cEstimateCalc => 'Ước tính tự động';

  @override
  String get cBase => 'Cơ bản';

  @override
  String get cExtras => 'Phụ thêm';

  @override
  String get cSurcharge => 'Phụ phí';

  @override
  String get cBeforeVat => 'Trước VAT';

  @override
  String get cProQuotes => 'Báo giá đối tác';

  @override
  String get cNoProQuotes => 'Chưa có báo giá';

  @override
  String get cFinalPrice => 'Giá cuối cho khách';

  @override
  String get cQuoteNote => 'Ghi chú cho khách';

  @override
  String get cSendQuote => 'Gửi báo giá cho khách';

  @override
  String get cQuoteSent => 'Đã gửi báo giá';

  @override
  String get cCustomerChats => 'Khách';

  @override
  String get cPartnerChats => 'Đối tác';

  @override
  String get cSelectBooking => 'Chọn một lịch hẹn';

  @override
  String get cRefunded => 'Đã hoàn tiền';

  @override
  String get cPartRefunded => 'Hoàn một phần';

  @override
  String get cFailed => 'Thất bại';

  @override
  String get cSelectThread => 'Chọn cuộc trò chuyện';

  @override
  String get cReplyHint => 'Trả lời · Ctrl+Enter để gửi';

  @override
  String get cOpenBooking => 'Mở lịch';

  @override
  String get cShortcuts => 'J/K di chuyển · Ctrl+K lệnh';

  @override
  String get cPricing => 'Giá';

  @override
  String get cMinutes => 'Phút';

  @override
  String get cActive => 'Đang bán';

  @override
  String get cSaved => 'Đã lưu';

  @override
  String get cSlotCapacity => 'Sức chứa mỗi khung giờ';

  @override
  String get cUnlimited => 'Không giới hạn';

  @override
  String get cFormula => 'Công thức báo giá';

  @override
  String get cTabCancelPolicy => 'Chính sách hủy';

  @override
  String get cPolicyDefaultBanner =>
      'Đây là giá trị mặc định. Hãy xem lại và lưu để xác nhận.';

  @override
  String get cPolicyDaysBefore => 'Trước lịch bao nhiêu ngày';

  @override
  String get cPolicyPercent => 'Phí % (để trống = không hủy trong app)';

  @override
  String get cPolicyMinFee => 'Phí tối thiểu (KRW)';

  @override
  String get cPolicyReschedule => 'Cho đổi lịch (trước lịch bao nhiêu ngày)';

  @override
  String get cPolicyHint =>
      'Áp dụng ngay trên màn hình hủy của app khách. Điều khoản cập nhật ở bản build sau.';

  @override
  String get f_base_studio => 'Cơ bản: studio';

  @override
  String get f_base_one_and_half => 'Cơ bản: 1,5 phòng';

  @override
  String get f_base_two_rooms => 'Cơ bản: 2 phòng';

  @override
  String get f_base_three_rooms => 'Cơ bản: 3 phòng';

  @override
  String get f_base_four_plus => 'Cơ bản: 4+ phòng';

  @override
  String get f_per_extra_bathroom => 'Mỗi phòng tắm thêm';

  @override
  String get f_per_balcony => 'Mỗi ban công';

  @override
  String get f_duplex => 'Nhà 2 tầng';

  @override
  String get f_no_elevator_high_floor => 'Không thang máy & tầng 3+';

  @override
  String get cIssueCoupon => 'Phát phiếu';

  @override
  String get cCouponName => 'Tên phiếu';

  @override
  String get cCouponPhones => 'Số điện thoại (mỗi dòng một số)';

  @override
  String get cAllCustomers => 'Cho mọi khách';

  @override
  String cIssued(String n) {
    return 'Đã phát $n';
  }

  @override
  String get cContent => 'Nội dung';

  @override
  String get cKind_notice => 'Thông báo';

  @override
  String get cKind_tip => 'Mẹo';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Biểu ngữ';

  @override
  String get cKind_legal => 'Pháp lý';

  @override
  String get cNewContent => 'Nội dung mới';

  @override
  String get cTitleField => 'Tiêu đề';

  @override
  String get cBodyField => 'Nội dung';

  @override
  String get cSlug => 'Mã (pháp lý: privacy / terms)';

  @override
  String get cVerify => 'Duyệt';

  @override
  String get cSuspend => 'Tạm dừng';

  @override
  String get cPro_pending => 'Chờ duyệt';

  @override
  String get cPro_verified => 'Đang hoạt động';

  @override
  String get cPro_suspended => 'Tạm dừng';

  @override
  String get cCompleted => 'Hoàn tất';

  @override
  String get cCancelledN => 'Hủy';

  @override
  String get cRating => 'Đánh giá';

  @override
  String get cFeeRate => 'Phí %';

  @override
  String get cRunPayouts => 'Chạy thanh toán';

  @override
  String get cPayoutDate => 'Trả đến ngày';

  @override
  String cPayoutDone(String n) {
    return 'Đã trả cho $n đối tác';
  }

  @override
  String get cHold => 'Giữ';

  @override
  String get cRelease => 'Bỏ giữ';

  @override
  String get cNet => 'Thực nhận';

  @override
  String get cAddStaff => 'Thêm nhân viên';

  @override
  String get cRoleAdmin => 'Quản trị';

  @override
  String get cRoleConsultant => 'Tư vấn viên';

  @override
  String get cDeactivate => 'Vô hiệu';

  @override
  String get cActivate => 'Kích hoạt';

  @override
  String get cPasswordRule => 'Ít nhất 12 ký tự';

  @override
  String get cAdminOnly => 'Chỉ quản trị viên';

  @override
  String cBookingsCount(String n) {
    return '$n lịch';
  }

  @override
  String get cJoined => 'Tham gia';

  @override
  String get cNewBooking => 'Lịch mới';

  @override
  String get cNewMessage => 'Tin nhắn mới';

  @override
  String get cConfirmAsk => 'Bạn có chắc chắn không?';

  @override
  String get ok => 'Xác nhận';

  @override
  String get cancel => 'Hủy';

  @override
  String get next => 'Tiếp';

  @override
  String get close => 'Đóng';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get change => 'Đổi';

  @override
  String get retry => 'Thử lại';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get required => 'Bắt buộc';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get today => 'Hôm nay';

  @override
  String get errorGeneric => 'Đã có lỗi. Vui lòng thử lại.';

  @override
  String get errorNetwork => 'Kiểm tra kết nối mạng';

  @override
  String get err_invalid_phone => 'Kiểm tra số điện thoại';

  @override
  String get err_otp_invalid => 'Mã xác thực không đúng';

  @override
  String get err_otp_expired => 'Mã đã hết hạn, hãy lấy mã mới';

  @override
  String get err_rate_limited => 'Quá nhiều lần thử, hãy thử lại sau';

  @override
  String get err_studio_too_large =>
      'Dọn phòng studio chỉ cho nhà tối đa 10 pyeong';

  @override
  String get err_date_out_of_range => 'Chọn ngày từ mai đến 60 ngày tới';

  @override
  String get err_slot_full => 'Khung giờ đã kín, hãy chọn giờ khác';

  @override
  String get err_coupon_expired => 'Phiếu đã hết hạn';

  @override
  String get err_coupon_used => 'Phiếu đã được dùng';

  @override
  String get err_coupon_wrong_service => 'Phiếu không áp dụng cho dịch vụ này';

  @override
  String get err_payment_failed => 'Thanh toán bị từ chối, hãy dùng cách khác';

  @override
  String get err_payment_method_required => 'Chọn phương thức thanh toán';

  @override
  String get err_cancellation_window_closed =>
      'Không thể hủy trong ứng dụng lúc này. Vui lòng liên hệ đội hỗ trợ';

  @override
  String get err_address_required => 'Thêm địa chỉ';

  @override
  String get err_already_taken => 'Đối tác khác đã nhận trước';

  @override
  String get err_invalid_address => 'Điền đủ thông tin địa chỉ';

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabBookings => 'Lịch hẹn';

  @override
  String get tabChat => 'Tư vấn';

  @override
  String get tabMore => 'Thêm';

  @override
  String get introTitle => 'Dọn dẹp chuyên nghiệp,\nđặt lịch trong một phút';

  @override
  String get introBody => 'Giá minh bạch · Đội ngũ uy tín · Theo dõi trực tiếp';

  @override
  String get introStart => 'Bắt đầu bằng số điện thoại';

  @override
  String get loginPhoneTitle => 'Số điện thoại của bạn?';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'Gửi mã';

  @override
  String get loginCodeTitle => 'Nhập mã 6 chữ số';

  @override
  String loginCodeSentTo(String phone) {
    return 'Đã gửi đến $phone';
  }

  @override
  String get loginResend => 'Gửi lại';

  @override
  String get loginVerify => 'Xác nhận';

  @override
  String get loginTerms =>
      'Tiếp tục nghĩa là bạn đồng ý Điều khoản và Chính sách bảo mật';

  @override
  String get profileTitle => 'Chúng tôi nên gọi bạn là gì?';

  @override
  String get profileNameHint => 'Tên';

  @override
  String get profileDone => 'Bắt đầu';

  @override
  String get welcomeToast => 'Đã tặng 2 phiếu chào mừng';

  @override
  String get svc_studio => 'Dọn phòng studio';

  @override
  String get svc_kitchen => 'Dọn bếp';

  @override
  String get svc_bathroom => 'Dọn phòng tắm';

  @override
  String get svc_mattress => 'Giặt nệm';

  @override
  String get svc_aircon => 'Vệ sinh máy lạnh';

  @override
  String get svc_sofa => 'Giặt sofa';

  @override
  String get svc_move_out => 'Dọn khi chuyển đi';

  @override
  String get svc_move_in => 'Dọn trước khi vào ở';

  @override
  String get svcShort_studio => 'Studio';

  @override
  String get svcShort_kitchen => 'Bếp';

  @override
  String get svcShort_bathroom => 'Phòng tắm';

  @override
  String get svcShort_mattress => 'Nệm';

  @override
  String get svcShort_aircon => 'Máy lạnh';

  @override
  String get svcShort_sofa => 'Sofa';

  @override
  String get svcShort_move_out => 'Chuyển đi';

  @override
  String get svcShort_move_in => 'Vào ở';

  @override
  String get svcDesc_studio =>
      'Dọn kỹ 2 giờ cho studio tối đa 10 pyeong: 1 phòng, 1 phòng tắm.';

  @override
  String get svcDesc_kitchen =>
      'Dọn tập trung bồn rửa, bếp, mặt ngoài máy hút mùi và mặt bàn.';

  @override
  String get svcDesc_bathroom =>
      'Kệ, vòi, bồn rửa, bồn cầu trong ngoài và lau khô sàn.';

  @override
  String get svcDesc_mattress =>
      'Thiết bị chuyên dụng hút bụi, mạt, vết bẩn rồi khử khuẩn bằng hơi nước.';

  @override
  String get svcDesc_aircon =>
      'Tháo rời, rửa áp lực dàn lạnh, quạt, lưới lọc và khử khuẩn.';

  @override
  String get svcDesc_sofa =>
      'Dung dịch phù hợp chất liệu, làm sạch bằng phương pháp hút ướt.';

  @override
  String get svcDesc_move_out =>
      'Trước khi chuyển đi, đội chuyên nghiệp mang thiết bị đến dọn nhà trống.';

  @override
  String get svcDesc_move_in =>
      'Trước khi vào ở, đội chuyên nghiệp mang thiết bị đến dọn nhà mới.';

  @override
  String get svcNotes_bathroom =>
      'Cống/bồn cầu tắc có thể hạn chế dịch vụ\nKhông làm vệ sinh cần hóa chất đặc biệt, trần, quạt hút\nNấm mốc lâu năm có thể không sạch hoàn toàn';

  @override
  String get svcNotes_mattress =>
      'Cùng giá từ đơn đến king\nKhô hoàn toàn sau 4–6 giờ\nKhông khắc phục lò xo hỏng, lún';

  @override
  String get svcNotes_aircon =>
      'Máy trên 10 năm có thể khó tháo rửa\nKhông gồm dàn nóng\nKiểm tra hoạt động trước và sau';

  @override
  String get svcNotes_sofa =>
      'Sofa da được làm sạch và dưỡng\nVết bẩn lâu có thể không hết\nKhô hoàn toàn sau 4–6 giờ';

  @override
  String get unitTitle_bathroom => 'Số phòng tắm';

  @override
  String get unitTitle_mattress => 'Số nệm';

  @override
  String get unitTitle_aircon => 'Loại máy lạnh';

  @override
  String get unitTitle_sofa => 'Kích thước sofa';

  @override
  String unit_count(String n) {
    return '$n';
  }

  @override
  String get unit_wall => 'Treo tường';

  @override
  String get unit_stand => 'Tủ đứng';

  @override
  String get unit_two_in_one => '2 trong 1 (đứng + treo)';

  @override
  String get unit_ceiling => 'Âm trần';

  @override
  String get unit_seat_1_2 => '1–2 chỗ';

  @override
  String get unit_seat_3 => '3 chỗ';

  @override
  String get unit_seat_4_plus => '4+ chỗ';

  @override
  String get unit_l_shape => 'Chữ L / couch';

  @override
  String durH(String h) {
    return '$h giờ';
  }

  @override
  String durHM(String h, String m) {
    return '$h giờ $m phút';
  }

  @override
  String durM(String m) {
    return '$m phút';
  }

  @override
  String about(String value) {
    return 'khoảng $value';
  }

  @override
  String fromPrice(String price) {
    return 'từ $price';
  }

  @override
  String get quoteBadge => 'Báo giá';

  @override
  String get status0 => 'Đang tư vấn';

  @override
  String get status1 => 'Đã xác nhận';

  @override
  String get status2 => 'Đã có đội';

  @override
  String get status3 => 'Hoàn tất';

  @override
  String get statusCancelled => 'Đã hủy';

  @override
  String homeGreeting(String name) {
    return 'Chào $name,\nhôm nay dọn chỗ nào?';
  }

  @override
  String get homeGreetingAnon => 'Hôm nay\ndọn chỗ nào?';

  @override
  String get homeUpcoming => 'Sắp tới';

  @override
  String dDay(String days) {
    return 'còn $days ngày';
  }

  @override
  String get homeServices => 'Bạn cần dịch vụ nào?';

  @override
  String get homeAddAddress => 'Thêm địa chỉ để xem dịch vụ khả dụng';

  @override
  String get homeAddAddressCta => 'Thêm địa chỉ';

  @override
  String homeRebook(String service) {
    return 'Đặt lại $service';
  }

  @override
  String get homeRebookBody => 'Cùng lựa chọn như lần trước';

  @override
  String get homeNotices => 'Tin mới';

  @override
  String get trustVat => 'Đã gồm VAT,\nkhông phát sinh';

  @override
  String get trustCancel => 'Hủy miễn phí\ntrước 2 ngày';

  @override
  String get trustCard => 'Thông tin thẻ\nchỉ do cổng thanh toán giữ';

  @override
  String stepOf(String current, String total) {
    return '$current/$total';
  }

  @override
  String get chooseDate => 'Chọn ngày';

  @override
  String get notIncluded => 'Lưu ý';

  @override
  String studioBlockedTitle(String size) {
    return '$size pyeong quá lớn cho dọn studio';
  }

  @override
  String get studioBlockedBody => 'Đội tư vấn sẽ gợi ý dịch vụ phù hợp.';

  @override
  String get consultCta => 'Hỏi đội tư vấn';

  @override
  String get addressTitle => 'Đến địa chỉ nào?';

  @override
  String get addressAdd => 'Thêm địa chỉ mới';

  @override
  String get addressLabel => 'Tên gợi nhớ';

  @override
  String get addressLabelHint => 'VD: Nhà';

  @override
  String get addressDistrict => 'Quận';

  @override
  String get addressRoad => 'Địa chỉ đường';

  @override
  String get addressDetail => 'Căn hộ / tầng';

  @override
  String get addressSize => 'Diện tích (pyeong)';

  @override
  String get addressSizeHelp => 'Diện tích sử dụng · 1 pyeong ≈ 3,3 m²';

  @override
  String get addressHome => 'Nhà';

  @override
  String get addressOffice => 'Văn phòng';

  @override
  String get addressEmpty => 'Chưa có địa chỉ';

  @override
  String get addressSaved => 'Đã lưu địa chỉ';

  @override
  String pyeong(String n) {
    return '$n pyeong';
  }

  @override
  String get scheduleTitle => 'Khi nào đến?';

  @override
  String get scheduleArrival => 'Giờ đến';

  @override
  String get scheduleFull => 'Kín';

  @override
  String scheduleWindow(String start, String end) {
    return 'Đến $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · xong khoảng $time';
  }

  @override
  String get scheduleRange => 'Đặt từ ngày mai đến 60 ngày tới';

  @override
  String get morning => 'Buổi sáng';

  @override
  String get afternoon => 'Buổi chiều';

  @override
  String get scheduleQuoteNote => 'Giờ chính xác sẽ báo trong chat';

  @override
  String get goToPayment => 'Đến thanh toán';

  @override
  String get prepTitle => 'Vui lòng chuẩn bị';

  @override
  String get prepBody => 'Thiếu dụng cụ có thể hạn chế một số việc';

  @override
  String get prepAsk => 'Không chuẩn bị được? Báo đội tư vấn';

  @override
  String get tool_vacuum => 'Máy hút bụi';

  @override
  String get tool_trash => 'Túi rác';

  @override
  String get tool_mop => 'Cây lau nhà';

  @override
  String get tool_cloth => 'Khăn lau';

  @override
  String get tool_gloves => 'Găng tay cao su';

  @override
  String get tool_sponge => 'Miếng cọ';

  @override
  String get tool_spray => 'Nước tẩy đa năng';

  @override
  String get checkoutTitle => 'Thanh toán';

  @override
  String get coupon => 'Phiếu giảm giá';

  @override
  String get couponNone => 'Không dùng';

  @override
  String couponAvailable(String count) {
    return '$count phiếu dùng được';
  }

  @override
  String get paymentMethod => 'Phương thức';

  @override
  String get addPaymentMethod => 'Thêm phương thức';

  @override
  String get methodCard => 'Thẻ tín dụng / ghi nợ';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Đã thêm';

  @override
  String get methodAdded => 'Đã thêm phương thức';

  @override
  String get listPrice => 'Dịch vụ';

  @override
  String get discount => 'Giảm giá';

  @override
  String get total => 'Tổng cộng';

  @override
  String get vatIncluded => 'Đã gồm VAT';

  @override
  String payAmount(String amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get needMethod => 'Hãy thêm phương thức trước';

  @override
  String freeCancelUntil(String date) {
    return 'Hủy miễn phí đến $date';
  }

  @override
  String get doneTitle => 'Đã đặt lịch!';

  @override
  String get doneBody => 'Chúng tôi sẽ báo ngay khi có đội';

  @override
  String get doneQuoteTitle => 'Đã nhận yêu cầu';

  @override
  String get doneQuoteBody =>
      'Đội tư vấn sẽ gửi báo giá cuối cùng trong tab Tư vấn.';

  @override
  String get goHome => 'Về trang chủ';

  @override
  String get viewBooking => 'Xem lịch hẹn';

  @override
  String get bookingsTitle => 'Lịch hẹn';

  @override
  String get bookingsUpcoming => 'Sắp tới';

  @override
  String get bookingsPast => 'Đã qua';

  @override
  String get bookingsEmpty => 'Chưa có lịch hẹn';

  @override
  String get bookingsEmptyBody => 'Có phiếu chào mừng cho lần đặt đầu';

  @override
  String get bookNow => 'Đặt dọn dẹp';

  @override
  String get detailTitle => 'Chi tiết';

  @override
  String get stepRequested => 'Đã gửi';

  @override
  String get stepConfirmed => 'Xác nhận';

  @override
  String get stepAssigned => 'Có đội';

  @override
  String get stepCompleted => 'Hoàn tất';

  @override
  String teamVisiting(String team) {
    return '$team sẽ đến';
  }

  @override
  String get photosSoon => 'Ảnh trước & sau sẽ hiện ở đây';

  @override
  String photoThumb(String n) {
    return 'Ảnh $n';
  }

  @override
  String get before => 'Trước';

  @override
  String get after => 'Sau';

  @override
  String get prepCheck => 'Danh sách chuẩn bị';

  @override
  String get prepAllSet => 'Đã sẵn sàng';

  @override
  String get visitAddress => 'Địa chỉ';

  @override
  String get paid => 'Đã trả';

  @override
  String get askTeam => 'Nhắn đội tư vấn';

  @override
  String get cancelBooking => 'Hủy lịch';

  @override
  String get cancelTitle => 'Hủy lịch hẹn này?';

  @override
  String get cancelFree => 'Bạn được hoàn tiền đầy đủ và nhận lại phiếu.';

  @override
  String get cancelKeep => 'Giữ lịch';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Hủy ngay sẽ mất phí $fee và hoàn lại $refund.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return 'Chấp nhận phí $fee và hủy';
  }

  @override
  String get cancelled => 'Đã hủy lịch';

  @override
  String get reschedule => 'Đổi lịch';

  @override
  String get rescheduled => 'Đã đổi lịch';

  @override
  String get visitNotes => 'Ghi chú cho đội';

  @override
  String get notesEntry => 'Cách vào (mã cửa...)';

  @override
  String get notesParking => 'Đỗ xe';

  @override
  String get notesOther => 'Khác';

  @override
  String get notesSaved => 'Đã lưu ghi chú';

  @override
  String depositDue(String amount) {
    return 'Thanh toán đặt cọc $amount để xác nhận';
  }

  @override
  String get payDeposit => 'Trả đặt cọc';

  @override
  String get waitingQuote => 'Đội tư vấn đang chuẩn bị báo giá';

  @override
  String get estimate => 'Ước tính';

  @override
  String get finalPrice => 'Báo giá cuối';

  @override
  String get deposit => 'Đặt cọc';

  @override
  String get balance => 'Còn lại';

  @override
  String balanceDue(String amount) {
    return 'Vui lòng trả phần còn lại $amount';
  }

  @override
  String get payBalance => 'Trả phần còn lại';

  @override
  String get reviewTitle => 'Dịch vụ thế nào?';

  @override
  String get reviewHint => 'Điều gì tốt, điều gì cần cải thiện?';

  @override
  String ratingStars(String n) {
    return '$n sao';
  }

  @override
  String get reviewSubmit => 'Gửi đánh giá';

  @override
  String get reviewThanks => 'Cảm ơn đánh giá của bạn';

  @override
  String get bookAgain => 'Đặt lại như cũ';

  @override
  String get chatTitle => 'Tư vấn';

  @override
  String get chatTeam => 'Đội tư vấn';

  @override
  String get chatHours => 'Ngày thường 09:00–18:00';

  @override
  String get chatEmpty => 'Có thắc mắc? Hỏi bất cứ lúc nào';

  @override
  String get chatNew => 'Cuộc trò chuyện mới';

  @override
  String get chatTopicTitle => 'Bạn cần hỏi gì?';

  @override
  String get topicOther => 'Vấn đề khác';

  @override
  String get chatHint => 'Nhập tin nhắn';

  @override
  String get chatSend => 'Gửi';

  @override
  String get chatPhoto => 'Gửi ảnh';

  @override
  String get chatTyping => 'Đang nhập';

  @override
  String get quick_confirm => 'Tôi xác nhận';

  @override
  String get quick_price => 'Hỏi về giá';

  @override
  String get quick_date => 'Muốn đổi ngày';

  @override
  String get quick_parking => 'Có chỗ đỗ xe không?';

  @override
  String get quick_hello => 'Xin chào';

  @override
  String get quick_duration => 'Mất bao lâu?';

  @override
  String get quoteArrived => 'Báo giá cuối đã đến';

  @override
  String get quoteDepositNow => 'Đặt cọc bây giờ (10%)';

  @override
  String get quoteBalanceLater => 'Còn lại sau khi xong';

  @override
  String get quotePay => 'Trả cọc & xác nhận';

  @override
  String get quotePaid => 'Đã trả';

  @override
  String get requestCard => 'Yêu cầu báo giá';

  @override
  String get sys_consultation_received => 'Đã nhận yêu cầu';

  @override
  String sys_deposit_paid(String amount) {
    return 'Đã trả cọc $amount. Lịch đã xác nhận.';
  }

  @override
  String get sys_booking_cancelled => 'Lịch hẹn đã bị hủy';

  @override
  String sys_status_changed(String status) {
    return 'Trạng thái: $status';
  }

  @override
  String get sys_job_completed => 'Đã xong! Xem ảnh trước & sau.';

  @override
  String sys_rescheduled(String date) {
    return 'Đã đổi lịch sang $date';
  }

  @override
  String get sys_reschedule_declined =>
      'Đối tác không đến được giờ mới. Đội sẽ sắp xếp lại.';

  @override
  String get moreTitle => 'Thêm';

  @override
  String get moreScope => 'Phạm vi dịch vụ';

  @override
  String get morePayments => 'Phương thức thanh toán';

  @override
  String get moreCoupons => 'Phiếu giảm giá';

  @override
  String get morePoints => 'Điểm';

  @override
  String get moreAccount => 'Tài khoản';

  @override
  String get moreAddresses => 'Địa chỉ';

  @override
  String get moreNotices => 'Thông báo';

  @override
  String get moreTips => 'Mẹo dọn dẹp';

  @override
  String get moreFaq => 'Câu hỏi thường gặp';

  @override
  String get morePartner => 'Hợp tác';

  @override
  String get moreLanguage => 'Ngôn ngữ';

  @override
  String get langSystem => 'Theo thiết bị';

  @override
  String moreVersion(String v) {
    return 'Phiên bản $v';
  }

  @override
  String get morePrivacy => 'Chính sách bảo mật';

  @override
  String get moreTerms => 'Điều khoản';

  @override
  String get moreLicenses => 'Giấy phép nguồn mở';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get deleteAccountBody =>
      'Dữ liệu cá nhân sẽ bị xóa vĩnh viễn. Hãy hủy lịch đang có trước.';

  @override
  String get couponsEmpty => 'Chưa có phiếu';

  @override
  String couponUntil(String date) {
    return 'Đến $date';
  }

  @override
  String get couponUsed => 'Đã dùng';

  @override
  String get couponExpired => 'Hết hạn';

  @override
  String get couponAnyService => 'Mọi dịch vụ';

  @override
  String get coupon_welcome_studio => 'Chào mừng: studio';

  @override
  String get coupon_welcome_any => 'Phiếu chào mừng';

  @override
  String get pointsBalance => 'Điểm của bạn';

  @override
  String get pointsEmpty => 'Chưa có lịch sử điểm';

  @override
  String get accountName => 'Tên';

  @override
  String get accountPhone => 'Số điện thoại';

  @override
  String get accountEmail => 'Thư điện tử';

  @override
  String get accountLogin => 'Cách đăng nhập';

  @override
  String get accountLoginPhone => 'Xác thực điện thoại';

  @override
  String get methodsEmpty => 'Chưa có phương thức';

  @override
  String get noContent => 'Chưa có nội dung';

  @override
  String get quoteTypeTitle => 'Loại dọn dẹp nào?';

  @override
  String get type_standard => 'Dọn khi chuyển đi';

  @override
  String get type_same_day_move => 'Dọn ngay ngày chuyển';

  @override
  String get type_some_luggage_left => 'Còn ít đồ';

  @override
  String get type_normal_move_in => 'Vào ở thông thường';

  @override
  String get type_after_interior => 'Sau sửa nhà';

  @override
  String get type_lived_in_deep_clean => 'Tổng vệ sinh khi đang ở';

  @override
  String get luggageTitle => 'Đồ đạc thế nào?';

  @override
  String get luggage_empty => 'Nhà trống';

  @override
  String get luggage_partly_unpacked => 'Đang dọn một phần';

  @override
  String get luggage_fully_lived_in => 'Đang ở đầy đủ';

  @override
  String get luggage_unknown => 'Không rõ';

  @override
  String get quoteBasicTitle => 'Thông tin căn nhà';

  @override
  String get buildingType => 'Loại nhà';

  @override
  String get building_apartment => 'Chung cư';

  @override
  String get building_villa => 'Nhà thấp tầng';

  @override
  String get building_officetel => 'Officetel';

  @override
  String get building_house => 'Nhà riêng';

  @override
  String get building_other => 'Khác';

  @override
  String get layoutTitle => 'Bố cục';

  @override
  String get layout_studio => 'Studio';

  @override
  String get layout_one_and_half => '1,5 phòng';

  @override
  String get layout_two_rooms => '2 phòng';

  @override
  String get layout_three_rooms => '3 phòng';

  @override
  String get layout_four_plus => '4+ phòng';

  @override
  String get duplexTitle => 'Nhà 2 tầng trong?';

  @override
  String get quoteSpaceTitle => 'Thêm về không gian';

  @override
  String get bathroomsLabel => 'Phòng tắm';

  @override
  String get balconiesLabel => 'Ban công / phòng giặt';

  @override
  String get elevatorTitle => 'Có thang máy?';

  @override
  String get floor3Label => 'Tầng 3 trở lên';

  @override
  String get quoteEstimateTitle => 'Ước tính của bạn';

  @override
  String get quoteEstimateBody =>
      'Giá cuối được chốt sau khi xem ảnh trong chat';

  @override
  String get quoteG1 => 'Giá cuối chốt trong chat';

  @override
  String get quoteG2 => 'Cọc 10%, phần còn lại sau khi xong';

  @override
  String get quoteG3 => 'Hủy miễn phí trước khi xác nhận';

  @override
  String get quoteConfirmTitle => 'Kiểm tra yêu cầu';

  @override
  String get quoteRequest => 'Gửi yêu cầu';

  @override
  String get quoteNoPayNow => 'Chưa cần thanh toán';

  @override
  String get summaryType => 'Loại';

  @override
  String get summaryHome => 'Nhà';

  @override
  String get summaryDate => 'Lịch';

  @override
  String get cpTitle => 'Chính sách hủy và đổi lịch';

  @override
  String cpWhen(String days) {
    return 'Từ $days ngày trở lên trước lịch';
  }

  @override
  String get cpWhenSameDay => 'Ngay ngày hẹn';

  @override
  String get cpFree => 'Hoàn tiền đầy đủ';

  @override
  String cpFee(String percent, String fee, String refund) {
    return 'Phí $percent% ($fee), hoàn $refund';
  }

  @override
  String get cpClosed => 'Không hủy được trong app (đội tư vấn xem xét)';

  @override
  String get hhTitle => 'Thông tin hộ gia đình';

  @override
  String get hhAddPet => 'Thêm thú cưng';

  @override
  String get hhPetCount => 'Số con';

  @override
  String get hhFloorLabel => 'Tầng (âm nếu là hầm)';

  @override
  String get hhElevator => 'Có thang máy';

  @override
  String get hhNotes => 'Ghi chú';

  @override
  String get hhHint => 'Lưu theo địa chỉ này và có thể đổi cho từng lịch hẹn.';

  @override
  String get themeTitle => 'Giao diện';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeTip => 'Đổi giao diện';

  @override
  String get err_price_changed =>
      'Giá đã thay đổi. Hãy xem báo giá mới và thử lại.';

  @override
  String get err_checkout_closed => 'Thanh toán này đã đóng. Hãy bắt đầu lại.';

  @override
  String get err_checkout_refunded =>
      'Thanh toán này đã được hủy và hoàn tiền.';

  @override
  String get err_already_paid => 'Đã thanh toán rồi.';

  @override
  String get err_quote_not_payable =>
      'Báo giá này chưa thể thanh toán. Vui lòng liên hệ đội hỗ trợ.';

  @override
  String get err_payment_method_disabled =>
      'Hiện không dùng được phương thức thanh toán này.';

  @override
  String get err_invalid_payment_method =>
      'Không dùng được phương thức đã chọn. Hãy chọn cách khác.';

  @override
  String get err_balance_not_due => 'Chưa đến hạn thanh toán số dư.';

  @override
  String get err_invalid_slot => 'Dịch vụ này không có khung giờ đó.';

  @override
  String get err_booking_changed =>
      'Thông tin đặt lịch đã thay đổi. Hãy làm mới và kiểm tra lại.';

  @override
  String get err_booking_closed => 'Lịch đặt này không thể thay đổi nữa.';

  @override
  String get err_reschedule_closed =>
      'Hiện không thể dời lịch. Vui lòng liên hệ đội hỗ trợ.';

  @override
  String get err_too_many_open_requests =>
      'Bạn có quá nhiều yêu cầu đang mở. Hãy hoàn tất một yêu cầu trước.';

  @override
  String get err_already_reviewed => 'Bạn đã đánh giá lần đặt này rồi.';

  @override
  String get err_identity_not_verified =>
      'Vui lòng hoàn tất xác minh danh tính trước.';

  @override
  String get err_email_taken => 'Email này đã được sử dụng.';

  @override
  String get err_invalid_email => 'Hãy kiểm tra địa chỉ email.';

  @override
  String get err_file_too_large => 'Tệp quá lớn. Hãy tải lên tệp nhỏ hơn.';

  @override
  String get err_unsupported_image =>
      'Định dạng ảnh không được hỗ trợ. Hãy tải lên JPG hoặc PNG.';

  @override
  String get err_upload_quota =>
      'Đã đạt giới hạn tải lên hôm nay. Hãy thử lại ngày mai.';

  @override
  String get err_provider_unreachable =>
      'Không kết nối được dịch vụ. Hãy thử lại sau.';

  @override
  String get err_invalid_token =>
      'Thông tin đăng nhập không hợp lệ. Hãy thử lại.';

  @override
  String get err_invalid_transition =>
      'Hiện không thể chuyển sang trạng thái này.';

  @override
  String get err_job_not_started => 'Hãy bắt đầu công việc trước.';

  @override
  String get err_job_not_active => 'Công việc này hiện không hoạt động.';

  @override
  String get err_quote_locked => 'Báo giá đã khóa nên không thể sửa.';

  @override
  String get err_request_closed => 'Yêu cầu này đã đóng.';

  @override
  String get err_team_full => 'Nhóm đã đủ người.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret phải bắt đầu bằng whsec_.';

  @override
  String get err_invalid_endpoint => 'Endpoint phải bắt đầu bằng https://.';

  @override
  String get err_invalid_bucket => 'Tên bucket không hợp lệ.';

  @override
  String get err_invalid_region => 'Vùng không hợp lệ.';

  @override
  String get err_invalid_retention => 'Thời gian lưu giữ nằm ngoài giới hạn.';

  @override
  String get err_invalid_service_account =>
      'Tệp tài khoản dịch vụ không hợp lệ.';

  @override
  String get err_invalid_mode => 'Hãy chọn lại chế độ AI hợp lệ.';

  @override
  String get err_invalid_model => 'Tên mô hình AI không hợp lệ.';

  @override
  String get err_missing_field => 'Hãy điền đầy đủ các mục bắt buộc.';

  @override
  String get err_invalid_amount => 'Hãy nhập số tiền hợp lệ.';

  @override
  String get err_cannot_deactivate_self =>
      'Bạn không thể vô hiệu hóa tài khoản của chính mình.';

  @override
  String get err_invalid_coupon => 'Phiếu giảm giá không hợp lệ.';

  @override
  String get err_settlement_state =>
      'Hiện không thể thay đổi trạng thái thanh toán.';

  @override
  String get err_deposit_required => 'Cần thanh toán tiền đặt cọc trước.';

  @override
  String get err_payout_state =>
      'Trạng thái chi trả đã thay đổi. Hãy làm mới và kiểm tra lại.';

  @override
  String get err_payout_provider =>
      'Phương thức chi trả này hiện không dùng được.';

  @override
  String get err_unsupported_bank => 'Ngân hàng này chưa được hỗ trợ chi trả.';

  @override
  String get err_toss_unverified =>
      'Chưa thể kết nối Toss chi hộ. Vui lòng dùng chuyển khoản thủ công.';

  @override
  String get err_invalid_cap => 'Vui lòng nhập số trong phạm vi cho phép.';

  @override
  String get err_invalid_capacity => 'Hãy nhập sức chứa hợp lệ.';

  @override
  String get err_seller_declined =>
      'Toss chưa duyệt đăng ký người bán. Hãy kiểm tra thông tin doanh nghiệp.';

  @override
  String get err_payout_account_unverified =>
      'Đối tác này chưa có tài khoản nhận tiền đã xác minh. Hãy xác minh tài khoản trước.';

  @override
  String get fFinance => 'Tài chính';

  @override
  String get fPeriodDay => 'Ngày';

  @override
  String get fPeriodWeek => 'Tuần';

  @override
  String get fPeriodMonth => 'Tháng';

  @override
  String get fPeriodCustom => 'Tùy chọn';

  @override
  String get fFrom => 'Từ';

  @override
  String get fTo => 'Đến';

  @override
  String get fGross => 'Tổng thanh toán';

  @override
  String get fRefunds => 'Hoàn tiền';

  @override
  String get fNetRevenue => 'Doanh thu ròng';

  @override
  String get fPlatformFee => 'Phí nền tảng';

  @override
  String get fPaidOut => 'Đã trả đối tác';

  @override
  String get fPendingOut => 'Chờ thanh toán';

  @override
  String get fHeldOut => 'Tạm giữ';

  @override
  String get fVatEstimate => 'Thuế GTGT (ước tính)';

  @override
  String get fVatNote => 'Ước tính 10% phí nền tảng. Hãy kiểm tra với kế toán.';

  @override
  String get fAov => 'Giá trị đơn TB';

  @override
  String get fBookings => 'Đặt lịch';

  @override
  String get fCancelRate => 'Tỷ lệ hủy';

  @override
  String get fDiscounts => 'Giảm giá & phiếu';

  @override
  String get fMethods => 'Phương thức thanh toán';

  @override
  String get fTrend => 'Xu hướng';

  @override
  String fRangeDays(String n) {
    return '$n ngày qua';
  }

  @override
  String get fRangeWeeks => '12 tuần qua';

  @override
  String get fRangeMonths => '12 tháng qua';

  @override
  String get fByPartner => 'Thu nhập theo đối tác';

  @override
  String get fByService => 'Doanh thu theo dịch vụ';

  @override
  String get fExportTitle => 'Xuất dữ liệu kế toán';

  @override
  String get fExportLedger => 'Sổ thanh toán CSV';

  @override
  String get fExportSettlements => 'Bảng thanh toán CSV';

  @override
  String get fExportMonthly => 'Tóm tắt tháng CSV (kế toán)';

  @override
  String get fDownload => 'Tải CSV';

  @override
  String get fDownloadWebOnly => 'Tải CSV dùng bảng điều hành web';

  @override
  String get fDownloadFailed => 'Tải xuống thất bại';

  @override
  String get fNoRecords => 'Không có dữ liệu trong kỳ này';

  @override
  String get fLoadFailed => 'Không tải được dữ liệu tài chính';

  @override
  String get fRetry => 'Thử lại';

  @override
  String get fColPartner => 'Đối tác';

  @override
  String get fColJobs => 'Số việc';

  @override
  String get fColSettled => 'Tổng quyết toán';

  @override
  String get fColFee => 'Phí';

  @override
  String get fColNet => 'Thực nhận';

  @override
  String get pEarnings => 'Thu nhập';

  @override
  String get pNextPayout => 'Lần thanh toán tiếp';

  @override
  String pNextPayoutOn(String date) {
    return 'Thanh toán $date';
  }

  @override
  String get pNoPayout => 'Chưa có lần thanh toán';

  @override
  String get pPendingTotal => 'Chờ thanh toán';

  @override
  String get pPaidTotal => 'Đã thanh toán';

  @override
  String get pWeekly => 'Theo tuần';

  @override
  String get pMonthly => 'Theo tháng';

  @override
  String proofHomes(String count) {
    return 'Tháng này đã dọn $count nhà';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Trung bình $rating sao · $count đánh giá';
  }

  @override
  String get proofReviewsTitle => 'Đánh giá gần đây';

  @override
  String get rebookTitle => 'Đặt lại dịch vụ lần trước?';

  @override
  String rebookBody(String service, String date) {
    return '$service · lần trước $date';
  }

  @override
  String get rebookButton => 'Đặt lại';

  @override
  String seatsLeft(String count) {
    return 'Còn $count chỗ';
  }

  @override
  String get reviewSheetTitle => 'Lần dọn này thế nào?';

  @override
  String get reviewPhotosAdd => 'Thêm ảnh';

  @override
  String get reviewPhotosHint => 'Tối đa 5 ảnh';

  @override
  String get reviewSaved => 'Cảm ơn bạn đã đánh giá';

  @override
  String get reviewPhotoFailed => 'Không tải được ảnh, hãy thử lại';

  @override
  String get referralTitle => 'Mời bạn bè, nhận phiếu giảm giá';

  @override
  String referralBody(String amount) {
    return 'Khi bạn bè hoàn tất lần đặt đầu, cả hai nhận phiếu $amount';
  }

  @override
  String get referralCopy => 'Sao chép mã';

  @override
  String get referralCopied => 'Đã sao chép mã giới thiệu';

  @override
  String get referralClaimTitle => 'Bạn có mã giới thiệu?';

  @override
  String get referralClaimField => 'Nhập mã giới thiệu';

  @override
  String get referralClaimButton => 'Áp dụng';

  @override
  String get referralClaimed => 'Đã áp dụng mã giới thiệu';

  @override
  String referralStats(String invited, String rewarded) {
    return 'Đã mời $invited · Đã thưởng $rewarded';
  }

  @override
  String get err_self_referral => 'Không thể dùng mã của chính bạn';

  @override
  String get err_referee_already_booked => 'Chỉ nhập mã trước lần đặt đầu tiên';

  @override
  String get err_already_referred => 'Bạn đã áp dụng mã giới thiệu';

  @override
  String get err_invalid_referral_code => 'Kiểm tra lại mã giới thiệu';

  @override
  String get err_referral_disabled => 'Hiện chưa nhận giới thiệu';

  @override
  String get err_invalid_photos => 'Chỉ đính kèm ảnh đã tải lên qua ứng dụng';

  @override
  String get welcomeOfferTitle => 'Ưu đãi lần đặt đầu';

  @override
  String get welcomeOfferBody =>
      'Tự động áp dụng cho lần đặt đầu của khách mới. Không cộng với phiếu giảm giá.';

  @override
  String get offerKindAmount => 'Số tiền (won)';

  @override
  String get offerKindPercent => 'Phần trăm (%)';

  @override
  String get offerValue => 'Giá trị giảm';

  @override
  String get offerEnabled => 'Bật';

  @override
  String get offerSaved => 'Đã lưu';

  @override
  String get referralSettingsTitle => 'Thưởng giới thiệu bạn bè';

  @override
  String get referralSettingsBody =>
      'Được thưởng khi bạn bè hoàn tất và thanh toán lần đặt đầu. Chặn tự giới thiệu và trùng số.';

  @override
  String get referralRewardAmount => 'Số tiền thưởng (won)';

  @override
  String get reviewsModerationTitle => 'Quản lý đánh giá';

  @override
  String get reviewHide => 'Ẩn';

  @override
  String get reviewShow => 'Hiện lại';

  @override
  String get reviewHiddenTag => 'Đã ẩn';

  @override
  String get growthAverageRating => 'Điểm trung bình';

  @override
  String growthReviewCount(String count) {
    return '$count đánh giá';
  }

  @override
  String get growthReferralConversion => 'Tỷ lệ chuyển đổi giới thiệu';

  @override
  String get growthTab => 'Tăng trưởng';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded/$invited người';
  }

  @override
  String get uMaintenanceTitle => 'Đang bảo trì';

  @override
  String get uMaintenanceBody =>
      'Chúng tôi đang bảo trì để nâng cao dịch vụ. Vui lòng quay lại sau.';

  @override
  String get cOps => 'Trạng thái hệ thống';

  @override
  String get oLevelGreen => 'Ổn định';

  @override
  String get oLevelYellow => 'Cần xem';

  @override
  String get oLevelRed => 'Cần xử lý';

  @override
  String get oOverall => 'Trạng thái máy chủ';

  @override
  String get oRefresh => 'Làm mới';

  @override
  String get oVersion => 'Phiên bản';

  @override
  String get oUptime => 'Thời gian chạy';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String get oChecks => 'Mục kiểm tra';

  @override
  String get oCheckDb => 'Cơ sở dữ liệu';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Phản hồi $ms ms · dung lượng $mb MB';
  }

  @override
  String get oCheckDisk => 'Ổ đĩa máy chủ';

  @override
  String oCheckDiskValue(String pct) {
    return 'Còn trống $pct%';
  }

  @override
  String get oCheckBackup => 'Sao lưu tự động';

  @override
  String oCheckBackupValue(String hours) {
    return 'Sao lưu cuối $hours giờ trước';
  }

  @override
  String get oCheckBackupNone => 'Chưa có bản sao lưu';

  @override
  String get oCheckErrors => 'Lỗi máy chủ (24 giờ)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count lỗi';
  }

  @override
  String get oCheckPayments => 'Thanh toán cần kiểm tra';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 giờ)';
  }

  @override
  String get oCheckWebhook => 'Thông báo thanh toán (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Sai chữ ký $count (24 giờ)';
  }

  @override
  String get oIntegrations => 'Dịch vụ bên ngoài';

  @override
  String get oIntNotSet => 'Chưa cài đặt';

  @override
  String oIntLastOk(String at) {
    return 'Thành công gần nhất $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Lỗi gần nhất $at ($code)';
  }

  @override
  String get oIntNever => 'Chưa có lượt sử dụng';

  @override
  String get oActDb =>
      'Không kết nối được cơ sở dữ liệu. Chạy malkkeum logs trên máy chủ; khởi động lại nếu vẫn lỗi.';

  @override
  String get oActDisk =>
      'Dung lượng trống dưới 10%. Xóa bản sao lưu cũ hoặc tăng dung lượng đĩa.';

  @override
  String get oActBackup =>
      'Sao lưu tự động đã quá hạn. Chạy malkkeum backup trên máy chủ và kiểm tra backups/backup.log.';

  @override
  String get oActErrors =>
      'Nhiều lỗi máy chủ. Xem các dòng error trong malkkeum logs; nếu lặp lại, hãy báo cho nhà phát triển.';

  @override
  String get oActPayments =>
      'Có thanh toán đã thành công nhưng chưa xử lý tự động. Kiểm tra trên PortOne và hoàn tiền thủ công nếu cần.';

  @override
  String get oActWebhook =>
      'Xác minh chữ ký thông báo thanh toán lỗi. Nhập lại webhook secret trong Thiết lập > Thanh toán (PortOne).';

  @override
  String get oActIntegration =>
      'Kết nối đang lỗi. Kiểm tra khóa trong Thiết lập và bấm Kiểm tra kết nối.';

  @override
  String get oActNotSet => 'Chưa cài đặt. Nhập khóa trong Thiết lập.';

  @override
  String get oAlerts => 'Cài đặt cảnh báo';

  @override
  String get oAlertsHint =>
      'Khi có sự cố, hộp thư và tin nhắn SMS đến điện thoại chủ cửa hàng. Cùng một sự cố chỉ gửi 6 giờ một lần.';

  @override
  String get oRuleSms => 'Gửi SMS lỗi';

  @override
  String get oRulePush => 'Thông báo đẩy lỗi';

  @override
  String get oRulePayment => 'Kết nối thanh toán lỗi';

  @override
  String get oRuleStuck => 'Thanh toán không tự xử lý';

  @override
  String get oRuleSocial => 'Đăng nhập mạng xã hội lỗi';

  @override
  String get oRuleBackup => 'Thiếu sao lưu tự động';

  @override
  String get oRuleDisk => 'Hết dung lượng đĩa';

  @override
  String get oQuietHours => 'Giờ yên tĩnh';

  @override
  String get oQuietFrom => 'Từ';

  @override
  String get oQuietTo => 'Đến';

  @override
  String oHour(String hour) {
    return '${hour}h';
  }

  @override
  String get oQuietHint =>
      'Không gửi cảnh báo trong giờ này; sẽ gửi một lần sau khi kết thúc.';

  @override
  String get oAlertPhone => 'Điện thoại nhận cảnh báo';

  @override
  String get oAlertPhoneHint =>
      'Để trống sẽ gửi đến số hỗ trợ trong thông tin doanh nghiệp.';

  @override
  String get oSave => 'Lưu';

  @override
  String get oSaved => 'Đã lưu cài đặt cảnh báo';

  @override
  String get oSaveFailed => 'Không lưu được. Kiểm tra lại giá trị đã nhập.';

  @override
  String get oLoadFailed => 'Không tải được trạng thái';

  @override
  String get oBackupOffsite => 'Sao lưu ngoài máy chủ (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Đang tắt. Bật trong Thiết lập > Sao lưu ngoài máy chủ.';

  @override
  String get oLastBackup => 'Sao lưu gần nhất';

  @override
  String get oDiskFree => 'Dung lượng trống';

  @override
  String get oNoData => 'Chưa có dữ liệu';

  @override
  String get cIntBackup => 'Sao lưu ngoài (tương thích S3)';

  @override
  String get pTabJobs => 'Việc';

  @override
  String get pTabQuotes => 'Báo giá';

  @override
  String get pTabSchedule => 'Lịch';

  @override
  String get pIntroTitle => 'Việc, lịch và thanh toán\ncho chuyên gia dọn dẹp';

  @override
  String get pIntroBody => 'Làm ở khu vực và giờ bạn muốn, nhận tiền hàng tuần';

  @override
  String get pOnbTitle => 'Thông tin của bạn';

  @override
  String get pOnbName => 'Tên của bạn';

  @override
  String get pOnbTeam => 'Tên đội';

  @override
  String get pOnbServices => 'Dịch vụ bạn làm';

  @override
  String get pOnbAreas => 'Khu vực làm việc';

  @override
  String get pOnbDone => 'Đăng ký';

  @override
  String get pPendingTitle => 'Đang chờ duyệt';

  @override
  String get pPendingBody =>
      'Chúng tôi sẽ báo khi được duyệt. Hãy thêm tài khoản nhận tiền.';

  @override
  String get pSuspended => 'Tài khoản bị tạm dừng, hãy liên hệ vận hành.';

  @override
  String get pDirect => 'Đặt ngay';

  @override
  String get pQuoteReq => 'Yêu cầu báo giá';

  @override
  String get pShowClosed => 'Hiện việc đã đóng';

  @override
  String get pSortNewest => 'Mới nhất';

  @override
  String get pSortVisit => 'Ngày gần nhất';

  @override
  String get pSortAmount => 'Giá cao nhất';

  @override
  String get pNoJobs => 'Chưa có việc phù hợp';

  @override
  String get pNoJobsBody => 'Mở rộng dịch vụ, khu vực, giờ để thấy thêm';

  @override
  String get pPayout => 'Bạn nhận';

  @override
  String get pCustomerEstimate => 'Ước tính của khách';

  @override
  String get pNew => 'MỚI';

  @override
  String get pClosed => 'Đã đóng';

  @override
  String get pPrivacyNote => 'Địa chỉ và thông tin khách hiện sau khi nhận';

  @override
  String get pAccept => 'Nhận việc';

  @override
  String get pAcceptConfirm => 'Nhận việc này?';

  @override
  String get pAcceptBody =>
      'Việc sẽ vào lịch và khách được báo. Hủy trong 2 ngày trước bị hạn chế.';

  @override
  String get pAccepted => 'Đã nhận việc';

  @override
  String get pSendQuote => 'Gửi báo giá';

  @override
  String get pQuotePrice => 'Giá cho khách';

  @override
  String get pQuoteNote => 'Ghi chú cho đội';

  @override
  String get pQuoteSent => 'Đã gửi báo giá';

  @override
  String pFee(String rate) {
    return 'Phí $rate%';
  }

  @override
  String get pYouGet => 'Bạn nhận';

  @override
  String get pQuoteAll => 'Tất cả';

  @override
  String get pQ_waiting => 'Đang chờ';

  @override
  String get pQ_selected => 'Được chọn';

  @override
  String get pQ_rejected => 'Không chọn';

  @override
  String get pQ_closed => 'Đã đóng';

  @override
  String get pUnseenOnly => 'Chỉ kết quả mới';

  @override
  String get pNoQuotes => 'Chưa có báo giá';

  @override
  String get pMyQuote => 'Báo giá của tôi';

  @override
  String get pWithdraw => 'Rút báo giá';

  @override
  String get pWithdrawn => 'Đã rút báo giá';

  @override
  String get pOnlyMine => 'Chỉ của tôi';

  @override
  String pJobsCount(String n) {
    return '$n việc';
  }

  @override
  String get pNoSchedule => 'Không có lịch';

  @override
  String get pCancelledBanner => 'Việc đã bị hủy, không thể hoàn tất.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Đổi lịch: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Được';

  @override
  String get pRescheduleNo => 'Không được';

  @override
  String get pCustomer => 'Khách';

  @override
  String get pCall => 'Gọi (số ẩn)';

  @override
  String get pCallSoon => 'Gọi số ẩn sẽ bật khi ra mắt';

  @override
  String get pQuietHours => 'Không gọi sau 20 giờ';

  @override
  String get pAssignee => 'Người phụ trách';

  @override
  String get pChangeAssignee => 'Đổi người phụ trách';

  @override
  String get pCustomerRequests => 'Yêu cầu của khách';

  @override
  String get pHousehold => 'Thông tin hộ gia đình';

  @override
  String get pPets => 'Thú cưng';

  @override
  String get pPetDog => 'Chó';

  @override
  String get pPetCat => 'Mèo';

  @override
  String get pPetBird => 'Chim';

  @override
  String get pPetFish => 'Cá';

  @override
  String get pPetOther => 'Thú khác';

  @override
  String get pAllergies => 'Dị ứng & nhạy cảm';

  @override
  String get pPreferredProducts => 'Sản phẩm ưa thích';

  @override
  String get pParking => 'Đỗ xe';

  @override
  String pFloor(String floor) {
    return 'Tầng $floor';
  }

  @override
  String get pElevatorYes => 'Có thang máy';

  @override
  String get pElevatorNo => 'Không có thang máy';

  @override
  String get pTeamMemo => 'Ghi chú đội (khách không thấy)';

  @override
  String get pMemoSaved => 'Đã lưu ghi chú';

  @override
  String get pPayoutBreakdown => 'Chi tiết thanh toán';

  @override
  String get pAfterBalance => 'Thanh toán sau khi khách trả phần còn lại';

  @override
  String get pChatOps => 'Chat với vận hành';

  @override
  String get pComplete => 'Hoàn tất việc';

  @override
  String get pBeforePhotos => 'Ảnh trước';

  @override
  String get pAfterPhotos => 'Ảnh sau';

  @override
  String get pAddPhoto => 'Thêm ảnh';

  @override
  String get pChecklist => 'Danh sách kiểm tra';

  @override
  String get pCheck1 => 'Đã dọn mọi khu vực yêu cầu';

  @override
  String get pCheck2 => 'Đã dọn rác, thu dụng cụ';

  @override
  String get pCheck3 => 'Đã kiểm tra cửa sổ, điện, nước';

  @override
  String get pCheck4 => 'Đã làm theo yêu cầu của khách';

  @override
  String get pCompleteCta => 'Đánh dấu hoàn tất';

  @override
  String get pCompleteNeed => 'Cần ít nhất 1 ảnh mỗi loại và tích đủ mục';

  @override
  String get pCompleted => 'Làm tốt lắm!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount sẽ trả vào $date';
  }

  @override
  String get pPayoutWaiting => 'Ngày trả được định sau khi khách trả';

  @override
  String get pPendingPayout => 'Sắp nhận';

  @override
  String get pSettlements => 'Lịch sử thanh toán';

  @override
  String get pS_waiting_balance => 'Chờ khách trả';

  @override
  String get pS_pending => 'Sắp trả';

  @override
  String get pS_paid => 'Đã trả';

  @override
  String get pS_held => 'Tạm giữ';

  @override
  String get pReviews => 'Đánh giá';

  @override
  String get pNoReviews => 'Chưa có đánh giá';

  @override
  String get pReplyLater => 'Sắp có tính năng trả lời';

  @override
  String get pServicesAreas => 'Dịch vụ & khu vực';

  @override
  String get pPayoutAccount => 'Tài khoản nhận tiền';

  @override
  String get pBank => 'Ngân hàng';

  @override
  String get pAccountNumber => 'Số tài khoản';

  @override
  String get pHolder => 'Chủ tài khoản';

  @override
  String get pVerified => 'Đã xác minh';

  @override
  String get pUnverified => 'Đang xác minh';

  @override
  String get pAccountSaved => 'Đã lưu. Thay đổi sẽ được xác minh lại.';

  @override
  String get pWorkSchedule => 'Lịch làm việc';

  @override
  String get pWeekdays => 'Ngày làm';

  @override
  String get pDayParts => 'Khung giờ';

  @override
  String get pDaysOff => 'Ngày nghỉ';

  @override
  String get pAddDayOff => 'Thêm ngày nghỉ';

  @override
  String get pSaved => 'Đã lưu';

  @override
  String get pTeam => 'Thành viên';

  @override
  String get pOwner => 'Chủ';

  @override
  String get pInvited => 'Đã mời';

  @override
  String get pInvite => 'Mời thành viên';

  @override
  String get pInviteSent => 'Đã gửi lời mời';

  @override
  String get pRemove => 'Xóa';

  @override
  String get pNotifications => 'Thông báo';

  @override
  String get pNotifyDirect => 'Việc đặt ngay mới';

  @override
  String get pNotifyQuotes => 'Yêu cầu & kết quả báo giá';

  @override
  String get pNotifyChat => 'Tin nhắn vận hành';

  @override
  String get pQuietNight => 'Yên lặng ban đêm (22–08)';

  @override
  String get pNewInquiry => 'Hỏi mới';

  @override
  String get pTopic_settlement => 'Thanh toán';

  @override
  String get pTopic_reschedule => 'Đổi lịch / hủy';

  @override
  String get pTopic_app => 'Hỗ trợ ứng dụng';

  @override
  String get pOpsTeam => 'Đội vận hành';

  @override
  String get pViewJob => 'Xem việc';

  @override
  String pBookingNo(String n) {
    return 'Mã đặt $n';
  }

  @override
  String get pSize => 'Diện tích';

  @override
  String get pSchedule => 'Lịch';

  @override
  String get pSpace => 'Không gian';

  @override
  String get pNavigate => 'Chỉ đường';

  @override
  String get pNavHint =>
      'Mở địa chỉ trong ứng dụng bản đồ. Nếu chưa cài, sẽ mở bản đồ web.';

  @override
  String get pOfflineSaved => 'Không có sóng. Đã lưu, sẽ gửi khi có mạng.';

  @override
  String get pPhotoRetry => 'Tải lại';

  @override
  String get pPhotoWaiting => 'Ảnh chưa tải lên sẽ tự gửi khi có mạng.';

  @override
  String pUploadedCount(String total, String done) {
    return 'Đã tải $done/$total ảnh';
  }

  @override
  String get cIntPayout => 'Chi trả đối tác';

  @override
  String get poTabSettlements => 'Quyết toán';

  @override
  String get poTabPayouts => 'Chi trả';

  @override
  String get poState_requested => 'Đã yêu cầu';

  @override
  String get poState_sent => 'Đã gửi';

  @override
  String get poState_paid => 'Đã trả';

  @override
  String get poState_failed => 'Thất bại';

  @override
  String get poProviderManual => 'Chuyển khoản tay';

  @override
  String get poProviderToss => 'Toss chi hộ';

  @override
  String get poShowAccount => 'Xem tài khoản';

  @override
  String get poAccountTitle => 'Thông tin chuyển khoản';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'Chuyển $amount won tới $holder · $bank · $account, rồi bấm xác nhận.';
  }

  @override
  String get poConfirmPaid => 'Đánh dấu đã chuyển';

  @override
  String get poMarkFailed => 'Đánh dấu thất bại';

  @override
  String get poReasonTitle => 'Lý do thất bại';

  @override
  String get poReasonHint => 'VD: sai tài khoản, đã hủy';

  @override
  String get poSend => 'Gửi qua Toss';

  @override
  String get poSync => 'Kiểm tra trạng thái';

  @override
  String get poRetry => 'Thử lại';

  @override
  String get poNoPayouts => 'Chưa có khoản chi trả';

  @override
  String poRequestedToast(String n) {
    return 'Đã tạo $n yêu cầu chi trả';
  }

  @override
  String get poReasonRequired => 'Nhập lý do';

  @override
  String get poRevealNote => 'Việc xem tài khoản được ghi lại';

  @override
  String get poSellerAction => 'Đăng ký người bán';

  @override
  String get poSellerTitle => 'Đăng ký làm người bán Toss';

  @override
  String get poSellerHint =>
      'Dùng tài khoản nhận tiền đã xác minh của đối tác. Chỉ nhập thông tin kinh doanh.';

  @override
  String get poSellerIndividual => 'Cá nhân';

  @override
  String get poSellerCompany => 'Doanh nghiệp';

  @override
  String get poSellerName => 'Họ tên';

  @override
  String get poSellerRepresentative => 'Tên người đại diện';

  @override
  String get poSellerRegNo => 'Mã số doanh nghiệp (10 chữ số)';

  @override
  String get poSellerEmail => 'Email đối soát';

  @override
  String get poSellerPhone => 'Số điện thoại';

  @override
  String get poSellerSubmit => 'Đăng ký';

  @override
  String poSellerDone(String status) {
    return 'Trạng thái người bán: $status';
  }

  @override
  String get pvManage => 'Quản lý đồng ý';

  @override
  String get pvOptional => 'Tùy chọn';

  @override
  String get pvTerms => 'Đồng ý điều khoản dịch vụ';

  @override
  String get pvPrivacy => 'Đồng ý thu thập và sử dụng dữ liệu cá nhân';

  @override
  String get pvOverseas => 'Đồng ý chuyển dữ liệu cá nhân ra nước ngoài';

  @override
  String get pvMarketing => 'Nhận thông tin khuyến mãi';

  @override
  String get pvMarketingHint =>
      'Nhận tin ưu đãi và sự kiện qua SMS, KakaoTalk và thông báo ứng dụng. Bạn có thể tắt bất cứ lúc nào.';

  @override
  String get pvReconsent =>
      'Chính sách quyền riêng tư đã thay đổi. Vui lòng xem lại và đồng ý lại.';

  @override
  String get pvSaved => 'Đã lưu cài đặt đồng ý';

  @override
  String get pvExport => 'Tải dữ liệu của tôi';

  @override
  String get pvExportHint =>
      'Hiển thị toàn bộ dữ liệu chúng tôi lưu về bạn dưới dạng JSON. Bạn có thể sao chép và lưu giữ.';

  @override
  String get pvCopy => 'Sao chép';

  @override
  String get pvCopied => 'Đã sao chép';

  @override
  String get pvExportFailed =>
      'Không thể tải dữ liệu của bạn. Vui lòng thử lại sau.';

  @override
  String get safetyEmergency => 'Liên hệ khẩn cấp';

  @override
  String get emergencyPolice => '112 Cảnh sát';

  @override
  String get emergencyFire => '119 Cứu hỏa & cứu thương';

  @override
  String get emergencyShop => 'Hỗ trợ khách hàng';

  @override
  String get caseReportAction => 'Báo cáo sự cố';

  @override
  String get caseReportTitle => 'Có chuyện gì đã xảy ra?';

  @override
  String get caseKindDamage => 'Hư hỏng';

  @override
  String get caseKindLoss => 'Thất lạc';

  @override
  String get caseKindComplaint => 'Khiếu nại';

  @override
  String get caseKindNoShow => 'Nhân viên không đến';

  @override
  String get caseKindSafety => 'Vấn đề an toàn';

  @override
  String get caseKindPayment => 'Tranh chấp thanh toán';

  @override
  String get caseSummaryHint => 'Mô tả chi tiết (tối đa 300 ký tự)';

  @override
  String get caseSubmit => 'Gửi';

  @override
  String get caseSubmitted =>
      'Đã tiếp nhận. Nhân viên sẽ phản hồi trong 24 giờ.';

  @override
  String get caseFailed => 'Không gửi được, hãy thử lại.';

  @override
  String get checkInAction => 'Check-in';

  @override
  String get checkOutAction => 'Check-out';

  @override
  String checkedInAt(String time) {
    return 'Đến lúc $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Rời đi lúc $time';
  }

  @override
  String get entryCodeAction => 'Xem mã cửa ra vào';

  @override
  String get entryCodeTitle => 'Mã cửa ra vào';

  @override
  String get entryCodeNotToday => 'Chỉ xem được vào ngày đến';

  @override
  String get entryCodeEmpty => 'Chưa có mã cửa';

  @override
  String get actionFailed => 'Không thực hiện được, hãy thử lại.';

  @override
  String get consoleCasesTitle => 'Hàng đợi vụ việc';

  @override
  String get consoleCasesEmpty => 'Không có vụ việc đang mở';

  @override
  String get caseOverdue => 'Quá hạn';

  @override
  String get caseStatusOpen => 'Mở';

  @override
  String get caseStatusInvestigating => 'Đang xem xét';

  @override
  String get caseStatusResolved => 'Đã giải quyết';

  @override
  String get caseStatusRejected => 'Từ chối';

  @override
  String get caseReassign => 'Phân công lại';

  @override
  String get caseRefund => 'Hoàn tiền';

  @override
  String get caseHold => 'Tạm giữ thanh toán';

  @override
  String get caseNoteHint => 'Ghi chú nội bộ';

  @override
  String get caseSave => 'Lưu';

  @override
  String get cSetup => 'Thiết lập';

  @override
  String get cSetupTitle => 'Sẵn sàng ra mắt';

  @override
  String cSetupProgress(String done, String total) {
    return 'Xong $done/$total';
  }

  @override
  String get cSetupAllDone => 'Mọi thứ đã sẵn sàng!';

  @override
  String get cSetupBusiness => 'Thông tin doanh nghiệp';

  @override
  String get cSetupBusinessName => 'Tên dịch vụ';

  @override
  String get cSetupSupportPhone => 'SĐT hỗ trợ';

  @override
  String get cSetupSupportEmail => 'Email hỗ trợ';

  @override
  String get cSetupSupportHours => 'Giờ hỗ trợ';

  @override
  String get cSetupColor => 'Màu thương hiệu';

  @override
  String get cSetupLogo => 'Tải logo lên';

  @override
  String get cSetupCompany => 'Thông tin công ty (hiện ở chân trang)';

  @override
  String get cSetupLegalName => 'Tên pháp lý';

  @override
  String get cSetupCeo => 'Người đại diện';

  @override
  String get cSetupRegNo => 'Mã số đăng ký';

  @override
  String get cSetupMailOrderNo => 'Số đăng ký bán hàng';

  @override
  String get cSetupAddress => 'Địa chỉ';

  @override
  String get cSetupPrivacyOfficer => 'Người phụ trách bảo mật';

  @override
  String get cSetupStoreLinks => 'Liên kết cửa hàng (điền để bật nút trên web)';

  @override
  String get cSetupCustomerApp => 'Ứng dụng khách';

  @override
  String get cSetupPartnerApp => 'Ứng dụng đối tác';

  @override
  String get cSetupPayMethods => 'Phương thức thanh toán';

  @override
  String get cSetupPayMethodsHint =>
      'Bật/tắt phương thức khách thấy. Áp dụng ngay.';

  @override
  String get cReviewTitle => 'Tài khoản demo cho duyệt ứng dụng';

  @override
  String get cReviewHint =>
      'Người duyệt không nhận được SMS Hàn Quốc. Ghi số và mã 6 chữ số vào ghi chú duyệt. Tự tắt khi hết hạn.';

  @override
  String get cReviewPhone => 'Số điện thoại demo';

  @override
  String get cReviewCode => 'Mã cố định (6 chữ số)';

  @override
  String cReviewActiveUntil(String date) {
    return 'Dùng được đến $date';
  }

  @override
  String get cReviewEnable => 'Bật (14 ngày)';

  @override
  String get pDeleteAccountBody =>
      'Nhóm và dữ liệu cá nhân sẽ bị xóa vĩnh viễn. Hãy hoàn tất việc đã nhận và khoản chờ thanh toán trước.';

  @override
  String get err_has_active_jobs =>
      'Bạn còn việc đã nhận. Hãy hoàn thành hoặc nhờ hỗ trợ chuyển giao.';

  @override
  String get err_pending_payouts =>
      'Còn khoản chờ thanh toán. Có thể xóa sau khi nhận tiền.';

  @override
  String get err_phone_required =>
      'Hãy xác minh số điện thoại trước khi nhận việc.';

  @override
  String get nAlerts => 'Thông báo';

  @override
  String get nEmpty => 'Chưa có thông báo';

  @override
  String nUnread(String count) {
    return '$count thông báo chưa đọc';
  }

  @override
  String get pVerifyPhone => 'Xác minh';

  @override
  String get mMyJobs => 'Việc của tôi';

  @override
  String get mNoJobs =>
      'Chưa có việc được giao. Việc trưởng nhóm giao sẽ hiện ở đây.';

  @override
  String mTeam(String team) {
    return 'Thành viên $team';
  }

  @override
  String get cSetupSave => 'Lưu';

  @override
  String get cSetupSaved => 'Đã lưu';

  @override
  String get cSetupTest => 'Kiểm tra kết nối';

  @override
  String get cSetupClear => 'Ngắt kết nối';

  @override
  String get cSetupConnected => 'Đã kết nối';

  @override
  String get cSetupNotConnected => 'Chưa kết nối';

  @override
  String get cSetupFromEnv => 'Đang dùng cấu hình máy chủ';

  @override
  String get cSetupCheckInApp => 'Đã lưu · đăng nhập từ ứng dụng để xác nhận';

  @override
  String get cSetupInvalidKey =>
      'Khóa không hợp lệ, hãy kiểm tra giá trị đã sao chép';

  @override
  String get cSetupUnreachable => 'Không kết nối được, hãy thử lại sau';

  @override
  String get cSetupKeepValue => 'Đã lưu (chỉ nhập khi muốn thay)';

  @override
  String get cSetupGuide => 'Cách thiết lập';

  @override
  String get cSetupOpenSite => 'Mở trang';

  @override
  String get cSetupWebhook => 'URL webhook (dán vào PortOne)';

  @override
  String get cCopied => 'Đã sao chép';

  @override
  String get cSetupDevMode => 'Chế độ thử: không thanh toán hay gửi tin thật';

  @override
  String get cSetupOptional => 'Tùy chọn';

  @override
  String get cIntPortone => 'Thanh toán (PortOne)';

  @override
  String get cIntSolapi => 'SMS & KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Thông báo đẩy (Firebase)';

  @override
  String get cIntKakao => 'Đăng nhập Kakao';

  @override
  String get cIntNaver => 'Đăng nhập Naver';

  @override
  String get cIntGoogle => 'Đăng nhập Google';

  @override
  String get cIntApple => 'Đăng nhập Apple';

  @override
  String get cFirstRunTitle => 'Chào mừng! Hãy tạo tài khoản chủ';

  @override
  String get cFirstRunBody => 'Nhập mã cài đặt 12 ký tự hiển thị khi cài đặt.';

  @override
  String get cFirstRunCode => 'Mã cài đặt';

  @override
  String get cName => 'Tên';

  @override
  String get cFirstRunCreate => 'Tạo tài khoản và bắt đầu';

  @override
  String get cWrongSetupCode => 'Mã cài đặt không đúng';

  @override
  String get cWeakPassword => 'Mật khẩu cần ít nhất 12 ký tự';

  @override
  String get cInvalidValue => 'Vui lòng kiểm tra giá trị';

  @override
  String get subTitle => 'Dọn định kỳ';

  @override
  String get subNew => 'Đăng ký dọn định kỳ';

  @override
  String get subCadence => 'Tần suất';

  @override
  String get subWeekly => 'Hằng tuần';

  @override
  String get subBiweekly => '2 tuần một lần';

  @override
  String get subEvery4Weeks => '4 tuần một lần';

  @override
  String get subWeekday => 'Thứ';

  @override
  String get subHour => 'Giờ đến';

  @override
  String subDiscountNote(String percent) {
    return 'Dọn định kỳ được giảm $percent% mỗi lần';
  }

  @override
  String get subChargeNote =>
      'Mỗi lần dọn được trừ vào thẻ đã lưu, trước một ngày';

  @override
  String get subCreate => 'Đăng ký';

  @override
  String get subCreated => 'Đã đăng ký dọn định kỳ';

  @override
  String get subNeedAddress => 'Hãy thêm địa chỉ dọn trước';

  @override
  String get subListEmpty => 'Chưa có gói dọn định kỳ nào';

  @override
  String get subStatusActive => 'Đang dùng';

  @override
  String get subStatusPaused => 'Tạm dừng';

  @override
  String get subStatusCancelled => 'Đã hủy';

  @override
  String subNextVisit(String date) {
    return 'Lần dọn tiếp $date';
  }

  @override
  String get subPause => 'Tạm dừng';

  @override
  String get subResume => 'Tiếp tục';

  @override
  String get subCancelSub => 'Hủy gói định kỳ';

  @override
  String get subCancelConfirm =>
      'Các lần dọn sau sẽ bị hủy. Lịch đã đặt cần hủy riêng và có thể phát sinh phí.';

  @override
  String get subSkip => 'Bỏ qua lần này';

  @override
  String get subMove => 'Đổi ngày';

  @override
  String get subVisitLocked => 'Không đổi được từ ngày trước khi dọn';

  @override
  String get subPausedPayment =>
      'Tạm dừng vì thanh toán thất bại nhiều lần. Đổi thẻ rồi tiếp tục.';

  @override
  String get subStatePlanned => 'Dự kiến';

  @override
  String get subStateBooked => 'Đã đặt';

  @override
  String get subStateSkipped => 'Đã bỏ qua';

  @override
  String get subStateMissed => 'Bỏ lỡ';

  @override
  String get pSubsTitle => 'Khách định kỳ';

  @override
  String get pSubsEmpty => 'Chưa có khách định kỳ';

  @override
  String get cSubsTitle => 'Gói định kỳ';

  @override
  String get cSubsEdit => 'Sửa thay khách';

  @override
  String get cMrr => 'Doanh thu định kỳ/tháng (MRR)';

  @override
  String get cChurn => 'Tỷ lệ rời bỏ';

  @override
  String get cActiveSubs => 'Gói đang hoạt động';

  @override
  String get cRecognized => 'Doanh thu ghi nhận trong kỳ';

  @override
  String get cSubsLoadFailed => 'Không tải được danh sách gói';

  @override
  String get tTaxSection => 'Thuế';

  @override
  String tVatQuarter(String q) {
    return 'Thuế GTGT Q$q CSV';
  }

  @override
  String get tVatYear => 'Năm';

  @override
  String get tExportWithholding => 'Bảng khấu trừ CSV';

  @override
  String get tExportTaxInvoices => 'CSV tải hóa đơn thuế';

  @override
  String get tTaxLayoutNote =>
      'Kiểm tra cột với mẫu 홈택스 trước khi tải lên. Bố cục chưa được xác minh.';

  @override
  String get tCashReceipts => 'Biên lai tiền mặt';

  @override
  String get tCashIssued => 'Đã phát hành';

  @override
  String get tCashFailed => 'Phát hành lỗi';

  @override
  String get tCashPending => 'Đang chờ';

  @override
  String get tCashCancelled => 'Đã hủy';

  @override
  String get tReissue => 'Phát hành lại';

  @override
  String get tTaxInvoices => 'Hóa đơn thuế';

  @override
  String get tApprovalNumber => 'Số phê duyệt';

  @override
  String get tIssuedOn => 'Ngày phát hành';

  @override
  String get tMarkIssued => 'Đánh dấu đã phát hành';

  @override
  String get tQueueEmpty => 'Không có yêu cầu đang chờ';

  @override
  String get tWithholdingLabel => 'Khấu trừ thuế';

  @override
  String get tGrossAmount => 'Tổng gộp';

  @override
  String get tIncomeTax => 'Thuế thu nhập';

  @override
  String get tLocalTax => 'Thuế thu nhập địa phương';

  @override
  String get tNetAmount => 'Thực nhận';

  @override
  String get tNoWithholding => 'Không khấu trừ (doanh nghiệp đã đăng ký)';

  @override
  String get tEstWithholding => 'Khấu trừ dự kiến (phần chờ)';

  @override
  String get tReceiptOptions => 'Tùy chọn biên lai';

  @override
  String get tWantCashReceipt => 'Nhận biên lai tiền mặt';

  @override
  String get tCashForIncome => 'Khấu trừ thu nhập (số điện thoại)';

  @override
  String get tCashForBusiness => 'Chứng từ chi phí (mã doanh nghiệp)';

  @override
  String get tWantTaxInvoice => 'Nhận hóa đơn thuế (doanh nghiệp)';

  @override
  String get tPhoneForReceipt => 'Số điện thoại';

  @override
  String get tBusinessNumber => 'Mã số đăng ký doanh nghiệp';

  @override
  String get tCompanyName => 'Tên công ty';

  @override
  String get tRepresentative => 'Người đại diện';

  @override
  String get tInvoiceEmail => 'Email nhận hóa đơn';

  @override
  String get tReceiptSave => 'Lưu và thanh toán';

  @override
  String get tReceiptSaveFailed => 'Không lưu được thông tin biên lai';

  @override
  String get tTaxType => 'Loại thuế';

  @override
  String get tTaxFreelancer => 'Freelancer (khấu trừ)';

  @override
  String get tTaxBusiness => 'Doanh nghiệp đã đăng ký (không khấu trừ)';

  @override
  String get tReceiptSettings => 'Cài đặt biên lai';

  @override
  String get reviewRuleLine =>
      'Cấm lời lẽ xúc phạm, thông tin cá nhân, nội dung giả mạo hoặc quảng cáo. Đánh giá bị báo cáo sẽ bị ẩn.';

  @override
  String get reportAction => 'Báo cáo';

  @override
  String get reportSheetTitle => 'Báo cáo đánh giá này?';

  @override
  String get reportReasonSpam => 'Spam hoặc quảng cáo';

  @override
  String get reportReasonOffensive => 'Xúc phạm hoặc thù ghét';

  @override
  String get reportReasonPersonal => 'Có thông tin cá nhân';

  @override
  String get reportReasonOther => 'Khác';

  @override
  String get reportNoteHint => 'Chi tiết (không bắt buộc, tối đa 300 ký tự)';

  @override
  String get reportSubmit => 'Gửi báo cáo';

  @override
  String get reportThanks => 'Cảm ơn bạn. Đội ngũ vận hành sẽ xem xét.';

  @override
  String get reportAlready => 'Bạn đã báo cáo đánh giá này';

  @override
  String get reportFailed => 'Không gửi được báo cáo, hãy thử lại.';

  @override
  String get reviewBlocked =>
      'Tài khoản này không thể đánh giá. Liên hệ hỗ trợ.';

  @override
  String get modTitle => 'Quản lý báo cáo đánh giá';

  @override
  String get modEmpty => 'Không có báo cáo nào đang chờ';

  @override
  String modReports(String count) {
    return '$count báo cáo';
  }

  @override
  String get modKeep => 'Giữ lại';

  @override
  String get modHide => 'Ẩn';

  @override
  String get modDelete => 'Xóa';

  @override
  String get modBlockAuthor => 'Hạn chế người viết';

  @override
  String get modUnblockAuthor => 'Bỏ hạn chế';

  @override
  String get modDone => 'Đã xử lý';

  @override
  String get modFailed => 'Không thực hiện được, hãy thử lại.';

  @override
  String get modHidden => 'Đánh giá đã ẩn';

  @override
  String uUpdateBanner(String version) {
    return 'Đã có phiên bản $version';
  }

  @override
  String get uUpdateNow => 'Cập nhật';

  @override
  String get uUpdateLater => 'Để sau';

  @override
  String get uUpdateRequiredTitle => 'Cần cập nhật ứng dụng';

  @override
  String get uUpdateRequiredBody =>
      'Phiên bản này không còn được hỗ trợ. Vui lòng cập nhật từ cửa hàng.';

  @override
  String get uUpdateStore => 'Cập nhật trên cửa hàng';

  @override
  String get uUpdateStoreMissing =>
      'Liên kết cập nhật chưa sẵn sàng. Vui lòng thử lại sau.';

  @override
  String uCurrentVersion(String version) {
    return 'Phiên bản hiện tại $version';
  }

  @override
  String get uAppVersionTitle => 'Quản lý phiên bản ứng dụng';

  @override
  String get uAppVersionHint =>
      'Ứng dụng thấp hơn bản tối thiểu sẽ dừng ở màn hình cập nhật. Thấp hơn bản mới nhất sẽ thấy banner. Định dạng: 1.2.0';

  @override
  String get uMinVersion => 'Phiên bản tối thiểu';

  @override
  String get uLatestVersion => 'Phiên bản mới nhất';

  @override
  String get webBookNow => 'Đặt lịch ngay trên web';

  @override
  String get webBookSub => 'Đặt lịch không cần cài ứng dụng';

  @override
  String get apPgBrowserNote =>
      'Hoàn tất thanh toán trên trình duyệt, sau đó quay lại đây và nhấn nút bên dưới.';

  @override
  String get apPgBrowserDone => 'Tôi đã thanh toán xong';
}
