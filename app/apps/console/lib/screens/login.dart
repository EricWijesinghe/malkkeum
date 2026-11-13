import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../server_address.dart';
import '../state.dart';
import 'staff_mfa.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  StaffMfaChallenge? _challenge;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await Deps.read(
        context,
      ).session.staffLogin(_email.text.trim(), _password.text);
      if (mounted && challenge != null) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.status == 401
              ? context.t.cLoginFailed
              : context.t.error(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.gutter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
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
                            const DahaeLogo(size: 40),
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
                        const SizedBox(height: Space.xl),
                        Text(
                          '${BrandConfig.placeholder.name} ${t.cTitle}',
                          style: context.text.headlineMedium,
                        ),
                        const SizedBox(height: Space.xl),
                        TextField(
                          controller: _email,
                          autofillHints: const [AutofillHints.username],
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: t.cEmail),
                        ),
                        const SizedBox(height: Space.sm),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: t.cPassword,
                            errorText: _error,
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: Space.lg),
                        PrimaryButton(
                          label: t.cLogin,
                          busy: _busy,
                          onPressed: _login,
                        ),
                        if (ServerChange.of(context) case final change?)
                          TextButton(
                            onPressed: change,
                            child: Text(t.cServerChange),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
