import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'auth.dart';
import 'chat.dart';
import 'jobs.dart';
import 'more.dart';
import 'quotes.dart';
import 'schedule.dart';

/// Bottom-bar 3D icon size (dp).
const double _navIcon = 28;

/// Routes by account state: onboarding -> waiting for approval -> app.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  /// How often an app opened without signal asks the server again.
  static const _offlineRetry = Duration(seconds: 20);

  late Future<void> _boot = _start();
  Timer? _catchUp;

  Future<void> _start() async {
    final pro = context.proRead;
    final fresh = await pro.boot();
    pro.realtime.connect();
    if (fresh) {
      pro.syncOutbox().ignore();
    } else if (mounted) {
      _catchUpLater();
    }
  }

  /// Opened from the saved profile: keep asking until the real one loads, then send the queue.
  void _catchUpLater() => _catchUp = Timer(_offlineRetry, () async {
    final pro = context.proRead;
    try {
      await pro.loadAll();
      pro.syncOutbox().ignore();
    } catch (e) {
      // Still no signal: ask again. Any other failure is left to the next realtime resync.
      if (e is ApiException && e.isNetwork && mounted) _catchUpLater();
    }
  });

  /// Runs the boot again. The session is kept: no signal is no reason to make a pro sign in again.
  Future<void> _retry() async {
    final boot = _start();
    setState(() {
      _boot = boot;
    });
    // The FutureBuilder shows the outcome; this only tells the button when to stop spinning.
    await boot.then((_) {}, onError: (Object _) {});
  }

  @override
  void dispose() {
    _catchUp?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _boot,
    builder: (context, snap) {
      // A retry keeps the last error on screen (its button shows progress) until it settles.
      if (snap.hasError) {
        return Scaffold(
          body: ErrorRetry(
            message: context.t.error(snap.error!),
            retryLabel: context.t.retry,
            onRetry: _retry,
            secondary: TextButton(
              onPressed: () => Deps.read(context).session.logout(),
              child: Text(context.t.logout),
            ),
          ),
        );
      }
      if (snap.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final pro = context.pro;
      if (!pro.onboarded) return const OnboardingScreen();
      return switch (pro.status) {
        'verified' => const PartnerShell(),
        'suspended' => _Blocked(message: context.t.pSuspended),
        _ => const _Pending(),
      };
    },
  );
}

class _Pending extends StatelessWidget {
  const _Pending();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          children: [
            Expanded(
              child: EmptyState(
                icon: Icons.verified_user_rounded,
                art: 'p_verified',
                title: context.t.pPendingTitle,
                body: context.t.pPendingBody,
                hue: ServiceHues.moveOut,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PayoutAccountScreen(),
                ),
              ),
              child: Text(context.t.pPayoutAccount),
            ),
            TextButton(
              onPressed: () => context.proRead.loadProfile(),
              child: Text(context.t.retry),
            ),
            TextButton(
              onPressed: Deps.read(context).session.logout,
              child: Text(context.t.logout),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: EmptyState(
      icon: Icons.block_rounded,
      title: message,
      hue: StatusHues.cancelled,
      action: OutlinedButton(
        onPressed: Deps.read(context).session.logout,
        child: Text(context.t.logout),
      ),
    ),
  );
}

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});
  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int _tab = 0;
  bool _pushStarted = false;
  StreamSubscription<PushTarget>? _pushTaps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pushStarted) return;
    _pushStarted = true;
    PushService.start(context.api).ignore();
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
    _pushTaps?.cancel();
    super.dispose();
  }

  /// Opens the job or ops chat a tapped push points to.
  Future<void> _openPush(PushTarget target) async {
    final nav = Navigator.of(context);
    final api = context.api;
    try {
      switch (target) {
        case BookingTarget(:final bookingId):
          await nav.push(
            MaterialPageRoute<void>(
              builder: (_) => JobDetailScreen(id: bookingId),
            ),
          );
        case ChatTarget(:final threadId):
          final thread = await findChatThread(
            api,
            '/partner/threads',
            threadId,
          );
          if (thread == null) return;
          await nav.push(
            MaterialPageRoute<void>(
              builder: (_) => OpsRoom(
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

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    Widget badge(Widget icon, int n) =>
        Badge(isLabelVisible: n > 0, label: Text('$n'), child: icon);
    // 3D nav art (plan §4): the selected tab pops, the rest stay flat.
    NavigationDestination tab(String id, String label, [int count = 0]) =>
        NavigationDestination(
          icon: badge(Icon3D(id, size: _navIcon), count),
          selectedIcon: badge(Icon3D(id, active: true, size: _navIcon), count),
          label: label,
        );
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          JobsTab(),
          QuotesTab(),
          ScheduleTab(),
          OpsChatTab(),
          MoreTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          tab('p_nav_jobs', t.pTabJobs),
          tab('p_nav_quotes', t.pTabQuotes, pro.unseenQuotes),
          tab('p_nav_schedule', t.pTabSchedule),
          tab('nav_chat', t.tabChat, pro.unreadChats),
          tab('nav_more', t.tabMore),
        ],
      ),
    );
  }
}
