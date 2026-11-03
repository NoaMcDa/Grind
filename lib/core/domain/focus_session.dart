/// Stub for phase 2 (#19). Kept in the schema from day one so the
/// momentum/analytics layers have somewhere to read from.
class FocusSession {
  const FocusSession({
    required this.id,
    this.taskId,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? taskId;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  int? get actualMinutes => endedAt?.difference(startedAt).inMinutes;
}
