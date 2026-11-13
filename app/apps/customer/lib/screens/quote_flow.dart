import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'booking_flow.dart';
import 'quote_price_hint.dart';
import 'quote_review.dart';
import 'request_status.dart';
import 'service.dart' show ScopeLink;

export 'quote_review.dart';

/// Pages of the move-in / move-out flow (owner design p14-p19).
const quoteSteps = 7;
const _stepAddress = 3;
const _stepDate = 4;
const _stepMethod = 5;
const _stepReview = 6;
const _quoteSlots = [8, 13];

const _luggage = [
  'empty',
  'not_unpacked',
  'partly_unpacked',
  'fully_lived_in',
  'unknown',
];
const _buildings = ['apartment', 'officetel', 'villa', 'commercial'];
const _layouts = [
  'studio',
  'one_and_half',
  'two_rooms',
  'three_rooms',
  'four_plus',
];
const _maxCount = 5;
const _reviewCardHeight = 132.0;
const _reviewPhotoHeight = 96.0;

/// Required questions that "다음" points at while they are unanswered (design p15, p16).
enum _Ask { building, layout, duplex, elevator }

String buildingLabel(T t, String? c) => switch (c) {
  'apartment' => t.building_apartment,
  'officetel' => t.building_officetel,
  'villa' => t.dfBldVillaHouse,
  'commercial' => t.building_commercial,
  'house' => t.building_house,
  _ => t.building_other,
};

String layoutLabel(T t, String? c) => switch (c) {
  'studio' => t.layout_studio,
  'one_and_half' => t.dfLayoutOneHalf,
  'two_rooms' => t.dfLayoutTwo,
  'three_rooms' => t.dfLayoutThree,
  _ => t.dfLayoutFour,
};

String luggageLabel(T t, String c) => switch (c) {
  'empty' => t.luggage_empty,
  'not_unpacked' => t.luggage_not_unpacked,
  'partly_unpacked' => t.luggage_partly_unpacked,
  'fully_lived_in' => t.luggage_fully_lived_in,
  _ => t.luggage_unknown,
};

String cleaningTypeLabel(T t, String? c) => switch (c) {
  'standard' => t.type_standard,
  'same_day_move' => t.type_same_day_move,
  'some_luggage_left' => t.type_some_luggage_left,
  'normal_move_in' => t.type_normal_move_in,
  'after_interior' => t.type_after_interior,
  _ => t.type_lived_in_deep_clean,
};

/// 3D art for a cleaning type: the art set names three of them shorter than the API codes.
String cleaningTypeIcon(String c) => switch (c) {
  'same_day_move' => 'type_same_day',
  'some_luggage_left' => 'type_some_luggage',
  'lived_in_deep_clean' => 'type_lived_in',
  _ => 'type_$c',
};

/// "오전 방문" / "오후 방문".
String visitHalf(T t, int hour) => hour < 12 ? t.dfAmVisit : t.dfPmVisit;

/// Move-in / move-out in 7 steps: cleaning, basics, space, address, date (+AC add-on),
/// Safe booking, review. "변경" on the review jumps back to a step.
class QuoteFlowScreen extends StatefulWidget {
  const QuoteFlowScreen({super.key, required this.service});
  final Service service;
  @override
  State<QuoteFlowScreen> createState() => _QuoteFlowScreenState();
}

class _QuoteFlowScreenState extends State<QuoteFlowScreen> {
  late final BookingDraft d = BookingDraft(widget.service);
  final _pages = PageController();
  int _step = 0;
  bool _busy = false;
  Future<Json>? _estimate;

  /// Price shown from the address step on, before any visit time is chosen.
  Future<Json>? _preview;
  Map<int, (bool, int?)> _slots = {};
  final _askKeys = {for (final q in _Ask.values) q: GlobalKey()};
  final _nudges = <_Ask, int>{};

