import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'more.dart';

/// Owner-only earnings: weekly or monthly net chart, the next payout, and balances.
/// Team members never reach this screen; the API refuses them too.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _grain = 'week';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pEarnings)),
      body: AsyncView<Json>(
        key: ValueKey(_grain),
        load: () async => await context.api.get('/partner/earnings', query: {'grain': _grain}) as Json,
        builder: (context, data, _) => ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'week', label: Text(t.pWeekly)),
                ButtonSegment(value: 'month', label: Text(t.pMonthly)),
              ],
              selected: {_grain},
              onSelectionChanged: (s) => setState(() => _grain = s.first),
            ),
            const SizedBox(height: Space.md),
            _NextPayoutCard(data: data),
            const SizedBox(height: Space.md),
            _ChartCard(series: [for (final p in (data['series'] as List)) p as Json]),
            const SizedBox(height: Space.md),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettlementsScreen())),
              child: Text('${t.pSettlements} ›'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPayoutCard extends StatelessWidget {
  const _NextPayoutCard({required this.data});
  final Json data;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final next = data['next_payout'] as Json?;
    return AppCard(
      glow: ServiceHues.mattress.tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.pNextPayout, style: context.text.labelMedium),
          const SizedBox(height: Space.xs),
          Text(
            next == null ? t.pNoPayout : context.won((next['amount'] as num).toInt()),
            style: context.text.headlineSmall,
          ),
          if (next != null) Text(t.pNextPayoutOn(next['date'] as String), style: context.text.bodySmall),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(child: Text('${t.pPendingTotal}\n${context.won((data['pending_total'] as num).toInt())}', style: context.text.bodySmall)),
              Expanded(child: Text('${t.pPaidTotal}\n${context.won((data['paid_total'] as num).toInt())}', style: context.text.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.series});
  final List<Json> series;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.line, strokeWidth: 1)),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < series.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: ((series[i]['net'] as num?) ?? 0).toDouble(),
                      color: ServiceHues.mattress.tone,
                      width: 10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}
