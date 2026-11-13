import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  T get t => T.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  String won(int amount) => formatWon(amount, lang);
}

/// Every user-facing label that depends on a server code lives here,
/// so screens never switch on raw strings.
extension Labels on T {
  String error(Object e) {
    if (e is! ApiException) return errorGeneric;
    if (e.isNetwork) return errorNetwork;
    return _codeMessage(e.code) ?? errorGeneric;
  }

  /// Copy for one backend code; null means no dedicated copy. Codes listed in
  /// test/fixtures/backend_error_codes.json as 'localized' must return non-null.
  String? _codeMessage(String code) => switch (code) {
    'invalid_phone' => err_invalid_phone,
    'otp_invalid' => err_otp_invalid,
    'otp_expired' => err_otp_expired,
    'rate_limited' => err_rate_limited,
    'studio_too_large' => err_studio_too_large,
    'date_out_of_range' => err_date_out_of_range,
    'slot_full' => err_slot_full,
    'coupon_expired' => err_coupon_expired,
    'coupon_used' => err_coupon_used,
    'coupon_wrong_service' => err_coupon_wrong_service,
    'points_insufficient' => err_points_insufficient,
    'points_over_cap' => err_points_over_cap,
    'points_cover_total' => err_points_cover_total,
    'payment_failed' => err_payment_failed,
    'payment_method_required' => err_payment_method_required,
    'cancellation_window_closed' => err_cancellation_window_closed,
    'address_required' => err_address_required,
    'already_taken' => err_already_taken,
    'invalid_address' => err_invalid_address,
    'has_active_jobs' => err_has_active_jobs,
    'pending_payouts' => err_pending_payouts,
    'phone_required' => err_phone_required,
    'self_referral' => err_self_referral,
    'referee_already_booked' => err_referee_already_booked,
    'already_referred' => err_already_referred,
    'invalid_referral_code' => err_invalid_referral_code,
    'referral_disabled' => err_referral_disabled,
    'invalid_photos' => err_invalid_photos,
    'price_changed' => err_price_changed,
    'checkout_closed' => err_checkout_closed,
    'checkout_refunded' => err_checkout_refunded,
    'checkout_refund_pending' => err_checkout_refund_pending,
    'payment_not_for_checkout' => err_payment_not_for_checkout,
    'already_paid' => err_already_paid,
    'quote_not_payable' => err_quote_not_payable,
    'payment_method_disabled' => err_payment_method_disabled,
    'invalid_payment_method' => err_invalid_payment_method,
    'balance_not_due' => err_balance_not_due,
    'invalid_slot' => err_invalid_slot,
    'booking_changed' => err_booking_changed,
    'booking_closed' => err_booking_closed,
    'reschedule_closed' => err_reschedule_closed,
    'too_many_open_requests' => err_too_many_open_requests,
    'already_reviewed' => err_already_reviewed,
    'identity_not_verified' => err_identity_not_verified,
    'email_taken' => err_email_taken,
    'invalid_email' => err_invalid_email,
    'file_too_large' => err_file_too_large,
    'unsupported_image' => err_unsupported_image,
    'upload_quota' => err_upload_quota,
    'provider_unreachable' => err_provider_unreachable,
    'invalid_token' => err_invalid_token,
    'invalid_transition' => err_invalid_transition,
    'job_not_started' => err_job_not_started,
    'job_not_active' => err_job_not_active,
    'quote_locked' => err_quote_locked,
    'request_closed' => err_request_closed,
    'team_full' => err_team_full,
    'invalid_webhook_secret' => err_invalid_webhook_secret,
    'invalid_endpoint' => err_invalid_endpoint,
    'invalid_bucket' => err_invalid_bucket,
    'invalid_region' => err_invalid_region,
    'invalid_retention' => err_invalid_retention,
    'invalid_service_account' => err_invalid_service_account,
    'invalid_mode' => err_invalid_mode,
    'invalid_model' => err_invalid_model,
    'missing_field' => err_missing_field,
    'invalid_amount' => err_invalid_amount,
    'cannot_deactivate_self' => err_cannot_deactivate_self,
    'invalid_coupon' => err_invalid_coupon,
    'settlement_state' => err_settlement_state,
    'deposit_required' => err_deposit_required,
    'payout_state' => err_payout_state,
    'payout_provider' => err_payout_provider,
    'unsupported_bank' => err_unsupported_bank,
    'seller_declined' => err_seller_declined,
    'payout_account_unverified' => err_payout_account_unverified,
    'toss_unverified' => err_toss_unverified,
    'invalid_cap' => err_invalid_cap,
    'invalid_capacity' => err_invalid_capacity,
    'owner_exists' => err_owner_exists,
    'second_factor_required' => err_second_factor_required,
    'owner_transfer_self' => err_owner_transfer_self,
    'owner_target_invalid' => err_owner_target_invalid,
    'wrong_password' => err_wrong_password,
    'mfa_not_enabled' => err_mfa_not_enabled,
    'reset_code_invalid' => err_reset_code_invalid,
    'recovery_code_invalid' => err_recovery_code_invalid,
    'totp_reused' => err_totp_reused,
    'totp_invalid' => err_totp_invalid,
    'totp_required' => err_totp_required,
    'owner_cannot_deactivate' => err_owner_cannot_deactivate,
    'sms_failed' => err_sms_failed,
    _ => null,
  };

  String service(String code) => switch (code) {
    'studio' => svc_studio,
    'kitchen' => svc_kitchen,
    'bathroom' => svc_bathroom,
    'mattress' => svc_mattress,
    'aircon' => svc_aircon,
    'sofa' => svc_sofa,
    'move_out' => svc_move_out,
    'move_in' => svc_move_in,
    _ => code,
  };

