import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final d = context.console.dashboard;
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
          const SizedBox(height: Space.lg),
          StaggerIn(
            index: 1,
            child: LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 1000 ? 6 : (c.maxWidth > 560 ? 3 : 2);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  mainAxisSpacing: Space.sm,
                  crossAxisSpacing: Space.sm,
                  childAspectRatio: 1.3,
                  children: [
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
