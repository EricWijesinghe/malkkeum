import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

const _bpsPerPercent = 100;

/// Shows basis points as a percent for the owner: 1250 bps is "12.5".
String _pct(num bps) {
  final whole = bps % _bpsPerPercent == 0;
  return (bps / _bpsPerPercent).toStringAsFixed(whole ? 0 : 2);
}

/// Parses a typed percent back to basis points; null when it is not a number.
int? _bps(String text) {
  final pct = double.tryParse(text.trim());
  return pct == null ? null : (pct * _bpsPerPercent).round();
}

TextField _field(
  TextEditingController c,
  String label, {
  bool percent = false,
}) => TextField(
  controller: c,
  keyboardType: TextInputType.numberWithOptions(decimal: percent),
  inputFormatters: [
    FilteringTextInputFormatter.allow(
      percent ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
    ),
  ],
  decoration: InputDecoration(labelText: label, isDense: true),
);

/// Peak-hour surcharges for quotes and bookings. Percent inputs, saved as basis points.
class PeakTab extends StatefulWidget {
  const PeakTab({super.key});

  @override
  State<PeakTab> createState() => _PeakTabState();
}

class _PeakTabState extends State<PeakTab> {
  static const _percentKeys = [
    'weekend_bps',
    'public_holiday_bps',
    'lunar_period_bps',
    'evening_bps',
    'max_bps',
  ];
  final _ctrls = <String, TextEditingController>{};
  Json _config = const {};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Json config) {
    _config = config;
    for (final k in _percentKeys) {
      _ctrls[k] = TextEditingController(text: _pct(config[k] as num));
    }
    for (final k in const ['evening_start_hour', 'evening_end_hour']) {
      _ctrls[k] ??= TextEditingController(text: '${config[k]}');
    }
  }

  String? _labelFor(T t, String k) => switch (k) {
    'weekend_bps' => t.cgPeakWeekend,
    'public_holiday_bps' => t.cgPeakHoliday,
    'lunar_period_bps' => t.cgPeakLunar,
    'evening_bps' => t.cgPeakEvening,
    'max_bps' => t.cgPeakMax,
    'evening_start_hour' => t.cgPeakEveningFrom,
    'evening_end_hour' => t.cgPeakEveningTo,
    _ => null,
  };

  Json? _collect() {
    final next = Map<String, dynamic>.from(_config);
    for (final k in _percentKeys) {
      final bps = _bps(_ctrls[k]!.text);
      if (bps == null) return null;
      next[k] = bps;
    }
    for (final k in const ['evening_start_hour', 'evening_end_hour']) {
      final hour = int.tryParse(_ctrls[k]!.text);
      if (hour == null) return null;
      next[k] = hour;
    }
    return next;
  }

  Future<void> _save() async {
    final t = context.t;
    final body = _collect();
    if (body == null) {
      showToast(context, t.cgCodeInvalid);
      return;
    }
    try {
      await context.api.put('/admin/peak-pricing', body);
      if (mounted) showToast(context, t.cSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async => await context.api.get('/admin/peak-pricing') as Json,
      builder: (context, config, _) {
        if (_ctrls.isEmpty) _fill(config);
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(t.cgPeakHint, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            for (final k in [
              ..._percentKeys,
              'evening_start_hour',
              'evening_end_hour',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _field(
                  _ctrls[k]!,
                  _labelFor(t, k)!,
                  percent: _percentKeys.contains(k),
                ),
              ),
            FilledButton(
              onPressed: context.console.isAdmin ? _save : null,
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }
}

/// Score bands that warn about, or auto-pause, partners with low quality scores.
class QualityTab extends StatefulWidget {
  const QualityTab({super.key});

  @override
  State<QualityTab> createState() => _QualityTabState();
}

class _QualityTabState extends State<QualityTab> {
  final _warning = TextEditingController();
  final _pause = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _warning.dispose();
    _pause.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    final warning = int.tryParse(_warning.text);
    final pause = int.tryParse(_pause.text);
    if (warning == null || pause == null) {
      showToast(context, t.cgCodeInvalid);
      return;
    }
    try {
      await context.api.put('/admin/quality-thresholds', {
        'warning_below': warning,
        'pause_below': pause,
      });
      if (mounted) showToast(context, t.cSaved);
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async =>
          await context.api.get('/admin/quality-thresholds') as Json,
      builder: (context, q, _) {
        if (!_filled) {
          _warning.text = '${q['warning_below']}';
          _pause.text = '${q['pause_below']}';
          _filled = true;
        }
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(t.cgQualityHint, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            _field(_warning, t.cgQualityWarning),
            const SizedBox(height: Space.sm),
            _field(_pause, t.cgQualityPause),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: context.console.isAdmin ? _save : null,
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }
}
