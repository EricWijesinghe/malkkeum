import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'jobs.dart';

String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Month view with a job-count chip per day, then the selected day's jobs.
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});
  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  final _view = GlobalKey<AsyncViewState<List<Booking>>>();
  int _seen = -1;

  Future<List<Booking>> _load() async {
    final from = DateTime(_month.year, _month.month);
    final to = DateTime(_month.year, _month.month + 1, 0);
    return (await context.api.get(
              '/partner/schedule',
              query: {'from': _iso(from), 'to': _iso(to)},
            )
            as List)
        .map((e) => Booking.fromJson(e as Json))
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.pro.jobsVersion;
    if (_seen != -1 && v != _seen) _view.currentState?.reload();
    _seen = v;
  }

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
    _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final loc = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(t.pTabSchedule, style: context.text.headlineSmall),
      ),
      body: AsyncView<List<Booking>>(
        key: _view,
        load: _load,
        builder: (context, jobs, reload) {
          final byDay = <int, List<Booking>>{};
          for (final j in jobs) {
            (byDay[j.visitDate.day] ??= []).add(j);
          }
          final lead = DateTime(_month.year, _month.month).weekday % 7;
          final days = DateUtils.getDaysInMonth(_month.year, _month.month);
          final dayJobs = jobs
              .where((j) => DateUtils.isSameDay(j.visitDate, _day))
              .toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: loc.previousMonthTooltip,
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => _shift(-1),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat.yMMMM(context.lang).format(_month),
                              textAlign: TextAlign.center,
                              style: context.text.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: loc.nextMonthTooltip,
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => _shift(1),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          for (final w in loc.narrowWeekdays)
                            Expanded(
                              child: Center(
                                child: Text(w, style: context.text.labelSmall),
                              ),
                            ),
                        ],
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 7,
                        childAspectRatio: 0.8,
                        children: [
                          for (var i = 0; i < lead; i++) const SizedBox(),
                          for (var d = 1; d <= days; d++)
                            _cell(
                              DateTime(_month.year, _month.month, d),
                              byDay[d] ?? const [],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                SectionTitle(dateLabel(_day, context.lang)),
                if (dayJobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Center(
                      child: Text(t.pNoSchedule, style: context.text.bodySmall),
                    ),
                  ),
                for (final j in dayJobs) _JobRow(job: j),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cell(DateTime date, List<Booking> jobs) {
    final selected = DateUtils.isSameDay(date, _day);
    final active = jobs.where((j) => j.status >= 0).length;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _day = date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryTint : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: context.text.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (active > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: context.colors.ink,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  context.t.pJobsCount('$active'),
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.surface,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});
  final Booking job;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final j = job;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => JobDetailScreen(id: j.id)),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  slotLabel(context, j.startHour, j.isQuote),
                  style: context.text.titleSmall,
                ),
                if (j.minutes != null)
                  Text(t.duration(j.minutes!), style: context.text.labelSmall),
              ],
            ),
            const SizedBox(width: Space.md),
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: ServiceHues.of(j.serviceCode).tone,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.service(j.serviceCode),
                          style: context.text.titleSmall,
                        ),
                      ),
                      if (j.status == -1)
                        Tag(
                          label: t.statusCancelled,
                          hue: StatusHues.cancelled,
                        ),
                      if (j.reschedule != null)
                        Tag(label: t.reschedule, hue: StatusHues.consultation),
                    ],
                  ),
                  Text(
                    '${j.address['road_address']}',
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
