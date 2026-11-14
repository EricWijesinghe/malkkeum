import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

/// Request header the server reads the owner's authenticator code from (routes/keys.rs owner_gate).
const ownerTotpHeader = 'X-Owner-Totp';

/// Asks the owner for the 6-digit authenticator code before a Toss payout change. Null when cancelled.
Future<String?> askOwnerCode(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _OwnerCodeDialog(),
    );

class _OwnerCodeDialog extends StatefulWidget {
  const _OwnerCodeDialog();

  @override
  State<_OwnerCodeDialog> createState() => _OwnerCodeDialogState();
}

class _OwnerCodeDialogState extends State<_OwnerCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _complete => RegExp(r'^\d{6}$').hasMatch(_code.text);

  void _submit() {
    if (_complete) Navigator.of(context).pop(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.cOwnerCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cOwnerCodeBody),
          const SizedBox(height: Space.md),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t.cOwnerCodeField),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _complete ? _submit : null,
          child: Text(t.cOwnerCodeConfirm),
        ),
      ],
    );
  }
}
