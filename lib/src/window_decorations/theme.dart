import 'package:flutter/widgets.dart';

import 'style.dart';

/// The [WindowDecorationStyle] to draw windows in below this widget.
///
/// Without one every window is drawn in the style of the platform the app is
/// running on, i.e. [WindowDecorationStyle.adaptive].
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
