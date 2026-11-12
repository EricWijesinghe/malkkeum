// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class TZh extends T {
  TZh([String locale = 'zh']) : super(locale);

  @override
  String get addressSearch => '搜索地址';

  @override
  String get addressSearchHint => '按道路名、建筑名或地号搜索';

  @override
  String get addressSearchButton => '搜索';

  @override
  String get addressSearchMinChars => '请至少输入 2 个字符';

  @override
  String get addressNoResults => '没有结果，请换个词再试。';

  @override
  String get addressManualEntry => '手动输入';

  @override
  String get cardRegisterTitle => '注册卡片';

  @override
  String get cIntJuso => '地址搜索（道路名地址）';

  @override
  String get aiLabel => 'AI 助手';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint => '自动回复客户聊天。每条消息都会产生 API 费用。';

  @override
  String get aiModeOffline => '仅在无人值班时回答';

  @override
  String get aiModeAlways => '始终由 AI 先回答';

  @override
  String get aiPause => '暂停 AI';

  @override
  String get aiResume => '恢复 AI';

  @override
  String get aiPausedNote => '此对话已暂停 AI';

  @override
  String aiUsageMonth(String count) {
    return '本月 AI 调用 $count 次';
  }

  @override
  String get aiNotConfigured => 'AI 客服未开启';

  @override
  String get aiCapThreadLabel => '每个对话每小时回复上限';

  @override
  String get aiCapMemberLabel => '每位客户每天回复上限';

  @override
  String get aiCapDailyLabel => '每天所有对话回复上限';

  @override
  String get aiCapHint => '仅输入数字。留空则使用默认值。';

  @override
  String get apSocialOr => '或';

  @override
  String get apSocialSignIn => '快捷登录';

  @override
  String get apLoginKakao => '使用 Kakao 继续';

  @override
  String get apLoginNaver => '使用 Naver 继续';

  @override
  String get apLoginGoogle => '使用 Google 继续';

  @override
  String get apLoginApple => '使用 Apple 继续';

  @override
  String get apDevSocialNote => '开发模式：将登录测试账号，而非真实社交账号。';

  @override
  String get apSocialFailed => '快捷登录失败，请重试。';

  @override
  String get apProviderNotConfigured => '该登录方式暂未开放';

  @override
  String get apPhoneTaken => '该手机号已绑定其他账号';

  @override
  String get apPhoneAttachTitle => '请验证手机号';

  @override
  String get apPhoneAttachBody => '用于预约和服务人员联系，只需验证一次。';

  @override
  String get apPayAllTitle => '选择付款方式';

  @override
  String get apPaySavedTitle => '已保存的付款方式';

  @override
  String get apPayMoreTitle => '全部付款方式';

  @override
  String get apPayBillingHint => '绑定一次，之后一键支付';

  @override
  String get apPayCheckoutHint => '在支付窗口中完成';

  @override
  String get apPayRegistering => '正在绑定…';

  @override
  String get apPayManageHint => '使用已绑定的付款方式一键支付，可在此添加快捷支付。';

  @override
  String get apMethodCard => '信用卡·借记卡';

  @override
  String get apMethodKakao => 'Kakao Pay';

  @override
  String get apMethodNaver => 'Naver Pay';

  @override
  String get apMethodToss => 'Toss Pay';

  @override
  String get apMethodPayco => 'PAYCO';

  @override
  String get apMethodSamsung => '三星支付';

  @override
  String get apMethodApple => 'Apple Pay';

  @override
  String get apMethodTransfer => '银行转账';

  @override
  String get apMethodVirtual => '虚拟账户';

  @override
  String get apMethodPhone => '手机代扣';

  @override
  String get apMethodUnknown => '其他';

  @override
  String get apVaTitle => '入账账户已生成';

  @override
  String get apVaWaiting => '等待付款';

  @override
  String get apVaBody => '在期限内付款后预约即确认，系统自动核对。';

  @override
  String get apVaBank => '银行';

  @override
  String get apVaAccount => '账号';

  @override
  String get apVaHolder => '户名';

  @override
  String get apVaAmount => '金额';

  @override
  String apVaDue(String due) {
    return '请在$due前付款';
  }

  @override
  String get apVaCopy => '复制';

  @override
  String get apVaCopied => '已复制账号';

  @override
  String get apVaBannerTitle => '有待付款的预约';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · $due前';
  }

  @override
  String get apVaBannerAction => '查看账户';

  @override
  String get apPgTitle => '支付窗口';

  @override
  String get apPgDevNote => '仅限开发环境的模拟支付，不会真实扣款。';

  @override
  String apPgPay(String amount) {
    return '支付 $amount';
  }

  @override
  String get apPgIssue => '获取账号';

  @override
  String get apPgCancel => '取消支付';

  @override
  String get apErrSlotFullRefunded => '该时段刚被订满，付款已自动取消';

  @override
  String get apErrCheckoutExpired => '支付已超时，请重试。';

  @override
  String get apIdentityTitle => '实名认证 (PASS)';

  @override
  String get apIdentityBody => '通过手机运营商实名核验，用于保障交易与结算安全。';

  @override
  String get apIdentityAction => '去实名认证';

  @override
  String get apIdentityDone => '实名认证已完成';

  @override
  String get apIdentityVerified => '已认证';

  @override
  String get apIdentityUnverified => '尚未认证';

  @override
  String get apIdentityDevTitle => '测试实名认证';

  @override
  String get apIdentityDevBody => '开发环境下无需真实认证即可通过。';

  @override
  String get apIdentityDevPass => '通过';

  @override
  String get apPayManageTitle => '快捷支付绑定';

  @override
  String get cTitle => '运营控制台';

  @override
  String get cEmail => '邮箱';

  @override
  String get cPassword => '密码';

  @override
  String get cLogin => '登录';

  @override
  String get cLoginFailed => '邮箱或密码错误';

  @override
  String get cDashboard => '仪表盘';

  @override
  String get cBookings => '预约';

  @override
  String get cQuoteDesk => '报价台';

  @override
  String get cInbox => '咨询箱';

  @override
  String get cCatalog => '目录与价格';

  @override
  String get cMarketing => '优惠券与内容';

  @override
  String get cPartners => '服务者';

  @override
  String get cSettlements => '结算';

  @override
  String get cCustomers => '客户';

  @override
  String get cStaff => '员工';

  @override
  String get cSearchCommand => '搜索或跳转';

  @override
  String get cPaletteHint => '输入菜单名或预约号';

  @override
  String get cTodayJobs => '今日作业';

  @override
  String get cOpenQuotes => '待报价';

  @override
  String get cUnassigned => '未派单';

  @override
  String get cUnreadThreads => '未读咨询';

  @override
  String get cRevenue30 => '30天收入';

  @override
  String get cBookings30 => '30天预约';

  @override
  String get cByService => '按服务预约（30天）';

  @override
  String get cAllStatus => '全部状态';

  @override
  String get cAllServices => '全部服务';

  @override
  String get cSearch => '搜索（编号、电话、姓名、地址）';

  @override
  String get cNoResults => '无结果';

  @override
  String get cNumber => '预约号';

  @override
  String get cVisit => '上门';

  @override
  String get cService => '服务';

  @override
  String get cStatus => '状态';

  @override
  String get cTeam => '团队';

  @override
  String get cAmount => '金额';

  @override
  String get cCustomer => '客户';

  @override
  String get cPayments => '支付';

  @override
  String get cChangeStatus => '更改状态';

  @override
  String get cTeamName => '指派团队';

  @override
  String get cAssign => '指派团队';

  @override
  String get cMarkDone => '标记完成';

  @override
  String get cConfirm => '标记确认';

  @override
  String get cCancelRefund => '取消并退款';

  @override
  String get cRefundAmount => '退款金额（留空为全额）';

  @override
  String get cDone => '已处理';

  @override
  String get cAnswers => '客户回答';

  @override
  String get cEstimateCalc => '自动估算';

  @override
  String get cBase => '基础';

  @override
  String get cExtras => '附加';

  @override
  String get cSurcharge => '加价';

  @override
  String get cBeforeVat => '税前';

  @override
  String get cProQuotes => '服务者报价';

  @override
  String get cNoProQuotes => '暂无服务者报价';

  @override
  String get cFinalPrice => '给客户的最终价';

  @override
  String get cQuoteNote => '给客户的备注';

  @override
  String get cSendQuote => '发送报价给客户';

  @override
  String get cQuoteSent => '报价已发送';

  @override
  String get cCustomerChats => '客户';

  @override
  String get cPartnerChats => '服务者';

  @override
  String get cSelectBooking => '请选择预约';

  @override
  String get cRefunded => '已退款';

  @override
  String get cPartRefunded => '部分退款';

  @override
  String get cFailed => '失败';

  @override
  String get cSelectThread => '请选择会话';

  @override
  String get cReplyHint => '输入回复 · Ctrl+Enter发送';

  @override
  String get cOpenBooking => '打开预约';

  @override
  String get cShortcuts => 'J/K移动 · Ctrl+K命令';

  @override
  String get cPricing => '价格';

  @override
  String get cMinutes => '时长(分)';

  @override
  String get cActive => '上架中';

  @override
  String get cSaved => '已保存';

  @override
  String get cSlotCapacity => '各时段容量';

  @override
  String get cUnlimited => '不限';

  @override
  String get cFormula => '报价公式';

  @override
  String get cTabCancelPolicy => '取消政策';

  @override
  String get cPolicyDefaultBanner => '这是内置默认值，请确认后保存。';

  @override
  String get cPolicyDaysBefore => '访问前几天起（天）';

  @override
  String get cPolicyPercent => '手续费％（留空则不可在应用内取消）';

  @override
  String get cPolicyMinFee => '最低手续费（韩元）';

  @override
  String get cPolicyReschedule => '可改期（访问前几天起）';

  @override
  String get cPolicyHint => '立即作用于客户应用的取消页面，条款在下次构建后更新。';

  @override
  String get f_base_studio => '基础：单间';

  @override
  String get f_base_one_and_half => '基础：1.5室';

  @override
  String get f_base_two_rooms => '基础：2室';

  @override
  String get f_base_three_rooms => '基础：3室';

  @override
  String get f_base_four_plus => '基础：4室以上';

  @override
  String get f_per_extra_bathroom => '每增加卫生间';

  @override
  String get f_per_balcony => '每个阳台';

  @override
  String get f_duplex => '复式';

  @override
  String get f_no_elevator_high_floor => '无电梯且3楼以上';

  @override
  String get cIssueCoupon => '发放优惠券';

  @override
  String get cCouponName => '优惠券名称';

  @override
  String get cCouponPhones => '目标手机号（每行一个）';

  @override
  String get cAllCustomers => '发给全部客户';

  @override
  String cIssued(String n) {
    return '已发放$n张';
  }

  @override
  String get cContent => '内容';

  @override
  String get cKind_notice => '公告';

  @override
  String get cKind_tip => '贴士';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => '横幅';

  @override
  String get cKind_legal => '条款';

  @override
  String get cNewContent => '新内容';

  @override
  String get cTitleField => '标题';

  @override
  String get cBodyField => '正文';

  @override
  String get cSlug => '标识（条款：privacy / terms）';

  @override
  String get cVerify => '批准';

  @override
  String get cSuspend => '暂停';

  @override
  String get cPro_pending => '待审核';

  @override
  String get cPro_verified => '活跃';

  @override
  String get cPro_suspended => '已暂停';

  @override
  String get cCompleted => '完成';

  @override
  String get cCancelledN => '取消';

  @override
  String get cRating => '评分';

  @override
  String get cFeeRate => '费率 %';

  @override
  String get cRunPayouts => '执行结算';

  @override
  String get cPayoutDate => '截止日期';

  @override
  String cPayoutDone(String n) {
    return '已向$n位服务者支付';
  }

  @override
  String get cHold => '暂缓';

  @override
  String get cRelease => '解除暂缓';

  @override
  String get cNet => '实付';

  @override
  String get cAddStaff => '添加员工';

  @override
  String get cRoleAdmin => '管理员';

  @override
  String get cRoleConsultant => '顾问';

  @override
  String get cDeactivate => '停用';

  @override
  String get cActivate => '启用';

  @override
  String get cPasswordRule => '至少12个字符';

  @override
  String get cAdminOnly => '仅管理员可操作';

  @override
  String cBookingsCount(String n) {
    return '预约$n笔';
  }

  @override
  String get cJoined => '注册';

  @override
  String get cNewBooking => '新预约';

  @override
  String get cNewMessage => '新消息';

  @override
  String get cConfirmAsk => '确定要继续吗？';

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
  String get err_cancellation_window_closed => '此时已无法在应用内取消，请联系客服';

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
  String photoThumb(String n) {
    return '照片 $n';
  }

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
  String cancelFeeNow(String fee, String refund) {
    return '现在取消将收取$fee手续费，退款$refund。';
  }

  @override
  String cancelFeeAccept(String fee) {
    return '同意$fee手续费并取消';
  }

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
  String ratingStars(String n) {
    return '$n星';
  }

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

  @override
  String get cpTitle => '取消与变更政策';

  @override
  String cpWhen(String days) {
    return '访问前$days天或更早';
  }

  @override
  String get cpWhenSameDay => '上门当天';

  @override
  String get cpFree => '全额退款';

  @override
  String cpFee(String percent, String fee, String refund) {
    return '手续费$percent%（$fee），退款$refund';
  }

  @override
  String get cpClosed => '应用内不可取消（客服审核）';

  @override
  String get hhTitle => '住户信息';

  @override
  String get hhAddPet => '添加宠物';

  @override
  String get hhPetCount => '数量';

  @override
  String get hhFloorLabel => '楼层（地下为负）';

  @override
  String get hhElevator => '有电梯';

  @override
  String get hhNotes => '备注';

  @override
  String get hhHint => '保存到该地址，每次预约可单独修改。';

  @override
  String get themeTitle => '主题';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeTip => '切换主题';

  @override
  String get err_price_changed => '价格已变动，请查看新报价后重试。';

  @override
  String get err_checkout_closed => '该付款已结束，请重新开始。';

  @override
  String get err_checkout_refunded => '该付款已取消并退款。';

  @override
  String get err_already_paid => '已完成付款。';

  @override
  String get err_quote_not_payable => '该报价暂时无法付款，请联系客服确认。';

  @override
  String get err_payment_method_disabled => '当前无法使用该付款方式。';

  @override
  String get err_invalid_payment_method => '无法使用所选付款方式，请选择其他方式。';

  @override
  String get err_balance_not_due => '尾款尚未到期。';

  @override
  String get err_invalid_slot => '该服务不提供这个时段。';

  @override
  String get err_booking_changed => '预约内容已变更，请刷新后确认。';

  @override
  String get err_booking_closed => '该预约已无法更改。';

  @override
  String get err_reschedule_closed => '现在无法改期，请联系客服。';

  @override
  String get err_too_many_open_requests => '进行中的请求过多，请先处理一个。';

  @override
  String get err_already_reviewed => '您已评价过此次服务。';

  @override
  String get err_identity_not_verified => '请先完成实名认证。';

  @override
  String get err_email_taken => '该邮箱已被使用。';

  @override
  String get err_invalid_email => '请检查邮箱地址。';

  @override
  String get err_file_too_large => '文件太大，请上传更小的文件。';

  @override
  String get err_unsupported_image => '不支持该图片格式，请上传 JPG 或 PNG。';

  @override
  String get err_upload_quota => '今天的上传次数已达上限，请明天再试。';

  @override
  String get err_provider_unreachable => '无法连接服务，请稍后重试。';

  @override
  String get err_invalid_token => '登录信息无效，请重试。';

  @override
  String get err_invalid_transition => '当前无法更改为该状态。';

  @override
  String get err_job_not_started => '请先开始工作。';

  @override
  String get err_job_not_active => '该工作当前不可操作。';

  @override
  String get err_quote_locked => '报价已锁定，无法修改。';

  @override
  String get err_request_closed => '该请求已关闭。';

  @override
  String get err_team_full => '团队人数已满。';

  @override
  String get err_invalid_webhook_secret => 'Webhook 密钥必须以 whsec_ 开头。';

  @override
  String get err_invalid_endpoint => '端点必须以 https:// 开头。';

  @override
  String get err_invalid_bucket => '存储桶名称无效。';

  @override
  String get err_invalid_region => '区域无效。';

  @override
  String get err_invalid_retention => '保留天数超出范围。';

  @override
  String get err_invalid_service_account => '服务账号文件无效。';

  @override
  String get err_invalid_mode => '请重新选择有效的 AI 模式。';

  @override
  String get err_invalid_model => 'AI 模型名称无效。';

  @override
  String get err_missing_field => '请填写所有必填项。';

  @override
  String get err_invalid_amount => '请输入有效金额。';

  @override
  String get err_cannot_deactivate_self => '不能停用自己的账号。';

  @override
  String get err_invalid_coupon => '优惠券无效。';

  @override
  String get err_settlement_state => '当前无法更改结算状态。';

  @override
  String get err_deposit_required => '需先支付定金。';

  @override
  String get err_payout_state => '支付状态已变更，请刷新后重新确认。';

  @override
  String get err_payout_provider => '该支付方式当前不可用。';

  @override
  String get err_unsupported_bank => '不支持向该银行付款。';

  @override
  String get err_toss_unverified => '暂不支持 Toss 代付，请使用手动转账。';

  @override
  String get err_invalid_cap => '请输入允许范围内的数字。';

  @override
  String get err_invalid_capacity => '请输入有效的容量。';

  @override
  String get err_seller_declined => 'Toss 未通过卖家注册，请检查营业信息。';

  @override
  String get err_payout_account_unverified => '该合作伙伴还没有已验证的收款账户，请先验证账户。';

  @override
  String get fFinance => '财务';

  @override
  String get fPeriodDay => '日';

  @override
  String get fPeriodWeek => '周';

  @override
  String get fPeriodMonth => '月';

  @override
  String get fPeriodCustom => '自定义';

  @override
  String get fFrom => '开始';

  @override
  String get fTo => '结束';

  @override
  String get fGross => '总支付额';

  @override
  String get fRefunds => '退款';

  @override
  String get fNetRevenue => '净收入';

  @override
  String get fPlatformFee => '平台手续费';

  @override
  String get fPaidOut => '已支付合作方';

  @override
  String get fPendingOut => '待支付';

  @override
  String get fHeldOut => '暂缓';

  @override
  String get fVatEstimate => '增值税（估算）';

  @override
  String get fVatNote => '按平台手续费的10%估算，请与会计师确认。';

  @override
  String get fAov => '平均订单额';

  @override
  String get fBookings => '预约';

  @override
  String get fCancelRate => '取消率';

  @override
  String get fDiscounts => '折扣与优惠券';

  @override
  String get fMethods => '支付方式';

  @override
  String get fTrend => '趋势';

  @override
  String fRangeDays(String n) {
    return '最近$n天';
  }

  @override
  String get fRangeWeeks => '最近12周';

  @override
  String get fRangeMonths => '最近12个月';

  @override
  String get fByPartner => '按合作方结算';

  @override
  String get fByService => '按服务统计收入';

  @override
  String get fExportTitle => '会计数据导出';

  @override
  String get fExportLedger => '支付台账 CSV';

  @override
  String get fExportSettlements => '结算明细 CSV';

  @override
  String get fExportMonthly => '月度汇总 CSV（会计用）';

  @override
  String get fDownload => '下载 CSV';

  @override
  String get fDownloadWebOnly => 'CSV 下载请在网页控制台进行';

  @override
  String get fDownloadFailed => '下载失败';

  @override
  String get fNoRecords => '此期间没有记录';

  @override
  String get fLoadFailed => '无法加载财务数据';

  @override
  String get fRetry => '重试';

  @override
  String get fColPartner => '合作方';

  @override
  String get fColJobs => '单数';

  @override
  String get fColSettled => '结算总额';

  @override
  String get fColFee => '手续费';

  @override
  String get fColNet => '净额';

  @override
  String get pEarnings => '收入';

  @override
  String get pNextPayout => '下次结算';

  @override
  String pNextPayoutOn(String date) {
    return '$date结算';
  }

  @override
  String get pNoPayout => '暂无结算安排';

  @override
  String get pPendingTotal => '待结算';

  @override
  String get pPaidTotal => '已结算';

  @override
  String get pWeekly => '每周';

  @override
  String get pMonthly => '每月';

  @override
  String proofHomes(String count) {
    return '本月已清洁 $count 户';
  }

  @override
  String proofRating(String rating, String count) {
    return '平均 $rating 分 · $count 条评价';
  }

  @override
  String get proofReviewsTitle => '最近评价';

  @override
  String get rebookTitle => '要再次预约上次的服务吗？';

  @override
  String rebookBody(String service, String date) {
    return '$service · 上次 $date';
  }

  @override
  String get rebookButton => '再次预约';

  @override
  String seatsLeft(String count) {
    return '剩余$count个名额';
  }

  @override
  String get reviewSheetTitle => '这次清洁怎么样？';

  @override
  String get reviewPhotosAdd => '添加照片';

  @override
  String get reviewPhotosHint => '最多可上传 5 张照片';

  @override
  String get reviewSaved => '感谢您的评价';

  @override
  String get reviewPhotoFailed => '照片上传失败，请重试';

  @override
  String get referralTitle => '邀请好友，各得优惠券';

  @override
  String referralBody(String amount) {
    return '好友完成首单后，你们各得 $amount 优惠券';
  }

  @override
  String get referralCopy => '复制代码';

  @override
  String get referralCopied => '推荐码已复制';

  @override
  String get referralClaimTitle => '有推荐码吗？';

  @override
  String get referralClaimField => '输入推荐码';

  @override
  String get referralClaimButton => '提交';

  @override
  String get referralClaimed => '推荐码已提交';

  @override
  String referralStats(String invited, String rewarded) {
    return '已邀请 $invited 人 · 已发放 $rewarded 次';
  }

  @override
  String get err_self_referral => '不能使用自己的推荐码';

  @override
  String get err_referee_already_booked => '首单之后无法填写推荐码';

  @override
  String get err_already_referred => '已经填写过推荐码';

  @override
  String get err_invalid_referral_code => '请检查推荐码';

  @override
  String get err_referral_disabled => '目前暂不接受好友推荐';

  @override
  String get err_invalid_photos => '只能附加通过平台上传的照片';

  @override
  String get welcomeOfferTitle => '首单优惠';

  @override
  String get welcomeOfferBody => '新客户首单自动适用，不与优惠券叠加。';

  @override
  String get offerKindAmount => '固定金额（韩元）';

  @override
  String get offerKindPercent => '百分比（%）';

  @override
  String get offerValue => '优惠值';

  @override
  String get offerEnabled => '启用';

  @override
  String get offerSaved => '已保存';

  @override
  String get referralSettingsTitle => '好友推荐奖励';

  @override
  String get referralSettingsBody => '好友首单完成并付款后发放。禁止自我推荐和重复手机号。';

  @override
  String get referralRewardAmount => '奖励金额（韩元）';

  @override
  String get reviewsModerationTitle => '评价管理';

  @override
  String get reviewHide => '隐藏';

  @override
  String get reviewShow => '重新显示';

  @override
  String get reviewHiddenTag => '已隐藏';

  @override
  String get growthAverageRating => '平均评分';

  @override
  String growthReviewCount(String count) {
    return '$count 条评价';
  }

  @override
  String get growthReferralConversion => '推荐转化';

  @override
  String get growthTab => '增长';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded/$invited 人';
  }

  @override
  String get uMaintenanceTitle => '系统维护中';

  @override
  String get uMaintenanceBody => '我们正在维护以提升服务，请稍后再试。';

  @override
  String get cOps => '系统状态';

  @override
  String get oLevelGreen => '正常';

  @override
  String get oLevelYellow => '需关注';

  @override
  String get oLevelRed => '需处理';

  @override
  String get oOverall => '服务器状态';

  @override
  String get oRefresh => '刷新';

  @override
  String get oVersion => '版本';

  @override
  String get oUptime => '运行时间';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours小时$minutes分';
  }

  @override
  String get oChecks => '检查项目';

  @override
  String get oCheckDb => '数据库';

  @override
  String oCheckDbValue(String ms, String mb) {
    return '响应 ${ms}ms・容量 ${mb}MB';
  }

  @override
  String get oCheckDisk => '服务器磁盘';

  @override
  String oCheckDiskValue(String pct) {
    return '剩余 $pct%';
  }

  @override
  String get oCheckBackup => '自动备份';

  @override
  String oCheckBackupValue(String hours) {
    return '上次备份 $hours 小时前';
  }

  @override
  String get oCheckBackupNone => '没有备份记录';

  @override
  String get oCheckErrors => '服务器错误（24小时）';

  @override
  String oCheckErrorsValue(String count) {
    return '$count次';
  }

  @override
  String get oCheckPayments => '待核对的支付';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count笔（24小时）';
  }

  @override
  String get oCheckWebhook => '支付通知（Webhook）';

  @override
  String oCheckWebhookValue(String count) {
    return '签名失败 $count次（24小时）';
  }

  @override
  String get oIntegrations => '外部服务';

  @override
  String get oIntNotSet => '未设置';

  @override
  String oIntLastOk(String at) {
    return '上次成功 $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return '上次失败 $at（$code）';
  }

  @override
  String get oIntNever => '暂无使用记录';

  @override
  String get oActDb => '无法连接数据库。在服务器运行 malkkeum logs 查看原因，持续出现请重启服务器。';

  @override
  String get oActDisk => '磁盘剩余不足10%。请删除旧备份文件或扩大磁盘。';

  @override
  String get oActBackup =>
      '自动备份已过期。请在服务器运行 malkkeum backup，并查看 backups/backup.log。';

  @override
  String get oActErrors => '服务器错误较多。请在 malkkeum logs 中查看 error 行，反复出现请反馈给开发方。';

  @override
  String get oActPayments => '部分支付可能已成功但未自动处理。请在 PortOne 后台核对，必要时手动退款。';

  @override
  String get oActWebhook => '支付通知签名校验失败。请在 设置 > 支付（PortOne）中重新输入 Webhook 密钥。';

  @override
  String get oActIntegration => '连接失败。请在设置页面检查密钥并点击 [连接测试]。';

  @override
  String get oActNotSet => '尚未设置。请在设置页面输入密钥。';

  @override
  String get oAlerts => '提醒设置';

  @override
  String get oAlertsHint => '出现问题时会通知咨询箱，并短信发送到店主手机。同一问题每6小时只发一次。';

  @override
  String get oRuleSms => '短信发送失败';

  @override
  String get oRulePush => '推送失败';

  @override
  String get oRulePayment => '支付连接失败';

  @override
  String get oRuleStuck => '支付未自动处理';

  @override
  String get oRuleSocial => '社交登录失败';

  @override
  String get oRuleBackup => '自动备份缺失';

  @override
  String get oRuleDisk => '磁盘不足';

  @override
  String get oQuietHours => '勿扰时段';

  @override
  String get oQuietFrom => '开始';

  @override
  String get oQuietTo => '结束';

  @override
  String oHour(String hour) {
    return '$hour点';
  }

  @override
  String get oQuietHint => '这段时间不发送提醒，结束后发送一次。';

  @override
  String get oAlertPhone => '接收提醒的手机';

  @override
  String get oAlertPhoneHint => '留空则发送到商家信息中的客服号码。';

  @override
  String get oSave => '保存';

  @override
  String get oSaved => '提醒设置已保存';

  @override
  String get oSaveFailed => '保存失败，请检查输入内容。';

  @override
  String get oLoadFailed => '无法加载状态';

  @override
  String get oBackupOffsite => '异地备份（S3）';

  @override
  String get oBackupOffsiteOff => '未开启。可在 设置 > 异地备份 中开启。';

  @override
  String get oLastBackup => '上次备份';

  @override
  String get oDiskFree => '剩余空间';

  @override
  String get oNoData => '暂无数据';

  @override
  String get cIntBackup => '异地备份（S3 兼容）';

  @override
  String get pTabJobs => '接单';

  @override
  String get pTabQuotes => '我的报价';

  @override
  String get pTabSchedule => '日程';

  @override
  String get pIntroTitle => '为清洁专家打造\n接单 · 日程 · 结算';

  @override
  String get pIntroBody => '只在想要的区域和时间工作，每周结算';

  @override
  String get pOnbTitle => '填写服务者信息';

  @override
  String get pOnbName => '负责人姓名';

  @override
  String get pOnbTeam => '团队名称';

  @override
  String get pOnbServices => '可提供的服务';

  @override
  String get pOnbAreas => '服务区域';

  @override
  String get pOnbDone => '提交申请';

  @override
  String get pPendingTitle => '正在审核中';

  @override
  String get pPendingBody => '审核通过后会通知您，请先登记结算账户。';

  @override
  String get pSuspended => '账户已暂停，请联系运营团队。';

  @override
  String get pDirect => '直接订单';

  @override
  String get pQuoteReq => '报价请求';

  @override
  String get pShowClosed => '显示已结束';

  @override
  String get pSortNewest => '最新';

  @override
  String get pSortVisit => '上门最近';

  @override
  String get pSortAmount => '金额最高';

  @override
  String get pNoJobs => '暂无匹配的订单';

  @override
  String get pNoJobsBody => '扩大服务、区域或时间可看到更多';

  @override
  String get pPayout => '预计结算';

  @override
  String get pCustomerEstimate => '客户预估';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => '已结束';

  @override
  String get pPrivacyNote => '接单后显示详细地址和客户信息';

  @override
  String get pAccept => '接单';

  @override
  String get pAcceptConfirm => '确认接单吗？';

  @override
  String get pAcceptBody => '将加入日程并通知客户。上门前2天内取消受限。';

  @override
  String get pAccepted => '接单成功';

  @override
  String get pSendQuote => '提交报价';

  @override
  String get pQuotePrice => '客户支付金额';

  @override
  String get pQuoteNote => '给客服的备注';

  @override
  String get pQuoteSent => '报价已提交';

  @override
  String pFee(String rate) {
    return '手续费$rate%';
  }

  @override
  String get pYouGet => '实收金额';

  @override
  String get pQuoteAll => '全部';

  @override
  String get pQ_waiting => '等待中';

  @override
  String get pQ_selected => '已选中';

  @override
  String get pQ_rejected => '未选中';

  @override
  String get pQ_closed => '已结束';

  @override
  String get pUnseenOnly => '仅看新结果';

  @override
  String get pNoQuotes => '暂无报价';

  @override
  String get pMyQuote => '我的报价';

  @override
  String get pWithdraw => '撤回报价';

  @override
  String get pWithdrawn => '报价已撤回';

  @override
  String get pOnlyMine => '只看我的';

  @override
  String pJobsCount(String n) {
    return '$n单';
  }

  @override
  String get pNoSchedule => '当天没有日程';

  @override
  String get pCancelledBanner => '该订单已取消，无法完成。';

  @override
  String pRescheduleBanner(String from, String to) {
    return '改期请求：$from → $to';
  }

  @override
  String get pRescheduleOk => '可以';

  @override
  String get pRescheduleNo => '无法前往';

  @override
  String get pCustomer => '客户';

  @override
  String get pCall => '隐私号码拨打';

  @override
  String get pCallSoon => '隐私号码将在上线时开通';

  @override
  String get pQuietHours => '20点后请勿致电';

  @override
  String get pAssignee => '负责人';

  @override
  String get pChangeAssignee => '更换负责人';

  @override
  String get pCustomerRequests => '客户要求';

  @override
  String get pHousehold => '住户信息';

  @override
  String get pPets => '宠物';

  @override
  String get pPetDog => '狗';

  @override
  String get pPetCat => '猫';

  @override
  String get pPetBird => '鸟';

  @override
  String get pPetFish => '鱼';

  @override
  String get pPetOther => '其他宠物';

  @override
  String get pAllergies => '过敏与注意';

  @override
  String get pPreferredProducts => '偏好产品';

  @override
  String get pParking => '停车';

  @override
  String pFloor(String floor) {
    return '$floor层';
  }

  @override
  String get pElevatorYes => '有电梯';

  @override
  String get pElevatorNo => '无电梯';

  @override
  String get pTeamMemo => '团队备注（客户不可见）';

  @override
  String get pMemoSaved => '备注已保存';

  @override
  String get pPayoutBreakdown => '结算明细';

  @override
  String get pAfterBalance => '客户付清尾款后结算';

  @override
  String get pChatOps => '联系运营';

  @override
  String get pComplete => '完成检查';

  @override
  String get pBeforePhotos => '清洁前照片';

  @override
  String get pAfterPhotos => '清洁后照片';

  @override
  String get pAddPhoto => '添加照片';

  @override
  String get pChecklist => '检查项';

  @override
  String get pCheck1 => '已清洁所有指定区域';

  @override
  String get pCheck2 => '已处理垃圾并收回工具';

  @override
  String get pCheck3 => '已检查门窗水电';

  @override
  String get pCheck4 => '已满足客户要求';

  @override
  String get pCompleteCta => '确认完成';

  @override
  String get pCompleteNeed => '前后各需至少1张照片并勾选全部';

  @override
  String get pCompleted => '辛苦了！';

  @override
  String pPayoutOn(String date, String amount) {
    return '$date结算$amount';
  }

  @override
  String get pPayoutWaiting => '客户付款后确定结算日';

  @override
  String get pPendingPayout => '待结算金额';

  @override
  String get pSettlements => '结算记录';

  @override
  String get pS_waiting_balance => '等待尾款';

  @override
  String get pS_pending => '待结算';

  @override
  String get pS_paid => '已支付';

  @override
  String get pS_held => '暂缓';

  @override
  String get pReviews => '客户评价';

  @override
  String get pNoReviews => '暂无评价';

  @override
  String get pReplyLater => '回复功能即将上线';

  @override
  String get pServicesAreas => '服务与区域';

  @override
  String get pPayoutAccount => '结算账户';

  @override
  String get pBank => '银行';

  @override
  String get pAccountNumber => '账号';

  @override
  String get pHolder => '户名';

  @override
  String get pVerified => '已验证';

  @override
  String get pUnverified => '验证中';

  @override
  String get pAccountSaved => '已保存，修改后需重新验证。';

  @override
  String get pWorkSchedule => '工作时间';

  @override
  String get pWeekdays => '工作日';

  @override
  String get pDayParts => '工作时段';

  @override
  String get pDaysOff => '休息日';

  @override
  String get pAddDayOff => '添加休息日';

  @override
  String get pSaved => '已保存';

  @override
  String get pTeam => '团队成员';

  @override
  String get pOwner => '负责人';

  @override
  String get pInvited => '已邀请';

  @override
  String get pInvite => '邀请成员';

  @override
  String get pInviteSent => '邀请短信已发送';

  @override
  String get pRemove => '移除';

  @override
  String get pNotifications => '通知设置';

  @override
  String get pNotifyDirect => '新直接订单';

  @override
  String get pNotifyQuotes => '报价请求与结果';

  @override
  String get pNotifyChat => '运营消息';

  @override
  String get pQuietNight => '夜间免打扰（22–8点）';

  @override
  String get pNewInquiry => '新咨询';

  @override
  String get pTopic_settlement => '结算';

  @override
  String get pTopic_reschedule => '改期/取消';

  @override
  String get pTopic_app => '应用帮助';

  @override
  String get pOpsTeam => '运营团队';

  @override
  String get pViewJob => '查看订单';

  @override
  String pBookingNo(String n) {
    return '预约号 $n';
  }

  @override
  String get pSize => '面积';

  @override
  String get pSchedule => '日程';

  @override
  String get pSpace => '空间信息';

  @override
  String get pNavigate => '导航';

  @override
  String get pNavHint => '在地图应用中打开上门地址，未安装应用则打开网页地图。';

  @override
  String get pOfflineSaved => '没有信号。已保存，恢复网络后自动发送。';

  @override
  String get pPhotoRetry => '重新上传';

  @override
  String get pPhotoWaiting => '未上传的照片将在恢复网络后自动上传。';

  @override
  String pUploadedCount(String total, String done) {
    return '已上传 $done/$total 张';
  }

  @override
  String get apPgPickMethod => '请选择支付方式';

  @override
  String get apPgConfirmTitle => '确认支付内容';

  @override
  String get apPgConfirmBtn => '确认付款';

  @override
  String get apPgProcessing => '正在处理付款…';

  @override
  String get apPgDoneTitle => '付款完成';

  @override
  String get apPgReceiptTitle => '电子收据';

  @override
  String get apPgReceiptApproval => '批准编号';

  @override
  String get apPgReceiptMethod => '支付方式';

  @override
  String get apPgReceiptAmount => '金额';

  @override
  String get apPgReceiptDone => '完成';

  @override
  String get apPgVaIssued => '已发放虚拟账户（测试账户）';

  @override
  String get apPgTestBadge => '测试';

  @override
  String get cIntPayout => '合作伙伴付款';

  @override
  String get poTabSettlements => '结算';

  @override
  String get poTabPayouts => '支付记录';

  @override
  String get poState_requested => '已请求';

  @override
  String get poState_sent => '已发送';

  @override
  String get poState_paid => '已支付';

  @override
  String get poState_failed => '失败';

  @override
  String get poProviderManual => '手动转账';

  @override
  String get poProviderToss => 'Toss 代付';

  @override
  String get poShowAccount => '查看账户';

  @override
  String get poAccountTitle => '转账信息';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return '请向 $holder · $bank · $account 转账 $amount 韩元，然后点击确认。';
  }

  @override
  String get poConfirmPaid => '标记为已转账';

  @override
  String get poMarkFailed => '标记为失败';

  @override
  String get poReasonTitle => '失败原因';

  @override
  String get poReasonHint => '例如：账户错误、转账取消';

  @override
  String get poSend => '通过 Toss 发送';

  @override
  String get poSync => '查询状态';

  @override
  String get poRetry => '重试';

  @override
  String get poNoPayouts => '暂无支付记录';

  @override
  String poRequestedToast(String n) {
    return '已创建 $n 笔支付请求';
  }

  @override
  String get poReasonRequired => '请输入原因';

  @override
  String get poRevealNote => '查看账户信息会被记录';

  @override
  String get poSellerAction => '注册卖家';

  @override
  String get poSellerTitle => '注册为 Toss 卖家';

  @override
  String get poSellerHint => '将使用该合作伙伴已验证的收款账户注册，只需填写营业信息。';

  @override
  String get poSellerIndividual => '个人';

  @override
  String get poSellerCompany => '企业';

  @override
  String get poSellerName => '姓名';

  @override
  String get poSellerRepresentative => '代表人姓名';

  @override
  String get poSellerRegNo => '营业执照号（10位）';

  @override
  String get poSellerEmail => '结算邮箱';

  @override
  String get poSellerPhone => '电话';

  @override
  String get poSellerSubmit => '注册';

  @override
  String poSellerDone(String status) {
    return '卖家状态：$status';
  }

  @override
  String get pvManage => '同意管理';

  @override
  String get pvOptional => '可选';

  @override
  String get pvTerms => '同意服务条款';

  @override
  String get pvPrivacy => '同意收集和使用个人信息';

  @override
  String get pvOverseas => '同意个人信息跨境传输';

  @override
  String get pvMarketing => '同意接收营销信息';

  @override
  String get pvMarketingHint => '通过短信、KakaoTalk 和应用推送接收优惠券与活动消息。可随时关闭。';

  @override
  String get pvLocation => '同意使用位置信息';

  @override
  String get pvReconsent => '隐私政策已更新，请重新查看并同意。';

  @override
  String get pvSaved => '同意设置已保存';

  @override
  String get pvExport => '下载我的数据';

  @override
  String get pvExportHint => '以 JSON 格式显示我们保存的您的全部信息，可复制保存。';

  @override
  String get pvCopy => '复制';

  @override
  String get pvCopied => '已复制';

  @override
  String get pvExportFailed => '无法加载您的数据，请稍后再试。';

  @override
  String get safetyEmergency => '紧急联系方式';

  @override
  String get emergencyPolice => '112 警察';

  @override
  String get emergencyFire => '119 消防·急救';

  @override
  String get emergencyShop => '客服中心';

  @override
  String get caseReportAction => '报告问题';

  @override
  String get caseReportTitle => '发生了什么问题？';

  @override
  String get caseKindDamage => '损坏';

  @override
  String get caseKindLoss => '遗失';

  @override
  String get caseKindComplaint => '投诉';

  @override
  String get caseKindNoShow => '清洁人员未到场';

  @override
  String get caseKindSafety => '安全问题';

  @override
  String get caseKindPayment => '支付异议';

  @override
  String get caseSummaryHint => '请详细描述（300字以内）';

  @override
  String get caseSubmit => '提交';

  @override
  String get caseSubmitted => '已接收，工作人员将在24小时内确认。';

  @override
  String get caseFailed => '提交失败，请重试。';

  @override
  String get checkInAction => '到达签到';

  @override
  String get checkOutAction => '离场签退';

  @override
  String checkedInAt(String time) {
    return '$time 到达';
  }

  @override
  String checkedOutAt(String time) {
    return '$time 离场';
  }

  @override
  String get entryCodeAction => '查看门禁密码';

  @override
  String get entryCodeTitle => '门禁密码';

  @override
  String get entryCodeNotToday => '仅在上门当天可查看';

  @override
  String get entryCodeEmpty => '没有登记的门禁密码';

  @override
  String get actionFailed => '处理失败，请重试。';

  @override
  String get consoleCasesTitle => '案件队列';

  @override
  String get consoleCasesEmpty => '没有待处理案件';

  @override
  String get caseOverdue => '已超期';

  @override
  String get caseStatusOpen => '待处理';

  @override
  String get caseStatusInvestigating => '调查中';

  @override
  String get caseStatusResolved => '已解决';

  @override
  String get caseStatusRejected => '已驳回';

  @override
  String get caseReassign => '重新分配清洁人员';

  @override
  String get caseRefund => '退款';

  @override
  String get caseHold => '暂停结算';

  @override
  String get caseNoteHint => '内部备注';

  @override
  String get caseSave => '保存';

  @override
  String get cSetup => '设置';

  @override
  String get cSetupTitle => '准备上线';

  @override
  String cSetupProgress(String done, String total) {
    return '已完成 $done/$total';
  }

  @override
  String get cSetupAllDone => '一切就绪！';

  @override
  String get cSetupBusiness => '商家信息';

  @override
  String get cSetupBusinessName => '服务名称';

  @override
  String get cSetupSupportPhone => '客服电话';

  @override
  String get cSetupSupportEmail => '客服邮箱';

  @override
  String get cSetupSupportHours => '客服时间';

  @override
  String get cSetupColor => '品牌色';

  @override
  String get cSetupLogo => '上传标志';

  @override
  String get cSetupCompany => '公司信息（显示在应用和网站底部）';

  @override
  String get cSetupLegalName => '公司名称';

  @override
  String get cSetupCeo => '法定代表人';

  @override
  String get cSetupRegNo => '营业执照号';

  @override
  String get cSetupMailOrderNo => '电商备案号';

  @override
  String get cSetupAddress => '公司地址';

  @override
  String get cSetupPrivacyOfficer => '个人信息负责人';

  @override
  String get cSetupStoreLinks => '应用商店链接（填写后网站按钮生效）';

  @override
  String get cSetupCustomerApp => '客户应用';

  @override
  String get cSetupPartnerApp => '服务者应用';

  @override
  String get cSetupPayMethods => '支付方式';

  @override
  String get cSetupPayMethodsHint => '开启或关闭客户可见的支付方式，立即生效。';

  @override
  String get cReviewTitle => '应用审核演示账号';

  @override
  String get cReviewHint => '审核人员无法接收韩国短信。请把号码和6位验证码写进审核备注，到期自动关闭。';

  @override
  String get cReviewPhone => '演示电话号码';

  @override
  String get cReviewCode => '固定验证码（6位数字）';

  @override
  String cReviewActiveUntil(String date) {
    return '有效期至 $date';
  }

  @override
  String get cReviewEnable => '开启（14天）';

  @override
  String get pDeleteAccountBody => '团队和个人信息将被删除且无法恢复。请先完成已分配的作业和待结算款项。';

  @override
  String get err_has_active_jobs => '您还有已分配的作业，请完成或联系客服转派。';

  @override
  String get err_pending_payouts => '仍有待结算款项，付款完成后可注销。';

  @override
  String get err_phone_required => '接单前请先验证手机号。';

  @override
  String get nAlerts => '通知';

  @override
  String get nEmpty => '暂无通知';

  @override
  String nUnread(String count) {
    return '$count 条未读通知';
  }

  @override
  String get pVerifyPhone => '验证手机号';

  @override
  String get mMyJobs => '我的作业';

  @override
  String get mNoJobs => '暂无分配的作业，组长分配后会显示在这里。';

  @override
  String mTeam(String team) {
    return '$team 成员';
  }

  @override
  String get cSetupSave => '保存';

  @override
  String get cSetupSaved => '已保存';

  @override
  String get cSetupTest => '测试连接';

  @override
  String get cSetupClear => '断开连接';

  @override
  String get cSetupConnected => '已连接';

  @override
  String get cSetupNotConnected => '未连接';

  @override
  String get cSetupFromEnv => '使用服务器设置';

  @override
  String get cSetupCheckInApp => '已保存 · 请在应用中登录确认';

  @override
  String get cSetupInvalidKey => '密钥无效，请检查复制的内容';

  @override
  String get cSetupUnreachable => '无法连接服务，请稍后重试';

  @override
  String get cSetupKeepValue => '已保存（仅在更换时输入）';

  @override
  String get cSetupGuide => '设置步骤';

  @override
  String get cSetupOpenSite => '打开网站';

  @override
  String get cSetupWebhook => 'Webhook 地址（粘贴到 PortOne 控制台）';

  @override
  String get cCopied => '已复制';

  @override
  String get cSetupDevMode => '测试模式：不会产生真实支付或短信';

  @override
  String get cSetupOptional => '可选';

  @override
  String get cIntPortone => '支付（PortOne）';

  @override
  String get cIntSolapi => '短信与通知（Solapi）';

  @override
  String get cIntPush => '应用推送（Firebase）';

  @override
  String get cIntKakao => 'Kakao 登录';

  @override
  String get cIntNaver => 'Naver 登录';

  @override
  String get cIntGoogle => 'Google 登录';

  @override
  String get cIntApple => 'Apple 登录';

  @override
  String get cFirstRunTitle => '欢迎！请创建店主账号';

  @override
  String get cFirstRunBody => '请输入安装时显示的 12 位安装码。此账号可管理所有设置。';

  @override
  String get cFirstRunCode => '安装码';

  @override
  String get cName => '姓名';

  @override
  String get cFirstRunCreate => '创建账号并开始';

  @override
  String get cWrongSetupCode => '安装码不正确';

  @override
  String get cWeakPassword => '密码至少需要 12 个字符';

  @override
  String get cInvalidValue => '请检查输入内容';

  @override
  String get cMfaTitle => '两步验证';

  @override
  String get cMfaCode => '验证器应用中的6位验证码';

  @override
  String get cMfaRecovery => '恢复代码';

  @override
  String get cMfaUseRecovery => '改用恢复代码';

  @override
  String get cMfaUseCode => '改用验证器代码';

  @override
  String get cMfaVerify => '验证';

  @override
  String get cMfaBack => '返回登录';

  @override
  String get cMfaEnrolTitle => '设置两步验证';

  @override
  String get cMfaEnrolBody =>
      '管理员需要使用验证器应用。请在 Google Authenticator、1Password 等应用中添加下方密钥，然后输入其显示的6位验证码。';

  @override
  String get cMfaSecret => '设置密钥';

  @override
  String get cMfaLink => '设置链接（otpauth）';

  @override
  String get cMfaCopy => '复制';

  @override
  String get cMfaCopied => '已复制';

  @override
  String get cMfaConfirm => '确认并开启';

  @override
  String get cMfaCodesTitle => '请保存恢复代码';

  @override
  String get cMfaCodesBody => '如果丢失验证器，每个代码可用于登录一次。这些代码只会显示这一次。';

  @override
  String get cMfaDownload => '下载';

  @override
  String get cMfaSaveFailed => '此设备无法保存文件。请复制代码并妥善保管。';

  @override
  String get cMfaContinue => '进入控制台';

  @override
  String get cMfaInvalid => '验证码不正确。请检查手机时间是否准确后重试。';

  @override
  String get cMfaExpired => '登录已过期，请从密码步骤重新开始。';

  @override
  String get cMfaLocked => '尝试次数过多，请几分钟后再试。';

  @override
  String get cStaffReset => '重置密码';

  @override
  String get cStaffResetConfirm => '重置该员工的密码？其所有设备将被登出。';

  @override
  String get cStaffResetTitle => '重置令牌';

  @override
  String get cStaffResetBody => '请将此令牌交给员工。只能使用一次，有效期30分钟。关闭后将无法再次查看。';

  @override
  String get tTaxSection => '税务';

  @override
  String tVatQuarter(String q) {
    return '第$q季度增值税 CSV';
  }

  @override
  String get tVatYear => '年份';

  @override
  String get tExportWithholding => '代扣代缴明细 CSV';

  @override
  String get tExportTaxInvoices => '税务发票上传 CSV';

  @override
  String get tTaxLayoutNote => '上传前请与홈택스实际模板核对，列结构尚未验证。';

  @override
  String get tCashReceipts => '现金收据';

  @override
  String get tCashIssued => '已开具';

  @override
  String get tCashFailed => '开具失败';

  @override
  String get tCashPending => '待处理';

  @override
  String get tCashCancelled => '已取消';

  @override
  String get tReissue => '重新开具';

  @override
  String get tTaxInvoices => '税务发票';

  @override
  String get tApprovalNumber => '审批号';

  @override
  String get tIssuedOn => '开具日期';

  @override
  String get tMarkIssued => '标记为已开具';

  @override
  String get tQueueEmpty => '暂无待处理请求';

  @override
  String get tWithholdingLabel => '代扣税';

  @override
  String get tGrossAmount => '应付总额';

  @override
  String get tIncomeTax => '所得税';

  @override
  String get tLocalTax => '地方所得税';

  @override
  String get tNetAmount => '实发金额';

  @override
  String get tNoWithholding => '无代扣税（已注册企业）';

  @override
  String get tEstWithholding => '预计代扣税（待结算部分）';

  @override
  String get tReceiptOptions => '收据选项';

  @override
  String get tWantCashReceipt => '开具现金收据';

  @override
  String get tCashForIncome => '用于收入扣除（手机号）';

  @override
  String get tCashForBusiness => '用于费用凭证（营业执照号）';

  @override
  String get tWantTaxInvoice => '开具税务发票（企业）';

  @override
  String get tPhoneForReceipt => '手机号';

  @override
  String get tBusinessNumber => '营业执照号';

  @override
  String get tCompanyName => '公司名称';

  @override
  String get tRepresentative => '法人代表';

  @override
  String get tInvoiceEmail => '接收发票的邮箱';

  @override
  String get tReceiptSave => '保存并支付';

  @override
  String get tReceiptSaveFailed => '无法保存收据信息';

  @override
  String get tTaxType => '税务类型';

  @override
  String get tTaxFreelancer => '自由职业者（代扣）';

  @override
  String get tTaxBusiness => '已注册企业（无代扣）';

  @override
  String get tReceiptSettings => '收据设置';

  @override
  String get reviewRuleLine => '禁止辱骂、个人信息、虚假或广告内容。被举报的评价将被隐藏。';

  @override
  String get reportAction => '举报';

  @override
  String get reportSheetTitle => '要举报这条评价吗？';

  @override
  String get reportReasonSpam => '垃圾或广告';

  @override
  String get reportReasonOffensive => '辱骂或仇恨言论';

  @override
  String get reportReasonPersonal => '包含个人信息';

  @override
  String get reportReasonOther => '其他';

  @override
  String get reportNoteHint => '详细说明（可选，300字以内）';

  @override
  String get reportSubmit => '提交举报';

  @override
  String get reportThanks => '感谢举报，运营团队会进行审核。';

  @override
  String get reportAlready => '您已举报过此评价';

  @override
  String get reportFailed => '举报失败，请重试。';

  @override
  String get reviewBlocked => '此账户已被限制发表评价，请联系客服。';

  @override
  String get modTitle => '评价举报管理';

  @override
  String get modEmpty => '没有待处理的举报';

  @override
  String modReports(String count) {
    return '$count 条举报';
  }

  @override
  String get modKeep => '保留';

  @override
  String get modHide => '隐藏';

  @override
  String get modDelete => '删除';

  @override
  String get modBlockAuthor => '限制作者发表';

  @override
  String get modUnblockAuthor => '解除限制';

  @override
  String get modDone => '已处理';

  @override
  String get modFailed => '处理失败，请重试。';

  @override
  String get modHidden => '已隐藏的评价';

  @override
  String uUpdateBanner(String version) {
    return '新版本 $version 已发布';
  }

  @override
  String get uUpdateNow => '更新';

  @override
  String get uUpdateLater => '稍后';

  @override
  String get uUpdateRequiredTitle => '需要更新';

  @override
  String get uUpdateRequiredBody => '此版本已不再支持，请从应用商店更新到最新版本。';

  @override
  String get uUpdateStore => '前往应用商店更新';

  @override
  String get uUpdateStoreMissing => '更新链接尚未准备好，请稍后再试。';

  @override
  String uCurrentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get uAppVersionTitle => '应用版本管理';

  @override
  String get uAppVersionHint => '低于最低版本的应用会停在更新页面；低于最新版本则显示提示横幅。格式：1.2.0';

  @override
  String get uMinVersion => '最低版本';

  @override
  String get uLatestVersion => '最新版本';

  @override
  String get walletTitle => '积分钱包';

  @override
  String get walletBalance => '可用积分';

  @override
  String walletPoints(String count) {
    return '$count 积分';
  }

  @override
  String walletExpiring(String days, String count) {
    return '$days天内 $count 积分将到期';
  }

  @override
  String get walletOff => '积分奖励尚未开放';

  @override
  String get walletEmpty => '暂无积分记录';

  @override
  String get walletHistory => '最近记录';

  @override
  String get walletKindEarn => '预约返现';

  @override
  String get walletKindWelcome => '欢迎积分';

  @override
  String get walletKindReferral => '好友推荐奖励';

  @override
  String get walletKindRefund => '取消后退还的积分';

  @override
  String get walletKindSpend => '用于预约支付';

  @override
  String get walletKindExpire => '到期失效';

  @override
  String get walletKindOther => '积分调整';

  @override
  String get moreWallet => '积分钱包';

  @override
  String get payHistoryTitle => '支付记录';

  @override
  String get payHistoryEmpty => '暂无支付记录';

  @override
  String get payStatusPaid => '已支付';

  @override
  String get payStatusRefunded => '已退款';

  @override
  String get payStatusPending => '等待付款';

  @override
  String get payStatusClosed => '未付款';

  @override
  String get receiptTitle => '电子收据';

  @override
  String get receiptLegal => '商号';

  @override
  String get receiptRegNo => '营业执照号';

  @override
  String get receiptAddr => '地址';

  @override
  String get receiptPhone => '客服';

  @override
  String get receiptDate => '支付日期';

  @override
  String get receiptCopy => '复制收据内容';

  @override
  String get receiptCopied => '收据内容已复制';

  @override
  String get receiptNote => '仅作支付凭证。如需税务发票，请在预约详情中另行申请。';

  @override
  String get webBookNow => '网页直接预约';

  @override
  String get webBookSub => '无需安装应用，直接预约';

  @override
  String get apPgBrowserNote => '请在浏览器中完成付款，然后返回此页面并点击下方按钮。';

  @override
  String get apPgBrowserDone => '我已完成付款';
}
