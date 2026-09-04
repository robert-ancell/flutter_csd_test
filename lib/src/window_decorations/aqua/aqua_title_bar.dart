import 'package:flutter/widgets.dart';

import '../move_area.dart';
import '../style.dart';
import 'aqua_buttons.dart';

/// The title bar macOS draws along the top of a window.
///
/// The buttons come before the title rather than after it, and the title stays
/// centred in the window whatever is beside it.
class AquaTitleBar extends StatelessWidget {
  final WindowDecorationDetails window;

  const AquaTitleBar({super.key, required this.window});

  /// The height of a standard, i.e. not a tall, title bar.
  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: window.isActivated
            ? const Color(0xFFECECEC)
            : const Color(0xFFF6F6F6),
        border: Border(
          bottom: BorderSide(
            color: window.isActivated
                ? const Color(0xFFD5D5D5)
                : const Color(0xFFE4E4E4),
          ),
        ),
      ),
      child: Stack(
        children: <Widget>[
          // The draggable area sits below the window controls so that pointer
          // events over a button never reach it.
          Positioned.fill(
            child: WindowMoveArea(
              window: window,
              child: Center(child: AquaWindowTitle(window: window)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: AquaWindowControls(
                isActivated: window.isActivated,
                isMaximized: window.isMaximized,
                onClose: window.onClose,
                onMinimize: window.onMinimize,
                onToggleMaximize: window.onToggleMaximize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AquaWindowTitle extends StatelessWidget {
  final WindowDecorationDetails window;

  const AquaWindowTitle({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Text(
      window.title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: window.isActivated
            ? const Color(0xD9000000)
            : const Color(0x40000000),
      ),
    );
  }
}
