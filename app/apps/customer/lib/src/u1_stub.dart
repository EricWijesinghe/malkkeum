// u1-stub: delete when U1 lands
// Stand-ins for the U1 contract so U3 compiles before the foundation merges:
// `Icon3D` comes from package:ui and `slotRangeLabel` from package:core.
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

const _fallback = <String, IconData>{
  'step_consult': Icons.support_agent_rounded,
  'step_confirmed': Icons.event_available_rounded,
  'step_matched': Icons.handshake_rounded,
  'step_completed': Icons.home_rounded,
  'status_cancelled': Icons.cancel_rounded,
  'ui_calendar': Icons.calendar_month_rounded,
  'ui_clock': Icons.schedule_rounded,
  'slot_am': Icons.wb_twilight_rounded,
  'slot_pm': Icons.wb_sunny_rounded,
};

class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = false, this.size = 24});
  final String id;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    _fallback[id] ?? Icons.circle,
    size: size,
    color: active ? context.colors.accent : context.colors.inkMuted,
  );
}

/// One-hour arrival slot, "09:00~10:00".
String slotRangeLabel(int startHour, String lang) {
  String hh(int h) => '${'$h'.padLeft(2, '0')}:00';
  return '${hh(startHour)}~${hh(startHour + 1)}';
}
