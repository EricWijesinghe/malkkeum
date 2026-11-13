import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'booking_detail.dart';
import 'request_status.dart';

const _avatarSize = 52.0;
const _avatarArt = 32.0;

/// The status pill never takes more than this share of the screen width.
const _chipMaxShare = 0.3;

/// A quote still in consultation opens the request tracker; every other booking its detail.
void openBooking(BuildContext context, Booking b) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => b.isQuote && b.status == 0
        ? RequestStatusScreen(booking: b)
        : BookingDetailScreen(id: b.id),
  ),
);

/// Flat row: the service art on its tinted disc, the time as the title, the service under it
/// and the status pill on the right. [showDate] puts the date before the time (rows outside a day list).
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.showDate = false});
  final Booking booking;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.tile),
      onTap: () => openBooking(context, b),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tintOf(ServiceHues.of(b.serviceCode)),
              ),
              child: ServiceGlyph(b.serviceCode, size: _avatarArt),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showDate ? bookingWhen(context, b) : bookingTime(context, b),
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.t.service(b.serviceCode),
                          style: context.text.bodyMedium?.copyWith(
                            color: c.inkSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.inkMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            // A long translation wraps inside its pill rather than squeezing out the time.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * _chipMaxShare,
              ),
              child: BookingStatusChip(status: b.status),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wording of the brief for chips and the timeline: 상담요청 → 예약확정 → 매칭 완료 → 서비스 완료.
String bookingStepLabel(T t, int status) => switch (status) {
  0 => t.bkStepConsult,
  1 => t.bkStepConfirmed,
  2 => t.bkStepMatched,
  3 => t.bkStepCompleted,
  _ => t.statusCancelled,
};

String bookingStepIcon(int status) => switch (status) {
  0 => 'step_consult',
  1 => 'step_confirmed',
  2 => 'step_matched',
  3 => 'step_completed',
  _ => 'status_cancelled',
};

/// Quotes are booked by half-day ("오전 방문"); fixed-price visits by the hour slot ("오전 9시~10시").
String bookingTime(BuildContext context, Booking b) {
  final t = context.t;
  if (b.isQuote) return b.startHour < 12 ? t.dfAmVisit : t.dfPmVisit;
  return slotRangeLabel(b.startHour, context.lang);
}

String bookingWhen(BuildContext context, Booking b) =>
    '${dateLabel(b.visitDate, context.lang)} ${bookingTime(context, b)}';

/// Text-only status pill. A request in consultation is outlined; later steps fill with their
/// [StatusHues] tint. A status that changes while on screen cross-fades.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});
  final int status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = StatusHues.of(status);
    final outlined = status == 0;
    return AnimatedSwitcher(
      duration: motionFor(context, Motion.standard),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: outlined ? c.surface : c.tintOf(hue),
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(
            color: outlined ? c.line : c.line.withValues(alpha: 0),
          ),
        ),
        // A long translation wraps inside its pill instead of overflowing the row.
        child: Text(
          bookingStepLabel(context.t, status),
          textAlign: TextAlign.center,
          style: context.text.labelMedium?.copyWith(
            color: outlined ? c.ink : (c.isDark ? hue.tint : hue.tone),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
