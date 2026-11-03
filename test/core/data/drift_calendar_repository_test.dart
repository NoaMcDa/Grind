import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  DateTime h(num hours) => now.add(Duration(minutes: (hours * 60).round()));
  late AppDatabase db;
  late DriftCalendarRepository repo;

  CalendarEvent event(
    String id,
    num start,
    num end, {
    CalendarSource source = CalendarSource.google,
  }) => CalendarEvent(
    id: id,
    source: source,
    externalId: 'ext-$id',
    calendarId: 'primary',
    title: 'E$id',
    start: h(start),
    end: h(end),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    db = openInMemoryDatabase();
    repo = DriftCalendarRepository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  test('upsert, get, update, soft delete', () async {
    await repo.upsert(event('a', 1, 2));
    expect((await repo.getById('a'))!.title, 'Ea');
    expect(
      (await repo.getByExternalId(CalendarSource.google, 'ext-a'))!.id,
      'a',
    );
    expect(await repo.getByExternalId(CalendarSource.apple, 'ext-a'), isNull);

    await repo.upsert(
      (await repo.getById('a'))!.copyWith(title: 'moved', isBusy: false),
    );
    final updated = (await repo.getById('a'))!;
    expect(updated.title, 'moved');
    expect(updated.isBusy, isFalse);
    expect(updated.duration, const Duration(hours: 1));

    await repo.delete('a');
    expect(await repo.getById('a'), isNull);
    expect(await repo.getByExternalId(CalendarSource.google, 'ext-a'), isNull);
    expect(await repo.getBetween(h(0), h(24)), isEmpty);
    expect((await db.select(db.calendarEvents).get()).length, 1);
  });

  test('v3: htmlLink round-trips and clears', () async {
    await repo.upsert(
      event('a', 1, 2).copyWith(htmlLink: 'https://calendar.example/a'),
    );
    final got = (await repo.getById('a'))!;
    expect(got.htmlLink, 'https://calendar.example/a');
    await repo.upsert(got.copyWith(htmlLink: null));
    expect((await repo.getById('a'))!.htmlLink, isNull);
  });

  test('getBetween: overlaps of [from, to), sorted by start', () async {
    await repo.upsertAll([
      event('late', 3, 4),
      event('early', 1, 2),
      event('overlapStart', -1, 0.5),
      event('endsAtFrom', -1, 0),
      event('startsAtTo', 5, 6),
      event('spanning', -2, 8),
    ]);
    final got = await repo.getBetween(h(0), h(5));
    expect(got.map((e) => e.id), ['spanning', 'overlapStart', 'early', 'late']);
  });

  test('clearSource hard-deletes one source only', () async {
    await repo.upsertAll([
      event('g', 1, 2),
      event('a', 1, 2, source: CalendarSource.apple),
    ]);
    await repo.clearSource(CalendarSource.google);
    expect((await repo.getBetween(h(0), h(5))).map((e) => e.id), ['a']);
    expect((await db.select(db.calendarEvents).get()).length, 1);
  });

  test('watchBetween emits current value then changes in range', () async {
    final emissions = <List<String>>[];
    final sub = repo
        .watchBetween(h(0), h(5))
        .listen((l) => emissions.add([for (final e in l) e.id]));
    await pumpEventQueue();
    await repo.upsert(event('in', 1, 2));
    await pumpEventQueue();
    await repo.upsert(event('out', 10, 11));
    await pumpEventQueue();
    await repo.delete('in');
    await pumpEventQueue();
    await sub.cancel();
    // Like the in-memory version, every write re-emits the range.
    expect(emissions, [
      <String>[],
      ['in'],
      ['in'],
      <String>[],
    ]);
  });
}
