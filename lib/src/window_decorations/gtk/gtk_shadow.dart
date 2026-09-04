import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../style.dart';

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

/// The shadow GTK3 Adwaita draws around a client side decorated window, i.e.
/// the box-shadow of the "decoration" node in that theme.
class GtkWindowShadows extends StatelessWidget {
  final Widget child;
  final bool isActivated;
  final double cornerRadius;
  final double resizeBorder;

  const GtkWindowShadows({
    super.key,
    required this.child,
    required this.isActivated,
    required this.cornerRadius,
    required this.resizeBorder,
  });

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
  static EdgeInsets extentsFor(double resizeBorder) {
    EdgeInsets result = EdgeInsets.all(resizeBorder);
    for (final GtkShadow shadow in <GtkShadow>[
      ..._activatedShadows,
      ..._backdropShadows,
    ]) {
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

  @override
  Widget build(BuildContext context) {
    final EdgeInsets extents = extentsFor(resizeBorder);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: WindowDecorationStyle.fitInsets(
            extents,
            constraints.biggest,
          ),
          child: DecoratedBox(
            decoration: _decorationFor(cornerRadius, isActivated),
            child: child,
          ),
        );
      },
    );
  }
}
