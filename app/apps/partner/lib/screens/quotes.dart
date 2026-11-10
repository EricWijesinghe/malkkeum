import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'jobs.dart';

ServiceHue quoteHue(String state) => switch (state) {
  'selected' => StatusHues.assigned,
  'waiting' => StatusHues.confirmed,
  'rejected' => StatusHues.cancelled,
  _ => StatusHues.completed,
};

String quoteStateLabel(T t, String s) => switch (s) {
  'waiting' => t.pQ_waiting,
  'selected' => t.pQ_selected,
  'rejected' => t.pQ_rejected,
  _ => t.pQ_closed,
};

class QuotesTab extends StatefulWidget {
  const QuotesTab({super.key});
  @override
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();
  String? _filter;
  bool _unseen = false;
  int _seen = -1;

  Future<List<Json>> _load() async {
    final r = (await context.api.get('/partner/quotes') as List).cast<Json>();
    // Opening the tab marks results as seen on the server; refresh the badge.
    if (mounted) context.proRead.loadBadges().ignore();
    return r;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.pro.jobsVersion;
    if (_seen != -1 && v != _seen) _view.currentState?.reload();
    _seen = v;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(t.pTabQuotes, style: context.text.headlineSmall),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              children: [
                for (final s in [
                  null,
                  'waiting',
                  'selected',
                  'rejected',
                  'closed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        s == null ? t.pQuoteAll : quoteStateLabel(t, s),
                      ),
                      selected: _filter == s,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  ),
                FilterChip(
                  label: Text(t.pUnseenOnly),
                  selected: _unseen,
                  onSelected: (v) => setState(() => _unseen = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<Json>>(
              key: _view,
              load: _load,
              builder: (context, all, reload) {
                final items = all
                    .where(
                      (q) =>
                          (_filter == null || q['state'] == _filter) &&
                          (!_unseen || q['seen_by_pro'] == false),
                    )
                    .toList();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.request_quote_rounded,
                    title: t.pNoQuotes,
                    hue: ServiceHues.moveIn,
                  );
                }
                return RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.all(Space.gutter),
                    children: [
                      for (final q in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.sm),
                          child: AppCard(
                            onTap: () => _open(q, reload),
                            child: Row(
                              children: [
                                ServiceGlyph(
                                  q['service_code'] as String,
                                  size: 44,
                                ),
                                const SizedBox(width: Space.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              t.service(
                                                q['service_code'] as String,
                                              ),
                                              style: context.text.titleSmall,
                                            ),
                                          ),
                                          if (q['seen_by_pro'] == false) ...[
                                            Tag(
                                              label: t.pNew,
                                              hue: StatusHues.cancelled,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Tag(
                                            label: quoteStateLabel(
                                              t,
                                              q['state'] as String,
                                            ),
                                            hue: quoteHue(q['state'] as String),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${dateLabel(DateTime.parse(q['visit_date'] as String), context.lang)} · ${districtName(context, q['district_code'] as String)}',
                                        style: context.text.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${t.pMyQuote} ${context.won((q['amount'] as num).toInt())} · ${t.pCustomerEstimate} ${context.won((q['estimate'] as num? ?? 0).toInt())}',
                                        style: context.text.labelMedium,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Json q, Future<void> Function() reload) async {
    final t = context.t;
    if (q['state'] == 'selected') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(id: q['booking_id'] as String),
        ),
      );
      return;
    }
    if (q['state'] != 'waiting') return;
    final action = await showAppSheet<String>(
      context,
      title: t.pMyQuote,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ctx.won((q['amount'] as num).toInt()),
              style: ctx.text.headlineMedium,
            ),
            if ((q['note'] as String?)?.isNotEmpty ?? false)
              Text(q['note'] as String, style: ctx.text.bodySmall),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('edit'),
              child: Text(t.edit),
            ),
            const SizedBox(height: Space.xs),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop('withdraw'),
              child: Text(t.pWithdraw),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('view'),
              child: Text(t.pViewJob),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await showQuoteSheet(
          context,
          bookingId: q['booking_id'] as String,
          estimate: (q['estimate'] as num? ?? 0).toInt(),
          current: (q['amount'] as num).toInt(),
          note: q['note'] as String? ?? '',
          edit: true,
        );
      case 'withdraw':
        try {
          await context.api.delete('/partner/jobs/${q['booking_id']}/quote');
          if (mounted) showToast(context, t.pWithdrawn);
        } catch (e) {
          if (mounted) showToast(context, t.error(e));
        }
      case 'view':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JobDetailScreen(id: q['booking_id'] as String),
          ),
        );
    }
    await reload();
  }
}
