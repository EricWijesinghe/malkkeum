import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, Object>> sent;
  late DateTime now;

  ErrorReporter make({bool enabled = true}) {
    sent = [];
    now = DateTime(2026, 11, 13, 9);
    return ErrorReporter(
      app: 'android',
      enabled: enabled,
      version: () async => '1.4.0+12',
      clock: () => now,
      send: (body) async => sent.add(body),
    );
  }

  tearDown(() => ErrorReporter.current = null);

  test('scrubs e-mails, phone numbers, tokens and codes before sending', () {
    const raw = 'user a.b@mail.co phone 010-1234-5678 jwt eyJhbGciOi.eyJzdWIi.sig '
        'wss://h/v1/ws?token=abc123&x=1 code=987654 at app.dart:42';
    expect(
      scrubErrorText(raw),
      'user [redacted] phone [redacted] jwt [redacted] '
      'wss://h/v1/ws?token=[redacted]&x=1 code=[redacted] at app.dart:42',
    );
  });

  test('keeps the hex addresses of an obfuscated stack trace', () {
    const frame = '#00 abs 0000007a1c3d4e5f virt 00000000001b2c3d _kDartIsolateSnapshotInstructions+0x1a2b3c';
    expect(scrubErrorText(frame), frame);
  });

  test('sends app, version, scrubbed message and stack', () async {
    final r = make();
    expect(await r.report(StateError('bad 01012345678'), StackTrace.fromString('#0 main (a.dart:1)')), isTrue);
    expect(sent.single, {
      'app': 'android',
      'version': '1.4.0+12',
      'message': 'Bad state: bad [redacted]',
      'stack': '#0 main (a.dart:1)',
    });
  });

  test('the same error is sent once and at most 5 a minute', () async {
    final r = make();
    await r.report(StateError('same'), null);
    await r.report(StateError('same'), null);
    expect(sent, hasLength(1));
    for (var i = 0; i < 10; i++) {
      await r.report(StateError('e$i'), null);
    }
    expect(sent, hasLength(5));
    now = now.add(const Duration(minutes: 1));
    expect(await r.report(StateError('later'), null), isTrue);
  });

  test('debug builds and a missing sender send nothing; a failed send does not throw', () async {
    expect(await make(enabled: false).report(StateError('x'), null), isFalse);
    expect(await (make()..send = null).report(StateError('x'), null), isFalse);
    final failing = make()..send = (_) async => throw StateError('offline');
    expect(await failing.report(StateError('x'), null), isFalse);
  });

  test('Flutter errors, uncaught async errors and screen-reported errors reach the reporter', () async {
    final r = make();
    final flutterBefore = FlutterError.onError;
    final platformBefore = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = flutterBefore;
      PlatformDispatcher.instance.onError = platformBefore;
    });
    FlutterError.onError = (_) {}; // keep the test output clean
    final done = Completer<void>();
    ErrorReporter.run(r, () async {
      FlutterError.reportError(FlutterErrorDetails(exception: StateError('build failed')));
      unawaited(Future<void>.error(StateError('async boom')));
      reportError(const ApiException(500, 'server_error'));
      reportError(TypeError());
      done.complete();
    });
    await done.future;
    await pumpEventQueue();
    final messages = [for (final b in sent) b['message']];
    expect(messages, containsAll(['Bad state: build failed', 'Bad state: async boom', "Instance of 'TypeError'"]));
    expect(messages.where((m) => '$m'.contains('server_error')), isEmpty, reason: 'API answers stay local');
  });
}
