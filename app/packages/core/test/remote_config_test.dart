import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget _host(ApiClient api) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    T.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: RemoteConfigGate(api: api, child: const Text('홈 화면')),
);

ApiClient _api(Json? body, {bool offline = false}) => ApiClient(
  baseUrl: 'http://127.0.0.1:8080',
  session: Session(namespace: 'remote-config-test'),
  client: MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
);

void main() {
  test('missing or malformed fields mean on and no maintenance', () {
    final c = RemoteConfig.fromJson({
      'flags': {'booking': false, 'chat': 'no', 3: true},
      'maintenance': 'x',
    });
    expect(c.isOn('booking'), isFalse);
    expect(c.isOn('chat'), isTrue);
    expect(c.isOn('unknown_future_flag'), isTrue);
    expect(c.maintenance, isFalse);
  });

  test('maintenance message is trimmed', () {
    final c = RemoteConfig.fromJson({
      'maintenance': {'on': true, 'message': '  곧 돌아와요  '},
    });
    expect(c.maintenance, isTrue);
    expect(c.maintenanceMessage, '곧 돌아와요');
  });

  testWidgets('shows a banner over the app while switched on', (tester) async {
    await tester.pumpWidget(
      _host(
        _api({
          'maintenance': {'on': true, 'message': '  곧 돌아와요  '},
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget, reason: 'the app stays usable');
    expect(find.text('점검 중이에요'), findsOneWidget);
    expect(find.text('곧 돌아와요'), findsOneWidget);
    expect(find.text('점검 중에는 새 예약을 받지 않아요.'), findsOneWidget);
  });

  testWidgets('shows the app without a banner when maintenance is off', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _api({
          'maintenance': {'on': false},
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
    expect(find.text('점검 중이에요'), findsNothing);
  });

  testWidgets('children see maintenance so booking screens can hold submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          T.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RemoteConfigGate(
          api: _api({
            'maintenance': {'on': true},
          }),
          child: Builder(
            builder: (context) => Text(
              RemoteConfigScope.of(context).maintenance ? 'paused' : 'open',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('paused'), findsOneWidget);
  });

  testWidgets('offline keeps the app usable', (tester) async {
    await tester.pumpWidget(_host(_api(null, offline: true)));
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
  });
}
