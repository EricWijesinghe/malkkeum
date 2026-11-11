import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// System status: green / yellow / red per check, the external services, and the owner's alert settings.
/// Every red item says what to do, in the owner's language.
class OpsScreen extends StatefulWidget {
  const OpsScreen({super.key});
  @override
  State<OpsScreen> createState() => _OpsScreenState();
}

class _OpsScreenState extends State<OpsScreen> {
  final _view = GlobalKey<AsyncViewState<Json>>();

  void _reload() => _view.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AsyncView<Json>(
      key: _view,
      load: () async {
        final api = context.api;
        return {
          'status': await api.get('/admin/ops/status') as Json,
          'alerts': await api.get('/admin/ops/alerts') as Json,
        };
      },
      builder: (context, data, reload) {
        final status = data['status'] as Json;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t.cOps, style: context.text.headlineMedium),
                  ),
                  IconButton(
                    tooltip: t.oRefresh,
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              _Overall(status: status),
              const SizedBox(height: Space.lg),
              SectionTitle(t.oChecks),
              const SizedBox(height: Space.sm),
              _Checks(status: status),
              const SizedBox(height: Space.lg),
              SectionTitle(t.oIntegrations),
              const SizedBox(height: Space.sm),
              for (final i in (status['integrations'] as List).cast<Json>())
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: _IntegrationRow(item: i),
                ),
              const SizedBox(height: Space.lg),
              SectionTitle(t.oAlerts),
              const SizedBox(height: Space.sm),
              _AlertsCard(initial: data['alerts'] as Json, onSaved: _reload),
            ],
          ),
        );
      },
    );
  }
}

Color levelColor(BuildContext context, String level) {
  final c = context.colors;
  return switch (level) {
    'red' => c.danger,
    'yellow' => c.sun,
    _ => c.fresh,
  };
}

String levelLabel(T t, String level) => switch (level) {
  'red' => t.oLevelRed,
  'yellow' => t.oLevelYellow,
  _ => t.oLevelGreen,
};

class _Dot extends StatelessWidget {
  const _Dot(this.level);
  final String level;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: levelColor(context, level),
      shape: BoxShape.circle,
    ),
  );
}

