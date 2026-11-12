import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildTheme(BrandConfig.placeholder, Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('EmptyState shows the 3D art instead of the glyph cluster when given an id', (tester) async {
    await tester.pumpWidget(_app(const EmptyState(icon: Icons.inbox, art: 'p_verified', title: 'Pending')));
    expect(find.byWidgetPredicate((w) => w is Icon3D && w.id == 'p_verified'), findsOneWidget);
    expect(find.byType(ServiceGlyph), findsNothing);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('EmptyState keeps the glyph cluster without art', (tester) async {
    await tester.pumpWidget(_app(const EmptyState(icon: Icons.inbox, title: 'Empty')));
    expect(find.byType(ServiceGlyph), findsNWidgets(3));
  });
}
