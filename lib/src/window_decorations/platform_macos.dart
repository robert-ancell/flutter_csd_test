import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:flutter/src/widgets/_window_macos.dart';

import 'style.dart';
import 'window_platform.dart';

/// The things the window decoration widgets need from macOS.
///
/// None of this is in the windowing API yet, so it is all done here by sending
/// messages to the NSWindow behind the window controller. Once the API covers
/// it this can be replaced by calls to the controller.
class MacOSWindowPlatform extends WindowPlatform {
  final BaseWindowControllerMacOS controller;

  const MacOSWindowPlatform(this.controller);

  /// macOS keeps every part of the frame and hands over only the strip the
  /// title bar sits in, by letting the content view fill the whole frame. The
  /// shadow, rounded corners and resize edges still belong to the window
  /// server, so the window can still be resized, zoomed and dragged between
  /// spaces without the app doing anything.
  @override
  bool get drawsFrame => true;

  @override
  void setDecorated(bool decorated) {
    final ffi.Pointer<ffi.Void> window = controller.windowHandle;
    final int styleMask = _objcGetUnsignedLong(window, _sel('styleMask'));
    if (styleMask & _nsWindowStyleMaskTitled == 0) {
      // A window that never had a title bar, e.g. a popup, has nothing to show
      // or hide.
      return;
    }

    // Letting the content view fill the frame is what puts Flutter behind the
    // title bar. The title bar itself stays, so that the window keeps behaving
    // like a normal one, and is made invisible instead.
    _objcSendUnsignedLong(
      window,
      _sel('setStyleMask:'),
      decorated
          ? styleMask & ~_nsWindowStyleMaskFullSizeContentView
          : styleMask | _nsWindowStyleMaskFullSizeContentView,
    );
    _objcSendBool(window, _sel('setTitlebarAppearsTransparent:'), !decorated);
    _objcSendLong(
      window,
      _sel('setTitleVisibility:'),
      decorated ? _nsWindowTitleVisible : _nsWindowTitleHidden,
    );

    // The app draws its own close, minimize and zoom buttons, so the real ones
    // would sit on top of them.
    for (final int button in _standardWindowButtons) {
      final ffi.Pointer<ffi.Void> handle = _objcGetIdWithLong(
        window,
        _sel('standardWindowButton:'),
        button,
      );
      if (handle != ffi.nullptr) {
        _objcSendBool(handle, _sel('setHidden:'), !decorated);
      }
    }
  }

  @override
  void beginMove() {
    // The event being handled is the press that started the drag, which is what
    // macOS wants to track the pointer from.
    final ffi.Pointer<ffi.Void> event = _objcGetId(
      _nsApp,
      _sel('currentEvent'),
    );
    if (event == ffi.nullptr) {
      return;
    }
    _objcSendId(
      controller.windowHandle,
      _sel('performWindowDragWithEvent:'),
      event,
    );
  }

  @override
  void beginResize(WindowEdge edge) {
    // Never reached: the resize handles are only drawn where the app owns the
    // frame, and on macOS the window server keeps it. There is no equivalent of
    // performWindowDragWithEvent: for resizing, so there is nothing to call.
    throw UnsupportedError('macOS resizes its own windows');
  }
}

/// Whether a window has a title bar at all.
const int _nsWindowStyleMaskTitled = 1 << 0;

/// Lets the content view of a window fill the whole frame, rather than stopping
/// below the title bar.
const int _nsWindowStyleMaskFullSizeContentView = 1 << 15;

const int _nsWindowTitleVisible = 0;
const int _nsWindowTitleHidden = 1;

/// NSWindowCloseButton, NSWindowMiniaturizeButton and NSWindowZoomButton.
const List<int> _standardWindowButtons = <int>[0, 1, 2];

ffi.Pointer<ffi.Void> get _nsApp => _objcGetId(
  _objcGetClass(_cString('NSApplication')),
  _sel('sharedApplication'),
);

final Map<String, ffi.Pointer<ffi.Void>> _selectors =
    <String, ffi.Pointer<ffi.Void>>{};

/// Looks up the selector named [name], registering it the first time.
ffi.Pointer<ffi.Void> _sel(String name) {
  return _selectors.putIfAbsent(name, () => _selRegisterName(_cString(name)));
}

final Map<String, ffi.Pointer<ffi.Char>> _cStrings =
    <String, ffi.Pointer<ffi.Char>>{};

/// Copies [value] into memory the Objective-C runtime can read.
///
/// Every string here names a class or a selector, so there is a fixed number of
/// them and they are kept rather than freed.
ffi.Pointer<ffi.Char> _cString(String value) {
  return _cStrings.putIfAbsent(value, () {
    final List<int> bytes = utf8.encode(value);
    final ffi.Pointer<ffi.Uint8> result = _malloc(
      bytes.length + 1,
    ).cast<ffi.Uint8>();
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i];
    }
    result[bytes.length] = 0;
    return result.cast<ffi.Char>();
  });
}

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.UintPtr)>(symbol: 'malloc')
external ffi.Pointer<ffi.Void> _malloc(int size);

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>)>(
  symbol: 'objc_getClass',
)
external ffi.Pointer<ffi.Void> _objcGetClass(ffi.Pointer<ffi.Char> name);

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>)>(
  symbol: 'sel_registerName',
)
external ffi.Pointer<ffi.Void> _selRegisterName(ffi.Pointer<ffi.Char> name);

// objc_msgSend has to be called through a pointer typed for the exact message
// being sent, because it is not a normal variadic function: on arm64 it passes
// arguments the way the method it dispatches to expects them. There is one of
// these for each shape of message sent above.

final ffi.DynamicLibrary _process = ffi.DynamicLibrary.process();

final ffi.Pointer<ffi.Void> Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Void>,
)
_objcGetId = _process
    .lookupFunction<
      ffi.Pointer<ffi.Void> Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
      ),
      ffi.Pointer<ffi.Void> Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
      )
    >('objc_msgSend');

final int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
_objcGetUnsignedLong = _process
    .lookupFunction<
      ffi.UnsignedLong Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>),
      int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
    >('objc_msgSend');

final ffi.Pointer<ffi.Void> Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Void>,
  int,
)
_objcGetIdWithLong = _process
    .lookupFunction<
      ffi.Pointer<ffi.Void> Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
        ffi.Long,
      ),
      ffi.Pointer<ffi.Void> Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
        int,
      )
    >('objc_msgSend');

final void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Void>,
)
_objcSendId = _process
    .lookupFunction<
      ffi.Void Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
      ),
      void Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
      )
    >('objc_msgSend');

final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
_objcSendUnsignedLong = _process
    .lookupFunction<
      ffi.Void Function(
        ffi.Pointer<ffi.Void>,
        ffi.Pointer<ffi.Void>,
        ffi.UnsignedLong,
      ),
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
    >('objc_msgSend');

final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
_objcSendLong = _process
    .lookupFunction<
      ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, ffi.Long),
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
    >('objc_msgSend');

/// BOOL is a signed char on every platform macOS runs on, so it is passed as
/// one rather than as a C bool.
final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
_objcSendSignedChar = _process
    .lookupFunction<
      ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, ffi.Int8),
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, int)
    >('objc_msgSend');

void _objcSendBool(
  ffi.Pointer<ffi.Void> target,
  ffi.Pointer<ffi.Void> selector,
  bool value,
) {
  _objcSendSignedChar(target, selector, value ? 1 : 0);
}
