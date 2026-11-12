import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
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
          ReceiptSettingsLine(api: context.appRead.api, memory: ReceiptMemory()),
        ],
      ),
    ),
  );
}

/// Runs create -> PG window -> confirm for a checkout channel. The caller decides navigation
/// (paid, virtual account, failure), so this never pushes a route itself.
Future<CheckoutResult> payWithChannel(
  BuildContext context,
  PayChannel channel,
  Json request,
) {
  final app = context.appRead;
  final service = CheckoutService(
    api: app.api,
    launcher: paymentLauncherFor(app.api.baseUrl),
  );
  return service.run(context, {
    ...request,
    'method': channel.code,
  }, beforePay: receiptStep(context, app.api, ReceiptMemory()));
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
