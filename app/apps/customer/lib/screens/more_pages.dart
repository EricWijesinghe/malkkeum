part of 'more.dart';

/// Short day as the design writes it: "11.26" in Korean, the locale's month/day elsewhere.
String _shortDay(DateTime d, String lang) =>
    lang == 'ko' ? DateFormat('M.d').format(d) : DateFormat.Md(lang).format(d);

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final coupons = context.app.coupons;
    final usable = coupons.where((c) => c.usable).toList();
    final spent = coupons.where((c) => !c.usable).toList();
    Widget heading(String title, [String? count]) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xxs, Space.md, 0, Space.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title),
            if (count != null)
              TextSpan(
                text: ' $count',
                style: TextStyle(color: context.colors.accent),
              ),
          ],
        ),
        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    var i = 0;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreCoupons)),
      body: coupons.isEmpty
          ? EmptyState(
              icon: Icons.confirmation_number_rounded,
              title: t.couponsEmpty,
              hue: ServiceHues.studio,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.gutter,
              ),
              children: [
                heading(
                  t.couponsAvailableTitle,
                  t.moreCouponCount('${usable.length}'),
                ),
                for (final c in usable)
                  StaggerIn(
                    index: i++,
                    child: _CouponTicket(coupon: c),
                  ),
                if (spent.isNotEmpty) ...[
                  heading(t.couponsUsedTitle),
                  for (final c in spent)
                    StaggerIn(
                      index: i++,
                      child: _CouponTicket(coupon: c),
                    ),
                ],
                const SizedBox(height: Space.xs),
                Text(
                  t.couponsNote,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.inkSoft,
                  ),
                ),
              ],
            ),
    );
  }
}

