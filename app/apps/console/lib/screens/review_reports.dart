// Reported reviews waiting for a staff decision: keep, hide, or delete the review, and optionally
// restrict its author from posting reviews. The server writes an audit row for each action.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class ReviewReportQueue extends StatefulWidget {
  const ReviewReportQueue({
    super.key,
    required this.fetch,
    required this.decide,
    required this.setAuthorBlocked,
  });

  final Future<List<Json>> Function() fetch;

  /// action: keep | hide | delete
  final Future<void> Function(String bookingId, String action) decide;
  final Future<void> Function(String bookingId, bool blocked) setAuthorBlocked;

  @override
  State<ReviewReportQueue> createState() => _ReviewReportQueueState();
}

class _ReviewReportQueueState extends State<ReviewReportQueue> {
  List<Json>? _rows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.fetch();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (_) {
      if (mounted) showToast(context, context.t.modFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rows = _rows;
    if (rows == null) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.modTitle, style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        if (rows.isEmpty) Text(t.modEmpty, style: context.text.bodySmall),
        for (final r in rows)
          _ReportCard(
            row: r,
            busy: _busy,
            onAction: (action) =>
                _run(() => widget.decide(r['booking_id'] as String, action)),
            onBlock: () => _run(
              () => widget.setAuthorBlocked(
                r['booking_id'] as String,
                r['author_blocked'] != true,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.row,
    required this.busy,
    required this.onAction,
    required this.onBlock,
  });

  final Json row;
  final bool busy;
  final void Function(String action) onAction;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final reports = (row['reports'] as List? ?? const []).cast<Json>();
    final blocked = row['author_blocked'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '★${row['rating']}  ${row['customer_name']} · ${row['pro_name'] ?? ''}',
              style: context.text.labelLarge,
            ),
            if ((row['body'] as String? ?? '').isNotEmpty)
              Text(row['body'] as String, style: context.text.bodyMedium),
            if (row['hidden'] == true)
              Text(t.modHidden, style: context.text.labelSmall),
            Text(
              t.modReports('${reports.length}'),
              style: context.text.labelMedium,
            ),
            for (final rep in reports)
              Text(
                '· ${reviewReportLabel(t, rep['reason'] as String)}${(rep['note'] as String? ?? '').isEmpty ? '' : ': ${rep['note']}'}',
                style: context.text.bodySmall,
              ),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => onAction('keep'),
                  child: Text(t.modKeep),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => onAction('hide'),
                  child: Text(t.modHide),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => onAction('delete'),
                  child: Text(t.modDelete),
                ),
                TextButton(
                  onPressed: busy ? null : onBlock,
                  child: Text(blocked ? t.modUnblockAuthor : t.modBlockAuthor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
