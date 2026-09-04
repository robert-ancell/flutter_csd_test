import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import '../shadow_extents.dart';
import '../style.dart';
import 'aqua_title_bar.dart';

/// Windows drawn in the style of macOS.
///
/// The measurements here are the ones macOS uses, but unlike the GTK style they
/// haven't been checked against a running desktop yet.
class AquaWindowDecorationStyle extends WindowDecorationStyle {
  const AquaWindowDecorationStyle();

  /// The corner radius macOS rounds windows to.
  static const double _cornerRadius = 10;

  @override
  double get resizeBorder => 6;

  /// The shadow macOS draws around a window, which is much larger and softer
  /// than the ones the other desktops use.
  static const List<BoxShadow> _shadows = <BoxShadow>[
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 10), blurRadius: 30),
    // The hairline border around the window, drawn as a shadow so that it
    // follows the rounded corners.
    BoxShadow(color: Color(0x1A000000), spreadRadius: 1),
  ];

  static final EdgeInsets _shadowExtents = shadowExtentsOf(
    _shadows,
    minimum: 6,
  );

  @override
  EdgeInsets get shadowExtents => _shadowExtents;

  @override
  BorderRadius cornerRadius({required bool isMaximized}) {
    // A zoomed window keeps its rounded corners, but a full screen one fills
    // the display and loses them.
    return BorderRadius.circular(_cornerRadius);
  }

  @override
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window) {
    return AquaTitleBar(window: window);
  }

  @override
  Widget buildShadow(
    BuildContext context,
    WindowDecorationDetails window,
    Widget child,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: WindowDecorationStyle.fitInsets(
            _shadowExtents,
            constraints.biggest,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: cornerRadius(isMaximized: window.isMaximized),
              boxShadow: _shadows,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void prepareWindow(BaseWindowController controller) {
    // Needs the macOS equivalent of setDecorated() and setBackgroundColor(),
    // i.e. a borderless window with a transparent, full size content view.
  }
}
