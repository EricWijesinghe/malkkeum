import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = context.console;
    final d = state.dashboard;
    final failed = switch (state.dashboardError) {
      null => null,
      // Over numbers already on screen it is a banner: they are the last good ones, not live.
      final Object e => ErrorRetry(
        compact: d != null,
        message: t.error(e),
        retryLabel: t.retry,
        onRetry: state.loadDashboard,
      ),
    };
    // Not loaded is not "0 jobs today": placeholders while loading, the error when it failed.
    if (d == null) return failed ?? const SkeletonList();
    int n(String k) => (d[k] as num? ?? 0).toInt();
    final kpis = [
      (
        t.cTodayJobs,
        '${n('today_jobs')}',
        Icons.today_rounded,
        ServiceHues.bathroom,
      ),
      (
        t.cOpenQuotes,
        '${n('open_quotes')}',
        Icons.request_quote_rounded,
        ServiceHues.studio,
      ),
      (
        t.cUnassigned,
        '${n('unassigned')}',
        Icons.person_search_rounded,
        ServiceHues.kitchen,
      ),
      (
        t.cUnreadThreads,
        '${n('unread_threads')}',
        Icons.mark_chat_unread_rounded,
        ServiceHues.mattress,
      ),
      (
        t.cRevenue30,
        context.won(n('revenue_30d')),
        Icons.trending_up_rounded,
        ServiceHues.moveOut,
      ),
      (
        t.cBookings30,
        '${n('bookings_30d')}',
        Icons.event_available_rounded,
        ServiceHues.aircon,
      ),
      (
        t.growthAverageRating,
        d['average_rating'] == null
            ? '-'
            : (d['average_rating'] as num).toStringAsFixed(1),
        Icons.star_rounded,
        ServiceHues.kitchen,
      ),
      (
        t.growthReferralConversion,
        t.growthReferralValue(
          '${n('referrals_rewarded')}',
          '${n('referrals_invited')}',
        ),
        Icons.group_add_rounded,
        ServiceHues.mattress,
      ),
    ];
    final byService = ((d['by_service'] as Json?) ?? const {}).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    final maxCount = byService.values.fold<int>(1, (a, b) => a > b ? a : b);
    return RefreshIndicator(
      onRefresh: context.consoleRead.loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          StaggerIn(
            index: 0,
            child: Text(t.cDashboard, style: context.text.headlineMedium),
          ),
          if (failed != null) ...[const SizedBox(height: Space.md), failed],
          const SizedBox(height: Space.lg),
          StaggerIn(
            index: 1,
            child: LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 1000 ? 6 : (c.maxWidth > 560 ? 3 : 2);
                return _KpiGrid(
                  columns: cols,
                  tiles: [
                    for (final (label, value, icon, hue) in kpis)
                      // Hover tilt is desktop-first; touch gets the same card with the press spring only.
                      Tilt3D(
                        child: SizedBox.expand(
                          child: AppCard(
                            glow: hue.tone,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: context.colors.tintOf(hue),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: context.colors.isDark
                                        ? hue.tint
                                        : hue.tone,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    value,
                                    style: context.text.headlineSmall,
                                  ),
                                ),
                                Text(
                                  label,
                                  style: context.text.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Space.xl),
          StaggerIn(
            index: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.cByService, style: context.text.titleMedium),
                  const SizedBox(height: Space.md),
                  for (final code in const [
                    'studio',
                    'kitchen',
                    'bathroom',
                    'mattress',
                    'aircon',
                    'sofa',
                    'move_out',
                    'move_in',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              t.service(code),
                              style: context.text.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Semantics(
                              label:
                                  '${t.service(code)} ${byService[code] ?? 0}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (byService[code] ?? 0) / maxCount,
                                  minHeight: 14,
                                  backgroundColor: context.colors.line,
                                  color: ServiceHues.of(code).tone,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${byService[code] ?? 0}',
                              textAlign: TextAlign.right,
                              style: context.text.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// KPI tiles in rows of [columns]. Tiles size to their text instead of a fixed aspect ratio, so
/// large system fonts and long translations grow the card rather than overflow it. A row stretches
/// to its tallest tile, and short last rows keep the column lines.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns, required this.tiles});

  final int columns;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var start = 0; start < tiles.length; start += columns) ...[
        if (start > 0) const SizedBox(height: Space.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) const SizedBox(width: Space.sm),
                Expanded(
                  child: i < tiles.length ? tiles[i] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
