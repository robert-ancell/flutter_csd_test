/// Client side window decorations that emulate the GTK3 Adwaita style, in the
/// same way the Cupertino widgets emulate iOS.
///
/// Wrap the contents of a [Window] in [WindowDecorations] to give it a title
/// bar, rounded corners, a drop shadow and draggable resize borders. The
/// decorations drive the window through its [WindowController], so an app only
/// needs to provide its content:
///
/// ```dart
/// Window(controller: controller, child: WindowDecorations(child: MyApp()))
/// ```
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_linux.dart";

/// Radius of the rounded window corners.
///
/// These decorations emulate the GTK3 Adwaita style rather than reading values
/// from the platform, in the same way the Cupertino widgets emulate iOS. This
/// matches the border-radius of the "decoration" node in that theme.
const double windowCornerRadius = 15;

/// Width of the invisible border around a window that can be grabbed to resize
/// it.
///
/// GTK3 puts this on the decoration as a margin, and also uses it as the
/// minimum amount of space to leave around a window for its shadow.
const double windowResizeBorder = 10;

/// Draws client side decorations around the contents of a window.
///
/// Gives the window a title bar with minimize, maximize and close buttons,
/// rounded corners, a drop shadow and borders that can be dragged to resize it.
/// The window is driven through the [WindowController] provided by the
/// enclosing [WindowScope].
class WindowDecorations extends StatefulWidget {
  final Widget child;

  const WindowDecorations({super.key, required this.child});

  @override
  State<WindowDecorations> createState() => _WindowDecorationsState();
}

class _WindowDecorationsState extends State<WindowDecorations> {
  BaseWindowController? _configuredWindow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The decorations replace the ones the window system would draw, and the
    // window has to be transparent for the shadow around it to show through.
    // This only has to be done as the window changes, not every time the
    // decorations are rebuilt.
    final BaseWindowController controller = WindowScope.of(context);
    if (identical(controller, _configuredWindow)) {
      return;
    }
    _configuredWindow = controller;
    (controller as WindowControllerLinux)
      ..setDecorated(false)
      ..setBackgroundColor(Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    final WindowController controller =
        WindowScope.of(context) as WindowController;
    final WindowControllerLinux linuxController =
        controller as WindowControllerLinux;

    // Maximized windows are tiled against the screen edges, so they don't get
    // rounded corners or shadows.
    final bool isMaximized = WindowScope.isMaximizedOf(context);
    final bool isActivated = WindowScope.isActivatedOf(context);
    Widget decorated = ClipRRect(
      borderRadius: BorderRadius.circular(isMaximized ? 0 : windowCornerRadius),
      child: Column(
        children: <Widget>[
          // The title bar redraws as its buttons are hovered and pressed, so
          // keep it off the layer the window shadows are drawn on.
          RepaintBoundary(
            child: TitleBar(
              onClose: controller.destroy,
              onMinimize: () => controller.setMinimized(true),
              onToggleMaximize: () =>
                  controller.setMaximized(!controller.isMaximized),
              onMove: (int button) =>
                  linuxController.beginMoveDrag(button: button),
              onActivate: controller.activate,
            ),
          ),
          // The debug banner paints outside the bounds of the app, so clip it
          // to the window contents.
          //
          // The contents are also given a layer of their own so that an app
          // animating doesn't make the decorations around it repaint.
          Expanded(
            child: ClipRect(child: RepaintBoundary(child: widget.child)),
          ),
        ],
      ),
    );

    // A maximized window fills the screen, so it can't be resized by its edges
    // and has no margin to put the resize handles in.
    if (!isMaximized) {
      decorated = WindowResizeHandles(
        shadowExtents: WindowShadows.extents,
        onResize: (WindowDragEdge edge, int button) =>
            linuxController.beginResizeDrag(edge: edge, button: button),
        child: WindowShadows(isActivated: isActivated, child: decorated),
      );
    }

    return Directionality(textDirection: TextDirection.ltr, child: decorated);
  }
}

