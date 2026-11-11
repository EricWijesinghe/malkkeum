import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'gen/app_localizations.dart';
import 'i18n.dart';

/// Max summary length; matches the server's MAX_TEXT.
const caseSummaryChars = 2000;
const _caseSheetChars = 300;

/// Localized name of a case kind (customer, partner and console use the same labels).
String caseKindLabel(T t, String kind) => switch (kind) {
  'damage' => t.caseKindDamage,
  'loss' => t.caseKindLoss,
  'no_show' => t.caseKindNoShow,
  'safety' => t.caseKindSafety,
  'payment_dispute' => t.caseKindPayment,
  _ => t.caseKindComplaint,
};

/// Localized name of a case status.
String caseStatusLabel(T t, String status) => switch (status) {
  'investigating' => t.caseStatusInvestigating,
  'resolved' => t.caseStatusResolved,
  'rejected' => t.caseStatusRejected,
  _ => t.caseStatusOpen,
};

/// Opens the problem-report form. `kinds` are the server kinds this reporter may file.
/// Returns true when the case was accepted.
Future<bool> showCaseReport(
  BuildContext context, {
  required List<String> kinds,
  required Future<dynamic> Function(String kind, String summary) submit,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CaseReportSheet(kinds: kinds, submit: submit),
  );
  return sent ?? false;
}

/// The report form. An [ApiException] shows an error and keeps what the user typed.
class CaseReportSheet extends StatefulWidget {
  const CaseReportSheet({super.key, required this.kinds, required this.submit});

  final List<String> kinds;
  final Future<dynamic> Function(String kind, String summary) submit;

  @override
  State<CaseReportSheet> createState() => _CaseReportSheetState();
}

class _CaseReportSheetState extends State<CaseReportSheet> {
  final _summary = TextEditingController();
  String? _kind;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final kind = _kind;
    final summary = _summary.text.trim();
    if (kind == null || summary.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = context.t;
    try {
      await widget.submit(kind, summary);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.caseFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.gutter + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.caseReportTitle, style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final kind in widget.kinds)
                ChoiceChip(
                  label: Text(caseKindLabel(t, kind)),
                  selected: _kind == kind,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _summary,
            enabled: !_busy,
            maxLength: _caseSheetChars,
            maxLines: 4,
            decoration: InputDecoration(hintText: t.caseSummaryHint),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: context.colors.danger)),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: _kind == null || _summary.text.trim().isEmpty || _busy
                ? null
                : _send,
            child: Text(t.caseSubmit),
          ),
        ],
      ),
    );
  }
}

/// Emergency numbers and the shop line, from the booking detail's `emergency` list.
class EmergencyContactsCard extends StatelessWidget {
  const EmergencyContactsCard({super.key, required this.contacts});

  final List<dynamic> contacts;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.safetyEmergency, style: context.text.titleSmall),
            for (final c in contacts)
              if (c is Map && c['number'] != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_contactLabel(t, '${c['label']}')),
                  trailing: Text(
                    '${c['number']}',
                    style: context.text.titleMedium,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _contactLabel(T t, String label) => switch (label) {
  'police_fire_emergency' => t.emergencyPolice,
  'fire_rescue' => t.emergencyFire,
  _ => t.emergencyShop,
};
