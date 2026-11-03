import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/features/review/drift_review_repository.dart';
import 'package:grind/features/review/review.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 19);
  late AppDatabase db;

  setUp(() => db = openInMemoryDatabase());
  tearDown(() => db.close());

  const entry = ReviewEntry(
    date: '2026-11-03',
    win: 'Finished the draft',
    doneCount: 4,
    movedCount: 1,
  );

  // The same contract runs against both implementations.
  final impls = <String, ReviewRepository Function()>{
    'Drift': () => DriftReviewRepository(db, clock: FixedClock(now)),
    'InMemory': InMemoryReviewRepository.new,
  };

  for (final MapEntry(key: name, value: make) in impls.entries) {
    group(name, () {
      test(
        'save and all, sorted by day; saving a day again replaces',
        () async {
          final repo = make();
          await repo.save(entry);
          await repo.save(
            const ReviewEntry(
              date: '2026-11-01',
              win: 'Rested',
              doneCount: 0,
              movedCount: 2,
            ),
          );
          await repo.save(
            const ReviewEntry(
              date: '2026-11-03',
              win: 'Finished the draft and the slides',
              doneCount: 5,
              movedCount: 0,
            ),
          );
          final all = await repo.all();
          expect(all.map((e) => e.date), ['2026-11-01', '2026-11-03']);
          expect(all.last.win, 'Finished the draft and the slides');
          expect((all.last.doneCount, all.last.movedCount), (5, 0));
        },
      );

      test('markHandled / isHandled, idempotent', () async {
        final repo = make();
        expect(await repo.isHandled('2026-11-03'), isFalse);
        await repo.markHandled('2026-11-03');
        await repo.markHandled('2026-11-03');
        expect(await repo.isHandled('2026-11-03'), isTrue);
        expect(await repo.isHandled('2026-11-02'), isFalse);
      });
    });
  }

  test('Drift: reviews survive a new repository (cold start)', () async {
    await DriftReviewRepository(db, clock: FixedClock(now)).save(entry);
    await DriftReviewRepository(db).markHandled('2026-11-03');
    final fresh = DriftReviewRepository(db);
    expect((await fresh.all()).single.win, 'Finished the draft');
    expect(await fresh.isHandled('2026-11-03'), isTrue);
  });

  test('Drift: re-saving a day keeps its first createdAt', () async {
    final clock = FixedClock(now);
    final repo = DriftReviewRepository(db, clock: clock);
    await repo.save(entry);
    clock.advance(const Duration(hours: 2));
    await repo.save(entry);
    final row = await db.select(db.reviewEntries).getSingle();
    expect(row.createdAt, now.millisecondsSinceEpoch);
  });

  test('reviewRepositoryOverride swaps in Drift', () {
    final c = ProviderContainer(overrides: [reviewRepositoryOverride(db)]);
    addTearDown(c.dispose);
    expect(c.read(reviewRepositoryProvider), isA<DriftReviewRepository>());
  });
}
