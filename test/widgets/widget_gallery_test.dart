import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/widgets/gallery/widget_gallery.dart';

import '../test_fonts.dart';
import 'test_app.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (name, locale, scale) in [
    ('LTR en', const Locale('en'), 1.0),
    ('RTL he', const Locale('he'), 1.0),
    ('RTL he at 2.0x (clamped to 1.3)', const Locale('he'), 2.0),
  ]) {
    testWidgets('gallery renders without overflow: $name', (tester) async {
      await pumpApp(
        tester,
        const WidgetGallery(),
        locale: locale,
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      final dir = Directionality.of(tester.element(find.byType(WidgetGallery)));
      expect(
        dir,
        locale.languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr,
      );
      // Scroll to the bottom to lay out every section.
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('text scale is clamped to 1.3', (tester) async {
    late double scaled;
    await pumpApp(
      tester,
      Builder(
        builder: (ctx) {
          scaled = MediaQuery.textScalerOf(ctx).scale(10);
          return const SizedBox();
        },
      ),
      textScale: 2.0,
    );
    expect(scaled, closeTo(13, 0.001));
  });
}
