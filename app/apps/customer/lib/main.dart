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
  final analytics = Analytics(
    send: (body) async => api.post('/events', body),
    platform: kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
    anonId: await Analytics.loadOrCreateAnonId(),
  );
  final app = AppState(api, Realtime(api), analytics: analytics);
  runApp(
    CustomerApp(
      session: session,
      app: app,
      locale: locale,
      theme: theme,
    ),
  );
  analytics.start();
  // Consent is read from the server; app_open is sent only once it is known.
  app.syncAnalyticsConsent().then((_) => analytics.track('app_open'));
  // Push (Firebase, local notifications) after the first frame: keeps cold start fast.
  // A launch tap that arrives before Shell listens is kept by PushService until taken.
  WidgetsBinding.instance.addPostFrameCallback((_) => PushService.init().ignore());
}

/// Dynamic Type / font scale ceiling: layouts are tested up to 2.0x, beyond that they break.
const maxTextScale = 2.0;

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
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxTextScale,
          child: DesktopColumn(
            child: UpdateGate(
              api: session.api,
              app: 'customer',
              child: RemoteConfigGate(api: session.api, child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
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
        home: session.signedIn
            ? const Shell()
            : LanguageWelcome(locale: locale, child: const IntroScreen()),
      ),
    ),
  );
}
