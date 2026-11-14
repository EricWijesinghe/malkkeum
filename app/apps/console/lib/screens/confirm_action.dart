import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Asks before a destructive action. [action] names both the title and the confirm button, so the owner
/// sees exactly what they are agreeing to. Resolves false when cancelled or dismissed.
Future<bool> confirmAction(BuildContext context, String action, {String? message}) async {
  final t = context.t;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(action),
      content: Text(message ?? t.cConfirmAsk),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
