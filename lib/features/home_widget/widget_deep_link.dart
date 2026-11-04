/// The `grind://widget/...` URLs the iOS home-screen widget hands back to
/// the app on a tap or an App-Intents button press (#23).
///
/// Why a URL scheme (and not just the App Group value `WidgetAction`
/// defines): WidgetKit's `.widgetURL(_:)` and `.openAppIntent` flows
/// return control to the host app by launching a URL. The widget has no
/// way to call Dart directly, so a URL is the one channel iOS guarantees
/// for "tap → run some code in the full app". The App Group payload
/// still exists for bulk state; this scheme is the trigger.
///
/// All URLs sit under a dedicated `widget` host so routing and analytics
/// can tell a widget tap from a calendar write-back deep link
/// (`grind://task/<id>`) or a Live Activity tap (`grind:///focus`).
///
/// Pure data. The router wiring and the dispatcher that performs the
/// side effect (complete the task, start a focus session) come in a
/// later slice; this file lets both sides share one spec of the URLs.
library;

/// A parsed widget deep link, or null when the URI is not one of ours.
///
/// Exhaustive `switch` — adding a new verb forces every dispatcher to
/// handle it.
sealed class WidgetDeepLink {
  const WidgetDeepLink();

  /// Scheme and host every widget link uses. Keeping them as constants
  /// lets the Swift side reference the same strings over the method
  /// channel without stringly-typed duplication.
  static const scheme = 'grind';
  static const host = 'widget';

  /// Verbs that live under `grind://widget/<verb>`.
  static const _verbTask = 'task';
  static const _verbFocus = 'focus';
  static const _verbPlan = 'plan';

  /// The action the task verb carries after the id: `/task/<id>/<action>`.
  static const _actionDone = 'done';

  /// The URL the widget should open to trigger this action.
  Uri toUri();

  String toUriString() => toUri().toString();

  /// Parses [raw] (a string or a [Uri]) into a [WidgetDeepLink], or null
  /// when it is not a widget link. Unknown verbs, missing ids and spare
  /// path segments all return null so a widget built from a newer app
  /// cannot crash an older app's intent handler — the fallback is to
  /// open the app.
  static WidgetDeepLink? tryParse(Object? raw) {
    final uri = switch (raw) {
      Uri u => u,
      String s => Uri.tryParse(s),
      _ => null,
    };
    if (uri == null) return null;
    if (uri.scheme != scheme || uri.host != host) return null;

    final segments = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    // `grind://widget` with no path: the plain container tap.
    if (segments.isEmpty) return const WidgetOpenApp();

    switch (segments[0]) {
      case _verbTask:
        // `/task/<id>` → open; `/task/<id>/done` → mark done.
        if (segments.length == 2) {
          return WidgetOpenTask(taskId: segments[1]);
        }
        if (segments.length == 3 && segments[2] == _actionDone) {
          return WidgetMarkTaskDone(taskId: segments[1]);
        }
        return null;
      case _verbFocus:
        // `/focus` → open focus with no task preselected.
        // `/focus/<id>` → start focus on that task.
        if (segments.length == 1) return const WidgetStartFocus();
        if (segments.length == 2) {
          return WidgetStartFocus(taskId: segments[1]);
        }
        return null;
      case _verbPlan:
        if (segments.length == 1) return const WidgetPlanMyDay();
        return null;
      default:
        return null;
    }
  }
}

/// The plain widget surface was tapped — open the app's default screen.
class WidgetOpenApp extends WidgetDeepLink {
  const WidgetOpenApp();

  @override
  Uri toUri() => Uri(scheme: WidgetDeepLink.scheme, host: WidgetDeepLink.host);

  @override
  bool operator ==(Object other) => other is WidgetOpenApp;

  @override
  int get hashCode => (WidgetOpenApp).hashCode;
}

/// The "up next" row was tapped — open the task detail.
class WidgetOpenTask extends WidgetDeepLink {
  const WidgetOpenTask({required this.taskId}) : assert(taskId != '');

  final String taskId;

  @override
  Uri toUri() => Uri(
    scheme: WidgetDeepLink.scheme,
    host: WidgetDeepLink.host,
    pathSegments: [WidgetDeepLink._verbTask, taskId],
  );

  @override
  bool operator ==(Object other) =>
      other is WidgetOpenTask && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('openTask', taskId);
}

/// Done button on the reminder row — mark the task done and cancel its
/// pending notification. Mirrors the `WidgetAction.taskDone` payload sent
/// through the App Group; both reach the same dispatcher.
class WidgetMarkTaskDone extends WidgetDeepLink {
  const WidgetMarkTaskDone({required this.taskId}) : assert(taskId != '');

  final String taskId;

  @override
  Uri toUri() => Uri(
    scheme: WidgetDeepLink.scheme,
    host: WidgetDeepLink.host,
    pathSegments: [
      WidgetDeepLink._verbTask,
      taskId,
      WidgetDeepLink._actionDone,
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is WidgetMarkTaskDone && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('taskDone', taskId);
}

/// Start-focus button — open the Focus tab and start a session. [taskId]
/// is null when the momentum tile was tapped (no specific task) so the
/// user lands on the Focus picker.
class WidgetStartFocus extends WidgetDeepLink {
  const WidgetStartFocus({this.taskId}) : assert(taskId != '');

  final String? taskId;

  @override
  Uri toUri() => Uri(
    scheme: WidgetDeepLink.scheme,
    host: WidgetDeepLink.host,
    pathSegments: [WidgetDeepLink._verbFocus, if (taskId != null) taskId!],
  );

  @override
  bool operator ==(Object other) =>
      other is WidgetStartFocus && other.taskId == taskId;

  @override
  int get hashCode => Object.hash('startFocus', taskId);
}

/// Plan-my-day button on the medium widget — open the Today tab with the
/// Pip morning card ready to run.
class WidgetPlanMyDay extends WidgetDeepLink {
  const WidgetPlanMyDay();

  @override
  Uri toUri() => Uri(
    scheme: WidgetDeepLink.scheme,
    host: WidgetDeepLink.host,
    pathSegments: [WidgetDeepLink._verbPlan],
  );

  @override
  bool operator ==(Object other) => other is WidgetPlanMyDay;

  @override
  int get hashCode => (WidgetPlanMyDay).hashCode;
}
