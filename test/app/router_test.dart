import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/test_app.dart';
import 'package:grind/core/core.dart';

import '../test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  const tabs = {
    '/today': 'Good morning!',
    '/plan': 'Your day, drafted',
    '/focus': 'FOCUS 2 OF 4',
    '/pip': null,
    '/ask': 'Ask Pip',
  };

  for (final entry in tabs.entries) {
    testWidgets('router shows ${entry.key}', (tester) async {
      await pumpGrindApp(tester, initialLocation: entry.key);
      if (entry.value != null) {
        expect(find.text(entry.value!), findsOneWidget);
      }
      for (final label in ['Today', 'Plan', 'Focus', 'Pip', 'Ask']) {
        expect(find.text(label), findsWidgets);
      }
    });
  }

  testWidgets('tapping tabs navigates', (tester) async {
    await pumpGrindApp(tester);
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your day, drafted'), findsOneWidget);
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Pip'), findsOneWidget);
  });

  testWidgets('/focus?taskId= opens the Focus tab', (tester) async {
    await pumpGrindApp(tester, initialLocation: '/focus?taskId=lab');
    expect(find.text('FOCUS 2 OF 4'), findsOneWidget);
  });

  testWidgets('deep link /task/abc opens the placeholder', (tester) async {
    await pumpGrindApp(tester, initialLocation: '/task/abc');
    expect(find.text('abc'), findsOneWidget);
    expect(find.text('Task details are coming soon.'), findsOneWidget);
  });

  testWidgets('Today add button goes to Ask', (tester) async {
    await pumpGrindApp(tester);
    await tester.tap(find.bySemanticsLabel('Add a task'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Pip'), findsOneWidget);
  });

  testWidgets('Today toggling a task updates the repository', (tester) async {
    final container = await pumpGrindApp(tester);
    final repo = container.read(taskRepositoryProvider);

    expect(find.text('1 of 5 today'), findsOneWidget);
    expect((await repo.getById('gym'))!.status, TaskStatus.open);

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();

    expect((await repo.getById('gym'))!.status, TaskStatus.done);
    expect(find.text('2 of 5 today'), findsOneWidget);

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect((await repo.getById('gym'))!.status, TaskStatus.open);
  });

  testWidgets('Plan reads tasks and events from the repositories', (
    tester,
  ) async {
    await pumpGrindApp(tester, initialLocation: '/plan');
    expect(find.text('Lecture: Computer Vision'), findsOneWidget);
    expect(find.text('Thesis: write related-work section'), findsOneWidget);
    expect(find.text('2 of 5 done'), findsOneWidget);
  });
}
