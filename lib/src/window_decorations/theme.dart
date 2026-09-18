import 'package:flutter/widgets.dart';

import 'style.dart';

/// A widget that sets the [WindowDecorationStyle] of the windows below it.
///
/// Without one, windows are drawn in the style of the platform the app is
/// running on, unless their decorations are given a style of their own.
class WindowDecorationTheme extends InheritedWidget {
  final WindowDecorationStyle style;

  const WindowDecorationTheme({
    super.key,
    required this.style,
    required super.child,
  });

  static WindowDecorationStyle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WindowDecorationTheme>()
        ?.style;
  }

  static WindowDecorationStyle of(BuildContext context) {
    return maybeOf(context) ?? WindowDecorationStyle.adaptive();
  }

  @override
  bool updateShouldNotify(WindowDecorationTheme oldWidget) =>
      style != oldWidget.style;
}
