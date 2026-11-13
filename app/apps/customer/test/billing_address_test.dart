import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:customer/screens/pay_method_picker.dart';
import 'package:customer/screens/payments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _channel(String code, String flow) => {'code': code, 'flow': flow};

FakeApi _apiWith({required bool billing, required bool addressSearch}) {
  final fake = FakeApi()
    ..reply('GET', '/payments/methods', [_channel('card', 'billing'), _channel('kakaopay', 'billing'), _channel('transfer', 'checkout')])
    ..reply('GET', '/features', {'address_search': addressSearch, 'card_billing': billing})
    ..reply(
      'GET',
      '/me/payment-methods/setup',
      billing ? {'enabled': true, 'store_id': 'store-1', 'channels': {'card': 'ch-card'}, 'issue_id': 'iss-1'} : {'enabled': false},
    );
  stockCustomerApi(fake, methods: const <Json>[]);
  return fake;
}

void main() {
  testWidgets('saved-card section is hidden while PortOne is not configured', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _apiWith(billing: false, addressSearch: false));
    await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await settle(tester);

    expect(find.text(koT.apPayManageTitle), findsNothing, reason: 'no save-card option without a PortOne setup');
    expect(find.byWidgetPredicate((w) => w is PayChannelTile && w.code == 'card'), findsNothing);
    await unmount(tester);
  });

  testWidgets('saved-card section shows only billing channels once PortOne is configured', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _apiWith(billing: true, addressSearch: false));
    await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await settle(tester);

    expect(find.text(koT.apPayManageTitle), findsOneWidget);
    bool tile(String code) => find.byWidgetPredicate((w) => w is PayChannelTile && w.code == code).evaluate().isNotEmpty;
    expect(tile('card'), isTrue);
    expect(tile('kakaopay'), isFalse, reason: 'no channel key for kakaopay');
    expect(tile('transfer'), isFalse, reason: 'checkout channels are not saved');
    await unmount(tester);
  });

  testWidgets('address form has no road search while the juso key is not configured', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _apiWith(billing: false, addressSearch: false));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    expect(find.text(koT.addressSearchButton), findsNothing);
    expect(find.text(koT.addressRoad), findsOneWidget, reason: 'typed road address stays as the fallback');
    await unmount(tester);
  });

  testWidgets('address form offers road search when the server can search', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _apiWith(billing: false, addressSearch: true));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    expect(find.text(koT.addressSearchButton), findsOneWidget);
    await unmount(tester);
  });

  test('billing setup parses off, on and unknown channels', () {
    expect(BillingSetup.fromJson({'enabled': false}).enabled, isFalse);
    final on = BillingSetup.fromJson({'enabled': true, 'store_id': 's', 'channels': {'card': 'c'}, 'issue_id': 'i'});
    expect(on.supports('card'), isTrue);
    expect(on.supports('kakaopay'), isFalse);
    expect(BillingSetup.off.supports('card'), isFalse);
  });

  test('billing key is read from the redirect and empty or missing means cancelled', () {
    expect(billingKeyFromRedirect(Uri.parse('https://x/pay/billing-done.html?billingKey=bk_1')), 'bk_1');
    expect(billingKeyFromRedirect(Uri.parse('https://x/pay/billing-done.html?code=USER_CANCEL')), isNull);
    expect(billingKeyFromRedirect(Uri.parse('https://x/pay/billing-done.html?billingKey=')), isNull);
  });
}
