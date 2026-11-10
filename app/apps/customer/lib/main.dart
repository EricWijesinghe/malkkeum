import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/auth.dart';
import 'screens/shell.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'customer');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  final locale = LocaleController();
  final theme = ThemeController();
  await Future.wait([session.restore(), locale.restore(), theme.restore()]);
  runApp(
    CustomerApp(
      session: session,
      app: AppState(api, Realtime(api)),
      locale: locale,
      theme: theme,
    ),
  );
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({
    super.key,
    required this.session,
    required this.app,
    required this.locale,
    required this.theme,
  });
  final Session session;
  final AppState app;
  final LocaleController locale;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([locale, session, theme]),
    builder: (context, _) => Deps(
      app: app,
      session: session,
      locale: locale,
      theme: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (c) => BrandConfig.placeholder.name,
        theme: buildTheme(BrandConfig.placeholder, Brightness.light),
        darkTheme: buildTheme(BrandConfig.placeholder, Brightness.dark),
        themeMode: theme.mode,
        themeAnimationDuration: const Duration(milliseconds: 280),
        themeAnimationCurve: Motion.ease,
        locale: locale.locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          T.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: session.signedIn ? const Shell() : LanguageWelcome(locale: locale, child: const IntroScreen()),
      ),
    ),
  );
}
