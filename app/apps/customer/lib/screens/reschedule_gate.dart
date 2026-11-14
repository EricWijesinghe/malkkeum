import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../state.dart';
import 'cancel_booking_sheet.dart';

/// Shows [child] (the 일정 변경 entry) only when the server's cancel preview allows a reschedule.
/// A failed preview hides the entry, because the server would refuse the change anyway.
class RescheduleGate extends StatelessWidget {
  const RescheduleGate({
    super.key,
    required this.bookingId,
    required this.child,
  });

  final String bookingId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _allowed(context),
      builder: (context, snap) =>
          snap.data == true ? child : const SizedBox.shrink(),
    );
  }

  Future<bool> _allowed(BuildContext context) async {
    try {
      final j =
          (await context.api.get('/bookings/$bookingId/cancel-preview'))
              as Json;
      return CancelPreview.fromJson(j).rescheduleAllowed;
    } catch (_) {
      return false;
    }
  }
}