/// White ticket: amount, title and scope on the left, a dashed tear line, the glyph stub on the right.
class _CouponTicket extends StatelessWidget {
  const _CouponTicket({required this.coupon});
  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = coupon;
    final colors = context.colors;
    final state = c.usedBookingId != null
        ? t.couponUsed
        : (!c.usable ? t.couponExpired : null);
    final scope = c.serviceCode == null
        ? t.couponAnyService
        : t.service(c.serviceCode!);
    final ticket = AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.won(c.amount),
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: state == null ? colors.accent : colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      t.couponName(c.name),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$scope · ${t.couponUntil(_shortDay(c.expiresAt, context.lang))}',
                      style: context.text.bodySmall?.copyWith(
                        color: colors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 1,
              child: CustomPaint(painter: _Perforation(colors.line)),
            ),
            SizedBox(
              width: 76,
              child: Center(
                child: state == null
                    ? CircleAvatar(
                        radius: 22,
                        backgroundColor: colors.primaryTint,
                        child: const Icon3D(
                          'ui_coupon',
                          size: 28,
                          idle: Icon3DIdle.sway,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(Space.xs),
                        child: Text(
                          state,
                          textAlign: TextAlign.center,
                          style: context.text.labelMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: state == null ? ticket : Opacity(opacity: 0.6, child: ticket),
    );
  }
}

/// The ticket's dashed vertical tear line.
class _Perforation extends CustomPainter {
  const _Perforation(this.color);
  final Color color;
  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = Space.sm; y < size.height - Space.sm; y += _dash + _gap) {
      canvas.drawLine(Offset(0, y), Offset(0, y + _dash), paint);
    }
  }

  @override
  bool shouldRepaint(_Perforation old) => old.color != color;
}

String _loginLabel(T t, String provider) => switch (provider) {
  'kakao' => t.accountLoginKakao,
  'naver' => t.accountLoginNaver,
  'apple' => t.accountLoginApple,
  'google' => t.accountLoginGoogle,
  _ => provider,
};

/// Small brand chip for a social login (colours fixed by each brand's guide).
class _LoginBadge extends StatelessWidget {
  const _LoginBadge(this.provider);
  final String provider;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, mark) = switch (provider) {
      'kakao' => (const Color(0xFFFEE500), const Color(0xFF191919), 'K'),
      'naver' => (const Color(0xFF03C75A), Colors.white, 'N'),
      'apple' => (Colors.black, Colors.white, ''),
      'google' => (Colors.white, const Color(0xFF4285F4), 'G'),
      _ => (context.colors.surfaceHigh, context.colors.ink, '·'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colors.line, width: 0.5),
            ),
            child: Center(
              child: provider == 'apple'
                  ? Icon(Icons.apple, size: 14, color: fg)
                  : Text(
                      mark,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _loginLabel(context.t, provider),
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Account info (p26): header, the profile rows, points, then privacy tools and sign-out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    final c = context.colors;
    final lang = context.lang;
    final joined = app.joinedAt;
    final logins = [
      for (final p in app.logins) _LoginBadge(p),
      if (app.phone.isNotEmpty)
        Text(t.accountLoginPhone, style: context.text.bodyMedium),
    ];
    Widget divider() =>
        const Divider(height: 1, indent: Space.lg, endIndent: Space.lg);
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(t.moreAccount)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: motionFor(context, Motion.iconPop),
                  curve: Curves.easeOutBack,
                  builder: (_, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: c.primaryTint,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 30,
                      color: c.accent,
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (joined != null)
                        Text(
                          t.accountJoined(
                            lang == 'ko'
                                ? DateFormat('yyyy.MM.dd').format(joined)
                                : DateFormat.yMd(lang).format(joined),
                          ),
                          style: context.text.bodySmall?.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FlowBand(),
          _LabelValueRow(label: t.accountName, value: app.name),
          divider(),
          _LabelValueRow(
            label: t.accountPhone,
            value: app.phone,
            extra: TextButton(
              onPressed: () => _push(context, const AccountIdentityScreen()),
              child: Text(t.change),
            ),
          ),
          divider(),
          _LabelValueRow(label: t.accountEmail, value: app.email ?? '-'),
          divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      t.accountLogin,
                      style: context.text.bodyMedium?.copyWith(
                        color: c.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    // Read-only: what this account can sign in with. Fades in once /me answers.
                    child: AnimatedSwitcher(
                      duration: motionFor(context, Motion.standard),
                      child: Wrap(
                        key: ValueKey(logins.length),
                        alignment: WrapAlignment.end,
                        spacing: Space.sm,
                        runSpacing: Space.xxs,
                        children: logins,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FlowBand(),
          _LabelValueRow(
            label: t.morePoints,
            value: app.points == null ? '-' : t.walletPoints('${app.points}'),
          ),
          const FlowBand(),
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
          const SizedBox(height: Space.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.md,
            children: [
              TextButton(
                onPressed: Deps.read(context).session.logout,
                style: TextButton.styleFrom(foregroundColor: c.inkSoft),
                child: Text(
                  t.logout,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              TextButton(
                onPressed: () => _deleteAccount(context),
                style: TextButton.styleFrom(foregroundColor: c.inkSoft),
                child: Text(
                  t.deleteAccount,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }
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

String _faqCategory(T t, String code) => switch (code) {
  'booking' => t.faqCat_booking,
  'payment' => t.faqCat_payment,
  'move' => t.faqCat_move,
  _ => code,
};

/// FAQ (p27): category chips when the content carries `body.category`, then Q rows.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.surface,
    appBar: AppBar(title: Text(context.t.moreFaq)),
    body: AsyncView<List<ContentItem>>(
      load: () async =>
          (await context.api.get('/content', query: {'kind': 'faq'}) as List)
              .map((e) => ContentItem(e as Json))
              .toList(),
      builder: (context, items, _) {
        final cats = <String>{
          for (final f in items)
            if (f.body['category'] case final String c when c.isNotEmpty) c,
        }.toList();
        final shown = _category == null
            ? items
            : items.where((f) => f.body['category'] == _category).toList();
        return Column(
          children: [
            if (cats.isNotEmpty) _chips(cats),
            Expanded(
              child: FadeThroughSwitcher(
                child: ListView(
                  key: ValueKey(_category),
                  padding: const EdgeInsets.only(bottom: Space.gutter),
                  children: [for (final f in shown) _FaqRow(item: f)],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _chips(List<String> cats) {
    final t = context.t;
    final c = context.colors;
    Widget chip(String? code, String label) {
      final on = _category == code;
      return Padding(
        padding: const EdgeInsets.only(right: Space.xs),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          showCheckmark: false,
          shape: const StadiumBorder(),
          side: BorderSide(color: on ? c.ink : c.line),
          selectedColor: c.ink,
          backgroundColor: c.surface,
          labelStyle: context.text.labelLarge?.copyWith(
            color: on ? c.surface : c.ink,
            fontWeight: on ? FontWeight.w700 : null,
          ),
          onSelected: (_) => setState(() => _category = code),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        children: [
          chip(null, t.faqAll),
          for (final code in cats) chip(code, _faqCategory(t, code)),
        ],
      ),
    );
  }
}

/// One question: teal "Q", the question and a chevron; the answer opens in a grey box.
class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: Space.md),
        leading: Text(
          'Q',
          style: context.text.titleMedium?.copyWith(
            color: c.accent,
            fontWeight: FontWeight.w900,
          ),
        ),
        minTileHeight: 56,
        title: Text(
          item.title(context.lang),
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          Space.md,
          0,
          Space.md,
          Space.md,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: c.surfaceHigh,
              borderRadius: BorderRadius.circular(Radii.chip + 2),
            ),
            child: Text(
              item.text(context.lang),
              style: context.text.bodyMedium?.copyWith(color: c.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
