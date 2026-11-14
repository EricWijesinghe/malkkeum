import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with the three theme choices; the current one is checked. Picking one applies and closes.
Future<void> showThemeSheet(BuildContext context, ThemeController theme) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListenableBuilder(
        listenable: theme,
        builder: (context, _) {
          final t = context.t;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  t.themeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final mode in const [
                ThemeMode.light,
                ThemeMode.dark,
                ThemeMode.system,
              ])
                ListTile(
                  key: ValueKey('theme_${mode.name}'),
                  title: Text(t.themeLabel(mode)),
                  trailing: theme.mode == mode ? const Icon(Icons.check) : null,
                  selected: theme.mode == mode,
                  onTap: () async {
                    await theme.set(mode);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}
