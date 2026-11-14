// Customer rights requests: find a customer by phone, give them a copy of their data (CSV), or delete the
// account (admins only, phone typed again). Every request is listed below with its outcome.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../download.dart';
import '../state.dart';

class PrivacyRequestsScreen extends StatefulWidget {
  const PrivacyRequestsScreen({super.key});

  @override
  State<PrivacyRequestsScreen> createState() => _PrivacyRequestsState();
}

class _PrivacyRequestsState extends State<PrivacyRequestsScreen> {
  final _phone = TextEditingController();
  List<Json>? _found;
  List<Json>? _log;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadLog() async {
    try {
      final rows = (await context.api.get('/admin/privacy/requests') as List)
          .cast<Json>();
      if (mounted) setState(() => _log = rows);
    } on ApiException {
      if (mounted) showToast(context, context.t.prqFailed);
    }
  }

  /// Runs one request. Every call is refreshed afterwards, so the log shows the outcome even on failure.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException {
      if (mounted) showToast(context, context.t.prqFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _loadLog();
    }
  }

  Future<void> _find() => _run(() async {
    final rows =
        (await context.api.get(
                  '/admin/privacy/customers',
                  query: {'phone': _phone.text.trim()},
                )
                as List)
            .cast<Json>();
    if (mounted) setState(() => _found = rows);
  });

  Future<void> _export(String id) => _run(() async {
    final bytes = await context.api.getBytes(
      '/admin/privacy/customers/$id/export',
      query: {'format': 'csv'},
    );
    final saved = await saveCsv(bytes, 'malkkeum-customer-$id.csv');
    if (mounted) {
      showToast(
        context,
        saved ? context.t.prqExported : context.t.fDownloadWebOnly,
      );
    }
  });

  Future<void> _delete(Json customer) async {
    final typed = await _askPhone(customer['phone'] as String);
    if (typed == null) return;
    await _run(() async {
      await context.api.post(
        '/admin/privacy/customers/${customer['id']}/delete',
        {'phone': typed},
        ApiClient.newIdempotencyKey(),
      );
      if (mounted) {
        setState(() => _found = null);
        showToast(context, context.t.prqDeleteDone);
      }
    });
  }

  /// Asks for the customer's phone again. Null when cancelled or the digits do not match.
  Future<String?> _askPhone(String expected) async {
    final t = context.t;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.prqDelete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.prqDeleteAsk),
            const SizedBox(height: Space.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.prqPhoneAgain),
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
            child: Text(t.prqDelete),
          ),
        ],
      ),
    );
    final typed = controller.text.trim();
    controller.dispose();
    if (ok != true) return null;
    if (!samePhoneDigits(typed, expected)) {
      if (mounted) showToast(context, t.prqPhoneMismatch);
      return null;
    }
    return typed;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Text(t.prqTitle, style: context.text.headlineMedium),
        const SizedBox(height: Space.xs),
        Text(t.prqIntro, style: context.text.bodySmall),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.prqPhone,
                  isDense: true,
                ),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: Space.sm),
            FilledButton(
              onPressed: _busy ? null : _find,
              child: Text(t.prqFind),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        if (_found != null && _found!.isEmpty)
          Text(t.prqNotFound, style: context.text.bodyMedium),
        for (final c in _found ?? const <Json>[]) _customerCard(c),
        const Divider(height: Space.xxl),
        Text(t.prqLog, style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        ..._logRows(),
      ],
    );
  }

  Widget _customerCard(Json c) {
    final t = context.t;
    final id = c['id'] as String;
    final name = (c['name'] as String).isEmpty ? '-' : c['name'] as String;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name · ${c['phone']}', style: context.text.labelLarge),
            Text(
              '${t.prqBookings} ${c['bookings']}',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _export(id),
                  child: Text(t.prqExport),
                ),
                FilledButton(
                  onPressed: _busy || !context.console.isAdmin
                      ? null
                      : () => _delete(c),
                  child: Text(t.prqDelete),
                ),
              ],
            ),
            if (!context.console.isAdmin)
              Text(t.prqDeleteAdminOnly, style: context.text.labelSmall),
          ],
        ),
      ),
    );
  }

  List<Widget> _logRows() {
    final t = context.t;
    final rows = _log;
    if (rows == null) return const [CircularProgressIndicator()];
    if (rows.isEmpty) {
      return [Text(t.prqLogEmpty, style: context.text.bodySmall)];
    }
    return [
      for (final r in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${r['kind'] == 'delete' ? t.prqKindDelete : t.prqKindExport} · ${r['status'] == 'done' ? t.prqStatusDone : t.prqStatusFailed}',
          ),
          subtitle: Text(
            '${t.prqBy}: ${r['staff_name'] ?? '-'} · ${dateLabel(DateTime.parse(r['created_at'] as String), context.lang)}',
          ),
        ),
    ];
  }
}

/// Whether two phone numbers have the same digits, so "010-1234-5678" matches "01012345678".
bool samePhoneDigits(String typed, String stored) {
  String digits(String s) => s.replaceAll(RegExp(r'\D'), '');
  final want = digits(stored);
  return want.isNotEmpty && digits(typed) == want;
}
