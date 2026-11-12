import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'confirm_action.dart';

/// Owner-initiated password reset. The server returns a one-time token shown once in a dialog; the
/// owner hands it to the staff member, who redeems it on the sign-in screen.
Future<void> issueStaffPasswordReset(BuildContext context, Json staff) async {
  final t = context.t;
  if (!await confirmAction(context, t.cStaffReset) || !context.mounted) return;
  try {
    final r =
        await context.api.post('/admin/staff/${staff['id']}/password-reset', {})
            as Json;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ResetTokenDialog(token: r['token'] as String),
    );
  } catch (e) {
    if (context.mounted) showToast(context, t.error(e));
  }
}

class _ResetTokenDialog extends StatelessWidget {
  const _ResetTokenDialog({required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.cStaffResetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cStaffResetBody),
          const SizedBox(height: Space.sm),
          SelectableText(
            token,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: token));
            if (context.mounted) showToast(context, t.cMfaCopied);
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(t.cMfaCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cDone),
        ),
      ],
    );
  }
}
