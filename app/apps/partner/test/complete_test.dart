import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/complete.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/partner_host.dart';

// Photo upload goes through ImagePicker, which has no seam yet. These tests cover the
// enabled-state rules that do not need a picked photo. Photo-required paths stay untested
// until a picker seam exists.
void main() {
  testWidgets('completion stays locked with no photos, even when every checklist item is ticked', (tester) async {
    setViewport(tester, phoneSize);
    final fake = FakeApi();
    stockPartnerApi(fake);
    final env = await TestEnv.create(fake: fake, role: 'partner');
    await pumpPartnerScreen(tester, env, const CompleteScreen(bookingId: 'bk-1', isQuote: false));
    await pumpUntilFound(tester, find.text(koT.pChecklist));

    final cta = find.widgetWithText(PrimaryButton, koT.pCompleteCta);
    expect(tester.widget<PrimaryButton>(cta).onPressed, isNull);
    expect(find.text('${koT.pBeforePhotos} (0)'), findsOneWidget);
    expect(find.text('${koT.pAfterPhotos} (0)'), findsOneWidget);
    expect(find.text(koT.pCompleteNeed), findsOneWidget);

    final checks = find.byType(CheckboxListTile);
    expect(checks, findsNWidgets(4), reason: 'four checklist items');
    for (var i = 0; i < 4; i++) {
      await tester.tap(checks.at(i));
      await settle(tester, duration: const Duration(milliseconds: 150));
    }
    expect(tester.widget<PrimaryButton>(cta).onPressed, isNull, reason: 'checklist alone is not enough');
    expect(fake.callsTo('POST', '/partner/jobs/bk-1/complete'), isEmpty);
    await unmount(tester);
  });
}
