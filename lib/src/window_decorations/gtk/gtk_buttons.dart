import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A button in a GTK3 title bar, i.e. a "button.titlebutton" node.
class GtkWindowControlButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool isActivated;
  final VoidCallback onPressed;

  const GtkWindowControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isActivated,
    required this.onPressed,
    this.iconSize = 14,
  });

  @override
  State<GtkWindowControlButton> createState() => _GtkWindowControlButtonState();
}

class _GtkWindowControlButtonState extends State<GtkWindowControlButton> {
  /// The size of a window button, as GTK3 Adwaita sizes the ones in the title
  /// bar it draws for a window without a header bar.
  ///
  /// The theme gives "button.titlebutton" a minimum size of 26 pixels and a one
  /// pixel border, which fills the height of the title bar exactly.
  static const double _size = 26 + 1 + 1;

  bool _hovered = false;
  bool _pressed = false;

  /// How a window button is drawn when it is pressed, hovered, or neither.
  ///
  /// GTK draws nothing at all until the pointer is over the button, and then a
  /// circle the shape of the whole button.
  BoxDecoration? get _decoration {
    if (_pressed) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD6D1CD),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFCDC7C2))),
      );
    }
    if (_hovered) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFDFDFC), Color(0xFFF4F3F2)],
        ),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFCDC7C2))),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.tooltip,
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
          child: Container(
            width: _size,
            height: _size,
            decoration: _decoration,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.isActivated
                  ? const Color(0xFF2E3436)
                  : const Color(0xFF8B8E8F),
            ),
          ),
        ),
      ),
    );
  }
}
