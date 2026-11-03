import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:grind/core/core.dart';

import 'local_notification_service.dart';
import 'notification_scheduler.dart';

/// Supplies extra reminders for the plan, e.g. recurrence occurrences (#11).
typedef ExtraNotifications =
    FutureOr<List<ScheduledNotification>> Function(
      List<Task> tasks,
      Preferences prefs,
    );

/// Keeps the OS pending set equal to [NotificationScheduler.plan] of the
/// current tasks and preferences.
///
/// Re-plans (debounced) on every task or preference change, and immediately
/// on [refresh] (app launch, return to foreground, background fetch).
/// Skips `replaceAll` when the plan did not change.
class NotificationSync {
  NotificationSync({
    required TaskRepository tasks,
    required PreferencesRepository preferences,
    required NotificationService service,
    required Clock clock,
    this.debounce = const Duration(milliseconds: 500),
    this.horizonDays = 7,
    this.cap = 50,
    this.prompts = const PromptSettings(),
    this.extra,
  }) : _tasks = tasks,
       _prefs = preferences,
       _service = service,
       _clock = clock;

  final TaskRepository _tasks;
  final PreferencesRepository _prefs;
  final NotificationService _service;
  final Clock _clock;
  final Duration debounce;
  final int horizonDays;
  final int cap;
  final PromptSettings prompts;
  final ExtraNotifications? extra;

  final List<StreamSubscription<Object?>> _subs = [];
  List<Task>? _latestTasks;
  Preferences? _latestPrefs;
  Timer? _timer;
  String? _lastSignature;
  Future<void> _running = Future.value();
  AppLifecycleListener? _lifecycle;

  /// Number of `replaceAll` calls made (for tests and diagnostics).
  int replaceCount = 0;

  /// Starts listening to the repositories. Idempotent.
  void start() {
    if (_subs.isNotEmpty) return;
    _subs
      ..add(
        _tasks.watchAll().listen((t) {
          _latestTasks = t;
          _schedule();
        }),
      )
      ..add(
        _prefs.watch().listen((p) {
          _latestPrefs = p;
          _schedule();
        }),
      );
  }

  /// Calls [refresh] whenever the app returns to the foreground. Needs the
  /// widgets binding, so call it from the app, not from unit tests.
  void bindAppLifecycle() {
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(refresh()));
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(refresh()));
  }

  /// Re-plans now. Reads the repositories if no value arrived yet.
  Future<void> refresh({bool force = false}) {
    _timer?.cancel();
    final run = _running.then((_) => _replan(force));
    _running = run.catchError((Object _) {});
    return run;
  }

  Future<void> _replan(bool force) async {
    final tasks = _latestTasks ?? await _tasks.getAll();
    final prefs = _latestPrefs ?? await _prefs.get();
    final service = _service;
    if (service is TimeZoneAware) {
      (service as TimeZoneAware).timeZoneName = prefs.timeZoneName;
    }
    final plan = NotificationScheduler.plan(
      tasks: tasks,
      prefs: prefs,
      clock: _clock,
      horizonDays: horizonDays,
      cap: cap,
      prompts: prompts,
      extra: await extra?.call(tasks, prefs) ?? const [],
    );
    final signature = plan
        .map(
          (n) => '${n.id}|${n.fireAt.toIso8601String()}|${n.title}|${n.body}',
        )
        .join('\n');
    if (!force && signature == _lastSignature) return;
    _lastSignature = signature;
    replaceCount++;
    await _service.replaceAll(plan);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _lifecycle?.dispose();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
