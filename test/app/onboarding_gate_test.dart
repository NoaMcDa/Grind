import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';

import '../test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a new user is sent to /onboarding first', (tester) async {
    await pumpGrindApp(
      tester,
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          InMemoryPreferencesRepository(const Preferences()),
        ),
      ],
    );
    expect(find.text('Good morning!'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.textContaining('Start'), findsWidgets);
  });

  testWidgets('an onboarded user lands on Today', (tester) async {
    await pumpGrindApp(tester);
    expect(find.text('Good morning!'), findsOneWidget);
  });

  testWidgets('/goals and /review routes open their screens', (tester) async {
    await pumpGrindApp(tester, initialLocation: '/goals');
    expect(find.text('Good morning!'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
    await pumpGrindApp(tester, initialLocation: '/review');
    expect(find.text('Good morning!'), findsNothing);
  });

  testWidgets('Today has Goals and Settings entry points', (tester) async {
    await pumpGrindApp(tester);
    expect(find.byKey(const Key('today-goals')), findsOneWidget);
    expect(find.byKey(const Key('today-settings')), findsOneWidget);
  });

  testWidgets('/settings opens the settings screen', (tester) async {
    await pumpGrindApp(tester, initialLocation: '/settings');
    expect(find.text('Good morning!'), findsNothing);
    expect(find.textContaining('Settings'), findsWidgets);
  });
}
