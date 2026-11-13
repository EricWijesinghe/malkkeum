import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'action_keys.dart';
import 'api.dart';
import 'checkout.dart';
import 'models.dart';
import 'payment_launcher.dart';

/// Outcome of create -> launch -> confirm. Every branch is explicit; nothing is thrown to the UI.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Paid: the booking exists and is confirmed. [booking] is null when the payment went through but
/// loading the booking afterwards failed; open it by [bookingId].
final class CheckoutPaid extends CheckoutResult {
  const CheckoutPaid(this.bookingId, [this.booking]);
  final String bookingId;
  final Booking? booking;
}

/// Virtual account issued: the customer must deposit before the booking is confirmed.
final class CheckoutAwaitingDeposit extends CheckoutResult {
  const CheckoutAwaitingDeposit(this.account);
  final VirtualAccount account;
}

/// The customer closed the PG window. Nothing was charged.
final class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

/// The PG approved, but the server's answer to confirm never arrived. The money may be taken:
/// never offer Pay again; keep asking the server ([CheckoutService.confirm]) until it answers.
final class CheckoutPending extends CheckoutResult {
  const CheckoutPending(this.checkoutId, this.paymentId);
  final String checkoutId;
  final String paymentId;
}

/// Failed at create, launch or confirm. `code` is a server code, or 'paid_slot_full' when the
/// payment was authorized but the slot filled first (the server cancels it).
final class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed(this.code);
  final String code;
}

/// The approved payment whose confirm is still unanswered, kept across restarts so the app
/// resumes asking the server. Tied to the account that paid: another sign-in never sees it.
/// Storage failures never block a payment.
class PendingPayment {
  PendingPayment({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'pay.pending';

  Future<void> save(CheckoutPending p, {required String? user}) async {
    if (user == null) return;
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'checkout': p.checkoutId,
          'payment': p.paymentId,
          'user': user,
        }),
      );
    } on Exception {
      // Kept in memory only: the server's reconciler still settles the payment.
    }
  }

  /// The saved payment if [user] made it; null for anyone else (or an entry saved before accounts were kept).
  Future<CheckoutPending?> load({required String? user}) async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || user == null) return null;
      final j = jsonDecode(raw) as Json;
      if (j['user'] != user) return null;
      return CheckoutPending(j['checkout'] as String, j['payment'] as String);
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Exception {
      // Nothing to resume next time is the worst case.
    }
  }
}

class CheckoutService {
  CheckoutService({
    required this.api,
    required this.launcher,
    PendingPayment? pending,
    this.confirmBackoff = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  }) : pending = pending ?? PendingPayment();

  final ApiClient api;
  final PaymentLauncher launcher;
  final PendingPayment pending;

  /// Waits between confirm attempts after a lost reply; one retry per entry.
  final List<Duration> confirmBackoff;

  /// [request] is the POST /v1/checkouts body: {kind, booking | booking_id, method}.
  /// [beforePay] runs once the checkout exists and before the PG window: it may save receipt requests.
  /// It returns an error code to stop the payment, or null to continue.
  Future<CheckoutResult> run(
    BuildContext context,
    Json request, {
    Future<String?> Function(CheckoutIntent intent)? beforePay,
  }) async {
    try {
      // Same request, same key: a second tap after a lost reply reopens the same checkout.
      final intent = CheckoutIntent.fromJson(
        await api.postAction('/checkouts', request) as Json,
      );
      if (!context.mounted) return const CheckoutCancelled();
      if (beforePay != null) {
        final blocked = await beforePay(intent);
        if (blocked != null) return CheckoutFailed(blocked);
        if (!context.mounted) return const CheckoutCancelled();
      }
      final outcome = await launcher.pay(context: context, intent: intent);
      return switch (outcome) {
        null => const CheckoutCancelled(),
        PaymentRejected(:final code) => CheckoutFailed(code),
        PaymentApproved(:final paymentId) => await confirm(
          intent.id,
          paymentId,
        ),
      };
    } on ApiException catch (e) {
      return CheckoutFailed(e.code);
    } on Object {
      return const CheckoutFailed('unknown');
    }
  }

  /// Confirms a checkout the PG authorized. Also used when the web app resumes after the hosted
  /// page, and to poll a [CheckoutPending]. Lost replies are retried with the same key; if they
  /// stay lost the result is [CheckoutPending] (saved, so the next start resumes it).
  Future<CheckoutResult> confirm(String checkoutId, String paymentId) async {
    final result = await _confirm(checkoutId, paymentId);
    await (result is CheckoutPending
        ? pending.save(result, user: api.session.subject)
        : pending.clear());
    return result;
  }

  Future<CheckoutResult> _confirm(String checkoutId, String paymentId) async {
    for (var attempt = 0; ; attempt++) {
      final Object? r;
      try {
        r = await api.postAction('/checkouts/$checkoutId/confirm', {
          'payment_id': paymentId,
        });
      } on ApiException catch (e) {
        if (isFinalAnswer(e)) {
          return CheckoutFailed(
            e.code == 'slot_full' ? 'paid_slot_full' : e.code,
          );
        }
        if (attempt >= confirmBackoff.length) {
          return CheckoutPending(checkoutId, paymentId);
        }
        await Future<void>.delayed(confirmBackoff[attempt]);
        continue;
      } on Object {
        return const CheckoutFailed('unknown');
      }
      return _settled(r);
    }
  }

  /// Maps the server's confirm answer. Once it said paid, the result is paid even if the
  /// follow-up booking load fails.
  Future<CheckoutResult> _settled(Object? r) async {
    try {
      final j = r! as Json;
      if (j['status'] == 'awaiting_deposit') {
        return CheckoutAwaitingDeposit(
          VirtualAccount.fromJson(j['virtual_account'] as Json),
        );
      }
      if (j['status'] != 'paid') return const CheckoutFailed('unknown');
      final bookingId =
          (j['booking_id'] ?? j['result_booking_id'] ?? j['id']) as String;
      try {
        return CheckoutPaid(
          bookingId,
          Booking.fromJson(await api.get('/bookings/$bookingId') as Json),
        );
      } on Object {
        return CheckoutPaid(bookingId);
      }
    } on Object {
      return const CheckoutFailed('unknown');
    }
  }
}
