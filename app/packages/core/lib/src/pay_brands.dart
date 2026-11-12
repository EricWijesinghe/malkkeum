import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Visual identity of a payment method. Text wordmarks and Material icons only (no image assets).
/// Brand colors are constants on purpose: a brand guide fixes them in both themes.
@immutable
class PayBrand {
  const PayBrand({this.wordmark, this.icon, this.background, this.foreground});

  final String? wordmark;
  final IconData? icon;

  /// Null = neutral chip surface from the theme.
  final Color? background;
  final Color? foreground;
}

/// Brand table keyed by server channel code (see GET /v1/payments/methods).
PayBrand payBrandFor(String code) => switch (code) {
  'kakaopay' => const PayBrand(
    wordmark: 'kakaopay',
    background: Color(0xFFFEE500),
    foreground: Color(0xFF191919),
  ),
  'naverpay' => const PayBrand(
    wordmark: 'NAVER pay',
    background: Color(0xFF03C75A),
    foreground: Color(0xFFFFFFFF),
  ),
  'tosspay' => const PayBrand(
    wordmark: 'toss pay',
    background: Color(0xFF0064FF),
    foreground: Color(0xFFFFFFFF),
  ),
  'payco' => const PayBrand(
    wordmark: 'PAYCO',
    background: Color(0xFFE4002B),
    foreground: Color(0xFFFFFFFF),
  ),
  'samsungpay' => const PayBrand(
    wordmark: 'SAMSUNG Pay',
    background: Color(0xFF1428A0),
    foreground: Color(0xFFFFFFFF),
  ),
  'applepay' => const PayBrand(
    wordmark: 'Pay',
    background: Color(0xFF000000),
    foreground: Color(0xFFFFFFFF),
  ),
  'transfer' => const PayBrand(icon: Icons.account_balance_rounded),
  'virtual_account' => const PayBrand(icon: Icons.receipt_long_rounded),
  'phone' => const PayBrand(icon: Icons.smartphone_rounded),
  _ => const PayBrand(icon: Icons.credit_card_rounded),
};

/// Small brand badge, 40px tall. Decorative: the caller's label carries the meaning.
class PayBrandBadge extends StatelessWidget {
  const PayBrandBadge({super.key, required this.code, this.height = 40});
  final String code;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brand = payBrandFor(code);
    final fg = brand.foreground ?? context.colors.ink;
    return ExcludeSemantics(
      child: Container(
        height: height,
        constraints: BoxConstraints(minWidth: height * 1.6),
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: brand.background ?? context.colors.canvas,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: brand.background == null
              ? Border.all(color: context.colors.line)
              : null,
        ),
        child: brand.wordmark != null
            ? Text(
                brand.wordmark!,
                style: context.text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
              )
            : Icon(brand.icon, color: context.primary, size: 22),
      ),
    );
  }
}
