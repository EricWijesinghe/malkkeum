import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  StoreReview fake({
    bool asked = false,
    bool available = true,
    Object? error,
    List<String>? log,
  }) {
    var wasAsked = asked;
    return StoreReview(
      wasAsked: () async => wasAsked,
      markAsked: () async {
        wasAsked = true;
        log?.add('mark');
      },
      isAvailable: () async => available,
      request: () async {
        log?.add('request');
        if (error != null) throw error;
      },
    );
  }

  test('asks once: marks the flag, then requests the OS sheet', () async {
    final log = <String>[];
    final review = fake(log: log);
    await review.maybeAsk();
    expect(log, ['mark', 'request']);
  });

  test('never asks again after the flag is set', () async {
    final log = <String>[];
    final review = fake(asked: true, log: log);
    await review.maybeAsk();
    expect(log, isEmpty);
  });

  test(
    'marks the flag but does not request when the platform says no',
    () async {
      final log = <String>[];
      await fake(available: false, log: log).maybeAsk();
      expect(log, ['mark']);
    },
  );

  test('a failing review API never reaches the customer', () async {
    await expectLater(fake(error: StateError('boom')).maybeAsk(), completes);
  });
}
