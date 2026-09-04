import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How far [shadows] reach out from the box they are drawn around, and so how
/// much space has to be left around a window for them.
///
/// A window whose buffer is too small for its shadow gets a shadow with a
/// straight edge cut across it, so this is deliberately generous: a Gaussian
/// blur is only invisible past three standard deviations.
///
/// The result is never smaller than [minimum], which is how the desktops make
/// sure there is always room for the invisible resize border.
EdgeInsets shadowExtentsOf(List<BoxShadow> shadows, {double minimum = 0}) {
  EdgeInsets result = EdgeInsets.all(minimum);
  for (final BoxShadow shadow in shadows) {
    final double reach = 3 * shadow.blurSigma + shadow.spreadRadius;
    double side(double current, double offset) =>
        math.max(current, math.max(0, (reach + offset).ceilToDouble()));
    result = EdgeInsets.only(
      left: side(result.left, -shadow.offset.dx),
      right: side(result.right, shadow.offset.dx),
      top: side(result.top, -shadow.offset.dy),
      bottom: side(result.bottom, shadow.offset.dy),
    );
  }
  return result;
}
