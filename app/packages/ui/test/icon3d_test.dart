import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// An asset bundle with no files: every Icon3D falls back to its clay plate.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('missing $key');
}

final _empty = _EmptyBundle();
// Built once: a fresh ThemeData per pump would start an AnimatedTheme lerp (a ticker).
final _themes = {
  for (final b in Brightness.values) b: buildTheme(BrandConfig.placeholder, b),
};

/// [empty]: no art at all (fallback path). Otherwise the real bundle, whose
/// decodes never finish under fake async, so no load errors on idle/active swaps.
Widget _app(
  Widget child, {
  bool reduce = false,
  bool empty = true,
  Brightness b = Brightness.light,
}) => MaterialApp(
  theme: _themes[b],
  builder: (ctx, c) {
    final media = MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: reduce),
      child: c!,
    );
    return empty ? DefaultAssetBundle(bundle: _empty, child: media) : media;
  },
  home: Scaffold(body: Center(child: child)),
);

double _scaleOf(WidgetTester tester, String id) {
  final t = find.descendant(
    of: find.byWidgetPredicate((w) => w is Icon3D && w.id == id),
    matching: find.byType(Transform),
  );
  if (t.evaluate().isEmpty) return 1;
  return tester.widget<Transform>(t.first).transform.getMaxScaleOnAxis();
}

