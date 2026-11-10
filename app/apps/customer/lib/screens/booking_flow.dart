import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'addresses.dart';
import 'booking_detail.dart';
import 'chat.dart';
import 'pay_flow.dart';
import 'pay_method_picker.dart';
import 'virtual_account.dart';

const _maxDaysAhead = 60;
const _standardSlots = [8, 9, 13, 14];
const _quoteSlots = [8, 13];

String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Step 2 (fixed/unit) — pick a saved address, or add one. Enforces the studio size rule.
class AddressPickScreen extends StatefulWidget {
  const AddressPickScreen({super.key, required this.draft, this.onPicked, this.step = 2, this.total = 4});
  final BookingDraft draft;
  final void Function(BuildContext context)? onPicked;
  final int step;
  final int total;
  @override
  State<AddressPickScreen> createState() => _AddressPickScreenState();
}

class _AddressPickScreenState extends State<AddressPickScreen> {
  BookingDraft get d => widget.draft;

  Future<void> _next() async {
    final a = d.address!;
    final max = d.service.maxPyeong;
    if (max != null && a.sizePyeong > max) {
      await _studioBlocked(a);
      return;
    }
    if (!mounted) return;
    if (widget.onPicked != null) return widget.onPicked!(context);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScheduleScreen(draft: d)));
  }

  Future<void> _studioBlocked(Address a) => showAppSheet<void>(
        context,
        title: context.t.studioBlockedTitle('${a.sizePyeong}'),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(ctx.t.studioBlockedBody, style: ctx.text.bodyMedium),
            const SizedBox(height: Space.xl),
            PrimaryButton(
              label: ctx.t.consultCta,
              onPressed: () {
                Navigator.of(ctx).pop();
                openTopicChat(context, d.service.code);
              },
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    d.address ??= app.addresses.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t.stepOf('${widget.step}', '${widget.total}'))),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        StepProgress(current: widget.step, total: widget.total, color: ServiceHues.of(d.service.code).tone),
        const SizedBox(height: Space.xl),
        Text(t.addressTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.lg),
        for (final a in app.addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: OptionCard(
              leading: Icon(a.kind == 'office' ? Icons.business_rounded : Icons.home_rounded, color: context.colors.inkMuted),
              title: '${a.label} · ${t.pyeong('${a.sizePyeong}')}',
              subtitle: '${a.roadAddress} ${a.detail}',
              selected: d.address?.id == a.id,
              onTap: () => setState(() => d.address = a),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(t.addressAdd),
          onPressed: () async {
            final added = await Navigator.of(context).push<Address>(MaterialPageRoute(builder: (_) => const AddressFormScreen()));
            if (added != null) setState(() => d.address = added);
          },
        ),
      ]),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t.next, onPressed: d.address == null ? null : _next)),
    );
  }
}

/// Opens (or reuses) a general consultation thread and shows it.
Future<void> openTopicChat(BuildContext context, String topic, {String? bookingId}) async {
  try {
    final r = await context.api.post('/chat/threads', {'topic': topic, 'booking_id': bookingId}) as Json;
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(threadId: r['id'] as String, topic: topic)));
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}

