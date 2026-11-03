import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/onboarding/onboarding_flow.dart';
import 'package:grind/features/onboarding/weekday_hours_editor.dart';
import 'package:grind/features/calendar/google/key_value_store.dart';
import 'package:grind/features/settings/time_zone/device_time_zone.dart';
import 'package:grind/l10n/l10n.dart';
import 'package:grind/theme/app_theme.dart';

import '../../test_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  required InMemoryPreferencesRepository prefs,
  FakeNotificationService? notifications,
  FakeCalendarProvider? google,
  VoidCallback? onFinished,
  TextDirection direction = TextDirection.ltr,
  Locale locale = const Locale('en'),
  MinutesPicker? picker,
  DeviceTimeZone? device,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(prefs),
        if (notifications != null)
          notificationServiceProvider.overrideWithValue(notifications),
        if (google != null) googleCalendarProvider.overrideWithValue(google),
        if (device != null) deviceTimeZoneProvider.overrideWithValue(device),
        deviceTimeZoneMemoryProvider.overrideWithValue(InMemoryKeyValueStore()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Directionality(
          textDirection: direction,
          child: OnboardingFlow(
            onFinished: onFinished ?? () {},
            picker: picker,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('full flow sets onboardingDone and calls onFinished', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    final google = FakeCalendarProvider(CalendarSource.google);
    var finished = false;
    await _pump(
      tester,
      prefs: prefs,
      google: google,
      onFinished: () => finished = true,
    );

    await _tapText(tester, 'Start');
    await _tapText(tester, 'Allow');
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'Connect');
    expect(google.connected, isTrue);
    expect(find.text('Connected'), findsOneWidget);
    await _tapText(tester, 'Continue');
    await tester.drag(
      find.text('When do you like to work?'),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text("You're set."), findsOneWidget);
    await _tapText(tester, 'Take me to Today');

    expect((await prefs.get()).onboardingDone, isTrue);
    expect(finished, isTrue);
  });

  testWidgets('allowing notifications starts quiet hours 22:00 – 07:00', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs);
    await _tapText(tester, 'Start');
    await _tapText(tester, 'Allow');

    final quiet = (await prefs.get()).quietHours!;
    expect((quiet.startMinutes, quiet.endMinutes), (22 * 60, 7 * 60));
    expect(quiet.wrapsMidnight, isTrue);
    expect(find.textContaining('22:00 – 07:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-quiet-switch')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours, isNull);
    await tester.tap(find.byKey(const ValueKey('onboarding-quiet-switch')));
    await tester.pumpAndSettle();
    expect((await prefs.get()).quietHours, isNotNull);
  });

  testWidgets('first run takes the device time zone', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(
      tester,
      prefs: prefs,
      device: FakeDeviceTimeZone('America/Los_Angeles'),
    );
    expect((await prefs.get()).timeZoneName, 'America/Los_Angeles');
  });

  testWidgets('skipping every step still finishes', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    var finished = false;
    await _pump(tester, prefs: prefs, onFinished: () => finished = true);

    for (var i = 0; i < 4; i++) {
      await _tapText(tester, 'Skip');
    }
    await _tapText(tester, 'Take me to Today');
    expect(finished, isTrue);
    expect((await prefs.get()).onboardingDone, isTrue);
  });

  testWidgets('denied notifications show a gentle note and continue works', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    final notifications = FakeNotificationService()..permission = false;
    await _pump(tester, prefs: prefs, notifications: notifications);

    await _tapText(tester, 'Start');
    await _tapText(tester, 'Allow');
    expect(find.byKey(const ValueKey('notif-denied')), findsOneWidget);
    await _tapText(tester, 'Continue');
    expect(find.text('Bring your calendar along'), findsOneWidget);
  });

  testWidgets('"Not now" moves on without requesting', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs);
    await _tapText(tester, 'Start');
    await _tapText(tester, 'Not now');
    expect(find.text('Bring your calendar along'), findsOneWidget);
  });

  testWidgets('working hours, week start and language are saved', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs, picker: (_, _) async => 8 * 60);
    for (var i = 0; i < 3; i++) {
      await _tapText(tester, 'Skip');
    }
    expect(find.text('When do you like to work?'), findsOneWidget);

    // Wednesday off.
    await tester.tap(
      find.byKey(const ValueKey('day-switch-${DateTime.wednesday}')),
    );
    await tester.pumpAndSettle();
    expect(
      (await prefs.get()).workingHours.containsKey(DateTime.wednesday),
      isFalse,
    );

    // Monday start picks 08:00.
    await tester.tap(
      find.byKey(const ValueKey('day-start-${DateTime.monday}')),
    );
    await tester.pumpAndSettle();
    expect(
      (await prefs.get()).workingHours[DateTime.monday]!.first.startMinutes,
      8 * 60,
    );

    await tester.ensureVisible(find.text('Monday').last);
    await _tapText(tester, 'Monday');
    await tester.ensureVisible(find.text('עברית'));
    await _tapText(tester, 'עברית');
    final saved = await prefs.get();
    expect(saved.weekStart, DateTime.monday);
    expect(saved.localeCode, 'he');
  });

  testWidgets('Apple calendar row only on iOS', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs);
    await _tapText(tester, 'Start');
    await _tapText(tester, 'Not now');
    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('Apple Calendar'), findsNothing);
  });

  testWidgets('RTL render has no overflow on every step', (tester) async {
    final prefs = InMemoryPreferencesRepository();
    final he = lookupAppLocalizations(const Locale('he'));
    await _pump(
      tester,
      prefs: prefs,
      direction: TextDirection.rtl,
      locale: const Locale('he'),
    );
    expect(find.text(he.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 4; i++) {
      await _tapText(tester, he.commonSkip);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('RTL: progress dots start at the right edge, gap after each', (
    tester,
  ) async {
    await _pump(
      tester,
      prefs: InMemoryPreferencesRepository(),
      direction: TextDirection.rtl,
      locale: const Locale('he'),
    );
    final dots = find.byType(AnimatedContainer);
    final first = tester.getRect(dots.at(0));
    final second = tester.getRect(dots.at(1));
    // 20 px start padding on the right; the 6 px gap (part of each dot's
    // box) trails to the left, and the next dot follows it.
    expect(first.right, closeTo(390 - 20, 0.5));
    expect(second.right, closeTo(first.left, 0.5));
  });

  testWidgets('choice pills take keyboard focus and activate on Enter', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesRepository();
    await _pump(tester, prefs: prefs);
    await _tapText(tester, 'Start');
    await _tapText(tester, 'Not now');
    await _tapText(tester, 'Continue');
    expect(find.text('Monday'), findsOneWidget);
    // Move focus onto the Monday pill and press Enter.
    final pill = find.ancestor(
      of: find.text('Monday'),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(pill.first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect((await prefs.get()).weekStart, DateTime.monday);
  });

  testWidgets('editing one range keeps the day\'s other ranges', (
    tester,
  ) async {
    Map<int, List<TimeRange>>? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeekdayHoursEditor(
              value: const {
                DateTime.monday: [
                  TimeRange(startMinutes: 540, endMinutes: 720),
                  TimeRange(startMinutes: 780, endMinutes: 1020),
                ],
              },
              weekStart: DateTime.monday,
              picker: (_, __) async => 600,
              onChanged: (v) => saved = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('day-start-1')));
    await tester.pumpAndSettle();
    expect(saved![DateTime.monday], const [
      TimeRange(startMinutes: 600, endMinutes: 720),
      TimeRange(startMinutes: 780, endMinutes: 1020),
    ]);
  });
}
