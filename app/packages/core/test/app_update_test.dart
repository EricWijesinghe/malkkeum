import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Json _brand({String? min, String? latest}) => {
  'name': '말끔',
  'app_store_url': 'https://apps.apple.com/kr/app/customer',
  'play_store_url': 'https://play.google.com/store/apps/details?id=customer',
  'partner_app_store_url': 'https://apps.apple.com/kr/app/partner',
  'partner_play_store_url': 'http://insecure.example/partner',
  'app_versions': {
    'customer': {'min_app_version': ?min, 'latest_app_version': ?latest},
  },
};

Widget _host(ApiClient api, {required String current, Widget? child}) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: T.delegate.supportedLocales,
  localizationsDelegates: const [
    T.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: UpdateGate(
    api: api,
    app: 'customer',
    currentVersion: () async => current,
    child: child ?? const Text('홈 화면'),
  ),
);

ApiClient _api(Json? brand, {bool offline = false}) => ApiClient(
  baseUrl: 'http://127.0.0.1:8080',
  session: Session(namespace: 'update-test'),
  client: MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    return http.Response(jsonEncode(brand), 200, headers: {'content-type': 'application/json'});
  }),
);

void main() {
  group('compareAppVersions', () {
    test('compares numeric parts, not text', () {
      expect(compareAppVersions('1.2.0', '1.10.0'), lessThan(0));
      expect(compareAppVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('ignores the build suffix and treats missing parts as zero', () {
      expect(compareAppVersions('1.0.0+12', '1.0.0'), 0);
      expect(compareAppVersions('1.2', '1.2.0'), 0);
    });
  });

  group('AppVersionPolicy.from', () {
    test('picks the store link for the app and platform', () {
      final customerIos = AppVersionPolicy.from(_brand(), 'customer', platform: TargetPlatform.iOS);
      final customerAndroid = AppVersionPolicy.from(_brand(), 'customer', platform: TargetPlatform.android);
      final partnerAndroid = AppVersionPolicy.from(_brand(), 'partner', platform: TargetPlatform.android);
      expect(customerIos.storeUrl, 'https://apps.apple.com/kr/app/customer');
      expect(customerAndroid.storeUrl, 'https://play.google.com/store/apps/details?id=customer');
      expect(partnerAndroid.storeUrl, isNull, reason: 'http links are never opened');
    });

    test('malformed versions mean no rule', () {
      final p = AppVersionPolicy.from(_brand(min: '1.0', latest: 'abc'), 'customer');
      expect(p.min, isNull);
      expect(p.latest, isNull);
    });
  });

  testWidgets('blocks with a full-screen update page below the minimum version', (tester) async {
    final api = _api(_brand(min: '1.1.0', latest: '1.2.0'));
    await tester.pumpWidget(_host(api, current: '1.0.0'));
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 필요해요'), findsOneWidget);
    expect(find.text('홈 화면'), findsNothing);
  });

  testWidgets('shows a dismissible banner below the latest version', (tester) async {
    final api = _api(_brand(min: '1.0.0', latest: '1.2.0'));
    await tester.pumpWidget(_host(api, current: '1.0.0'));
    await tester.pumpAndSettle();
    expect(find.text('새 버전 1.2.0이 나왔어요'), findsOneWidget);
    expect(find.text('홈 화면'), findsOneWidget);
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(find.text('새 버전 1.2.0이 나왔어요'), findsNothing);
  });

  testWidgets('stays silent when up to date or offline', (tester) async {
    await tester.pumpWidget(_host(_api(_brand(min: '1.0.0', latest: '1.2.0')), current: '1.2.0'));
    await tester.pumpAndSettle();
    expect(find.textContaining('나왔어요'), findsNothing);
    expect(find.text('홈 화면'), findsOneWidget);

    await tester.pumpWidget(_host(_api(null, offline: true), current: '0.1.0'));
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 필요해요'), findsNothing);
    expect(find.text('홈 화면'), findsOneWidget);
  });
}
