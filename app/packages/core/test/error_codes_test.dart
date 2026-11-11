import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend error codes must either have copy in every locale or be an explicit fallback.
/// The fixture is generated from backend/crates (api + domain) by hand-run script.
void main() {
  final fixture = jsonDecode(File('test/fixtures/backend_error_codes.json').readAsStringSync()) as Map<String, dynamic>;
  final localized = (fixture['localized'] as List).cast<String>();
  final fallback = (fixture['fallback'] as List).cast<String>();

  test('fixture lists each code once, in one bucket', () {
    expect(localized.toSet().length, localized.length);
    expect(fallback.toSet().length, fallback.length);
    expect(localized.toSet().intersection(fallback.toSet()), isEmpty);
  });

  test('every localized backend code has copy in all supported locales', () async {
    expect(T.supportedLocales, hasLength(14));
    for (final locale in T.supportedLocales) {
      final t = await T.delegate.load(locale);
      for (final code in localized) {
        final message = t.error(ApiException(400, code));
        expect(message.trim(), isNotEmpty, reason: '${locale.languageCode}: $code');
        expect(message, isNot(t.errorGeneric), reason: '${locale.languageCode}: $code has no dedicated copy');
      }
    }
  });

  test('fallback codes keep the generic message', () async {
    final en = await T.delegate.load(const Locale('en'));
    for (final code in fallback) {
      expect(en.error(ApiException(400, code)), en.errorGeneric, reason: code);
    }
  });

  test('network failures ignore the code', () async {
    final en = await T.delegate.load(const Locale('en'));
    expect(en.error(const ApiException(0, 'slot_full')), en.errorNetwork);
  });
}
