import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../state.dart';
import 'account_identity.dart';
import 'addresses.dart';
import 'booking_flow.dart';
import 'business_info.dart';
import 'chat.dart' show tabRootTitle;
import 'payments.dart';
import 'privacy.dart';
import 'service_scope.dart';
import 'wallet.dart';
import 'subscriptions.dart';

part 'more_pages.dart';

/// Installed build version (pubspec `version`), or null where no platform channel answers (widget tests).
Future<String?> _buildVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Exception {
    return null;
  }
}

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// Account-only screens: a guest gets the sign-in sheet, a member goes straight through.
Future<void> _pushMember(BuildContext context, Widget screen) async {
  if (!await requireSignIn(context, reason: SignInReason.account)) return;
  if (context.mounted) _push(context, screen);
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = context.app;
    final deps = Deps.of(context);
    final brand = BrandConfig.placeholder.name;
    final coupons = app.coupons.where((c) => c.usable).length;
    // A member-only row shows a hint instead of its value while the guest is signed out.
    final guest = !deps.session.signedIn;
    _MoreRow row(
      String icon,
      String label,
      VoidCallback? onTap, {
      String? trailing,
      bool accent = false,
      int attention = 0,
      bool member = false,
    }) {
      final hidden = member && guest;
      return _MoreRow(
        icon: icon,
        label: label,
        onTap: onTap,
        trailing: hidden ? null : trailing,
        subtitle: hidden ? t.guestAccountHint : null,
        accent: accent,
        attention: hidden ? 0 : attention,
      );
    }

    // The design's groups, in its order (p05); rows the design leaves out follow below the version.
    final groups = <Widget>[
      _ProfileCard(coupons: coupons, points: app.points, name: app.name),
      _Group([
        row(
          'menu_scope',
          t.moreScope,
          () => _push(context, const ServiceScopeScreen()),
        ),
        row(
          'menu_payments',
          t.morePayments,
          () => _pushMember(context, const PaymentMethodsScreen()),
          member: true,
        ),
        row(
          'ui_coupon',
          t.moreCoupons,
          () => _pushMember(context, const CouponsScreen()),
          trailing: '$coupons',
          accent: true,
          attention: coupons,
          member: true,
        ),
        row(
          'ui_points',
          t.morePoints,
          () => _pushMember(context, const WalletScreen()),
          member: true,
        ),
      ]),
      _Group([
        row(
          'menu_account',
          t.moreAccount,
          () => _pushMember(context, const AccountScreen()),
          member: true,
        ),
        row(
          'menu_addresses',
          t.moreAddresses,
          () => _pushMember(context, const AddressesScreen()),
          member: true,
        ),
      ]),
      _Group([
        row(
          'menu_notices',
          t.moreNotices,
          () => _push(
            context,
            ContentListScreen(kind: 'notice', title: t.moreNotices),
          ),
        ),
        row(
          'menu_tips',
          t.moreBrandTips(brand),
          () => _push(
            context,
            ContentListScreen(kind: 'tip', title: t.moreBrandTips(brand)),
          ),
        ),
        row('menu_faq', t.moreFaq, () => _push(context, const FaqScreen())),
        row(
          'menu_contact',
          t.moreContact,
          () => openTopicChat(context, 'other'),
        ),
        row(
          'menu_partner',
          t.morePartner,
          () => openTopicChat(context, 'other'),
        ),
      ]),
      _Group([
        FutureBuilder<String?>(
          future: _buildVersion(),
          builder: (context, snap) => _LabelValueRow(
            label: t.moreVersionInfo,
            value: snap.data == null ? '' : 'v${snap.data}',
          ),
        ),
      ]),
      _Group([
        row(
          'pay_virtual',
          t.payHistoryTitle,
          () => _pushMember(context, const PaymentHistoryScreen()),
          member: true,
        ),
        row(
          'menu_subscriptions',
          t.subTitle,
          () => _pushMember(context, const SubscriptionsScreen()),
          member: true,
        ),
        row(
          'menu_language',
          t.moreLanguage,
          () => _push(context, const LanguageScreen()),
          trailing: _langName(deps.locale.locale?.languageCode, t),
        ),
        row(
          'menu_theme',
          t.themeTitle,
          () => deps.theme.cycle(),
          trailing: t.themeLabel(deps.theme.mode),
        ),
        row(
          'menu_privacy',
          t.morePrivacy,
          () => _push(
            context,
            LegalScreen(slug: 'privacy', title: t.morePrivacy),
          ),
        ),
        row(
          'menu_terms',
          t.moreTerms,
          () => _push(context, LegalScreen(slug: 'terms', title: t.moreTerms)),
        ),
        row('menu_licenses', t.moreLicenses, () async {
          final version = await _buildVersion();
          if (!context.mounted) return;
          showLicensePage(
            context: context,
            applicationName: brand,
            applicationVersion: version,
          );
        }),
      ]),
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: tabRootTitle(context, t.moreTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.xs,
          Space.md,
          Space.gutter,
        ),
        children: [
          for (final (i, g) in groups.indexed)
            StaggerIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: g,
              ),
            ),
          BusinessInfo(api: app.api),
        ],
      ),
    );
  }
}

