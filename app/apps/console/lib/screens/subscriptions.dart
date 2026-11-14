import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Owner view of regular cleaning subscriptions: filter by status, pause or resume one on the customer's behalf.
/// The server audits every action. A schedule edit keeps tomorrow's visit and re-plans the later ones.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  static const _statuses = ['active', 'paused', 'cancelled'];

  String? _status;
  late Future<List<Json>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Json>> _load() async {
    final rows = await context.api.get(
      '/admin/subscriptions',
      query: {'status': _status},
    ) as List;
    return rows.cast<Json>();
  }

  // Block body: setState must not be handed the Future that the assignment evaluates to.
  void _reload() {
    setState(() {
      _rows = _load();
    });
  }

  Future<void> _toggle(Json sub) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    final action = sub['status'] == 'paused' ? 'resume' : 'pause';
    try {
      await context.api.post('/admin/subscriptions/${sub['id']}/$action');
      _reload();
    } on ApiException {
      messenger.showSnackBar(SnackBar(content: Text(t.errorGeneric)));
    }
  }

  /// Same slots the server accepts for standard visits (`STANDARD_SLOTS`).
  static const _hours = [8, 9, 13, 14];

  Future<void> _edit(Json sub) async {
    final draft = await _askSchedule(sub);
    if (draft == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await context.api.put('/admin/subscriptions/${sub['id']}', draft);
      messenger.showSnackBar(SnackBar(content: Text(t.cSaved)));
      _reload();
    } on ApiException {
      messenger.showSnackBar(SnackBar(content: Text(t.errorGeneric)));
    }
  }

  /// Schedule dialog. Returns the PUT body, or null when cancelled.
  Future<Json?> _askSchedule(Json sub) {
    final t = context.t;
    var cadence = sub['cadence_weeks'] as int;
    var weekday = sub['weekday'] as int;
    var hour = sub['start_hour'] as int;
    return showDialog<Json>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t.cgSubEdit),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.cgSubEditHint, style: context.text.bodySmall),
                  const SizedBox(height: Space.md),
                  Text(t.cgSubCadence, style: context.text.titleSmall),
                  Wrap(
                    spacing: Space.xs,
                    children: [
                      for (final w in const [1, 2, 4])
                        ChoiceChip(
                          label: Text(_cadence(t, w)),
                          selected: cadence == w,
                          onSelected: (_) => set(() => cadence = w),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(t.cgSubWeekday, style: context.text.titleSmall),
                  Wrap(
                    spacing: Space.xs,
                    children: [
                      for (var i = 0; i < 7; i++)
                        ChoiceChip(
                          label: Text(_weekdayLabel(t, i)),
                          selected: weekday == i,
                          onSelected: (_) => set(() => weekday = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(t.cgSubStartHour, style: context.text.titleSmall),
                  Wrap(
                    spacing: Space.xs,
                    children: [
                      for (final h in _hours)
                        ChoiceChip(
                          label: Text('$h:00'),
                          selected: hour == h,
                          onSelected: (_) => set(() => hour = h),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop({
                'cadence_weeks': cadence,
                'weekday': weekday,
                'start_hour': hour,
              }),
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(T t, int index) => switch (index) {
    0 => t.cgWeekdayMon,
    1 => t.cgWeekdayTue,
    2 => t.cgWeekdayWed,
    3 => t.cgWeekdayThu,
    4 => t.cgWeekdayFri,
    5 => t.cgWeekdaySat,
    _ => t.cgWeekdaySun,
  };

  String _statusLabel(T t, String s) => switch (s) {
    'paused' => t.subStatusPaused,
    'cancelled' => t.subStatusCancelled,
    _ => t.subStatusActive,
  };

  String _cadence(T t, int weeks) => switch (weeks) {
    1 => t.subWeekly,
    2 => t.subBiweekly,
    _ => t.subEvery4Weeks,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Json>>(
        future: _rows,
        builder: (context, snap) {
          final header = Wrap(
            spacing: Space.xs,
            children: [
              for (final s in _statuses)
                ChoiceChip(
                  key: Key('sub-filter-$s'),
                  label: Text(_statusLabel(t, s)),
                  selected: _status == s,
                  onSelected: (on) {
                    setState(() => _status = on ? s : null);
                    _reload();
                  },
                ),
            ],
          );
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: [
                header,
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: [
                header,
                Text(t.cSubsLoadFailed),
                TextButton(onPressed: _reload, child: Text(t.retry)),
              ],
            );
          }
          final rows = snap.data ?? const <Json>[];
          return ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Text(t.cSubsTitle, style: context.text.headlineMedium),
              const SizedBox(height: Space.md),
              header,
              const SizedBox(height: Space.md),
              if (rows.isEmpty) Text(t.subListEmpty),
              for (final sub in rows)
                Card(
                  child: ListTile(
                    key: Key('sub-${sub['id']}'),
                    title: Text(
                      '${t.service(sub['service_code'] as String)} · ${_cadence(t, sub['cadence_weeks'] as int)}',
                    ),
                    subtitle: Text(
                      '${_statusLabel(t, sub['status'] as String)} · ${sub['start_hour']}:00',
                    ),
                    trailing: sub['status'] == 'cancelled'
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (context.console.isAdmin)
                                TextButton(
                                  key: Key('sub-edit-${sub['id']}'),
                                  onPressed: () => _edit(sub),
                                  child: Text(t.cgSubEdit),
                                ),
                              TextButton(
                                key: Key('sub-toggle-${sub['id']}'),
                                onPressed: () => _toggle(sub),
                                child: Text(
                                  sub['status'] == 'paused'
                                      ? t.subResume
                                      : t.subPause,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
