import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/ask_screen.dart';

import '../../test_fonts.dart';
import '../../widgets/test_app.dart';

const _planMyDayKey = Key('ask-quick-plan-my-day');
const _moveGymKey = Key('ask-quick-move-gym');
const _whatsNextKey = Key('ask-quick-whats-next');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('bubbles sit on LTR sides in English', (tester) async {
    await pumpApp(tester, const ProviderScope(child: AskScreen()));
    expect(
      Directionality.of(tester.element(find.byType(AskScreen))),
      TextDirection.ltr,
    );
    // User bubble (right) sits further right than Pip bubble (left).
    final userRect = tester.getRect(
      find.text('gym tomorrow 7am, 45 min').first,
    );
    final pipRect = tester.getRect(find.textContaining("Got it!").first);
    expect(userRect.right, greaterThan(pipRect.right));
    expect(pipRect.left, lessThan(userRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubbles flip to mirrored sides in RTL Hebrew', (tester) async {
    await pumpApp(
      tester,
      const ProviderScope(child: AskScreen()),
      locale: const Locale('he'),
    );
    expect(
      Directionality.of(tester.element(find.byType(AskScreen))),
      TextDirection.rtl,
    );
    // The underlying English copy is unchanged but the bubbles must now be
    // on the opposite horizontal side: user on the LEFT, Pip on the RIGHT.
    final userRect = tester.getRect(
      find.text('gym tomorrow 7am, 45 min').first,
    );
    final pipRect = tester.getRect(find.textContaining("Got it!").first);
    expect(userRect.left, lessThan(pipRect.left));
    expect(pipRect.right, greaterThan(userRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick-prompt chip labels come from AppLocalizations in English',
      (tester) async {
    await pumpApp(tester, const ProviderScope(child: AskScreen()));
    // All three chips render, in English, and each one has its stable key
    // so other tests and golden images can pin them down.
    expect(find.byKey(_planMyDayKey), findsOneWidget);
    expect(find.byKey(_moveGymKey), findsOneWidget);
    expect(find.byKey(_whatsNextKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_planMyDayKey),
        matching: find.text('Plan my day'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_whatsNextKey),
        matching: find.text("What's next?"),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick-prompt chip labels come from AppLocalizations in Hebrew',
      (tester) async {
    await pumpApp(
      tester,
      const ProviderScope(child: AskScreen()),
      locale: const Locale('he'),
    );
    // Hebrew is pulled from the ARB table, not a hard-coded English
    // fallback — the chip wouldn't carry an RTL label otherwise.
    expect(
      find.descendant(
        of: find.byKey(_planMyDayKey),
        matching: find.text('תכננו לי את היום'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_whatsNextKey),
        matching: find.text('מה הבא?'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Plan my day" chip fires the onPlanMyDay callback end-to-end',
      (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      ProviderScope(child: AskScreen(onPlanMyDay: () => taps += 1)),
    );
    await tester.tap(find.byKey(_planMyDayKey));
    await tester.pump();
    // Exactly one invocation per tap — no accidental fall-through into the
    // composer branch, which would also show the chip's label in the input.
    expect(taps, 1);
    expect(_composerText(tester), isEmpty);
  });

  testWidgets('other chips still populate the composer', (tester) async {
    var planTaps = 0;
    await pumpApp(
      tester,
      ProviderScope(child: AskScreen(onPlanMyDay: () => planTaps += 1)),
    );
    // The three chips sit in a horizontal ListView wider than the phone
    // viewport, so the rightmost chip can scroll off-screen; the tester
    // scrolls it into view before tapping.
    await tester.ensureVisible(find.byKey(_whatsNextKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_whatsNextKey));
    await tester.pump();
    expect(planTaps, 0);
    // The other chips keep their original behavior until the rest of the
    // epic's intents (#40) wire them end-to-end: the English chip label
    // is written into the composer.
    expect(_composerText(tester), "What's next?");
  });
}

/// Reads the current text of the Ask composer: the only `EditableText` the
/// `AskScreen` renders (chips are plain `Text`), so finding it by type is
/// safe.
String _composerText(WidgetTester tester) {
  final editable = tester.widget<EditableText>(find.byType(EditableText));
  return editable.controller.text;
}
