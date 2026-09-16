import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import 'resize_handles.dart';
import 'style.dart';
import 'theme.dart';
import 'window_platform.dart';

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

  /// Takes the decorations away from the window system.
  ///
  /// This only has to be done as the window changes, not every time the
  /// decorations are rebuilt. The style makes no difference: every style draws
  /// the same parts of the window.
  void _prepareWindow() {
    final BaseWindowController controller = WindowScope.of(context);
    if (identical(controller, _preparedWindow)) {
      return;
    }
    _preparedWindow = controller;
    WindowPlatform.of(controller).setDecorated(false);
  }

  @override
  Widget build(BuildContext context) {
    final WindowDecorationStyle style = _style;
    final WindowController controller =
        WindowScope.of(context) as WindowController;
    final WindowPlatform platform = WindowPlatform.of(controller);

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
      onMove: platform.beginMove,
      onResize: platform.beginResize,
    );

    Widget decorated = Column(
      children: <Widget>[
        // The title bar redraws as its buttons are hovered and pressed, so
        // keep it off the layer the window shadows are drawn on.
        RepaintBoundary(child: style.buildTitleBar(context, window)),
        // The debug banner paints outside the bounds of the app, so clip it
        // to the window contents.
        //
        // The contents are also given a layer of their own so that an app
        // animating doesn't make the decorations around it repaint.
        Expanded(child: ClipRect(child: RepaintBoundary(child: widget.child))),
      ],
    );

    // Where the window system goes on drawing the frame it only gave up its
    // title bar, so the title bar is the whole of the decorations. Everywhere
    // else the app draws the window itself, borders, corners, shadow and all.
    if (!platform.drawsFrame) {
      decorated = ClipRRect(
        borderRadius: style.cornerRadius(isMaximized: isMaximized),
        child: decorated,
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
    }

    return Directionality(textDirection: TextDirection.ltr, child: decorated);
  }
}
