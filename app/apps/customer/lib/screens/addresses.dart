import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../location.dart';
import '../state.dart';
import 'household_editor.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.moreAddresses)),
      body: app.addresses.isEmpty
          ? EmptyState(
              icon: Icons.home_work_rounded,
              title: t.addressEmpty,
              hue: ServiceHues.moveIn,
            )
          : RefreshIndicator(
              onRefresh: () => app.loadAddresses().catchError((Object e) {
                if (context.mounted) showToast(context, t.error(e));
              }),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Space.gutter),
                children: [
                  for (final a in app.addresses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: AppCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AddressFormScreen(existing: a),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              a.kind == 'office'
                                  ? Icons.business_rounded
                                  : Icons.home_rounded,
                              color: context.primary,
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a.label} · ${t.pyeong('${a.sizePyeong}')}',
                                    style: context.text.titleSmall,
                                  ),
                                  Text(
                                    '${a.roadAddress} ${a.detail}',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.addressAdd,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddressFormScreen()),
          ),
        ),
      ),
    );
  }
}

/// Add / edit. District comes from the service-area list; size is required (studio rule).
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({
    super.key,
    this.existing,
    this.location = const PluginLocationDevice(),
  });
  final Address? existing;

  /// Where "use my current location" reads from; tests pass a fake.
  final LocationDevice location;
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _road = TextEditingController(
    text: widget.existing?.roadAddress ?? '',
  );
  late final _detail = TextEditingController(
    text: widget.existing?.detail ?? '',
  );
  late final _size = TextEditingController(
    text: widget.existing?.sizePyeong.toString() ?? '',
  );
  late String _kind = widget.existing?.kind ?? 'home';
  late String? _district = widget.existing?.districtCode;
  final _query = TextEditingController();
  bool _busy = false;
  // Road search: null while the server's feature check is pending (typed entry shows meanwhile).
  bool? _searchOn;
  bool _manual = false;
  bool _searching = false;
  bool _searched = false;
  // Localized server message for the last failed search (shown inline; typed entry stays below).
  String? _searchError;
  List<AddressHit> _hits = const [];
  // "Use my current location": the suggestion waits here until the customer confirms it; nothing is saved from it.
  bool _locating = false;
  String? _suggestion;
  // Why there is no suggestion (permission, services off, timeout ...); typed entry stays below.
  String? _locationNote;
  // Household profile; the editor reports every change. Starts as the saved one so an untouched save keeps it.
  late Json _household = widget.existing?.household ?? const {};

  @override
  void initState() {
    super.initState();
    addressSearchEnabled(context.api).then((on) {
      if (mounted) setState(() => _searchOn = on);
    });
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) {
      showToast(context, context.t.addressSearchMinChars);
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final hits = await searchAddresses(context.api, q);
      if (mounted) {
        setState(() {
          _hits = hits;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hits = const [];
          _searchError = context.t.error(e);
        });
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Fills the road field from a result; the customer then adds the unit (detail) themselves.
  void _pick(AddressHit h) {
    setState(() {
      _road.text = h.road;
      _hits = const [];
      _searched = false;
    });
  }

  /// Asks for the location terms consent the first time (stored server-side), then suggests an address.
  Future<void> _useLocation() async {
    final t = context.t;
    final api = context.api;
    setState(() {
      _locating = true;
      _suggestion = null;
      _locationNote = null;
    });
    try {
      final consents = await api.get('/me/consents') as Json;
      final agreed = (consents['items'] as List).cast<Json>().any(
        (i) => i['kind'] == 'location' && i['granted'] == true,
      );
      if (!agreed) {
        if (!mounted || !await _askLocationConsent(t)) return;
        await api.put('/me/consents', {
          'consents': [
            {
              'kind': 'location',
              'granted': true,
              'version': consents['version'],
            },
          ],
        });
      }
      final address = await suggestCurrentAddress(widget.location);
      if (mounted) setState(() => _suggestion = address);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationNote = t.locationFailure(e.reason));
    } catch (e) {
      if (mounted) setState(() => _locationNote = t.error(e));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<bool> _askLocationConsent(T t) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.locConsentTitle),
        content: SingleChildScrollView(child: Text(t.locConsentBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.locConsentAgree),
          ),
        ],
      ),
    );
    return agreed == true;
  }

  /// The customer confirmed the suggestion: it fills the road field, which stays editable.
  void _acceptSuggestion() {
    setState(() {
      _road.text = _suggestion!;
      _suggestion = null;
    });
  }

  bool get _valid {
    final size = int.tryParse(_size.text);
    return _label.text.trim().isNotEmpty &&
        _road.text.trim().isNotEmpty &&
        _district != null &&
        size != null &&
        size >= 1 &&
        size <= 500;
  }

  Future<void> _save() async {
    // Guest drafts stay on screen while the sign-in sheet is up, so nothing typed is lost.
    if (!await requireSignIn(context) || !mounted) return;
    setState(() => _busy = true);
    try {
      final saved = await context.appRead.saveAddress({
        'kind': _kind,
        'label': _label.text.trim(),
        'road_address': _road.text.trim(),
        'detail': _detail.text.trim(),
        'district_code': _district,
        'size_pyeong': int.parse(_size.text),
        'household': _household,
      }, id: widget.existing?.id);
      if (!mounted) return;
      showToast(context, context.t.addressSaved);
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    try {
      await context.appRead.deleteAddress(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _road, _detail, _size, _query]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    InputDecoration deco(String label, [String? hint, String? helper]) =>
        InputDecoration(labelText: label, hintText: hint, helperText: helper);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? t.addressAdd : t.edit),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'home',
                label: Text(t.addressHome),
                icon: const Icon(Icons.home_rounded),
              ),
              ButtonSegment(
                value: 'office',
                label: Text(t.addressOffice),
                icon: const Icon(Icons.business_rounded),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _label,
            maxLength: 40,
            decoration: deco(
              t.addressLabel,
              t.addressLabelHint,
            ).copyWith(counterText: ''),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _district,
            decoration: deco(t.addressDistrict),
            items: [
              for (final d in seoulDistricts)
                DropdownMenuItem(value: d.code, child: Text(d.name(lang))),
            ],
            onChanged: (v) => setState(() => _district = v),
          ),
          const SizedBox(height: Space.md),
          if (locationSupported) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _locating ? null : _useLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(t.locUseCurrent),
              ),
            ),
            if (_locating) const LinearProgressIndicator(),
            if (_locationNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Text(
                  _locationNote!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            if (_suggestion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.locSuggestionTitle, style: context.text.bodySmall),
                      Text(_suggestion!, style: context.text.titleSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _suggestion = null),
                            child: Text(t.close),
                          ),
                          TextButton(
                            onPressed: _acceptSuggestion,
                            child: Text(t.locUseAddress),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (_searchOn == true && !_manual) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: deco(t.addressSearch, t.addressSearchHint),
                  ),
                ),
                const SizedBox(width: Space.xs),
                IconButton.filledTonal(
                  tooltip: t.addressSearchButton,
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _searching ? null : _search,
                ),
              ],
            ),
            for (final h in _hits)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: AppCard(
                  onTap: () => _pick(h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.road, style: context.text.titleSmall),
                      Text(
                        [
                          h.building,
                          h.jibun,
                          h.zip,
                        ].where((x) => x.isNotEmpty).join(' · '),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(top: Space.xs),
                child: LinearProgressIndicator(),
              ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  _searchError!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            if (_searched && _hits.isEmpty && _searchError == null)
              Text(t.addressNoResults, style: context.text.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _manual = true),
                child: Text(t.addressManualEntry),
              ),
            ),
          ],
          TextField(
            controller: _road,
            maxLength: 200,
            decoration: deco(t.addressRoad).copyWith(counterText: ''),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _detail,
            maxLength: 200,
            decoration: deco(t.addressDetail).copyWith(counterText: ''),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _size,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: deco(t.addressSize, null, t.addressSizeHelp),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.lg),
          HouseholdEditor(
            initial: widget.existing?.household ?? const {},
            onChanged: (h) => _household = h,
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.save,
          busy: _busy,
          onPressed: _valid ? _save : null,
        ),
      ),
    );
  }
}
