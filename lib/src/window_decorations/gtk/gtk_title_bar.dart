import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../move_area.dart';
import '../style.dart';
import 'gtk_buttons.dart';

/// The title bar GTK3 Adwaita draws for a window that has no header bar.
///
/// GTK builds it as a header bar with no spacing and the "titlebar" and
/// "default-decoration" style classes, which the theme gives a minimum height
/// of 28 pixels, 4 pixels of padding and a one pixel bottom border.
class GtkTitleBar extends StatelessWidget {
  final WindowDecorationDetails window;

  const GtkTitleBar({super.key, required this.window});

  static const double height = 28 + 4 + 4 + 1;

  @override
  Widget build(BuildContext context) {
    final bool isActivated = window.isActivated;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: isActivated
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFE1DEDB), Color(0xFFDAD6D2)],
              )
            : null,
        color: isActivated ? null : const Color(0xFFF6F5F4),
        border: Border(
          bottom: BorderSide(
            color: isActivated
                ? const Color(0xFFBFB8B1)
                : const Color(0xFFD5D0CC),
          ),
        ),
      ),
      // The highlight along the top of the title bar. GTK draws it as an inset
      // shadow, which takes up no space, so it goes in front of the contents
      // rather than in the border.
      foregroundDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xCCFFFFFF))),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: <Widget>[
          // The draggable area sits below the window controls so that
          // pointer events over a button never reach it.
          Positioned.fill(
            child: WindowMoveArea(
              window: window,
              child: Center(child: GtkWindowTitle(window: window)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GtkWindowControls(window: window),
          ),
        ],
      ),
    );
  }
}

class GtkWindowTitle extends StatelessWidget {
  final WindowDecorationDetails window;

  const GtkWindowTitle({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Text(
      window.title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: window.isActivated
            ? const Color(0xFF2E3436)
            : const Color(0xFF8B8E8F),
      ),
    );
  }
}

class GtkWindowControls extends StatelessWidget {
  final WindowDecorationDetails window;

  const GtkWindowControls({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    // GTK gives the title bar it draws for a window without a header bar a
    // spacing of zero, so its buttons sit right next to each other.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GtkWindowControlButton(
          icon: Icons.remove,
          tooltip: 'Minimize',
          isActivated: window.isActivated,
          onPressed: window.onMinimize,
        ),
        GtkWindowControlButton(
          icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
          iconSize: window.isMaximized ? 12 : 14,
          tooltip: window.isMaximized ? 'Restore' : 'Maximize',
          isActivated: window.isActivated,
          onPressed: window.onToggleMaximize,
        ),
        GtkWindowControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          isActivated: window.isActivated,
          onPressed: window.onClose,
        ),
      ],
    );
  }
}
