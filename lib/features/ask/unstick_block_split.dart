/// Deterministic generator of the "two short focus blocks instead of one
/// long one" split, the `splitInTwo` branch of the "I'm stuck" helper
/// (epic #41).
///
/// Pure Dart with no I/O, no Flutter and no clock reads: given a long focus
/// block, return two shorter blocks separated by a short gap, honoring the
/// user's quiet hours when passed in. The chat UI (epic #42) renders the
/// split as a pill, and the matching tool call reads the two child blocks
/// to replace the long one on the timeline.
library;

import 'package:grind/core/core.dart' show TimeRange;

/// One focus block on a local timeline, half-open `[start, end)`.
///
/// Kept tiny on purpose: `splitLongBlock` is reached from both the chat
/// side (which only needs clock times) and the scheduler side (which has
/// its own [Slot] for the timeline), so this type does not pretend to
/// replace either. Callers construct it from whichever shape they hold
/// and read `start`/`end` on the way back out.
class FocusBlock {
  const FocusBlock(this.start, this.end);

  final DateTime start;
  final DateTime end;

  int get minutes => end.difference(start).inMinutes;
  bool get isEmpty => !end.isAfter(start);

  @override
  bool operator ==(Object other) =>
      other is FocusBlock && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'FocusBlock($start → $end)';
}

/// The result of splitting one long focus block into two shorter ones.
///
/// [first] and [second] are the two new blocks, in start order; [gap] is
/// the half-open interval between them. All three cover the same wall
/// clock as the original block: `first.start == original.start`,
/// `gap.start == first.end`, `second.start == gap.end`,
/// `second.end == original.end`. The second block always ends at the
/// original's end so the task's reserved window on the timeline does not
/// shift — only its middle opens up for a break.
class FocusBlockSplit {
  const FocusBlockSplit({
    required this.first,
    required this.second,
    required this.gap,
  });

  final FocusBlock first;
  final FocusBlock second;
  final FocusBlock gap;

  /// The two focus blocks, first then second — handy for timeline writes.
  List<FocusBlock> get blocks => [first, second];

  /// Total focus minutes across the two blocks (excludes the gap).
  int get totalFocusMinutes => first.minutes + second.minutes;

  @override
  bool operator ==(Object other) =>
      other is FocusBlockSplit &&
      other.first == first &&
      other.second == second &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(first, second, gap);

  @override
  String toString() => 'FocusBlockSplit(first=$first, gap=$gap, second=$second)';
}

/// Why a split was refused. The chat layer uses this to pick which offline
/// fallback to show — `tooShort` leads to `shortenTo10Min`, `quietHoursOverlap`
/// leads to `reschedule`.
enum SplitRefusal {
  /// The block is shorter than two parts of [minPartMinutes] plus the gap.
  tooShort,

  /// A split exists arithmetically but at least one half still lands
  /// inside the user's quiet hours — rescheduling is the better answer.
  quietHoursOverlap,
}

/// Outcome of [splitLongBlock]: either a [FocusBlockSplit] or a
/// [SplitRefusal] reason the caller can read.
class SplitLongBlockResult {
  const SplitLongBlockResult._(this.split, this.refusal);

  const SplitLongBlockResult.ok(FocusBlockSplit split) : this._(split, null);
  const SplitLongBlockResult.refused(SplitRefusal reason)
    : this._(null, reason);

  final FocusBlockSplit? split;
  final SplitRefusal? refusal;

  bool get isOk => split != null;
}

/// The 5-minute granularity the scheduler already uses for chunk lengths;
/// keeping the split on the same grid means the result lines up when the
/// scheduler re-reads these blocks.
const _grid = 5;

int _floorToGrid(int n) => (n ~/ _grid) * _grid;

bool _blockOverlapsQuietHours(FocusBlock b, TimeRange quietHours) {
  if (b.isEmpty) return false;
  // Scan the block minute by minute on its local calendar day. A focus
  // block is at most a few hours long in practice, so the loop is cheap
  // and it handles wrapping quiet hours without any date arithmetic.
  final start = b.start.toLocal();
  final end = b.end.toLocal();
  final startMin = start.hour * 60 + start.minute;
  final totalMinutes = end.difference(start).inMinutes;
  for (var i = 0; i < totalMinutes; i++) {
    final m = (startMin + i) % (24 * 60);
    if (quietHours.contains(m)) return true;
  }
  return false;
}

/// Splits [block] into two shorter focus blocks separated by a short gap.
///
/// The split is deterministic: the two halves are as even as possible on a
/// 5-minute grid, the first half rounded up when the block does not halve
/// cleanly so the user's heavier work lands first. The gap defaults to 5
/// minutes — the same short-break length the focus timer uses — and sits
/// in the middle of the original block.
///
/// Returns an `ok` result when the block is at least `2 * minPartMinutes +
/// gapMinutes` long and (when [quietHours] is given) neither focus half
/// overlaps the quiet-hours window. A tight quiet-hours window that fits
/// inside the gap is fine — splitting is what opens the gap. Otherwise
/// returns a `refused` result with the reason, so the "I'm stuck" helper
/// can fall back to a reschedule or shorten option instead.
///
/// [gapMinutes] and [minPartMinutes] both round up to the 5-minute grid.
SplitLongBlockResult splitLongBlock(
  FocusBlock block, {
  int gapMinutes = 5,
  int minPartMinutes = 15,
  TimeRange? quietHours,
}) {
  assert(gapMinutes >= 0, 'gapMinutes must be non-negative');
  assert(minPartMinutes > 0, 'minPartMinutes must be positive');

  if (block.isEmpty) {
    return const SplitLongBlockResult.refused(SplitRefusal.tooShort);
  }

  // Round configuration to the 5-minute grid so the split stays on it.
  final gap = ((gapMinutes + _grid - 1) ~/ _grid) * _grid;
  final minPart = ((minPartMinutes + _grid - 1) ~/ _grid) * _grid;

  final totalMinutes = block.minutes;
  if (totalMinutes < 2 * minPart + gap) {
    return const SplitLongBlockResult.refused(SplitRefusal.tooShort);
  }

  // Equal halves on the grid. If the focus time does not halve cleanly on
  // the grid, the first half carries the extra 5 minutes — the heavier
  // start matches how people pick up long tasks again.
  final focusMinutes = totalMinutes - gap;
  var firstMinutes = _floorToGrid(focusMinutes ~/ 2);
  if (firstMinutes + firstMinutes < focusMinutes) {
    // A 5-minute remainder landed in [firstMinutes * 2 + _grid, focusMinutes].
    final bumped = firstMinutes + _grid;
    if (bumped + minPart <= focusMinutes) {
      firstMinutes = bumped;
    }
  }
  if (firstMinutes < minPart) firstMinutes = minPart;
  final secondMinutes = focusMinutes - firstMinutes;
  if (secondMinutes < minPart) {
    return const SplitLongBlockResult.refused(SplitRefusal.tooShort);
  }

  final firstEnd = block.start.add(Duration(minutes: firstMinutes));
  final gapEnd = firstEnd.add(Duration(minutes: gap));
  final first = FocusBlock(block.start, firstEnd);
  final gapBlock = FocusBlock(firstEnd, gapEnd);
  final second = FocusBlock(gapEnd, block.end);

  if (quietHours != null) {
    if (_blockOverlapsQuietHours(first, quietHours) ||
        _blockOverlapsQuietHours(second, quietHours)) {
      return const SplitLongBlockResult.refused(SplitRefusal.quietHoursOverlap);
    }
  }

  return SplitLongBlockResult.ok(
    FocusBlockSplit(first: first, second: second, gap: gapBlock),
  );
}
