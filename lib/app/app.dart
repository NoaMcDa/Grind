import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
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

class _RouterApp extends StatefulWidget {
  const _RouterApp({required this.initialLocation});

  final String initialLocation;

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Grind',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
