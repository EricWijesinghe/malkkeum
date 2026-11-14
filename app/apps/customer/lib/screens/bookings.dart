import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_card.dart';
import 'pending_deposits_banner.dart';

export 'booking_card.dart';

/// One calendar week row; tall enough to be a touch target on its own.
const _rowHeight = 52.0;
const _daySize = 44.0;
const _dayRadius = 10.0;
const _dotSize = 5.0;
const _handleTarget = 48.0;

/// Finger travel that takes the month grid from open to a single week.
const _dragExtent = 220.0;

/// A flick faster than this (dp/s) decides open or closed whatever the position.
const _flingVelocity = 300.0;

/// Calendar chrome stops growing here; the bookings under it follow the system text size in full.
const _headerMaxTextScale = 1.3;

/// Days of the neighbouring months are shown greyed.
const _outsideAlpha = 0.4;

/// Languages that write the year before the month, where "26년 11월" reads naturally.
const _shortYearLangs = {'ko', 'ja', 'zh'};

DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

String _monthTitle(DateTime month, String lang) {
  final full = DateFormat.yMMMM(lang).format(month);
  return _shortYearLangs.contains(lang)
      ? full.replaceFirst('${month.year}', '${month.year % 100}')
      : full;
}

/// Month calendar (a drag handle folds it to one week) over the selected day's bookings.
class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});
  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab>
    with SingleTickerProviderStateMixin {
  final _view = GlobalKey<AsyncViewState<List<Booking>>>();
  DateTime _month = _monthOf(DateTime.now());
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  /// +1 when the last month change went forward, -1 back: the grid slides that way.
  int _slide = 1;
  int _seen = -1;

  /// 1 = month grid open (the default), 0 = folded to the selected week.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: Motion.route,
    value: 1,
  )
    ..addListener(_onFold)
    ..addStatusListener((_) => _onFold());

  /// What the last build showed: (month grid, week strip, the fold a tap would make).
  (bool, bool, bool) _shown = (true, false, true);

  /// Rebuilds only when that changes, not on every frame of the fold. Value and status are both
  /// watched: a fold with no duration (reduced motion) moves the value without a status report.
  void _onFold() {
    final now = (_monthOpen, _weekOpen, _willFold);
    if (now != _shown) setState(() => _shown = now);
  }

  late final _pager = Pager<Booking>(
    context.api,
    '/bookings',
    Booking.fromJson,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.app.bookingsVersion;
    if (_seen != -1 && v != _seen) _view.currentState?.reload();
    _seen = v;
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  // Both are built while the fold is under way (animating, or held part-way by a drag).
  bool get _monthOpen => _open.value > 0 || _open.isAnimating;
  bool get _weekOpen => _open.value < 1 || _open.isAnimating;

  /// Where a tap on the title or the handle goes next.
  bool get _willFold => _open.value > 0.5;

  void _pickDay(DateTime d) => setState(() {
    _slide = d.isBefore(_month) ? -1 : 1;
    _day = d;
    _month = _monthOf(d);
  });

  /// Chevrons: a month while the grid is open, a week once it is folded.
  void _step(int by) {
    if (!_monthOpen) {
      _pickDay(DateTime(_day.year, _day.month, _day.day + by * 7));
    } else {
      setState(() {
        _slide = by;
        _month = DateTime(_month.year, _month.month + by);
      });
    }
  }

  void _settle(bool open) {
    // The week strip shows the selected day's week, so the title follows it home.
    if (!open && _month != _monthOf(_day)) {
      setState(() {
        _slide = _day.isBefore(_month) ? -1 : 1;
        _month = _monthOf(_day);
      });
    }
    final duration = motionFor(context, Motion.route);
    // animateBack, not animateTo(0): the controller then ends dismissed, as a closed grid should.
    if (open) {
      _open.animateTo(1, duration: duration, curve: Motion.emphasized);
    } else {
      _open.animateBack(0, duration: duration, curve: Motion.emphasized);
    }
  }

  void _dragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    _settle(v.abs() > _flingVelocity ? v > 0 : _open.value > 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PendingDepositsBanner(),
            Expanded(
              child: AsyncView<List<Booking>>(
                key: _view,
                load: _pager.first,
                builder: (context, _, reload) => LoadMore<Booking>(
                  pager: _pager,
                  builder: (context, all) {
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
                      child: _calendarView(all),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarView(List<Booking> all) {
    final t = context.t;
    final c = context.colors;
    final loc = MaterialLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final counts = <DateTime, int>{};
    for (final b in all) {
      if (b.status >= 0) {
        counts.update(
          DateUtils.dateOnly(b.visitDate),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final toggleLabel = _willFold ? t.bkViewWeek : t.bkViewMonth;
    final dayItems =
        all.where((b) => DateUtils.isSameDay(b.visitDate, _day)).toList()
          ..sort((a, b) => a.startHour.compareTo(b.startHour));
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.sm, 0),
          child: Column(
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: _headerMaxTextScale,
                child: Column(
                  children: [
                    _CalendarHeader(
                      title: _monthTitle(_month, context.lang),
                      folded: !_willFold,
                      toggleLabel: toggleLabel,
                      prevTooltip: _monthOpen
                          ? loc.previousMonthTooltip
                          : loc.previousPageTooltip,
                      nextTooltip: _monthOpen
                          ? loc.nextMonthTooltip
                          : loc.nextPageTooltip,
                      onPrev: () => _step(-1),
                      onNext: () => _step(1),
                      onToday: () => _pickDay(today),
                      onToggle: () => _settle(!_willFold),
                    ),
                    Row(
                      children: [
                        for (final w in loc.narrowWeekdays)
                          Expanded(
                            child: Center(
                              child: Text(
                                w,
                                style: context.text.labelSmall?.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xxs),
              if (_weekOpen)
                SizeTransition(
                  sizeFactor: ReverseAnimation(_open),
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: ReverseAnimation(_open),
                    child: _WeekStrip(
                      selected: _day,
                      today: today,
                      counts: counts,
                      onDay: _pickDay,
                    ),
                  ),
                ),
              if (_monthOpen)
                SizeTransition(
                  sizeFactor: _open,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _open,
                    child: _MonthPager(
                      key: const ValueKey('month-grid'),
                      month: _month,
                      slide: _slide,
                      selected: _day,
                      today: today,
                      counts: counts,
                      onDay: _pickDay,
                      onStep: _step,
                    ),
                  ),
                ),
              Semantics(
                button: true,
                label: toggleLabel,
                child: GestureDetector(
                  key: const ValueKey('calendar-handle'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _settle(!_willFold),
                  onVerticalDragUpdate: (d) =>
                      _open.value += (d.primaryDelta ?? 0) / _dragExtent,
                  onVerticalDragEnd: _dragEnd,
                  child: SizedBox(
                    height: _handleTarget,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.line,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        // The day's list fades and rises in as the selection moves.
        AnimatedSwitcher(
          duration: motionFor(context, Motion.standard),
          switchInCurve: Motion.ease,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, Space.xs * (1 - animation.value)),
                child: child,
              ),
              child: child,
            ),
          ),
          child: _DayList(
            key: ValueKey(_day),
            items: dayItems,
            upcoming: dayItems.isNotEmpty
                ? const []
                : (all.where((b) => b.isActive).toList()
                    ..sort((a, b) => a.visitStart.compareTo(b.visitStart))),
          ),
        ),
      ],
    );
  }
}

/// "26년 11월 ▾" on the left (tap folds or opens the grid), then previous, next and "today".
class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.folded,
    required this.toggleLabel,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onToggle,
  });
  final String title;
  final bool folded;
  final String toggleLabel;
  final String prevTooltip;
  final String nextTooltip;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        const SizedBox(width: Space.xs),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            // The month title is the week/month switch; the label names the view a tap opens.
            child: Semantics(
              button: true,
              label: toggleLabel,
              child: InkWell(
                key: const ValueKey('calendar-toggle'),
                borderRadius: BorderRadius.circular(Radii.chip),
                onTap: onToggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  // Scales down instead of overflowing beside the buttons on a 320dp phone.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: context.text.headlineSmall),
                        AnimatedRotation(
                          turns: folded ? -0.25 : 0,
                          duration: motionFor(context, Motion.standard),
                          curve: Motion.ease,
                          child: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: prevTooltip,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrev,
        ),
        IconButton(
          tooltip: nextTooltip,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
        ),
        OutlinedButton(
          key: const ValueKey('calendar-today'),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.ink,
            minimumSize: const Size(48, 36),
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            side: BorderSide(color: c.ink, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            textStyle: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: onToday,
          child: Text(context.t.today),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}

/// Seven day cells from [start], each a full-height tap target.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.start,
    required this.selected,
    required this.today,
    required this.counts,
    required this.onDay,
    this.month,
  });
  final DateTime start;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onDay;

  /// Days outside this month are greyed; null (the week strip) greys none.
  final DateTime? month;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _rowHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < DateTime.daysPerWeek; i++)
          Expanded(child: _cell(DateTime(start.year, start.month, start.day + i))),
      ],
    ),
  );

  Widget _cell(DateTime date) => _DayCell(
    date: date,
    selected: DateUtils.isSameDay(selected, date),
    today: DateUtils.isSameDay(today, date),
    outside: month != null && date.month != month!.month,
    count: counts[date] ?? 0,
    onTap: () => onDay(date),
  );
}

/// The month grid. A change of month slides the old page out and the new one in; a sideways
/// flick turns the page too.
class _MonthPager extends StatelessWidget {
  const _MonthPager({
    super.key,
    required this.month,
    required this.slide,
    required this.selected,
    required this.today,
    required this.counts,
    required this.onDay,
    required this.onStep,
  });
  final DateTime month;
  final int slide;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final lead = month.weekday % 7; // weeks start on Sunday
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = ((lead + days) / DateTime.daysPerWeek).ceil();
    final duration = motionFor(context, Motion.route);
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > _flingVelocity) onStep(v < 0 ? 1 : -1);
      },
      child: ClipRect(
        // Months have four to six weeks: the height eases instead of jumping.
        child: AnimatedSize(
          duration: duration,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: Motion.emphasized,
            switchOutCurve: Motion.emphasized.flipped,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) {
              // The incoming month enters from the side it lies on; the old one leaves opposite.
              final from = child.key == ValueKey(month) ? slide : -slide;
              return SlideTransition(
                position: Tween(
                  begin: Offset(from.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Column(
              key: ValueKey(month),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var w = 0; w < weeks; w++)
                  _WeekRow(
                    start: DateTime(
                      month.year,
                      month.month,
                      1 - lead + w * DateTime.daysPerWeek,
                    ),
                    month: month,
                    selected: selected,
                    today: today,
                    counts: counts,
                    onDay: onDay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One week per page; a swipe moves a week and keeps the weekday selected.
class _WeekStrip extends StatefulWidget {
  const _WeekStrip({
    required this.selected,
    required this.today,
    required this.counts,
    required this.onDay,
  });
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onDay;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
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
      // Chevrons and "today" slide the strip; a far jump would spin through every week between.
      if ((page - (_pages.page ?? page)).abs() <= 1 &&
          !MediaQuery.disableAnimationsOf(context)) {
        _pages.animateToPage(
          page,
          duration: Motion.route,
          curve: Motion.emphasized,
        );
      } else {
        _pages.jumpToPage(page);
      }
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _rowHeight,
    child: PageView.builder(
      key: const ValueKey('week-strip'),
      controller: _pages,
      onPageChanged: (page) {
        // Already there when the parent moved the day (chevrons, today, month grid).
        if (page == _pageOf(widget.selected)) return;
        widget.onDay(_dayAt(page, widget.selected.weekday % 7));
      },
      itemBuilder: (context, page) => _WeekRow(
        start: _dayAt(page, 0),
        selected: widget.selected,
        today: widget.today,
        counts: widget.counts,
        onDay: widget.onDay,
      ),
    ),
  );
}

/// A day: the numeral ("today" in words), one dot when it has bookings. The selected day sits
/// on an ink square that morphs in from a circle.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.outside,
    required this.count,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final bool today;
  final bool outside;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = selected
        ? c.surface
        : today
        ? context.primary
        : outside
        ? c.inkMuted.withValues(alpha: _outsideAlpha)
        : c.ink;
    return Semantics(
      selected: selected,
      label: '${dateLabel(date, context.lang)}${count == 0 ? '' : ' · $count'}',
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dayRadius),
        ),
        onTap: onTap,
        // Center: the ink fills the whole cell, not just the square.
        child: Center(
          child: AnimatedContainer(
            duration: motionFor(context, Motion.standard),
            curve: Motion.ease,
            width: _daySize,
            height: _daySize,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected ? c.ink : c.ink.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(
                selected ? _dayRadius : _daySize / 2,
              ),
            ),
            // "Today" is a word and long in some languages: it scales down inside the square.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    today ? context.t.today : '${date.day}',
                    style: context.text.titleMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: today ? 14 : null,
                    ),
                  ),
                  if (count > 0)
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // On the ink square of dark mode (a light fill) the bright teal would vanish.
                        color: selected && c.isDark ? c.primaryTint : c.fresh,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected day's bookings grouped by address ("우리집 2"). An empty day says so and offers
/// the upcoming bookings instead, so nothing active is ever more than a glance away.
class _DayList extends StatelessWidget {
  const _DayList({super.key, required this.items, required this.upcoming});
  final List<Booking> items;
  final List<Booking> upcoming;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final groups = <String, List<Booking>>{};
    for (final b in items) {
      (groups[b.address['label'] as String? ?? ''] ??= []).add(b);
    }
    var row = 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              child: Center(
                child: Text(t.bookingsEmpty, style: context.text.bodySmall),
              ),
            ),
          for (final MapEntry(key: label, value: list) in groups.entries) ...[
            Text.rich(
              TextSpan(
                text: label,
                children: [
                  TextSpan(
                    text: ' ${list.length}',
                    style: TextStyle(
                      color: context.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              style: context.text.bodyMedium?.copyWith(color: c.inkSoft),
            ),
            const SizedBox(height: Space.xxs),
            for (final b in list)
              StaggerIn(index: row++, child: BookingCard(booking: b)),
            const SizedBox(height: Space.sm),
          ],
          if (upcoming.isNotEmpty) ...[
            SectionTitle(t.bookingsUpcoming),
            for (final b in upcoming)
              StaggerIn(
                index: row++,
                child: BookingCard(booking: b, showDate: true),
              ),
          ],
        ],
      ),
    );
  }
}