  /// Set by a blocked "다음": every unanswered question then shows "선택해 주세요".
  bool _asked = false;

  QuoteAnswers get a => d.answers;
  bool get _moveIn => widget.service.code == 'move_in';

  @override
  void initState() {
    super.initState();
    d.date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.appRead.analytics.track('quote_view', screen: 'quote');
      d.address ??= context.appRead.addresses.firstOrNull;
      _loadSlots();
    });
  }

  Future<void> _loadSlots() async {
    try {
      final s = await loadSlots(context.api, d.date!, quote: true);
      if (!mounted) return;
      setState(() {
        _slots = s;
        if (d.hour != null && !(_slots[d.hour]?.$1 ?? true)) d.hour = null;
        d.hour ??= _quoteSlots.where((h) => _slots[h]?.$1 ?? true).firstOrNull;
      });
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  // Steps 2/7 and 3/7 keep "다음" tappable: it points at what is still missing instead.
  bool get _canNext => switch (_step) {
    0 => a.cleaningType != null,
    _stepAddress => d.address != null,
    _stepDate => d.date != null && d.hour != null,
    _ => true,
  };

  _Ask? get _missing => switch (_step) {
    1 =>
      a.building == null
          ? _Ask.building
          : a.layout == null
          ? _Ask.layout
          : a.duplex == null
          ? _Ask.duplex
          : null,
    2 => a.elevator == null ? _Ask.elevator : null,
    _ => null,
  };

  void _go(int step) {
    // The estimate depends on every answer before it: ask again after a change.
    if (step <= _stepDate) _estimate = null;
    if (step < _stepAddress) _preview = null;
    if (step >= _stepAddress) _preview ??= _fetchEstimate(withSlot: false);
    if (step >= _stepMethod) _estimate ??= _fetchEstimate();
    setState(() {
      _step = step;
      _asked = false;
    });
    if (reducedMotion(context)) {
      _pages.jumpToPage(step);
    } else {
      _pages.animateToPage(step, duration: Motion.route, curve: Motion.ease);
    }
  }

  /// "다음": advance, or nudge the first unanswered question into view and say so.
  void _next() {
    final missing = _missing;
    if (missing == null) return _go(_step + 1);
    setState(() {
      _asked = true;
      _nudges[missing] = (_nudges[missing] ?? 0) + 1;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.t.dfPleaseSelect,
      Directionality.of(context),
    );
    final section = _askKeys[missing]!.currentContext;
    if (section == null) return;
    Scrollable.ensureVisible(
      section,
      alignment: 0.1,
      duration: motionFor(context, Motion.route),
      curve: Motion.ease,
    );
  }

  /// With the chosen slot, so the estimate carries the same peak surcharge the booking stores.
  /// Without it (the early preview) the server adds no peak surcharge.
  Future<Json> _fetchEstimate({bool withSlot = true}) async =>
      await context.api.post('/quote/estimate', {
        ...a.toJson(),
        if (withSlot && d.date case final day?) 'visit_date': isoDate(day),
        if (withSlot) 'start_hour': ?d.hour,
      }) as Json;

  /// Guests answer the questions first; signing in is asked only when they book.
  Future<void> _bookAsGuest() async {
    if (!await requireSignIn(context, reason: SignInReason.quote) || !mounted) {
      return;
    }
    // Signed in: the address list replaces the button.
    setState(() {});
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!await requireSignIn(context, reason: SignInReason.book) || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final app = context.appRead;
    app.analytics.track('booking_start', screen: 'quote');
    try {
      final b = Booking.fromJson(
        await app.api.postAction('/bookings', d.toJson()) as Json,
      );
      app.analytics.track('booking_done', screen: 'quote');
      app.bookingsChanged();
      app.loadUnread().ignore();
      final estimate = await _estimate;
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => RequestStatusScreen(
            booking: b,
            estimate: estimate,
            showDoneSheet: true,
          ),
        ),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() => _step == 0 ? Navigator.of(context).pop() : _go(_step - 1);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _back(),
      child: Scaffold(
        backgroundColor: _step == _stepMethod
            ? context.colors.surfaceHigh
            : context.colors.surface,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          backgroundColor: _step == _stepMethod
              ? context.colors.surfaceHigh
              : context.colors.surface,
          actions: [if (_step == 0) ScopeLink(code: widget.service.code)],
        ),
        body: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _typeStep(t),
            _basicStep(t),
            _spaceStep(t),
            _page(t, 3, t.dfAddressTitle, [
              QuotePriceHint(estimate: _preview),
              // A guest never types an address before signing in (PIPA).
              if (_guest)
                _guestBookButton(t)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: AddressRadioList(
                    draft: d,
                    onChanged: () => setState(() {}),
                  ),
                ),
            ]),
            _dateStep(t),
            QuoteMethodPage(chip: _chip(t, 5), estimate: _estimate),
            QuoteReviewPage(
              chip: _chip(t, 6),
              draft: d,
              estimate: _estimate,
              onEdit: _go,
            ),
          ],
        ),
        // A guest's address step has its own button in the page, not a disabled "다음".
        bottomNavigationBar: _guest && _step == _stepAddress
            ? null
            : BottomActionBar(
                child: PrimaryButton(
                  label: _step == _stepReview ? t.dfSubmitRequest : t.next,
                  busy: _busy,
                  onPressed: !_canNext
                      ? null
                      : (_step == _stepReview ? _submit : _next),
                ),
              ),
      ),
    );
  }

  bool get _guest => !Deps.of(context).session.signedIn;

  Widget _guestBookButton(T t) => Padding(
    padding: const EdgeInsets.all(Space.gutter),
    child: PrimaryButton(label: t.guestBookWithQuote, onPressed: _bookAsGuest),
  );

  String _chip(T t, int i) =>
      '${t.service(widget.service.code)} · ${i + 1}/$quoteSteps';

  Widget _page(
    T t,
    int i,
    String title,
    List<Widget> children, {
    String? body,
    Widget? footer,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowTitle(title, chip: _chip(t, i), body: body),
        ...children,
      ],
    );
    // Not a lazy list: a blocked "다음" must find a question that is scrolled far away.
    if (footer == null) return SingleChildScrollView(child: content);
    // The footer rests at the foot of the screen; on a page taller than the screen
    // (large text) it scrolls with the rest.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [content, footer],
          ),
        ),
      ),
    );
  }

  /// A required question: nudged by a blocked "다음", marked "선택해 주세요" while unanswered
  /// ([marked]: from the start, as the design does for 복층 and 엘리베이터).
  Widget _ask(
    T t,
    _Ask q, {
    required String title,
    required bool answered,
    required List<Widget> children,
    bool marked = false,
  }) => OneShot(
    key: _askKeys[q],
    trigger: _nudges[q] ?? 0,
    builder: nudge,
    child: FlowSection(
      title: title,
      trailing: AnimatedSwitcher(
        duration: motionFor(context, Motion.standard),
        child: !answered && (marked || _asked)
            ? Text(
                t.dfPleaseSelect,
                textAlign: TextAlign.end,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.danger,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const SizedBox.shrink(),
      ),
      children: children,
    ),
  );

  Widget _typeStep(T t) {
    final types = _moveIn
        ? ['normal_move_in', 'after_interior', 'lived_in_deep_clean']
        : ['standard', 'same_day_move', 'some_luggage_left'];
    return _page(
      t,
      0,
      t.quoteTypeTitle,
      body: t.serviceDesc(widget.service.code),
      [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.lg,
          ),
          child: circleRow(width: 96, [
            for (final c in types)
              CircleChoice(
                icon: cleaningTypeIcon(c),
                label: cleaningTypeLabel(t, c),
                size: 84,
                selected: a.cleaningType == c,
                onTap: () => setState(() => a.cleaningType = c),
              ),
          ]),
        ),
        const FlowBand(),
        FlowSection(
          title: t.luggageTitle,
          children: [
            for (final l in _luggage)
              RadioRow(
                title: luggageLabel(t, l),
                selected: a.luggage == l,
                onTap: () => setState(() => a.luggage = l),
              ),
          ],
        ),
        const ReviewCarousel(),
      ],
    );
  }

  Widget _basicStep(T t) =>
      _page(t, 1, t.quoteBasicTitle, body: t.dfBasicBody, [
        _ask(
          t,
          _Ask.building,
          title: t.buildingType,
          answered: a.building != null,
          children: [
            circleRow([
              for (final b in _buildings)
                CircleChoice(
                  icon: 'bld_$b',
                  label: buildingLabel(t, b),
                  selected: a.building == b,
                  onTap: () => setState(() => a.building = b),
                ),
            ]),
          ],
        ),
        const FlowBand(),
        _ask(
          t,
          _Ask.layout,
          title: t.layoutTitle,
          answered: a.layout != null,
          children: [
            for (final l in _layouts)
              RadioRow(
                title: layoutLabel(t, l),
                selected: a.layout == l,
                onTap: () => setState(() => a.layout = l),
              ),
          ],
        ),
        const FlowBand(),
        _ask(
          t,
          _Ask.duplex,
          title: t.dfDuplexTitle,
          answered: a.duplex != null,
          marked: true,
          children: [
            circleRow([
              CircleChoice(
                icon: 'room_studio',
                label: t.dfNone,
                selected: a.duplex == false,
                onTap: () => setState(() => a.duplex = false),
              ),
              CircleChoice(
                icon: 'duplex_stairs',
                label: t.dfHas,
                selected: a.duplex == true,
                onTap: () => setState(() => a.duplex = true),
              ),
            ]),
          ],
        ),
      ]);

  Widget _counter(T t, String title, int value, ValueChanged<int> set) =>
      FlowSection(
        title: title,
        children: [
          circleRow(width: 44, [
            for (var n = 0; n <= _maxCount; n++)
              CircleChoice(
                text: '$n',
                label: t.dfCountN('$n'),
                size: 44,
                selected: value == n,
                onTap: () => setState(() => set(n)),
              ),
          ]),
        ],
      );

  Widget _spaceStep(T t) => _page(t, 2, t.quoteSpaceTitle, [
    _counter(t, t.dfBathCount, a.bathrooms, (v) => a.bathrooms = v),
    const FlowBand(),
    _counter(t, t.dfBalconyCount, a.balconies, (v) => a.balconies = v),
    const FlowBand(),
    _ask(
      t,
      _Ask.elevator,
      title: t.dfElevatorTitle,
      answered: a.elevator != null,
      marked: true,
      children: [
        circleRow([
          CircleChoice(
            icon: 'elev_yes',
            label: t.dfHas,
            selected: a.elevator == true,
            onTap: () => setState(() => a.elevator = true),
          ),
          CircleChoice(
            icon: 'elev_no',
            label: t.dfNone,
            selected: a.elevator == false,
            onTap: () => setState(() => a.elevator = false),
          ),
        ]),
        const Divider(height: Space.xl),
        // Needed by the formula when there is no elevator.
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.dfFloor3),
          value: a.floor3OrHigher,
          checkboxShape: const CircleBorder(),
          onChanged: (v) => setState(() => a.floor3OrHigher = v ?? false),
        ),
      ],
    ),
  ]);

  Widget _dateStep(T t) {
    final lang = context.lang;
    final aircon = context.app.service('aircon');
    // Design p17: the aircon offer rests at the foot of the step, just above "다음".
    final offer = aircon == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.lg,
              Space.gutter,
              Space.sm,
            ),
            child: EnterMotion(
              child: AcAddonBanner(
                aircon: aircon,
                answers: a,
                onChanged: () => setState(() {}),
              ),
            ),
          );
    return _page(t, 4, t.dfDateTitle, body: t.dfDateNote, footer: offer, [
      QuotePriceHint(estimate: _preview),
      FlowSection(
        children: [
          VisitDateRow(
            date: d.date!,
            onChanged: (v) {
              setState(() => d.date = v);
              _loadSlots();
            },
          ),
          const SizedBox(height: Space.lg),
          Text(
            t.dfVisitTime,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
          const SizedBox(height: Space.xs),
          tileRows([
            for (final h in _quoteSlots)
              OptionCard(
                title: visitHalf(t, h),
                subtitle: !(_slots[h]?.$1 ?? true)
                    ? t.scheduleFull
                    // The card's title already says 오전/오후 (design p17: "8시~9시 도착").
                    : t.dfArrive(slotRangeLabel(h, lang, withPeriod: false)),
                selected: d.hour == h,
                enabled: _slots[h]?.$1 ?? true,
                onTap: () => setState(() => d.hour = h),
              ),
          ]),
        ],
      ),
    ]);
  }
}

