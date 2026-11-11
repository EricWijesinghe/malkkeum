// Case queue: claims, incidents and disputes. Staff triage, note, assign, reassign a no-show job,
// and settle. Refunds and settlement holds are admin-only (the server refuses them otherwise).

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Statuses a case can move to from [status] (mirrors `safety::can_move` on the server).
List<String> caseNextStatuses(String status) => switch (status) {
  'open' => const ['investigating', 'rejected'],
  'investigating' => const ['resolved', 'rejected'],
  _ => const [],
};

class CaseQueue extends StatefulWidget {
  const CaseQueue({
    super.key,
    required this.fetch,
    required this.detail,
    required this.update,
    required this.reassign,
    required this.isAdmin,
  });

  final Future<List<Json>> Function() fetch;
  final Future<Json> Function(String id) detail;
  final Future<Json> Function(String id, Json body) update;
  final Future<Json> Function(String id, Json body) reassign;
  final bool isAdmin;

  @override
  State<CaseQueue> createState() => _CaseQueueState();
}

class _CaseQueueState extends State<CaseQueue> {
  List<Json>? _rows;
  Json? _open;
  bool _busy = false;
  final _note = TextEditingController();
  final _refund = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _refund.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.fetch();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  Future<void> _select(String id) async {
    try {
      final d = await widget.detail(id);
      if (mounted) setState(() => _open = d);
    } catch (_) {
      if (mounted) showToast(context, context.t.actionFailed);
    }
  }

  /// Runs one action, then refreshes the queue and the open case.
  Future<void> _run(Future<Json> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final d = await action();
      _note.clear();
      if (mounted) setState(() => _open = d);
      await _load();
    } catch (_) {
      if (mounted) showToast(context, context.t.actionFailed);
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
        Text(t.consoleCasesTitle, style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        if (rows.isEmpty) Text(t.consoleCasesEmpty, style: context.text.bodySmall),
        for (final r in rows)
          Card(
            child: ListTile(
              title: Text(caseKindLabel(t, r['kind'] as String)),
              subtitle: Text('${r['booking_number'] ?? '-'} · ${caseStatusLabel(t, r['status'] as String)}'),
              trailing: r['overdue'] == true ? Chip(label: Text(t.caseOverdue)) : null,
              onTap: () => _select(r['id'] as String),
            ),
          ),
        if (_open != null) _Detail(
          data: _open!,
          busy: _busy,
          isAdmin: widget.isAdmin,
          note: _note,
          refund: _refund,
          onStatus: (s) => _run(() => widget.update(_caseId, {'status': s})),
          onNote: () => _run(() => widget.update(_caseId, {'note': _note.text.trim()})),
          onRefund: () => _run(() => widget.update(_caseId, {'refund_amount': int.tryParse(_refund.text) ?? 0})),
          onHold: (hold) => _run(() => widget.update(_caseId, {'hold_settlement': hold})),
          onReassign: () => _run(() => widget.reassign(_caseId, const {})),
        ),
      ],
    );
  }

  String get _caseId => (_open!['case'] as Json)['id'] as String;
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.data,
    required this.busy,
    required this.isAdmin,
    required this.note,
    required this.refund,
    required this.onStatus,
    required this.onNote,
    required this.onRefund,
    required this.onHold,
    required this.onReassign,
  });

  final Json data;
  final bool busy;
  final bool isAdmin;
  final TextEditingController note;
  final TextEditingController refund;
  final void Function(String status) onStatus;
  final VoidCallback onNote;
  final VoidCallback onRefund;
  final void Function(bool hold) onHold;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = data['case'] as Json;
    final booking = data['booking'] as Json?;
    final status = c['status'] as String;
    final notes = (data['notes'] as List? ?? const []).cast<Json>();
    final checkedIn = booking?['checked_in_at'] as String?;
    final checkedOut = booking?['checked_out_at'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${caseKindLabel(t, c['kind'] as String)} · ${caseStatusLabel(t, status)}', style: context.text.labelLarge),
            Text(c['summary'] as String, style: context.text.bodyMedium),
            if (checkedIn != null) Text(t.checkedInAt(_hm(checkedIn)), style: context.text.bodySmall),
            if (checkedOut != null) Text(t.checkedOutAt(_hm(checkedOut)), style: context.text.bodySmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final next in caseNextStatuses(status))
                  OutlinedButton(onPressed: busy ? null : () => onStatus(next), child: Text(caseStatusLabel(t, next))),
                if (c['kind'] == 'no_show' && booking != null)
                  OutlinedButton(onPressed: busy ? null : onReassign, child: Text(t.caseReassign)),
              ],
            ),
            if (isAdmin && c['booking_id'] != null) ...[
              const SizedBox(height: Space.xs),
              Row(children: [
                Expanded(child: TextField(controller: refund, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.caseRefund))),
                const SizedBox(width: Space.xs),
                OutlinedButton(onPressed: busy ? null : onRefund, child: Text(t.caseRefund)),
                const SizedBox(width: Space.xs),
                OutlinedButton(onPressed: busy ? null : () => onHold(true), child: Text(t.caseHold)),
              ]),
            ],
            const SizedBox(height: Space.xs),
            for (final n in notes) Text('· ${n['author'] ?? '-'}: ${n['body']}', style: context.text.bodySmall),
            Row(children: [
              Expanded(child: TextField(controller: note, decoration: InputDecoration(labelText: t.caseNoteHint))),
              TextButton(onPressed: busy ? null : onNote, child: Text(t.caseSave)),
            ]),
          ],
        ),
      ),
    );
  }

  String _hm(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
