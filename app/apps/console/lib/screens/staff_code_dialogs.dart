import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

/// How a one-time staff code leaves the console: a text to the staff member, or shown once to copy by hand.
class CodeDelivery {
  const CodeDelivery(this.channel, this.phone);
  final String channel;
  final String? phone;
}

/// Asks how to send the code. Shows a phone field when the staff member has no number on file yet.
Future<CodeDelivery?> pickCodeDelivery(
  BuildContext context, {
  required bool needsPhone,
}) async {
  final t = context.t;
  final phone = TextEditingController();
  var channel = 'sms';
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(t.cStaffChannel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsPhone) ...[
              Text(t.cStaffPhoneNeeded),
              const SizedBox(height: Space.sm),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.cStaffPhone),
              ),
              const SizedBox(height: Space.sm),
            ],
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'sms', label: Text(t.cStaffChannelSms)),
                ButtonSegment(value: 'copy', label: Text(t.cStaffChannelCopy)),
              ],
              selected: {channel},
              onSelectionChanged: (s) => set(() => channel = s.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.cStaffSendCode),
          ),
        ],
      ),
    ),
  );
  final entered = phone.text.trim();
  disposeAfterClose([phone]);
  if (send != true) return null;
  return CodeDelivery(
    channel,
    needsPhone && entered.isNotEmpty ? entered : null,
  );
}

/// After the server issues a code: shows it once when it was handed back (copy channel), else confirms the text.
Future<void> showSentCode(
  BuildContext context,
  Json reply,
  String title,
) async {
  final t = context.t;
  final code = reply['code'];
  if (code is! String) {
    showToast(context, t.cStaffSentSms);
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CodeDialog(title: title, code: code),
  );
}

class _CodeDialog extends StatelessWidget {
  const _CodeDialog({required this.title, required this.code});
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cStaffCodeBody),
          const SizedBox(height: Space.sm),
          SelectableText(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 24),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
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
