import 'package:flutter/material.dart';

import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GrindApp());
}

class GrindApp extends StatelessWidget {
  const GrindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grind',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
