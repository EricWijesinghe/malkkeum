import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';

Future<void> _act(
  BuildContext context,
  Future<void> Function() fn,
  Future<void> Function() reload,
) async {
  try {
    await fn();
    if (context.mounted) showToast(context, context.t.cDone);
    await reload();
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final admin = context.console.isAdmin;
    String label(String s) => switch (s) {
      'verified' => t.cPro_verified,
      'suspended' => t.cPro_suspended,
      _ => t.cPro_pending,
    };
    ServiceHue hue(String s) => switch (s) {
      'verified' => StatusHues.assigned,
      'suspended' => StatusHues.cancelled,
      _ => StatusHues.consultation,
    };
    return AsyncView<List<Json>>(
      load: () async =>
          (await context.api.get('/admin/pros') as List).cast<Json>(),
      builder: (context, rows, reload) => rows.isEmpty
          ? EmptyState(icon: Icons.engineering_rounded, title: t.cNoResults)
          : ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                for (final p in rows)
                  Card(
                    elevation: 0,
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p['team_name']} · ${p['name']}',
                              style: context.text.titleSmall,
                            ),
                          ),
                          Tag(
                            label: label(p['status'] as String),
                            hue: hue(p['status'] as String),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${p['phone']} · ${t.cCompleted} ${p['completed']} · ${t.cCancelledN} ${p['cancelled']} · ${t.cRating} ${p['rating'] ?? '-'} · ${t.cFeeRate} ${(p['fee_bps'] as num) / 100}',
                      ),
                      trailing: !admin
                          ? null
                          : Wrap(
                              spacing: 4,
                              children: [
                                if (p['status'] != 'verified')
                                  FilledButton.tonal(
                                    onPressed: () => _act(
                                      context,
                                      () => context.api.post(
                                        '/admin/pros/${p['id']}/status',
                                        {'status': 'verified'},
                                      ),
                                      reload,
                                    ),
                                    child: Text(t.cVerify),
                                  ),
                                if (p['status'] == 'verified')
                                  OutlinedButton(
                                    onPressed: () => _act(
                                      context,
                                      () => context.api.post(
                                        '/admin/pros/${p['id']}/status',
                                        {'status': 'suspended'},
                                      ),
                                      reload,
                                    ),
                                    child: Text(t.cSuspend),
                                  ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});
  @override
  State<SettlementsScreen> createState() => _SettlementsState();
}

class _SettlementsState extends State<SettlementsScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  String? _state;

  Future<void> _run() async {
    final t = context.t;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: t.cPayoutDate,
    );
    if (date == null || !mounted) return;
    try {
      final lines =
          (await context.api.post('/admin/settlements/run-payouts', {
                    'date': DateFormat('yyyy-MM-dd').format(date),
                  })
                  as List)
              .cast<Json>();
      if (!mounted) return;
      showToast(context, t.cPayoutDone('${lines.length}'));
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.cRunPayouts),
          // Transfer sheet for the bank (or the future bank API): holder, bank, account, amount.
          content: SelectableText(
            lines
                .map(
                  (l) =>
                      '${l['holder']}\t${l['bank']}\t${l['account']}\t${l['total']}',
                )
                .join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.close),
            ),
          ],
        ),
      );
      await _view.currentState?.reload();
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final admin = context.console.isAdmin;
    String stateLabel(String s) => switch (s) {
      'waiting_balance' => t.pS_waiting_balance,
      'pending' => t.pS_pending,
      'paid' => t.pS_paid,
      _ => t.pS_held,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              DropdownButton<String?>(
                value: _state,
                items: [
                  DropdownMenuItem(value: null, child: Text(t.cAllStatus)),
                  for (final s in const [
                    'waiting_balance',
                    'pending',
                    'paid',
                    'held',
                  ])
                    DropdownMenuItem(value: s, child: Text(stateLabel(s))),
                ],
                onChanged: (v) {
                  setState(() => _state = v);
                  _view.currentState?.reload();
                },
              ),
              const Spacer(),
              if (admin)
                FilledButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  label: Text(t.cRunPayouts),
                  onPressed: _run,
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Json>>(
            key: _view,
            load: () async =>
                (await context.api.get(
                          '/admin/settlements',
                          query: {'state': _state},
                        )
                        as List)
                    .cast<Json>(),
            builder: (context, rows, reload) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              children: [
                for (final s in rows)
                  Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text('${s['team_name']} · ${s['number']}'),
                      subtitle: Text(
                        '${t.cNet} ${context.won((s['net'] as num).toInt())} · ${s['payout_date'] ?? '-'}',
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tag(
                            label: stateLabel(s['state'] as String),
                            hue: switch (s['state']) {
                              'paid' => StatusHues.assigned,
                              'pending' => StatusHues.confirmed,
                              'held' => StatusHues.cancelled,
                              _ => StatusHues.consultation,
                            },
                          ),
                          if (admin && s['state'] == 'pending')
                            TextButton(
                              onPressed: () => _act(
                                context,
                                () => context.api.post(
                                  '/admin/settlements/${s['id']}/hold',
                                  {'hold': true},
                                ),
                                reload,
                              ),
                              child: Text(t.cHold),
                            ),
                          if (admin && s['state'] == 'held')
                            TextButton(
                              onPressed: () => _act(
                                context,
                                () => context.api.post(
                                  '/admin/settlements/${s['id']}/hold',
                                  {'hold': false},
                                ),
                                reload,
                              ),
                              child: Text(t.cRelease),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersState();
}

class _CustomersState extends State<CustomersScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: TextField(
            controller: _q,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: t.cSearch,
              isDense: true,
            ),
            onSubmitted: (_) => _view.currentState?.reload(),
          ),
        ),
        Expanded(
          child: AsyncView<List<Json>>(
            key: _view,
            load: () async =>
                (await context.api.get(
                          '/admin/customers',
                          query: {
                            'q': _q.text.trim().isEmpty ? null : _q.text.trim(),
                          },
                        )
                        as List)
                    .cast<Json>(),
            builder: (context, rows, _) => ListView(
              children: [
                for (final c in rows)
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (c['name'] as String).isEmpty
                            ? '?'
                            : (c['name'] as String).characters.first,
                      ),
                    ),
                    title: Text(
                      (c['name'] as String).isEmpty ? '-' : c['name'] as String,
                    ),
                    subtitle: Text(
                      '${c['phone']} · ${t.cJoined} ${dateLabel(DateTime.parse(c['created_at'] as String), context.lang)}',
                    ),
                    trailing: Text(t.cBookingsCount('${c['bookings']}')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffState();
}

class _StaffState extends State<StaffScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();

  Future<void> _add() async {
    final t = context.t;
    final email = TextEditingController();
    final name = TextEditingController();
    final password = TextEditingController();
    var role = 'consultant';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t.cAddStaff),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: t.accountName),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: t.cEmail),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.cPassword,
                  helperText: t.cPasswordRule,
                ),
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'consultant',
                    label: Text(t.cRoleConsultant),
                  ),
                  ButtonSegment(value: 'admin', label: Text(t.cRoleAdmin)),
                ],
                selected: {role},
                onSelectionChanged: (s) => set(() => role = s.first),
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
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final api = context.api;
      await _act(
        context,
        () => api.post('/admin/staff', {
          'email': email.text,
          'name': name.text,
          'role': role,
          'password': password.text,
        }),
        () async => _view.currentState?.reload(),
      );
    }
    disposeAfterClose([email, name, password]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(t.cAddStaff),
      ),
      body: AsyncView<List<Json>>(
        key: _view,
        load: () async =>
            (await context.api.get('/admin/staff') as List).cast<Json>(),
        builder: (context, rows, reload) => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            for (final s in rows)
              ListTile(
                title: Text('${s['name']} · ${s['email']}'),
                subtitle: Text(
                  s['role'] == 'admin' ? t.cRoleAdmin : t.cRoleConsultant,
                ),
                trailing: TextButton(
                  onPressed: () => _act(
                    context,
                    () => context.api.post('/admin/staff/${s['id']}/active', {
                      'active': s['active'] != true,
                    }),
                    reload,
                  ),
                  child: Text(
                    s['active'] == true ? t.cDeactivate : t.cActivate,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
