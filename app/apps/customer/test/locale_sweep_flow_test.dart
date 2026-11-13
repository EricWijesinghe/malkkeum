import 'package:core/core.dart';
import 'package:customer/screens/booking_flow.dart';
import 'package:customer/screens/quote_flow.dart';
import 'package:customer/screens/request_status.dart';
import 'package:customer/screens/service.dart';
import 'package:customer/screens/service_scope.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

/// U5 booking flows on the smallest phone at large system fonts, in every language.
const _smallPhone = Size(320, 568);

void _noException(WidgetTester tester, String what) {
  final e = tester.takeException();
  expect(
    e,
    isNull,
    reason: '$what: ${e is FlutterError ? e.toStringDeep() : e}',
  );
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: false);
  await settle(tester, duration: const Duration(milliseconds: 400));
}

const _estimate = {
  'base': 300000,
  'extras': 30000,
  'surcharge_bps': 1500,
  'peak_bps': 2000,
  'peak': 66000,
  'before_vat': 445500,
  'addons': 71100,
  'addon_discount_bps': 1000,
  'total': 561200,
  'deposit': 56100,
  'deposit_bps': 1000,
};

FakeApi _api() {
  final fake = FakeApi()
    ..reply('POST', '/quote/estimate', _estimate)
    ..reply('GET', '/slots', [
      slotJson(8),
      slotJson(9),
      slotJson(13, available: false),
      slotJson(14),
    ])
    ..reply('GET', '/public/proof', {
      'reviews': [
        {
          'booking_id': 'b',
          'rating': 5,
          'body': 'Rất sạch sẽ, nhân viên cẩn thận và đúng giờ. Cảm ơn!',
          'name': 'N**',
        },
      ],
    })
    ..reply('GET', '/me/points', {
      'enabled': true,
      'balance': 8000,
      'max_use_bps': 3000,
      'entries': const <Json>[],
    })
    ..reply('GET', '/policy/cancellation', {
      'policy': {
        'min_fee': 0,
        'tiers': [
          {'min_days': 2, 'percent': 0},
          {'min_days': 0, 'percent': 50},
        ],
      },
    });
  stockCustomerApi(
    fake,
    name: 'Nguyễn Thị Phương Thảo',
    addresses: [
      addressJson(sizePyeong: 8),
      addressJson(id: 'a-2', label: 'Parents', sizePyeong: 24),
    ],
    coupons: [couponJson(id: 'cp', name: 'welcome_any', amount: 5000)],
  );
  return fake;
}

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;
    for (final scale in const [1.3, 2.0]) {
      testWidgets(
        '[$code x$scale] studio, AC, scope, move 7 steps, checkout, done and status fit a small phone',
        (tester) async {
          setViewport(tester, _smallPhone);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final t = lookupT(locale);
          // Prints each framework error in full, so a failing locale names the widget.
          final orig = FlutterError.onError;
          FlutterError.onError = (d) {
            debugPrint('SWEEP-ERROR ${d.toString().split('\n').take(30).join('\n')}');
            orig?.call(d);
          };
          addTearDown(() => FlutterError.onError = orig);
          final env = await TestEnv.create(fake: _api(), localeCode: code);
          final app = AppState(env.api, FakeRealtime(env.api));
          await app.loadAll();
          Future<void> show(Widget home, String what) async {
            // A new MaterialApp home does not replace the first route: start each screen from scratch.
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              CustomerTestHost(env: env, app: app, home: home),
            );
            await settle(tester, duration: const Duration(milliseconds: 400));
            _noException(tester, what);
          }

          await show(
            ServiceScreen(service: app.service('studio')!),
            'studio detail',
          );
          await show(ServiceScreen(service: app.service('aircon')!), 'aircon');
          await show(const ServiceScopeScreen(), 'service scope');

          final studio = BookingDraft(app.service('studio')!)
            ..address = app.addresses.first
            ..date = DateUtils.dateOnly(
              DateTime.now(),
            ).add(const Duration(days: 5));
          await show(AddressPickScreen(draft: studio), 'address');
          await show(ScheduleScreen(draft: studio), 'date');
          await _tap(tester, find.text(t.dfSelect));
          _noException(tester, 'slot sheet');
          await show(PrepToolsScreen(draft: studio), 'prep tools');
          await show(CheckoutScreen(draft: studio), 'checkout');
          await tester.scrollUntilVisible(
            find.text(t.dfPgNotice),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await settle(tester);
          _noException(tester, 'checkout PG notice');
          await show(
            DoneScreen(
              booking: Booking.fromJson(
                bookingJson(
                  status: 1,
                  paidAmount: 40000,
                  address: addressJson(),
                ),
              ),
            ),
            'done',
          );

          await show(
            QuoteFlowScreen(service: app.service('move_out')!),
            'move 1/7',
          );
          Finder next() => find.widgetWithText(PrimaryButton, t.next).last;
          await _tap(tester, find.text(t.type_standard));
          await _tap(tester, next());
          _noException(tester, 'move 2/7');
          await _tap(tester, find.text(t.building_apartment));
          await _tap(tester, find.text(t.dfLayoutTwo));
          await _tap(tester, find.text(t.dfNone).last);
          await _tap(tester, next());
          _noException(tester, 'move 3/7');
          await _tap(tester, find.text(t.dfHas).last);
          await _tap(tester, next());
          _noException(tester, 'move 4/7');
          await _tap(tester, next());
          _noException(tester, 'move 5/7');
          await _tap(tester, find.text(t.dfAcAddonAdd));
          _noException(tester, 'AC add-on sheet');
          await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
          await settle(tester, duration: const Duration(milliseconds: 400));
          await _tap(tester, next());
          _noException(tester, 'move 6/7');
          await _tap(tester, next());
          _noException(tester, 'move 7/7');
          expect(find.text(t.dfSubmitRequest), findsOneWidget);

          await show(
            RequestStatusScreen(
              booking: Booking.fromJson(
                bookingJson(
                  serviceCode: 'move_out',
                  status: 0,
                  estimate: 346500,
                  threadId: 'th-1',
                  address: addressJson(),
                  answers: {
                    'cleaning_type': 'standard',
                    'building': 'commercial',
                    'layout': 'four_plus',
                  },
                ),
              ),
              estimate: _estimate,
              showDoneSheet: true,
            ),
            'request status + done sheet',
          );
          await unmount(tester);
        },
      );
    }
  }
}
