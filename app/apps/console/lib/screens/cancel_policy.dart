import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Owner-editable cancellation fee tiers. Blank percent = not cancellable in the app (staff decide).
/// The server validates monotonic penalties; a refused save shows the error.
class CancelPolicyTab extends StatefulWidget {
  const CancelPolicyTab({super.key});

  @override
  State<CancelPolicyTab> createState() => _CancelPolicyTabState();
}

class _CancelPolicyTabState extends State<CancelPolicyTab> {
  final _days = <TextEditingController>[];
  final _percents = <TextEditingController>[];
  final _minFee = TextEditingController();
  final _reschedule = TextEditingController();
  bool _isDefault = true;

  @override
  void dispose() {
    for (final c in [..._days, ..._percents, _minFee, _reschedule]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Json data) {
    final policy = data['policy'] as Json;
    _isDefault = data['is_default'] == true;
    for (final tier in (policy['tiers'] as List).cast<Json>()) {
      _days.add(TextEditingController(text: '${tier['min_days']}'));
      _percents.add(TextEditingController(text: tier['percent'] == null ? '' : '${tier['percent']}'));
    }
    _minFee.text = '${policy['min_fee']}';
    _reschedule.text = '${policy['reschedule_min_days']}';
  }

  Json _body() => {
    'tiers': [
      for (var i = 0; i < _days.length; i++)
        {
          'min_days': int.tryParse(_days[i].text) ?? 0,
          'percent': _percents[i].text.trim().isEmpty ? null : int.tryParse(_percents[i].text),
        },
    ],
    'min_fee': int.tryParse(_minFee.text) ?? 0,
    'reschedule_min_days': int.tryParse(_reschedule.text) ?? 2,
  };

  Future<void> _save() async {
    final t = context.t;
    try {
      await context.api.put('/admin/cancel-policy', _body());
      if (!mounted) return;
      setState(() => _isDefault = false);
      showToast(context, t.cSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async => await context.api.get('/policy/cancellation') as Json,
      builder: (context, data, _) {
        if (_days.isEmpty) _fill(data);
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            if (_isDefault) Text(t.cPolicyDefaultBanner, style: context.text.bodyMedium),
            const SizedBox(height: Space.sm),
            for (var i = 0; i < _days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  children: [
                    Expanded(child: _field(_days[i], t.cPolicyDaysBefore)),
                    const SizedBox(width: Space.sm),
                    Expanded(child: _field(_percents[i], t.cPolicyPercent)),
                  ],
                ),
              ),
            _field(_minFee, t.cPolicyMinFee),
            const SizedBox(height: Space.sm),
            _field(_reschedule, t.cPolicyReschedule),
            const SizedBox(height: Space.sm),
            Text(t.cPolicyHint, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: !context.console.isAdmin ? null : _save, child: Text(t.save)),
          ],
        );
      },
    );
  }
}
