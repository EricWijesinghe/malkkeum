import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api.dart';

/// Body sender for `POST /v1/client-errors` (the app passes `api.post('/client-errors', body)`).
typedef ErrorSend = Future<void> Function(Map<String, Object> body);

const _maxPerMinute = 5;
const _maxDistinct = 50;
const _maxMessageChars = 1000;
const _maxStackChars = 4000;

final _email = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
final _jwt = RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]*');
final _secretParam = RegExp(r'((?:token|key|code|secret|password|auth)[\w-]*=)[^&\s]+', caseSensitive: false);
// Phone-like and card-like digit runs (dashes or spaces allowed), as client_errors.rs. Runs glued to
// letters are left alone: release stack traces are hex addresses that `flutter symbolize` needs.
final _digitRun = RegExp(r'(?<!\w)\+?\d[\d\- ]{7,}\d(?!\w)');

/// Removes what must never leave the device: e-mails, phone and card numbers, tokens, codes.
/// The server scrubs again; this side also catches tokens the server rule does not know.
String scrubErrorText(String text) => text
    .replaceAll(_jwt, '[redacted]')
    .replaceAllMapped(_secretParam, (m) => '${m[1]}[redacted]')
    .replaceAll(_email, '[redacted]')
    .replaceAllMapped(_digitRun, (m) => _digits.allMatches(m[0]!).length >= 9 ? '[redacted]' : m[0]!);

final _digits = RegExp(r'\d');

/// Crash and error reports to the API's own `client_errors` table (no third-party SDK).
///
/// Wired by [ErrorReporter.run] in each `main()`: Flutter framework errors, uncaught async errors and
/// errors outside any zone handler. Screens report the unexpected errors they catch with [reportError].
/// Reports are scrubbed, capped, deduplicated and limited to [_maxPerMinute] a minute; a failed send is
/// dropped and never reported again (no loops). Only release builds send unless [enabled] says so.
class ErrorReporter {
  ErrorReporter({required this.app, this.send, Future<String> Function()? version, bool? enabled, DateTime Function()? clock})
    : _version = version ?? _installedVersion,
      enabled = enabled ?? kReleaseMode,
      _clock = clock ?? DateTime.now;

  /// The `app` label client_errors.rs accepts (`android`, `ios`, `web`, `windows`, `partner_android`, ...).
  final String app;

  /// Set once the API client exists (console sets it per server); null drops reports.
  ErrorSend? send;
  final bool enabled;
  final Future<String> Function() _version;
  final DateTime Function() _clock;
  final _seen = <String>{};
  DateTime? _windowStart;
  int _inWindow = 0;
  String? _cachedVersion;

  /// The reporter the uncaught-error hooks and [reportError] use. Null (tests, before startup): no-op.
  static ErrorReporter? current;

  static Future<String> _installedVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  /// Installs the hooks and runs [body] (the rest of `main`) in a guarded zone, so errors from
  /// unawaited futures anywhere in the app are reported too. Earlier handlers still run (console output).
  static void run(ErrorReporter reporter, Future<void> Function() body) {
    current = reporter;
    runZonedGuarded(() {
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        reporter.report(details.exception, details.stack, context: details.context?.toDescription());
        (previous ?? FlutterError.presentError)(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        reporter.report(error, stack);
        debugPrint('uncaught: $error');
        return true;
      };
      body().catchError((Object e, StackTrace s) => reporter.report(e, s));
    }, (error, stack) {
      reporter.report(error, stack);
      debugPrint('uncaught: $error');
    });
  }

  /// Sends one report. Returns false when it was not sent (disabled, duplicate, over the limit, no sender).
  Future<bool> report(Object error, StackTrace? stack, {String? context}) async {
    final send = this.send;
    if (!enabled || send == null || app.isEmpty) return false;
    final message = scrubErrorText(_cap('${context == null ? '' : '$context: '}$error'.trim(), _maxMessageChars));
    if (message.isEmpty || !_admit(message)) return false;
    try {
      _cachedVersion ??= await _version();
      await send({
        'app': app,
        'version': _cachedVersion!,
        'message': message,
        'stack': scrubErrorText(_cap(stack?.toString() ?? '', _maxStackChars)),
      });
      return true;
    } on Object catch (e) {
      // Never report a failed report: that is how loops start.
      debugPrint('error report not sent: $e');
      return false;
    }
  }

  bool _admit(String message) {
    final key = message.split('\n').first;
    if (_seen.contains(key) || _seen.length >= _maxDistinct) return false;
    final now = _clock();
    final start = _windowStart;
    if (start == null || now.difference(start) >= const Duration(minutes: 1)) {
      _windowStart = now;
      _inWindow = 0;
    }
    if (_inWindow >= _maxPerMinute) return false;
    _inWindow++;
    _seen.add(key);
    return true;
  }

  static String _cap(String s, int max) => s.length <= max ? s : s.substring(0, max);
}

/// For catch blocks that turn an error into a toast or an error state: reports what is unexpected
/// (a parse `TypeError`, a plugin `PlatformException`). Server and network answers ([ApiException])
/// are expected and stay local.
void reportError(Object error, [StackTrace? stack]) {
  if (error is ApiException) return;
  ErrorReporter.current?.report(error, stack ?? StackTrace.current).ignore();
}
