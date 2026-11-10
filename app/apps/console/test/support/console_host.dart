import 'package:console/main.dart';
import 'package:console/state.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

/// Same theme and localisation wiring as [ConsoleApp], with [home] inside a Scaffold
/// (the real screens rely on the shell's Scaffold for Material ancestry).
class ConsoleTestHost extends StatelessWidget {
  const ConsoleTestHost({super.key, required this.env, required this.state, required this.home});

  final TestEnv env;
  final ConsoleState state;
  final Widget home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([env.locale, env.session, env.theme]),
        builder: (context, _) => Deps(
          state: state,
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
            home: Scaffold(body: home),
          ),
        ),
      );
}

Future<ConsoleState> pumpConsoleScreen(WidgetTester tester, TestEnv env, Widget home) async {
  final state = ConsoleState(env.api, FakeRealtime(env.api), env.session);
  await tester.pumpWidget(ConsoleTestHost(env: env, state: state, home: home));
  return state;
}

/// Pumps the real [ConsoleApp] root (login gate, shell, palette, shortcuts).
Future<ConsoleState> pumpConsoleApp(WidgetTester tester, TestEnv env) async {
  final state = ConsoleState(env.api, FakeRealtime(env.api), env.session);
  await tester.pumpWidget(ConsoleApp(session: env.session, state: state, locale: env.locale, theme: env.theme));
  return state;
}

/// Start-up reads of the console shell, plus empty lists for the tabs.
void stockConsoleApi(FakeApi api, {List<Json> bookings = const []}) {
  api
    ..reply('GET', '/admin/dashboard', {'unread_threads': 0, 'open_quotes': 0})
    ..reply('GET', '/admin/threads', const <Json>[])
    ..reply('GET', '/admin/bookings', bookings)
    ..reply('GET', '/admin/services', const <Json>[])
    ..reply('GET', '/admin/content', const <Json>[])
    ..reply('GET', '/admin/coupons', const <Json>[]);
}

/// Detail payload the booking panel reads.
Json bookingDetail({
  String id = 'bk-1',
  int status = 2,
  Json? answers,
  Json? estimate,
}) =>
    {
      'booking': bookingJson(id: id, number: 'B-20260101-0001', status: status, answers: answers, estimate: 58000),
      'customer': {'name': '지민', 'phone': '01012345678', 'email': null},
      'payments': <Json>[],
      'estimate_breakdown': estimate,
    };
