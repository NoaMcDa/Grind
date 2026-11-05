import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ask/ask_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/pip/pip_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/capacity/week_capacity_screen.dart';
import '../features/goals/goals.dart';
import '../features/review/review.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/task_form.dart';
import '../features/today/today_screen.dart';
import '../theme/tokens.dart';
import 'tab_bar.dart';

/// Builds the app router: five tabs in a [StatefulShellRoute.indexedStack]
/// plus deep links.
///
/// - `/today`, `/plan`, `/focus`, `/pip`, `/ask`: the tabs
/// - `/focus?taskId=abc`: Focus tab for a task
/// - `/task/:id`: task detail
/// - `/onboarding`: first-run flow; `/settings`
///
/// [onboardingDone] returns null while unknown, false to force `/onboarding`.
/// [onOnboardingFinished] runs after the flow completes (e.g. to refresh
/// the provider the gate reads).
GoRouter createRouter({
  String initialLocation = '/today',
  bool? Function()? onboardingDone,
  void Function()? onOnboardingFinished,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      // Custom-scheme deep links (`grind://focus`, `grind://task/<id>` from
      // Apple Calendar write-backs): the first segment parses as the host.
      final uri = state.uri;
      if (uri.scheme == 'grind' && uri.host.isNotEmpty) {
        return '/${uri.host}${uri.path}';
      }
      final done = onboardingDone?.call();
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (done == false && !atOnboarding) return '/onboarding';
      if (done == true && atOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/today'),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingFlow(
          onFinished: () {
            onOnboardingFinished?.call();
            context.go('/today');
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const _PhoneColumn(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const EveningReviewEntry(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => GoalDetailScreen(
              goalId: state.pathParameters['id']!,
              onAddTask: taskSheetForGoal,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/highlights',
        builder: (context, state) => const HighlightsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/week',
        builder: (context, state) => const WeekCapacityScreen(),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                builder: (_, state) =>
                    FocusScreen(taskId: state.uri.queryParameters['taskId']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/pip', builder: (_, _) => const PipScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ask', builder: (_, _) => const AskScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Phone-width column on wide viewports, tab bar at the bottom.
class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _PhoneColumn(
      child: Column(
        children: [
          Expanded(child: shell),
          GrindShellTabBar(shell: shell),
        ],
      ),
    );
  }
}

/// Centers [child] in a phone-width column on wide viewports so screens
/// reached outside the tab shell (e.g. `/settings`) match the tabbed screens'
/// layout instead of spanning the full width.
class _PhoneColumn extends StatelessWidget {
  const _PhoneColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
