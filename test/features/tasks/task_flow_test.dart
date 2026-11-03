import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';

import '../../test_fonts.dart';

List<Override> get _hebrew => [
  preferencesRepositoryProvider.overrideWithValue(
    InMemoryPreferencesRepository(
      const Preferences(onboardingDone: true, localeCode: 'he'),
    ),
  ),
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('creating a task from the sheet adds it to Up next', (
    tester,
  ) async {
    final container = await pumpGrindApp(tester);
    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Write abstract');
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsNothing);
    expect(find.text('Write abstract'), findsOneWidget);
    expect(find.text('1 of 5 today'), findsOneWidget);
    final all = await container.read(taskRepositoryProvider).getAll();
    final saved = all.firstWhere((t) => t.title == 'Write abstract');
    expect(saved.estimatedMinutes, 30);
    expect(saved.energy, Energy.light);
    expect(saved.dueAt, isNotNull);
    expect(saved.dueAt!.isUtc, isTrue);
  });

  testWidgets('Enter saves, empty title shows an error, Esc closes', (
    tester,
  ) async {
    await pumpGrindApp(tester);
    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Give it a short name and you are set.'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Email Dana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Email Dana'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsNothing);
  });

  testWidgets('reminder follows the due time; estimate and energy save', (
    tester,
  ) async {
    final container = await pumpGrindApp(tester);
    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Pack bag');
    await tester.tap(find.bySemanticsLabel('Add a time').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('60 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 min'));
    await tester.ensureVisible(find.text('Deep focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deep focus'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    final all = await container.read(taskRepositoryProvider).getAll();
    final t = all.firstWhere((t) => t.title == 'Pack bag');
    expect(t.remindAt, isNotNull);
    expect(t.remindAt, t.dueAt);
    expect(t.estimatedMinutes, 60);
    expect(t.energy, Energy.deep);
  });

  testWidgets('detail screen edits, completes, and deletes with undo', (
    tester,
  ) async {
    final container = await pumpGrindApp(tester);
    final repo = container.read(taskRepositoryProvider);

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(find.text('If it is 17:00, then pack your bag'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Gym session');
    await tester.ensureVisible(find.text('45 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 min'));
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    final edited = (await repo.getById('gym'))!;
    expect(edited.title, 'Gym session');
    expect(edited.estimatedMinutes, 45);
    expect(find.text('Gym session'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Complete'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.isDone, isTrue);

    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Delete').last);
    await tester.pumpAndSettle();
    expect(await repo.getById('gym'), isNull);
    expect(find.text('Task deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await repo.getById('gym'), isNotNull);
    expect(find.text('Gym session'), findsOneWidget);
  });

  testWidgets('RTL sheet at 390x844 has no overflow', (tester) async {
    await pumpGrindApp(tester, overrides: _hebrew);
    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
