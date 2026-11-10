import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_flow.dart';
import 'quote_flow.dart';

/// Service intro + option choice. Color wash in the service's own hue.
class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.service, this.initialUnit});
  final Service service;
  final int? initialUnit;
  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  late final BookingDraftBox _draft = BookingDraftBox(widget.service)..draft.unitIndex = widget.initialUnit ?? (widget.service.type == PricingType.unit ? 0 : null);

  Service get s => widget.service;

  void _continue() {
    final route = s.isQuote
        ? MaterialPageRoute<void>(builder: (_) => QuoteFlowScreen(service: s))
        : MaterialPageRoute<void>(builder: (_) => AddressPickScreen(draft: _draft.draft));
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hue = ServiceHues.of(s.code);
    final d = _draft.draft;
    final notes = t.serviceNotes(s.code);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: context.colors.tintOf(hue),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: context.colors.tintOf(hue),
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 48),
              child: Hero(tag: 'svc-${s.code}', child: ServiceGlyph(s.code, size: 112)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Space.gutter),
          sliver: SliverList.list(children: [
            Text(t.service(s.code), style: context.text.headlineMedium),
            const SizedBox(height: Space.xs),
            Text(t.serviceDesc(s.code), style: context.text.bodyLarge?.copyWith(color: context.colors.inkSoft)),
            const SizedBox(height: Space.xl),
            if (s.type == PricingType.fixed)
              AppCard(
                color: context.colors.tintOf(hue),
                child: Row(children: [
                  Icon(Icons.schedule_rounded, color: hue.tone),
                  const SizedBox(width: Space.xs),
                  Text(t.about(t.duration(s.minutes!)), style: context.text.titleSmall),
                  const Spacer(),
                  Text(context.won(s.price!), style: context.text.titleLarge),
                ]),
              ),
            if (s.type == PricingType.unit) ...[
              SectionTitle(t.unitTitle(s.code)),
              for (var i = 0; i < s.units.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: OptionCard(
                    title: t.unit(s.units[i].labelKey),
                    subtitle: t.about(t.duration(s.units[i].minutes)),
                    trailing: context.won(s.units[i].price),
                    selected: d.unitIndex == i,
                    accent: hue.tone,
                    onTap: () => setState(() => d.unitIndex = i),
                  ),
                ),
            ],
            if (s.isQuote) ...[
              for (final g in [t.quoteG1, t.quoteG2, t.quoteG3])
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded, color: hue.tone, size: 20),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Text(g, style: context.text.bodyMedium)),
                  ]),
                ),
            ],
            if (s.needsPreparation) ...[
              const SizedBox(height: Space.lg),
              SectionTitle(t.prepTitle),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final tool in prepTools) Chip(label: Text(t.tool(tool)), visualDensity: VisualDensity.compact),
              ]),
              const SizedBox(height: Space.xs),
              Text(t.prepBody, style: context.text.bodySmall),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(t.notIncluded, style: context.text.titleSmall),
                  children: [
                    for (final n in notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('·  ', style: context.text.bodyMedium),
                          Expanded(child: Text(n, style: context.text.bodySmall)),
                        ]),
                      ),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(
        summary: s.isQuote
            ? null
            : Row(children: [
                Text(t.about(t.duration(d.minutes)), style: context.text.bodySmall),
                const Spacer(),
                RollingAmount(value: d.listPrice, format: context.won, style: context.text.titleLarge),
              ]),
        child: PrimaryButton(label: s.isQuote ? t.next : t.chooseDate, onPressed: _continue, color: hue.tone),
      ),
    );
  }
}

/// Holds the draft so it survives rebuilds of the service screen.
class BookingDraftBox {
  BookingDraftBox(Service s) : draft = BookingDraft(s);
  final BookingDraft draft;
}
