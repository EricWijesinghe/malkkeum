import 'dart:async';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Product events the server accepts (analytics.rs EVENT_NAMES). Anything else is dropped here.
const analyticsEventNames = {
  'app_open',
  'signup_start',
  'signup_done',
  'quote_view',
  'booking_start',
  'booking_done',
  'payment_done',
  'review_done',
};

final _screenPattern = RegExp(r'^[a-z_]{1,40}$');
final _anonPattern = RegExp(r'^[0-9a-f]{32}$');
const _anonKey = 'analytics.anon';
const _batchSize = 20;
const _maxQueued = 200;
const _flushEvery = Duration(seconds: 30);

/// Consent-gated product events for POST /v1/events. Sends only allowlisted names, a screen id and the
/// platform, under a random per-install id. No user id, no free text, nothing without marketing consent.
class Analytics {
  Analytics({required this.send, required this.platform, required this.anonId});

  /// Never sends: the default for tests and for apps that have not wired analytics.
  Analytics.off() : this(send: (_) async {}, platform: '', anonId: '');

  /// Posts one batch body to /v1/events (the app passes `api.post('/events', body)`).
  final Future<void> Function(Map<String, Object> body) send;
  final String platform;
  final String anonId;
  final List<Map<String, String>> _queue = [];
  Timer? _timer;
  bool _consented = false;

  /// Set from the user's consent state. Withdrawing consent drops whatever is still queued.
  void setConsent(bool granted) {
    _consented = granted;
    if (!granted) _queue.clear();
  }

  /// Starts the periodic flush. Safe to call twice.
  void start() => _timer ??= Timer.periodic(_flushEvery, (_) => flush());

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Queues one event. Returns false when it was dropped (no consent, unknown name, bad screen id).
  bool track(String name, {String? screen}) {
    if (!_consented || !analyticsEventNames.contains(name)) return false;
    if (screen != null && !_screenPattern.hasMatch(screen)) return false;
    // Desktop builds pass no platform: the API stores NULL instead of a wrong label (it accepts android/ios/web only).
    _queue.add({'name': name, if (platform.isNotEmpty) 'platform': platform, 'screen': ?screen});
    if (_queue.length >= _batchSize) unawaited(flush());
    return true;
  }

  /// Sends the queue in one request. On failure the events go back to the front of the queue, capped
  /// so an offline device cannot grow it without limit.
  Future<void> flush() async {
    if (!_consented || _queue.isEmpty) return;
    final batch = List<Map<String, String>>.of(_queue);
    _queue.clear();
    try {
      await send({'anon_id': anonId, 'events': batch});
    } on Object {
      if (_consented) {
        _queue.insertAll(0, batch);
        if (_queue.length > _maxQueued) _queue.removeRange(_maxQueued, _queue.length);
      }
    }
  }

  /// A random id for this install: 128 bits from a secure RNG, hex.
  static String newAnonId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// The install's id, kept in secure storage so it survives restarts. Storage errors propagate.
  static Future<String> loadOrCreateAnonId({FlutterSecureStorage storage = const FlutterSecureStorage()}) async {
    final saved = await storage.read(key: _anonKey);
    if (saved != null && _anonPattern.hasMatch(saved)) return saved;
    final id = newAnonId();
    await storage.write(key: _anonKey, value: id);
    return id;
  }
}
