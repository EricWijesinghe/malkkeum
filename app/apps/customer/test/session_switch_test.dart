import 'package:core/core.dart';
import 'package:customer/main.dart';
import 'package:customer/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_routes.dart';

/// Counts how often the shell (re)binds live updates.
class _CountingRealtime extends FakeRealtime {
  _CountingRealtime(super.api);
  int connects = 0;

  @override
  void connect() => connects++;
}


const _tokenB = 'access-b';

/// Answers each account's own data, chosen by the bearer token of the call.
void _stockTwoAccounts(FakeApi fake) {
  bool isB(ApiCall c) => c.headers['authorization'] == 'Bearer $_tokenB';
  fake
    ..onGet('/me', (c) => {'name': isB(c) ? '비회원' : '에이씨', 'phone': isB(c) ? '01099998888' : '01011112222', 'email': null})
    ..onGet('/me/addresses', (c) => [addressJson(id: isB(c) ? 'addr-b' : 'addr-a')])
    ..onGet('/me/coupons', (c) => isB(c) ? const <Json>[] : [couponJson(id: 'cp-a', name: '첫 예약 쿠폰', amount: 5000)])
    ..onGet('/me/payment-methods', (c) => [paymentMethodJson(id: isB(c) ? 'pm-b' : 'pm-a')])
    ..onGet('/me/points', (c) => {'balance': isB(c) ? 0 : 4200});
  stockCustomerApi(fake);
}

void main() {
  testWidgets('sign-out clears the last account and the next sign-in loads and binds its own', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    _stockTwoAccounts(fake);
    final env = await TestEnv.create(fake: fake);
    final realtime = _CountingRealtime(env.api);
    final pushStarts = <String?>[];
    final app = AppState(env.api, realtime, startPush: (api) async => pushStarts.add(api.session.subject));
    await tester.pumpWidget(CustomerApp(session: env.session, app: app, locale: env.locale, theme: env.theme));
    await settle(tester);

    expect(app.name, '에이씨');
    expect(app.addresses.single.id, 'addr-a');
    expect(app.points, 4200);
    expect(realtime.connects, 1);
    expect(pushStarts, ['user-1']);

    await env.session.logout();
    await settle(tester);

    // Guest: nothing of A is left in state or anywhere on screen (hidden tabs included).
    expect(app.name, isEmpty);
    expect(app.phone, isEmpty);
    expect(app.addresses, isEmpty);
    expect(app.coupons, isEmpty);
    expect(app.methods, isEmpty);
    expect(app.points, isNull);
    expect(app.unreadChats, 0);
    expect(find.textContaining('에이씨', skipOffstage: false), findsNothing);
    expect(app.services, isNotEmpty, reason: 'the public catalogue stays');

    final meCallsBefore = fake.callsTo('GET', '/me').length;
    await env.session.save({
      'access_token': _tokenB,
      'refresh_token': 'refresh-b',
      'role': 'customer',
      'subject': 'user-b',
    });
    await settle(tester);

    final meB = fake.callsTo('GET', '/me').skip(meCallsBefore);
    expect(meB.single.headers['authorization'], 'Bearer $_tokenB');
    expect(app.name, '비회원');
    expect(app.addresses.single.id, 'addr-b');
    expect(app.methods.single.id, 'pm-b');
    expect(find.textContaining('에이씨', skipOffstage: false), findsNothing);
    expect(realtime.connects, 2, reason: 'live updates re-bound for the new account');
    expect(pushStarts, ['user-1', 'user-b'], reason: 'push token registered for the new account');
    await unmount(tester);
  });

  testWidgets('a response for the old account that lands after sign-out is dropped', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    var slowMe = false;
    fake.onGet('/me', (c) async {
      if (slowMe) await Future<void>.delayed(const Duration(seconds: 1));
      return {'name': '에이씨', 'phone': '01011112222', 'email': null};
    });
    stockCustomerApi(fake);
    final env = await TestEnv.create(fake: fake);
    final app = AppState(env.api, FakeRealtime(env.api), startPush: (_) async {});
    await tester.pumpWidget(CustomerApp(session: env.session, app: app, locale: env.locale, theme: env.theme));
    await settle(tester);

    slowMe = true;
    final pending = app.loadProfile();
    await env.session.logout();
    await tester.pump(const Duration(seconds: 2));
    await pending;
    expect(app.name, isEmpty);
    await unmount(tester);
  });
}
