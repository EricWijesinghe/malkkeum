import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'confirm_action.dart';
import 'payout_seller_dialog.dart';

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
                                    onPressed: () async {
                                      if (!await confirmAction(context, t.cSuspend) || !context.mounted) return;
                                      await _act(
                                        context,
                                        () => context.api.post(
                                          '/admin/pros/${p['id']}/status',
                                          {'status': 'suspended'},
                                        ),
                                        reload,
                                      );
                                    },
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
  const SettlementsScreen({super.key, this.initialPayouts = false});
  final bool initialPayouts;
  @override
  State<SettlementsScreen> createState() => _SettlementsState();
}

class _SettlementsState extends State<SettlementsScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  String? _state;
  late bool _payouts = widget.initialPayouts;
  final _payoutsView = GlobalKey<AsyncViewState<List<Json>>>();

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
      final rows =
          (await context.api.post('/admin/settlements/run-payouts', {
                    'date': DateFormat('yyyy-MM-dd').format(date),
                  })
                  as List)
              .cast<Json>();
      if (!mounted) return;
      showToast(context, t.poRequestedToast('${rows.length}'));
      // A new tab mounts and loads its own list, so no reload is needed here.
      setState(() => _payouts = true);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  Widget _payoutList(BuildContext context, bool admin) {
    final t = context.t;
    return AsyncView<List<Json>>(
      key: _payoutsView,
      load: () async => (await context.api.get('/admin/settlements/payouts') as List).cast<Json>(),
      builder: (context, rows, reload) => rows.isEmpty
          ? EmptyState(icon: Icons.payments_rounded, title: t.poNoPayouts, hue: StatusHues.consultation)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              children: [for (final p in rows) _payoutCard(context, p, admin, reload)],
            ),
    );
  }

  Widget _payoutCard(BuildContext context, Json p, bool admin, Future<void> Function() reload) {
    final t = context.t;
    final id = p['id'] as String;
    final state = p['state'] as String;
    final manual = p['provider'] == 'manual';
    final team = (p['team_name'] as String? ?? '').isEmpty ? '' : ' · ${p['team_name']}';
    final failure = p['failure_reason'] == null ? '' : '\n${p['failure_reason']}';
    Future<void> post(String path) => _act(context, () => context.api.post('/admin/settlements/payouts/$id/$path', {}), reload);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p['pro_name']}$team · ${p['bank']} ${p['account_last4']}', style: context.text.titleSmall),
            const SizedBox(height: Space.xxs),
            Text(
              '${context.won((p['amount'] as num).toInt())} · ${p['payout_date']} · ${manual ? t.poProviderManual : t.poProviderToss}$failure',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.xs),
            // Actions wrap under the text: a trailing row overflowed narrow phones at large text.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
              Tag(
                label: switch (state) {
                  'requested' => t.poState_requested,
                  'sent' => t.poState_sent,
                  'paid' => t.poState_paid,
                  _ => t.poState_failed,
                },
                hue: switch (state) {
                  'paid' => StatusHues.assigned,
                  'sent' => StatusHues.confirmed,
                  'failed' => StatusHues.cancelled,
                  _ => StatusHues.consultation,
                },
              ),
              if (admin && state == 'requested' && manual)
                TextButton(onPressed: () => _showAccount(context, id), child: Text(t.poShowAccount)),
              if (admin && state == 'requested' && manual) TextButton(onPressed: () => post('confirm'), child: Text(t.poConfirmPaid)),
              if (admin && state == 'requested' && !manual) TextButton(onPressed: () => post('send'), child: Text(t.poSend)),
              if (admin && state == 'sent') TextButton(onPressed: () => post('sync'), child: Text(t.poSync)),
              if (admin && state == 'failed') TextButton(onPressed: () => post('retry'), child: Text(t.poRetry)),
              if (admin && state == 'requested') TextButton(onPressed: () => _fail(context, id, reload), child: Text(t.poMarkFailed)),
              if (admin && !manual && (state == 'requested' || state == 'failed'))
                TextButton(onPressed: () => _seller(context, p['pro_id'] as String), child: Text(t.poSellerAction)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Toss needs the partner registered as a seller before it can send money. Re-registering is safe after an account change.
  Future<void> _seller(BuildContext context, String proId) async {
    final status = await showTossSellerDialog(context, proId);
    if (status != null && context.mounted) showToast(context, context.t.poSellerDone(status));
  }

  /// Bank details for a manual transfer. Each reveal is audit-logged on the server.
  Future<void> _showAccount(BuildContext context, Object id) async {
    final t = context.t;
    try {
      final a = (await context.api.get('/admin/settlements/payouts/$id/account')) as Json;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.poAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(t.poAccountBody(a['holder'] as String, a['bank'] as String, a['account'] as String, '${a['amount']}')),
              const SizedBox(height: Space.sm),
              Text(t.poRevealNote, style: ctx.text.bodySmall),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.close))],
        ),
      );
    } catch (e) {
      if (context.mounted) showToast(context, t.error(e));
    }
  }

  Future<void> _fail(BuildContext context, Object id, Future<void> Function() reload) async {
    final t = context.t;
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.poReasonTitle),
        content: TextField(controller: c, decoration: InputDecoration(hintText: t.poReasonHint)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.close)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: Text(t.poMarkFailed)),
        ],
      ),
    );
    c.dispose();
    if (reason == null || !context.mounted) return;
    if (reason.isEmpty) {
      showToast(context, t.poReasonRequired);
      return;
    }
    await _act(context, () => context.api.post('/admin/settlements/payouts/$id/fail', {'reason': reason}), reload);
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
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(t.poTabSettlements)),
                  ButtonSegment(value: true, label: Text(t.poTabPayouts)),
                ],
                selected: {_payouts},
                onSelectionChanged: (s) => setState(() => _payouts = s.first),
              ),
              if (!_payouts)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DropdownButton<String?>(
                isExpanded: true,
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
              ),
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
          child: _payouts
              ? _payoutList(context, admin)
              : AsyncView<List<Json>>(
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
                  onPressed: () async {
                    // Only deactivation needs a confirm; reactivating is harmless.
                    final deactivating = s['active'] == true;
                    if (deactivating && !await confirmAction(context, t.cDeactivate)) return;
                    if (!context.mounted) return;
                    await _act(
                      context,
                      () => context.api.post('/admin/staff/${s['id']}/active', {'active': !deactivating}),
                      reload,
                    );
                  },
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
