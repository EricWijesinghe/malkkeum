import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'flow_motion.dart';

const _ctaMinSize = 64.0;
const _ctaMaxWidth = 104.0;

/// Move-in/out (design p17): one grey row, copy on the left, "쿠폰받기" on the right.
/// The first tap takes the aircon coupon the console issued to this customer, when one is
/// usable; otherwise (and afterwards) it opens the add-on sheet: aircon units at the catalog
/// price, discounted by the server's estimate (`ac_addon_discount_bps`) on the review step.
class AcAddonBanner extends StatefulWidget {
  const AcAddonBanner({
    super.key,
    required this.aircon,
    required this.answers,
    required this.onChanged,
  });
  final Service aircon;
  final QuoteAnswers answers;
  final VoidCallback onChanged;

  @override
  State<AcAddonBanner> createState() => _AcAddonBannerState();
}

class _AcAddonBannerState extends State<AcAddonBanner> {
  bool _claimed = false;
  int _kicks = 0;

  Service get aircon => widget.aircon;
  QuoteAnswers get answers => widget.answers;

  int get _count => answers.acAddons.values.fold(0, (a, b) => a + b);

  /// The biggest usable coupon issued for aircon cleaning, if any.
  Coupon? _coupon(List<Coupon> coupons) => coupons
      .where((c) => c.usable && c.serviceCode == aircon.code)
      .fold<Coupon?>(
        null,
        (best, c) => best == null || c.amount > best.amount ? c : best,
      );

  void _tap(Coupon? coupon) {
    if (coupon == null || _claimed) {
      _open();
      return;
    }
    // shortcut: there is no claim endpoint, the console issues coupons straight into the
    // wallet; this only confirms it. Call a claim API here when the backend gets one.
    setState(() => _claimed = true);
    showToast(context, context.t.dfAcCouponClaimed);
  }

  Future<void> _open() async {
    final before = _count;
    await showAppSheet<void>(
      context,
      title: context.t.service('aircon'),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.gutter,
          ),
          children: [
            for (final (i, u) in aircon.units.indexed)
              StaggerIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon3D('ac_${u.labelKey}', size: 40),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: CountStepper(
                          label:
                              '${ctx.t.unit(u.labelKey)} · ${ctx.won(u.price)}',
                          value: answers.acAddons[u.labelKey] ?? 0,
                          onChanged: (v) {
                            setSheet(() => answers.acAddons[u.labelKey] = v);
                            widget.onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(ctx.t.dfAcAddonNote, style: ctx.text.bodySmall),
          ],
        ),
      ),
    );
    // Kick the count line once the sheet is gone, so the change is seen.
    if (mounted && _count != before) setState(() => _kicks++);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final count = _count;
    final coupon = _coupon(context.app.coupons);
    return Material(
      color: context.colors.surfaceHigh,
      borderRadius: BorderRadius.circular(Radii.tile),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            const SizedBox(width: Space.md),
            // Sways at rest; kicks with the count line when units were added.
            ExcludeSemantics(
              child: Icon3D(
                'promo_ac_addon',
                size: 44,
                idle: Icon3DIdle.sway,
                attention: _kicks,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      // The amount is the coupon's own; no price lives in the app.
                      coupon == null
                          ? t.dfAcAddonBanner
                          : t.dfAcCouponTitle(context.won(coupon.amount)),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    OneShot(
                      trigger: _kicks,
                      builder: kick,
                      child: Text(
                        count == 0
                            ? t.dfAcAddonBody
                            : t.dfAcAddonAdded('$count'),
                        style: context.text.bodySmall?.copyWith(
                          color: count == 0
                              ? context.colors.inkSoft
                              : context.primary,
                          fontWeight: count == 0 ? null : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: Space.lg,
              indent: Space.sm,
              endIndent: Space.sm,
              color: context.colors.line,
            ),
            Semantics(
              button: true,
              child: InkWell(
                onTap: () => _tap(coupon),
                // Capped: a long label at large text wraps instead of squeezing the copy out.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: _ctaMinSize,
                    maxWidth: _ctaMaxWidth,
                    minHeight: _ctaMinSize,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: Space.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _claimed ? Icons.add_rounded : Icons.download_rounded,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _claimed ? t.dfAcAddonAdd : t.dfAcCouponCta,
                          textAlign: TextAlign.center,
                          style: context.text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
