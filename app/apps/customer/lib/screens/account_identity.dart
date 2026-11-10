import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// Drop-in row for the account screen (coordinator: add `const IdentityEntryTile()` to the
/// AccountScreen list in more.dart). Opens the PASS identity check.
class IdentityEntryTile extends StatelessWidget {
  const IdentityEntryTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(context.t.apIdentityTitle),
        subtitle: Text(context.t.apIdentityUnverified),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountIdentityScreen())),
      );
}

class AccountIdentityScreen extends StatefulWidget {
  const AccountIdentityScreen({super.key});

  @override
  State<AccountIdentityScreen> createState() => _AccountIdentityScreenState();
}

class _AccountIdentityScreenState extends State<AccountIdentityScreen> {
  bool _verified = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Status comes from /me when the server reports it; absent means not verified yet.
    context.appRead.api.get('/me').then((v) {
      if (mounted && v is Json) setState(() => _verified = v['identity_verified'] as bool? ?? false);
    }).ignore();
  }

  Future<void> _verify() async {
    final app = context.appRead;
    setState(() => _busy = true);
    try {
      final id = await identityVerifierFor(app.api.baseUrl).verify(context);
      if (id == null) return;
      await submitIdentity(app.api, id);
      if (!mounted) return;
      setState(() => _verified = true);
      showToast(context, context.t.apIdentityDone);
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.apIdentityTitle)),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        AppCard(
          child: Row(children: [
            Icon(_verified ? Icons.verified_rounded : Icons.verified_user_outlined, size: 40, color: _verified ? context.colors.fresh : context.colors.inkMuted),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_verified ? t.apIdentityVerified : t.apIdentityUnverified, style: context.text.titleMedium),
                const SizedBox(height: Space.xxs),
                Text(t.apIdentityBody, style: context.text.bodySmall),
              ]),
            ),
          ]),
        ),
      ]),
      bottomNavigationBar: _verified
          ? null
          : BottomActionBar(child: PrimaryButton(label: t.apIdentityAction, busy: _busy, onPressed: _verify)),
    );
  }
}
