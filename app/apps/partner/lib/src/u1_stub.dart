// u1-stub: delete when U1 lands (package:ui then exports Icon3D).
// Minimal stand-in for the U1 contract so this app compiles before the foundation merges:
// no art, no motion, Material fallback icons only.
import 'package:flutter/material.dart';

const _fallback = <String, IconData>{
  'p_nav_jobs': Icons.search_rounded,
  'p_nav_quotes': Icons.request_quote_outlined,
  'p_nav_schedule': Icons.calendar_month_outlined,
  'nav_chat': Icons.chat_bubble_outline_rounded,
  'nav_more': Icons.menu_rounded,
};

class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = false, this.size = 64});
  final String id;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(_fallback[id] ?? Icons.circle_outlined, size: size);
}
