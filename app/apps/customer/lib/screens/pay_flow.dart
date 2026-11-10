import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'pay_method_picker.dart';
import 'virtual_account.dart';

export 'pay_method_picker.dart' show ChannelChoice, PayChoice, SavedChoice;

/// The full method picker in a sheet. Null when dismissed.
Future<PayChoice?> choosePayMethod(BuildContext context, {String? selectedId}) => showAppSheet<PayChoice>(
      context,
      title: context.t.apPayAllTitle,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
        child: PayMethodPicker(selectedSavedId: selectedId, onChoose: (c) => Navigator.of(ctx).pop(c)),
      ),
    );

/// Runs create -> PG window -> confirm for a checkout channel. The caller decides navigation
/// (paid, virtual account, failure), so this never pushes a route itself.
Future<CheckoutResult> payWithChannel(BuildContext context, PayChannel channel, Json request) {
  final app = context.appRead;
  final service = CheckoutService(api: app.api, launcher: paymentLauncherFor(app.api.baseUrl));
  return service.run(context, {...request, 'method': channel.code});
}

/// Shows the virtual-account details screen and returns when the customer leaves it.
Future<void> showVirtualAccount(BuildContext context, VirtualAccount account, {int? amount}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VirtualAccountScreen(account: account, amount: amount)));
