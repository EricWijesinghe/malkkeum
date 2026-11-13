// Activity log: who did what and when, newest first. Read-only for the owner; the server refuses
// anyone who is not the owner. Recorded details are shown as plain text.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Period chips. Days are Seoul calendar days, as the server reads them.
enum AuditPeriod { today, week, month, all }

/// Query for [period] as of [nowUtc]. Both ends are Seoul days, inclusive; `all` sends neither.
Map<String, String?> auditPeriodQuery(AuditPeriod period, DateTime nowUtc) {
  final seoul = nowUtc.add(const Duration(hours: 9));
  final today = DateTime.utc(seoul.year, seoul.month, seoul.day);
  final back = switch (period) {
    AuditPeriod.today => 0,
    AuditPeriod.week => 6,
    AuditPeriod.month => 29,
    AuditPeriod.all => -1,
  };
  if (back < 0) return const {};
  final from = today.subtract(Duration(days: back));
  return {'from': _day(from), 'to': _day(today)};
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// `yyyy.MM.dd HH:mm` in Seoul time for an ISO timestamp from the server; the raw text if unparsable.
String auditStamp(String iso) {
  final utc = DateTime.tryParse(iso)?.toUtc();
  if (utc == null) return iso;
  final k = utc.add(const Duration(hours: 9));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${k.year}.${two(k.month)}.${two(k.day)} ${two(k.hour)}:${two(k.minute)}';
}

/// Plain-language label for an action code. Unknown codes read as "other"; the code stays in details.
String auditActionLabel(T t, String action) => switch (action) {
  'case.refund' => t.audActCaseRefund,
  'case.update' => t.audActCaseUpdate,
  'points.adjust' => t.audActPointsAdjust,
  'customer.pii_view' => t.audActPiiView,
  'customer.pii_list' => t.audActPiiList,
  'staff.create' => t.audActStaffCreate,
  'staff.active' => t.audActStaffActive,
  'settlement.hold' => t.audActSettlementHold,
  'service.update' => t.audActServiceUpdate,
  _ => t.audOtherAction,
};

String _roleLabel(T t, String role) => switch (role) {
  'staff' => t.audRoleStaff,
  'customer' => t.audRoleCustomer,
  'pro' => t.audRolePro,
  'system' => t.audRoleSystem,
  _ => role,
};

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  Pager<Json>? _pager;
  AuditPeriod _period = AuditPeriod.week;
  String? _role;
  String? _prefix;

  Map<String, String?> _query() => {
    ...auditPeriodQuery(_period, DateTime.now().toUtc()),
    'actor_role': _role,
    'action': _prefix,
  };

  void _reload() => _view.currentState?.reload();

  void _set(VoidCallback change) {
    setState(change);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    _pager ??= Pager<Json>(context.api, '/admin/audit', (row) => row, query: _query);
    final pager = _pager!;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Text(t.cAudit, style: context.text.headlineMedium),
        const SizedBox(height: Space.xs),
        Text(t.audIntro, style: context.text.bodyMedium),
        const SizedBox(height: Space.md),
        _Filters(
          period: _period,
          role: _role,
          prefix: _prefix,
          onPeriod: (p) => _set(() => _period = p),
          onRole: (r) => _set(() => _role = r),
          onPrefix: (p) => _set(() => _prefix = p),
        ),
        const SizedBox(height: Space.md),
        AsyncView<List<Json>>(
          key: _view,
          load: pager.first,
          builder: (context, _, _) => LoadMore<Json>(
            pager: pager,
            builder: (context, rows) => _Rows(rows: rows),
          ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.period,
    required this.role,
    required this.prefix,
    required this.onPeriod,
    required this.onRole,
    required this.onPrefix,
  });

  final AuditPeriod period;
  final String? role;
  final String? prefix;
  final ValueChanged<AuditPeriod> onPeriod;
  final ValueChanged<String?> onRole;
  final ValueChanged<String?> onPrefix;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final periods = {
      AuditPeriod.today: t.audPeriodToday,
      AuditPeriod.week: t.audPeriod7,
      AuditPeriod.month: t.audPeriod30,
      AuditPeriod.all: t.audPeriodAll,
    };
    final roles = ['staff', 'customer', 'pro', 'system'];
    final prefixes = <String?, String>{
      null: t.audWhatAll,
      'case.': t.audCatCase,
      'booking.': t.audCatBooking,
      'customer.': t.audCatCustomer,
      'staff.': t.audCatStaff,
      'settlement.': t.audCatSettlement,
      'points.': t.audCatPoints,
      'service.': t.audCatService,
    };
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final e in periods.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: period == e.key,
            onSelected: (_) => onPeriod(e.key),
          ),
        DropdownButton<String?>(
          value: role,
          items: [
            DropdownMenuItem(value: null, child: Text('${t.audFilterWho}: ${t.audWhoAll}')),
            for (final r in roles)
              DropdownMenuItem(value: r, child: Text('${t.audFilterWho}: ${_roleLabel(t, r)}')),
          ],
          onChanged: onRole,
        ),
        DropdownButton<String?>(
          value: prefix,
          items: [
            for (final e in prefixes.entries)
              DropdownMenuItem(value: e.key, child: Text('${t.audFilterWhat}: ${e.value}')),
          ],
          onChanged: onPrefix,
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<Json> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (rows.isEmpty) return EmptyState(icon: Icons.history_rounded, title: t.audEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) _RowTile(row: row),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});

  final Json row;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final role = row['actor_role'] as String? ?? '';
    final name = row['actor_name'] as String?;
    final who = name ?? (role == 'system' ? t.audRoleSystem : t.audUnknownActor);
    final action = row['action'] as String? ?? '';
    return ListTile(
      title: Text(auditActionLabel(t, action)),
      subtitle: Text('$who · ${auditStamp(row['created_at'] as String? ?? '')}'),
      onTap: () => _showDetail(context, row),
    );
  }

  Future<void> _showDetail(BuildContext context, Json row) {
    final t = context.t;
    final action = row['action'] as String? ?? '';
    final data = row['data_text'] as String? ?? '';
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.audDetailTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auditActionLabel(t, action), style: ctx.text.titleMedium),
              const SizedBox(height: Space.sm),
              Text('${t.audActionCode}: $action'),
              Text('${t.audTarget}: ${row['target'] ?? ''}'),
              const SizedBox(height: Space.sm),
              SelectableText(data.isEmpty ? t.audNoDetail : data),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.audClose)),
        ],
      ),
    );
  }
}
