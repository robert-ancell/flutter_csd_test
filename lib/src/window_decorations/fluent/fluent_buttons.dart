import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A caption button in a Windows title bar.
///
/// These are full height rectangles rather than the round buttons the other
/// desktops use, and the close button turns red rather than just darker.
class FluentWindowControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActivated;

  /// Whether this is the close button, which is highlighted in red.
  final bool isClose;

  final VoidCallback onPressed;

  const FluentWindowControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isActivated,
    required this.onPressed,
    this.isClose = false,
  });

  /// The size of a caption button in Windows 11.
  static const double width = 46;
  static const double height = 32;

  @override
  State<FluentWindowControlButton> createState() =>
      _FluentWindowControlButtonState();
}

class _FluentWindowControlButtonState extends State<FluentWindowControlButton> {
  bool _hovered = false;
  bool _pressed = false;

  Color? get _background {
    if (widget.isClose) {
      if (_pressed) {
        return const Color(0xFFC84031);
      }
      return _hovered ? const Color(0xFFC42B1C) : null;
    }
    if (_pressed) {
      return const Color(0x0A000000);
    }
    return _hovered ? const Color(0x0F000000) : null;
  }

  Color get _foreground {
    if (widget.isClose && (_hovered || _pressed)) {
      return const Color(0xFFFFFFFF);
    }
    return widget.isActivated
        ? const Color(0xFF191919)
        : const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
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
          child: Container(
            width: FluentWindowControlButton.width,
            height: FluentWindowControlButton.height,
            color: _background,
            child: Icon(widget.icon, size: 10, color: _foreground),
          ),
        ),
      ),
    );
  }
}
