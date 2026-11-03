import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  Task task(String id, {DateTime? remindAt}) => Task(
    id: id,
    title: 'T$id',
    remindAt: remindAt,
    createdAt: now,
    updatedAt: now,
  );

  group('InMemoryTaskRepository', () {
    test('upsert, get, soft delete', () async {
      final repo = InMemoryTaskRepository();
      await repo.upsert(task('a'));
      expect((await repo.getAll()).length, 1);
      await repo.delete('a');
      expect(await repo.getAll(), isEmpty);
      expect(await repo.getById('a'), isNull);
    });

    test('getDueBetween filters by remindAt and open status', () async {
      final repo = InMemoryTaskRepository([
        task('in', remindAt: now.add(const Duration(hours: 1))),
        task('out', remindAt: now.add(const Duration(days: 9))),
        task(
          'done',
          remindAt: now.add(const Duration(hours: 2)),
        ).copyWith(status: TaskStatus.done),
      ]);
      final due = await repo.getDueBetween(
        now,
        now.add(const Duration(days: 7)),
      );
      expect(due.map((t) => t.id), ['in']);
    });

    test('watchAll emits current value then changes', () async {
      final repo = InMemoryTaskRepository();
      final emissions = <int>[];
      final sub = repo.watchAll().listen((l) => emissions.add(l.length));
      await Future<void>.delayed(Duration.zero);
      await repo.upsert(task('a'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [0, 1]);
    });
  });

  test('Task.copyWith can clear nullable fields', () {
    final t = task('a', remindAt: now).copyWith(remindAt: null);
    expect(t.remindAt, isNull);
  });

  test('Preferences defaults describe a working week', () {
    const p = Preferences();
    expect(p.workingHours.containsKey(DateTime.saturday), isFalse);
    expect(p.deepWindows.single.durationMinutes, 180);
  });

  test('contracts v2 fields round-trip through copyWith', () {
    final t = task('a').copyWith(notBefore: now, minutesDone: 20);
    expect(t.notBefore, now);
    expect(t.minutesDone, 20);
    expect(t.copyWith(notBefore: null).notBefore, isNull);
    const p = Preferences();
    expect(p.morningPromptMinutes, 8 * 60);
    final off = p.copyWith(morningPromptMinutes: null);
    expect(off.morningPromptMinutes, isNull);
    final sel = p.copyWith(
      selectedCalendarIds: {
        CalendarSource.google: ['a', 'b'],
      },
    );
    expect(sel.selectedCalendarIds[CalendarSource.google], ['a', 'b']);
    expect(p.backupHintShown, isFalse);
  });

  test('FixedClock advances', () {
    final c = FixedClock(now);
    c.advance(const Duration(hours: 1));
    expect(c.now(), now.add(const Duration(hours: 1)));
  });

  test('FakeCalendarProvider round trip', () async {
    final p = FakeCalendarProvider(CalendarSource.google);
    expect(await p.isConnected(), isFalse);
    await p.connect();
    expect((await p.listCalendars()).single.isPrimary, isTrue);
  });
}
