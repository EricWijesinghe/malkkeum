import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/auth.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('partner intro: animated Dahae lockup, AA CTA and tag (${mode.name})', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final env = await TestEnv.create(fake: FakeApi(), role: 'partner', themeMode: mode);
      await pumpPartnerScreen(tester, env, const PartnerIntro());
      await settle(tester, duration: const Duration(milliseconds: 900));

      final logo = tester.widget<DahaeLogo>(find.byType(DahaeLogo));
      expect(logo.wordmark && logo.animate && logo.onDark == true, isTrue);
      expect(find.text('PARTNER'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester.takeException(), isNull);
      await unmount(tester);
      handle.dispose();
    });
  }
}
