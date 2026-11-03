/// A clock-time range inside one day, e.g. 09:00–12:00. End is exclusive.
///
/// The default constructor is a plain range (`end > start`, at most 24:00).
/// [TimeRange.wrapping] also allows `end <= start`, which means the range
/// crosses midnight (22:00–07:00); only quiet hours use that today.
class TimeRange {
  const TimeRange({required this.startMinutes, required this.endMinutes})
    : assert(startMinutes >= 0 && startMinutes < _day),
      assert(endMinutes > startMinutes && endMinutes <= _day);

  /// A range that may cross midnight: `end <= start` means it runs from
  /// [startMinutes] to midnight and on to [endMinutes] the next day.
  /// `end == start` is not allowed (it would be empty or the whole day).
  const TimeRange.wrapping({
    required this.startMinutes,
    required this.endMinutes,
  }) : assert(startMinutes >= 0 && startMinutes < _day),
       assert(endMinutes >= 0 && endMinutes <= _day),
       assert(endMinutes != startMinutes);

  static const _day = 24 * 60;

  /// Minutes after midnight.
  final int startMinutes;
  final int endMinutes;

  /// True when the range crosses midnight (only via [TimeRange.wrapping]).
  bool get wrapsMidnight => endMinutes <= startMinutes;

  int get durationMinutes => wrapsMidnight
      ? _day - startMinutes + endMinutes
      : endMinutes - startMinutes;

  /// Whether the clock time [minuteOfDay] (0..1439) is inside the range.
  bool contains(int minuteOfDay) => wrapsMidnight
      ? minuteOfDay >= startMinutes || minuteOfDay < endMinutes
      : minuteOfDay >= startMinutes && minuteOfDay < endMinutes;

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

  /// Reads `{"start": .., "end": ..}`. Validates explicitly (asserts are off
  /// in release builds) and throws a [FormatException] on bad values. With
  /// [allowWrap], `end <= start` is read as a range across midnight.
  factory TimeRange.fromJson(
    Map<String, Object?> json, {
    bool allowWrap = false,
  }) {
    final start = json['start'];
    final end = json['end'];
    if (start is! int || end is! int) {
      throw FormatException('A time range needs whole-minute start and end.');
    }
    if (start < 0 || start >= _day || end < 0 || end > _day) {
      throw FormatException('Time range $start-$end is outside one day.');
    }
    if (end > start) return TimeRange(startMinutes: start, endMinutes: end);
    if (allowWrap && end != start) {
      return TimeRange.wrapping(startMinutes: start, endMinutes: end);
    }
    throw FormatException('Time range $start-$end ends before it starts.');
  }

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
