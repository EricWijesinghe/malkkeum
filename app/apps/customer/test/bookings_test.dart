import 'package:core/core.dart';
import 'package:customer/screens/booking_detail.dart';
import 'package:customer/screens/bookings.dart';
import 'package:customer/screens/request_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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

/// The design's frame.
const _phone = Size(360, 780);

/// Long enough for the fold, the month slide and the day list to finish.
const _calendarSettle = Duration(milliseconds: 600);

/// Both fixtures are at the default address, so they share one group with its count.
const _homeGroup = '우리집 2';

final _firstOfMonth = DateTime(_today.year, _today.month);

/// Days of this month that are never today: one with a booking, one without.
final _otherDay = DateTime(_today.year, _today.month, _today.day > 15 ? 3 : 24);
final _emptyDay = DateTime(_today.year, _today.month, _today.day > 15 ? 5 : 26);

String _monthTitle(DateTime month) => DateFormat.yMMMM('ko').format(month);

/// The calendar cell of [day]: cells carry the full date as their semantics label.
Finder _cell(DateTime day) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.button == true && (w.properties.label ?? '').startsWith(dateLabel(day, 'ko')),
);

/// Booking dots are the only 5dp boxes in a cell.
Finder _dots(Finder cell) => find.descendant(
  of: cell,
  matching: find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 5),
);

