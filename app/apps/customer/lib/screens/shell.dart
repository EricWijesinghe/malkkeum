import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'bookings.dart';
import 'chat.dart';
import 'home.dart';
import 'more.dart';

/// Four tabs. Phones get a bottom bar; tablets and desktop get a side rail.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final app = context.appRead;
    app.loadAll().catchError((Object e) {
      if (mounted) showToast(context, context.t.error(e));
    });
    app.realtime.connect();
  }

  void go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final unread = context.app.unreadChats;
    Widget badge(IconData icon) => Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: Icon(icon),
    );
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, t.tabHome),
      (
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        t.tabBookings,
      ),
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, t.tabChat),
      (Icons.menu_rounded, Icons.menu_rounded, t.tabMore),
    ];
    final pages = [
      HomeTab(onOpenTab: go),
      const BookingsTab(),
      const ChatListTab(),
      const MoreTab(),
    ];
    final body = IndexedStack(index: _tab, children: pages);

    if (context.isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: context.colors.surface,
              destinations: [
                for (var i = 0; i < destinations.length; i++)
                  NavigationRailDestination(
                    icon: i == 2
                        ? badge(destinations[i].$1)
                        : Icon(destinations[i].$1),
                    selectedIcon: i == 2
                        ? badge(destinations[i].$2)
                        : Icon(destinations[i].$2),
                    label: Text(destinations[i].$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: GlassBar(
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: go,
          destinations: [
            for (var i = 0; i < destinations.length; i++)
              NavigationDestination(
                icon: i == 2
                    ? badge(destinations[i].$1)
                    : Icon(destinations[i].$1),
                selectedIcon: i == 2
                    ? badge(destinations[i].$2)
                    : Icon(destinations[i].$2),
                label: destinations[i].$3,
              ),
          ],
        ),
      ),
    );
  }
}
