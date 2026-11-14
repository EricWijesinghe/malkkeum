import 'package:core/core.dart';
import 'package:customer/screens/subscribe.dart';
import 'package:customer/screens/subscriptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _sub(String id, String status) => {
  'id': id,
  'user_id': 'u-1',
  'service_code': 'studio',
  'unit_index': null,
  'address_id': 'addr-1',
  'payment_method_id': 'pm-1',
  'preferred_pro_id': null,
  'cadence_weeks': 1,
  'weekday': 0,
  'start_hour': 9,
  'anchor_date': '2026-11-16',
  'status': status,
  'paused_reason': null,
  'discount_percent': 0,
  'consecutive_failures': 0,
  'created_at': '2026-11-10T00:00:00Z',
  'cancelled_at': null,
};

FakeApi _subscribeApi() {
  final fake = FakeApi()
    ..reply('GET', '/policy/subscription', {'discount_percent': 10, 'is_default': false})
    ..reply('POST', '/subscriptions', {'subscription': _sub('s-new', 'active'), 'visits': const <Json>[]});
  stockCustomerApi(fake);
  return fake;
}

/// Picks studio, the address and the card, then a biweekly Monday at 13:00.
Future<void> _chooseSubscription(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('sub-service')));
  await settle(tester);
  await tester.tap(find.text(koT.service('studio')).last);
  await settle(tester);

  await tester.tap(find.byKey(const Key('sub-address')));
  await settle(tester);
  await tester.tap(find.text(addressJson()['label'] as String).last);
  await settle(tester);

  await tester.tap(find.byKey(const Key('sub-method')));
  await settle(tester);
  await tester.tap(find.text(paymentMethodJson()['display_name'] as String).last);
  await settle(tester);

  await tester.tap(find.text(koT.subBiweekly));
  await tester.tap(find.text('13:00'));
  await settle(tester);
}

void main() {
  testWidgets('subscribe sends the chosen service, address, card, cadence, weekday and hour', (tester) async {
    setViewport(tester, phoneSize);
    final fake = _subscribeApi();
    final env = await TestEnv.create(fake: fake);
    final app = await pumpCustomerScreen(tester, env, const SubscribeScreen());
    // The Shell has loaded these before the screen can be opened in the app.
    await app.loadAll();
    await settle(tester);

    expect(find.text(koT.subDiscountNote('10')), findsOneWidget);
    await _chooseSubscription(tester);

    await tester.tap(find.byKey(const Key('sub-submit')));
    await settle(tester);

    final post = fake.calls.lastWhere((c) => c.method == 'POST' && c.path == '/subscriptions');
    final body = post.body! as Json;
    expect(body['service_code'], 'studio');
    expect(body['address_id'], addressJson()['id']);
    expect(body['payment_method_id'], paymentMethodJson()['id']);
    expect(body['cadence_weeks'], 2);
    expect(body['weekday'], 0);
    expect(body['start_hour'], 13);
    await unmount(tester);
  });

  testWidgets('submit stays disabled until service, address and card are chosen', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _subscribeApi());
    await pumpCustomerScreen(tester, env, const SubscribeScreen());
    await settle(tester);

    final button = tester.widget<FilledButton>(find.byKey(const Key('sub-submit')));
    expect(button.onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('maintenance holds the subscribe submit even when everything is chosen', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _subscribeApi());
    final app = await pumpCustomerScreen(
      tester,
      env,
      const RemoteConfigScope(config: RemoteConfig(maintenance: true), child: SubscribeScreen()),
    );
    await app.loadAll();
    await settle(tester);
    await _chooseSubscription(tester);

    final button = tester.widget<FilledButton>(find.byKey(const Key('sub-submit')));
    expect(button.onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('the list shows each subscription status and opens the manage view', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/subscriptions', [_sub('s-1', 'active'), _sub('s-2', 'paused')])
      ..reply('GET', '/subscriptions/s-1', {'subscription': _sub('s-1', 'active'), 'visits': const <Json>[]});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const SubscriptionsScreen());
    await settle(tester);

    expect(find.text(koT.subStatusActive), findsOneWidget);
    expect(find.text(koT.subStatusPaused), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await settle(tester);
    expect(find.byKey(const Key('sub-pause')), findsOneWidget);
    expect(find.byKey(const Key('sub-resume')), findsNothing);
    await unmount(tester);
  });

  testWidgets('pausing from the manage view posts the pause and shows the new status', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/subscriptions', [_sub('s-1', 'active')])
      ..reply('GET', '/subscriptions/s-1', {'subscription': _sub('s-1', 'active'), 'visits': const <Json>[]})
      ..reply('POST', '/subscriptions/s-1/pause', {'subscription': _sub('s-1', 'paused'), 'visits': const <Json>[]});
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const SubscriptionsScreen());
    await settle(tester);
    await tester.tap(find.byType(ListTile).first);
    await settle(tester);

    await tester.tap(find.byKey(const Key('sub-pause')));
    await settle(tester);

    expect(fake.calls.any((c) => c.method == 'POST' && c.path == '/subscriptions/s-1/pause'), isTrue);
    expect(find.byKey(const Key('sub-resume')), findsOneWidget);
    await unmount(tester);
  });
}