class TitleBar extends StatefulWidget {
  final void Function() onClose;
  final void Function() onMinimize;
  final void Function() onToggleMaximize;
  final void Function(int button) onMove;
  final void Function() onActivate;

  const TitleBar({
    super.key,
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onMove,
    required this.onActivate,
  });

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> {
  /// The height of a title bar, as GTK3 Adwaita sizes the one it draws for a
  /// window that has no header bar.
  ///
  /// That title bar is a "headerbar.titlebar.default-decoration" node, which
  /// the theme gives a minimum height of 28 pixels, 4 pixels of padding and a
  /// one pixel bottom border.
  static const double _height = 28 + 4 + 4 + 1;

  // The distance the pointer has to move before a press becomes a window
  // move, matching the GTK drag threshold.
  static const double _dragThreshold = 8;

  Offset? _pointerDownPosition;
  Offset? _lastClickPosition;
  Duration? _lastClickTime;
  bool _isActivated = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }

    // Moving the window makes it lose focus, so make sure a press on the title
    // bar always brings the window back to the front and focused.
    if (!_isActivated) {
      widget.onActivate();
    }

    // A double click toggles the maximized state, matching GTK.
    final Duration? lastTime = _lastClickTime;
    final Offset? lastPosition = _lastClickPosition;
    if (lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime < kDoubleTapTimeout &&
        (event.position - lastPosition).distance < kDoubleTapSlop) {
      _pointerDownPosition = null;
      _lastClickPosition = null;
      _lastClickTime = null;
      widget.onToggleMaximize();
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
    _pointerDownPosition = null;
    _lastClickPosition = null;
    _lastClickTime = null;
    widget.onMove(1);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerDownPosition = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isActivated = WindowScope.isActivatedOf(context);
    final bool isMaximized = WindowScope.isMaximizedOf(context);
    _isActivated = isActivated;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        gradient: isActivated
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFE1DEDB), Color(0xFFDAD6D2)],
              )
            : null,
        color: isActivated ? null : const Color(0xFFF6F5F4),
        border: Border(
          bottom: BorderSide(
            color: isActivated
                ? const Color(0xFFBFB8B1)
                : const Color(0xFFD5D0CC),
          ),
        ),
      ),
      // The highlight along the top of the title bar. GTK draws it as an inset
      // shadow, which takes up no space, so it goes in front of the contents
      // rather than in the border.
      foregroundDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xCCFFFFFF))),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: <Widget>[
          // The draggable area sits below the window controls so that
          // pointer events over a button never reach it.
          Positioned.fill(
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              behavior: HitTestBehavior.opaque,
              child: Center(child: WindowTitle(isActivated: isActivated)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: WindowControls(
              isActivated: isActivated,
              isMaximized: isMaximized,
              onClose: widget.onClose,
              onMinimize: widget.onMinimize,
              onToggleMaximize: widget.onToggleMaximize,
            ),
          ),
        ],
      ),
    );
  }
}

class WindowTitle extends StatelessWidget {
  final bool isActivated;

  const WindowTitle({super.key, required this.isActivated});

  @override
  Widget build(BuildContext context) {
    return Text(
      WindowScope.titleOf(context),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isActivated ? const Color(0xFF2E3436) : const Color(0xFF8B8E8F),
      ),
    );
  }
}

class WindowControls extends StatelessWidget {
  final bool isActivated;
  final bool isMaximized;
  final void Function() onClose;
  final void Function() onMinimize;
  final void Function() onToggleMaximize;

  const WindowControls({
    super.key,
    required this.isActivated,
    required this.isMaximized,
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context) {
    // GTK gives the title bar it draws for a window without a header bar a
    // spacing of zero, so its buttons sit right next to each other.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        WindowControlButton(
          icon: Icons.remove,
          tooltip: 'Minimize',
          isActivated: isActivated,
          onPressed: onMinimize,
        ),
        WindowControlButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          iconSize: isMaximized ? 12 : 14,
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          isActivated: isActivated,
          onPressed: onToggleMaximize,
        ),
        WindowControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          isActivated: isActivated,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class WindowControlButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool isActivated;
  final void Function() onPressed;

