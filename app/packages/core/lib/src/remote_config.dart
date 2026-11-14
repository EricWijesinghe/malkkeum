import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'api.dart';
import 'foreground.dart';
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

/// Loads `/config` and shows a banner above the app while the owner has maintenance switched on. The app
/// stays usable; screens that create bookings check [RemoteConfigScope] and hold their submit button.
/// Offline or on error the app keeps working with everything on; the server still refuses new bookings.
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
    // A forced update or a maintenance switch must not wait for a cold start.
    _resume = Foreground(onResume: _load, every: gateRecheckEvery);
  }

  late final Foreground _resume;

  @override
  void dispose() {
    _resume.dispose();
    super.dispose();
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
    // The banner slot and the padding wrapper are always in the tree, so the app below keeps its state when
    // maintenance toggles. The banner's SafeArea already clears the status bar, so the app drops that inset.
    return RemoteConfigScope(
      config: c,
      child: Column(
        children: [
          _MaintenanceBanner(
            message: c.maintenance ? c.maintenanceMessage : null,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: c.maintenance,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Above the app while maintenance is on: says new bookings are paused. Empty when it is off.
class _MaintenanceBanner extends StatelessWidget {
  const _MaintenanceBanner({required this.message});

  /// The owner's message while maintenance is on; null when it is off.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final msg = message;
    if (msg == null) return const SizedBox.shrink();
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.uMaintenanceTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      msg.isEmpty ? t.uMaintenanceBody : msg,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                    Text(
                      t.uMaintenanceBookingPaused,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