  String serviceShort(String code) => switch (code) {
    'studio' => svcShort_studio,
    'kitchen' => svcShort_kitchen,
    'bathroom' => svcShort_bathroom,
    'mattress' => svcShort_mattress,
    'aircon' => svcShort_aircon,
    'sofa' => svcShort_sofa,
    'move_out' => svcShort_move_out,
    'move_in' => svcShort_move_in,
    _ => code,
  };

  String serviceDesc(String code) => switch (code) {
    'studio' => svcDesc_studio,
    'kitchen' => svcDesc_kitchen,
    'bathroom' => svcDesc_bathroom,
    'mattress' => svcDesc_mattress,
    'aircon' => svcDesc_aircon,
    'sofa' => svcDesc_sofa,
    'move_out' => svcDesc_move_out,
    'move_in' => svcDesc_move_in,
    _ => '',
  };

  List<String> serviceNotes(String code) => switch (code) {
    'bathroom' => svcNotes_bathroom,
    'mattress' => svcNotes_mattress,
    'aircon' => svcNotes_aircon,
    'sofa' => svcNotes_sofa,
    _ => '',
  }.split('\n').where((l) => l.isNotEmpty).toList();

  String unitTitle(String code) => switch (code) {
    'bathroom' => unitTitle_bathroom,
    'mattress' => unitTitle_mattress,
    'aircon' => unitTitle_aircon,
    _ => unitTitle_sofa,
  };

  String unit(String key) {
    if (key.startsWith('count_')) return unit_count(key.substring(6));
    return switch (key) {
      'wall' => unit_wall,
      'stand' => unit_stand,
      'two_in_one' => unit_two_in_one,
      'ceiling' => unit_ceiling,
      'seat_1_2' => unit_seat_1_2,
      'seat_3' => unit_seat_3,
      'seat_4_plus' => unit_seat_4_plus,
      'l_shape' => unit_l_shape,
      _ => key,
    };
  }

  String status(int s) => switch (s) {
    0 => status0,
    1 => status1,
    2 => status2,
    3 => status3,
    _ => statusCancelled,
  };

  String duration(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return durM('$m');
    return m == 0 ? durH('$h') : durHM('$h', '$m');
  }

  String couponName(String name) => switch (name) {
    'welcome_studio' => coupon_welcome_studio,
    'welcome_any' => coupon_welcome_any,
    _ => name,
  };

  String tool(String key) => switch (key) {
    'vacuum' => tool_vacuum,
    'trash' => tool_trash,
    'mop' => tool_mop,
    'cloth' => tool_cloth,
    'gloves' => tool_gloves,
    'sponge' => tool_sponge,
    _ => tool_spray,
  };

  String system(String code, Map<String, dynamic> params, String lang) =>
      switch (code) {
        'consultation_received' => sys_consultation_received,
        'deposit_paid' => sys_deposit_paid(
          formatWon((params['amount'] as num? ?? 0).toInt(), lang),
        ),
        'booking_cancelled' => sys_booking_cancelled,
        'status_changed' => sys_status_changed(
          status((params['status'] as num? ?? 0).toInt()),
        ),
        'job_completed' => sys_job_completed,
        'rescheduled' => sys_rescheduled(params['visit_date'] as String? ?? ''),
        'reschedule_declined' => sys_reschedule_declined,
        _ => code,
      };
}

const prepTools = [
  'vacuum',
  'trash',
  'mop',
  'cloth',
  'gloves',
  'sponge',
  'spray',
];

/// "오전 9시" / "9 AM" in the user's language.
String hourLabel(int hour, String lang) =>
    DateFormat.j(lang).format(DateTime(2000, 1, 1, hour));

/// Arrival window. ko/ja/zh read hours the way the design writes them:
/// "오전 9시~10시" (the period is not repeated), "오전 11시~오후 12시" across
/// noon; [withPeriod] false drops the period ("8시~9시 도착"). Other languages
/// use 24h "09:00~10:00". [hours] is the window length; 24 wraps to midnight.
String slotRangeLabel(
  int startHour,
  String lang, {
  int hours = 1,
  bool withPeriod = true,
}) {
  DateTime at(int h) => DateTime(2000, 1, 1, h % 24);
  if (!_hourLangs.contains(lang)) {
    final f = DateFormat.Hm(lang);
    return '${f.format(at(startHour))}~${f.format(at(startHour + hours))}';
  }
  final f = DateFormat.j(lang);
  final start = f.format(at(startHour));
  final end = f.format(at(startHour + hours));
  // The period ("오전", "上午") is whatever precedes the first digit.
  String period(String s) => s.substring(0, s.indexOf(RegExp(r'\d')));
  final p1 = period(start), p2 = period(end);
  if (!withPeriod) {
    return '${start.substring(p1.length)}~${end.substring(p2.length)}';
  }
  return p1 == p2 ? '$start~${end.substring(p2.length)}' : '$start~$end';
}

const _hourLangs = {'ko', 'ja', 'zh'};

/// "11월 13일 (금)" / "Fri, Nov 13".
String dateLabel(DateTime d, String lang) => DateFormat.MMMEd(lang).format(d);
String dateTimeLabel(DateTime d, String lang) =>
    '${DateFormat.MMMEd(lang).format(d)} ${DateFormat.j(lang).format(d)}';
String timeLabel(DateTime d, String lang) => DateFormat.jm(lang).format(d);
