import 'package:flutter/widgets.dart';
import 'package:flutter_csd_test/window_decorations.dart';

import 'cloud_shape.dart';
import 'star_button.dart';

/// The title bar of a cloud, i.e. a patch of sky with the title written across
/// it and a star for each of the window buttons.
///
/// It is kept a puff away from the edges of the window, because the top corners
/// of the window are cut away by the shape of the cloud.
class CloudTitleBar extends StatelessWidget {
  final WindowDecorationDetails window;

  const CloudTitleBar({super.key, required this.window});

  static const double _buttonRow = 38;

  /// The room to leave above the title bar for the puffs along the top edge of
  /// the window, which a maximized window is not drawn with.
  static double insetFor(bool isMaximized) => isMaximized ? 6 : CloudShape.puff;

  @override
  Widget build(BuildContext context) {
    final bool isActivated = window.isActivated;
    final double inset = insetFor(window.isMaximized);

    return Container(
      height: inset + _buttonRow,
      decoration: BoxDecoration(
        // The sky fades out to almost white along the bottom, so that the
        // puffs the title bar shares with the window contents below it don't
        // have a line drawn across them where the two meet.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isActivated
              ? const <Color>[Color(0xFF8FC7EE), Color(0xFFF8FAFD)]
              : const <Color>[Color(0xFFDCE5EB), Color(0xFFF8FAFD)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(CloudShape.puff, inset, CloudShape.puff, 4),
      child: Stack(
        // The draggable area sits below the window controls so that pointer
        // events over a star never reach it.
        children: <Widget>[
          Positioned.fill(
            child: WindowMoveArea(
              window: window,
              child: Center(child: CloudWindowTitle(window: window)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CloudWindowControls(window: window),
          ),
        ],
      ),
    );
  }
}

class CloudWindowTitle extends StatelessWidget {
  final WindowDecorationDetails window;

  const CloudWindowTitle({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Text(
      window.title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: window.isActivated
            ? const Color(0xFF2B4A63)
            : const Color(0xFF9AAEBC),
      ),
    );
  }
}

class CloudWindowControls extends StatelessWidget {
  final WindowDecorationDetails window;

  const CloudWindowControls({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        StarWindowButton(
          color: const Color(0xFFFFC94D),
          semanticLabel: 'Minimize',
          isActivated: window.isActivated,
          onPressed: window.onMinimize,
        ),
        StarWindowButton(
          color: const Color(0xFF6FCF97),
          semanticLabel: window.isMaximized ? 'Restore' : 'Maximize',
          isActivated: window.isActivated,
          onPressed: window.onToggleMaximize,
        ),
        StarWindowButton(
          color: const Color(0xFFFF8A80),
          semanticLabel: 'Close',
          isActivated: window.isActivated,
          onPressed: window.onClose,
        ),
      ],
    );
  }
}
