import 'package:flutter/material.dart';

import '../tokens.dart';
import 'basics.dart' show serviceIcon;

/// How one 3D icon id renders while (or if) its art is missing, and which
/// asset file it reads.
@immutable
class Icon3DSpec {
  const Icon3DSpec(
    this.icon, {
    this.hue = _teal,
    this.hasIdle = false,
    this.alias,
    this.large = false,
  });

  /// Material glyph on the clay fallback plate.
  final IconData icon;

  /// Plate colour of the fallback. The glyph is white or ink, whichever reads.
  final Color hue;

  /// The art ships a separate grey `<id>_idle.webp` for the inactive state
  /// (bottom nav). Other ids show the same art when inactive.
  final bool hasIdle;

  /// Another id whose art this one reuses (no second asset).
  final String? alias;

  /// Also rendered at 160dp (`large/`, 320/480 px) for hero sizes.
  final bool large;
}

const _teal = Color(0xFF1E9EBA);
const _deep = Color(0xFF187A8F);
const _ink = Color(0xFF17232C);
const _sun = Color(0xFFFFD95A);
const _grey = Color(0xFF8C9AA3);

Icon3DSpec _svc(String code) =>
    Icon3DSpec(serviceIcon(code), hue: ServiceHues.of(code).tone);

/// Every 3D icon id of DAHAE-PLAN §4 with its fallback. Art lives in
/// `packages/ui/assets/icons3d/<id>.webp` (1x main, REQUIRED: a folder asset
/// entry only lists main files, so variants without one are never bundled)
/// plus `2.0x/<id>.webp` and `3.0x/<id>.webp`. Each WP drops its own files
/// there by id and [Icon3D] picks them up without a code change.
abstract final class Icon3DRegistry {
  static const package = 'ui';
  static const _dir = 'assets/icons3d';

  /// Used for an id that is not registered (a typo shows a neutral plate, not a crash).
  static const unknown = Icon3DSpec(Icons.circle_outlined, hue: _grey);

