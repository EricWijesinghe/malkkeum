import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'chat.dart';
import 'complete.dart';
import 'site_actions.dart';
import 'navigate.dart';

part 'job_detail.dart';

String slotLabel(BuildContext context, int hour, bool isQuote) => isQuote
    ? (hour < 12 ? context.t.morning : context.t.afternoon)
    : hourLabel(hour, context.lang);

String districtName(BuildContext context, String code) =>
    districtByCode(code)?.name(context.lang) ?? code;

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});
  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  String _kind = 'direct';
  String _sort = 'newest';
  bool _closed = false;
  int _seen = -1;

  Future<List<Json>> _load() async =>
      (await context.api.get(
                '/partner/jobs',
                query: {
                  'kind': _kind,
                  'sort': _sort,
                  'include_closed': '$_closed',
                },
              )
              as List)
          .cast<Json>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.pro.jobsVersion;
    if (_seen != -1 && v != _seen) _view.currentState?.reload();
    _seen = v;
  }

  void _set(VoidCallback fn) {
    setState(fn);
    _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(t.pTabJobs, style: context.text.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.md),
            // Capped and scaled so long translations never push the title off a small phone.
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${t.pPendingPayout} ${context.won(pro.pendingPayout)}',
                    style: context.text.labelMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          // Grows with the system font so the filter rows never clip.
          preferredSize: Size.fromHeight(MediaQuery.textScalerOf(context).scale(120).clamp(104, 200)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.xs,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'direct', label: Text(t.pDirect)),
                      ButtonSegment(value: 'quote', label: Text(t.pQuoteReq)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => _set(() => _kind = s.first),
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: FilterChip(
                        label: Text(t.pShowClosed, overflow: TextOverflow.ellipsis),
                        selected: _closed,
                        onSelected: (v) => _set(() => _closed = v),
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    Flexible(child: PopupMenuButton<String>(
                      initialValue: _sort,
                      onSelected: (v) => _set(() => _sort = v),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'newest',
                          child: Text(t.pSortNewest),
                        ),
                        PopupMenuItem(
                          value: 'visit',
                          child: Text(t.pSortVisit),
                        ),
                        PopupMenuItem(
                          value: 'amount',
                          child: Text(t.pSortAmount),
                        ),
                      ],
                      // 48 dp minimum tap target; the bare label is only ~34 dp tall.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.all(Space.xs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: Text(switch (_sort) {
                                'visit' => t.pSortVisit,
                                'amount' => t.pSortAmount,
                                _ => t.pSortNewest,
                              }, style: context.text.labelMedium, overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.expand_more_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!pro.phoneVerified) const _PhoneGate(),
          Expanded(
            child: AsyncView<List<Json>>(
              key: _view,
              load: _load,
              builder: (context, jobs, reload) => RefreshIndicator(
                onRefresh: reload,
                child: jobs.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: 420,
                            child: EmptyState(
                              icon: Icons.travel_explore_rounded,
                              title: t.pNoJobs,
                              body: t.pNoJobsBody,
                              hue: ServiceHues.moveOut,
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(Space.gutter),
                        children: [
                          for (final (i, j) in jobs.indexed)
                            StaggerIn(
                              index: i,
                              child: _JobCard(job: j, onChanged: reload),
                            ),
                          const SizedBox(height: Space.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: context.colors.inkMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t.pPrivacyNote,
                                  style: context.text.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onChanged});
  final Json job;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    final code = job['service_code'] as String;
    final isQuote = job['answers'] != null;
    final open = job['is_open'] as bool? ?? false;
    final price = (job['customer_price'] as num?)?.toInt();
    final isNew =
        DateTime.now()
            .difference(DateTime.parse(job['created_at'] as String))
            .inHours <
        3;
    final facts = [
      districtName(context, job['district_code'] as String),
      if (job['road_area'] != null && (job['road_area'] as String).isNotEmpty)
        job['road_area'] as String,
      if (job['size_pyeong'] != null) t.pyeong('${job['size_pyeong']}'),
    ].join(' · ');
    return Opacity(
      opacity: open ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: AppCard(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JobDetailScreen(id: job['id'] as String),
              ),
            );
            await onChanged();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceGlyph(code, size: 40),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      t.service(code),
                      style: context.text.titleSmall,
                    ),
                  ),
                  if (isNew && open)
                    Tag(label: t.pNew, hue: StatusHues.cancelled),
                  if (!open) Tag(label: t.pClosed, hue: StatusHues.completed),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                '${dateLabel(DateTime.parse(job['visit_date'] as String), context.lang)} ${slotLabel(context, (job['start_hour'] as num).toInt(), isQuote)}',
                style: context.text.bodyMedium,
              ),
              Text(facts, style: context.text.bodySmall),
              const Divider(height: Space.xl),
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQuote ? t.pCustomerEstimate : t.pPayout,
                        style: context.text.labelSmall,
                      ),
                      Text(
                        isQuote
                            ? context.won(
                                (job['estimate'] as num? ?? 0).toInt(),
                              )
                            : context.won(pro.payoutFor(price ?? 0)),
                        style: context.text.titleLarge,
                      ),
                    ],
                  )),
                  if (job['my_quote'] != null)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Tag(
                          label: '${t.pMyQuote} ${context.won((job['my_quote'] as num).toInt())}',
                          hue: StatusHues.confirmed,
                        ),
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
}
