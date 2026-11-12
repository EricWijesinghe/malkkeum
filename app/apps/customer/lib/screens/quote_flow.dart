import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../src/u1_stub.dart';
import '../state.dart';
import 'booking_flow.dart';
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
  Map<int, (bool, int?)> _slots = {};

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

  bool get _canNext => switch (_step) {
    0 => a.cleaningType != null,
    1 => a.stepBasicDone,
    2 => a.stepSpaceDone,
    _stepAddress => d.address != null,
    _stepDate => d.date != null && d.hour != null,
    _ => true,
  };

  void _go(int step) {
    // The estimate depends on every answer before it: ask again after a change.
    if (step <= _stepDate) _estimate = null;
    if (step >= _stepMethod) _estimate ??= _fetchEstimate();
    setState(() => _step = step);
    _pages.animateToPage(step, duration: Motion.route, curve: Motion.ease);
  }

  Future<Json> _fetchEstimate() async =>
      await context.api.post('/quote/estimate', a.toJson()) as Json;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final app = context.appRead;
    app.analytics.track('booking_start', screen: 'quote');
    try {
      final b = Booking.fromJson(
        await app.api.post(
              '/bookings',
              d.toJson(),
              ApiClient.newIdempotencyKey(),
            )
            as Json,
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
            : null,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          backgroundColor: _step == _stepMethod
              ? context.colors.surfaceHigh
              : null,
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
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: _step == _stepReview ? t.dfSubmitRequest : t.next,
            busy: _busy,
            onPressed: !_canNext
                ? null
                : (_step == _stepReview ? _submit : () => _go(_step + 1)),
          ),
        ),
      ),
    );
  }

  String _chip(T t, int i) =>
      '${t.service(widget.service.code)} · ${i + 1}/$quoteSteps';

  Widget _page(
    T t,
    int i,
    String title,
    List<Widget> children, {
    String? body,
  }) => ListView(
    children: [
      FlowTitle(title, chip: _chip(t, i), body: body),
      ...children,
    ],
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
                icon: 'type_$c',
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
        FlowSection(
          title: t.buildingType,
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
        FlowSection(
          title: t.layoutTitle,
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
        FlowSection(
          title: t.dfDuplexTitle,
          trailing: a.duplex == null
              ? Text(
                  t.dfPleaseSelect,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
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
    FlowSection(
      title: t.dfElevatorTitle,
      trailing: a.elevator == null
          ? Text(
              t.dfPleaseSelect,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.danger,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
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
    return _page(t, 4, t.dfDateTitle, body: t.dfDateNote, [
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
                    : t.dfArrive(slotRangeLabel(h, lang)),
                selected: d.hour == h,
                enabled: _slots[h]?.$1 ?? true,
                onTap: () => setState(() => d.hour = h),
              ),
          ]),
          if (aircon != null) ...[
            const SizedBox(height: Space.xl),
            AcAddonBanner(
              aircon: aircon,
              answers: a,
              onChanged: () => setState(() {}),
            ),
          ],
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

  @override
  Widget build(BuildContext context) => FutureBuilder<Object?>(
    future: _proof,
    builder: (context, snap) {
      final reviews = ((snap.data as Json?)?['reviews'] as List? ?? const [])
          .cast<Json>();
      if (reviews.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowBand(),
          FlowSection(
            title: context.t.dfReviewsTitle,
            children: [
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                  itemBuilder: (context, i) => SizedBox(
                    width: 240,
                    child: AppCard(
                      padding: const EdgeInsets.all(Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'★' * ((reviews[i]['rating'] as num?)?.toInt() ?? 5)} · ${reviews[i]['name'] ?? ''}',
                            style: context.text.labelMedium?.copyWith(
                              color: context.colors.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Space.xs),
                          Expanded(
                            child: Text(
                              reviews[i]['body'] as String? ?? '',
                              style: context.text.bodySmall,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
