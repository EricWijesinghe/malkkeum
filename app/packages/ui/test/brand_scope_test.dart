import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

const _custom = BrandConfig(
  name: 'Test Co',
  primary: Color(0xFF0B5D2A),
  primaryDeep: Color(0xFF07401C),
  fresh: Color(0xFF2E8B57),
  sun: Color(0xFFFFD95A),
);

void main() {
  test('contrast ratio matches WCAG for black on white', () {
    expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
  });

  test('white label text is allowed on dark brand colours only', () {
    expect(whiteTextReadsOn(BrandConfig.placeholder.primary), isTrue);
    expect(whiteTextReadsOn(_custom.primary), isTrue);
    expect(whiteTextReadsOn(const Color(0xFFFFD95A)), isFalse);
  });

  testWidgets('theme colours and the logo wordmark follow the BrandScope', (tester) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(_custom, Brightness.light),
        home: BrandScope(
          brand: _custom,
          child: Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return const DahaeLogo(wordmark: true);
            },
          ),
        ),
      ),
    );

    expect(scheme.primary, _custom.primary);
    expect(find.text('Test Co'), findsOneWidget);
  });

  testWidgets('outside a scope the built-in brand is used', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(BrandConfig.placeholder, Brightness.light),
        home: const DahaeLogo(wordmark: true),
      ),
    );

    expect(find.text(BrandConfig.placeholder.name), findsOneWidget);
  });
}
