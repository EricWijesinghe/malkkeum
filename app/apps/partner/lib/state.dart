import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

import 'outbox.dart';

/// Partner-wide data: profile (status, payouts), preferences, unread operations chats.
class PartnerState extends ChangeNotifier {
  PartnerState(
    this.api,
    this.realtime, {
    required this.outbox,
    JsonCache? cache,
  }) : _cache = cache ?? JsonCache() {
    outbox.account = () => api.session.subject;
    realtime.events.listen(_onEvent);
    api.session.addListener(_forgetOnSignOut);
  }

  final ApiClient api;
  final Realtime realtime;

  /// The last profile and prefs the server sent: what [boot] opens with when there is no signal.
  final JsonCache _cache;

  /// Where they are saved for the account signed in; null when nothing is saved.
  String? _savedKey;
  String get _keyNow => 'partner.boot.${api.session.subject}';
  bool _profileFromServer = false;

  /// Signing out (or deleting the account) leaves nothing of the profile on the device.
  void _forgetOnSignOut() {
    if (api.session.signedIn) return;
    _profileFromServer = false;
    final key = _savedKey;
    if (key == null) return;
    _savedKey = null;
    unawaited(_cache.write(key, const <String, Object?>{}));
  }

  /// Completions and photos queued while there was no signal.
  final CompletionOutbox outbox;

  Json profile = const {};
  Json prefs = const {};
  int unreadChats = 0;
  int unseenQuotes = 0;
  int jobsVersion = 0;

  String get status => profile['status'] as String? ?? 'pending';

  /// Social sign-ups have no phone yet; the server refuses accept/quote/complete until one is verified.
  bool get phoneVerified => profile['phone_verified'] != false;
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

  Future<void> loadAll() async {
    await Future.wait([loadProfile(), loadPrefs(), loadBadges()]);
    // Signed out while loading: nothing to save.
    if (!api.session.signedIn) return;
    final key = _savedKey = _keyNow;
    unawaited(_cache.write(key, {'profile': profile, 'prefs': prefs}));
  }

  /// Start-up load; true when the server answered. With no signal (a basement, a lift) a pro who was
  /// verified last time still opens Jobs and the outbox from the saved profile, and this returns false.
  /// Anything the server itself refuses is rethrown: a saved profile never overrides its answer.
  Future<bool> boot() async {
    try {
      await loadAll();
      return true;
    } on ApiException catch (e) {
      // A profile that did arrive (say "suspended", with only the badges lost to a flaky link) is the
      // server's answer too: the saved one stands in only while the server has said nothing.
      if (!e.isNetwork || _profileFromServer) rethrow;
      final key = _savedKey = _keyNow;
      final saved = await _cache.read(key);
      if (saved case {
        'profile': final Json p,
        'prefs': final Json f,
      } when p['status'] == 'verified') {
        profile = p;
        prefs = f;
        notifyListeners();
        return false;
      }
      rethrow;
    }
  }

  Future<void> loadProfile() async {
    profile = await api.get('/partner/me') as Json;
    _profileFromServer = true;
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

  /// Sends queued photos and completions. Runs at start and after a realtime resync (a reconnect).
  Future<void> syncOutbox() async {
    await outbox.drain(api);
    jobsChanged();
  }

  void _onEvent(Json e) {
    switch (e['type']) {
      case 'chat.message' || 'quote.selected':
        loadBadges().ignore();
      case 'pro.status':
        loadProfile().ignore();
      case 'resync':
        loadAll().ignore();
        syncOutbox().ignore();
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
