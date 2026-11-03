import 'calendar_event.dart';
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
    this.morningPromptMinutes = 8 * 60,
    this.eveningPromptMinutes = 20 * 60 + 30,
    this.selectedCalendarIds = const {},
    this.backupHintShown = false,
    this.pipAccessory = defaultPipAccessory,
  });

  static const defaultPipAccessory = 'scarf';

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

  /// No notifications inside this range. May cross midnight: build it with
  /// [TimeRange.wrapping] (22:00–07:00 has `wrapsMidnight`).
  final TimeRange? quietHours;
  final String timeZoneName;
  final String localeCode;
  final bool onboardingDone;

  /// Local minutes after midnight for the daily prompts; null = off.
  final int? morningPromptMinutes;
  final int? eveningPromptMinutes;

  /// Calendars the user chose to read per provider. A missing source means
  /// "never chose" (sync code then takes the primary calendar).
  final Map<CalendarSource, List<String>> selectedCalendarIds;

  /// Whether the one-time "export a backup" hint was shown (web durability).
  final bool backupHintShown;

  /// Pip's cosmetic accessory id (see the companion feature).
  final String pipAccessory;

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
    Object? morningPromptMinutes = _unset,
    Object? eveningPromptMinutes = _unset,
    Map<CalendarSource, List<String>>? selectedCalendarIds,
    bool? backupHintShown,
    String? pipAccessory,
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
    morningPromptMinutes: morningPromptMinutes == _unset
        ? this.morningPromptMinutes
        : morningPromptMinutes as int?,
    eveningPromptMinutes: eveningPromptMinutes == _unset
        ? this.eveningPromptMinutes
        : eveningPromptMinutes as int?,
    selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
    backupHintShown: backupHintShown ?? this.backupHintShown,
    pipAccessory: pipAccessory ?? this.pipAccessory,
  );
}

const _unset = Object();
