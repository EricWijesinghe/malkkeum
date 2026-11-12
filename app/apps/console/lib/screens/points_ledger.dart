// One customer's points ledger, with the admin-only manual adjustment. Every number comes from
// the server (GET /admin/growth/points/{id}); an adjustment needs a reason and is audit-logged there.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Same limits as the server (points.rs): it refuses anything else, this only saves a round trip.
const _maxAdjust = 100000;
const _maxReasonChars = 200;

String _kindLabel(T t, String kind) => switch (kind) {
  'earn' => t.walletKindEarn,
  'welcome' => t.walletKindWelcome,
  'referral' => t.walletKindReferral,
  'refund' => t.walletKindRefund,
  'spend' => t.walletKindSpend,
  'expire' => t.walletKindExpire,
  _ => t.walletKindOther,
};

class PointsLedgerPage extends StatelessWidget {
  const PointsLedgerPage({super.key, required this.userId, required this.name});
  final String userId;
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${context.t.pointsLedgerTitle} · $name')),
    body: PointsLedgerPanel(userId: userId),
  );
}

class PointsLedgerPanel extends StatelessWidget {
  const PointsLedgerPanel({super.key, required this.userId});
  final String userId;

  Future<void> _adjust(
    BuildContext context,
    Future<void> Function() reload,
  ) async {
    final t = context.t;
    final amount = TextEditingController();
    final reason = TextEditingController();
    final input = await showDialog<(int, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.walletKindOther),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,6}')),
              ],
              decoration: InputDecoration(labelText: t.pointsAdjustAmount),
            ),
            TextField(
              controller: reason,
              maxLength: _maxReasonChars,
              decoration: InputDecoration(labelText: t.pointsAdjustReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              ctx,
            ).pop((int.tryParse(amount.text) ?? 0, reason.text.trim())),
            child: Text(t.save),
          ),
        ],
      ),
    );
    amount.dispose();
    reason.dispose();
    if (input == null || !context.mounted) return;
    final (points, why) = input;
    if (points == 0 || points.abs() > _maxAdjust || why.isEmpty) {
      showToast(context, t.pointsAdjustInvalid);
      return;
    }
    try {
      await context.api.post('/admin/growth/points/adjust', {
        'user_id': userId,
        'amount': points,
        'reason': why,
      }, ApiClient.newIdempotencyKey());
      if (context.mounted) showToast(context, t.pointsAdjustDone);
      await reload();
    } catch (e) {
      if (context.mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async =>
          (await context.api.get('/admin/growth/points/$userId')) as Json,
      builder: (context, p, reload) {
        final entries = ((p['entries'] as List?) ?? const []).cast<Json>();
        return ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            AppCard(
              // Stacked: the theme's buttons are full width, which a Row cannot lay out.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.walletBalance, style: context.text.bodySmall),
                  Text(
                    t.walletPoints('${p['balance'] ?? 0}'),
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: Space.sm),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(t.walletKindOther),
                    onPressed: () => _adjust(context, reload),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            if (entries.isEmpty)
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: t.walletEmpty,
              ),
            for (final e in entries) _row(context, e),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, Json e) {
    final t = context.t;
    final amount = (e['amount'] as num).toInt();
    final at = DateTime.parse(e['at'] as String).toLocal();
    final reason = e['reason'] as String?;
    return ListTile(
      title: Text(_kindLabel(t, e['kind'] as String)),
      subtitle: Text(
        [dateTimeLabel(at, context.lang), ?reason].join(' · '),
      ),
      trailing: Text(
        t.walletPoints(amount > 0 ? '+$amount' : '$amount'),
        style: context.text.titleSmall?.copyWith(
          color: amount > 0 ? context.colors.fresh : context.colors.inkSoft,
        ),
      ),
    );
  }
}
