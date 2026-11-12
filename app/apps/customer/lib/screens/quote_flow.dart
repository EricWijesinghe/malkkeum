import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../src/u1_stub.dart';
import '../state.dart';
import 'booking_flow.dart';
import 'chat.dart';

const _total = 5;

/// Buildings with their own tile; the rest sit under "기타".
const _mainBuildings = ['apartment', 'villa', 'commercial'];
const _otherBuildings = ['officetel', 'house', 'other'];

const _layoutIcons = {
  'studio': 'room_studio',
  'one_and_half': 'room_one_half',
  'two_rooms': 'room_two',
  'three_rooms': 'room_three',
  'four_plus': 'room_four_plus',
};

String _buildingLabel(T t, String? c) => switch (c) {
  'apartment' => t.building_apartment,
  'villa' => t.building_villa,
  'commercial' => t.building_commercial,
  'officetel' => t.building_officetel,
  'house' => t.building_house,
  _ => t.building_other,
};

String _layoutLabel(T t, String? c) => switch (c) {
  'studio' => t.layout_studio,
  'one_and_half' => t.layout_one_and_half,
  'two_rooms' => t.layout_two_rooms,
  'three_rooms' => t.layout_three_rooms,
  _ => t.layout_four_plus,
};

/// Move-in / move-out in 5 steps: condition, building, space, date (+ AC add-on), Safe booking review.
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

  QuoteAnswers get a => d.answers;
  bool get _moveIn => widget.service.code == 'move_in';
  ServiceHue get _hue => ServiceHues.of(widget.service.code);

  @override
  void initState() {
    super.initState();
    // After the first frame: the app is only reachable through the context once mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.appRead.analytics.track('quote_view', screen: 'quote');
      }
    });
  }

  bool get _canNext => switch (_step) {
    0 => a.cleaningType != null,
    1 => a.stepBasicDone,
    _ => a.stepSpaceDone,
  };

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pages.nextPage(duration: Motion.route, curve: Motion.ease);
      return;
    }
    // Step 4 is the date; it shows the address with "change". Only a customer with no
    // saved address goes through the address screen first (still step 4).
    Widget schedule() => ScheduleScreen(
      draft: d,
      step: 4,
      total: _total,
      onDone: (ctx) => Navigator.of(ctx).push(
        MaterialPageRoute<void>(builder: (_) => QuoteConfirmScreen(draft: d)),
      ),
    );
    d.address ??= context.appRead.addresses.firstOrNull;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => d.address != null
            ? schedule()
            : AddressPickScreen(
                draft: d,
                step: 4,
                total: _total,
                onPicked: (ctx) => Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => schedule()),
                ),
              ),
      ),
    );
  }

  void _back() {
    if (_step == 0) return Navigator.of(context).pop();
    setState(() => _step--);
    _pages.previousPage(duration: Motion.route, curve: Motion.ease);
  }

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
        appBar: AppBar(
          title: Text(t.stepOf('${_step + 1}', '$_total')),
          leading: BackButton(onPressed: _back),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: StepProgress(
                current: _step + 1,
                total: _total,
                color: _hue.tone,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [_typeStep(t), _basicStep(t), _spaceStep(t)],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: t.next,
            color: _hue.tone,
            onPressed: _canNext ? _next : null,
          ),
        ),
      ),
    );
  }

  Widget _page(List<Widget> children) =>
      ListView(padding: const EdgeInsets.all(Space.gutter), children: children);

  Widget _tile(String icon, String label, bool selected, VoidCallback onTap) =>
      ChoiceTile3D(
        icon: icon,
        label: label,
        selected: selected,
        accent: _hue.tone,
        onTap: () => setState(onTap),
      );

  /// Yes / no as two 3D tiles (elevator, duplex). Null until answered: both are required.
  Widget _yesNo(
    T t,
    String label,
    bool? value,
    (String, String) icons,
    ValueChanged<bool> set,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionTitle('$label *'),
      tileRows([
        _tile(icons.$1, t.yes, value == true, () => set(true)),
        _tile(icons.$2, t.no, value == false, () => set(false)),
      ]),
    ],
  );

  Widget _typeStep(T t) {
    final types = _moveIn
        ? [
            ('normal_move_in', t.type_normal_move_in),
            ('after_interior', t.type_after_interior),
            ('lived_in_deep_clean', t.type_lived_in_deep_clean),
          ]
        : [
            ('standard', t.type_standard),
            ('same_day_move', t.type_same_day_move),
            ('some_luggage_left', t.type_some_luggage_left),
          ];
    final boxes = [
      ('empty', 'box_empty', t.luggage_empty),
      ('partly_unpacked', 'box_partial', t.luggage_partly_unpacked),
      ('fully_lived_in', 'box_full', t.luggage_fully_lived_in),
    ];
    return _page([
      Text(t.quoteTypeTitle, style: context.text.headlineSmall),
      const SizedBox(height: Space.lg),
      // Cleaning type drives the surcharge, so it stays above the condition boxes.
      for (final (code, label) in types)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: OptionCard(
            leading: ExcludeSemantics(
              child: Icon3D(
                'type_$code',
                active: a.cleaningType == code,
                size: 40,
              ),
            ),
            title: label,
            selected: a.cleaningType == code,
            accent: _hue.tone,
            onTap: () => setState(() => a.cleaningType = code),
          ),
        ),
      const SizedBox(height: Space.xl),
      SectionTitle(t.luggageTitle),
      tileRows(cols: 3, [
        for (final (code, icon, label) in boxes)
          _tile(icon, label, a.luggage == code, () => a.luggage = code),
      ]),
      Align(
        alignment: Alignment.centerLeft,
        child: ChoiceChip(
          label: Text(t.luggage_unknown),
          selected: a.luggage == 'unknown',
          showCheckmark: false,
          onSelected: (_) => setState(() => a.luggage = 'unknown'),
        ),
      ),
    ]);
  }

  Widget _basicStep(T t) {
    final other = _otherBuildings.contains(a.building);
    return _page([
      Text(t.quoteBasicTitle, style: context.text.headlineSmall),
      const SizedBox(height: Space.xl),
      SectionTitle(t.buildingType),
      tileRows([
        for (final b in _mainBuildings)
          _tile(
            'bld_$b',
            _buildingLabel(t, b),
            a.building == b,
            () => a.building = b,
          ),
        _tile('bld_other', t.building_other, other, () {
          if (!other) {
            a.building = 'other';
          }
        }),
      ]),
      if (other)
        ChoiceRow<String>(
          options: [for (final b in _otherBuildings) (b, _buildingLabel(t, b))],
          value: a.building,
          onChanged: (v) => setState(() => a.building = v),
        ),
      const SizedBox(height: Space.xl),
      SectionTitle(t.layoutTitle),
      tileRows(cols: 3, [
        for (final MapEntry(key: code, value: icon) in _layoutIcons.entries)
          _tile(
            icon,
            _layoutLabel(t, code),
            a.layout == code,
            () => a.layout = code,
          ),
      ]),
      const SizedBox(height: Space.xl),
      _yesNo(t, t.duplexTitle, a.duplex, (
        'duplex_stairs',
        'room_studio',
      ), (v) => a.duplex = v),
    ]);
  }

  Widget _counter(
    String icon,
    String label,
    int value,
    ValueChanged<int> set,
  ) => Row(
    children: [
      ExcludeSemantics(child: Icon3D(icon, size: 40)),
      const SizedBox(width: Space.sm),
      Expanded(
        child: CountStepper(
          label: label,
          value: value,
          onChanged: (v) => setState(() => set(v)),
        ),
      ),
    ],
  );

  Widget _spaceStep(T t) => _page([
    Text(t.quoteSpaceTitle, style: context.text.headlineSmall),
    const SizedBox(height: Space.xl),
    AppCard(
      child: Column(
        children: [
          _counter(
            'cnt_bathroom',
            t.bathroomsLabel,
            a.bathrooms,
            (v) => a.bathrooms = v,
          ),
          const Divider(height: Space.xl),
          _counter(
            'cnt_balcony',
            t.balconiesLabel,
            a.balconies,
            (v) => a.balconies = v,
          ),
        ],
      ),
    ),
    const SizedBox(height: Space.xl),
    _yesNo(t, t.elevatorTitle, a.elevator, (
      'elev_yes',
      'elev_no',
    ), (v) => a.elevator = v),
    const SizedBox(height: Space.md),
    // Needed by the formula when there is no elevator.
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t.floor3Label),
      value: a.floor3OrHigher,
      onChanged: (v) => setState(() => a.floor3OrHigher = v),
    ),
  ]);
}

