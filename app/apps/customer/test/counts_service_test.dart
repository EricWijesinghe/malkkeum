import 'package:core/core.dart';
import 'package:customer/screens/flow_widgets.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/screens/service_counts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// Aircon as the counts catalogue sends it: steppers, 10% off two or more.
Service _aircon() => Service.fromJson({
  'code': 'aircon',
  'pricing': {
    'type': 'counts',
    'multi_discount_bps': 1000,
    'units': [
      {'label_key': 'wall', 'minutes': 90, 'price': 79000},
      {'label_key': 'stand', 'minutes': 120, 'price': 119000},
      {'label_key': 'two_in_one', 'minutes': 180, 'price': 179000},
      {'label_key': 'ceiling', 'minutes': 120, 'price': 139000},
    ],
  },
});

/// Disinfection: each treatment at most once, 10% off two or more.
Service _disinfection() => Service.fromJson({
  'code': 'disinfection',
  'pricing': {
    'type': 'counts',
    'max_each': 1,
    'multi_discount_bps': 1000,
    'units': [
      {'label_key': 'pest', 'minutes': 90, 'price': 80000},
      {'label_key': 'mite_bedbug', 'minutes': 120, 'price': 90000},
      {'label_key': 'sanitize', 'minutes': 90, 'price': 100000},
      {'label_key': 'sick_house', 'minutes': 240, 'price': 300000},
    ],
  },
});

Finder _barAmount(int won) => find.descendant(
  of: find.byType(PriceBar),
  matching: find.text(formatWon(won, 'ko')),
);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

Future<void> _pumpService(WidgetTester tester, Service s) async {
  setViewport(tester, phoneSize);
  final fake = FakeApi();
  stockCustomerApi(fake);
  final env = await TestEnv.create(fake: fake);
  await pumpCustomerScreen(tester, env, ServiceScreen(service: s));
  await settle(tester);
}

void main() {
  testWidgets('aircon steppers: live total, duration and multi-item discount', (
    tester,
  ) async {
    final ac = _aircon();
    await _pumpService(tester, ac);

    // Stand ×2 and wall ×1: 317,000원 less 10% (285,300원), 5시간 30분.
    await _tap(tester, find.byTooltip(koT.countPlus).at(1));
    await _tap(tester, find.byTooltip(koT.countPlus).at(1));
    await _tap(tester, find.byTooltip(koT.countPlus).at(0));

    expect(_barAmount(285300), findsOneWidget);
    expect(find.text(koT.duration(330)), findsOneWidget);
    expect(find.text(koT.countsDiscount('10')), findsOneWidget);
    expect(find.byType(CountsGrid), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('aircon minus stops at zero and no discount under two items', (
    tester,
  ) async {
    final ac = _aircon();
    await _pumpService(tester, ac);

    await _tap(tester, find.byTooltip(koT.countPlus).at(3));
    expect(_barAmount(139000), findsOneWidget);
    expect(find.text(koT.countsDiscount('10')), findsNothing);

    await _tap(tester, find.byTooltip(koT.countMinus).at(3));
    expect(_barAmount(0), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('disinfection cards toggle: pest + sanitize is 162,000원', (
    tester,
  ) async {
    final s = _disinfection();
    await _pumpService(tester, s);

    // Multi-select cards have no stepper.
    expect(find.byTooltip(koT.countPlus), findsNothing);
    await _tap(tester, find.text(koT.unit('pest')));
    await _tap(tester, find.text(koT.unit('sanitize')));
    expect(_barAmount(162000), findsOneWidget);
    expect(find.text(koT.countsDiscount('10')), findsOneWidget);

    // Tapping a picked card clears it.
    await _tap(tester, find.text(koT.unit('pest')));
    expect(_barAmount(100000), findsOneWidget);
    expect(find.text(koT.countsDiscount('10')), findsNothing);
    await unmount(tester);
  });

  testWidgets('next stays disabled until one item is picked', (tester) async {
    await _pumpService(tester, _aircon());
    final next = find.widgetWithText(PrimaryButton, koT.next);
    expect(tester.widget<PrimaryButton>(next).onPressed, isNull);

    await _tap(tester, find.byTooltip(koT.countPlus).at(0));
    expect(tester.widget<PrimaryButton>(next).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('legacy aircon booking starts with its single unit counted', (
    tester,
  ) async {
    final ac = _aircon();
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    // unit_index 1 (스탠드) with no unit_counts: one stand, 119,000원.
    await pumpCustomerScreen(
      tester,
      env,
      ServiceScreen(
        service: ac,
        initialUnit: 1,
        initialCounts: Booking.fromJson({
          'id': 'b',
          'unit_index': 1,
        }).countsOf(4),
      ),
    );
    await settle(tester);
    expect(_barAmount(119000), findsOneWidget);
    expect(find.text(koT.duration(120)), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('counts labels read in Korean for summaries', (tester) async {
    final ac = _aircon();
    expect(koT.unitCounts(ac, [0, 2, 1, 0]), '스탠드 2 · 2in1 1');
    expect(koT.unitCounts(ac, [0, 0, 0, 0]), isEmpty);
  });
}
