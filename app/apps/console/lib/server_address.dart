import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui/ui.dart';

/// Normalises what the owner typed into an origin (`https://host[:port]`), or null if it is not acceptable.
/// Release builds accept https only; other builds also accept http on loopback or an RFC 1918 LAN host (demo kit).
String? parseServerAddress(String input, {bool release = kReleaseMode}) {
  var s = input.trim();
  if (s.isEmpty || s.contains(RegExp(r'\s'))) return null;
  if (!s.contains('://')) s = 'https://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty || u.userInfo.isNotEmpty) return null;
  final https = u.scheme == 'https';
  if (!https && !(u.scheme == 'http' && !release && _isLanHost(u.host))) {
    return null;
  }
  // A pasted ".../admin/" link is fine: only the origin is kept.
  return u.origin;
}

bool _isLanHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1') return true;
  final p = host.split('.').map(int.tryParse).toList();
  if (p.length != 4 || p.any((n) => n == null || n < 0 || n > 255)) {
    return false;
  }
  final a = p[0]!, b = p[1]!;
  return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
}

/// True when the API address is not compiled in and there is no same-origin web host: the owner types it once.
bool get needsServerAddress =>
    !kIsWeb && kReleaseMode && const String.fromEnvironment('API_BASE').isEmpty;

class ServerAddressStore {
  const ServerAddressStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _key = 'console.server';

  Future<String?> read() async {
    try {
      final v = await _storage.read(key: _key);
      return v == null ? null : parseServerAddress(v);
    } catch (_) {
      return null; // keystore wiped: ask again
    }
  }

  Future<void> write(String origin) => _storage.write(key: _key, value: origin);
  Future<void> clear() => _storage.delete(key: _key);
}

/// Lets the login screen offer "change server address" when the address was typed in, not compiled in.
class ServerChange extends InheritedWidget {
  const ServerChange({super.key, required this.onChange, required super.child});
  final VoidCallback? onChange;

  static VoidCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServerChange>()?.onChange;

  @override
  bool updateShouldNotify(ServerChange old) => onChange != old.onChange;
}

class ServerAddressScreen extends StatefulWidget {
  const ServerAddressScreen({
    super.key,
    required this.onSaved,
    this.release = kReleaseMode,
  });
  final ValueChanged<String> onSaved;
  final bool release;

  @override
  State<ServerAddressScreen> createState() => _ServerAddressScreenState();
}

class _ServerAddressScreenState extends State<ServerAddressScreen> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final origin = parseServerAddress(
      _controller.text,
      release: widget.release,
    );
    if (origin == null) {
      setState(() => _invalid = true);
      return;
    }
    widget.onSaved(origin);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DahaeLogo(size: 40),
                const SizedBox(height: Space.xl),
                Text(t.cServerTitle, style: context.text.headlineMedium),
                const SizedBox(height: Space.sm),
                Text(t.cServerBody),
                const SizedBox(height: Space.lg),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'https://',
                    errorText: _invalid ? t.cServerInvalid : null,
                  ),
                  onChanged: (_) {
                    if (_invalid) setState(() => _invalid = false);
                  },
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: Space.lg),
                PrimaryButton(label: t.cServerSave, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
