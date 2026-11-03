import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/review/review.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

Task _task(String id, DateTime remind, {DateTime? due}) {
  final t = DateTime(2026, 11, 3).toUtc();
  return Task(
    id: id,
    title: 'Task $id',
    remindAt: remind.toUtc(),
    dueAt: due?.toUtc(),
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  setUpAll(loadAppFonts);

  final now = DateTime(2026, 11, 3, 21);

  Future<({InMemoryTaskRepository tasks, InMemoryReviewRepository reviews})>
  pump(
    WidgetTester tester,
    List<Task> seed, {
    TextDirection dir = TextDirection.ltr,
    Locale locale = const Locale('en'),
    VoidCallback? onFinished,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final tasks = InMemoryTaskRepository(seed);
    final reviews = InMemoryReviewRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          taskRepositoryProvider.overrideWithValue(tasks),
          reviewRepositoryProvider.overrideWithValue(reviews),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: Directionality(
            textDirection: dir,
            child: EveningReviewFlow(onFinished: onFinished ?? () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (tasks: tasks, reviews: reviews);
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Key primary(String label) => ValueKey('review-primary-$label');

  final seed = [
    _task('a', DateTime(2026, 11, 3, 9)),
    _task('b', DateTime(2026, 11, 3, 15)),
    _task('c', DateTime(2026, 11, 3, 18), due: DateTime(2026, 11, 3, 23, 59)),
  ];

  testWidgets('done, move, drop and win are saved', (tester) async {
    final env = await pump(tester, seed);
    await tap(tester, const ValueKey('review-done-a'));
    await tap(tester, primary('Continue'));
    // a is done; b moves tomorrow; c is due today so it offers keep/anyway.
    expect(find.text('Task a'), findsNothing);
    expect(find.byKey(const ValueKey('review-opt-b-laterThisWeek')), findsOne);
    expect(find.byKey(const ValueKey('review-opt-c-tomorrow')), findsNothing);
    await tap(tester, const ValueKey('review-opt-b-tomorrow'));
    await tap(tester, const ValueKey('review-opt-c-drop'));
    await tap(tester, const ValueKey('review-undo-c'));
    await tap(tester, const ValueKey('review-opt-c-drop'));
    await tap(tester, primary('Continue'));
    await tester.enterText(
      find.byKey(const ValueKey('review-win-field')),
      'Finished the draft',
    );
    await tap(tester, primary('Save and finish'));

    expect(find.byKey(const ValueKey('review-praise')), findsOneWidget);
    final all = await env.tasks.getAll();
    expect(all.map((t) => t.id), ['a', 'b']);
    expect(all.first.status, TaskStatus.done);
    expect(all.last.remindAt!.toLocal(), DateTime(2026, 11, 4, 15));
    final entries = await env.reviews.all();
    expect(entries.single.win, 'Finished the draft');
    expect(entries.single.doneCount, 1);
    expect(entries.single.movedCount, 2);
  });

  testWidgets('skipping every step records nothing and is handled', (
    tester,
  ) async {
    var finished = false;
    final env = await pump(tester, seed, onFinished: () => finished = true);
    for (var i = 0; i < 3; i++) {
      await tap(tester, const ValueKey('review-skip'));
    }
    expect(find.byKey(const ValueKey('review-praise')), findsOneWidget);
    await tap(tester, primary('Done'));
    expect(finished, isTrue);
    expect(await env.reviews.all(), isEmpty);
    expect(await env.reviews.isHandled('2026-11-03'), isTrue);
    final all = await env.tasks.getAll();
    expect(all.every((t) => t.status == TaskStatus.open), isTrue);
    expect(all.first.remindAt!.toLocal(), DateTime(2026, 11, 3, 9));
  });

  testWidgets('tomorrow anyway on a deadline task moves the deadline', (
    tester,
  ) async {
    final env = await pump(tester, seed);
    await tap(tester, primary('Continue'));
    await tap(tester, const ValueKey('review-opt-c-tomorrowAnyway'));
    await tap(tester, primary('Continue'));
    final c = await env.tasks.getById('c');
    expect(c!.dueAt!.toLocal(), DateTime(2026, 11, 4, 23, 59));
  });

  testWidgets('lays out in RTL at 390x844', (tester) async {
    final he = lookupAppLocalizations(const Locale('he'));
    await pump(
      tester,
      seed,
      dir: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(find.text(he.reviewDoneTitle), findsOneWidget);
    expect(find.text('What got done?'), findsNothing);
    expect(tester.takeException(), isNull);
    await tap(tester, primary(he.onboardingContinue));
    expect(tester.takeException(), isNull);
  });
}
