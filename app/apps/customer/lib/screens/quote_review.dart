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

/// District, road address and unit on one line (C-09).
String _fullAddress(T t, Address address) => [
  districtByCode(address.districtCode)?.name(t.lang),
  address.roadAddress,
  address.detail,
].whereType<String>().where((s) => s.isNotEmpty).join(' ');

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
              _field(context, t.dfSummaryAddress, _fullAddress(t, address)),
              _field(context, t.hgAddressAlias, address.label),
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
