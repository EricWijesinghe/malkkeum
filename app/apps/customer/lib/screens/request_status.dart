import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'bookings.dart' show bookingStepLabel;
import 'chat.dart';
import 'flow_widgets.dart';
import 'quote_flow.dart';
import 'service.dart';

const _trackerSteps = 4;
const _sheetCtaKickDelay = Duration(milliseconds: 1200);

/// Quote request status (design p20): date, 4-step tracker, payment and service info,
/// "상담 채팅" and "예약 취소". Right after submitting it opens the completion sheet (p21).
class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({
    super.key,
    required this.booking,
    this.estimate,
    this.showDoneSheet = false,
  });
  final Booking booking;

  /// The estimate the customer saw (for the deposit rate); optional.
  final Json? estimate;
  final bool showDoneSheet;
  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  late Booking b = widget.booking;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.showDoneSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _doneSheet();
      });
    }
  }

  void _openChat() {
    final thread = b.threadId;
    if (thread == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(
          threadId: thread,
          topic: b.serviceCode,
          bookingId: b.id,
        ),
      ),
    );
  }

  Future<void> _doneSheet() async {
    final t = context.t;
    final aircon = context.appRead.service('aircon');
    final go = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CloseButton(onPressed: () => Navigator.of(ctx).pop()),
            ),
            StaggerIn(
              index: 0,
              child: Text(
                t.dfRequestDone,
                textAlign: TextAlign.center,
                style: ctx.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            StaggerIn(
              index: 1,
              child: Text(
                t.dfRequestDoneBody,
                textAlign: TextAlign.center,
                style: ctx.text.bodyMedium?.copyWith(color: ctx.colors.inkSoft),
              ),
            ),
            if (aircon != null) ...[
              const SizedBox(height: Space.lg),
              StaggerIn(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: ctx.colors.surfaceHigh,
                    borderRadius: BorderRadius.circular(Radii.tile),
                  ),
                  child: Column(
                    children: [
                      const ExcludeSemantics(
                        child: Icon3D(
                          'svc_aircon',
                          size: 56,
                          idle: Icon3DIdle.sway,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        t.dfAcUpsell,
                        textAlign: TextAlign.center,
                        style: ctx.text.bodyMedium,
                      ),
                      const SizedBox(height: Space.sm),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => Navigator.of(ctx).pop('aircon'),
                        child: Text(t.dfAcUpsellCta),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: Space.md),
            if (b.threadId != null)
              StaggerIn(
                index: 3,
                // One kick once the sheet has been read: the chat is the next step.
                child: OneShot(
                  onMount: true,
                  delay: _sheetCtaKickDelay,
                  builder: kick,
                  child: PrimaryButton(
                    label: t.dfViewChat,
                    onPressed: () => Navigator.of(ctx).pop('chat'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (go == 'chat') _openChat();
    if (go == 'aircon' && aircon != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ServiceScreen(service: aircon)),
      );
    }
  }

  Future<void> _cancel() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.cancelBooking),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.cancelBooking),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final app = context.appRead;
    try {
      // A consultation has no payment yet, so no cancellation fee applies.
      await app.api.postAction('/bookings/${b.id}/cancel', {'accepted_fee': 0});
      app.bookingsChanged();
      if (!mounted) return;
      showToast(context, t.cancelled);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    final a = b.answers ?? const {};
    final depositBps = (widget.estimate?['deposit_bps'] as num?)?.toInt();
    final road = b.j['address'] is Json
        ? (b.address['road_address'] as String? ?? '')
        : '';
    // The same wording as the bookings list: 상담요청, 예약확정, 매칭 완료, 서비스 완료.
    final steps = [
      for (var i = 0; i < _trackerSteps; i++) bookingStepLabel(t, i),
    ];
    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Column(
              children: [
                Text(
                  DateFormat.yMMMEd(lang).format(b.visitDate),
                  textAlign: TextAlign.center,
                  style: context.text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${visitHalf(t, b.startHour)} (${slotRangeLabel(b.startHour, lang)})',
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: Space.lg),
                const ExcludeSemantics(
                  child: Icon3D(
                    'step_consult',
                    size: 96,
                    idle: Icon3DIdle.float,
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(t.dfRequested, style: context.text.titleLarge),
                const SizedBox(height: Space.lg),
                _Tracker(
                  labels: steps,
                  current: b.status.clamp(0, steps.length - 1),
                ),
                const SizedBox(height: Space.md),
                Text(
                  t.dfStatusNote,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.lg),
              ],
            ),
          ),
          const FlowBand(),
          FlowSection(
            title: t.dfPayInfo,
            children: [
              if (depositBps != null)
                Text(
                  t.dfPayInfoBody(pctOf(depositBps)),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              const SizedBox(height: Space.sm),
              AppCard(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dfQuoteMethod,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.inkMuted,
                      ),
                    ),
                    Text(
                      t.dfSafeBooking,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              if (b.estimate != null)
                InfoRow(t.dfEstAmount, context.won(b.estimate!)),
              InfoRow(
                t.dfDeposit,
                b.deposit != null && b.status >= 1
                    ? context.won(b.deposit!)
                    : t.dfAwaitingPay,
                valueStyle: context.text.bodyMedium?.copyWith(
                  color: context.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const FlowBand(),
          FlowSection(
            title: t.dfServiceInfo,
            children: [
              InfoRow(
                t.dfSummaryService,
                '${t.service(b.serviceCode)} · ${cleaningTypeLabel(t, a['cleaning_type'] as String?)}',
              ),
              InfoRow(
                t.dfSpace,
                '${buildingLabel(t, a['building'] as String?)} · ${layoutLabel(t, a['layout'] as String?)}',
              ),
              if (road.isNotEmpty) InfoRow(t.dfSummaryAddress, road),
            ],
          ),
          Container(
            color: context.colors.surfaceHigh,
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              children: [
                if (b.threadId != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 52),
                      backgroundColor: context.colors.surface,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(t.dfChat),
                    onPressed: _openChat,
                  ),
                if (b.status == 0) ...[
                  const SizedBox(height: Space.sm),
                  TextButton(
                    onPressed: _busy ? null : _cancel,
                    child: Text(
                      t.cancelBooking,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _dotRow = 32.0;

/// 상담요청 → 예약확정 → 매칭완료 → 서비스완료 on one line that fills up to the current
/// step as the screen opens; the current step pulses.
class _Tracker extends StatelessWidget {
  const _Tracker({required this.labels, required this.current});
  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: labels[current],
      child: Stack(
        children: [
          // The connector runs from the first dot's centre to the last one's, under the dots.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _dotRow,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: (labels.length - 1) / labels.length,
                child: ProgressLine(
                  fraction: current / (labels.length - 1),
                  color: context.primary,
                  thickness: 3,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, l) in labels.indexed)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: _dotRow,
                        child: Center(
                          child: i == current
                              ? Pulse(
                                  child: _dot(
                                    context.primary,
                                    22,
                                    ring: c.primaryTint,
                                  ),
                                )
                              : _dot(
                                  i < current ? context.primary : c.line,
                                  14,
                                ),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      ExcludeSemantics(
                        child: Text(
                          l,
                          textAlign: TextAlign.center,
                          style: context.text.labelMedium?.copyWith(
                            color: i == current ? context.primary : c.inkMuted,
                            fontWeight: i == current
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, double size, {Color? ring}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: ring == null ? null : Border.all(color: ring, width: 4),
    ),
  );
}
