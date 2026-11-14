import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'cancel_policy_card.dart';

/// The server's cancel preview for one booking. The server decides the fee and refund; the app only shows them.
class CancelPreview {
  const CancelPreview({
    required this.canCancel,
    required this.days,
    required this.percent,
    required this.paid,
    required this.fee,
    required this.refund,
  });

  factory CancelPreview.fromJson(Json j) => CancelPreview(
    canCancel: j['can_cancel'] == true,
    days: (j['days_before'] as num? ?? 0).toInt(),
    percent: (j['percent'] as num?)?.toInt(),
    paid: (j['paid'] as num? ?? 0).toInt(),
    fee: (j['fee'] as num? ?? 0).toInt(),
    refund: (j['refund'] as num? ?? 0).toInt(),
  );

  final bool canCancel;
  final int days;

  /// Null when the cancel is free or closed.
  final int? percent;
  final int paid;
  final int fee;
  final int refund;
}

/// What the customer confirmed: the fee they saw (sent back so a changed policy is refused) and an optional reason.
class CancelConfirmation {
  const CancelConfirmation({required this.fee, this.reason});
  final int fee;
  final String? reason;
}

/// Shows the cancel sheet for booking [id] with the fee tier, refund and method. Null when the customer keeps it
/// or the preview cannot be loaded.
Future<CancelConfirmation?> confirmCancelBooking(
  BuildContext context,
  String id,
) async {
  final t = context.t;
  final CancelPreview preview;
  try {
    preview = CancelPreview.fromJson(
      (await context.api.get('/bookings/$id/cancel-preview')) as Json,
    );
  } catch (e) {
    if (context.mounted) showToast(context, t.error(e));
    return null;
  }
  if (!context.mounted) return null;
  return showAppSheet<CancelConfirmation>(
    context,
    title: t.cancelTitle,
    builder: (ctx) => _CancelSheetBody(preview: preview),
  );
}

class _CancelSheetBody extends StatefulWidget {
  const _CancelSheetBody({required this.preview});
  final CancelPreview preview;

  @override
  State<_CancelSheetBody> createState() => _CancelSheetBodyState();
}

class _CancelSheetBodyState extends State<_CancelSheetBody> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = widget.preview;
    final refundCta = p.refund > 0
        ? t.cancelRefundCta(context.won(p.refund))
        : t.cancelBooking;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!p.canCancel)
            Text(
              t.err_cancellation_window_closed,
              style: context.text.bodyMedium,
            )
          else ...[
            Text(
              p.fee > 0
                  ? t.cancelTierLine('${p.days}', '${p.percent ?? 0}')
                  : t.cancelFree,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: Space.sm),
            if (p.fee > 0)
              Text(
                t.cancelFeeLine(context.won(p.fee)),
                style: context.text.bodyMedium,
              ),
            Text(
              p.refund > 0
                  ? t.cancelRefundLine(context.won(p.refund))
                  : t.cancelNoRefund,
              style: context.text.titleSmall,
            ),
            if (p.refund > 0)
              Text(t.cancelMethodLine, style: context.text.bodySmall),
            TextButton(
              onPressed: () => showAppSheet<void>(
                context,
                title: t.cancelPolicyTitle,
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(Space.gutter),
                  child: CancelPolicyCard(total: p.paid),
                ),
              ),
              child: Text(t.cancelPolicyLink),
            ),
            const SizedBox(height: Space.sm),
            Text(t.cancelReasonTitle, style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            _reasonPicker(context),
          ],
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.cancelKeep),
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.danger,
                  ),
                  onPressed: p.canCancel
                      ? () => Navigator.of(
                          context,
                        ).pop(CancelConfirmation(fee: p.fee, reason: _reason))
                      : null,
                  child: Text(refundCta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reasonPicker(BuildContext context) {
    final t = context.t;
    final reasons = {
      'schedule': t.cancelReasonSchedule,
      'provider': t.cancelReasonProvider,
      'price': t.cancelReasonPrice,
      'other': t.cancelReasonOther,
    };
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final e in reasons.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: _reason == e.key,
            onSelected: (on) => setState(() => _reason = on ? e.key : null),
          ),
      ],
    );
  }
}
