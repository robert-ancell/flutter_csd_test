import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import 'resize_handles.dart';
import 'style.dart';
import 'theme.dart';
import 'window_gestures.dart';

/// Draws client side decorations around the contents of a window.
///
/// Gives the window a title bar with minimize, maximize and close buttons,
/// rounded corners, a drop shadow and borders that can be dragged to resize it,
/// in the style of a desktop. The window is driven through the
/// [WindowController] provided by the enclosing [WindowScope].
///
/// The decorations are drawn in the [style] given here, or the one from the
/// enclosing [WindowDecorationTheme], or failing that the style of the platform
/// the app is running on.
class WindowDecorations extends StatefulWidget {
  final Widget child;
  final WindowDecorationStyle? style;

  const WindowDecorations({super.key, required this.child, this.style});

  @override
  State<WindowDecorations> createState() => _WindowDecorationsState();
}

class _WindowDecorationsState extends State<WindowDecorations> {
  BaseWindowController? _preparedWindow;
  WindowDecorationStyle? _preparedStyle;

  WindowDecorationStyle get _style =>
      widget.style ?? WindowDecorationTheme.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareWindow();
  }

  @override
  void didUpdateWidget(WindowDecorations oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prepareWindow();
  }

  /// Stops the window system drawing decorations of its own.
  ///
  /// This only has to be done as the window or the style changes, not every
  /// time the decorations are rebuilt.
  void _prepareWindow() {
    final BaseWindowController controller = WindowScope.of(context);
    final WindowDecorationStyle style = _style;
    if (identical(controller, _preparedWindow) &&
        identical(style, _preparedStyle)) {
      return;
    }
    _preparedWindow = controller;
    _preparedStyle = style;
    style.prepareWindow(controller);
  }

  @override
  Widget build(BuildContext context) {
    final WindowDecorationStyle style = _style;
    final WindowController controller =
        WindowScope.of(context) as WindowController;
    final WindowGestures gestures = WindowGestures.of(controller);

    // Maximized windows are tiled against the screen edges, so they can't be
    // resized by their edges and have no margin to put the resize handles in.
    final bool isMaximized = WindowScope.isMaximizedOf(context);
    final WindowDecorationDetails window = WindowDecorationDetails(
      title: WindowScope.titleOf(context),
      isActivated: WindowScope.isActivatedOf(context),
      isMaximized: isMaximized,
      canResize: !isMaximized,
      onClose: controller.destroy,
      onMinimize: () => controller.setMinimized(true),
      onToggleMaximize: () => controller.setMaximized(!controller.isMaximized),
      onActivate: controller.activate,
      onMove: gestures.beginMove,
      onResize: gestures.beginResize,
    );

    Widget decorated = ClipRRect(
      borderRadius: style.cornerRadius(isMaximized: isMaximized),
      child: Column(
        children: <Widget>[
          // The title bar redraws as its buttons are hovered and pressed, so
          // keep it off the layer the window shadows are drawn on.
          RepaintBoundary(child: style.buildTitleBar(context, window)),
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

    if (window.canResize) {
      decorated = WindowResizeHandles(
        shadowExtents: style.shadowExtents,
        resizeBorder: style.resizeBorder,
        cornerRadius: style.cornerRadius(isMaximized: isMaximized),
        onResize: window.onResize,
        child: style.buildShadow(context, window, decorated),
      );
    }

    return Directionality(textDirection: TextDirection.ltr, child: decorated);
  }
}
