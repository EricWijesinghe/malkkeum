import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

/// One input in [askFields]. [phone] and [digits] pick the keyboard and the input filter.
class FieldSpec {
  const FieldSpec(this.label, {this.obscure = false, this.phone = false, this.digits = false});
  final String label;
  final bool obscure;
  final bool phone;
  final bool digits;
}

/// Asks for a few typed values in one dialog. Resolves to the trimmed values in field order, or null when
/// cancelled. Confirm stays disabled until every field has text.
Future<List<String>?> askFields(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  required List<FieldSpec> fields,
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _FieldsDialog(title: title, body: body, confirm: confirm, fields: fields),
);

class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({required this.title, required this.body, required this.confirm, required this.fields});
  final String title;
  final String body;
  final String confirm;
  final List<FieldSpec> fields;

  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final List<TextEditingController> _ctl = [for (final _ in widget.fields) TextEditingController()];

  @override
  void dispose() {
    for (final c in _ctl) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _filled => _ctl.every((c) => c.text.trim().isNotEmpty);

  void _submit() {
    if (!_filled) return;
    Navigator.of(context).pop([for (final c in _ctl) c.text.trim()]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            for (var i = 0; i < widget.fields.length; i++) ...[
              const SizedBox(height: Space.sm),
              TextField(
                controller: _ctl[i],
                obscureText: widget.fields[i].obscure,
                autofocus: i == 0,
                keyboardType: widget.fields[i].phone || widget.fields[i].digits ? TextInputType.number : TextInputType.text,
                inputFormatters: widget.fields[i].phone
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))]
                    : widget.fields[i].digits
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(labelText: widget.fields[i].label),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.oaCancel),
        ),
        FilledButton(
          onPressed: _filled ? _submit : null,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}

/// Picks the new owner from active admins. Resolves to the chosen staff row, or null.
Future<Json?> askTransferTarget(BuildContext context, List<Json> admins) => showDialog<Json>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(context.t.oaTransferTarget),
    content: SizedBox(
      width: 360,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final a in admins)
            ListTile(
              title: Text('${a['name']}'),
              subtitle: Text('${a['email']}'),
              onTap: () => Navigator.of(ctx).pop(a),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(context.t.oaCancel),
      ),
    ],
  ),
);

/// Shows freshly issued recovery codes once. Resolves true when the owner says they wrote them down.
/// Asks for one of the codes just shown, typed back: that proves the owner saw the new set.
/// Null when cancelled.
Future<String?> askRecoveryCode(BuildContext context) async {
  final t = context.t;
  final typed = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.oaRecoveryTypeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.oaRecoveryTypeBody),
          const SizedBox(height: Space.sm),
          TextField(
            controller: typed,
            autofocus: true,
            decoration: InputDecoration(labelText: t.oaRecoveryTypeLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t.oaCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(typed.text.trim()),
          child: Text(t.oaContinue),
        ),
      ],
    ),
  );
  typed.dispose();
  return code;
}

Future<bool> showRecoveryCodes(BuildContext context, List<String> codes) async {
  final t = context.t;
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t.oaRecoveryShown),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(codes.join('\n'), style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: Space.sm),
          Text(t.oaRecoveryBody),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: codes.join('\n'))),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(t.cMfaCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(t.oaConfirmCodes),
        ),
      ],
    ),
  );
  return saved ?? false;
}
