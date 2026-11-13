import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/member.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'outbox.dart';
import 'state.dart';

/// The partner app shares the Dahae palette but leads with ink (customer app: dark teal),
/// so pros never confuse the two.
const partnerBrand = BrandConfig(
  name: '다해 파트너',
  primary: Color(0xFF17232C),
  primaryDeep: Color(0xFF0B1217),
  fresh: Color(0xFF1E9EBA),
  sun: Color(0xFFFFD95A),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'partner');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  final locale = LocaleController();
  final theme = ThemeController();
  await Future.wait([session.restore(), locale.restore(), theme.restore()]);
  await PushService.init();
  runApp(
    PartnerApp(
      session: session,
      app: PartnerState(
        api,
        Realtime(api),
        outbox: await CompletionOutbox.open(),
      ),
      locale: locale,
      theme: theme,
    ),
  );
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({
    super.key,
    required this.session,
    required this.app,
    required this.locale,
    required this.theme,
  });
  final Session session;
  final PartnerState app;
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
        builder: (context, child) => DesktopColumn(
          child: UpdateGate(
            api: session.api,
            app: 'partner',
            child: RemoteConfigGate(
              api: session.api,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
        onGenerateTitle: (_) => partnerBrand.name,
        theme: buildTheme(partnerBrand, Brightness.light),
        darkTheme: buildTheme(partnerBrand, Brightness.dark),
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
        home: !session.signedIn
            ? const PartnerIntro()
            : session.role == 'member'
            ? const MemberShell()
            : const Gate(),
      ),
    ),
  );
}
