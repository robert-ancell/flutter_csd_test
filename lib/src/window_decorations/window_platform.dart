import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_linux.dart";
import "package:flutter/src/widgets/_window_win32.dart";

import 'style.dart';

/// The window system a window belongs to, and the things the window
/// decoration widgets need from it.
///
/// These are the things the cross platform [WindowController] doesn't have:
/// taking away the decorations the window system draws, and handing a drag
/// back to it, which takes over the pointer until the button is released.
///
/// Linux and Windows are implemented so far. Once every platform is, and the
/// windowing API covers all of this, this can go away.
abstract class WindowPlatform {
  const WindowPlatform();

  static WindowPlatform of(BaseWindowController controller) {
    if (controller is WindowControllerLinux) {
      return _LinuxWindowPlatform(controller);
    }
    if (controller is WindowControllerWin32) {
      return _Win32WindowPlatform(controller);
    }
    throw UnsupportedError(
      'Windows cannot be decorated by the app on this platform yet',
    );
  }

  /// Whether the window system goes on drawing the frame around a window whose
  /// decorations it has given up: its border, the border's resize handles, its
  /// rounded corners and its drop shadow.
  ///
  /// These go together because a window system either hands over the whole
  /// window or only its title bar. Windows hands over the title bar alone, so
  /// an app there draws nothing but a title bar of its own, and drawing any of
  /// the rest would double up on a frame that is still there. GTK takes away
  /// the whole frame, so an app there has to draw all of it.
  ///
  /// The title bar is not part of this: the app always draws that one.
  bool get drawsFrame;

  /// Sets whether the window system draws the decorations of this window,
  /// rather than the app.
  void setDecorated(bool decorated);

  /// Hands a press on the title bar to the window system, which drags the
  /// window until the button is released.
  void beginMove(int button);

  /// Hands a press on a window border to the window system, which resizes the
  /// window until the button is released.
  void beginResize(WindowEdge edge, int button);
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

class _LinuxWindowPlatform extends WindowPlatform {
  final WindowControllerLinux controller;

  const _LinuxWindowPlatform(this.controller);

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

  @override
  void beginMove(int button) => controller.beginMoveDrag(button: button);

  @override
  void beginResize(WindowEdge edge, int button) =>
      controller.beginResizeDrag(edge: _dragEdges[edge]!, button: button);
}

class _Win32WindowPlatform extends WindowPlatform {
  final WindowControllerWin32 controller;

  const _Win32WindowPlatform(this.controller);

  /// Windows keeps every part of the frame and hands over only the strip the
  /// title bar sits in, by letting the client area extend up over it. The
  /// border, shadow and rounded corners are still drawn outside the client
  /// area, so the window can still be resized by its border, snapped to the
  /// screen edges and restored from the taskbar without the app doing anything.
  @override
  bool get drawsFrame => true;

  @override
  void setDecorated(bool decorated) => controller.setDecorated(decorated);

  @override
  void beginMove(int button) => controller.beginMoveDrag(button: button);

  @override
  void beginResize(WindowEdge edge, int button) =>
      controller.beginResizeDrag(edge: _dragEdges[edge]!, button: button);
}
