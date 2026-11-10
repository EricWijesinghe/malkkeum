import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

void main() {
  testWidgets('home greets the customer by name and lists 8 service tiles with prices', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, name: '지민');
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.homeGreeting('지민')));

    for (final code in catalogCodes) {
      expect(find.bySemanticsLabel(koT.service(code)), findsWidgets, reason: 'tile for $code');
    }

    // Tile tags: cheapest unit / fixed price with the "from" wording, quote services get the badge.
    expect(find.text(koT.fromPrice(formatWon(45000, 'ko'))), findsNWidgets(2), reason: 'studio + kitchen');
    expect(find.text(koT.fromPrice(formatWon(39000, 'ko'))), findsOneWidget, reason: 'bathroom');
    expect(find.text(koT.fromPrice(formatWon(59000, 'ko'))), findsNWidgets(2), reason: 'mattress + sofa');
    expect(find.text(koT.fromPrice(formatWon(79000, 'ko'))), findsOneWidget, reason: 'aircon');
    expect(find.text(koT.quoteBadge), findsNWidgets(2), reason: 'move in + move out');
    await unmount(tester);
  });

  testWidgets('home falls back to the anonymous greeting when the profile has no name', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake, name: '');
    final env = await TestEnv.create(fake: fake);

    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.homeGreetingAnon));
    expect(find.text(koT.homeServices), findsOneWidget);
    await unmount(tester);
  });
}
