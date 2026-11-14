import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Sample customers, partners and bookings for demos and training. Loading refuses over real bookings.
/// Removing it needs a 6-digit code from the owner's authenticator app, typed here for each removal.
class DemoTab extends StatelessWidget {
  const DemoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final admin = context.console.isAdmin;
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Text(t.cgDemoTitle, style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        Text(t.cgDemoBody, style: context.text.bodySmall),
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: admin ? () => _load(context) : null,
          child: Text(t.cgDemoLoad),
        ),
        const SizedBox(height: Space.sm),
        OutlinedButton(
          onPressed: admin ? () => _clear(context) : null,
          child: Text(t.cgDemoClear),
        ),
        const SizedBox(height: Space.xs),
        Text(t.cgDemoClearBody, style: context.text.bodySmall),
      ],
    );
  }

  Future<void> _load(BuildContext context) async {
    final t = context.t;
    try {
      await context.api.post('/admin/demo/load');
      if (context.mounted) showToast(context, t.cgDemoLoaded);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showToast(context, switch (e.code) {
        'demo_real_data' => t.cgDemoRealData,
        'demo_already_loaded' => t.cgDemoAlready,
        _ => t.error(e),
      });
    }
  }

  Future<void> _clear(BuildContext context) async {
    final t = context.t;
    final code = await _askOwnerCode(context);
    if (code == null || !context.mounted) return;
    try {
      await context.api.post('/admin/demo/clear', null, null, {
        'X-Owner-Totp': code,
      });
      if (context.mounted) showToast(context, t.cgDemoCleared);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showToast(context, e.status == 401 ? t.cgCodeWrong : t.error(e));
    }
  }
}

/// Asks for the 6-digit code; null when cancelled or left empty.
Future<String?> _askOwnerCode(BuildContext context) async {
  final t = context.t;
  final ctrl = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.cgDemoClear),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(labelText: t.cgDemoOwnerCode),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: Text(t.save),
        ),
      ],
    ),
  );
  disposeAfterClose([ctrl]);
  return (code == null || code.length != 6) ? null : code;
}
