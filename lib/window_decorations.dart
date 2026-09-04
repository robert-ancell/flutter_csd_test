/// Client side window decorations, drawn by the app rather than the window
/// system, in the style of a desktop.
///
/// Each desktop is emulated rather than asked how to draw, in the same way the
/// Cupertino widgets emulate iOS.
///
/// Wrap the contents of a [Window] in [WindowDecorations] to give it a title
/// bar, rounded corners, a drop shadow and draggable resize borders. The
/// decorations drive the window through its [WindowController], so an app only
/// needs to provide its content:
///
/// ```dart
/// Window(controller: controller, child: WindowDecorations(child: MyApp()))
/// ```
///
/// Windows are drawn in the style of the platform the app is running on. To
/// draw them in a particular style instead, pass a [WindowDecorationStyle] to
/// [WindowDecorations], or put a [WindowDecorationTheme] above it.
library;

export 'src/window_decorations/aqua/aqua_style.dart';
export 'src/window_decorations/decorations.dart';
export 'src/window_decorations/fluent/fluent_style.dart';
export 'src/window_decorations/gtk/gtk_shadow.dart' show GtkShadow;
export 'src/window_decorations/gtk/gtk_style.dart';
export 'src/window_decorations/style.dart';
export 'src/window_decorations/theme.dart';
