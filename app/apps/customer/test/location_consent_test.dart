import 'package:core/core.dart';
import 'package:customer/screens/addresses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';
import 'support/fake_location.dart';

const _version = '2026-11-17';
const _address = '서울특별시 강남구 테헤란로 152';

Json _consents({required bool location}) => {
  'version': _version,
  'reconsent_required': false,
  'items': [
    {'kind': 'terms', 'required': true, 'granted': true, 'granted_at': null},
    {'kind': 'location', 'required': false, 'granted': location, 'granted_at': null},
  ],
};

FakeApi _api({required bool consented, int consentsStatus = 200}) {
  final fake = FakeApi()
    ..reply('GET', '/features', {'address_search': false, 'card_billing': false})
    ..reply('GET', '/me/consents', _consents(location: consented), status: consentsStatus)
    ..reply('PUT', '/me/consents', _consents(location: true));
  stockCustomerApi(fake);
  return fake;
}

Future<void> _open(WidgetTester tester, FakeApi fake, FakeLocationDevice device) async {
  setViewport(tester, phoneSize);
  final env = await TestEnv.create(fake: fake);
  await pumpCustomerScreen(tester, env, AddressFormScreen(location: device));
  await settle(tester);
}

Future<void> _tapUseLocation(WidgetTester tester) async {
  await tester.tap(find.text(koT.locUseCurrent));
  await settle(tester);
}

String _roadField(WidgetTester tester) =>
    tester.widget<TextField>(find.widgetWithText(TextField, koT.addressRoad)).controller!.text;

void main() {
  testWidgets('first use shows the location terms before the device is asked for anything', (tester) async {
    final fake = _api(consented: false);
    final device = FakeLocationDevice(fix: seoulFix);
    await _open(tester, fake, device);

    await _tapUseLocation(tester);
    expect(find.text(koT.locConsentTitle), findsOneWidget);
    expect(find.text(koT.locConsentBody), findsOneWidget);
    expect(device.permissionAsks, 0, reason: 'no OS prompt before the terms are agreed');

    await tester.tap(find.text(koT.cancel));
    await settle(tester);
    expect(fake.callsTo('PUT', '/me/consents'), isEmpty, reason: 'declining stores no consent');
    expect(device.permissionAsks, 0);
    expect(device.positionReads, 0);
    expect(find.text(koT.addressRoad), findsOneWidget, reason: 'typed entry still works');
    await unmount(tester);
  });

  testWidgets('agreeing stores the consent, then the suggestion waits for confirmation', (tester) async {
    final fake = _api(consented: false);
    final device = FakeLocationDevice(fix: seoulFix);
    await _open(tester, fake, device);

    await _tapUseLocation(tester);
    await tester.tap(find.text(koT.locConsentAgree));
    await settle(tester);

    expect(fake.lastCall('PUT', '/me/consents')!.json, {
      'consents': [
        {'kind': 'location', 'granted': true, 'version': _version},
      ],
    });
    expect(find.text(_address), findsOneWidget);
    expect(_roadField(tester), isEmpty, reason: 'a suggestion is not applied until confirmed');

    await tester.tap(find.text(koT.locUseAddress));
    await settle(tester);
    expect(_roadField(tester), _address);
    expect(fake.calls.where((c) => c.path.startsWith('/me/addresses') && c.method != 'GET'), isEmpty, reason: 'nothing is saved without the save button');
    await unmount(tester);
  });

  testWidgets('a stored consent skips the terms dialog', (tester) async {
    final fake = _api(consented: true);
    final device = FakeLocationDevice(fix: seoulFix);
    await _open(tester, fake, device);

    await _tapUseLocation(tester);
    expect(find.text(koT.locConsentTitle), findsNothing);
    expect(fake.callsTo('PUT', '/me/consents'), isEmpty);
    expect(find.text(_address), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('permission denied shows a short inline message and keeps typed entry', (tester) async {
    final fake = _api(consented: true);
    await _open(tester, fake, FakeLocationDevice(granted: false, fix: seoulFix));

    await _tapUseLocation(tester);
    expect(find.text(koT.locDenied), findsOneWidget);
    expect(find.text(koT.addressRoad), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('a failed consent read shows the error inline and never asks the device', (tester) async {
    final fake = _api(consented: true, consentsStatus: 500);
    final device = FakeLocationDevice(fix: seoulFix);
    await _open(tester, fake, device);

    await _tapUseLocation(tester);
    expect(find.text(koT.errorGeneric), findsOneWidget);
    expect(device.permissionAsks, 0);
    await unmount(tester);
  });
}
