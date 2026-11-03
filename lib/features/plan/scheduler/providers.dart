import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import 'scheduler_service.dart';

/// The scheduler, with `now` from [clockProvider]. Override [clockProvider]
/// with a `FixedClock` in tests.
final schedulerProvider = Provider<SchedulerService>(
  (ref) => SchedulerService(ref.watch(clockProvider)),
);
