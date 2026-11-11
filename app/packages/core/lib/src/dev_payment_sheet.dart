import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'checkout.dart';
import 'i18n.dart';
import 'pay_brands.dart';
import 'pay_i18n.dart';

/// Payment methods the simulated window offers, in the order a Korean customer expects.
const devPaymentMethods = [
  'card',
  'kakaopay',
  'naverpay',
  'tosspay',
  'transfer',
  'virtual_account',
];

enum _Step { pick, confirm, processing, done }

/// Simulated PG window (dev only): method pick, confirm, processing, then a receipt. Nothing is
/// charged. Pops the chosen method code on "done" and null on cancel. The launcher maps it to a
/// dev payment id, and the normal confirm path marks the booking paid.
class DevPaymentSheet extends StatefulWidget {
  const DevPaymentSheet({super.key, required this.intent, this.processingDelay = const Duration(milliseconds: 1400)});

  final CheckoutIntent intent;

  /// Pause that stands in for the PG round trip. Tests pass zero.
  final Duration processingDelay;

  @override
  State<DevPaymentSheet> createState() => _DevPaymentSheetState();
}

class _DevPaymentSheetState extends State<DevPaymentSheet> {
  late String _method = devPaymentMethods.contains(widget.intent.method) ? widget.intent.method : 'card';
  _Step _step = _Step.pick;
  // Fake approval number: six digits from the clock, stable for this sheet.
  final String _approval = (DateTime.now().microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0');

  bool get _isVa => _method == 'virtual_account';

  Future<void> _process() async {
    setState(() => _step = _Step.processing);
    await Future<void>.delayed(widget.processingDelay);
    if (!mounted) return;
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_step) {
      _Step.pick => _pick(context),
      _Step.confirm => _confirm(context),
      _Step.processing => _processing(context),
      _Step.done => _done(context),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
      ),
    );
  }

  List<Widget> _pick(BuildContext context) {
    final t = context.t;
    return [
      Text(t.apPgPickMethod, style: context.text.titleSmall),
      const SizedBox(height: Space.sm),
      for (final code in devPaymentMethods)
        _MethodTile(
          key: ValueKey('pay-method-$code'),
          code: code,
          label: t.payMethod(code),
          selected: code == _method,
          onTap: () => setState(() => _method = code),
        ),
      const SizedBox(height: Space.md),
      PrimaryButton(
        key: const ValueKey('pay-next'),
        label: _isVa ? t.apPgConfirmBtn : t.apPgPay(context.won(widget.intent.amount)),
        onPressed: () => setState(() => _step = _Step.confirm),
      ),
      _cancelButton(context),
      _testNote(context),
    ];
  }

  List<Widget> _confirm(BuildContext context) {
    final t = context.t;
    return [
      Text(t.apPgConfirmTitle, style: context.text.titleSmall),
      const SizedBox(height: Space.sm),
      AppCard(
        child: Row(
          children: [
            PayBrandBadge(code: _method),
            const SizedBox(width: Space.md),
            Expanded(child: Text(t.payMethod(_method), style: context.text.titleSmall)),
          ],
        ),
      ),
      const SizedBox(height: Space.md),
      _amountRow(context, t.apVaAmount),
      const SizedBox(height: Space.md),
      PrimaryButton(key: const ValueKey('pay-confirm'), label: t.apPgConfirmBtn, onPressed: _process),
      _cancelButton(context),
      _testNote(context),
    ];
  }

  List<Widget> _processing(BuildContext context) {
    return [
      const SizedBox(height: Space.lg),
      const Center(child: CircularProgressIndicator()),
      const SizedBox(height: Space.md),
      Text(context.t.apPgProcessing, textAlign: TextAlign.center, style: context.text.bodyMedium),
      const SizedBox(height: Space.lg),
    ];
  }

  List<Widget> _done(BuildContext context) {
    final t = context.t;
    return [
      Text(t.apPgDoneTitle, style: context.text.titleSmall),
      const SizedBox(height: Space.sm),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.apPgReceiptTitle, style: context.text.labelLarge),
            const SizedBox(height: Space.sm),
            _line(context, t.apPgReceiptMethod, t.payMethod(_method)),
            _line(context, t.apPgReceiptApproval, _approval),
            _amountRow(context, t.apPgReceiptAmount),
          ],
        ),
      ),
      if (_isVa) ...[
        const SizedBox(height: Space.sm),
        Text(t.apPgVaIssued, style: context.text.bodySmall, textAlign: TextAlign.center),
      ],
      const SizedBox(height: Space.md),
      PrimaryButton(
        key: const ValueKey('pay-done'),
        label: t.apPgReceiptDone,
        onPressed: () => Navigator.of(context).pop(_method),
      ),
    ];
  }

  Widget _amountRow(BuildContext context, String label) {
    return Row(
      children: [
        Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft)),
        const Spacer(),
        Text(context.won(widget.intent.amount), style: context.text.headlineSmall),
      ],
    );
  }

  Widget _line(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          Text(k, style: context.text.bodySmall?.copyWith(color: context.colors.inkSoft)),
          const Spacer(),
          Text(v, style: context.text.bodySmall),
        ],
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(context.t.apPgCancel),
    );
  }

  Widget _testNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Text(
        '${context.t.apPgTestBadge} · ${context.t.apPgDevNote}',
        style: context.text.labelSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({super.key, required this.code, required this.label, required this.selected, required this.onTap});

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            children: [
              PayBrandBadge(code: code),
              const SizedBox(width: Space.md),
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? context.primary : context.colors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
