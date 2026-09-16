import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter/src/widgets/_window.dart";

import 'window_decorations.dart';

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
  aqua('Aqua', 'Drawn by the app, in the style of macOS');

  const WindowDecoration(this.label, this.description);

  final String label;
  final String description;

  /// Whether the app draws these decorations, rather than the window system.
  bool get isClientSide => this != WindowDecoration.native;

  /// The style to draw the decorations in, or null to leave them to the window
  /// system.
  WindowDecorationStyle? get style => switch (this) {
    WindowDecoration.native => null,
    WindowDecoration.automatic => WindowDecorationStyle.adaptive(),
    WindowDecoration.gtk => const GtkWindowDecorationStyle(),
    WindowDecoration.fluent => const FluentWindowDecorationStyle(),
    WindowDecoration.aqua => const AquaWindowDecorationStyle(),
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

  @override
  Widget build(BuildContext context) {
    return ViewCollection(
      views: [
        Window(
          controller: controller,
          child: WindowDecorations(
            style: _decoration.style,
            clientSide: _decoration.isClientSide,
            child: MyApp(
              decoration: _decoration,
              onChanged: (WindowDecoration decoration) =>
                  setState(() => _decoration = decoration),
            ),
          ),
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
        child: RadioGroup<WindowDecoration>(
          groupValue: decoration,
          onChanged: (WindowDecoration? decoration) {
            if (decoration != null) {
              onChanged(decoration);
            }
          },
          child: ListView(
            children: [
              for (final WindowDecoration decoration in WindowDecoration.values)
                RadioListTile<WindowDecoration>(
                  value: decoration,
                  title: Text(decoration.label),
                  subtitle: Text(decoration.description),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
