import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'i18n.dart';
import 'models.dart';

/// Server switches from `GET /v1/config`. Missing or malformed values mean "feature on, no maintenance",
/// so an old app never hides features because the server sent something it does not understand.
class RemoteConfig {
  const RemoteConfig({
    this.flags = const {},
    this.maintenance = false,
    this.maintenanceMessage = '',
  });

  final Map<String, bool> flags;
  final bool maintenance;
  final String maintenanceMessage;

  bool isOn(String feature) => flags[feature] ?? true;

  factory RemoteConfig.fromJson(Json json) {
    final raw = json['flags'];
    final flags = <String, bool>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is bool) flags[k] = v;
      });
    }
    final m = json['maintenance'];
    final on = m is Map && m['on'] == true;
    final msg = m is Map && m['message'] is String
        ? (m['message'] as String).trim()
        : '';
    return RemoteConfig(flags: flags, maintenance: on, maintenanceMessage: msg);
  }
}

/// Makes the loaded config available below it. Outside a [RemoteConfigGate] everything is on.
class RemoteConfigScope extends InheritedWidget {
  const RemoteConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  final RemoteConfig config;

  static RemoteConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemoteConfigScope>()?.config ??
      const RemoteConfig();

  @override
  bool updateShouldNotify(RemoteConfigScope old) =>
      old.config.maintenance != config.maintenance ||
      old.config.maintenanceMessage != config.maintenanceMessage ||
      !mapEquals(old.config.flags, config.flags);
}

/// Loads `/config` and shows a maintenance screen while the owner has it switched on. Offline or on
/// error the app keeps working with everything on; the server still refuses switched-off features.
class RemoteConfigGate extends StatefulWidget {
  const RemoteConfigGate({super.key, required this.api, required this.child});

  final ApiClient api;
  final Widget child;

  @override
  State<RemoteConfigGate> createState() => _RemoteConfigGateState();
}

class _RemoteConfigGateState extends State<RemoteConfigGate> {
  RemoteConfig _config = const RemoteConfig();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final body = await widget.api.get('/config');
      if (!mounted || body is! Json) return;
      setState(() => _config = RemoteConfig.fromJson(body));
    } on Exception {
      // Offline: keep the last known state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return RemoteConfigScope(
      config: c,
      child: c.maintenance
          ? _MaintenancePage(message: c.maintenanceMessage, onRetry: _load)
          : widget.child,
    );
  }
}

class _MaintenancePage extends StatelessWidget {
  const _MaintenancePage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                t.uMaintenanceTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                message.isEmpty ? t.uMaintenanceBody : message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onRetry,
                child: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
