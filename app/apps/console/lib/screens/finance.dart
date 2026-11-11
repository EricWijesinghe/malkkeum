import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../download.dart';
import '../state.dart';
import 'finance_tax.dart';

/// Owner finance: period KPIs, trend charts, payment mix, partner and service tables, accountant CSVs.
/// Every figure is integer won from the API. Charts only convert to double for drawing.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

enum _Period { day, week, month, custom }

enum _Grain { day30, day90, week, month }

class _FinanceScreenState extends State<FinanceScreen> {
  _Period _period = _Period.month;
  DateTimeRange? _custom;
  _Grain _grain = _Grain.day30;
  bool _loading = true;
  bool _failed = false;
  Json _summary = const {};
  List<Json> _series = const [];
  List<Json> _partners = const [];
  List<Json> _services = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String?> get _periodQuery => switch (_period) {
    _Period.custom when _custom != null => {'period': 'custom', 'from': _ymd(_custom!.start), 'to': _ymd(_custom!.end)},
    _Period.custom || _Period.month => {'period': 'month'},
    _Period.week => {'period': 'week'},
    _Period.day => {'period': 'day'},
  };

  Map<String, String?> get _grainQuery => switch (_grain) {
    _Grain.day30 => {'grain': 'day', 'days': '30'},
    _Grain.day90 => {'grain': 'day', 'days': '90'},
    _Grain.week => {'grain': 'week'},
    _Grain.month => {'grain': 'month'},
  };

