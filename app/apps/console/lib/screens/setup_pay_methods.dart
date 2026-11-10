import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Which payment methods customers can pick. Each switch saves immediately.
class PayMethodsCard extends StatefulWidget {
  const PayMethodsCard({super.key});
  @override
  State<PayMethodsCard> createState() => _PayMethodsCardState();
}

class _PayMethodsCardState extends State<PayMethodsCard> {
  List<Json>? _methods;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = (await context.api.get('/admin/payment-methods') as List)
          .cast<Json>();
      if (mounted) setState(() => _methods = rows);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  Future<void> _toggle(String code, bool on) async {
    final current = [
      for (final m in _methods!)
        if (m['enabled'] == true) m['code'] as String,
    ];
    final next = on
        ? [...current, code]
        : current.where((c) => c != code).toList();
    setState(() => _busy = true);
    try {
      final rows =
          (await context.api.put('/admin/payment-methods', {'enabled': next})
                  as List)
              .cast<Json>();
      if (mounted) setState(() => _methods = rows);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final methods = _methods;
    final on = methods?.where((m) => m['enabled'] == true).length ?? 0;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            0,
            Space.lg,
            Space.lg,
          ),
          leading: Icon(Icons.credit_card_rounded, color: context.primary),
          title: Text(t.cSetupPayMethods, style: context.text.titleMedium),
          subtitle: methods == null
              ? null
              : Text('$on / ${methods.length}', style: context.text.bodySmall),
          children: [
            Text(t.cSetupPayMethodsHint, style: context.text.bodyMedium),
            const SizedBox(height: Space.sm),
            if (methods == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Space.lg),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              for (final m in methods)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: PayBrandBadge(
                    code: m['code'] as String,
                    height: 32,
                  ),
                  title: Text(t.payMethod(m['code'] as String)),
                  value: m['enabled'] == true,
                  onChanged: _busy
                      ? null
                      : (v) => _toggle(m['code'] as String, v),
                ),
          ],
        ),
      ),
    );
  }
}
