import 'package:flutter/widgets.dart';
import 'package:flutter_csd_test/window_decorations.dart';

import 'cloud_shape.dart';
import 'cloud_title_bar.dart';

/// Windows drawn as clouds, with a star for each of the window buttons.
///
/// A style belonging to no desktop at all, written here in the app rather than
/// in the package to show what a [WindowDecorationStyle] of your own takes: a
/// title bar, a shadow, and the measurements the decorations need to lay the
/// window out and to work out what the pointer is over.
///
/// The cloud is cut out in [buildShadow], which is only called where the window
/// system has handed the whole window over. Where it keeps the frame and gives
/// up nothing but the strip its title bar sat in, as Windows and macOS do, a
/// window cannot be any shape but the one the window system draws, so all that
/// is left of this style there is the patch of sky along the top.
class CloudWindowDecorationStyle extends WindowDecorationStyle {
  const CloudWindowDecorationStyle();

  /// The shadow a cloud casts, which is softer and bluer than the shadow of a
  /// window with edges.
  static const List<BoxShadow> _shadows = <BoxShadow>[
    BoxShadow(color: Color(0x3D3A6B96), offset: Offset(0, 10), blurRadius: 26),
  ];

  static final EdgeInsets _shadowExtents = shadowExtentsOf(
    _shadows,
    minimum: 12,
  );

  @override
  EdgeInsets get shadowExtents => _shadowExtents;

  @override
  double get resizeBorder => 10;

  @override
  BorderRadius cornerRadius({required bool isMaximized}) {
    // Nothing is rounded off before the cloud is cut out, which happens in
    // buildShadow where the whole of the outline can be described. A corner
    // radius could only say how the window is rounded, and a cloud has no
    // corners to round.
    return BorderRadius.zero;
  }

  @override
  Widget buildTitleBar(BuildContext context, WindowDecorationDetails window) {
    return CloudTitleBar(window: window);
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
          // The shadow is painted behind the window, and the window itself is
          // cut to the same shape, so the two always agree on where the edge of
          // the cloud is.
          child: CustomPaint(
            painter: const CloudShadowPainter(_shadows),
            child: ClipPath(clipper: const CloudClipper(), child: child),
          ),
        );
      },
    );
  }
}
