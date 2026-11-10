import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'fake_api.dart';
import 'fake_storage.dart';

/// Everything an app needs at construction time, wired to one [FakeApi].
/// Build the app with the same objects that `main()` would create.
class TestEnv {
  TestEnv._({
    required this.fake,
    required this.storage,
    required this.session,
    required this.api,
    required this.locale,
    required this.theme,
  });

  final FakeApi fake;
  final FakeStorage storage;
  final Session session;
  final ApiClient api;
  final LocaleController locale;
  final ThemeController theme;

  /// Base URL used by every test. Not a real host: the MockClient never opens a socket.
  static const baseUrl = 'http://api.test';

  /// Creates a signed-in (default) or signed-out environment.
  ///
  /// [localeCode] sets the persisted app language (null = fresh install; default Korean, matching the
  /// product default). [themeMode] defaults to dark, the app's own default.
  static Future<TestEnv> create({
    FakeApi? fake,
    String namespace = 'test',
    bool signedIn = true,
    String? localeCode = 'ko',
    ThemeMode themeMode = ThemeMode.dark,
    String role = 'customer',
  }) async {
    final f = fake ?? FakeApi();
    final storage = FakeStorage({'app.locale': ?localeCode});
    final session = Session(namespace: namespace, storage: storage);
    final api = ApiClient(baseUrl: baseUrl, session: session, client: f.client);
    if (signedIn) {
      await session.save({
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'role': role,
        'subject': 'user-1',
      });
    }
    final locale = LocaleController(storage: storage);
    await locale.restore();
    final theme = ThemeController(storage: storage);
    await theme.set(themeMode);
    return TestEnv._(
      fake: f,
      storage: storage,
      session: session,
      api: api,
      locale: locale,
      theme: theme,
    );
  }
}
