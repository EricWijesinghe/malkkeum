import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'booking_flow.dart';
import 'quote_flow.dart';
import 'service_scope.dart';

/// Service detail (design p07 fixed price, p08 unit choice). Quote services go straight
/// into the move-in/out steps (p14). Every number comes from the catalog.
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

  /// Drives the hero art's parallax.
  final _scroll = ScrollController();

  Service get s => widget.service;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The detail is free to browse; booking asks for sign-in first and keeps the draft in place.
  Future<void> _continue() async {
    if (!await requireSignIn(context, reason: SignInReason.book) || !mounted) {
      return;
    }
    // Account data loads after sign-in: wait for the address list before picking the step.
    final app = context.appRead;
    await app.loadAddresses().catchError(reportError);
    if (!mounted) return;
    final d = _draft.draft;
    final addresses = app.addresses;
    final only = addresses.length == 1 ? addresses.first : null;
    final fits =
        only != null &&
        (s.maxPyeong == null || only.sizePyeong <= s.maxPyeong!);
    // One saved address that fits: skip the address step (the schedule screen books it).
    if (fits) d.address = only;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            fits ? ScheduleScreen(draft: d) : AddressPickScreen(draft: d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (s.isQuote) return QuoteFlowScreen(service: s);
    final t = context.t;
    final d = _draft.draft;
    final notes = t.serviceNotes(s.code);
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        actions: [ScopeLink(code: s.code)],
      ),
      body: ListView(
        controller: _scroll,
        children: [
          FlowTitle(
            s.type == PricingType.unit
                ? t.unitTitle(s.code)
                : t.service(s.code),
            body: t.serviceDesc(s.code),
          ),
          if (!Deps.of(context).session.signedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Text(
                t.guestSeePrices,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ),
          if (s.type == PricingType.fixed)
            ..._fixed(context, t)
          else
            ..._units(context, t, d),
          if (notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.lg,
              ),
              child: NoteBox(title: t.dfMustCheck, items: notes),
            ),
        ],
      ),
      bottomNavigationBar: PriceBar(
        amount: d.listPrice,
        // Design p07 captions the fixed price; p08 links to the breakdown instead.
        caption: s.type == PricingType.fixed
            ? '${t.duration(d.minutes)} · ${t.vatIncluded}'
            : null,
        onDetails: s.type == PricingType.fixed
            ? null
            : () => showPriceBreakdown(context, d),
        label: s.type == PricingType.fixed ? t.dfBookNow : t.next,
        onPressed: _continue,
      ),
    );
  }

  List<Widget> _fixed(BuildContext context, T t) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ServiceHero(service: s, scroll: _scroll),
          const SizedBox(height: Space.md),
          AppCard(
            padding: const EdgeInsets.all(Space.md),
            level: Level.flat,
            border: context.colors.line,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _Fact(t.dfDuration, s.minutes!, t.duration)),
                  const VerticalDivider(width: Space.lg),
                  Expanded(child: _Fact(t.dfPriceVat, s.price!, context.won)),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    ),
    const FlowBand(),
    FlowSection(
      children: [
        Text(
          t.dfBasicService,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
        const SizedBox(height: Space.sm),
        if (s.code == 'studio')
          CheckList([for (final k in studioScope) scopeLabel(t, k)]),
        if (s.needsPreparation) ...[
          const SizedBox(height: Space.xs),
          Text(
            t.prepBody,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ],
        if (s.maxPyeong != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            t.dfStudioNote('${s.maxPyeong}'),
            style: context.text.bodySmall?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ],
      ],
    ),
  ];

  List<Widget> _units(BuildContext context, T t, BookingDraft d) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.md,
      ),
      child: tileRows([
        for (var i = 0; i < s.units.length; i++)
          ChoiceTile3D(
            icon: s.code == 'aircon'
                ? 'ac_${s.units[i].labelKey}'
                : 'svc_${s.code}',
            label: t.unit(s.units[i].labelKey),
            subtitle: t.duration(s.units[i].minutes),
            trailing: context.won(s.units[i].price),
            selected: d.unitIndex == i,
            onTap: () => setState(() => d.unitIndex = i),
          ),
      ]),
    ),
  ];
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, this.format);
  final String label;
  final int value;
  final String Function(int) format;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.text.bodySmall?.copyWith(color: context.colors.inkMuted),
      ),
      const SizedBox(height: 4),
      CountIn(
        value: value,
        format: format,
        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

/// The design's photo slot: the catalog photo when the console set one, else the 3D art.
class ServiceHero extends StatelessWidget {
  const ServiceHero({super.key, required this.service, this.scroll});
  final Service service;

  /// The page's scroll position: the 3D art trails it for a little depth.
  final ScrollController? scroll;

  static const _parallax = 0.3;

  Widget _art(BuildContext context) {
    final art = Hero(
      tag: 'svc-${service.code}',
      child: Tilt3D(
        child: Icon3D('svc_${service.code}', size: 120, idle: Icon3DIdle.float),
      ),
    );
    final scroll = this.scroll;
    if (scroll == null || reducedMotion(context)) return art;
    return AnimatedBuilder(
      animation: scroll,
      child: art,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, (scroll.hasClients ? scroll.offset : 0) * _parallax),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = service.content['image_url'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ColoredBox(
          color: context.colors.surfaceHigh,
          child: url is String && url.startsWith('https://')
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  // Hero box is at most ~full width; 1080 covers a 3x phone without decoding the original.
                  cacheWidth: 1080,
                  semanticLabel: context.t.service(service.code),
                  errorBuilder: (_, _, _) => Center(child: _art(context)),
                )
              : Center(child: _art(context)),
        ),
      ),
    );
  }
}

/// "ⓘ 서비스 범위" in the app bar (design p07, p08, p14).
class ScopeLink extends StatelessWidget {
  const ScopeLink({super.key, required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Long translations at large text must not push the app bar past the screen.
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width * 0.5,
    ),
    child: TextButton.icon(
      // Design p07: a filled dark-teal disc, not the button's default tone.
      icon: Icon(Icons.info_rounded, color: context.primary),
      label: Text(context.t.moreScope, overflow: TextOverflow.ellipsis),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ServiceScopeScreen(initialGroup: scopeGroupFor(code)),
        ),
      ),
    ),
  );
}

/// Holds the draft so it survives rebuilds of the service screen.
class BookingDraftBox {
  BookingDraftBox(Service s) : draft = BookingDraft(s);
  final BookingDraft draft;
}
