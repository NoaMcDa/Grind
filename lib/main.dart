import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/demo_seed.dart';

void main() {
  // Demo data until the real database (#2) and services (#5) are wired in.
  runApp(GrindApp(overrides: [...demoOverrides()]));
}
