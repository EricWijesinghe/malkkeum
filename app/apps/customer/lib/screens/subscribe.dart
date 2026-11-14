import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';

/// Arrival windows a subscription can use (same as a standard booking).
const subscriptionHours = [8, 9, 13, 14];

/// Customer-facing cadences in weeks.
const subscriptionCadences = [1, 2, 4];

String cadenceLabel(T t, int weeks) => switch (weeks) {
  1 => t.subWeekly,
  2 => t.subBiweekly,
  _ => t.subEvery4Weeks,
};

/// Starts a regular cleaning subscription: service, address, saved card, cadence, weekday and arrival window.
/// Pops with `true` once the server has planned the first visits.
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  String? _service;
  String? _address;
  String? _method;
  int _cadence = 1;
  /// 0 = Monday, the server's convention.
  int _weekday = 0;
  int _hour = 9;
  int _percent = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  /// The discount is shown when the owner has set one. The server prices every visit regardless.
  Future<void> _loadPolicy() async {
    try {
      final p = await context.api.get('/policy/subscription') as Json;
      if (mounted) setState(() => _percent = p['discount_percent'] as int);
    } on ApiException {
      // Optional line: a failed lookup only hides the discount note.
    }
  }

  Future<void> _submit() async {
    if (!await requireSignIn(context, reason: SignInReason.book) || !mounted) return;
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await context.api.post('/subscriptions', {
        'service_code': _service,
        'address_id': _address,
        'payment_method_id': _method,
        'cadence_weeks': _cadence,
        'weekday': _weekday,
        'start_hour': _hour,
      });
      messenger.showSnackBar(SnackBar(content: Text(t.subCreated)));
      nav.pop(true);
    } on ApiException {
      messenger.showSnackBar(SnackBar(content: Text(t.errorGeneric)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // Listening: services, addresses and cards may still be loading when the screen opens.
    final app = context.app;
    final services = app.services.where((s) => !s.isQuote).toList();
    final addresses = app.addresses;
    final methods = app.methods;
    final ready = _service != null && _address != null && _method != null && !_saving;
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;
    return Scaffold(
      appBar: AppBar(title: Text(t.subNew)),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          if (addresses.isEmpty) Text(t.subNeedAddress),
          DropdownButtonFormField<String>(
            key: const Key('sub-service'),
            initialValue: _service,
            items: [for (final s in services) DropdownMenuItem(value: s.code, child: Text(t.service(s.code)))],
            onChanged: (v) => setState(() => _service = v),
          ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            key: const Key('sub-address'),
            initialValue: _address,
            items: [for (final a in addresses) DropdownMenuItem(value: a.id, child: Text(a.label))],
            onChanged: (v) => setState(() => _address = v),
          ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            key: const Key('sub-method'),
            initialValue: _method,
            items: [for (final m in methods) DropdownMenuItem(value: m.id, child: Text(m.displayName))],
            onChanged: (v) => setState(() => _method = v),
          ),
          const SizedBox(height: Space.lg),
          Text(t.subCadence),
          const SizedBox(height: Space.xs),
          SegmentedButton<int>(
            key: const Key('sub-cadence'),
            segments: [for (final w in subscriptionCadences) ButtonSegment(value: w, label: Text(cadenceLabel(t, w)))],
            selected: {_cadence},
            onSelectionChanged: (s) => setState(() => _cadence = s.first),
          ),
          const SizedBox(height: Space.lg),
          Text(t.subWeekday),
          const SizedBox(height: Space.xs),
          SegmentedButton<int>(
            key: const Key('sub-weekday'),
            // Seven segments: the check mark would push the selected day past a phone's width.
            showSelectedIcon: false,
            segments: [for (var i = 0; i < 7; i++) ButtonSegment(value: i, label: Text(narrow[(i + 1) % 7]))],
            selected: {_weekday},
            onSelectionChanged: (s) => setState(() => _weekday = s.first),
          ),
          const SizedBox(height: Space.lg),
          Text(t.subHour),
          const SizedBox(height: Space.xs),
          SegmentedButton<int>(
            key: const Key('sub-hour'),
            segments: [for (final h in subscriptionHours) ButtonSegment(value: h, label: Text('${h.toString().padLeft(2, '0')}:00'))],
            selected: {_hour},
            onSelectionChanged: (s) => setState(() => _hour = s.first),
          ),
          const SizedBox(height: Space.lg),
          if (_percent > 0) Text(t.subDiscountNote('$_percent')),
          const SizedBox(height: Space.sm),
          Text(t.subChargeNote),
          const SizedBox(height: Space.xl),
          FilledButton(
            key: const Key('sub-submit'),
            onPressed: ready ? _submit : null,
            child: Text(t.subCreate),
          ),
        ],
      ),
    );
  }
}
