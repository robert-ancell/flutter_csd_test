import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter/src/widgets/_window.dart";
import 'package:flutter_csd_test/window_decorations.dart';

import 'cloud/cloud_style.dart';

/// Quits the application once the only window has gone away.
///
/// Destroying a window doesn't end the process by itself, so without this the
/// app keeps running in the background after its last window is closed.
class MainWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

/// The ways this app can have its window decorated.
///
/// A style can be picked regardless of the platform the app is running on, so
/// the decorations of every desktop can be looked at side by side on any one
/// of them.
enum WindowDecoration {
  native('Native', 'Drawn by the window system'),
  automatic('Automatic', 'Drawn by the app, in the style of this desktop'),
  gtk('GTK', 'Drawn by the app, in the style of a GNOME desktop'),
  fluent('Fluent', 'Drawn by the app, in the style of Windows 11'),
  aqua('Aqua', 'Drawn by the app, in the style of macOS'),
  cloud('Cloud', 'Drawn by the app, in a style of its own');

  const WindowDecoration(this.label, this.description);

  final String label;
  final String description;

  /// The style to draw the decorations in, or null to leave them to the window
  /// system.
  WindowDecorationStyle? get style => switch (this) {
    WindowDecoration.native => null,
    WindowDecoration.automatic => WindowDecorationStyle.adaptive(),
    WindowDecoration.gtk => const GtkWindowDecorationStyle(),
    WindowDecoration.fluent => const FluentWindowDecorationStyle(),
    WindowDecoration.aqua => const AquaWindowDecorationStyle(),
    WindowDecoration.cloud => const CloudWindowDecorationStyle(),
  };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const MyWindow());
}

class MyWindow extends StatefulWidget {
  const MyWindow({super.key});

  @override
  State<MyWindow> createState() => _WindowState();
}

class _WindowState extends State<MyWindow> {
  // Big enough for every option to fit inside the largest of the shadows the
  // styles draw around the window.
  WindowController controller = WindowController(
    size: Size(600, 600),
    title: 'Flutter Window',
    delegate: MainWindowDelegate(),
  );

  WindowDecoration _decoration = WindowDecoration.automatic;

  // Putting the decorations on and taking them off moves the contents of the
  // window in the widget tree, so they need a key to keep their state.
  final GlobalKey _appKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final Widget app = MyApp(
      key: _appKey,
      decoration: _decoration,
      onChanged: (WindowDecoration decoration) =>
          setState(() => _decoration = decoration),
    );
    final WindowDecorationStyle? style = _decoration.style;

    return ViewCollection(
      views: [
        Window(
          controller: controller,
          // Decorating the window is a matter of wrapping its contents in the
          // decorations, so leaving them to the window system is a matter of
          // leaving the wrapper out.
          child: style == null
              ? app
              : WindowDecorations(style: style, child: app),
        ),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  final WindowDecoration decoration;
  final ValueChanged<WindowDecoration> onChanged;

  const MyApp({super.key, required this.decoration, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Window Decorations',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: WindowDecorationSelector(
        decoration: decoration,
        onChanged: onChanged,
      ),
    );
  }
}

/// Picks which decorations the window around this app is drawn with.
class WindowDecorationSelector extends StatelessWidget {
  final WindowDecoration decoration;
  final ValueChanged<WindowDecoration> onChanged;

  const WindowDecorationSelector({
    super.key,
    required this.decoration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RadioGroup<WindowDecoration>(
                groupValue: decoration,
                onChanged: (WindowDecoration? decoration) {
                  if (decoration != null) {
                    onChanged(decoration);
                  }
                },
                child: ListView(
                  children: [
                    for (final WindowDecoration decoration
                        in WindowDecoration.values)
                      RadioListTile<WindowDecoration>(
                        value: decoration,
                        title: Text(decoration.label),
                        subtitle: Text(decoration.description),
                      ),
                  ],
                ),
              ),
            ),
            const WindowDragStrip(),
          ],
        ),
      ),
    );
  }
}

/// A piece of the app, nowhere near a title bar, that the window can be
/// dragged around by.
///
/// A [WindowMoveArea] works anywhere inside a window, so this strip moves the
/// window whichever decorations are drawn around it, including the ones the
/// window system draws.
class WindowDragStrip extends StatelessWidget {
  const WindowDragStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return WindowMoveArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: colors.secondaryContainer,
        child: Text(
          'Drag here to move the window',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}
