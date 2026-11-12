import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'account_identity.dart';
import 'addresses.dart';
import 'booking_flow.dart';
import 'business_info.dart';
import 'payments.dart';
import 'privacy.dart';
import 'service.dart';
import 'wallet.dart';
import 'subscriptions.dart';

/// Installed build version (pubspec `version`), or null where no platform channel answers (widget tests).
Future<String?> _buildVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Exception {
    return null;
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = context.app;
    final deps = Deps.of(context);
    final brand = BrandConfig.placeholder.name;
    Widget tile(
      String icon,
      String label,
      VoidCallback? onTap, {
      String? trailing,
    }) => ListTile(
      leading: Icon3D(icon, size: 36),
      title: Text(label),
      trailing: trailing == null
          ? const Icon(Icons.chevron_right_rounded)
          : _RowValue(trailing, style: context.text.labelMedium),
      onTap: onTap,
    );
    Widget group(List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Column(children: children),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _push(context, const AccountScreen()),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: context.colors.primaryTint,
                          child: Text(
                            app.name.isEmpty ? '?' : app.name.characters.first,
                            style: context.text.titleLarge?.copyWith(
                              color: context.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.name, style: context.text.titleMedium),
                              Text(
                                t.moreGreeting(brand),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: _Counter(
                        icon: 'ui_coupon',
                        label: t.moreCoupons,
                        value: '${app.coupons.where((c) => c.usable).length}',
                        onTap: () => _push(context, const CouponsScreen()),
                      ),
                    ),
                    Expanded(
                      child: _Counter(
                        icon: 'ui_points',
                        label: t.morePoints,
                        value: app.points == null
                            ? '-'
                            : t.walletPoints('${app.points}'),
                        onTap: () => _push(context, const WalletScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          // The brief's menu, in its order.
          group([
            tile(
              'menu_scope',
              t.moreScope,
              () => _push(context, const ScopeScreen()),
            ),
            tile(
              'menu_payments',
              t.morePayments,
              () => _push(context, const PaymentMethodsScreen()),
            ),
            tile(
              'menu_addresses',
              t.moreAddresses,
              () => _push(context, const AddressesScreen()),
            ),
            tile(
              'menu_account',
              t.moreAccount,
              () => _push(context, const AccountScreen()),
            ),
            tile(
              'menu_notices',
              t.moreNotices,
              () => _push(
                context,
                ContentListScreen(kind: 'notice', title: t.moreNotices),
              ),
            ),
            tile(
              'menu_tips',
              t.moreBrandTips(brand),
              () => _push(
                context,
                ContentListScreen(kind: 'tip', title: t.moreBrandTips(brand)),
              ),
            ),
            tile(
              'menu_faq',
              t.moreFaq,
              () => _push(context, const FaqScreen()),
            ),
            tile(
              'menu_contact',
              t.moreContact,
              () => openTopicChat(context, 'other'),
            ),
            FutureBuilder<String?>(
              future: _buildVersion(),
              builder: (context, snap) => tile(
                'menu_version',
                t.moreVersionInfo,
                null,
                trailing: snap.data ?? '',
              ),
            ),
          ]),
          group([
            tile(
              'pay_virtual',
              t.payHistoryTitle,
              () => _push(context, const PaymentHistoryScreen()),
            ),
            tile(
              'menu_subscriptions',
              t.subTitle,
              () => _push(context, const SubscriptionsScreen()),
            ),
            tile(
              'menu_partner',
              t.morePartner,
              () => openTopicChat(context, 'other'),
            ),
            tile(
              'menu_language',
              t.moreLanguage,
              () => _push(context, const LanguageScreen()),
              trailing: _langName(deps.locale.locale?.languageCode, t),
            ),
            tile(
              'menu_theme',
              t.themeTitle,
              () => deps.theme.cycle(),
              trailing: t.themeLabel(deps.theme.mode),
            ),
            tile(
              'menu_privacy',
              t.morePrivacy,
              () => _push(
                context,
                LegalScreen(slug: 'privacy', title: t.morePrivacy),
              ),
            ),
            tile(
              'menu_terms',
              t.moreTerms,
              () => _push(
                context,
                LegalScreen(slug: 'terms', title: t.moreTerms),
              ),
            ),
            tile('menu_licenses', t.moreLicenses, () async {
              final version = await _buildVersion();
              if (!context.mounted) return;
              showLicensePage(
                context: context,
                applicationName: brand,
                applicationVersion: version,
              );
            }),
          ]),
          TextButton(onPressed: deps.session.logout, child: Text(t.logout)),
          TextButton(
            onPressed: () => _deleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: Text(t.deleteAccount),
          ),
          BusinessInfo(api: app.api),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final t = context.t;
    final deps = Deps.read(context);
    final ok = await showAppSheet<bool>(
      context,
      title: t.deleteAccount,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.deleteAccountBody, style: ctx.text.bodyMedium),
            const SizedBox(height: Space.xl),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.deleteAccount),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await deps.app.api.delete('/me');
      await deps.session.clear();
    } catch (e) {
      if (context.mounted) showToast(context, t.error(e));
    }
  }
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

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final coupons = context.app.coupons;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreCoupons)),
      body: coupons.isEmpty
          ? EmptyState(
              icon: Icons.confirmation_number_rounded,
              title: t.couponsEmpty,
              hue: ServiceHues.studio,
            )
          : ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [for (final c in coupons) _CouponTicket(coupon: c)],
            ),
    );
  }
}

