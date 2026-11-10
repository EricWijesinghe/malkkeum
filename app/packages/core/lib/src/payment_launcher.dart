import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'checkout.dart';
import 'i18n.dart';
import 'pay_brands.dart';
import 'pay_i18n.dart';
import 'social_auth.dart';

/// What the PG window returned. A null PaymentOutcome means the customer closed the window.
sealed class PaymentOutcome {
  const PaymentOutcome();
}

/// Authorized; confirm with this payment id. Dev ids: 'dev:paid' or 'dev:va'.
final class PaymentApproved extends PaymentOutcome {
  const PaymentApproved(this.paymentId);
  final String paymentId;
}

/// The PG declined or could not start. `code` is a server-style code (payment_failed, ...).
final class PaymentRejected extends PaymentOutcome {
  const PaymentRejected(this.code);
  final String code;
}

abstract class PaymentLauncher {
  const PaymentLauncher();

  /// Opens the PG window for [intent]. Returns null when the customer cancels.
  /// The context is needed to show the window; the launcher does not keep it.
  Future<PaymentOutcome?> pay({required BuildContext context, required CheckoutIntent intent});
}

/// Simulated PG window for local development. Never charges anything.
class DevPaymentLauncher extends PaymentLauncher {
  const DevPaymentLauncher();

  @override
  Future<PaymentOutcome?> pay({required BuildContext context, required CheckoutIntent intent}) async {
    final ok = await showAppSheet<bool>(context, title: context.t.apPgTitle, builder: (_) => _DevPaymentSheet(intent: intent));
    if (ok != true) return null;
    return PaymentApproved(intent.method == 'virtual_account' ? 'dev:va' : 'dev:paid');
  }
}

/// Integration point: PortOne v2 payment window (portone_flutter_v2 or the PortOne WebView).
/// Open the window with intent.storeId / channelKey / orderName / amount, then return the
/// payment_id from the callback. Not wired to a package yet (see docs/DEPLOY.md §4).
class PortOneLauncher extends PaymentLauncher {
  const PortOneLauncher();

  // TODO(portone): PortOne.requestPayment(storeId: intent.storeId, channelKey: intent.channelKey,
  // paymentId: intent.id, orderName: intent.orderName, totalAmount: intent.amount, payMethod: ...).
  @override
  Future<PaymentOutcome?> pay({required BuildContext context, required CheckoutIntent intent}) async => const PaymentRejected('provider_not_configured');
}

/// Dev base URL: simulated window. Anything else: the real PG integration point.
PaymentLauncher paymentLauncherFor(String apiBase) => isDevApiBase(apiBase) ? const DevPaymentLauncher() : const PortOneLauncher();

class _DevPaymentSheet extends StatelessWidget {
  const _DevPaymentSheet({required this.intent});
  final CheckoutIntent intent;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isVa = intent.method == 'virtual_account';
    final amount = context.won(intent.amount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(
          child: Row(children: [
            PayBrandBadge(code: intent.method),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.payMethod(intent.method), style: context.text.titleSmall),
                if (intent.orderName.isNotEmpty) Text(intent.orderName, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Space.md),
        Row(children: [
          Text(t.apVaAmount, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft)),
          const Spacer(),
          Text(amount, style: context.text.headlineSmall),
        ]),
        const SizedBox(height: Space.md),
        Text(t.apPgDevNote, style: context.text.labelSmall, textAlign: TextAlign.center),
        const SizedBox(height: Space.md),
        PrimaryButton(label: isVa ? t.apPgIssue : t.apPgPay(amount), onPressed: () => Navigator.of(context).pop(true)),
        const SizedBox(height: Space.xs),
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.apPgCancel)),
      ]),
    );
  }
}
