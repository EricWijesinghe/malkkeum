// u1-stub: delete when U1 lands (Icon3D comes from package:ui).
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

const _fallback = <String, IconData>{
  'chat_new': Icons.add_comment_rounded,
  'chat_team_avatar': Icons.support_agent_rounded,
  'chat_quote': Icons.request_quote_rounded,
  'chat_hours': Icons.schedule_rounded,
};

class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = false, this.size = 24});
  final String id;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        _fallback[id] ?? Icons.circle_outlined,
        size: size * 0.6,
        color: context.primary,
      ),
    ),
  );
}
