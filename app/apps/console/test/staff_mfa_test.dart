import 'package:console/screens/people.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';
import 'package:ui/ui.dart';

import 'support/console_host.dart';

const _mfaToken = 'mfa-token-1';
const _tokens = {
  'access_token': 'a-1',
  'refresh_token': 'r-1',
  'role': 'staff_admin',
  'subject': 'staff-1',
};

/// Pumps the real sign-in gate and submits the password step; [reply] is what the server answers.
Future<TestEnv> _submitPassword(
  WidgetTester tester,
  FakeApi fake,
  Json reply,
) async {
  stockConsoleApi(fake);
  fake.reply('POST', '/auth/staff/login', reply);
  final env = await TestEnv.create(fake: fake, signedIn: false);
  await pumpConsoleApp(tester, env);
  await settle(tester, duration: const Duration(milliseconds: 500));
  await tester.enterText(find.byType(TextField).at(0), 'ops@example.test');
  await tester.enterText(find.byType(TextField).at(1), 'right-password');
  await tester.tap(find.widgetWithText(PrimaryButton, koT.cLogin));
  await settle(tester);
  return env;
}

/// The selectable text that carries [value] (setup key, otpauth link, recovery codes, reset token).
Finder _selectable(String value) => find.byWidgetPredicate(
  (w) => w is SelectableText && (w.data ?? '').contains(value),
);

void main() {
  testWidgets(
    'an enrolled staff member is asked for the authenticator code, then signs in',
    (tester) async {
      setViewport(tester, wideSize);
      final fake = FakeApi()..reply('POST', '/auth/staff/mfa/verify', _tokens);
      final env = await _submitPassword(tester, fake, {
        'mfa_required': true,
        'mfa_token': _mfaToken,
      });

      expect(find.text(koT.cMfaTitle), findsOneWidget);
      expect(env.session.signedIn, isFalse);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.widgetWithText(PrimaryButton, koT.cMfaVerify));
      await settle(tester);

      final sent = fake.lastCall('POST', '/auth/staff/mfa/verify')!.json;
      expect(sent['mfa_token'], _mfaToken);
      expect(sent['code'], '123456');
      expect(sent.containsKey('recovery_code'), isFalse);
      expect(env.session.signedIn, isTrue);
      await unmount(tester);
    },
  );

  testWidgets('a recovery code can be used instead of the authenticator code', (
    tester,
  ) async {
    setViewport(tester, wideSize);
    final fake = FakeApi()..reply('POST', '/auth/staff/mfa/verify', _tokens);
    final env = await _submitPassword(tester, fake, {
      'mfa_required': true,
      'mfa_token': _mfaToken,
    });

    await tester.tap(find.widgetWithText(TextButton, koT.cMfaUseRecovery));
    await settle(tester, duration: const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField).first, 'ABCD-EFGH-JKLM-NPQR');
    await tester.tap(find.widgetWithText(PrimaryButton, koT.cMfaVerify));
    await settle(tester);

    final sent = fake.lastCall('POST', '/auth/staff/mfa/verify')!.json;
    expect(sent['recovery_code'], 'ABCD-EFGH-JKLM-NPQR');
    expect(sent.containsKey('code'), isFalse);
    expect(env.session.signedIn, isTrue);
    await unmount(tester);
  });

  testWidgets(
    'a wrong authenticator code shows the message and stays on the second factor',
    (tester) async {
      setViewport(tester, wideSize);
      final fake = FakeApi()
        ..reply('POST', '/auth/staff/mfa/verify', {
          'error': {'code': 'mfa_invalid_code'},
        }, status: 400);
      final env = await _submitPassword(tester, fake, {
        'mfa_required': true,
        'mfa_token': _mfaToken,
      });

      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.tap(find.widgetWithText(PrimaryButton, koT.cMfaVerify));
      await settle(tester);

      expect(find.text(koT.cMfaInvalid), findsOneWidget);
      expect(env.session.signedIn, isFalse);
      await unmount(tester);
    },
  );

  testWidgets(
    'an admin without an authenticator sets it up, keeps the recovery codes, then signs in',
    (tester) async {
      setViewport(tester, wideSize);
      const secret = 'JBSWY3DPEHPK3PXP';
      final fake = FakeApi()
        ..reply('POST', '/auth/staff/mfa/enrol', {
          'secret': secret,
          'otpauth_uri':
              'otpauth://totp/Malkkeum%20staff:ops%40example.test?secret=$secret',
        })
        ..reply('POST', '/auth/staff/mfa/enrol/confirm', {
          ..._tokens,
          'recovery_codes': ['AAAA-BBBB-CCCC-DDDD', 'EEEE-FFFF-GGGG-HHHH'],
        });
      final env = await _submitPassword(tester, fake, {
        'mfa_enrol_required': true,
        'mfa_token': _mfaToken,
      });

      expect(
        fake.lastCall('POST', '/auth/staff/mfa/enrol')!.json['mfa_token'],
        _mfaToken,
      );
      expect(find.byWidgetPredicate((w) => w is SelectableText && w.data == secret), findsOneWidget);
      expect(_selectable('otpauth://totp/'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '654321');
      await tester.tap(find.widgetWithText(PrimaryButton, koT.cMfaConfirm));
      await settle(tester);

      expect(
        fake.lastCall('POST', '/auth/staff/mfa/enrol/confirm')!.json['code'],
        '654321',
      );
      expect(find.text(koT.cMfaCodesTitle), findsOneWidget);
      expect(_selectable('AAAA-BBBB-CCCC-DDDD'), findsOneWidget);
      expect(_selectable('EEEE-FFFF-GGGG-HHHH'), findsOneWidget);
      // Not signed in until the owner has the codes in hand.
      expect(env.session.signedIn, isFalse);

      await tester.tap(find.widgetWithText(PrimaryButton, koT.cMfaContinue));
      await settle(tester);
      expect(env.session.signedIn, isTrue);
      await unmount(tester);
    },
  );

  testWidgets(
    'an owner issues a one-time reset token for an active staff member',
    (tester) async {
      setViewport(tester, wideSize);
      final fake = FakeApi()
        ..reply('GET', '/admin/staff', [
          {
            'id': 'st-1',
            'name': '민준',
            'email': 'min@example.test',
            'role': 'consultant',
            'active': true,
          },
        ])
        ..onPost(
          '/admin/staff/st-1/password-reset',
          (_) => {'token': 'reset-abc-123', 'expires_in': 1800},
        );
      final env = await TestEnv.create(fake: fake, role: 'staff_admin');
      await pumpConsoleScreen(tester, env, const StaffScreen());
      await settle(tester);

      await tester.tap(find.widgetWithText(TextButton, koT.cStaffReset));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, koT.cStaffReset));
      await settle(tester);

      expect(fake.lastCall('POST', '/admin/staff/st-1/password-reset'), isNotNull);
      expect(find.text(koT.cStaffResetTitle), findsOneWidget);
      expect(_selectable('reset-abc-123'), findsOneWidget);
      await unmount(tester);
    },
  );
}
