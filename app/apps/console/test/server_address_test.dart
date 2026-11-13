import 'package:console/server_address.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

void main() {
  group('parseServerAddress', () {
    test('release keeps https origins only', () {
      expect(
        parseServerAddress('https://dahae.example', release: true),
        'https://dahae.example',
      );
      expect(
        parseServerAddress('dahae.example/admin/', release: true),
        'https://dahae.example',
      );
      expect(
        parseServerAddress('  https://dahae.example:8443/x?y ', release: true),
        'https://dahae.example:8443',
      );
      expect(parseServerAddress('http://dahae.example', release: true), isNull);
      expect(
        parseServerAddress('http://192.168.0.5:8080', release: true),
        isNull,
      );
    });

    test('non-release also accepts http on loopback and RFC 1918 hosts', () {
      expect(
        parseServerAddress('http://192.168.0.5:8080', release: false),
        'http://192.168.0.5:8080',
      );
      expect(
        parseServerAddress('http://172.20.1.2', release: false),
        'http://172.20.1.2',
      );
      expect(
        parseServerAddress('http://localhost:8080', release: false),
        'http://localhost:8080',
      );
      expect(parseServerAddress('http://172.32.0.1', release: false), isNull);
      expect(
        parseServerAddress('http://dahae.example', release: false),
        isNull,
      );
    });

    test('rejects junk', () {
      for (final bad in [
        '',
        '   ',
        'a b',
        'ftp://x.example',
        'https://',
        'https://u:p@x.example',
      ]) {
        expect(parseServerAddress(bad, release: true), isNull, reason: bad);
      }
    });
  });

  testWidgets(
    'server address screen reports the normalised origin or shows the error',
    (tester) async {
      setViewport(tester, wideSize);
      String? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(BrandConfig.placeholder, Brightness.light),
          locale: const Locale('ko'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            T.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ServerAddressScreen(release: true, onSaved: (v) => saved = v),
        ),
      );
      await tester.enterText(find.byType(TextField), 'http://insecure.example');
      await tester.tap(find.widgetWithText(PrimaryButton, koT.cServerSave));
      await tester.pump();
      expect(saved, isNull);
      expect(find.text(koT.cServerInvalid), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'dahae.example');
      await tester.tap(find.widgetWithText(PrimaryButton, koT.cServerSave));
      await tester.pump();
      expect(saved, 'https://dahae.example');
    },
  );
}
