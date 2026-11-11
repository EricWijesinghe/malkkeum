import 'dart:async';

import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

Json _hit(String road) => {'road_address': road, 'jibun_address': '서울 마포구 상암동 1', 'zip_code': '03922', 'building_name': '상암 아파트'};

/// Juso key configured (`address_search` on) and the given `/address/search` handler.
FakeApi _api(FutureOr<Object?> Function(ApiCall call) search) {
  final fake = FakeApi()
    ..reply('GET', '/features', {'address_search': true, 'card_billing': false})
    ..onGet('/address/search', search);
  stockCustomerApi(fake);
  return fake;
}

/// Types [query] into the road-search box and presses the search button.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.widgetWithText(TextField, koT.addressSearch), query);
  await tester.tap(find.byTooltip(koT.addressSearchButton));
  await tester.pump();
}

void main() {
  testWidgets('a search shows its results as tappable cards', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api((_) => {'results': [_hit('서울특별시 마포구 월드컵북로 400')], 'page': 1}));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    await _search(tester, '월드컵북로');
    await pumpUntilFound(tester, find.text('서울특별시 마포구 월드컵북로 400'));
    expect(find.text(koT.addressNoResults), findsNothing);
    await unmount(tester);
  });

  testWidgets('a search with no hits shows the no-results message and the typed fallback', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api((_) => {'results': const <Json>[], 'page': 1}));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    await _search(tester, '없는주소');
    await pumpUntilFound(tester, find.text(koT.addressNoResults));
    expect(find.text(koT.addressManualEntry), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a failed search shows the localized server message, not the exception', (tester) async {
    setViewport(tester, phoneSize);
    final env = await TestEnv.create(fake: _api((_) => const ApiReply(502, {'error': {'code': 'provider_unreachable'}})));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    await _search(tester, '상암동');
    await pumpUntilFound(tester, find.text(koT.err_provider_unreachable));
    expect(find.textContaining('ApiException'), findsNothing);
    expect(find.text(koT.addressNoResults), findsNothing, reason: 'an error is not an empty result');
    expect(find.text(koT.addressRoad), findsOneWidget, reason: 'typed road address still works');
    await unmount(tester);
  });

  testWidgets('a search in flight shows a progress bar and blocks a second search', (tester) async {
    setViewport(tester, phoneSize);
    final pending = Completer<Object?>();
    final env = await TestEnv.create(fake: _api((_) => pending.future));
    await pumpCustomerScreen(tester, env, const AddressFormScreen());
    await settle(tester);

    await _search(tester, '상암동');
    await settle(tester, duration: const Duration(milliseconds: 300));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final button = tester.widget<IconButton>(find.ancestor(of: find.byTooltip(koT.addressSearchButton), matching: find.byType(IconButton)));
    expect(button.onPressed, isNull, reason: 'search button is disabled while searching');

    pending.complete({'results': const <Json>[], 'page': 1});
    await settle(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await unmount(tester);
  });
}
