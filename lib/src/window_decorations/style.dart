import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import 'aqua/aqua_style.dart';
import 'fluent/fluent_style.dart';
import 'gtk/gtk_style.dart';

/// An edge or corner of a window that can be dragged to resize it.
enum WindowEdge {
  topLeft,
  top,
  topRight,
  left,
  right,
  bottomLeft,
  bottom,
  bottomRight,
}

/// The state of a window, and the ways it can be driven.
///
/// This is everything a [WindowDecorationStyle] is allowed to know about the
/// window it is decorating. Keeping the window itself away from the styles
/// means they hold nothing but the look of a platform, and can be built and
/// tested without a window at all.
@immutable
class WindowDecorationDetails {
  final String title;
  final bool isActivated;
  final bool isMaximized;

  /// Whether the window can be resized by dragging its edges. Maximized
  /// windows are held against the screen edges, so they cannot.
  final bool canResize;

  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;

  /// Brings the window to the front and gives it the keyboard focus.
  final VoidCallback onActivate;

  /// Starts dragging the whole window with the given pointer button.
  final void Function(int button) onMove;

  /// Starts dragging one edge or corner of the window.
  final void Function(WindowEdge edge, int button) onResize;

  const WindowDecorationDetails({
    required this.title,
    required this.isActivated,
    required this.isMaximized,
    required this.canResize,
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onActivate,
    required this.onMove,
    required this.onResize,
  });
}

/// The look of the decorations drawn around a window.
///
/// Each desktop draws its windows differently enough that the differences are
/// structural rather than a matter of colour: GTK centres the title and puts
/// round buttons after it, Windows puts a left aligned title and full height
/// rectangular buttons, and macOS puts its buttons before the title. So a style
/// builds those parts itself, and only publishes the measurements the shared
/// layout and hit testing need as numbers.
///
/// Styles emulate a platform rather than asking it how to draw, in the same way
/// the Cupertino widgets emulate iOS. An app is free to use any style on any
/// platform.
abstract class WindowDecorationStyle {
  const WindowDecorationStyle();

  /// The style of the platform the app is running on.
  factory WindowDecorationStyle.adaptive() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux => const GtkWindowDecorationStyle(),
      TargetPlatform.windows => const FluentWindowDecorationStyle(),
      TargetPlatform.macOS => const AquaWindowDecorationStyle(),
      _ => throw UnsupportedError(
        '$defaultTargetPlatform does not have decorated windows',
      ),
    };
  }

  /// The space to leave around a window for the shadow it casts.
  ///
  /// The resize handles live in here too, so this is never smaller than
  /// [resizeBorder].
  EdgeInsets get shadowExtents;

  /// The width of the invisible border around a window that can be grabbed to
  /// resize it.
  double get resizeBorder;

  /// How much the corners of the window are rounded.
  BorderRadius cornerRadius({required bool isMaximized});

  /// Builds the bar along the top of the window that holds its title and the
  /// buttons that close, minimize and maximize it.
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window);

  /// Draws the shadow the window casts on what is behind it, around [child].
  ///
  /// The shadow is drawn by the app rather than the window system because a
  /// window that draws its own decorations has to be transparent around them,
  /// and so cannot use the shadow the window system would draw.
  Widget buildShadow(
    BuildContext context,
    WindowDecorationDetails window,
    Widget child,
  );

  /// Puts a window into the state this style needs before it is first shown,
  /// i.e. stops the window system drawing decorations of its own.
  void prepareWindow(BaseWindowController controller);

  /// Shrinks [insets] until they leave at least a pixel of room in [size].
  ///
  /// A window is laid out at a minimal size until it is first shown, and there
  /// the shadow extents are bigger than the whole window. Padding the window
  /// away to nothing there would leave nothing to draw, and a window that never
  /// draws anything never gets shown.
  static EdgeInsets fitInsets(EdgeInsets insets, Size size) {
    final double horizontal = _scale(insets.horizontal, size.width);
    final double vertical = _scale(insets.vertical, size.height);
    if (horizontal == 1 && vertical == 1) {
      return insets;
    }
    return EdgeInsets.only(
      left: insets.left * horizontal,
      right: insets.right * horizontal,
      top: insets.top * vertical,
      bottom: insets.bottom * vertical,
    );
  }

  static double _scale(double inset, double extent) {
    if (!extent.isFinite || inset <= 0 || inset < extent) {
      return 1;
    }
    return math.max(extent - 1, 0) / inset;
  }
}
