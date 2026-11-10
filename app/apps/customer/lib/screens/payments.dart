import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

typedef _Provider = ({String code, String label, IconData icon, Color color});

List<_Provider> _providers(T t) => [
      (code: 'card', label: t.methodCard, icon: Icons.credit_card_rounded, color: const Color(0xFF3B5BFD)),
      (code: 'kakaopay', label: t.methodKakao, icon: Icons.chat_bubble_rounded, color: const Color(0xFFB38F00)),
      (code: 'naverpay', label: t.methodNaver, icon: Icons.bolt_rounded, color: const Color(0xFF03A94D)),
      (code: 'tosspay', label: t.methodToss, icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF1B64DA)),
    ];

/// Pick a saved method or register a new one. Returns the method id.
Future<String?> pickPaymentMethod(BuildContext context, {String? selected}) {
  final t = context.t;
  return showAppSheet<String>(
    context,
    title: t.paymentMethod,
    builder: (ctx) => ListenableBuilder(
      listenable: ctx.appRead,
      builder: (ctx, _) {
        final methods = ctx.appRead.methods;
        return ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter), children: [
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: OptionCard(
                leading: Icon(_providers(t).firstWhere((p) => p.code == m.provider, orElse: () => _providers(t).first).icon),
                title: m.displayName,
                selected: m.id == selected,
                onTap: () => Navigator.of(ctx).pop(m.id),
              ),
            ),
          const SizedBox(height: Space.xs),
          Text(t.addPaymentMethod, style: ctx.text.titleSmall),
          const SizedBox(height: Space.xs),
          _ProviderGrid(onAdded: (id) => Navigator.of(ctx).pop(id)),
        ]);
      },
    ),
  );
}

class _ProviderGrid extends StatefulWidget {
  const _ProviderGrid({required this.onAdded});
  final ValueChanged<String> onAdded;
  @override
  State<_ProviderGrid> createState() => _ProviderGridState();
}

class _ProviderGridState extends State<_ProviderGrid> {
  String? _busy;

  Future<void> _add(_Provider p) async {
    setState(() => _busy = p.code);
    try {
      // The gateway's registration UI runs here once the PG contract is signed (decision #3).
      final m = await context.appRead.addMethod(p.code, p.label);
      if (!mounted) return;
      showToast(context, context.t.methodAdded);
      widget.onAdded(m.id);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: Space.xs,
        crossAxisSpacing: Space.xs,
        children: [
          for (final p in _providers(context.t))
            OutlinedButton.icon(
              icon: _busy == p.code ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(p.icon, color: p.color),
              label: Text(p.label, overflow: TextOverflow.ellipsis),
              onPressed: _busy == null ? () => _add(p) : null,
            ),
        ],
      );
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.morePayments)),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        if (app.methods.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: Space.xl), child: Center(child: Text(t.methodsEmpty, style: context.text.bodySmall))),
        for (final m in app.methods)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: AppCard(
              child: Row(children: [
                Icon(Icons.credit_card_rounded, color: context.primary),
                const SizedBox(width: Space.md),
                Expanded(child: Text(m.displayName, style: context.text.titleSmall)),
                Tag(label: t.methodRegistered, hue: StatusHues.assigned),
                IconButton(tooltip: t.delete, icon: const Icon(Icons.delete_outline_rounded), onPressed: () => app.deleteMethod(m.id).catchError((Object e) {
                      if (context.mounted) showToast(context, t.error(e));
                    })),
              ]),
            ),
          ),
        const SizedBox(height: Space.lg),
        Text(t.addPaymentMethod, style: context.text.titleSmall),
        const SizedBox(height: Space.xs),
        _ProviderGrid(onAdded: (_) {}),
      ]),
    );
  }
}