/// Date strip + arrival slots with live availability.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.draft, this.onDone, this.step = 3, this.total = 4});
  final BookingDraft draft;
  final void Function(BuildContext context)? onDone;
  final int step;
  final int total;
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  BookingDraft get d => widget.draft;
  Map<int, bool> _available = {};
  bool _loading = false;

  List<DateTime> get _days {
    final today = DateUtils.dateOnly(DateTime.now());
    return [for (var i = 1; i <= _maxDaysAhead; i++) today.add(Duration(days: i))];
  }

  List<int> get _slots => d.service.isQuote ? _quoteSlots : _standardSlots;

  @override
  void initState() {
    super.initState();
    d.date ??= _days.first;
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loading = true);
    try {
      final r = await context.api.get('/slots', query: {'date': isoDate(d.date!), 'quote': '${d.service.isQuote}'}) as List;
      if (!mounted) return;
      _available = {for (final s in r.cast<Json>()) (s['start_hour'] as num).toInt(): s['available'] as bool};
      if (d.hour != null && _available[d.hour] == false) d.hour = null;
      d.hour ??= _slots.where((h) => _available[h] ?? true).firstOrNull;
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    final hue = ServiceHues.of(d.service.code);
    final endHour = d.hour == null ? null : d.hour! + 1 + (d.minutes / 60).ceil();
    return Scaffold(
      appBar: AppBar(title: Text(t.stepOf('${widget.step}', '${widget.total}'))),
      body: ListView(padding: const EdgeInsets.symmetric(vertical: Space.gutter), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StepProgress(current: widget.step, total: widget.total, color: hue.tone),
            const SizedBox(height: Space.xl),
            Text(t.scheduleTitle, style: context.text.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(t.scheduleRange, style: context.text.bodySmall),
            if (d.address != null) ...[
              const SizedBox(height: Space.md),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                child: Row(children: [
                  Icon(Icons.place_rounded, color: hue.tone, size: 20),
                  const SizedBox(width: Space.xs),
                  Expanded(child: Text('${d.address!.label} · ${t.pyeong('${d.address!.sizePyeong}')}', style: context.text.titleSmall)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => AddressPickScreen(draft: d, step: widget.step, total: widget.total, onPicked: (ctx) {
                        Navigator.of(ctx).pop();
                        setState(() {});
                      }),
                    )),
                    child: Text(t.change),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: Space.lg),
          ]),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
            itemBuilder: (_, i) => _DayChip(
              day: _days[i],
              selected: DateUtils.isSameDay(_days[i], d.date),
              accent: hue.tone,
              onTap: () {
                setState(() => d.date = _days[i]);
                _loadSlots();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle(t.scheduleArrival, trailing: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5, // 2.6 clipped the title and window text at 390 dp
              mainAxisSpacing: Space.xs,
              crossAxisSpacing: Space.xs,
              children: [
                for (final h in _slots)
                  OptionCard(
                    title: d.service.isQuote ? (h < 12 ? t.morning : t.afternoon) : hourLabel(h, lang),
                    subtitle: (_available[h] ?? true) ? t.scheduleWindow(hourLabel(h, lang), hourLabel(h + 1, lang)) : t.scheduleFull,
                    selected: d.hour == h,
                    enabled: _available[h] ?? true,
                    accent: hue.tone,
                    onTap: () => setState(() => d.hour = h),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            if (d.service.isQuote)
              Text(t.scheduleQuoteNote, style: context.text.bodySmall)
            else if (endHour != null)
              AppCard(
                color: context.colors.tintOf(hue),
                padding: const EdgeInsets.all(Space.md),
                child: Row(children: [
                  Icon(Icons.schedule_rounded, color: hue.tone),
                  const SizedBox(width: Space.xs),
                  Expanded(child: Text(t.scheduleEnds(t.duration(d.minutes), hourLabel(endHour, lang)), style: context.text.bodyMedium)),
                ]),
              ),
          ]),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: d.service.isQuote ? t.next : t.goToPayment,
          color: hue.tone,
          onPressed: d.hour == null
              ? null
              : () => widget.onDone != null ? widget.onDone!(context) : Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CheckoutScreen(draft: d))),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, required this.onTap, required this.accent});
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final weekend = day.weekday >= DateTime.saturday;
    final dow = MaterialLocalizations.of(context).narrowWeekdays[day.weekday % 7];
    final dowColor = selected ? Colors.white : (day.weekday == DateTime.sunday ? Semantic.sunday : weekend ? Semantic.saturday : context.colors.inkMuted);
    return Semantics(
      selected: selected,
      button: true,
      label: dateLabel(day, context.lang),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.standard,
          width: 56,
          decoration: BoxDecoration(
            color: selected ? accent : context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? accent : context.colors.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(day.day == 1 || selected ? '${day.month}/${day.day}' : dow, style: context.text.labelSmall?.copyWith(color: dowColor)),
            const SizedBox(height: 4),
            Text('${day.day}', style: context.text.titleLarge?.copyWith(color: selected ? Colors.white : context.colors.ink)),
          ]),
        ),
      ),
    );
  }
}

