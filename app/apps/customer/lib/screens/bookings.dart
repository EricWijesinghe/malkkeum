import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'pending_deposits_banner.dart';

/// Month calendar with service-colored dots + the day's bookings; or a plain list.
class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});
  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final _view = GlobalKey<AsyncViewState<List<Booking>>>();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  bool _calendar = true;
  int _seen = -1;

  Future<List<Booking>> _load() async =>
      (await context.api.get('/bookings') as List)
          .map((e) => Booking.fromJson(e as Json))
          .toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.app.bookingsVersion;
    if (_seen != -1 && v != _seen) _view.currentState?.reload();
    _seen = v;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookingsTitle),
        actions: [
          IconButton(
            tooltip: _calendar ? t.viewAll : t.bookingsTitle,
            icon: Icon(
              _calendar
                  ? Icons.view_agenda_outlined
                  : Icons.calendar_month_outlined,
            ),
            onPressed: () => setState(() => _calendar = !_calendar),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PendingDepositsBanner(),
          Expanded(
            child: AsyncView<List<Booking>>(
              key: _view,
              load: _load,
              builder: (context, all, reload) {
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_note_rounded,
                    title: t.bookingsEmpty,
                    body: t.bookingsEmptyBody,
                    hue: ServiceHues.studio,
                  );
                }
                return RefreshIndicator(
                  onRefresh: reload,
                  child: _calendar ? _calendarView(all) : _listView(all),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarView(List<Booking> all) {
    final dayItems = all
        .where((b) => DateUtils.isSameDay(b.visitDate, _day))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        AppCard(
          padding: const EdgeInsets.all(Space.sm),
          child: _MonthGrid(
            month: _month,
            selected: _day,
            bookings: all,
            onMonth: (m) => setState(() => _month = m),
            onDay: (d) => setState(() => _day = d),
          ),
        ),
        const SizedBox(height: Space.lg),
        SectionTitle(dateLabel(_day, context.lang)),
        if (dayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Center(
              child: Text(
                context.t.bookingsEmpty,
                style: context.text.bodySmall,
              ),
            ),
          ),
        for (final b in dayItems) BookingCard(booking: b),
      ],
    );
  }

  Widget _listView(List<Booking> all) {
    final upcoming = all.where((b) => b.isActive).toList()
      ..sort((a, b) => a.visitStart.compareTo(b.visitStart));
    final past = all.where((b) => !b.isActive).toList();
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        if (upcoming.isNotEmpty) ...[
          SectionTitle(context.t.bookingsUpcoming),
          for (final b in upcoming) BookingCard(booking: b),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          SectionTitle(context.t.bookingsPast),
          for (final b in past) BookingCard(booking: b),
        ],
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.bookings,
    required this.onMonth,
    required this.onDay,
  });
  final DateTime month;
  final DateTime selected;
  final List<Booking> bookings;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final lead = first.weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final byDay = <int, List<Booking>>{};
    for (final b in bookings) {
      if (b.visitDate.year == month.year &&
          b.visitDate.month == month.month &&
          b.status >= 0) {
        (byDay[b.visitDate.day] ??= []).add(b);
      }
    }
    final today = DateUtils.dateOnly(DateTime.now());
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: loc.previousMonthTooltip,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(context.lang).format(month),
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                onMonth(DateTime(today.year, today.month));
                onDay(today);
              },
              child: Text(context.t.today),
            ),
            IconButton(
              tooltip: loc.nextMonthTooltip,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in loc.narrowWeekdays)
              Expanded(
                child: Center(child: Text(w, style: context.text.labelSmall)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 0.92,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                date: DateTime(month.year, month.month, d),
                selected: DateUtils.isSameDay(
                  selected,
                  DateTime(month.year, month.month, d),
                ),
                today: DateUtils.isSameDay(
                  today,
                  DateTime(month.year, month.month, d),
                ),
                items: byDay[d] ?? const [],
                onTap: () => onDay(DateTime(month.year, month.month, d)),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.items,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final bool today;
  final List<Booking> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    label:
        '${dateLabel(date, context.lang)} ${items.isEmpty ? '' : '· ${items.length}'}',
    button: true,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      // Large system fonts scale the day cell down instead of overflowing the strip.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? context.primary : null,
                border: today && !selected
                    ? Border.all(color: context.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: context.text.labelLarge?.copyWith(
                  color: selected ? Colors.white : context.colors.ink,
                  fontWeight: today || selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final b in items.take(3))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ServiceHues.of(b.serviceCode).tone,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingDetailScreen(id: b.id),
          ),
        ),
        child: Row(
          children: [
            ServiceGlyph(b.serviceCode, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.service(b.serviceCode),
                          style: context.text.titleSmall,
                        ),
                      ),
                      StatusBadge(status: b.status, label: t.status(b.status)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateLabel(b.visitDate, context.lang)} ${b.isQuote ? (b.startHour < 12 ? t.morning : t.afternoon) : hourLabel(b.startHour, context.lang)}',
                    style: context.text.bodySmall,
                  ),
                  Text(
                    b.address['label'] as String? ?? '',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
