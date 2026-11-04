import '../../core/domain/energy.dart';

/// Structured output a natural-language capture produces before the user
/// confirms it as a [Task]. Lives on the Ask screen's task card.
///
/// The LLM path (#38) emits this against [jsonSchema] with the Anthropic
/// structured-outputs format; the offline fallback parser emits it from
/// regex + date parsing. Downstream (the task card, then `task_form`)
/// turns a confirmed draft into a real [Task].
///
/// Dates and times are wall-clock in the user's zone: [date] is an
/// ISO-8601 calendar date (`YYYY-MM-DD`) and [time] is `HH:MM` on the
/// 24-hour clock. Keeping them as separate string fields matches the
/// Anthropic schema and leaves the UTC conversion to the caller, which
/// already knows the user's [tz.Location].
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.date,
    this.time,
    this.durationMinutes,
    this.energy,
    this.firstAction,
    this.recurrenceRrule,
  });

  /// Short, imperative task title. Required.
  final String title;

  /// `YYYY-MM-DD` in the user's zone, or null when no date was captured.
  final String? date;

  /// `HH:MM` on the 24-hour clock in the user's zone, or null when the
  /// phrase gave no explicit time.
  final String? time;

  /// Estimated duration in minutes. Null when nothing like "45 min" or
  /// "1h" was in the phrase.
  final int? durationMinutes;

  /// `Energy.deep` or `Energy.light`; null when the phrase gave no clue.
  final Energy? energy;

  /// The "if-then" first step the user confirms, e.g. "pack your bag".
  final String? firstAction;

  /// A plain RRULE body (no `RRULE:` prefix), e.g. `FREQ=WEEKLY;BYDAY=MO`,
  /// or null for a one-off task. Parses via `Recurrence.parse`.
  final String? recurrenceRrule;

  /// Both fields of [date] and [time] present and well-formed.
  bool get hasDateTime => date != null && time != null;

  TaskDraft copyWith({
    String? title,
    Object? date = _unset,
    Object? time = _unset,
    Object? durationMinutes = _unset,
    Object? energy = _unset,
    Object? firstAction = _unset,
    Object? recurrenceRrule = _unset,
  }) => TaskDraft(
    title: title ?? this.title,
    date: date == _unset ? this.date : date as String?,
    time: time == _unset ? this.time : time as String?,
    durationMinutes: durationMinutes == _unset
        ? this.durationMinutes
        : durationMinutes as int?,
    energy: energy == _unset ? this.energy : energy as Energy?,
    firstAction: firstAction == _unset
        ? this.firstAction
        : firstAction as String?,
    recurrenceRrule: recurrenceRrule == _unset
        ? this.recurrenceRrule
        : recurrenceRrule as String?,
  );

  Map<String, Object?> toJson() {
    final j = <String, Object?>{'title': title};
    if (date != null) j['date'] = date;
    if (time != null) j['time'] = time;
    if (durationMinutes != null) j['durationMinutes'] = durationMinutes;
    if (energy != null) j['energy'] = energy!.name;
    if (firstAction != null) j['firstAction'] = firstAction;
    if (recurrenceRrule != null) j['recurrence'] = recurrenceRrule;
    return j;
  }

  /// Parses a JSON map the LLM produced. Unknown or malformed fields
  /// become null (we trust the schema to keep them well-formed, but
  /// stay defensive).
  static TaskDraft fromJson(Map<String, Object?> json) {
    final title = (json['title'] as String?)?.trim();
    if (title == null || title.isEmpty) {
      throw const FormatException('TaskDraft.title is required');
    }
    return TaskDraft(
      title: title,
      date: _validDate(json['date']),
      time: _validTime(json['time']),
      durationMinutes: _validDuration(json['durationMinutes']),
      energy: _validEnergy(json['energy']),
      firstAction: (json['firstAction'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['firstAction'] as String).trim(),
      recurrenceRrule: (json['recurrence'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['recurrence'] as String).trim(),
    );
  }

  /// JSON schema for Anthropic structured outputs. `additionalProperties:
  /// false` on every object lets the model emit only these keys.
  static const Map<String, Object?> jsonSchema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['title'],
    'properties': {
      'title': {
        'type': 'string',
        'description':
            'Short imperative task title, in the language of the input.',
      },
      'date': {
        'type': 'string',
        'description':
            "ISO-8601 calendar date (YYYY-MM-DD) in the user's time zone, "
            'or omit when no date was given.',
        'pattern': r'^\d{4}-\d{2}-\d{2}$',
      },
      'time': {
        'type': 'string',
        'description':
            "HH:MM on the 24-hour clock in the user's time zone, or "
            'omit when no time was given.',
        'pattern': r'^([01]\d|2[0-3]):[0-5]\d$',
      },
      'durationMinutes': {
        'type': 'integer',
        'description': 'Estimated duration in minutes.',
        'minimum': 5,
        'maximum': 1440,
      },
      'energy': {
        'type': 'string',
        'description':
            '"deep" for focus-heavy work, "light" for errands / easy work.',
        'enum': ['deep', 'light'],
      },
      'firstAction': {
        'type': 'string',
        'description': 'The if-then first step, e.g. "pack your bag".',
      },
      'recurrence': {
        'type': 'string',
        'description':
            'RRULE body without the RRULE: prefix, '
            'e.g. FREQ=WEEKLY;BYDAY=MO. Omit for a one-off task.',
      },
    },
  };

  @override
  bool operator ==(Object other) =>
      other is TaskDraft &&
      other.title == title &&
      other.date == date &&
      other.time == time &&
      other.durationMinutes == durationMinutes &&
      other.energy == energy &&
      other.firstAction == firstAction &&
      other.recurrenceRrule == recurrenceRrule;

  @override
  int get hashCode => Object.hash(
    title,
    date,
    time,
    durationMinutes,
    energy,
    firstAction,
    recurrenceRrule,
  );

  @override
  String toString() {
    final parts = <String>['title: $title'];
    if (date != null) parts.add('date: $date');
    if (time != null) parts.add('time: $time');
    if (durationMinutes != null) parts.add('dur: ${durationMinutes}m');
    if (energy != null) parts.add('energy: ${energy!.name}');
    if (firstAction != null) parts.add('firstAction: $firstAction');
    if (recurrenceRrule != null) parts.add('rrule: $recurrenceRrule');
    return 'TaskDraft(${parts.join(', ')})';
  }
}

String? _validDate(Object? v) {
  if (v is! String) return null;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return null;
  final parts = v.split('-').map(int.parse).toList();
  final m = parts[1], d = parts[2];
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return v;
}

String? _validTime(Object? v) {
  if (v is! String) return null;
  if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v)) return null;
  return v;
}

int? _validDuration(Object? v) {
  if (v is int) return v < 5 || v > 1440 ? null : v;
  if (v is num) {
    final i = v.round();
    return i < 5 || i > 1440 ? null : i;
  }
  return null;
}

Energy? _validEnergy(Object? v) {
  if (v is! String) return null;
  for (final e in Energy.values) {
    if (e.name == v) return e;
  }
  return null;
}

const _unset = Object();
