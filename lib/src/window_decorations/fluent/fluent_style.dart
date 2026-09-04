import 'package:flutter/widgets.dart';
import "package:flutter/src/widgets/_window.dart";

import '../shadow_extents.dart';
import '../style.dart';
import 'fluent_title_bar.dart';

/// Windows drawn in the style of Windows 11.
///
/// The measurements here are the ones Windows uses, but unlike the GTK style
/// they haven't been checked against a running desktop yet.
class FluentWindowDecorationStyle extends WindowDecorationStyle {
  const FluentWindowDecorationStyle();

  /// The corner radius Windows 11 rounds windows to.
  static const double _cornerRadius = 8;

  @override
  double get resizeBorder => 8;

  /// The shadow the desktop window manager draws around a window.
  static const List<BoxShadow> _shadows = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 16),
    // The hairline border around the window, drawn as a shadow so that it
    // follows the rounded corners.
    BoxShadow(color: Color(0x1F000000), spreadRadius: 1),
  ];

  static final EdgeInsets _shadowExtents = shadowExtentsOf(
    _shadows,
    minimum: 8,
  );

  @override
  EdgeInsets get shadowExtents => _shadowExtents;

  @override
  BorderRadius cornerRadius({required bool isMaximized}) {
    // A maximized or snapped window has square corners.
    return BorderRadius.circular(isMaximized ? 0 : _cornerRadius);
  }

  @override
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window) {
    return FluentTitleBar(window: window);
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
    // Windows draws no frame of its own around a window whose frame has been
    // extended into the client area, so there is nothing to turn off yet. This
    // needs the Windows equivalent of setDecorated() and setBackgroundColor().
  }
}
