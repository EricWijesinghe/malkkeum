import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/jobs.dart';
import 'package:test_support/test_support.dart';

import 'support/partner_host.dart';

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('jobs feed meets tap-target and contrast guidelines (${mode.name})', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi();
      stockPartnerApi(fake, jobs: [jobJson(customerPrice: 100000)]);
      final env = await TestEnv.create(fake: fake, role: 'partner', themeMode: mode);
      await pumpPartnerScreen(tester, env, const JobsTab());
      await pumpUntilFound(tester, find.text(koT.pDirect));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('pending waiting screen meets tap-target and contrast guidelines (${mode.name})', (tester) async {
      setViewport(tester, phoneSize);
      final handle = tester.ensureSemantics();
      final fake = FakeApi();
      stockPartnerApi(fake, profile: verifiedProfile(status: 'pending'));
      final env = await TestEnv.create(fake: fake, role: 'partner', themeMode: mode);
      await pumpPartnerApp(tester, env);
      await pumpUntilFound(tester, find.text(koT.pPendingTitle));
      await settle(tester, duration: const Duration(milliseconds: 800));
      await _expectAccessible(tester);
      await unmount(tester);
      handle.dispose();
    });
  }
}