/// "생생한 이용 후기" (design p14): recent public reviews; hidden when there are none.
class ReviewCarousel extends StatefulWidget {
  const ReviewCarousel({super.key});
  @override
  State<ReviewCarousel> createState() => _ReviewCarouselState();
}

class _ReviewCarouselState extends State<ReviewCarousel> {
  // Fetched once; a failure only hides the section (social proof is optional).
  late final Future<Object?> _proof = context.api
      .get('/public/proof')
      .then<Object?>((v) => v, onError: (_) => null);

  /// Both photos, or none: half a comparison says nothing.
  static (String, String)? _photos(Json r) {
    final before = r['before_url'];
    final after = r['after_url'];
    return before is String &&
            after is String &&
            before.startsWith('https://') &&
            after.startsWith('https://')
        ? (before, after)
        : null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object?>(
    future: _proof,
    builder: (context, snap) {
      final reviews = ((snap.data as Json?)?['reviews'] as List? ?? const [])
          .cast<Json>();
      if (reviews.isEmpty) return const SizedBox.shrink();
      final t = context.t;
      final withPhotos = reviews.any((r) => _photos(r) != null);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowBand(),
          FlowSection(
            title: t.dfReviewsTitle,
            children: [
              SizedBox(
                height:
                    _reviewCardHeight + (withPhotos ? _reviewPhotoHeight : 0),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                  itemBuilder: (context, i) {
                    final r = reviews[i];
                    final photos = _photos(r);
                    return StaggerIn(
                      index: i,
                      child: SizedBox(
                        width: 240,
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          level: Level.flat,
                          border: context.colors.line,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (photos != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(Radii.card),
                                  ),
                                  child: SizedBox(
                                    height: _reviewPhotoHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _Shot(photos.$1, t.dfBefore),
                                        ),
                                        Expanded(
                                          child: _Shot(
                                            photos.$2,
                                            t.dfAfter,
                                            after: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(Space.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${'★' * ((r['rating'] as num?)?.toInt() ?? 5)} · ${r['name'] ?? ''}',
                                        style: context.text.labelMedium
                                            ?.copyWith(
                                              color: context.colors.inkMuted,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: Space.xs),
                                      Expanded(
                                        child: Text(
                                          r['body'] as String? ?? '',
                                          style: context.text.bodySmall,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// One half of a review's BEFORE | AFTER split (design p14). A photo that fails to load
/// leaves the labelled tint, as in the design's placeholder.
class _Shot extends StatelessWidget {
  const _Shot(this.url, this.label, {this.after = false});
  final String url;
  final String label;
  final bool after;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: after ? c.primaryTint : c.surfaceHigh),
        Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: label,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: after ? context.primary : c.inkSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