  static final Map<String, Icon3DSpec> specs = {
    // Bottom nav (customer + partner).
    'nav_home': const Icon3DSpec(Icons.home_rounded, hasIdle: true),
    'nav_bookings': const Icon3DSpec(
      Icons.event_available_rounded,
      hasIdle: true,
    ),
    'nav_chat': const Icon3DSpec(Icons.chat_bubble_rounded, hasIdle: true),
    'nav_more': const Icon3DSpec(Icons.grid_view_rounded, hasIdle: true),
    // Services.
    'svc_studio': _svc('studio'),
    'svc_move': const Icon3DSpec(
      Icons.local_shipping_rounded,
      hue: Color(0xFF0A795E),
    ),
    'svc_move_in': _svc('move_in'),
    'svc_move_out': _svc('move_out'),
    'svc_bathroom': _svc('bathroom'),
    'svc_kitchen': _svc('kitchen'),
    'svc_mattress': _svc('mattress'),
    'svc_aircon': _svc('aircon'),
    'svc_sofa': _svc('sofa'),
    'rec_move_combo': const Icon3DSpec(Icons.compare_arrows_rounded),
    'banner_coupon': const Icon3DSpec(
      Icons.confirmation_number_rounded,
      hue: _sun,
      large: true,
    ),
    // Content.
    'news_megaphone': const Icon3DSpec(Icons.campaign_rounded),
    'tip_bulb': const Icon3DSpec(Icons.lightbulb_rounded, hue: _sun),
    'notice_pin': const Icon3DSpec(Icons.push_pin_rounded),
    'faq_bubble': const Icon3DSpec(Icons.help_rounded),
    // Booking status timeline.
    'step_consult': const Icon3DSpec(Icons.support_agent_rounded),
    'step_confirmed': const Icon3DSpec(Icons.event_available_rounded),
    'step_matched': const Icon3DSpec(Icons.handshake_rounded),
    'step_completed': const Icon3DSpec(Icons.cottage_rounded),
    'status_cancelled': const Icon3DSpec(Icons.cancel_rounded, hue: _grey),
    // Studio scope blueprint.
    'scope_dusting': const Icon3DSpec(Icons.auto_fix_high_rounded),
    'scope_vacuum': const Icon3DSpec(Icons.cleaning_services_rounded),
    'scope_dishes': const Icon3DSpec(Icons.restaurant_rounded),
    'scope_bathroom': const Icon3DSpec(Icons.wc_rounded),
    'scope_trash': const Icon3DSpec(Icons.delete_rounded),
    // Prep tools (core prepTools codes).
    'tool_vacuum': const Icon3DSpec(Icons.cleaning_services_rounded),
    'tool_mop': const Icon3DSpec(Icons.cleaning_services_rounded),
    'tool_trash': const Icon3DSpec(Icons.delete_outline_rounded),
    'tool_gloves': const Icon3DSpec(Icons.back_hand_rounded, hue: _sun),
    'tool_cloth': const Icon3DSpec(Icons.layers_rounded),
    'tool_sponge': const Icon3DSpec(Icons.water_drop_rounded),
    'tool_spray': const Icon3DSpec(Icons.sanitizer_rounded),
    // Aircon units.
    'ac_wall': const Icon3DSpec(Icons.ac_unit_rounded),
    'ac_stand': const Icon3DSpec(Icons.kitchen_rounded),
    'ac_two_in_one': const Icon3DSpec(Icons.devices_rounded),
    'ac_ceiling': const Icon3DSpec(Icons.grid_4x4_rounded),
    // Move step 1: luggage and cleaning type.
    'box_empty': const Icon3DSpec(Icons.inventory_2_outlined),
    'box_partial': const Icon3DSpec(Icons.inventory_2_rounded),
    'box_full': const Icon3DSpec(Icons.all_inbox_rounded),
    'box_unknown': const Icon3DSpec(Icons.help_center_rounded, hue: _grey),
    'type_normal_move_in': const Icon3DSpec(Icons.vpn_key_rounded),
    'type_after_interior': const Icon3DSpec(Icons.format_paint_rounded),
    'type_lived_in': const Icon3DSpec(Icons.auto_awesome_rounded),
    'type_standard': const Icon3DSpec(Icons.inventory_2_rounded),
    'type_same_day': const Icon3DSpec(Icons.local_shipping_rounded),
    'type_some_luggage': const Icon3DSpec(Icons.chair_rounded),
    // Move step 2: building and layout.
    'bld_apartment': const Icon3DSpec(Icons.apartment_rounded),
    'bld_villa': const Icon3DSpec(Icons.holiday_village_rounded),
    'bld_commercial': const Icon3DSpec(Icons.storefront_rounded),
    'bld_officetel': const Icon3DSpec(Icons.domain_rounded),
    'bld_house': const Icon3DSpec(Icons.house_rounded),
    'bld_other': const Icon3DSpec(Icons.more_horiz_rounded, hue: _grey),
    'room_studio': const Icon3DSpec(Icons.crop_square_rounded),
    'room_one_half': const Icon3DSpec(Icons.view_sidebar_rounded),
    'room_two': const Icon3DSpec(Icons.view_module_rounded),
    'room_three': const Icon3DSpec(Icons.view_quilt_rounded),
    'room_four_plus': const Icon3DSpec(Icons.dashboard_rounded),
    'duplex_stairs': const Icon3DSpec(Icons.stairs_rounded),
    // Move step 3.
    'cnt_bathroom': const Icon3DSpec(Icons.bathtub_rounded),
    'cnt_balcony': const Icon3DSpec(Icons.balcony_rounded),
    'elev_yes': const Icon3DSpec(Icons.elevator_rounded),
    'elev_no': const Icon3DSpec(Icons.stairs_rounded, hue: _ink),
    // Schedule.
    'ui_calendar': const Icon3DSpec(Icons.calendar_month_rounded),
    'ui_clock': const Icon3DSpec(Icons.schedule_rounded),
    'slot_am': const Icon3DSpec(Icons.wb_twilight_rounded, hue: _sun),
    'slot_pm': const Icon3DSpec(Icons.wb_sunny_rounded, hue: _sun),
    // Wallet / app bar.
    'ui_coupon': const Icon3DSpec(Icons.confirmation_number_rounded, hue: _sun),
    'ui_points': const Icon3DSpec(Icons.toll_rounded, hue: _sun),
    'ui_pin': const Icon3DSpec(Icons.place_rounded),
    'ui_bell': const Icon3DSpec(Icons.notifications_rounded),
    'promo_ac_addon': const Icon3DSpec(Icons.discount_rounded),
    // Chat.
    'chat_new': const Icon3DSpec(Icons.add_comment_rounded),
    'chat_team_avatar': const Icon3DSpec(Icons.support_agent_rounded),
    'chat_quote': const Icon3DSpec(Icons.request_quote_rounded),
    'chat_hours': const Icon3DSpec(Icons.bedtime_rounded, hue: _deep),
    // Payment.
    'pay_card': const Icon3DSpec(Icons.credit_card_rounded),
    'pay_wallet': const Icon3DSpec(Icons.account_balance_wallet_rounded),
    'pay_bank': const Icon3DSpec(Icons.account_balance_rounded),
    'pay_virtual': const Icon3DSpec(Icons.receipt_long_rounded),
    // More menu (first group = the brief's ten).
    'menu_scope': const Icon3DSpec(Icons.checklist_rounded),
    'menu_payments': const Icon3DSpec(Icons.payments_rounded),
    'menu_addresses': const Icon3DSpec(Icons.maps_home_work_rounded),
    'menu_account': const Icon3DSpec(Icons.badge_rounded),
    'menu_notices': const Icon3DSpec(Icons.campaign_rounded),
    'menu_tips': const Icon3DSpec(Icons.lightbulb_rounded, hue: _sun),
    'menu_faq': const Icon3DSpec(Icons.help_rounded),
    'menu_contact': const Icon3DSpec(Icons.headset_mic_rounded),
    'menu_version': const Icon3DSpec(Icons.info_rounded),
    'menu_coupons': const Icon3DSpec(
      Icons.confirmation_number_rounded,
      hue: _sun,
    ),
    'menu_subscriptions': const Icon3DSpec(Icons.autorenew_rounded, hue: _deep),
    'menu_partner': const Icon3DSpec(Icons.handshake_rounded, hue: _deep),
    'menu_language': const Icon3DSpec(Icons.language_rounded, hue: _deep),
    'menu_theme': const Icon3DSpec(Icons.dark_mode_rounded, hue: _deep),
    'menu_privacy': const Icon3DSpec(Icons.privacy_tip_rounded, hue: _deep),
    'menu_terms': const Icon3DSpec(Icons.description_rounded, hue: _deep),
    'menu_licenses': const Icon3DSpec(Icons.article_rounded, hue: _deep),
    // Brand moments.
    'confirm_check': const Icon3DSpec(Icons.check_rounded, large: true),
    'logo_3d': const Icon3DSpec(Icons.home_rounded, large: true),
    'empty_inbox': const Icon3DSpec(Icons.inbox_rounded, hue: _grey),
    'error_offline': const Icon3DSpec(Icons.cloud_off_rounded, hue: _grey),
    // Partner app.
    'p_nav_jobs': const Icon3DSpec(Icons.assignment_rounded, hasIdle: true),
    'p_nav_quotes': const Icon3DSpec(
      Icons.request_quote_rounded,
      hasIdle: true,
    ),
    'p_nav_schedule': const Icon3DSpec(Icons.calendar_month_rounded),
    'p_camera': const Icon3DSpec(Icons.photo_camera_rounded),
    'p_verified': const Icon3DSpec(Icons.verified_rounded),
    'p_payout': const Icon3DSpec(Icons.savings_rounded, hue: _deep),
    // Console rail (24dp, tilt off).
    'c_dashboard': const Icon3DSpec(Icons.dashboard_rounded),
    'c_bookings': const Icon3DSpec(Icons.event_note_rounded),
    'c_quotes': const Icon3DSpec(Icons.request_quote_rounded),
    'c_chat': const Icon3DSpec(Icons.forum_rounded),
    'c_pricing': const Icon3DSpec(Icons.sell_rounded),
    'c_marketing': const Icon3DSpec(Icons.campaign_rounded),
    'c_partners': const Icon3DSpec(Icons.groups_rounded),
    'c_payments': const Icon3DSpec(Icons.payments_rounded),
    'c_payouts': const Icon3DSpec(Icons.account_balance_wallet_rounded),
    'c_subscriptions': const Icon3DSpec(Icons.autorenew_rounded),
    'c_customers': const Icon3DSpec(Icons.people_rounded),
    'c_staff': const Icon3DSpec(Icons.badge_rounded),
    'c_settings': const Icon3DSpec(Icons.settings_rounded),
    'c_monitor': const Icon3DSpec(Icons.monitor_heart_rounded),
    'c_privacy': const Icon3DSpec(Icons.privacy_tip_rounded),
  };

  static Icon3DSpec of(String id) => specs[id] ?? unknown;

  static bool has(String id) => specs.containsKey(id);

  /// Edge (dp) from which ids with a [Icon3DSpec.large] set use it: above
  /// ~96dp the 64dp set (192 px at 3.0x) starts to look soft.
  static const largeFrom = 96.0;

  /// Asset key (resolution variants live in `2.0x/` and `3.0x/` beside it).
  static String assetFor(String id, {bool idle = false, double size = 48}) {
    final spec = of(id);
    final file = spec.alias ?? id;
    final dir = spec.large && size >= largeFrom ? '$_dir/large' : _dir;
    return '$dir/${idle && spec.hasIdle ? '${file}_idle' : file}.webp';
  }

  /// `svc_<code>` for a catalog service code (move_in / move_out stay apart).
  static String serviceId(String code) => 'svc_$code';
}
