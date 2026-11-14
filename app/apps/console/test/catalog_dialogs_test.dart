import 'package:console/screens/catalog_counts.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

Json _pricing({int maxEach = 5}) => {
  'type': 'counts',
  'units': [
    {'label_key': 'wall', 'label': '벽걸이', 'minutes': 90, 'price': 79000},
    {'label_key': 'stand', 'label': '스탠드', 'minutes': 120, 'price': 119000},
  ],
  'max_each': maxEach,
  'multi_discount_bps': 1000,
};

/// Opens the counts dialog from a button and records what it returns.
Future<({Json? Function() result, Future<void> Function() open})> _host(
  WidgetTester tester,
  Json pricing,
) async {
  final env = await TestEnv.create(role: 'staff_admin');
  Json? saved;
  var returned = false;
  await pumpConsoleScreen(
    tester,
    env,
    Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () async {
            saved = await askCountsPricing(context, pricing);
            returned = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  return (
    result: () => returned ? saved : null,
    open: () async {
      await tester.tap(find.text('open'));
      await settle(tester);
    },
  );
}

Finder _fields() => find.byType(TextField);

void main() {
  final t = koT;

  testWidgets('a new option is added, keeps a generated key and saves', (
    tester,
  ) async {
    final h = await _host(tester, _pricing());
    await h.open();
    await tester.tap(find.text(t.cntAddOption));
    await settle(tester);
    // Rows are label, price, minutes; the new row is the third one.
    await tester.enterText(_fields().at(6), '소파');
    await tester.enterText(_fields().at(7), '59000');
    await tester.enterText(_fields().at(8), '60');
    await tester.tap(find.widgetWithText(FilledButton, t.save));
    await settle(tester);

    final units = (h.result()!['units'] as List).cast<Json>();
    expect(units, hasLength(3));
    expect(units[2]['label'], '소파');
    expect(units[2]['label_key'], startsWith('opt_'));
    expect(units[2]['price'], 59000);
  });

  testWidgets('the stepper stops at the per-option cap', (tester) async {
    final h = await _host(tester, _pricing(maxEach: 1));
    await h.open();
    final plus = find.byTooltip(t.cntMore).first;
    await tester.tap(plus);
    await settle(tester);
    await tester.tap(plus);
    await settle(tester);
    // The second tap is ignored: the basket shows 1, not 2.
    expect(find.text('2'), findsNothing);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('a cap above 20 blocks saving with a message', (tester) async {
    final h = await _host(tester, _pricing());
    await h.open();
    // The cap field follows the two option rows (3 fields each).
    await tester.enterText(_fields().at(6), '25');
    await tester.tap(find.widgetWithText(FilledButton, t.save));
    await settle(tester);
    expect(find.text(t.cntMaxEachInvalid), findsOneWidget);
    expect(h.result(), isNull);
  });

  testWidgets('moving an option down swaps the saved order and keeps its key', (
    tester,
  ) async {
    final h = await _host(tester, _pricing());
    await h.open();
    await tester.tap(find.byTooltip(t.cntMoveDown).first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, t.save));
    await settle(tester);

    final units = (h.result()!['units'] as List).cast<Json>();
    expect(units.map((u) => u['label_key']).toList(), ['stand', 'wall']);
  });

  testWidgets('cancel returns nothing', (tester) async {
    final h = await _host(tester, _pricing());
    await h.open();
    await tester.tap(find.widgetWithText(TextButton, t.cancel));
    await settle(tester);
    expect(h.result(), isNull);
  });
}
