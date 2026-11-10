import 'package:flutter/widgets.dart';

import 'api.dart';
import 'checkout.dart';
import 'models.dart';
import 'payment_launcher.dart';

/// Outcome of create -> launch -> confirm. Every branch is explicit; nothing is thrown to the UI.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Paid: the booking exists and is confirmed.
final class CheckoutPaid extends CheckoutResult {
  const CheckoutPaid(this.booking);
  final Booking booking;
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

/// Failed at create, launch or confirm. `code` is a server code, or 'paid_slot_full' when the
/// payment was authorized but the slot filled first (the server cancels it).
final class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed(this.code);
  final String code;
}

class CheckoutService {
  CheckoutService({required this.api, required this.launcher});

  final ApiClient api;
  final PaymentLauncher launcher;

  /// [request] is the POST /v1/checkouts body: {kind, booking | booking_id, method}.
  Future<CheckoutResult> run(BuildContext context, Json request) async {
    final CheckoutIntent intent;
    try {
      intent = CheckoutIntent.fromJson(await api.post('/checkouts', request) as Json);
    } on ApiException catch (e) {
      return CheckoutFailed(e.code);
    }
    if (!context.mounted) return const CheckoutCancelled();
    final outcome = await launcher.pay(context: context, intent: intent);
    switch (outcome) {
      case null:
        return const CheckoutCancelled();
      case PaymentRejected(:final code):
        return CheckoutFailed(code);
      case PaymentApproved(:final paymentId):
        return _confirm(intent.id, paymentId);
    }
  }

  Future<CheckoutResult> _confirm(String checkoutId, String paymentId) async {
    try {
      final r = await api.post('/checkouts/$checkoutId/confirm', {'payment_id': paymentId}) as Json;
      if (r['status'] == 'awaiting_deposit') {
        return CheckoutAwaitingDeposit(VirtualAccount.fromJson(r['virtual_account'] as Json));
      }
      // Server answers {status: 'paid', booking_id}; load the full booking for the UI.
      final bookingId = (r['booking_id'] ?? r['result_booking_id'] ?? r['id']) as String;
      return CheckoutPaid(Booking.fromJson(await api.get('/bookings/$bookingId') as Json));
    } on ApiException catch (e) {
      return CheckoutFailed(e.code == 'slot_full' ? 'paid_slot_full' : e.code);
    }
  }
}
