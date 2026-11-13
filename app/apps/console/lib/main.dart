import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui/ui.dart';

import 'screens/first_run.dart';
import 'server_address.dart';
import 'shell.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = LocaleController();
  final theme = ThemeController();
  const store = ServerAddressStore();
  await Future.wait([locale.restore(), theme.restore()]);
  // Web (same origin) and builds with API_BASE compiled in never ask; a sideloaded release APK asks once.
  final base = needsServerAddress ? await store.read() : defaultApiBase();
  runApp(ServerGate(initial: base, store: store, locale: locale, theme: theme));
}

/// Shows the server-address screen until an address is known, then the console for that address.
class ServerGate extends StatefulWidget {
  const ServerGate({
    super.key,
    required this.initial,
    required this.store,
    required this.locale,
    required this.theme,
  });
  final String? initial;
  final ServerAddressStore store;
  final LocaleController locale;
  final ThemeController theme;

  @override
  State<ServerGate> createState() => _ServerGateState();
}

class _ServerGateState extends State<ServerGate> {
  late String? _base = widget.initial;
  ConsoleApp? _app;

  Future<ConsoleApp> _build(String base) async {
    final session = Session(namespace: 'console');
    final api = ApiClient(baseUrl: base, session: session);
    await session.restore();
    return ConsoleApp(
      session: session,
      state: ConsoleState(api, Realtime(api), session),
      locale: widget.locale,
      theme: widget.theme,
      onChangeServer: needsServerAddress ? _change : null,
    );
  }

  Future<void> _save(String origin) async {
    await widget.store.write(origin);
    final app = await _build(origin);
    if (mounted) {
      setState(() {
        _base = origin;
        _app = app;
      });
    }
  }

  Future<void> _change() async {
    await widget.store.clear();
    if (mounted) {
      setState(() {
        _base = null;
        _app = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final base = _base;
    if (base != null) {
      _build(base).then((app) {
        if (mounted) setState(() => _app = app);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_base == null) {
      return _shell(ServerAddressScreen(onSaved: _save));
    }
    return _app ?? const SizedBox.shrink();
  }

  Widget _shell(Widget home) => ListenableBuilder(
    listenable: Listenable.merge([widget.locale, widget.theme]),
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(BrandConfig.placeholder, Brightness.light),
      darkTheme: buildTheme(BrandConfig.placeholder, Brightness.dark),
      themeMode: widget.theme.mode,
      locale: widget.locale.locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        T.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
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
    this.onChangeServer,
  });
  final VoidCallback? onChangeServer;
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
      child: ServerChange(
        onChange: onChangeServer,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              DesktopColumn(child: child ?? const SizedBox.shrink()),
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
          home: session.signedIn ? const ConsoleShell() : const ConsoleEntry(),
        ),
      ),
    ),
  );
}
