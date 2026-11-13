import 'package:console/screens/people.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Finder _selectable(String value) => find.byWidgetPredicate(
  (w) => w is SelectableText && (w.data ?? '').contains(value),
);

void main() {
  testWidgets(
    'an owner invites a consultant and copies the one-time code by hand',
    (tester) async {
      setViewport(tester, wideSize);
      final fake = FakeApi()
        ..reply('GET', '/admin/staff', <Json>[])
        ..onPost(
          '/admin/staff/invite',
          (_) => {'id': 'st-9', 'expires_in': 86400, 'code': '135790'},
        );
      final env = await TestEnv.create(fake: fake, role: 'staff_admin');
      await pumpConsoleScreen(tester, env, const StaffScreen());
      await settle(tester);

      await tester.tap(find.text(koT.cStaffInvite));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, koT.cName), '박서연');
      await tester.enterText(
        find.widgetWithText(TextField, koT.cEmail),
        'seoyeon@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, koT.cStaffPhone),
        '010-1234-5678',
      );
      await tester.tap(find.text(koT.cStaffChannelCopy));
      await tester.tap(find.widgetWithText(FilledButton, koT.cStaffSendCode));
      await settle(tester);

      final sent = fake.lastCall('POST', '/admin/staff/invite')!.json;
      expect(sent['role'], 'consultant');
      expect(sent['channel'], 'copy');
      expect(sent['phone'], '010-1234-5678');
      expect(find.text(koT.cStaffCodeTitle), findsOneWidget);
      expect(_selectable('135790'), findsOneWidget);
      await unmount(tester);
    },
  );
}
