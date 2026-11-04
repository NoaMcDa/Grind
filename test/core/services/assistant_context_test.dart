import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

// All times UTC; the context builder is zone-agnostic, so the test picks a
// window that happens to be one Jerusalem day (Nov 3 2026, UTC+2) but
// nothing in the builder reads a zone database.
final _now = DateTime.utc(2026, 11, 3, 10);
final _todayStart = DateTime.utc(2026, 11, 2, 22); // Mon 00:00 Jerusalem
final _todayEnd = DateTime.utc(2026, 11, 3, 22); // Tue 00:00 Jerusalem
final _todayLocalDate = DateTime(2026, 11, 3); // weekday = Tuesday

Task _task({
  required String id,
  required String title,
  TaskStatus status = TaskStatus.open,
  int priority = 2,
  int estimatedMinutes = 30,
  Energy energy = Energy.light,
  DateTime? dueAt,
  DateTime? scheduledStart,
  DateTime? scheduledEnd,
  String? notes,
  String? goalId,
  DateTime? deletedAt,
}) => Task(
  id: id,
  title: title,
  status: status,
  priority: priority,
  estimatedMinutes: estimatedMinutes,
  energy: energy,
  dueAt: dueAt,
  scheduledStart: scheduledStart,
  scheduledEnd: scheduledEnd,
  notes: notes,
  goalId: goalId,
  createdAt: _now,
  updatedAt: _now,
  deletedAt: deletedAt,
);

Goal _goal({
  required String id,
  required String title,
  GoalStatus status = GoalStatus.active,
  double importance = 0.5,
  double progress = 0,
  DateTime? targetDate,
  String? area,
  String? notes,
  String? metricKind,
  int? metricTarget,
  int? metricCurrent,
  String? metricUnit,
  String? metricPeriod,
  DateTime? deletedAt,
}) => Goal(
  id: id,
  title: title,
  status: status,
  importance: importance,
  progress: progress,
  targetDate: targetDate,
  area: area,
  notes: notes,
  metricKind: metricKind,
  metricTarget: metricTarget,
  metricCurrent: metricCurrent,
  metricUnit: metricUnit,
  metricPeriod: metricPeriod,
  createdAt: _now,
  updatedAt: _now,
  deletedAt: deletedAt,
);

CalendarEvent _event({
  required String id,
  required String title,
  required DateTime start,
  required DateTime end,
  bool isAllDay = false,
  bool isBusy = true,
  DateTime? deletedAt,
}) => CalendarEvent(
  id: id,
  source: CalendarSource.google,
  externalId: 'ext-$id',
  title: title,
  start: start,
  end: end,
  isAllDay: isAllDay,
  isBusy: isBusy,
  createdAt: _now,
  updatedAt: _now,
  deletedAt: deletedAt,
);

const _prefs = Preferences(timeZoneName: 'Asia/Jerusalem', localeCode: 'en');

AssistantContext _build(
  AssistantContextBuilder b, {
  Iterable<Task> tasks = const [],
  Iterable<Goal> goals = const [],
  Iterable<CalendarEvent> events = const [],
  Preferences prefs = _prefs,
}) => b.build(
  now: _now,
  todayStart: _todayStart,
  todayEnd: _todayEnd,
  todayLocalDate: _todayLocalDate,
  tasks: tasks,
  goals: goals,
  events: events,
  preferences: prefs,
);

