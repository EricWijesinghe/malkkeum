import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../main.dart';
import '../state.dart';

class PartnerIntro extends StatelessWidget {
  const PartnerIntro({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: Space.xl),
              Row(children: [
                Text(partnerBrand.name, style: context.text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(width: Space.xs),
                const Tag(label: 'PARTNER', hue: ServiceHue(Color(0xFF1E3B3A), Color(0xFF8FE0D6), Color(0xFF1E3B3A))),
              ]),
              const Spacer(),
              Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                for (final c in const ['bathroom', 'kitchen', 'aircon', 'sofa', 'move_in', 'mattress']) ServiceGlyph(c, size: 64),
              ]),
              const SizedBox(height: Space.xxl),
              Text(context.t.pIntroTitle, style: context.text.displaySmall?.copyWith(color: Colors.white)),
              const SizedBox(height: Space.sm),
              Text(context.t.pIntroBody, style: context.text.bodyLarge?.copyWith(color: const Color(0xFFC3C9D3))),
              const SizedBox(height: Space.xxl),
              PrimaryButton(
                label: context.t.introStart,
                color: partnerBrand.fresh,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _PhoneScreen())),
              ),
            ]),
          ),
        ),
      );
}

class _PhoneScreen extends StatefulWidget {
  const _PhoneScreen();
  @override
  State<_PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<_PhoneScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final dev = await Deps.read(context).session.requestOtp(_digits);
        setState(() {
          _sent = true;
          if (dev != null) _code.text = dev;
        });
      });

  Future<void> _verify() => _run(() async {
        final deps = Deps.read(context);
        await deps.session.verifyOtp(_digits, _code.text, audience: 'partner');
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        Text(_sent ? t.loginCodeTitle : t.loginPhoneTitle, style: context.text.headlineSmall),
        const SizedBox(height: Space.xl),
        TextField(
          controller: _phone,
          enabled: !_sent,
          autofocus: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          decoration: InputDecoration(hintText: t.loginPhoneHint),
          onChanged: (_) => setState(() {}),
        ),
        if (_sent) ...[
          const SizedBox(height: Space.md),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(hintText: '••••••'),
            onChanged: (v) => v.length == 6 ? _verify() : setState(() {}),
          ),
          TextButton(onPressed: _busy ? null : _send, child: Text(t.loginResend)),
        ],
      ]),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: _sent ? t.loginVerify : t.loginSendCode,
          busy: _busy,
          onPressed: _sent ? (_code.text.length == 6 ? _verify : null) : (_digits.length >= 10 ? _send : null),
        ),
      ),
    );
  }
}

/// First-run: name, team, services and districts. Then staff approve the account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final _name = TextEditingController(text: context.proRead.name);
  late final _team = TextEditingController(text: context.proRead.teamName);
  late final Set<String> _services = {...(context.proRead.prefs['services'] as List? ?? const []).cast<String>()};
  late final Set<String> _districts = {...(context.proRead.prefs['districts'] as List? ?? const []).cast<String>()};
  bool _busy = false;

  static const _codes = ['studio', 'kitchen', 'bathroom', 'mattress', 'aircon', 'sofa', 'move_out', 'move_in'];

  bool get _valid => _name.text.trim().isNotEmpty && _team.text.trim().isNotEmpty && _services.isNotEmpty && _districts.isNotEmpty;

  Future<void> _save() async {
    setState(() => _busy = true);
    final pro = context.proRead;
    try {
      await pro.api.patch('/partner/me', {'name': _name.text.trim(), 'team_name': _team.text.trim(), 'locale': context.lang});
      await pro.savePrefs({...pro.prefs, 'services': _services.toList(), 'districts': _districts.toList()});
      await pro.loadProfile();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _team.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pOnbTitle)),
      body: ListView(padding: const EdgeInsets.all(Space.gutter), children: [
        TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: t.pOnbName, counterText: ''), onChanged: (_) => setState(() {})),
        const SizedBox(height: Space.md),
        TextField(controller: _team, maxLength: 40, decoration: InputDecoration(labelText: t.pOnbTeam, counterText: ''), onChanged: (_) => setState(() {})),
        const SizedBox(height: Space.xl),
        SectionTitle(t.pOnbServices),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in _codes)
            FilterChip(
              avatar: Icon(serviceIcon(c), size: 18, color: ServiceHues.of(c).tone),
              label: Text(t.serviceShort(c)),
              selected: _services.contains(c),
              onSelected: (on) => setState(() => on ? _services.add(c) : _services.remove(c)),
            ),
        ]),
        const SizedBox(height: Space.xl),
        SectionTitle(t.pOnbAreas),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final d in seoulDistricts)
            FilterChip(label: Text(d.name(context.lang)), selected: _districts.contains(d.code), onSelected: (on) => setState(() => on ? _districts.add(d.code) : _districts.remove(d.code))),
        ]),
      ]),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t.pOnbDone, busy: _busy, onPressed: _valid ? _save : null)),
    );
  }
}
