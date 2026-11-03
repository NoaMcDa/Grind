import '../../../l10n/app_localizations.dart';
import '../domain/goal_progress.dart';
import '../../../core/domain/goal.dart';

/// Goal copy that needs a little Dart around the generated strings: enum
/// labels, dates and progress lines. Everything else is `context.l10n.goals*`.
extension GoalL10n on AppLocalizations {
  String goalHorizon(GoalHorizon h) => switch (h) {
    GoalHorizon.week => goalsHorizonWeek,
    GoalHorizon.month => goalsHorizonMonth,
    GoalHorizon.quarter => goalsHorizonQuarter,
    GoalHorizon.year => goalsHorizonYear,
  };

  String goalHorizonShort(GoalHorizon h) => switch (h) {
    GoalHorizon.week => goalsHorizonShortWeek,
    GoalHorizon.month => goalsHorizonShortMonth,
    GoalHorizon.quarter => goalsHorizonShortQuarter,
    GoalHorizon.year => goalsHorizonShortYear,
  };

  String goalStatus(GoalStatus s) => switch (s) {
    GoalStatus.active => goalsStatusActive,
    GoalStatus.paused => goalsStatusPaused,
    GoalStatus.done => goalsStatusDone,
  };

  /// "8 of 12 lessons".
  String goalOfTarget(int current, int target, String unit) => unit.isEmpty
      ? goalsOfTarget(current, target)
      : goalsOfTargetUnit(current, target, unit);

  /// "8 of 12 lessons · 67%".
  String goalProgressLine(GoalProgress p) =>
      goalsProgressLine(goalOfTarget(p.current, p.target, p.unit), p.percent);

  /// "Dec 31" (local date).
  String goalDate(DateTime d) {
    final l = d.toLocal();
    final month = [
      commonMonthShortJan,
      commonMonthShortFeb,
      commonMonthShortMar,
      commonMonthShortApr,
      commonMonthShortMay,
      commonMonthShortJun,
      commonMonthShortJul,
      commonMonthShortAug,
      commonMonthShortSep,
      commonMonthShortOct,
      commonMonthShortNov,
      commonMonthShortDec,
    ][l.month - 1];
    return goalsDate(month, l.day);
  }

  String goalByDate(DateTime d) => goalsByDate(goalDate(d));

  String goalAddOne(String unit) =>
      unit.isEmpty ? goalsAddOne : goalsAddOneTo(unit);

  String goalMilestone(GoalMilestone m, String title) => switch (m) {
    GoalMilestone.closeToDone => goalsMilestoneCloseToDone(title),
    GoalMilestone.completed => goalsMilestoneCompleted(title),
  };
}
