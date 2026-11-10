import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'gen/app_localizations.dart';
import 'i18n.dart';
import 'social_auth.dart';

/// Brand guide colors. Fixed on purpose: a provider's button keeps its look in both themes.
abstract final class SocialBrand {
  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoLabel = Color(0xFF000000);
  static const naverGreen = Color(0xFF03C75A);
  static const naverLabel = Color(0xFFFFFFFF);
  static const appleBlack = Color(0xFF000000);
  static const appleLabel = Color(0xFFFFFFFF);
  static const googleWhite = Color(0xFFFFFFFF);
  static const googleLabel = Color(0xFF1F1F1F);
  static const googleBorder = Color(0xFFDADCE0);
}

String _label(T t, String provider) => switch (provider) {
      SocialProviders.kakao => t.apLoginKakao,
      SocialProviders.naver => t.apLoginNaver,
      SocialProviders.google => t.apLoginGoogle,
      _ => t.apLoginApple,
    };

/// A brand-compliant sign-in button, 52px tall (well above the 48px target minimum).
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({super.key, required this.provider, required this.onPressed, this.busy = false});

  final String provider;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final label = _label(context.t, provider);
    final (bg, fg, border) = switch (provider) {
      SocialProviders.kakao => (SocialBrand.kakaoYellow, SocialBrand.kakaoLabel, null),
      SocialProviders.naver => (SocialBrand.naverGreen, SocialBrand.naverLabel, null),
      SocialProviders.google => (SocialBrand.googleWhite, SocialBrand.googleLabel, SocialBrand.googleBorder),
      _ => (SocialBrand.appleBlack, SocialBrand.appleLabel, null),
    };
    return Semantics(
      button: true,
      enabled: onPressed != null && !busy,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.5),
            disabledForegroundColor: fg.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input), side: border == null ? BorderSide.none : BorderSide(color: border)),
            elevation: 0,
          ),
          onPressed: busy ? null : onPressed,
          child: busy
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ExcludeSemantics(child: _mark(provider, fg)),
                  const SizedBox(width: Space.xs),
                  Flexible(child: Text(label, style: context.text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                ]),
        ),
      ),
    );
  }

  static Widget _mark(String provider, Color fg) => switch (provider) {
        SocialProviders.kakao => Icon(Icons.chat_bubble_rounded, size: 18, color: fg),
        SocialProviders.naver => Text('N', style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w900)),
        SocialProviders.google => const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 18, fontWeight: FontWeight.w900)),
        _ => const SizedBox(width: 18),
      };
}

/// The "간편 로그인" block: a divider, one button per provider, and a dev-only caption.
class SocialSignInRow extends StatelessWidget {
  const SocialSignInRow({super.key, required this.providers, required this.onSelected, this.busyProvider, this.devMode = false});

  final List<SocialSignIn> providers;
  final ValueChanged<SocialSignIn> onSelected;
  final String? busyProvider;
  final bool devMode;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Divider(color: context.colors.line)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: Space.sm), child: Text(t.apSocialOr, style: context.text.labelMedium?.copyWith(color: context.colors.inkMuted))),
        Expanded(child: Divider(color: context.colors.line)),
      ]),
      const SizedBox(height: Space.sm),
      Text(t.apSocialSignIn, style: context.text.titleSmall),
      const SizedBox(height: Space.xs),
      for (final p in providers)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: SocialSignInButton(
            provider: p.provider,
            busy: busyProvider == p.provider,
            onPressed: busyProvider == null ? () => onSelected(p) : null,
          ),
        ),
      if (devMode) Text(t.apDevSocialNote, style: context.text.labelSmall?.copyWith(color: context.colors.inkMuted), textAlign: TextAlign.center),
    ]);
  }
}
