import 'dart:async';
import 'dart:convert';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ui/ui.dart';

/// In-memory stand-in for the OS keystore.
class _MemStorage extends FlutterSecureStorage {
  _MemStorage();
  final data = <String, String>{};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data[key];

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async =>
      value == null ? data.remove(key) : data[key] = value;

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data.remove(key);
}

/// Thrown by a fake transport: the client sees a dropped connection.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}

http.Response _json(int status, Object body) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

ApiClient _client(MockClientHandler handler, {FlutterSecureStorage? storage}) {
  final session = Session(namespace: 't', storage: storage ?? _MemStorage());
  return ApiClient(baseUrl: 'http://127.0.0.1:8080', session: session, client: MockClient(handler));
}

/// Fake SDK: returns a fixed token, or null to simulate the user cancelling.
class _FakeSocial extends SocialSignIn {
  const _FakeSocial(this.provider, this.token);
  @override
  final String provider;
  final String? token;
  @override
  Future<String?> obtainToken(BuildContext context) async => token;
}

/// Fake Apple SDK: identity token plus authorization code, like `AppleSocialSignIn`.
class _FakeApple extends SocialSignIn {
  const _FakeApple();
  @override
  String get provider => 'apple';
  @override
  Future<String?> obtainToken(BuildContext context) async => 'id-tok';
  @override
  Future<Map<String, String>?> obtainCredential(BuildContext context) async => appleCredentialFields('id-tok', 'code-1');
}

/// Fake PG: returns a scripted outcome and records the intent it was given.
class _FakeLauncher extends PaymentLauncher {
  _FakeLauncher(this.outcome);
  final PaymentOutcome? outcome;
  CheckoutIntent? seen;

  @override
  Future<PaymentOutcome?> pay({required BuildContext context, required CheckoutIntent intent}) async {
    seen = intent;
    return outcome;
  }
}

const _intent = {'id': 'co1', 'amount': 39000, 'order_name': '욕실 청소', 'method': 'kakaopay', 'store_id': 'store-1', 'channel_key': 'ch-1'};

/// Captures a BuildContext for calls that need one (no widgets are built beyond a Builder).
Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(Builder(builder: (c) {
    ctx = c;
    return const SizedBox();
  }));
  return ctx;
}

