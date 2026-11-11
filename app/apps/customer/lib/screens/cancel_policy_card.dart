import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Cancellation fee tiers priced for this checkout total, shown before the customer pays.
/// Mirrors the server rule: fee = max(min_fee, total * percent / 100), capped at the total.
class CancelPolicyCard extends StatelessWidget {
  const CancelPolicyCard({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FutureBuilder<Json>(
      future: context.api.get('/policy/cancellation').then((v) => v as Json),
      builder: (context, snap) {
        if (snap.hasError) return AppCard(child: Text(t.error(snap.error!), style: context.text.bodySmall));
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final policy = data['policy'] as Json;
        final minFee = (policy['min_fee'] as num).toInt();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.cpTitle, style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              for (final tier in (policy['tiers'] as List).cast<Json>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(_line(context, tier, minFee), style: context.text.bodySmall),
                ),
            ],
          ),
        );
      },
    );
  }

  String _line(BuildContext context, Json tier, int minFee) {
    final t = context.t;
    final days = (tier['min_days'] as num).toInt();
    final percent = (tier['percent'] as num?)?.toInt();
    final when = days == 0 ? t.cpWhenSameDay : t.cpWhen('$days');
    if (percent == null) return '$when: ${t.cpClosed}';
    if (percent == 0) return '$when: ${t.cpFree}';
    final fee = total * percent ~/ 100 > minFee ? total * percent ~/ 100 : minFee;
    final capped = fee > total ? total : fee;
    return '$when: ${t.cpFee('$percent', context.won(capped), context.won(total - capped))}';
  }
}
