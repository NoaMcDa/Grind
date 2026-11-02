import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/main.dart';

import 'test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shell shows the five tabs and switches between them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const GrindApp());
    await tester.pumpAndSettle();

    expect(find.text('Good morning!'), findsOneWidget);
    for (final tab in ['Today', 'Plan', 'Focus', 'Pip', 'Ask']) {
      expect(find.text(tab), findsWidgets);
    }

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your day, drafted'), findsOneWidget);

    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Pip'), findsOneWidget);
  });

  testWidgets('today: marking the reminder done moves momentum', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const GrindApp());
    await tester.pumpAndSettle();

    expect(find.text('1 of 5 today'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Nice start!'), findsOneWidget);
    expect(find.text('2 of 5 today'), findsOneWidget);
  });
}