/// Name, greeting and the grey coupon / points strip (p05). The card opens the account page.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.coupons,
    required this.points,
    required this.name,
  });
  final int coupons;
  final int? points;
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final brand = BrandConfig.placeholder.name;
    final guest = !Deps.of(context).session.signedIn;
    return AppCard(
      padding: EdgeInsets.zero,
      // A guest has no account to show yet: the card starts sign-in instead.
      onTap: guest
          ? () => requireSignIn(context)
          : () => _push(context, const AccountScreen()),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.lg,
              Space.md,
              Space.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest
                            ? t.introStart
                            : name.isEmpty
                            ? ''
                            : t.moreNameSuffix(name),
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.moreGreeting(brand),
                        style: context.text.bodySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.inkMuted),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
            decoration: BoxDecoration(
              color: c.surfaceHigh,
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Counter(
                      label: t.moreCoupons,
                      value: guest
                          ? _guestHint(context)
                          : CountUp(
                              value: coupons,
                              format: (v) => t.moreCouponCount('$v'),
                              style: _counterStyle(context),
                            ),
                      onTap: () => _pushMember(context, const CouponsScreen()),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    indent: Space.sm,
                    endIndent: Space.sm,
                    color: c.line,
                  ),
                  Expanded(
                    child: _Counter(
                      label: t.morePoints,
                      value: guest
                          ? _guestHint(context)
                          : points == null
                          ? Text('-', style: _counterStyle(context))
                          : CountUp(
                              value: points!,
                              format: (v) => t.walletPoints('$v'),
                              style: _counterStyle(context),
                            ),
                      onTap: () => _pushMember(context, const WalletScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle? _counterStyle(BuildContext context) => context
      .text
      .labelLarge
      ?.copyWith(fontWeight: FontWeight.w800, color: context.colors.accent);

  /// A guest's counter shows what sign-in unlocks, not a dash or a zero.
  static Widget _guestHint(BuildContext context) => Text(
    context.t.guestAccountHint,
    style: context.text.labelSmall?.copyWith(color: context.colors.inkSoft),
  );
}

/// One strip cell: label left, value right; the whole cell is the tap target.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Radii.chip),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          // The value sits at the cell's end ("쿠폰    2장"), not right after the label.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            // Large balances at large text shrink instead of overflowing the half-width cell.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// White rounded group of rows on the grey canvas.
class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: Space.xxs),
    child: Column(children: children),
  );
}

/// A More row: 3D glyph, label, optional value and a chevron. Pressing lifts the glyph.
class _MoreRow extends StatefulWidget {
  const _MoreRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.subtitle,
    this.accent = false,
    this.attention = 0,
  });
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailing;

  /// Second line under the label (a guest's "sign in to view" hint).
  final String? subtitle;

  /// Trailing value in the accent colour (coupon count).
  final bool accent;

  /// A change kicks the glyph once (the coupon count going up).
  final int attention;

  @override
  State<_MoreRow> createState() => _MoreRowState();
}

