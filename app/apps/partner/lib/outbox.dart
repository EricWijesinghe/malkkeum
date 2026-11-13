import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:path_provider/path_provider.dart';

/// One completion photo. [file] stays on disk until the server has it ([url] set), so a bad signal never loses it.
class QueuedPhoto {
  QueuedPhoto(this.file, {this.url});

  factory QueuedPhoto.fromJson(Json j) => QueuedPhoto(j['file'] as String, url: j['url'] as String?);

  final String file;
  String? url;

  Json toJson() => {'file': file, 'url': url};
}

/// A job-day completion (or a draft still being filled in). [ready] means the pro tapped complete.
class QueuedCompletion {
  QueuedCompletion({
    required this.basePath,
    required this.bookingId,
    required this.before,
    required this.after,
    required this.checklist,
    this.ready = false,
    this.error,
  });

  factory QueuedCompletion.fromJson(Json j) => QueuedCompletion(
    basePath: j['basePath'] as String,
    bookingId: j['bookingId'] as String,
    before: [for (final p in j['before'] as List) QueuedPhoto.fromJson(p as Json)],
    after: [for (final p in j['after'] as List) QueuedPhoto.fromJson(p as Json)],
    checklist: [for (final c in j['checklist'] as List) c as bool],
    ready: j['ready'] as bool? ?? false,
    error: j['error'] as String?,
  );

  /// `/partner` for the owner, `/member` for a team member.
  final String basePath;
  final String bookingId;
  final List<QueuedPhoto> before;
  final List<QueuedPhoto> after;
  final List<bool> checklist;
  bool ready;

  /// Last non-network failure from the server, kept so the entry is never dropped silently.
  String? error;

  Iterable<QueuedPhoto> get photos => [...before, ...after];
  bool get isEmpty => photos.isEmpty && !checklist.contains(true);

  Json get payload => {
    'before_photos': [for (final p in before) p.url],
    'after_photos': [for (final p in after) p.url],
    'checklist': checklist,
  };

  Json toJson() => {
    'basePath': basePath,
    'bookingId': bookingId,
    'before': [for (final p in before) p.toJson()],
    'after': [for (final p in after) p.toJson()],
    'checklist': checklist,
    'ready': ready,
    'error': error,
  };
}

/// Job-day completions and their photos, kept on disk. One entry per booking, one folder per account.
/// Uploads run one at a time (mobile data), and [drain] stops at the first network error.
class CompletionOutbox {
  CompletionOutbox(this.root);

  static Future<CompletionOutbox> open() async {
    final root = await getApplicationSupportDirectory();
    return CompletionOutbox(Directory('${root.path}/outbox'));
  }

  final Directory root;

  /// Who is signed in (set by PartnerState), so one pro's queue is never sent under another's sign-in.
  String? Function() account = () => null;

  Directory get dir {
    final who = account();
    return who == null ? root : Directory('${root.path}/${who.replaceAll(RegExp(r'[^\w-]'), '_')}');
  }

  File _entryFile(String bookingId) => File('${dir.path}/$bookingId.json');

  /// Null for a file that does not decode (the app was killed mid-write by an older build). The file is
  /// renamed out of the queue, not deleted, so it never blocks the other entries or its job's screen.
  static Future<QueuedCompletion?> _read(File f) async {
    final raw = await f.readAsString();
    try {
      return QueuedCompletion.fromJson(jsonDecode(raw) as Json);
    } catch (_) {
      await f.rename('${f.path}.corrupt');
      return null;
    }
  }

  Future<QueuedCompletion?> find(String bookingId) async {
    final f = _entryFile(bookingId);
    return await f.exists() ? _read(f) : null;
  }

  Future<List<QueuedCompletion>> all() async {
    await _adoptUnscoped();
    if (!await dir.exists()) return const [];
    return [
      for (final e in await dir.list().toList())
        if (e is File && e.path.endsWith('.json'))
          ?await _read(e),
    ];
  }

  /// Entries queued before folders were per account go to whoever is signed in at the upgrade.
  Future<void> _adoptUnscoped() async {
    if (dir.path == root.path || !await root.exists()) return;
    for (final e in await root.list().toList()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      await dir.create(recursive: true);
      await e.rename('${dir.path}/${e.uri.pathSegments.last}');
    }
  }

  /// Written to a temp file and renamed over the entry, so a kill mid-write never leaves half an entry.
  Future<void> save(QueuedCompletion c) async {
    await dir.create(recursive: true);
    final f = _entryFile(c.bookingId);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(c.toJson()), flush: true);
    await tmp.rename(f.path);
  }

  /// Keeps the picked photo on disk before any upload attempt.
  Future<QueuedPhoto> stash(Uint8List bytes, String bookingId) async {
    final f = File('${dir.path}/photos/$bookingId-${DateTime.now().microsecondsSinceEpoch}.jpg');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
    return QueuedPhoto(f.path);
  }

  /// Deletes an entry and its photo files: sent, or a draft the pro emptied.
  Future<void> remove(QueuedCompletion c) async {
    for (final p in c.photos) {
      await _delete(File(p.file));
    }
    await _delete(_entryFile(c.bookingId));
  }

  Future<void> dropPhoto(QueuedPhoto p) => _delete(File(p.file));

  static Future<void> _delete(File f) async {
    if (await f.exists()) await f.delete();
  }

  /// Uploads one photo and records its URL. The caller saves the entry.
  Future<void> uploadPhoto(ApiClient api, QueuedPhoto p) async {
    final name = File(p.file).uri.pathSegments.last;
    p.url = await api.upload(await File(p.file).readAsBytes(), name);
  }

  Future<void> _uploadMissing(ApiClient api, QueuedCompletion c) async {
    for (final p in c.photos) {
      if (p.url != null) continue;
      await uploadPhoto(api, p);
      await save(c);
    }
  }

  /// Uploads what is missing, completes the job, then removes the entry. Throws on failure; progress is kept.
  Future<Json> send(ApiClient api, QueuedCompletion c) async {
    await _uploadMissing(api, c);
    final r = await api.post('${c.basePath}/jobs/${c.bookingId}/complete', c.payload) as Json;
    await remove(c);
    return r;
  }

  /// Sends what can be sent now. Stops at the first network error; other errors are recorded on the entry.
  Future<void> drain(ApiClient api) async {
    for (final c in await all()) {
      try {
        if (c.ready) {
          await send(api, c);
        } else {
          await _uploadMissing(api, c);
        }
      } on ApiException catch (e) {
        if (e.isNetwork) return;
        c.error = e.code;
        await save(c);
      } on FileSystemException {
        c.error = 'photo_missing';
        await save(c);
      }
    }
  }
}
