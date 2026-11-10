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
  await Future.wait([session.restore(), locale.restore()]);
  runApp(ConsoleApp(session: session, state: ConsoleState(api, Realtime(api), session), locale: locale));
}

class ConsoleApp extends StatelessWidget {
  const ConsoleApp({super.key, required this.session, required this.state, required this.locale});
  final Session session;
  final ConsoleState state;
  final LocaleController locale;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([locale, session]),
        builder: (context, _) => Deps(
          state: state,
          session: session,
          locale: locale,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (c) => '${BrandConfig.placeholder.name} ${T.of(c).cTitle}',
            theme: buildTheme(BrandConfig.placeholder, Brightness.light),
            darkTheme: buildTheme(BrandConfig.placeholder, Brightness.dark),
            locale: locale.locale,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [T.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            home: session.signedIn ? const ConsoleShell() : const LoginScreen(),
          ),
        ),
      );
}