/// "안심 예약": itemised estimate from the server + summary. No payment now: staff confirm the
/// final quote in the booking chat, which opens right after the request is sent.
class QuoteConfirmScreen extends StatefulWidget {
  const QuoteConfirmScreen({super.key, required this.draft});
  final BookingDraft draft;
  @override
  State<QuoteConfirmScreen> createState() => _QuoteConfirmScreenState();
}

class _QuoteConfirmScreenState extends State<QuoteConfirmScreen> {
  BookingDraft get d => widget.draft;
  bool _busy = false;

  Future<Json> _estimate() async =>
      await context.api.post('/quote/estimate', d.answers.toJson()) as Json;

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
      if (!mounted) return;
      final thread = b.threadId;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => thread == null
              ? DoneScreen(booking: b)
              : ChatRoomScreen(
                  threadId: thread,
                  topic: b.serviceCode,
                  bookingId: b.id,
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

  static String _pct(int bps) =>
      bps % 100 == 0 ? '${bps ~/ 100}' : (bps / 100).toStringAsFixed(2);

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: context.text.bodySmall)),
        const SizedBox(width: Space.xs),
        Text(
          value,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _estimateCard(Json e, ServiceHue hue) {
    final t = context.t;
    int n(String k) => (e[k] as num? ?? 0).toInt();
    return AppCard(
      color: context.colors.tintOf(hue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.estimate,
            style: context.text.labelMedium?.copyWith(color: hue.tone),
          ),
          RollingAmount(
            value: n('total'),
            format: context.won,
            style: context.text.displaySmall,
          ),
          Text(t.vatIncluded, style: context.text.labelSmall),
          const SizedBox(height: Space.md),
          _line(t.dfEstBase, context.won(n('base'))),
          if (n('extras') > 0)
            _line(t.dfEstExtras, '+${context.won(n('extras'))}'),
          if (n('surcharge_bps') > 0)
            _line(
              t.dfEstSurcharge(_pct(n('surcharge_bps'))),
              '+${_pct(n('surcharge_bps'))}%',
            ),
          if (n('peak') > 0)
            _line(
              t.dfEstPeak(_pct(n('peak_bps'))),
              '+${context.won(n('peak'))}',
            ),
          if (n('addons') > 0)
            _line(
              t.dfEstAddons(_pct(n('addon_discount_bps'))),
              '+${context.won(n('addons'))}',
            ),
          const SizedBox(height: Space.xs),
          Text(t.quoteEstimateBody, style: context.text.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = d.answers;
    final hue = ServiceHues.of(d.service.code);
    String typeLabel(String? c) => switch (c) {
      'standard' => t.type_standard,
      'same_day_move' => t.type_same_day_move,
      'some_luggage_left' => t.type_some_luggage_left,
      'normal_move_in' => t.type_normal_move_in,
      'after_interior' => t.type_after_interior,
      _ => t.type_lived_in_deep_clean,
    };
    final addons = [
      for (final MapEntry(key: unit, value: count) in a.acAddons.entries)
        if (count > 0) '${t.unit(unit)} ${t.dfCountUnits('$count')}',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.stepOf('$_total', '$_total'))),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          StepProgress(current: _total, total: _total, color: hue.tone),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: hue.tone),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(t.dfSafeBooking, style: context.text.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            t.dfSafeBookingBody,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.inkSoft,
            ),
          ),
          const SizedBox(height: Space.lg),
          AsyncView<Json>(
            load: _estimate,
            skeletons: 1,
            skeletonHeight: 150,
            builder: (context, e, _) => _estimateCard(e, hue),
          ),
          const SizedBox(height: Space.lg),
          SectionTitle(t.quoteConfirmTitle),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: Text(t.summaryType),
                  subtitle: Text(
                    '${t.service(d.service.code)} · ${typeLabel(a.cleaningType)}',
                  ),
                ),
                ListTile(
                  title: Text(t.summaryHome),
                  subtitle: Text(
                    '${_buildingLabel(t, a.building)} · ${_layoutLabel(t, a.layout)}\n'
                    '${t.bathroomsLabel} ${a.bathrooms} · ${t.balconiesLabel} ${a.balconies}\n'
                    '${d.address!.label} · ${t.pyeong('${d.address!.sizePyeong}')}',
                  ),
                ),
                if (addons.isNotEmpty)
                  ListTile(
                    title: Text(t.service('aircon')),
                    subtitle: Text(addons.join(' · ')),
                  ),
                ListTile(
                  title: Text(t.summaryDate),
                  subtitle: Text(
                    '${dateLabel(d.date!, context.lang)} · ${d.hour! < 12 ? t.morning : t.afternoon}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        summary: Text(t.quoteNoPayNow, style: context.text.labelSmall),
        child: PrimaryButton(
          label: t.quoteRequest,
          busy: _busy,
          color: hue.tone,
          onPressed: _submit,
        ),
      ),
    );
  }
}
