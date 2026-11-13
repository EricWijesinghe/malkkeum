part of 'chat.dart';

DateTime _dayOf(DateTime at) {
  final l = at.toLocal();
  return DateTime(l.year, l.month, l.day);
}

bool _isReceived(ChatMessage m) =>
    m.kind == 'system' && m.body['code'] == 'consultation_received';

/// Fade + short slide from [from] (logical px) once, after [delay]. Plays only when [play];
/// reduced motion starts no ticker and shows the final frame.
class _Entrance extends StatefulWidget {
  const _Entrance({
    required this.child,
    this.from = const Offset(0, 12),
    this.delay = Duration.zero,
    this.play = true,
  });
  final Widget child;
  final Offset from;
  final Duration delay;
  final bool play;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  // The delay is folded into the curve, so no timer outlives the widget.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + Motion.standard,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / _c.duration!.inMilliseconds,
      1,
      curve: Motion.emphasized,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.play || reducedMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Transform.translate(
        offset: widget.from * (1 - _t.value),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

/// Date pill between days; the first day of a request also says it was received.
class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.day, required this.received});
  final DateTime day;
  final bool received;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = dateLabel(day, context.lang);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.sm),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          received ? '$label · ${t.chatDayReceived}' : label,
          style: context.text.labelSmall?.copyWith(
            color: context.colors.inkSoft,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.depositPaid,
    required this.latestQuote,
    required this.live,
    required this.onPay,
    this.refundingQuote,
  });
  final ChatMessage message;
  final bool depositPaid;
  final String? latestQuote;

  /// The quote whose payment the server is giving back (`checkout_refund_pending`).
  final String? refundingQuote;

  /// Arrived while the room is open: slides in from its sender's side.
  final bool live;

  /// Null while a payment is in flight.
  final void Function(ChatMessage quote)? onPay;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final t = context.t;
    final c = context.colors;
    final mine = m.sender == 'customer';
    if (m.kind == 'system') {
      return _Entrance(
        play: live,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: Space.xs),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.surfaceHigh,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              t.system(
                m.body['code'] as String? ?? '',
                (m.body['params'] as Json?) ?? const {},
                context.lang,
              ),
              style: context.text.labelSmall?.copyWith(color: c.inkSoft),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final Widget content = switch (m.kind) {
      'photo' => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          m.body['url'] as String,
          width: 200,
          cacheWidth: 400,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(width: 200, height: 120),
        ),
      ),
      'card' => _RequestCard(body: m.body),
      'quote' => _QuoteCard(
        body: m.body,
        paid: depositPaid,
        superseded: m.id != latestQuote,
        refunding: m.id == refundingQuote,
        arrive: live,
        onPay: onPay == null ? null : () => onPay!(m),
      ),
      _ => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? context.primary : c.surfaceHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.isAi)
              Text(
                t.aiLabel,
                style: context.text.labelSmall?.copyWith(
                  color: mine ? Colors.white70 : c.ink.withValues(alpha: 0.6),
                ),
              ),
            Text(
              m.body['text'] as String? ?? '',
              style: context.text.bodyMedium?.copyWith(
                color: mine ? Colors.white : c.ink,
              ),
            ),
          ],
        ),
      ),
    };
    final time = Text(
      timeLabel(m.createdAt, context.lang),
      style: context.text.labelSmall?.copyWith(fontSize: 10, color: c.inkMuted),
    );
    return _Entrance(
      play: live,
      from: Offset(mine ? 12 : -12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              const Icon3D('chat_team_avatar', size: 32),
              const SizedBox(width: 6),
            ],
            if (mine) ...[time, const SizedBox(width: 4)],
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: content,
              ),
            ),
            if (!mine) ...[const SizedBox(width: 4), time],
          ],
        ),
      ),
    );
  }
}

