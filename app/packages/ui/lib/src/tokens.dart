import 'package:flutter/material.dart';

/// Brand is data, not code: swap name, colors and logo here (or load from
/// config) and every app re-skins without touching a screen.
///
/// Dahae palette usage rules (contrast ratios in palette/theme contrast tests):
/// - Body text is [ink]; secondary text is the theme's `inkMuted`. Links and
///   inline price emphasis use [primary] (dark teal, 4.98:1 on white).
/// - [fresh] (brand teal #1E9EBA) is 3.16:1 on white: icons, borders, fills and
///   large text (>= 24px, or >= 19px bold) only, never body text.
/// - Primary button: fill [primary], white label; pressed [primaryDeep].
/// - Accent CTA (welcome coupon, pay deposit): fill [sun], label [ink] (11.67:1).
///   [sun] is never text on a light surface (1.37:1).
@immutable
class BrandConfig {
  const BrandConfig({
    required this.name,
    required this.primary,
    required this.primaryDeep,
    required this.fresh,
    required this.sun,
    this.ink = const Color(0xFF17232C),
    this.logoUrl,
  });

  final String name;

  /// Dark teal: primary actions, links, selection. Text-safe on light surfaces.
  final Color primary;

  /// Pressed state and gradient end.
  final Color primaryDeep;

  /// Brand teal: decorative fills, icons, large text, success wash.
  final Color fresh;

  /// Check yellow: coupons, highlights, the checkmark. Never text on light.
  final Color sun;

  /// Ink: body text and dark surfaces.
  final Color ink;

  /// Uploaded logo image (absolute URL) from the business profile; null shows the built-in mark.
  final String? logoUrl;

  static const placeholder = BrandConfig(
    name: '다해',
    primary: Color(0xFF187A8F),
    primaryDeep: Color(0xFF12606F),
    fresh: Color(0xFF1E9EBA),
    sun: Color(0xFFFFD95A),
    ink: Color(0xFF17232C),
  );
}

/// Neutral ink scale. Text always uses ink; color carries meaning, not prose.
abstract final class Neutral {
  static const c900 = Color(0xFF17232C);
  static const c700 = Color(0xFF3A4A55);
  static const c500 = Color(0xFF5A6B76); // 5.53:1 on white
  static const c400 = Color(0xFF8C9AA3); // decorative / disabled only
  static const c300 = Color(0xFFCDD6DB);
  static const c200 = Color(0xFFE3E9EC);
  static const c100 = Color(0xFFF0F4F6);
  static const c50 = Color(0xFFF7FAFB);
}

/// Each service owns a hue so customers recognise it at a glance
/// (tile, icon, header wash, chat card). Tint = background, tone = icon/text.
@immutable
class ServiceHue {
  const ServiceHue(this.tint, this.tone, this.darkTint);
  final Color tint;
  final Color tone;
  final Color darkTint;
}

abstract final class ServiceHues {
  // Tone = text/icon on tint, >= 4.5:1 (palette_contrast_test.dart).
  static const studio = ServiceHue(
    Color(0xFFFFF3D6),
    Color(0xFF9E5F00),
    Color(0xFF3A2D10),
  );
  static const kitchen = ServiceHue(
    Color(0xFFFFE9E3),
    Color(0xFFBF3D28),
    Color(0xFF3B1E18),
  );
  static const bathroom = ServiceHue(
    Color(0xFFE2F0FF),
    Color(0xFF1668D6),
    Color(0xFF14263E),
  );
  static const mattress = ServiceHue(
    Color(0xFFEEE9FF),
    Color(0xFF5E3FD6),
    Color(0xFF241C40),
  );
  static const aircon = ServiceHue(
    Color(0xFFDDF6FA),
    Color(0xFF09768B),
    Color(0xFF102E35),
  );
  static const sofa = ServiceHue(
    Color(0xFFFFE6F0),
    Color(0xFFC12C69),
    Color(0xFF3A1626),
  );
  static const moveOut = ServiceHue(
    Color(0xFFDBF5EC),
    Color(0xFF0A795E),
    Color(0xFF0F2F27),
  );
  static const moveIn = ServiceHue(
    Color(0xFFE7F6DA),
    Color(0xFF377A10),
    Color(0xFF1C2E10),
  );

