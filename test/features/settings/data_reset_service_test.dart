import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/backup_actions_adapter.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/data/connection/memory.dart';
import 'package:grind/core/data/data.dart';
import 'package:grind/features/calendar/google/google_calendar_provider.dart';
import 'package:grind/features/calendar/google/google_config.dart';
import 'package:grind/features/calendar/google/key_value_store.dart';
import 'package:grind/features/calendar/sync/calendar_sync_engine.dart';
import 'package:grind/features/calendar/sync/sync_status.dart';
import 'package:grind/features/settings/data_reset_service.dart';

import '../calendar/google/fakes.dart';

class _Gateway implements BackupFileGateway {
  String? toPick;

  @override
  Future<void> save({
    required String fileName,
    required String contents,
  }) async {}

  @override
  Future<String?> pick() async => toPick;
}

class _Throwing extends FakeCalendarProvider {
  _Throwing() : super(CalendarSource.apple);

  @override
  Future<void> disconnect() async => throw StateError('offline');
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 8);
  final month = (DateTime.utc(2026, 11), DateTime.utc(2026, 12));
  late FakeGateway gw;
  late FakeAuth auth;
  late InMemoryKeyValueStore store;
  late GoogleCalendarProvider google;
  late InMemoryCalendarRepository calendars;
  late InMemoryPreferencesRepository prefs;
  late CalendarSyncEngine engine;
  late DataResetService reset;

  Future<List<CalendarEvent>> mirrored() =>
      calendars.getBetween(month.$1, month.$2);

  setUp(() async {
    gw = FakeGateway();
    gw.put(
      'primary',
      timed(
        'e1',
        DateTime.utc(2026, 11, 4, 9),
        DateTime.utc(2026, 11, 4, 10),
        title: 'Standup',
      ),
    );
    auth = FakeAuth(gw);
    store = InMemoryKeyValueStore();
    google = GoogleCalendarProvider(
      auth: auth,
      store: store,
      config: const GoogleCalendarConfig(
        iosClientId: '123-ios.apps.googleusercontent.com',
        webClientId: '123-web.apps.googleusercontent.com',
      ),
      clock: FixedClock(now),
    );
    calendars = InMemoryCalendarRepository();
    prefs = InMemoryPreferencesRepository();
    await prefs.save(
      const Preferences().copyWith(
        selectedCalendarIds: {
          CalendarSource.google: ['primary'],
        },
      ),
    );
    engine = CalendarSyncEngine(
      provider: google,
      calendarRepository: calendars,
      taskRepository: InMemoryTaskRepository(),
      preferencesRepository: prefs,
      clock: FixedClock(now),
    );
    reset = DataResetService(
      providers: [google],
      engines: [engine],
      calendarRepository: calendars,
      preferencesRepository: prefs,
    );
    await google.connect();
    await engine.sync();
  });

  test('premise: connected, state stored, events mirrored', () async {
    expect(await google.isConnected(), isTrue);
    expect(store.values.keys.any((k) => k.startsWith('grind.google.')), isTrue);
    expect(engine.status.lastSyncedAt, isNotNull);
    expect(await mirrored(), isNotEmpty);
  });

  test('resetCalendars disconnects and clears tokens, events, selection and '
      'in-memory status', () async {
    await reset.resetCalendars();

    expect(await google.isConnected(), isFalse);
    expect(auth.signOuts, 1);
    expect(store.values, isEmpty);
    expect(await mirrored(), isEmpty);
    expect((await prefs.get()).selectedCalendarIds, isEmpty);
    expect(engine.status, const SyncStatus.idle());

    // The next sync starts clean: nothing comes back while disconnected.
    await engine.sync();
    expect(await mirrored(), isEmpty);
  });

  test('a provider that cannot disconnect does not stop the reset', () async {
    final r = DataResetService(
      providers: [_Throwing(), google],
      engines: [engine],
      calendarRepository: calendars,
      preferencesRepository: prefs,
    );
    await r.resetCalendars();
    expect(await google.isConnected(), isFalse);
  });

  group('DriftBackupActions', () {
    late AppDatabase db;
    late _Gateway files;

    setUp(() {
      db = openInMemoryDatabase();
      files = _Gateway();
    });
    tearDown(() => db.close());

    DriftBackupActions actions() => DriftBackupActions(
      BackupService(db, clock: FixedClock(now)),
      gateway: files,
      reset: reset,
    );

    test(
      'deleteAllData also disconnects Google and clears its state',
      () async {
        await actions().deleteAllData();
        expect(await google.isConnected(), isFalse);
        expect(store.values, isEmpty);
        expect(engine.status.lastSyncedAt, isNull);
      },
    );

    test(
      'a restored backup disconnects Google; a cancelled pick does not',
      () async {
        await actions().importBackup();
        expect(await google.isConnected(), isTrue);

        files.toPick = await BackupService(
          db,
          clock: FixedClock(now),
        ).exportJson();
        await actions().importBackup();
        expect(await google.isConnected(), isFalse);
        expect(store.values, isEmpty);
      },
    );
  });
}
