import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';


/// Header that carries the owner's per-request TOTP. The server burns the code, so each owner action
/// asks again.
const ownerTotpHeader = 'X-Owner-Totp';

/// Asks for the owner's own 6-digit code for one owner-only request. Resolves to the code, or null when
/// cancelled.
Future<String?> askOwnerTotp(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _OwnerTotpDialog(),
);

/// Headers for one owner request. Keep the code out of logs and URLs: it travels only in this header.
Map<String, String> ownerHeaders(String code) => {ownerTotpHeader: code};

/// Runs one owner-only request: asks for the code, sends it and toasts [done]. Resolves to the server's
/// answer, or null when the prompt was cancelled or the request failed (the failure is shown).
Future<dynamic> runOwnerAction(
  BuildContext context,
  Future<dynamic> Function(Map<String, String> headers) send, {
  required String done,
}) async {
  final code = await askOwnerTotp(context);
  if (code == null || !context.mounted) return null;
  try {
    final result = await send(ownerHeaders(code));
    if (context.mounted) showToast(context, done);
    return result;
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
    return null;
  }
}

class _OwnerTotpDialog extends StatefulWidget {
  const _OwnerTotpDialog();

  @override
  State<_OwnerTotpDialog> createState() => _OwnerTotpDialogState();
}

class _OwnerTotpDialogState extends State<_OwnerTotpDialog> {
  final _code = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.oaTotpTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.oaTotpBody),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: InputDecoration(
              labelText: t.oaTotpLabel,
              counterText: '',
              errorText: _invalid ? t.oaTotpInvalid : null,
            ),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.oaCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(t.oaContinue)),
      ],
    );
  }
}
