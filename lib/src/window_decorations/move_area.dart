import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'style.dart';

/// An area of a window that the window can be dragged around by, i.e. the
/// empty parts of a title bar.
///
/// Presses are handed to the window system once the pointer has moved far
/// enough for them to be a drag rather than a click, and a double click
/// maximizes the window.
class WindowMoveArea extends StatefulWidget {
  final Widget child;
  final WindowDecorationDetails window;

  const WindowMoveArea({super.key, required this.child, required this.window});

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

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }

    // Moving the window makes it lose focus, so make sure a press on the title
    // bar always brings the window back to the front and focused.
    if (!widget.window.isActivated) {
      widget.window.onActivate();
    }

    final Duration? lastTime = _lastClickTime;
    final Offset? lastPosition = _lastClickPosition;
    if (lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime < kDoubleTapTimeout &&
        (event.position - lastPosition).distance < kDoubleTapSlop) {
      _reset();
      widget.window.onToggleMaximize();
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
    widget.window.onMove(1);
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