class _Overall extends StatelessWidget {
  const _Overall({required this.status});
  final Json status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final level = status['level'] as String;
    final uptime = (status['uptime_secs'] as num? ?? 0).toInt();
    return AppCard(
      child: Row(
        children: [
          _Dot(level),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(t.oOverall, style: context.text.titleLarge)),
          Flexible(
            child: Text(
              levelLabel(t, level),
              textAlign: TextAlign.end,
              style: context.text.titleSmall,
            ),
          ),
          const SizedBox(width: Space.lg),
          Flexible(
            child: Text(
              '${t.oVersion} ${status['version']} · ${t.oUptime} ${t.oUptimeValue('${uptime ~/ 3600}', '${(uptime % 3600) ~/ 60}')}',
              textAlign: TextAlign.end,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _mb(num bytes) => (bytes / (1024 * 1024)).round().toString();

String _checkTitle(T t, String key) => switch (key) {
  'db' => t.oCheckDb,
  'disk' => t.oCheckDisk,
  'backup' => t.oCheckBackup,
  'errors' => t.oCheckErrors,
  'payments' => t.oCheckPayments,
  _ => t.oCheckWebhook,
};

String _checkValue(T t, Json status, Json check) {
  final v = check['value'];
  return switch (check['key']) {
    'db' => t.oCheckDbValue(
      '${v ?? 0}',
      _mb((status['db']['size_bytes'] as num?) ?? 0),
    ),
    'disk' => v == null ? t.oNoData : t.oCheckDiskValue('$v'),
    'backup' => v == null ? t.oCheckBackupNone : t.oCheckBackupValue('$v'),
    'errors' => t.oCheckErrorsValue('$v'),
    'payments' => t.oCheckPaymentsValue('$v'),
    _ => t.oCheckWebhookValue('$v'),
  };
}

String? _checkAction(T t, String key) => switch (key) {
  'db' => t.oActDb,
  'disk' => t.oActDisk,
  'backup' => t.oActBackup,
  'errors' => t.oActErrors,
  'payments' => t.oActPayments,
  'webhook' => t.oActWebhook,
  _ => null,
};

class _Checks extends StatelessWidget {
  const _Checks({required this.status});
  final Json status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final checks = (status['checks'] as List).cast<Json>();
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final c in checks)
          SizedBox(
            width: 300,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Dot(c['level'] as String),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          _checkTitle(t, c['key'] as String),
                          style: context.text.titleSmall,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          levelLabel(t, c['level'] as String),
                          textAlign: TextAlign.end,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    _checkValue(t, status, c),
                    style: context.text.bodyMedium,
                  ),
                  if (c['level'] == 'red' &&
                      _checkAction(t, c['key'] as String) != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      _checkAction(t, c['key'] as String)!,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

final _integrationNames = <String, String Function(T)>{
  'portone': (T t) => t.cIntPortone,
  'solapi': (T t) => t.cIntSolapi,
  'push': (T t) => t.cIntPush,
  'kakao': (T t) => t.cIntKakao,
  'naver': (T t) => t.cIntNaver,
  'google': (T t) => t.cIntGoogle,
  'apple': (T t) => t.cIntApple,
  'backup': (T t) => t.cIntBackup,
};

/// "2026-11-11 14:05" in the device's time zone; the status page is for people, not logs.
String _when(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({required this.item});
  final Json item;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final code = item['code'] as String;
    final level = item['level'] as String;
    final configured = item['configured'] == true;
    final ok = item['last_ok_at'] as String?;
    final fail = item['last_fail_at'] as String?;
    final failing =
        fail != null &&
        (ok == null ||
            (DateTime.tryParse(fail) ?? DateTime(0)).isAfter(
              DateTime.tryParse(ok) ?? DateTime(0),
            ));
    final detail = switch ((configured, failing, ok, fail)) {
      (false, _, _, _) => t.oIntNotSet,
      (true, true, _, _) => t.oIntLastFail(
        _when(fail),
        item['last_error'] as String? ?? '-',
      ),
      (true, false, final String o, _) => t.oIntLastOk(_when(o)),
      _ => t.oIntNever,
    };
    final action = switch (level) {
      'red' => t.oActIntegration,
      'yellow' when !configured => t.oActNotSet,
      _ => null,
    };
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: _Dot(level)),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _integrationNames[code]!(t),
                  style: context.text.titleSmall,
                ),
                Text(detail, style: context.text.bodySmall),
                if (action != null)
                  Text(
                    action,
                    style: context.text.bodySmall?.copyWith(
                      color: levelColor(context, level),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _ruleLabels = <String, String Function(T)>{
  'sms_failing': (T t) => t.oRuleSms,
  'push_failing': (T t) => t.oRulePush,
  'payment_failing': (T t) => t.oRulePayment,
  'payment_stuck': (T t) => t.oRuleStuck,
  'social_failing': (T t) => t.oRuleSocial,
  'backup_stale': (T t) => t.oRuleBackup,
  'disk_low': (T t) => t.oRuleDisk,
};

class _AlertsCard extends StatefulWidget {
  const _AlertsCard({required this.initial, required this.onSaved});
  final Json initial;
  final VoidCallback onSaved;

  @override
  State<_AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends State<_AlertsCard> {
  late final Map<String, bool> _rules;
  late int _from;
  late int _to;
  late final TextEditingController _phone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial['prefs'] as Json;
    final saved = (p['rules'] as Map?) ?? const {};
    _rules = {for (final r in _ruleLabels.keys) r: saved[r] as bool? ?? true};
    _from = (p['quiet_start'] as num).toInt();
    _to = (p['quiet_end'] as num).toInt();
    _phone = TextEditingController(text: p['alert_phone'] as String? ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await context.api.put('/admin/ops/alerts', {
        'rules': _rules,
        'quiet_start': _from,
        'quiet_end': _to,
        'alert_phone': _phone.text.trim(),
      });
      messenger.showSnackBar(SnackBar(content: Text(t.oSaved)));
      widget.onSaved();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.oSaveFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canSave = context.console.isAdmin;
    final defaultPhone = widget.initial['default_phone'] as String?;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.oAlertsHint, style: context.text.bodySmall),
          for (final e in _ruleLabels.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value(t)),
              value: _rules[e.key] ?? true,
              onChanged: canSave
                  ? (v) => setState(() => _rules[e.key] = v)
                  : null,
            ),
          const SizedBox(height: Space.sm),
          Text(t.oQuietHours, style: context.text.titleSmall),
          Text(t.oQuietHint, style: context.text.bodySmall),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              _HourPicker(
                label: t.oQuietFrom,
                value: _from,
                onChanged: canSave ? (h) => setState(() => _from = h) : null,
              ),
              const SizedBox(width: Space.lg),
              _HourPicker(
                label: t.oQuietTo,
                value: _to,
                onChanged: canSave ? (h) => setState(() => _to = h) : null,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _phone,
            enabled: canSave,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: t.oAlertPhone,
              helperText: defaultPhone == null
                  ? t.oAlertPhoneHint
                  : '${t.oAlertPhoneHint} ($defaultPhone)',
            ),
          ),
          const SizedBox(height: Space.md),
          if (canSave)
            PrimaryButton(label: t.oSave, busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Expanded(
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var h = 0; h < 24; h++)
            DropdownMenuItem(value: h, child: Text(t.oHour('$h'))),
        ],
        onChanged: onChanged == null
            ? null
            : (h) => h == null ? null : onChanged!(h),
      ),
    );
  }
}
