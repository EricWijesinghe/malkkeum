import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../src/u1_stub.dart'; // u1-stub: delete when U1 lands
import '../state.dart';
import 'booking_detail.dart';
import 'pending_deposits_banner.dart';

/// Week strip (default) or month calendar with service-colored dots + the day's bookings; or a plain list.
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
  bool _monthView = false;
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

  void _pickDay(DateTime d) => setState(() {
    _day = d;
    _month = DateTime(d.year, d.month);
  });

  Widget _calendarView(List<Booking> all) {
    final dayItems = all
        .where((b) => DateUtils.isSameDay(b.visitDate, _day))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        AppCard(
          padding: const EdgeInsets.all(Space.sm),
          child: _monthView
              ? _MonthGrid(
                  month: _month,
                  selected: _day,
                  bookings: all,
                  onMonth: (m) => setState(() => _month = m),
                  onDay: _pickDay,
                  onToggle: () => setState(() => _monthView = false),
                )
              : _WeekStrip(
                  selected: _day,
                  bookings: all,
                  onDay: _pickDay,
                  onToggle: () => setState(() => _monthView = true),
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
    required this.onToggle,
  });
  final DateTime month;
  final DateTime selected;
  final List<Booking> bookings;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onToggle;

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
        _CalendarHeader(
          month: month,
          monthView: true,
          prevTooltip: loc.previousMonthTooltip,
          nextTooltip: loc.nextMonthTooltip,
          onPrev: () => onMonth(DateTime(month.year, month.month - 1)),
          onNext: () => onMonth(DateTime(month.year, month.month + 1)),
          onToday: () => onDay(today),
          onToggle: onToggle,
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.monthView,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onToggle,
  });
  final DateTime month;
  final bool monthView;
  final String prevTooltip;
  final String nextTooltip;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: prevTooltip,
        icon: const Icon(Icons.chevron_left_rounded),
        onPressed: onPrev,
      ),
      Expanded(
        // The month title is the week/month switch; the label names the view a tap opens.
        child: Semantics(
          button: true,
          label: monthView ? context.t.bkViewWeek : context.t.bkViewMonth,
          child: InkWell(
            key: const ValueKey('calendar-toggle'),
            borderRadius: BorderRadius.circular(Radii.chip),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              // Scales down instead of overflowing between the buttons on a 320dp phone.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: Icon3D('ui_calendar', size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat.yMMMM(context.lang).format(month),
                      style: context.text.titleMedium,
                    ),
                    Icon(
                      monthView
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: context.colors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // An icon, not the word: long translations at large fonts would squeeze out the month title.
      IconButton(
        tooltip: context.t.today,
        icon: const Icon(Icons.today_rounded),
        onPressed: onToday,
      ),
      IconButton(
        tooltip: nextTooltip,
        icon: const Icon(Icons.chevron_right_rounded),
        onPressed: onNext,
      ),
    ],
  );
}

/// One week per page; a swipe (or the chevrons) moves a week and keeps the weekday selected.
class _WeekStrip extends StatefulWidget {
  const _WeekStrip({
    required this.selected,
    required this.bookings,
    required this.onDay,
    required this.onToggle,
  });
  final DateTime selected;
  final List<Booking> bookings;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onToggle;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  static const _height = 72.0;
  // Page 0 starts on Sunday 2 Jan 2000: weeks start on Sunday, like the month grid.
  static const _epochDay = 2;
  static final _epoch = DateTime.utc(2000, 1, _epochDay);

  // UTC so a daylight-saving day never shifts the week count.
  static int _pageOf(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).difference(_epoch).inDays ~/
      DateTime.daysPerWeek;
  static DateTime _dayAt(int page, int weekday) =>
      DateTime(2000, 1, _epochDay + DateTime.daysPerWeek * page + weekday);

  late final _pages = PageController(initialPage: _pageOf(widget.selected));

