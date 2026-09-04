import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_csd_test/src/window_decorations/resize_handles.dart';
import 'package:flutter_csd_test/window_decorations.dart';

void main() {
  test(
    'shadow extents match the invisible border GTK3 leaves around a window',
    () {
      expect(
        const GtkWindowDecorationStyle().shadowExtents,
        const EdgeInsets.fromLTRB(26, 23, 26, 29),
      );
    },
  );
  test('shadow extents shrink to leave room for a very small window', () {
    // A window is laid out at a minimal size before it is first shown, and a
    // window that draws nothing there never gets shown at all.
    const EdgeInsets extents = EdgeInsets.fromLTRB(26, 23, 26, 29);
    expect(
      WindowDecorationStyle.fitInsets(extents, const Size(400, 400)),
      extents,
    );
    final EdgeInsets fitted = WindowDecorationStyle.fitInsets(
      extents,
      const Size(10, 10),
    );
    expect(fitted.horizontal, lessThan(10));
    expect(fitted.vertical, lessThan(10));
    expect(fitted.left, fitted.right);
    expect(fitted.top / fitted.bottom, closeTo(23 / 29, 0.001));
  });
  test('blur radius converts to a GTK sigma', () {
    const GtkShadow shadow = GtkShadow(color: Color(0xFF000000), blurRadius: 9);
    expect(shadow.toBoxShadow().blurSigma, closeTo(9, 0.001));
  });
  test('every style leaves room for its own shadows and resize border', () {
    for (final WindowDecorationStyle style in <WindowDecorationStyle>[
      const GtkWindowDecorationStyle(),
      const FluentWindowDecorationStyle(),
      const AquaWindowDecorationStyle(),
    ]) {
      final EdgeInsets extents = style.shadowExtents;
      for (final double inset in <double>[
        extents.left,
        extents.right,
        extents.top,
        extents.bottom,
      ]) {
        expect(
          inset,
          greaterThanOrEqualTo(style.resizeBorder),
          reason: '$style has nowhere to put its resize handles',
        );
      }
    }
  });

  group('resize handles', () {
    // A 400x400 window drawn in the GTK style, so the window itself is the
    // rectangle from 26,23 to 374,371 with 15 pixel rounded corners.
    const GtkWindowDecorationStyle style = GtkWindowDecorationStyle();
    WindowEdge? edgeAt(double x, double y) => WindowResizeHandles.edgeAt(
      Offset(x, y),
      const Size(400, 400),
      shadowExtents: style.shadowExtents,
      resizeBorder: style.resizeBorder,
      cornerRadius: style.cornerRadius(isMaximized: false),
    );

    test('run along each side of the window', () {
      expect(edgeAt(20, 200), WindowEdge.left);
      expect(edgeAt(380, 200), WindowEdge.right);
      expect(edgeAt(200, 15), WindowEdge.top);
      expect(edgeAt(200, 375), WindowEdge.bottom);
    });

    test('take over the ends of those sides for the corners', () {
      expect(edgeAt(20, 30), WindowEdge.topLeft);
      expect(edgeAt(46, 15), WindowEdge.topLeft);
      expect(edgeAt(380, 365), WindowEdge.bottomRight);
    });

    test('cover the piece a rounded corner cuts out of the window', () {
      // Just inside the window, but outside the rounded corner.
      expect(edgeAt(30, 26), WindowEdge.topLeft);
      expect(edgeAt(370, 367), WindowEdge.bottomRight);
    });

    test('leave the window itself alone', () {
      expect(edgeAt(200, 200), isNull);
      // Inside the rounded corner, i.e. on the window.
      expect(edgeAt(45, 45), isNull);
      // Out past the resize border, in the shadow.
      expect(edgeAt(5, 200), isNull);
    });
  });

  testWidgets('resize handles let the window have everything else', (
    WidgetTester tester,
  ) async {
    const GtkWindowDecorationStyle style = GtkWindowDecorationStyle();
    final List<WindowEdge> resized = <WindowEdge>[];
    int taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: WindowResizeHandles(
              shadowExtents: style.shadowExtents,
              resizeBorder: style.resizeBorder,
              cornerRadius: style.cornerRadius(isMaximized: false),
              onResize: (WindowEdge edge, int button) => resized.add(edge),
              // The window itself, which fills the whole area the handles are
              // laid out in.
              child: SizedBox.expand(
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(color: Color(0xFF000000)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The middle of the window belongs to the window.
    await tester.tapAt(tester.getCenter(find.byType(WindowResizeHandles)));
    expect(taps, 1);
    expect(resized, isEmpty);

    // The border around it, and the pieces the rounded corners cut out of it,
    // start a resize instead.
    final Offset origin = tester.getTopLeft(find.byType(WindowResizeHandles));
    await tester.tapAt(origin + const Offset(20, 200));
    await tester.tapAt(origin + const Offset(30, 26));
    expect(taps, 1);
    expect(resized, <WindowEdge>[WindowEdge.left, WindowEdge.topLeft]);
  });
}