  const WindowControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isActivated,
    required this.onPressed,
    this.iconSize = 14,
  });

  @override
  State<WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<WindowControlButton> {
  /// The size of a window button, as GTK3 Adwaita sizes the ones in the title
  /// bar it draws for a window without a header bar.
  ///
  /// The theme gives "button.titlebutton" a minimum size of 26 pixels and a one
  /// pixel border, which fills the height of the title bar exactly.
  static const double _size = 26 + 1 + 1;

  bool _hovered = false;
  bool _pressed = false;

  /// How a window button is drawn when it is pressed, hovered, or neither.
  ///
  /// GTK draws nothing at all until the pointer is over the button, and then a
  /// circle the shape of the whole button.
  BoxDecoration? get _decoration {
    if (_pressed) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD6D1CD),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFCDC7C2))),
      );
    }
    if (_hovered) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFDFDFC), Color(0xFFF4F3F2)],
        ),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFCDC7C2))),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (PointerEnterEvent event) {
          setState(() => _hovered = true);
        },
        onExit: (PointerExitEvent event) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            setState(() => _pressed = true);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTap: () {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: Container(
            width: _size,
            height: _size,
            decoration: _decoration,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.isActivated
                  ? const Color(0xFF2E3436)
                  : const Color(0xFF8B8E8F),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shadow written the way GTK3 writes them in its stylesheets, i.e. as a CSS
/// box-shadow.
///
/// GTK3 interprets these differently to both the CSS specification and Flutter,
/// so they are kept in GTK's terms and converted where they are used.
class GtkShadow {
  final Offset offset;
  final double blurRadius;
  final double spreadRadius;
  final Color color;

  const GtkShadow({
    this.offset = Offset.zero,
    this.blurRadius = 0,
    this.spreadRadius = 0,
    required this.color,
  });

  /// The size of the box blur GTK approximates a Gaussian blur with, relative
  /// to the standard deviation of that Gaussian.
  static final double _gaussianScaleFactor = 3 * math.sqrt(2 * math.pi) / 4;

  /// The equivalent Flutter shadow.
  ///
  /// GTK blurs with three box blurs sized so that the blur radius is the
  /// standard deviation of the Gaussian they approximate. Flutter instead
  /// derives the standard deviation from the blur radius with
  /// [Shadow.convertRadiusToSigma], so the radius has to be converted to get
  /// the same amount of blur.
  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius <= 0 ? 0 : (blurRadius - 0.5) / 0.57735,
      spreadRadius: spreadRadius,
    );
  }

  /// How far this shadow reaches out from the box it is drawn around.
  ///
  /// Matches _gtk_css_shadows_value_get_extents() in GTK3, which measures the
  /// radius of the whole triple box blur kernel, not the blur radius.
  EdgeInsets get extents {
    final double clipRadius = (blurRadius * _gaussianScaleFactor * 1.5 + 0.5)
        .floorToDouble();
    double reach(double offset) =>
        math.max(0, (clipRadius + spreadRadius + offset).ceilToDouble());
    return EdgeInsets.only(
      left: reach(-offset.dx),
      right: reach(offset.dx),
      top: reach(-offset.dy),
      bottom: reach(offset.dy),
    );
  }
}

class WindowShadows extends StatelessWidget {
  final Widget child;
  final bool isActivated;
  final double cornerRadius;

  const WindowShadows({
    super.key,
    required this.child,
    required this.isActivated,
    this.cornerRadius = windowCornerRadius,
  });

  // The shadows GTK3 Adwaita draws around a client side decorated window, i.e.
  // the box-shadow of the "decoration" node in that theme.
  static const List<GtkShadow> _activatedShadows = <GtkShadow>[
    GtkShadow(
      color: Color(0x80000000),
      offset: Offset(0, 3),
      blurRadius: 9,
      spreadRadius: 1,
    ),
    // The window border, drawn as a shadow so it follows the rounded corners.
    GtkShadow(color: Color(0x3B000000), spreadRadius: 1),
  ];

