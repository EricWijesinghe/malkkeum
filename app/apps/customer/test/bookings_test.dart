import 'package:core/core.dart';
import 'package:customer/screens/booking_detail.dart';
import 'package:customer/screens/bookings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/customer_host.dart';
import 'support/customer_routes.dart';

final _today = DateUtils.dateOnly(DateTime.now());

/// A fixed-price studio visit (예약확정) and a move-in quote (상담요청), both today at 09:00.
List<Json> _todayBookings() => [
  bookingJson(id: 'fixed', status: 1, serviceCode: 'studio', visitDate: _today),
  bookingJson(id: 'quote', status: 0, serviceCode: 'move_in', visitDate: _today, answers: const {}, estimate: 346500),
];

Future<TestEnv> _env(List<Json> bookings, {ThemeMode themeMode = ThemeMode.light}) async {
  final fake = FakeApi();
  for (final b in bookings) {
    fake.reply('GET', '/bookings/${b['id']}', b);
  }
  stockCustomerApi(fake, bookings: bookings);
  return TestEnv.create(fake: fake, themeMode: themeMode);
}

Future<void> _pumpDetail(WidgetTester tester, Json booking, {bool reduceMotion = false}) async {
  final env = await _env([booking]);
  await pumpCustomerScreen(
    tester,
    env,
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: BookingDetailScreen(id: booking['id'] as String),
      ),
    ),
  );
  await pumpUntilFound(tester, find.byType(Pulse));
}

Iterable<Pulse> _steps(WidgetTester tester) => tester.widgetList<Pulse>(find.byType(Pulse));

/// On-screen width of the current step's disc (40dp at rest; wider while the pulse scales it up).
double _currentDotWidth(WidgetTester tester) => tester
    .getRect(find.descendant(of: find.byWidgetPredicate((w) => w is Pulse && w.active), matching: find.byType(AnimatedContainer)))
    .width;

Finder _toggleLabelled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

void main() {
  final t = lookupT(const Locale('ko'));

  testWidgets('week strip is the default and cards show the slot range, half-day and brief statuses', (tester) async {
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));

    expect(find.byKey(const ValueKey('week-strip')), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.textContaining('09:00~10:00'), findsOneWidget);
    expect(find.textContaining(t.morning), findsOneWidget);
    expect(find.text('예약확정'), findsOneWidget);
    expect(find.text('상담요청'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('swiping the week strip moves the selected day one week', (tester) async {
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    final strip = find.byKey(const ValueKey('week-strip'));

    await tester.fling(strip, const Offset(-300, 0), 1000);
    await settle(tester);
    final next = _today.add(const Duration(days: 7, hours: 12));
    expect(find.text(dateLabel(next, 'ko')), findsOneWidget);
    expect(find.byType(BookingCard), findsNothing);

    await tester.fling(strip, const Offset(300, 0), 1000);
    await settle(tester);
    expect(find.text(dateLabel(_today, 'ko')), findsOneWidget);
    expect(find.byType(BookingCard), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('the month title toggles between the week strip and the month grid', (tester) async {
    // Tall enough that the day's cards stay built under the month grid.
    setViewport(tester, const Size(400, 1200));
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    final toggle = find.byKey(const ValueKey('calendar-toggle'));
    expect(_toggleLabelled(t.bkViewMonth), findsOneWidget);

    await tester.tap(toggle);
    await settle(tester, duration: const Duration(milliseconds: 400));
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byKey(const ValueKey('week-strip')), findsNothing);
    expect(_toggleLabelled(t.bkViewWeek), findsOneWidget);
    expect(find.byType(BookingCard), findsNWidgets(2));

    await tester.tap(toggle);
    await settle(tester, duration: const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('week-strip')), findsOneWidget);
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
    await unmount(tester);
  });

  testWidgets('week strip days are full-height tap targets that tile the strip', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));

    final strip = tester.getRect(find.byKey(const ValueKey('week-strip')));
    final days = find.descendant(of: find.byKey(const ValueKey('week-strip')), matching: find.byType(InkWell));
    final rects = [for (final e in days.evaluate()) tester.getRect(find.byWidget(e.widget))]
      ..removeWhere((r) => r.right <= strip.left || r.left >= strip.right);
    expect(rects, hasLength(DateTime.daysPerWeek));
    for (final r in rects) {
      expect(r.height, greaterThanOrEqualTo(48));
      expect(r.width, closeTo(strip.width / DateTime.daysPerWeek, 0.5), reason: 'no dead gaps between days');
    }
    await unmount(tester);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('status chips use StatusHues (${mode.name})', (tester) async {
      final env = await _env(const [], themeMode: mode);
      const statuses = [0, 1, 2, 3, -1];
      await pumpCustomerScreen(
        tester,
        env,
        Scaffold(
          body: Column(children: [for (final s in statuses) BookingStatusChip(status: s)]),
        ),
      );
      await tester.pump();
      for (final s in statuses) {
        final box = tester.widget<Container>(
          find.descendant(of: find.byWidgetPredicate((w) => w is BookingStatusChip && w.status == s), matching: find.byType(Container)),
        );
        final hue = StatusHues.of(s);
        expect((box.decoration! as BoxDecoration).color, mode == ThemeMode.dark ? hue.darkTint : hue.tint);
        final label = tester.widget<Text>(find.text(bookingStepLabel(t, s)));
        expect(label.style!.color, mode == ThemeMode.dark ? hue.tint : hue.tone);
      }
      await unmount(tester);
    });
  }

  testWidgets('a quote booking shows four steps in the brief wording and pulses the current one', (tester) async {
    await _pumpDetail(tester, bookingJson(id: 'quote', status: 0, serviceCode: 'move_in', answers: const {}, estimate: 346500));

    expect(_steps(tester), hasLength(4));
    expect(_steps(tester).where((p) => p.active), hasLength(1));
    // 상담요청 is the current step: once in the header chip, once in the timeline.
    expect(find.text('상담요청'), findsNWidgets(2));
    for (final label in ['예약확정', '매칭 완료', '서비스 완료']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(_currentDotWidth(tester), greaterThan(40));
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('a fixed-price booking shows three steps and the hour slot', (tester) async {
    await _pumpDetail(tester, bookingJson(id: 'fixed', status: 2, serviceCode: 'studio'));

    expect(_steps(tester), hasLength(3));
    expect(find.text('상담요청'), findsNothing);
    expect(find.text('매칭 완료'), findsNWidgets(2));
    expect(find.textContaining('09:00~10:00'), findsOneWidget);
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('reduced motion keeps the timeline static', (tester) async {
    await _pumpDetail(tester, bookingJson(id: 'quote', status: 1, serviceCode: 'move_in', answers: const {}), reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_steps(tester).where((p) => p.active), hasLength(1));
    expect(_currentDotWidth(tester), 40);
    expect(tester.binding.transientCallbackCount, 0);
    await unmount(tester);
  });
}
