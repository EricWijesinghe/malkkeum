import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/main.dart';
import 'package:partner/state.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

/// Same theme and localisation wiring as [PartnerApp], around any [home] screen.
class PartnerTestHost extends StatelessWidget {
  const PartnerTestHost({super.key, required this.env, required this.app, required this.home});

  final TestEnv env;
  final PartnerState app;
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
            theme: buildTheme(partnerBrand, Brightness.light),
            darkTheme: buildTheme(partnerBrand, Brightness.dark),
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

/// Pumps [home] inside the partner app wiring (no sign-in gate) and returns the state.
Future<PartnerState> pumpPartnerScreen(WidgetTester tester, TestEnv env, Widget home) async {
  final app = PartnerState(env.api, FakeRealtime(env.api));
  await tester.pumpWidget(PartnerTestHost(env: env, app: app, home: home));
  return app;
}

/// Pumps the real [PartnerApp] root (sign-in gate, onboarding/pending/shell routing).
Future<PartnerState> pumpPartnerApp(WidgetTester tester, TestEnv env) async {
  final app = PartnerState(env.api, FakeRealtime(env.api));
  await tester.pumpWidget(PartnerApp(session: env.session, app: app, locale: env.locale, theme: env.theme));
  return app;
}

/// Verified, onboarded pro with a 20% fee unless a test says otherwise.
Json verifiedProfile({String name = '말끔팀', String status = 'verified', int feeBps = 2000, int pendingPayout = 120000}) => {
      'name': name,
      'team_name': '팀A',
      'status': status,
      'fee_bps': feeBps,
      'pending_payout': pendingPayout,
    };

/// Registers the endpoints the partner Gate and tabs read on start-up.
void stockPartnerApi(
  FakeApi api, {
  Json? profile,
  Json? prefs,
  List<Json> jobs = const [],
}) {
  api
    ..reply('GET', '/partner/me', profile ?? verifiedProfile())
    ..reply('GET', '/partner/prefs', prefs ?? {'services': ['studio', 'kitchen'], 'districts': ['11680']})
    ..reply('GET', '/partner/threads', const <Json>[])
    ..reply('GET', '/partner/quotes', const <Json>[])
    ..reply('GET', '/partner/jobs', jobs);
}

/// A row of the jobs feed (fields read by the job card).
Json jobJson({
  String id = 'job-1',
  String serviceCode = 'studio',
  bool isOpen = true,
  int customerPrice = 100000,
  Json? answers,
  int? estimate,
  int? myQuote,
}) =>
    {
      'id': id,
      'service_code': serviceCode,
      'is_open': isOpen,
      'customer_price': customerPrice,
      'answers': answers,
      'estimate': estimate,
      'my_quote': myQuote,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'visit_date': isoDay(DateTime.now().add(const Duration(days: 2))),
      'start_hour': 9,
      'district_code': '11680',
      'road_area': null,
      'size_pyeong': 20,
    };
