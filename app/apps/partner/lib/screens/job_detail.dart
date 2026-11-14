part of 'jobs.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _view = GlobalKey<AsyncViewState<Json>>();
  StreamSubscription<Json>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.proRead.realtime.events.listen((e) {
      if ((e['data'] as Json?)?['booking_id'] == widget.id) {
        _view.currentState?.reload();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<Json> _load() async =>
      await context.api.get('/partner/jobs/${widget.id}') as Json;

  Future<void> _act(Future<void> Function() fn, String done) async {
    try {
      await fn();
      if (!mounted) return;
      HapticFeedback.mediumImpact().ignore();
      showToast(context, done);
      context.proRead.jobsChanged();
      await _view.currentState?.reload();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
      await _view.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: AsyncView<Json>(
      key: _view,
      load: _load,
      builder: (context, d, reload) =>
          RefreshIndicator(onRefresh: reload, child: _body(d)),
    ),
  );

  Widget _body(Json d) {
    final t = context.t;
    final b = d['booking'] as Json;
    final committed = d['committed'] as bool;
    final code = b['service_code'] as String;
    final isQuote = b['is_quote'] as bool;
    final status = (b['status'] as num).toInt();
    final payout = d['payout'] as Json?;
    final hue = ServiceHues.of(code);
    final answers = b['answers'] as Json?;
    final notes = (b['visit_notes'] as Json?) ?? const {};
    final reschedule = b['reschedule'] as Json?;
    final addr = committed
        ? '${(b['address'] as Json)['road_address']} ${(b['address'] as Json)['detail']}'
              .trim()
        : null;
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        if (committed) ...[
          SiteActionsCard(raw: b, act: _act),
          const SizedBox(height: Space.sm),
        ],
        Tilt3D(
          child: AppCard(
            glow: hue.tone,
            color: context.colors.tintOf(hue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ServiceGlyph(code, size: 44),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        t.service(code),
                        style: context.text.titleMedium,
                      ),
                    ),
                    StatusBadge(status: status, label: t.status(status)),
                  ],
                ),
                const SizedBox(height: Space.md),
                Text(
                  isQuote && payout == null ? t.pCustomerEstimate : t.pPayout,
                  style: context.text.labelMedium,
                ),
                Text(
                  payout != null
                      ? context.won((payout['net'] as num).toInt())
                      : context.won((b['estimate'] as num? ?? 0).toInt()),
                  style: context.text.displaySmall,
                ),
                Text(
                  '${t.pBookingNo(b['number'] as String)} · ${t.pyeong('${b['size_pyeong']}')}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (b['cancelled'] == true)
          _banner(
            Icons.event_busy_rounded,
            t.pCancelledBanner,
            StatusHues.cancelled,
          ),
        if (reschedule != null && committed) _rescheduleBanner(reschedule, b),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.event_rounded),
                title: Text(t.pSchedule),
                subtitle: Text(
                  '${dateLabel(DateTime.parse(b['visit_date'] as String), context.lang)} ${slotLabel(context, (b['start_hour'] as num).toInt(), isQuote)}${b['minutes'] == null ? '' : ' · ${t.about(t.duration((b['minutes'] as num).toInt()))}'}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(committed ? t.visitAddress : t.addressDistrict),
                subtitle: Text(
                  addr ?? districtName(context, b['district_code'] as String),
                ),
                trailing: addr == null
                    ? null
                    : IconButton(
                        tooltip: t.pNavigate,
                        icon: const Icon(Icons.directions_rounded),
                        onPressed: () => showNavigateSheet(context, addr),
                      ),
              ),
              if (answers != null)
                ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(t.pSpace),
                  subtitle: Text(_answersText(t, answers)),
                ),
            ],
          ),
        ),
        if (committed) ..._committedSections(d, b, notes, isQuote, status),
        if (payout != null) ...[
          const SizedBox(height: Space.sm),
          AppCard(
            child: Column(
              children: [
                _row(
                  t.listPrice,
                  context.won((payout['gross'] as num).toInt()),
                ),
                _row(
                  t.pFee(context.pro.feeLabel),
                  '−${context.won((payout['fee'] as num).toInt())}',
                ),
                const Divider(height: Space.lg),
                _row(
                  t.pYouGet,
                  context.won((payout['net'] as num).toInt()),
                  bold: true,
                ),
                if (isQuote)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.pAfterBalance,
                      style: context.text.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (!committed) ...[
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: context.colors.inkMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(t.pPrivacyNote, style: context.text.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (!isQuote && status == 1)
            PrimaryButton(
              label: t.pAccept,
              color: context.colors.fresh,
              onPressed: () => _accept(d),
            ),
          if (isQuote && status == 0)
            PrimaryButton(label: t.pSendQuote, onPressed: () => _quote(b)),
        ],
      ],
    );
  }

  List<Widget> _committedSections(
    Json d,
    Json b,
    Json notes,
    bool isQuote,
    int status,
  ) {
    final t = context.t;
    final noteLines = [
      notes['entry'],
      notes['parking'],
      notes['other'],
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    final householdLines = _householdLines(
      (b['household'] as Json?) ?? const {},
    );
    return [
      const SizedBox(height: Space.sm),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text('${t.pCustomer} ${d['customer_name'] ?? ''}'),
              subtitle: Text(t.pQuietHours),
              trailing: IconButton.filledTonal(
                tooltip: t.pCall,
                icon: const Icon(Icons.call_rounded),
                onPressed: () => showToast(context, t.pCallSoon),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(t.pAssignee),
              subtitle: Text(
                (d['assignee'] as Json?)?['name'] as String? ?? '-',
              ),
              trailing: TextButton(
                onPressed: () => _assign(b),
                child: Text(t.change),
              ),
            ),
            if (householdLines.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(t.pHousehold),
                subtitle: Text(householdLines.join('\n')),
              ),
            if (noteLines.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(t.pCustomerRequests),
                subtitle: Text(noteLines.join('\n')),
              ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(t.pTeamMemo),
              subtitle: Text(
                (d['team_memo'] as String?)?.isNotEmpty == true
                    ? d['team_memo'] as String
                    : '-',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _memo(b, d['team_memo'] as String? ?? ''),
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.sm),
      OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: Text(t.pChatOps),
        onPressed: () => openOpsThread(
          context,
          topic: b['service_code'] as String,
          bookingId: b['id'] as String,
        ),
      ),
      if (status == 2 && b['cancelled'] != true) ...[
        const SizedBox(height: Space.xs),
        PrimaryButton(
          label: t.pComplete,
          color: context.colors.fresh,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompleteScreen(
                  bookingId: b['id'] as String,
                  isQuote: isQuote,
                ),
              ),
            );
            await _view.currentState?.reload();
          },
        ),
      ],
    ];
  }

  String _answersText(T t, Json a) {
    final layout = switch (a['layout']) {
      'studio' => t.layout_studio,
      'one_and_half' => t.layout_one_and_half,
      'two_rooms' => t.layout_two_rooms,
      'three_rooms' => t.layout_three_rooms,
      _ => t.layout_four_plus,
    };
    final building = switch (a['building']) {
      'apartment' => t.building_apartment,
      'villa' => t.building_villa,
      'officetel' => t.building_officetel,
      'house' => t.building_house,
      'commercial' => t.building_commercial,
      _ => t.building_other,
    };
    final ac = [
      for (final u in (a['ac_addons'] as List? ?? const []).cast<Json>())
        '${t.unit(u['unit'] as String)} ${t.dfCountUnits('${u['count']}')}',
    ];
    return '$building · $layout · ${t.bathroomsLabel} ${a['bathrooms']} · ${t.balconiesLabel} ${a['balconies']}${a['duplex'] == true ? ' · ${t.duplexTitle}' : ''}'
        '${ac.isEmpty ? '' : '\n${t.service('aircon')}: ${ac.join(', ')}'}';
  }

  /// Household profile as display lines; empty fields are skipped.
  List<String> _householdLines(Json h) {
    final t = context.t;
    String petLabel(String kind) => switch (kind) {
      'dog' => t.pPetDog,
      'cat' => t.pPetCat,
      'bird' => t.pPetBird,
      'fish' => t.pPetFish,
      _ => t.pPetOther,
    };
    String text(String key) => (h[key] as String?)?.trim() ?? '';
    final pets = (h['pets'] as List? ?? const []).cast<Json>();
    final floor = h['floor'];
    final elevator = h['elevator'];
    return [
      if (pets.isNotEmpty)
        '${t.pPets}: ${pets.map((p) => '${petLabel(p['kind'] as String)} ${p['count']}').join(', ')}',
      if (text('allergies').isNotEmpty) '${t.pAllergies}: ${text('allergies')}',
      if (text('preferred_products').isNotEmpty)
        '${t.pPreferredProducts}: ${text('preferred_products')}',
      if (text('parking').isNotEmpty) '${t.pParking}: ${text('parking')}',
      if (floor != null)
        [
          t.pFloor('$floor'),
          if (elevator == true) t.pElevatorYes,
          if (elevator == false) t.pElevatorNo,
        ].join(' · '),
      if (text('notes').isNotEmpty) text('notes'),
    ];
  }

  Widget _row(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(l, style: context.text.bodyMedium),
        const Spacer(),
        Text(
          v,
          style: bold ? context.text.titleMedium : context.text.bodyMedium,
        ),
      ],
    ),
  );

  Widget _banner(IconData i, String text, ServiceHue hue) => Padding(
    padding: const EdgeInsets.only(top: Space.sm),
    child: AppCard(
      color: context.colors.tintOf(hue),
      child: Row(
        children: [
          Icon(i, color: hue.tone),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: context.text.titleSmall)),
        ],
      ),
    ),
  );

  Widget _rescheduleBanner(Json r, Json b) {
    final t = context.t;
    final from =
        '${dateLabel(DateTime.parse(r['from_date'] as String), context.lang)} ${hourLabel((r['from_hour'] as num).toInt(), context.lang)}';
    final to =
        '${dateLabel(DateTime.parse(b['visit_date'] as String), context.lang)} ${hourLabel((b['start_hour'] as num).toInt(), context.lang)}';
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: AppCard(
        color: context.colors.sunTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.pRescheduleBanner(from, to), style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _act(
                      () => context.api.post(
                        '/partner/jobs/${b['id']}/reschedule',
                        {'accept': false},
                      ),
                      t.pSaved,
                    ),
                    child: Text(t.pRescheduleNo),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _act(
                      () => context.api.post(
                        '/partner/jobs/${b['id']}/reschedule',
                        {'accept': true},
                      ),
                      t.pSaved,
                    ),
                    child: Text(t.pRescheduleOk),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(Json d) async {
    final t = context.t;
    final ok = await showAppSheet<bool>(
      context,
      title: t.pAcceptConfirm,
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
            Text(t.pAcceptBody, style: ctx.text.bodyMedium),
            const SizedBox(height: Space.xl),
            PrimaryButton(
              label: t.pAccept,
              color: ctx.colors.fresh,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _act(
        () => context.api.post('/partner/jobs/${widget.id}/accept'),
        t.pAccepted,
      );
    }
  }

  Future<void> _quote(Json b) async {
    final sent = await showQuoteSheet(
      context,
      bookingId: b['id'] as String,
      estimate: (b['estimate'] as num? ?? 0).toInt(),
    );
    if (sent == true && mounted) {
      context.proRead.jobsChanged();
      await _view.currentState?.reload();
    }
  }

  Future<void> _assign(Json b) async {
    final team = (await context.api.get('/partner/team') as List).cast<Json>();
    if (!mounted) return;
    final id = await showAppSheet<String>(
      context,
      title: context.t.pChangeAssignee,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        children: [
          for (final m in team)
            ListTile(
              title: Text(
                (m['name'] as String).isEmpty
                    ? formatKoreanPhone(m['phone'] as String)
                    : m['name'] as String,
              ),
              subtitle: Text(m['role'] == 'owner' ? ctx.t.pOwner : ''),
              onTap: () => Navigator.of(ctx).pop(m['id'] as String),
            ),
        ],
      ),
    );
    if (id == null || !mounted) return;
    final api = context.api;
    await _act(
      () => api.post('/partner/jobs/${b['id']}/assign', {'member_id': id}),
      context.t.pSaved,
    );
  }

  Future<void> _memo(Json b, String current) async {
    final ctrl = TextEditingController(text: current);
    final save = await showAppSheet<bool>(
      context,
      title: context.t.pTeamMemo,
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
              controller: ctrl,
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.t.save),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      final api = context.api;
      await _act(
        () => api.put('/partner/jobs/${b['id']}/memo', {'memo': ctrl.text}),
        context.t.pMemoSaved,
      );
    }
    disposeAfterClose([ctrl]);
  }
}

