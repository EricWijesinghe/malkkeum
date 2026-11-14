/// Design system shared by the customer, partner and console apps.
///
/// Surfaces: [AppCard], [GlassBar], [Depth] (per-theme elevation).
/// Touch: [Pressable] (spring + haptic), [Tilt3D] (perspective hover/drag).
/// Ambient: [AuroraBackground], [ParallaxField]. Motion: [Depth3DPageTransitionsBuilder], [StaggerIn], [FlipIn].
/// Cards and data: [ServiceCard3D], [EarningsSparkline], [SkeletonList].
/// Brand: [DahaeLogo], [Icon3D] (art by id from [Icon3DRegistry], clay fallback).
/// Modern: [SegmentedControl], [RatingStars], [AvatarRing], [PriceTag], [CountUp], [EnterMotion].
library;

export 'src/components/aurora.dart';
export 'src/components/basics.dart';
export 'src/components/celebrate.dart';
export 'src/components/depth.dart';
export 'src/components/flip.dart';
export 'src/components/glyph.dart';
export 'src/components/icon3d.dart';
export 'src/components/icon3d_registry.dart';
export 'src/components/inputs.dart';
export 'src/components/interactive.dart';
export 'src/components/logo.dart';
export 'src/components/modern.dart';
export 'src/components/motion.dart';
export 'src/brand_scope.dart';
export 'src/components/service_card.dart';
export 'src/components/sparkline.dart';
export 'src/contrast.dart';
export 'src/theme.dart';
export 'src/tokens.dart';
