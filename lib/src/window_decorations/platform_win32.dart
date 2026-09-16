import 'dart:ffi' as ffi;

import 'package:flutter/src/widgets/_window_win32.dart';

import 'style.dart';
import 'window_platform.dart';

/// The things the window decoration widgets need from Windows.
///
/// None of this is in the windowing API yet, so it is all done here by calling
/// Win32 directly. Once the API covers it this can be replaced by calls to the
/// window controller.
class Win32WindowPlatform extends WindowPlatform {
  final WindowControllerWin32 controller;

  const Win32WindowPlatform(this.controller);

  /// Windows keeps every part of the frame and hands over only the strip the
  /// title bar sits in, by letting the client area extend up over it. The
  /// border, shadow and rounded corners are still drawn outside the client
  /// area, so the window can still be resized by its border, snapped to the
  /// screen edges and restored from the taskbar without the app doing anything.
  @override
  bool get drawsFrame => true;

  @override
  void setDecorated(bool decorated) =>
      _Win32Frame.of(controller.windowHandle).setDecorated(decorated);

  @override
  void beginMove(int button) {
    // The pointer has to be let go of first, or the window being dragged never
    // sees the pointer events that move it.
    _releaseCapture();
    _sendMessage(controller.windowHandle, _wmSysCommand, _scMove | _htCaption, 0);
  }

  @override
  void beginResize(WindowEdge edge, int button) {
    _releaseCapture();
    _sendMessage(
      controller.windowHandle,
      _wmSysCommand,
      _scSize | _wmszEdges[edge]!,
      0,
    );
  }
}

/// Keeps a window undecorated by handling the message Windows uses to ask where
/// the client area goes.
///
/// This is per window rather than per [Win32WindowPlatform], because a platform
/// is made fresh every time the decorations are built while the window and the
/// hook into it last as long as the window does.
class _Win32Frame {
  final ffi.Pointer<ffi.Void> windowHandle;

  _Win32Frame._(this.windowHandle) {
    _frames[windowHandle.address] = this;
    _setWindowSubclass(windowHandle, _subclassProcPointer, 0, 0);
  }

  static final Map<int, _Win32Frame> _frames = <int, _Win32Frame>{};

  static _Win32Frame of(ffi.Pointer<ffi.Void> windowHandle) {
    return _frames[windowHandle.address] ?? _Win32Frame._(windowHandle);
  }

  bool _decorated = true;

  void setDecorated(bool decorated) {
    if (decorated == _decorated) {
      return;
    }
    _decorated = decorated;
    // Where the client area goes is worked out once and remembered, so Windows
    // has to be told to ask again before the change is visible.
    _setWindowPos(
      windowHandle,
      ffi.nullptr,
      0,
      0,
      0,
      0,
      _swpNoMove | _swpNoSize | _swpNoZOrder | _swpNoActivate | _swpFrameChanged,
    );
  }

  /// Returns what to reply to [message] with, or null to let Windows handle it.
  int? handleMessage(int message, int wParam, int lParam) {
    if (message == _wmNcDestroy) {
      _frames.remove(windowHandle.address);
      return null;
    }
    // A wParam of zero asks for a rectangle rather than the full parameters,
    // which is only sent to windows with the CS_VREDRAW style and is not worth
    // adjusting because nothing is drawn from it.
    if (_decorated || message != _wmNcCalcSize || wParam == 0) {
      return null;
    }
    // Let Windows work out where the client area would normally be, so that the
    // sizing border and the insets a maximized window needs are whatever this
    // version of Windows uses, then take back the title bar from the top of it.
    //
    // Leaving the sizing border in the non-client area is what lets Windows go
    // on resizing the window from any edge on its own.
    final int result = _defSubclassProc(windowHandle, message, wParam, lParam);
    // The first rectangle of NCCALCSIZE_PARAMS is the proposed client area, and
    // is the first field of the struct, so the parameters can be read as a
    // rectangle.
    final clientRect = ffi.Pointer<_Win32Rect>.fromAddress(lParam);
    clientRect.ref.top -= _getSystemMetricsForDpi(
      _smCyCaption,
      _getDpiForWindow(windowHandle),
    );
    return result;
  }
}

/// The window procedure installed in front of the one Flutter uses, so that
/// [_Win32Frame] sees messages first.
int _subclassProc(
  ffi.Pointer<ffi.Void> windowHandle,
  int message,
  int wParam,
  int lParam,
  int idSubclass,
  int refData,
) {
  final int? result = _Win32Frame._frames[windowHandle.address]?.handleMessage(
    message,
    wParam,
    lParam,
  );
  return result ?? _defSubclassProc(windowHandle, message, wParam, lParam);
}

