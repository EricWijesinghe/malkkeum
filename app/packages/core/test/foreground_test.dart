import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resume after a real background runs at most once per interval; leaving always runs', (tester) async {
    var now = DateTime(2026, 11, 13, 9);
    var resumes = 0, hides = 0;
    final fg = Foreground(
      onResume: () => resumes++,
      onHide: () => hides++,
      every: const Duration(minutes: 10),
      clock: () => now,
    );
    addTearDown(fg.dispose);
    final binding = tester.binding;
    void walk(List<AppLifecycleState> states) {
      for (final s in states) {
        binding.handleAppLifecycleStateChanged(s);
      }
    }

    const leave = [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused];
    const back = [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed];
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    // A dialog or the notification shade only makes the app inactive: nothing happens.
    walk([AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect((resumes, hides), (0, 0));

    now = now.add(const Duration(minutes: 11));
    walk(leave);
    expect(hides, 1, reason: 'leaving flushes');
    walk(back);
    expect(resumes, 1);

    // Back again 2 minutes later: throttled.
    now = now.add(const Duration(minutes: 2));
    walk(leave);
    walk(back);
    expect((resumes, hides), (1, 2));

    now = now.add(const Duration(minutes: 10));
    // Web tab hidden / desktop minimised: no paused state.
    walk([AppLifecycleState.inactive, AppLifecycleState.hidden]);
    walk([AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect((resumes, hides), (2, 3));
  });
}
