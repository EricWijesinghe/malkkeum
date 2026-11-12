import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

const _ids = ['nav_home', 'nav_bookings', 'nav_chat', 'nav_more'];

Icon3D _nav(WidgetTester tester, String id) => tester.widget<Icon3D>(
  find.byWidgetPredicate((w) => w is Icon3D && w.id == id),
);

List<bool> _active(WidgetTester tester) => [for (final id in _ids) _nav(tester, id).active];

Future<TestEnv> _env() async {
  final fake = FakeApi();
  stockCustomerApi(
    fake,
    name: '지민',
    threads: [threadJson(id: 't1', unreadMember: 2)],
  );
  return TestEnv.create(fake: fake);
}

void main() {
  testWidgets('bottom nav: 4 Dahae tabs with 3D icons, the selected one active', (tester) async {
    setViewport(tester, phoneSize);
    final env = await _env();
    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.tabHome));
    await settle(tester);

    expect(koT.tabBookings, '내 예약');
    for (final label in [koT.tabHome, koT.tabBookings, koT.tabChat, koT.tabMore]) {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)), findsOneWidget);
    }
    expect(_active(tester), [true, false, false, false]);

    await tester.tap(find.text(koT.tabBookings).last);
    await tester.pump(const Duration(milliseconds: 32));
    // The new tab pops (spring running); settle brings it to rest at the active scale.
    expect(tester.hasRunningAnimations, isTrue);
    await settle(tester);
    expect(_active(tester), [false, true, false, false]);

    await tester.tap(find.text(koT.tabMore).last);
    await settle(tester);
    expect(_active(tester), [false, false, false, true]);

    // Unread chats keep their badge on the 3D chat icon.
    expect(
      find.ancestor(of: find.byWidgetPredicate((w) => w is Icon3D && w.id == 'nav_chat'), matching: find.byType(Badge)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('bottom nav under reduced motion switches tabs without any animation', (tester) async {
    setViewport(tester, phoneSize);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final env = await _env();
    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.text(koT.tabHome));
    await settle(tester);

    await tester.tap(find.text(koT.tabChat).last);
    await tester.pump();
    expect(_active(tester), [false, false, true, false]);
    // No pop transform on any tab icon: the active state is the art alone.
    for (final id in _ids) {
      expect(
        find.descendant(of: find.byWidgetPredicate((w) => w is Icon3D && w.id == id), matching: find.byType(Transform)),
        findsNothing,
        reason: id,
      );
    }
    await unmount(tester);
  });

  testWidgets('wide layout: the side rail uses the same 3D icons', (tester) async {
    setViewport(tester, const Size(1200, 800));
    final env = await _env();
    await pumpCustomerApp(tester, env);
    await pumpUntilFound(tester, find.byType(NavigationRail));
    await settle(tester);
    for (final id in _ids) {
      expect(find.byWidgetPredicate((w) => w is Icon3D && w.id == id), findsOneWidget, reason: id);
    }
    expect(_active(tester).first, isTrue);
    await unmount(tester);
  });

  test('slotRangeLabel shows the arrival window in 24h', () {
    expect(slotRangeLabel(9, 'ko'), '09:00~10:00');
    expect(slotRangeLabel(8, 'en'), '08:00~09:00');
    expect(slotRangeLabel(13, 'vi', hours: 2), '13:00~15:00');
    expect(slotRangeLabel(23, 'ko'), '23:00~00:00');
  });
}
