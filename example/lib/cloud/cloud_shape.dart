import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The shape of a cloud: a rectangle with puffs bulging out all the way around
/// it.
///
/// The puffs grow out of a core rectangle inset by the puff radius on every
/// side, and are never bigger than that radius, so a cloud always fills exactly
/// the box it is given however many puffs it ends up with.
abstract final class CloudShape {
  /// How far a puff bulges out from the core of the cloud.
  ///
  /// The decorations keep the title bar this far from the edges of the window,
  /// so that nothing is drawn where a puff might not be.
  static const double puff = 26;

  /// The puff radius to draw a cloud of [size] with.
  ///
  /// A window is laid out at a minimal size until it is first shown, and a
  /// small cloud with full sized puffs would be all edge and no middle.
  static double puffFor(Size size) =>
      math.min(puff, size.shortestSide / 8).clamp(4, puff);

  /// The outline of a cloud filling [size].
  static Path path(Size size) {
    final Path path = Path()..fillType = PathFillType.nonZero;
    final double radius = puffFor(size);
    final Rect core = Rect.fromLTRB(
      radius,
      radius,
      size.width - radius,
      size.height - radius,
    );
    if (core.isEmpty) {
      return path..addOval(Offset.zero & size);
    }

    // The puffs overlap each other and the core, and every one of them winds
    // the same way round, so filling the lot as a single non-zero path draws
    // their union without the outline ever having to be worked out.
    path.addRect(core);
    final double perimeter = 2 * (core.width + core.height);
    final int count = math.max(8, (perimeter / (radius * 1.5)).round());
    for (int i = 0; i < count; i++) {
      // Puffs of a single size look machined rather than drawn. Stepping the
      // variation by the golden angle keeps every puff a different size from
      // its neighbours without the sizes falling into a pattern.
      final double variation = 0.5 + 0.5 * math.sin(i * 2.39996);
      path.addOval(
        Rect.fromCircle(
          center: _alongPerimeter(core, perimeter * i / count),
          radius: radius * (0.72 + 0.28 * variation),
        ),
      );
    }
    return path;
  }

  /// The point [distance] clockwise around the edge of [rect], starting from
  /// its top left corner.
  static Offset _alongPerimeter(Rect rect, double distance) {
    double travelled = distance;
    if (travelled < rect.width) {
      return Offset(rect.left + travelled, rect.top);
    }
    travelled -= rect.width;
    if (travelled < rect.height) {
      return Offset(rect.right, rect.top + travelled);
    }
    travelled -= rect.height;
    if (travelled < rect.width) {
      return Offset(rect.right - travelled, rect.bottom);
    }
    return Offset(rect.left, rect.bottom - (travelled - rect.width));
  }
}

/// Cuts a window out in the shape of a cloud.
class CloudClipper extends CustomClipper<Path> {
  const CloudClipper();

  @override
  Path getClip(Size size) => CloudShape.path(size);

  @override
  bool shouldReclip(CloudClipper oldClipper) => false;
}

/// Draws the shadow a cloud casts on what is behind it.
///
/// Only the shadow: the window contents are clipped to the same shape and drawn
/// over the top, so there is nothing to be gained by filling the cloud in as
/// well.
class CloudShadowPainter extends CustomPainter {
  final List<BoxShadow> shadows;

  const CloudShadowPainter(this.shadows);

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = CloudShape.path(size);
    for (final BoxShadow shadow in shadows) {
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(path, shadow.toPaint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CloudShadowPainter oldDelegate) =>
      !listEquals(shadows, oldDelegate.shadows);
}
