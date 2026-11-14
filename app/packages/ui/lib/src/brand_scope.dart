import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The brand the running app shows. Apps wrap their root in this so widgets such as
/// [DahaeLogo] follow the business profile without taking it as a parameter.
class BrandScope extends InheritedWidget {
  const BrandScope({super.key, required this.brand, required super.child});

  final BrandConfig brand;

  /// Outside a scope (tests, previews) the built-in brand is used.
  static BrandConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandScope>()?.brand ?? BrandConfig.placeholder;

  @override
  bool updateShouldNotify(BrandScope old) => old.brand != brand;
}
