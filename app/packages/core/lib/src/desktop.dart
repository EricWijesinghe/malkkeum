import 'package:flutter/material.dart';

/// The Windows (MSIX) build. It has no native social SDKs, no FCM, and no WebView plugin.
bool isWindowsApp() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

/// Windows: keeps the phone-first layouts to one readable column instead of stretching across a wide window.
/// Every other platform gets the child unchanged.
class DesktopColumn extends StatelessWidget {
  const DesktopColumn({super.key, required this.child});

  final Widget child;

  static const maxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    if (!isWindowsApp()) return child;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