class _CouponTicket extends StatelessWidget {
  const _CouponTicket({required this.coupon});
  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = coupon;
    final hue = c.serviceCode == null
        ? ServiceHues.studio
        : ServiceHues.of(c.serviceCode!);
    final state = c.usedBookingId != null
        ? t.couponUsed
        : (!c.usable ? t.couponExpired : null);
    return Opacity(
      opacity: state == null ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 108,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.tintOf(hue),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(Radii.card),
                    ),
                  ),
                  child: Text(
                    context.won(c.amount),
                    style: context.text.titleLarge?.copyWith(
                      color: context.colors.isDark ? hue.tint : hue.tone,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.couponName(c.name),
                          style: context.text.titleSmall,
                        ),
                        Text(
                          c.serviceCode == null
                              ? t.couponAnyService
                              : t.service(c.serviceCode!),
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state ??
                              t.couponUntil(
                                dateLabel(c.expiresAt, context.lang),
                              ),
                          style: context.text.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One header stat (coupons, points): 3D icon, label and value; the whole cell is the tap target.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Icon3D(icon, size: 32),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Trailing value of a row, capped to a share of the screen so long text or a large font
/// can never squeeze the title out of the tile.
class _RowValue extends StatelessWidget {
  const _RowValue(this.text, {this.style, this.share = 0.3, this.maxLines = 1});
  final String text;
  final TextStyle? style;
  final double share;
  final int maxLines;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width * share,
    ),
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
    ),
  );
}

String _loginLabel(T t, String provider) => switch (provider) {
  'kakao' => t.accountLoginKakao,
  'naver' => t.accountLoginNaver,
  'apple' => t.accountLoginApple,
  'google' => t.accountLoginGoogle,
  _ => provider,
};

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreAccount)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: Text(t.accountName),
                  trailing: _RowValue(app.name, share: 0.55, maxLines: 2),
                ),
                ListTile(
                  title: Text(t.accountPhone),
                  trailing: _RowValue(app.phone, share: 0.55, maxLines: 2),
                ),
                ListTile(
                  title: Text(t.accountEmail),
                  trailing: _RowValue(
                    app.email ?? '-',
                    share: 0.55,
                    maxLines: 2,
                  ),
                ),
                ListTile(
                  title: Text(t.accountLogin),
                  // Read-only: what this account can sign in with.
                  subtitle: Text(
                    [
                      for (final p in app.logins) _loginLabel(t, p),
                      if (app.phone.isNotEmpty) t.accountLoginPhone,
                    ].join(' · '),
                  ),
                ),
                const IdentityEntryTile(),
                ListTile(
                  title: Text(t.pvManage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _push(context, const ConsentScreen()),
                ),
                ListTile(
                  title: Text(t.pvExport),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDataExport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// "What's included": every service with its description and limits.
class ScopeScreen extends StatelessWidget {
  const ScopeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final services = context.app.services;
    return DefaultTabController(
      length: services.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.moreScope),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final s in services) Tab(text: t.serviceShort(s.code))],
          ),
        ),
        body: TabBarView(
          children: [
            for (final s in services)
              ListView(
                padding: const EdgeInsets.all(Space.gutter),
                children: [
                  Center(child: ServiceGlyph(s.code, size: 96)),
                  const SizedBox(height: Space.lg),
                  Text(t.service(s.code), style: context.text.headlineSmall),
                  const SizedBox(height: Space.xs),
                  Text(t.serviceDesc(s.code), style: context.text.bodyLarge),
                  const SizedBox(height: Space.lg),
                  for (final n in t.serviceNotes(s.code))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(n, style: context.text.bodyMedium),
                    ),
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ServiceScreen(service: s),
                      ),
                    ),
                    child: Text(t.bookNow),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
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

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.t.moreFaq)),
    body: AsyncView<List<ContentItem>>(
      load: () async =>
          (await context.api.get('/content', query: {'kind': 'faq'}) as List)
              .map((e) => ContentItem(e as Json))
              .toList(),
      builder: (context, items, _) => ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          for (final f in items)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: Space.xs),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(),
                title: Text(
                  f.title(context.lang),
                  style: context.text.titleSmall,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.md,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f.text(context.lang),
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
