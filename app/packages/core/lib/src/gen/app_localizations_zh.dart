// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class TZh extends T {
  TZh([String locale = 'zh']) : super(locale);

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get next => '下一步';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get change => '更改';

  @override
  String get retry => '重试';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get required => '必填';

  @override
  String get viewAll => '查看全部';

  @override
  String get today => '今天';

  @override
  String get errorGeneric => '出了点问题，请稍后重试。';

  @override
  String get errorNetwork => '请检查网络连接';

  @override
  String get err_invalid_phone => '请检查手机号码';

  @override
  String get err_otp_invalid => '验证码不正确';

  @override
  String get err_otp_expired => '验证码已过期，请重新获取';

  @override
  String get err_rate_limited => '尝试次数过多，请稍后再试';

  @override
  String get err_studio_too_large => '单间清洁仅限10坪以下的房屋';

  @override
  String get err_date_out_of_range => '请选择明天起60天内的日期';

  @override
  String get err_slot_full => '该时段已满，请选择其他时间';

  @override
  String get err_coupon_expired => '优惠券已过期';

  @override
  String get err_coupon_used => '优惠券已使用';

  @override
  String get err_coupon_wrong_service => '该优惠券不适用于此服务';

  @override
  String get err_payment_failed => '付款被拒绝，请换一种方式';

  @override
  String get err_payment_method_required => '请选择付款方式';

  @override
  String get err_cancellation_window_closed => '上门前2天内需通过客服取消';

  @override
  String get err_address_required => '请添加上门地址';

  @override
  String get err_already_taken => '其他服务者已抢先接单';

  @override
  String get err_invalid_address => '请填写完整地址';

  @override
  String get tabHome => '首页';

  @override
  String get tabBookings => '预约';

  @override
  String get tabChat => '咨询';

  @override
  String get tabMore => '更多';

  @override
  String get introTitle => '专业清洁\n一分钟轻松预约';

  @override
  String get introBody => '明码标价 · 认证团队 · 实时进度';

  @override
  String get introStart => '使用手机号开始';

  @override
  String get loginPhoneTitle => '请输入手机号码';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => '获取验证码';

  @override
  String get loginCodeTitle => '请输入6位验证码';

  @override
  String loginCodeSentTo(String phone) {
    return '已发送至 $phone';
  }

  @override
  String get loginResend => '重新发送';

  @override
  String get loginVerify => '验证';

  @override
  String get loginTerms => '继续即表示同意服务条款和隐私政策';

  @override
  String get profileTitle => '怎么称呼您？';

  @override
  String get profileNameHint => '姓名';

  @override
  String get profileDone => '开始使用';

  @override
  String get welcomeToast => '已发放2张新人优惠券';

  @override
  String get svc_studio => '单间清洁';

  @override
  String get svc_kitchen => '厨房清洁';

  @override
  String get svc_bathroom => '卫生间清洁';

  @override
  String get svc_mattress => '床垫清洁';

  @override
  String get svc_aircon => '空调清洗';

  @override
  String get svc_sofa => '沙发清洁';

  @override
  String get svc_move_out => '搬出清洁';

  @override
  String get svc_move_in => '入住清洁';

  @override
  String get svcShort_studio => '单间';

  @override
  String get svcShort_kitchen => '厨房';

  @override
  String get svcShort_bathroom => '卫生间';

  @override
  String get svcShort_mattress => '床垫';

  @override
  String get svcShort_aircon => '空调';

  @override
  String get svcShort_sofa => '沙发';

  @override
  String get svcShort_move_out => '搬出';

  @override
  String get svcShort_move_in => '入住';

  @override
  String get svcDesc_studio => '对10坪以下单间（1室1卫）进行2小时细致清洁。';

  @override
  String get svcDesc_kitchen => '重点清洁水槽、灶台、油烟机外部和台面。';

  @override
  String get svcDesc_bathroom => '清洁置物架、水龙头、洗手台和马桶内外，并擦干地面。';

  @override
  String get svcDesc_mattress => '专业设备吸除灰尘、螨虫和污渍，并蒸汽杀菌。';

  @override
  String get svcDesc_aircon => '拆机后高压清洗换热器、风扇和滤网并杀菌。';

  @override
  String get svcDesc_sofa => '使用适配面料的清洁剂分解污渍，湿式抽吸清洗。';

  @override
  String get svcDesc_move_out => '搬出前，专业团队携带设备清洁空房。';

  @override
  String get svcDesc_move_in => '入住前，专业团队携带设备清洁新家。';

  @override
  String get svcNotes_bathroom =>
      '下水道或马桶堵塞时服务可能受限\n不提供需特殊药剂、天花板和排风扇清洁\n陈年霉斑和顽固污渍可能无法完全去除';

  @override
  String get svcNotes_mattress => '单人到特大床同价\n完全干燥需4~6小时\n弹簧损坏、塌陷等结构问题无法改善';

  @override
  String get svcNotes_aircon => '使用10年以上的机器可能无法拆洗\n不含室外机清洗\n清洗前后均会检查运行';

  @override
  String get svcNotes_sofa => '皮沙发采用清洁+保养涂层\n陈旧污渍、染色可能无法完全去除\n完全干燥需4~6小时';

  @override
  String get unitTitle_bathroom => '卫生间数量';

  @override
  String get unitTitle_mattress => '床垫数量';

  @override
  String get unitTitle_aircon => '空调类型';

  @override
  String get unitTitle_sofa => '沙发尺寸';

  @override
  String unit_count(String n) {
    return '$n个';
  }

  @override
  String get unit_wall => '壁挂式1台';

  @override
  String get unit_stand => '立式1台';

  @override
  String get unit_two_in_one => '一拖二（立式+壁挂）';

  @override
  String get unit_ceiling => '天花板式1台';

  @override
  String get unit_seat_1_2 => '1~2人座';

  @override
  String get unit_seat_3 => '3人座';

  @override
  String get unit_seat_4_plus => '4人座以上';

  @override
  String get unit_l_shape => 'L型/贵妃';

  @override
  String durH(String h) {
    return '$h小时';
  }

  @override
  String durHM(String h, String m) {
    return '$h小时$m分';
  }

  @override
  String durM(String m) {
    return '$m分钟';
  }

  @override
  String about(String value) {
    return '约$value';
  }

  @override
  String fromPrice(String price) {
    return '$price起';
  }

  @override
  String get quoteBadge => '报价';

  @override
  String get status0 => '咨询中';

  @override
  String get status1 => '已确认';

  @override
  String get status2 => '已派团队';

  @override
  String get status3 => '已完成';

  @override
  String get statusCancelled => '已取消';

  @override
  String homeGreeting(String name) {
    return '$name，\n今天想打扫哪里？';
  }

  @override
  String get homeGreetingAnon => '今天想\n打扫哪里？';

  @override
  String get homeUpcoming => '即将到来';

  @override
  String dDay(String days) {
    return '还有$days天';
  }

  @override
  String get homeServices => '需要哪种清洁？';

  @override
  String get homeAddAddress => '添加地址即可查看可用服务';

  @override
  String get homeAddAddressCta => '添加地址';

  @override
  String homeRebook(String service) {
    return '再次预约$service';
  }

  @override
  String get homeRebookBody => '沿用上次的选项，快速预约';

  @override
  String get homeNotices => '最新消息';

  @override
  String get trustVat => '含税价格，\n无隐藏费用';

  @override
  String get trustCancel => '上门前2天\n免费取消';

  @override
  String get trustCard => '银行卡信息\n仅由支付机构保存';

  @override
  String stepOf(String current, String total) {
    return '$current/$total';
  }

  @override
  String get chooseDate => '选择日期';

  @override
  String get notIncluded => '注意事项';

  @override
  String studioBlockedTitle(String size) {
    return '$size坪不适用单间清洁';
  }

  @override
  String get studioBlockedBody => '客服将为您推荐合适的服务。';

  @override
  String get consultCta => '咨询客服';

  @override
  String get addressTitle => '上门地址？';

  @override
  String get addressAdd => '添加新地址';

  @override
  String get addressLabel => '名称';

  @override
  String get addressLabelHint => '例如：我家';

  @override
  String get addressDistrict => '区';

  @override
  String get addressRoad => '道路地址';

  @override
  String get addressDetail => '详细地址';

  @override
  String get addressSize => '面积（坪）';

  @override
  String get addressSizeHelp => '按套内面积 · 1坪≈3.3㎡';

  @override
  String get addressHome => '住宅';

  @override
  String get addressOffice => '办公室';

  @override
  String get addressEmpty => '暂无保存的地址';

  @override
  String get addressSaved => '地址已保存';

  @override
  String pyeong(String n) {
    return '$n坪';
  }

  @override
  String get scheduleTitle => '何时上门？';

  @override
  String get scheduleArrival => '到达时间';

  @override
  String get scheduleFull => '已满';

  @override
  String scheduleWindow(String start, String end) {
    return '$start–$end到达';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '约需$duration · $time左右结束';
  }

  @override
  String get scheduleRange => '可预约明天起60天内';

  @override
  String get morning => '上午';

  @override
  String get afternoon => '下午';

  @override
  String get scheduleQuoteNote => '具体到达时间将在咨询中告知';

  @override
  String get goToPayment => '去付款';

  @override
  String get prepTitle => '请提前准备';

  @override
  String get prepBody => '未准备可能影响部分服务';

  @override
  String get prepAsk => '无法准备请提前告知客服';

  @override
  String get tool_vacuum => '吸尘器';

  @override
  String get tool_trash => '垃圾袋';

  @override
  String get tool_mop => '拖把';

  @override
  String get tool_cloth => '抹布';

  @override
  String get tool_gloves => '橡胶手套';

  @override
  String get tool_sponge => '百洁布';

  @override
  String get tool_spray => '多用途清洁剂';

  @override
  String get checkoutTitle => '付款';

  @override
  String get coupon => '优惠券';

  @override
  String get couponNone => '不使用';

  @override
  String couponAvailable(String count) {
    return '可用$count张';
  }

  @override
  String get paymentMethod => '付款方式';

  @override
  String get addPaymentMethod => '添加付款方式';

  @override
  String get methodCard => '信用卡/借记卡';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => '已添加';

  @override
  String get methodAdded => '付款方式已添加';

  @override
  String get listPrice => '服务金额';

  @override
  String get discount => '优惠券抵扣';

  @override
  String get total => '应付金额';

  @override
  String get vatIncluded => '含增值税';

  @override
  String payAmount(String amount) {
    return '支付$amount';
  }

  @override
  String get needMethod => '请先添加付款方式';

  @override
  String freeCancelUntil(String date) {
    return '$date前可免费取消';
  }

  @override
  String get doneTitle => '预约成功';

  @override
  String get doneBody => '派单后会立即通知您';

  @override
  String get doneQuoteTitle => '已收到咨询请求';

  @override
  String get doneQuoteBody => '客服确认后会发送最终报价，可在咨询页查看。';

  @override
  String get goHome => '返回首页';

  @override
  String get viewBooking => '查看预约';

  @override
  String get bookingsTitle => '预约';

  @override
  String get bookingsUpcoming => '即将到来';

  @override
  String get bookingsPast => '历史预约';

  @override
  String get bookingsEmpty => '暂无预约';

  @override
  String get bookingsEmptyBody => '首单可用优惠券已备好';

  @override
  String get bookNow => '预约清洁';

  @override
  String get detailTitle => '预约详情';

  @override
  String get stepRequested => '已受理';

  @override
  String get stepConfirmed => '已确认';

  @override
  String get stepAssigned => '已派团队';

  @override
  String get stepCompleted => '已完成';

  @override
  String teamVisiting(String team) {
    return '$team将上门';
  }

  @override
  String get photosSoon => '完成后将在此展示前后对比照';

  @override
  String get before => '清洁前';

  @override
  String get after => '清洁后';

  @override
  String get prepCheck => '准备清单';

  @override
  String get prepAllSet => '全部就绪';

  @override
  String get visitAddress => '上门地址';

  @override
  String get paid => '已付';

  @override
  String get askTeam => '联系客服';

  @override
  String get cancelBooking => '取消预约';

  @override
  String get cancelTitle => '确定取消预约吗？';

  @override
  String get cancelFree => '将全额退款并退回优惠券。';

  @override
  String get cancelKeep => '保留预约';

  @override
  String get cancelled => '预约已取消';

  @override
  String get reschedule => '改期';

  @override
  String get rescheduled => '已改期';

  @override
  String get visitNotes => '上门备注';

  @override
  String get notesEntry => '进门方式（门禁密码等）';

  @override
  String get notesParking => '停车';

  @override
  String get notesOther => '其他';

  @override
  String get notesSaved => '备注已保存';

  @override
  String depositDue(String amount) {
    return '支付定金$amount即可确认';
  }

  @override
  String get payDeposit => '支付定金';

  @override
  String get waitingQuote => '客服正在准备报价';

  @override
  String get estimate => '预估金额';

  @override
  String get finalPrice => '最终报价';

  @override
  String get deposit => '定金';

  @override
  String get balance => '尾款';

  @override
  String balanceDue(String amount) {
    return '请支付尾款$amount';
  }

  @override
  String get payBalance => '支付尾款';

  @override
  String get reviewTitle => '清洁效果如何？';

  @override
  String get reviewHint => '说说满意或不足之处';

  @override
  String get reviewSubmit => '提交评价';

  @override
  String get reviewThanks => '感谢您的评价';

  @override
  String get bookAgain => '按原条件再次预约';

  @override
  String get chatTitle => '咨询';

  @override
  String get chatTeam => '客服团队';

  @override
  String get chatHours => '工作日 09:00–18:00';

  @override
  String get chatEmpty => '有疑问随时咨询';

  @override
  String get chatNew => '新咨询';

  @override
  String get chatTopicTitle => '咨询什么？';

  @override
  String get topicOther => '其他问题';

  @override
  String get chatHint => '输入消息';

  @override
  String get chatSend => '发送';

  @override
  String get chatPhoto => '发送图片';

  @override
  String get chatTyping => '客服正在输入';

  @override
  String get quick_confirm => '确认预约';

  @override
  String get quick_price => '关于价格';

  @override
  String get quick_date => '想改日期';

  @override
  String get quick_parking => '可以停车吗？';

  @override
  String get quick_hello => '你好';

  @override
  String get quick_duration => '需要多久？';

  @override
  String get quoteArrived => '最终报价已送达';

  @override
  String get quoteDepositNow => '现在支付定金10%';

  @override
  String get quoteBalanceLater => '完工后付尾款';

  @override
  String get quotePay => '支付定金并确认';

  @override
  String get quotePaid => '已支付';

  @override
  String get requestCard => '报价请求';

  @override
  String get sys_consultation_received => '已受理您的咨询';

  @override
  String sys_deposit_paid(String amount) {
    return '定金$amount已支付，预约已确认。';
  }

  @override
  String get sys_booking_cancelled => '预约已取消';

  @override
  String sys_status_changed(String status) {
    return '预约状态已变为“$status”';
  }

  @override
  String get sys_job_completed => '清洁已完成，快去看看前后对比照。';

  @override
  String sys_rescheduled(String date) {
    return '已改期至$date';
  }

  @override
  String get sys_reschedule_declined => '服务者无法按新时间上门，客服将重新协调。';

  @override
  String get moreTitle => '更多';

  @override
  String get moreScope => '服务范围';

  @override
  String get morePayments => '付款方式';

  @override
  String get moreCoupons => '优惠券';

  @override
  String get morePoints => '积分';

  @override
  String get moreAccount => '账户信息';

  @override
  String get moreAddresses => '地址管理';

  @override
  String get moreNotices => '公告';

  @override
  String get moreTips => '清洁小贴士';

  @override
  String get moreFaq => '常见问题';

  @override
  String get morePartner => '合作咨询';

  @override
  String get moreLanguage => '语言';

  @override
  String get langSystem => '跟随系统';

  @override
  String moreVersion(String v) {
    return '版本 $v';
  }

  @override
  String get morePrivacy => '隐私政策';

  @override
  String get moreTerms => '服务条款';

  @override
  String get moreLicenses => '开源许可';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '注销账户';

  @override
  String get deleteAccountBody => '个人信息将被删除且无法恢复。请先取消进行中的预约。';

  @override
  String get couponsEmpty => '暂无优惠券';

  @override
  String couponUntil(String date) {
    return '$date前有效';
  }

  @override
  String get couponUsed => '已使用';

  @override
  String get couponExpired => '已过期';

  @override
  String get couponAnyService => '全部服务';

  @override
  String get coupon_welcome_studio => '新人：单间';

  @override
  String get coupon_welcome_any => '新人优惠券';

  @override
  String get pointsBalance => '当前积分';

  @override
  String get pointsEmpty => '暂无积分记录';

  @override
  String get accountName => '姓名';

  @override
  String get accountPhone => '手机号';

  @override
  String get accountEmail => '邮箱';

  @override
  String get accountLogin => '登录方式';

  @override
  String get accountLoginPhone => '手机验证';

  @override
  String get methodsEmpty => '暂无付款方式';

  @override
  String get noContent => '暂无内容';

  @override
  String get quoteTypeTitle => '需要哪种清洁？';

  @override
  String get type_standard => '退租清洁';

  @override
  String get type_same_day_move => '搬家当天清洁';

  @override
  String get type_some_luggage_left => '仍有部分物品';

  @override
  String get type_normal_move_in => '普通入住';

  @override
  String get type_after_interior => '装修后';

  @override
  String get type_lived_in_deep_clean => '居住中大扫除';

  @override
  String get luggageTitle => '物品状态？';

  @override
  String get luggage_empty => '空房';

  @override
  String get luggage_partly_unpacked => '部分整理中';

  @override
  String get luggage_fully_lived_in => '正常居住';

  @override
  String get luggage_unknown => '不确定';

  @override
  String get quoteBasicTitle => '请告诉我们房屋信息';

  @override
  String get buildingType => '建筑类型';

  @override
  String get building_apartment => '公寓';

  @override
  String get building_villa => '多层住宅';

  @override
  String get building_officetel => '商住两用';

  @override
  String get building_house => '独栋住宅';

  @override
  String get building_other => '其他';

  @override
  String get layoutTitle => '户型';

  @override
  String get layout_studio => '单间';

  @override
  String get layout_one_and_half => '1.5室';

  @override
  String get layout_two_rooms => '2室';

  @override
  String get layout_three_rooms => '3室';

  @override
  String get layout_four_plus => '4室以上';

  @override
  String get duplexTitle => '是复式吗？';

  @override
  String get quoteSpaceTitle => '空间信息';

  @override
  String get bathroomsLabel => '卫生间';

  @override
  String get balconiesLabel => '阳台/多用途间';

  @override
  String get elevatorTitle => '有电梯吗？';

  @override
  String get floor3Label => '3楼及以上';

  @override
  String get quoteEstimateTitle => '这是您的预估报价';

  @override
  String get quoteEstimateBody => '客服确认照片等情况后确定最终价格';

  @override
  String get quoteG1 => '最终价格在咨询中确定';

  @override
  String get quoteG2 => '付10%定金确认，尾款完工后付';

  @override
  String get quoteG3 => '确认前可随时免费取消';

  @override
  String get quoteConfirmTitle => '请确认请求内容';

  @override
  String get quoteRequest => '提交咨询';

  @override
  String get quoteNoPayNow => '现在无需付款';

  @override
  String get summaryType => '类型';

  @override
  String get summaryHome => '房屋';

  @override
  String get summaryDate => '上门时间';
}
