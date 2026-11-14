import 'package:console/screens/setup_owner_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_support/test_support.dart';

import 'support/console_host.dart';

/// Opens the owner-code prompt and records what it returned (null when cancelled).
class _AskHost extends StatelessWidget {
  const _AskHost({required this.onAnswer});
  final void Function(String?) onAnswer;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () async => onAnswer(await askOwnerCode(context)),
      child: const Text('ask'),
    ),
  );
}

Future<void> _pump(WidgetTester tester, void Function(String?) onAnswer) async {
  setViewport(tester, tallPhoneSize);
  final env = await TestEnv.create(fake: FakeApi(), role: 'staff_admin');
  await pumpConsoleScreen(tester, env, _AskHost(onAnswer: onAnswer));
  await tester.tap(find.text('ask'));
  await settle(tester);
}

void main() {
  testWidgets('owner code is returned only once six digits are typed', (tester) async {
    final answers = <String?>[];
    await _pump(tester, answers.add);
    final confirm = find.widgetWithText(FilledButton, koT.cOwnerCodeConfirm);

    await tester.enterText(find.byType(TextField), '12345');
    await settle(tester);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'five digits is not a code');

    await tester.enterText(find.byType(TextField), '123456');
    await settle(tester);
    await tester.tap(confirm);
    await settle(tester);

    expect(answers, ['123456']);
    await unmount(tester);
  });

  testWidgets('cancelling the owner code prompt answers null', (tester) async {
    final answers = <String?>[];
    await _pump(tester, answers.add);

    await tester.tap(find.widgetWithText(TextButton, koT.cancel));
    await settle(tester);

    expect(answers, [null]);
    await unmount(tester);
  });
}
