// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TEn extends T {
  TEn([String locale = 'en']) : super(locale);

  @override
  String get addressSearch => 'Search address';

  @override
  String get addressSearchHint => 'Road name, building or lot number';

  @override
  String get addressSearchButton => 'Search';

  @override
  String get addressSearchMinChars => 'Enter at least 2 characters';

  @override
  String get addressNoResults => 'No results. Try different words.';

  @override
  String get addressManualEntry => 'Enter manually';

  @override
  String get cardRegisterTitle => 'Register card';

  @override
  String get cIntJuso => 'Address search (juso.go.kr)';

  @override
  String get aiLabel => 'AI assistant';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Answers customer chats automatically. Each message costs API fees.';

  @override
  String get aiModeOffline => 'Answer only when staff are away';

  @override
  String get aiModeAlways => 'AI answers first, always';

  @override
  String get aiPause => 'Pause AI';

  @override
  String get aiResume => 'Resume AI';

  @override
  String get aiPausedNote => 'AI is paused for this chat';

  @override
  String aiUsageMonth(String count) {
    return 'AI calls this month: $count';
  }

  @override
  String get aiNotConfigured => 'AI support is off';

  @override
  String get aiCapThreadLabel => 'Replies per chat per hour';

  @override
  String get aiCapMemberLabel => 'Replies per customer per day';

  @override
  String get aiCapDailyLabel => 'Replies per day, all chats';

  @override
  String get aiCapHint => 'Numbers only. Leave empty for the default.';

  @override
  String get apSocialOr => 'or';

  @override
  String get apSocialSignIn => 'Quick sign-in';

  @override
  String get apLoginKakao => 'Continue with Kakao';

  @override
  String get apLoginNaver => 'Continue with Naver';

  @override
  String get apLoginGoogle => 'Continue with Google';

  @override
  String get apLoginApple => 'Continue with Apple';

  @override
  String get apDevSocialNote =>
      'Dev mode: signs in to a test account, not a real social account.';

  @override
  String get apSocialFailed => 'Quick sign-in failed. Please try again.';

  @override
  String get apProviderNotConfigured =>
      'This sign-in method isn\'t available yet';

  @override
  String get apPhoneTaken => 'This number is already linked to another account';

  @override
  String get apPhoneAttachTitle => 'Verify your mobile number';

  @override
  String get apPhoneAttachBody =>
      'We use this number for bookings and pro contact. One-time check.';

  @override
  String get apPayAllTitle => 'Choose a payment method';

  @override
  String get apPaySavedTitle => 'Saved methods';

  @override
  String get apPayMoreTitle => 'All payment methods';

  @override
  String get apPayBillingHint => 'Save once, then pay in one tap';

  @override
  String get apPayCheckoutHint => 'Finish in the payment window';

  @override
  String get apPayRegistering => 'Registering…';

  @override
  String get apPayManageHint =>
      'Pay in one tap with saved methods. Add quick-pay methods here.';

  @override
  String get apMethodCard => 'Credit & debit card';

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
  String get apMethodUnknown => 'Other';

  @override
  String get apVaTitle => 'Your deposit account is ready';

  @override
  String get apVaWaiting => 'Waiting for your deposit';

  @override
  String get apVaBody =>
      'Your booking is confirmed once the deposit arrives. We check it automatically.';

  @override
  String get apVaBank => 'Bank';

  @override
  String get apVaAccount => 'Account number';

  @override
  String get apVaHolder => 'Account holder';

  @override
  String get apVaAmount => 'Amount';

  @override
  String apVaDue(String due) {
    return 'Deposit by $due';
  }

  @override
  String get apVaCopy => 'Copy';

  @override
  String get apVaCopied => 'Account number copied';

  @override
  String get apVaBannerTitle => 'A booking is waiting for your deposit';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · by $due';
  }

  @override
  String get apVaBannerAction => 'View account';

  @override
  String get apPgTitle => 'Payment window';

  @override
  String get apPgDevNote =>
      'Development-only payment simulation. No real charge happens.';

  @override
  String apPgPay(String amount) {
    return 'Pay $amount';
  }

  @override
  String get apPgIssue => 'Get account number';

  @override
  String get apPgCancel => 'Cancel payment';

  @override
  String get apErrSlotFullRefunded =>
      'That slot just filled up, so your payment was cancelled automatically';

  @override
  String get apErrCheckoutExpired =>
      'The payment window expired. Please try again.';

  @override
  String get apIdentityTitle => 'Identity check (PASS)';

  @override
  String get apIdentityBody =>
      'Confirms you with your phone carrier. Used for safe trading and payouts.';

  @override
  String get apIdentityAction => 'Verify identity';

  @override
  String get apIdentityDone => 'Identity verified';

  @override
  String get apIdentityVerified => 'Verified';

  @override
  String get apIdentityUnverified => 'Not verified yet';

  @override
  String get apIdentityDevTitle => 'Test identity check';

  @override
  String get apIdentityDevBody =>
      'In development, this passes without a real check.';

  @override
  String get apIdentityDevPass => 'Pass';

  @override
  String get apPayManageTitle => 'Register quick-pay';

  @override
  String get cTitle => 'Operations console';

  @override
  String get cEmail => 'Email';

  @override
  String get cPassword => 'Password';

  @override
  String get cLogin => 'Sign in';

  @override
  String get cLoginFailed => 'Wrong email or password';

  @override
  String get cDashboard => 'Dashboard';

  @override
  String get cBookings => 'Bookings';

  @override
  String get cQuoteDesk => 'Quote desk';

  @override
  String get cInbox => 'Inbox';

  @override
  String get cCatalog => 'Catalog & prices';

  @override
  String get cMarketing => 'Coupons & content';

  @override
  String get cPartners => 'Partners';

  @override
  String get cSettlements => 'Settlements';

  @override
  String get cCustomers => 'Customers';

  @override
  String get cStaff => 'Staff';

  @override
  String get cSearchCommand => 'Search or jump';

  @override
  String get cPaletteHint => 'Type a section or booking number';

  @override
  String get cTodayJobs => 'Today\'s jobs';

  @override
  String get cOpenQuotes => 'Open quotes';

  @override
  String get cUnassigned => 'Unassigned';

  @override
  String get cUnreadThreads => 'Unread chats';

  @override
  String get cRevenue30 => '30-day revenue';

  @override
  String get cBookings30 => '30-day bookings';

  @override
  String get cByService => 'Bookings by service (30 days)';

  @override
  String get cAllStatus => 'All statuses';

  @override
  String get cAllServices => 'All services';

  @override
  String get cSearch => 'Search (number, phone, name, address)';

  @override
  String get cNoResults => 'No results';

  @override
  String get cNumber => 'Number';

  @override
  String get cVisit => 'Visit';

  @override
  String get cService => 'Service';

  @override
  String get cStatus => 'Status';

  @override
  String get cTeam => 'Team';

  @override
  String get cAmount => 'Amount';

  @override
  String get cCustomer => 'Customer';

  @override
  String get cPayments => 'Payments';

  @override
  String get cChangeStatus => 'Change status';

  @override
  String get cTeamName => 'Assigned team';

  @override
  String get cAssign => 'Assign team';

  @override
  String get cMarkDone => 'Mark completed';

  @override
  String get cConfirm => 'Mark confirmed';

  @override
  String get cCancelRefund => 'Cancel & refund';

  @override
  String get cRefundAmount => 'Refund amount (empty = full)';

  @override
  String get cDone => 'Done';

  @override
  String get cAnswers => 'Customer answers';

  @override
  String get cEstimateCalc => 'Calculated estimate';

  @override
  String get cBase => 'Base';

  @override
  String get cExtras => 'Extras';

  @override
  String get cSurcharge => 'Surcharge';

  @override
  String get cBeforeVat => 'Before VAT';

  @override
  String get cProQuotes => 'Partner quotes';

  @override
  String get cNoProQuotes => 'No partner quotes yet';

  @override
  String get cFinalPrice => 'Final price to customer';

  @override
  String get cQuoteNote => 'Note to customer';

  @override
  String get cSendQuote => 'Send quote to customer';

  @override
  String get cQuoteSent => 'Quote sent';

  @override
  String get cCustomerChats => 'Customers';

  @override
  String get cPartnerChats => 'Partners';

  @override
  String get cSelectBooking => 'Pick a booking';

  @override
  String get cRefunded => 'Refunded';

  @override
  String get cPartRefunded => 'Partly refunded';

  @override
  String get cFailed => 'Failed';

  @override
  String get cSelectThread => 'Pick a conversation';

  @override
  String get cReplyHint => 'Reply · Ctrl+Enter to send';

  @override
  String get cOpenBooking => 'Open booking';

  @override
  String get cShortcuts => 'J/K move · Ctrl+K command';

  @override
  String get cPricing => 'Pricing';

  @override
  String get cMinutes => 'Minutes';

  @override
  String get cActive => 'Active';

  @override
  String get cSaved => 'Saved';

  @override
  String get cSlotCapacity => 'Capacity per arrival slot';

  @override
  String get cUnlimited => 'Unlimited';

  @override
  String get cFormula => 'Quote formula';

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
  String get f_per_extra_bathroom => 'Per extra bathroom';

  @override
  String get f_per_balcony => 'Per balcony';

  @override
  String get f_duplex => 'Duplex';

  @override
  String get f_no_elevator_high_floor => 'No elevator & floor 3+';

  @override
  String get cIssueCoupon => 'Issue coupons';

  @override
  String get cCouponName => 'Coupon name';

  @override
  String get cCouponPhones => 'Phone numbers (one per line)';

  @override
  String get cAllCustomers => 'To all customers';

  @override
  String cIssued(String n) {
    return 'Issued $n';
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
  String get cNewContent => 'New content';

  @override
  String get cTitleField => 'Title';

  @override
  String get cBodyField => 'Body';

  @override
  String get cSlug => 'Slug (legal: privacy / terms)';

  @override
  String get cVerify => 'Approve';

  @override
  String get cSuspend => 'Suspend';

  @override
  String get cPro_pending => 'Pending';

  @override
  String get cPro_verified => 'Active';

  @override
  String get cPro_suspended => 'Suspended';

  @override
  String get cCompleted => 'Completed';

  @override
  String get cCancelledN => 'Cancelled';

  @override
  String get cRating => 'Rating';

  @override
  String get cFeeRate => 'Fee %';

  @override
  String get cRunPayouts => 'Run payouts';

  @override
  String get cPayoutDate => 'Pay up to date';

  @override
  String cPayoutDone(String n) {
    return 'Paid $n partners';
  }

  @override
  String get cHold => 'Hold';

  @override
  String get cRelease => 'Release';

  @override
  String get cNet => 'Net';

  @override
  String get cAddStaff => 'Add staff';

  @override
  String get cRoleAdmin => 'Admin';

  @override
  String get cRoleConsultant => 'Consultant';

  @override
  String get cDeactivate => 'Deactivate';

  @override
  String get cActivate => 'Activate';

  @override
  String get cPasswordRule => 'At least 12 characters';

  @override
  String get cAdminOnly => 'Admins only';

  @override
  String cBookingsCount(String n) {
    return '$n bookings';
  }

  @override
  String get cJoined => 'Joined';

  @override
  String get cNewBooking => 'New booking';

  @override
  String get cNewMessage => 'New message';

  @override
  String get cConfirmAsk => 'Are you sure?';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get next => 'Next';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get change => 'Change';

  @override
  String get retry => 'Try again';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get required => 'Required';

  @override
  String get viewAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Check your internet connection';

  @override
  String get err_invalid_phone => 'Check your mobile number';

  @override
  String get err_otp_invalid => 'That code is incorrect';

  @override
  String get err_otp_expired => 'The code expired. Request a new one.';

  @override
  String get err_rate_limited => 'Too many attempts. Try again later.';

  @override
  String get err_studio_too_large =>
      'Studio cleaning is for homes up to 10 pyeong';

  @override
  String get err_date_out_of_range =>
      'Pick a date from tomorrow up to 60 days ahead';

  @override
  String get err_slot_full => 'That time just filled up. Pick another.';

  @override
  String get err_coupon_expired => 'This coupon has expired';

  @override
  String get err_coupon_used => 'This coupon was already used';

  @override
  String get err_coupon_wrong_service =>
      'This coupon isn\'t valid for this service';

  @override
  String get err_payment_failed => 'Payment was declined. Try another method.';

  @override
  String get err_payment_method_required => 'Choose a payment method';

  @override
  String get err_cancellation_window_closed =>
      'Within 2 days of the visit, cancel through our team';

  @override
  String get err_address_required => 'Add the visit address';

  @override
  String get err_already_taken => 'Another pro accepted it first';

  @override
  String get err_invalid_address => 'Fill in every address field';

  @override
  String get tabHome => 'Home';

  @override
  String get tabBookings => 'Bookings';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabMore => 'More';

  @override
  String get introTitle => 'Professional cleaning,\nbooked in a minute';

  @override
  String get introBody => 'Upfront prices · Vetted teams · Live progress';

  @override
  String get introStart => 'Continue with phone number';

  @override
  String get loginPhoneTitle => 'What\'s your mobile number?';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginCodeTitle => 'Enter the 6-digit code';

  @override
  String loginCodeSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get loginResend => 'Resend';

  @override
  String get loginVerify => 'Verify';

  @override
  String get loginTerms =>
      'By continuing you agree to the Terms and Privacy Policy';

  @override
  String get profileTitle => 'What should we call you?';

  @override
  String get profileNameHint => 'Name';

  @override
  String get profileDone => 'Get started';

  @override
  String get welcomeToast => '2 welcome coupons are in your wallet';

  @override
  String get svc_studio => 'Studio cleaning';

  @override
  String get svc_kitchen => 'Kitchen cleaning';

  @override
  String get svc_bathroom => 'Bathroom cleaning';

  @override
  String get svc_mattress => 'Mattress cleaning';

  @override
  String get svc_aircon => 'Air conditioner cleaning';

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
  String get svcShort_bathroom => 'Bathroom';

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
      'A 2-hour clean of a studio up to 10 pyeong: one room and one bathroom.';

  @override
  String get svcDesc_kitchen =>
      'Focused kitchen clean: sink, stove, hood exterior and counters.';

  @override
  String get svcDesc_bathroom =>
      'Shelves, taps, basin and toilet inside and out, finished with a dry floor.';

  @override
  String get svcDesc_mattress =>
      'Pro equipment extracts dust, mites and stains, then steam-sanitises.';

  @override
  String get svcDesc_aircon =>
      'Disassembled, then coil, fan and filter pressure-washed and sanitised.';

  @override
  String get svcDesc_sofa =>
      'Fabric-matched cleaner breaks down dirt, then wet extraction lifts it out.';

  @override
  String get svcDesc_move_out =>
      'Before you move out, a pro team brings equipment and cleans the empty home.';

  @override
  String get svcDesc_move_in =>
      'Before you move in, a pro team brings equipment and cleans the new home.';

  @override
  String get svcNotes_bathroom =>
      'Blocked drains or toilets may limit the service\nNo special-chemical, ceiling or vent cleaning\nOld mould and set-in grime may not fully come off';

  @override
  String get svcNotes_mattress =>
      'Same price from single to king\nFully dry in 4–6 hours\nSpring damage or sagging can\'t be fixed';

  @override
  String get svcNotes_aircon =>
      'Units over 10 years old may not be safe to disassemble\nOutdoor unit not included\nWe check it works before and after';

  @override
  String get svcNotes_sofa =>
      'Leather sofas get cleaning plus conditioning\nOld stains or dye transfer may not fully lift\nFully dry in 4–6 hours';

  @override
  String get unitTitle_bathroom => 'Number of bathrooms';

  @override
  String get unitTitle_mattress => 'Number of mattresses';

  @override
  String get unitTitle_aircon => 'Unit type';

  @override
  String get unitTitle_sofa => 'Sofa size';

  @override
  String unit_count(String n) {
    return '$n';
  }

  @override
  String get unit_wall => 'Wall-mounted';

  @override
  String get unit_stand => 'Floor-standing';

  @override
  String get unit_two_in_one => '2-in-1 (stand + wall)';

  @override
  String get unit_ceiling => 'Ceiling cassette';

  @override
  String get unit_seat_1_2 => '1–2 seats';

  @override
  String get unit_seat_3 => '3 seats';

  @override
  String get unit_seat_4_plus => '4+ seats';

  @override
  String get unit_l_shape => 'L-shape / couch';

  @override
  String durH(String h) {
    return '$h h';
  }

  @override
  String durHM(String h, String m) {
    return '$h h $m min';
  }

  @override
  String durM(String m) {
    return '$m min';
  }

  @override
  String about(String value) {
    return 'about $value';
  }

  @override
  String fromPrice(String price) {
    return 'from $price';
  }

  @override
  String get quoteBadge => 'Quote';

  @override
  String get status0 => 'In consultation';

  @override
  String get status1 => 'Confirmed';

  @override
  String get status2 => 'Team assigned';

  @override
  String get status3 => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String homeGreeting(String name) {
    return 'Hi $name,\nwhat shall we clean today?';
  }

  @override
  String get homeGreetingAnon => 'What shall we\nclean today?';

  @override
  String get homeUpcoming => 'Upcoming';

  @override
  String dDay(String days) {
    return 'in $days days';
  }

  @override
  String get homeServices => 'What do you need?';

  @override
  String get homeAddAddress => 'Add your address to see what\'s available';

  @override
  String get homeAddAddressCta => 'Add address';

  @override
  String homeRebook(String service) {
    return 'Book $service again';
  }

  @override
  String get homeRebookBody => 'Same options as last time, two taps';

  @override
  String get homeNotices => 'What\'s new';

  @override
  String get trustVat => 'VAT included,\nno surprises';

  @override
  String get trustCancel => 'Free cancellation\nup to 2 days before';

  @override
  String get trustCard => 'Card details stay\nwith the payment firm';

  @override
  String stepOf(String current, String total) {
    return '$current of $total';
  }

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get notIncluded => 'Good to know';

  @override
  String studioBlockedTitle(String size) {
    return '$size pyeong is too large for studio cleaning';
  }

  @override
  String get studioBlockedBody =>
      'Our team will suggest the right service for your home.';

  @override
  String get consultCta => 'Ask our team';

  @override
  String get addressTitle => 'Where should we go?';

  @override
  String get addressAdd => 'Add a new address';

  @override
  String get addressLabel => 'Label';

  @override
  String get addressLabelHint => 'e.g. Home';

  @override
  String get addressDistrict => 'District';

  @override
  String get addressRoad => 'Street address';

  @override
  String get addressDetail => 'Unit / floor';

  @override
  String get addressSize => 'Home size (pyeong)';

  @override
  String get addressSizeHelp => 'Net floor area · 1 pyeong ≈ 3.3 m²';

  @override
  String get addressHome => 'Home';

  @override
  String get addressOffice => 'Office';

  @override
  String get addressEmpty => 'No saved addresses';

  @override
  String get addressSaved => 'Address saved';

  @override
  String pyeong(String n) {
    return '$n pyeong';
  }

  @override
  String get scheduleTitle => 'When should we come?';

  @override
  String get scheduleArrival => 'Arrival time';

  @override
  String get scheduleFull => 'Full';

  @override
  String scheduleWindow(String start, String end) {
    return 'Arrive $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · done around $time';
  }

  @override
  String get scheduleRange => 'Book from tomorrow up to 60 days ahead';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get scheduleQuoteNote => 'We\'ll confirm the exact time in chat';

  @override
  String get goToPayment => 'Continue to payment';

  @override
  String get prepTitle => 'Please have these ready';

  @override
  String get prepBody => 'Some tasks may be limited without them';

  @override
  String get prepAsk => 'Can\'t prepare these? Let our team know';

  @override
  String get tool_vacuum => 'Vacuum';

  @override
  String get tool_trash => 'Trash bags';

  @override
  String get tool_mop => 'Mop';

  @override
  String get tool_cloth => 'Cloths';

  @override
  String get tool_gloves => 'Rubber gloves';

  @override
  String get tool_sponge => 'Scrubber';

  @override
  String get tool_spray => 'All-purpose cleaner';

  @override
  String get checkoutTitle => 'Payment';

  @override
  String get coupon => 'Coupon';

  @override
  String get couponNone => 'None';

  @override
  String couponAvailable(String count) {
    return '$count available';
  }

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get addPaymentMethod => 'Add a payment method';

  @override
  String get methodCard => 'Credit / debit card';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Added';

  @override
  String get methodAdded => 'Payment method added';

  @override
  String get listPrice => 'Service';

  @override
  String get discount => 'Coupon';

  @override
  String get total => 'Total';

  @override
  String get vatIncluded => 'VAT included';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get needMethod => 'Add a payment method first';

  @override
  String freeCancelUntil(String date) {
    return 'Free cancellation until $date';
  }

  @override
  String get doneTitle => 'You\'re booked!';

  @override
  String get doneBody => 'We\'ll let you know as soon as a team is assigned';

  @override
  String get doneQuoteTitle => 'Request received';

  @override
  String get doneQuoteBody =>
      'Our team will send a final quote. Find it in the Chat tab.';

  @override
  String get goHome => 'Home';

  @override
  String get viewBooking => 'View booking';

  @override
  String get bookingsTitle => 'Bookings';

  @override
  String get bookingsUpcoming => 'Upcoming';

  @override
  String get bookingsPast => 'Past';

  @override
  String get bookingsEmpty => 'No bookings yet';

  @override
  String get bookingsEmptyBody =>
      'Welcome coupons are waiting for your first booking';

  @override
  String get bookNow => 'Book a clean';

  @override
  String get detailTitle => 'Booking';

  @override
  String get stepRequested => 'Requested';

  @override
  String get stepConfirmed => 'Confirmed';

  @override
  String get stepAssigned => 'Team assigned';

  @override
  String get stepCompleted => 'Completed';

  @override
  String teamVisiting(String team) {
    return '$team is coming';
  }

  @override
  String get photosSoon => 'Before & after photos will appear here';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get prepCheck => 'Prep checklist';

  @override
  String get prepAllSet => 'All set';

  @override
  String get visitAddress => 'Address';

  @override
  String get paid => 'Paid';

  @override
  String get askTeam => 'Message our team';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get cancelTitle => 'Cancel this booking?';

  @override
  String get cancelFree => 'You\'ll get a full refund and your coupon back.';

  @override
  String get cancelKeep => 'Keep it';

  @override
  String get cancelled => 'Booking cancelled';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get rescheduled => 'Rescheduled';

  @override
  String get visitNotes => 'Notes for the team';

  @override
  String get notesEntry => 'How to get in (door code etc.)';

  @override
  String get notesParking => 'Parking';

  @override
  String get notesOther => 'Anything else';

  @override
  String get notesSaved => 'Notes saved';

  @override
  String depositDue(String amount) {
    return 'Pay the $amount deposit to confirm';
  }

  @override
  String get payDeposit => 'Pay deposit';

  @override
  String get waitingQuote => 'Our team is preparing your quote';

  @override
  String get estimate => 'Estimate';

  @override
  String get finalPrice => 'Final quote';

  @override
  String get deposit => 'Deposit';

  @override
  String get balance => 'Balance';

  @override
  String balanceDue(String amount) {
    return 'Please pay the $amount balance';
  }

  @override
  String get payBalance => 'Pay balance';

  @override
  String get reviewTitle => 'How did it go?';

  @override
  String get reviewHint => 'Tell us what went well or could be better';

  @override
  String ratingStars(String n) {
    return '$n stars';
  }

  @override
  String get reviewSubmit => 'Submit review';

  @override
  String get reviewThanks => 'Thanks for your review';

  @override
  String get bookAgain => 'Book again';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatTeam => 'Support team';

  @override
  String get chatHours => 'Weekdays 09:00–18:00';

  @override
  String get chatEmpty => 'Questions? Ask us anytime';

  @override
  String get chatNew => 'New chat';

  @override
  String get chatTopicTitle => 'What\'s it about?';

  @override
  String get topicOther => 'Something else';

  @override
  String get chatHint => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatPhoto => 'Send photo';

  @override
  String get chatTyping => 'Team is typing';

  @override
  String get quick_confirm => 'Let\'s confirm';

  @override
  String get quick_price => 'About the price';

  @override
  String get quick_date => 'Change the date';

  @override
  String get quick_parking => 'Is parking available?';

  @override
  String get quick_hello => 'Hello';

  @override
  String get quick_duration => 'How long will it take?';

  @override
  String get quoteArrived => 'Your final quote is here';

  @override
  String get quoteDepositNow => 'Deposit now (10%)';

  @override
  String get quoteBalanceLater => 'Balance after the job';

  @override
  String get quotePay => 'Pay deposit & confirm';

  @override
  String get quotePaid => 'Paid';

  @override
  String get requestCard => 'Quote request';

  @override
  String get sys_consultation_received => 'Your request was received';

  @override
  String sys_deposit_paid(String amount) {
    return 'Deposit of $amount paid. You\'re confirmed.';
  }

  @override
  String get sys_booking_cancelled => 'The booking was cancelled';

  @override
  String sys_status_changed(String status) {
    return 'Status changed to $status';
  }

  @override
  String get sys_job_completed => 'All done! Check the before & after photos.';

  @override
  String sys_rescheduled(String date) {
    return 'Rescheduled to $date';
  }

  @override
  String get sys_reschedule_declined =>
      'The pro can\'t make the new time. Our team will sort it out.';

  @override
  String get moreTitle => 'More';

  @override
  String get moreScope => 'What\'s included';

  @override
  String get morePayments => 'Payment methods';

  @override
  String get moreCoupons => 'Coupons';

  @override
  String get morePoints => 'Points';

  @override
  String get moreAccount => 'Account';

  @override
  String get moreAddresses => 'Addresses';

  @override
  String get moreNotices => 'Notices';

  @override
  String get moreTips => 'Cleaning tips';

  @override
  String get moreFaq => 'FAQ';

  @override
  String get morePartner => 'Partner with us';

  @override
  String get moreLanguage => 'Language';

  @override
  String get langSystem => 'Use device setting';

  @override
  String moreVersion(String v) {
    return 'Version $v';
  }

  @override
  String get morePrivacy => 'Privacy policy';

  @override
  String get moreTerms => 'Terms of service';

  @override
  String get moreLicenses => 'Open-source licenses';

  @override
  String get logout => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your personal data will be erased. This can\'t be undone. Cancel active bookings first.';

  @override
  String get couponsEmpty => 'No coupons yet';

  @override
  String couponUntil(String date) {
    return 'Until $date';
  }

  @override
  String get couponUsed => 'Used';

  @override
  String get couponExpired => 'Expired';

  @override
  String get couponAnyService => 'Any service';

  @override
  String get coupon_welcome_studio => 'Welcome: studio';

  @override
  String get coupon_welcome_any => 'Welcome coupon';

  @override
  String get pointsBalance => 'Your points';

  @override
  String get pointsEmpty => 'No point history';

  @override
  String get accountName => 'Name';

  @override
  String get accountPhone => 'Mobile';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountLogin => 'Sign-in method';

  @override
  String get accountLoginPhone => 'Phone verification';

  @override
  String get methodsEmpty => 'No payment methods';

  @override
  String get noContent => 'Nothing here yet';

  @override
  String get quoteTypeTitle => 'Which kind of clean?';

  @override
  String get type_standard => 'Standard move-out';

  @override
  String get type_same_day_move => 'Same-day move';

  @override
  String get type_some_luggage_left => 'Some items left';

  @override
  String get type_normal_move_in => 'Standard move-in';

  @override
  String get type_after_interior => 'After renovation';

  @override
  String get type_lived_in_deep_clean => 'Lived-in deep clean';

  @override
  String get luggageTitle => 'How full is the home?';

  @override
  String get luggage_empty => 'Empty';

  @override
  String get luggage_partly_unpacked => 'Partly unpacked';

  @override
  String get luggage_fully_lived_in => 'Fully lived-in';

  @override
  String get luggage_unknown => 'Not sure';

  @override
  String get quoteBasicTitle => 'Tell us about the home';

  @override
  String get buildingType => 'Building type';

  @override
  String get building_apartment => 'Apartment';

  @override
  String get building_villa => 'Low-rise';

  @override
  String get building_officetel => 'Officetel';

  @override
  String get building_house => 'House';

  @override
  String get building_other => 'Other';

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
  String get duplexTitle => 'Is it a duplex?';

  @override
  String get quoteSpaceTitle => 'A bit more about the space';

  @override
  String get bathroomsLabel => 'Bathrooms';

  @override
  String get balconiesLabel => 'Balconies / utility';

  @override
  String get elevatorTitle => 'Is there an elevator?';

  @override
  String get floor3Label => 'Floor 3 or higher';

  @override
  String get quoteEstimateTitle => 'Here\'s your estimate';

  @override
  String get quoteEstimateBody =>
      'The final price is set in chat after we see photos';

  @override
  String get quoteG1 => 'Final price agreed with you in chat';

  @override
  String get quoteG2 => '10% deposit to confirm, rest after';

  @override
  String get quoteG3 => 'Free to cancel before you confirm';

  @override
  String get quoteConfirmTitle => 'Check your request';

  @override
  String get quoteRequest => 'Send request';

  @override
  String get quoteNoPayNow => 'Nothing to pay yet';

  @override
  String get summaryType => 'Type';

  @override
  String get summaryHome => 'Home';

  @override
  String get summaryDate => 'Visit';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeTip => 'Change theme';

  @override
  String get err_price_changed =>
      'The price changed. Review the new quote and try again.';

  @override
  String get err_checkout_closed =>
      'This payment is no longer open. Start again.';

  @override
  String get err_checkout_refunded =>
      'This payment was cancelled and refunded.';

  @override
  String get err_already_paid => 'This is already paid.';

  @override
  String get err_quote_not_payable =>
      'This quote can\'t be paid yet. Check with our team.';

  @override
  String get err_payment_method_disabled =>
      'This payment method isn\'t available right now.';

  @override
  String get err_invalid_payment_method =>
      'That payment method can\'t be used. Choose another.';

  @override
  String get err_balance_not_due => 'The balance isn\'t due yet.';

  @override
  String get err_invalid_slot => 'That time isn\'t offered for this service.';

  @override
  String get err_booking_changed =>
      'The booking changed. Refresh and check the details.';

  @override
  String get err_booking_closed => 'This booking can\'t be changed anymore.';

  @override
  String get err_reschedule_closed =>
      'The visit can\'t be rescheduled now. Contact our team.';

  @override
  String get err_too_many_open_requests =>
      'You have too many open requests. Finish one first.';

  @override
  String get err_already_reviewed => 'You already reviewed this visit.';

  @override
  String get err_identity_not_verified => 'Finish identity verification first.';

  @override
  String get err_email_taken => 'This email is already in use.';

  @override
  String get err_invalid_email => 'Check the email address.';

  @override
  String get err_file_too_large =>
      'That file is too large. Upload a smaller one.';

  @override
  String get err_unsupported_image =>
      'This photo format isn\'t supported. Upload a JPG or PNG.';

  @override
  String get err_upload_quota =>
      'Upload limit reached for today. Try again tomorrow.';

  @override
  String get err_provider_unreachable =>
      'Couldn\'t reach the service. Try again shortly.';

  @override
  String get err_invalid_token => 'Sign-in didn\'t go through. Try again.';

  @override
  String get err_invalid_transition =>
      'The status can\'t be changed that way right now.';

  @override
  String get err_job_not_started => 'Start the job first.';

  @override
  String get err_job_not_active => 'This job isn\'t active.';

  @override
  String get err_quote_locked => 'This quote is locked and can\'t be edited.';

  @override
  String get err_request_closed => 'This request is closed.';

  @override
  String get err_team_full => 'Your team is full.';

  @override
  String get err_invalid_webhook_secret =>
      'The webhook secret must start with whsec_.';

  @override
  String get err_invalid_endpoint => 'The endpoint must start with https://.';

  @override
  String get err_invalid_bucket => 'The bucket name isn\'t valid.';

  @override
  String get err_invalid_region => 'The region isn\'t valid.';

  @override
  String get err_invalid_retention => 'The retention period is out of range.';

  @override
  String get err_invalid_service_account =>
      'The service account file isn\'t valid.';

  @override
  String get err_invalid_mode => 'Pick a valid AI mode.';

  @override
  String get err_invalid_model => 'The AI model name isn\'t valid.';

  @override
  String get err_missing_field => 'Fill in every required field.';

  @override
  String get err_invalid_amount => 'Enter a valid amount.';

  @override
  String get err_cannot_deactivate_self =>
      'You can\'t deactivate your own account.';

  @override
  String get err_invalid_coupon => 'This coupon isn\'t valid.';

  @override
  String get err_settlement_state =>
      'The settlement can\'t be changed right now.';

  @override
  String get err_deposit_required => 'The deposit must be paid first.';

  @override
  String get err_payout_state =>
      'The payout status changed. Refresh and check again.';

  @override
  String get err_payout_provider =>
      'This payout method isn\'t available right now.';

  @override
  String get err_unsupported_bank => 'This bank isn\'t supported for payouts.';

  @override
  String get err_toss_unverified =>
      'Toss payouts aren\'t available yet. Use manual transfer.';

  @override
  String get err_invalid_cap => 'Enter a number within the allowed range.';

  @override
  String get err_invalid_capacity => 'Enter a valid capacity.';

  @override
  String get err_seller_declined =>
      'Toss did not approve the seller registration. Check the business details.';

  @override
  String get err_payout_account_unverified =>
      'This partner has no verified payout account yet. Verify the account first.';

  @override
  String get fFinance => 'Finance';

  @override
  String get fPeriodDay => 'Day';

  @override
  String get fPeriodWeek => 'Week';

  @override
  String get fPeriodMonth => 'Month';

  @override
  String get fPeriodCustom => 'Custom';

  @override
  String get fFrom => 'From';

  @override
  String get fTo => 'To';

  @override
  String get fGross => 'Gross bookings';

  @override
  String get fRefunds => 'Refunds';

  @override
  String get fNetRevenue => 'Net revenue';

  @override
  String get fPlatformFee => 'Platform fee';

  @override
  String get fPaidOut => 'Paid to partners';

  @override
  String get fPendingOut => 'Pending payouts';

  @override
  String get fHeldOut => 'On hold';

  @override
  String get fVatEstimate => 'VAT estimate';

  @override
  String get fVatNote =>
      'Estimate: 10% of the platform fee. Confirm with your accountant.';

  @override
  String get fAov => 'Avg order value';

  @override
  String get fBookings => 'Bookings';

  @override
  String get fCancelRate => 'Cancellation rate';

  @override
  String get fDiscounts => 'Discounts & coupons';

  @override
  String get fMethods => 'Payment methods';

  @override
  String get fTrend => 'Trend';

  @override
  String fRangeDays(String n) {
    return 'Last $n days';
  }

  @override
  String get fRangeWeeks => 'Last 12 weeks';

  @override
  String get fRangeMonths => 'Last 12 months';

  @override
  String get fByPartner => 'Earnings by partner';

  @override
  String get fByService => 'Revenue by service';

  @override
  String get fExportTitle => 'Accounting exports';

  @override
  String get fExportLedger => 'Payments ledger CSV';

  @override
  String get fExportSettlements => 'Settlements CSV';

  @override
  String get fExportMonthly => 'Monthly summary CSV (accountant)';

  @override
  String get fDownload => 'Download CSV';

  @override
  String get fDownloadWebOnly => 'CSV download works in the web console';

  @override
  String get fDownloadFailed => 'Download failed';

  @override
  String get fNoRecords => 'No records in this period';

  @override
  String get fLoadFailed => 'Could not load finance data';

  @override
  String get fRetry => 'Try again';

  @override
  String get fColPartner => 'Partner';

  @override
  String get fColJobs => 'Jobs';

  @override
  String get fColSettled => 'Settled';

  @override
  String get fColFee => 'Fee';

  @override
  String get fColNet => 'Net';

  @override
  String get pEarnings => 'Earnings';

  @override
  String get pNextPayout => 'Next payout';

  @override
  String pNextPayoutOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get pNoPayout => 'No payout scheduled';

  @override
  String get pPendingTotal => 'Waiting to pay';

  @override
  String get pPaidTotal => 'Paid out';

  @override
  String get pWeekly => 'Weekly';

  @override
  String get pMonthly => 'Monthly';

  @override
  String proofHomes(String count) {
    return '$count homes cleaned this month';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Average $rating stars · $count reviews';
  }

  @override
  String get proofReviewsTitle => 'Recent reviews';

  @override
  String get rebookTitle => 'Book the last service again?';

  @override
  String rebookBody(String service, String date) {
    return '$service · last visit $date';
  }

  @override
  String get rebookButton => 'Book again';

  @override
  String seatsLeft(String count) {
    return '$count left';
  }

  @override
  String get reviewSheetTitle => 'How was this clean?';

  @override
  String get reviewPhotosAdd => 'Add photos';

  @override
  String get reviewPhotosHint => 'Up to 5 photos';

  @override
  String get reviewSaved => 'Thanks for your review';

  @override
  String get reviewPhotoFailed => 'Couldn\'t upload the photo. Try again.';

  @override
  String get referralTitle => 'Invite a friend, get a coupon';

  @override
  String referralBody(String amount) {
    return 'When your friend completes a first booking, you both get a $amount coupon';
  }

  @override
  String get referralCopy => 'Copy code';

  @override
  String get referralCopied => 'Referral code copied';

  @override
  String get referralClaimTitle => 'Have a referral code?';

  @override
  String get referralClaimField => 'Enter referral code';

  @override
  String get referralClaimButton => 'Apply';

  @override
  String get referralClaimed => 'Referral code applied';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited invited · $rewarded rewarded';
  }

  @override
  String get err_self_referral => 'You can\'t use your own code';

  @override
  String get err_referee_already_booked =>
      'Codes can only be added before your first booking';

  @override
  String get err_already_referred => 'A referral code is already applied';

  @override
  String get err_invalid_referral_code => 'Check the referral code';

  @override
  String get err_referral_disabled => 'Referrals are paused right now';

  @override
  String get err_invalid_photos =>
      'Only photos uploaded through Malkkeum can be attached';

  @override
  String get welcomeOfferTitle => 'First-booking offer';

  @override
  String get welcomeOfferBody =>
      'Applied automatically to a new customer\'s first booking. Not combined with coupons.';

  @override
  String get offerKindAmount => 'Fixed (won)';

  @override
  String get offerKindPercent => 'Percent (%)';

  @override
  String get offerValue => 'Discount value';

  @override
  String get offerEnabled => 'On';

  @override
  String get offerSaved => 'Saved';

  @override
  String get referralSettingsTitle => 'Referral reward';

  @override
  String get referralSettingsBody =>
      'Paid once a friend\'s first booking is completed and paid. Self-referrals and duplicate phones are blocked.';

  @override
  String get referralRewardAmount => 'Reward amount (won)';

  @override
  String get reviewsModerationTitle => 'Review moderation';

  @override
  String get reviewHide => 'Hide';

  @override
  String get reviewShow => 'Show again';

  @override
  String get reviewHiddenTag => 'Hidden';

  @override
  String get growthAverageRating => 'Average rating';

  @override
  String growthReviewCount(String count) {
    return '$count reviews';
  }

  @override
  String get growthReferralConversion => 'Referral conversion';

  @override
  String get growthTab => 'Growth';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded of $invited';
  }

  @override
  String get cOps => 'System status';

  @override
  String get oLevelGreen => 'OK';

  @override
  String get oLevelYellow => 'Check';

  @override
  String get oLevelRed => 'Action needed';

  @override
  String get oOverall => 'Server status';

  @override
  String get oRefresh => 'Refresh';

  @override
  String get oVersion => 'Version';

  @override
  String get oUptime => 'Uptime';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get oChecks => 'Checks';

  @override
  String get oCheckDb => 'Database';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Response $ms ms · size $mb MB';
  }

  @override
  String get oCheckDisk => 'Server disk';

  @override
  String oCheckDiskValue(String pct) {
    return '$pct% free';
  }

  @override
  String get oCheckBackup => 'Automatic backup';

  @override
  String oCheckBackupValue(String hours) {
    return 'Last backup $hours h ago';
  }

  @override
  String get oCheckBackupNone => 'No backup yet';

  @override
  String get oCheckErrors => 'Server errors (24 h)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Payments to check';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 h)';
  }

  @override
  String get oCheckWebhook => 'Payment webhooks';

  @override
  String oCheckWebhookValue(String count) {
    return 'Signature failures $count (24 h)';
  }

  @override
  String get oIntegrations => 'External services';

  @override
  String get oIntNotSet => 'Not set up';

  @override
  String oIntLastOk(String at) {
    return 'Last success $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Last failure $at ($code)';
  }

  @override
  String get oIntNever => 'No traffic yet';

  @override
  String get oActDb =>
      'The database is unreachable. Run malkkeum logs on the server; restart it if this continues.';

  @override
  String get oActDisk =>
      'Less than 10% disk space is free. Delete old backup files or add disk space.';

  @override
  String get oActBackup =>
      'The automatic backup is overdue. Run malkkeum backup on the server and check backups/backup.log.';

  @override
  String get oActErrors =>
      'Many server errors. Check the error lines in malkkeum logs and send them to your developer if they repeat.';

  @override
  String get oActPayments =>
      'A payment may have gone through without being processed. Check it in the PortOne console and refund it yourself if needed.';

  @override
  String get oActWebhook =>
      'Payment webhook signature checks are failing. Re-enter the webhook secret under Setup > Payments (PortOne).';

  @override
  String get oActIntegration =>
      'This connection is failing. Check the keys in Setup and press Test connection.';

  @override
  String get oActNotSet => 'Not set up yet. Enter the keys in Setup.';

  @override
  String get oAlerts => 'Alert settings';

  @override
  String get oAlertsHint =>
      'Problems show in the inbox and are texted to the owner\'s phone. The same problem is sent once every 6 hours.';

  @override
  String get oRuleSms => 'SMS sending fails';

  @override
  String get oRulePush => 'Push notifications fail';

  @override
  String get oRulePayment => 'Payment connection fails';

  @override
  String get oRuleStuck => 'Payment not processed automatically';

  @override
  String get oRuleSocial => 'Social sign-in fails';

  @override
  String get oRuleBackup => 'Automatic backup missed';

  @override
  String get oRuleDisk => 'Disk nearly full';

  @override
  String get oQuietHours => 'Quiet hours';

  @override
  String get oQuietFrom => 'From';

  @override
  String get oQuietTo => 'To';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'No alerts during these hours; you get one message after they end.';

  @override
  String get oAlertPhone => 'Phone for alerts';

  @override
  String get oAlertPhoneHint =>
      'Leave empty to use the support number from business info.';

  @override
  String get oSave => 'Save';

  @override
  String get oSaved => 'Alert settings saved';

  @override
  String get oSaveFailed => 'Could not save. Check the values.';

  @override
  String get oLoadFailed => 'Could not load status';

  @override
  String get oBackupOffsite => 'Offsite backup (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Off. Turn it on under Setup > Offsite backup.';

  @override
  String get oLastBackup => 'Last backup';

  @override
  String get oDiskFree => 'Free space';

  @override
  String get oNoData => 'No data yet';

  @override
  String get cIntBackup => 'Offsite backup (S3-compatible)';

  @override
  String get pTabJobs => 'Jobs';

  @override
  String get pTabQuotes => 'My quotes';

  @override
  String get pTabSchedule => 'Schedule';

  @override
  String get pIntroTitle => 'Jobs, schedule and payouts\nfor cleaning pros';

  @override
  String get pIntroBody =>
      'Work only where and when you want. Get paid weekly.';

  @override
  String get pOnbTitle => 'Tell us about you';

  @override
  String get pOnbName => 'Your name';

  @override
  String get pOnbTeam => 'Team name';

  @override
  String get pOnbServices => 'Services you offer';

  @override
  String get pOnbAreas => 'Where you work';

  @override
  String get pOnbDone => 'Apply';

  @override
  String get pPendingTitle => 'Your account is under review';

  @override
  String get pPendingBody =>
      'We\'ll notify you once approved. Meanwhile, add your payout account.';

  @override
  String get pSuspended => 'Your account is paused. Please contact operations.';

  @override
  String get pDirect => 'Direct';

  @override
  String get pQuoteReq => 'Quote requests';

  @override
  String get pShowClosed => 'Show closed jobs';

  @override
  String get pSortNewest => 'Newest';

  @override
  String get pSortVisit => 'Soonest visit';

  @override
  String get pSortAmount => 'Highest amount';

  @override
  String get pNoJobs => 'No matching jobs right now';

  @override
  String get pNoJobsBody => 'Widen services, areas or hours to see more';

  @override
  String get pPayout => 'Your payout';

  @override
  String get pCustomerEstimate => 'Customer estimate';

  @override
  String get pNew => 'NEW';

  @override
  String get pClosed => 'Closed';

  @override
  String get pPrivacyNote =>
      'Exact address and customer details appear after you accept';

  @override
  String get pAccept => 'Accept job';

  @override
  String get pAcceptConfirm => 'Accept this job?';

  @override
  String get pAcceptBody =>
      'It goes on your schedule and the customer is notified. Cancelling within 2 days of the visit is restricted.';

  @override
  String get pAccepted => 'Job accepted';

  @override
  String get pSendQuote => 'Send quote';

  @override
  String get pQuotePrice => 'Customer price';

  @override
  String get pQuoteNote => 'Note for the team';

  @override
  String get pQuoteSent => 'Quote sent';

  @override
  String pFee(String rate) {
    return '$rate% fee';
  }

  @override
  String get pYouGet => 'You receive';

  @override
  String get pQuoteAll => 'All';

  @override
  String get pQ_waiting => 'Waiting';

  @override
  String get pQ_selected => 'Selected';

  @override
  String get pQ_rejected => 'Not selected';

  @override
  String get pQ_closed => 'Closed';

  @override
  String get pUnseenOnly => 'New results only';

  @override
  String get pNoQuotes => 'No quotes yet';

  @override
  String get pMyQuote => 'My quote';

  @override
  String get pWithdraw => 'Withdraw';

  @override
  String get pWithdrawn => 'Quote withdrawn';

  @override
  String get pOnlyMine => 'Only mine';

  @override
  String pJobsCount(String n) {
    return '$n jobs';
  }

  @override
  String get pNoSchedule => 'Nothing scheduled';

  @override
  String get pCancelledBanner =>
      'This job was cancelled and can\'t be completed.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Reschedule: $from → $to';
  }

  @override
  String get pRescheduleOk => 'I can make it';

  @override
  String get pRescheduleNo => 'Can\'t make it';

  @override
  String get pCustomer => 'Customer';

  @override
  String get pCall => 'Call (masked number)';

  @override
  String get pCallSoon => 'Masked calling activates at launch';

  @override
  String get pQuietHours => 'No calls after 8 pm';

  @override
  String get pAssignee => 'Assignee';

  @override
  String get pChangeAssignee => 'Change assignee';

  @override
  String get pCustomerRequests => 'Customer requests';

  @override
  String get pTeamMemo => 'Team memo (customer can\'t see)';

  @override
  String get pMemoSaved => 'Memo saved';

  @override
  String get pPayoutBreakdown => 'Payout';

  @override
  String get pAfterBalance => 'Paid out after the customer pays the balance';

  @override
  String get pChatOps => 'Chat with operations';

  @override
  String get pComplete => 'Complete job';

  @override
  String get pBeforePhotos => 'Before photos';

  @override
  String get pAfterPhotos => 'After photos';

  @override
  String get pAddPhoto => 'Add photo';

  @override
  String get pChecklist => 'Checklist';

  @override
  String get pCheck1 => 'All requested areas cleaned';

  @override
  String get pCheck2 => 'Trash handled, tools collected';

  @override
  String get pCheck3 => 'Windows, power and water checked';

  @override
  String get pCheck4 => 'Customer requests handled';

  @override
  String get pCompleteCta => 'Mark complete';

  @override
  String get pCompleteNeed => 'Add at least one photo each and tick every item';

  @override
  String get pCompleted => 'Great work!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount will be paid on $date';
  }

  @override
  String get pPayoutWaiting => 'Payout date is set after the customer pays';

  @override
  String get pPendingPayout => 'Pending payout';

  @override
  String get pSettlements => 'Settlements';

  @override
  String get pS_waiting_balance => 'Awaiting balance';

  @override
  String get pS_pending => 'Scheduled';

  @override
  String get pS_paid => 'Paid';

  @override
  String get pS_held => 'On hold';

  @override
  String get pReviews => 'Reviews';

  @override
  String get pNoReviews => 'No reviews yet';

  @override
  String get pReplyLater => 'Replies are coming soon';

  @override
  String get pServicesAreas => 'Services & areas';

  @override
  String get pPayoutAccount => 'Payout account';

  @override
  String get pBank => 'Bank';

  @override
  String get pAccountNumber => 'Account number';

  @override
  String get pHolder => 'Account holder';

  @override
  String get pVerified => 'Verified';

  @override
  String get pUnverified => 'Verifying';

  @override
  String get pAccountSaved => 'Saved. Changes are re-verified.';

  @override
  String get pWorkSchedule => 'Work schedule';

  @override
  String get pWeekdays => 'Working days';

  @override
  String get pDayParts => 'Working hours';

  @override
  String get pDaysOff => 'Days off';

  @override
  String get pAddDayOff => 'Add a day off';

  @override
  String get pSaved => 'Saved';

  @override
  String get pTeam => 'Team';

  @override
  String get pOwner => 'Owner';

  @override
  String get pInvited => 'Invited';

  @override
  String get pInvite => 'Invite member';

  @override
  String get pInviteSent => 'Invitation sent';

  @override
  String get pRemove => 'Remove';

  @override
  String get pNotifications => 'Notifications';

  @override
  String get pNotifyDirect => 'New direct jobs';

  @override
  String get pNotifyQuotes => 'Quote requests & results';

  @override
  String get pNotifyChat => 'Operations messages';

  @override
  String get pQuietNight => 'Quiet at night (22–08)';

  @override
  String get pNewInquiry => 'New inquiry';

  @override
  String get pTopic_settlement => 'Payouts';

  @override
  String get pTopic_reschedule => 'Reschedule / cancel';

  @override
  String get pTopic_app => 'App help';

  @override
  String get pOpsTeam => 'Operations';

  @override
  String get pViewJob => 'View job';

  @override
  String pBookingNo(String n) {
    return 'Booking $n';
  }

  @override
  String get pSize => 'Size';

  @override
  String get pSchedule => 'Schedule';

  @override
  String get pSpace => 'Space';

  @override
  String get cIntPayout => 'Partner payouts';

  @override
  String get poTabSettlements => 'Settlements';

  @override
  String get poTabPayouts => 'Payouts';

  @override
  String get poState_requested => 'Requested';

  @override
  String get poState_sent => 'Sent';

  @override
  String get poState_paid => 'Paid';

  @override
  String get poState_failed => 'Failed';

  @override
  String get poProviderManual => 'Manual transfer';

  @override
  String get poProviderToss => 'Toss payouts';

  @override
  String get poShowAccount => 'Show account';

  @override
  String get poAccountTitle => 'Transfer details';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'Send $amount won to $holder · $bank · $account, then tap confirm.';
  }

  @override
  String get poConfirmPaid => 'Mark as transferred';

  @override
  String get poMarkFailed => 'Mark as failed';

  @override
  String get poReasonTitle => 'Failure reason';

  @override
  String get poReasonHint => 'e.g. wrong account, transfer cancelled';

  @override
  String get poSend => 'Send via Toss';

  @override
  String get poSync => 'Check status';

  @override
  String get poRetry => 'Retry';

  @override
  String get poNoPayouts => 'No payouts yet';

  @override
  String poRequestedToast(String n) {
    return 'Created $n payout requests';
  }

  @override
  String get poReasonRequired => 'Enter a reason';

  @override
  String get poRevealNote => 'Viewing account details is logged';

  @override
  String get poSellerAction => 'Register seller';

  @override
  String get poSellerTitle => 'Register as Toss seller';

  @override
  String get poSellerHint =>
      'Uses the partner\'s verified payout account. Enter business details only.';

  @override
  String get poSellerIndividual => 'Individual';

  @override
  String get poSellerCompany => 'Business';

  @override
  String get poSellerName => 'Name';

  @override
  String get poSellerRepresentative => 'Representative name';

  @override
  String get poSellerRegNo => 'Business registration no. (10 digits)';

  @override
  String get poSellerEmail => 'Settlement email';

  @override
  String get poSellerPhone => 'Phone';

  @override
  String get poSellerSubmit => 'Register';

  @override
  String poSellerDone(String status) {
    return 'Seller status: $status';
  }

  @override
  String get pvManage => 'Consent settings';

  @override
  String get pvOptional => 'Optional';

  @override
  String get pvTerms => 'Terms of service';

  @override
  String get pvPrivacy => 'Personal data collection and use';

  @override
  String get pvOverseas => 'Transfer of personal data abroad';

  @override
  String get pvMarketing => 'Marketing messages';

  @override
  String get pvMarketingHint =>
      'Get coupon and event news by SMS, KakaoTalk and app push. You can turn this off any time.';

  @override
  String get pvReconsent =>
      'Our privacy policy changed. Please review and agree again.';

  @override
  String get pvSaved => 'Consent settings saved';

  @override
  String get pvExport => 'Download my data';

  @override
  String get pvExportHint =>
      'Shows everything we hold about you as JSON. You can copy it and keep it.';

  @override
  String get pvCopy => 'Copy';

  @override
  String get pvCopied => 'Copied';

  @override
  String get pvExportFailed =>
      'Could not load your data. Please try again later.';

  @override
  String get cSetup => 'Setup';

  @override
  String get cSetupTitle => 'Get ready to launch';

  @override
  String cSetupProgress(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get cSetupAllDone => 'Everything is ready!';

  @override
  String get cSetupBusiness => 'Business profile';

  @override
  String get cSetupBusinessName => 'Service name';

  @override
  String get cSetupSupportPhone => 'Support phone';

  @override
  String get cSetupSupportEmail => 'Support email';

  @override
  String get cSetupSupportHours => 'Support hours';

  @override
  String get cSetupColor => 'Brand color';

  @override
  String get cSetupLogo => 'Upload logo';

  @override
  String get cSetupCompany =>
      'Company details (shown in app and website footer)';

  @override
  String get cSetupLegalName => 'Legal name';

  @override
  String get cSetupCeo => 'Representative';

  @override
  String get cSetupRegNo => 'Business registration no.';

  @override
  String get cSetupMailOrderNo => 'Mail-order registration no.';

  @override
  String get cSetupAddress => 'Business address';

  @override
  String get cSetupPrivacyOfficer => 'Privacy officer';

  @override
  String get cSetupStoreLinks =>
      'Store links (the website buttons turn on once filled)';

  @override
  String get cSetupCustomerApp => 'Customer app';

  @override
  String get cSetupPartnerApp => 'Partner app';

  @override
  String get cSetupPayMethods => 'Payment methods';

  @override
  String get cSetupPayMethodsHint =>
      'Turn the methods customers see on or off. Applies instantly.';

  @override
  String get cReviewTitle => 'Store review demo account';

  @override
  String get cReviewHint =>
      'Reviewers can\'t receive Korean SMS. Put this number and 6-digit code in the review notes. It switches off automatically.';

  @override
  String get cReviewPhone => 'Demo phone number';

  @override
  String get cReviewCode => 'Fixed sign-in code (6 digits)';

  @override
  String cReviewActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String get cReviewEnable => 'Turn on (14 days)';

  @override
  String get pDeleteAccountBody =>
      'Your team and personal data will be erased. This can\'t be undone. Finish assigned jobs and pending payouts first.';

  @override
  String get err_has_active_jobs =>
      'You still have assigned jobs. Finish them or ask support to reassign.';

  @override
  String get err_pending_payouts =>
      'A payout is still pending. You can delete the account after it is paid.';

  @override
  String get err_phone_required =>
      'Verify your phone number before taking jobs.';

  @override
  String get nAlerts => 'Alerts';

  @override
  String get nEmpty => 'No alerts yet';

  @override
  String nUnread(String count) {
    return '$count unread alerts';
  }

  @override
  String get pVerifyPhone => 'Verify';

  @override
  String get mMyJobs => 'My jobs';

  @override
  String get mNoJobs =>
      'No jobs assigned yet. Jobs your team lead assigns show up here.';

  @override
  String mTeam(String team) {
    return 'Member of $team';
  }

  @override
  String get cSetupSave => 'Save';

  @override
  String get cSetupSaved => 'Saved';

  @override
  String get cSetupTest => 'Test connection';

  @override
  String get cSetupClear => 'Disconnect';

  @override
  String get cSetupConnected => 'Connected';

  @override
  String get cSetupNotConnected => 'Not connected';

  @override
  String get cSetupFromEnv => 'Using server settings';

  @override
  String get cSetupCheckInApp => 'Saved · confirm by signing in from the app';

  @override
  String get cSetupInvalidKey =>
      'The key was rejected. Check the value you copied';

  @override
  String get cSetupUnreachable =>
      'Could not reach the service. Try again shortly';

  @override
  String get cSetupKeepValue => 'Saved (type only to replace)';

  @override
  String get cSetupGuide => 'How to set up';

  @override
  String get cSetupOpenSite => 'Open site';

  @override
  String get cSetupWebhook => 'Webhook URL (paste into the PortOne console)';

  @override
  String get cCopied => 'Copied';

  @override
  String get cSetupDevMode =>
      'Test mode: no real payments or messages are sent';

  @override
  String get cSetupOptional => 'Optional';

  @override
  String get cIntPortone => 'Payments (PortOne)';

  @override
  String get cIntSolapi => 'SMS & KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'App push (Firebase)';

  @override
  String get cIntKakao => 'Kakao login';

  @override
  String get cIntNaver => 'Naver login';

  @override
  String get cIntGoogle => 'Google login';

  @override
  String get cIntApple => 'Apple login';

  @override
  String get cFirstRunTitle => 'Welcome! Create the owner account';

  @override
  String get cFirstRunBody =>
      'Enter the 12-character setup code shown during installation. This account manages every setting.';

  @override
  String get cFirstRunCode => 'Setup code';

  @override
  String get cName => 'Name';

  @override
  String get cFirstRunCreate => 'Create account and start';

  @override
  String get cWrongSetupCode => 'That setup code is not right';

  @override
  String get cWeakPassword => 'Password needs at least 12 characters';

  @override
  String get cInvalidValue => 'Please check the highlighted value';

  @override
  String get reviewRuleLine =>
      'No insults, personal information, fake or promotional content. Reported reviews are hidden.';

  @override
  String get reportAction => 'Report';

  @override
  String get reportSheetTitle => 'Report this review?';

  @override
  String get reportReasonSpam => 'Spam or ads';

  @override
  String get reportReasonOffensive => 'Insults or hate';

  @override
  String get reportReasonPersonal => 'Personal information';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNoteHint => 'Details (optional, up to 300 characters)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportThanks => 'Thanks. Our team will review it.';

  @override
  String get reportAlready => 'You already reported this review';

  @override
  String get reportFailed => 'Couldn\'t send the report. Try again.';

  @override
  String get reviewBlocked =>
      'Reviews are disabled for this account. Contact support.';

  @override
  String get modTitle => 'Review reports';

  @override
  String get modEmpty => 'No reports waiting';

  @override
  String modReports(String count) {
    return '$count reports';
  }

  @override
  String get modKeep => 'Keep';

  @override
  String get modHide => 'Hide';

  @override
  String get modDelete => 'Delete';

  @override
  String get modBlockAuthor => 'Restrict author';

  @override
  String get modUnblockAuthor => 'Lift restriction';

  @override
  String get modDone => 'Done';

  @override
  String get modFailed => 'Couldn\'t apply that. Try again.';

  @override
  String get modHidden => 'Hidden review';

  @override
  String uUpdateBanner(String version) {
    return 'Version $version is available';
  }

  @override
  String get uUpdateNow => 'Update';

  @override
  String get uUpdateLater => 'Later';

  @override
  String get uUpdateRequiredTitle => 'An update is required';

  @override
  String get uUpdateRequiredBody =>
      'This version is no longer supported. Please update from the store.';

  @override
  String get uUpdateStore => 'Update in the store';

  @override
  String get uUpdateStoreMissing =>
      'The update link is not ready yet. Please try again later.';

  @override
  String uCurrentVersion(String version) {
    return 'Current version $version';
  }

  @override
  String get uAppVersionTitle => 'App versions';

  @override
  String get uAppVersionHint =>
      'Apps below the minimum stop on an update screen. Apps below the latest version see a banner. Format: 1.2.0';

  @override
  String get uMinVersion => 'Minimum version';

  @override
  String get uLatestVersion => 'Latest version';

  @override
  String get webBookNow => 'Book on the web';

  @override
  String get webBookSub => 'Book without installing the app';

  @override
  String get apPgBrowserNote =>
      'Complete the payment in your browser, then come back here and tap the button below.';

  @override
  String get apPgBrowserDone => 'I finished paying';
}
