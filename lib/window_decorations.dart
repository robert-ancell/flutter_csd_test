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
/// [WindowDecorations], or put a [WindowDecorationTheme] above it. No style
/// asks anything of the window it is drawn around, so the decorations of every
/// desktop can be looked at on any one of them.
///
/// Turning [WindowDecorations.clientSide] off hands the window back to the
/// window system, which is how these decorations can be compared against the
/// ones they are imitating.
library;

export 'src/window_decorations/aqua/aqua_style.dart';
export 'src/window_decorations/decorations.dart';
export 'src/window_decorations/fluent/fluent_style.dart';
export 'src/window_decorations/gtk/gtk_shadow.dart' show GtkShadow;
export 'src/window_decorations/gtk/gtk_style.dart';
export 'src/window_decorations/style.dart';
export 'src/window_decorations/theme.dart';
