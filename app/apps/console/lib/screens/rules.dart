import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'confirm_action.dart';

/// Keys that delete records or open cases when lowered. Saving them asks the owner first.
const _deleteKeys = {'ai_chat_retention_days', 'upload_orphan_days'};
const _noshowKey = 'noshow_grace_minutes';

/// 운영 규칙: the limits and thresholds the owner may change, one tab per group. Values come from
/// `/admin/settings/<group>`. A save sends only the rows that changed; "기본값으로" sends null.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const groups = ['business', 'marketing', 'points', 'quality', 'ops'];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return DefaultTabController(
      length: groups.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Text(t.rulesIntro),
          ),
          TabBar(
            isScrollable: true,
            tabs: [for (final g in groups) Tab(text: _groupLabel(context, g))],
          ),
          Expanded(
            child: TabBarView(
              children: [for (final g in groups) _GroupForm(group: g)],
            ),
          ),
        ],
      ),
    );
  }
}

String _groupLabel(BuildContext context, String group) {
  final t = context.t;
  return switch (group) {
    'business' => t.rulesGroupBusiness,
    'marketing' => t.rulesGroupMarketing,
    'points' => t.rulesGroupPoints,
    'quality' => t.rulesGroupQuality,
    _ => t.rulesGroupOps,
  };
}

/// The warning to show before saving these changes, or null when none applies.
String? _riskWarning(BuildContext context, Map<String, Object?> values) {
  final t = context.t;
  if (values.keys.any(_deleteKeys.contains)) return t.rulesDeleteWarning;
  if (values.containsKey(_noshowKey)) return t.rulesNoshowWarning;
  return null;
}

class _GroupForm extends StatefulWidget {
  const _GroupForm({required this.group});

  final String group;

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  final _edits = <String, Object?>{};
  final _resets = <String>{};
  bool _saving = false;

  void _changed(String key, Object? value) {
    setState(() {
      _resets.remove(key);
      if (value == null) {
        _edits.remove(key);
      } else {
        _edits[key] = value;
      }
    });
  }

  void _reset(String key) {
    setState(() {
      _edits.remove(key);
      _resets.add(key);
    });
  }

  Future<void> _save(Future<void> Function() reload) async {
    final t = context.t;
    if (_edits.isEmpty && _resets.isEmpty) {
      showToast(context, t.rulesNoChanges);
      return;
    }
    final values = <String, Object?>{
      ..._edits,
      for (final key in _resets) key: null,
    };
    final warning = _riskWarning(context, values);
    if (warning != null) {
      final ok = await confirmAction(context, t.rulesSave, message: warning);
      if (!ok) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await context.api.put('/admin/settings/${widget.group}', {
        'values': values,
      });
      _edits.clear();
      _resets.clear();
      await reload();
      if (mounted) showToast(context, t.rulesSaved);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      load: () async =>
          (await context.api.get('/admin/settings/${widget.group}')) as Json,
      builder: (context, doc, reload) {
        final items = ((doc['items'] as List?) ?? const []).cast<Json>();
        return ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            for (final item in items)
              _RuleRow(
                key: ValueKey('${item['key']}|${item['value']}|${item['source']}'),
                item: item,
                onChanged: (v) => _changed(item['key'] as String, v),
                onReset: () => _reset(item['key'] as String),
              ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving ? null : () => _save(reload),
              child: Text(t.rulesSave),
            ),
          ],
        );
      },
    );
  }
}

class _RuleRow extends StatefulWidget {
  const _RuleRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onReset,
  });

  final Json item;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onReset;

  @override
  State<_RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends State<_RuleRow> {
  late final _controller = TextEditingController(
    text: '${widget.item['value']}',
  );
  late bool _on = widget.item['value'] == true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _label(BuildContext context) {
    final t = context.t;
    final key = widget.item['key'];
    return switch (key) {
      'upload_daily_quota' => t.ruleUploadDailyQuota,
      'max_open_quote_requests' => t.ruleMaxOpenQuoteRequests,
      'max_threads_per_day' => t.ruleMaxThreadsPerDay,
      'review_report_threshold' => t.ruleReviewReportThreshold,
      'noshow_grace_minutes' => t.ruleNoshowGraceMinutes,
      'ai_chat_retention_days' => t.ruleAiChatRetentionDays,
      'upload_orphan_days' => t.ruleUploadOrphanDays,
      'reconcile_interval_secs' => t.ruleReconcileIntervalSecs,
      'freq_cap_per_week' => t.ruleFreqCapPerWeek,
      'nudge_rebook_days' => t.ruleNudgeRebookDays,
      'points_adjust_max' => t.rulePointsAdjustMax,
      'quality_window_days' => t.ruleQualityWindowDays,
      'quality_on_time_grace_min' => t.ruleQualityOnTimeGraceMin,
      'backup_stale_hours' => t.ruleBackupStaleHours,
      'backup_late_hours' => t.ruleBackupLateHours,
      'disk_low_pct' => t.ruleDiskLowPct,
      'disk_warn_pct' => t.ruleDiskWarnPct,
      'maintenance_on' => t.ruleMaintenanceOn,
      'maintenance_message' => t.ruleMaintenanceMessage,
      _ => '$key',
    };
  }

  String _source(BuildContext context) {
    final t = context.t;
    return switch (widget.item['source']) {
      'db' => t.rulesSourceDb,
      'env' => t.rulesSourceEnv,
      _ => t.rulesSourceDefault,
    };
  }

  String _applies(BuildContext context) {
    final t = context.t;
    return switch (widget.item['applies']) {
      'rebuild' => t.rulesApplyRebuild,
      'store_manual' => t.rulesApplyStoreManual,
      _ => t.rulesApplyInstant,
    };
  }

  Widget _input(bool readOnly) {
    if (widget.item['type'] == 'bool') {
      return Switch(
        value: _on,
        onChanged: readOnly
            ? null
            : (v) {
                setState(() => _on = v);
                widget.onChanged(v);
              },
      );
    }
    final isInt = widget.item['type'] != 'text';
    return TextField(
      controller: _controller,
      enabled: !readOnly,
      keyboardType: isInt ? TextInputType.number : TextInputType.multiline,
      maxLines: isInt ? 1 : 3,
      onChanged: (s) => widget.onChanged(isInt ? int.tryParse(s.trim()) : s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final item = widget.item;
    final readOnly = item['read_only'] == true;
    final tighten = item['tighten'];
    final notes = [
      if (item['type'] == 'int') '${t.rulesRange}: ${item['min']} – ${item['max']}',
      if (item['type'] == 'text') '${t.rulesMaxLength}: ${item['max_length']}',
      if (tighten == 'down') t.rulesTightenDown,
      if (tighten == 'up') t.rulesTightenUp,
      _applies(context),
      if (readOnly) t.rulesReadOnly,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_label(context), style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          _input(readOnly),
          const SizedBox(height: Space.xs),
          Text(
            '${t.rulesSource}: ${_source(context)}',
            style: context.text.bodySmall,
          ),
          for (final n in notes) Text(n, style: context.text.bodySmall),
          if (!readOnly && item['source'] == 'db')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onReset,
                child: Text(t.rulesReset),
              ),
            ),
        ],
      ),
    );
  }
}