final ffi.Pointer<ffi.NativeFunction<_SubclassProcNative>> _subclassProcPointer =
    ffi.Pointer.fromFunction<_SubclassProcNative>(_subclassProc, 0);

typedef _SubclassProcNative =
    ffi.IntPtr Function(
      ffi.Pointer<ffi.Void>,
      ffi.Uint32,
      ffi.UintPtr,
      ffi.IntPtr,
      ffi.UintPtr,
      ffi.UintPtr,
    );

/// Win32 RECT.
final class _Win32Rect extends ffi.Struct {
  @ffi.Int32()
  external int left;

  @ffi.Int32()
  external int top;

  @ffi.Int32()
  external int right;

  @ffi.Int32()
  external int bottom;
}

const int _wmNcCalcSize = 0x0083;
const int _wmNcDestroy = 0x0082;
const int _wmSysCommand = 0x0112;

/// The height of a title bar, used with GetSystemMetricsForDpi.
const int _smCyCaption = 4;

/// SetWindowPos flags. The frame changed flag makes Windows ask where the
/// client area goes again, the others keep the current position, size, stacking
/// and activation.
const int _swpNoSize = 0x0001;
const int _swpNoMove = 0x0002;
const int _swpNoZOrder = 0x0004;
const int _swpNoActivate = 0x0010;
const int _swpFrameChanged = 0x0020;

/// System commands sent with WM_SYSCOMMAND to start a move or resize.
const int _scSize = 0xF000;
const int _scMove = 0xF010;

/// Hit test result for the title bar, used to tell SC_MOVE the drag started
/// there.
const int _htCaption = 2;

/// The edges an SC_SIZE command can resize from.
const Map<WindowEdge, int> _wmszEdges = <WindowEdge, int>{
  WindowEdge.left: 1,
  WindowEdge.right: 2,
  WindowEdge.top: 3,
  WindowEdge.topLeft: 4,
  WindowEdge.topRight: 5,
  WindowEdge.bottom: 6,
  WindowEdge.bottomLeft: 7,
  WindowEdge.bottomRight: 8,
};

/// Subclassing lives in comctl32 rather than user32, which a Flutter app has no
/// reason to have loaded already, so it is opened here.
///
/// This is only looked up when a window is first undecorated, which only
/// happens on Windows.
final ffi.DynamicLibrary _comctl32 = ffi.DynamicLibrary.open('comctl32.dll');

final int Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.NativeFunction<_SubclassProcNative>>,
  int,
  int,
)
_setWindowSubclass = _comctl32
    .lookupFunction<
      ffi.Int32 Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.NativeFunction<_SubclassProcNative>>,
        ffi.UintPtr,
        ffi.UintPtr,
      ),
      int Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.NativeFunction<_SubclassProcNative>>,
        int,
        int,
      )
    >('SetWindowSubclass');

final int Function(ffi.Pointer<ffi.Void>, int, int, int) _defSubclassProc =
    _comctl32
        .lookupFunction<
          ffi.IntPtr Function(ffi.Pointer<ffi.Void>, ffi.Uint32, ffi.UintPtr, ffi.IntPtr),
          int Function(ffi.Pointer<ffi.Void>, int, int, int)
        >('DefSubclassProc');

@ffi.Native<ffi.Bool Function()>(symbol: 'ReleaseCapture')
external bool _releaseCapture();

@ffi.Native<ffi.IntPtr Function(ffi.Pointer<ffi.Void>, ffi.Uint32, ffi.UintPtr, ffi.IntPtr)>(
  symbol: 'SendMessageW',
)
external int _sendMessage(
  ffi.Pointer<ffi.Void> windowHandle,
  int message,
  int wParam,
  int lParam,
);

@ffi.Native<
  ffi.Bool Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Int32,
    ffi.Int32,
    ffi.Int32,
    ffi.Int32,
    ffi.Uint32,
  )
>(symbol: 'SetWindowPos')
external bool _setWindowPos(
  ffi.Pointer<ffi.Void> windowHandle,
  ffi.Pointer<ffi.Void> windowHandleInsertAfter,
  int x,
  int y,
  int width,
  int height,
  int flags,
);

@ffi.Native<ffi.Uint32 Function(ffi.Pointer<ffi.Void>)>(symbol: 'GetDpiForWindow')
external int _getDpiForWindow(ffi.Pointer<ffi.Void> windowHandle);

@ffi.Native<ffi.Int32 Function(ffi.Int32, ffi.Uint32)>(symbol: 'GetSystemMetricsForDpi')
external int _getSystemMetricsForDpi(int index, int dpi);
