import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'style.dart';

/// Makes a window resizable by dragging its edges and corners.
///
/// The handles sit just outside the visible edges of the window, in the space
/// left around it for its shadow, which matches the invisible resize border the
/// desktops put there. The pieces the rounded corners cut out of the window are
/// handles too, since nothing is drawn there.
///
/// Pointer events that aren't on a handle pass straight through to the window.
class WindowResizeHandles extends StatefulWidget {
  final Widget child;
  final void Function(WindowEdge edge, int button) onResize;

  /// The distance from the edges of this widget to the visible edges of the
  /// window, i.e. the space taken by the window shadow.
  final EdgeInsets shadowExtents;

  /// How far the handles reach out from the edges of the window.
  final double resizeBorder;

  /// How much the corners of the window are rounded.
  final BorderRadius cornerRadius;

  const WindowResizeHandles({
    super.key,
    required this.child,
    required this.onResize,
    required this.shadowExtents,
    required this.resizeBorder,
    required this.cornerRadius,
  });

  /// How far the corner handles reach along each edge, as GTK4 sizes them.
  ///
  /// Corners are harder to hit than edges, so they get more than their share of
  /// the border.
  static const double cornerSize = 24;

  /// The edge of a window of [size] at [position], or null if that isn't on a
  /// resize handle.
  ///
  /// This is get_edge_for_coordinates() from GTK4: a strip along each side of
  /// the window, with the corners taking over the ends of those strips, plus
  /// the piece each rounded corner cuts out of the window itself.
  static WindowEdge? edgeAt(
    Offset position,
    Size size, {
    required EdgeInsets shadowExtents,
    required double resizeBorder,
    required BorderRadius cornerRadius,
  }) {
    final Rect window = shadowExtents.deflateRect(Offset.zero & size);
    final double x = position.dx;
    final double y = position.dy;

    // A corner reaches along the edges it joins, always far enough to cover the
    // whole of the rounded part of the window.
    double corner(Radius radius) =>
        math.max(cornerSize, math.max(radius.x, radius.y));

    if (x < window.left && x >= window.left - resizeBorder) {
      if (y < window.top + corner(cornerRadius.topLeft) &&
          y >= window.top - resizeBorder) {
        return WindowEdge.topLeft;
      }
      if (y > window.bottom - corner(cornerRadius.bottomLeft) &&
          y <= window.bottom + resizeBorder) {
        return WindowEdge.bottomLeft;
      }
      return WindowEdge.left;
    }

    if (x > window.right && x <= window.right + resizeBorder) {
      if (y < window.top + corner(cornerRadius.topRight) &&
          y >= window.top - resizeBorder) {
        return WindowEdge.topRight;
      }
      if (y > window.bottom - corner(cornerRadius.bottomRight) &&
          y <= window.bottom + resizeBorder) {
        return WindowEdge.bottomRight;
      }
      return WindowEdge.right;
    }

    if (y < window.top && y >= window.top - resizeBorder) {
      if (x < window.left + corner(cornerRadius.topLeft)) {
        return WindowEdge.topLeft;
      }
      if (x > window.right - corner(cornerRadius.topRight)) {
        return WindowEdge.topRight;
      }
      return WindowEdge.top;
    }

    if (y > window.bottom && y <= window.bottom + resizeBorder) {
      if (x < window.left + corner(cornerRadius.bottomLeft)) {
        return WindowEdge.bottomLeft;
      }
      if (x > window.right - corner(cornerRadius.bottomRight)) {
        return WindowEdge.bottomRight;
      }
      return WindowEdge.bottom;
    }

    // Inside the window, but possibly in the piece a rounded corner cuts out of
    // it. Nothing is drawn there, so it belongs to the corner beside it.
    if (!window.contains(position) ||
        cornerRadius.toRRect(window).contains(position)) {
      return null;
    }
    if (x < window.left + cornerRadius.topLeft.x &&
        y < window.top + cornerRadius.topLeft.y) {
      return WindowEdge.topLeft;
    }
    if (x > window.right - cornerRadius.topRight.x &&
        y < window.top + cornerRadius.topRight.y) {
      return WindowEdge.topRight;
    }
    if (x < window.left + cornerRadius.bottomLeft.x &&
        y > window.bottom - cornerRadius.bottomLeft.y) {
      return WindowEdge.bottomLeft;
    }
    if (x > window.right - cornerRadius.bottomRight.x &&
        y > window.bottom - cornerRadius.bottomRight.y) {
      return WindowEdge.bottomRight;
    }
    return null;
  }

  @override
  State<WindowResizeHandles> createState() => _WindowResizeHandlesState();
}

class _WindowResizeHandlesState extends State<WindowResizeHandles> {
  static const Map<WindowEdge, MouseCursor> _cursors =
      <WindowEdge, MouseCursor>{
        WindowEdge.topLeft: SystemMouseCursors.resizeUpLeft,
        WindowEdge.top: SystemMouseCursors.resizeUp,
        WindowEdge.topRight: SystemMouseCursors.resizeUpRight,
        WindowEdge.left: SystemMouseCursors.resizeLeft,
        WindowEdge.right: SystemMouseCursors.resizeRight,
        WindowEdge.bottomLeft: SystemMouseCursors.resizeDownLeft,
        WindowEdge.bottom: SystemMouseCursors.resizeDown,
        WindowEdge.bottomRight: SystemMouseCursors.resizeDownRight,
      };

  MouseCursor _cursor = MouseCursor.defer;

  WindowEdge? _edgeAt(Offset position, Size size) {
    return WindowResizeHandles.edgeAt(
      position,
      size,
      shadowExtents: widget.shadowExtents,
      resizeBorder: widget.resizeBorder,
      cornerRadius: widget.cornerRadius,
    );
  }

  void _handleHover(PointerHoverEvent event) {
    final MouseCursor cursor =
        _cursors[_edgeAt(event.localPosition, context.size ?? Size.zero)] ??
        MouseCursor.defer;
    if (cursor != _cursor) {
      setState(() => _cursor = cursor);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }
    final WindowEdge? edge = _edgeAt(
      event.localPosition,
      context.size ?? Size.zero,
    );
    if (edge != null) {
      widget.onResize(edge, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        // In front of the window, but only in the way where there is a handle.
        Positioned.fill(
          child: _ResizeHandleRegion(
            edgeAt: _edgeAt,
            child: MouseRegion(
              cursor: _cursor,
              onHover: _handleHover,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Takes pointer events where there is a resize handle, and lets everything
/// else fall through to the window behind it.
class _ResizeHandleRegion extends SingleChildRenderObjectWidget {
  final WindowEdge? Function(Offset position, Size size) edgeAt;

  const _ResizeHandleRegion({required this.edgeAt, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderResizeHandleRegion(edgeAt);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizeHandleRegion renderObject,
  ) {
    renderObject.edgeAt = edgeAt;
  }
}

class _RenderResizeHandleRegion extends RenderProxyBox {
  WindowEdge? Function(Offset position, Size size) edgeAt;

  _RenderResizeHandleRegion(this.edgeAt);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (edgeAt(position, size) == null) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
