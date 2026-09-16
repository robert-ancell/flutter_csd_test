import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_win32.dart";

import '../style.dart';
import 'fluent_title_bar.dart';

/// Windows drawn in the style of Windows 11.
///
/// Windows only gives an app the client area of a window. Taking the title bar
/// away leaves the rest of the frame in place, and its border, drop shadow and
/// rounded corners are drawn by the desktop window manager outside anything
/// Flutter can paint. So unlike the GTK style, which has to draw the whole
/// window itself, this draws nothing but the title bar.
///
/// The measurements here are the ones Windows uses, but unlike the GTK style
/// they haven't been checked against a running desktop yet.
class FluentWindowDecorationStyle extends WindowDecorationStyle {
  const FluentWindowDecorationStyle();

  /// The window keeps the sizing border it is resized by, which sits in the
  /// frame rather than the client area, so the app needs no resize handles of
  /// its own.
  @override
  double get resizeBorder => 0;

  /// The shadow is drawn by the desktop window manager, around the outside of
  /// the window, so no room has to be left for it inside.
  @override
  EdgeInsets get shadowExtents => EdgeInsets.zero;

  @override
  BorderRadius cornerRadius({required bool isMaximized}) {
    // Windows 11 rounds the corners of the frame and clips the window to them,
    // so rounding the contents here as well would only cut the corners off
    // twice, and leave the window showing through in between.
    return BorderRadius.zero;
  }

  @override
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window) {
    return FluentTitleBar(window: window);
  }

  @override
  Widget buildShadow(
    BuildContext context,
    WindowDecorationDetails window,
    Widget child,
  ) {
    return child;
  }

  @override
  void prepareWindow(BaseWindowController controller) {
    // Take away the title bar Windows would draw, so this one replaces it. The
    // rest of the frame stays, so the window can still be resized by its
    // border, snapped to the screen edges and restored from the taskbar.
    (controller as WindowControllerWin32).setDecorated(false);
  }
}
