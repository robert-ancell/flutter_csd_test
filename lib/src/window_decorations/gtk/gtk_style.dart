import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_linux.dart";

import '../style.dart';
import 'gtk_shadow.dart';
import 'gtk_title_bar.dart';

/// Windows drawn in the style of GTK3 Adwaita, i.e. the way a GNOME desktop
/// draws them.
class GtkWindowDecorationStyle extends WindowDecorationStyle {
  const GtkWindowDecorationStyle();

  /// The border-radius of the "decoration" node in Adwaita.
  static const double _cornerRadius = 15;

  /// GTK3 puts this on the decoration as a margin, and also uses it as the
  /// minimum amount of space to leave around a window for its shadow.
  @override
  double get resizeBorder => 10;

  @override
  EdgeInsets get shadowExtents => _shadowExtents;

  static final EdgeInsets _shadowExtents = GtkWindowShadows.extentsFor(10);

  @override
  BorderRadius cornerRadius({required bool isMaximized}) {
    // Maximized windows are tiled against the screen edges, so they don't get
    // rounded corners.
    return BorderRadius.circular(isMaximized ? 0 : _cornerRadius);
  }

  @override
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window) {
    return GtkTitleBar(window: window);
  }

  @override
  Widget buildShadow(
    BuildContext context,
    WindowDecorationDetails window,
    Widget child,
  ) {
    return GtkWindowShadows(
      isActivated: window.isActivated,
      cornerRadius: _cornerRadius,
      resizeBorder: resizeBorder,
      child: child,
    );
  }

  @override
  void prepareWindow(BaseWindowController controller) {
    // The decorations replace the ones GTK would draw, and the window has to be
    // transparent for the shadow around it to show through.
    (controller as WindowControllerLinux)
      ..setDecorated(false)
      ..setBackgroundColor(const Color(0x00000000));
  }
}