/// Step 4 — coupon, method, breakdown, pay.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.draft});
  final BookingDraft draft;
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  BookingDraft get d => widget.draft;
  bool _busy = false;
  bool _autoPicked = false;
  PayChoice? _choice;

  int _discount(List<Coupon> coupons) {
    final c = coupons.where((c) => c.id == d.couponId).firstOrNull;
    return c == null ? 0 : (c.amount < d.listPrice ? c.amount : d.listPrice);
  }

  /// Booking body for checkout channels: the draft without the saved-method id.
  Json _bookingBody() => d.toJson()..remove('payment_method_id');

  /// Saved method -> POST /bookings (one-tap). Checkout channel -> PG window, then confirm.
  Future<void> _pay(int total) async {
    final choice = _choice;
    if (choice == null) return;
    setState(() => _busy = true);
    final app = context.appRead;
    try {
      final CheckoutResult result;
      if (choice case ChannelChoice(:final channel)) {
        result = await payWithChannel(context, channel, {'kind': 'booking', 'booking': _bookingBody()});
      } else {
        result = CheckoutPaid(Booking.fromJson(await app.api.post('/bookings', d.toJson()) as Json));
      }
      if (!mounted) return;
      switch (result) {
        case CheckoutPaid(:final booking):
          app.bookingsChanged();
          await app.loadCoupons();
          if (!mounted) return;
          await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => DoneScreen(booking: booking)), (r) => r.isFirst);
        case CheckoutAwaitingDeposit(:final account):
          app.bookingsChanged();
          await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => VirtualAccountScreen(account: account, amount: total)), (r) => r.isFirst);
        case CheckoutFailed(:final code):
          showToast(context, context.t.checkoutFailure(code));
        case CheckoutCancelled():
          break;
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    final usable = app.coupons.where((c) => c.appliesTo(d.service.code)).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    if (!_autoPicked) {
      // Best coupon pre-applied: customers shouldn't have to hunt for savings.
      d.couponId ??= usable.firstOrNull?.id;
      d.methodId ??= app.methods.firstOrNull?.id;
      _choice = d.methodId == null ? null : SavedChoice(d.methodId!);
      _autoPicked = true;
    }
    final savedId = switch (_choice) {
      SavedChoice(:final methodId) => methodId,
      _ => null,
    };
    final channelCode = switch (_choice) {
      ChannelChoice(:final channel) => channel.code,
      _ => null,
    };
    final discount = _discount(app.coupons);
    final total = d.listPrice - discount;
    final freeUntil = d.date!.subtract(const Duration(days: 2));
    final coupon = app.coupons.where((c) => c.id == d.couponId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t.stepOf('${d.totalSteps}', '${d.totalSteps}'))),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        StepProgress(current: d.totalSteps, total: d.totalSteps, color: ServiceHues.of(d.service.code).tone),
        const SizedBox(height: Space.xl),
        AppCard(
          child: Row(children: [
            ServiceGlyph(d.service.code, size: 52),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text([t.service(d.service.code), if (d.unitIndex != null) t.unit(d.service.units[d.unitIndex!].labelKey)].join(' · '), style: context.text.titleSmall),
                Text('${dateLabel(d.date!, context.lang)} ${hourLabel(d.hour!, context.lang)} · ${t.about(t.duration(d.minutes))}', style: context.text.bodySmall),
                Text('${d.address!.label} · ${t.pyeong('${d.address!.sizePyeong}')}', style: context.text.bodySmall),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: Icon(Icons.confirmation_number_rounded, color: context.colors.sun),
              title: Text(t.coupon),
              subtitle: Text(coupon == null ? (usable.isEmpty ? t.couponNone : t.couponAvailable('${usable.length}')) : t.couponName(coupon.name)),
              trailing: coupon == null ? const Icon(Icons.chevron_right_rounded) : Text('−${context.won(discount)}', style: context.text.titleSmall?.copyWith(color: context.colors.fresh)),
              onTap: usable.isEmpty ? null : () => _pickCoupon(usable),
            ),
          ]),
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.apPayAllTitle, style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            PayMethodPicker(
              selectedSavedId: savedId,
              selectedChannel: channelCode,
              onChoose: (c) => setState(() {
                _choice = c;
                d.methodId = switch (c) {
                  SavedChoice(:final methodId) => methodId,
                  ChannelChoice() => null,
                };
              }),
            ),
          ]),
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          child: Column(children: [
            _Line(t.listPrice, context.won(d.listPrice)),
            const SizedBox(height: Space.xs),
            _Line(t.discount, discount == 0 ? context.won(0) : '−${context.won(discount)}', color: discount == 0 ? null : context.colors.fresh),
            const Padding(padding: EdgeInsets.symmetric(vertical: Space.sm), child: Divider()),
            Row(children: [
              Text(t.total, style: context.text.titleMedium),
              const Spacer(),
              RollingAmount(value: total, format: context.won, style: context.text.headlineSmall),
            ]),
            Align(alignment: Alignment.centerRight, child: Text(t.vatIncluded, style: context.text.labelSmall)),
          ]),
        ),
        if (d.service.needsPreparation) ...[
          const SizedBox(height: Space.sm),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.prepTitle, style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final tool in prepTools) Chip(label: Text(t.tool(tool)), visualDensity: VisualDensity.compact)]),
              TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(t.prepAsk),
                onPressed: () => openTopicChat(context, d.service.code),
              ),
            ]),
          ),
        ],
      ]),
      bottomNavigationBar: BottomActionBar(
        summary: Text(t.freeCancelUntil(dateLabel(freeUntil, context.lang)), style: context.text.labelSmall),
        child: PrimaryButton(
          label: _choice == null ? t.needMethod : t.payAmount(context.won(total)),
          busy: _busy,
          onPressed: _choice == null ? null : () => _pay(total),
        ),
      ),
    );
  }

  Future<void> _pickCoupon(List<Coupon> usable) async {
    final t = context.t;
    final picked = await showAppSheet<String>(
      context,
      title: t.coupon,
      builder: (ctx) => ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter), children: [
        for (final c in usable)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: OptionCard(
              title: t.couponName(c.name),
              subtitle: t.couponUntil(dateLabel(c.expiresAt, ctx.lang)),
              trailing: ctx.won(c.amount),
              selected: c.id == d.couponId,
              onTap: () => Navigator.of(ctx).pop(c.id),
            ),
          ),
        OptionCard(title: t.couponNone, selected: d.couponId == null, onTap: () => Navigator.of(ctx).pop('')),
      ]),
    );
    if (picked != null) setState(() => d.couponId = picked.isEmpty ? null : picked);
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft)),
        const Spacer(),
        Text(value, style: context.text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ]);
}

/// Celebration + summary.
class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = booking;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(children: [
            const Spacer(),
            FlipIn(child: SuccessMark(semanticLabel: b.isQuote ? t.doneQuoteTitle : t.doneTitle)),
            StaggerIn(index: 1, child: Text(b.isQuote ? t.doneQuoteTitle : t.doneTitle, style: context.text.headlineSmall, textAlign: TextAlign.center)),
            const SizedBox(height: Space.xs),
            Text(b.isQuote ? t.doneQuoteBody : t.doneBody, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft), textAlign: TextAlign.center),
            const SizedBox(height: Space.xl),
            StaggerIn(index: 2, child: AppCard(
              child: Row(children: [
                ServiceGlyph(b.serviceCode, size: 48),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.service(b.serviceCode), style: context.text.titleSmall),
                    Text('${dateLabel(b.visitDate, context.lang)} ${hourLabel(b.startHour, context.lang)}', style: context.text.bodySmall),
                  ]),
                ),
                if (!b.isQuote) RollingAmount(value: b.paidAmount, format: context.won, style: context.text.titleSmall),
              ]),
            )),
            const Spacer(),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.goHome))),
              const SizedBox(width: Space.xs),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: b.id))),
                  child: Text(t.viewBooking),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
