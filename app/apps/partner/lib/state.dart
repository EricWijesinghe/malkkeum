import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Partner-wide data: profile (status, payouts), preferences, unread operations chats.
class PartnerState extends ChangeNotifier {
  PartnerState(this.api, this.realtime) {
    realtime.events.listen(_onEvent);
  }

  final ApiClient api;
  final Realtime realtime;

  Json profile = const {};
  Json prefs = const {};
  int unreadChats = 0;
  int unseenQuotes = 0;
  int jobsVersion = 0;

  String get status => profile['status'] as String? ?? 'pending';
  String get name => profile['name'] as String? ?? '';
  String get teamName => profile['team_name'] as String? ?? '';
  int get feeBps => (profile['fee_bps'] as num? ?? 2000).toInt();
  String get feeLabel => feeBps % 100 == 0
      ? '${feeBps ~/ 100}'
      : (feeBps / 100).toStringAsFixed(1);
  int get pendingPayout => (profile['pending_payout'] as num? ?? 0).toInt();
  bool get onboarded =>
      name.isNotEmpty && (prefs['services'] as List? ?? const []).isNotEmpty;

  /// Same math as the server's domain::partner::payout (fee rounded half-up).
  int payoutFor(int gross) => gross - ((gross * feeBps + 5000) ~/ 10000);

  Future<void> loadAll() =>
      Future.wait([loadProfile(), loadPrefs(), loadBadges()]);

  Future<void> loadProfile() async {
    profile = await api.get('/partner/me') as Json;
    notifyListeners();
  }

  Future<void> loadPrefs() async {
    prefs = await api.get('/partner/prefs') as Json;
    notifyListeners();
  }

  Future<void> savePrefs(Json next) async {
    prefs = await api.put('/partner/prefs', next) as Json;
    jobsVersion++;
    notifyListeners();
  }

  Future<void> loadBadges() async {
    final threads = (await api.get('/partner/threads') as List).map(
      (e) => ChatThread.fromJson(e as Json),
    );
    unreadChats = threads.fold(0, (s, t) => s + t.unreadMember);
    final quotes = (await api.get('/partner/quotes') as List).cast<Json>();
    unseenQuotes = quotes.where((q) => q['seen_by_pro'] == false).length;
    notifyListeners();
  }

  void jobsChanged() {
    jobsVersion++;
    notifyListeners();
  }

  void _onEvent(Json e) {
    switch (e['type']) {
      case 'chat.message' || 'quote.selected':
        loadBadges().ignore();
      case 'pro.status':
        loadProfile().ignore();
      case 'resync':
        loadAll().ignore();
    }
    if (e['type'] != 'chat.message') jobsChanged();
  }
}

class Deps extends InheritedNotifier<PartnerState> {
  const Deps({
    super.key,
    required this.app,
    required this.session,
    required this.locale,
    required this.theme,
    required super.child,
  }) : super(notifier: app);
  final PartnerState app;
  final Session session;
  final LocaleController locale;
  final ThemeController theme;
  static Deps of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Deps>()!;
  static Deps read(BuildContext c) => c.getInheritedWidgetOfExactType<Deps>()!;
}

extension DepsX on BuildContext {
  PartnerState get pro => Deps.of(this).app;
  PartnerState get proRead => Deps.read(this).app;
  ApiClient get api => Deps.read(this).app.api;
}
