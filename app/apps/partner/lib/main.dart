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

/// Kept for the app's lifetime (client_errors.rs APPS: partner_android, partner_ios).
final _errors = ErrorReporter(app: 'partner_${analyticsPlatform()}');

void main() => ErrorReporter.run(_errors, _start);

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(namespace: 'partner');
  final api = ApiClient(baseUrl: defaultApiBase(), session: session);
  _errors.send = (body) async => api.post('/client-errors', body);
  final locale = LocaleController();
  final theme = ThemeController();
  final brand = BrandController(api: api, fallback: partnerBrand);
  await Future.wait([session.restore(), locale.restore(), theme.restore(), brand.restore()]);
  // One refresh now instead of a 401 on every first screen call.
  api.warmUp().ignore();
  // The business's colours and logo; the saved brand paints until this answers (and stays if offline).
  brand.refresh().ignore();
  final app = PartnerState(api, Realtime(api), outbox: await CompletionOutbox.open());
  runApp(PartnerApp(session: session, app: app, locale: locale, theme: theme, brand: brand));
  // Back from the background: a fresh socket; its resync reloads jobs and drains the outbox.
  Foreground(onResume: app.realtime.reconnect);
  // Push (Firebase, launch tap) after the first frame, as in the customer app: keeps cold start fast.
  // A launch tap that arrives before the shell listens is kept by PushService until taken.
  WidgetsBinding.instance.addPostFrameCallback((_) => PushService.init().ignore());
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({
    super.key,
    required this.session,
    required this.app,
    required this.locale,
    required this.theme,
    this.brand,
  });
  final Session session;
  final PartnerState app;
  final LocaleController locale;
  final ThemeController theme;
  final BrandController? brand;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([locale, session, theme, brand]),
    builder: (context, _) => BrandScope(
      brand: brand?.brand ?? partnerBrand,
      child: Deps(
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
              child: RemoteConfigGate(api: session.api, child: child ?? const SizedBox.shrink()),
            ),
          ),
          onGenerateTitle: (_) => (brand?.brand ?? partnerBrand).name,
          theme: buildTheme(brand?.brand ?? partnerBrand, Brightness.light),
          darkTheme: buildTheme(brand?.brand ?? partnerBrand, Brightness.dark),
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
    ),
  );
}
