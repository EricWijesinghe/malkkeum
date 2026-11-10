import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'i18n.dart';
import 'session.dart';

/// First-launch language choice, shown before sign-in. The device language is already saved;
/// tapping a language switches the app at once, [next] continues to [child].
class LanguageWelcome extends StatelessWidget {
  const LanguageWelcome({super.key, required this.locale, required this.child});
  final LocaleController locale;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: locale, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    if (!locale.firstRun) return child;
    final current = locale.locale?.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(context.t.moreLanguage), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Space.gutter),
                children: [
                  for (final e in LocaleController.names.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: OptionCard(
                        title: e.value,
                        selected: current == e.key,
                        onTap: () => locale.set(Locale(e.key)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: PrimaryButton(label: context.t.next, onPressed: locale.finishFirstRun),
            ),
          ],
        ),
      ),
    );
  }
}
