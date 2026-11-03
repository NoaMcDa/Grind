import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/time_zones.dart';
import 'package:grind/features/plan/draft/day_draft.dart';
import 'package:grind/features/plan/draft/day_draft_sheet.dart';
import 'package:grind/features/plan/draft/day_drafter.dart';
import 'package:grind/l10n/l10n.dart';

import '../../../test_fonts.dart';
import '../scheduler/fixtures.dart';

final _talk = event('talk', at(0, 14, 30), at(0, 15, 30), title: 'Talk');

DayDraftProposal _proposal() {
  final tasks = [
    task('thesis', title: 'Thesis', minutes: 90, energy: Energy.deep),
    task('email', title: 'Email', minutes: 15, due: at(0, 17)),
    task('read', title: 'Read', minutes: 45),
    task('call', title: 'Call', minutes: 20, priority: 1),
  ];
  return DayDraftProposal(
    draft: draftDay(
      tasks: tasks,
      goals: const {},
      events: [_talk],
      prefs: prefsFixture,
      now: at(0, 8),
    ),
    tasks: {for (final t in tasks) t.id: t},
    events: [_talk],
    location: locationFor('UTC'),
  );
}

/// Pumps a page with one button that opens the sheet; [result] receives
/// what the sheet resolves to.
Future<void> _pump(
  WidgetTester tester,
  DayDraftProposal proposal,
  void Function(DayDraft?) result, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async =>
                  result(await showDayDraftSheet(context, proposal)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String id) =>
    tester.getTopLeft(find.byKey(Key('draft-item-$id'))).dy;

void main() {
  setUpAll(() async {
    ensureTimeZones();
    await loadAppFonts();
  });

  testWidgets('shows the day in order between events, each block with its '
      'reason', (tester) async {
    await _pump(tester, _proposal(), (_) {});
    expect(find.text('Your day, drafted'), findsOneWidget);
    expect(find.text('TODAY, IN ORDER'), findsOneWidget);
    expect(find.byKey(const Key('draft-event-talk')), findsOneWidget);
    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('09:00–10:30'), findsOneWidget);
    expect(find.text('your focus window'), findsOneWidget);
    expect(
      find.text('due today · keeps your focus window clear'),
      findsOneWidget,
    );
    expect(
      find.text('Pip found 4.5 h free today and drafted 3 h.'),
      findsOneWidget,
    );
    expect(_top(tester, 'thesis'), lessThan(_top(tester, 'email')));
    // The event sits after the blocks that end before it.
    final talk = tester.getTopLeft(find.byKey(const Key('draft-event-talk')));
    expect(talk.dy, greaterThan(_top(tester, 'read')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove, move and accept all', (tester) async {
    DayDraft? out;
    await _pump(tester, _proposal(), (d) => out = d);

    // The first block cannot move earlier: nothing changes.
    await tester.tap(find.bySemanticsLabel('Move Thesis earlier'));
    await tester.pumpAndSettle();
    expect(_top(tester, 'thesis'), lessThan(_top(tester, 'email')));

    await tester.tap(find.bySemanticsLabel('Remove Call from the draft'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('draft-item-call')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Move Read earlier'));
    await tester.pumpAndSettle();
    expect(_top(tester, 'read'), lessThan(_top(tester, 'email')));
    expect(find.text('in the order you chose'), findsOneWidget);

    await tester.tap(find.byKey(const Key('draft-accept')));
    await tester.pumpAndSettle();
    expect(out, isNotNull);
    expect(out!.items.map((i) => i.taskId), ['thesis', 'read', 'email']);
    // Read now follows Thesis at the first free moment after it.
    expect(out!.items[1].start, at(0, 10, 30));
  });

  testWidgets('a move that does not fit says so and keeps the draft', (
    tester,
  ) async {
    final tasks = [
      task('due', title: 'Due soon', minutes: 20, due: at(0, 9, 20)),
      task('long', title: 'Long', minutes: 60, energy: Energy.deep),
    ];
    final p = DayDraftProposal(
      draft: draftDay(
        tasks: tasks,
        goals: const {},
        events: const [],
        prefs: prefsFixture,
        now: at(0, 8),
      ),
      tasks: {for (final t in tasks) t.id: t},
      events: const [],
      location: locationFor('UTC'),
    );
    await _pump(tester, p, (_) {});
    await tester.tap(find.bySemanticsLabel('Move Due soon later'));
    await tester.pump();
    expect(find.text('That one does not fit there'), findsOneWidget);
    expect(_top(tester, 'due'), lessThan(_top(tester, 'long')));
  });

  testWidgets('Not now resolves to null; an empty draft cannot be accepted', (
    tester,
  ) async {
    var called = false;
    DayDraft? out = _proposal().draft;
    final empty = DayDraftProposal(
      draft: draftDay(
        tasks: const [],
        goals: const {},
        events: const [],
        prefs: prefsFixture,
        now: at(0, 8),
      ),
      tasks: const {},
      events: const [],
      location: locationFor('UTC'),
    );
    await _pump(tester, empty, (d) {
      called = true;
      out = d;
    });
    expect(
      find.text('Nothing to draft right now. The day is yours.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('draft-accept')));
    await tester.pumpAndSettle();
    expect(called, isFalse);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(out, isNull);
  });

  testWidgets('Hebrew at 390x844: copy and no overflow', (tester) async {
    await _pump(tester, _proposal(), (_) {}, locale: const Locale('he'));
    expect(find.text('היום שלך, בטיוטה'), findsOneWidget);
    expect(find.text('חלון הפוקוס שלך'), findsOneWidget);
    expect(find.text('לאשר הכול'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
