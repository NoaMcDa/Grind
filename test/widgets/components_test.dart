import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/theme/tokens.dart';
import 'package:grind/widgets/widgets.dart';

import '../test_fonts.dart';
import 'test_app.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('PillButton: semantics, tap, 44px target when short', (
    tester,
  ) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      Center(
        child: PillButton(label: 'Go', height: 30, onPressed: () => taps++),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Go')),
      matchesSemantics(
        label: 'Go',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(PillButton),
              matching: find.byType(GestureDetector),
            ),
          )
          .height,
      44,
    );
    await tester.tap(find.text('Go'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('PillButton disabled when onPressed is null', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const Center(child: PillButton(label: 'Nope')));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Nope')),
      matchesSemantics(
        label: 'Nope',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('Pill, SectionLabel header, IconChip labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      Column(
        children: [
          const Pill(label: 'Tag'),
          const SectionLabel('Energy'),
          IconChip.deep(label: 'Deep focus'),
          IconChip.light(label: 'Light'),
        ],
      ),
    );
    expect(find.text('Tag'), findsOneWidget);
    expect(find.text('ENERGY'), findsOneWidget);
    expect(find.bySemanticsLabel('Deep focus'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    handle.dispose();
  });

  testWidgets('MomentumMeter exposes label and percent value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const MomentumMeter(value: 0.4));
    final node = tester.getSemantics(find.bySemanticsLabel('Momentum'));
    expect(node.value, '40%');
    handle.dispose();
  });

  testWidgets('PipAvatar is an image with a label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const PipAvatar());
    expect(find.bySemanticsLabel('Pip, your companion'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('StickerCard renders child', (tester) async {
    await pumpApp(tester, const StickerCard(child: Text('hi')));
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('StickerTextField: typing, hint, error state', (tester) async {
    final c = TextEditingController();
    String? changed;
    await pumpApp(
      tester,
      Column(
        children: [
          StickerTextField(
            controller: c,
            label: 'Title',
            onChanged: (v) => changed = v,
          ),
          const StickerTextField(label: 'Bad', errorText: 'Oops'),
        ],
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'abc');
    expect(changed, 'abc');
    expect(c.text, 'abc');
    expect(find.text('Oops'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('showStickerSheet shows handle and content, dismisses', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (ctx) => PillButton(
          label: 'Open',
          onPressed: () => showStickerSheet<void>(ctx, (_) => const Text('In')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('In'), findsOneWidget);
    expect(find.bySemanticsLabel('Drag handle'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('In'), findsNothing);
  });

  testWidgets('showPipToast shows message with Pip', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (ctx) => PillButton(
          label: 'Toast',
          onPressed: () => showPipToast(ctx, 'Nice start!'),
        ),
      ),
    );
    await tester.tap(find.text('Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nice start!'), findsOneWidget);
    expect(find.byType(PipAvatar), findsOneWidget);
  });

  testWidgets('EmptyState: texts and action tap', (tester) async {
    var tapped = false;
    await pumpApp(
      tester,
      EmptyState(
        title: 'Nothing yet',
        body: 'Pip is here.',
        actionLabel: 'Add a task',
        onAction: () => tapped = true,
      ),
    );
    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.byType(PipAvatar), findsOneWidget);
    await tester.tap(find.text('Add a task'));
    expect(tapped, isTrue);
  });

  testWidgets('SkeletonBox has a localized loading label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const SkeletonBox(width: 100));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await pumpApp(
      tester,
      const SkeletonBox(width: 100),
      locale: const Locale('he'),
    );
    expect(find.bySemanticsLabel('טוען'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('date and time pickers open themed and return a value', (
    tester,
  ) async {
    DateTime? result;
    await pumpApp(
      tester,
      Builder(
        builder: (ctx) => PillButton(
          label: 'Pick',
          onPressed: () async => result = await showStickerDateTimePicker(
            ctx,
            initial: DateTime(2026, 11, 3, 9, 30),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 11, 3, 9, 30));
  });

  testWidgets('MomentumMeter fill starts at the start edge in RTL', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(width: 200, child: MomentumMeter(value: 0.5)),
      ),
    );
    final fill = tester.getRect(find.byType(FractionallySizedBox));
    final meter = tester.getRect(find.byType(MomentumMeter));
    expect(fill.right, closeTo(meter.right - AppStroke.border, 1));
  });

  testWidgets('PillButton takes keyboard focus, shows a ring, Enter taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: PillButton(label: 'Go', onPressed: () => taps++),
      ),
    );
    final tap = find.descendant(
      of: find.byType(PillButton),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(tap)).requestFocus();
    await tester.pump();
    // A key press switches Flutter to keyboard (traditional) highlight mode.
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(PillButton),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null &&
              w.position == DecorationPosition.foreground,
        ),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('disabled PillButton is not focusable', (tester) async {
    await pumpApp(tester, const Center(child: PillButton(label: 'Nope')));
    final detector = find.descendant(
      of: find.byType(PillButton),
      matching: find.byType(FocusableActionDetector),
    );
    expect(tester.widget<FocusableActionDetector>(detector).enabled, isFalse);
  });

  testWidgets('MomentumMeter at zero is an empty track', (tester) async {
    await pumpApp(tester, const MomentumMeter(value: 0));
    expect(find.byType(FractionallySizedBox), findsNothing);
    await pumpApp(tester, const MomentumMeter(value: 0.01));
    expect(find.byType(FractionallySizedBox), findsOneWidget);
  });

  testWidgets('Pip and momentum labels follow the app language', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const Column(children: [PipAvatar(), MomentumMeter(value: 0.5)]),
      locale: const Locale('he'),
    );
    expect(find.bySemanticsLabel('פיפ, המלווה שלך'), findsOneWidget);
    expect(find.bySemanticsLabel('מומנטום'), findsOneWidget);
    handle.dispose();
  });
}
