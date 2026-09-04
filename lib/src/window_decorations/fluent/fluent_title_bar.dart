import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../move_area.dart';
import '../style.dart';
import 'fluent_buttons.dart';

/// The title bar Windows draws along the top of a window.
///
/// Unlike the other desktops the title is left aligned, after where the window
/// icon would be, and the buttons are full height rectangles.
class FluentTitleBar extends StatelessWidget {
  final WindowDecorationDetails window;

  const FluentTitleBar({super.key, required this.window});

  /// The caption height in Windows 11.
  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: window.isActivated
          ? const Color(0xFFF3F3F3)
          : const Color(0xFFF9F9F9),
      child: Row(
        children: <Widget>[
          Expanded(
            child: WindowMoveArea(
              window: window,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FluentWindowTitle(window: window),
                ),
              ),
            ),
          ),
          FluentWindowControls(window: window),
        ],
      ),
    );
  }
}

class FluentWindowTitle extends StatelessWidget {
  final WindowDecorationDetails window;

  const FluentWindowTitle({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Text(
      window.title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: window.isActivated
            ? const Color(0xFF191919)
            : const Color(0xFF757575),
      ),
    );
  }
}

class FluentWindowControls extends StatelessWidget {
  final WindowDecorationDetails window;

  const FluentWindowControls({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentWindowControlButton(
          icon: Icons.minimize,
          tooltip: 'Minimize',
          isActivated: window.isActivated,
          onPressed: window.onMinimize,
        ),
        FluentWindowControlButton(
          icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
          tooltip: window.isMaximized ? 'Restore' : 'Maximize',
          isActivated: window.isActivated,
          onPressed: window.onToggleMaximize,
        ),
        FluentWindowControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          isActivated: window.isActivated,
          isClose: true,
          onPressed: window.onClose,
        ),
      ],
    );
  }
}
