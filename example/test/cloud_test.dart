import 'package:flutter/widgets.dart';
import 'package:flutter_csd_test/window_decorations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_csd_test_example/cloud/cloud_shape.dart';
import 'package:flutter_csd_test_example/cloud/cloud_style.dart';

/// The sizes a cloud has to hold up at: square, wide, tall, and the minimal
/// size a window is laid out at before it is first shown.
const List<Size> _sizes = <Size>[
  Size(600, 600),
  Size(1200, 300),
  Size(300, 1200),
  Size(40, 40),
  Size(1, 1),
  Size.zero,
];

void main() {
  test('a cloud never spills out of the box it is given', () {
    // The puffs bulge out of a core inset by their own radius, so however many
    // of them there are and whatever sizes they come out at, none of them can
    // reach past the edge. If one did it would be cut off square by the edge of
    // the window, which is the one thing a cloud must not have.
    for (final Size size in _sizes) {
      final Rect bounds = CloudShape.path(size).getBounds();
      expect(
        bounds.isEmpty || (Offset.zero & size).contains(bounds.topLeft),
        isTrue,
        reason: 'a $size cloud starts at ${bounds.topLeft}',
      );
      expect(bounds.left, greaterThanOrEqualTo(-0.01), reason: '$size');
      expect(bounds.top, greaterThanOrEqualTo(-0.01), reason: '$size');
      expect(
        bounds.right,
        lessThanOrEqualTo(size.width + 0.01),
        reason: '$size',
      );
      expect(
        bounds.bottom,
        lessThanOrEqualTo(size.height + 0.01),
        reason: '$size',
      );
    }
  });

  test('a cloud fills the middle of the window it is drawn around', () {
    for (final Size size in _sizes) {
      if (size.isEmpty) {
        continue;
      }
      expect(
        CloudShape.path(size).contains(size.center(Offset.zero)),
        isTrue,
        reason: 'a $size cloud has a hole in the middle',
      );
    }
  });

  test('a cloud leaves room for its own shadow and resize border', () {
    const CloudWindowDecorationStyle style = CloudWindowDecorationStyle();
    expect(style.shadowExtents.left, greaterThanOrEqualTo(style.resizeBorder));
    expect(style.shadowExtents.top, greaterThanOrEqualTo(style.resizeBorder));
    expect(style.shadowExtents.right, greaterThanOrEqualTo(style.resizeBorder));
    expect(
      style.shadowExtents.bottom,
      greaterThanOrEqualTo(style.resizeBorder),
    );
  });

  testWidgets('the cloud title bar has a star for each window button', (
    WidgetTester tester,
  ) async {
    int closed = 0;
    int minimized = 0;
    int maximized = 0;
    final WindowDecorationDetails window = WindowDecorationDetails(
      title: 'A Window',
      isActivated: true,
      isMaximized: false,
      canResize: true,
      onClose: () => closed++,
      onMinimize: () => minimized++,
      onToggleMaximize: () => maximized++,
      onResize: (WindowEdge edge) {},
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) =>
              const CloudWindowDecorationStyle().buildTitleBar(context, window),
        ),
      ),
    );

    expect(find.text('A Window'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Minimize'));
    await tester.tap(find.bySemanticsLabel('Maximize'));
    await tester.tap(find.bySemanticsLabel('Close'));
    expect(<int>[minimized, maximized, closed], <int>[1, 1, 1]);
  });
}
