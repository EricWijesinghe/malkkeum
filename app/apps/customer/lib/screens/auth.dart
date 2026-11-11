import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// First screen: aurora mesh behind floating service orbs that drift with the pointer.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          // Fills the screen on normal phones; scrolls instead of overflowing on small ones with large text.
          child: LayoutBuilder(builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: Space.xl),
              StaggerIn(index: 0, child: Text(BrandConfig.placeholder.name, style: context.text.titleLarge?.copyWith(color: context.primary, fontWeight: FontWeight.w800))),
              Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 120), child: const _OrbField()))),
              StaggerIn(index: 1, child: Text(t.introTitle, style: context.text.displaySmall)),
              const SizedBox(height: Space.sm),
              StaggerIn(index: 2, child: Text(t.introBody, style: context.text.bodyLarge?.copyWith(color: context.colors.inkSoft))),
              const SizedBox(height: Space.xxl),
              PrimaryButton(label: t.introStart, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PhoneScreen()))),
              const SizedBox(height: Space.sm),
              Center(child: Text(t.loginTerms, style: context.text.labelSmall, textAlign: TextAlign.center)),
            ]),
          )),
            ),
          )),
        ),
      ),
    );
  }
}

/// Eight service orbs at staggered depths; the sun in the middle stays put.
class _OrbField extends StatelessWidget {
  const _OrbField();

  @override
  Widget build(BuildContext context) => const AspectRatio(
        aspectRatio: 1,
        child: ParallaxField(
          range: 22,
          items: [
            ParallaxItem(alignment: Alignment(-0.62, -0.78), depth: 0.6, phase: 0.0, child: ServiceGlyph('studio', size: 72)),
            ParallaxItem(alignment: Alignment(0.02, -0.95), depth: 0.9, phase: 0.2, child: ServiceGlyph('kitchen', size: 64)),
            ParallaxItem(alignment: Alignment(0.68, -0.7), depth: 0.5, phase: 0.4, child: ServiceGlyph('bathroom', size: 78)),
            ParallaxItem(alignment: Alignment(-0.9, -0.05), depth: 1.0, phase: 0.6, child: ServiceGlyph('mattress', size: 74)),
            ParallaxItem(alignment: Alignment(0.86, 0.02), depth: 0.7, phase: 0.8, child: ServiceGlyph('aircon', size: 66)),
            ParallaxItem(alignment: Alignment(-0.38, 0.5), depth: 0.4, phase: 0.1, child: ServiceGlyph('sofa', size: 60)),
            ParallaxItem(alignment: Alignment(0.42, 0.62), depth: 0.8, phase: 0.3, child: ServiceGlyph('move_out', size: 72)),
            ParallaxItem(alignment: Alignment(-0.84, 0.72), depth: 0.6, phase: 0.5, child: ServiceGlyph('move_in', size: 58)),
            ParallaxItem(alignment: Alignment.center, depth: 0.2, child: _Sun()),
          ],
        ),
      );
}

class _Sun extends StatelessWidget {
  const _Sun();

  @override
  Widget build(BuildContext context) {
    final sun = context.colors.sun;
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [sun.withValues(alpha: 0.9), sun.withValues(alpha: 0.35)]),
        boxShadow: [BoxShadow(color: sun.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: 2)],
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 40, color: Colors.white),
    );
  }
}

