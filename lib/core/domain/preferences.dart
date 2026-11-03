import 'time_range.dart';

/// User preferences the planner and notifications depend on. One row.
class Preferences {
  const Preferences({
    this.workingHours = const {
      DateTime.monday: [TimeRange(startMinutes: 9 * 60, endMinutes: 18 * 60)],
      DateTime.tuesday: [TimeRange(startMinutes: 9 * 60, endMinutes: 18 * 60)],
      DateTime.wednesday: [
        TimeRange(startMinutes: 9 * 60, endMinutes: 18 * 60),
      ],
      DateTime.thursday: [TimeRange(startMinutes: 9 * 60, endMinutes: 18 * 60)],
      DateTime.friday: [TimeRange(startMinutes: 9 * 60, endMinutes: 14 * 60)],
    },
    this.deepWindows = const [
      TimeRange(startMinutes: 9 * 60, endMinutes: 12 * 60),
    ],
    this.lunch = const [TimeRange(startMinutes: 12 * 60, endMinutes: 13 * 60)],
    this.maxDeepBlocksPerDay = 2,
    this.deepBlockMinutes = 90,
    this.bufferBetweenEventsMinutes = 10,
    this.dailyCushionMinutes = 60,
    this.weekStart = DateTime.sunday,
    this.defaultReminderLeadMinutes = 0,
    this.quietHours,
    this.timeZoneName = 'Asia/Jerusalem',
    this.localeCode = 'en',
    this.onboardingDone = false,
  });

  /// Keyed by [DateTime.monday] … [DateTime.sunday]. Missing day = day off.
  final Map<int, List<TimeRange>> workingHours;
  final List<TimeRange> deepWindows;
  final List<TimeRange> lunch;
  final int maxDeepBlocksPerDay;
  final int deepBlockMinutes;
  final int bufferBetweenEventsMinutes;

  /// Minutes per day never planned, so the day has slack.
  final int dailyCushionMinutes;
  final int weekStart;
  final int defaultReminderLeadMinutes;

  /// No notifications inside this range (may cross midnight by using two).
  final TimeRange? quietHours;
  final String timeZoneName;
  final String localeCode;
  final bool onboardingDone;

  Preferences copyWith({
    Map<int, List<TimeRange>>? workingHours,
    List<TimeRange>? deepWindows,
    List<TimeRange>? lunch,
    int? maxDeepBlocksPerDay,
    int? deepBlockMinutes,
    int? bufferBetweenEventsMinutes,
    int? dailyCushionMinutes,
    int? weekStart,
    int? defaultReminderLeadMinutes,
    Object? quietHours = _unset,
    String? timeZoneName,
    String? localeCode,
    bool? onboardingDone,
  }) => Preferences(
    workingHours: workingHours ?? this.workingHours,
    deepWindows: deepWindows ?? this.deepWindows,
    lunch: lunch ?? this.lunch,
    maxDeepBlocksPerDay: maxDeepBlocksPerDay ?? this.maxDeepBlocksPerDay,
    deepBlockMinutes: deepBlockMinutes ?? this.deepBlockMinutes,
    bufferBetweenEventsMinutes:
        bufferBetweenEventsMinutes ?? this.bufferBetweenEventsMinutes,
    dailyCushionMinutes: dailyCushionMinutes ?? this.dailyCushionMinutes,
    weekStart: weekStart ?? this.weekStart,
    defaultReminderLeadMinutes:
        defaultReminderLeadMinutes ?? this.defaultReminderLeadMinutes,
    quietHours: quietHours == _unset
        ? this.quietHours
        : quietHours as TimeRange?,
    timeZoneName: timeZoneName ?? this.timeZoneName,
    localeCode: localeCode ?? this.localeCode,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

const _unset = Object();
