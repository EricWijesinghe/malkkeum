// u1-stub: delete when U1 lands (package:ui then exports Icon3D and DahaeLogo).
// Minimal stand-in for the U1 contract so this app compiles before the foundation merges:
// no art, no motion, Material fallback icons only.
import 'package:flutter/material.dart';

const _fallback = <String, IconData>{
  'c_dashboard': Icons.space_dashboard_rounded,
  'c_bookings': Icons.event_note_rounded,
  'c_quotes': Icons.request_quote_rounded,
  'c_chat': Icons.forum_rounded,
  'c_pricing': Icons.sell_rounded,
  'c_marketing': Icons.campaign_rounded,
  'c_partners': Icons.engineering_rounded,
  'c_payments': Icons.payments_rounded,
  'c_payouts': Icons.account_balance_wallet_rounded,
  'c_subscriptions': Icons.event_repeat_rounded,
  'c_customers': Icons.people_alt_rounded,
  'c_staff': Icons.badge_rounded,
  'c_settings': Icons.tune_rounded,
  'c_monitor': Icons.monitor_heart_rounded,
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

class DahaeLogo extends StatelessWidget {
  const DahaeLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.home_rounded,
    size: size,
    color: Theme.of(context).colorScheme.primary,
  );
}
