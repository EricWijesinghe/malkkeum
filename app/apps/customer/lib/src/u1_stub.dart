// u1-stub: delete when U1 lands (Icon3D then comes from package:ui, with art, motion and semantics).
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Stand-in for U1's `Icon3D('<id>', active:, size:)`: a tinted plate with a Material fallback icon.
class Icon3D extends StatelessWidget {
  const Icon3D(this.id, {super.key, this.active = false, this.size = 40});
  final String id;
  final bool active;
  final double size;

  static const _fallback = <String, IconData>{
    'menu_scope': Icons.checklist_rounded,
    'menu_payments': Icons.credit_card_rounded,
    'menu_addresses': Icons.home_work_rounded,
    'menu_account': Icons.badge_rounded,
    'menu_notices': Icons.campaign_rounded,
    'menu_tips': Icons.lightbulb_rounded,
    'menu_faq': Icons.help_rounded,
    'menu_contact': Icons.support_agent_rounded,
    'menu_version': Icons.info_rounded,
    'menu_subscriptions': Icons.event_repeat_rounded,
    'menu_partner': Icons.handshake_rounded,
    'menu_language': Icons.translate_rounded,
    'menu_theme': Icons.dark_mode_rounded,
    'menu_privacy': Icons.privacy_tip_rounded,
    'menu_terms': Icons.description_rounded,
    'menu_licenses': Icons.code_rounded,
    'ui_coupon': Icons.confirmation_number_rounded,
    'ui_points': Icons.savings_rounded,
    'pay_card': Icons.credit_card_rounded,
    'pay_wallet': Icons.account_balance_wallet_rounded,
    'pay_bank': Icons.account_balance_rounded,
    'pay_virtual': Icons.receipt_long_rounded,
  };

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.colors.primaryTint,
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Icon(
      _fallback[id] ?? Icons.circle_outlined,
      size: size * 0.56,
      color: context.primary,
    ),
  );
}
