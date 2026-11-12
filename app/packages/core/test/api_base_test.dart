import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API_BASE from the build wins in every mode', () {
    for (final release in [true, false]) {
      expect(
        defaultApiBase(fromEnv: 'https://api.example.com', release: release),
        'https://api.example.com',
      );
    }
  });

  test('a release app without API_BASE refuses to start', () {
    expect(
      () => defaultApiBase(fromEnv: '', release: true, web: false),
      throwsStateError,
    );
  });

  test('debug and profile builds fall back to the local dev server', () {
    expect(
      defaultApiBase(fromEnv: '', release: false, web: false),
      'http://127.0.0.1:8080',
    );
  });

  test('a release web build served from localhost keeps the local server', () {
    // The demo kit serves the console on localhost without API_BASE.
    expect(
      defaultApiBase(fromEnv: '', release: true, web: true),
      'http://127.0.0.1:8080',
    );
  });
}