  static const List<GtkShadow> _backdropShadows = <GtkShadow>[
    // Invisible, but keeps the space taken by the shadows the same as when the
    // window is focused so it doesn't jump about as it gains and loses focus.
    GtkShadow(
      color: Color(0x00000000),
      offset: Offset(0, 3),
      blurRadius: 9,
      spreadRadius: 1,
    ),
    GtkShadow(
      color: Color(0x33000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 2,
    ),
    GtkShadow(color: Color(0x2E000000), spreadRadius: 1),
  ];

  /// The space that has to be left around a window for its shadows.
  ///
  /// This is how GTK3 sizes the invisible border around a client side decorated
  /// window: far enough out for every shadow to be drawn in full, and never
  /// less than the resize border.
  static final EdgeInsets extents = _extentsOf(<GtkShadow>[
    ..._activatedShadows,
    ..._backdropShadows,
  ]);

  static EdgeInsets _extentsOf(List<GtkShadow> shadows) {
    EdgeInsets result = const EdgeInsets.all(windowResizeBorder);
    for (final GtkShadow shadow in shadows) {
      final EdgeInsets shadowExtents = shadow.extents;
      result = EdgeInsets.only(
        left: math.max(result.left, shadowExtents.left),
        right: math.max(result.right, shadowExtents.right),
        top: math.max(result.top, shadowExtents.top),
        bottom: math.max(result.bottom, shadowExtents.bottom),
      );
    }
    return result;
  }

  // The decorations are built once and reused, so that rebuilding doesn't make
  // Flutter repaint the shadows.
  static final Map<double, List<BoxDecoration>> _decorations =
      <double, List<BoxDecoration>>{};

  static BoxDecoration _decorationFor(double cornerRadius, bool isActivated) {
    final List<BoxDecoration> forRadius = _decorations.putIfAbsent(
      cornerRadius,
      () => <List<GtkShadow>>[_backdropShadows, _activatedShadows]
          .map(
            (List<GtkShadow> shadows) => BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: shadows
                  .map((GtkShadow shadow) => shadow.toBoxShadow())
                  .toList(),
            ),
          )
          .toList(),
    );
    return forRadius[isActivated ? 1 : 0];
  }

  /// Shrinks [padding] until it leaves at least a pixel of room in [size].
  ///
  /// A window is laid out at a minimal size until it is first shown, and there
  /// the shadow extents are bigger than the whole window. Padding the window
  /// away to nothing there would leave nothing to draw, and a window that never
  /// draws anything never gets shown.
  static EdgeInsets fit(EdgeInsets padding, Size size) {
    final double horizontal = _scale(padding.horizontal, size.width);
    final double vertical = _scale(padding.vertical, size.height);
    if (horizontal == 1 && vertical == 1) {
      return padding;
    }
    return EdgeInsets.only(
      left: padding.left * horizontal,
      right: padding.right * horizontal,
      top: padding.top * vertical,
      bottom: padding.bottom * vertical,
    );
  }

  static double _scale(double padding, double extent) {
    if (!extent.isFinite || padding <= 0 || padding < extent) {
      return 1;
    }
    return math.max(extent - 1, 0) / padding;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: fit(extents, constraints.biggest),
          child: DecoratedBox(
            decoration: _decorationFor(cornerRadius, isActivated),
            child: child,
          ),
        );
      },
    );
  }
}

/// Makes a window resizable by dragging its edges and corners.
///
/// The handles sit just outside the visible edges of the window, in the space
/// left around it for its shadow. This matches the invisible resize border GTK3
/// puts there, and means the handles don't cover any window contents.
class WindowResizeHandles extends StatelessWidget {
  final Widget child;
  final void Function(WindowDragEdge edge, int button) onResize;

  /// The distance from the edges of this widget to the visible edges of the
  /// window, i.e. the space taken by the window shadow.
  final EdgeInsets shadowExtents;

  /// How far the corner handles reach along each edge. Corners are easier to
  /// hit than edges, so they get more than their share of the border.
  static const double _cornerExtent = 16;

