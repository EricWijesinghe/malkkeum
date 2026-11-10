import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';

/// First screen: a colorful mosaic of the services and one clear call to action.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const codes = ['studio', 'kitchen', 'bathroom', 'mattress', 'aircon', 'sofa', 'move_out', 'move_in'];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: Space.xl),
            Text(BrandConfig.placeholder.name, style: context.text.titleLarge?.copyWith(color: context.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.xxl),
            Expanded(
              child: Center(
                child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: Space.md,
                crossAxisSpacing: Space.md,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < codes.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 420 + i * 60),
                      curve: Motion.emphasized,
                      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
                      child: LayoutBuilder(builder: (_, c) => ServiceGlyph(codes[i], size: c.maxWidth)),
                    ),
                  Center(child: Icon(Icons.auto_awesome_rounded, size: 48, color: BrandConfig.placeholder.sun)),
                ],
              ),
              ),
            ),
            Text(context.t.introTitle, style: context.text.displaySmall),
            const SizedBox(height: Space.sm),
            Text(context.t.introBody, style: context.text.bodyLarge?.copyWith(color: context.colors.inkSoft)),
            const SizedBox(height: Space.xxl),
            PrimaryButton(label: context.t.introStart, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PhoneScreen()))),
            const SizedBox(height: Space.sm),
            Center(child: Text(context.t.loginTerms, style: context.text.labelSmall, textAlign: TextAlign.center)),
          ]),
        ),
      ),
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

  String get _digits => _ctrl.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => RegExp(r'^01[016789]\d{7,8}$').hasMatch(_digits);

  Future<void> _send() async {
    setState(() => _busy = true);
    final session = Deps.read(context).session;
    try {
      final dev = await session.requestOtp(_digits);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CodeScreen(phone: _digits, devCode: dev)));
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
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
        body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
          Text(context.t.loginPhoneTitle, style: context.text.headlineSmall),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: context.text.headlineSmall,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              TextInputFormatter.withFunction((_, v) => TextEditingValue(text: _pretty(v.text), selection: TextSelection.collapsed(offset: _pretty(v.text).length))),
            ],
            decoration: InputDecoration(hintText: context.t.loginPhoneHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _valid ? _send() : null,
          ),
        ]),
        bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: context.t.loginSendCode, busy: _busy, onPressed: _valid ? _send : null)),
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
    setState(() => _busy = true);
    final deps = Deps.read(context);
    try {
      final isNew = await deps.session.verifyOtp(widget.phone, _ctrl.text, audience: 'customer');
      if (!mounted) return;
      await deps.app.loadProfile();
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (isNew || deps.app.name.isEmpty) {
        await nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
      } else {
        nav.popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final dev = await Deps.read(context).session.requestOtp(widget.phone);
      if (dev != null) _ctrl.text = dev;
      _tick();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
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
        body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
          Text(context.t.loginCodeTitle, style: context.text.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(context.t.loginCodeSentTo(_pretty(widget.phone)), style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted)),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: context.text.headlineMedium?.copyWith(letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onChanged: (v) => v.length == 6 ? _verify() : setState(() {}),
            decoration: const InputDecoration(hintText: '••••••'),
          ),
          const SizedBox(height: Space.md),
          Center(
            child: TextButton(
              onPressed: _left == 0 ? _resend : null,
              child: Text(_left == 0 ? context.t.loginResend : '${context.t.loginResend} ($_left)'),
            ),
          ),
        ]),
        bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: context.t.loginVerify, busy: _busy, onPressed: _ctrl.text.length == 6 ? _verify : null)),
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

  Future<void> _save() async {
    setState(() => _busy = true);
    final app = context.appRead;
    try {
      await app.api.patch('/me', {'name': _ctrl.text.trim(), 'locale': context.lang});
      await Future.wait([app.loadProfile(), app.loadCoupons()]);
      if (!mounted) return;
      showToast(context, context.t.welcomeToast);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
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
        body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
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
          ),
        ]),
        bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: context.t.profileDone, busy: _busy, onPressed: _ctrl.text.trim().isEmpty ? null : _save)),
      );
}