class _MoreRowState extends State<_MoreRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (v) => setState(() => _pressed = v),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          child: Row(
            children: [
              Icon3D(
                widget.icon,
                size: 28,
                highlight: _pressed,
                attention: widget.attention,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: context.text.bodyLarge),
                    if (widget.subtitle case final s?)
                      Text(
                        s,
                        style: context.text.bodySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing case final v?) ...[
                const SizedBox(width: Space.xs),
                _RowValue(
                  v,
                  style: widget.accent
                      ? context.text.labelLarge?.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w800,
                        )
                      : context.text.labelMedium?.copyWith(color: c.inkSoft),
                ),
              ],
              const SizedBox(width: Space.xxs),
              Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey label left, value right (version card, account rows).
class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({required this.label, required this.value, this.extra});
  final String label;
  final String value;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xs,
      ),
      child: Row(
        // A short label leaves part of its flex share unused: that space goes before the value,
        // so the value ends at the row's edge as in the design.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.inkSoft,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          // Two shares for the value side: a phone number and its 변경 link stay on one line.
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Flexible: a long translated link wraps instead of pushing the row off screen.
                if (extra case final e?) Flexible(child: e),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _langName(String? code, T t) =>
    LocaleController.names[code] ?? t.langSystem;

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Deps.of(context);
    final current = deps.locale.locale?.languageCode;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          for (final code in [null, ...LocaleController.names.keys])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: OptionCard(
                title: _langName(code, t),
                selected: current == code,
                onTap: () async {
                  await deps.locale.set(code == null ? null : Locale(code));
                  // Server-side messages (push, SMS) follow the account language too.
                  deps.app.api.patch('/me', {
                    'locale': deps.locale.effectiveCode,
                  }).ignore();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Trailing value of a row, capped to a share of the screen so long text or a large font
/// can never squeeze the title out of the tile.
class _RowValue extends StatelessWidget {
  const _RowValue(this.text, {this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width * 0.3,
    ),
    child: Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
    ),
  );
}

class ContentListScreen extends StatelessWidget {
  const ContentListScreen({super.key, required this.kind, required this.title});
  final String kind;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ContentListBody(kind: kind),
  );
}

/// Published content of one kind (notices, FAQ); also a tab in the notification inbox.
class ContentListBody extends StatelessWidget {
  const ContentListBody({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) => AsyncView<List<ContentItem>>(
    load: () async =>
        (await context.api.get('/content', query: {'kind': kind}) as List)
            .map((e) => ContentItem(e as Json))
            .toList(),
    builder: (context, items, _) => items.isEmpty
        ? EmptyState(icon: Icons.inbox_rounded, title: context.t.noContent)
        : ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i].title(context.lang)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ContentDetailScreen(item: items[i]),
                ),
              ),
            ),
          ),
  );
}

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({super.key, required this.item});
  final ContentItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        Text(item.title(context.lang), style: context.text.headlineSmall),
        const SizedBox(height: Space.lg),
        if (item.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.card),
            child: Image.network(item.imageUrl!, cacheWidth: 720),
          ),
          const SizedBox(height: Space.lg),
        ],
        SelectableText(item.text(context.lang), style: context.text.bodyLarge),
      ],
    ),
  );
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.slug, required this.title});
  final String slug;
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AsyncView<List<ContentItem>>(
      load: () async =>
          (await context.api.get('/content', query: {'kind': 'legal'}) as List)
              .map((e) => ContentItem(e as Json))
              .where((c) => c.j['slug'] == slug)
              .toList(),
      builder: (context, items, _) => items.isEmpty
          ? EmptyState(
              icon: Icons.description_rounded,
              title: context.t.noContent,
            )
          : ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [
                SelectableText(
                  items.first.text(context.lang),
                  style: context.text.bodyMedium,
                ),
              ],
            ),
    ),
  );
}