/// The request the customer sent: teal header band and the booking rows from the message body.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.body});
  final Json body;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final lang = context.lang;
    final code = body['service_code'] as String? ?? 'move_in';
    final visit = DateTime.tryParse(body['visit_date'] as String? ?? '');
    final hour = (body['start_hour'] as num?)?.toInt();
    final answers = body['answers'] is Json
        ? body['answers'] as Json
        : const <String, dynamic>{};
    final structure = [
      if (answers['building'] case final String b) _buildingLabel(t, b),
      if (answers['layout'] case final String l) _layoutLabel(t, l),
    ].join(' · ');
    final estimate = body['estimate'] as num?;
    final rows = [
      if (visit != null)
        (
          t.quoteVisit,
          [
            dateLabel(visit, lang),
            if (hour != null) hour < 12 ? t.morning : t.afternoon,
          ].join(' '),
          false,
        ),
      (t.quoteKind, t.service(code), false),
      if (structure.isNotEmpty) (t.layoutTitle, structure, false),
      if (estimate != null) (t.estimate, context.won(estimate.toInt()), true),
    ];
    final bookingId = body['booking_id'] as String?;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.tile),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: bookingId == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookingDetailScreen(id: bookingId),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: c.primaryTint,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Text(
                t.chatRequestTitle(t.service(code)),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.md,
                Space.sm,
              ),
              child: Column(
                children: [
                  for (final (label, value, strong) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: context.text.bodySmall?.copyWith(
                                color: c.inkSoft,
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.xs),
                          Flexible(
                            flex: 2,
                            child: Text(
                              value,
                              textAlign: TextAlign.end,
                              style: strong
                                  ? context.text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )
                                  : context.text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staff quote: confirmed total, the deposit sentence and the pay button. Every amount is read
/// from the message body the server wrote; the percentage is display-only.
class _QuoteCard extends StatefulWidget {
  const _QuoteCard({
    required this.body,
    required this.paid,
    required this.superseded,
    required this.arrive,
    required this.onPay,
    this.refunding = false,
  });
  final Json body;
  final bool paid;
  final bool superseded;

  /// Paid, then refunded because the booking changed; the refund has not landed yet.
  final bool refunding;

  /// Arrived while the room is open: settles in with one glow.
  final bool arrive;
  final VoidCallback? onPay;

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.celebrate,
  );

  /// Paid while this card was on screen: the button plays the check once.
  bool _justPaid = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0) return;
    if (widget.arrive && !reducedMotion(context)) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(_QuoteCard old) {
    super.didUpdateWidget(old);
    if (!old.paid && widget.paid) _justPaid = true;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final body = widget.body;
    int n(String k) => (body[k] as num? ?? 0).toInt();
    final finalPrice = n('final_price');
    final deposit = n('deposit');
    final paid = widget.paid;
    final payable = !paid && !widget.superseded && !widget.refunding;
    final note = body['note'] as String?;
    final teal = c.fresh;
    final label = paid
        ? Row(
            key: const ValueKey('paid'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _justPaid
                  ? const SuccessMark(size: 32)
                  : const Icon(Icons.check_rounded, size: 18),
              const SizedBox(width: 6),
              Text(t.quotePaid),
            ],
          )
        : Text(
            widget.refunding
                ? t.payStatusRefundPending
                : widget.superseded
                ? t.quoteSuperseded
                : t.quotePayDeposit,
            key: ValueKey((widget.superseded, widget.refunding)),
          );
    final card = Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.tile),
        border: Border.all(color: teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.quoteConfirmedTitle,
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.accent,
            ),
          ),
          const SizedBox(height: Space.xxs),
          Text(
            context.won(finalPrice),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            finalPrice > 0
                ? t.quoteDepositLine(
                    '${(deposit * 100 / finalPrice).round()}',
                    context.won(deposit),
                  )
                : '${t.quoteDepositNow} ${context.won(deposit)}',
            style: context.text.bodySmall?.copyWith(color: c.inkSoft),
          ),
          if (note?.isNotEmpty ?? false) ...[
            const SizedBox(height: Space.xs),
            Text(note!, style: context.text.bodySmall),
          ],
          const SizedBox(height: Space.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              // Paid reads as done, not as disabled.
              disabledBackgroundColor: paid ? c.primaryTint : null,
              disabledForegroundColor: paid ? c.accent : null,
            ),
            onPressed: payable ? widget.onPay : null,
            child: AnimatedSwitcher(
              duration: motionFor(context, Motion.standard),
              child: label,
            ),
          ),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = Motion.emphasized.transform(_c.value);
        return Transform.scale(
          scale: 0.96 + 0.04 * v,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.tile),
              // One teal glow that fades as the card settles.
              boxShadow: _c.value < 1
                  ? [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.35 * (1 - _c.value)),
                        blurRadius: 18,
                        spreadRadius: 2 * (1 - _c.value),
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
