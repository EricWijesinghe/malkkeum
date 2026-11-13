import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'flow_widgets.dart';
import 'quote_flow.dart';

/// "8.5%" style percent from basis points.
String pctOf(int bps) =>
    bps % 100 == 0 ? '${bps ~/ 100}' : (bps / 100).toStringAsFixed(1);

int _n(Json e, String k) => (e[k] as num? ?? 0).toInt();

const _checkKickDelay = Duration(milliseconds: 260);

/// Waits for the server estimate; shows a skeleton until it lands, then fades the figures in.
class _EstimateView extends StatelessWidget {
  const _EstimateView({required this.estimate, required this.builder});
  final Future<Json>? estimate;
  final Widget Function(BuildContext, Json) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: estimate,
    builder: (context, snap) {
      if (snap.hasError) {
        return Text(
          context.t.error(snap.error!),
          style: context.text.bodySmall,
        );
      }
      final e = snap.data;
      return FadeThroughSwitcher(
        child: e == null
            ? const Skeleton(key: ValueKey('wait'), height: 120)
            : KeyedSubtree(
                key: const ValueKey('estimate'),
                child: builder(context, e),
              ),
      );
    },
  );
}

/// Step 6/7 (design p18): the "다해 안심예약" card with the server estimate and its benefits.
class QuoteMethodPage extends StatelessWidget {
  const QuoteMethodPage({
    super.key,
    required this.chip,
    required this.estimate,
  });
  final String chip;
  final Future<Json>? estimate;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      children: [
        FlowTitle(t.dfQuoteMethodTitle, chip: chip),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: _EstimateView(
            estimate: estimate,
            builder: (context, e) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.lg),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(color: context.colors.fresh, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: Space.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  t.dfSafeBooking,
                                  style: context.text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Space.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.primaryTint,
                                    borderRadius: BorderRadius.circular(
                                      Radii.chip,
                                    ),
                                  ),
                                  child: Text(
                                    t.dfRecommended,
                                    style: context.text.labelSmall?.copyWith(
                                      color: context.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // The chosen method's check answers with one kick.
                          OneShot(
                            onMount: true,
                            delay: _checkKickDelay,
                            builder: kick,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: context.colors.fresh,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.sm),
                      // Counts up from zero: the estimate was just worked out for these answers.
                      CountIn(
                        value: _n(e, 'total'),
                        format: context.won,
                        style: context.text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        t.dfEstimateVat,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      CheckList([
                        t.dfBenefit1,
                        t.dfBenefit2,
                        t.dfBenefit3,
                        t.dfBenefit4,
                        t.dfBenefit5,
                      ], filled: false),
                    ],
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(
                  t.dfDepositNote(pctOf(_n(e, 'deposit_bps'))),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 7/7 (design p19): everything the customer chose, each section with "변경".
class QuoteReviewPage extends StatelessWidget {
  const QuoteReviewPage({
    super.key,
    required this.chip,
    required this.draft,
    required this.estimate,
    required this.onEdit,
  });
  final String chip;
  final BookingDraft draft;
  final Future<Json>? estimate;
  final ValueChanged<int> onEdit;

  Widget _edit(BuildContext context, int step) => TextButton(
    onPressed: () => onEdit(step),
    child: Text(
      context.t.dfChange,
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: context.colors.inkMuted,
      ),
    ),
  );

  Widget _field(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(value, style: context.text.bodyMedium),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    final d = draft;
    final a = d.answers;
    final address = d.address;
    final hour = d.hour;
    final date = d.date;
    if (address == null || hour == null || date == null) {
      return const SizedBox.shrink();
    }
    final addons = [
      for (final MapEntry(key: unit, value: count) in a.acAddons.entries)
        if (count > 0) '${t.unit(unit)} ${t.dfCountUnits('$count')}',
    ];
    // Sections rise in one after another as the page lands.
    var order = 0;
    Widget inTurn(Widget section) => StaggerIn(index: order++, child: section);
    return ListView(
      children: [
        FlowTitle(t.dfReviewHeader(dateLabel(date, lang)), chip: chip),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.dfVisitTimeLine(
                  '${visitHalf(t, hour)} (${slotRangeLabel(hour, lang)})',
                ),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                t.dfReviewNote,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const FlowBand(),
        inTurn(
          FlowSection(
            title: t.dfHomeInfo,
            trailing: _edit(context, 3),
            children: [
              _field(
                context,
                t.dfSummaryAddress,
                '${address.roadAddress} ${address.detail}',
              ),
              _field(context, t.dfName, address.label),
            ],
          ),
        ),
        const FlowBand(),
        inTurn(
          FlowSection(
            title: t.dfBasicInfo,
            trailing: _edit(context, 0),
            children: [
              _field(
                context,
                t.dfCleanType,
                '${cleaningTypeLabel(t, a.cleaningType)} · ${luggageLabel(t, a.luggage)}',
              ),
              _field(
                context,
                t.dfBuilding,
                '${buildingLabel(t, a.building)} · ${layoutLabel(t, a.layout)} · ${t.dfDuplexTitle} ${a.duplex == true ? t.dfHas : t.dfNone}',
              ),
            ],
          ),
        ),
        const FlowBand(),
        inTurn(
          FlowSection(
            title: t.dfSpaceInfo,
            trailing: _edit(context, 2),
            children: [
              Text(
                '${t.bathroomsLabel} ${t.dfCountN('${a.bathrooms}')} · ${t.balconiesLabel} ${t.dfCountN('${a.balconies}')} · '
                '${t.dfElevatorTitle} ${a.elevator == true ? t.dfHas : t.dfNone}',
                style: context.text.bodyMedium,
              ),
              if (addons.isNotEmpty) ...[
                const SizedBox(height: Space.sm),
                Text(
                  '${t.service('aircon')}: ${addons.join(' · ')}',
                  style: context.text.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const FlowBand(),
        inTurn(
          FlowSection(
            title: t.dfPayInfo,
            children: [
              _EstimateView(
                estimate: estimate,
                builder: (context, e) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_n(e, 'addons') > 0)
                      InfoRow(
                        t.dfEstAddons(pctOf(_n(e, 'addon_discount_bps'))),
                        '+${context.won(_n(e, 'addons'))}',
                      ),
                    InfoRow(t.dfEstAmount, context.won(_n(e, 'total'))),
                    InfoRow(
                      t.dfDepositOnConfirm,
                      context.won(_n(e, 'deposit')),
                    ),
                    Text(
                      t.quoteNoPayNow,
                      style: context.text.bodySmall?.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const FlowBand(),
        inTurn(
          FlowSection(
            title: t.dfNotes,
            children: [
              NoteBox(
                items: [t.dfNote1, t.dfNote2, t.dfNote3, t.dfNoteWarn],
                danger: const {3},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