String _pretty(String digits) {
  if (digits.length < 4) return digits;
  if (digits.length < 8) return '${digits.substring(0, 3)}-${digits.substring(3)}';
  final mid = digits.length == 11 ? 7 : 6;
  return '${digits.substring(0, 3)}-${digits.substring(3, mid)}-${digits.substring(mid)}';
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _busyProvider;
  String? _error;

  String get _digits => _ctrl.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => RegExp(r'^01[016789]\d{7,8}$').hasMatch(_digits);

  /// Social sign-in: SDK token -> /auth/social. A new account without a verified phone
  /// verifies one first, then asks for a name if it has none.
  Future<void> _socialSignIn(SocialSignIn provider) async {
    final deps = Deps.read(context);
    final nav = Navigator.of(context);
    setState(() => _busyProvider = provider.provider);
    try {
      final result = await signInWithSocial(context: context, api: deps.session.api, session: deps.session, provider: provider, audience: 'customer');
      if (result == null || !mounted) return;
      if (result.needsPhone) {
        await nav.push<bool>(MaterialPageRoute<bool>(builder: (_) => PhoneAttachScreen(api: deps.session.api, audience: 'customer')));
        if (!mounted) return;
      }
      // The language picked before sign-in (or the device one) becomes the account language.
      deps.app.api.patch('/me', {'locale': deps.locale.effectiveCode}).ignore();
      await deps.app.loadProfile();
      if (!mounted) return;
      if (result.isNew || deps.app.name.isEmpty) {
        await nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
      } else {
        nav.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = Deps.read(context).session;
    try {
      final dev = await session.requestOtp(_digits, locale: Deps.read(context).locale.effectiveCode);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CodeScreen(phone: _digits, devCode: dev)));
    } catch (e) {
      // Inline, not a toast: a toast can land behind the keyboard or the sign-in sheet.
      if (mounted) setState(() => _error = context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: const EdgeInsets.all(Space.gutter), children: [
          Text(context.t.loginPhoneTitle, style: context.text.headlineSmall),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: context.text.headlineSmall,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              TextInputFormatter.withFunction((_, v) => TextEditingValue(text: _pretty(v.text), selection: TextSelection.collapsed(offset: _pretty(v.text).length))),
            ],
            decoration: InputDecoration(hintText: context.t.loginPhoneHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _valid && !_busy ? _send() : null,
          ),
          const SizedBox(height: Space.xl),
          SocialSignInRow(
            providers: defaultSocialSignIns(Deps.read(context).session.api.baseUrl),
            busyProvider: _busyProvider,
            devMode: isDevApiBase(Deps.read(context).session.api.baseUrl),
            onSelected: _socialSignIn,
              ),
            ]),
            ),
            if (_error != null) _InlineError(message: _error!, onRetry: _valid && !_busy ? _send : null),
            BottomActionBar(child: PrimaryButton(label: context.t.loginSendCode, busy: _busy, onPressed: _valid ? _send : null)),
          ]),
        ),
      );
}

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key, required this.phone, this.devCode});
  final String phone;
  final String? devCode;
  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  late final _ctrl = TextEditingController(text: widget.devCode ?? '');
  bool _busy = false;
  int _left = 60;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _left = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _left > 0 ? _left-- : t.cancel()));
  }

  Future<void> _verify() async {
    if (_ctrl.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final deps = Deps.read(context);
    try {
      final isNew = await deps.session.verifyOtp(widget.phone, _ctrl.text, audience: 'customer');
      if (!mounted) return;
      // The language picked before sign-in (or the device one) becomes the account language.
      deps.app.api.patch('/me', {'locale': deps.locale.effectiveCode}).ignore();
      await deps.app.loadProfile();
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (isNew || deps.app.name.isEmpty) {
        await nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
      } else {
        nav.popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.t.error(e));
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      final dev = await Deps.read(context).session.requestOtp(widget.phone, locale: Deps.read(context).locale.effectiveCode);
      if (dev != null) _ctrl.text = dev;
      _tick();
    } catch (e) {
      if (mounted) setState(() => _error = context.t.error(e));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: const EdgeInsets.all(Space.gutter), children: [
          Text(context.t.loginCodeTitle, style: context.text.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(context.t.loginCodeSentTo(_pretty(widget.phone)), style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted)),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _ctrl.text.length == 6 ? _verify() : null,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: context.text.headlineMedium?.copyWith(letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onChanged: (v) => v.length == 6 ? _verify() : setState(() {}),
            decoration: const InputDecoration(hintText: '••••••'),
          ),
          const SizedBox(height: Space.md),
          if (_error != null) _InlineError(message: _error!, onRetry: _ctrl.text.length == 6 && !_busy ? _verify : null),
          Center(
            child: TextButton(
              onPressed: _left == 0 ? _resend : null,
              child: Text(_left == 0 ? context.t.loginResend : '${context.t.loginResend} ($_left)'),
            ),
          ),
              ]),
            ),
            BottomActionBar(child: PrimaryButton(label: context.t.loginVerify, busy: _busy, onPressed: _ctrl.text.length == 6 ? _verify : null)),
          ]),
        ),
      );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.appRead;
    try {
      await app.api.patch('/me', {'name': _ctrl.text.trim(), 'locale': context.lang});
      await Future.wait([app.loadProfile(), app.loadCoupons()]);
      if (!mounted) return;
      showToast(context, context.t.welcomeToast);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: const EdgeInsets.all(Space.gutter), children: [
                Text(context.t.profileTitle, style: context.text.headlineSmall),
                const SizedBox(height: Space.xl),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(hintText: context.t.profileNameHint, counterText: ''),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _ctrl.text.trim().isEmpty || _busy ? null : _save(),
                ),
              ]),
            ),
            if (_error != null) _InlineError(message: _error!, onRetry: _ctrl.text.trim().isEmpty || _busy ? null : _save),
            BottomActionBar(child: PrimaryButton(label: context.t.profileDone, busy: _busy, onPressed: _ctrl.text.trim().isEmpty ? null : _save)),
          ]),
        ),
      );
}

/// Failure copy that stays on screen with a retry, so a tap is never a silent no-op.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
        child: Row(children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.danger)),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.t.retry)),
        ]),
      );
}
