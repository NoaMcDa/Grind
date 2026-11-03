import '../../../l10n/app_localizations.dart';
import '../domain/goal_metric.dart';
import '../domain/goal_progress.dart';
import '../domain/highlights.dart';
import '../domain/weekly_recap.dart';
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

  /// "8 of 12 lessons · 67%", or "3 of 4 workouts this week".
  String goalProgressLine(GoalProgress p) => switch (p.period) {
    null => goalsProgressLine(
      goalOfTarget(p.current, p.target, p.unit),
      p.percent,
    ),
    final period => goalPeriodLine(p.current, p.target, p.unit, period),
  };

  /// "3 of 4 workouts this week" / "… this month".
  String goalPeriodLine(
    int current,
    int target,
    String unit,
    MetricPeriod period,
  ) => switch (period) {
    MetricPeriod.week => goalsThisWeek(current, target, unit),
    MetricPeriod.month => goalsThisMonth(current, target, unit),
  };

  String goalQuotaHit(MetricPeriod p) => switch (p) {
    MetricPeriod.week => goalsQuotaHitWeek,
    MetricPeriod.month => goalsQuotaHitMonth,
  };

  String goalTrendTitle(MetricPeriod p) => switch (p) {
    MetricPeriod.week => goalsTrendWeeks,
    MetricPeriod.month => goalsTrendMonths,
  };

  String goalRecurringHint(MetricPeriod p) => switch (p) {
    MetricPeriod.week => goalsRecurringHintWeek,
    MetricPeriod.month => goalsRecurringHintMonth,
  };

  String highlightGroup(HighlightGroup g) => switch (g) {
    HighlightGroup.completed => highlightsGroupCompleted,
    HighlightGroup.closeToDone => highlightsGroupCloseToDone,
    HighlightGroup.onTrack => highlightsGroupOnTrack,
    HighlightGroup.stalled => highlightsGroupStalled,
  };

  /// "Nov 1 – Nov 7".
  String recapRangeOf(WeeklyRecap r) =>
      recapRange(goalDay(r.week.firstDay), goalDay(r.week.lastDay));

  String recapTitle(WeeklyRecap r) =>
      r.isCurrentWeek ? recapTitleThisWeek : recapTitleLastWeek;

  /// The recap's first line: its biggest win, never a miss.
  String recapHeadline(WeeklyRecap r) => switch (r.lead) {
    RecapLead.goalCompleted => recapLeadGoalCompleted(
      r.completedGoals.first.title,
    ),
    RecapLead.metricHit => recapLeadMetricHit(
      r.metricHits.first.goal.title,
      r.metricHits.first.count,
      r.metricHits.first.quota,
      r.metricHits.first.unit,
    ),
    RecapLead.win => recapLeadWin(r.wins.first),
    RecapLead.tasksDone => recapLeadTasksDone(r.doneCount),
    RecapLead.quiet => recapLeadQuiet,
  };

  /// The recap as plain text for the share sheet.
  String recapShareText(WeeklyRecap r) {
    final lines = <String>[
      recapShareHeader(recapRangeOf(r)),
      recapHeadline(r),
      if (r.wins.isNotEmpty) recapShareWins(r.wins.join(' · ')),
      if (r.metricHits.isNotEmpty)
        recapShareHits(
          r.metricHits
              .map((h) => '${h.goal.title} ${h.count}/${h.quota}')
              .join(' · '),
        ),
      if (r.movedGoals.isNotEmpty)
        recapShareMoved(r.movedGoals.map((g) => g.title).join(' · ')),
      recapShareDone(r.doneCount),
      if (r.rolledOver > 0) recapRolledOverLine(r.rolledOver),
      '',
      recapShareFooter,
    ];
    return lines.join('\n');
  }

  /// "Dec 31" (local date).
  String goalDate(DateTime d) => goalDay(d.toLocal());

  /// "Dec 31" for a calendar date (its y/m/d fields as given).
  String goalDay(DateTime l) {
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
    GoalMilestone.metricHit => goalsMilestoneMetricHit(title),
  };
}
