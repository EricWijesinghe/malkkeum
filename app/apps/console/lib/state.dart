import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Console-wide state: who is signed in, live counters, last event for toasts.
class ConsoleState extends ChangeNotifier {
  ConsoleState(this.api, this.realtime, this.session) {
    realtime.events.listen(_onEvent);
  }

  final ApiClient api;
  final Realtime realtime;
  final Session session;

  /// Null until the first answer: "not loaded" must never read as "0 jobs today".
  Json? dashboard;

  /// Why the last load failed. With [dashboard] set, its numbers are the last good ones (stale).
  Object? dashboardError;
  int dataVersion = 0;
  String? lastEventType;

  bool get isAdmin => session.role == 'staff_admin';
  int get unreadThreads => (dashboard?['unread_threads'] as num? ?? 0).toInt();
  int get openQuotes => (dashboard?['open_quotes'] as num? ?? 0).toInt();

  /// Never throws: a failure lands in [dashboardError] for the dashboard to show.
  Future<void> loadDashboard() async {
    try {
      dashboard = await api.get('/admin/dashboard') as Json;
      dashboardError = null;
    } catch (e) {
      dashboardError = e;
    }
    notifyListeners();
  }

  void _onEvent(Json e) {
    lastEventType = e['type'] as String?;
    dataVersion++;
    loadDashboard().ignore();
  }
}

class Deps extends InheritedNotifier<ConsoleState> {
  const Deps({
    super.key,
    required this.state,
    required this.session,
    required this.locale,
    required this.theme,
    required super.child,
  }) : super(notifier: state);
  final ConsoleState state;
  final Session session;
  final LocaleController locale;
  final ThemeController theme;
  static Deps of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Deps>()!;
  static Deps read(BuildContext c) => c.getInheritedWidgetOfExactType<Deps>()!;
}

extension DepsX on BuildContext {
  ConsoleState get console => Deps.of(this).state;
  ConsoleState get consoleRead => Deps.read(this).state;
  ApiClient get api => Deps.read(this).state.api;
}

/// Reloads [load] whenever any live event arrives (bookings, chat, quotes).
mixin LiveReload<W extends StatefulWidget> on State<W> {
  int _seen = -1;
  void onLive();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.console.dataVersion;
    if (_seen != -1 && v != _seen) onLive();
    _seen = v;
  }
}
