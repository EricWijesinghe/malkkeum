import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'screens/auth.dart';
import 'state.dart';

/// Why a guest is asked to sign in. The sheet title says what the sign-in unlocks.
enum SignInReason {
  generic,
  quote,
  book,
  chat,
  account;

  String title(T t) => switch (this) {
    SignInReason.generic => t.guestSheetTitle,
    SignInReason.quote => t.guestReasonQuote,
    SignInReason.book => t.guestReasonBook,
    SignInReason.chat => t.guestReasonChat,
    SignInReason.account => t.guestReasonAccount,
  };
}

/// Sign-in only when a protected action needs it. Resolves true once signed in; the caller then
/// carries on with its own state (the booking draft), so nothing the guest entered is lost.
Future<bool> requireSignIn(
  BuildContext context, {
  SignInReason reason = SignInReason.generic,
}) async {
  final session = Deps.read(context).session;
  if (session.signedIn) return true;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _SignInSheet(session: session, reason: reason),
  );
  if (ok != true) return false;
  // The sheet closed before the account finished loading, so the caller's own state
  // (and the name step for a nameless account) is handled here, after the sheet.
  if (context.mounted && await completeSignIn(context)) {
    if (!context.mounted) return true;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }
  return true;
}

/// Hosts the normal phone and code screens in a nested navigator and closes itself on success.
class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.session, required this.reason});
  final Session session;
  final SignInReason reason;

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
    if (widget.session.signedIn && mounted)
      Navigator.of(context, rootNavigator: true).pop(true);
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
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.sm,
            ),
            child: Text(widget.reason.title(t), style: context.text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.md,
            ),
            child: Text(
              t.guestSheetBody,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => const PhoneScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
