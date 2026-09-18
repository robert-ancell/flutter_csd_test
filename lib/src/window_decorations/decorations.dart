import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import 'resize_handles.dart';
import 'style.dart';
import 'theme.dart';
import 'window_platform.dart';

/// A widget that decorates the window it is in, in place of the window system.
///
/// The window system is asked to leave the window undecorated, and decorations
/// are drawn around [child] instead. If this widget is removed the window
/// system returns to drawing the window decorations.
///
/// How the decorations look is up to the [style] given here, the enclosing
/// [WindowDecorationTheme], or failing that the platform the app is running on.
///
/// The whole of the window belongs inside [child], so this is usually the
/// widget the [Window] itself is given, with only widgets that draw nothing of
/// their own, such as [WindowDecorationTheme], above it.
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
  void dispose() {
    // These decorations are going away, so the window needs the ones the window
    // system draws back, otherwise it would be left with none at all.
    _restoreWindow(_preparedWindow);
    super.dispose();
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
    _restoreWindow(_preparedWindow);
    _preparedWindow = controller;
    WindowPlatform.of(controller).setDecorated(false);
  }

  /// Hands the decorations of [controller] back to the window system.
  ///
  /// A window that has already been destroyed is left alone, as it has no
  /// decorations left to hand back.
  void _restoreWindow(BaseWindowController? controller) {
    if (controller == null || controller.isDestroyed) {
      return;
    }
    WindowPlatform.of(controller).setDecorated(true);
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
        //
        // Nothing above a Window lays text out, so the title bar carries a
        // text direction of its own. It only goes around the decorations: the
        // app below is left to pick its own.
        RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: style.buildTitleBar(context, window),
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
    );

    // Where the window system goes on drawing the frame it has given up only
    // the strip its title bar sat in, so the title bar is the whole of the
    // decorations. Everywhere else the app draws the window itself, borders,
    // corners, shadow and all.
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

    return decorated;
  }
}
