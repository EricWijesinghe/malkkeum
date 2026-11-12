import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'booking_flow.dart';
import 'pay_flow.dart' show showVirtualAccount;
import 'web_history_stub.dart'
    if (dart.library.js_interop) 'web_history_web.dart';

/// Web deep links live in the URL hash: /app/#/booking/`<id>`, and /app/#/pay-return?paymentId=..
/// after the hosted PortOne page. Null when there is no hash (every mobile launch).
Uri? webHashRoute(Uri base) =>
    base.fragment.isEmpty ? null : Uri.parse(base.fragment);

/// Runs the hash route once, then clears the hash so a reload never repeats a payment confirm.
/// The Shell calls this after sign-in, so a link opened while signed out waits for sign-in.
Future<void> openWebHashRoute(BuildContext context) async {
  final route = webHashRoute(Uri.base);
  if (route == null) return;
  replaceBrowserUrl(Uri.base.replace(fragment: '').toString());
  final segments = route.pathSegments;
  if (segments.length == 2 && segments.first == 'booking') {
    final id = segments[1];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: id)),
    );
  } else if (route.path == '/pay-return') {
    await _resumePayment(context, route);
  }
}

/// The PG authorized (or not) in the hosted page; confirm it with the server, then show the result.
Future<void> _resumePayment(BuildContext context, Uri route) async {
  final id = route.queryParameters['paymentId'] ?? '';
  if (id.isEmpty) return;
  final app = context.appRead;
  try {
    final result = switch (outcomeFromRedirect(route, id)) {
      null => const CheckoutCancelled(),
      PaymentRejected(:final code) => CheckoutFailed(code),
      PaymentApproved(:final paymentId) => await CheckoutService(
        api: app.api,
        launcher: paymentLauncherFor(app.api.baseUrl),
      ).confirm(id, paymentId),
    };
    if (!context.mounted) return;
    switch (result) {
      case CheckoutPaid(:final booking):
        app.bookingsChanged();
        app.analytics.track('payment_done', screen: 'web_return');
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => DoneScreen(booking: booking)),
          (r) => r.isFirst,
        );
      case CheckoutAwaitingDeposit(:final account):
        app.bookingsChanged();
        await showVirtualAccount(context, account);
      case CheckoutFailed(:final code):
        showToast(context, context.t.checkoutFailure(code));
      case CheckoutCancelled():
        break;
    }
  } catch (e) {
    if (context.mounted) showToast(context, context.t.payError(e));
  }
}
