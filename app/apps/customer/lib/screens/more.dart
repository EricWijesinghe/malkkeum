import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'account_identity.dart';
import 'addresses.dart';
import 'booking_flow.dart';
import 'payments.dart';
import 'privacy.dart';
import 'service.dart';
import 'subscriptions.dart';

const appVersion = '1.0.0';

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
    Widget tile(
      IconData icon,
      ServiceHue hue,
      String label,
      VoidCallback onTap, {
      String? trailing,
    }) => ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.tintOf(hue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: context.colors.isDark ? hue.tint : hue.tone,
        ),
      ),
      title: Text(label),
      trailing: trailing == null
          ? const Icon(Icons.chevron_right_rounded)
          : Text(trailing, style: context.text.labelMedium),
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
            onTap: () => _push(context, const AccountScreen()),
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
                      Text(app.phone, style: context.text.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          group([
            tile(
              Icons.checklist_rounded,
              ServiceHues.moveOut,
              t.moreScope,
              () => _push(context, const ScopeScreen()),
            ),
            tile(
              Icons.credit_card_rounded,
              ServiceHues.bathroom,
              t.morePayments,
              () => _push(context, const PaymentMethodsScreen()),
            ),
            tile(
              Icons.event_repeat_rounded,
              ServiceHues.studio,
              t.subTitle,
              () => _push(context, const SubscriptionsScreen()),
            ),
            tile(
              Icons.confirmation_number_rounded,
              ServiceHues.studio,
              t.moreCoupons,
              () => _push(context, const CouponsScreen()),
              trailing: '${app.coupons.where((c) => c.usable).length}',
            ),
            tile(
              Icons.savings_rounded,
              ServiceHues.moveIn,
              t.morePoints,
              () => _push(context, const PointsScreen()),
              trailing: '0P',
            ),
            tile(
              Icons.home_work_rounded,
              ServiceHues.sofa,
              t.moreAddresses,
              () => _push(context, const AddressesScreen()),
            ),
          ]),
          group([
            tile(
              Icons.campaign_rounded,
              ServiceHues.kitchen,
              t.moreNotices,
              () => _push(
                context,
                ContentListScreen(kind: 'notice', title: t.moreNotices),
              ),
            ),
            tile(
              Icons.lightbulb_rounded,
              ServiceHues.studio,
              t.moreTips,
              () => _push(
                context,
                ContentListScreen(kind: 'tip', title: t.moreTips),
              ),
            ),
            tile(
              Icons.help_rounded,
              ServiceHues.mattress,
              t.moreFaq,
              () => _push(context, const FaqScreen()),
            ),
            tile(
              Icons.support_agent_rounded,
              ServiceHues.aircon,
              t.askTeam,
              () => openTopicChat(context, 'other'),
            ),
            tile(
              Icons.handshake_rounded,
              ServiceHues.moveOut,
              t.morePartner,
              () => openTopicChat(context, 'other'),
            ),
          ]),
          group([
            tile(
              Icons.translate_rounded,
              ServiceHues.bathroom,
              t.moreLanguage,
              () => _push(context, const LanguageScreen()),
              trailing: _langName(deps.locale.locale?.languageCode, t),
            ),
            tile(
              Icons.dark_mode_rounded,
              ServiceHues.mattress,
              t.themeTitle,
              () => deps.theme.cycle(),
              trailing: t.themeLabel(deps.theme.mode),
            ),
            tile(
              Icons.privacy_tip_rounded,
              ServiceHues.moveIn,
              t.morePrivacy,
              () => _push(
                context,
                LegalScreen(slug: 'privacy', title: t.morePrivacy),
              ),
            ),
            tile(
              Icons.description_rounded,
              ServiceHues.moveIn,
              t.moreTerms,
              () => _push(
                context,
                LegalScreen(slug: 'terms', title: t.moreTerms),
              ),
            ),
            tile(
              Icons.code_rounded,
              ServiceHues.moveIn,
              t.moreLicenses,
              () => showLicensePage(
                context: context,
                applicationName: BrandConfig.placeholder.name,
                applicationVersion: appVersion,
              ),
            ),
            ListTile(
              title: Text(
                t.moreVersion(appVersion),
                style: context.text.bodySmall,
              ),
            ),
          ]),
          TextButton(onPressed: deps.session.logout, child: Text(t.logout)),
          TextButton(
            onPressed: () => _deleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: Text(t.deleteAccount),
          ),
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

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.t.morePoints)),
    body: ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        AppCard(
          color: context.colors.freshTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t.pointsBalance, style: context.text.labelMedium),
              Text('0 P', style: context.text.displaySmall),
            ],
          ),
        ),
        const SizedBox(height: Space.xxl),
        EmptyState(
          icon: Icons.savings_rounded,
          title: context.t.pointsEmpty,
          hue: ServiceHues.moveIn,
        ),
      ],
    ),
  );
}

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
                ListTile(title: Text(t.accountName), trailing: Text(app.name)),
                ListTile(
                  title: Text(t.accountPhone),
                  trailing: Text(app.phone),
                ),
                ListTile(
                  title: Text(t.accountEmail),
                  trailing: Text(app.email ?? '-'),
                ),
                ListTile(
                  title: Text(t.accountLogin),
                  trailing: Text(t.accountLoginPhone),
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
