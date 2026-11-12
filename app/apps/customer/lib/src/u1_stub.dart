// u1-stub: delete when U1 lands (U1 exports the real Icon3D from package:ui).
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

const _fallback = <String, IconData>{
  'scope_dusting': Icons.air_rounded,
  'scope_vacuum': Icons.cleaning_services_rounded,
  'scope_dishes': Icons.local_dining_rounded,
  'scope_bathroom': Icons.bathtub_rounded,
  'scope_trash': Icons.delete_outline_rounded,
  'tool_vacuum': Icons.cleaning_services_rounded,
  'tool_mop': Icons.cleaning_services_outlined,
  'tool_trash': Icons.delete_outline_rounded,
  'tool_gloves': Icons.back_hand_rounded,
  'tool_cloth': Icons.dry_cleaning_rounded,
  'tool_sponge': Icons.wash_rounded,
  'tool_spray': Icons.sanitizer_rounded,
  'ac_wall': Icons.ac_unit_rounded,
  'ac_stand': Icons.kitchen_rounded,
  'ac_two_in_one': Icons.dashboard_rounded,
  'ac_ceiling': Icons.grid_view_rounded,
  'box_empty': Icons.check_box_outline_blank_rounded,
  'box_partial': Icons.inventory_2_outlined,
  'box_full': Icons.inventory_2_rounded,
  'bld_apartment': Icons.apartment_rounded,
  'bld_villa': Icons.home_work_rounded,
  'bld_commercial': Icons.storefront_rounded,
  'bld_other': Icons.more_horiz_rounded,
  'room_studio': Icons.crop_square_rounded,
  'room_one_half': Icons.view_agenda_rounded,
  'room_two': Icons.view_week_rounded,
  'room_three': Icons.view_module_rounded,
  'room_four_plus': Icons.view_comfy_rounded,
  'duplex_stairs': Icons.stairs_rounded,
  'cnt_bathroom': Icons.bathtub_rounded,
  'cnt_balcony': Icons.balcony_rounded,
  'elev_yes': Icons.elevator_rounded,
  'elev_no': Icons.stairs_rounded,
  'promo_ac_addon': Icons.ac_unit_rounded,
};

/// Clay plate + Material icon, the same fallback U1's Icon3D draws while art is missing.
class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = true, this.size = 48});
  final String id;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = active ? context.colors.fresh : context.colors.inkMuted;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        _fallback[id] ?? Icons.auto_awesome_rounded,
        color: hue,
        size: size * 0.56,
      ),
    );
  }
}
