import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'login.dart';
import 'staff_mfa.dart';

/// Signed-out entry: a fresh install (no staff yet) asks for the owner account,
/// otherwise the normal login. A failed check falls back to login.
class ConsoleEntry extends StatefulWidget {
  const ConsoleEntry({super.key});
  @override
  State<ConsoleEntry> createState() => _ConsoleEntryState();
}

class _ConsoleEntryState extends State<ConsoleEntry> {
  late final Future<bool> _needsAdmin = _check();

  Future<bool> _check() async {
    try {
      final s = await context.api.get('/setup') as Json;
      return s['needs_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _needsAdmin,
    builder: (context, snap) {
      if (!snap.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snap.data! ? const FirstRunScreen() : const LoginScreen();
    },
  );
}

class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key});
  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  StaffMfaChallenge? _challenge;
  static const _minPassword = 12;
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _name, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    final t = context.t;
    if (_password.text.length < _minPassword) {
      setState(() => _error = t.cWeakPassword);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final deps = Deps.read(context);
    try {
      await deps.state.api.post('/setup/admin', {
        'code': _code.text,
        'name': _name.text,
        'email': _email.text.trim(),
        'password': _password.text,
      });
      final challenge = await deps.session.staffLogin(
        _email.text.trim(),
        _password.text,
      );
      if (mounted && challenge != null) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.status) {
          403 => t.cWrongSetupCode,
          409 => t.cLoginFailed,
          400 => e.code == 'weak_password' ? t.cWeakPassword : t.cInvalidValue,
          _ => t.error(e),
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: AuroraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                child: _challenge != null
                    ? StaffMfaPanel(
                        challenge: _challenge!,
                        onCancel: () => setState(() => _challenge = null),
                      )
                    : AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in const [
                                  'bathroom',
                                  'kitchen',
                                  'aircon',
                                  'sofa',
                                  'move_in',
                                ])
                                  ServiceGlyph(c, size: 40),
                              ],
                            ),
                            const SizedBox(height: Space.lg),
                            Text(
                              t.cFirstRunTitle,
                              style: context.text.headlineSmall,
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              t.cFirstRunBody,
                              style: context.text.bodyMedium,
                            ),
                            const SizedBox(height: Space.lg),
                            TextField(
                              controller: _code,
                              textCapitalization: TextCapitalization.characters,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: t.cFirstRunCode,
                                hintText: 'ABCD-2345-EFGH',
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                            TextField(
                              controller: _name,
                              autofillHints: const [AutofillHints.name],
                              decoration: InputDecoration(labelText: t.cName),
                            ),
                            const SizedBox(height: Space.sm),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.newUsername],
                              decoration: InputDecoration(labelText: t.cEmail),
                            ),
                            const SizedBox(height: Space.sm),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: t.cPassword,
                                helperText: t.cPasswordRule,
                                errorText: _error,
                              ),
                              onSubmitted: (_) => _create(),
                            ),
                            const SizedBox(height: Space.lg),
                            PrimaryButton(
                              label: t.cFirstRunCreate,
                              busy: _busy,
                              onPressed: _create,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
