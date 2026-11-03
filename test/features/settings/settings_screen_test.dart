import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/settings/backup_actions.dart';
import 'package:grind/features/settings/settings_screen.dart';
import 'package:grind/features/settings/settings_store.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  required InMemoryPreferencesRepository prefs,
  FakeBackupActions? backup,
  FakeCalendarProvider? google,
  InMemorySettingsStore? store,
  TextDirection direction = TextDirection.ltr,
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
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Directionality(
          textDirection: direction,
          child: SettingsScreen(picker: (_, _) async => 7 * 60),
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

    await tester.tap(find.byKey(const ValueKey('quiet-start')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours!.startMinutes, 7 * 60);

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
      find.textContaining('Everything stays on this device'),
      findsOneWidget,
    );
  });

  testWidgets('RTL render at 390x844 has no overflow', (tester) async {
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
