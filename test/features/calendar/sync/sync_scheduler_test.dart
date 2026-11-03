import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/calendar/sync/sync_scheduler.dart';

class _CountingProvider extends FakeCalendarProvider {
  _CountingProvider() : super(CalendarSource.google) {
    connected = true;
  }

  int fetches = 0;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    fetches++;
    return const [];
  }
}

// testWidgets runs in a fake-async zone, so `pump(duration)` drives the
// scheduler's timers without real waiting.
void main() {
  late _CountingProvider provider;
  late InMemoryTaskRepository tasks;
  late CalendarSyncEngine engine;

  // Built inside each test body so every future lives in the test's
  // fake-async zone.
  void setUpEngine() {
    provider = _CountingProvider();
    tasks = InMemoryTaskRepository();
    engine = CalendarSyncEngine(
      provider: provider,
      calendarRepository: InMemoryCalendarRepository(),
      taskRepository: tasks,
      preferencesRepository: InMemoryPreferencesRepository(),
      clock: FixedClock(DateTime.utc(2026, 11, 3, 8)),
    );
  }

  testWidgets('syncs on start, every 15 minutes, and on foreground', (
    tester,
  ) async {
    setUpEngine();
    final scheduler = SyncScheduler([engine], bindLifecycle: false);
    await scheduler.start();
    expect(provider.fetches, 1);

    await tester.pump(const Duration(minutes: 15));
    expect(provider.fetches, 2);
    await tester.pump(const Duration(minutes: 14));
    expect(provider.fetches, 2);

    // Backgrounded: the timer stops.
    scheduler.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(hours: 1));
    expect(provider.fetches, 2);

    // Foreground: sync right away and restart the timer.
    scheduler.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(provider.fetches, 3);
    await tester.pump(const Duration(minutes: 15));
    expect(provider.fetches, 4);

    scheduler.stop();
    await tester.pump(const Duration(hours: 1));
    expect(provider.fetches, 4);
  });

  testWidgets('task edits push after a short debounce', (tester) async {
    setUpEngine();
    final scheduler = SyncScheduler(
      [engine],
      tasks: tasks,
      bindLifecycle: false,
    );
    await scheduler.start();
    await tasks.upsert(
      Task(
        id: 't1',
        title: 'Draft',
        scheduledStart: DateTime.utc(2026, 11, 4, 9),
        scheduledEnd: DateTime.utc(2026, 11, 4, 10),
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(provider.nextId, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(provider.nextId, 2, reason: 'one event created');
    expect((await tasks.getById('t1'))!.calendarEventId, 'fake-1');
    scheduler.stop();
  });

  testWidgets('binds to the app lifecycle', (tester) async {
    setUpEngine();
    final scheduler = SyncScheduler([engine]);
    await scheduler.start();
    expect(provider.fetches, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(provider.fetches, 2);
    scheduler.stop();
  });
}
