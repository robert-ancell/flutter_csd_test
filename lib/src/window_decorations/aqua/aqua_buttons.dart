import 'package:flutter/material.dart' show Icons;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// One of the three round buttons at the start of a macOS title bar.
///
/// They are only coloured while the window is focused, and only show their
/// glyph while the pointer is somewhere over the group, so they are told about
/// both from outside.
class AquaWindowControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;

  /// The colour of the glyph, which is a dark shade of [color].
  final Color glyphColor;

  final bool isActivated;
  final bool showGlyph;
  final VoidCallback onPressed;

  const AquaWindowControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.glyphColor,
    required this.isActivated,
    required this.showGlyph,
    required this.onPressed,
  });

  /// The diameter of a traffic light button.
  static const double size = 12;

  @override
  State<AquaWindowControlButton> createState() =>
      _AquaWindowControlButtonState();
}

class _AquaWindowControlButtonState extends State<AquaWindowControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color color = widget.isActivated ? widget.color : const Color(0xFFD6D6D6);
    if (_pressed) {
      color = Color.alphaBlend(const Color(0x33000000), color);
    }

    return Semantics(
      label: widget.tooltip,
      button: true,
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
        child: Container(
          width: AquaWindowControlButton.size,
          height: AquaWindowControlButton.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0x1A000000)),
            ),
          ),
          child: widget.showGlyph && widget.isActivated
              ? Icon(widget.icon, size: 8, color: widget.glyphColor)
              : null,
        ),
      ),
    );
  }
}

/// The three traffic light buttons, which show their glyphs together as soon as
/// the pointer is over any of them.
class AquaWindowControls extends StatefulWidget {
  final bool isActivated;
  final bool isMaximized;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;

  const AquaWindowControls({
    super.key,
    required this.isActivated,
    required this.isMaximized,
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
  });

  @override
  State<AquaWindowControls> createState() => _AquaWindowControlsState();
}

class _AquaWindowControlsState extends State<AquaWindowControls> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) {
        setState(() => _hovered = true);
      },
      onExit: (PointerExitEvent event) {
        setState(() => _hovered = false);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          AquaWindowControlButton(
            icon: Icons.close,
            tooltip: 'Close',
            color: const Color(0xFFFF5F57),
            glyphColor: const Color(0xFF4D0000),
            isActivated: widget.isActivated,
            showGlyph: _hovered,
            onPressed: widget.onClose,
          ),
          AquaWindowControlButton(
            icon: Icons.remove,
            tooltip: 'Minimize',
            color: const Color(0xFFFEBC2E),
            glyphColor: const Color(0xFF995700),
            isActivated: widget.isActivated,
            showGlyph: _hovered,
            onPressed: widget.onMinimize,
          ),
          AquaWindowControlButton(
            icon: widget.isMaximized
                ? Icons.close_fullscreen
                : Icons.open_in_full,
            tooltip: widget.isMaximized ? 'Restore' : 'Zoom',
            color: const Color(0xFF28C840),
            glyphColor: const Color(0xFF006500),
            isActivated: widget.isActivated,
            showGlyph: _hovered,
            onPressed: widget.onToggleMaximize,
          ),
        ],
      ),
    );
  }
}
