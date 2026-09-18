import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import 'window_platform.dart';

/// A widget that lets the window be moved by dragging over [child].
///
/// Dragging anywhere in [child] moves the window, and double clicking it
/// maximizes the window or restores it, the way dragging a title bar does. Put
/// one anywhere in a window that should be draggable, whether that is a title
/// bar, a toolbar, or the background of the window itself.
///
/// The drag is handed to the window system, which takes over the pointer until
/// it is released, so [child] sees a press but never the drag that follows.
class WindowMoveArea extends StatefulWidget {
  final Widget child;

  const WindowMoveArea({super.key, required this.child});

  @override
  State<WindowMoveArea> createState() => _WindowMoveAreaState();
}

class _WindowMoveAreaState extends State<WindowMoveArea> {
  /// The distance the pointer has to move before a press becomes a window
  /// move, matching the drag threshold of the desktops being emulated.
  static const double _dragThreshold = 8;

  Offset? _pointerDownPosition;
  Offset? _lastClickPosition;
  Duration? _lastClickTime;

  /// The window being dragged, looked up as the drag happens.
  ///
  /// A style builds its title bar long before anyone drags it, and does so
  /// with no window at all in the tests, so this is not asked for until there
  /// is a press to act on.
  WindowController get _window => WindowScope.of(context) as WindowController;

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }

    // Moving the window makes it lose focus, so make sure a press on the title
    // bar always brings the window back to the front and focused.
    final WindowController window = _window;
    if (!window.isActivated) {
      window.activate();
    }

    final Duration? lastTime = _lastClickTime;
    final Offset? lastPosition = _lastClickPosition;
    if (lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime < kDoubleTapTimeout &&
        (event.position - lastPosition).distance < kDoubleTapSlop) {
      _reset();
      window.setMaximized(!window.isMaximized);
      return;
    }

    _pointerDownPosition = event.position;
    _lastClickPosition = event.position;
    _lastClickTime = event.timeStamp;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Only start moving the window once the pointer has moved far enough,
    // otherwise a click that wobbles slightly is swallowed by the move.
    final Offset? start = _pointerDownPosition;
    if (start == null || (event.position - start).distance < _dragThreshold) {
      return;
    }
    _reset();
    WindowPlatform.of(_window).beginMove();
  }

  void _reset() {
    _pointerDownPosition = null;
    _lastClickPosition = null;
    _lastClickTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (PointerUpEvent event) => _pointerDownPosition = null,
      onPointerCancel: (PointerCancelEvent event) =>
          _pointerDownPosition = null,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
