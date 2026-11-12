import 'package:flutter/widgets.dart';

import 'icon3d.dart';
import 'icon3d_registry.dart';

/// A catalog service's 3D icon (`svc_<code>`). Kept as its own widget so the
/// many call sites read naturally; the clay plate is [Icon3D]'s fallback.
class ServiceGlyph extends StatelessWidget {
  const ServiceGlyph(
    this.code, {
    super.key,
    this.size = 56,
    this.active = false,
  });
  final String code;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) =>
      Icon3D(Icon3DRegistry.serviceId(code), size: size, active: active);
}
