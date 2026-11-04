import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/ask_screen.dart';

import '../../test_fonts.dart';
import '../../widgets/test_app.dart';

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
}
