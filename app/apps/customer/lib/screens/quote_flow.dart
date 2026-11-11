import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_flow.dart';

const _total = 6;

/// Move-in / move-out: 3 question steps here, then address, date, estimate + confirm.
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
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AddressPickScreen(
        draft: d,
        step: 4,
        total: _total,
        onPicked: (ctx) => Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => ScheduleScreen(
            draft: d,
            step: 5,
            total: _total,
            onDone: (ctx2) => Navigator.of(ctx2).push(MaterialPageRoute<void>(builder: (_) => QuoteConfirmScreen(draft: d))),
          ),
        )),
      ),
    ));
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
        appBar: AppBar(title: Text(t.stepOf('${_step + 1}', '$_total')), leading: BackButton(onPressed: _back)),
        body: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: Space.gutter), child: StepProgress(current: _step + 1, total: _total, color: _hue.tone)),
          Expanded(
            child: PageView(controller: _pages, physics: const NeverScrollableScrollPhysics(), children: [_typeStep(t), _basicStep(t), _spaceStep(t)]),
          ),
        ]),
        bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t.next, color: _hue.tone, onPressed: _canNext ? _next : null)),
      ),
    );
  }

  Widget _page(List<Widget> children) => ListView(padding: const EdgeInsets.all(Space.gutter), children: children);

  Widget _typeStep(T t) {
    final types = _moveIn
        ? [('normal_move_in', t.type_normal_move_in, Icons.home_rounded), ('after_interior', t.type_after_interior, Icons.format_paint_rounded), ('lived_in_deep_clean', t.type_lived_in_deep_clean, Icons.cleaning_services_rounded)]
        : [('standard', t.type_standard, Icons.inventory_2_rounded), ('same_day_move', t.type_same_day_move, Icons.local_shipping_rounded), ('some_luggage_left', t.type_some_luggage_left, Icons.chair_rounded)];
    final luggage = [('empty', t.luggage_empty), ('partly_unpacked', t.luggage_partly_unpacked), ('fully_lived_in', t.luggage_fully_lived_in), ('unknown', t.luggage_unknown)];
    return _page([
      Text(t.quoteTypeTitle, style: context.text.headlineSmall),
      const SizedBox(height: Space.lg),
      for (final (code, label, icon) in types)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: OptionCard(
            leading: Icon(icon, color: _hue.tone),
            title: label,
            selected: a.cleaningType == code,
            accent: _hue.tone,
            onTap: () => setState(() => a.cleaningType = code),
          ),
        ),
      const SizedBox(height: Space.xl),
      SectionTitle(t.luggageTitle),
      ChoiceRow<String>(options: luggage, value: a.luggage, onChanged: (v) => setState(() => a.luggage = v)),
    ]);
  }

  Widget _basicStep(T t) => _page([
        Text(t.quoteBasicTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.xl),
        SectionTitle(t.buildingType),
        ChoiceRow<String>(
          options: [('apartment', t.building_apartment), ('villa', t.building_villa), ('officetel', t.building_officetel), ('house', t.building_house), ('other', t.building_other)],
          value: a.building,
          onChanged: (v) => setState(() => a.building = v),
        ),
        const SizedBox(height: Space.xl),
        SectionTitle(t.layoutTitle),
        ChoiceRow<String>(
          options: [('studio', t.layout_studio), ('one_and_half', t.layout_one_and_half), ('two_rooms', t.layout_two_rooms), ('three_rooms', t.layout_three_rooms), ('four_plus', t.layout_four_plus)],
          value: a.layout,
          onChanged: (v) => setState(() => a.layout = v),
        ),
        const SizedBox(height: Space.xl),
        YesNo(label: '${t.duplexTitle} *', value: a.duplex, yes: t.yes, no: t.no, onChanged: (v) => setState(() => a.duplex = v)),
      ]);

  Widget _spaceStep(T t) => _page([
        Text(t.quoteSpaceTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.xl),
        AppCard(
          child: Column(children: [
            CountStepper(label: t.bathroomsLabel, value: a.bathrooms, onChanged: (v) => setState(() => a.bathrooms = v)),
            const Divider(height: Space.xl),
            CountStepper(label: t.balconiesLabel, value: a.balconies, onChanged: (v) => setState(() => a.balconies = v)),
          ]),
        ),
        const SizedBox(height: Space.xl),
        YesNo(label: '${t.elevatorTitle} *', value: a.elevator, yes: t.yes, no: t.no, onChanged: (v) => setState(() => a.elevator = v)),
        const SizedBox(height: Space.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.floor3Label),
          value: a.floor3OrHigher,
          onChanged: (v) => setState(() => a.floor3OrHigher = v),
        ),
      ]);
}

