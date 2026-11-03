/// Copy for "Your numbers". Pip's tone: plain facts, no verdicts.
abstract final class AnalyticsStrings {
  static const title = 'Your numbers';
  static const subtitle = 'Just what happened. No grades.';
  static const back = 'Back';

  static const emptyTitle = 'Nothing to chart yet';
  static const emptyBody =
      'Finish a task or a focus session and your numbers show up here.';

  static const focusTitle = 'Focus minutes';
  static const focusSub = 'Last 14 days';
  static const restDay = 'rest day';
  static const restLegend = 'Pale bars are rest days. Rest counts too.';
  static String focusTotal(int minutes) {
    if (minutes == 0) return 'A quiet stretch. Pip is patient.';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final t = h == 0 ? '$m min' : (m == 0 ? '$h h' : '$h h $m min');
    return '$t of focus in two weeks';
  }

  static const completionTitle = 'Completion rate';
  static const completionSub = 'Last 8 weeks';
  static const completionNote =
      "Share of each week's tasks you finished. A dash means nothing was planned.";

  static const accuracyTitle = 'Estimate accuracy';
  static const accuracySub = 'Planned time vs real time';
  static const accuracyWaiting = 'A few more tasks and Pip will know.';
  static const accuracyHow =
      'Pip uses this to plan with a little more room where you need it.';

  /// "study tasks usually run 1.4× longer".
  static String accuracyLine(String category, double ratio) {
    final r = ratio.toStringAsFixed(1);
    if (ratio >= 1.1) return '$category tasks usually run $r× longer';
    if (ratio <= 0.9) return '$category tasks usually take $r× the time';
    return '$category tasks usually land right on the estimate';
  }

  static String samples(int n) => '$n tasks';

  static String semanticsFocus(int minutes, int restDays) =>
      'Focus minutes, last 14 days: $minutes in total, $restDays rest days';
  static String semanticsCompletion(int done, int planned) =>
      'Completion rate, last 8 weeks: $done of $planned tasks finished';
}