void main() {
  test('registry covers every plan §4 id and aliases resolve to real ids', () {
    const required = [
      'nav_home',
      'nav_bookings',
      'nav_chat',
      'nav_more',
      'svc_studio',
      'svc_move',
      'svc_move_in',
      'svc_move_out',
      'svc_bathroom',
      'svc_kitchen',
      'svc_mattress',
      'svc_aircon',
      'svc_sofa',
      'svc_whole_home',
      'svc_window',
      'svc_disinfection',
      'rec_move_combo',
      'banner_coupon',
      'news_megaphone',
      'tip_bulb',
      'notice_pin',
      'faq_bubble',
      'step_consult',
      'step_confirmed',
      'step_matched',
      'step_completed',
      'status_cancelled',
      'scope_dusting',
      'scope_vacuum',
      'scope_dishes',
      'scope_bathroom',
      'scope_trash',
      'tool_vacuum',
      'tool_mop',
      'tool_trash',
      'tool_gloves',
      'tool_cloth',
      'tool_sponge',
      'tool_spray',
      'ac_wall',
      'ac_stand',
      'ac_two_in_one',
      'ac_ceiling',
      'box_empty',
      'box_partial',
      'box_full',
      'box_unknown',
      'type_normal_move_in',
      'type_after_interior',
      'type_lived_in',
      'type_standard',
      'type_same_day',
      'type_some_luggage',
      'bld_apartment',
      'bld_villa',
      'bld_commercial',
      'bld_officetel',
      'bld_house',
      'bld_other',
      'room_studio',
      'room_one_half',
      'room_two',
      'room_three',
      'room_four_plus',
      'duplex_stairs',
      'cnt_bathroom',
      'cnt_balcony',
      'elev_yes',
      'elev_no',
      'ui_calendar',
      'ui_clock',
      'slot_am',
      'slot_pm',
      'ui_coupon',
      'ui_points',
      'ui_pin',
      'ui_bell',
      'promo_ac_addon',
      'chat_new',
      'chat_team_avatar',
      'chat_quote',
      'chat_hours',
      'pay_card',
      'pay_wallet',
      'pay_bank',
      'pay_virtual',
      'menu_scope',
      'menu_payments',
      'menu_addresses',
      'menu_account',
      'menu_notices',
      'menu_tips',
      'menu_faq',
      'menu_contact',
      'menu_version',
      'menu_coupons',
      'confirm_check',
      'logo_3d',
      'empty_inbox',
      'error_offline',
      'p_nav_jobs',
      'p_nav_quotes',
      'p_nav_schedule',
      'p_camera',
      'p_verified',
      'p_payout',
      'c_dashboard',
      'c_bookings',
      'c_quotes',
      'c_chat',
      'c_pricing',
      'c_marketing',
      'c_partners',
      'c_payments',
      'c_payouts',
      'c_subscriptions',
      'c_customers',
      'c_staff',
      'c_settings',
      'c_monitor',
    ];
    for (final id in required) {
      expect(Icon3DRegistry.has(id), isTrue, reason: id);
    }
    for (final e in Icon3DRegistry.specs.entries) {
      final alias = e.value.alias;
      if (alias != null) {
        expect(Icon3DRegistry.has(alias), isTrue, reason: e.key);
      }
    }
    expect(Icon3DRegistry.assetFor('nav_home'), 'assets/icons3d/nav_home.webp');
    expect(
      Icon3DRegistry.assetFor('nav_home', idle: true),
      'assets/icons3d/nav_home_idle.webp',
    );
    expect(
      Icon3DRegistry.assetFor('svc_studio', idle: true),
      'assets/icons3d/svc_studio.webp',
    );
    expect(
      Icon3DRegistry.assetFor('menu_tips'),
      'assets/icons3d/menu_tips.webp',
    );
    // Hero sizes read the 160dp large set; small sizes the 64dp set.
    expect(
      Icon3DRegistry.assetFor('confirm_check', size: 160),
      'assets/icons3d/large/confirm_check.webp',
    );
    expect(
      Icon3DRegistry.assetFor('confirm_check', size: 48),
      'assets/icons3d/confirm_check.webp',
    );
    expect(
      Icon3DRegistry.assetFor('nav_home', size: 200),
      'assets/icons3d/nav_home.webp',
    );
  });

  test(
    'every registered id ships art (except the optional second menu group)',
    () {
      const optional = {
        'menu_language',
        'menu_licenses',
        'menu_partner',
        'menu_privacy',
        'menu_subscriptions',
        'menu_terms',
        'menu_theme',
      };
      for (final e in Icon3DRegistry.specs.entries) {
        if (optional.contains(e.key)) continue;
        expect(
          File(Icon3DRegistry.assetFor(e.key)).existsSync(),
          isTrue,
          reason: e.key,
        );
        if (e.value.hasIdle) {
          expect(
            File(Icon3DRegistry.assetFor(e.key, idle: true)).existsSync() ||
                e.key.startsWith('p_'),
            isTrue,
            reason: '${e.key} idle',
          );
        }
        if (e.value.large) {
          expect(
            File(Icon3DRegistry.assetFor(e.key, size: 160)).existsSync(),
            isTrue,
            reason: '${e.key} large',
          );
        }
      }
    },
  );

  test(
    'every 2.0x/3.0x icon has its 1x main file (else it is never bundled)',
    () {
      final mains = {
        for (final f in Directory(
          'assets/icons3d',
        ).listSync().whereType<File>())
          f.uri.pathSegments.last,
      };
      for (final density in ['2.0x', '3.0x']) {
        final sub = Directory('assets/icons3d/$density');
        if (!sub.existsSync()) continue;
        for (final f in sub.listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          expect(mains, contains(name), reason: '$density/$name');
        }
      }
    },
  );

  testWidgets(
    'missing art falls back to the clay plate with the registry glyph',
    (tester) async {
      for (final b in Brightness.values) {
        await tester.pumpWidget(
          _app(const Icon3D('svc_kitchen', size: 56), b: b),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Clay3DPlate), findsOneWidget);
        expect(find.byIcon(serviceIcon('kitchen')), findsOneWidget);
        expect(tester.getSize(find.byType(Icon3D)), const Size(56, 56));
      }
      // Unknown id: neutral plate, no throw.
      await tester.pumpWidget(_app(const Icon3D('nope')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Clay3DPlate), findsOneWidget);
    },
  );

  testWidgets('active pops to 1.12 and settles; inactive returns to 1', (
    tester,
  ) async {
    Widget icon(bool on) =>
        _app(Icon3D('nav_home', active: on, size: 28), empty: false);
    await tester.pumpWidget(icon(false));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester, 'nav_home'), 1);

    await tester.pumpWidget(icon(true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    // The spring overshoots (the bounce) before it settles.
    var peak = 0.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final s = _scaleOf(tester, 'nav_home');
      if (s > peak) peak = s;
    }
    expect(peak, greaterThan(Motion.activeScale));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester, 'nav_home'), closeTo(Motion.activeScale, 1e-3));

    await tester.pumpWidget(icon(false));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester, 'nav_home'), closeTo(1, 1e-3));
  });

  testWidgets('reduced motion: no ticker, no transform, identical frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Icon3D('nav_chat', size: 28), reduce: true, empty: false),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        const Icon3D('nav_chat', active: true, size: 28, tilt: true),
        reduce: true,
        empty: false,
      ),
    );
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    expect(tester.hasRunningAnimations, isFalse);
    for (final type in [Transform, AnimatedBuilder, Listener]) {
      expect(
        find.descendant(of: find.byType(Icon3D), matching: find.byType(type)),
        findsNothing,
        reason: '$type',
      );
    }
    final before = tester
        .renderObject<RenderBox>(find.byType(Icon3D))
        .localToGlobal(Offset.zero);
    final g = await tester.press(find.byType(Icon3D));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      tester
          .renderObject<RenderBox>(find.byType(Icon3D))
          .localToGlobal(Offset.zero),
      before,
    );
  });

  testWidgets(
    'semantics label, decorative by default, 48dp target when tappable',
    (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon3D('ui_pin', size: 24),
              Icon3D(
                'ui_bell',
                size: 24,
                semanticLabel: 'Notifications',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      final bell = find.byWidgetPredicate(
        (w) => w is Icon3D && w.id == 'ui_bell',
      );
      final size = tester.getSize(bell);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(bell);
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    },
  );

  testWidgets('disabled icon renders greyscale and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(Icon3D('ui_coupon', enabled: false, onTap: () => taps++)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsOneWidget);
    await tester.tap(find.byType(Icon3D));
    expect(taps, 0);
  });

  testWidgets(
    'DahaeLogo flat, mono and 3D (fallback) render with the brand label',
    (tester) async {
      for (final v in DahaeLogoVariant.values) {
        await tester.pumpWidget(
          _app(DahaeLogo(variant: v, size: 64, wordmark: true)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.bySemanticsLabel(BrandConfig.placeholder.name),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'SuccessMark without art paints the fallback and settles; reduced motion is instant',
    (tester) async {
      await tester.pumpWidget(_app(const SuccessMark()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpWidget(
        _app(const SuccessMark(key: ValueKey('r')), reduce: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
