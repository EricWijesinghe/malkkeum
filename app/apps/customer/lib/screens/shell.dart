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

/// 3D art ids of the four tabs, in tab order (DAHAE-PLAN §4).
const _navIcons = ['nav_home', 'nav_bookings', 'nav_chat', 'nav_more'];

/// Four tabs. Phones get a bottom bar; tablets and desktop get a side rail.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int _tab = 0;

  /// Fade-through-in of the newly selected tab (the old one is already hidden).
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Motion.fadeIn,
    value: 1,
  );
  late final _enterFade = CurvedAnimation(parent: _enter, curve: Motion.ease);
  late final _enterScale = Tween(
    begin: 0.985,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _enter, curve: Motion.emphasized));
  bool _started = false;
  bool _memberStarted = false;
  String? _memberSubject;
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
    final s = _session!;
    if (_memberStarted && (!s.signedIn || s.subject != _memberSubject)) _stopMember();
    if (s.signedIn && !_memberStarted) {
      _startMember();
      // Launch reads consent in main(); a sign-in brings this account's own choice.
      context.appRead.syncAnalyticsConsent().ignore();
      // The tabs loaded as a guest: reload them with the account's bookings and feed.
      context.appRead.bookingsChanged();
    }
    setState(() {});
  }

  /// Account data, live updates and push: once per signed-in account.
  void _startMember() {
    if (_memberStarted) return;
    _memberStarted = true;
    _memberSubject = _session!.subject;
    final app = context.appRead;
    app.loadAll().catchError((Object e, StackTrace st) {
      reportError(e, st);
      if (mounted) showToast(context, context.t.error(e));
    });
    app.realtime.connect();
    app.startPush(app.api).ignore();
    _pushTaps = PushService.taps.listen(_openPush);
    final launch = PushService.takePending();
    if (launch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPush(launch);
      });
    }
  }

  /// Sign-out or another account: the last account's data, taps and tab position go.
  /// Realtime closes its own socket on sign-out; [_startMember] opens it again for the next account.
  void _stopMember() {
    _memberStarted = false;
    _memberSubject = null;
    _pushTaps?.cancel();
    _pushTaps = null;
    context.appRead.reset();
    _tab = 0;
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    _pushTaps?.cancel();
    _enter.dispose();
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
    } catch (e, st) {
      reportError(e, st);
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  void go(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (MediaQuery.disableAnimationsOf(context)) return;
    _enter.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final unread = context.app.unreadChats;
    // 3D tab icons: the selected one pops and bounces (static under reduced motion).
    Widget icon(int i) {
      final art = Icon3D(
        _navIcons[i],
        active: _tab == i,
        size: 30,
        tilt: true,
        // A new unread chat nudges the chat tab once.
        attention: i == 2 ? unread : 0,
      );
      if (i != 2) return art;
      return Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: art,
      );
    }

    final labels = [t.tabHome, t.tabBookings, t.tabChat, t.tabMore];
    final signedIn = _session?.signedIn ?? false;
    final pages = [
      HomeTab(onOpenTab: go),
      signedIn ? const BookingsTab() : const GuestGate(),
      signedIn ? const ChatListTab() : const GuestGate(),
      const MoreTab(),
    ];
    // Hidden tabs stay alive but their tickers (idle icons, staggers) pause.
    final body = FadeTransition(
      opacity: _enterFade,
      child: ScaleTransition(
        scale: _enterScale,
        child: IndexedStack(
          // Each account gets fresh tab state: nothing the last one loaded survives a switch.
          key: ValueKey(_memberSubject),
          index: _tab,
          children: [
            for (var i = 0; i < pages.length; i++)
              TickerMode(enabled: i == _tab, child: pages[i]),
          ],
        ),
      ),
    );

    // Android back on another tab goes Home first (Toss, Linear); back on Home leaves the app.
    Widget backToHome(Widget child) => PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(0);
      },
      child: child,
    );

    if (context.isWide) {
      return backToHome(Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: context.colors.surface,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(
                    icon: icon(i),
                    label: Text(labels[i]),
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
      ));
    }
    return backToHome(Scaffold(
      body: body,
      bottomNavigationBar: GlassBar(
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: go,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationDestination(icon: icon(i), label: labels[i]),
          ],
        ),
      ),
    ));
  }
}
