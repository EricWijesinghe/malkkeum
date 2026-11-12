import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// On-site steps for the assigned partner: check-in and check-out, the door code (visit day only),
/// an incident report, and emergency numbers. The server enforces the same rules; the UI hides
/// what cannot work today.
class SiteActionsCard extends StatelessWidget {
  const SiteActionsCard({super.key, required this.raw, required this.act});

  /// The job's booking JSON from `GET /partner/jobs/{id}`.
  final Json raw;

  /// Runs a request, shows the toast and reloads the job (same helper as the job screen).
  final Future<void> Function(Future<void> Function() fn, String done) act;

  bool get _isToday {
    final d = Booking(raw).visitDate;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = Booking(raw);
    final id = b.id;
    final active = b.status == 2 && _isToday;
    final checkedIn = b.checkedInAt != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checkedIn) Text(t.checkedInAt(TimeOfDay.fromDateTime(b.checkedInAt!.toLocal()).format(context)), style: context.text.bodySmall),
          if (b.checkedOutAt != null) Text(t.checkedOutAt(TimeOfDay.fromDateTime(b.checkedOutAt!.toLocal()).format(context)), style: context.text.bodySmall),
          if (active && !checkedIn)
            FilledButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: Text(t.checkInAction),
              onPressed: () => act(() => context.api.post('/partner/jobs/$id/check-in'), t.checkInAction),
            ),
          if (active && checkedIn && b.checkedOutAt == null)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.logout_rounded),
              label: Text(t.checkOutAction),
              onPressed: () => act(() => context.api.post('/partner/jobs/$id/check-out'), t.checkOutAction),
            ),
          if (b.entryCodeSet)
            OutlinedButton.icon(
              icon: const Icon(Icons.dialpad_rounded),
              label: Text(_isToday ? t.entryCodeAction : t.entryCodeNotToday),
              onPressed: _isToday ? () => _showEntryCode(context, id) : null,
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(t.caseReportAction),
            onPressed: () => showCaseReport(
              context,
              kinds: const ['damage', 'loss', 'complaint', 'safety'],
              submit: (kind, summary) => context.api.post('/partner/jobs/$id/cases', {'kind': kind, 'summary': summary}),
            ),
          ),
          const SizedBox(height: Space.sm),
          EmergencyContactsCard(contacts: b.emergency),
        ],
      ),
    );
  }

  Future<void> _showEntryCode(BuildContext context, String id) async {
    final t = context.t;
    final String? code;
    try {
      final res = await context.api.get('/partner/jobs/$id/entry-code') as Json;
      code = res['entry_code'] as String?;
    } catch (_) {
      if (context.mounted) showToast(context, t.actionFailed);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.entryCodeTitle),
        content: SelectableText(code ?? t.entryCodeEmpty, style: ctx.text.headlineSmall),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(MaterialLocalizations.of(ctx).okButtonLabel))],
      ),
    );
  }
}
