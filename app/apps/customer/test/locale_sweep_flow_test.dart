import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// U5 booking flows on the smallest phone at large system fonts, in every language.
const _smallPhone = Size(320, 568);

void _noException(WidgetTester tester, String what) {
  final e = tester.takeException();
  expect(e, isNull, reason: '$what: ${e is FlutterError ? e.toStringDeep() : e}');
}

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;
    for (final scale in const [1.3, 2.0]) {
      testWidgets('[$code x$scale] studio, AC, move steps, Safe booking and checkout fit a small phone', (tester) async {
        setViewport(tester, _smallPhone);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final t = lookupT(locale);
        final fake = FakeApi()
          ..reply('POST', '/quote/estimate', {
            'base': 300000, 'extras': 30000, 'surcharge_bps': 1500, 'peak_bps': 2000, 'peak': 66000,
            'before_vat': 445500, 'addons': 71100, 'addon_discount_bps': 1000, 'total': 561200,
          })
          ..reply('GET', '/policy/cancellation', {
            'policy': {'min_fee': 0, 'tiers': [{'min_days': 2, 'percent': 0}, {'min_days': 0, 'percent': 50}]},
          });
        stockCustomerApi(fake, name: 'Nguyễn Thị Phương Thảo');
        final env = await TestEnv.create(fake: fake, localeCode: code);
        final app = AppState(env.api, FakeRealtime(env.api));
        await app.loadAll();
        Future<void> show(Widget home, String what) async {
          await tester.pumpWidget(CustomerTestHost(env: env, app: app, home: home));
          await settle(tester, duration: const Duration(milliseconds: 400));
          _noException(tester, what);
        }

        await show(ServiceScreen(service: app.service('studio')!), 'studio');
        await show(ServiceScreen(service: app.service('aircon')!), 'aircon');

        await show(QuoteFlowScreen(service: app.service('move_out')!), 'move step 1');
        await tester.tap(find.text(t.type_standard));
        await settle(tester);
        await tester.tap(find.text(t.next).last);
        await settle(tester, duration: const Duration(milliseconds: 400));
        _noException(tester, 'move step 2');
        await tester.tap(find.text(t.building_other));
        await settle(tester);
        _noException(tester, 'move step 2 others');
        await tester.tap(find.text(t.building_apartment));
        await tester.tap(find.text(t.layout_two_rooms));
        await settle(tester);
        await tester.scrollUntilVisible(find.text(t.yes).first, 200, scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text(t.yes).first);
        await settle(tester);
        await tester.tap(find.text(t.next).last);
        await settle(tester, duration: const Duration(milliseconds: 400));
        _noException(tester, 'move step 3');

        final d = BookingDraft(app.service('move_out')!)
          ..address = app.addresses.first
          ..date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 5))
          ..hour = 8
          ..answers.cleaningType = 'standard'
          ..answers.building = 'commercial'
          ..answers.layout = 'two_rooms'
          ..answers.duplex = true
          ..answers.elevator = false
          ..answers.acAddons['two_in_one'] = 1;
        fake.reply('GET', '/slots', [slotJson(8), slotJson(13)]);
        await show(ScheduleScreen(draft: d, step: 4, total: 5), 'move step 4 + AC banner');
        await tester.tap(find.text(t.dfAcAddonAdd).last);
        await settle(tester, duration: const Duration(milliseconds: 400));
        _noException(tester, 'AC add-on sheet');
        await show(QuoteConfirmScreen(draft: d), 'Safe booking');

        final studio = BookingDraft(app.service('studio')!)
          ..address = app.addresses.first
          ..date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 5))
          ..hour = 9;
        await show(CheckoutScreen(draft: studio), 'checkout');
        await tester.scrollUntilVisible(find.text(t.dfPgNotice), 300, scrollable: find.byType(Scrollable).first);
        await settle(tester);
        _noException(tester, 'checkout PG notice');
        await unmount(tester);
      });
    }
  }
}
