import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Funnel totals for the window (GET /admin/analytics/funnel).
typedef FunnelFn = Future<Json> Function(int days);

/// Weekly signup cohorts (GET /admin/analytics/cohorts).
typedef CohortsFn = Future<List<Json>> Function(int weeks);

/// Share of `n` out of `of`, 0 when there is nothing to divide by.
double shareOf(num n, num of) => of <= 0 ? 0 : (n / of).clamp(0, 1).toDouble();

/// Funnel bars (each stage as a share of signups) and a cohort table with raw counts per week.
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key, required this.funnel, required this.cohorts, this.days = 30, this.weeks = 8});
  final FunnelFn funnel;
  final CohortsFn cohorts;
  final int days;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<Json>(
          future: funnel(days),
          builder: (context, snap) {
            if (snap.hasError) return Text(context.t.error(snap.error!));
            final f = snap.data;
            if (f == null) return const LinearProgressIndicator();
            final signed = (f['signed_up'] as num);
            final stages = [
              (t.anInstalls, f['installs'] as num),
              (t.anSignedUp, signed),
              (t.anQuoted, f['quoted'] as num),
              (t.anBooked, f['booked'] as num),
              (t.anPaid, f['paid'] as num),
              (t.anRepeat, f['repeat_buyers'] as num),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.anFunnel('$days'), style: Theme.of(context).textTheme.titleMedium),
                for (final (label, n) in stages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$label · $n'),
                        LinearProgressIndicator(value: shareOf(n, signed)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text(t.anCohorts, style: Theme.of(context).textTheme.titleMedium),
        FutureBuilder<List<Json>>(
          future: cohorts(weeks),
          builder: (context, snap) {
            if (snap.hasError) return Text(context.t.error(snap.error!));
            final rows = snap.data;
            if (rows == null) return const LinearProgressIndicator();
            return Column(
              children: [
                for (final r in rows)
                  ListTile(
                    dense: true,
                    title: Text((r['week'] as String).substring(0, 10)),
                    subtitle: Text(
                      '${t.anCohortSize('${r['size']}')} · ${t.anWeekAfter('1')} ${r['w1']} · '
                      '${t.anWeekAfter('2')} ${r['w2']} · ${t.anWeekAfter('3')} ${r['w3']} · ${t.anWeekAfter('4')} ${r['w4']}',
                    ),
                    trailing: Text('${(shareOf(r['w1'] as num, r['size'] as num) * 100).round()}%'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
