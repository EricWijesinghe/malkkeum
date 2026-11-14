part of 'booking_flow.dart';

/// "{name}님 서비스 전 꼭 준비해 주세요!" (design p11): the tools to have ready, then checkout.
class PrepToolsScreen extends StatelessWidget {
  const PrepToolsScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final name = context.app.name;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(backgroundColor: context.colors.surface),
      body: ListView(
        children: [
          FlowTitle(name.isEmpty ? t.prepTitle : t.dfPrepHeader(name)),
          FlowSection(
            title: t.dfPrepTools,
            children: [
              Text(
                t.prepBody,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
              const SizedBox(height: Space.lg),
              tileRows(cols: 4, [
                for (final (i, tool) in prepTools.indexed)
                  StaggerIn(
                    index: i,
                    step: _toolStagger,
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          // Seven icons, each swaying on its own phase.
                          child: Tilt3D(
                            child: Icon3D(
                              'tool_$tool',
                              size: 52,
                              idle: Icon3DIdle.sway,
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          t.tool(tool),
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ]),
            ],
          ),
          const FlowBand(),
          Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: AppCard(
              color: context.colors.surfaceHigh,
              onTap: () => openTopicChat(context, draft.service.code),
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  // One kick after the tools have landed: help is a tap away.
                  OneShot(
                    onMount: true,
                    delay: _glyphKickDelay,
                    builder: kick,
                    child: CircleAvatar(
                      backgroundColor: context.colors.surface,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: context.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.dfNoTools, style: context.text.titleSmall),
                        Text(t.dfNoToolsBody, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PriceBar(
        amount: draft.listPrice,
        label: t.next,
        onDetails: () => showPriceBreakdown(context, draft),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CheckoutScreen(draft: draft)),
        ),
      ),
    );
  }
}

/// Booking confirmed (design p13): big check, summary card, 홈으로 / 예약 보기.
class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = booking;
    final minutes = b.minutes;
    final service = context.app.service(b.serviceCode);
    final counts = service != null && service.isCounts
        ? t.unitCounts(service, b.unitCounts)
        : '';
    final road = b.j['address'] is Json
        ? (b.address['road_address'] as String? ?? '')
        : '';
    // 확정 only for a booking that is confirmed (paid, awaiting a team); any other state keeps 완료.
    final title = b.isQuote
        ? t.doneQuoteTitle
        : b.isConfirmed
        ? t.doneConfirmedTitle
        : t.doneTitle;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            const SizedBox(height: Space.xl),
            Center(
              // Big confirm check (U1 renders it as the 3D confirm_check), scaled down on short screens.
              child: FlipIn(
                child: SuccessMark(
                  size: (MediaQuery.sizeOf(context).height * 0.2).clamp(
                    _minConfirmSize,
                    _confirmSize,
                  ),
                  semanticLabel: title,
                ),
              ),
            ),
            StaggerIn(
              index: 1,
              child: Text(
                title,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Space.xs),
            StaggerIn(
              index: 1,
              child: Text(
                b.isQuote ? t.doneQuoteBody : t.doneBody,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.inkSoft,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Space.xl),
            StaggerIn(
              index: 2,
              child: AppCard(
                color: context.colors.surfaceHigh,
                child: Column(
                  children: [
                    // Each line lands after the card, the paid amount last, counting up.
                    for (final (i, row) in [
                      InfoRow(
                        t.dfSummaryService,
                        [
                          minutes == null
                              ? t.service(b.serviceCode)
                              : '${t.service(b.serviceCode)} (${t.duration(minutes)})',
                          if (counts.isNotEmpty) counts,
                        ].join('\n'),
                      ),
                      InfoRow(
                        t.dfSummaryWhen,
                        '${dateLabel(b.visitDate, context.lang)} ${slotRangeLabel(b.startHour, context.lang)}',
                      ),
                      if (road.isNotEmpty) InfoRow(t.dfSummaryAddress, road),
                      if (!b.isQuote) ...[
                        const Divider(height: Space.lg),
                        InfoRow(
                          t.dfSummaryPaid,
                          context.won(b.paidAmount),
                          valueChild: CountIn(
                            value: b.paidAmount,
                            format: context.won,
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ].indexed)
                      StaggerIn(index: i + 3, child: row),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.goHome),
              ),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingDetailScreen(id: b.id),
                  ),
                ),
                child: Text(t.viewBooking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
