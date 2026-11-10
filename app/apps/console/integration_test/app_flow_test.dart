// End-to-end golden path against a real dev API.
//
// Skipped unless E2E=true. Run from apps/console:
//   flutter test integration_test/app_flow_test.dart \
//     --dart-define=E2E=true \
//     --dart-define=API_BASE=https://<dev-api-host> \
//     --dart-define=E2E_STAFF_EMAIL=<staff email> \
//     --dart-define=E2E_STAFF_PASSWORD=<staff password>
//
// Use a dev-only staff account. The password comes from the command line and is never stored.
import 'package:console/main.dart';
import 'package:console/shell.dart';
import 'package:console/state.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

const _runE2e = bool.fromEnvironment('E2E');
const _email = String.fromEnvironment('E2E_STAFF_EMAIL');
const _password = String.fromEnvironment('E2E_STAFF_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('golden path: staff login, open the palette, reach the bookings list', skip: !_runE2e, (tester) async {
    final session = Session(namespace: 'e2e-console');
    await session.clear();
    final api = ApiClient(baseUrl: defaultApiBase(), session: session);
    final locale = LocaleController();
    final theme = ThemeController();
    await locale.set(const Locale('ko'));
    await theme.set(ThemeMode.dark);
    final state = ConsoleState(api, Realtime(api), session);

    await tester.pumpWidget(ConsoleApp(session: session, state: state, locale: locale, theme: theme));
    final t = lookupT(const Locale('ko'));
    await pumpUntilFound(tester, find.byType(TextField), timeout: const Duration(seconds: 15));
    await tester.enterText(find.byType(TextField).at(0), _email);
    await tester.enterText(find.byType(TextField).at(1), _password);
    await settle(tester, duration: const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(PrimaryButton, t.cLogin));
    await settle(tester, duration: const Duration(seconds: 2));

    // The shell only appears after a fresh launch (see docs/verify/flutter-tests.md, known risks).
    // Relaunch the app for the rest of the journey.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ConsoleApp(session: session, state: state, locale: locale, theme: theme));
    await pumpUntilFound(tester, find.byType(ConsoleShell), timeout: const Duration(seconds: 15));

    await tester.tap(find.byTooltip(t.cSearchCommand).first);
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, t.cBookings).last);
    await settle(tester, duration: const Duration(seconds: 2));
    expect(find.text(t.cBookings), findsWidgets);

    await session.logout();
  });
}
