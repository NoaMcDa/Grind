import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../core/notifications/notifications.dart';
import '../features/calendar/apple/providers.dart';
import '../features/calendar/sync/providers.dart';
import '../features/companion/celebration_bus.dart';
import '../features/goals/domain/goal_progress.dart';
import '../features/goals/goal_providers.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../features/settings/time_zone/device_time_zone.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/text_scale.dart';
import 'router.dart';

/// Root widget: Riverpod scope + go_router.
///
/// `main.dart` passes [overrides] to swap in real implementations (database,
/// notifications, calendar); tests pass fakes.
///
/// [startServices] starts the background services that need the widget tree
/// (notification sync + action routing). Tests leave it off so no timers
/// keep `pumpAndSettle` waiting.
class GrindApp extends StatelessWidget {
  const GrindApp({
    super.key,
    this.overrides = const [],
    this.initialLocation = '/today',
    this.startServices = true,
  });

  final List<Override> overrides;
  final String initialLocation;
  final bool startServices;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: _RouterApp(
        initialLocation: initialLocation,
        startServices: startServices,
      ),
    );
  }
}

class _RouterApp extends ConsumerStatefulWidget {
  const _RouterApp({
    required this.initialLocation,
    required this.startServices,
  });

  final String initialLocation;
  final bool startServices;

  @override
  ConsumerState<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends ConsumerState<_RouterApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
    onboardingDone: () => ref.read(onboardingDoneProvider).valueOrNull,
    onOnboardingFinished: () => ref.invalidate(onboardingDoneProvider),
  );

  StreamSubscription<String>? _focusSub;
  StreamSubscription<NotificationResponse>? _openedSub;

  @override
  void initState() {
    super.initState();
    if (widget.startServices) {
      // Apply Done / Snooze / Start focus taps to tasks, and open the Focus
      // tab when asked, even when the tap arrives from the Lock Screen.
      final router = ref.read(notificationRouterProvider);
      _focusSub = router.focusRequests.listen(
        (taskId) => _router.go(NotificationRouter.focusLocation(taskId)),
      );
      // Body taps and "Pick a time" open the task; prompts open Today.
      _openedSub = router.opened.listen((response) {
        final location = NotificationRouter.openLocation(response);
        _router.go(location ?? '/today');
      });
      // Keep the pending notifications in step with tasks and preferences.
      final sync = ref.read(notificationSyncProvider)..bindAppLifecycle();
      unawaited(sync.refresh());
      // Pull external calendars on start, on foreground and every 15 min.
      startCalendarSync(ref);
      // First run, or the device moved zones: follow the device time zone.
      unawaited(syncDeviceTimeZone(ref));
    }
  }

  Timer? _appleSyncDebounce;

  /// EventKit also fires for Grind's own writes, so coalesce bursts.
  void _onAppleCalendarChanged() {
    _appleSyncDebounce?.cancel();
    _appleSyncDebounce = Timer(const Duration(seconds: 3), () {
      unawaited(ref.read(appleCalendarSyncEngineProvider).sync());
    });
  }

  @override
  void dispose() {
    _appleSyncDebounce?.cancel();
    _focusSub?.cancel();
    _openedSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-run the redirect once the onboarding flag is known or changes.
    ref.listen(onboardingDoneProvider, (_, _) => _router.refresh());
    // A goal metric reached its quota or a goal was completed, from any
    // screen (goal detail, a tick on Today, an import): Pip cheers.
    ref.listen(goalMilestoneEventsProvider, (_, next) {
      final m = next.valueOrNull?.milestone;
      if (m == GoalMilestone.metricHit) {
        celebrate(ref, const CelebrationEvent.metricReached());
      } else if (m == GoalMilestone.completed) {
        celebrate(ref, const CelebrationEvent.goalCompleted());
      }
    });
    if (widget.startServices) {
      // Apple Calendar changed outside the app: pull again (debounced).
      ref.listen(
        appleCalendarChangesProvider,
        (_, _) => _onAppleCalendarChanged(),
      );
    }
    final localeCode = ref.watch(preferencesProvider).valueOrNull?.localeCode;
    return MaterialApp.router(
      title: 'Grind',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: localeCode == null ? null : Locale(localeCode),
      // CelebrationHost needs the ScaffoldMessenger above it, so it lives in
      // the builder, not around MaterialApp.
      builder: (context, child) =>
          CelebrationHost(child: TextScaleClamp(child: child!)),
      routerConfig: _router,
    );
  }
}
