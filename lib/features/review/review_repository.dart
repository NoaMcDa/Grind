/// One finished evening review.
class ReviewEntry {
  const ReviewEntry({
    required this.date,
    required this.win,
    required this.doneCount,
    required this.movedCount,
  });

  /// Local day key, `yyyy-MM-dd`.
  final String date;
  final String win;
  final int doneCount;
  final int movedCount;
}

/// Storage for reviews. [InMemoryReviewRepository] is the default (tests,
/// demo); `DriftReviewRepository` (`drift_review_repository.dart`) keeps
/// them in the `review_entries` / `review_handled_days` tables.
abstract interface class ReviewRepository {
  Future<void> save(ReviewEntry entry);
  Future<List<ReviewEntry>> all();

  /// The review for a day was shown (finished or skipped): never offer again.
  Future<void> markHandled(String day);
  Future<bool> isHandled(String day);
}

class InMemoryReviewRepository implements ReviewRepository {
  final Map<String, ReviewEntry> _entries = {};
  final Set<String> _handled = {};

  @override
  Future<void> save(ReviewEntry entry) async => _entries[entry.date] = entry;

  @override
  Future<List<ReviewEntry>> all() async =>
      _entries.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  @override
  Future<void> markHandled(String day) async => _handled.add(day);

  @override
  Future<bool> isHandled(String day) async => _handled.contains(day);
}

/// The non-empty win of each saved review by local day (`yyyy-MM-dd`), for
/// the evening prompt (#37): pass to `NotificationSync(wins: ...)`.
Future<Map<String, String>> Function() reviewDayWins(ReviewRepository repo) =>
    () async => {
      for (final e in await repo.all())
        if (e.win.trim().isNotEmpty) e.date: e.win.trim(),
    };
