import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The outline of a five pointed star filling [size], point upwards.
Path starPath(Size size) {
  const int points = 5;
  final Offset centre = size.center(Offset.zero);
  final double outer = size.shortestSide / 2;
  final double inner = outer * 0.45;

  final Path path = Path();
  for (int corner = 0; corner < points * 2; corner++) {
    // Every other corner is a point of the star, and the ones between them are
    // the notches that separate the points.
    final double radius = corner.isEven ? outer : inner;
    final double angle = -math.pi / 2 + corner * math.pi / points;
    final Offset at =
        centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    if (corner == 0) {
      path.moveTo(at.dx, at.dy);
    } else {
      path.lineTo(at.dx, at.dy);
    }
  }
  return path..close();
}

/// A star that closes, minimizes or maximizes the window when it is clicked.
class StarWindowButton extends StatefulWidget {
  final Color color;
  final String semanticLabel;
  final bool isActivated;
  final VoidCallback onPressed;

  const StarWindowButton({
    super.key,
    required this.color,
    required this.semanticLabel,
    required this.isActivated,
    required this.onPressed,
  });

  /// The size of the box a star is drawn in.
  static const double size = 24;

  @override
  State<StarWindowButton> createState() => _StarWindowButtonState();
}

class _StarWindowButtonState extends State<StarWindowButton> {
  bool _hovered = false;
  bool _pressed = false;

  /// A star lights up as the pointer comes over it, and dims along with the
  /// rest of the title bar when the window loses focus.
  Color get _color {
    if (!widget.isActivated) {
      return Color.lerp(widget.color, const Color(0xFFE8EEF2), 0.6)!;
    }
    if (_hovered) {
      return Color.lerp(widget.color, const Color(0xFFFFFFFF), 0.45)!;
    }
    return widget.color;
  }

  double get _scale {
    if (_pressed) {
      return 0.85;
    }
    return _hovered ? 1.15 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (PointerEnterEvent event) {
          setState(() => _hovered = true);
        },
        onExit: (PointerExitEvent event) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            setState(() => _pressed = true);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTap: () {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: SizedBox.square(
            dimension: StarWindowButton.size,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 90),
              child: CustomPaint(painter: _StarPainter(_color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;

  const _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      starPath(size),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => color != oldDelegate.color;
}
