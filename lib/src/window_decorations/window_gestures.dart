import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_linux.dart";
import "package:flutter/src/widgets/_window_win32.dart";

import 'style.dart';

/// Lets a window be dragged around and resized by its decorations.
///
/// These are the only two things client side decorations need that the cross
/// platform [WindowController] doesn't have: they have to be handed to the
/// window system, which takes over the pointer for the rest of the drag.
///
/// Linux and Windows implement them so far. Once every platform does they
/// belong on [WindowController] itself, and this can go away.
abstract class WindowGestures {
  const WindowGestures();

  static WindowGestures of(BaseWindowController controller) {
    if (controller is WindowControllerLinux) {
      return _LinuxWindowGestures(controller);
    }
    if (controller is WindowControllerWin32) {
      return _Win32WindowGestures(controller);
    }
    throw UnsupportedError(
      'Windows cannot be moved or resized by their decorations on this '
      'platform yet',
    );
  }

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

class _LinuxWindowGestures extends WindowGestures {
  final WindowControllerLinux controller;

  const _LinuxWindowGestures(this.controller);

  @override
  void beginMove(int button) => controller.beginMoveDrag(button: button);

  @override
  void beginResize(WindowEdge edge, int button) =>
      controller.beginResizeDrag(edge: _dragEdges[edge]!, button: button);
}

class _Win32WindowGestures extends WindowGestures {
  final WindowControllerWin32 controller;

  const _Win32WindowGestures(this.controller);

  @override
  void beginMove(int button) => controller.beginMoveDrag(button: button);

  @override
  void beginResize(WindowEdge edge, int button) =>
      controller.beginResizeDrag(edge: _dragEdges[edge]!, button: button);
}
