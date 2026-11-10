/// Design system shared by the customer, partner and console apps.
///
/// Surfaces: [AppCard], [GlassBar], [Depth] (per-theme elevation).
/// Touch: [Pressable] (spring + haptic), [Tilt3D] (perspective hover/drag).
/// Ambient: [AuroraBackground], [ParallaxField]. Motion: [SharedAxisPageTransitionsBuilder], [StaggerIn].
library;

export 'src/components/aurora.dart';
export 'src/components/basics.dart';
export 'src/components/celebrate.dart';
export 'src/components/depth.dart';
export 'src/components/glyph.dart';
export 'src/components/inputs.dart';
export 'src/components/interactive.dart';
export 'src/components/motion.dart';
export 'src/theme.dart';
export 'src/tokens.dart';
