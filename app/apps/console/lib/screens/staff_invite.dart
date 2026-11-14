import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'staff_code_dialogs.dart';

/// Invites a staff member: name, email, mobile and role, then a one-time code by SMS or copied by hand.
/// Only admins are offered the admin role; the server enforces the same rule.
Future<void> inviteStaff(
  BuildContext context,
  Future<void> Function() reload,
) async {
  final t = context.t;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  var role = 'consultant';
  var channel = 'sms';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(t.cStaffInviteTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.cStaffInviteBody),
              const SizedBox(height: Space.sm),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: t.cName),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: t.cEmail),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.cStaffPhone),
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'consultant',
                    label: Text(t.cRoleConsultant),
                  ),
                  if (context.console.isAdmin)
                    ButtonSegment(value: 'admin', label: Text(t.cRoleAdmin)),
                ],
                selected: {role},
                onSelectionChanged: (s) => set(() => role = s.first),
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'sms',
                    label: Text(t.cStaffChannelSms),
                  ),
                  ButtonSegment(
                    value: 'copy',
                    label: Text(t.cStaffChannelCopy),
                  ),
                ],
                selected: {channel},
                onSelectionChanged: (s) => set(() => channel = s.first),
              ),
            ],
          ),
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
  final body = {
    'name': name.text,
    'email': email.text,
    'phone': phone.text,
    'role': role,
    'channel': channel,
  };
  disposeAfterClose([name, email, phone]);
  if (ok == true && context.mounted) {
    await _send(context, reload, body);
  }
}

Future<void> _send(
  BuildContext context,
  Future<void> Function() reload,
  Json body,
) async {
  try {
    final r = await context.api.post('/admin/staff/invite', body) as Json;
    if (!context.mounted) return;
    await showSentCode(context, r, context.t.cStaffCodeTitle);
    await reload();
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}
