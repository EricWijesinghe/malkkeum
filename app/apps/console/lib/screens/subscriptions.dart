import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Owner view of regular cleaning subscriptions: filter by status, pause or resume one on the customer's behalf.
/// The server audits every action. Editing the schedule is done through the API for now.
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
    final rows = await context.api.get('/admin/subscriptions', query: {'status': _status}) as List;
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
            return ListView(padding: const EdgeInsets.all(Space.xl), children: [header, const Center(child: CircularProgressIndicator())]);
          }
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: [header, Text(t.cSubsLoadFailed), TextButton(onPressed: _reload, child: Text(t.retry))],
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
                    title: Text('${t.service(sub['service_code'] as String)} · ${_cadence(t, sub['cadence_weeks'] as int)}'),
                    subtitle: Text('${_statusLabel(t, sub['status'] as String)} · ${sub['start_hour']}:00'),
                    trailing: sub['status'] == 'cancelled'
                        ? null
                        : TextButton(
                            key: Key('sub-toggle-${sub['id']}'),
                            onPressed: () => _toggle(sub),
                            child: Text(sub['status'] == 'paused' ? t.subResume : t.subPause),
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
