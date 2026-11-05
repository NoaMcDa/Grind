import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/settings/backup_actions.dart';
import 'package:grind/features/settings/settings_screen.dart';
import 'package:grind/features/settings/settings_store.dart';
import 'package:grind/features/settings/time_zone/device_time_zone.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  required InMemoryPreferencesRepository prefs,
  FakeBackupActions? backup,
  FakeCalendarProvider? google,
  InMemorySettingsStore? store,
  InMemoryCalendarRepository? calendars,
  Clock? clock,
  TextDirection direction = TextDirection.ltr,
  Locale? locale,
  int Function()? pick,
  DeviceTimeZone? device,
  FakeCalendarProvider? apple,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(prefs),
        if (backup != null) backupActionsProvider.overrideWithValue(backup),
        if (google != null) googleCalendarProvider.overrideWithValue(google),
        if (store != null) settingsStoreProvider.overrideWithValue(store),
        if (calendars != null)
          calendarRepositoryProvider.overrideWithValue(calendars),
        if (clock != null) clockProvider.overrideWithValue(clock),
        if (device != null) deviceTimeZoneProvider.overrideWithValue(device),
        if (apple != null) appleCalendarProvider.overrideWithValue(apple),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Directionality(
          textDirection: direction,
          child: SettingsScreen(
            picker: (_, _) async => pick == null ? 7 * 60 : pick(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('toggles persist to the preferences repository', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs);

    await _scrollTo(tester, find.byKey(const ValueKey('quiet-switch')));
    await tester.tap(find.byKey(const ValueKey('quiet-switch')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours, isNotNull);

    await tester.tap(find.byKey(const ValueKey('quiet-end')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours!.endMinutes, 7 * 60);

    await tester.tap(find.byKey(const ValueKey('quiet-switch')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours, isNull);

    await _scrollTo(tester, find.text('15 min'));
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    expect((await prefs.get()).defaultReminderLeadMinutes, 15);

    await _scrollTo(tester, find.byKey(const ValueKey('day-switch-3')));
    await tester.tap(find.byKey(const ValueKey('day-switch-3')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).workingHours.containsKey(3), isFalse);

    await _scrollTo(tester, find.text('Monday'));
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();
    expect((await prefs.get()).weekStart, DateTime.monday);

    await _scrollTo(tester, find.text('עברית'));
    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();
    expect((await prefs.get()).localeCode, 'he');
  });

  testWidgets('quiet hours default to 22:00 – 07:00 and may cross midnight', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    var next = 6 * 60;
    await _pump(tester, prefs: prefs, pick: () => next);

    await _scrollTo(tester, find.byKey(const ValueKey('quiet-switch')));
    await tester.tap(find.byKey(const ValueKey('quiet-switch')));
    await tester.pumpAndSettle();
    var quiet = (await prefs.get()).quietHours!;
    expect(quiet.startMinutes, 22 * 60);
    expect(quiet.endMinutes, 7 * 60);
    expect(quiet.wrapsMidnight, isTrue);
    expect(find.text('22:00 – 07:00'), findsOneWidget);

    // An earlier end keeps the start: the range still crosses midnight.
    await tester.tap(find.byKey(const ValueKey('quiet-end')));
    await tester.pumpAndSettle();
    quiet = (await prefs.get()).quietHours!;
    expect((quiet.startMinutes, quiet.endMinutes), (22 * 60, 6 * 60));
    expect(find.text('22:00 – 06:00'), findsOneWidget);

    // A start after the end is fine too, and nothing is pushed to 24:00.
    next = 23 * 60 + 30;
    await tester.tap(find.byKey(const ValueKey('quiet-start')));
    await tester.pumpAndSettle();
    quiet = (await prefs.get()).quietHours!;
    expect((quiet.startMinutes, quiet.endMinutes), (23 * 60 + 30, 6 * 60));

    // Same start and end would be empty: the old range stays.
    next = 6 * 60;
    await tester.tap(find.byKey(const ValueKey('quiet-start')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours!.startMinutes, 23 * 60 + 30);
  });

  testWidgets('time zone row: device zone in one tap, or search', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(
      tester,
      prefs: prefs,
      device: FakeDeviceTimeZone('Europe/London'),
    );
    final row = find.byKey(const ValueKey('time-zone-row'));
    await _scrollTo(tester, row);
    expect(find.text('Asia/Jerusalem'), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tz-use-device')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).timeZoneName, 'Europe/London');
    expect(find.text('Europe/London'), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tz-search')), 'new york');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tz-America/New_York')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).timeZoneName, 'America/New_York');
    expect(find.text('America/New York'), findsOneWidget);
  });

  testWidgets('time zone picker hides an unknown device zone', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs, device: FakeDeviceTimeZone('Nope/Zone'));
    final row = find.byKey(const ValueKey('time-zone-row'));
    await _scrollTo(tester, row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tz-use-device')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('tz-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No zone by that name'), findsOneWidget);
  });

  testWidgets('calendar connect, pick calendars and disconnect', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    final google = FakeCalendarProvider(CalendarSource.google);
    final store = InMemorySettingsStore();
    await _pump(tester, prefs: prefs, google: google, store: store);

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(google.connected, isTrue);
    final box = find.byKey(const ValueKey('cal-Google Calendar-primary'));
    expect(tester.widget<CheckboxListTile>(box).value, isTrue);

    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(await store.selectedCalendarIds(CalendarSource.google), isEmpty);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(google.connected, isFalse);
  });

  testWidgets('calendar checkboxes read and write Preferences', (tester) async {
    final prefs = InMemoryPreferencesRepository(
      const Preferences(
        selectedCalendarIds: {
          CalendarSource.google: ['work'],
        },
      ),
    );
    final google = _TwoCalendars()..connected = true;
    // No store override: the app's PreferencesSettingsStore is used.
    await _pump(tester, prefs: prefs, google: google);

    final primary = find.byKey(const ValueKey('cal-Google Calendar-primary'));
    final work = find.byKey(const ValueKey('cal-Google Calendar-work'));
    expect(tester.widget<CheckboxListTile>(primary).value, isFalse);
    expect(tester.widget<CheckboxListTile>(work).value, isTrue);

    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(
      (await prefs.get()).selectedCalendarIds[CalendarSource.google]!.toSet(),
      {'work', 'primary'},
    );
    await tester.tap(work);
    await tester.pumpAndSettle();
    expect((await prefs.get()).selectedCalendarIds[CalendarSource.google], [
      'primary',
    ]);
  });

  testWidgets('on iOS the Apple sync pill shows next to the Google one', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final google = FakeCalendarProvider(CalendarSource.google)
        ..connected = true;
      final apple = FakeCalendarProvider(CalendarSource.apple)
        ..connected = true;
      final prefs = InMemoryPreferencesRepository();
      await _pump(
        tester,
        prefs: prefs,
        google: google,
        apple: apple,
        clock: FixedClock(DateTime.utc(2026, 11, 3, 8)),
      );
      expect(find.text('Apple Calendar'), findsOneWidget);
      expect(find.byKey(const ValueKey('sync-status-google')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync-status-apple')), findsOneWidget);
      final apples = find.byKey(const ValueKey('cal-Apple Calendar-primary'));
      expect(apples, findsOneWidget);
      await tester.tap(apples);
      await tester.pumpAndSettle();
      expect(
        (await prefs.get()).selectedCalendarIds[CalendarSource.apple],
        isEmpty,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('prompt times persist in the settings store', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    final store = InMemorySettingsStore();
    await _pump(tester, prefs: prefs, store: store);
    await _scrollTo(tester, find.byKey(const ValueKey('morning-switch')));
    await tester.tap(find.byKey(const ValueKey('morning-switch')));
    await tester.pumpAndSettle();
    expect(await store.morningPromptMinutes(), isNull);
  });

  testWidgets('data actions call BackupActions; delete asks first', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    final backup = FakeBackupActions();
    await _pump(tester, prefs: prefs, backup: backup);

    await _scrollTo(tester, find.text('Export backup'));
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
    expect(backup.exports, 1);

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(backup.imports, 1);

    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backup.deletes, 0);

    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(backup.deletes, 1);
  });

  testWidgets('about shows privacy copy', (tester) async {
    await _pump(tester, prefs: InMemoryPreferencesRepository());
    await _scrollTo(tester, find.text('Licences'));
    expect(
      find.textContaining('Your plans stay on this device'),
      findsOneWidget,
    );
  });

  testWidgets('Hebrew RTL render at 390x844 has no overflow', (tester) async {
    final he = lookupAppLocalizations(const Locale('he'));
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      direction: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(he.settingsTitle), findsOneWidget);
    expect(find.text(he.settingsCalendars.toUpperCase()), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('connecting pulls events right away and shows the status', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 11, 3, 8, 5);
    final event = CalendarEvent(
      id: 'g1',
      source: CalendarSource.google,
      externalId: 'g1',
      title: 'Standup',
      start: DateTime.utc(2026, 11, 4, 9),
      end: DateTime.utc(2026, 11, 4, 10),
      createdAt: now,
      updatedAt: now,
    );
    final google = FakeCalendarProvider(CalendarSource.google, events: [event]);
    final calendars = InMemoryCalendarRepository();
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      google: google,
      calendars: calendars,
      clock: FixedClock(now),
    );
    expect(find.byKey(const ValueKey('sync-status-google')), findsNothing);

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    final stored = await calendars.getBetween(
      DateTime.utc(2026, 11),
      DateTime.utc(2026, 12),
    );
    expect(stored.map((e) => e.title), ['Standup']);
    final pill = find.byKey(const ValueKey('sync-status-google'));
    final t = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    expect(
      find.descendant(
        of: pill,
        matching: find.text('Last synced ${two(t.hour)}:${two(t.minute)}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the sync pill shows the engine error message', (tester) async {
    final google = _BrokenFetch();
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      google: google,
      clock: FixedClock(DateTime.utc(2026, 11, 3, 8)),
    );
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sync-status-google')),
        matching: find.textContaining("Pip couldn't reach your calendar"),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the sync pill localizes the engine error in Hebrew', (
    tester,
  ) async {
    final he = lookupAppLocalizations(const Locale('he'));
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      google: _BrokenFetch(),
      clock: FixedClock(DateTime.utc(2026, 11, 3, 8)),
      direction: TextDirection.rtl,
      locale: const Locale('he'),
    );
    await tester.tap(find.text(he.commonConnect));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sync-status-google')),
        matching: find.text(he.calendarSyncGenericError),
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings chips hug their label instead of stretching', (
    tester,
  ) async {
    await _pump(tester, prefs: InMemoryPreferencesRepository());
    await _scrollTo(tester, find.text('15 min'));
    final label = tester.getSize(find.text('15 min'));
    final chip = tester.getSize(
      find
          .ancestor(of: find.text('15 min'), matching: find.byType(Container))
          .first,
    );
    expect(chip.width, lessThan(label.width + 40));
    expect(chip.height, greaterThanOrEqualTo(44));
  });

  testWidgets('switches expose their row label as an accessible name (#217)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final prefs = InMemoryPreferencesRepository();
    final store = InMemorySettingsStore();
    await _pump(tester, prefs: prefs, store: store);

    // Quiet hours switch.
    await _scrollTo(tester, find.byKey(const ValueKey('quiet-switch')));
    final quietNode = tester.getSemantics(
      find.byKey(const ValueKey('quiet-switch')),
    );
    expect(quietNode.label, contains('Quiet hours'));

    // Morning / evening prompt switches.
    await _scrollTo(tester, find.byKey(const ValueKey('morning-switch')));
    final morningNode = tester.getSemantics(
      find.byKey(const ValueKey('morning-switch')),
    );
    expect(morningNode.label, contains('Morning'));

    await _scrollTo(tester, find.byKey(const ValueKey('evening-switch')));
    final eveningNode = tester.getSemantics(
      find.byKey(const ValueKey('evening-switch')),
    );
    expect(eveningNode.label, contains('Evening'));

    // Every day-of-week switch has the weekday short name as its label.
    for (var d = 1; d <= 7; d++) {
      await _scrollTo(tester, find.byKey(ValueKey('day-switch-$d')));
      final node = tester.getSemantics(find.byKey(ValueKey('day-switch-$d')));
      expect(node.label, isNotEmpty, reason: 'day-switch-$d has no label');
    }

    handle.dispose();
  });

  testWidgets(
    'Google Calendar Connect button is its own semantic node (#217)',
    (tester) async {
      final handle = tester.ensureSemantics();
      final google = FakeCalendarProvider(CalendarSource.google);
      await _pump(
        tester,
        prefs: InMemoryPreferencesRepository(),
        google: google,
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Connect')),
        matchesSemantics(
          label: 'Connect',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    },
  );

  testWidgets('About card: Licences is reachable as a separate button (#217)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, prefs: InMemoryPreferencesRepository());
    await _scrollTo(tester, find.text('Licences'));
    // Version, Licences and Privacy are each in their own semantic node.
    expect(find.bySemanticsLabel(RegExp(r'^Version')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Licences')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Privacy')), findsOneWidget);
    handle.dispose();
  });
}

class _BrokenFetch extends FakeCalendarProvider {
  _BrokenFetch() : super(CalendarSource.google);

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async => throw StateError('network');
}

class _TwoCalendars extends FakeCalendarProvider {
  _TwoCalendars() : super(CalendarSource.google);

  @override
  Future<List<ExternalCalendar>> listCalendars() async => const [
    ExternalCalendar(id: 'primary', name: 'Me', isPrimary: true),
    ExternalCalendar(id: 'work', name: 'Work'),
  ];
}
