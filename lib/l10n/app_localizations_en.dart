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
      'Snooze again and Pip will offer to move it instead.';

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
}
