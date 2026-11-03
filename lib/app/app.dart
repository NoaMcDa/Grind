import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/text_scale.dart';
import 'router.dart';

/// Root widget: Riverpod scope + go_router.
///
/// `main.dart` passes [overrides] to swap in real implementations (database,
/// notifications, calendar); tests pass fakes.
class GrindApp extends StatelessWidget {
  const GrindApp({
    super.key,
    this.overrides = const [],
    this.initialLocation = '/today',
  });

  final List<Override> overrides;
  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: _RouterApp(initialLocation: initialLocation),
    );
  }
}

class _RouterApp extends ConsumerStatefulWidget {
  const _RouterApp({required this.initialLocation});

  final String initialLocation;

  @override
  ConsumerState<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends ConsumerState<_RouterApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
    onboardingDone: () => ref.read(onboardingDoneProvider).valueOrNull,
    onOnboardingFinished: () => ref.invalidate(onboardingDoneProvider),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-run the redirect once the onboarding flag is known or changes.
    ref.listen(onboardingDoneProvider, (_, _) => _router.refresh());
    final localeCode = ref.watch(preferencesProvider).valueOrNull?.localeCode;
    return MaterialApp.router(
      title: 'Grind',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: localeCode == null ? null : Locale(localeCode),
      builder: (context, child) => TextScaleClamp(child: child!),
      routerConfig: _router,
    );
  }
}
