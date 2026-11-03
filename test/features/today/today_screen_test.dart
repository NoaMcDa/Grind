import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';

import '../../test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Up next shows today, done items sink, momentum is real', (
    tester,
  ) async {
    await pumpGrindApp(tester);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('1 of 4 today'), findsOneWidget);
    // Open tasks first by reminder time, the done one last.
    final lab = tester.getTopLeft(find.text('Deep learning lab 4')).dy;
    final gym = tester.getTopLeft(find.text('Gym')).dy;
    final mom = tester.getTopLeft(find.text('Call mom')).dy;
    expect(lab < gym, isTrue);
    expect(gym < mom, isTrue);
  });

  testWidgets('empty state renders when nothing is due', (tester) async {
    final container = await pumpGrindApp(tester);
    final repo = container.read(taskRepositoryProvider);
    for (final t in await repo.getAll()) {
      await repo.delete(t.id);
    }
    await tester.pumpAndSettle();
    expect(find.text('Nothing due today'), findsOneWidget);
    expect(find.text('0 of 0 today'), findsOneWidget);
  });

  testWidgets('swipe right completes, swipe left deletes and undo restores', (
    tester,
  ) async {
    final container = await pumpGrindApp(tester);
    final repo = container.read(taskRepositoryProvider);

    await tester.drag(find.text('Gym'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.status, TaskStatus.done);
    expect(find.text('2 of 4 today'), findsOneWidget);

    await tester.drag(find.text('Deep learning lab 4'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(await repo.getById('lab'), isNull);
    expect(find.text('Deep learning lab 4'), findsNothing);
    expect(find.text('Task deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await repo.getById('lab'), isNotNull);
    expect(find.text('Deep learning lab 4'), findsOneWidget);
  });

  testWidgets('checkbox toggles done and undo reopens', (tester) async {
    final container = await pumpGrindApp(tester);
    final repo = container.read(taskRepositoryProvider);
    await tester.tap(find.bySemanticsLabel('Complete Gym'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.isDone, isTrue);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.isDone, isFalse);
  });

  testWidgets('RTL at 390x844 has no overflow', (tester) async {
    await pumpGrindApp(
      tester,
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          InMemoryPreferencesRepository(
            const Preferences(onboardingDone: true, localeCode: 'he'),
          ),
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
  });
}
