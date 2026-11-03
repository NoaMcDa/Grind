/// Deterministic scheduler core (#16): pure functions of
/// `(tasks, events, prefs, stats, now)`, no I/O, no clock reads, no Riverpod.
/// The Riverpod wiring lives in `providers.dart`. See README.md.
library;

export 'capacity.dart'
    show weekCapacity, deferralSuggestions, avgFreeHoursPerDay, capacitySummary;
export 'free_slots.dart'
    show freeSlots, freeSlotsForDay, blocksTime, minSlotMinutes;
export 'models.dart';
export 'planner.dart' show plan, defaultHorizonEnd, isOpenTask, isPinned;
export 'replan.dart';
export 'scheduler_service.dart';
export 'scoring.dart';
