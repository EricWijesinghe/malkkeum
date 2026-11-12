import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../src/u1_stub.dart';
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
  late final BookingDraftBox _draft = BookingDraftBox(widget.service)
    ..draft.unitIndex =
        widget.initialUnit ??
        (widget.service.type == PricingType.unit ? 0 : null);

  Service get s => widget.service;

  /// The estimate is free to browse; booking asks for sign-in first and keeps the draft in place.
  Future<void> _continue() async {
    if (s.isQuote) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => QuoteFlowScreen(service: s)),
      );
      return;
    }
    if (!await requireSignIn(context) || !mounted) return;
    final d = _draft.draft;
    final addresses = context.appRead.addresses;
    final only = addresses.length == 1 ? addresses.first : null;
    final fits =
        only != null &&
        (s.maxPyeong == null || only.sizePyeong <= s.maxPyeong!);
    // One saved address that fits: skip the address step (the schedule screen shows it with "change").
    if (fits) {
      d
        ..address = only
        ..totalSteps = 3;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScheduleScreen(draft: d, step: 2, total: 3),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddressPickScreen(draft: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hue = ServiceHues.of(s.code);
    final d = _draft.draft;
    final notes = t.serviceNotes(s.code);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: context.colors.tintOf(hue),
            flexibleSpace: FlexibleSpaceBar(
              background: AuroraBackground(
                colors: [hue.tone, Color.lerp(hue.tone, Colors.white, 0.45)!],
                child: Container(
                  color: context.colors.tintOf(hue).withValues(alpha: 0.72),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 48),
                  // The clay glyph carries its own depth; the tilt adds the 3D read.
                  child: Hero(
                    tag: 'svc-${s.code}',
                    child: Tilt3D(child: ServiceGlyph(s.code, size: 104)),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(Space.gutter),
            sliver: SliverList.list(
              children: [
                Text(t.service(s.code), style: context.text.headlineMedium),
                const SizedBox(height: Space.xs),
                Text(
                  t.serviceDesc(s.code),
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.inkSoft,
                  ),
                ),
                const SizedBox(height: Space.xl),
                if (s.type == PricingType.fixed)
                  AppCard(
                    color: context.colors.tintOf(hue),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: hue.tone),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            t.duration(s.minutes!),
                            style: context.text.titleSmall,
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        // Catalog price and minutes (console-editable), VAT included.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.won(s.price!),
                              style: context.text.titleLarge,
                            ),
                            Text(t.vatIncluded, style: context.text.labelSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (s.code == 'studio') ...[
                  const SizedBox(height: Space.lg),
                  SectionTitle(t.moreScope),
                  const ScopeBlueprint(),
                ],
                if (s.code == 'aircon') ...[
                  SectionTitle(t.unitTitle(s.code)),
                  tileRows([
                    for (var i = 0; i < s.units.length; i++)
                      ChoiceTile3D(
                        icon: 'ac_${s.units[i].labelKey}',
                        label: t.unit(s.units[i].labelKey),
                        subtitle: context.won(s.units[i].price),
                        selected: d.unitIndex == i,
                        accent: hue.tone,
                        onTap: () => setState(() => d.unitIndex = i),
                      ),
                  ]),
                ] else if (s.type == PricingType.unit) ...[
                  SectionTitle(t.unitTitle(s.code)),
                  for (var i = 0; i < s.units.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: EnterMotion(
                        delay: Duration(milliseconds: 60 * i),
                        child: OptionCard(
                          title: t.unit(s.units[i].labelKey),
                          subtitle: t.about(t.duration(s.units[i].minutes)),
                          trailing: context.won(s.units[i].price),
                          selected: d.unitIndex == i,
                          accent: hue.tone,
                          onTap: () => setState(() => d.unitIndex = i),
                        ),
                      ),
                    ),
                ],
                if (s.isQuote) ...[
                  for (final g in [t.quoteG1, t.quoteG2, t.quoteG3])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: hue.tone,
                            size: 20,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(g, style: context.text.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
                if (s.needsPreparation) ...[
                  const SizedBox(height: Space.lg),
                  SectionTitle(t.prepTitle),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tool in prepTools)
                        Chip(
                          label: Text(t.tool(tool)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(t.prepBody, style: context.text.bodySmall),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        t.notIncluded,
                        style: context.text.titleSmall,
                      ),
                      children: [
                        for (final n in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('·  ', style: context.text.bodyMedium),
                                Expanded(
                                  child: Text(n, style: context.text.bodySmall),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        summary: s.isQuote
            ? null
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      t.about(t.duration(d.minutes)),
                      style: context.text.bodySmall,
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  RollingAmount(
                    value: d.listPrice,
                    format: context.won,
                    style: context.text.titleLarge,
                  ),
                ],
              ),
        child: PrimaryButton(
          label: s.isQuote ? t.next : t.chooseDate,
          onPressed: _continue,
          color: hue.tone,
        ),
      ),
    );
  }
}

/// Holds the draft so it survives rebuilds of the service screen.
class BookingDraftBox {
  BookingDraftBox(Service s) : draft = BookingDraft(s);
  final BookingDraft draft;
}

/// What a studio clean covers. shortcut: client constant, move to the catalog's content JSON if the owner wants to edit it.
const serviceScope = ['dusting', 'vacuum', 'dishes', 'bathroom', 'trash'];

/// Floor-plan style card: a drawn room outline with the five scope items on it.
class ScopeBlueprint extends StatelessWidget {
  const ScopeBlueprint({super.key});

  String _label(T t, String k) => switch (k) {
    'dusting' => t.dfScopeDusting,
    'vacuum' => t.dfScopeVacuum,
    'dishes' => t.dfScopeDishes,
    'bathroom' => t.dfScopeBathroom,
    _ => t.dfScopeTrash,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: CustomPaint(
        painter: _BlueprintPainter(line: c.fresh, grid: c.line),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = ((box.maxWidth - 2 * Space.xs) / 3).floorToDouble();
              return Wrap(
                spacing: Space.xs,
                runSpacing: Space.md,
                alignment: WrapAlignment.center,
                children: [
                  for (final k in serviceScope)
                    SizedBox(
                      width: w,
                      child: Column(
                        children: [
                          ExcludeSemantics(child: Icon3D('scope_$k', size: 44)),
                          const SizedBox(height: 4),
                          Text(
                            _label(t, k),
                            style: context.text.labelMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter({required this.line, required this.grid});
  final Color line;
  final Color grid;

  static const _cell = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = line.withValues(alpha: 0.06),
    );
    final g = Paint()
      ..color = grid
      ..strokeWidth = 0.6;
    for (var x = _cell; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (var y = _cell; y < size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    final wall = Paint()
      ..color = line.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final room = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawRect(room, wall);
    // Bathroom corner and the door swing make it read as a floor plan.
    final bath = room.width * 0.3;
    canvas.drawLine(
      Offset(room.right - bath, room.top),
      Offset(room.right - bath, room.top + room.height * 0.4),
      wall,
    );
    canvas.drawLine(
      Offset(room.right - bath, room.top + room.height * 0.4),
      Offset(room.right, room.top + room.height * 0.4),
      wall,
    );
    final door = Rect.fromCircle(
      center: Offset(room.left, room.bottom),
      radius: 28,
    );
    canvas.drawArc(
      door,
      -math.pi / 2,
      math.pi / 2,
      false,
      wall..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BlueprintPainter old) =>
      old.line != line || old.grid != grid;
}
