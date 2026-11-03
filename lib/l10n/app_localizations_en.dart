// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabToday => 'Today';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabFocus => 'Focus';

  @override
  String get tabPip => 'Pip';

  @override
  String get tabAsk => 'Ask';

  @override
  String get askTitle => 'Ask Pip';

  @override
  String get cloudAssistant => 'Cloud assistant';

  @override
  String get askGotIt => 'Got it! Here\'s the task:';

  @override
  String addedToDay(String day) {
    return 'Added to $day';
  }

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get yesPlanIt => 'Yes, plan it';

  @override
  String get justOneBlock => 'Just one block';

  @override
  String get quickPlanMyDay => 'Plan my day';

  @override
  String get quickMoveGym => 'Move gym to evening';

  @override
  String get composerHint => 'Type or speak a task…';

  @override
  String get speakATask => 'Speak a task';

  @override
  String get sendMessage => 'Send message';

  @override
  String focusProgress(int current, int total) {
    return 'Focus $current of $total';
  }

  @override
  String hardModeOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps shielded',
      one: '1 app shielded',
    );
    return 'Hard mode on · $_temp0';
  }

  @override
  String get paused => 'Paused';

  @override
  String get focusing => 'Focusing';

  @override
  String plusMinutes(int minutes) {
    return '+$minutes min';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get end => 'End';

  @override
  String sessionsDone(int done, int total) {
    return '$done of $total sessions done';
  }

  @override
  String get lockScreenPreview => 'Lock screen preview';

  @override
  String get liveActivity => 'Live Activity';

  @override
  String get pipSays => 'Pip:';

  @override
  String get pipCheeringSquad => 'Your cheering squad of one';

  @override
  String get pipGlowing => 'Pip is glowing';

  @override
  String get sectionMomentum => 'Momentum';

  @override
  String get momentumStrong => 'Strong';

  @override
  String get sectionThisWeek => 'This week';

  @override
  String get weeklyChartSemantics =>
      'Focus minutes per day this week. Wednesday was a rest day.';

  @override
  String get focusMinutesPerDay => 'Focus minutes per day';

  @override
  String get sectionWins => 'Wins you logged';

  @override
  String get sectionUnlocks => 'Unlocks';

  @override
  String get accScarf => 'Scarf';

  @override
  String get accSunglasses => 'Sunglasses';

  @override
  String get accPartyHat => 'Party hat';

  @override
  String get accRainBoots => 'Rain boots';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get wearing => 'Wearing';

  @override
  String get tapToWear => 'Tap to wear';

  @override
  String pipWearing(String item) {
    return 'wearing: $item';
  }

  @override
  String get sectionEnergy => 'Energy';

  @override
  String get energyDeep => 'Deep focus';

  @override
  String get energyLight => 'Light';

  @override
  String doneOfTotal(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get planDrafted => 'Your day, drafted';

  @override
  String planArranged(int tasks, int classes) {
    return 'Pip arranged $tasks tasks around $classes classes. Drag to tweak.';
  }

  @override
  String get rePlanWithPip => 'Re-plan with Pip';

  @override
  String get addTask => 'Add task';

  @override
  String get fromCalendar => 'From calendar';

  @override
  String get startFocus => 'Start focus';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get upNext => 'Up next';

  @override
  String get addATask => 'Add a task';

  @override
  String get reminderNow => 'Reminder · now';

  @override
  String get done => 'Done';

  @override
  String get snooze15 => 'Snooze 15';

  @override
  String get niceStart => 'Nice start!';

  @override
  String get pipHappyDance => 'Pip is doing a little happy dance.';

  @override
  String seeYouAt(String time) {
    return 'See you at $time';
  }

  @override
  String get snoozeAgainHint =>
      'Need a bit more time? Pip can offer to move it instead.';

  @override
  String get undo => 'Undo';

  @override
  String get pipSemanticLabel => 'Pip, your companion';

  @override
  String get momentumSemantic => 'Momentum';

  @override
  String get loading => 'Loading';

  @override
  String get dragHandle => 'Drag handle';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get emptyDefaultTitle => 'Nothing here yet';

  @override
  String get emptyDefaultBody => 'Whenever you\'re ready, Pip is here.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConnect => 'Connect';

  @override
  String get commonConnected => 'Connected';

  @override
  String get commonSunday => 'Sunday';

  @override
  String get commonMonday => 'Monday';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonGoogleCalendar => 'Google Calendar';

  @override
  String get commonAppleCalendar => 'Apple Calendar';

  @override
  String get commonLanguageEnglish => 'English';

  @override
  String get commonLanguageHebrew => 'עברית';

  @override
  String commonMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get commonWeekdayShortMon => 'Mon';

  @override
  String get commonWeekdayShortTue => 'Tue';

  @override
  String get commonWeekdayShortWed => 'Wed';

  @override
  String get commonWeekdayShortThu => 'Thu';

  @override
  String get commonWeekdayShortFri => 'Fri';

  @override
  String get commonWeekdayShortSat => 'Sat';

  @override
  String get commonWeekdayShortSun => 'Sun';

  @override
  String get commonWeekdayFullMon => 'Monday';

  @override
  String get commonWeekdayFullTue => 'Tuesday';

  @override
  String get commonWeekdayFullWed => 'Wednesday';

  @override
  String get commonWeekdayFullThu => 'Thursday';

  @override
  String get commonWeekdayFullFri => 'Friday';

  @override
  String get commonWeekdayFullSat => 'Saturday';

  @override
  String get commonWeekdayFullSun => 'Sunday';

  @override
  String get commonWeekdayLetterMon => 'M';

  @override
  String get commonWeekdayLetterTue => 'T';

  @override
  String get commonWeekdayLetterWed => 'W';

  @override
  String get commonWeekdayLetterThu => 'T';

  @override
  String get commonWeekdayLetterFri => 'F';

  @override
  String get commonWeekdayLetterSat => 'S';

  @override
  String get commonWeekdayLetterSun => 'S';

  @override
  String get commonMonthShortJan => 'Jan';

  @override
  String get commonMonthShortFeb => 'Feb';

  @override
  String get commonMonthShortMar => 'Mar';

  @override
  String get commonMonthShortApr => 'Apr';

  @override
  String get commonMonthShortMay => 'May';

  @override
  String get commonMonthShortJun => 'Jun';

  @override
  String get commonMonthShortJul => 'Jul';

  @override
  String get commonMonthShortAug => 'Aug';

  @override
  String get commonMonthShortSep => 'Sep';

  @override
  String get commonMonthShortOct => 'Oct';

  @override
  String get commonMonthShortNov => 'Nov';

  @override
  String get commonMonthShortDec => 'Dec';

  @override
  String commonDateShort(String weekday, String month, int day) {
    return '$weekday, $month $day';
  }

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksEditTask => 'Edit task';

  @override
  String get tasksTitleLabel => 'What needs doing?';

  @override
  String get tasksTitleRequired => 'Give it a short name and you are set.';

  @override
  String get tasksDueLabel => 'Due';

  @override
  String get tasksPickDate => 'Pick a date';

  @override
  String get tasksNoDate => 'No date';

  @override
  String get tasksDueTime => 'Due time';

  @override
  String get tasksReminderTime => 'Reminder';

  @override
  String get tasksAddTime => 'Add a time';

  @override
  String get tasksEstimateLabel => 'How long?';

  @override
  String get tasksCustom => 'Custom';

  @override
  String get tasksCustomMinutes => 'Minutes';

  @override
  String get tasksFirstActionLabel => 'First action';

  @override
  String get tasksFirstActionHint => 'If it\'s 7:00, then open the thesis file';

  @override
  String get tasksNotesLabel => 'Notes';

  @override
  String get tasksDetailTitle => 'Task';

  @override
  String get tasksNotFound => 'This task is not here anymore.';

  @override
  String get tasksBackToToday => 'Back to Today';

  @override
  String get tasksComplete => 'Complete';

  @override
  String get tasksReopen => 'Mark as open';

  @override
  String get tasksDeleteTitle => 'Delete this task?';

  @override
  String get tasksDeleteBody => 'You can undo it right after.';

  @override
  String get tasksKeep => 'Keep it';

  @override
  String get tasksDeleted => 'Task deleted';

  @override
  String get tasksMarkedDone => 'Nicely done';

  @override
  String get tasksEmptyTitle => 'Nothing due today';

  @override
  String get tasksEmptyBody => 'Add one small thing and Pip will remind you.';

  @override
  String tasksDoneOfToday(int done, int total) {
    return '$done of $total today';
  }

  @override
  String get remindersTonight => 'Tonight';

  @override
  String get remindersPickATime => 'Pick a time';

  @override
  String get remindersMoveOffer => 'Want to move this instead?';

  @override
  String remindersMoveLine(String title) {
    return '\"$title\" can have a calmer moment.';
  }

  @override
  String get remindersLine01 => '25 minutes is enough to start.';

  @override
  String get remindersLine02 => 'Small steps count.';

  @override
  String get remindersLine03 => 'Just the first step. Pip has the rest.';

  @override
  String get remindersLine04 => 'Starting is the hard part, and you are here.';

  @override
  String get remindersLine05 => 'Five minutes in, it gets easier.';

  @override
  String get remindersLine06 => 'One page is a fine start.';

  @override
  String get remindersLine07 => 'Pip has the timer ready.';

  @override
  String get remindersLine08 => 'No need to finish, just begin.';

  @override
  String get remindersLine09 => 'You picked this step for a reason.';

  @override
  String get remindersLine10 => 'Little by little adds up.';

  @override
  String get remindersLine11 => 'Open it and see how it feels.';

  @override
  String get remindersLine12 => 'A quick start beats a perfect plan.';

  @override
  String get remindersLine13 => 'Pip is cheering for you.';

  @override
  String get remindersLine14 => 'Ten focused minutes go a long way.';

  @override
  String get remindersLine15 => 'Begin small, keep it light.';

  @override
  String get remindersLine16 => 'This moment is yours.';

  @override
  String get remindersLine17 => 'Momentum starts with one move.';

  @override
  String get remindersLine18 => 'Easy does it. Start where you are.';

  @override
  String get remindersLine19 => 'Future you will be glad.';

  @override
  String get remindersLine20 => 'Ready when you are.';

  @override
  String get recurrenceDoesNotRepeat => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekdays => 'Weekdays';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceRepeatLabel => 'Repeat';

  @override
  String get recurrenceOnDays => 'On days';

  @override
  String get recurrenceEveryLabel => 'Every';

  @override
  String get recurrenceEndsLabel => 'Ends';

  @override
  String get recurrenceNever => 'Never';

  @override
  String get recurrenceOnDate => 'On a date';

  @override
  String get recurrenceDone => 'Done';

  @override
  String get recurrenceIncrease => 'Increase';

  @override
  String get recurrenceDecrease => 'Decrease';

  @override
  String recurrenceUnitDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceEditThisOne => 'This one';

  @override
  String get recurrenceEditAllFuture => 'All future';

  @override
  String get recurrenceEditTitle => 'Change just this one?';

  @override
  String get recurrenceEditHint =>
      'Change this one time, or the series from here on.';

  @override
  String recurrenceEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceEveryWeekday => 'Every weekday';

  @override
  String recurrenceEveryWeek(int n, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n weeks on $days',
      one: 'Every $days',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryWeekPlain(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonthOn(int n, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n months',
      one: 'Every month',
    );
    return '$_temp0 on the $day';
  }

  @override
  String recurrenceListJoinLast(String head, String last) {
    return '$head and $last';
  }

  @override
  String recurrenceUntil(String date) {
    return 'until $date';
  }

  @override
  String recurrenceTimesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String recurrenceDateLabel(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get planYourDay => 'Your day';

  @override
  String planSubtitle(int tasks, int events) {
    String _temp0 = intl.Intl.pluralLogic(
      tasks,
      locale: localeName,
      other: '$tasks tasks',
      one: '1 task',
    );
    String _temp1 = intl.Intl.pluralLogic(
      events,
      locale: localeName,
      other: '$events events',
      one: '1 event',
    );
    return 'Pip arranged $_temp0 around $_temp1. Long-press a task to move it.';
  }

  @override
  String get planEmptyTitle => 'Nothing planned yet';

  @override
  String get planEmptyBody =>
      'A quiet day. Add a task and Pip will find it a good spot.';

  @override
  String get planPreviousDay => 'Previous day';

  @override
  String get planNextDay => 'Next day';

  @override
  String get planPickDay => 'Pick a day';

  @override
  String get planWeekStripLabel => 'Week';

  @override
  String get planNowLabel => 'Now';

  @override
  String planDayLoad(String day, int percent) {
    return '$day, $percent% booked';
  }

  @override
  String get planAllDay => 'All day';

  @override
  String get planCalendarLocal => 'Grind';

  @override
  String get planCalendarLabel => 'Calendar';

  @override
  String get planOpenInCalendar => 'Open in calendar';

  @override
  String get planOpenInCalendarSoon =>
      'Opening the calendar app is coming soon.';

  @override
  String get planMarkDone => 'Mark done';

  @override
  String get planMarkOpen => 'Mark as not done';

  @override
  String get planUnschedule => 'Unschedule';

  @override
  String get planCantDropHere => 'That slot is taken by an event.';

  @override
  String get onboardingWelcomeTitle => 'Hi, I\'m Pip';

  @override
  String get onboardingWelcomeBody =>
      'Grind keeps your plans on this phone. Nothing leaves it.';

  @override
  String get onboardingWelcomeStart => 'Start';

  @override
  String get onboardingNotifTitle => 'Gentle nudges, only when you want them';

  @override
  String get onboardingNotifRationaleTitle => 'Why notifications?';

  @override
  String get onboardingNotifRationale =>
      'Reminders can only reach you if Grind may show them. I will only nudge you about things you asked me to remind you of.';

  @override
  String get onboardingNotifAllow => 'Allow';

  @override
  String get onboardingNotifNotNow => 'Not now';

  @override
  String get onboardingNotifGranted => 'Notifications are on. Thank you!';

  @override
  String get onboardingNotifDenied =>
      'No problem. Grind works fine without notifications. You can switch them on later in Settings.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingCalTitle => 'Bring your calendar along';

  @override
  String get onboardingCalRationale =>
      'Connecting a calendar lets me plan around meetings you already have. Events are read on this device and stay here.';

  @override
  String get onboardingCalFailed =>
      'That did not work this time. You can retry, or skip it for now.';

  @override
  String get onboardingCalLater =>
      'You can always connect one later in Settings.';

  @override
  String get onboardingHoursTitle => 'When do you like to work?';

  @override
  String get onboardingHoursBody =>
      'I will plan around these hours. Switch a day off to keep it free.';

  @override
  String get onboardingWeekStartLabel => 'Week starts on';

  @override
  String get onboardingLanguageLabel => 'Language';

  @override
  String get onboardingDoneTitle => 'You\'re set.';

  @override
  String get onboardingDoneBody =>
      'Everything stays on this device. You can change any of this in Settings, whenever you like.';

  @override
  String get onboardingDoneButton => 'Take me to Today';

  @override
  String get onboardingDayOff => 'Day off';

  @override
  String get onboardingStartTime => 'Start time';

  @override
  String get onboardingEndTime => 'End time';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCalendars => 'Calendars';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsCalendarsToUse => 'Calendars to use';

  @override
  String get settingsConnectFailed =>
      'That did not work this time. Whenever you like, give it another go.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifPermission => 'Allow notifications';

  @override
  String get settingsNotifPermissionOn => 'On';

  @override
  String get settingsNotifPermissionOff =>
      'Off. Grind keeps working; turn them on if you want reminders.';

  @override
  String get settingsLeadTime => 'Remind me before';

  @override
  String get settingsLeadAtTime => 'At the time';

  @override
  String get settingsQuietHours => 'Quiet hours';

  @override
  String get settingsQuietHoursHint => 'No notifications in this window.';

  @override
  String get settingsQuietFrom => 'From';

  @override
  String get settingsQuietTo => 'To';

  @override
  String get settingsMorningPrompt => 'Morning prompt';

  @override
  String get settingsEveningPrompt => 'Evening prompt';

  @override
  String get settingsPromptsHint =>
      'A short hello from Pip to plan or wrap up.';

  @override
  String get settingsPlanning => 'Planning';

  @override
  String get settingsWorkingHours => 'Working hours';

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExportBackup => 'Export backup';

  @override
  String get settingsImportBackup => 'Import backup';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsExportDone => 'Backup saved.';

  @override
  String get settingsImportDone => 'Backup restored.';

  @override
  String get settingsActionFailed =>
      'That did not work this time. Nothing was lost.';

  @override
  String get settingsDeleteConfirmTitle => 'Delete everything?';

  @override
  String get settingsDeleteConfirmBody =>
      'This removes all tasks, plans and settings from this device. It cannot be undone.';

  @override
  String get settingsDeleteConfirm => 'Delete';

  @override
  String get settingsDeleted => 'All data deleted.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicences => 'Licences';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyCopy =>
      'Everything stays on this device. No account, no sign-in.';
}
