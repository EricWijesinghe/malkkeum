part of 'more.dart';

class PayoutAccountScreen extends StatefulWidget {
  const PayoutAccountScreen({super.key});
  @override
  State<PayoutAccountScreen> createState() => _PayoutAccountState();
}

class _PayoutAccountState extends State<PayoutAccountScreen> {
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  Json? _current;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.api
        .get('/partner/payout-account')
        .then(
          (v) {
            if (mounted) setState(() => _current = v as Json?);
          },
          onError: (Object e) {
            if (mounted) showToast(context, context.t.error(e));
          },
        )
        .ignore();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final v =
          await context.api.put('/partner/payout-account', {
                'bank': _bank.text,
                'account_number': _number.text,
                'holder': _holder.text,
              })
              as Json;
      if (!mounted) return;
      setState(() => _current = v);
      _number.clear();
      showToast(context, context.t.pAccountSaved);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_bank, _number, _holder]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = _current;
    return Scaffold(
      appBar: AppBar(title: Text(t.pPayoutAccount)),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          if (c != null)
            AppCard(
              color: context.colors.freshTint,
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c['bank']} •••• ${c['account_last4']}\n${c['holder']}',
                          style: context.text.titleSmall,
                        ),
                        const SizedBox(height: Space.xs),
                        Tag(
                          label: c['verified_at'] == null
                              ? t.pUnverified
                              : t.pVerified,
                          hue: c['verified_at'] == null
                              ? StatusHues.consultation
                              : StatusHues.assigned,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _bank,
            decoration: InputDecoration(labelText: t.pBank),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            ],
            decoration: InputDecoration(labelText: t.pAccountNumber),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _holder,
            decoration: InputDecoration(labelText: t.pHolder),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.save,
          busy: _busy,
          onPressed:
              _bank.text.isEmpty ||
                  _number.text.length < 8 ||
                  _holder.text.isEmpty
              ? null
              : _save,
        ),
      ),
    );
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamState();
}

class _TeamState extends State<TeamScreen> {
  final _view = GlobalKey<AsyncViewState<List<Json>>>();

  Future<void> _invite() async {
    final t = context.t;
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      title: t.pInvite,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: t.accountName),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.accountPhone),
            ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.pInvite),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final api = context.api;
      try {
        await api.post('/partner/team', {
          'name': name.text,
          'phone': phone.text,
        });
        if (mounted) showToast(context, t.pInviteSent);
        await _view.currentState?.reload();
      } catch (e) {
        if (mounted) showToast(context, t.error(e));
      }
    }
    disposeAfterClose([name, phone]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.pTeam)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _invite,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(t.pInvite),
      ),
      body: AsyncView<List<Json>>(
        key: _view,
        load: () async =>
            (await context.api.get('/partner/team') as List).cast<Json>(),
        builder: (context, members, reload) => ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: [
            for (final m in members)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    ((m['name'] as String).isEmpty
                        ? '?'
                        : (m['name'] as String).characters.first),
                  ),
                ),
                title: Text(
                  (m['name'] as String).isEmpty
                      ? formatKoreanPhone(m['phone'] as String)
                      : m['name'] as String,
                ),
                subtitle: Text(formatKoreanPhone(m['phone'] as String)),
                trailing: m['role'] == 'owner'
                    ? Tag(label: t.pOwner, hue: StatusHues.confirmed)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m['invite_status'] == 'invited')
                            Tag(
                              label: t.pInvited,
                              hue: StatusHues.consultation,
                            ),
                          IconButton(
                            tooltip: t.pRemove,
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () async {
                              try {
                                await context.api.delete(
                                  '/partner/team/${m['id']}',
                                );
                                await reload();
                              } catch (e) {
                                if (context.mounted) {
                                  showToast(context, t.error(e));
                                }
                              }
                            },
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
