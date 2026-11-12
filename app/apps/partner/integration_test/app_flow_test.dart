// End-to-end golden path against a real dev API.
//
// Skipped unless E2E=true. Run from apps/partner:
//   flutter test integration_test/app_flow_test.dart \
//     --dart-define=E2E=true \
//     --dart-define=API_BASE=https://<dev-api-host> \
//     --dart-define=E2E_PHONE=01012345678 \
//     --dart-define=E2E_CODE=<code from the dev SMS or DEV_MODE>
//
// Use a dev-only pro account. If the code screen is pre-filled (DEV_MODE), E2E_CODE is ignored.
import 'package:core/core.dart';
import 'package:partner/outbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:partner/main.dart';
import 'package:partner/screens/shell.dart';
import 'package:partner/state.dart';
import 'package:test_support/test_support.dart';

const _runE2e = bool.fromEnvironment('E2E');
const _phone = String.fromEnvironment('E2E_PHONE', defaultValue: '01012345678');
const _code = String.fromEnvironment('E2E_CODE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('golden path: sign in as a pro, land on the gate, and see the jobs or waiting screen', skip: !_runE2e, (tester) async {
    final session = Session(namespace: 'e2e-partner');
    await session.clear();
    final api = ApiClient(baseUrl: defaultApiBase(), session: session);
    final locale = LocaleController();
    final theme = ThemeController();
    await locale.set(const Locale('ko'));
    await theme.set(ThemeMode.dark);
    final state = PartnerState(api, Realtime(api), outbox: await CompletionOutbox.open());
    final t = lookupT(const Locale('ko'));

    await tester.pumpWidget(PartnerApp(session: session, app: state, locale: locale, theme: theme));
    await pumpUntilFound(tester, find.text(t.introStart), timeout: const Duration(seconds: 15));
    await tester.tap(find.text(t.introStart));
    await settle(tester);

    await tester.enterText(find.byType(TextField), _phone);
    await settle(tester, duration: const Duration(milliseconds: 300));
    await tester.tap(find.text(t.loginSendCode));
    await settle(tester);

    final codeField = find.byType(TextField);
    if (tester.widget<TextField>(codeField).controller!.text.isEmpty) {
      await tester.enterText(codeField, _code);
      await settle(tester, duration: const Duration(milliseconds: 300));
    }
    await tester.tap(find.text(t.loginVerify));
    await settle(tester, duration: const Duration(seconds: 2));

    // Relaunch: the root route is chosen at launch, so a fresh tree routes through the Gate.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(PartnerApp(session: session, app: state, locale: locale, theme: theme));
    await pumpUntilFound(tester, find.byType(Gate), timeout: const Duration(seconds: 20));
    await settle(tester, duration: const Duration(seconds: 2));

    final reached = find.text(t.pOnbTitle).evaluate().isNotEmpty ||
        find.text(t.pPendingTitle).evaluate().isNotEmpty ||
        find.text(t.pTabJobs).evaluate().isNotEmpty;
    expect(reached, isTrue, reason: 'expected onboarding, the waiting screen, or the jobs tab');

    await session.logout();
  });
}
