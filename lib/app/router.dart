import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ask/ask_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/pip/pip_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/today/today_screen.dart';
import '../theme/tokens.dart';
import 'tab_bar.dart';
import 'task_placeholder.dart';

/// Builds the app router: five tabs in a [StatefulShellRoute.indexedStack]
/// plus deep links.
///
/// - `/today`, `/plan`, `/focus`, `/pip`, `/ask`: the tabs
/// - `/focus?taskId=abc`: Focus tab for a task
/// - `/task/:id`: task detail (placeholder until the tasks feature lands)
GoRouter createRouter({String initialLocation = '/today'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/today'),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) =>
            TaskPlaceholderPage(taskId: state.pathParameters['id']!),
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
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(child: shell),
              GrindShellTabBar(shell: shell),
            ],
          ),
        ),
      ),
    );
  }
}