  @override
  void didUpdateWidget(_WeekStrip old) {
    super.didUpdateWidget(old);
    final page = _pageOf(widget.selected);
    if (_pages.hasClients && _pages.page?.round() != page) {
      _pages.jumpToPage(page);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _shift(int weeks) => widget.onDay(
    DateTime(
      widget.selected.year,
      widget.selected.month,
      widget.selected.day + DateTime.daysPerWeek * weeks,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    return Column(
      children: [
        _CalendarHeader(
          month: widget.selected,
          monthView: false,
          prevTooltip: loc.previousPageTooltip,
          nextTooltip: loc.nextPageTooltip,
          onPrev: () => _shift(-1),
          onNext: () => _shift(1),
          onToday: () => widget.onDay(today),
          onToggle: widget.onToggle,
        ),
        SizedBox(
          height: _height,
          child: PageView.builder(
            key: const ValueKey('week-strip'),
            controller: _pages,
            onPageChanged: (page) {
              // Already there when the parent moved the day (chevrons, today, month grid).
              if (page == _pageOf(widget.selected)) return;
              widget.onDay(_dayAt(page, widget.selected.weekday % 7));
            },
            itemBuilder: (context, page) => Row(
              children: [
                for (var i = 0; i < DateTime.daysPerWeek; i++)
                  Expanded(child: _cell(_dayAt(page, i), loc, today)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(DateTime date, MaterialLocalizations loc, DateTime today) =>
      _DayCell(
        date: date,
        weekday: loc.narrowWeekdays[date.weekday % 7],
        selected: DateUtils.isSameDay(widget.selected, date),
        today: DateUtils.isSameDay(today, date),
        items: [
          for (final b in widget.bookings)
            if (b.status >= 0 && DateUtils.isSameDay(b.visitDate, date)) b,
        ],
        onTap: () => widget.onDay(date),
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.items,
    required this.onTap,
    this.weekday,
  });
  final DateTime date;
  final bool selected;
  final bool today;
  final List<Booking> items;
  final VoidCallback onTap;
  final String? weekday;

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
            if (weekday != null) ...[
              Text(weekday!, style: context.text.labelSmall),
              const SizedBox(height: 4),
            ],
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
                      const SizedBox(width: Space.xs),
                      Flexible(child: BookingStatusChip(status: b.status)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon3D(bookingTimeIcon(b), size: 16),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bookingWhen(context, b),
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    b.address['label'] as String? ?? '',
                    style: context.text.bodySmall,
                  ),
                  if (b.status >= 0) ...[
                    const SizedBox(height: 6),
                    _MiniSteps(booking: b),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wording of the brief for chips and the timeline: 상담요청 → 예약확정 → 매칭 완료 → 서비스 완료.
String bookingStepLabel(T t, int status) => switch (status) {
  0 => t.bkStepConsult,
  1 => t.bkStepConfirmed,
  2 => t.bkStepMatched,
  3 => t.bkStepCompleted,
  _ => t.statusCancelled,
};

String bookingStepIcon(int status) => switch (status) {
  0 => 'step_consult',
  1 => 'step_confirmed',
  2 => 'step_matched',
  3 => 'step_completed',
  _ => 'status_cancelled',
};

bool _isMorning(Booking b) => b.startHour < 12;

String bookingTimeIcon(Booking b) => !b.isQuote
    ? 'ui_clock'
    : _isMorning(b)
    ? 'slot_am'
    : 'slot_pm';

/// Quotes are booked by half-day (오전/오후); fixed-price visits by the hour slot ("09:00~10:00").
String bookingWhen(BuildContext context, Booking b) {
  final t = context.t;
  final time = b.isQuote
      ? (_isMorning(b) ? t.morning : t.afternoon)
      : slotRangeLabel(b.startHour, context.lang);
  return '${dateLabel(b.visitDate, context.lang)} $time';
}

/// Status pill in the [StatusHues] colours with the step's 3D icon.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});
  final int status;

  @override
  Widget build(BuildContext context) {
    final hue = StatusHues.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.tintOf(hue),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon3D(bookingStepIcon(status), active: true, size: 16),
          ),
          const SizedBox(width: 4),
          // Flexible: a long translation wraps inside its pill instead of overflowing the row.
          Flexible(
            child: Text(
              bookingStepLabel(context.t, status),
              style: context.text.labelMedium?.copyWith(
                color: context.colors.isDark ? hue.tint : hue.tone,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card-sized progress: one bar per step (4 for quotes, 3 for fixed-price), filled up to the current one.
class _MiniSteps extends StatelessWidget {
  const _MiniSteps({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var step = booking.isQuote ? 0 : 1; step <= 3; step++)
          Container(
            width: 20,
            height: 4,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: booking.status >= step
                  ? context.colors.fresh
                  : context.colors.line,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
      ],
    ),
  );
}
