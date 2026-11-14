import 'package:console/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// The glyph each sidebar entry must show, written out by hand so a shifted mapping fails here.
const _expected = <String, IconData>{
  'c_dashboard': Icons.dashboard_rounded,
  'c_bookings': Icons.event_note_rounded,
  'c_quotes': Icons.request_quote_rounded,
  'c_chat': Icons.forum_rounded,
  'c_pricing': Icons.sell_rounded,
  'c_marketing': Icons.campaign_rounded,
  'c_partners': Icons.groups_rounded,
  'c_payments': Icons.payments_rounded,
  'c_payouts': Icons.account_balance_wallet_rounded,
  'c_subscriptions': Icons.autorenew_rounded,
  'c_customers': Icons.people_rounded,
  'c_staff': Icons.badge_rounded,
  'c_settings': Icons.settings_rounded,
  'c_rules': Icons.rule_rounded,
  'c_notify': Icons.notifications_active_rounded,
  'c_monitor': Icons.monitor_heart_rounded,
  'c_audit': Icons.history_rounded,
  'c_privacy': Icons.privacy_tip_rounded,
  'c_renewals': Icons.event_repeat_rounded,
};

void main() {
  final pairs = navIconPairs();

  test('every nav item has its own registered rail icon', () {
    final ids = pairs.map((p) => p.$1).toList();
    expect(
      ids.toSet().length,
      ids.length,
      reason: 'two nav items share one icon id',
    );
    for (final (id, _) in pairs) {
      expect(Icon3DRegistry.has(id), isTrue, reason: id);
    }
  });

  test('each nav item shows the glyph the design assigns to it', () {
    expect(
      {for (final (id, _) in pairs) id},
      _expected.keys.toSet(),
      reason: 'every sidebar entry needs an expected glyph',
    );
    for (final (id, icon) in pairs) {
      expect(icon, _expected[id], reason: id);
    }
  });

  test('first nav items keep their rail order', () {
    expect(pairs.take(3).map((p) => p.$1).toList(), [
      'c_dashboard',
      'c_bookings',
      'c_quotes',
    ]);
  });
}
