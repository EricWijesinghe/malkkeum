import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'screens/auth.dart';
import 'state.dart';

/// Sign-in only when a protected action needs it. Resolves true once signed in; the caller then
/// carries on with its own state (the booking draft), so nothing the guest entered is lost.
Future<bool> requireSignIn(BuildContext context) async {
  final session = Deps.read(context).session;
  if (session.signedIn) return true;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _SignInSheet(session: session),
  );
  return ok ?? false;
}

/// Hosts the normal phone and code screens in a nested navigator and closes itself on success.
class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.session});
  final Session session;

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (widget.session.signedIn && mounted) Navigator.of(context, rootNavigator: true).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
            child: Text(t.guestSheetTitle, style: context.text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
            child: Text(t.guestSheetBody, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft)),
          ),
          Expanded(
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const PhoneScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for a tab that needs an account. Tapping opens the sheet; success rebuilds the tab.
class GuestGate extends StatelessWidget {
  const GuestGate({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.guestSheetTitle, style: context.text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text(t.guestSheetBody, style: context.text.bodyMedium?.copyWith(color: context.colors.inkSoft), textAlign: TextAlign.center),
            const SizedBox(height: Space.lg),
            PrimaryButton(label: t.introStart, onPressed: () => requireSignIn(context)),
          ],
        ),
      ),
    );
  }
}
