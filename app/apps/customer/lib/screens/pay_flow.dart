import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'booking_detail.dart';
import 'pay_method_picker.dart';
import 'virtual_account.dart';

export 'pay_method_picker.dart' show ChannelChoice, PayChoice, SavedChoice;

/// The full method picker in a sheet. Null when dismissed or when a guest declines to sign in.
/// A guest signs in first; the picker then opens in the same tap.
Future<PayChoice?> choosePayMethod(
  BuildContext context, {
  String? selectedId,
}) async {
  if (!await requireSignIn(context) || !context.mounted) return null;
  return showAppSheet<PayChoice>(
    context,
    title: context.t.apPayAllTitle,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PayMethodPicker(
            selectedSavedId: selectedId,
            onChoose: (c) => Navigator.of(ctx).pop(c),
          ),
          ReceiptSettingsLine(
            api: context.appRead.api,
            memory: ReceiptMemory(),
          ),
        ],
      ),
    ),
  );
}

/// Runs create -> PG window -> confirm for a checkout channel. The caller decides navigation
/// (paid, virtual account, failure); the only route pushed here is [PaymentConfirmingScreen]
/// when the confirm reply is lost. [CheckoutPending] comes back only if the customer left that
/// screen: never offer Pay again then.
Future<CheckoutResult> payWithChannel(
  BuildContext context,
  PayChannel channel,
  Json request,
) async {
  final app = context.appRead;
  final service = checkoutServiceFor(app.api);
  final result = await service.run(context, {
    ...request,
    'method': channel.code,
  }, beforePay: receiptStep(context, app.api, ReceiptMemory()));
  if (result is! CheckoutPending || !context.mounted) return result;
  return untilConfirmed(context, service, result);
}

CheckoutService checkoutServiceFor(ApiClient api) =>
    CheckoutService(api: api, launcher: paymentLauncherFor(api.baseUrl));

/// Shows [PaymentConfirmingScreen] until the server answers for [pending]. Returns [pending]
/// itself when the customer leaves; the next start resumes it ([resumePendingPayment]).
Future<CheckoutResult> untilConfirmed(
  BuildContext context,
  CheckoutService service,
  CheckoutPending pending,
) async =>
    await Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            PaymentConfirmingScreen(service: service, pending: pending),
      ),
    ) ??
    pending;

/// After sign-in: a payment whose confirm went unanswered last time is asked about again.
Future<void> resumePendingPayment(BuildContext context) async {
  final app = context.appRead;
  final service = checkoutServiceFor(app.api);
  final pending = await service.pending.load(user: app.api.session.subject);
  if (pending == null || !context.mounted) return;
  final result = await untilConfirmed(context, service, pending);
  if (!context.mounted) return;
  app.bookingsChanged();
  switch (result) {
    case CheckoutPaid(:final bookingId):
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingDetailScreen(id: bookingId),
        ),
      );
    case CheckoutAwaitingDeposit(:final account):
      await showVirtualAccount(context, account);
    case CheckoutFailed(:final code):
      showToast(context, context.t.checkoutFailure(code));
    case CheckoutPending() || CheckoutCancelled():
      break;
  }
}

/// The PG approved but the server has not said so yet: keep asking, with growing waits, and
/// never offer to pay again. Pops with the server's answer, or null when the customer leaves.
class PaymentConfirmingScreen extends StatefulWidget {
  const PaymentConfirmingScreen({
    super.key,
    required this.service,
    required this.pending,
    this.waits = const [
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 20),
      Duration(seconds: 30),
    ],
  });
  final CheckoutService service;
  final CheckoutPending pending;

  /// Between polls; the last one repeats.
  final List<Duration> waits;

  @override
  State<PaymentConfirmingScreen> createState() =>
      _PaymentConfirmingScreenState();
}

class _PaymentConfirmingScreenState extends State<PaymentConfirmingScreen> {
  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    final p = widget.pending;
    for (var i = 0; mounted; i++) {
      final r = await widget.service.confirm(p.checkoutId, p.paymentId);
      if (!mounted) return;
      if (r is! CheckoutPending) {
        Navigator.of(context).pop(r);
        return;
      }
      final waits = widget.waits;
      await Future<void>.delayed(
        waits[i < waits.length ? i : waits.length - 1],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PopScope<CheckoutResult>(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: Space.gutter),
                Text(
                  t.payConfirmingTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Space.gutter / 2),
                Text(t.payConfirmingBody, textAlign: TextAlign.center),
                const SizedBox(height: Space.gutter),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.goHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the virtual-account details screen and returns when the customer leaves it.
Future<void> showVirtualAccount(
  BuildContext context,
  VirtualAccount account, {
  int? amount,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => VirtualAccountScreen(account: account, amount: amount),
  ),
);
