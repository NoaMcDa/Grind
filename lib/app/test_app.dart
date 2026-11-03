// Test support that lives in lib so every feature's tests can import it.
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/core.dart';
import 'app.dart';
import 'demo_seed.dart';

/// 2026-10-29 09:00 local: the day the demo data describes.
DateTime get testNow => DateTime(2026, 10, 29, 9);

/// The app wired with the in-memory fakes and a [FixedClock]. Anything in
/// [overrides] wins over the defaults. No platform channels are touched.
class TestApp extends StatelessWidget {
  TestApp({
    super.key,
    this.overrides = const [],
    this.initialLocation = '/today',
    Clock? clock,
  }) : clock = clock ?? FixedClock(testNow);

  final List<Override> overrides;
  final String initialLocation;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return GrindApp(
      initialLocation: initialLocation,
      overrides: [
        ...demoOverrides(clock: clock),
        ...overrides,
      ],
    );
  }
}

/// Pumps [TestApp] at phone size and settles. Returns the app's
/// [ProviderContainer] so tests can read repositories.
Future<ProviderContainer> pumpGrindApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  String initialLocation = '/today',
  Clock? clock,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    TestApp(
      overrides: overrides,
      initialLocation: initialLocation,
      clock: clock,
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}
