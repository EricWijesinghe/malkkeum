import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'gen/app_localizations.dart';
import 'i18n.dart';

/// Reasons the server accepts (`POST /reviews/{booking}/report`), in display order.
const reviewReportReasons = ['spam', 'offensive', 'personal_info', 'other'];

/// Max note length; matches the server's REPORT_NOTE_CHARS.
const reviewReportNoteChars = 300;

/// Localized name of a report reason (also used by the console queue).
String reviewReportLabel(T t, String reason) => switch (reason) {
  'spam' => t.reportReasonSpam,
  'offensive' => t.reportReasonOffensive,
  'personal_info' => t.reportReasonPersonal,
  _ => t.reportReasonOther,
};

/// Store rule (Google Play UGC, App Store 1.2): every public review can be reported in the app.
/// Returns true when the report was accepted.
Future<bool> showReviewReport(BuildContext context, {required String bookingId}) async {
  final api = context.api;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReviewReportSheet(
      bookingId: bookingId,
      submit: (reason, note) => api.post('/reviews/$bookingId/report', {'reason': reason, 'note': note}),
    ),
  );
  return sent ?? false;
}

/// Report action for one review card. Shows a thank-you snackbar after a successful report.
class ReviewReportButton extends StatelessWidget {
  const ReviewReportButton({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final sent = await showReviewReport(context, bookingId: bookingId);
        if (sent && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.reportThanks)));
        }
      },
      child: Text(context.t.reportAction),
    );
  }
}

/// The report form. `submit` sends the report; an [ApiException] shows an error and keeps the form.
class ReviewReportSheet extends StatefulWidget {
  const ReviewReportSheet({super.key, required this.bookingId, required this.submit});

  final String bookingId;
  final Future<dynamic> Function(String reason, String note) submit;

  @override
  State<ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ReviewReportSheetState extends State<ReviewReportSheet> {
  final _note = TextEditingController();
  String? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = context.t;
    try {
      await widget.submit(reason, _note.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'already_reported' ? t.reportAlready : t.reportFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.reportSheetTitle, style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final reason in reviewReportReasons)
                ChoiceChip(
                  label: Text(reviewReportLabel(t, reason)),
                  selected: _reason == reason,
                  onSelected: _busy ? null : (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _note,
            maxLength: reviewReportNoteChars,
            maxLines: 3,
            enabled: !_busy,
            decoration: InputDecoration(hintText: t.reportNoteHint),
          ),
          if (_error != null) Text(_error!, style: context.text.bodySmall),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: _reason == null || _busy ? null : _send,
            child: Text(t.reportSubmit),
          ),
        ],
      ),
    );
  }
}
