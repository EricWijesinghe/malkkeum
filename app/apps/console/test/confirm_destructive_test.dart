import 'package:console/screens/people.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

const _staffPath = '/admin/staff/s-1/active';

Future<void> _pumpStaff(WidgetTester tester, FakeApi fake) async {
  final env = await TestEnv.create(fake: fake, role: 'staff_admin');
  await pumpConsoleScreen(tester, env, const StaffScreen());
}

FakeApi _staffFake() => FakeApi()
  ..reply('GET', '/admin/staff', [
    {'id': 's-1', 'name': 'Kim', 'email': 'kim@example.com', 'role': 'consultant', 'active': true},
  ])
  ..reply('POST', _staffPath, {'ok': true});

void main() {
  testWidgets('deactivating staff asks first and sends nothing when cancelled', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = _staffFake();
    await _pumpStaff(tester, fake);
    await pumpUntilFound(tester, find.widgetWithText(TextButton, koT.cDeactivate));

    await tester.tap(find.widgetWithText(TextButton, koT.cDeactivate));
    await pumpUntilFound(tester, find.text(koT.cConfirmAsk));
    await tester.tap(find.widgetWithText(TextButton, koT.cancel));
    await settle(tester);

    expect(fake.callsTo('POST', _staffPath), isEmpty);
    await unmount(tester);
  });

  testWidgets('deactivating staff sends the change once confirmed', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = _staffFake();
    await _pumpStaff(tester, fake);
    await pumpUntilFound(tester, find.widgetWithText(TextButton, koT.cDeactivate));

    await tester.tap(find.widgetWithText(TextButton, koT.cDeactivate));
    await pumpUntilFound(tester, find.text(koT.cConfirmAsk));
    await tester.tap(find.widgetWithText(FilledButton, koT.cDeactivate));
    await settle(tester);

    final calls = fake.callsTo('POST', _staffPath);
    expect(calls, hasLength(1));
    expect(calls.single.body, {'active': false});
    await unmount(tester);
  });
}
