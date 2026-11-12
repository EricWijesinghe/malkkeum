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

  /// Every channel the server offers. The register grid shows only the billing ones PortOne
  /// is configured for (see [BillingSetup]).
  Future<List<PayChannel>> _loadBilling() async {
    final api = context.api;
    final channels = await fetchPayChannels(api);
    _setup = await fetchBillingSetup(api);
    return channels;
  }

  void _reload() {
    setState(() {
      _billing = _loadBilling();
    });
  }

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
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          try {
            await app.loadMethods();
          } catch (e) {
            if (context.mounted) showToast(context, t.error(e));
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            Text(
              t.apPayManageHint,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.inkSoft,
              ),
            ),
            const SizedBox(height: Space.md),
            if (app.methods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.lg),
                child: Center(
                  child: Text(t.methodsEmpty, style: context.text.bodySmall),
                ),
              ),
            for (final m in app.methods)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: AppCard(
                  child: Row(
                    children: [
                      PayBrandBadge(code: m.provider, height: 36),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.displayName, style: context.text.titleSmall),
                            const SizedBox(height: Space.xxs),
                            Tag(
                              label: t.methodRegistered,
                              hue: StatusHues.assigned,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: t.delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () =>
                            app.deleteMethod(m.id).catchError((Object e) {
                              if (context.mounted) {
                                showToast(context, t.payError(e));
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            FutureBuilder<List<PayChannel>>(
              future: _billing,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorRetry(
                    message: t.error(snap.error!),
                    retryLabel: t.retry,
                    onRetry: _reload,
                  );
                }
                final all = snap.data;
                if (all == null) {
                  return const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final channels = all
                    .where((c) => c.isBilling && _setup.supports(c.code))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (all.isNotEmpty) ...[
                      const SizedBox(height: Space.lg),
                      Text(t.payAvailableTitle, style: context.text.titleSmall),
                      const SizedBox(height: Space.xs),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: Space.xs),
                        child: Column(
                          children: [
                            for (final ch in all)
                              ListTile(
                                key: ValueKey('channel-${ch.code}'),
                                leading: Icon3D(
                                  _channelIcon(ch.code),
                                  size: 36,
                                ),
                                title: Text(t.payMethod(ch.code)),
                                // Text wordmark only: no third-party logo artwork is bundled.
                                // Decorative, so it keeps its size; the title scales.
                                // Unconstrained: the badge would otherwise stretch
                                // to the whole tile width.
                                trailing: UnconstrainedBox(
                                  child: MediaQuery.withNoTextScaling(
                                    child: PayBrandBadge(
                                      code: ch.code,
                                      height: 28,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (channels.isNotEmpty) ...[
                      const SizedBox(height: Space.lg),
                      Text(t.apPayManageTitle, style: context.text.titleSmall),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          for (final ch in channels)
                            PayChannelTile(
                              code: ch.code,
                              label: t.payMethod(ch.code),
                              busy: _adding == ch.code,
                              onTap: _adding == null ? () => _add(ch) : null,
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic art per channel kind; easy-pay brands share the wallet.
String _channelIcon(String code) => switch (code) {
  'card' => 'pay_card',
  'transfer' => 'pay_bank',
  'virtual_account' => 'pay_virtual',
  _ => 'pay_wallet',
};
