// u1-stub: delete when U1 lands (package:ui exports the real Icon3D with art, tilt and bounce).
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Stand-in for U1's `Icon3D('<id>', active:, size:)`: the existing clay glyph for services,
/// a tinted plate with a Material icon for everything else. No motion.
class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = false, this.size = 56});
  final String id;
  final bool active;
  final double size;

  static const _icons = <String, IconData>{
    'banner_coupon': Icons.confirmation_number_rounded,
    'rec_move_combo': Icons.swap_horiz_rounded,
    'news_megaphone': Icons.campaign_rounded,
    'tip_bulb': Icons.lightbulb_rounded,
    'ui_pin': Icons.place_rounded,
    'ui_bell': Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (id.startsWith('svc_')) {
      final code = id.substring(4);
      return ServiceGlyph(code == 'move' ? 'move_out' : code, size: size);
    }
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primaryTint,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        _icons[id] ?? Icons.cleaning_services_rounded,
        size: size * 0.56,
        color: context.primary,
      ),
    );
  }
}
