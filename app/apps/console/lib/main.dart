import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/login.dart';
import 'shell.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'console');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  final locale = LocaleController();
  final theme = ThemeController();
  await Future.wait([session.restore(), locale.restore(), theme.restore()]);
  runApp(
    ConsoleApp(
      session: session,
      state: ConsoleState(api, Realtime(api), session),
      locale: locale,
      theme: theme,
    ),
  );
}

class ConsoleApp extends StatelessWidget {
  const ConsoleApp({
    super.key,
    required this.session,
    required this.state,
    required this.locale,
    required this.theme,
  });
  final Session session;
  final ConsoleState state;
  final LocaleController locale;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([locale, session, theme]),
    builder: (context, _) => Deps(
      state: state,
      session: session,
      locale: locale,
      theme: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (c) =>
            '${BrandConfig.placeholder.name} ${T.of(c).cTitle}',
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
        home: session.signedIn ? const ConsoleShell() : const LoginScreen(),
      ),
    ),
  );
}
