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
  /// **'Snooze again and Pip will offer to move it instead.'**
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
