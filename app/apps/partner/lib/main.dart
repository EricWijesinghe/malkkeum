import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/auth.dart';
import 'screens/shell.dart';
import 'state.dart';

/// The partner app shares the design system but leads with ink + fresh mint,
/// so pros never confuse it with the customer app.
const partnerBrand = BrandConfig(
  name: '말끔 파트너',
  primary: Color(0xFF111827),
  primaryDeep: Color(0xFF000000),
  fresh: Color(0xFF12B48F),
  sun: Color(0xFFFFB400),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'partner');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  final locale = LocaleController();
  await Future.wait([session.restore(), locale.restore()]);
  runApp(PartnerApp(session: session, app: PartnerState(api, Realtime(api)), locale: locale));
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key, required this.session, required this.app, required this.locale});
  final Session session;
  final PartnerState app;
  final LocaleController locale;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([locale, session]),
        builder: (context, _) => Deps(
          app: app,
          session: session,
          locale: locale,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (_) => partnerBrand.name,
            theme: buildTheme(partnerBrand, Brightness.light),
            darkTheme: buildTheme(partnerBrand, Brightness.dark),
            locale: locale.locale,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [T.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            home: session.signedIn ? const Gate() : const PartnerIntro(),
          ),
        ),
      );
}
