import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'flow_widgets.dart';

/// What a studio clean covers (design p07 기본 서비스).
const studioScope = ['dusting', 'vacuum', 'dishes', 'bathroom', 'trash'];

enum ScopeGroup { studio, move, bathKitchen, wholeHome, window, disinfection }

enum ScopeArea { room, kitchen, bath, entrance }

/// shortcut: scope lists are client constants (owner design p22); move them to the catalog's
/// content JSON when the owner wants to edit them in the console.
const _scope = <ScopeGroup, Map<ScopeArea, List<String>>>{
  ScopeGroup.studio: {
    ScopeArea.room: ['dusting', 'vacuum', 'bedding', 'tidy'],
    ScopeArea.kitchen: ['dishes', 'stove', 'fridge'],
    ScopeArea.bath: ['bathroom', 'tiles'],
    ScopeArea.entrance: ['entrance', 'trash'],
  },
  ScopeGroup.move: {
    ScopeArea.room: ['dusting', 'vacuum', 'windows', 'cabinets'],
    ScopeArea.kitchen: ['dishes', 'stove', 'hood', 'cabinets'],
    ScopeArea.bath: ['bathroom', 'tiles', 'mold'],
    ScopeArea.entrance: ['entrance', 'shoes', 'trash'],
  },
  ScopeGroup.bathKitchen: {
    ScopeArea.kitchen: ['dishes', 'stove', 'hood'],
    ScopeArea.bath: ['bathroom', 'tiles', 'mold'],
  },
  ScopeGroup.wholeHome: {
    ScopeArea.room: ['dusting', 'vacuum', 'windows', 'cabinets'],
    ScopeArea.kitchen: ['dishes', 'stove', 'hood', 'fridge'],
    ScopeArea.bath: ['bathroom', 'tiles', 'mold'],
    ScopeArea.entrance: ['entrance', 'shoes', 'trash'],
  },
  ScopeGroup.window: {
    ScopeArea.room: ['windows', 'dusting'],
  },
  ScopeGroup.disinfection: {
    ScopeArea.room: ['pest', 'mite'],
    ScopeArea.kitchen: ['sanitize'],
    ScopeArea.bath: ['sanitize'],
    ScopeArea.entrance: ['pest', 'sick_house'],
  },
};

ScopeGroup scopeGroupFor(String code) => switch (code) {
  'move_in' || 'move_out' => ScopeGroup.move,
  'bathroom' || 'kitchen' => ScopeGroup.bathKitchen,
  'whole_home' => ScopeGroup.wholeHome,
  'window' => ScopeGroup.window,
  'disinfection' => ScopeGroup.disinfection,
  _ => ScopeGroup.studio,
};

String scopeLabel(T t, String k) => switch (k) {
  'dusting' => t.dfScopeDusting,
  'vacuum' => t.dfScopeVacuum,
  'dishes' => t.dfScopeDishes,
  'bathroom' => t.dfScopeBathroom,
  'trash' => t.dfScopeTrash,
  'bedding' => t.dfScopeBedding,
  'tidy' => t.dfScopeTidy,
  'stove' => t.dfScopeStove,
  'fridge' => t.dfScopeFridge,
  'tiles' => t.dfScopeTiles,
  'mold' => t.dfScopeMold,
  'hood' => t.dfScopeHood,
  'cabinets' => t.dfScopeCabinets,
  'windows' => t.dfScopeWindows,
  'shoes' => t.dfScopeShoes,
  'pest' => t.dfScopePest,
  'mite' => t.dfScopeMite,
  'sanitize' => t.dfScopeSanitize,
  'sick_house' => t.dfScopeSickHouse,
  _ => t.dfScopeEntrance,
};

String _groupLabel(T t, ScopeGroup g) => switch (g) {
  ScopeGroup.studio => t.service('studio'),
  ScopeGroup.move => t.dfScopeMove,
  ScopeGroup.bathKitchen => t.dfScopeBathKitchen,
  ScopeGroup.wholeHome => t.dfScopeWholeHomeGroup,
  ScopeGroup.window => t.dfScopeWindowGroup,
  ScopeGroup.disinfection => t.dfScopeDisinfGroup,
};

