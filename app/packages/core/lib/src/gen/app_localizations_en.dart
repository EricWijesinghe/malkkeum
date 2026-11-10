// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TEn extends T {
  TEn([String locale = 'en']) : super(locale);

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
}
