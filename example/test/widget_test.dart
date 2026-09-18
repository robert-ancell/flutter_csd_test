import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_csd_test/window_decorations.dart';
import 'package:flutter_csd_test_example/main.dart';

void main() {
  testWidgets('the selector offers every decoration and reports a choice', (
    WidgetTester tester,
  ) async {
    WindowDecoration? chosen;
    await tester.pumpWidget(
      MyApp(
        decoration: WindowDecoration.automatic,
        onChanged: (WindowDecoration decoration) => chosen = decoration,
      ),
    );

    for (final WindowDecoration decoration in WindowDecoration.values) {
      expect(find.text(decoration.label), findsOneWidget);
    }

    await tester.tap(find.text(WindowDecoration.fluent.label));
    await tester.pump();
    expect(chosen, WindowDecoration.fluent);
  });

  testWidgets('the window can be dragged by a part of the app itself', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        decoration: WindowDecoration.automatic,
        onChanged: (WindowDecoration decoration) {},
      ),
    );

    // The app is pumped with no window around it, so a move area that asked
    // for one as it was built would not have got this far.
    expect(
      find.ancestor(
        of: find.text('Drag here to move the window'),
        matching: find.byType(WindowMoveArea),
      ),
      findsOneWidget,
    );
  });

  test('only the native decorations are left to the window system', () {
    // The automatic style has to know what desktop it is being drawn on.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final WindowDecoration decoration in WindowDecoration.values) {
      expect(
        decoration.style,
        decoration == WindowDecoration.native ? isNull : isNotNull,
        reason: '$decoration disagrees about who draws it',
      );
    }
  });
}