String _areaLabel(T t, ScopeArea a) => switch (a) {
  ScopeArea.room => t.dfRoom,
  ScopeArea.kitchen => t.dfKitchen,
  ScopeArea.bath => t.dfBath,
  ScopeArea.entrance => t.dfEntranceTrash,
};

/// Service scope (design p22): service chips, a floor plan with the chosen area highlighted,
/// area tabs, the included checklist and the collapsible "제공하지 않는 서비스".
class ServiceScopeScreen extends StatefulWidget {
  const ServiceScopeScreen({super.key, this.initialGroup = ScopeGroup.studio});
  final ScopeGroup initialGroup;
  @override
  State<ServiceScopeScreen> createState() => _ServiceScopeScreenState();
}

class _ServiceScopeScreenState extends State<ServiceScopeScreen> {
  late ScopeGroup _group = widget.initialGroup;
  late ScopeArea _area = _scope[_group]!.keys.first;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final areas = _scope[_group]!;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          FlowTitle(t.moreScope),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Row(
              children: [
                for (final g in ScopeGroup.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: ChoiceChip(
                      label: Text(_groupLabel(t, g)),
                      selected: g == _group,
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        _group = g;
                        _area = _scope[g]!.keys.first;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: FloorPlan(
              highlight: _area,
              available: areas.keys.toSet(),
              onTap: (a) => setState(() => _area = a),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Row(
              children: [
                for (final a in areas.keys)
                  _AreaTab(
                    label: _areaLabel(t, a),
                    selected: a == _area,
                    onTap: () => setState(() => _area = a),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          FlowSection(
            children: [
              Text(
                t.dfBasicService,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
              const SizedBox(height: Space.sm),
              // A new area fades its list in (the checks stagger again); the height follows.
              AnimatedSize(
                duration: motionFor(context, Motion.standard),
                curve: Motion.ease,
                alignment: Alignment.topCenter,
                child: FadeThroughSwitcher(
                  child: CheckList(key: ValueKey((_group, _area)), [
                    for (final k in areas[_area]!) scopeLabel(t, k),
                  ]),
                ),
              ),
              const SizedBox(height: Space.sm),
              // Material, not a decorated box: the ExpansionTile paints its ink on it.
              Material(
                color: context.colors.surfaceHigh,
                borderRadius: BorderRadius.circular(Radii.tile),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      t.dfNotProvided,
                      style: context.text.titleSmall,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      Space.md,
                      0,
                      Space.md,
                      Space.md,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final n in [t.dfNp1, t.dfNp2, t.dfNp3, t.dfNp4])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('·  $n', style: context.text.bodySmall),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AreaTab extends StatelessWidget {
  const _AreaTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: motionFor(context, Motion.standard),
        curve: Motion.ease,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? context.colors.ink : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: context.text.titleMedium?.copyWith(
            color: selected ? context.colors.ink : context.colors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

/// Blueprint of a small home: room, kitchen, bathroom, entrance. The highlighted area is
/// hatched in teal; tapping an area selects it.
class FloorPlan extends StatelessWidget {
  const FloorPlan({
    super.key,
    required this.highlight,
    required this.available,
    required this.onTap,
  });
  final ScopeArea highlight;
  final Set<ScopeArea> available;
  final ValueChanged<ScopeArea> onTap;

  /// Fractional layout of the plan (left, top, width, height).
  static const rects = <ScopeArea, Rect>{
    ScopeArea.room: Rect.fromLTWH(0, 0, 0.62, 0.68),
    ScopeArea.kitchen: Rect.fromLTWH(0.62, 0, 0.38, 0.45),
    ScopeArea.bath: Rect.fromLTWH(0.62, 0.45, 0.38, 0.55),
    ScopeArea.entrance: Rect.fromLTWH(0, 0.68, 0.62, 0.32),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    String label(ScopeArea a) => switch (a) {
      ScopeArea.room => t.dfRoom,
      ScopeArea.kitchen => t.dfKitchen,
      ScopeArea.bath => t.dfBath,
      ScopeArea.entrance => t.dfEntrance,
    };
    return AspectRatio(
      aspectRatio: 1.25,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(
              // The hatched room slides and resizes to the next area instead of jumping.
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: rects[highlight]),
                duration: motionFor(context, Motion.route),
                curve: Motion.emphasized,
                builder: (_, rect, _) => CustomPaint(
                  painter: _PlanPainter(
                    highlight: rect!,
                    wall: c.inkMuted,
                    accent: c.fresh,
                    fill: c.surface,
                  ),
                ),
              ),
            ),
            for (final MapEntry(key: a, value: r) in rects.entries)
              Positioned(
                left: r.left * box.maxWidth,
                top: r.top * box.maxHeight,
                width: r.width * box.maxWidth,
                height: r.height * box.maxHeight,
                child: Semantics(
                  button: available.contains(a),
                  selected: a == highlight,
                  label: label(a),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: available.contains(a) ? () => onTap(a) : null,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: AnimatedContainer(
                        duration: motionFor(context, Motion.standard),
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: a == highlight
                            ? context.primary
                            : context.primary.withValues(alpha: 0),
                        child: ExcludeSemantics(
                          child: Text(
                            label(a),
                            style: context.text.labelSmall?.copyWith(
                              color: a == highlight ? Colors.white : c.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter({
    required this.highlight,
    required this.wall,
    required this.accent,
    required this.fill,
  });

  /// Fractional rect of the hatched area (see [FloorPlan.rects]); tweened between areas.
  final Rect highlight;
  final Color wall;
  final Color accent;
  final Color fill;

  static const _hatch = 12.0;

  Rect _abs(Rect r, Size s) => Rect.fromLTWH(
    r.left * s.width,
    r.top * s.height,
    r.width * s.width,
    r.height * s.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    canvas.drawRect(outer, Paint()..color = fill);
    // Hatched highlight first, so the walls draw over its edges.
    final h = _abs(highlight, size).deflate(3);
    canvas.save();
    canvas.clipRect(h);
    canvas.drawRect(h, Paint()..color = accent.withValues(alpha: 0.08));
    final stripe = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var x = h.left - h.height; x < h.right; x += _hatch) {
      canvas.drawLine(Offset(x, h.bottom), Offset(x + h.height, h.top), stripe);
    }
    canvas.restore();
    canvas.drawRect(
      h,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final walls = Paint()
      ..color = wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(outer.deflate(1.5), walls);
    final thin = Paint()
      ..color = wall.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final r in FloorPlan.rects.values) {
      canvas.drawRect(_abs(r, size), thin);
    }
    // Furniture outlines: bed and desk in the room, counter in the kitchen, toilet in the bath.
    final room = _abs(FloorPlan.rects[ScopeArea.room]!, size);
    final kitchen = _abs(FloorPlan.rects[ScopeArea.kitchen]!, size);
    final bath = _abs(FloorPlan.rects[ScopeArea.bath]!, size);
    RRect r(double l, double t, double w, double hh, Rect base) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            base.left + l * base.width,
            base.top + t * base.height,
            w * base.width,
            hh * base.height,
          ),
          const Radius.circular(4),
        );
    canvas.drawRRect(r(0.18, 0.25, 0.28, 0.5, room), thin);
    canvas.drawRRect(r(0.62, 0.15, 0.26, 0.15, room), thin);
    canvas.drawRRect(r(0.7, 0.18, 0.2, 0.7, kitchen), thin);
    canvas.drawRRect(r(0.3, 0.3, 0.3, 0.3, bath), thin);
  }

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.highlight != highlight ||
      old.wall != wall ||
      old.accent != accent ||
      old.fill != fill;
}