  static ServiceHue of(String code) => switch (code) {
    'studio' => studio,
    'kitchen' => kitchen,
    'bathroom' => bathroom,
    'mattress' => mattress,
    'aircon' => aircon,
    'sofa' => sofa,
    'move_out' => moveOut,
    'move_in' => moveIn,
    _ => bathroom,
  };
}

/// Booking status colors (0-3, -1). Text tones all pass 4.5:1 on their tint.
abstract final class StatusHues {
  static const consultation = ServiceHue(
    Color(0xFFFFF6D6),
    Color(0xFF8A6400),
    Color(0xFF3A3214),
  );
  static const confirmed = ServiceHue(
    Color(0xFFE3F4F8),
    Color(0xFF136B7E),
    Color(0xFF123642),
  );
  static const assigned = ServiceHue(
    Color(0xFFDDF5EC),
    Color(0xFF0E7A55),
    Color(0xFF0F2F27),
  );
  static const completed = ServiceHue(
    Color(0xFFEEF0F3),
    Color(0xFF374151),
    Color(0xFF262B33),
  );
  static const cancelled = ServiceHue(
    Color(0xFFFDE8E8),
    Color(0xFFB42318),
    Color(0xFF3B1818),
  );

  static ServiceHue of(int status) => switch (status) {
    0 => consultation,
    1 => confirmed,
    2 => assigned,
    3 => completed,
    _ => cancelled,
  };
}

/// Fixed semantic colors (not brand): errors and weekend markers.
abstract final class Semantic {
  static const danger = Color(0xFFC8321F);
  static const sunday = Color(0xFFC8321F);
  static const saturday = Color(0xFF2A44D6);
}

abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const gutter = 20.0;
}

abstract final class Radii {
  static const chip = 10.0;
  static const input = 14.0;
  static const card = 20.0;
  static const tile = 16.0;
  static const sheet = 28.0;
  static const pill = 999.0;

  /// Clay plate behind a 3D icon fallback (same ratio as the old ServiceGlyph).
  static double icon3dPlate(double size) => size * 0.32;
}

abstract final class Motion {
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const route = Duration(milliseconds: 300);
  static const celebrate = Duration(milliseconds: 520);
  static const ease = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1);
  static const press = Duration(milliseconds: 90);

  /// 3D icon pop when it becomes active (nav tab, selected tile).
  static const iconPop = Duration(milliseconds: 320);

  /// Spring for the icon pop/bounce: a little overshoot, settles fast.
  static const iconBounce = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 18,
  );

  /// Max pointer tilt for 3D icons, radians (~8 degrees).
  static const iconTiltMax = 0.14;
  static const activeScale = 1.12;
  static const pressScale = 0.92;

  /// Idle loop for hero/grid 3D icons (`Icon3D(idle:)`): one full float or sway cycle.
  static const idlePeriod = Duration(milliseconds: 3200);

  /// Idle float height as a fraction of the icon size.
  static const idleLift = 0.035;

  /// Idle sway angle, radians (~2 degrees).
  static const idleSway = 0.035;

  /// Spring velocity of one `Icon3D(attention:)` kick: peaks near 1.08x, settles in ~350 ms.
  static const attentionKick = 3.0;

  /// Material fade-through: outgoing fades for [fadeOut], incoming for [fadeIn] after it.
  static const fadeOut = Duration(milliseconds: 90);
  static const fadeIn = Duration(milliseconds: 210);

  /// Progress fills ([ProgressLine]) and the success halo.
  static const progress = Duration(milliseconds: 600);

  /// One play of the 24-frame 3D logo (`DahaeLogo(animate: true)`).
  static const logoPlay = Duration(milliseconds: 720);
}

abstract final class Elevation {
  static const card = [
    BoxShadow(color: Color(0x0D17232C), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1417232C), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A17232C), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x2917232C), blurRadius: 40, offset: Offset(0, -8)),
  ];

  /// Soft coloured contact shadow under a 3D icon of [size] dp.
  static List<BoxShadow> icon3d(Color hue, double size) => [
    BoxShadow(
      color: hue.withValues(alpha: 0.28),
      blurRadius: size * 0.30,
      offset: Offset(0, size * 0.14),
      spreadRadius: -size * 0.04,
    ),
  ];
}

abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;
}