void main() {
  group('AssistantContextBuilder', () {
    test('includes the carried metadata and today weekday working hours', () {
      // Tuesday default: 09:00–18:00.
      final ctx = _build(const AssistantContextBuilder());

      expect(ctx.nowUtc, _now);
      expect(ctx.timeZoneName, 'Asia/Jerusalem');
      expect(ctx.localeCode, 'en');
      expect(ctx.workingHoursToday, hasLength(1));
      expect(ctx.workingHoursToday.single.startMinutes, 9 * 60);
      expect(ctx.workingHoursToday.single.endMinutes, 18 * 60);
    });

    test('a day off returns no working windows', () {
      // Default prefs have no Saturday entry.
      final saturday = DateTime(2026, 11, 7); // weekday = Saturday
      final ctx = const AssistantContextBuilder().build(
        now: _now,
        todayStart: _todayStart,
        todayEnd: _todayEnd,
        todayLocalDate: saturday,
        tasks: const [],
        goals: const [],
        events: const [],
        preferences: _prefs,
      );
      expect(ctx.workingHoursToday, isEmpty);
    });

    test('keeps only open, non-deleted tasks', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        tasks: [
          _task(id: 'open', title: 'write proposal'),
          _task(id: 'done', title: 'laundry', status: TaskStatus.done),
          _task(id: 'skipped', title: 'nap', status: TaskStatus.skipped),
          _task(
            id: 'deleted',
            title: 'ghost',
            deletedAt: DateTime.utc(2026, 10, 30),
          ),
        ],
      );
      expect(ctx.openTasks, hasLength(1));
      expect(ctx.openTasks.single.title, 'write proposal');
      expect(ctx.totals.openTasks, 1);
    });

    test('orders tasks by priority, then due date, then schedule, title', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        tasks: [
          _task(id: 'c', title: 'c', priority: 2),
          _task(id: 'a', title: 'a', priority: 1),
          _task(
            id: 'b',
            title: 'b',
            priority: 2,
            dueAt: DateTime.utc(2026, 11, 3),
          ),
          _task(id: 'd', title: 'd', priority: 3),
        ],
      );
      expect(ctx.openTasks.map((t) => t.title).toList(), ['a', 'b', 'c', 'd']);
    });

    test('excludes task notes by default and includes them when opted in', () {
      final withNotes = _task(id: '1', title: 't', notes: 'private');
      final defaultCtx = _build(
        const AssistantContextBuilder(),
        tasks: [withNotes],
      );
      expect(defaultCtx.openTasks.single.notes, isNull);
      expect(defaultCtx.includesTaskNotes, isFalse);
      expect(
        defaultCtx.toJson()['openTasks'],
        isA<List>().having(
          (l) => (l.first as Map).containsKey('notes'),
          'notes key omitted',
          isFalse,
        ),
      );

      final optedInCtx = _build(
        const AssistantContextBuilder(includeTaskNotes: true),
        tasks: [withNotes],
      );
      expect(optedInCtx.openTasks.single.notes, 'private');
      expect(optedInCtx.includesTaskNotes, isTrue);
    });

    test('event filter keeps only those overlapping today in UTC', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        events: [
          _event(
            id: 'before',
            title: 'yesterday',
            start: DateTime.utc(2026, 11, 2, 15),
            end: DateTime.utc(2026, 11, 2, 16),
          ),
          _event(
            id: 'mid',
            title: 'standup',
            start: DateTime.utc(2026, 11, 3, 7),
            end: DateTime.utc(2026, 11, 3, 7, 30),
          ),
          _event(
            id: 'spans-end',
            title: 'late call',
            start: DateTime.utc(2026, 11, 3, 21, 30),
            end: DateTime.utc(2026, 11, 3, 23),
          ),
          _event(
            id: 'after',
            title: 'tomorrow',
            start: DateTime.utc(2026, 11, 4, 8),
            end: DateTime.utc(2026, 11, 4, 9),
          ),
          _event(
            id: 'deleted',
            title: 'cancelled',
            start: DateTime.utc(2026, 11, 3, 10),
            end: DateTime.utc(2026, 11, 3, 11),
            deletedAt: DateTime.utc(2026, 11, 3),
          ),
        ],
      );
      expect(ctx.todayEvents.map((e) => e.title).toList(), [
        'standup',
        'late call',
      ]);
    });

    test('event titles can be redacted while keeping windows', () {
      final ctx = _build(
        const AssistantContextBuilder(includeEventTitles: false),
        events: [
          _event(
            id: '1',
            title: '1:1 with therapist',
            start: DateTime.utc(2026, 11, 3, 10),
            end: DateTime.utc(2026, 11, 3, 11),
          ),
        ],
      );
      final event = ctx.todayEvents.single;
      expect(event.title, isNull);
      expect(event.startUtc, DateTime.utc(2026, 11, 3, 10));
      expect(event.endUtc, DateTime.utc(2026, 11, 3, 11));
      expect(ctx.includesEventTitles, isFalse);
      expect(
        (ctx.toJson()['todayEvents'] as List).first,
        isNot(contains('title')),
      );
    });

    test('goals keep only active ones, ordered by importance desc', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        goals: [
          _goal(id: 'low', title: 'low', importance: 0.2),
          _goal(id: 'done', title: 'd', status: GoalStatus.done),
          _goal(id: 'high', title: 'high', importance: 0.9),
          _goal(id: 'mid', title: 'mid', importance: 0.5),
          _goal(id: 'del', title: 'g', deletedAt: DateTime.utc(2026, 10, 1)),
        ],
      );
      expect(ctx.activeGoals.map((g) => g.title).toList(), [
        'high',
        'mid',
        'low',
      ]);
    });

    test('goal notes opt-out by default; metric fields flow through', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        goals: [
          _goal(
            id: '1',
            title: 'PM course',
            notes: 'private motivation',
            metricKind: 'finite',
            metricTarget: 12,
            metricCurrent: 8,
            metricUnit: 'lessons',
          ),
        ],
      );
      final g = ctx.activeGoals.single;
      expect(g.notes, isNull);
      expect(g.metric?.kind, 'finite');
      expect(g.metric?.target, 12);
      expect(g.metric?.current, 8);
      expect(g.metric?.unit, 'lessons');
      expect(ctx.includesGoalNotes, isFalse);

      final optedInCtx = _build(
        const AssistantContextBuilder(includeGoalNotes: true),
        goals: [_goal(id: '1', title: 'g', notes: 'why')],
      );
      expect(optedInCtx.activeGoals.single.notes, 'why');
      expect(optedInCtx.includesGoalNotes, isTrue);
    });

    test('size caps truncate lists and the totals keep the real counts', () {
      final many = [
        for (var i = 0; i < 25; i++)
          _task(
            id: 't$i',
            title: 'task-${i.toString().padLeft(2, '0')}',
            priority: 2,
          ),
      ];
      final ctx = _build(
        const AssistantContextBuilder(maxOpenTasks: 5),
        tasks: many,
      );
      expect(ctx.openTasks, hasLength(5));
      expect(ctx.totals.openTasks, 25);
      expect(ctx.truncated, isTrue);
    });

    test('not truncated when lists fit under their caps', () {
      final ctx = _build(
        const AssistantContextBuilder(),
        tasks: [_task(id: '1', title: 'one')],
      );
      expect(ctx.truncated, isFalse);
    });

    test('task summary carries the fields the LLM needs, nothing more', () {
      final t = _task(
        id: '1',
        title: 'draft outline',
        priority: 1,
        estimatedMinutes: 45,
        energy: Energy.deep,
        dueAt: DateTime.utc(2026, 11, 4),
        scheduledStart: DateTime.utc(2026, 11, 3, 9),
        scheduledEnd: DateTime.utc(2026, 11, 3, 10),
        goalId: 'g1',
      );
      final s = _build(
        const AssistantContextBuilder(),
        tasks: [t],
      ).openTasks.single;
      expect(s.title, 'draft outline');
      expect(s.priority, 1);
      expect(s.estimatedMinutes, 45);
      expect(s.energy, Energy.deep);
      expect(s.dueAtUtc, DateTime.utc(2026, 11, 4));
      expect(s.scheduledStartUtc, DateTime.utc(2026, 11, 3, 9));
      expect(s.linkedToGoal, isTrue);

      final json = s.toJson();
      // No id, no goalId, no reminders, no calendar back-pointer.
      expect(json.keys, [
        'title',
        'estimatedMinutes',
        'priority',
        'energy',
        'dueAtUtc',
        'scheduledStartUtc',
        'linkedToGoal',
      ]);
    });

    test('toJson is deterministic and includes top-level flags', () {
      final json = _build(const AssistantContextBuilder()).toJson();
      expect(json['timeZoneName'], 'Asia/Jerusalem');
      expect(json['localeCode'], 'en');
      expect(json['includesTaskNotes'], isFalse);
      expect(json['includesGoalNotes'], isFalse);
      expect(json['includesEventTitles'], isTrue);
      expect(json['truncated'], isFalse);
      expect(json['totals'], {
        'openTasks': 0,
        'todayEvents': 0,
        'activeGoals': 0,
      });
    });
  });
}
