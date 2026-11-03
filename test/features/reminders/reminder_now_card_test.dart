import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';
import 'package:grind/features/reminders/reminder_now_card.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

final _epoch = DateTime.utc(2026, 1, 1);

// 07:05 in Asia/Jerusalem; the thesis reminder fired at 07:00.
final _now = DateTime.utc(2026, 11, 3, 5, 5);

Task _thesis({int snoozes = 0, DateTime? remindAt}) => Task(
  id: 'thesis',
  title: 'Thesis',
  firstAction: 'open the thesis file',
  remindAt: remindAt ?? DateTime.utc(2026, 11, 3, 5),
  snoozeCount: snoozes,
  createdAt: _epoch,
  updatedAt: _epoch,
);

const _prefs = Preferences(timeZoneName: 'Asia/Jerusalem');

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  late InMemoryTaskRepository repo;
  late FakeNotificationService notifications;
  final focus = <String>[];
  final picked = <String>[];

  Future<void> pump(
    WidgetTester tester,
    List<Task> tasks, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    repo = InMemoryTaskRepository(tasks);
    notifications = FakeNotificationService();
    focus.clear();
    picked.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(_now)),
          taskRepositoryProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(notifications),
          preferencesRepositoryProvider.overrideWithValue(
            InMemoryPreferencesRepository(_prefs),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: ReminderNowCard(
                onStartFocus: focus.add,
                onPickTime: picked.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('open: the if-then copy and the three actions', (tester) async {
    await pump(tester, [_thesis()]);
    expect(find.text('REMINDER · NOW'), findsOneWidget);
    expect(find.text('07:00 — open the thesis file.'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Snooze 15'), findsOneWidget);
    await tester.tap(find.text('Start focus'));
    expect(focus, ['thesis']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Done: task done, pending cancelled, "Nice start!"', (
    tester,
  ) async {
    await pump(tester, [_thesis()]);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final t = (await repo.getById('thesis'))!;
    expect(t.isDone, isTrue);
    expect(t.completedAt, _now);
    expect(notifications.cancelledTaskIds, ['thesis']);
    expect(find.text('Nice start!'), findsOneWidget);
  });

  testWidgets('Snooze -> "See you at 07:20", Undo goes back', (tester) async {
    await pump(tester, [_thesis()]);
    await tester.tap(find.text('Snooze 15'));
    await tester.pumpAndSettle();
    final t = (await repo.getById('thesis'))!;
    expect(t.snoozeCount, 1);
    expect(find.text('See you at 07:20'), findsOneWidget);
    expect(
      find.text('Need a bit more time? Pip can offer to move it instead.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await repo.getById('thesis'))!.snoozeCount, 0);
    expect(find.text('07:00 — open the thesis file.'), findsOneWidget);
  });

  testWidgets('after the 2nd snooze: Tonight / Tomorrow / Pick a time', (
    tester,
  ) async {
    await pump(tester, [
      _thesis(snoozes: 2, remindAt: _now.add(const Duration(minutes: 15))),
    ]);
    expect(find.text('Want to move this instead?'), findsOneWidget);
    expect(find.textContaining('Thesis'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    await tester.tap(find.text('Pick a time'));
    expect(picked, ['thesis']);

    await tester.tap(find.text('Tonight'));
    await tester.pumpAndSettle();
    final t = (await repo.getById('thesis'))!;
    expect(t.remindAt, DateTime.utc(2026, 11, 3, 18)); // 20:00 local
    expect(t.snoozeCount, 0);
    // 20:00 is outside the ±2 h window: the card steps aside.
    expect(find.text('Want to move this instead?'), findsNothing);
  });

  testWidgets('Tomorrow keeps the time of day', (tester) async {
    await pump(tester, [
      _thesis(snoozes: 3, remindAt: _now.add(const Duration(minutes: 15))),
    ]);
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    final t = (await repo.getById('thesis'))!;
    expect(t.remindAt, DateTime.utc(2026, 11, 4, 5, 20));
    expect(t.snoozeCount, 0);
  });

  testWidgets('Hebrew strings and copy, right to left', (tester) async {
    await pump(tester, [
      _thesis().copyWith(firstAction: 'לפתוח את קובץ התזה'),
    ], locale: const Locale('he'));
    expect(find.text('07:00 — לפתוח את קובץ התזה.'), findsOneWidget);
    expect(find.text('בוצע'), findsOneWidget);
    expect(find.text('תזכורת · עכשיו'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing near: renders nothing', (tester) async {
    await pump(tester, [_thesis(remindAt: _now.add(const Duration(hours: 5)))]);
    expect(find.byType(ReminderNowCard), findsOneWidget);
    expect(find.text('REMINDER · NOW'), findsNothing);
  });

  group('pickCurrentReminder', () {
    Task t(String id, DateTime at, {int snoozes = 0, DateTime? updated}) =>
        Task(
          id: id,
          title: id,
          remindAt: at,
          snoozeCount: snoozes,
          createdAt: _epoch,
          updatedAt: updated ?? _epoch,
        );

    test('the most recently fired wins over an older one', () {
      final c = pickCurrentReminder(
        [
          t('old', _now.subtract(const Duration(hours: 1))),
          t('recent', _now.subtract(const Duration(minutes: 2))),
          t('soon', _now.add(const Duration(minutes: 30))),
        ],
        _prefs,
        _now,
      );
      expect(c!.task.id, 'recent');
      expect(c.state, ReminderCardState.open);
    });

    test('an upcoming one when nothing fired', () {
      final c = pickCurrentReminder(
        [
          t('later', _now.add(const Duration(minutes: 90))),
          t('soon', _now.add(const Duration(minutes: 30))),
          t('far', _now.add(const Duration(hours: 3))),
        ],
        _prefs,
        _now,
      );
      expect(c!.task.id, 'soon');
    });

    test('a fresh snooze beats an older fired reminder', () {
      final c = pickCurrentReminder(
        [
          t('fired', _now.subtract(const Duration(minutes: 30))),
          t(
            'snoozed',
            _now.add(const Duration(minutes: 14)),
            snoozes: 1,
            updated: _now.subtract(const Duration(minutes: 1)),
          ),
        ],
        _prefs,
        _now,
      );
      expect(c!.task.id, 'snoozed');
      expect(c.state, ReminderCardState.snoozed);
    });

    test('a snoozed-once reminder that fired again is open', () {
      final c = pickCurrentReminder(
        [t('a', _now.subtract(const Duration(minutes: 1)), snoozes: 1)],
        _prefs,
        _now,
      );
      expect(c!.state, ReminderCardState.open);
    });

    test('outside ±2 h is ignored', () {
      expect(
        pickCurrentReminder(
          [t('x', _now.subtract(const Duration(hours: 3)))],
          _prefs,
          _now,
        ),
        isNull,
      );
    });
  });
}
