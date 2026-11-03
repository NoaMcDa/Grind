import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/core.dart';
import 'calendar_sync_engine.dart';

/// Runs [CalendarSyncEngine.sync] on start, whenever the app returns to the
/// foreground, and every [interval] while it is open. Task edits are pushed
/// shortly after they happen ([taskDebounce]).
///
/// There is no background sync while the app is closed (no server; see
/// docs/adr/0005-google-calendar.md).
class SyncScheduler with WidgetsBindingObserver {
  SyncScheduler(
    this.engines, {
    this.tasks,
    this.interval = const Duration(minutes: 15),
    this.taskDebounce = const Duration(seconds: 2),
    this.bindLifecycle = true,
  });

  final List<CalendarSyncEngine> engines;

  /// When given, task changes trigger a debounced write-back push.
  final TaskRepository? tasks;
  final Duration interval;
  final Duration taskDebounce;

  /// Off in pure unit tests that have no widgets binding.
  final bool bindLifecycle;

  Timer? _timer;
  Timer? _debounce;
  StreamSubscription<List<Task>>? _taskSub;
  bool _started = false;

  bool get isRunning => _started;

  /// Sync now and start the periodic timer. Idempotent.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (bindLifecycle) WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _taskSub = tasks?.watchAll().skip(1).listen((_) => _schedulePush());
    await runNow();
  }

  /// One sync of every engine (errors end up in each engine's status).
  Future<void> runNow() => Future.wait([for (final e in engines) e.sync()]);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(runNow()));
  }

  void _schedulePush() {
    _debounce?.cancel();
    _debounce = Timer(taskDebounce, () {
      for (final e in engines) {
        unawaited(e.pushSoon());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
        unawaited(runNow());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void stop() {
    if (!_started) return;
    _started = false;
    if (bindLifecycle) WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _debounce?.cancel();
    _taskSub?.cancel();
    _timer = null;
    _debounce = null;
    _taskSub = null;
  }
}
