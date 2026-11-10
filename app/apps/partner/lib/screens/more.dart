import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'chat.dart';
import 'earnings.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  void _go(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    final deps = Deps.of(context);
    final rating = pro.profile['rating'];
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(t.tabMore, style: context.text.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          AppCard(
            color: context.colors.ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pro.name} · ${pro.teamName}',
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.surface,
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(
                  t.pPendingPayout,
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                Text(
                  context.won(pro.pendingPayout),
                  style: context.text.displaySmall?.copyWith(
                    color: context.colors.surface,
                  ),
                ),
                TextButton(
                  onPressed: () => _go(context, const EarningsScreen()),
                  child: Text(
                    '${t.pEarnings} ›',
                    style: TextStyle(color: context.colors.fresh),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.star_rounded, color: context.colors.sun),
                  title: Text(t.pReviews),
                  trailing: Text(rating == null ? '-' : '$rating'),
                  onTap: () => _go(context, const ReviewsScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.map_rounded),
                  title: Text(t.pServicesAreas),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _go(context, const AreasScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(t.pWorkSchedule),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _go(context, const WorkScheduleScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_rounded),
                  title: Text(t.pPayoutAccount),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _go(context, const PayoutAccountScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text(t.pTeam),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _go(context, const TeamScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: Text(t.pNotifications),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _go(context, const NotifyScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(t.pChatOps),
                  onTap: () => openOpsThread(context, topic: 'other'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(t.moreLanguage),
                  trailing: DropdownButton<String?>(
                    value: deps.locale.locale?.languageCode,
                    underline: const SizedBox(),
                    items: [
                      for (final (c, n) in [
                        (null, t.langSystem),
                        for (final e in LocaleController.names.entries)
                          (e.key, e.value),
                      ])
                        DropdownMenuItem(value: c, child: Text(n)),
                    ],
                    onChanged: (c) async {
                      await deps.locale.set(c == null ? null : Locale(c));
                      // Server-side messages (push, SMS) follow the account language too.
                      if (deps.session.role != 'member') {
                        deps.app.api.patch('/partner/me', {'locale': deps.locale.effectiveCode}).ignore();
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: Text(t.themeTitle),
                  trailing: DropdownButton<ThemeMode>(
                    value: deps.theme.mode,
                    underline: const SizedBox(),
                    items: [
                      for (final m in ThemeMode.values)
                        DropdownMenuItem(
                          value: m,
                          child: Text(t.themeLabel(m)),
                        ),
                    ],
                    onChanged: (m) => m == null ? null : deps.theme.set(m),
                  ),
                ),
                ListTile(
                  title: Text(
                    t.moreVersion('1.0.0'),
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: deps.session.logout, child: Text(t.logout)),
          TextButton(
            onPressed: () => _deleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: Text(t.deleteAccount),
          ),
        ],
      ),
    );
  }

  /// Account deletion (App Store 5.1.1(v)). The server refuses while a job is assigned or a
  /// payout is still owed, and says which.
  Future<void> _deleteAccount(BuildContext context) async {
    final t = context.t;
    final deps = Deps.read(context);
    final ok = await showAppSheet<bool>(
      context,
      title: t.deleteAccount,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.pDeleteAccountBody, style: ctx.text.bodyMedium),
            const SizedBox(height: Space.xl),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.deleteAccount),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await deps.app.api.delete('/partner/me');
      await deps.session.clear();
    } catch (e) {
      if (context.mounted) showToast(context, t.error(e));
    }
  }
}

String settlementLabel(T t, String s) => switch (s) {
  'waiting_balance' => t.pS_waiting_balance,
  'pending' => t.pS_pending,
  'paid' => t.pS_paid,
  _ => t.pS_held,
};

class SettlementsScreen extends StatelessWidget {
  const SettlementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pSettlements)),
      body: AsyncView<List<Json>>(
        load: () async =>
            (await context.api.get('/partner/settlements') as List)
                .cast<Json>(),
        builder: (context, rows, _) => rows.isEmpty
            ? EmptyState(
                icon: Icons.payments_rounded,
                title: t.noContent,
                hue: ServiceHues.moveIn,
              )
            : ListView(
                padding: const EdgeInsets.all(Space.gutter),
                children: [
                  for (final s in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: AppCard(
                        child: Row(
                          children: [
                            ServiceGlyph(s['service_code'] as String, size: 40),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.service(s['service_code'] as String),
                                    style: context.text.titleSmall,
                                  ),
                                  Text(
                                    s['payout_date'] == null
                                        ? t.pPayoutWaiting
                                        : dateLabel(
                                            DateTime.parse(
                                              s['payout_date'] as String,
                                            ),
                                            context.lang,
                                          ),
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  context.won((s['net'] as num).toInt()),
                                  style: context.text.titleSmall,
                                ),
                                Tag(
                                  label: settlementLabel(
                                    t,
                                    s['state'] as String,
                                  ),
                                  hue: switch (s['state']) {
                                    'paid' => StatusHues.assigned,
                                    'pending' => StatusHues.confirmed,
                                    'held' => StatusHues.cancelled,
                                    _ => StatusHues.consultation,
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pReviews)),
      body: AsyncView<List<Json>>(
        load: () async =>
            (await context.api.get('/partner/reviews') as List).cast<Json>(),
        builder: (context, rows, _) => rows.isEmpty
            ? EmptyState(
                icon: Icons.star_rounded,
                title: t.pNoReviews,
                hue: ServiceHues.studio,
              )
            : ListView(
                padding: const EdgeInsets.all(Space.gutter),
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (var i = 1; i <= 5; i++)
                                  Icon(
                                    i <= (r['rating'] as num)
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 18,
                                    color: context.colors.sun,
                                  ),
                                const Spacer(),
                                Text(
                                  t.service(r['service_code'] as String),
                                  style: context.text.labelSmall,
                                ),
                              ],
                            ),
                            if ((r['body'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: Space.xs),
                                child: Text(r['body'] as String),
                              ),
                            TextButton(
                              onPressed: () =>
                                  showToast(context, t.pReplyLater),
                              child: Text(t.pReplyLater),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Edits a copy of prefs and saves the whole object (server validates).
abstract class _PrefsEditor extends StatefulWidget {
  const _PrefsEditor({super.key});
}

abstract class _PrefsEditorState<W extends _PrefsEditor> extends State<W> {
  late Json prefs = {...context.proRead.prefs};
  bool busy = false;

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await context.proRead.savePrefs(prefs);
      if (mounted) {
        showToast(context, context.t.pSaved);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Set<E> setOf<E>(String key) => {
    ...(prefs[key] as List? ?? const []).cast<E>(),
  };
  void toggle<E>(String key, E v, bool on) => setState(
    () => prefs[key] =
        (on ? (setOf<E>(key)..add(v)) : (setOf<E>(key)..remove(v))).toList(),
  );
}

class AreasScreen extends _PrefsEditor {
  const AreasScreen({super.key});
  @override
  State<AreasScreen> createState() => _AreasState();
}

class _AreasState extends _PrefsEditorState<AreasScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final services = setOf<String>('services');
    final districts = setOf<String>('districts');
    return Scaffold(
      appBar: AppBar(title: Text(t.pServicesAreas)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          SectionTitle(t.pOnbServices),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final c in const [
                  'studio',
                  'kitchen',
                  'bathroom',
                  'mattress',
                  'aircon',
                  'sofa',
                  'move_out',
                  'move_in',
                ])
                  SwitchListTile(
                    secondary: ServiceGlyph(c, size: 36),
                    title: Text(t.service(c)),
                    value: services.contains(c),
                    onChanged: (v) => toggle('services', c, v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          SectionTitle(t.pOnbAreas),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in seoulDistricts)
                FilterChip(
                  label: Text(d.name(context.lang)),
                  selected: districts.contains(d.code),
                  onSelected: (v) => toggle('districts', d.code, v),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: t.save, busy: busy, onPressed: save),
      ),
    );
  }
}

class WorkScheduleScreen extends _PrefsEditor {
  const WorkScheduleScreen({super.key});
  @override
  State<WorkScheduleScreen> createState() => _WorkState();
}

class _WorkState extends _PrefsEditorState<WorkScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final days = setOf<int>('weekdays');
    final parts = setOf<String>('day_parts');
    final off = setOf<String>('days_off').toList()..sort();
    // Server weekdays: 0 = Monday … 6 = Sunday.
    final names = MaterialLocalizations.of(context).narrowWeekdays;
    return Scaffold(
      appBar: AppBar(title: Text(t.pWorkSchedule)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          SectionTitle(t.pWeekdays),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 0; d < 7; d++)
                FilterChip(
                  label: Text(names[(d + 1) % 7]),
                  selected: days.contains(d),
                  onSelected: (v) => toggle('weekdays', d, v),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SectionTitle(t.pDayParts),
          Wrap(
            spacing: 6,
            children: [
              FilterChip(
                label: Text(t.morning),
                selected: parts.contains('morning'),
                onSelected: (v) => toggle('day_parts', 'morning', v),
              ),
              FilterChip(
                label: Text(t.afternoon),
                selected: parts.contains('afternoon'),
                onSelected: (v) => toggle('day_parts', 'afternoon', v),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SectionTitle(
            t.pDaysOff,
            trailing: TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(t.pAddDayOff),
              onPressed: _addDayOff,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in off)
                InputChip(
                  label: Text(dateLabel(DateTime.parse(d), context.lang)),
                  onDeleted: () => toggle('days_off', d, false),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: t.save, busy: busy, onPressed: save),
      ),
    );
  }

  Future<void> _addDayOff() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
    );
    if (d != null) {
      toggle(
        'days_off',
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        true,
      );
    }
  }
}

class NotifyScreen extends _PrefsEditor {
  const NotifyScreen({super.key});
  @override
  State<NotifyScreen> createState() => _NotifyState();
}

class _NotifyState extends _PrefsEditorState<NotifyScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final n = {...(prefs['notify'] as Json? ?? const {})};
    Widget sw(String key, String label) => SwitchListTile(
      title: Text(label),
      value: n[key] as bool? ?? true,
      onChanged: (v) => setState(() => prefs['notify'] = {...n, key: v}),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.pNotifications)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                sw('direct', t.pNotifyDirect),
                sw('quotes', t.pNotifyQuotes),
                sw('chat', t.pNotifyChat),
                sw('quiet_night', t.pQuietNight),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: t.save, busy: busy, onPressed: save),
      ),
    );
  }
}

class PayoutAccountScreen extends StatefulWidget {
  const PayoutAccountScreen({super.key});
  @override
  State<PayoutAccountScreen> createState() => _PayoutAccountState();
}

class _PayoutAccountState extends State<PayoutAccountScreen> {
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  Json? _current;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.api
        .get('/partner/payout-account')
        .then(
          (v) {
            if (mounted) setState(() => _current = v as Json?);
          },
          onError: (Object e) {
            if (mounted) showToast(context, context.t.error(e));
          },
        )
        .ignore();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final v =
          await context.api.put('/partner/payout-account', {
                'bank': _bank.text,
                'account_number': _number.text,
                'holder': _holder.text,
              })
              as Json;
      if (!mounted) return;
      setState(() => _current = v);
      _number.clear();
      showToast(context, context.t.pAccountSaved);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_bank, _number, _holder]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = _current;
    return Scaffold(
      appBar: AppBar(title: Text(t.pPayoutAccount)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          if (c != null)
            AppCard(
              color: context.colors.freshTint,
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      '${c['bank']} •••• ${c['account_last4']}\n${c['holder']}',
                      style: context.text.titleSmall,
                    ),
                  ),
                  Tag(
                    label: c['verified_at'] == null
                        ? t.pUnverified
                        : t.pVerified,
                    hue: c['verified_at'] == null
                        ? StatusHues.consultation
                        : StatusHues.assigned,
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _bank,
            decoration: InputDecoration(labelText: t.pBank),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            ],
            decoration: InputDecoration(labelText: t.pAccountNumber),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _holder,
            decoration: InputDecoration(labelText: t.pHolder),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.save,
          busy: _busy,
          onPressed:
              _bank.text.isEmpty ||
                  _number.text.length < 8 ||
                  _holder.text.isEmpty
              ? null
              : _save,
        ),
      ),
    );
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamState();
}

class _TeamState extends State<TeamScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();

  Future<void> _invite() async {
    final t = context.t;
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      title: t.pInvite,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: t.accountName),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.accountPhone),
            ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.pInvite),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final api = context.api;
      try {
        await api.post('/partner/team', {
          'name': name.text,
          'phone': phone.text,
        });
        if (mounted) showToast(context, t.pInviteSent);
        await _view.currentState?.reload();
      } catch (e) {
        if (mounted) showToast(context, t.error(e));
      }
    }
    disposeAfterClose([name, phone]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pTeam)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _invite,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(t.pInvite),
      ),
      body: AsyncView<List<Json>>(
        key: _view,
        load: () async =>
            (await context.api.get('/partner/team') as List).cast<Json>(),
        builder: (context, members, reload) => ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            for (final m in members)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    ((m['name'] as String).isEmpty
                        ? '?'
                        : (m['name'] as String).characters.first),
                  ),
                ),
                title: Text(
                  (m['name'] as String).isEmpty
                      ? m['phone'] as String
                      : m['name'] as String,
                ),
                subtitle: Text(m['phone'] as String),
                trailing: m['role'] == 'owner'
                    ? Tag(label: t.pOwner, hue: StatusHues.confirmed)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m['invite_status'] == 'invited')
                            Tag(
                              label: t.pInvited,
                              hue: StatusHues.consultation,
                            ),
                          IconButton(
                            tooltip: t.pRemove,
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () async {
                              try {
                                await context.api.delete(
                                  '/partner/team/${m['id']}',
                                );
                                await reload();
                              } catch (e) {
                                if (context.mounted) {
                                  showToast(context, t.error(e));
                                }
                              }
                            },
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
