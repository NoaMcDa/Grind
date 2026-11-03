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
  String get onboardingQuietLabel => 'Quiet overnight';

  @override
  String onboardingQuietBody(String range) {
    return 'No nudges $range. You can change this in Settings.';
  }

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

  @override
  String get pipNoAccessory => 'no accessory';

  @override
  String get momentumSteady => 'Steady';

  @override
  String get momentumQuiet => 'Quiet';

  @override
  String get pipMoodWarm => 'Pip is warm';

  @override
  String get pipMoodResting => 'Pip is resting';

  @override
  String get pipLineHello =>
      'Pip is here whenever you are. One small thing is plenty.';

  @override
  String pipShowedUp(int days) {
    return 'You showed up $days of the last 7 days.';
  }

  @override
  String get pipLineGlowing => 'That\'s real momentum.';

  @override
  String get pipLineWarm => 'Nicely steady.';

  @override
  String get pipLineQuiet => 'Every bit counts.';

  @override
  String get pipMomentumNote =>
      'Momentum fades slowly, one quiet day won\'t reset it.';

  @override
  String get pipWeekSemantics =>
      'Things finished per day this week. Days with none are rest days.';

  @override
  String get pipRestDay => 'rest day';

  @override
  String get pipWeekCaption => 'Tasks and sessions finished per day';

  @override
  String get pipFirstWin => 'Your first win will land here.';

  @override
  String get accCrown => 'Crown';

  @override
  String pipMoreTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more tasks',
      one: '1 more task',
    );
    return '$_temp0';
  }

  @override
  String pipMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more days',
      one: '1 more day',
    );
    return '$_temp0';
  }

  @override
  String get pipFinishGoal => 'Finish a goal';

  @override
  String pipUnlockedToast(String item) {
    return 'New for Pip: $item. Tap Pip\'s wardrobe to wear it.';
  }

  @override
  String get pipToggleWear => 'Tap to wear or take off';

  @override
  String pipMoreSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more sessions',
      one: '1 more session',
    );
    return '$_temp0';
  }

  @override
  String get focusFree => 'Free focus';

  @override
  String get focusBreak => 'Break';

  @override
  String get focusLongBreak => 'Long break';

  @override
  String get focusReady => 'Ready';

  @override
  String get focusOnBreak => 'On a break';

  @override
  String focusOfTotal(String total) {
    return 'of $total';
  }

  @override
  String get focusHardModeSoon => 'Hard mode · coming soon';

  @override
  String focusMinusMinutes(int minutes) {
    return '−$minutes min';
  }

  @override
  String get focusStartNext => 'Start next focus';

  @override
  String get focusEndBreak => 'End break';

  @override
  String get focusDoneTitle => 'Session done. Nice work.';

  @override
  String get focusEarlyTitle => 'Session ended. It still counts.';

  @override
  String focusFocusedFor(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'You focused for $_temp0.';
  }

  @override
  String focusFocusedForTask(int minutes, String task) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'You focused for $_temp0 on $task.';
  }

  @override
  String get focusMarkDone => 'Mark task done';

  @override
  String get focusKeepGoing => 'Keep going';

  @override
  String get focusLogWin => 'Log a win';

  @override
  String get focusWinLogged => 'Win logged. Pip saw that.';

  @override
  String get focusWinTitle => 'What got done?';

  @override
  String get focusWinHint => 'Drafted section 2';

  @override
  String get focusTaskDone => 'Task done. Pip is proud of you.';

  @override
  String get focusSessionOverToast => 'Time! Session done, take a breather.';

  @override
  String get focusBreakOverToast => 'Break\'s over. Ready when you are.';

  @override
  String get focusCheerIdle1 =>
      'Pick a length and press play. Pip will keep time.';

  @override
  String get focusCheerIdle2 =>
      'One small step is enough to start. Pip is right here.';

  @override
  String get focusCheerStart1 =>
      'The first minutes are the hardest, and you already started.';

  @override
  String get focusCheerStart2 =>
      'Just the next small step. Nothing else matters right now.';

  @override
  String get focusCheerMiddle1 => 'Nice rhythm. Keep it simple.';

  @override
  String get focusCheerMiddle2 =>
      'You are doing the thing. Pip is cheering quietly.';

  @override
  String get focusCheerPastHalf1 =>
      'You\'re past halfway. Keep going, the first draft just needs to exist.';

  @override
  String get focusCheerPastHalf2 => 'More than half done. Steady wins this.';

  @override
  String get focusCheerNearEnd1 =>
      'Almost there. Finish the sentence you are on.';

  @override
  String get focusCheerNearEnd2 => 'A few minutes left. Land it gently.';

  @override
  String get focusCheerPaused1 => 'Paused. Take a breath, Pip will wait.';

  @override
  String get focusCheerPaused2 =>
      'Little pauses are fine. Come back when you are ready.';

  @override
  String get focusCheerBreak1 =>
      'Break time. Stand up, stretch, drink some water.';

  @override
  String get focusCheerBreak2 =>
      'Rest is part of the work. Look at something far away.';

  @override
  String get reviewBannerTitle => 'Ready for a one-minute look back?';

  @override
  String get reviewBannerAction => 'Start';

  @override
  String get reviewDoneTitle => 'What got done?';

  @override
  String get reviewDoneHint => 'Tick anything you finished. Pip counts it all.';

  @override
  String get reviewDoneEmpty =>
      'Nothing was waiting on today. Lovely and light.';

  @override
  String get reviewMoveTitle => 'What moves on?';

  @override
  String get reviewMoveHint => 'Give each one a gentle new spot.';

  @override
  String get reviewMoveEmpty => 'Nothing left to move. You are clear.';

  @override
  String get reviewLater => 'Later this week';

  @override
  String get reviewKeepToday => 'Keep today';

  @override
  String get reviewTomorrowAnyway => 'Tomorrow anyway';

  @override
  String get reviewDrop => 'Drop';

  @override
  String get reviewDropped => 'Dropped.';

  @override
  String get reviewDeadlineNote =>
      'This one is due today. Moving it is fine, just your call.';

  @override
  String get reviewRepeatsNote => 'Repeats on its own, so it stays put.';

  @override
  String get reviewWinTitle => 'One win';

  @override
  String get reviewWinHint => 'Big or tiny. What are you glad about today?';

  @override
  String get reviewWinField => 'Today I...';

  @override
  String get reviewSave => 'Save and finish';

  @override
  String get reviewFinishTitle => 'Day wrapped';

  @override
  String get reviewPraise1 => 'You showed up today. That is the whole trick.';

  @override
  String get reviewPraise2 => 'A good day to be you. Sleep well.';

  @override
  String get reviewPraise3 => 'Small steps still count. Nice work today.';

  @override
  String get reviewPraise4 => 'Look at you, closing the day with care.';

  @override
  String get reviewPraise5 => 'Whatever got done, I am proud of you.';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsSubtitle => 'Near and far. Every small step counts.';

  @override
  String get goalsNewGoal => 'New goal';

  @override
  String get goalsEditGoal => 'Edit goal';

  @override
  String get goalsEmptyTitle => 'No goals yet';

  @override
  String get goalsEmptyBody =>
      'Pick one thing you would love to move this month. Pip will cheer.';

  @override
  String get goalsEmptyAction => 'Add a goal';

  @override
  String get goalsHorizonWeek => 'This week';

  @override
  String get goalsHorizonMonth => 'This month';

  @override
  String get goalsHorizonQuarter => 'This quarter';

  @override
  String get goalsHorizonYear => 'This year';

  @override
  String get goalsHorizonShortWeek => 'Week';

  @override
  String get goalsHorizonShortMonth => 'Month';

  @override
  String get goalsHorizonShortQuarter => 'Quarter';

  @override
  String get goalsHorizonShortYear => 'Year';

  @override
  String get goalsStatusActive => 'Active';

  @override
  String get goalsStatusPaused => 'Paused';

  @override
  String get goalsStatusDone => 'Done';

  @override
  String get goalsCloseToDone => 'Almost there';

  @override
  String get goalsCompleted => 'Completed';

  @override
  String get goalsResting => 'Resting';

  @override
  String goalsOfTarget(int current, int target) {
    return '$current of $target';
  }

  @override
  String goalsOfTargetUnit(int current, int target, String unit) {
    return '$current of $target $unit';
  }

  @override
  String goalsProgressLine(String summary, int percent) {
    return '$summary · $percent%';
  }

  @override
  String get goalsNoMetric => 'Add a count to see progress';

  @override
  String goalsByDate(String date) {
    return 'by $date';
  }

  @override
  String goalsDate(String month, int day) {
    return '$month $day';
  }

  @override
  String get goalsDetailTitle => 'Goal';

  @override
  String get goalsNotFound => 'This goal is not here anymore.';

  @override
  String get goalsBackToGoals => 'Back to goals';

  @override
  String get goalsAddOne => 'Add one';

  @override
  String goalsAddOneTo(String unit) {
    return 'Add one to $unit';
  }

  @override
  String get goalsEditCount => 'Edit count';

  @override
  String get goalsCountLabel => 'Count so far';

  @override
  String get goalsCountInvalid => 'A whole number from 0 works.';

  @override
  String get goalsLinkedCountHint =>
      'Counts up when you tick off a linked task.';

  @override
  String get goalsLinkedTasks => 'Linked tasks';

  @override
  String get goalsNoLinkedTasks =>
      'No tasks here yet. Link one and it will count toward this goal.';

  @override
  String get goalsLinkTask => 'Link a task';

  @override
  String get goalsPickTask => 'Which task moves this goal?';

  @override
  String get goalsNoTasksToLink => 'Every open task already has a goal.';

  @override
  String get goalsUnlink => 'Unlink';

  @override
  String get goalsTargetDateLabel => 'Target date';

  @override
  String get goalsNoTargetDate => 'Whenever it fits';

  @override
  String get goalsImportanceLabel => 'Importance';

  @override
  String goalsImportanceValue(int n) {
    return '$n of 5';
  }

  @override
  String get goalsDeleteTitle => 'Delete this goal?';

  @override
  String get goalsDeleteBody =>
      'Its tasks stay; they just will not point to a goal anymore.';

  @override
  String get goalsKeep => 'Keep it';

  @override
  String get goalsDeleted => 'Goal deleted';

  @override
  String get goalsMarkDone => 'Mark as done';

  @override
  String get goalsReopen => 'Back to active';

  @override
  String get goalsTitleLabel => 'What do you want to reach?';

  @override
  String get goalsTitleHint => 'Finish the project management course';

  @override
  String get goalsTitleRequired => 'Give it a short name and you are set.';

  @override
  String get goalsAreaLabel => 'Area';

  @override
  String get goalsCustomArea => 'Your own';

  @override
  String get goalsCustomAreaHint => 'Name your area';

  @override
  String get goalsHorizonLabel => 'Horizon';

  @override
  String get goalsMetricLabel => 'Measure it (optional)';

  @override
  String get goalsTargetLabel => 'Target';

  @override
  String get goalsTargetInvalid => 'A whole number above 0 works.';

  @override
  String get goalsUnitLabel => 'Unit';

  @override
  String get goalsUnitHint => 'lessons';

  @override
  String get goalsDefaultUnit => 'steps';

  @override
  String get goalsLinkedUnit => 'tasks';

  @override
  String get goalsCountManual => 'I count';

  @override
  String get goalsCountLinked => 'Linked tasks';

  @override
  String get goalsStatusLabel => 'Status';

  @override
  String goalsMilestoneCloseToDone(String title) {
    return 'Almost there on \"$title\". Lovely pace.';
  }

  @override
  String goalsMilestoneCompleted(String title) {
    return 'You did it: \"$title\" is complete.';
  }

  @override
  String get goalsCounted => 'Counted. Nice step.';

  @override
  String get capacityTitle => 'This week';

  @override
  String get capacitySubtitle => 'Is it realistic? Pip took a look.';

  @override
  String get capacityTabWeek => 'Week';

  @override
  String get capacityTabPriorities => 'Priorities';

  @override
  String get capacityBack => 'Back';

  @override
  String capacityHoursShort(String n) {
    return '$n h';
  }

  @override
  String capacityMinutesShort(String n) {
    return '$n min';
  }

  @override
  String capacityTotals(String free, String planned) {
    return '$free free · $planned planned';
  }

  @override
  String get capacityVerdictFits => 'It fits, with room to breathe.';

  @override
  String get capacityVerdictTight =>
      'Tight, but doable. Worth a look at what can wait.';

  @override
  String capacityVerdictOver(String over) {
    return 'Overbooked by $over. Let\'s move a few things, no stress.';
  }

  @override
  String get capacityStateFits => 'Fits';

  @override
  String get capacityStateTight => 'Tight';

  @override
  String get capacityStateOver => 'Overbooked';

  @override
  String get capacityDayPacked => 'Packed';

  @override
  String capacityDaySemantics(String day, String free, String planned) {
    return '$day: $free free, $planned planned';
  }

  @override
  String get capacityMoveTitle => 'What could move';

  @override
  String get capacityMoveIntro =>
      'Lowest cost first. Nothing here is due this week.';

  @override
  String get capacityMoveOne => 'Move to next week';

  @override
  String get capacityMoveAll => 'Move all suggested';

  @override
  String get capacityMovedOne => 'Moved to next week. One less thing now.';

  @override
  String capacityMovedMany(int count) {
    return 'Moved $count to next week. Breathe.';
  }

  @override
  String get capacityReasonNoDeadline => 'No deadline, so next week works.';

  @override
  String capacityReasonDue(String day) {
    return 'Not due until $day.';
  }

  @override
  String capacitySlack(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days of slack',
      one: '1 day of slack',
      zero: 'Due right after this week',
    );
    return '$_temp0';
  }

  @override
  String get capacityNothingToMove => 'Nothing needs to move. Nicely done.';

  @override
  String get capacityPrioTitle => 'What matters most';

  @override
  String get capacityPrioIntro =>
      'Pip ranks by deadline, goal and effort. Drag one up and Pip remembers.';

  @override
  String get capacityPrioEmpty => 'Nothing open. Enjoy the quiet.';

  @override
  String capacityRank(int rank) {
    return '#$rank';
  }

  @override
  String get capacityReasonPinnedTop => 'You pinned this to the top';

  @override
  String get capacityReasonOverdue => 'Past its date, so it comes first';

  @override
  String get capacityReasonDueSoon => 'Due soon';

  @override
  String get capacityReasonMarkedHigh => 'You marked it high';

  @override
  String get capacityReasonGoalMatters => 'Matters to a goal you care about';

  @override
  String get capacityReasonGoalStalled => 'Its goal hasn\'t moved in a while';

  @override
  String get capacityReasonGoalMoving => 'Its goal is on a roll';

  @override
  String get capacityReasonQuickWin => 'A quick win';

  @override
  String get capacityReasonSteady => 'Steady, no rush';

  @override
  String get capacityPinTop => 'Top';

  @override
  String get capacityPinHigh => 'High';

  @override
  String get capacityPinNormal => 'Normal';

  @override
  String get capacityPinLow => 'Low';

  @override
  String get capacityPinTitle => 'How much does this matter?';

  @override
  String capacityPinLabel(String pin) {
    return 'Priority: $pin';
  }

  @override
  String get capacityDragHandle => 'Drag to reorder';

  @override
  String get capacityRemembered => 'Noted. Pip will remember that.';

  @override
  String get capacityWeightsTitle => 'Weights';

  @override
  String get capacityWeightsHint =>
      'Advanced. Tune how Pip ranks things while we\'re in beta.';

  @override
  String get capacityWeightUrgency => 'Deadline';

  @override
  String get capacityWeightImportance => 'Goal importance';

  @override
  String get capacityWeightPriority => 'Your priority';

  @override
  String get capacityWeightQuickWin => 'Quick wins';

  @override
  String get capacityWeightsReset => 'Reset to defaults';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String todayMarkOpen(String title) {
    return 'Mark $title as open';
  }

  @override
  String todayComplete(String title) {
    return 'Complete $title';
  }

  @override
  String get planReplanTitle => 'Pip\'s draft for the week';

  @override
  String get planReplanPlacedLabel => 'Where things go';

  @override
  String get planReplanUnplacedLabel => 'What didn\'t fit';

  @override
  String get planReplanNothing =>
      'Nothing to move. Your week already looks settled.';

  @override
  String get planReplanPast => 'This week has passed. Pick today or later.';

  @override
  String planReplanKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things you placed yourself stay put.',
      one: 'One thing you placed yourself stays put.',
    );
    return '$_temp0';
  }

  @override
  String get planApply => 'Apply';

  @override
  String get planNotNow => 'Not now';

  @override
  String planApplied(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Done. $n things have a spot now.',
      one: 'Done. One thing has a spot now.',
      zero: 'All set, nothing needed moving.',
    );
    return '$_temp0';
  }

  @override
  String planScheduledAt(String when, String reason) {
    return '$when · $reason';
  }

  @override
  String planNotScheduled(String reason) {
    return 'No spot yet: $reason';
  }

  @override
  String get planNothingToSchedule => 'this one is already done';

  @override
  String get planNoRoomThisWeek => 'no free gap before the end of the week';

  @override
  String planHoursShort(String hours) {
    return '$hours h';
  }

  @override
  String planCapacityFull(String amount) {
    return 'A full week: over by $amount. Pip can help trim it.';
  }

  @override
  String planCapacityNothing(String free) {
    return '$free free · nothing planned yet';
  }

  @override
  String planCapacityLine(String free, String planned) {
    return '$free free · $planned planned';
  }

  @override
  String planDurationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String planDurationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String planSummaryHead(String free, String demand) {
    return 'You have $free free and $demand of plans.';
  }

  @override
  String planSummaryFits(String head) {
    return '$head It fits, with room to breathe.';
  }

  @override
  String planSummaryLighter(String head) {
    return '$head A lighter week might help.';
  }

  @override
  String planSummaryDefer(String head, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things',
      one: 'One thing',
    );
    return '$head $_temp0 could move to next week.';
  }

  @override
  String get planWordToday => 'today';

  @override
  String get planWordTomorrow => 'tomorrow';

  @override
  String get planDeadlineToday => 'today\'s deadline';

  @override
  String get planDeadlineTomorrow => 'tomorrow\'s deadline';

  @override
  String planDeadlineOn(String day) {
    return 'the $day deadline';
  }

  @override
  String get planReasonPlacedByYou => 'you placed this here';

  @override
  String planReasonDue(String when) {
    return 'due $when';
  }

  @override
  String planReasonPartOf(String title) {
    return 'part of $title';
  }

  @override
  String get planReasonFocusWindow => 'your focus window';

  @override
  String planReasonChunkFirst(int minutes, int total) {
    return 'first $minutes of $total min';
  }

  @override
  String planReasonChunkNext(int minutes, int total) {
    return 'next $minutes of $total min';
  }

  @override
  String planReasonChunkLast(int minutes, int total) {
    return 'last $minutes of $total min';
  }

  @override
  String planReasonEarliestGap(int minutes) {
    return 'earliest free $minutes-minute gap';
  }

  @override
  String planReasonEarliestGapBefore(int minutes, String deadline) {
    return 'earliest free $minutes-minute gap before $deadline';
  }

  @override
  String get planReasonDatePassed =>
      'the due date has passed, want to pick a new one?';

  @override
  String get planByThisWeek => 'this week';

  @override
  String planByBefore(String when) {
    return 'before $when';
  }

  @override
  String planReasonFocusFull(String by) {
    return 'focus blocks are full $by';
  }

  @override
  String planReasonOnlyFit(int fit, int need, String by) {
    return 'only $fit of $need min fit $by';
  }

  @override
  String planReasonNoSlot(int minutes, String by) {
    return 'no free $minutes-minute slot $by';
  }

  @override
  String get goalsMetricKindLabel => 'How it counts';

  @override
  String get goalsMetricNone => 'No count';

  @override
  String get goalsMetricFinite => 'Total';

  @override
  String get goalsMetricPerWeek => 'Per week';

  @override
  String get goalsMetricPerMonth => 'Per month';

  @override
  String get goalsQuotaLabel => 'How many';

  @override
  String get goalsRecurringHintWeek =>
      'Starts fresh every week. Your +1 taps and linked tasks both count.';

  @override
  String get goalsRecurringHintMonth =>
      'Starts fresh every month. Your +1 taps and linked tasks both count.';

  @override
  String get goalsDefaultRecurringUnit => 'times';

  @override
  String goalsThisWeek(int current, int target, String unit) {
    return '$current of $target $unit this week';
  }

  @override
  String goalsThisMonth(int current, int target, String unit) {
    return '$current of $target $unit this month';
  }

  @override
  String get goalsQuotaHitWeek => 'Done for the week';

  @override
  String get goalsQuotaHitMonth => 'Done for the month';

  @override
  String get goalsUndoTick => 'Take one back';

  @override
  String get goalsTickUndone => 'Took one back.';

  @override
  String get goalsRecurringCountHint => 'Ticked linked tasks count here too.';

  @override
  String get goalsTrendWeeks => 'Last 8 weeks';

  @override
  String get goalsTrendMonths => 'Last 8 months';

  @override
  String goalsTrendSummary(int hit, int tracked) {
    return 'Reached the quota in $hit of $tracked.';
  }

  @override
  String get goalsTrendQuietNote =>
      'Quiet stretches are just data. Nothing resets.';

  @override
  String get goalsTrendBefore => 'Before this goal';

  @override
  String goalsMilestoneMetricHit(String title) {
    return '\"$title\": quota reached. That\'s the rhythm.';
  }

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get highlightsSubtitle => 'Every goal at a glance.';

  @override
  String get highlightsGroupCompleted => 'Completed';

  @override
  String get highlightsGroupCloseToDone => 'Close to done';

  @override
  String get highlightsGroupOnTrack => 'On track';

  @override
  String get highlightsGroupStalled => 'Waiting for you';

  @override
  String highlightsStalledNote(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quiet for $days days',
      one: 'Quiet for a day',
    );
    return '$_temp0. One small step wakes it up.';
  }

  @override
  String get highlightsEmptyTitle => 'Nothing to highlight yet';

  @override
  String get highlightsEmptyBody =>
      'Add a goal and Pip will keep the scoreboard.';

  @override
  String get recapTitleThisWeek => 'Your week with Pip';

  @override
  String get recapTitleLastWeek => 'Last week with Pip';

  @override
  String recapRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String recapLeadGoalCompleted(String title) {
    return 'You finished \"$title\". That\'s a big one.';
  }

  @override
  String recapLeadMetricHit(String title, int count, int quota, String unit) {
    return '\"$title\": $count of $quota $unit. Right on rhythm.';
  }

  @override
  String recapLeadWin(String win) {
    return 'Best moment: $win';
  }

  @override
  String recapLeadTasksDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things done',
      one: 'One thing done',
    );
    return '$_temp0. It adds up.';
  }

  @override
  String get recapLeadQuiet => 'A quiet week. Rest counts too.';

  @override
  String get recapStatDone => 'Tasks done';

  @override
  String get recapStatMoved => 'Goals moved';

  @override
  String get recapStatHit => 'Quotas hit';

  @override
  String get recapStatRolled => 'Moved on';

  @override
  String get recapWins => 'Wins you logged';

  @override
  String recapRolledOverLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count tasks moved to another day. That\'s planning, and it counts.',
      one: 'One task moved to another day. That\'s planning, and it counts.',
      zero: 'Everything stayed on its day.',
    );
    return '$_temp0';
  }

  @override
  String get recapShare => 'Share';

  @override
  String recapShareHeader(String range) {
    return 'My week with Pip ($range)';
  }

  @override
  String recapShareWins(String list) {
    return 'Wins: $list';
  }

  @override
  String recapShareHits(String list) {
    return 'Quotas hit: $list';
  }

  @override
  String recapShareMoved(String list) {
    return 'Goals that moved: $list';
  }

  @override
  String recapShareDone(int count) {
    return 'Tasks done: $count';
  }

  @override
  String get recapShareFooter => 'Sent from Grind';
}
