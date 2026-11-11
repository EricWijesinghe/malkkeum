import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'bookings.dart';
import 'chat.dart';
import 'home.dart';
import 'more.dart';
import 'web_return.dart';

/// Four tabs. Phones get a bottom bar; tablets and desktop get a side rail.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  bool _loaded = false;
  StreamSubscription<PushTarget>? _pushTaps;

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
    PushService.start(app.api).ignore();
    _pushTaps = PushService.taps.listen(_openPush);
    final launch = PushService.takePending();
    if (launch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPush(launch);
      });
    }
    // Web deep links (/app/#/booking/..) and the return from the hosted payment page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openWebHashRoute(context);
    });
  }

  @override
  void dispose() {
    _pushTaps?.cancel();
    super.dispose();
  }

  /// Opens the booking or chat a tapped push points to.
  Future<void> _openPush(PushTarget target) async {
    final app = context.appRead;
    final nav = Navigator.of(context);
    try {
      switch (target) {
        case BookingTarget(:final bookingId):
          await nav.push(
            MaterialPageRoute<void>(
              builder: (_) => BookingDetailScreen(id: bookingId),
            ),
          );
        case ChatTarget(:final threadId):
          final thread = await findChatThread(
            app.api,
            '/chat/threads',
            threadId,
          );
          if (thread == null) return;
          await nav.push(
            MaterialPageRoute<void>(
              builder: (_) => ChatRoomScreen(
                threadId: thread.id,
                topic: thread.topic,
                bookingId: thread.bookingId,
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
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