void main() {
  group('social sign-in', () {
    test('dev stub keeps one stable id per provider', () async {
      final storage = _MemStorage();
      final kakao = DevSocialSignIn('kakao', storage: storage);
      final first = await kakao.devToken();
      expect(first, startsWith('dev:'));
      expect(await DevSocialSignIn('kakao', storage: storage).devToken(), first, reason: 'same tester, same account');
      expect(await DevSocialSignIn('naver', storage: storage).devToken(), isNot(first));
    });

    test('Naver is offered once its client id is set; the secret never ships in the app', () {
      final keys = {'NAVER_CLIENT_ID': 'id', 'APP_LINK_DOMAIN': 'malkkeum.example'};
      expect(providersForKeys(requested: '', keys: keys, ios: false), contains('naver'));
      expect(providersForKeys(requested: '', keys: {'NAVER_CLIENT_ID': ''}, ios: false), isNot(contains('naver')));
      expect(providersForKeys(requested: '', keys: {'NAVER_CLIENT_ID': 'id'}, ios: false), isNot(contains('naver')),
          reason: 'Naver needs the App Link host for its https callback');
    });

    test('Naver uses the https App Link from iOS 17.4; older iOS keeps the custom scheme', () {
      bool app(String v) => naverUsesAppLink(ios: true, osVersion: v);
      expect(app('Version 17.4 (Build 21E213)'), isTrue);
      expect(app('Version 18.0 (Build 22A)'), isTrue);
      expect(app('Version 17.3.1 (Build 21D50)'), isFalse);
      expect(app('Version 16.7 (Build 20H19)'), isFalse);
      expect(app('unknown'), isTrue, reason: 'unknown version takes the secure path');
      expect(naverUsesAppLink(ios: false, osVersion: 'Version 9'), isTrue);
    });

    test('local API base offers every provider as a dev stub, Apple only where allowed', () {
      final storage = _MemStorage();
      final all = socialSignInsFor(apiBase: 'http://127.0.0.1:8080', storage: storage, appleOk: true);
      expect(all.map((p) => p.provider), ['kakao', 'naver', 'google', 'apple']);
      expect(all.every((p) => p is DevSocialSignIn), isTrue);
      final noApple = socialSignInsFor(apiBase: 'http://10.0.2.2:8080', storage: storage, appleOk: false);
      expect(noApple.map((p) => p.provider), ['kakao', 'naver', 'google']);
    });

    test('production base shows only configured providers, never dev stubs', () {
      final storage = _MemStorage();
      final none = socialSignInsFor(apiBase: 'https://api.example.com', storage: storage, configured: const {}, appleOk: true);
      expect(none, isEmpty);
      final kakaoOnly = socialSignInsFor(apiBase: 'https://api.example.com', storage: storage, configured: const {'kakao'}, appleOk: true);
      expect(kakaoOnly.single, isNot(isA<DevSocialSignIn>()));
      expect(kakaoOnly.single.provider, 'kakao');
    });

    test('dev base detection', () {
      expect(isDevApiBase('http://127.0.0.1:8080'), isTrue);
      expect(isDevApiBase('http://10.0.2.2:8080'), isTrue);
      expect(isDevApiBase('http://localhost:8080'), isTrue);
      expect(isDevApiBase('https://api.example.com'), isFalse);
      expect(isDevApiBase('http://172.25.243.168:8080'), isTrue, reason: 'demo server on office Wi-Fi');
      expect(isDevApiBase('http://192.168.0.7:8080'), isTrue);
      expect(isDevApiBase('http://10.1.2.3:8080'), isTrue);
      expect(isDevApiBase('http://172.32.0.1:8080'), isFalse);
      expect(isDevApiBase('http://8.8.8.8'), isFalse);
    });

    test('phone attach routes differ by audience', () {
      expect(phoneAttachPath('customer'), '/me/phone');
      expect(phoneAttachPath('partner'), '/partner/me/phone');
    });

    testWidgets('signing in saves tokens and reports needs_phone', (tester) async {
      Object? sent;
      final api = _client((req) async {
        expect(req.url.path, '/v1/auth/social');
        sent = jsonDecode(req.body);
        return _json(200, {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'customer', 'subject': 'u1', 'is_new': true, 'needs_phone': true});
      });
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => signInWithSocial(context: ctx, api: api, session: api.session, provider: const _FakeSocial('kakao', 'tok-1'), audience: 'customer'));
      expect(sent, {'provider': 'kakao', 'token': 'tok-1', 'audience': 'customer'});
      expect(result!.isNew, isTrue);
      expect(result.needsPhone, isTrue);
      expect(api.session.refreshToken, 'r1');
      expect(api.session.signedIn, isTrue);
    });

    test('apple credential carries the authorization code only when Apple gave one', () {
      expect(appleCredentialFields('id-tok', 'code-1'), {'token': 'id-tok', 'authorization_code': 'code-1'});
      expect(appleCredentialFields('id-tok', ''), {'token': 'id-tok'});
      expect(appleCredentialFields('id-tok', null), {'token': 'id-tok'});
    });

    testWidgets('apple sign-in posts the authorization code for server-side revocation', (tester) async {
      Object? sent;
      final api = _client((req) async {
        sent = jsonDecode(req.body);
        return _json(200, {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'customer', 'subject': 'u1'});
      });
      final ctx = await _context(tester);
      await tester.runAsync(() => signInWithSocial(context: ctx, api: api, session: api.session, provider: const _FakeApple(), audience: 'customer'));
      expect(sent, {'provider': 'apple', 'token': 'id-tok', 'authorization_code': 'code-1', 'audience': 'customer'});
    });

    testWidgets('a cancelled SDK sheet makes no request', (tester) async {
      final api = _client((req) async => throw StateError('no request expected'));
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => signInWithSocial(context: ctx, api: api, session: api.session, provider: const _FakeSocial('naver', null), audience: 'partner'));
      expect(result, isNull);
      expect(api.session.signedIn, isFalse);
    });

    test('phone attach and identity post to the right routes', () async {
      final paths = <String>[];
      final api = _client((req) async {
        paths.add(req.url.path);
        return _json(200, {'ok': true});
      });
      await attachPhone(api, audience: 'partner', phone: '01012345678', code: '123456');
      await submitIdentity(api, 'dev:abc');
      expect(paths, ['/v1/partner/me/phone', '/v1/me/identity']);
    });
  });

  group('checkout service', () {
    const body = {'kind': 'booking', 'booking': {'service_code': 'bathroom'}, 'method': 'kakaopay'};

    testWidgets('approved payment confirms and returns the booking', (tester) async {
      final seen = <String>[];
      final api = _client((req) async {
        seen.add('${req.method} ${req.url.path}');
        if (req.url.path == '/v1/checkouts') {
          expect(jsonDecode(req.body), body);
          return _json(200, _intent);
        }
        if (req.url.path == '/v1/bookings/b1') return _json(200, {'id': 'b1', 'status': 1});
        expect(jsonDecode(req.body), {'payment_id': 'dev:paid'});
        return _json(200, {'status': 'paid', 'booking_id': 'b1', 'virtual_account': null});
      });
      final launcher = _FakeLauncher(const PaymentApproved('dev:paid'));
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: launcher).run(ctx, body));
      expect(result, isA<CheckoutPaid>());
      expect((result! as CheckoutPaid).booking?.id, 'b1');
      expect(launcher.seen?.orderName, '욕실 청소');
      expect(seen, ['POST /v1/checkouts', 'POST /v1/checkouts/co1/confirm', 'GET /v1/bookings/b1']);
    });

    testWidgets('virtual account returns the deposit details', (tester) async {
      final api = _client((req) async {
        if (req.url.path == '/v1/checkouts') return _json(200, {..._intent, 'method': 'virtual_account'});
        return _json(200, {
          'status': 'awaiting_deposit',
          'virtual_account': {'bank': '국민', 'account_number': '123-456', 'holder': '말끔', 'due': '2030-01-02T23:59:00Z'},
        });
      });
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: _FakeLauncher(const PaymentApproved('dev:va'))).run(ctx, body));
      expect(result, isA<CheckoutAwaitingDeposit>());
      final account = (result! as CheckoutAwaitingDeposit).account;
      expect(account.accountNumber, '123-456');
      expect(account.due, isNotNull);
    });

    testWidgets('closing the PG window cancels without confirming', (tester) async {
      final api = _client((req) async => req.url.path == '/v1/checkouts' ? _json(200, _intent) : throw StateError('no confirm expected'));
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: _FakeLauncher(null)).run(ctx, body));
      expect(result, isA<CheckoutCancelled>());
    });

    testWidgets('a declined payment fails with the PG code', (tester) async {
      final api = _client((req) async => _json(200, _intent));
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: _FakeLauncher(const PaymentRejected('payment_failed'))).run(ctx, body));
      expect((result! as CheckoutFailed).code, 'payment_failed');
    });

    testWidgets('slot filled after payment is reported as paid_slot_full', (tester) async {
      final api = _client((req) async {
        if (req.url.path == '/v1/checkouts') return _json(200, _intent);
        return _json(409, {'error': {'code': 'slot_full'}});
      });
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: _FakeLauncher(const PaymentApproved('dev:paid'))).run(ctx, body));
      expect((result! as CheckoutFailed).code, 'paid_slot_full');
    });

    testWidgets('slot filled before payment keeps slot_full', (tester) async {
      final api = _client((req) async => _json(409, {'error': {'code': 'slot_full'}}));
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => CheckoutService(api: api, launcher: _FakeLauncher(null)).run(ctx, body));
      expect((result! as CheckoutFailed).code, 'slot_full');
    });
  });

  group('one key per payment action', () {
    const body = {'kind': 'booking', 'booking': {'service_code': 'bathroom'}, 'method': 'kakaopay'};
    String? keyOf(http.Request r) => r.headers['Idempotency-Key'];
    CheckoutService service(ApiClient api, PaymentLauncher launcher, {_MemStorage? storage}) =>
        CheckoutService(api: api, launcher: launcher, pending: PendingPayment(storage: storage ?? _MemStorage()), confirmBackoff: const [Duration.zero, Duration.zero, Duration.zero]);

    testWidgets('a lost create reply, then a second tap, reuses the key; a changed draft gets a new one', (tester) async {
      final keys = <String?>[];
      var calls = 0;
      final api = _client((req) async {
        keys.add(keyOf(req));
        if (calls++ == 0) throw const SocketExceptionStub();
        return _json(200, _intent);
      });
      final ctx = await _context(tester);
      final s = service(api, _FakeLauncher(null));
      expect(((await tester.runAsync(() => s.run(ctx, body)))! as CheckoutFailed).code, 'network');
      expect(await tester.runAsync(() => s.run(ctx, body)), isA<CheckoutCancelled>());
      await tester.runAsync(() => s.run(ctx, {...body, 'method': 'card'}));
      expect(keys[0], isNotNull);
      expect(keys[1], keys[0], reason: 'retry of the same action');
      expect(keys[2], isNot(keys[0]), reason: 'a changed request is a new action');
    });

    testWidgets('confirm that times out and then succeeds is paid, with the same key each time', (tester) async {
      final confirmKeys = <String?>[];
      final api = _client((req) async {
        if (req.url.path == '/v1/checkouts') return _json(200, _intent);
        if (req.url.path == '/v1/bookings/b1') return _json(200, {'id': 'b1', 'status': 1});
        confirmKeys.add(keyOf(req));
        if (confirmKeys.length < 3) throw TimeoutException('no reply');
        return _json(200, {'status': 'paid', 'booking_id': 'b1'});
      });
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => service(api, _FakeLauncher(const PaymentApproved('co1'))).run(ctx, body));
      expect((result! as CheckoutPaid).booking?.id, 'b1');
      expect(confirmKeys.toSet(), hasLength(1));
      expect(confirmKeys, hasLength(3));
    });

    testWidgets('confirm answered paid but the booking load fails: still paid, by id', (tester) async {
      final api = _client((req) async {
        if (req.url.path == '/v1/checkouts') return _json(200, _intent);
        if (req.url.path == '/v1/bookings/b1') return _json(503, {'error': {'code': 'unavailable'}});
        return _json(200, {'status': 'paid', 'booking_id': 'b1'});
      });
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => service(api, _FakeLauncher(const PaymentApproved('co1'))).run(ctx, body));
      expect(result, isA<CheckoutPaid>());
      final paid = result! as CheckoutPaid;
      expect(paid.bookingId, 'b1');
      expect(paid.booking, isNull);
    });

    testWidgets('confirm never answering is pending, saved, and resumes to paid', (tester) async {
      var online = false;
      final api = _client((req) async {
        if (req.url.path == '/v1/checkouts') return _json(200, _intent);
        if (req.url.path == '/v1/bookings/b1') return _json(200, {'id': 'b1', 'status': 1});
        if (!online) throw const SocketExceptionStub();
        return _json(200, {'status': 'paid', 'booking_id': 'b1'});
      });
      final storage = _MemStorage();
      final ctx = await _context(tester);
      final result = await tester.runAsync(() => service(api, _FakeLauncher(const PaymentApproved('co1')), storage: storage).run(ctx, body));
      expect(result, isA<CheckoutPending>());
      expect((result! as CheckoutPending).checkoutId, 'co1');

      // Next start: a new service over the same storage finds it and confirms it.
      online = true;
      final later = service(api, _FakeLauncher(null), storage: storage);
      final saved = await tester.runAsync(() => later.pending.load());
      expect(saved?.paymentId, 'co1');
      final resumed = await tester.runAsync(() => later.confirm(saved!.checkoutId, saved.paymentId));
      expect(resumed, isA<CheckoutPaid>());
      expect(await tester.runAsync(() => later.pending.load()), isNull, reason: 'a final answer clears it');
    });

    testWidgets('a malformed response is a failure, never an exception', (tester) async {
      final ctx = await _context(tester);
      final badCreate = _client((req) async => _json(200, ['not', 'a', 'checkout']));
      expect(((await tester.runAsync(() => service(badCreate, _FakeLauncher(null)).run(ctx, body)))! as CheckoutFailed).code, 'unknown');
      final badConfirm = _client((req) async => req.url.path == '/v1/checkouts' ? _json(200, _intent) : _json(200, {'status': 'paid'}));
      final result = await tester.runAsync(() => service(badConfirm, _FakeLauncher(const PaymentApproved('co1'))).run(ctx, body));
      expect((result! as CheckoutFailed).code, 'unknown');
    });

    test('postAction keeps the key after a lost reply and drops it after a final answer', () async {
      final keys = <String?>[];
      final replies = [0, 500, 409, 200, 200];
      final api = _client((req) async {
        keys.add(keyOf(req));
        final status = replies[keys.length - 1];
        if (status == 0) throw const SocketExceptionStub();
        return _json(status, status == 200 ? {'ok': true} : {'error': {'code': 'slot_full'}});
      });
      const cancel = {'accepted_fee': 0};
      for (var i = 0; i < 4; i++) {
        await api.postAction('/bookings/b1/cancel', cancel).then((_) {}, onError: (_) {});
      }
      await api.postAction('/bookings/b1/cancel', cancel);
      expect(keys[1], keys[0], reason: 'network error keeps the key');
      expect(keys[2], keys[0], reason: '5xx keeps the key');
      expect(keys[3], isNot(keys[0]), reason: '409 is a final answer');
      expect(keys[4], isNot(keys[3]), reason: '2xx is a final answer');
    });
  });

  group('fetchers and mapping', () {
    test('payment channels keep their flow', () async {
      final api = _client((req) async {
        expect(req.url.path, '/v1/payments/methods');
        return _json(200, [
          {'code': 'card', 'flow': 'billing'},
          {'code': 'payco', 'flow': 'checkout'},
        ]);
      });
      final channels = await fetchPayChannels(api);
      expect(channels.map((c) => (c.code, c.isBilling)).toList(), [('card', true), ('payco', false)]);
    });

    test('pending deposits skip items without a virtual account', () async {
      final api = _client((req) async {
        expect(req.url.queryParameters['status'], 'awaiting_deposit');
        return _json(200, [
          {'id': 'co1', 'amount': 39000, 'booking_id': 'b1', 'virtual_account': {'bank': 'x', 'account_number': '1', 'holder': 'h', 'due': null}},
          {'id': 'co2', 'amount': 1000},
        ]);
      });
      final deposits = await fetchPendingDeposits(api);
      expect(deposits.map((d) => d.id), ['co1']);
      expect(deposits.single.account.due, isNull);
    });

    test('failure codes map to friendly groups', () {
      expect(payFailureFor('phone_taken'), PayFailure.phoneTaken);
      expect(payFailureFor('paid_slot_full'), PayFailure.paidSlotFull);
      expect(payFailureFor('provider_not_configured'), PayFailure.providerNotConfigured);
      expect(payFailureFor('checkout_expired'), PayFailure.checkoutExpired);
      expect(payFailureFor('timeout'), PayFailure.network);
      expect(payFailureFor('whatever'), PayFailure.unknown);
    });
  });

  testWidgets('dev payment window approves, and closing it cancels', (tester) async {
    final intent = CheckoutIntent.fromJson(_intent);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(BrandConfig.placeholder, Brightness.light),
      locale: const Locale('ko'),
      localizationsDelegates: T.localizationsDelegates,
      supportedLocales: T.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox());
      }),
    ));

    final approved = const DevPaymentLauncher().pay(context: ctx, intent: intent);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-confirm')));
    // Processing spinner animates forever, so pumpAndSettle would time out: advance past the pause.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pay-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pay-done')));
    await tester.pumpAndSettle();
    final ok = await approved;
    expect(ok, isA<PaymentApproved>());
    expect((ok as PaymentApproved).paymentId, 'dev:kakaopay');

    final va = const DevPaymentLauncher().pay(context: ctx, intent: intent);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-method-virtual_account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-confirm')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-done')));
    await tester.pumpAndSettle();
    expect(((await va) as PaymentApproved).paymentId, 'dev:virtual_account');

    final cancelled = const DevPaymentLauncher().pay(context: ctx, intent: intent);
    await tester.pumpAndSettle();
    await tester.tap(find.text('결제 취소'));
    await tester.pumpAndSettle();
    expect(await cancelled, isNull);
  });
}