  const WindowResizeHandles({
    super.key,
    required this.child,
    required this.onResize,
    required this.shadowExtents,
  });

  Widget _handle({
    required WindowDragEdge edge,
    required MouseCursor cursor,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (PointerDownEvent event) {
            if (event.buttons != kPrimaryButton) {
              return;
            }
            onResize(edge, 1);
          },
        ),
      ),
    );
  }

  /// The two arms of an L shaped corner handle, one along each of the edges it
  /// joins. Keeping the handle outside the window means the corner of the
  /// window itself stays clickable.
  List<Widget> _cornerHandles({
    required WindowDragEdge edge,
    required MouseCursor cursor,
    required bool isLeft,
    required bool isTop,
  }) {
    final double outerLeft = shadowExtents.left - windowResizeBorder;
    final double outerRight = shadowExtents.right - windowResizeBorder;
    final double outerTop = shadowExtents.top - windowResizeBorder;
    final double outerBottom = shadowExtents.bottom - windowResizeBorder;
    const double armLength = windowResizeBorder + _cornerExtent;
    return <Widget>[
      _handle(
        edge: edge,
        cursor: cursor,
        left: isLeft ? outerLeft : null,
        right: isLeft ? null : outerRight,
        top: isTop ? outerTop : null,
        bottom: isTop ? null : outerBottom,
        width: armLength,
        height: windowResizeBorder,
      ),
      _handle(
        edge: edge,
        cursor: cursor,
        left: isLeft ? outerLeft : null,
        right: isLeft ? null : outerRight,
        top: isTop ? outerTop : null,
        bottom: isTop ? null : outerBottom,
        width: windowResizeBorder,
        height: armLength,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The handles run along the outside of the window, in the innermost part of
    // the space left for the shadow.
    final double outerLeft = shadowExtents.left - windowResizeBorder;
    final double outerRight = shadowExtents.right - windowResizeBorder;
    final double outerTop = shadowExtents.top - windowResizeBorder;
    final double outerBottom = shadowExtents.bottom - windowResizeBorder;
    // Where an edge handle starts, i.e. past the corner handle beside it.
    const double cornerLength = windowResizeBorder + _cornerExtent;

    return Stack(
      children: <Widget>[
        child,
        // Edges first so the corner handles that overlap them win.
        _handle(
          edge: WindowDragEdge.north,
          cursor: SystemMouseCursors.resizeUp,
          left: outerLeft + cornerLength,
          right: outerRight + cornerLength,
          top: outerTop,
          height: windowResizeBorder,
        ),
        _handle(
          edge: WindowDragEdge.south,
          cursor: SystemMouseCursors.resizeDown,
          left: outerLeft + cornerLength,
          right: outerRight + cornerLength,
          bottom: outerBottom,
          height: windowResizeBorder,
        ),
        _handle(
          edge: WindowDragEdge.west,
          cursor: SystemMouseCursors.resizeLeft,
          top: outerTop + cornerLength,
          bottom: outerBottom + cornerLength,
          left: outerLeft,
          width: windowResizeBorder,
        ),
        _handle(
          edge: WindowDragEdge.east,
          cursor: SystemMouseCursors.resizeRight,
          top: outerTop + cornerLength,
          bottom: outerBottom + cornerLength,
          right: outerRight,
          width: windowResizeBorder,
        ),
        ..._cornerHandles(
          edge: WindowDragEdge.northWest,
          cursor: SystemMouseCursors.resizeUpLeft,
          isLeft: true,
          isTop: true,
        ),
        ..._cornerHandles(
          edge: WindowDragEdge.northEast,
          cursor: SystemMouseCursors.resizeUpRight,
          isLeft: false,
          isTop: true,
        ),
        ..._cornerHandles(
          edge: WindowDragEdge.southWest,
          cursor: SystemMouseCursors.resizeDownLeft,
          isLeft: true,
          isTop: false,
        ),
        ..._cornerHandles(
          edge: WindowDragEdge.southEast,
          cursor: SystemMouseCursors.resizeDownRight,
          isLeft: false,
          isTop: false,
        ),
      ],
    );
  }
}
