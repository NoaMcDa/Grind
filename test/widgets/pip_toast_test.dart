import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/tab_bar.dart';
import 'package:grind/widgets/pip_toast.dart';

import '../test_fonts.dart';

/// Pumps a shell with a tab bar at the bottom and a button that, when
/// tapped, shows a Pip toast with an Undo action (the same shape used by
/// `TaskActions.toggle`).
Future<void> _pumpShellWithTabBar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showPipToast(
                      context,
                      'Nicely done',
                      actionLabel: 'Undo',
                      onAction: () {},
                    ),
                    child: const Text('cheer'),
                  ),
                ),
              ),
            ),
            GrindTabBar(current: AppTab.today, onSelect: (_) {}),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('toast auto-dismisses after its duration, even with Undo', (
    tester,
  ) async {
    await _pumpShellWithTabBar(tester);
    await tester.tap(find.text('cheer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Nicely done'), findsOneWidget);

    // Past the default 4 s duration: the snackbar must close itself.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Nicely done'), findsNothing);
  });

  testWidgets('tab bar is still hittable while the toast is visible', (
    tester,
  ) async {
    await _pumpShellWithTabBar(tester);
    await tester.tap(find.text('cheer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);

    // Each tab label on the bar must be hit-testable (not covered by the
    // toast).
    for (final label in ['Today', 'Plan', 'Focus', 'Pip', 'Ask']) {
      final finder = find.descendant(
        of: find.byType(GrindTabBar),
        matching: find.text(label),
      );
      expect(finder.hitTestable(), findsOneWidget, reason: '$label hittable');
    }

    // And the toast's own top must sit above the tab bar's top.
    final snackRect = tester.getRect(find.byType(SnackBar));
    final tabRect = tester.getRect(find.byType(GrindTabBar));
    expect(
      snackRect.bottom,
      lessThanOrEqualTo(tabRect.top),
      reason: 'toast must not overlap the tab bar',
    );

    // Let the duration run out so the test tears down cleanly.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  });

  testWidgets('a second toast replaces the first one instead of queuing', (
    tester,
  ) async {
    await _pumpShellWithTabBar(tester);
    await tester.tap(find.text('cheer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Nicely done'), findsOneWidget);

    // Showing another toast while the first is still on screen should
    // clear it, not queue behind it.
    await tester.tap(find.text('cheer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
