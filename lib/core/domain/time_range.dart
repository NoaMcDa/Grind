/// A clock-time range inside one day, e.g. 09:00–12:00. End is exclusive.
class TimeRange {
  const TimeRange({required this.startMinutes, required this.endMinutes})
    : assert(startMinutes >= 0 && startMinutes < 24 * 60),
      assert(endMinutes > startMinutes && endMinutes <= 24 * 60);

  /// Minutes after midnight.
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;

  factory TimeRange.hm(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) => TimeRange(
    startMinutes: startHour * 60 + startMinute,
    endMinutes: endHour * 60 + endMinute,
  );

  Map<String, Object?> toJson() => {'start': startMinutes, 'end': endMinutes};

  factory TimeRange.fromJson(Map<String, Object?> json) => TimeRange(
    startMinutes: json['start'] as int,
    endMinutes: json['end'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is TimeRange &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes);

  @override
  String toString() => 'TimeRange($startMinutes-$endMinutes)';
}
