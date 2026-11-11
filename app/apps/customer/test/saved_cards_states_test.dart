import 'dart:async';

import 'package:core/core.dart';
import 'package:customer/screens/pay_method_picker.dart';
import 'package:customer/screens/payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// PortOne configured for card and kakaopay, so the saved-card section appears.
FakeApi _api({required FutureOr<Object?> Function(ApiCall call)? channels, List<Json>? methods}) {
  // First matching route wins, so a test-specific channel handler is registered before the default.
  final fake = FakeApi();
  if (channels != null) {
    fake.onGet('/payments/methods', channels);
  } else {
    fake.reply('GET', '/payments/methods', [
      {'code': 'card', 'flow': 'billing'},
      {'code': 'kakaopay', 'flow': 'billing'},
    ]);
  }
  fake.reply('GET', '/me/payment-methods/setup', {'enabled': true, 'store_id': 'store-1', 'channels': {'card': 'ch-card', 'kakaopay': 'ch-kp'}, 'issue_id': 'iss-1'});
  stockCustomerApi(fake, methods: methods ?? [paymentMethodJson()]);
  return fake;
}

void main() {
  testWidgets('the saved-cards screen shows a spinner while the channel list loads', (tester) async {
    setViewport(tester, phoneSize);
    final pending = Completer<Object?>();
    final env = await TestEnv.create(fake: _api(channels: (_) => pending.future));
    final app = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    unawaited(app.loadMethods());
    await settle(tester, duration: const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'spinner until the channel list arrives');
    expect(find.text(koT.apPayManageTitle), findsNothing);
    pending.complete(const <Json>[]);
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('a failed channel load shows the localized server message and retry, never the exception', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api(channels: (_) => const ApiReply(502, {'error': {'code': 'provider_unreachable'}})));
    await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await pumpUntilFound(tester, find.text(koT.err_provider_unreachable));

    expect(find.text(koT.retry), findsOneWidget);
    expect(find.textContaining('ApiException'), findsNothing);
    expect(find.text(koT.errorGeneric), findsNothing, reason: 'the specific message is shown, not the generic fallback');
    await unmount(tester);
  });

  testWidgets('no saved cards shows the empty message and no registration tiles without PortOne', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi()
      ..reply('GET', '/payments/methods', [{'code': 'card', 'flow': 'billing'}])
      ..reply('GET', '/me/payment-methods/setup', {'enabled': false});
    stockCustomerApi(fake, methods: const <Json>[]);
    final env = await TestEnv.create(fake: fake);
    await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    await settle(tester);

    expect(find.text(koT.methodsEmpty), findsOneWidget);
    expect(find.byType(PayChannelTile), findsNothing);
    await unmount(tester);
  });

  testWidgets('saved cards are listed with a delete control that has a label', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api(channels: null));
    final app = await pumpCustomerScreen(tester, env, const PaymentMethodsScreen());
    unawaited(app.loadMethods());
    await pumpUntilFound(tester, find.text('신한 1234'));

    expect(find.byTooltip(koT.delete), findsOneWidget, reason: 'icon-only delete has a tooltip for screen readers');
    await unmount(tester);
  });
}
