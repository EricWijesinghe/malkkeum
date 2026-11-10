import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import 'screens/bookings.dart';
import 'screens/catalog.dart';
import 'screens/dashboard.dart';
import 'screens/finance.dart';
import 'screens/inbox.dart';
import 'screens/marketing.dart';
import 'screens/people.dart';
import 'screens/setup.dart';
import 'state.dart';

class _Section {
  const _Section(this.icon, this.label, this.build, {this.adminOnly = false});
  final IconData icon;
  final String Function(T) label;
  final Widget Function() build;
  final bool adminOnly;
}

final _sections = <_Section>[
  _Section(
    Icons.space_dashboard_rounded,
    (t) => t.cDashboard,
    () => const DashboardScreen(),
  ),
  _Section(
    Icons.event_note_rounded,
    (t) => t.cBookings,
    () => const BookingsScreen(),
  ),
  _Section(
    Icons.request_quote_rounded,
    (t) => t.cQuoteDesk,
    () => const BookingsScreen(quoteDesk: true),
  ),
  _Section(Icons.forum_rounded, (t) => t.cInbox, () => const InboxScreen()),
  _Section(Icons.sell_rounded, (t) => t.cCatalog, () => const CatalogScreen()),
  _Section(
    Icons.campaign_rounded,
    (t) => t.cMarketing,
    () => const MarketingScreen(),
  ),
  _Section(
    Icons.engineering_rounded,
    (t) => t.cPartners,
    () => const PartnersScreen(),
  ),
  _Section(
    Icons.payments_rounded,
    (t) => t.cSettlements,
    () => const SettlementsScreen(),
  ),
  _Section(
    Icons.account_balance_wallet_rounded,
    (t) => t.fFinance,
    () => const FinanceScreen(),
    adminOnly: true,
  ),
  _Section(
    Icons.people_alt_rounded,
    (t) => t.cCustomers,
    () => const CustomersScreen(),
  ),
  _Section(
    Icons.badge_rounded,
    (t) => t.cStaff,
    () => const StaffScreen(),
    adminOnly: true,
  ),
  _Section(
    Icons.tune_rounded,
    (t) => t.cSetup,
    () => const SetupScreen(),
    adminOnly: true,
  ),
];

/// Linear-style: side menu on desktop, drawer on phone, Ctrl+K palette, Ctrl+1..9 to jump.
class ConsoleShell extends StatefulWidget {
  const ConsoleShell({super.key});
  @override
  State<ConsoleShell> createState() => _ConsoleShellState();
}

class _ConsoleShellState extends State<ConsoleShell> {
  int _index = 0;
  final _pages = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    final s = context.consoleRead;
    s.loadDashboard().ignore();
    s.realtime.connect();
  }

  List<_Section> get _visible =>
      _sections.where((s) => !s.adminOnly || context.console.isAdmin).toList();

  void _go(int i) => setState(() => _index = i);

  Future<void> _palette() async {
    final t = context.t;
    final picked = await showDialog<Object>(
      context: context,
      builder: (_) => _Palette(sections: _visible, t: t),
    );
    if (picked is int) _go(picked);
    if (picked is String && mounted) {
      _go(1);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingDetailPage(query: picked),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.console;
    final sections = _visible;
    final page = _pages.putIfAbsent(_index, () => sections[_index].build());
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): _palette,
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _palette,
      for (var i = 0; i < sections.length && i < 9; i++)
        SingleActivator(
          LogicalKeyboardKey(0x00000000031 + i),
          control: true,
        ): () =>
            _go(i),
    };
    Widget navItem(int i) {
      final s = sections[i];
      final badge = switch (i) {
        2 => c.openQuotes,
        3 => c.unreadThreads,
        _ => 0,
      };
      final selected = i == _index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 1),
        child: ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: context.colors.primaryTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(s.icon, size: 20),
          title: Text(
            s.label(t),
            style: context.text.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: badge > 0 ? Badge(label: Text('$badge')) : null,
          onTap: () {
            _go(i);
            if (!context.isWide) Navigator.of(context).maybePop();
          },
        ),
      );
    }

    final menu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.lg,
            Space.md,
            Space.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  '${BrandConfig.placeholder.name} ${t.cTitle}',
                  style: context.text.titleSmall,
                ),
              ),
              const _ThemeButton(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xs,
          ),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Row(
              children: [
                Expanded(
                  child: Text(t.cSearchCommand, style: context.text.bodySmall),
                ),
                Text('Ctrl K', style: context.text.labelSmall),
              ],
            ),
            onPressed: _palette,
          ),
        ),
        Expanded(
          child: ListView(
            children: [for (var i = 0; i < sections.length; i++) navItem(i)],
          ),
        ),
        const Divider(),
        ListTile(
          dense: true,
          leading: const Icon(Icons.logout_rounded, size: 20),
          title: Text(t.logout),
          onTap: Deps.read(context).session.logout,
        ),
      ],
    );

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: context.isWide
            ? Scaffold(
                body: Row(
                  children: [
                    SizedBox(
                      width: 248,
                      child: AuroraBackground(
                        child: GlassBar(
                          horizontal: false,
                          child: Material(
                            color: Colors.transparent,
                            child: menu,
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: page),
                  ],
                ),
              )
            : Scaffold(
                appBar: AppBar(
                  title: Text(sections[_index].label(t)),
                  actions: [
                    IconButton(
                      tooltip: t.cSearchCommand,
                      onPressed: _palette,
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                drawer: Drawer(child: SafeArea(child: menu)),
                body: page,
              ),
      ),
    );
  }
}

/// One-tap theme cycle: dark -> light -> system. Icon shows the current mode.
class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final theme = Deps.of(context).theme;
    final icon = switch (theme.mode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
    return IconButton(
      tooltip: '${context.t.themeTip}: ${context.t.themeLabel(theme.mode)}',
      visualDensity: VisualDensity.compact,
      onPressed: () => Deps.read(context).theme.cycle(),
      icon: Icon(icon, size: 20),
    );
  }
}

class _Palette extends StatefulWidget {
  const _Palette({required this.sections, required this.t});
  final List<_Section> sections;
  final T t;
  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final matches = [
      for (var i = 0; i < widget.sections.length; i++)
        if (widget.sections[i]
            .label(widget.t)
            .toLowerCase()
            .contains(_q.toLowerCase()))
          i,
    ];
    final looksLikeBooking = _q.trim().length >= 3 && matches.isEmpty;
    return Dialog(
      alignment: const Alignment(0, -0.6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: widget.t.cPaletteHint,
                ),
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: (_) => Navigator.of(context).pop(
                  matches.isNotEmpty
                      ? matches.first
                      : (_q.trim().isEmpty ? null : _q.trim()),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final i in matches)
                    ListTile(
                      leading: Icon(widget.sections[i].icon),
                      title: Text(widget.sections[i].label(widget.t)),
                      trailing: i < 9 ? Text('Ctrl ${i + 1}') : null,
                      onTap: () => Navigator.of(context).pop(i),
                    ),
                  if (looksLikeBooking)
                    ListTile(
                      leading: const Icon(Icons.tag_rounded),
                      title: Text('${widget.t.cOpenBooking}: ${_q.trim()}'),
                      onTap: () => Navigator.of(context).pop(_q.trim()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
