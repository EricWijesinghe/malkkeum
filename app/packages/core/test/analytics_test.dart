import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, Object>> sent;
  late bool failNext;

  Analytics make({bool consent = true}) {
    sent = [];
    failNext = false;
    final a = Analytics(
      platform: 'android',
      anonId: 'a1b2',
      send: (body) async {
        if (failNext) throw StateError('offline');
        sent.add(body);
      },
    );
    a.setConsent(consent);
    return a;
  }

  test('drops every event without marketing consent', () async {
    final a = make(consent: false);
    expect(a.track('app_open'), isFalse);
    await a.flush();
    expect(sent, isEmpty);
  });

  test('drops names outside the server allowlist and malformed screen ids', () {
    final a = make();
    expect(a.track('user_123'), isFalse);
    expect(a.track('quote_view', screen: 'Quote Screen'), isFalse);
    expect(a.track('quote_view', screen: 'quote'), isTrue);
  });

  test('sends one batch with name, screen and platform only', () async {
    final a = make();
    a.track('app_open');
    a.track('quote_view', screen: 'quote');
    await a.flush();
    expect(sent, hasLength(1));
    expect(sent.single['anon_id'], 'a1b2');
    expect(sent.single['events'], [
      {'name': 'app_open', 'platform': 'android'},
      {'name': 'quote_view', 'platform': 'android', 'screen': 'quote'},
    ]);
  });

  test('a full batch flushes without waiting for the timer', () async {
    final a = make();
    for (var i = 0; i < 20; i++) {
      a.track('app_open');
    }
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(1));
    expect((sent.single['events'] as List), hasLength(20));
  });

  test('a failed send keeps the events for the next flush', () async {
    final a = make();
    a.track('booking_start', screen: 'booking');
    failNext = true;
    await a.flush();
    expect(sent, isEmpty);
    failNext = false;
    await a.flush();
    expect((sent.single['events'] as List).single, {
      'name': 'booking_start',
      'platform': 'android',
      'screen': 'booking',
    });
  });

  test('withdrawing consent clears what is still queued', () async {
    final a = make();
    a.track('app_open');
    a.setConsent(false);
    a.setConsent(true);
    await a.flush();
    expect(sent, isEmpty);
  });

  test('anonymous ids are 32 hex characters and differ between installs', () {
    final first = Analytics.newAnonId();
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(first), isTrue);
    expect(Analytics.newAnonId(), isNot(first));
  });
}