void main() {
  final t = lookupT(const Locale('ko'));

  testWidgets('month grid is the default: today in words, ink square, greyed neighbours, one dot per day', (tester) async {
    setViewport(tester, _phone);
    final env = await _env([
      ..._todayBookings(),
      bookingJson(id: 'later', status: 1, serviceCode: 'sofa', visitDate: _otherDay),
    ], themeMode: ThemeMode.light);
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await settle(tester);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('month-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-strip')), findsNothing);
    expect(find.text(_monthTitle(_today)), findsOneWidget);
    // Today is selected: its numeral is the word, on the ink square.
    final colors = appColorsFor(BrandConfig.placeholder, false);
    final square = tester.widget<AnimatedContainer>(
      find.descendant(of: _cell(_today), matching: find.byType(AnimatedContainer)),
    );
    final box = square.decoration! as BoxDecoration;
    expect(box.color, colors.ink);
    expect(box.borderRadius, BorderRadius.circular(10));
    final word = find.descendant(of: _cell(_today), matching: find.text(t.today));
    expect(tester.widget<Text>(word).style!.color, colors.surface);
    expect(find.descendant(of: _cell(_today), matching: find.text('${_today.day}')), findsNothing);
    // Two bookings today still draw a single dot; a day without bookings draws none.
    expect(_dots(_cell(_today)), findsOneWidget);
    expect(_dots(_cell(_otherDay)), findsOneWidget);
    expect(_dots(_cell(_emptyDay)), findsNothing);
    // The grid shows whole weeks, so it starts or ends in a neighbouring month, greyed.
    final outside = _firstOfMonth.weekday % 7 > 0
        ? _firstOfMonth.subtract(const Duration(hours: 12))
        : DateTime(_today.year, _today.month + 1, 1, 12);
    final grey = tester.widget<Text>(find.descendant(of: _cell(outside), matching: find.byType(Text)));
    expect(grey.style!.color!.a, closeTo(0.4, 0.01));
    await unmount(tester);
  });

  testWidgets('the day list groups by address with flat rows: time as title, service, text pill', (tester) async {
    setViewport(tester, _phone);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await settle(tester);

    expect(find.text(_homeGroup, findRichText: true), findsOneWidget);
    expect(slotRangeLabel(9, 'ko'), '오전 9시~10시');
    expect(find.text(slotRangeLabel(9, 'ko')), findsOneWidget);
    expect(find.text(t.dfAmVisit), findsOneWidget);
    expect(find.text(t.service('studio')), findsOneWidget);
    expect(find.text('예약확정'), findsOneWidget);
    expect(find.text('상담요청'), findsOneWidget);
    // Pills are text only and rows are flat: no icon in the pill, no card around the row.
    expect(find.descendant(of: find.byType(BookingStatusChip), matching: find.byType(Icon3D)), findsNothing);
    expect(find.descendant(of: find.byType(BookingsTab), matching: find.byType(AppCard)), findsNothing);
    await unmount(tester);
  });

  testWidgets('a quote in consultation opens the request tracker, any other booking its detail', (tester) async {
    setViewport(tester, _phone);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await settle(tester);

    await tester.tap(find.text(t.dfAmVisit));
    await settle(tester);
    expect(tester.widget<RequestStatusScreen>(find.byType(RequestStatusScreen)).booking.id, 'quote');
    Navigator.of(tester.element(find.byType(RequestStatusScreen))).pop();
    await settle(tester);

    await tester.tap(find.text(slotRangeLabel(9, 'ko')));
    await settle(tester);
    expect(tester.widget<BookingDetailScreen>(find.byType(BookingDetailScreen)).id, 'fixed');
    await unmount(tester);
  });

  testWidgets('the handle and the month title fold the grid to one week and open it again', (tester) async {
    setViewport(tester, _phone);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await settle(tester);
    final handle = find.byKey(const ValueKey('calendar-handle'));
    final toggle = find.byKey(const ValueKey('calendar-toggle'));
    final strip = find.byKey(const ValueKey('week-strip'));
    final open = tester.getTopLeft(handle).dy;
    expect(_toggleLabelled(t.bkViewWeek), findsWidgets);
    expect(tester.getSize(handle).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));

    // A flick up folds it whatever the distance.
    await tester.fling(handle, const Offset(0, -60), 1200);
    await settle(tester, duration: _calendarSettle);
    expect(strip, findsOneWidget);
    expect(find.byKey(const ValueKey('month-grid')), findsNothing);
    expect(tester.getTopLeft(handle).dy, lessThan(open - 100));
    expect(_toggleLabelled(t.bkViewMonth), findsWidgets);
    expect(find.byType(BookingCard), findsNWidgets(2), reason: 'the selected day stays');

    // A slow drag most of the way down opens it.
    await tester.drag(handle, const Offset(0, 180));
    await settle(tester, duration: _calendarSettle);
    expect(strip, findsNothing);
    expect(tester.getTopLeft(handle).dy, open);

    await tester.tap(toggle);
    await settle(tester, duration: _calendarSettle);
    expect(strip, findsOneWidget);
    await tester.tap(handle);
    await settle(tester, duration: _calendarSettle);
    expect(strip, findsNothing);
    await unmount(tester);
  });

  testWidgets('chevrons turn the month, a day of the next month selects it and today comes back', (tester) async {
    setViewport(tester, _phone);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await settle(tester);
    final next = DateTime(_today.year, _today.month + 1);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await settle(tester, duration: _calendarSettle);
    expect(find.text(_monthTitle(next)), findsOneWidget);
    expect(find.byType(BookingCard), findsNWidgets(2), reason: 'turning the page keeps the selected day');

    await tester.tap(_cell(DateTime(next.year, next.month, 15)));
    await settle(tester, duration: _calendarSettle);
    // An empty day says so and offers what is coming up instead, with the date on each row.
    expect(find.text(t.bookingsEmptyDay), findsOneWidget);
    expect(find.text(t.bookingsUpcoming), findsOneWidget);
    expect(find.textContaining(dateLabel(_today, 'ko')), findsNWidgets(2));
    // Date and hour are separate pieces, so a narrow row never splits "오전 9시~10시" mid-hour.
    expect(find.text(dateLabel(_today, 'ko')), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('calendar-today')));
    await settle(tester, duration: _calendarSettle);
    expect(find.text(_monthTitle(_today)), findsOneWidget);
    expect(find.text(t.bookingsUpcoming), findsNothing);
    expect(find.text(_homeGroup, findRichText: true), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('swiping the folded week strip moves the selected day one week', (tester) async {
    setViewport(tester, _phone);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await tester.tap(find.byKey(const ValueKey('calendar-handle')));
    await settle(tester, duration: _calendarSettle);
    final strip = find.byKey(const ValueKey('week-strip'));

    await tester.fling(strip, const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text(_homeGroup, findRichText: true), findsNothing);
    expect(find.text(t.bookingsEmptyDay), findsOneWidget);

    await tester.fling(strip, const Offset(300, 0), 1000);
    await settle(tester);
    expect(find.text(_homeGroup, findRichText: true), findsOneWidget);

    // Seven full-height tap targets tile the strip.
    final box = tester.getRect(strip);
    final rects = [
      for (final e in find.descendant(of: strip, matching: find.byType(InkWell)).evaluate()) tester.getRect(find.byWidget(e.widget)),
    ]..removeWhere((r) => r.right <= box.left || r.left >= box.right);
    expect(rects, hasLength(DateTime.daysPerWeek));
    for (final r in rects) {
      expect(r.height, greaterThanOrEqualTo(48));
      expect(r.width, closeTo(box.width / DateTime.daysPerWeek, 0.5), reason: 'no dead gaps between days');
    }
    await unmount(tester);
  });

  testWidgets('reduced motion folds the calendar at once and runs no animation', (tester) async {
    setViewport(tester, _phone);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final env = await _env(_todayBookings());
    await pumpCustomerScreen(tester, env, const BookingsTab());
    await pumpUntilFound(tester, find.byType(BookingCard));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('calendar-handle')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('week-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-grid')), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    await unmount(tester);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('status pills are text only: outlined in consultation, StatusHues after (${mode.name})', (tester) async {
      final env = await _env(const [], themeMode: mode);
      final colors = appColorsFor(BrandConfig.placeholder, mode == ThemeMode.dark);
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
        final decoration = box.decoration! as BoxDecoration;
        final label = tester.widget<Text>(find.text(bookingStepLabel(t, s)));
        final hue = StatusHues.of(s);
        if (s == 0) {
          expect(decoration.color, colors.surface);
          expect((decoration.border! as Border).top.color, colors.line);
          expect(label.style!.color, colors.ink);
        } else {
          expect(decoration.color, mode == ThemeMode.dark ? hue.darkTint : hue.tint);
          expect(label.style!.color, mode == ThemeMode.dark ? hue.tint : hue.tone);
        }
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
    expect(find.textContaining(slotRangeLabel(9, 'ko')), findsOneWidget);
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
