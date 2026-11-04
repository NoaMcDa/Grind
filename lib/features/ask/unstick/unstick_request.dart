/// Input value object for the "I'm stuck" helper (epic #41).
///
/// Bundles the single-task context Pip needs to produce 1–3 [UnstickOption]s:
/// the task the user is behind on, its current duration estimate, how long
/// it is already overdue, a short slice of the user's recent task history,
/// and the UI locale.
///
/// Both the offline fallback suggester and the LLM path (#38) consume this
/// shape so the chat layer builds one request once and passes it to
/// whichever backend is available. Keeping it a plain value object — no
/// Flutter, no gateway types, no clock reads — means the "I'm stuck" branch
/// stays testable end-to-end without mocking either side.
library;

import 'package:flutter/foundation.dart';

/// What kind of recent-history line this is. The offline fallback looks at
/// the mix (did the user complete anything today? are two tasks in a row
/// skipped?) to pick which options to lead with; the LLM path reads them
/// as structured context rather than a free-text journal.
enum RecentEventKind {
  /// The user finished a task.
  completed,

  /// The user skipped a task.
  skipped,

  /// The task fell off the day without an explicit skip.
  missed,

  /// The user started a focus block but did not finish it.
  started,

  /// The user moved a task to another time.
  rescheduled,
}

/// One entry in [UnstickRequest.recentHistory].
///
/// Kept deliberately small: the "I'm stuck" path looks at the shape of the
/// last few events, not their detail, so one line per event is enough.
@immutable
class RecentEvent {
  const RecentEvent({
    required this.kind,
    required this.taskTitle,
    required this.when,
  });

  /// What happened.
  final RecentEventKind kind;

  /// Short title of the task this event is about.
  final String taskTitle;

  /// When it happened, in the user's local wall clock.
  final DateTime when;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'taskTitle': taskTitle,
    'when': when.toIso8601String(),
  };

  static RecentEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    final kindName = j['kind'];
    if (kindName is! String) return null;
    final kind = RecentEventKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => RecentEventKind.missed,
    );
    final title = j['taskTitle'];
    final whenRaw = j['when'];
    if (title is! String || title.isEmpty) return null;
    if (whenRaw is! String) return null;
    final when = DateTime.tryParse(whenRaw);
    if (when == null) return null;
    return RecentEvent(kind: kind, taskTitle: title, when: when);
  }

  @override
  bool operator ==(Object other) =>
      other is RecentEvent &&
      other.kind == kind &&
      other.taskTitle == taskTitle &&
      other.when == when;

  @override
  int get hashCode => Object.hash(kind, taskTitle, when);

  @override
  String toString() => 'RecentEvent(${kind.name}, "$taskTitle", $when)';
}

/// Input to the "I'm stuck" helper.
///
/// Required: a task title and a positive duration estimate. Everything else
/// is optional; the suggester and the LLM path both tolerate empty history
/// and a null overdue duration — "stuck on a one-hour task, not overdue"
/// is a perfectly valid request.
///
/// Instances are immutable value objects: same inputs compare equal, which
/// lets the chat layer de-duplicate repeated asks on the same task without
/// re-running the suggester.
@immutable
class UnstickRequest {
  UnstickRequest({
    required this.taskTitle,
    required this.estimatedMinutes,
    this.overdueBy,
    List<RecentEvent> recentHistory = const [],
    this.localeCode = 'en',
  }) : recentHistory = List<RecentEvent>.unmodifiable(recentHistory),
       assert(estimatedMinutes > 0, 'estimatedMinutes must be positive'),
       assert(taskTitle != '', 'taskTitle must not be empty');

  /// The task the user says they are stuck on. Non-empty.
  final String taskTitle;

  /// Current duration estimate in minutes. Positive.
  final int estimatedMinutes;

  /// How long the task is already overdue. Null or non-positive means it
  /// is not overdue yet; the suggester treats both the same way.
  final Duration? overdueBy;