  Future<void> _load() async {
    final api = context.api;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final r = await Future.wait([
        api.get('/admin/finance/summary', query: _periodQuery),
        api.get('/admin/finance/series', query: _grainQuery),
        api.get('/admin/finance/partners', query: _periodQuery),
        api.get('/admin/finance/services', query: _periodQuery),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = r[0] as Json;
        _series = _rows(r[1]);
        _partners = _rows(r[2]);
        _services = _rows(r[3]);
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _pickPeriod(_Period p) async {
    if (p != _Period.custom) {
      setState(() => _period = p);
      return _load();
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = _Period.custom;
      _custom = picked;
    });
    return _load();
  }

  Future<void> _export(String kind) => _exportAt('/admin/finance/export/$kind', _periodQuery, 'malkkeum-$kind.csv');

  Future<void> _exportAt(String path, Map<String, String?> query, String fileName) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      final bytes = await context.api.getBytes(path, query: query);
      final saved = await saveCsv(bytes, fileName);
      messenger.showSnackBar(SnackBar(content: Text(saved ? t.fDownload : t.fDownloadWebOnly)));
    } on ApiException {
      messenger.showSnackBar(SnackBar(content: Text(t.fDownloadFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          Text(t.fFinance, style: context.text.headlineMedium),
          const SizedBox(height: Space.md),
          _PeriodBar(period: _period, custom: _custom, onPick: _pickPeriod),
          const SizedBox(height: Space.lg),
          if (_failed)
            _ErrorCard(onRetry: _load)
          else if (_loading && _summary.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(Space.xl), child: CircularProgressIndicator()))
          else ...[
            _KpiGrid(summary: _summary),
            const SizedBox(height: Space.sm),
            Text(t.fVatNote, style: context.text.labelSmall),
            const SizedBox(height: Space.xl),
            _TrendCard(series: _series, grain: _grain, onGrain: (g) {
              setState(() => _grain = g);
              _load();
            }),
            const SizedBox(height: Space.xl),
            _MixRow(summary: _summary),
            const SizedBox(height: Space.xl),
            _PartnerCard(partners: _partners),
            const SizedBox(height: Space.xl),
            _ServiceCard(services: _services),
            const SizedBox(height: Space.xl),
            _ExportCard(onExport: _export),
            const SizedBox(height: Space.xl),
            TaxSection(periodQuery: _periodQuery, onExport: _exportAt),
          ],
        ],
      ),
    );
  }
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<Json> _rows(Object? v) => [for (final e in (v as List? ?? const [])) e as Json];

int _n(Json m, String k) => (m[k] as num? ?? 0).toInt();

int _payout(Json m, String k) => _n((m['payouts'] as Json?) ?? const {}, k);

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.period, required this.custom, required this.onPick});
  final _Period period;
  final DateTimeRange? custom;
  final ValueChanged<_Period> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<_Period>(
          segments: [
            ButtonSegment(value: _Period.day, label: Text(t.fPeriodDay)),
            ButtonSegment(value: _Period.week, label: Text(t.fPeriodWeek)),
            ButtonSegment(value: _Period.month, label: Text(t.fPeriodMonth)),
            ButtonSegment(value: _Period.custom, label: Text(t.fPeriodCustom)),
          ],
          selected: {period},
          onSelectionChanged: (s) => onPick(s.first),
        ),
        if (custom != null && period == _Period.custom)
          Text('${_ymd(custom!.start)} ~ ${_ymd(custom!.end)}', style: context.text.labelMedium),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});
  final Json summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tiles = [
      (t.fGross, context.won(_n(summary, 'gross')), Icons.receipt_long_rounded, ServiceHues.studio),
      (t.fNetRevenue, context.won(_n(summary, 'net_revenue')), Icons.trending_up_rounded, ServiceHues.moveOut),
      (t.fPlatformFee, context.won(_n(summary, 'platform_fee')), Icons.percent_rounded, ServiceHues.bathroom),
      (t.fVatEstimate, context.won(_n(summary, 'vat_estimate')), Icons.account_balance_rounded, ServiceHues.kitchen),
      (t.fPaidOut, context.won(_payout(summary, 'paid')), Icons.payments_rounded, ServiceHues.aircon),
      (t.fPendingOut, context.won(_payout(summary, 'pending')), Icons.schedule_rounded, ServiceHues.mattress),
      (t.fAov, context.won(_n(summary, 'avg_order_value')), Icons.shopping_bag_rounded, ServiceHues.sofa),
      (t.fCancelRate, '${(_n(summary, 'cancellation_bps') / 100).toStringAsFixed(1)}%', Icons.event_busy_rounded, ServiceHues.moveIn),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1000 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: Space.sm,
          crossAxisSpacing: Space.sm,
          childAspectRatio: c.maxWidth > 1000 ? 1.6 : 1.3,
          children: [
            for (final (label, value, icon, hue) in tiles)
              Semantics(
                label: '$label $value',
                child: AppCard(
                  glow: hue.tone,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: context.colors.tintOf(hue), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 20, color: context.colors.isDark ? hue.tint : hue.tone),
                      ),
                      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: context.text.headlineSmall)),
                      Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.series, required this.grain, required this.onGrain});
  final List<Json> series;
  final _Grain grain;
  final ValueChanged<_Grain> onGrain;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final net = [for (final p in series) _n(p, 'net_revenue').toDouble()];
    final fee = [for (final p in series) _n(p, 'platform_fee').toDouble()];
    final paid = [for (final p in series) _payout(p, 'paid').toDouble()];
    final hasData = series.any((p) => _n(p, 'gross') > 0 || _payout(p, 'paid') > 0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.fTrend, style: context.text.titleMedium)),
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final (g, label) in [
                    (_Grain.day30, t.fRangeDays('30')),
                    (_Grain.day90, t.fRangeDays('90')),
                    (_Grain.week, t.fPeriodWeek),
                    (_Grain.month, t.fPeriodMonth),
                  ])
                    ChoiceChip(label: Text(label), selected: grain == g, onSelected: (_) => onGrain(g)),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (!hasData)
            Padding(padding: const EdgeInsets.all(Space.lg), child: Text(t.fNoRecords, style: context.text.bodySmall))
          else ...[
            SizedBox(height: 200, child: _Lines(net: net, fee: fee, netLabel: t.fNetRevenue, feeLabel: t.fPlatformFee, colors: context.colors)),
            const SizedBox(height: Space.lg),
            SizedBox(height: 160, child: _Bars(fee: fee, paid: paid, feeLabel: t.fPlatformFee, paidLabel: t.fPaidOut, colors: context.colors)),
          ],
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.net, required this.fee, required this.netLabel, required this.feeLabel, required this.colors});
  final List<double> net;
  final List<double> fee;
  final String netLabel;
  final String feeLabel;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots(List<double> v) => [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])];
    return LineChart(
      LineChartData(
        gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.line, strokeWidth: 1)),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(spots: spots(net), isCurved: true, color: ServiceHues.moveOut.tone, barWidth: 3, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: spots(fee), isCurved: true, color: ServiceHues.bathroom.tone, barWidth: 3, dotData: const FlDotData(show: false)),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.fee, required this.paid, required this.feeLabel, required this.paidLabel, required this.colors});
  final List<double> fee;
  final List<double> paid;
  final String feeLabel;
  final String paidLabel;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.line, strokeWidth: 1)),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < fee.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: fee[i], color: ServiceHues.bathroom.tone, width: 6, borderRadius: BorderRadius.circular(2)),
                BarChartRodData(toY: paid[i], color: ServiceHues.aircon.tone, width: 6, borderRadius: BorderRadius.circular(2)),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _MixRow extends StatelessWidget {
  const _MixRow({required this.summary});
  final Json summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final methods = _rows(summary['payment_methods']);
    final hues = [ServiceHues.studio, ServiceHues.bathroom, ServiceHues.kitchen, ServiceHues.mattress, ServiceHues.aircon, ServiceHues.sofa];
    final total = methods.fold<int>(0, (a, m) => a + _n(m, 'amount'));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.fMethods, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          if (methods.isEmpty)
            Text(t.fNoRecords, style: context.text.bodySmall)
          else
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sections: [
                        for (var i = 0; i < methods.length; i++)
                          PieChartSectionData(value: _n(methods[i], 'amount').toDouble(), color: hues[i % hues.length].tone, radius: 22, title: ''),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < methods.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.xs),
                          child: Text(
                            '${methods[i]['method']} · ${context.won(_n(methods[i], 'amount'))}'
                            '${total > 0 ? ' (${(_n(methods[i], 'amount') * 100 / total).round()}%)' : ''}',
                            style: context.text.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partners});
  final List<Json> partners;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.fByPartner, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          if (partners.isEmpty)
            Text(t.fNoRecords, style: context.text.bodySmall)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.fColPartner)),
                  DataColumn(label: Text(t.fColJobs), numeric: true),
                  DataColumn(label: Text(t.fColSettled), numeric: true),
                  DataColumn(label: Text(t.fColFee), numeric: true),
                  DataColumn(label: Text(t.fColNet), numeric: true),
                  DataColumn(label: Text(t.fPaidOut), numeric: true),
                  DataColumn(label: Text(t.fPendingOut), numeric: true),
                ],
                rows: [
                  for (final p in partners)
                    DataRow(
                      cells: [
                        DataCell(Text('${p['name']}${(p['team_name'] as String? ?? '').isEmpty ? '' : ' · ${p['team_name']}'}')),
                        DataCell(Text('${_n(p, 'jobs')}')),
                        DataCell(Text(context.won(_n(p, 'settled_gross')))),
                        DataCell(Text(context.won(_n(p, 'fee')))),
                        DataCell(Text(context.won(_n(p, 'net')))),
                        DataCell(Text(context.won(_n(p, 'paid')))),
                        DataCell(Text(context.won(_n(p, 'pending')))),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.services});
  final List<Json> services;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final max = services.fold<int>(1, (a, s) => _n(s, 'gross') > a ? _n(s, 'gross') : a);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.fByService, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          if (services.isEmpty) Text(t.fNoRecords, style: context.text.bodySmall),
          for (final s in services)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  SizedBox(width: 110, child: Text(t.service(s['service_code'] as String), style: context.text.bodySmall, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: Semantics(
                      label: '${t.service(s['service_code'] as String)} ${context.won(_n(s, 'gross'))}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _n(s, 'gross') / max,
                          minHeight: 14,
                          backgroundColor: context.colors.line,
                          color: ServiceHues.of(s['service_code'] as String).tone,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 110, child: Text(context.won(_n(s, 'gross')), textAlign: TextAlign.right, style: context.text.labelMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.onExport});
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.fExportTitle, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(onPressed: () => onExport('ledger'), icon: const Icon(Icons.download_rounded), label: Text(t.fExportLedger)),
              OutlinedButton.icon(onPressed: () => onExport('settlements'), icon: const Icon(Icons.download_rounded), label: Text(t.fExportSettlements)),
              FilledButton.icon(onPressed: () => onExport('monthly'), icon: const Icon(Icons.download_rounded), label: Text(t.fExportMonthly)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Column(
        children: [
          Text(t.fLoadFailed, style: context.text.bodyMedium),
          const SizedBox(height: Space.sm),
          TextButton(onPressed: onRetry, child: Text(t.fRetry)),
        ],
      ),
    );
  }
}
