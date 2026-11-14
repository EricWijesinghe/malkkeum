import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../guest.dart';
import '../location.dart';
import '../state.dart';
import 'household_editor.dart';

/// Saved addresses (p25): 집 / 사무실 tabs over one list; a tab switch cross-fades it.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen>
    with SingleTickerProviderStateMixin {
  static const _kinds = ['home', 'office'];
  late final _tabs = TabController(length: _kinds.length, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.t;
    final c = context.colors;
    final kind = _kinds[_tabs.index];
    final shown = app.addresses.where((a) => a.kind == kind).toList();
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(t.moreAddresses),
        bottom: app.addresses.isEmpty
            ? null
            : TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: t.addressHome),
                  Tab(text: t.addressOffice),
                ],
              ),
      ),
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
              child: FadeThroughSwitcher(
                child: ListView(
                  key: ValueKey(kind),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Space.gutter),
                        child: Text(
                          t.addressEmpty,
                          style: context.text.bodyMedium?.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                      ),
                    for (final (i, a) in shown.indexed)
                      StaggerIn(
                        key: ValueKey(a.id),
                        index: i,
                        child: _AddressRow(address: a),
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: t.addressAdd,
          onPressed: () => showAddressForm(context),
        ),
      ),
    );
  }
}

/// Bold label, then "address · N평" (p25). Opens the edit form.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address});
  final Address address;

  @override
  Widget build(BuildContext context) {
    final a = address;
    final t = context.t;
    return InkWell(
      onTap: () => showAddressForm(context, existing: a),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.md,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.label,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.roadAddress} ${a.detail} · ${t.pyeong('${a.sizePyeong}')}',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// As tall as the address field beside it.
const _searchButtonSize = Size(64, 56);

/// Share of the screen the form sheet covers: the page behind stays visible above it (p25).
const _formSheetHeight = 0.92;

/// Opens the add / edit form as a sheet over the caller (design p25). Completes with the
/// saved address, or null when it was closed or the address deleted.
Future<Address?> showAddressForm(BuildContext context, {Address? existing}) =>
    showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: _formSheetHeight,
        child: AddressFormScreen(existing: existing),
      ),
    );

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
  // The search words; the saved road address (_road) only ever comes from a picked result or the location suggestion.
  final _query = TextEditingController();
  late final _detail = TextEditingController(
    text: widget.existing?.detail ?? '',
  );
  late final _size = TextEditingController(
    text: widget.existing?.sizePyeong.toString() ?? '',
  );
  late String _kind = widget.existing?.kind ?? 'home';
  late String? _district = widget.existing?.districtCode;
  bool _busy = false;
  // Road search: null while the server's feature check is pending (the field takes typed entry either way).
  bool? _searchOn;
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

  /// Looks up the words typed in the address field; a picked result replaces them.
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

  /// Fills the road address and its district together from a result; the customer adds only the unit (detail).
  void _pick(AddressHit h) {
    setState(() {
      _road.text = h.road;
      _district = seoulDistricts.any((d) => d.code == h.districtCode)
          ? h.districtCode
          : null;
      _query.clear();
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
    for (final c in [_label, _road, _query, _detail, _size]) {
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
    final searchOn = _searchOn == true;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        // A sheet (design p25): the title, then close on the right.
        automaticallyImplyLeading: false,
        title: Text(widget.existing == null ? t.addressAdd : t.edit),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
          const CloseButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          // Two tiles side by side (design p25), not a joined segmented bar.
          Row(
            children: [
              for (final (i, (kind, label)) in [
                ('home', t.addressHome),
                ('office', t.addressOffice),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: Space.sm),
                Expanded(
                  child: _KindTile(
                    label: label,
                    selected: _kind == kind,
                    onTap: () => setState(() => _kind = kind),
                  ),
                ),
              ],
            ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: searchOn ? _query : _road,
                  maxLength: 200,
                  textInputAction: searchOn ? TextInputAction.search : null,
                  onSubmitted: searchOn ? (_) => _search() : null,
                  decoration: deco(
                    t.addressRoad,
                    searchOn ? t.addressSearchHint : null,
                  ).copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Design p25: the ink "검색" button, there only when the server can search.
              if (searchOn) ...[
                const SizedBox(width: Space.xs),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.ink,
                    foregroundColor: context.colors.surface,
                    minimumSize: _searchButtonSize,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                  ),
                  onPressed: _searching ? null : _search,
                  child: Text(t.addressSearchButton),
                ),
              ],
            ],
          ),
          if (searchOn && _road.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: AppCard(
                child: Text(_road.text, style: context.text.titleSmall),
              ),
            ),
          if (searchOn) ...[
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
          ],
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _detail,
                  maxLength: 200,
                  decoration: deco(t.addressDetail).copyWith(counterText: ''),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _size,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: deco(
                    t.addressSize,
                  ).copyWith(suffixText: t.pyeong('').trim()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            switch (context.app.service('studio')?.maxPyeong) {
              final max? => t.addressPyeongNote('$max'),
              null => t.addressSizeHelp,
            },
            style: context.text.bodySmall?.copyWith(
              color: context.colors.inkSoft,
            ),
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

/// One of the 집 / 사무실 tiles: tinted with a brand border when chosen, outlined otherwise.
class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Radii.chip);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? c.primaryTint : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? context.primary : c.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  color: selected ? context.primary : c.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
