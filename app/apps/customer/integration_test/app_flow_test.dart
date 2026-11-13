// End-to-end golden path against a real dev API.
//
// Skipped unless E2E=true. Run from apps/customer:
//   flutter test integration_test/app_flow_test.dart \
//     --dart-define=E2E=true \
//     --dart-define=API_BASE=https://<dev-api-host> \
//     --dart-define=E2E_PHONE=01012345678
//
// The dev API must run with DEV_MODE on, so /auth/otp returns `dev_code` and the code
// screen pre-fills it. Without that, the test stops at the code step and fails loudly.
import 'package:core/core.dart';
import 'package:customer/main.dart';
import 'package:customer/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_support/test_support.dart';

const _runE2e = bool.fromEnvironment('E2E');
const _phone = String.fromEnvironment('E2E_PHONE', defaultValue: '01012345678');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('golden path: sign in with the dev code, reach home, open a service', skip: !_runE2e, (tester) async {
    final session = Session(namespace: 'e2e-customer');
    await session.clear(); // start signed out, whatever the device kept
    final api = ApiClient(baseUrl: defaultApiBase(), session: session);
    final locale = LocaleController();
    final theme = ThemeController();
    await locale.set(const Locale('ko'));
    await theme.set(ThemeMode.dark);
    final app = AppState(api, Realtime(api));

    await tester.pumpWidget(CustomerApp(session: session, app: app, locale: locale, theme: theme));
    final t = lookupT(const Locale('ko'));
    await pumpUntilFound(tester, find.text(t.introStart), timeout: const Duration(seconds: 15));
    await tester.tap(find.text(t.introStart));
    await settle(tester);

    await tester.enterText(find.byType(TextField), _phone);
    await settle(tester, duration: const Duration(milliseconds: 300));
    await tester.tap(find.text(t.loginSendCode));
    await settle(tester);

    // Dev code is pre-filled on the code step.
    await tester.tap(find.text(t.loginVerify));
    await settle(tester, duration: const Duration(seconds: 2));

    if (find.text(t.profileTitle).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), 'E2E 고객');
      await settle(tester, duration: const Duration(milliseconds: 300));
      await tester.tap(find.text(t.profileDone));
      await settle(tester, duration: const Duration(seconds: 2));
    }

    await pumpUntilFound(tester, find.text(t.tabHome), timeout: const Duration(seconds: 15));
    await pumpUntilFound(tester, find.text(t.service('studio')), timeout: const Duration(seconds: 15));
    await tester.tap(find.text(t.service('studio')));
    await settle(tester);
    expect(find.text(t.service('studio')), findsWidgets);
    expect(find.text(t.dfBookNow), findsOneWidget);

    await session.logout();
  });
}
