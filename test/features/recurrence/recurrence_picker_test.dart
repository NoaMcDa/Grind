import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/recurrence/recurrence.dart';
import 'package:grind/features/recurrence/recurrence_picker.dart';

import '../../test_fonts.dart';
import '../../widgets/test_app.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('picks weekly days and keeps 44px targets', (tester) async {
    Recurrence? value;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => RecurrencePicker(
          value: value,
          anchor: DateTime(2026, 3, 23),
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(value?.preset, RecurrencePreset.weekly);
    expect(value?.weekdays, {1});

    await tester.tap(find.bySemanticsLabel('Wednesday'));
    await tester.pumpAndSettle();
    expect(value?.weekdays, {1, 3});

    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pumpAndSettle();
    expect(value?.interval, 2);

    final box = tester.getSize(find.bySemanticsLabel('Wednesday'));
    expect(box.width, greaterThanOrEqualTo(44));
    expect(box.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Does not repeat'));
    await tester.pumpAndSettle();
    expect(value, isNull);
  });

  testWidgets('renders in Hebrew RTL without overflow', (tester) async {
    await pumpApp(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              RecurrencePicker(
                value: const Recurrence.weekly({1, 3, 5}),
                anchor: DateTime(2026, 3, 23),
                onChanged: (_) {},
              ),
              RecurrenceSummaryChip(
                recurrence: const Recurrence.weekly({1, 3, 5}),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      locale: const Locale('he'),
      textScale: 1.3,
    );
    expect(find.text('כל יום שני, רביעי ושישי'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
