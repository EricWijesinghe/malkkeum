import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'pay_method_picker.dart';

/// Saved one-tap methods (billing flow) with the registration grid, PAYCO included.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late Future<List<PayChannel>> _billing;
  BillingSetup _setup = BillingSetup.off;
  String? _adding;

  @override
  void initState() {
    super.initState();
    _billing = _loadBilling();
  }

  /// Saved-card section is hidden unless PortOne is configured (see [BillingSetup]).
  Future<List<PayChannel>> _loadBilling() async {
    final api = context.api;
    final channels = await fetchPayChannels(api);
    _setup = await fetchBillingSetup(api);
    return channels.where((c) => c.isBilling && _setup.supports(c.code)).toList();
  }

  void _reload() => setState(() => _billing = _loadBilling());

  Future<void> _add(PayChannel ch) async {
    final t = context.t;
    setState(() => _adding = ch.code);
    final app = context.appRead;
    try {
      final key = await issueBillingKey(
        context: context,
        apiBase: context.api.baseUrl,
        setup: _setup,
        provider: ch.code,
        pageTitle: t.cardRegisterTitle,
      );
      if (key == null) return;
      await app.addMethod(ch.code, t.payMethod(ch.code), key);
      if (mounted) showToast(context, t.methodAdded);
    } catch (e) {
      if (mounted) showToast(context, t.payError(e));
    } finally {
      if (mounted) setState(() => _adding = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.morePayments)),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        Text(t.apPayManageHint, style: context.text.bodySmall?.copyWith(color: context.colors.inkSoft)),
        const SizedBox(height: Space.md),
        if (app.methods.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: Space.lg), child: Center(child: Text(t.methodsEmpty, style: context.text.bodySmall))),
        for (final m in app.methods)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: AppCard(
              child: Row(children: [
                PayBrandBadge(code: m.provider, height: 36),
                const SizedBox(width: Space.md),
                Expanded(child: Text(m.displayName, style: context.text.titleSmall)),
                Tag(label: t.methodRegistered, hue: StatusHues.assigned),
                IconButton(
                  tooltip: t.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => app.deleteMethod(m.id).catchError((Object e) {
                    if (context.mounted) showToast(context, t.payError(e));
                  }),
                ),
              ]),
            ),
          ),
        FutureBuilder<List<PayChannel>>(
          future: _billing,
          builder: (context, snap) {
            if (snap.hasError) return ErrorRetry(message: t.errorGeneric, retryLabel: t.retry, onRetry: _reload);
            final channels = snap.data;
            if (channels == null) return const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: CircularProgressIndicator()));
            if (channels.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: Space.lg),
              Text(t.apPayManageTitle, style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
                for (final ch in channels)
                  PayChannelTile(
                    code: ch.code,
                    label: t.payMethod(ch.code),
                    busy: _adding == ch.code,
                    onTap: _adding == null ? () => _add(ch) : null,
                  ),
              ]),
            ]);
          },
        ),
      ]),
    );
  }
}
