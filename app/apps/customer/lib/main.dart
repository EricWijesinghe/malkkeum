import 'dart:async';
import 'dart:developer' as developer;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/shell.dart';
import 'state.dart';

/// Kept for the app's lifetime. Customer surfaces are labelled by platform (client_errors.rs APPS).
final _errors = ErrorReporter(app: analyticsPlatform());

void main() => ErrorReporter.run(_errors, _start);

Future<void> _start() async {
  final boot = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'customer');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  _errors.send = (body) async => api.post('/client-errors', body);
  final locale = LocaleController();
  final theme = ThemeController(initial: ThemeMode.system);
  final brand = BrandController(api: api, fallback: BrandConfig.placeholder);
  await Future.wait([session.restore(), locale.restore(), theme.restore(), brand.restore()]);
  // One refresh now instead of a 401 on every first screen call.
  api.warmUp().ignore();
  // The business's colours and logo; the saved brand paints until this answers (and stays if offline).
  brand.refresh().ignore();
  final restored = boot.elapsedMilliseconds;
  final analytics = Analytics(
    send: (body) async => api.post('/events', body),
    platform: analyticsPlatform(),
    anonId: await Analytics.loadOrCreateAnonId(),
  );
  final app = AppState(api, Realtime(api), analytics: analytics);
  runApp(CustomerApp(session: session, app: app, locale: locale, theme: theme, brand: brand));
  analytics.start();
  // Back from the background: a fresh socket (its resync makes screens refetch). Leaving: send queued events.
  Foreground(onResume: app.realtime.reconnect, onHide: () => analytics.flush().ignore());
  // Consent is read from the server; app_open is sent only once it is known.
  unawaited(app.syncAnalyticsConsent().then((_) => analytics.track('app_open')));
  // Push (Firebase, local notifications) after the first frame: keeps cold start fast.
  // A launch tap that arrives before Shell listens is kept by PushService until taken.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    developer.log(
      'restore ${restored}ms, first frame ${boot.elapsedMilliseconds}ms',
      name: 'startup',
    );
    PushService.init().ignore();
  });
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
    this.brand,
  });
  final Session session;
  final AppState app;
  final LocaleController locale;
  final ThemeController theme;
  final BrandController? brand;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([locale, session, theme, brand]),
    builder: (context, _) => BrandScope(
      brand: brand?.brand ?? BrandConfig.placeholder,
      child: Deps(
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
          onGenerateTitle: (c) => (brand?.brand ?? BrandConfig.placeholder).name,
          theme: buildTheme(brand?.brand ?? BrandConfig.placeholder, Brightness.light),
          darkTheme: buildTheme(brand?.brand ?? BrandConfig.placeholder, Brightness.dark),
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
          // Guests land straight in the app; sign-in is asked only when a protected action needs it.
          home: const Shell(),
        ),
      ),
    ),
  );
}
