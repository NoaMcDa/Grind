import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/companion/celebration_bus.dart';
import 'package:grind/features/companion/praise.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/widgets/celebration/confetti_overlay.dart';
import 'package:grind/widgets/celebration/pip_bounce.dart';
import 'package:grind/widgets/pip_avatar.dart';

import '../../test_fonts.dart';

final _now = DateTime(2026, 11, 3, 12);

Task _done(String id) => Task(
  id: id,
  title: id,
  status: TaskStatus.done,
  completedAt: _now,
  createdAt: _now,
  updatedAt: _now,
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool reduce = false,
  List<Task> tasks = const [],
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_now)),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: CelebrationHost(child: child!),
        ),
        home: const Scaffold(body: Center(child: Text('app body'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Lets the toast time out (its timer does not schedule frames, so
/// pumpAndSettle alone would return early).
Future<void> _dismiss(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

void emit(ProviderContainer c, CelebrationEvent e) =>
    c.read(celebrationBusProvider).emit(e);

void main() {
  setUpAll(loadAppFonts);

  test('bus delivers events to every listener', () async {
    final bus = CelebrationBus();
    final a = <CelebrationEvent>[];
    final b = <CelebrationEvent>[];
    bus.stream.listen(a.add);
    bus.stream.listen(b.add);
    bus.emit(const CelebrationEvent.taskCompleted());
    bus.emit(const CelebrationEvent.goalCompleted());
    await Future<void>.delayed(Duration.zero);
    expect(a, hasLength(2));
    expect(b, hasLength(2));
    expect(a.first, isA<TaskCompleted>());
    expect(a.last, isA<GoalCompleted>());
    bus.dispose();
  });

  test('intensity: full session and goals are big', () {
    expect(
      intensityOf(const CelebrationEvent.focusSessionFinished()),
      PraiseIntensity.big,
    );
    expect(
      intensityOf(const CelebrationEvent.focusSessionFinished(full: false)),
      PraiseIntensity.light,
    );
    expect(
      intensityOf(const CelebrationEvent.goalCompleted()),
      PraiseIntensity.big,
    );
    expect(
      intensityOf(const CelebrationEvent.taskCompleted()),
      PraiseIntensity.light,
    );
  });

  test('variety rotates colours and swaps shapes every 5th burst', () {
    final v = CelebrationVariety();
    final styles = [for (var i = 0; i < 6; i++) v.next(PraiseIntensity.light)];
    expect(styles[0].colors.first, isNot(styles[1].colors.first));
    expect(
      [for (final s in styles) s.shapes],
      [
        ConfettiShapes.classic,
        ConfettiShapes.classic,
        ConfettiShapes.classic,
        ConfettiShapes.classic,
        ConfettiShapes.ribbons,
        ConfettiShapes.classic,
      ],
    );
  });

  testWidgets('host shows a toast and confetti, never blocking input', (
    tester,
  ) async {
    final c = await _pump(tester);
    emit(c, const CelebrationEvent.taskCompleted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ConfettiOverlay), findsOneWidget);
    expect(find.byType(PipBounce), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('app body').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(ConfettiOverlay), findsNothing);
    await _dismiss(tester);
  });

  testWidgets('finished focus session adds the Pip bounce', (tester) async {
    final c = await _pump(tester);
    emit(c, const CelebrationEvent.focusSessionFinished());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PipBounce), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(PipBounce), findsNothing);
    await _dismiss(tester);
  });

  testWidgets('reduced motion: toast only, no confetti or bounce', (
    tester,
  ) async {
    final c = await _pump(tester, reduce: true);
    emit(c, const CelebrationEvent.focusSessionFinished());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ConfettiOverlay), findsNothing);
    expect(find.byType(PipBounce), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    await _dismiss(tester);
  });

  testWidgets('praise never repeats back to back', (tester) async {
    final c = await _pump(tester, reduce: true);
    String? last;
    for (var i = 0; i < 6; i++) {
      emit(c, const CelebrationEvent.taskCompleted());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final text = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Text),
            ),
          )
          .first
          .data;
      expect(text, isNot(last));
      last = text;
      await _dismiss(tester);
    }
    await _dismiss(tester);
  });

  testWidgets('existing unlocks are silent; a new one fires once', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      tasks: [for (var i = 0; i < 24; i++) _done('t$i')],
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SnackBar), findsNothing);

    await c.read(taskRepositoryProvider).upsert(_done('t25'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('New for Pip: Party hat. Tap Pip\'s wardrobe to wear it.'),
      findsOneWidget,
    );

    await _dismiss(tester);
    await c.read(taskRepositoryProvider).upsert(_done('t26'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('New for Pip'), findsNothing);
    await _dismiss(tester);
  });

  testWidgets('Hebrew host: praise shows, no overflow', (tester) async {
    final c = await _pump(tester, locale: const Locale('he'));
    emit(c, const CelebrationEvent.goalCompleted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsOneWidget);
    await _dismiss(tester);
  });

  testWidgets('avatar renders every accessory', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final a in PipAccessory.values)
              PipAvatar(size: 80, accessory: a),
          ],
        ),
      ),
    );
    expect(find.byType(PipAvatar), findsNWidgets(PipAccessory.values.length));
    expect(tester.takeException(), isNull);
  });
}
