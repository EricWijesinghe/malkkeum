import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_address.dart';
import 'booking_flow.dart';
import 'bookings.dart';
import 'cancel_booking_sheet.dart';
import 'growth.dart';
import 'pay_flow.dart';
import 'service.dart';

part 'booking_detail_sections.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _view = GlobalKey<AsyncViewState<Booking>>();
  StreamSubscription<Json>? _sub;
  final Set<String> _prepDone = {};

  @override
  void initState() {
    super.initState();
    _sub = context.appRead.realtime.events.listen((e) {
      final id = (e['data'] as Json?)?['booking_id'];
      if (id == widget.id || e['type'] == 'resync') {
        _view.currentState?.reload();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<Booking> _load() async =>
      Booking.fromJson(await context.api.get('/bookings/${widget.id}') as Json);

  /// One money or cancel action at a time: a second tap while one runs is ignored.
  bool _busy = false;

  Future<void> _once(Future<void> Function() fn) async {
    if (_busy) return;
    _busy = true;
    try {
      await fn();
    } finally {
      _busy = false;
    }
  }

  Future<void> _act(Future<void> Function() fn, [String? success]) =>
      _once(() async {
        try {
          await fn();
          if (!mounted) return;
          context.appRead.bookingsChanged();
          await _view.currentState?.reload();
          if (mounted && success != null) showToast(context, success);
        } catch (e) {
          if (mounted) showToast(context, context.t.error(e));
        }
      });

  /// kind = 'deposit' | 'balance'. Saved method: one-tap. Channel: PG window per payment.
  Future<void> _pay(Booking b, String kind) async {
    final choice = await choosePayMethod(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case SavedChoice(:final methodId):
        await _act(
          () => context.api.postAction('/bookings/${b.id}/$kind', {
            'payment_method_id': methodId,
          }),
        );
      case ChannelChoice(:final channel):
        await _once(() => _payWithChannel(b, kind, channel));
    }
  }

  Future<void> _payWithChannel(
    Booking b,
    String kind,
    PayChannel channel,
  ) async {
    final result = await payWithChannel(context, channel, {
      'kind': kind,
      'booking_id': b.id,
    });
    if (!mounted) return;
    switch (result) {
      case CheckoutPaid():
        context.appRead.bookingsChanged();
        await _view.currentState?.reload();
      case CheckoutAwaitingDeposit(:final account):
        context.appRead.bookingsChanged();
        await showVirtualAccount(context, account);
        if (mounted) await _view.currentState?.reload();
      case CheckoutPending():
        // Possibly charged: leave so the pay button is not offered again until the server answers.
        context.appRead.bookingsChanged();
        Navigator.of(context).popUntil((r) => r.isFirst);
      case CheckoutFailed(:final code):
        showToast(context, context.t.checkoutFailure(code));
      case CheckoutCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.t.detailTitle)),
    body: AsyncView<Booking>(
      key: _view,
      load: _load,
      builder: (context, b, reload) =>
          RefreshIndicator(onRefresh: reload, child: _body(b)),
    ),
  );

  Widget _body(Booking b) {
    final t = context.t;
    final service = context.app.service(b.serviceCode);
    final hue = ServiceHues.of(b.serviceCode);
    final unit =
        b.unitIndex != null &&
            service != null &&
            b.unitIndex! < service.units.length
        ? t.unit(service.units[b.unitIndex!].labelKey)
        : null;
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        Row(
          children: [
            ServiceGlyph(b.serviceCode, size: 52),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookingStatusChip(status: b.status),
                  const SizedBox(height: 4),
                  Text(bookingWhen(context, b), style: context.text.titleLarge),
                  Text(
                    [
                      t.service(b.serviceCode),
                      ?unit,
                      if (b.minutes != null) t.about(t.duration(b.minutes!)),
                    ].join(' · '),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (b.status == 0 && b.finalPrice == null)
          _info(
            Icons.hourglass_top_rounded,
            t.waitingQuote,
            b.estimate == null
                ? null
                : '${t.estimate} ${context.won(b.estimate!)}',
            hue,
          ),
        if (b.status == 0 && b.finalPrice != null)
          _actionCard(
            t.depositDue(context.won(b.deposit!)),
            '${t.finalPrice} ${context.won(b.finalPrice!)}',
            t.payDeposit,
            () => _pay(b, 'deposit'),
          ),
        if (b.balanceDue)
          _actionCard(
            t.balanceDue(context.won(b.finalPrice! - b.deposit!)),
            null,
            t.payBalance,
            () => _pay(b, 'balance'),
          ),
        if (b.status >= 0) ...[
          const SizedBox(height: Space.sm),
          _Timeline(booking: b),
        ],
        if (b.status == -1)
          _info(
            Icons.event_busy_rounded,
            t.cancelled,
            null,
            StatusHues.cancelled,
          ),
        if (b.beforePhotos.isNotEmpty || b.afterPhotos.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          _Photos(before: b.beforePhotos, after: b.afterPhotos),
        ],
        if (b.status == 3 && !b.reviewed) ...[
          const SizedBox(height: Space.sm),
          _ReviewPrompt(
            bookingId: b.id,
            onSaved: () {
              _act(() async {}, t.reviewSaved);
              StoreReview.device().maybeAsk();
            },
          ),
        ],
        if ((service?.needsPreparation ?? false) && b.isActive) ...[
          const SizedBox(height: Space.sm),
          _prepCard(),
        ],
        const SizedBox(height: Space.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(t.visitAddress),
                subtitle: Text(
                  '${fullAddressLine(b.address)}\n${t.pyeong('${b.address['size_pyeong']}')}',
                ),
              ),
              if (b.paidAmount > 0)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(t.paid),
                  trailing: Text(
                    context.won(b.paidAmount),
                    style: context.text.titleSmall,
                  ),
                ),
              if (b.isActive)
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(t.visitNotes),
                  subtitle: Text(
                    [
                          b.visitNotes['entry'],
                          b.visitNotes['parking'],
                          b.visitNotes['other'],
                        ]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editNotes(b),
                ),
            ],
          ),
        ),
        if (b.checkedInAt != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            t.checkedInAt(
              TimeOfDay.fromDateTime(b.checkedInAt!.toLocal()).format(context),
            ),
            style: context.text.bodySmall,
          ),
        ],
        const SizedBox(height: Space.sm),
        EmergencyContactsCard(contacts: b.emergency),
        if (b.status == 2 || b.status == 3) ...[
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(t.caseReportAction),
            onPressed: () async {
              final api = context.api;
              final messenger = ScaffoldMessenger.of(context);
              final sent = await showCaseReport(
                context,
                kinds: const [
                  'damage',
                  'loss',
                  'complaint',
                  'no_show',
                  'safety',
                  'payment_dispute',
                ],
                submit: (kind, summary) => api.post('/bookings/${b.id}/cases', {
                  'kind': kind,
                  'summary': summary,
                }),
              );
              if (sent) {
                messenger.showSnackBar(
                  SnackBar(content: Text(t.caseSubmitted)),
                );
              }
            },
          ),
        ],
        const SizedBox(height: Space.lg),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: Text(t.askTeam),
          onPressed: () =>
              openTopicChat(context, b.serviceCode, bookingId: b.id),
        ),
        if (b.isActive) ...[
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reschedule(b),
                  child: Text(t.reschedule),
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancel(b),
                  child: Text(t.cancelBooking),
                ),
              ),
            ],
          ),
        ],
        if (b.status == 3 && service != null && !b.isQuote) ...[
          const SizedBox(height: Space.xs),
          OutlinedButton.icon(
            icon: const Icon(Icons.replay_rounded),
            label: Text(t.bookAgain),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ServiceScreen(service: service, initialUnit: b.unitIndex),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _info(IconData icon, String title, String? body, ServiceHue hue) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: AppCard(
          color: context.colors.tintOf(hue),
          child: Row(
            children: [
              Icon(icon, color: context.colors.isDark ? hue.tint : hue.tone),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (body != null) Text(body, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _actionCard(
    String title,
    String? body,
    String cta,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: AppCard(
      color: context.colors.primaryTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleSmall),
          if (body != null) Text(body, style: context.text.bodySmall),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    ),
  );

  Widget _prepCard() {
    final t = context.t;
    final all = _prepDone.length == prepTools.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.prepCheck, style: context.text.titleSmall),
              ),
              Text(
                all
                    ? t.prepAllSet
                    : '${_prepDone.length} / ${prepTools.length}',
                style: context.text.labelMedium?.copyWith(
                  color: all ? context.colors.fresh : context.colors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tool in prepTools)
                FilterChip(
                  label: Text(t.tool(tool)),
                  selected: _prepDone.contains(tool),
                  onSelected: (on) => setState(
                    () => on ? _prepDone.add(tool) : _prepDone.remove(tool),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editNotes(Booking b) async {
    final t = context.t;
    final entry = TextEditingController(
      text: b.visitNotes['entry'] as String? ?? '',
    );
    final parking = TextEditingController(
      text: b.visitNotes['parking'] as String? ?? '',
    );
    final other = TextEditingController(
      text: b.visitNotes['other'] as String? ?? '',
    );
    final save = await showAppSheet<bool>(
      context,
      title: t.visitNotes,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        children: [
          TextField(
            controller: entry,
            maxLength: 300,
            decoration: InputDecoration(labelText: t.notesEntry),
          ),
          TextField(
            controller: parking,
            maxLength: 300,
            decoration: InputDecoration(labelText: t.notesParking),
          ),
          TextField(
            controller: other,
            maxLength: 300,
            maxLines: 3,
            decoration: InputDecoration(labelText: t.notesOther),
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (save == true) {
      await _act(
        () => context.api.put('/bookings/${b.id}/notes', {
          'entry': entry.text,
          'parking': parking.text,
          'other': other.text,
        }),
        t.notesSaved,
      );
    }
    disposeAfterClose([entry, parking, other]);
  }

  Future<void> _reschedule(Booking b) async {
    final service = context.appRead.service(b.serviceCode);
    if (service == null) return;
    final draft = BookingDraft(service)
      ..unitIndex = b.unitIndex
      ..date = b.visitDate
      ..hour = b.startHour;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScheduleScreen(
          draft: draft,
          onDone: (ctx) async {
            final nav = Navigator.of(ctx);
            await _act(
              () => context.api.post('/bookings/${b.id}/reschedule', {
                'visit_date': isoDate(draft.date!),
                'start_hour': draft.hour,
              }),
              context.t.rescheduled,
            );
            nav.pop();
          },
        ),
      ),
    );
  }

  /// The cancel sheet shows the server's fee and refund; the accepted fee goes back so a changed policy is refused.
  Future<void> _cancel(Booking b) async {
    final result = await confirmCancelBooking(context, b.id);
    if (result == null || !mounted) return;
    await _act(
      () => context.api.postAction('/bookings/${b.id}/cancel', {
        'accepted_fee': result.fee,
        'reason': ?result.reason,
      }),
      context.t.cancelled,
    );
  }
}