/// Estimate + summary. No payment now: staff send the final quote in chat.
class QuoteConfirmScreen extends StatefulWidget {
  const QuoteConfirmScreen({super.key, required this.draft});
  final BookingDraft draft;
  @override
  State<QuoteConfirmScreen> createState() => _QuoteConfirmScreenState();
}

class _QuoteConfirmScreenState extends State<QuoteConfirmScreen> {
  BookingDraft get d => widget.draft;
  bool _busy = false;

  Future<int> _estimate() async => ((await context.api.post('/quote/estimate', d.answers.toJson()) as Json)['total'] as num).toInt();

  Future<void> _submit() async {
    setState(() => _busy = true);
    final app = context.appRead;
    try {
      final b = Booking.fromJson(await app.api.post('/bookings', d.toJson(), ApiClient.newIdempotencyKey()) as Json);
      app.bookingsChanged();
      app.loadUnread().ignore();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => DoneScreen(booking: b)), (r) => r.isFirst);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    String layoutLabel(String? c) => switch (c) {
          'studio' => t.layout_studio,
          'one_and_half' => t.layout_one_and_half,
          'two_rooms' => t.layout_two_rooms,
          'three_rooms' => t.layout_three_rooms,
          _ => t.layout_four_plus,
        };
    return Scaffold(
      appBar: AppBar(title: Text(t.stepOf('6', '6'))),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        StepProgress(current: 6, total: 6, color: hue.tone),
        const SizedBox(height: Space.xl),
        Text(t.quoteEstimateTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.lg),
        AsyncView<int>(
          load: _estimate,
          skeletons: 1,
          skeletonHeight: 150,
          builder: (context, total, _) => AppCard(
            color: context.colors.tintOf(hue),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.estimate, style: context.text.labelMedium?.copyWith(color: hue.tone)),
              RollingAmount(value: total, format: context.won, style: context.text.displaySmall),
              const SizedBox(height: Space.xs),
              Text(t.quoteEstimateBody, style: context.text.bodySmall),
              const SizedBox(height: Space.md),
              for (final g in [t.quoteG1, t.quoteG2, t.quoteG3])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [Icon(Icons.check_rounded, size: 18, color: hue.tone), const SizedBox(width: 6), Expanded(child: Text(g, style: context.text.bodySmall))]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: Space.lg),
        SectionTitle(t.quoteConfirmTitle),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(title: Text(t.summaryType), subtitle: Text('${t.service(d.service.code)} · ${typeLabel(a.cleaningType)}')),
            ListTile(
              title: Text(t.summaryHome),
              subtitle: Text('${layoutLabel(a.layout)} · ${t.bathroomsLabel} ${a.bathrooms} · ${t.balconiesLabel} ${a.balconies}\n${d.address!.label} · ${t.pyeong('${d.address!.sizePyeong}')}'),
            ),
            ListTile(title: Text(t.summaryDate), subtitle: Text('${dateLabel(d.date!, context.lang)} · ${d.hour! < 12 ? t.morning : t.afternoon}')),
          ]),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(
        summary: Text(t.quoteNoPayNow, style: context.text.labelSmall),
        child: PrimaryButton(label: t.quoteRequest, busy: _busy, color: hue.tone, onPressed: _submit),
      ),
    );
  }
}
