import 'dart:ui';

import 'package:flutter/src/widgets/_window_linux.dart';

import 'style.dart';
import 'window_platform.dart';

/// The things the window decoration widgets need from GTK.
///
/// Unlike the other platforms this is all in the windowing API already, so this
/// only has to pass the calls on.
class LinuxWindowPlatform extends WindowPlatform {
  final WindowControllerLinux controller;

  const LinuxWindowPlatform(this.controller);

  /// The color an FlView starts out drawing behind the Flutter contents.
  static const Color _defaultBackground = Color(0xFF000000);

  /// GTK takes the border, shadow and rounded corners away along with the
  /// title bar, leaving the whole window to the app.
  @override
  bool get drawsFrame => false;

  @override
  void setDecorated(bool decorated) {
    // An undecorated window has to be transparent for the rounded corners the
    // app draws, and the shadow around them, to show what is behind the
    // window.
    //
    // Painting the background ourselves stops GTK filling the window with the
    // background color of the current theme, which is opaque. What we then
    // leave unpainted is the transparent color below.
    controller
      ..setDecorated(decorated)
      ..setAppPaintable(!decorated)
      ..setBackgroundColor(
        decorated ? _defaultBackground : const Color(0x00000000),
      );
  }

  /// The pointer button a window is dragged with, which is always the primary
  /// one: the decorations ignore presses of any other button.
  static const int _dragButton = 1;

  @override
  void beginMove() => controller.beginMoveDrag(button: _dragButton);

  @override
  void beginResize(WindowEdge edge) =>
      controller.beginResizeDrag(edge: _dragEdges[edge]!, button: _dragButton);
}

/// What the windowing API calls each edge of a window, i.e. the compass point
/// it lies at.
const Map<WindowEdge, WindowDragEdge> _dragEdges = <WindowEdge, WindowDragEdge>{
  WindowEdge.topLeft: WindowDragEdge.northWest,
  WindowEdge.top: WindowDragEdge.north,
  WindowEdge.topRight: WindowDragEdge.northEast,
  WindowEdge.left: WindowDragEdge.west,
  WindowEdge.right: WindowDragEdge.east,
  WindowEdge.bottomLeft: WindowDragEdge.southWest,
  WindowEdge.bottom: WindowDragEdge.south,
  WindowEdge.bottomRight: WindowDragEdge.southEast,
};
