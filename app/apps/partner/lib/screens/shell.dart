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

/// Routes by account state: onboarding -> waiting for approval -> app.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  late final Future<void> _boot = _start();

  Future<void> _start() async {
    final pro = context.proRead;
    await pro.loadAll();
    pro.realtime.connect();
    pro.syncOutbox().ignore();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _boot,
    builder: (context, snap) {
      if (snap.hasError) {
        return Scaffold(
          body: ErrorRetry(
            message: context.t.error(snap.error!),
            retryLabel: context.t.retry,
            onRetry: () => Deps.read(context).session.logout(),
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
          await nav.push(MaterialPageRoute<void>(builder: (_) => JobDetailScreen(id: bookingId)));
        case ChatTarget(:final threadId):
          final thread = await findChatThread(api, '/partner/threads', threadId);
          if (thread == null) return;
          await nav.push(MaterialPageRoute<void>(builder: (_) => OpsRoom(threadId: thread.id, topic: thread.topic, bookingId: thread.bookingId)));
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    Widget badge(IconData i, int n) =>
        Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(i));
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
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: t.pTabJobs,
          ),
          NavigationDestination(
            icon: badge(Icons.request_quote_outlined, pro.unseenQuotes),
            label: t.pTabQuotes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            label: t.pTabSchedule,
          ),
          NavigationDestination(
            icon: badge(Icons.chat_bubble_outline_rounded, pro.unreadChats),
            label: t.tabChat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_rounded),
            label: t.tabMore,
          ),
        ],
      ),
    );
  }
}
