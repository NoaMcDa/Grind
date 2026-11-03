import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// Bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// Bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// Bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get tabFocus;

  /// Bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Pip'**
  String get tabPip;

  /// Bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get tabAsk;

  /// Ask screen title
  ///
  /// In en, this message translates to:
  /// **'Ask Pip'**
  String get askTitle;

  /// Pill shown when the cloud assistant is on
  ///
  /// In en, this message translates to:
  /// **'Cloud assistant'**
  String get cloudAssistant;

  /// Pip reply introducing a parsed task
  ///
  /// In en, this message translates to:
  /// **'Got it! Here\'s the task:'**
  String get askGotIt;

  /// Confirmation that a task was added
  ///
  /// In en, this message translates to:
  /// **'Added to {day}'**
  String addedToDay(String day);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Button accepting Pip's suggestion
  ///
  /// In en, this message translates to:
  /// **'Yes, plan it'**
  String get yesPlanIt;

  /// Button for a smaller suggestion
  ///
  /// In en, this message translates to:
  /// **'Just one block'**
  String get justOneBlock;

  /// Quick prompt chip
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get quickPlanMyDay;

  /// Quick prompt chip
  ///
  /// In en, this message translates to:
  /// **'Move gym to evening'**
  String get quickMoveGym;

  /// Composer placeholder
  ///
  /// In en, this message translates to:
  /// **'Type or speak a task…'**
  String get composerHint;

  /// Tooltip of the microphone button
  ///
  /// In en, this message translates to:
  /// **'Speak a task'**
  String get speakATask;

  /// Send button semantics
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Focus screen header
  ///
  /// In en, this message translates to:
  /// **'Focus {current} of {total}'**
  String focusProgress(int current, int total);

  /// Hard mode pill
  ///
  /// In en, this message translates to:
  /// **'Hard mode on · {count, plural, =1{1 app shielded} other{{count} apps shielded}}'**
  String hardModeOn(int count);

  /// Timer state
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// Timer state
  ///
  /// In en, this message translates to:
  /// **'Focusing'**
  String get focusing;

  /// Button adding minutes to the timer
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String plusMinutes(int minutes);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Session dots semantics
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sessions done'**
  String sessionsDone(int done, int total);

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Lock screen preview'**
  String get lockScreenPreview;

  /// Preview caption
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get liveActivity;

  /// Prefix before Pip's line
  ///
  /// In en, this message translates to:
  /// **'Pip:'**
  String get pipSays;

  /// Pip screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Your cheering squad of one'**
  String get pipCheeringSquad;

  /// Hero caption
  ///
  /// In en, this message translates to:
  /// **'Pip is glowing'**
  String get pipGlowing;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Momentum'**
  String get sectionMomentum;

  /// Momentum level
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get momentumStrong;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get sectionThisWeek;

  /// Chart semantics
  ///
  /// In en, this message translates to:
  /// **'Focus minutes per day this week. Wednesday was a rest day.'**
  String get weeklyChartSemantics;

  /// Chart caption
  ///
  /// In en, this message translates to:
  /// **'Focus minutes per day'**
  String get focusMinutesPerDay;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Wins you logged'**
  String get sectionWins;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Unlocks'**
  String get sectionUnlocks;

  /// Cosmetic
  ///
  /// In en, this message translates to:
  /// **'Scarf'**
  String get accScarf;

  /// Cosmetic
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get accSunglasses;

  /// Cosmetic
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get accPartyHat;

  /// Cosmetic
  ///
  /// In en, this message translates to:
  /// **'Rain boots'**
  String get accRainBoots;

  /// Caption
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Caption
  ///
  /// In en, this message translates to:
  /// **'Wearing'**
  String get wearing;

  /// Caption
  ///
  /// In en, this message translates to:
  /// **'Tap to wear'**
  String get tapToWear;

  /// Pip avatar semantics
  ///
  /// In en, this message translates to:
  /// **'wearing: {item}'**
  String pipWearing(String item);

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get sectionEnergy;

  /// Energy tag
  ///
  /// In en, this message translates to:
  /// **'Deep focus'**
  String get energyDeep;

  /// Energy tag
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get energyLight;

  /// Plan header pill
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String doneOfTotal(int done, int total);

  /// Plan card title
  ///
  /// In en, this message translates to:
  /// **'Your day, drafted'**
  String get planDrafted;

  /// Plan card body
  ///
  /// In en, this message translates to:
  /// **'Pip arranged {tasks} tasks around {classes} classes. Drag to tweak.'**
  String planArranged(int tasks, int classes);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Re-plan with Pip'**
  String get rePlanWithPip;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// Label on calendar events
  ///
  /// In en, this message translates to:
  /// **'From calendar'**
  String get fromCalendar;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get startFocus;

  /// Today greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get addATask;

  /// Reminder card label
  ///
  /// In en, this message translates to:
  /// **'Reminder · now'**
  String get reminderNow;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Snooze 15'**
  String get snooze15;

  /// Toast title
  ///
  /// In en, this message translates to:
  /// **'Nice start!'**
  String get niceStart;

  /// Toast body
  ///
  /// In en, this message translates to:
  /// **'Pip is doing a little happy dance.'**
  String get pipHappyDance;

  /// Snooze toast title
  ///
  /// In en, this message translates to:
  /// **'See you at {time}'**
  String seeYouAt(String time);

  /// Snooze toast body
  ///
  /// In en, this message translates to:
  /// **'Need a bit more time? Pip can offer to move it instead.'**
  String get snoozeAgainHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Pip avatar semantics
  ///
  /// In en, this message translates to:
  /// **'Pip, your companion'**
  String get pipSemanticLabel;

  /// Meter semantics
  ///
  /// In en, this message translates to:
  /// **'Momentum'**
  String get momentumSemantic;

  /// Skeleton semantics
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Bottom sheet handle semantics
  ///
  /// In en, this message translates to:
  /// **'Drag handle'**
  String get dragHandle;

  /// Toast dismiss
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyDefaultTitle;

  /// Empty state body
  ///
  /// In en, this message translates to:
  /// **'Whenever you\'re ready, Pip is here.'**
  String get emptyDefaultBody;

  /// Back button / semantics
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Connect button
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get commonConnect;

  /// Connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get commonConnected;

  /// Week start option
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get commonSunday;

  /// Week start option
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get commonMonday;

  /// Relative day name
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// Relative day name
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// Calendar provider name
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get commonGoogleCalendar;

  /// Calendar provider name
  ///
  /// In en, this message translates to:
  /// **'Apple Calendar'**
  String get commonAppleCalendar;

  /// Language name in its own language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonLanguageEnglish;

  /// Language name in its own language
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get commonLanguageHebrew;

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String commonMinutes(int minutes);

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get commonWeekdayShortMon;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get commonWeekdayShortTue;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get commonWeekdayShortWed;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get commonWeekdayShortThu;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get commonWeekdayShortFri;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get commonWeekdayShortSat;

  /// Short weekday name (list use)
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get commonWeekdayShortSun;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get commonWeekdayFullMon;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get commonWeekdayFullTue;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get commonWeekdayFullWed;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get commonWeekdayFullThu;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get commonWeekdayFullFri;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get commonWeekdayFullSat;

  /// Full weekday name
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get commonWeekdayFullSun;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get commonWeekdayLetterMon;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get commonWeekdayLetterTue;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get commonWeekdayLetterWed;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get commonWeekdayLetterThu;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get commonWeekdayLetterFri;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get commonWeekdayLetterSat;

  /// One-letter weekday toggle
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get commonWeekdayLetterSun;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get commonMonthShortJan;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get commonMonthShortFeb;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get commonMonthShortMar;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get commonMonthShortApr;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get commonMonthShortMay;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get commonMonthShortJun;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get commonMonthShortJul;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get commonMonthShortAug;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get commonMonthShortSep;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get commonMonthShortOct;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get commonMonthShortNov;

  /// Short month name
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get commonMonthShortDec;

  /// Short date such as "Thu, Oct 29"; weekday and month are already localised
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {month} {day}'**
  String commonDateShort(String weekday, String month, int day);

  /// Task form title (create)
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNewTask;

  /// Task form title (edit)
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get tasksEditTask;

  /// Task title field label
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get tasksTitleLabel;

  /// Validation hint when the title is empty
  ///
  /// In en, this message translates to:
  /// **'Give it a short name and you are set.'**
  String get tasksTitleRequired;

  /// Due date field label
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get tasksDueLabel;

  /// Date picker button
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get tasksPickDate;

  /// Chip for no due date
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get tasksNoDate;

  /// Due time label
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get tasksDueTime;

  /// Reminder time label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get tasksReminderTime;

  /// Button to add a time
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get tasksAddTime;

  /// Estimate field label
  ///
  /// In en, this message translates to:
  /// **'How long?'**
  String get tasksEstimateLabel;

  /// Custom estimate chip
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get tasksCustom;

  /// Custom estimate field label
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get tasksCustomMinutes;

  /// First action field label
  ///
  /// In en, this message translates to:
  /// **'First action'**
  String get tasksFirstActionLabel;

  /// If-then example hint
  ///
  /// In en, this message translates to:
  /// **'If it\'s 7:00, then open the thesis file'**
  String get tasksFirstActionHint;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tasksNotesLabel;

  /// Task detail screen title
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get tasksDetailTitle;

  /// Shown when a task id no longer exists
  ///
  /// In en, this message translates to:
  /// **'This task is not here anymore.'**
  String get tasksNotFound;

  /// Button on the not-found screen
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get tasksBackToToday;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get tasksComplete;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark as open'**
  String get tasksReopen;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get tasksDeleteTitle;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'You can undo it right after.'**
  String get tasksDeleteBody;

  /// Dialog button that cancels deletion
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get tasksKeep;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get tasksDeleted;

  /// Toast after completing a task
  ///
  /// In en, this message translates to:
  /// **'Nicely done'**
  String get tasksMarkedDone;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get tasksEmptyTitle;

  /// Empty state body
  ///
  /// In en, this message translates to:
  /// **'Add one small thing and Pip will remind you.'**
  String get tasksEmptyBody;

  /// Today header pill
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} today'**
  String tasksDoneOfToday(int done, int total);

  /// Smart-snooze button
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get remindersTonight;

  /// Smart-snooze button
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get remindersPickATime;

  /// Notification headline offering to move a task
  ///
  /// In en, this message translates to:
  /// **'Want to move this instead?'**
  String get remindersMoveOffer;

  /// Notification line under the move offer
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" can have a calmer moment.'**
  String remindersMoveLine(String title);

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'25 minutes is enough to start.'**
  String get remindersLine01;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Small steps count.'**
  String get remindersLine02;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Just the first step. Pip has the rest.'**
  String get remindersLine03;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Starting is the hard part, and you are here.'**
  String get remindersLine04;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Five minutes in, it gets easier.'**
  String get remindersLine05;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'One page is a fine start.'**
  String get remindersLine06;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Pip has the timer ready.'**
  String get remindersLine07;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'No need to finish, just begin.'**
  String get remindersLine08;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'You picked this step for a reason.'**
  String get remindersLine09;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Little by little adds up.'**
  String get remindersLine10;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Open it and see how it feels.'**
  String get remindersLine11;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'A quick start beats a perfect plan.'**
  String get remindersLine12;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Pip is cheering for you.'**
  String get remindersLine13;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Ten focused minutes go a long way.'**
  String get remindersLine14;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Begin small, keep it light.'**
  String get remindersLine15;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'This moment is yours.'**
  String get remindersLine16;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Momentum starts with one move.'**
  String get remindersLine17;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Easy does it. Start where you are.'**
  String get remindersLine18;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Future you will be glad.'**
  String get remindersLine19;

  /// Encouraging second line of a reminder notification (pool of 20, rotated per task and day)
  ///
  /// In en, this message translates to:
  /// **'Ready when you are.'**
  String get remindersLine20;

  /// Repeat option
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurrenceDoesNotRepeat;

  /// Repeat option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// Repeat option
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get recurrenceWeekdays;

  /// Repeat option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// Repeat option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurrenceRepeatLabel;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'On days'**
  String get recurrenceOnDays;

  /// Field label before the interval stepper
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurrenceEveryLabel;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurrenceEndsLabel;

  /// End option
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurrenceNever;

  /// End option
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get recurrenceOnDate;

  /// Button closing the recurrence sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recurrenceDone;

  /// Stepper semantics
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get recurrenceIncrease;

  /// Stepper semantics
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get recurrenceDecrease;

  /// Interval unit
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day} other{days}}'**
  String recurrenceUnitDay(int n);

  /// Interval unit
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{week} other{weeks}}'**
  String recurrenceUnitWeek(int n);

  /// Interval unit
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{month} other{months}}'**
  String recurrenceUnitMonth(int n);

  /// Edit scope option
  ///
  /// In en, this message translates to:
  /// **'This one'**
  String get recurrenceEditThisOne;

  /// Edit scope option
  ///
  /// In en, this message translates to:
  /// **'All future'**
  String get recurrenceEditAllFuture;

  /// Edit scope sheet title
  ///
  /// In en, this message translates to:
  /// **'Change just this one?'**
  String get recurrenceEditTitle;

  /// Edit scope sheet body
  ///
  /// In en, this message translates to:
  /// **'Change this one time, or the series from here on.'**
  String get recurrenceEditHint;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every day} other{Every {n} days}}'**
  String recurrenceEveryDay(int n);

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Every weekday'**
  String get recurrenceEveryWeekday;

  /// Description with chosen weekdays, already joined into one string
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every {days}} other{Every {n} weeks on {days}}}'**
  String recurrenceEveryWeek(int n, String days);

  /// Description without weekdays
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every week} other{Every {n} weeks}}'**
  String recurrenceEveryWeekPlain(int n);

  /// Description without a day of month
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every month} other{Every {n} months}}'**
  String recurrenceEveryMonth(int n);

  /// Description with day of month; day is a pre-formatted ordinal in English (3rd)
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every month} other{Every {n} months}} on the {day}'**
  String recurrenceEveryMonthOn(int n, String day);

  /// Joins the last item of a day list
  ///
  /// In en, this message translates to:
  /// **'{head} and {last}'**
  String recurrenceListJoinLast(String head, String last);

  /// Suffix of a description, appended after a space
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurrenceUntil(String date);

  /// Suffix of a description, appended after a comma
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String recurrenceTimesCount(int count);

  /// Date shown for the end date
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String recurrenceDateLabel(int day, String month, int year);

  /// Plan title for days other than today
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get planYourDay;

  /// Plan card body
  ///
  /// In en, this message translates to:
  /// **'Pip arranged {tasks, plural, =1{1 task} other{{tasks} tasks}} around {events, plural, =1{1 event} other{{events} events}}. Long-press a task to move it.'**
  String planSubtitle(int tasks, int events);

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get planEmptyTitle;

  /// Empty state body
  ///
  /// In en, this message translates to:
  /// **'A quiet day. Add a task and Pip will find it a good spot.'**
  String get planEmptyBody;

  /// Button semantics
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get planPreviousDay;

  /// Button semantics
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get planNextDay;

  /// Button semantics
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get planPickDay;

  /// Week strip semantics
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get planWeekStripLabel;

  /// Marker on the timeline
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get planNowLabel;

  /// Day chip semantics
  ///
  /// In en, this message translates to:
  /// **'{day}, {percent}% booked'**
  String planDayLoad(String day, int percent);

  /// Label for all-day events
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get planAllDay;

  /// Source name for events created in the app
  ///
  /// In en, this message translates to:
  /// **'Grind'**
  String get planCalendarLocal;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get planCalendarLabel;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Open in calendar'**
  String get planOpenInCalendar;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Opening the calendar app is coming soon.'**
  String get planOpenInCalendarSoon;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get planMarkDone;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get planMarkOpen;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Unschedule'**
  String get planUnschedule;

  /// Toast when dropping a task onto an event
  ///
  /// In en, this message translates to:
  /// **'That slot is taken by an event.'**
  String get planCantDropHere;

  /// Welcome title
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Pip'**
  String get onboardingWelcomeTitle;

  /// Welcome body
  ///
  /// In en, this message translates to:
  /// **'Grind keeps your plans on this phone. Nothing leaves it.'**
  String get onboardingWelcomeBody;

  /// Welcome button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingWelcomeStart;

  /// Notifications step title
  ///
  /// In en, this message translates to:
  /// **'Gentle nudges, only when you want them'**
  String get onboardingNotifTitle;

  /// Rationale heading
  ///
  /// In en, this message translates to:
  /// **'Why notifications?'**
  String get onboardingNotifRationaleTitle;

  /// Rationale body
  ///
  /// In en, this message translates to:
  /// **'Reminders can only reach you if Grind may show them. I will only nudge you about things you asked me to remind you of.'**
  String get onboardingNotifRationale;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get onboardingNotifAllow;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotifNotNow;

  /// Confirmation
  ///
  /// In en, this message translates to:
  /// **'Notifications are on. Thank you!'**
  String get onboardingNotifGranted;

  /// Message after permission was declined
  ///
  /// In en, this message translates to:
  /// **'No problem. Grind works fine without notifications. You can switch them on later in Settings.'**
  String get onboardingNotifDenied;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Calendar step title
  ///
  /// In en, this message translates to:
  /// **'Bring your calendar along'**
  String get onboardingCalTitle;

  /// Rationale
  ///
  /// In en, this message translates to:
  /// **'Connecting a calendar lets me plan around meetings you already have. Events are read on this device and stay here.'**
  String get onboardingCalRationale;

  /// Connection error message, rewritten without "again"
  ///
  /// In en, this message translates to:
  /// **'That did not work this time. You can retry, or skip it for now.'**
  String get onboardingCalFailed;

  /// Reassurance
  ///
  /// In en, this message translates to:
  /// **'You can always connect one later in Settings.'**
  String get onboardingCalLater;

  /// Hours step title
  ///
  /// In en, this message translates to:
  /// **'When do you like to work?'**
  String get onboardingHoursTitle;

  /// Hours step body
  ///
  /// In en, this message translates to:
  /// **'I will plan around these hours. Switch a day off to keep it free.'**
  String get onboardingHoursBody;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get onboardingWeekStartLabel;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguageLabel;

  /// Done title
  ///
  /// In en, this message translates to:
  /// **'You\'re set.'**
  String get onboardingDoneTitle;

  /// Done body
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device. You can change any of this in Settings, whenever you like.'**
  String get onboardingDoneBody;

  /// Final button
  ///
  /// In en, this message translates to:
  /// **'Take me to Today'**
  String get onboardingDoneButton;

  /// Toggle label
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get onboardingDayOff;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get onboardingStartTime;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get onboardingEndTime;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get settingsCalendars;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// Sub-list label
  ///
  /// In en, this message translates to:
  /// **'Calendars to use'**
  String get settingsCalendarsToUse;

  /// Connection error, rewritten without "again"
  ///
  /// In en, this message translates to:
  /// **'That did not work this time. Whenever you like, give it another go.'**
  String get settingsConnectFailed;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settingsNotifPermission;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotifPermissionOn;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Off. Grind keeps working; turn them on if you want reminders.'**
  String get settingsNotifPermissionOff;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Remind me before'**
  String get settingsLeadTime;

  /// Lead time option 0
  ///
  /// In en, this message translates to:
  /// **'At the time'**
  String get settingsLeadAtTime;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get settingsQuietHours;

  /// Row hint
  ///
  /// In en, this message translates to:
  /// **'No notifications in this window.'**
  String get settingsQuietHoursHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get settingsQuietFrom;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get settingsQuietTo;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Morning prompt'**
  String get settingsMorningPrompt;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Evening prompt'**
  String get settingsEveningPrompt;

  /// Row hint
  ///
  /// In en, this message translates to:
  /// **'A short hello from Pip to plan or wrap up.'**
  String get settingsPromptsHint;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get settingsPlanning;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get settingsWorkingHours;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get settingsExportBackup;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get settingsImportBackup;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsDeleteAll;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Backup saved.'**
  String get settingsExportDone;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get settingsImportDone;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'That did not work this time. Nothing was lost.'**
  String get settingsActionFailed;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get settingsDeleteConfirmTitle;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'This removes all tasks, plans and settings from this device. It cannot be undone.'**
  String get settingsDeleteConfirmBody;

  /// Dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteConfirm;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'All data deleted.'**
  String get settingsDeleted;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get settingsLicences;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Privacy statement
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device. No account, no sign-in.'**
  String get settingsPrivacyCopy;

  /// Pill on the Pip hero card when nothing is worn
  ///
  /// In en, this message translates to:
  /// **'no accessory'**
  String get pipNoAccessory;

  /// Momentum level label
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get momentumSteady;

  /// Momentum level label
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get momentumQuiet;

  /// Pip hero title
  ///
  /// In en, this message translates to:
  /// **'Pip is warm'**
  String get pipMoodWarm;

  /// Pip hero title
  ///
  /// In en, this message translates to:
  /// **'Pip is resting'**
  String get pipMoodResting;

  /// Pip hero sentence with no activity yet
  ///
  /// In en, this message translates to:
  /// **'Pip is here whenever you are. One small thing is plenty.'**
  String get pipLineHello;

  /// Pip hero sentence, first half
  ///
  /// In en, this message translates to:
  /// **'You showed up {days} of the last 7 days.'**
  String pipShowedUp(int days);

  /// Pip hero sentence, second half when glowing
  ///
  /// In en, this message translates to:
  /// **'That\'s real momentum.'**
  String get pipLineGlowing;

  /// Pip hero sentence, second half when warm
  ///
  /// In en, this message translates to:
  /// **'Nicely steady.'**
  String get pipLineWarm;

  /// Pip hero sentence, second half when quiet
  ///
  /// In en, this message translates to:
  /// **'Every bit counts.'**
  String get pipLineQuiet;

  /// Caption under the momentum meter
  ///
  /// In en, this message translates to:
  /// **'Momentum fades slowly, one quiet day won\'t reset it.'**
  String get pipMomentumNote;

  /// Screen reader label of the week chart
  ///
  /// In en, this message translates to:
  /// **'Things finished per day this week. Days with none are rest days.'**
  String get pipWeekSemantics;

  /// Label in a week chart column with no activity
  ///
  /// In en, this message translates to:
  /// **'rest day'**
  String get pipRestDay;

  /// Caption under the week chart
  ///
  /// In en, this message translates to:
  /// **'Tasks and sessions finished per day'**
  String get pipWeekCaption;

  /// Empty state of the wins row
  ///
  /// In en, this message translates to:
  /// **'Your first win will land here.'**
  String get pipFirstWin;

  /// Caption under a locked unlock
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more session} other{{count} more sessions}}'**
  String pipMoreSessions(int count);

  /// Title of a focus session without a task
  ///
  /// In en, this message translates to:
  /// **'Free focus'**
  String get focusFree;

  /// Focus header while on a short break
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get focusBreak;

  /// Focus header while on a long break
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get focusLongBreak;

  /// Lock screen status before a session starts
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get focusReady;

  /// Lock screen status while on a break
  ///
  /// In en, this message translates to:
  /// **'On a break'**
  String get focusOnBreak;

  /// Under the timer: total session length
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String focusOfTotal(String total);

  /// Pill for the upcoming hard mode
  ///
  /// In en, this message translates to:
  /// **'Hard mode · coming soon'**
  String get focusHardModeSoon;

  /// Button removing minutes from the timer
  ///
  /// In en, this message translates to:
  /// **'−{minutes} min'**
  String focusMinusMinutes(int minutes);

  /// Main button after a break
  ///
  /// In en, this message translates to:
  /// **'Start next focus'**
  String get focusStartNext;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'End break'**
  String get focusEndBreak;

  /// End-of-session sheet title
  ///
  /// In en, this message translates to:
  /// **'Session done. Nice work.'**
  String get focusDoneTitle;

  /// End-of-session sheet title after ending early
  ///
  /// In en, this message translates to:
  /// **'Session ended. It still counts.'**
  String get focusEarlyTitle;

  /// End-of-session sheet body
  ///
  /// In en, this message translates to:
  /// **'You focused for {minutes, plural, =1{1 minute} other{{minutes} minutes}}.'**
  String focusFocusedFor(int minutes);

  /// End-of-session sheet body when the session had a task
  ///
  /// In en, this message translates to:
  /// **'You focused for {minutes, plural, =1{1 minute} other{{minutes} minutes}} on {task}.'**
  String focusFocusedForTask(int minutes, String task);

  /// End-of-session button
  ///
  /// In en, this message translates to:
  /// **'Mark task done'**
  String get focusMarkDone;

  /// End-of-session button
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get focusKeepGoing;

  /// End-of-session button
  ///
  /// In en, this message translates to:
  /// **'Log a win'**
  String get focusLogWin;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Win logged. Pip saw that.'**
  String get focusWinLogged;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Task done. Pip is proud of you.'**
  String get focusTaskDone;

  /// In-app alert when a session ends
  ///
  /// In en, this message translates to:
  /// **'Time! Session done, take a breather.'**
  String get focusSessionOverToast;

  /// In-app alert when a break ends
  ///
  /// In en, this message translates to:
  /// **'Break\'s over. Ready when you are.'**
  String get focusBreakOverToast;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Pick a length and press play. Pip will keep time.'**
  String get focusCheerIdle1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'One small step is enough to start. Pip is right here.'**
  String get focusCheerIdle2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'The first minutes are the hardest, and you already started.'**
  String get focusCheerStart1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Just the next small step. Nothing else matters right now.'**
  String get focusCheerStart2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Nice rhythm. Keep it simple.'**
  String get focusCheerMiddle1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'You are doing the thing. Pip is cheering quietly.'**
  String get focusCheerMiddle2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'You\'re past halfway. Keep going, the first draft just needs to exist.'**
  String get focusCheerPastHalf1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'More than half done. Steady wins this.'**
  String get focusCheerPastHalf2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Almost there. Finish the sentence you are on.'**
  String get focusCheerNearEnd1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'A few minutes left. Land it gently.'**
  String get focusCheerNearEnd2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Paused. Take a breath, Pip will wait.'**
  String get focusCheerPaused1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Little pauses are fine. Come back when you are ready.'**
  String get focusCheerPaused2;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Break time. Stand up, stretch, drink some water.'**
  String get focusCheerBreak1;

  /// Pip cheering line on the focus screen
  ///
  /// In en, this message translates to:
  /// **'Rest is part of the work. Look at something far away.'**
  String get focusCheerBreak2;

  /// Evening review banner on Today
  ///
  /// In en, this message translates to:
  /// **'Ready for a one-minute look back?'**
  String get reviewBannerTitle;

  /// Evening review banner button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get reviewBannerAction;

  /// Review step title
  ///
  /// In en, this message translates to:
  /// **'What got done?'**
  String get reviewDoneTitle;

  /// Review step hint
  ///
  /// In en, this message translates to:
  /// **'Tick anything you finished. Pip counts it all.'**
  String get reviewDoneHint;

  /// Review step empty state
  ///
  /// In en, this message translates to:
  /// **'Nothing was waiting on today. Lovely and light.'**
  String get reviewDoneEmpty;

  /// Review step title
  ///
  /// In en, this message translates to:
  /// **'What moves on?'**
  String get reviewMoveTitle;

  /// Review step hint
  ///
  /// In en, this message translates to:
  /// **'Give each one a gentle new spot.'**
  String get reviewMoveHint;

  /// Review step empty state
  ///
  /// In en, this message translates to:
  /// **'Nothing left to move. You are clear.'**
  String get reviewMoveEmpty;

  /// Review move option
  ///
  /// In en, this message translates to:
  /// **'Later this week'**
  String get reviewLater;

  /// Review move option
  ///
  /// In en, this message translates to:
  /// **'Keep today'**
  String get reviewKeepToday;

  /// Review move option for a task due today
  ///
  /// In en, this message translates to:
  /// **'Tomorrow anyway'**
  String get reviewTomorrowAnyway;

  /// Review move option removing a task
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get reviewDrop;

  /// Toast after dropping a task
  ///
  /// In en, this message translates to:
  /// **'Dropped.'**
  String get reviewDropped;

  /// Note on a task with a deadline today
  ///
  /// In en, this message translates to:
  /// **'This one is due today. Moving it is fine, just your call.'**
  String get reviewDeadlineNote;

  /// Note on a recurring task
  ///
  /// In en, this message translates to:
  /// **'Repeats on its own, so it stays put.'**
  String get reviewRepeatsNote;

  /// Review step title
  ///
  /// In en, this message translates to:
  /// **'One win'**
  String get reviewWinTitle;

  /// Review step hint
  ///
  /// In en, this message translates to:
  /// **'Big or tiny. What are you glad about today?'**
  String get reviewWinHint;

  /// Review win text field label
  ///
  /// In en, this message translates to:
  /// **'Today I...'**
  String get reviewWinField;

  /// Review button
  ///
  /// In en, this message translates to:
  /// **'Save and finish'**
  String get reviewSave;

  /// Review last step title
  ///
  /// In en, this message translates to:
  /// **'Day wrapped'**
  String get reviewFinishTitle;

  /// Closing line of the evening review
  ///
  /// In en, this message translates to:
  /// **'You showed up today. That is the whole trick.'**
  String get reviewPraise1;

  /// Closing line of the evening review
  ///
  /// In en, this message translates to:
  /// **'A good day to be you. Sleep well.'**
  String get reviewPraise2;

  /// Closing line of the evening review
  ///
  /// In en, this message translates to:
  /// **'Small steps still count. Nice work today.'**
  String get reviewPraise3;

  /// Closing line of the evening review
  ///
  /// In en, this message translates to:
  /// **'Look at you, closing the day with care.'**
  String get reviewPraise4;

  /// Closing line of the evening review
  ///
  /// In en, this message translates to:
  /// **'Whatever got done, I am proud of you.'**
  String get reviewPraise5;

  /// Goals screen title
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// Goals screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Near and far. Every small step counts.'**
  String get goalsSubtitle;

  /// Button and form title
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNewGoal;

  /// Form title
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsEditGoal;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get goalsEmptyTitle;

  /// Empty state body
  ///
  /// In en, this message translates to:
  /// **'Pick one thing you would love to move this month. Pip will cheer.'**
  String get goalsEmptyBody;

  /// Empty state button
  ///
  /// In en, this message translates to:
  /// **'Add a goal'**
  String get goalsEmptyAction;

  /// Goal horizon
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get goalsHorizonWeek;

  /// Goal horizon
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get goalsHorizonMonth;

  /// Goal horizon
  ///
  /// In en, this message translates to:
  /// **'This quarter'**
  String get goalsHorizonQuarter;

  /// Goal horizon
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get goalsHorizonYear;

  /// Goal horizon, short chip
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get goalsHorizonShortWeek;

  /// Goal horizon, short chip
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get goalsHorizonShortMonth;

  /// Goal horizon, short chip
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get goalsHorizonShortQuarter;

  /// Goal horizon, short chip
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get goalsHorizonShortYear;

  /// Goal status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalsStatusActive;

  /// Goal status
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get goalsStatusPaused;

  /// Goal status
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get goalsStatusDone;

  /// Goal badge
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get goalsCloseToDone;

  /// Goal badge
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalsCompleted;

  /// Goal badge for a paused goal
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get goalsResting;

  /// Goal progress without a unit
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String goalsOfTarget(int current, int target);

  /// Goal progress with a unit
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} {unit}'**
  String goalsOfTargetUnit(int current, int target, String unit);

  /// Goal progress with percent
  ///
  /// In en, this message translates to:
  /// **'{summary} · {percent}%'**
  String goalsProgressLine(String summary, int percent);

  /// Goal card without a metric
  ///
  /// In en, this message translates to:
  /// **'Add a count to see progress'**
  String get goalsNoMetric;

  /// Goal target date
  ///
  /// In en, this message translates to:
  /// **'by {date}'**
  String goalsByDate(String date);

  /// Short date without weekday
  ///
  /// In en, this message translates to:
  /// **'{month} {day}'**
  String goalsDate(String month, int day);

  /// Goal detail title
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalsDetailTitle;

  /// Goal detail when the goal does not exist
  ///
  /// In en, this message translates to:
  /// **'This goal is not here anymore.'**
  String get goalsNotFound;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Back to goals'**
  String get goalsBackToGoals;

  /// Counter button label
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get goalsAddOne;

  /// Counter button label with unit
  ///
  /// In en, this message translates to:
  /// **'Add one to {unit}'**
  String goalsAddOneTo(String unit);

  /// Button and sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit count'**
  String get goalsEditCount;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Count so far'**
  String get goalsCountLabel;

  /// Field error
  ///
  /// In en, this message translates to:
  /// **'A whole number from 0 works.'**
  String get goalsCountInvalid;

  /// Hint for a linked counter
  ///
  /// In en, this message translates to:
  /// **'Counts up when you tick off a linked task.'**
  String get goalsLinkedCountHint;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Linked tasks'**
  String get goalsLinkedTasks;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No tasks here yet. Link one and it will count toward this goal.'**
  String get goalsNoLinkedTasks;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Link a task'**
  String get goalsLinkTask;

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Which task moves this goal?'**
  String get goalsPickTask;

  /// Sheet empty state
  ///
  /// In en, this message translates to:
  /// **'Every open task already has a goal.'**
  String get goalsNoTasksToLink;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get goalsUnlink;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get goalsTargetDateLabel;

  /// Value when there is no target date
  ///
  /// In en, this message translates to:
  /// **'Whenever it fits'**
  String get goalsNoTargetDate;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get goalsImportanceLabel;

  /// Importance value
  ///
  /// In en, this message translates to:
  /// **'{n} of 5'**
  String goalsImportanceValue(int n);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get goalsDeleteTitle;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'Its tasks stay; they just will not point to a goal anymore.'**
  String get goalsDeleteBody;

  /// Dialog button
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get goalsKeep;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalsDeleted;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get goalsMarkDone;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Back to active'**
  String get goalsReopen;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'What do you want to reach?'**
  String get goalsTitleLabel;

  /// Form field hint
  ///
  /// In en, this message translates to:
  /// **'Finish the project management course'**
  String get goalsTitleHint;

  /// Form field error
  ///
  /// In en, this message translates to:
  /// **'Give it a short name and you are set.'**
  String get goalsTitleRequired;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get goalsAreaLabel;

  /// Chip for a custom area
  ///
  /// In en, this message translates to:
  /// **'Your own'**
  String get goalsCustomArea;

  /// Custom area field hint
  ///
  /// In en, this message translates to:
  /// **'Name your area'**
  String get goalsCustomAreaHint;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Horizon'**
  String get goalsHorizonLabel;

  /// Form section label
  ///
  /// In en, this message translates to:
  /// **'Measure it (optional)'**
  String get goalsMetricLabel;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalsTargetLabel;

  /// Form field error
  ///
  /// In en, this message translates to:
  /// **'A whole number above 0 works.'**
  String get goalsTargetInvalid;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get goalsUnitLabel;

  /// Form field hint
  ///
  /// In en, this message translates to:
  /// **'lessons'**
  String get goalsUnitHint;

  /// Unit used when the field is empty
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get goalsDefaultUnit;

  /// Unit used for a count of linked tasks
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get goalsLinkedUnit;

  /// Count mode
  ///
  /// In en, this message translates to:
  /// **'I count'**
  String get goalsCountManual;

  /// Count mode
  ///
  /// In en, this message translates to:
  /// **'Linked tasks'**
  String get goalsCountLinked;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get goalsStatusLabel;

  /// Toast when a goal is close to done
  ///
  /// In en, this message translates to:
  /// **'Almost there on \"{title}\". Lovely pace.'**
  String goalsMilestoneCloseToDone(String title);

  /// Toast when a goal is complete
  ///
  /// In en, this message translates to:
  /// **'You did it: \"{title}\" is complete.'**
  String goalsMilestoneCompleted(String title);

  /// Toast after adding to a goal
  ///
  /// In en, this message translates to:
  /// **'Counted. Nice step.'**
  String get goalsCounted;

  /// Greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// Greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// Task checkbox semantics
  ///
  /// In en, this message translates to:
  /// **'Mark {title} as open'**
  String todayMarkOpen(String title);

  /// Task checkbox semantics
  ///
  /// In en, this message translates to:
  /// **'Complete {title}'**
  String todayComplete(String title);

  /// Replan sheet title
  ///
  /// In en, this message translates to:
  /// **'Pip\'s draft for the week'**
  String get planReplanTitle;

  /// Replan sheet section (shown uppercase)
  ///
  /// In en, this message translates to:
  /// **'Where things go'**
  String get planReplanPlacedLabel;

  /// Replan sheet section (shown uppercase)
  ///
  /// In en, this message translates to:
  /// **'What didn\'t fit'**
  String get planReplanUnplacedLabel;

  /// Replan sheet
  ///
  /// In en, this message translates to:
  /// **'Nothing to move. Your week already looks settled.'**
  String get planReplanNothing;

  /// Replan sheet
  ///
  /// In en, this message translates to:
  /// **'This week has passed. Pick today or later.'**
  String get planReplanPast;

  /// Replan sheet
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{One thing you placed yourself stays put.} other{{n} things you placed yourself stay put.}}'**
  String planReplanKept(int n);

  /// Replan sheet button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get planApply;

  /// Replan sheet button
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get planNotNow;

  /// Toast after applying a plan
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{All set, nothing needed moving.} =1{Done. One thing has a spot now.} other{Done. {n} things have a spot now.}}'**
  String planApplied(int n);

  /// Toast after scheduling one task
  ///
  /// In en, this message translates to:
  /// **'{when} · {reason}'**
  String planScheduledAt(String when, String reason);

  /// Toast when a task did not fit
  ///
  /// In en, this message translates to:
  /// **'No spot yet: {reason}'**
  String planNotScheduled(String reason);

  /// Reason, lowercase fragment
  ///
  /// In en, this message translates to:
  /// **'this one is already done'**
  String get planNothingToSchedule;

  /// Reason, lowercase fragment
  ///
  /// In en, this message translates to:
  /// **'no free gap before the end of the week'**
  String get planNoRoomThisWeek;

  /// Short duration in hours; hours is a number such as 1.5
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String planHoursShort(String hours);

  /// Plan header capacity line
  ///
  /// In en, this message translates to:
  /// **'A full week: over by {amount}. Pip can help trim it.'**
  String planCapacityFull(String amount);

  /// Plan header capacity line
  ///
  /// In en, this message translates to:
  /// **'{free} free · nothing planned yet'**
  String planCapacityNothing(String free);

  /// Plan header capacity line
  ///
  /// In en, this message translates to:
  /// **'{free} free · {planned} planned'**
  String planCapacityLine(String free, String planned);

  /// Long duration
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour} other{{n} hours}}'**
  String planDurationHours(int n);

  /// Long duration
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute} other{{n} minutes}}'**
  String planDurationMinutes(int n);

  /// Replan sheet summary opening
  ///
  /// In en, this message translates to:
  /// **'You have {free} free and {demand} of plans.'**
  String planSummaryHead(String free, String demand);

  /// Replan sheet summary
  ///
  /// In en, this message translates to:
  /// **'{head} It fits, with room to breathe.'**
  String planSummaryFits(String head);

  /// Replan sheet summary
  ///
  /// In en, this message translates to:
  /// **'{head} A lighter week might help.'**
  String planSummaryLighter(String head);

  /// Replan sheet summary
  ///
  /// In en, this message translates to:
  /// **'{head} {n, plural, =1{One thing} other{{n} things}} could move to next week.'**
  String planSummaryDefer(String head, int n);

  /// Day word in a reason
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get planWordToday;

  /// Day word in a reason
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get planWordTomorrow;

  /// Deadline phrase in a reason
  ///
  /// In en, this message translates to:
  /// **'today\'s deadline'**
  String get planDeadlineToday;

  /// Deadline phrase in a reason
  ///
  /// In en, this message translates to:
  /// **'tomorrow\'s deadline'**
  String get planDeadlineTomorrow;

  /// Deadline phrase in a reason
  ///
  /// In en, this message translates to:
  /// **'the {day} deadline'**
  String planDeadlineOn(String day);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'you placed this here'**
  String get planReasonPlacedByYou;

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'due {when}'**
  String planReasonDue(String when);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'part of {title}'**
  String planReasonPartOf(String title);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'your focus window'**
  String get planReasonFocusWindow;

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'first {minutes} of {total} min'**
  String planReasonChunkFirst(int minutes, int total);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'next {minutes} of {total} min'**
  String planReasonChunkNext(int minutes, int total);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'last {minutes} of {total} min'**
  String planReasonChunkLast(int minutes, int total);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'earliest free {minutes}-minute gap'**
  String planReasonEarliestGap(int minutes);

  /// Placement reason
  ///
  /// In en, this message translates to:
  /// **'earliest free {minutes}-minute gap before {deadline}'**
  String planReasonEarliestGapBefore(int minutes, String deadline);

  /// Unplaced reason
  ///
  /// In en, this message translates to:
  /// **'the due date has passed, want to pick a new one?'**
  String get planReasonDatePassed;

  /// Reason fragment
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get planByThisWeek;

  /// Reason fragment
  ///
  /// In en, this message translates to:
  /// **'before {when}'**
  String planByBefore(String when);

  /// Unplaced reason
  ///
  /// In en, this message translates to:
  /// **'focus blocks are full {by}'**
  String planReasonFocusFull(String by);

  /// Unplaced reason
  ///
  /// In en, this message translates to:
  /// **'only {fit} of {need} min fit {by}'**
  String planReasonOnlyFit(int fit, int need, String by);

  /// Unplaced reason
  ///
  /// In en, this message translates to:
  /// **'no free {minutes}-minute slot {by}'**
  String planReasonNoSlot(int minutes, String by);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
