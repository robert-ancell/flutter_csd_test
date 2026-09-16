import "package:flutter/src/widgets/_window.dart";
import "package:flutter/src/widgets/_window_linux.dart";
import "package:flutter/src/widgets/_window_macos.dart";
import "package:flutter/src/widgets/_window_win32.dart";

import 'platform_linux.dart';
import 'platform_macos.dart';
import 'platform_win32.dart';
import 'style.dart';

/// The window system a window belongs to, and the things the window
/// decoration widgets need from it.
///
/// These are the things the cross platform [WindowController] doesn't have:
/// taking away the decorations the window system draws, and handing a drag
/// back to it, which takes over the pointer until the button is released.
///
/// Only GTK has all of this in the windowing API. Windows and macOS are done by
/// calling the platform directly, in [Win32WindowPlatform] and
/// [MacOSWindowPlatform], so that this app builds against the master channel.
/// As the API grows to cover them those can be emptied out the way
/// [LinuxWindowPlatform] has been.
abstract class WindowPlatform {
  const WindowPlatform();

  static WindowPlatform of(BaseWindowController controller) {
    // Matching the concrete controller rather than the platform mixin, because
    // the mixins are not subtypes of the sealed BaseWindowController and so
    // don't promote.
    if (controller is WindowControllerLinux) {
      return LinuxWindowPlatform(controller);
    }
    if (controller is WindowControllerWin32) {
      return Win32WindowPlatform(controller);
    }
    if (controller is WindowControllerMacOS) {
      return MacOSWindowPlatform(controller);
    }
    throw UnsupportedError(
      'Windows cannot be decorated by the app on this platform yet',
    );
  }

  /// Whether the window system goes on drawing the frame around a window whose
  /// decorations it has given up: its border, the border's resize handles, its
  /// rounded corners and its drop shadow.
  ///
  /// These go together because a window system either hands over the whole
  /// window or only its title bar. Windows and macOS hand over the title bar
  /// alone, so an app there draws nothing but a title bar of its own, and
  /// drawing any of the rest would double up on a frame that is still there.
  /// GTK takes away the whole frame, so an app there has to draw all of it.
  ///
  /// The title bar is not part of this: the app always draws that one.
  bool get drawsFrame;

  /// Sets whether the window system draws the decorations of this window,
  /// rather than the app.
  void setDecorated(bool decorated);

  /// Hands a press on the title bar to the window system, which drags the
  /// window until the button is released.
  void beginMove(int button);

  /// Hands a press on a window border to the window system, which resizes the
  /// window until the button is released.
  ///
  /// Only called where [drawsFrame] is false, because the app only draws the
  /// borders to press when the window system has given them up.
  void beginResize(WindowEdge edge, int button);
}
