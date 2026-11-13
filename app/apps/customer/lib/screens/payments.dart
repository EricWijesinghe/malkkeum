import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
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
        child: FutureBuilder<List<PayChannel>>(
          future: _billing,
          builder: (context, snap) {
            final all = snap.data ?? const <PayChannel>[];
            final codes = {for (final ch in all) ch.code};
            // One list (p23): saved methods sit on their channel's row; any whose channel is
            // not offered (or not loaded yet) is listed on its own first.
            final rows = <Widget>[
              for (final m in app.methods)
                if (!codes.contains(m.provider))
                  _savedRow(m, ValueKey('method-${m.id}')),
              for (final ch in all) ..._channelRows(ch, app.methods),
            ];
            final channels = all
                .where((c) => c.isBilling && _setup.supports(c.code))
                .toList();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              // A short page: build every row so the register tiles below the fold exist too.
              scrollCacheExtent: const ScrollCacheExtent.viewport(4),
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              children: [
                if (app.methods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.gutter,
                      vertical: Space.xs,
                    ),
                    child: Text(
                      t.methodsEmpty,
                      style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                    ),
                  ),
                for (final (i, r) in rows.indexed)
                  StaggerIn(index: i, child: r),
                if (snap.hasError)
                  ErrorRetry(
                    message: t.error(snap.error!),
                    retryLabel: t.retry,
                    onRetry: _reload,
                  )
                else if (snap.data == null)
                  const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (channels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.lg,
                      Space.gutter,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t.apPayManageTitle,
                          style: context.text.titleSmall,
                        ),
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
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(Space.gutter),
                  child: Text(
                    t.payCardNote(BrandConfig.placeholder.name),
                    style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The channel's saved methods (one row each), or one plain row when none is saved.
  List<Widget> _channelRows(PayChannel ch, List<PaymentMethod> methods) {
    final saved = methods.where((m) => m.provider == ch.code).toList();
    if (saved.isEmpty) {
      final canAdd =
          ch.isBilling && _setup.supports(ch.code) && _adding == null;
      return [
        _MethodRow(
          key: ValueKey('channel-${ch.code}'),
          code: ch.code,
          title: context.t.payMethod(ch.code),
          onTap: canAdd ? () => _add(ch) : null,
        ),
      ];
    }
    return [
      for (final (i, m) in saved.indexed)
        _savedRow(
          m,
          ValueKey(i == 0 ? 'channel-${ch.code}' : 'method-${m.id}'),
        ),
    ];
  }

  Widget _savedRow(PaymentMethod m, Key key) {
    final t = context.t;
    final app = context.appRead;
    return _MethodRow(
      key: key,
      code: m.provider,
      title: t.payMethod(m.provider),
      subtitle: m.displayName,
      registered: true,
      onDelete: () => app.deleteMethod(m.id).catchError((Object e) {
        if (mounted) showToast(context, t.payError(e));
      }),
    );
  }
}

/// One payment row: brand chip, name, the saved card line, "등록됨" and delete when saved.
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    super.key,
    required this.code,
    required this.title,
    this.subtitle,
    this.registered = false,
    this.onTap,
    this.onDelete,
  });
  final String code;
  final String title;
  final String? subtitle;
  final bool registered;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    // A plain row, not a ListTile: at the largest text the tag and delete button would
    // leave a ListTile title no room at all; here the name and the tag share it instead.
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: Space.gutter,
            end: Space.sm,
            top: Space.xs,
            bottom: Space.xs,
          ),
          child: Row(
            children: [
              // Text wordmark only: no third-party logo artwork is bundled. Decorative, so it
              // keeps its size while the name scales.
              MediaQuery.withNoTextScaling(
                child: PayBrandBadge(code: code, height: 28),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.text.bodySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                      ),
                  ],
                ),
              ),
              if (registered)
                Flexible(
                  // Pops in when the method appears (e.g. right after registering it).
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: motionFor(context, Motion.iconPop),
                    curve: Curves.easeOutBack,
                    builder: (_, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: Tag(
                      label: t.methodRegistered,
                      hue: StatusHues.assigned,
                    ),
                  ),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: t.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
