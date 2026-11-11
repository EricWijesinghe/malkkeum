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

  testWidgets('shows the maintenance page while switched on', (tester) async {
    await tester.pumpWidget(
      _host(
        _api({
          'maintenance': {'on': true, 'message': ''},
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsNothing);
    expect(find.text('점검 중이에요'), findsOneWidget);
  });

  testWidgets('shows the app when maintenance is off', (tester) async {
    await tester.pumpWidget(
      _host(
        _api({
          'maintenance': {'on': false},
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
  });

  testWidgets('offline keeps the app usable', (tester) async {
    await tester.pumpWidget(_host(_api(null, offline: true)));
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
  });
}