/// Price input with a live payout preview. Used for new and edited quotes.
Future<bool?> showQuoteSheet(
  BuildContext context, {
  required String bookingId,
  required int estimate,
  int? current,
  String note = '',
  bool edit = false,
}) async {
  final t = context.t;
  final pro = context.proRead;
  final price = TextEditingController(text: '${current ?? estimate}');
  final memo = TextEditingController(text: note);
  var sending = false;
  final result = await showAppSheet<bool>(
    context,
    title: t.pSendQuote,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final amount =
            int.tryParse(price.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
        return Padding(
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
              Text(
                '${t.pCustomerEstimate} ${ctx.won(estimate)}',
                style: ctx.text.bodySmall,
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: ctx.text.headlineSmall,
                decoration: InputDecoration(
                  labelText: t.pQuotePrice,
                  suffixText: currencyUnit(ctx.lang),
                ),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: Space.sm),
              AppCard(
                color: ctx.colors.freshTint,
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t.pYouGet} (${t.pFee(pro.feeLabel)})',
                        style: ctx.text.bodySmall,
                      ),
                    ),
                    RollingAmount(
                      value: pro.payoutFor(amount),
                      format: ctx.won,
                      style: ctx.text.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: memo,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.pQuoteNote),
              ),
              PrimaryButton(
                label: t.pSendQuote,
                busy: sending,
                onPressed: amount <= 0
                    ? null
                    : () async {
                        setSheet(() => sending = true);
                        try {
                          final body = {'amount': amount, 'note': memo.text};
                          if (edit) {
                            await ctx.api.put(
                              '/partner/jobs/$bookingId/quote',
                              body,
                            );
                          } else {
                            await ctx.api.post(
                              '/partner/jobs/$bookingId/quote',
                              body,
                            );
                          }
                          if (!ctx.mounted) return;
                          showToast(ctx, t.pQuoteSent);
                          Navigator.of(ctx).pop(true);
                        } catch (e) {
                          if (ctx.mounted) showToast(ctx, t.error(e));
                        } finally {
                          if (ctx.mounted) setSheet(() => sending = false);
                        }
                      },
              ),
            ],
          ),
        );
      },
    ),
  );
  disposeAfterClose([price, memo]);
  return result;
}

/// Shown above the feed until the partner verifies a phone (social sign-ups start without one).
class _PhoneGate extends StatelessWidget {
  const _PhoneGate();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pro = context.pro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        0,
      ),
      child: AppCard(
        color: context.colors.sunTint,
        child: Row(
          children: [
            Icon(Icons.phone_iphone_rounded, color: context.colors.sun),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(t.err_phone_required, style: context.text.bodyMedium),
            ),
            const SizedBox(width: Space.sm),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PhoneAttachScreen(api: pro.api, audience: 'partner'),
                  ),
                );
                await pro.loadProfile();
              },
              child: Text(t.pVerifyPhone),
            ),
          ],
        ),
      ),
    );
  }
}
