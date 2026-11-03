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

/// Storage for reviews. In-memory for now; see the proposed `review_entries`
/// table in the PR description.
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
