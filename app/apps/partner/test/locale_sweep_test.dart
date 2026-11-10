import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/partner_host.dart';

/// Smallest supported phone at a larger system font, every app language: no overflow anywhere.
const _smallPhone = Size(320, 568);
const _bigFont = 1.3;

void main() {
  for (final locale in LocaleController.supported) {
    final code = locale.languageCode;
    testWidgets('[$code] every partner tab fits a small phone with large text', (tester) async {
      setViewport(tester, _smallPhone);
      tester.platformDispatcher.textScaleFactorTestValue = _bigFont;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fake = FakeApi();
      stockPartnerApi(
        fake,
        profile: verifiedProfile(name: 'Nguyễn Văn Thành Long'),
        jobs: [
          jobJson(id: 'j1', serviceCode: 'move_out', customerPrice: 420000, estimate: 420000),
          jobJson(id: 'j2', serviceCode: 'aircon', isOpen: false, customerPrice: 89000),
        ],
      );
      final env = await TestEnv.create(fake: fake, localeCode: code, role: 'pro');
      final t = lookupT(locale);
      await pumpPartnerApp(tester, env);
      await pumpUntilFound(tester, find.text(t.pTabJobs));
      await settle(tester, duration: const Duration(milliseconds: 600));
      for (final tab in [t.pTabQuotes, t.pTabSchedule, t.tabChat, t.tabMore, t.pTabJobs]) {
        await tester.tap(find.text(tab).last);
        await settle(tester, duration: const Duration(milliseconds: 600));
        final e = tester.takeException();
        expect(e, isNull, reason: '$tab: $e');
      }
      await unmount(tester);
    });
  }
}
