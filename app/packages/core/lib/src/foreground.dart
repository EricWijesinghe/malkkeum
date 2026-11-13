import 'package:flutter/widgets.dart';

/// How often the update and maintenance gates check again when the app comes back.
const gateRecheckEvery = Duration(minutes: 10);

/// App lifecycle hooks shared by the three apps.
///
/// [onResume] runs when the app comes back from the background (not after a mere dialog or the
/// notification shade), at most once per [every]: a quick switch to the payment app does not refetch.
/// [onHide] runs every time the app leaves the foreground (backgrounded, tab hidden, about to be killed).
class Foreground {
  Foreground({this.onResume, this.onHide, this.every = const Duration(seconds: 30), DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _last = _clock();
    _listener = AppLifecycleListener(onHide: _hidden, onResume: _resumed);
  }

  final VoidCallback? onResume;
  final VoidCallback? onHide;
  final Duration every;
  final DateTime Function() _clock;
  late DateTime _last;
  bool _wasHidden = false;
  late final AppLifecycleListener _listener;

  void _hidden() {
    _wasHidden = true;
    onHide?.call();
  }

  void _resumed() {
    if (!_wasHidden) return;
    _wasHidden = false;
    final now = _clock();
    if (now.difference(_last) < every) return;
    _last = now;
    onResume?.call();
  }

  void dispose() => _listener.dispose();
}
