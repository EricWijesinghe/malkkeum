import 'package:customer/main.dart';
import 'package:customer/state.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

/// Same theme and localisation wiring as [CustomerApp], around any [home] screen.
/// Use it for single-screen tests; use [CustomerApp] itself for journeys from sign-in.
class CustomerTestHost extends StatelessWidget {
  const CustomerTestHost({
    super.key,
    required this.env,
    required this.app,
    required this.home,
  });

  final TestEnv env;
  final AppState app;
  final Widget home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([env.locale, env.session, env.theme]),
    builder: (context, _) => Deps(
      app: app,
      session: env.session,
      locale: env.locale,
      theme: env.theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(BrandConfig.placeholder, Brightness.light),
        darkTheme: buildTheme(BrandConfig.placeholder, Brightness.dark),
        themeMode: env.theme.mode,
        locale: env.locale.locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          T.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
}

/// Pumps [home] inside the customer app shell (no sign-in logic) and returns the state.
Future<AppState> pumpCustomerScreen(
  WidgetTester tester,
  TestEnv env,
  Widget home,
) async {
  final app = AppState(env.api, FakeRealtime(env.api));
  await tester.pumpWidget(CustomerTestHost(env: env, app: app, home: home));
  return app;
}

/// Pumps the real [CustomerApp] root (sign-in gate, Shell, Deps, theme, locale).
Future<AppState> pumpCustomerApp(WidgetTester tester, TestEnv env) async {
  final app = AppState(env.api, FakeRealtime(env.api));
  await tester.pumpWidget(
    CustomerApp(
      session: env.session,
      app: app,
      locale: env.locale,
      theme: env.theme,
    ),
  );
  return app;
}
