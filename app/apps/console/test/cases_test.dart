import 'package:console/screens/cases.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget testApp(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    T.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: ListView(children: [child])),
);

Json _row({String status = 'open'}) => {'id': 'c1', 'kind': 'no_show', 'status': status, 'booking_number': 'B-1', 'overdue': true};

Json _detail({String status = 'open', bool checkedIn = false}) => {
  'case': {'id': 'c1', 'kind': 'no_show', 'status': status, 'summary': '도착 확인 없음', 'booking_id': 'b1'},
  'booking': {'id': 'b1', 'checked_in_at': checkedIn ? '2026-11-11T00:58:00Z' : null, 'checked_out_at': null},
  'notes': [
    {'author': '운영', 'body': '기사 연락함'},
  ],
};

void main() {
  test('a case moves only along open -> investigating -> resolved or rejected', () {
    expect(caseNextStatuses('open'), ['investigating', 'rejected']);
    expect(caseNextStatuses('investigating'), ['resolved', 'rejected']);
    expect(caseNextStatuses('resolved'), isEmpty);
    expect(caseNextStatuses('rejected'), isEmpty);
  });

  testWidgets('queue lists cases with overdue flag, and opening one shows its status moves and notes', (tester) async {
    final updates = <String>[];
    await tester.pumpWidget(testApp(CaseQueue(
      fetch: () async => [_row()],
      detail: (id) async => _detail(),
      update: (id, body) async {
        updates.add('$id:${body['status']}');
        return _detail(status: 'investigating');
      },
      reassign: (id, body) async => _detail(),
      isAdmin: false,
    )));
    await tester.pumpAndSettle();
    expect(find.text('기한 초과'), findsOneWidget);
    expect(find.text('도착 확인 없음'), findsNothing, reason: 'detail is closed until opened');

    await tester.tap(find.text('B-1 · 접수'));
    await tester.pumpAndSettle();
    expect(find.text('도착 확인 없음'), findsOneWidget);
    expect(find.text('· 운영: 기사 연락함'), findsOneWidget);
    expect(find.text('조사 중'), findsOneWidget);
    expect(find.text('환불'), findsNothing, reason: 'refund is admin-only');

    await tester.tap(find.text('조사 중'));
    await tester.pumpAndSettle();
    expect(updates, ['c1:investigating']);
  });

  testWidgets('reassign and the arrival time show for a no-show job that has a booking', (tester) async {
    var reassigned = 0;
    await tester.pumpWidget(testApp(CaseQueue(
      fetch: () async => [_row()],
      detail: (id) async => _detail(checkedIn: true),
      update: (id, body) async => _detail(),
      reassign: (id, body) async {
        reassigned++;
        return _detail();
      },
      isAdmin: true,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B-1 · 접수'));
    await tester.pumpAndSettle();
    expect(find.text('환불'), findsWidgets, reason: 'admin sees refund controls');
    await tester.tap(find.text('기사 재배정'));
    await tester.pumpAndSettle();
    expect(reassigned, 1);
  });
}
