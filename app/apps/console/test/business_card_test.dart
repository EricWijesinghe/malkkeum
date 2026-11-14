import 'package:console/screens/setup_business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

Widget _scrolled(Widget child) => SingleChildScrollView(child: child);

void main() {
  testWidgets(
    'a colour white text cannot read gets a warning that the apps will not use it',
    (tester) async {
      setViewport(tester, wideSize);
      final env = await TestEnv.create(fake: FakeApi(), role: 'staff_admin');
      await pumpConsoleScreen(
        tester,
        env,
        _scrolled(
          BusinessCard(
            initial: const {'primary_color': '#0B5D2A'},
            onSaved: () {},
          ),
        ),
      );
      await settle(tester);
      expect(find.text(koT.cSetupColorContrast), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, '#RRGGBB'),
        '#FFD95A',
      );
      await settle(tester, duration: const Duration(milliseconds: 200));

      expect(find.text(koT.cSetupColorContrast), findsOneWidget);
      expect(koT.cSetupColorContrast, contains('앱에는 적용되지 않아요'));

      await tester.enterText(
        find.widgetWithText(TextField, '#RRGGBB'),
        '#0B5D2A',
      );
      await settle(tester, duration: const Duration(milliseconds: 200));
      expect(find.text(koT.cSetupColorContrast), findsNothing);
      await unmount(tester);
    },
  );
}