  /// Up to the last handful of events on the user's day, newest last.
  /// Empty when no history is available.
  final List<RecentEvent> recentHistory;

  /// `'en'` or `'he'`. Any other value is passed through as-is; the
  /// suggester falls back to English for unknown locales, matching
  /// [StaticUnstickSuggester].
  final String localeCode;

  /// True when [overdueBy] is a positive duration.
  bool get isOverdue =>
      overdueBy != null && overdueBy! > Duration.zero;

  /// Serialised shape the LLM path sends over the wire.
  Map<String, Object?> toJson() => {
    'taskTitle': taskTitle,
    'estimatedMinutes': estimatedMinutes,
    if (overdueBy != null) 'overdueMinutes': overdueBy!.inMinutes,
    if (recentHistory.isNotEmpty)
      'recentHistory': recentHistory.map((e) => e.toJson()).toList(),
    'localeCode': localeCode,
  };

  /// Parses a JSON map the chat layer sends to the suggester or the LLM
  /// gateway. Returns null on any structural problem — callers decide
  /// whether to surface an error or fall back to defaults.
  static UnstickRequest? fromJson(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, Object?>();
    final title = j['taskTitle'];
    final minutesRaw = j['estimatedMinutes'];
    if (title is! String || title.isEmpty) return null;
    final minutes = minutesRaw is int
        ? minutesRaw
        : minutesRaw is num
        ? minutesRaw.round()
        : null;
    if (minutes == null || minutes <= 0) return null;

    Duration? overdue;
    final overdueRaw = j['overdueMinutes'];
    if (overdueRaw is int) {
      overdue = Duration(minutes: overdueRaw);
    } else if (overdueRaw is num) {
      overdue = Duration(minutes: overdueRaw.round());
    }

    final history = <RecentEvent>[];
    final rawHistory = j['recentHistory'];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        final event = RecentEvent.fromJson(entry);
        if (event != null) history.add(event);
      }
    }

    final locale = j['localeCode'];
    return UnstickRequest(
      taskTitle: title,
      estimatedMinutes: minutes,
      overdueBy: overdue,
      recentHistory: history,
      localeCode: locale is String && locale.isNotEmpty ? locale : 'en',
    );
  }

  /// Returns a copy with one or more fields replaced. `overdueBy` and
  /// `recentHistory` use a sentinel so a caller can explicitly clear them.
  UnstickRequest copyWith({
    String? taskTitle,
    int? estimatedMinutes,
    Object? overdueBy = _unset,
    List<RecentEvent>? recentHistory,
    String? localeCode,
  }) => UnstickRequest(
    taskTitle: taskTitle ?? this.taskTitle,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    overdueBy: overdueBy == _unset ? this.overdueBy : overdueBy as Duration?,
    recentHistory: recentHistory ?? this.recentHistory,
    localeCode: localeCode ?? this.localeCode,
  );

  @override
  bool operator ==(Object other) =>
      other is UnstickRequest &&
      other.taskTitle == taskTitle &&
      other.estimatedMinutes == estimatedMinutes &&
      other.overdueBy == overdueBy &&
      other.localeCode == localeCode &&
      listEquals(other.recentHistory, recentHistory);

  @override
  int get hashCode => Object.hash(
    taskTitle,
    estimatedMinutes,
    overdueBy,
    localeCode,
    Object.hashAll(recentHistory),
  );

  @override
  String toString() {
    final parts = <String>[
      'title: "$taskTitle"',
      'est: ${estimatedMinutes}m',
    ];
    if (overdueBy != null) parts.add('overdue: ${overdueBy!.inMinutes}m');
    if (recentHistory.isNotEmpty) parts.add('history: ${recentHistory.length}');
    parts.add('locale: $localeCode');
    return 'UnstickRequest(${parts.join(', ')})';
  }
}

const _unset = Object();
