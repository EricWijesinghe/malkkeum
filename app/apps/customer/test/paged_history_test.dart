import 'package:core/core.dart';
import 'package:customer/screens/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _entry(String id, {int amount = 100, String kind = 'earn'}) => {
  'id': id,
  'amount': amount,
  'kind': kind,
  'at': '2026-11-10T03:00:00Z',
};

Json _checkout(String id) => {
  'id': id,
  'amount': 10000,
  'method': 'card',
  'status': 'paid',
  'created_at': '2026-11-10T03:00:00Z',
};

/// A two-page cursor list: [first] answers page 1 (with a cursor header when [hasNext]); later pages answer [second].
void _cursorList(FakeApi fake, String path, Json Function(String id) row, {required String firstId, required String secondId, bool hasNext = true}) {
  fake.onGet(path, (c) {
    if (c.query['cursor'] == null) {
      return ApiReply(200, [row(firstId)], {if (hasNext) 'x-next-cursor': '2'});
    }
    return ApiReply(200, [row(secondId)]);
  });
}

FakeApi _walletApi({bool hasNext = true}) {
  final fake = FakeApi();
  // First match wins: the paged routes go before the stock ones.
  _cursorList(fake, '/me/points/ledger', (id) => _entry(id), firstId: 'e1', secondId: 'e2', hasNext: hasNext);
  fake.reply('GET', '/me/points', {'balance': 1200, 'enabled': true, 'expiring_soon': 0, 'notify_days': 30});
  stockCustomerApi(fake);
  return fake;
}

void main() {
  testWidgets('wallet loads the next ledger page without the user asking', (tester) async {
    final fake = _walletApi();
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const WalletScreen());
    await settle(tester);

    expect(find.text('+100 P'), findsOneWidget, reason: 'page 1');
    expect(find.text('-100 P'), findsNothing);
    expect(fake.callsTo('GET', '/me/points/ledger'), hasLength(2));
    expect(fake.lastCall('GET', '/me/points/ledger')!.query['cursor'], '2');
    await unmount(tester);
  });

  testWidgets('wallet stops asking once the cursor header is gone', (tester) async {
    final fake = _walletApi(hasNext: false);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const WalletScreen());
    await settle(tester);

    expect(find.text('+100 P'), findsOneWidget);
    expect(fake.callsTo('GET', '/me/points/ledger'), hasLength(1), reason: 'end of list: no page 2 request');
    await unmount(tester);
  });

  testWidgets('wallet shows a retry when a ledger page fails and loads it on retry', (tester) async {
    final fake = FakeApi();
    var failNext = true;
    fake.onGet('/me/points/ledger', (c) {
      if (c.query['cursor'] == null) return ApiReply(200, [_entry('e1')], {'x-next-cursor': '2'});
      if (failNext) {
        failNext = false;
        return const ApiReply(500, {'error': {'code': 'internal'}});
      }
      return ApiReply(200, [_entry('e2', amount: -50, kind: 'spend')]);
    });
    fake.reply('GET', '/me/points', {'balance': 1200, 'enabled': true, 'expiring_soon': 0, 'notify_days': 30});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const WalletScreen());
    await settle(tester);

    expect(find.text(koT.retry), findsOneWidget, reason: 'failed page 2 shows a retry row');
    expect(find.text('-50 P'), findsNothing);

    await tester.tap(find.text(koT.retry));
    await settle(tester);
    expect(find.text('-50 P'), findsOneWidget, reason: 'retry loads page 2');
    expect(find.text(koT.retry), findsNothing);
    await unmount(tester);
  });

  testWidgets('payment history loads the next checkouts page on scroll', (tester) async {
    final fake = FakeApi();
    _cursorList(fake, '/checkouts', (id) => _checkout(id), firstId: 'p1', secondId: 'p2');
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const PaymentHistoryScreen());
    await settle(tester);

    expect(find.byKey(const ValueKey('pay-row-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-row-p2')), findsOneWidget, reason: 'page 2 loaded');
    expect(fake.lastCall('GET', '/checkouts')!.query['cursor'], '2');
    await unmount(tester);
  });
}
