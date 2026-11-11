import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
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
  bool _started = false;
  bool _memberStarted = false;
  Session? _session;
  StreamSubscription<PushTarget>? _pushTaps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Guests get the public catalogue only; account data starts when they sign in.
    _session = Deps.read(context).session..addListener(_onSession);
    context.appRead.loadServices().catchError((Object e) {
      if (mounted) showToast(context, context.t.error(e));
    });
    if (_session!.signedIn) _startMember();
    // Web deep links (/app/#/booking/..) and the return from the hosted payment page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openWebHashRoute(context);
    });
  }

  void _onSession() {
    if (!mounted) return;
    if (_session!.signedIn) _startMember();
    setState(() {});
  }

  /// Account data, live updates and push: once per signed-in session.
  void _startMember() {
    if (_memberStarted) return;
    _memberStarted = true;
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
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
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
          await nav.push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: bookingId)));
        case ChatTarget(:final threadId):
          final thread = await findChatThread(app.api, '/chat/threads', threadId);
          if (thread == null) return;
          await nav.push(MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(threadId: thread.id, topic: thread.topic, bookingId: thread.bookingId)));
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
    final signedIn = _session?.signedIn ?? false;
    final pages = [
      HomeTab(onOpenTab: go),
      signedIn ? const BookingsTab() : const GuestGate(),
      signedIn ? const ChatListTab() : const GuestGate(),
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
