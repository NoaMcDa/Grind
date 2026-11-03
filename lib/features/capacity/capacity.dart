/// Weekly capacity (#29) and auto-prioritization with manual override (#30).
///
/// Route `/week` -> [WeekCapacityScreen] (integrator wires it and links it
/// from the Plan capacity line). Weights live in `capacityConfigProvider`;
/// the plan scheduler should read `.weights` and pass them to `plan(...)`.
library;

export 'capacity_math.dart';
export 'capacity_providers.dart';
export 'capacity_settings.dart';
export 'json_doc_store.dart';
export 'preference_log.dart';
export 'priority_list.dart';
export 'priority_math.dart';
export 'week_bars.dart';
export 'week_capacity_screen.dart';
