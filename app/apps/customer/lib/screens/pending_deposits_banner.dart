import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'pay_flow.dart';

/// Shows the first virtual-account deposit still waiting. Hidden when there is none or the
/// request fails: the banner is a reminder, never a blocker.
class PendingDepositsBanner extends StatelessWidget {
  const PendingDepositsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return FutureBuilder<List<PendingDeposit>>(
      // Re-fetch whenever a booking changes.
      key: ValueKey(app.bookingsVersion),
      future: fetchPendingDeposits(app.api),
      builder: (context, snap) {
        final first = snap.data?.firstOrNull;
        if (first == null) return const SizedBox.shrink();
        final t = context.t;
        final due = first.account.due;
        final amount = context.won(first.amount);
        return Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.gutter, Space.gutter, 0),
          child: AppCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: () => showVirtualAccount(context, first.account, amount: first.amount),
              child: Row(children: [
                Icon(Icons.account_balance_rounded, color: context.colors.sun),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.apVaBannerTitle, style: context.text.titleSmall),
                    Text(due == null ? amount : t.apVaBannerBody(amount, dateTimeLabel(due, context.lang)), style: context.text.bodySmall),
                  ]),
                ),
                Text(t.apVaBannerAction, style: context.text.labelLarge?.copyWith(color: context.primary)),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        );
      },
    );
  }
}
