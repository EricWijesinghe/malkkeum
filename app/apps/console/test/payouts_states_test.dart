import 'dart:async';

import 'package:console/screens/people.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';
import 'support/payout_fixtures.dart';

/// The payouts tab: loading, error, empty and rows (all four payout states), as an owner-admin sees it.
Future<void> _pumpPayouts(WidgetTester tester, FakeApi fake) async {
  final env = await TestEnv.create(fake: fake, role: 'staff_admin');
  await pumpConsoleScreen(tester, env, const SettlementsScreen(initialPayouts: true));
}

void main() {
  testWidgets('payouts tab shows skeletons while the list loads', (tester) async {
    setViewport(tester, phoneSize);
    final never = Completer<Object?>();
    final fake = FakeApi()..onGet('/admin/settlements/payouts', (_) => never.future);
    await _pumpPayouts(tester, fake);
    await settle(tester, duration: const Duration(milliseconds: 300));

    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text(koT.poNoPayouts), findsNothing);
    never.complete(const <Json>[]);
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('payouts tab shows the localized server message on failure, never raw exception text', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/admin/settlements/payouts', {'error': {'code': 'provider_unreachable'}}, status: 502);
    await _pumpPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.err_provider_unreachable));

    expect(find.text(koT.retry), findsOneWidget);
    expect(find.textContaining('ApiException'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    await unmount(tester);
  });

  testWidgets('payouts tab shows an empty state when there are no payouts', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()..reply('GET', '/admin/settlements/payouts', const <Json>[]);
    await _pumpPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poNoPayouts));

    expect(find.byType(EmptyState), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('payouts tab lists a row for each state with the matching action', (tester) async {
    setViewport(tester, tallPhoneSize);
    final fake = FakeApi()..reply('GET', '/admin/settlements/payouts', payoutRows);
    await _pumpPayouts(tester, fake);
    await pumpUntilFound(tester, find.text(koT.poState_requested));

    for (final label in [koT.poState_requested, koT.poState_sent, koT.poState_paid, koT.poState_failed]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // requested + manual: reveal account and confirm; sent: sync; failed: retry.
    expect(find.text(koT.poShowAccount), findsOneWidget);
    expect(find.text(koT.poConfirmPaid), findsOneWidget);
    expect(find.text(koT.poSync), findsOneWidget);
    expect(find.text(koT.poRetry), findsOneWidget);
    await unmount(tester);
  });
}
