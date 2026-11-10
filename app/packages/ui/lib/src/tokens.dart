import 'package:flutter/material.dart';

/// Brand is data, not code: swap name, colors and logo here (or load from
/// config) and every app re-skins without touching a screen.
@immutable
class BrandConfig {
  const BrandConfig({
    required this.name,
    required this.primary,
    required this.primaryDeep,
    required this.fresh,
    required this.sun,
  });

  final String name;

  /// Trust blue: primary actions, links, selection.
  final Color primary;
  final Color primaryDeep;

  /// Fresh mint: success, "clean" moments, completion.
  final Color fresh;

  /// Warm sun: rewards, coupons, celebration. Never for text on white.
  final Color sun;

  static const placeholder = BrandConfig(
    name: '말끔',
    primary: Color(0xFF3B5BFD),
    primaryDeep: Color(0xFF2A44D6),
    fresh: Color(0xFF12B48F),
    sun: Color(0xFFFFB400),
  );
}

/// Neutral ink scale. Text always uses ink; color carries meaning, not prose.
abstract final class Neutral {
  static const c900 = Color(0xFF111827);
  static const c700 = Color(0xFF374151);
  static const c500 = Color(0xFF5B6472); // 5.9:1 on white
  static const c400 = Color(0xFF8A929F); // decorative / disabled only
  static const c300 = Color(0xFFD3D7DE);
  static const c200 = Color(0xFFE7EAEE);
  static const c100 = Color(0xFFF2F4F7);
  static const c50 = Color(0xFFF8F9FB);
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
  static const studio = ServiceHue(Color(0xFFFFF3D6), Color(0xFFB86E00), Color(0xFF3A2D10));
  static const kitchen = ServiceHue(Color(0xFFFFE9E3), Color(0xFFD2432C), Color(0xFF3B1E18));
  static const bathroom = ServiceHue(Color(0xFFE2F0FF), Color(0xFF1668D6), Color(0xFF14263E));
  static const mattress = ServiceHue(Color(0xFFEEE9FF), Color(0xFF5E3FD6), Color(0xFF241C40));
  static const aircon = ServiceHue(Color(0xFFDDF6FA), Color(0xFF0B8AA3), Color(0xFF102E35));
  static const sofa = ServiceHue(Color(0xFFFFE6F0), Color(0xFFC72D6C), Color(0xFF3A1626));
  static const moveOut = ServiceHue(Color(0xFFDBF5EC), Color(0xFF0B8A6B), Color(0xFF0F2F27));
  static const moveIn = ServiceHue(Color(0xFFE7F6DA), Color(0xFF3E8A12), Color(0xFF1C2E10));

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
  static const consultation = ServiceHue(Color(0xFFFFF1D1), Color(0xFF8A5600), Color(0xFF3A2D10));
  static const confirmed = ServiceHue(Color(0xFFE6ECFF), Color(0xFF2A44D6), Color(0xFF1A2347));
  static const assigned = ServiceHue(Color(0xFFDDF5EE), Color(0xFF07725A), Color(0xFF0F2F27));
  static const completed = ServiceHue(Color(0xFFEEF0F3), Color(0xFF374151), Color(0xFF262B33));
  static const cancelled = ServiceHue(Color(0xFFFDE8E8), Color(0xFFB42318), Color(0xFF3B1818));

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
  static const danger = Color(0xFFD92D20);
  static const sunday = Color(0xFFD92D20);
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
  static const tile = 18.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const route = Duration(milliseconds: 300);
  static const celebrate = Duration(milliseconds: 520);
  static const ease = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1);
}

abstract final class Elevation {
  static const card = [BoxShadow(color: Color(0x0D111827), blurRadius: 2, offset: Offset(0, 1))];
  static const raised = [
    BoxShadow(color: Color(0x14111827), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A111827), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const sheet = [BoxShadow(color: Color(0x29111827), blurRadius: 40, offset: Offset(0, -8))];
}

abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;
}
