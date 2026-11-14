import 'package:customer/screens/service_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

void main() {
  test('new service codes map to their own scope groups', () {
    expect(scopeGroupFor('whole_home'), ScopeGroup.wholeHome);
    expect(scopeGroupFor('window'), ScopeGroup.window);
    expect(scopeGroupFor('disinfection'), ScopeGroup.disinfection);
    expect(scopeGroupFor('studio'), ScopeGroup.studio);
  });

  testWidgets('window scope lists the window items for the room', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: FakeApi());
    await pumpCustomerScreen(
      tester,
      env,
      const ServiceScopeScreen(initialGroup: ScopeGroup.window),
    );
    await settle(tester);

    expect(find.text(scopeLabel(koT, 'windows')), findsOneWidget);
    expect(find.text(scopeLabel(koT, 'dusting')), findsOneWidget);
  });

  testWidgets('disinfection chip switches to the pest control items', (
    tester,
  ) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: FakeApi());
    await pumpCustomerScreen(tester, env, const ServiceScopeScreen());
    await settle(tester);

    await _tap(tester, find.text(koT.dfScopeDisinfGroup));
    expect(find.text(scopeLabel(koT, 'pest')), findsOneWidget);
    expect(find.text(scopeLabel(koT, 'mite')), findsOneWidget);
    expect(find.text(koT.dfNotProvided), findsOneWidget);
  });
}
