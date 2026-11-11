import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/outbox.dart';
import 'package:test_support/test_support.dart';

const _complete = '/partner/jobs/bk-1/complete';

void main() {
  late TestEnv env;
  late CompletionOutbox box;
  var online = true;
  ApiReply? refusal;

  setUp(() async {
    online = true;
    refusal = null;
    final fake = FakeApi();
    fake.onPost('/uploads', (_) => {'url': 'https://cdn.test/${fake.callsTo('POST', '/uploads').length}.jpg'});
    fake.onPost(_complete, (_) {
      if (!online) throw const SocketException('no signal');
      if (refusal != null) return refusal;
      return {'ok': true, 'net': 1000, 'payout_date': null};
    });
    env = await TestEnv.create(fake: fake, role: 'partner');
    box = CompletionOutbox(Directory.systemTemp.createTempSync('outbox_test'));
  });

  tearDown(() => box.dir.deleteSync(recursive: true));

  Future<QueuedCompletion> completion({required String id, bool ready = true}) async => QueuedCompletion(
    basePath: '/partner',
    bookingId: id,
    before: [await box.stash(Uint8List.fromList([1, 2, 3]), id)],
    after: [await box.stash(Uint8List.fromList([4, 5, 6]), id)],
    checklist: [true, true, true, true],
    ready: ready,
  );

  test('send uploads the missing photos, completes the job, and removes the entry and its files', () async {
    final c = await completion(id: 'bk-1');
    final files = [for (final p in c.photos) File(p.file)];
    await box.save(c);

    final r = await box.send(env.api, c);

    expect(r['net'], 1000);
    expect(env.fake.callsTo('POST', '/uploads'), hasLength(2));
    final sent = env.fake.lastCall('POST', _complete)!.json;
    expect(sent['before_photos'], ['https://cdn.test/1.jpg']);
    expect(sent['after_photos'], ['https://cdn.test/2.jpg']);
    expect(await box.find('bk-1'), isNull);
    expect([for (final f in files) f.existsSync()], everyElement(isFalse));
  });

  test('a lost connection keeps the ready entry; the next drain uploads nothing twice', () async {
    final c = await completion(id: 'bk-1');
    c.ready = true;
    await box.save(c);
    online = false;

    await box.drain(env.api);

    final kept = await box.find('bk-1');
    expect(kept, isNotNull, reason: 'queued, not dropped');
    expect(kept!.ready, isTrue);
    expect(kept.photos.every((p) => p.url != null), isTrue, reason: 'photos went up before the completion failed');
    expect(env.fake.callsTo('POST', '/uploads'), hasLength(2));

    online = true;
    await box.drain(env.api);

    expect(env.fake.callsTo('POST', '/uploads'), hasLength(2), reason: 'no re-upload');
    expect(env.fake.callsTo('POST', _complete), hasLength(2));
    expect(await box.find('bk-1'), isNull);
  });

  test('a draft uploads its photos but is never completed', () async {
    final c = await completion(id: 'bk-1', ready: false);
    await box.save(c);

    await box.drain(env.api);

    expect(env.fake.callsTo('POST', '/uploads'), hasLength(2));
    expect(env.fake.callsTo('POST', _complete), isEmpty);
    final kept = await box.find('bk-1');
    expect(kept!.ready, isFalse);
    expect(kept.photos.every((p) => p.url != null), isTrue);
  });

  test('a server refusal is recorded on the entry instead of dropping it', () async {
    final c = await completion(id: 'bk-1');
    c.ready = true;
    await box.save(c);
    refusal = const ApiReply(409, {'error': {'code': 'job_not_active'}});

    await box.drain(env.api);

    final kept = await box.find('bk-1');
    expect(kept, isNotNull);
    expect(kept!.error, 'job_not_active');
  });
}
