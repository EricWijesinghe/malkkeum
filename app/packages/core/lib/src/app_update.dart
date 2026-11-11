import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'i18n.dart';
import 'models.dart';

/// Store version rules for one app (customer or partner), from the public `/brand` business profile.
class AppVersionPolicy {
  const AppVersionPolicy({this.min, this.latest, this.storeUrl});

  /// Below this the app stops and asks for an update.
  final String? min;

  /// Below this the app shows a dismissible banner.
  final String? latest;

  /// The store page for this app on this platform, when the owner has entered it.
  final String? storeUrl;

  /// [app] is `customer` or `partner`. Missing or malformed fields mean "no rule".
  factory AppVersionPolicy.from(
    Json brand,
    String app, {
    TargetPlatform? platform,
  }) {
    final versions = (brand['app_versions'] as Json?)?[app] as Json?;
    final ios = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;
    final partner = app == 'partner';
    final key = switch ((partner, ios)) {
      (false, true) => 'app_store_url',
      (false, false) => 'play_store_url',
      (true, true) => 'partner_app_store_url',
      (true, false) => 'partner_play_store_url',
    };
    return AppVersionPolicy(
      min: _version(versions?['min_app_version']),
      latest: _version(versions?['latest_app_version']),
      storeUrl: _https(brand[key]),
    );
  }

  static String? _version(Object? v) =>
      v is String && RegExp(r'^\d+\.\d+\.\d+$').hasMatch(v) ? v : null;
  static String? _https(Object? v) =>
      v is String && v.startsWith('https://') ? v : null;
}

/// Compares `major.minor.patch` strings (a `+build` suffix is ignored). Negative when [a] is older.
int compareAppVersions(String a, String b) {
  List<int> parts(String v) {
    final nums = v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    return [for (var i = 0; i < 3; i++) i < nums.length ? nums[i] : 0];
  }

  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return 0;
}

/// Wrap the whole app (MaterialApp `builder`). Below the minimum version the app is replaced by a
/// full-screen update page. Below the latest version a banner sits on top and can be dismissed.
/// Silent when the rules cannot be loaded (offline): an update check must never block the app.
class UpdateGate extends StatefulWidget {
  const UpdateGate({
    super.key,
    required this.api,
    required this.app,
    required this.child,
    this.currentVersion,
  });

  final ApiClient api;

  /// `customer` or `partner`.
  final String app;
  final Widget child;

  /// Overridable for tests; defaults to the installed app's version.
  final Future<String> Function()? currentVersion;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  String? _current;
  AppVersionPolicy? _policy;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final version = await (widget.currentVersion ?? _installedVersion)();
      final brand = await widget.api.get('/brand');
      if (!mounted || brand is! Json) return;
      setState(() {
        _current = version;
        _policy = AppVersionPolicy.from(brand, widget.app);
      });
    } on Exception {
      // Offline or the profile is not set up yet: keep the app usable.
    }
  }

  static Future<String> _installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  Widget build(BuildContext context) {
    final current = _current, policy = _policy;
    if (current == null || policy == null) return widget.child;
    final min = policy.min;
    if (min != null && compareAppVersions(current, min) < 0) {
      return _RequiredUpdate(current: current, storeUrl: policy.storeUrl);
    }
    final latest = policy.latest;
    if (latest == null ||
        _dismissed ||
        compareAppVersions(current, latest) >= 0) {
      return widget.child;
    }
    return Column(
      children: [
        _UpdateBanner(
          version: latest,
          storeUrl: policy.storeUrl,
          onLater: () => setState(() => _dismissed = true),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

Future<void> _openStore(String? url) async {
  if (url == null) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _RequiredUpdate extends StatelessWidget {
  const _RequiredUpdate({required this.current, required this.storeUrl});
  final String current;
  final String? storeUrl;

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
                Icons.system_update_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                t.uUpdateRequiredTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(t.uUpdateRequiredBody, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                t.uCurrentVersion(current),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: storeUrl == null ? null : () => _openStore(storeUrl),
                child: Text(
                  storeUrl == null ? t.uUpdateStoreMissing : t.uUpdateStore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.version,
    required this.storeUrl,
    required this.onLater,
  });
  final String version;
  final String? storeUrl;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.uUpdateBanner(version),
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
              TextButton(onPressed: onLater, child: Text(t.uUpdateLater)),
              FilledButton.tonal(
                onPressed: storeUrl == null ? null : () => _openStore(storeUrl),
                child: Text(t.uUpdateNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
