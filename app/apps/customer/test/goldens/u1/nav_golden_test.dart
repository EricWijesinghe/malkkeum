@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import '../../support/customer_host.dart';
import '../../support/customer_routes.dart';
import '../../support/golden_fonts.dart';

void main() {
  for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
    final file = 'nav_${mode.name}.png';
    testWidgets(
      'bottom nav golden (${mode.name})',
      (tester) async {
        setViewport(tester, phoneSize);
        await loadGoldenFonts(tester);
        final fake = FakeApi();
        stockCustomerApi(fake, name: '지민', threads: [threadJson(id: 't1', unreadMember: 2)]);
        final env = await TestEnv.create(fake: fake, themeMode: mode);
        await pumpCustomerApp(tester, env);
        await pumpUntilFound(tester, find.text(koT.tabHome));
        await settle(tester);
        await precacheIcon3D(tester);
        await settle(tester);
        await expectLater(find.byType(NavigationBar), matchesGoldenFile(file));
        await unmount(tester);
      },
      skip: !goldensEnabled('test/goldens/u1/$file'),
    );
  }
}
