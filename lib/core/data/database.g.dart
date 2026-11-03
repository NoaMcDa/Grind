// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledStartMeta = const VerificationMeta(
    'scheduledStart',
  );
  @override
  late final GeneratedColumn<int> scheduledStart = GeneratedColumn<int>(
    'scheduled_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledEndMeta = const VerificationMeta(
    'scheduledEnd',
  );
  @override
  late final GeneratedColumn<int> scheduledEnd = GeneratedColumn<int>(
    'scheduled_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedStartMeta = const VerificationMeta(
    'lockedStart',
  );
  @override
  late final GeneratedColumn<bool> lockedStart = GeneratedColumn<bool>(
    'locked_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked_start" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notBeforeMeta = const VerificationMeta(
    'notBefore',
  );
  @override
  late final GeneratedColumn<int> notBefore = GeneratedColumn<int>(
    'not_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minutesDoneMeta = const VerificationMeta(
    'minutesDone',
  );
  @override
  late final GeneratedColumn<int> minutesDone = GeneratedColumn<int>(
    'minutes_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta(
    'estimatedMinutes',
  );
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Energy, String> energy =
      GeneratedColumn<String>(
        'energy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(Energy.light.name),
      ).withConverter<Energy>($TasksTable.$converterenergy);
  static const VerificationMeta _firstActionMeta = const VerificationMeta(
    'firstAction',
  );
  @override
  late final GeneratedColumn<String> firstAction = GeneratedColumn<String>(
    'first_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splittableMeta = const VerificationMeta(
    'splittable',
  );
  @override
  late final GeneratedColumn<bool> splittable = GeneratedColumn<bool>(
    'splittable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("splittable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _minChunkMinutesMeta = const VerificationMeta(
    'minChunkMinutes',
  );
  @override
  late final GeneratedColumn<int> minChunkMinutes = GeneratedColumn<int>(
    'min_chunk_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(TaskStatus.open.name),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinutesMeta = const VerificationMeta(
    'actualMinutes',
  );
  @override
  late final GeneratedColumn<int> actualMinutes = GeneratedColumn<int>(
    'actual_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeCountMeta = const VerificationMeta(
    'snoozeCount',
  );
  @override
  late final GeneratedColumn<int> snoozeCount = GeneratedColumn<int>(
    'snooze_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _calendarEventIdMeta = const VerificationMeta(
    'calendarEventId',
  );
  @override
  late final GeneratedColumn<String> calendarEventId = GeneratedColumn<String>(
    'calendar_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    notes,
    goalId,
    dueAt,
    remindAt,
    scheduledStart,
    scheduledEnd,
    lockedStart,
    notBefore,
    minutesDone,
    estimatedMinutes,
    energy,
    firstAction,
    priority,
    category,
    splittable,
    minChunkMinutes,
    status,
    completedAt,
    actualMinutes,
    snoozeCount,
    calendarEventId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('scheduled_start')) {
      context.handle(
        _scheduledStartMeta,
        scheduledStart.isAcceptableOrUnknown(
          data['scheduled_start']!,
          _scheduledStartMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_end')) {
      context.handle(
        _scheduledEndMeta,
        scheduledEnd.isAcceptableOrUnknown(
          data['scheduled_end']!,
          _scheduledEndMeta,
        ),
      );
    }
    if (data.containsKey('locked_start')) {
      context.handle(
        _lockedStartMeta,
        lockedStart.isAcceptableOrUnknown(
          data['locked_start']!,
          _lockedStartMeta,
        ),
      );
    }
    if (data.containsKey('not_before')) {
      context.handle(
        _notBeforeMeta,
        notBefore.isAcceptableOrUnknown(data['not_before']!, _notBeforeMeta),
      );
    }
    if (data.containsKey('minutes_done')) {
      context.handle(
        _minutesDoneMeta,
        minutesDone.isAcceptableOrUnknown(
          data['minutes_done']!,
          _minutesDoneMeta,
        ),
      );
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
        _estimatedMinutesMeta,
        estimatedMinutes.isAcceptableOrUnknown(
          data['estimated_minutes']!,
          _estimatedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('first_action')) {
      context.handle(
        _firstActionMeta,
        firstAction.isAcceptableOrUnknown(
          data['first_action']!,
          _firstActionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('splittable')) {
      context.handle(
        _splittableMeta,
        splittable.isAcceptableOrUnknown(data['splittable']!, _splittableMeta),
      );
    }
    if (data.containsKey('min_chunk_minutes')) {
      context.handle(
        _minChunkMinutesMeta,
        minChunkMinutes.isAcceptableOrUnknown(
          data['min_chunk_minutes']!,
          _minChunkMinutesMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('actual_minutes')) {
      context.handle(
        _actualMinutesMeta,
        actualMinutes.isAcceptableOrUnknown(
          data['actual_minutes']!,
          _actualMinutesMeta,
        ),
      );
    }
    if (data.containsKey('snooze_count')) {
      context.handle(
        _snoozeCountMeta,
        snoozeCount.isAcceptableOrUnknown(
          data['snooze_count']!,
          _snoozeCountMeta,
        ),
      );
    }
    if (data.containsKey('calendar_event_id')) {
      context.handle(
        _calendarEventIdMeta,
        calendarEventId.isAcceptableOrUnknown(
          data['calendar_event_id']!,
          _calendarEventIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      ),
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      ),
      scheduledStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_start'],
      ),
      scheduledEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_end'],
      ),
      lockedStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked_start'],
      )!,
      notBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}not_before'],
      ),
      minutesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_done'],
      )!,
      estimatedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_minutes'],
      )!,
      energy: $TasksTable.$converterenergy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}energy'],
        )!,
      ),
      firstAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_action'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      splittable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}splittable'],
      )!,
      minChunkMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_chunk_minutes'],
      )!,
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      actualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minutes'],
      ),
      snoozeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_count'],
      )!,
      calendarEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_event_id'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Energy, String, String> $converterenergy =
      const EnumNameConverter<Energy>(Energy.values);
  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String title;
  final String? notes;
  final String? goalId;
  final int? dueAt;
  final int? remindAt;
  final int? scheduledStart;
  final int? scheduledEnd;
  final bool lockedStart;
  final int? notBefore;
  final int minutesDone;
  final int estimatedMinutes;
  final Energy energy;
  final String? firstAction;
  final int priority;
  final String? category;
  final bool splittable;
  final int minChunkMinutes;
  final TaskStatus status;
  final int? completedAt;
  final int? actualMinutes;
  final int snoozeCount;
  final String? calendarEventId;
  const TaskRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    this.notes,
    this.goalId,
    this.dueAt,
    this.remindAt,
    this.scheduledStart,
    this.scheduledEnd,
    required this.lockedStart,
    this.notBefore,
    required this.minutesDone,
    required this.estimatedMinutes,
    required this.energy,
    this.firstAction,
    required this.priority,
    this.category,
    required this.splittable,
    required this.minChunkMinutes,
    required this.status,
    this.completedAt,
    this.actualMinutes,
    required this.snoozeCount,
    this.calendarEventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<int>(remindAt);
    }
    if (!nullToAbsent || scheduledStart != null) {
      map['scheduled_start'] = Variable<int>(scheduledStart);
    }
    if (!nullToAbsent || scheduledEnd != null) {
      map['scheduled_end'] = Variable<int>(scheduledEnd);
    }
    map['locked_start'] = Variable<bool>(lockedStart);
    if (!nullToAbsent || notBefore != null) {
      map['not_before'] = Variable<int>(notBefore);
    }
    map['minutes_done'] = Variable<int>(minutesDone);
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    {
      map['energy'] = Variable<String>(
        $TasksTable.$converterenergy.toSql(energy),
      );
    }
    if (!nullToAbsent || firstAction != null) {
      map['first_action'] = Variable<String>(firstAction);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['splittable'] = Variable<bool>(splittable);
    map['min_chunk_minutes'] = Variable<int>(minChunkMinutes);
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || actualMinutes != null) {
      map['actual_minutes'] = Variable<int>(actualMinutes);
    }
    map['snooze_count'] = Variable<int>(snoozeCount);
    if (!nullToAbsent || calendarEventId != null) {
      map['calendar_event_id'] = Variable<String>(calendarEventId);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      scheduledStart: scheduledStart == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledStart),
      scheduledEnd: scheduledEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledEnd),
      lockedStart: Value(lockedStart),
      notBefore: notBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(notBefore),
      minutesDone: Value(minutesDone),
      estimatedMinutes: Value(estimatedMinutes),
      energy: Value(energy),
      firstAction: firstAction == null && nullToAbsent
          ? const Value.absent()
          : Value(firstAction),
      priority: Value(priority),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      splittable: Value(splittable),
      minChunkMinutes: Value(minChunkMinutes),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      actualMinutes: actualMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(actualMinutes),
      snoozeCount: Value(snoozeCount),
      calendarEventId: calendarEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarEventId),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      remindAt: serializer.fromJson<int?>(json['remindAt']),
      scheduledStart: serializer.fromJson<int?>(json['scheduledStart']),
      scheduledEnd: serializer.fromJson<int?>(json['scheduledEnd']),
      lockedStart: serializer.fromJson<bool>(json['lockedStart']),
      notBefore: serializer.fromJson<int?>(json['notBefore']),
      minutesDone: serializer.fromJson<int>(json['minutesDone']),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
      energy: $TasksTable.$converterenergy.fromJson(
        serializer.fromJson<String>(json['energy']),
      ),
      firstAction: serializer.fromJson<String?>(json['firstAction']),
      priority: serializer.fromJson<int>(json['priority']),
      category: serializer.fromJson<String?>(json['category']),
      splittable: serializer.fromJson<bool>(json['splittable']),
      minChunkMinutes: serializer.fromJson<int>(json['minChunkMinutes']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      actualMinutes: serializer.fromJson<int?>(json['actualMinutes']),
      snoozeCount: serializer.fromJson<int>(json['snoozeCount']),
      calendarEventId: serializer.fromJson<String?>(json['calendarEventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'goalId': serializer.toJson<String?>(goalId),
      'dueAt': serializer.toJson<int?>(dueAt),
      'remindAt': serializer.toJson<int?>(remindAt),
      'scheduledStart': serializer.toJson<int?>(scheduledStart),
      'scheduledEnd': serializer.toJson<int?>(scheduledEnd),
      'lockedStart': serializer.toJson<bool>(lockedStart),
      'notBefore': serializer.toJson<int?>(notBefore),
      'minutesDone': serializer.toJson<int>(minutesDone),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
      'energy': serializer.toJson<String>(
        $TasksTable.$converterenergy.toJson(energy),
      ),
      'firstAction': serializer.toJson<String?>(firstAction),
      'priority': serializer.toJson<int>(priority),
      'category': serializer.toJson<String?>(category),
      'splittable': serializer.toJson<bool>(splittable),
      'minChunkMinutes': serializer.toJson<int>(minChunkMinutes),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'completedAt': serializer.toJson<int?>(completedAt),
      'actualMinutes': serializer.toJson<int?>(actualMinutes),
      'snoozeCount': serializer.toJson<int>(snoozeCount),
      'calendarEventId': serializer.toJson<String?>(calendarEventId),
    };
  }

  TaskRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<String?> goalId = const Value.absent(),
    Value<int?> dueAt = const Value.absent(),
    Value<int?> remindAt = const Value.absent(),
    Value<int?> scheduledStart = const Value.absent(),
    Value<int?> scheduledEnd = const Value.absent(),
    bool? lockedStart,
    Value<int?> notBefore = const Value.absent(),
    int? minutesDone,
    int? estimatedMinutes,
    Energy? energy,
    Value<String?> firstAction = const Value.absent(),
    int? priority,
    Value<String?> category = const Value.absent(),
    bool? splittable,
    int? minChunkMinutes,
    TaskStatus? status,
    Value<int?> completedAt = const Value.absent(),
    Value<int?> actualMinutes = const Value.absent(),
    int? snoozeCount,
    Value<String?> calendarEventId = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    goalId: goalId.present ? goalId.value : this.goalId,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    scheduledStart: scheduledStart.present
        ? scheduledStart.value
        : this.scheduledStart,
    scheduledEnd: scheduledEnd.present ? scheduledEnd.value : this.scheduledEnd,
    lockedStart: lockedStart ?? this.lockedStart,
    notBefore: notBefore.present ? notBefore.value : this.notBefore,
    minutesDone: minutesDone ?? this.minutesDone,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    energy: energy ?? this.energy,
    firstAction: firstAction.present ? firstAction.value : this.firstAction,
    priority: priority ?? this.priority,
    category: category.present ? category.value : this.category,
    splittable: splittable ?? this.splittable,
    minChunkMinutes: minChunkMinutes ?? this.minChunkMinutes,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    actualMinutes: actualMinutes.present
        ? actualMinutes.value
        : this.actualMinutes,
    snoozeCount: snoozeCount ?? this.snoozeCount,
    calendarEventId: calendarEventId.present
        ? calendarEventId.value
        : this.calendarEventId,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      scheduledStart: data.scheduledStart.present
          ? data.scheduledStart.value
          : this.scheduledStart,
      scheduledEnd: data.scheduledEnd.present
          ? data.scheduledEnd.value
          : this.scheduledEnd,
      lockedStart: data.lockedStart.present
          ? data.lockedStart.value
          : this.lockedStart,
      notBefore: data.notBefore.present ? data.notBefore.value : this.notBefore,
      minutesDone: data.minutesDone.present
          ? data.minutesDone.value
          : this.minutesDone,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      energy: data.energy.present ? data.energy.value : this.energy,
      firstAction: data.firstAction.present
          ? data.firstAction.value
          : this.firstAction,
      priority: data.priority.present ? data.priority.value : this.priority,
      category: data.category.present ? data.category.value : this.category,
      splittable: data.splittable.present
          ? data.splittable.value
          : this.splittable,
      minChunkMinutes: data.minChunkMinutes.present
          ? data.minChunkMinutes.value
          : this.minChunkMinutes,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      actualMinutes: data.actualMinutes.present
          ? data.actualMinutes.value
          : this.actualMinutes,
      snoozeCount: data.snoozeCount.present
          ? data.snoozeCount.value
          : this.snoozeCount,
      calendarEventId: data.calendarEventId.present
          ? data.calendarEventId.value
          : this.calendarEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('goalId: $goalId, ')
          ..write('dueAt: $dueAt, ')
          ..write('remindAt: $remindAt, ')
          ..write('scheduledStart: $scheduledStart, ')
          ..write('scheduledEnd: $scheduledEnd, ')
          ..write('lockedStart: $lockedStart, ')
          ..write('notBefore: $notBefore, ')
          ..write('minutesDone: $minutesDone, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('energy: $energy, ')
          ..write('firstAction: $firstAction, ')
          ..write('priority: $priority, ')
          ..write('category: $category, ')
          ..write('splittable: $splittable, ')
          ..write('minChunkMinutes: $minChunkMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('calendarEventId: $calendarEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    notes,
    goalId,
    dueAt,
    remindAt,
    scheduledStart,
    scheduledEnd,
    lockedStart,
    notBefore,
    minutesDone,
    estimatedMinutes,
    energy,
    firstAction,
    priority,
    category,
    splittable,
    minChunkMinutes,
    status,
    completedAt,
    actualMinutes,
    snoozeCount,
    calendarEventId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.goalId == this.goalId &&
          other.dueAt == this.dueAt &&
          other.remindAt == this.remindAt &&
          other.scheduledStart == this.scheduledStart &&
          other.scheduledEnd == this.scheduledEnd &&
          other.lockedStart == this.lockedStart &&
          other.notBefore == this.notBefore &&
          other.minutesDone == this.minutesDone &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.energy == this.energy &&
          other.firstAction == this.firstAction &&
          other.priority == this.priority &&
          other.category == this.category &&
          other.splittable == this.splittable &&
          other.minChunkMinutes == this.minChunkMinutes &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.actualMinutes == this.actualMinutes &&
          other.snoozeCount == this.snoozeCount &&
          other.calendarEventId == this.calendarEventId);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String?> goalId;
  final Value<int?> dueAt;
  final Value<int?> remindAt;
  final Value<int?> scheduledStart;
  final Value<int?> scheduledEnd;
  final Value<bool> lockedStart;
  final Value<int?> notBefore;
  final Value<int> minutesDone;
  final Value<int> estimatedMinutes;
  final Value<Energy> energy;
  final Value<String?> firstAction;
  final Value<int> priority;
  final Value<String?> category;
  final Value<bool> splittable;
  final Value<int> minChunkMinutes;
  final Value<TaskStatus> status;
  final Value<int?> completedAt;
  final Value<int?> actualMinutes;
  final Value<int> snoozeCount;
  final Value<String?> calendarEventId;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.goalId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.scheduledStart = const Value.absent(),
    this.scheduledEnd = const Value.absent(),
    this.lockedStart = const Value.absent(),
    this.notBefore = const Value.absent(),
    this.minutesDone = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.firstAction = const Value.absent(),
    this.priority = const Value.absent(),
    this.category = const Value.absent(),
    this.splittable = const Value.absent(),
    this.minChunkMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.goalId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.scheduledStart = const Value.absent(),
    this.scheduledEnd = const Value.absent(),
    this.lockedStart = const Value.absent(),
    this.notBefore = const Value.absent(),
    this.minutesDone = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.firstAction = const Value.absent(),
    this.priority = const Value.absent(),
    this.category = const Value.absent(),
    this.splittable = const Value.absent(),
    this.minChunkMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       title = Value(title);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? goalId,
    Expression<int>? dueAt,
    Expression<int>? remindAt,
    Expression<int>? scheduledStart,
    Expression<int>? scheduledEnd,
    Expression<bool>? lockedStart,
    Expression<int>? notBefore,
    Expression<int>? minutesDone,
    Expression<int>? estimatedMinutes,
    Expression<String>? energy,
    Expression<String>? firstAction,
    Expression<int>? priority,
    Expression<String>? category,
    Expression<bool>? splittable,
    Expression<int>? minChunkMinutes,
    Expression<String>? status,
    Expression<int>? completedAt,
    Expression<int>? actualMinutes,
    Expression<int>? snoozeCount,
    Expression<String>? calendarEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (goalId != null) 'goal_id': goalId,
      if (dueAt != null) 'due_at': dueAt,
      if (remindAt != null) 'remind_at': remindAt,
      if (scheduledStart != null) 'scheduled_start': scheduledStart,
      if (scheduledEnd != null) 'scheduled_end': scheduledEnd,
      if (lockedStart != null) 'locked_start': lockedStart,
      if (notBefore != null) 'not_before': notBefore,
      if (minutesDone != null) 'minutes_done': minutesDone,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (energy != null) 'energy': energy,
      if (firstAction != null) 'first_action': firstAction,
      if (priority != null) 'priority': priority,
      if (category != null) 'category': category,
      if (splittable != null) 'splittable': splittable,
      if (minChunkMinutes != null) 'min_chunk_minutes': minChunkMinutes,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (snoozeCount != null) 'snooze_count': snoozeCount,
      if (calendarEventId != null) 'calendar_event_id': calendarEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? title,
    Value<String?>? notes,
    Value<String?>? goalId,
    Value<int?>? dueAt,
    Value<int?>? remindAt,
    Value<int?>? scheduledStart,
    Value<int?>? scheduledEnd,
    Value<bool>? lockedStart,
    Value<int?>? notBefore,
    Value<int>? minutesDone,
    Value<int>? estimatedMinutes,
    Value<Energy>? energy,
    Value<String?>? firstAction,
    Value<int>? priority,
    Value<String?>? category,
    Value<bool>? splittable,
    Value<int>? minChunkMinutes,
    Value<TaskStatus>? status,
    Value<int?>? completedAt,
    Value<int?>? actualMinutes,
    Value<int>? snoozeCount,
    Value<String?>? calendarEventId,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      goalId: goalId ?? this.goalId,
      dueAt: dueAt ?? this.dueAt,
      remindAt: remindAt ?? this.remindAt,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      lockedStart: lockedStart ?? this.lockedStart,
      notBefore: notBefore ?? this.notBefore,
      minutesDone: minutesDone ?? this.minutesDone,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energy: energy ?? this.energy,
      firstAction: firstAction ?? this.firstAction,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      splittable: splittable ?? this.splittable,
      minChunkMinutes: minChunkMinutes ?? this.minChunkMinutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (scheduledStart.present) {
      map['scheduled_start'] = Variable<int>(scheduledStart.value);
    }
    if (scheduledEnd.present) {
      map['scheduled_end'] = Variable<int>(scheduledEnd.value);
    }
    if (lockedStart.present) {
      map['locked_start'] = Variable<bool>(lockedStart.value);
    }
    if (notBefore.present) {
      map['not_before'] = Variable<int>(notBefore.value);
    }
    if (minutesDone.present) {
      map['minutes_done'] = Variable<int>(minutesDone.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (energy.present) {
      map['energy'] = Variable<String>(
        $TasksTable.$converterenergy.toSql(energy.value),
      );
    }
    if (firstAction.present) {
      map['first_action'] = Variable<String>(firstAction.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (splittable.present) {
      map['splittable'] = Variable<bool>(splittable.value);
    }
    if (minChunkMinutes.present) {
      map['min_chunk_minutes'] = Variable<int>(minChunkMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (actualMinutes.present) {
      map['actual_minutes'] = Variable<int>(actualMinutes.value);
    }
    if (snoozeCount.present) {
      map['snooze_count'] = Variable<int>(snoozeCount.value);
    }
    if (calendarEventId.present) {
      map['calendar_event_id'] = Variable<String>(calendarEventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('goalId: $goalId, ')
          ..write('dueAt: $dueAt, ')
          ..write('remindAt: $remindAt, ')
          ..write('scheduledStart: $scheduledStart, ')
          ..write('scheduledEnd: $scheduledEnd, ')
          ..write('lockedStart: $lockedStart, ')
          ..write('notBefore: $notBefore, ')
          ..write('minutesDone: $minutesDone, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('energy: $energy, ')
          ..write('firstAction: $firstAction, ')
          ..write('priority: $priority, ')
          ..write('category: $category, ')
          ..write('splittable: $splittable, ')
          ..write('minChunkMinutes: $minChunkMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderRulesTable extends ReminderRules
    with TableInfo<$ReminderRulesTable, ReminderRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leadMinutesMeta = const VerificationMeta(
    'leadMinutes',
  );
  @override
  late final GeneratedColumn<int> leadMinutes = GeneratedColumn<int>(
    'lead_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _untilMeta = const VerificationMeta('until');
  @override
  late final GeneratedColumn<int> until = GeneratedColumn<int>(
    'until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    taskId,
    rrule,
    leadMinutes,
    until,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    } else if (isInserting) {
      context.missing(_rruleMeta);
    }
    if (data.containsKey('lead_minutes')) {
      context.handle(
        _leadMinutesMeta,
        leadMinutes.isAcceptableOrUnknown(
          data['lead_minutes']!,
          _leadMinutesMeta,
        ),
      );
    }
    if (data.containsKey('until')) {
      context.handle(
        _untilMeta,
        until.isAcceptableOrUnknown(data['until']!, _untilMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      )!,
      leadMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lead_minutes'],
      )!,
      until: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}until'],
      ),
    );
  }

  @override
  $ReminderRulesTable createAlias(String alias) {
    return $ReminderRulesTable(attachedDatabase, alias);
  }
}

class ReminderRuleRow extends DataClass implements Insertable<ReminderRuleRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String taskId;
  final String rrule;
  final int leadMinutes;
  final int? until;
  const ReminderRuleRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.taskId,
    required this.rrule,
    required this.leadMinutes,
    this.until,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['task_id'] = Variable<String>(taskId);
    map['rrule'] = Variable<String>(rrule);
    map['lead_minutes'] = Variable<int>(leadMinutes);
    if (!nullToAbsent || until != null) {
      map['until'] = Variable<int>(until);
    }
    return map;
  }

  ReminderRulesCompanion toCompanion(bool nullToAbsent) {
    return ReminderRulesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      taskId: Value(taskId),
      rrule: Value(rrule),
      leadMinutes: Value(leadMinutes),
      until: until == null && nullToAbsent
          ? const Value.absent()
          : Value(until),
    );
  }

  factory ReminderRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRuleRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      taskId: serializer.fromJson<String>(json['taskId']),
      rrule: serializer.fromJson<String>(json['rrule']),
      leadMinutes: serializer.fromJson<int>(json['leadMinutes']),
      until: serializer.fromJson<int?>(json['until']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'taskId': serializer.toJson<String>(taskId),
      'rrule': serializer.toJson<String>(rrule),
      'leadMinutes': serializer.toJson<int>(leadMinutes),
      'until': serializer.toJson<int?>(until),
    };
  }

  ReminderRuleRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? taskId,
    String? rrule,
    int? leadMinutes,
    Value<int?> until = const Value.absent(),
  }) => ReminderRuleRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId ?? this.taskId,
    rrule: rrule ?? this.rrule,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    until: until.present ? until.value : this.until,
  );
  ReminderRuleRow copyWithCompanion(ReminderRulesCompanion data) {
    return ReminderRuleRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      leadMinutes: data.leadMinutes.present
          ? data.leadMinutes.value
          : this.leadMinutes,
      until: data.until.present ? data.until.value : this.until,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRuleRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('rrule: $rrule, ')
          ..write('leadMinutes: $leadMinutes, ')
          ..write('until: $until')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    taskId,
    rrule,
    leadMinutes,
    until,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRuleRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.rrule == this.rrule &&
          other.leadMinutes == this.leadMinutes &&
          other.until == this.until);
}

class ReminderRulesCompanion extends UpdateCompanion<ReminderRuleRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> taskId;
  final Value<String> rrule;
  final Value<int> leadMinutes;
  final Value<int?> until;
  final Value<int> rowid;
  const ReminderRulesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.rrule = const Value.absent(),
    this.leadMinutes = const Value.absent(),
    this.until = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderRulesCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String taskId,
    required String rrule,
    this.leadMinutes = const Value.absent(),
    this.until = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       taskId = Value(taskId),
       rrule = Value(rrule);
  static Insertable<ReminderRuleRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? taskId,
    Expression<String>? rrule,
    Expression<int>? leadMinutes,
    Expression<int>? until,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (rrule != null) 'rrule': rrule,
      if (leadMinutes != null) 'lead_minutes': leadMinutes,
      if (until != null) 'until': until,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderRulesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? taskId,
    Value<String>? rrule,
    Value<int>? leadMinutes,
    Value<int?>? until,
    Value<int>? rowid,
  }) {
    return ReminderRulesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      rrule: rrule ?? this.rrule,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      until: until ?? this.until,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (leadMinutes.present) {
      map['lead_minutes'] = Variable<int>(leadMinutes.value);
    }
    if (until.present) {
      map['until'] = Variable<int>(until.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRulesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('rrule: $rrule, ')
          ..write('leadMinutes: $leadMinutes, ')
          ..write('until: $until, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarSource>($CalendarEventsTable.$convertersource);
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBusyMeta = const VerificationMeta('isBusy');
  @override
  late final GeneratedColumn<bool> isBusy = GeneratedColumn<bool>(
    'is_busy',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_busy" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    source,
    externalId,
    calendarId,
    title,
    startAt,
    endAt,
    isAllDay,
    isBusy,
    taskId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('is_busy')) {
      context.handle(
        _isBusyMeta,
        isBusy.isAcceptableOrUnknown(data['is_busy']!, _isBusyMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      source: $CalendarEventsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      )!,
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      isBusy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_busy'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CalendarSource, String, String> $convertersource =
      const EnumNameConverter<CalendarSource>(CalendarSource.values);
}

class CalendarEventRow extends DataClass
    implements Insertable<CalendarEventRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final CalendarSource source;
  final String externalId;
  final String? calendarId;
  final String title;
  final int startAt;
  final int endAt;
  final bool isAllDay;
  final bool isBusy;

  /// No foreign key: sync may mirror an event before its task exists.
  final String? taskId;
  const CalendarEventRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.source,
    required this.externalId,
    this.calendarId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    required this.isBusy,
    this.taskId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['source'] = Variable<String>(
        $CalendarEventsTable.$convertersource.toSql(source),
      );
    }
    map['external_id'] = Variable<String>(externalId);
    if (!nullToAbsent || calendarId != null) {
      map['calendar_id'] = Variable<String>(calendarId);
    }
    map['title'] = Variable<String>(title);
    map['start_at'] = Variable<int>(startAt);
    map['end_at'] = Variable<int>(endAt);
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_busy'] = Variable<bool>(isBusy);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      source: Value(source),
      externalId: Value(externalId),
      calendarId: calendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarId),
      title: Value(title),
      startAt: Value(startAt),
      endAt: Value(endAt),
      isAllDay: Value(isAllDay),
      isBusy: Value(isBusy),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
    );
  }

  factory CalendarEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      source: $CalendarEventsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      externalId: serializer.fromJson<String>(json['externalId']),
      calendarId: serializer.fromJson<String?>(json['calendarId']),
      title: serializer.fromJson<String>(json['title']),
      startAt: serializer.fromJson<int>(json['startAt']),
      endAt: serializer.fromJson<int>(json['endAt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isBusy: serializer.fromJson<bool>(json['isBusy']),
      taskId: serializer.fromJson<String?>(json['taskId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'source': serializer.toJson<String>(
        $CalendarEventsTable.$convertersource.toJson(source),
      ),
      'externalId': serializer.toJson<String>(externalId),
      'calendarId': serializer.toJson<String?>(calendarId),
      'title': serializer.toJson<String>(title),
      'startAt': serializer.toJson<int>(startAt),
      'endAt': serializer.toJson<int>(endAt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isBusy': serializer.toJson<bool>(isBusy),
      'taskId': serializer.toJson<String?>(taskId),
    };
  }

  CalendarEventRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    CalendarSource? source,
    String? externalId,
    Value<String?> calendarId = const Value.absent(),
    String? title,
    int? startAt,
    int? endAt,
    bool? isAllDay,
    bool? isBusy,
    Value<String?> taskId = const Value.absent(),
  }) => CalendarEventRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    calendarId: calendarId.present ? calendarId.value : this.calendarId,
    title: title ?? this.title,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    isAllDay: isAllDay ?? this.isAllDay,
    isBusy: isBusy ?? this.isBusy,
    taskId: taskId.present ? taskId.value : this.taskId,
  );
  CalendarEventRow copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      title: data.title.present ? data.title.value : this.title,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isBusy: data.isBusy.present ? data.isBusy.value : this.isBusy,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('calendarId: $calendarId, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isBusy: $isBusy, ')
          ..write('taskId: $taskId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    source,
    externalId,
    calendarId,
    title,
    startAt,
    endAt,
    isAllDay,
    isBusy,
    taskId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.calendarId == this.calendarId &&
          other.title == this.title &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.isAllDay == this.isAllDay &&
          other.isBusy == this.isBusy &&
          other.taskId == this.taskId);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<CalendarSource> source;
  final Value<String> externalId;
  final Value<String?> calendarId;
  final Value<String> title;
  final Value<int> startAt;
  final Value<int> endAt;
  final Value<bool> isAllDay;
  final Value<bool> isBusy;
  final Value<String?> taskId;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.title = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isBusy = const Value.absent(),
    this.taskId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required CalendarSource source,
    required String externalId,
    this.calendarId = const Value.absent(),
    required String title,
    required int startAt,
    required int endAt,
    this.isAllDay = const Value.absent(),
    this.isBusy = const Value.absent(),
    this.taskId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       source = Value(source),
       externalId = Value(externalId),
       title = Value(title),
       startAt = Value(startAt),
       endAt = Value(endAt);
  static Insertable<CalendarEventRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? calendarId,
    Expression<String>? title,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<bool>? isAllDay,
    Expression<bool>? isBusy,
    Expression<String>? taskId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (title != null) 'title': title,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isBusy != null) 'is_busy': isBusy,
      if (taskId != null) 'task_id': taskId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<CalendarSource>? source,
    Value<String>? externalId,
    Value<String?>? calendarId,
    Value<String>? title,
    Value<int>? startAt,
    Value<int>? endAt,
    Value<bool>? isAllDay,
    Value<bool>? isBusy,
    Value<String?>? taskId,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      calendarId: calendarId ?? this.calendarId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      isBusy: isBusy ?? this.isBusy,
      taskId: taskId ?? this.taskId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CalendarEventsTable.$convertersource.toSql(source.value),
      );
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isBusy.present) {
      map['is_busy'] = Variable<bool>(isBusy.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('calendarId: $calendarId, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isBusy: $isBusy, ')
          ..write('taskId: $taskId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _plannedMinutesMeta = const VerificationMeta(
    'plannedMinutes',
  );
  @override
  late final GeneratedColumn<int> plannedMinutes = GeneratedColumn<int>(
    'planned_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    taskId,
    plannedMinutes,
    startedAt,
    endedAt,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('planned_minutes')) {
      context.handle(
        _plannedMinutesMeta,
        plannedMinutes.isAcceptableOrUnknown(
          data['planned_minutes']!,
          _plannedMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedMinutesMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      plannedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_minutes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSessionRow extends DataClass implements Insertable<FocusSessionRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String? taskId;
  final int plannedMinutes;
  final int startedAt;
  final int? endedAt;
  final bool completed;
  const FocusSessionRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.taskId,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['planned_minutes'] = Variable<int>(plannedMinutes);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      plannedMinutes: Value(plannedMinutes),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      completed: Value(completed),
    );
  }

  factory FocusSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      plannedMinutes: serializer.fromJson<int>(json['plannedMinutes']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'taskId': serializer.toJson<String?>(taskId),
      'plannedMinutes': serializer.toJson<int>(plannedMinutes),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  FocusSessionRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    int? plannedMinutes,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    bool? completed,
  }) => FocusSessionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId.present ? taskId.value : this.taskId,
    plannedMinutes: plannedMinutes ?? this.plannedMinutes,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    completed: completed ?? this.completed,
  );
  FocusSessionRow copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSessionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      plannedMinutes: data.plannedMinutes.present
          ? data.plannedMinutes.value
          : this.plannedMinutes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    taskId,
    plannedMinutes,
    startedAt,
    endedAt,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.plannedMinutes == this.plannedMinutes &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.completed == this.completed);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSessionRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> taskId;
  final Value<int> plannedMinutes;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<bool> completed;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    required int plannedMinutes,
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       plannedMinutes = Value(plannedMinutes),
       startedAt = Value(startedAt);
  static Insertable<FocusSessionRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? taskId,
    Expression<int>? plannedMinutes,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? taskId,
    Value<int>? plannedMinutes,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (plannedMinutes.present) {
      map['planned_minutes'] = Variable<int>(plannedMinutes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalHorizon, String> horizon =
      GeneratedColumn<String>(
        'horizon',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(GoalHorizon.month.name),
      ).withConverter<GoalHorizon>($GoalsTable.$converterhorizon);
  static const VerificationMeta _importanceMeta = const VerificationMeta(
    'importance',
  );
  @override
  late final GeneratedColumn<double> importance = GeneratedColumn<double>(
    'importance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastProgressAtMeta = const VerificationMeta(
    'lastProgressAt',
  );
  @override
  late final GeneratedColumn<int> lastProgressAt = GeneratedColumn<int>(
    'last_progress_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    area,
    horizon,
    importance,
    progress,
    lastProgressAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('importance')) {
      context.handle(
        _importanceMeta,
        importance.isAcceptableOrUnknown(data['importance']!, _importanceMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('last_progress_at')) {
      context.handle(
        _lastProgressAtMeta,
        lastProgressAt.isAcceptableOrUnknown(
          data['last_progress_at']!,
          _lastProgressAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      ),
      horizon: $GoalsTable.$converterhorizon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}horizon'],
        )!,
      ),
      importance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}importance'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      lastProgressAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_progress_at'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalHorizon, String, String> $converterhorizon =
      const EnumNameConverter<GoalHorizon>(GoalHorizon.values);
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String title;
  final String? area;
  final GoalHorizon horizon;
  final double importance;
  final double progress;
  final int? lastProgressAt;
  const GoalRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    this.area,
    required this.horizon,
    required this.importance,
    required this.progress,
    this.lastProgressAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<String>(area);
    }
    {
      map['horizon'] = Variable<String>(
        $GoalsTable.$converterhorizon.toSql(horizon),
      );
    }
    map['importance'] = Variable<double>(importance);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || lastProgressAt != null) {
      map['last_progress_at'] = Variable<int>(lastProgressAt);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      horizon: Value(horizon),
      importance: Value(importance),
      progress: Value(progress),
      lastProgressAt: lastProgressAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProgressAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      area: serializer.fromJson<String?>(json['area']),
      horizon: $GoalsTable.$converterhorizon.fromJson(
        serializer.fromJson<String>(json['horizon']),
      ),
      importance: serializer.fromJson<double>(json['importance']),
      progress: serializer.fromJson<double>(json['progress']),
      lastProgressAt: serializer.fromJson<int?>(json['lastProgressAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'area': serializer.toJson<String?>(area),
      'horizon': serializer.toJson<String>(
        $GoalsTable.$converterhorizon.toJson(horizon),
      ),
      'importance': serializer.toJson<double>(importance),
      'progress': serializer.toJson<double>(progress),
      'lastProgressAt': serializer.toJson<int?>(lastProgressAt),
    };
  }

  GoalRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? title,
    Value<String?> area = const Value.absent(),
    GoalHorizon? horizon,
    double? importance,
    double? progress,
    Value<int?> lastProgressAt = const Value.absent(),
  }) => GoalRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    area: area.present ? area.value : this.area,
    horizon: horizon ?? this.horizon,
    importance: importance ?? this.importance,
    progress: progress ?? this.progress,
    lastProgressAt: lastProgressAt.present
        ? lastProgressAt.value
        : this.lastProgressAt,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      area: data.area.present ? data.area.value : this.area,
      horizon: data.horizon.present ? data.horizon.value : this.horizon,
      importance: data.importance.present
          ? data.importance.value
          : this.importance,
      progress: data.progress.present ? data.progress.value : this.progress,
      lastProgressAt: data.lastProgressAt.present
          ? data.lastProgressAt.value
          : this.lastProgressAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('area: $area, ')
          ..write('horizon: $horizon, ')
          ..write('importance: $importance, ')
          ..write('progress: $progress, ')
          ..write('lastProgressAt: $lastProgressAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    area,
    horizon,
    importance,
    progress,
    lastProgressAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.area == this.area &&
          other.horizon == this.horizon &&
          other.importance == this.importance &&
          other.progress == this.progress &&
          other.lastProgressAt == this.lastProgressAt);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> title;
  final Value<String?> area;
  final Value<GoalHorizon> horizon;
  final Value<double> importance;
  final Value<double> progress;
  final Value<int?> lastProgressAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.area = const Value.absent(),
    this.horizon = const Value.absent(),
    this.importance = const Value.absent(),
    this.progress = const Value.absent(),
    this.lastProgressAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String title,
    this.area = const Value.absent(),
    this.horizon = const Value.absent(),
    this.importance = const Value.absent(),
    this.progress = const Value.absent(),
    this.lastProgressAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       title = Value(title);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? title,
    Expression<String>? area,
    Expression<String>? horizon,
    Expression<double>? importance,
    Expression<double>? progress,
    Expression<int>? lastProgressAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (area != null) 'area': area,
      if (horizon != null) 'horizon': horizon,
      if (importance != null) 'importance': importance,
      if (progress != null) 'progress': progress,
      if (lastProgressAt != null) 'last_progress_at': lastProgressAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? title,
    Value<String?>? area,
    Value<GoalHorizon>? horizon,
    Value<double>? importance,
    Value<double>? progress,
    Value<int?>? lastProgressAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      area: area ?? this.area,
      horizon: horizon ?? this.horizon,
      importance: importance ?? this.importance,
      progress: progress ?? this.progress,
      lastProgressAt: lastProgressAt ?? this.lastProgressAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (horizon.present) {
      map['horizon'] = Variable<String>(
        $GoalsTable.$converterhorizon.toSql(horizon.value),
      );
    }
    if (importance.present) {
      map['importance'] = Variable<double>(importance.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (lastProgressAt.present) {
      map['last_progress_at'] = Variable<int>(lastProgressAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('area: $area, ')
          ..write('horizon: $horizon, ')
          ..write('importance: $importance, ')
          ..write('progress: $progress, ')
          ..write('lastProgressAt: $lastProgressAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTableTable extends PreferencesTable
    with TableInfo<$PreferencesTableTable, PreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workingHoursMeta = const VerificationMeta(
    'workingHours',
  );
  @override
  late final GeneratedColumn<String> workingHours = GeneratedColumn<String>(
    'working_hours',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deepWindowsMeta = const VerificationMeta(
    'deepWindows',
  );
  @override
  late final GeneratedColumn<String> deepWindows = GeneratedColumn<String>(
    'deep_windows',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lunchMeta = const VerificationMeta('lunch');
  @override
  late final GeneratedColumn<String> lunch = GeneratedColumn<String>(
    'lunch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxDeepBlocksPerDayMeta =
      const VerificationMeta('maxDeepBlocksPerDay');
  @override
  late final GeneratedColumn<int> maxDeepBlocksPerDay = GeneratedColumn<int>(
    'max_deep_blocks_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deepBlockMinutesMeta = const VerificationMeta(
    'deepBlockMinutes',
  );
  @override
  late final GeneratedColumn<int> deepBlockMinutes = GeneratedColumn<int>(
    'deep_block_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bufferBetweenEventsMinutesMeta =
      const VerificationMeta('bufferBetweenEventsMinutes');
  @override
  late final GeneratedColumn<int> bufferBetweenEventsMinutes =
      GeneratedColumn<int>(
        'buffer_between_events_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dailyCushionMinutesMeta =
      const VerificationMeta('dailyCushionMinutes');
  @override
  late final GeneratedColumn<int> dailyCushionMinutes = GeneratedColumn<int>(
    'daily_cushion_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<int> weekStart = GeneratedColumn<int>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultReminderLeadMinutesMeta =
      const VerificationMeta('defaultReminderLeadMinutes');
  @override
  late final GeneratedColumn<int> defaultReminderLeadMinutes =
      GeneratedColumn<int>(
        'default_reminder_lead_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _quietHoursMeta = const VerificationMeta(
    'quietHours',
  );
  @override
  late final GeneratedColumn<String> quietHours = GeneratedColumn<String>(
    'quiet_hours',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneNameMeta = const VerificationMeta(
    'timeZoneName',
  );
  @override
  late final GeneratedColumn<String> timeZoneName = GeneratedColumn<String>(
    'time_zone_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
  );
  static const VerificationMeta _morningPromptMinutesMeta =
      const VerificationMeta('morningPromptMinutes');
  @override
  late final GeneratedColumn<int> morningPromptMinutes = GeneratedColumn<int>(
    'morning_prompt_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eveningPromptMinutesMeta =
      const VerificationMeta('eveningPromptMinutes');
  @override
  late final GeneratedColumn<int> eveningPromptMinutes = GeneratedColumn<int>(
    'evening_prompt_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedCalendarIdsMeta =
      const VerificationMeta('selectedCalendarIds');
  @override
  late final GeneratedColumn<String> selectedCalendarIds =
      GeneratedColumn<String>(
        'selected_calendar_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _backupHintShownMeta = const VerificationMeta(
    'backupHintShown',
  );
  @override
  late final GeneratedColumn<bool> backupHintShown = GeneratedColumn<bool>(
    'backup_hint_shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("backup_hint_shown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    workingHours,
    deepWindows,
    lunch,
    maxDeepBlocksPerDay,
    deepBlockMinutes,
    bufferBetweenEventsMinutes,
    dailyCushionMinutes,
    weekStart,
    defaultReminderLeadMinutes,
    quietHours,
    timeZoneName,
    localeCode,
    onboardingDone,
    morningPromptMinutes,
    eveningPromptMinutes,
    selectedCalendarIds,
    backupHintShown,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('working_hours')) {
      context.handle(
        _workingHoursMeta,
        workingHours.isAcceptableOrUnknown(
          data['working_hours']!,
          _workingHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workingHoursMeta);
    }
    if (data.containsKey('deep_windows')) {
      context.handle(
        _deepWindowsMeta,
        deepWindows.isAcceptableOrUnknown(
          data['deep_windows']!,
          _deepWindowsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deepWindowsMeta);
    }
    if (data.containsKey('lunch')) {
      context.handle(
        _lunchMeta,
        lunch.isAcceptableOrUnknown(data['lunch']!, _lunchMeta),
      );
    } else if (isInserting) {
      context.missing(_lunchMeta);
    }
    if (data.containsKey('max_deep_blocks_per_day')) {
      context.handle(
        _maxDeepBlocksPerDayMeta,
        maxDeepBlocksPerDay.isAcceptableOrUnknown(
          data['max_deep_blocks_per_day']!,
          _maxDeepBlocksPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxDeepBlocksPerDayMeta);
    }
    if (data.containsKey('deep_block_minutes')) {
      context.handle(
        _deepBlockMinutesMeta,
        deepBlockMinutes.isAcceptableOrUnknown(
          data['deep_block_minutes']!,
          _deepBlockMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deepBlockMinutesMeta);
    }
    if (data.containsKey('buffer_between_events_minutes')) {
      context.handle(
        _bufferBetweenEventsMinutesMeta,
        bufferBetweenEventsMinutes.isAcceptableOrUnknown(
          data['buffer_between_events_minutes']!,
          _bufferBetweenEventsMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bufferBetweenEventsMinutesMeta);
    }
    if (data.containsKey('daily_cushion_minutes')) {
      context.handle(
        _dailyCushionMinutesMeta,
        dailyCushionMinutes.isAcceptableOrUnknown(
          data['daily_cushion_minutes']!,
          _dailyCushionMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyCushionMinutesMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('default_reminder_lead_minutes')) {
      context.handle(
        _defaultReminderLeadMinutesMeta,
        defaultReminderLeadMinutes.isAcceptableOrUnknown(
          data['default_reminder_lead_minutes']!,
          _defaultReminderLeadMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultReminderLeadMinutesMeta);
    }
    if (data.containsKey('quiet_hours')) {
      context.handle(
        _quietHoursMeta,
        quietHours.isAcceptableOrUnknown(data['quiet_hours']!, _quietHoursMeta),
      );
    }
    if (data.containsKey('time_zone_name')) {
      context.handle(
        _timeZoneNameMeta,
        timeZoneName.isAcceptableOrUnknown(
          data['time_zone_name']!,
          _timeZoneNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneNameMeta);
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(data['locale_code']!, _localeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeCodeMeta);
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onboardingDoneMeta);
    }
    if (data.containsKey('morning_prompt_minutes')) {
      context.handle(
        _morningPromptMinutesMeta,
        morningPromptMinutes.isAcceptableOrUnknown(
          data['morning_prompt_minutes']!,
          _morningPromptMinutesMeta,
        ),
      );
    }
    if (data.containsKey('evening_prompt_minutes')) {
      context.handle(
        _eveningPromptMinutesMeta,
        eveningPromptMinutes.isAcceptableOrUnknown(
          data['evening_prompt_minutes']!,
          _eveningPromptMinutesMeta,
        ),
      );
    }
    if (data.containsKey('selected_calendar_ids')) {
      context.handle(
        _selectedCalendarIdsMeta,
        selectedCalendarIds.isAcceptableOrUnknown(
          data['selected_calendar_ids']!,
          _selectedCalendarIdsMeta,
        ),
      );
    }
    if (data.containsKey('backup_hint_shown')) {
      context.handle(
        _backupHintShownMeta,
        backupHintShown.isAcceptableOrUnknown(
          data['backup_hint_shown']!,
          _backupHintShownMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferencesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      workingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}working_hours'],
      )!,
      deepWindows: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deep_windows'],
      )!,
      lunch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lunch'],
      )!,
      maxDeepBlocksPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_deep_blocks_per_day'],
      )!,
      deepBlockMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deep_block_minutes'],
      )!,
      bufferBetweenEventsMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buffer_between_events_minutes'],
      )!,
      dailyCushionMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_cushion_minutes'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_start'],
      )!,
      defaultReminderLeadMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_reminder_lead_minutes'],
      )!,
      quietHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quiet_hours'],
      ),
      timeZoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_name'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      )!,
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      morningPromptMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morning_prompt_minutes'],
      ),
      eveningPromptMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evening_prompt_minutes'],
      ),
      selectedCalendarIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_calendar_ids'],
      )!,
      backupHintShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}backup_hint_shown'],
      )!,
    );
  }

  @override
  $PreferencesTableTable createAlias(String alias) {
    return $PreferencesTableTable(attachedDatabase, alias);
  }
}

class PreferencesRow extends DataClass implements Insertable<PreferencesRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  /// JSON: `{"1": [{"start": 540, "end": 1080}], ...}` keyed by weekday.
  final String workingHours;

  /// JSON: `[{"start": 540, "end": 720}]`.
  final String deepWindows;
  final String lunch;
  final int maxDeepBlocksPerDay;
  final int deepBlockMinutes;
  final int bufferBetweenEventsMinutes;
  final int dailyCushionMinutes;
  final int weekStart;
  final int defaultReminderLeadMinutes;

  /// JSON `{"start": .., "end": ..}` or null.
  final String? quietHours;
  final String timeZoneName;
  final String localeCode;
  final bool onboardingDone;
  final int? morningPromptMinutes;
  final int? eveningPromptMinutes;

  /// JSON: `{"google": ["id", ...], "apple": [...]}`.
  final String selectedCalendarIds;
  final bool backupHintShown;
  const PreferencesRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.workingHours,
    required this.deepWindows,
    required this.lunch,
    required this.maxDeepBlocksPerDay,
    required this.deepBlockMinutes,
    required this.bufferBetweenEventsMinutes,
    required this.dailyCushionMinutes,
    required this.weekStart,
    required this.defaultReminderLeadMinutes,
    this.quietHours,
    required this.timeZoneName,
    required this.localeCode,
    required this.onboardingDone,
    this.morningPromptMinutes,
    this.eveningPromptMinutes,
    required this.selectedCalendarIds,
    required this.backupHintShown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['working_hours'] = Variable<String>(workingHours);
    map['deep_windows'] = Variable<String>(deepWindows);
    map['lunch'] = Variable<String>(lunch);
    map['max_deep_blocks_per_day'] = Variable<int>(maxDeepBlocksPerDay);
    map['deep_block_minutes'] = Variable<int>(deepBlockMinutes);
    map['buffer_between_events_minutes'] = Variable<int>(
      bufferBetweenEventsMinutes,
    );
    map['daily_cushion_minutes'] = Variable<int>(dailyCushionMinutes);
    map['week_start'] = Variable<int>(weekStart);
    map['default_reminder_lead_minutes'] = Variable<int>(
      defaultReminderLeadMinutes,
    );
    if (!nullToAbsent || quietHours != null) {
      map['quiet_hours'] = Variable<String>(quietHours);
    }
    map['time_zone_name'] = Variable<String>(timeZoneName);
    map['locale_code'] = Variable<String>(localeCode);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    if (!nullToAbsent || morningPromptMinutes != null) {
      map['morning_prompt_minutes'] = Variable<int>(morningPromptMinutes);
    }
    if (!nullToAbsent || eveningPromptMinutes != null) {
      map['evening_prompt_minutes'] = Variable<int>(eveningPromptMinutes);
    }
    map['selected_calendar_ids'] = Variable<String>(selectedCalendarIds);
    map['backup_hint_shown'] = Variable<bool>(backupHintShown);
    return map;
  }

  PreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return PreferencesTableCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      workingHours: Value(workingHours),
      deepWindows: Value(deepWindows),
      lunch: Value(lunch),
      maxDeepBlocksPerDay: Value(maxDeepBlocksPerDay),
      deepBlockMinutes: Value(deepBlockMinutes),
      bufferBetweenEventsMinutes: Value(bufferBetweenEventsMinutes),
      dailyCushionMinutes: Value(dailyCushionMinutes),
      weekStart: Value(weekStart),
      defaultReminderLeadMinutes: Value(defaultReminderLeadMinutes),
      quietHours: quietHours == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHours),
      timeZoneName: Value(timeZoneName),
      localeCode: Value(localeCode),
      onboardingDone: Value(onboardingDone),
      morningPromptMinutes: morningPromptMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(morningPromptMinutes),
      eveningPromptMinutes: eveningPromptMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(eveningPromptMinutes),
      selectedCalendarIds: Value(selectedCalendarIds),
      backupHintShown: Value(backupHintShown),
    );
  }

  factory PreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferencesRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      workingHours: serializer.fromJson<String>(json['workingHours']),
      deepWindows: serializer.fromJson<String>(json['deepWindows']),
      lunch: serializer.fromJson<String>(json['lunch']),
      maxDeepBlocksPerDay: serializer.fromJson<int>(
        json['maxDeepBlocksPerDay'],
      ),
      deepBlockMinutes: serializer.fromJson<int>(json['deepBlockMinutes']),
      bufferBetweenEventsMinutes: serializer.fromJson<int>(
        json['bufferBetweenEventsMinutes'],
      ),
      dailyCushionMinutes: serializer.fromJson<int>(
        json['dailyCushionMinutes'],
      ),
      weekStart: serializer.fromJson<int>(json['weekStart']),
      defaultReminderLeadMinutes: serializer.fromJson<int>(
        json['defaultReminderLeadMinutes'],
      ),
      quietHours: serializer.fromJson<String?>(json['quietHours']),
      timeZoneName: serializer.fromJson<String>(json['timeZoneName']),
      localeCode: serializer.fromJson<String>(json['localeCode']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      morningPromptMinutes: serializer.fromJson<int?>(
        json['morningPromptMinutes'],
      ),
      eveningPromptMinutes: serializer.fromJson<int?>(
        json['eveningPromptMinutes'],
      ),
      selectedCalendarIds: serializer.fromJson<String>(
        json['selectedCalendarIds'],
      ),
      backupHintShown: serializer.fromJson<bool>(json['backupHintShown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'workingHours': serializer.toJson<String>(workingHours),
      'deepWindows': serializer.toJson<String>(deepWindows),
      'lunch': serializer.toJson<String>(lunch),
      'maxDeepBlocksPerDay': serializer.toJson<int>(maxDeepBlocksPerDay),
      'deepBlockMinutes': serializer.toJson<int>(deepBlockMinutes),
      'bufferBetweenEventsMinutes': serializer.toJson<int>(
        bufferBetweenEventsMinutes,
      ),
      'dailyCushionMinutes': serializer.toJson<int>(dailyCushionMinutes),
      'weekStart': serializer.toJson<int>(weekStart),
      'defaultReminderLeadMinutes': serializer.toJson<int>(
        defaultReminderLeadMinutes,
      ),
      'quietHours': serializer.toJson<String?>(quietHours),
      'timeZoneName': serializer.toJson<String>(timeZoneName),
      'localeCode': serializer.toJson<String>(localeCode),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'morningPromptMinutes': serializer.toJson<int?>(morningPromptMinutes),
      'eveningPromptMinutes': serializer.toJson<int?>(eveningPromptMinutes),
      'selectedCalendarIds': serializer.toJson<String>(selectedCalendarIds),
      'backupHintShown': serializer.toJson<bool>(backupHintShown),
    };
  }

  PreferencesRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? workingHours,
    String? deepWindows,
    String? lunch,
    int? maxDeepBlocksPerDay,
    int? deepBlockMinutes,
    int? bufferBetweenEventsMinutes,
    int? dailyCushionMinutes,
    int? weekStart,
    int? defaultReminderLeadMinutes,
    Value<String?> quietHours = const Value.absent(),
    String? timeZoneName,
    String? localeCode,
    bool? onboardingDone,
    Value<int?> morningPromptMinutes = const Value.absent(),
    Value<int?> eveningPromptMinutes = const Value.absent(),
    String? selectedCalendarIds,
    bool? backupHintShown,
  }) => PreferencesRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    workingHours: workingHours ?? this.workingHours,
    deepWindows: deepWindows ?? this.deepWindows,
    lunch: lunch ?? this.lunch,
    maxDeepBlocksPerDay: maxDeepBlocksPerDay ?? this.maxDeepBlocksPerDay,
    deepBlockMinutes: deepBlockMinutes ?? this.deepBlockMinutes,
    bufferBetweenEventsMinutes:
        bufferBetweenEventsMinutes ?? this.bufferBetweenEventsMinutes,
    dailyCushionMinutes: dailyCushionMinutes ?? this.dailyCushionMinutes,
    weekStart: weekStart ?? this.weekStart,
    defaultReminderLeadMinutes:
        defaultReminderLeadMinutes ?? this.defaultReminderLeadMinutes,
    quietHours: quietHours.present ? quietHours.value : this.quietHours,
    timeZoneName: timeZoneName ?? this.timeZoneName,
    localeCode: localeCode ?? this.localeCode,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    morningPromptMinutes: morningPromptMinutes.present
        ? morningPromptMinutes.value
        : this.morningPromptMinutes,
    eveningPromptMinutes: eveningPromptMinutes.present
        ? eveningPromptMinutes.value
        : this.eveningPromptMinutes,
    selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
    backupHintShown: backupHintShown ?? this.backupHintShown,
  );
  PreferencesRow copyWithCompanion(PreferencesTableCompanion data) {
    return PreferencesRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      workingHours: data.workingHours.present
          ? data.workingHours.value
          : this.workingHours,
      deepWindows: data.deepWindows.present
          ? data.deepWindows.value
          : this.deepWindows,
      lunch: data.lunch.present ? data.lunch.value : this.lunch,
      maxDeepBlocksPerDay: data.maxDeepBlocksPerDay.present
          ? data.maxDeepBlocksPerDay.value
          : this.maxDeepBlocksPerDay,
      deepBlockMinutes: data.deepBlockMinutes.present
          ? data.deepBlockMinutes.value
          : this.deepBlockMinutes,
      bufferBetweenEventsMinutes: data.bufferBetweenEventsMinutes.present
          ? data.bufferBetweenEventsMinutes.value
          : this.bufferBetweenEventsMinutes,
      dailyCushionMinutes: data.dailyCushionMinutes.present
          ? data.dailyCushionMinutes.value
          : this.dailyCushionMinutes,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      defaultReminderLeadMinutes: data.defaultReminderLeadMinutes.present
          ? data.defaultReminderLeadMinutes.value
          : this.defaultReminderLeadMinutes,
      quietHours: data.quietHours.present
          ? data.quietHours.value
          : this.quietHours,
      timeZoneName: data.timeZoneName.present
          ? data.timeZoneName.value
          : this.timeZoneName,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      morningPromptMinutes: data.morningPromptMinutes.present
          ? data.morningPromptMinutes.value
          : this.morningPromptMinutes,
      eveningPromptMinutes: data.eveningPromptMinutes.present
          ? data.eveningPromptMinutes.value
          : this.eveningPromptMinutes,
      selectedCalendarIds: data.selectedCalendarIds.present
          ? data.selectedCalendarIds.value
          : this.selectedCalendarIds,
      backupHintShown: data.backupHintShown.present
          ? data.backupHintShown.value
          : this.backupHintShown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workingHours: $workingHours, ')
          ..write('deepWindows: $deepWindows, ')
          ..write('lunch: $lunch, ')
          ..write('maxDeepBlocksPerDay: $maxDeepBlocksPerDay, ')
          ..write('deepBlockMinutes: $deepBlockMinutes, ')
          ..write('bufferBetweenEventsMinutes: $bufferBetweenEventsMinutes, ')
          ..write('dailyCushionMinutes: $dailyCushionMinutes, ')
          ..write('weekStart: $weekStart, ')
          ..write('defaultReminderLeadMinutes: $defaultReminderLeadMinutes, ')
          ..write('quietHours: $quietHours, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('localeCode: $localeCode, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('morningPromptMinutes: $morningPromptMinutes, ')
          ..write('eveningPromptMinutes: $eveningPromptMinutes, ')
          ..write('selectedCalendarIds: $selectedCalendarIds, ')
          ..write('backupHintShown: $backupHintShown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    workingHours,
    deepWindows,
    lunch,
    maxDeepBlocksPerDay,
    deepBlockMinutes,
    bufferBetweenEventsMinutes,
    dailyCushionMinutes,
    weekStart,
    defaultReminderLeadMinutes,
    quietHours,
    timeZoneName,
    localeCode,
    onboardingDone,
    morningPromptMinutes,
    eveningPromptMinutes,
    selectedCalendarIds,
    backupHintShown,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferencesRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.workingHours == this.workingHours &&
          other.deepWindows == this.deepWindows &&
          other.lunch == this.lunch &&
          other.maxDeepBlocksPerDay == this.maxDeepBlocksPerDay &&
          other.deepBlockMinutes == this.deepBlockMinutes &&
          other.bufferBetweenEventsMinutes == this.bufferBetweenEventsMinutes &&
          other.dailyCushionMinutes == this.dailyCushionMinutes &&
          other.weekStart == this.weekStart &&
          other.defaultReminderLeadMinutes == this.defaultReminderLeadMinutes &&
          other.quietHours == this.quietHours &&
          other.timeZoneName == this.timeZoneName &&
          other.localeCode == this.localeCode &&
          other.onboardingDone == this.onboardingDone &&
          other.morningPromptMinutes == this.morningPromptMinutes &&
          other.eveningPromptMinutes == this.eveningPromptMinutes &&
          other.selectedCalendarIds == this.selectedCalendarIds &&
          other.backupHintShown == this.backupHintShown);
}

class PreferencesTableCompanion extends UpdateCompanion<PreferencesRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> workingHours;
  final Value<String> deepWindows;
  final Value<String> lunch;
  final Value<int> maxDeepBlocksPerDay;
  final Value<int> deepBlockMinutes;
  final Value<int> bufferBetweenEventsMinutes;
  final Value<int> dailyCushionMinutes;
  final Value<int> weekStart;
  final Value<int> defaultReminderLeadMinutes;
  final Value<String?> quietHours;
  final Value<String> timeZoneName;
  final Value<String> localeCode;
  final Value<bool> onboardingDone;
  final Value<int?> morningPromptMinutes;
  final Value<int?> eveningPromptMinutes;
  final Value<String> selectedCalendarIds;
  final Value<bool> backupHintShown;
  final Value<int> rowid;
  const PreferencesTableCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.workingHours = const Value.absent(),
    this.deepWindows = const Value.absent(),
    this.lunch = const Value.absent(),
    this.maxDeepBlocksPerDay = const Value.absent(),
    this.deepBlockMinutes = const Value.absent(),
    this.bufferBetweenEventsMinutes = const Value.absent(),
    this.dailyCushionMinutes = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.defaultReminderLeadMinutes = const Value.absent(),
    this.quietHours = const Value.absent(),
    this.timeZoneName = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.morningPromptMinutes = const Value.absent(),
    this.eveningPromptMinutes = const Value.absent(),
    this.selectedCalendarIds = const Value.absent(),
    this.backupHintShown = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesTableCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String workingHours,
    required String deepWindows,
    required String lunch,
    required int maxDeepBlocksPerDay,
    required int deepBlockMinutes,
    required int bufferBetweenEventsMinutes,
    required int dailyCushionMinutes,
    required int weekStart,
    required int defaultReminderLeadMinutes,
    this.quietHours = const Value.absent(),
    required String timeZoneName,
    required String localeCode,
    required bool onboardingDone,
    this.morningPromptMinutes = const Value.absent(),
    this.eveningPromptMinutes = const Value.absent(),
    this.selectedCalendarIds = const Value.absent(),
    this.backupHintShown = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       workingHours = Value(workingHours),
       deepWindows = Value(deepWindows),
       lunch = Value(lunch),
       maxDeepBlocksPerDay = Value(maxDeepBlocksPerDay),
       deepBlockMinutes = Value(deepBlockMinutes),
       bufferBetweenEventsMinutes = Value(bufferBetweenEventsMinutes),
       dailyCushionMinutes = Value(dailyCushionMinutes),
       weekStart = Value(weekStart),
       defaultReminderLeadMinutes = Value(defaultReminderLeadMinutes),
       timeZoneName = Value(timeZoneName),
       localeCode = Value(localeCode),
       onboardingDone = Value(onboardingDone);
  static Insertable<PreferencesRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? workingHours,
    Expression<String>? deepWindows,
    Expression<String>? lunch,
    Expression<int>? maxDeepBlocksPerDay,
    Expression<int>? deepBlockMinutes,
    Expression<int>? bufferBetweenEventsMinutes,
    Expression<int>? dailyCushionMinutes,
    Expression<int>? weekStart,
    Expression<int>? defaultReminderLeadMinutes,
    Expression<String>? quietHours,
    Expression<String>? timeZoneName,
    Expression<String>? localeCode,
    Expression<bool>? onboardingDone,
    Expression<int>? morningPromptMinutes,
    Expression<int>? eveningPromptMinutes,
    Expression<String>? selectedCalendarIds,
    Expression<bool>? backupHintShown,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (workingHours != null) 'working_hours': workingHours,
      if (deepWindows != null) 'deep_windows': deepWindows,
      if (lunch != null) 'lunch': lunch,
      if (maxDeepBlocksPerDay != null)
        'max_deep_blocks_per_day': maxDeepBlocksPerDay,
      if (deepBlockMinutes != null) 'deep_block_minutes': deepBlockMinutes,
      if (bufferBetweenEventsMinutes != null)
        'buffer_between_events_minutes': bufferBetweenEventsMinutes,
      if (dailyCushionMinutes != null)
        'daily_cushion_minutes': dailyCushionMinutes,
      if (weekStart != null) 'week_start': weekStart,
      if (defaultReminderLeadMinutes != null)
        'default_reminder_lead_minutes': defaultReminderLeadMinutes,
      if (quietHours != null) 'quiet_hours': quietHours,
      if (timeZoneName != null) 'time_zone_name': timeZoneName,
      if (localeCode != null) 'locale_code': localeCode,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (morningPromptMinutes != null)
        'morning_prompt_minutes': morningPromptMinutes,
      if (eveningPromptMinutes != null)
        'evening_prompt_minutes': eveningPromptMinutes,
      if (selectedCalendarIds != null)
        'selected_calendar_ids': selectedCalendarIds,
      if (backupHintShown != null) 'backup_hint_shown': backupHintShown,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesTableCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? workingHours,
    Value<String>? deepWindows,
    Value<String>? lunch,
    Value<int>? maxDeepBlocksPerDay,
    Value<int>? deepBlockMinutes,
    Value<int>? bufferBetweenEventsMinutes,
    Value<int>? dailyCushionMinutes,
    Value<int>? weekStart,
    Value<int>? defaultReminderLeadMinutes,
    Value<String?>? quietHours,
    Value<String>? timeZoneName,
    Value<String>? localeCode,
    Value<bool>? onboardingDone,
    Value<int?>? morningPromptMinutes,
    Value<int?>? eveningPromptMinutes,
    Value<String>? selectedCalendarIds,
    Value<bool>? backupHintShown,
    Value<int>? rowid,
  }) {
    return PreferencesTableCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      workingHours: workingHours ?? this.workingHours,
      deepWindows: deepWindows ?? this.deepWindows,
      lunch: lunch ?? this.lunch,
      maxDeepBlocksPerDay: maxDeepBlocksPerDay ?? this.maxDeepBlocksPerDay,
      deepBlockMinutes: deepBlockMinutes ?? this.deepBlockMinutes,
      bufferBetweenEventsMinutes:
          bufferBetweenEventsMinutes ?? this.bufferBetweenEventsMinutes,
      dailyCushionMinutes: dailyCushionMinutes ?? this.dailyCushionMinutes,
      weekStart: weekStart ?? this.weekStart,
      defaultReminderLeadMinutes:
          defaultReminderLeadMinutes ?? this.defaultReminderLeadMinutes,
      quietHours: quietHours ?? this.quietHours,
      timeZoneName: timeZoneName ?? this.timeZoneName,
      localeCode: localeCode ?? this.localeCode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      morningPromptMinutes: morningPromptMinutes ?? this.morningPromptMinutes,
      eveningPromptMinutes: eveningPromptMinutes ?? this.eveningPromptMinutes,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      backupHintShown: backupHintShown ?? this.backupHintShown,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (workingHours.present) {
      map['working_hours'] = Variable<String>(workingHours.value);
    }
    if (deepWindows.present) {
      map['deep_windows'] = Variable<String>(deepWindows.value);
    }
    if (lunch.present) {
      map['lunch'] = Variable<String>(lunch.value);
    }
    if (maxDeepBlocksPerDay.present) {
      map['max_deep_blocks_per_day'] = Variable<int>(maxDeepBlocksPerDay.value);
    }
    if (deepBlockMinutes.present) {
      map['deep_block_minutes'] = Variable<int>(deepBlockMinutes.value);
    }
    if (bufferBetweenEventsMinutes.present) {
      map['buffer_between_events_minutes'] = Variable<int>(
        bufferBetweenEventsMinutes.value,
      );
    }
    if (dailyCushionMinutes.present) {
      map['daily_cushion_minutes'] = Variable<int>(dailyCushionMinutes.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<int>(weekStart.value);
    }
    if (defaultReminderLeadMinutes.present) {
      map['default_reminder_lead_minutes'] = Variable<int>(
        defaultReminderLeadMinutes.value,
      );
    }
    if (quietHours.present) {
      map['quiet_hours'] = Variable<String>(quietHours.value);
    }
    if (timeZoneName.present) {
      map['time_zone_name'] = Variable<String>(timeZoneName.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (morningPromptMinutes.present) {
      map['morning_prompt_minutes'] = Variable<int>(morningPromptMinutes.value);
    }
    if (eveningPromptMinutes.present) {
      map['evening_prompt_minutes'] = Variable<int>(eveningPromptMinutes.value);
    }
    if (selectedCalendarIds.present) {
      map['selected_calendar_ids'] = Variable<String>(
        selectedCalendarIds.value,
      );
    }
    if (backupHintShown.present) {
      map['backup_hint_shown'] = Variable<bool>(backupHintShown.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workingHours: $workingHours, ')
          ..write('deepWindows: $deepWindows, ')
          ..write('lunch: $lunch, ')
          ..write('maxDeepBlocksPerDay: $maxDeepBlocksPerDay, ')
          ..write('deepBlockMinutes: $deepBlockMinutes, ')
          ..write('bufferBetweenEventsMinutes: $bufferBetweenEventsMinutes, ')
          ..write('dailyCushionMinutes: $dailyCushionMinutes, ')
          ..write('weekStart: $weekStart, ')
          ..write('defaultReminderLeadMinutes: $defaultReminderLeadMinutes, ')
          ..write('quietHours: $quietHours, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('localeCode: $localeCode, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('morningPromptMinutes: $morningPromptMinutes, ')
          ..write('eveningPromptMinutes: $eveningPromptMinutes, ')
          ..write('selectedCalendarIds: $selectedCalendarIds, ')
          ..write('backupHintShown: $backupHintShown, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ReminderRulesTable reminderRules = $ReminderRulesTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $PreferencesTableTable preferencesTable = $PreferencesTableTable(
    this,
  );
  late final Index tasksRemindAt = Index(
    'tasks_remind_at',
    'CREATE INDEX tasks_remind_at ON tasks (remind_at)',
  );
  late final Index tasksScheduledStart = Index(
    'tasks_scheduled_start',
    'CREATE INDEX tasks_scheduled_start ON tasks (scheduled_start)',
  );
  late final Index reminderRulesTaskId = Index(
    'reminder_rules_task_id',
    'CREATE INDEX reminder_rules_task_id ON reminder_rules (task_id)',
  );
  late final Index calendarEventsStartAt = Index(
    'calendar_events_start_at',
    'CREATE INDEX calendar_events_start_at ON calendar_events (start_at)',
  );
  late final Index calendarEventsExternal = Index(
    'calendar_events_external',
    'CREATE INDEX calendar_events_external ON calendar_events (source, external_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    reminderRules,
    calendarEvents,
    focusSessions,
    goals,
    preferencesTable,
    tasksRemindAt,
    tasksScheduledStart,
    reminderRulesTaskId,
    calendarEventsStartAt,
    calendarEventsExternal,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminder_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('focus_sessions', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String title,
      Value<String?> notes,
      Value<String?> goalId,
      Value<int?> dueAt,
      Value<int?> remindAt,
      Value<int?> scheduledStart,
      Value<int?> scheduledEnd,
      Value<bool> lockedStart,
      Value<int?> notBefore,
      Value<int> minutesDone,
      Value<int> estimatedMinutes,
      Value<Energy> energy,
      Value<String?> firstAction,
      Value<int> priority,
      Value<String?> category,
      Value<bool> splittable,
      Value<int> minChunkMinutes,
      Value<TaskStatus> status,
      Value<int?> completedAt,
      Value<int?> actualMinutes,
      Value<int> snoozeCount,
      Value<String?> calendarEventId,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> title,
      Value<String?> notes,
      Value<String?> goalId,
      Value<int?> dueAt,
      Value<int?> remindAt,
      Value<int?> scheduledStart,
      Value<int?> scheduledEnd,
      Value<bool> lockedStart,
      Value<int?> notBefore,
      Value<int> minutesDone,
      Value<int> estimatedMinutes,
      Value<Energy> energy,
      Value<String?> firstAction,
      Value<int> priority,
      Value<String?> category,
      Value<bool> splittable,
      Value<int> minChunkMinutes,
      Value<TaskStatus> status,
      Value<int?> completedAt,
      Value<int?> actualMinutes,
      Value<int> snoozeCount,
      Value<String?> calendarEventId,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReminderRulesTable, List<ReminderRuleRow>>
  _reminderRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminderRules,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.reminderRules.taskId),
  );

  $$ReminderRulesTableProcessedTableManager get reminderRulesRefs {
    final manager = $$ReminderRulesTableTableManager(
      $_db,
      $_db.reminderRules,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reminderRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FocusSessionsTable, List<FocusSessionRow>>
  _focusSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.focusSessions,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.focusSessions.taskId),
  );

  $$FocusSessionsTableProcessedTableManager get focusSessionsRefs {
    final manager = $$FocusSessionsTableTableManager(
      $_db,
      $_db.focusSessions,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledEnd => $composableBuilder(
    column: $table.scheduledEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lockedStart => $composableBuilder(
    column: $table.lockedStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notBefore => $composableBuilder(
    column: $table.notBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesDone => $composableBuilder(
    column: $table.minutesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Energy, Energy, String> get energy =>
      $composableBuilder(
        column: $table.energy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get firstAction => $composableBuilder(
    column: $table.firstAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get splittable => $composableBuilder(
    column: $table.splittable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minChunkMinutes => $composableBuilder(
    column: $table.minChunkMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reminderRulesRefs(
    Expression<bool> Function($$ReminderRulesTableFilterComposer f) f,
  ) {
    final $$ReminderRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableFilterComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> focusSessionsRefs(
    Expression<bool> Function($$FocusSessionsTableFilterComposer f) f,
  ) {
    final $$FocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledEnd => $composableBuilder(
    column: $table.scheduledEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lockedStart => $composableBuilder(
    column: $table.lockedStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notBefore => $composableBuilder(
    column: $table.notBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesDone => $composableBuilder(
    column: $table.minutesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstAction => $composableBuilder(
    column: $table.firstAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get splittable => $composableBuilder(
    column: $table.splittable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minChunkMinutes => $composableBuilder(
    column: $table.minChunkMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<int> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduledEnd => $composableBuilder(
    column: $table.scheduledEnd,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lockedStart => $composableBuilder(
    column: $table.lockedStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notBefore =>
      $composableBuilder(column: $table.notBefore, builder: (column) => column);

  GeneratedColumn<int> get minutesDone => $composableBuilder(
    column: $table.minutesDone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Energy, String> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<String> get firstAction => $composableBuilder(
    column: $table.firstAction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get splittable => $composableBuilder(
    column: $table.splittable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minChunkMinutes => $composableBuilder(
    column: $table.minChunkMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => column,
  );

  Expression<T> reminderRulesRefs<T extends Object>(
    Expression<T> Function($$ReminderRulesTableAnnotationComposer a) f,
  ) {
    final $$ReminderRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> focusSessionsRefs<T extends Object>(
    Expression<T> Function($$FocusSessionsTableAnnotationComposer a) f,
  ) {
    final $$FocusSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool reminderRulesRefs,
            bool focusSessionsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<int?> scheduledStart = const Value.absent(),
                Value<int?> scheduledEnd = const Value.absent(),
                Value<bool> lockedStart = const Value.absent(),
                Value<int?> notBefore = const Value.absent(),
                Value<int> minutesDone = const Value.absent(),
                Value<int> estimatedMinutes = const Value.absent(),
                Value<Energy> energy = const Value.absent(),
                Value<String?> firstAction = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> splittable = const Value.absent(),
                Value<int> minChunkMinutes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> actualMinutes = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<String?> calendarEventId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                notes: notes,
                goalId: goalId,
                dueAt: dueAt,
                remindAt: remindAt,
                scheduledStart: scheduledStart,
                scheduledEnd: scheduledEnd,
                lockedStart: lockedStart,
                notBefore: notBefore,
                minutesDone: minutesDone,
                estimatedMinutes: estimatedMinutes,
                energy: energy,
                firstAction: firstAction,
                priority: priority,
                category: category,
                splittable: splittable,
                minChunkMinutes: minChunkMinutes,
                status: status,
                completedAt: completedAt,
                actualMinutes: actualMinutes,
                snoozeCount: snoozeCount,
                calendarEventId: calendarEventId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<int?> scheduledStart = const Value.absent(),
                Value<int?> scheduledEnd = const Value.absent(),
                Value<bool> lockedStart = const Value.absent(),
                Value<int?> notBefore = const Value.absent(),
                Value<int> minutesDone = const Value.absent(),
                Value<int> estimatedMinutes = const Value.absent(),
                Value<Energy> energy = const Value.absent(),
                Value<String?> firstAction = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> splittable = const Value.absent(),
                Value<int> minChunkMinutes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> actualMinutes = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<String?> calendarEventId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                notes: notes,
                goalId: goalId,
                dueAt: dueAt,
                remindAt: remindAt,
                scheduledStart: scheduledStart,
                scheduledEnd: scheduledEnd,
                lockedStart: lockedStart,
                notBefore: notBefore,
                minutesDone: minutesDone,
                estimatedMinutes: estimatedMinutes,
                energy: energy,
                firstAction: firstAction,
                priority: priority,
                category: category,
                splittable: splittable,
                minChunkMinutes: minChunkMinutes,
                status: status,
                completedAt: completedAt,
                actualMinutes: actualMinutes,
                snoozeCount: snoozeCount,
                calendarEventId: calendarEventId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({reminderRulesRefs = false, focusSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reminderRulesRefs) db.reminderRules,
                    if (focusSessionsRefs) db.focusSessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reminderRulesRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          ReminderRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._reminderRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).reminderRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (focusSessionsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          FocusSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._focusSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).focusSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({bool reminderRulesRefs, bool focusSessionsRefs})
    >;
typedef $$ReminderRulesTableCreateCompanionBuilder =
    ReminderRulesCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String taskId,
      required String rrule,
      Value<int> leadMinutes,
      Value<int?> until,
      Value<int> rowid,
    });
typedef $$ReminderRulesTableUpdateCompanionBuilder =
    ReminderRulesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> taskId,
      Value<String> rrule,
      Value<int> leadMinutes,
      Value<int?> until,
      Value<int> rowid,
    });

final class $$ReminderRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReminderRulesTable, ReminderRuleRow> {
  $$ReminderRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.reminderRules.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReminderRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leadMinutes => $composableBuilder(
    column: $table.leadMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get until => $composableBuilder(
    column: $table.until,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leadMinutes => $composableBuilder(
    column: $table.leadMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get until => $composableBuilder(
    column: $table.until,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<int> get leadMinutes => $composableBuilder(
    column: $table.leadMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get until =>
      $composableBuilder(column: $table.until, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderRulesTable,
          ReminderRuleRow,
          $$ReminderRulesTableFilterComposer,
          $$ReminderRulesTableOrderingComposer,
          $$ReminderRulesTableAnnotationComposer,
          $$ReminderRulesTableCreateCompanionBuilder,
          $$ReminderRulesTableUpdateCompanionBuilder,
          (ReminderRuleRow, $$ReminderRulesTableReferences),
          ReminderRuleRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$ReminderRulesTableTableManager(_$AppDatabase db, $ReminderRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> rrule = const Value.absent(),
                Value<int> leadMinutes = const Value.absent(),
                Value<int?> until = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                rrule: rrule,
                leadMinutes: leadMinutes,
                until: until,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String taskId,
                required String rrule,
                Value<int> leadMinutes = const Value.absent(),
                Value<int?> until = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                rrule: rrule,
                leadMinutes: leadMinutes,
                until: until,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReminderRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$ReminderRulesTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$ReminderRulesTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReminderRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderRulesTable,
      ReminderRuleRow,
      $$ReminderRulesTableFilterComposer,
      $$ReminderRulesTableOrderingComposer,
      $$ReminderRulesTableAnnotationComposer,
      $$ReminderRulesTableCreateCompanionBuilder,
      $$ReminderRulesTableUpdateCompanionBuilder,
      (ReminderRuleRow, $$ReminderRulesTableReferences),
      ReminderRuleRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required CalendarSource source,
      required String externalId,
      Value<String?> calendarId,
      required String title,
      required int startAt,
      required int endAt,
      Value<bool> isAllDay,
      Value<bool> isBusy,
      Value<String?> taskId,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<CalendarSource> source,
      Value<String> externalId,
      Value<String?> calendarId,
      Value<String> title,
      Value<int> startAt,
      Value<int> endAt,
      Value<bool> isAllDay,
      Value<bool> isBusy,
      Value<String?> taskId,
      Value<int> rowid,
    });

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarSource, CalendarSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBusy => $composableBuilder(
    column: $table.isBusy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBusy => $composableBuilder(
    column: $table.isBusy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get isBusy =>
      $composableBuilder(column: $table.isBusy, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEventRow,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (
            CalendarEventRow,
            BaseReferences<
              _$AppDatabase,
              $CalendarEventsTable,
              CalendarEventRow
            >,
          ),
          CalendarEventRow,
          PrefetchHooks Function()
        > {
  $$CalendarEventsTableTableManager(
    _$AppDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<CalendarSource> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String?> calendarId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int> endAt = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isBusy = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                source: source,
                externalId: externalId,
                calendarId: calendarId,
                title: title,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                isBusy: isBusy,
                taskId: taskId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required CalendarSource source,
                required String externalId,
                Value<String?> calendarId = const Value.absent(),
                required String title,
                required int startAt,
                required int endAt,
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isBusy = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                source: source,
                externalId: externalId,
                calendarId: calendarId,
                title: title,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                isBusy: isBusy,
                taskId: taskId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEventsTable,
      CalendarEventRow,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (
        CalendarEventRow,
        BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEventRow>,
      ),
      CalendarEventRow,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<String?> taskId,
      required int plannedMinutes,
      required int startedAt,
      Value<int?> endedAt,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String?> taskId,
      Value<int> plannedMinutes,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<bool> completed,
      Value<int> rowid,
    });

final class $$FocusSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSessionRow> {
  $$FocusSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.focusSessions.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSessionRow,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (FocusSessionRow, $$FocusSessionsTableReferences),
          FocusSessionRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> plannedMinutes = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                plannedMinutes: plannedMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                required int plannedMinutes,
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                plannedMinutes: plannedMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FocusSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$FocusSessionsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$FocusSessionsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSessionRow,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (FocusSessionRow, $$FocusSessionsTableReferences),
      FocusSessionRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String title,
      Value<String?> area,
      Value<GoalHorizon> horizon,
      Value<double> importance,
      Value<double> progress,
      Value<int?> lastProgressAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> title,
      Value<String?> area,
      Value<GoalHorizon> horizon,
      Value<double> importance,
      Value<double> progress,
      Value<int?> lastProgressAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalHorizon, GoalHorizon, String>
  get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastProgressAt => $composableBuilder(
    column: $table.lastProgressAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastProgressAt => $composableBuilder(
    column: $table.lastProgressAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalHorizon, String> get horizon =>
      $composableBuilder(column: $table.horizon, builder: (column) => column);

  GeneratedColumn<double> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get lastProgressAt => $composableBuilder(
    column: $table.lastProgressAt,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> area = const Value.absent(),
                Value<GoalHorizon> horizon = const Value.absent(),
                Value<double> importance = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int?> lastProgressAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                area: area,
                horizon: horizon,
                importance: importance,
                progress: progress,
                lastProgressAt: lastProgressAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String title,
                Value<String?> area = const Value.absent(),
                Value<GoalHorizon> horizon = const Value.absent(),
                Value<double> importance = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int?> lastProgressAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                area: area,
                horizon: horizon,
                importance: importance,
                progress: progress,
                lastProgressAt: lastProgressAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableTableCreateCompanionBuilder =
    PreferencesTableCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String workingHours,
      required String deepWindows,
      required String lunch,
      required int maxDeepBlocksPerDay,
      required int deepBlockMinutes,
      required int bufferBetweenEventsMinutes,
      required int dailyCushionMinutes,
      required int weekStart,
      required int defaultReminderLeadMinutes,
      Value<String?> quietHours,
      required String timeZoneName,
      required String localeCode,
      required bool onboardingDone,
      Value<int?> morningPromptMinutes,
      Value<int?> eveningPromptMinutes,
      Value<String> selectedCalendarIds,
      Value<bool> backupHintShown,
      Value<int> rowid,
    });
typedef $$PreferencesTableTableUpdateCompanionBuilder =
    PreferencesTableCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> workingHours,
      Value<String> deepWindows,
      Value<String> lunch,
      Value<int> maxDeepBlocksPerDay,
      Value<int> deepBlockMinutes,
      Value<int> bufferBetweenEventsMinutes,
      Value<int> dailyCushionMinutes,
      Value<int> weekStart,
      Value<int> defaultReminderLeadMinutes,
      Value<String?> quietHours,
      Value<String> timeZoneName,
      Value<String> localeCode,
      Value<bool> onboardingDone,
      Value<int?> morningPromptMinutes,
      Value<int?> eveningPromptMinutes,
      Value<String> selectedCalendarIds,
      Value<bool> backupHintShown,
      Value<int> rowid,
    });

class $$PreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deepWindows => $composableBuilder(
    column: $table.deepWindows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lunch => $composableBuilder(
    column: $table.lunch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxDeepBlocksPerDay => $composableBuilder(
    column: $table.maxDeepBlocksPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deepBlockMinutes => $composableBuilder(
    column: $table.deepBlockMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bufferBetweenEventsMinutes => $composableBuilder(
    column: $table.bufferBetweenEventsMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCushionMinutes => $composableBuilder(
    column: $table.dailyCushionMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultReminderLeadMinutes => $composableBuilder(
    column: $table.defaultReminderLeadMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quietHours => $composableBuilder(
    column: $table.quietHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get morningPromptMinutes => $composableBuilder(
    column: $table.morningPromptMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eveningPromptMinutes => $composableBuilder(
    column: $table.eveningPromptMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedCalendarIds => $composableBuilder(
    column: $table.selectedCalendarIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backupHintShown => $composableBuilder(
    column: $table.backupHintShown,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deepWindows => $composableBuilder(
    column: $table.deepWindows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lunch => $composableBuilder(
    column: $table.lunch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxDeepBlocksPerDay => $composableBuilder(
    column: $table.maxDeepBlocksPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deepBlockMinutes => $composableBuilder(
    column: $table.deepBlockMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bufferBetweenEventsMinutes => $composableBuilder(
    column: $table.bufferBetweenEventsMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCushionMinutes => $composableBuilder(
    column: $table.dailyCushionMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultReminderLeadMinutes => $composableBuilder(
    column: $table.defaultReminderLeadMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quietHours => $composableBuilder(
    column: $table.quietHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get morningPromptMinutes => $composableBuilder(
    column: $table.morningPromptMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eveningPromptMinutes => $composableBuilder(
    column: $table.eveningPromptMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedCalendarIds => $composableBuilder(
    column: $table.selectedCalendarIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backupHintShown => $composableBuilder(
    column: $table.backupHintShown,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deepWindows => $composableBuilder(
    column: $table.deepWindows,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lunch =>
      $composableBuilder(column: $table.lunch, builder: (column) => column);

  GeneratedColumn<int> get maxDeepBlocksPerDay => $composableBuilder(
    column: $table.maxDeepBlocksPerDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deepBlockMinutes => $composableBuilder(
    column: $table.deepBlockMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bufferBetweenEventsMinutes => $composableBuilder(
    column: $table.bufferBetweenEventsMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyCushionMinutes => $composableBuilder(
    column: $table.dailyCushionMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<int> get defaultReminderLeadMinutes => $composableBuilder(
    column: $table.defaultReminderLeadMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quietHours => $composableBuilder(
    column: $table.quietHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get morningPromptMinutes => $composableBuilder(
    column: $table.morningPromptMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eveningPromptMinutes => $composableBuilder(
    column: $table.eveningPromptMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedCalendarIds => $composableBuilder(
    column: $table.selectedCalendarIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backupHintShown => $composableBuilder(
    column: $table.backupHintShown,
    builder: (column) => column,
  );
}

class $$PreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTableTable,
          PreferencesRow,
          $$PreferencesTableTableFilterComposer,
          $$PreferencesTableTableOrderingComposer,
          $$PreferencesTableTableAnnotationComposer,
          $$PreferencesTableTableCreateCompanionBuilder,
          $$PreferencesTableTableUpdateCompanionBuilder,
          (
            PreferencesRow,
            BaseReferences<
              _$AppDatabase,
              $PreferencesTableTable,
              PreferencesRow
            >,
          ),
          PreferencesRow,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableTableManager(
    _$AppDatabase db,
    $PreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> workingHours = const Value.absent(),
                Value<String> deepWindows = const Value.absent(),
                Value<String> lunch = const Value.absent(),
                Value<int> maxDeepBlocksPerDay = const Value.absent(),
                Value<int> deepBlockMinutes = const Value.absent(),
                Value<int> bufferBetweenEventsMinutes = const Value.absent(),
                Value<int> dailyCushionMinutes = const Value.absent(),
                Value<int> weekStart = const Value.absent(),
                Value<int> defaultReminderLeadMinutes = const Value.absent(),
                Value<String?> quietHours = const Value.absent(),
                Value<String> timeZoneName = const Value.absent(),
                Value<String> localeCode = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<int?> morningPromptMinutes = const Value.absent(),
                Value<int?> eveningPromptMinutes = const Value.absent(),
                Value<String> selectedCalendarIds = const Value.absent(),
                Value<bool> backupHintShown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesTableCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                workingHours: workingHours,
                deepWindows: deepWindows,
                lunch: lunch,
                maxDeepBlocksPerDay: maxDeepBlocksPerDay,
                deepBlockMinutes: deepBlockMinutes,
                bufferBetweenEventsMinutes: bufferBetweenEventsMinutes,
                dailyCushionMinutes: dailyCushionMinutes,
                weekStart: weekStart,
                defaultReminderLeadMinutes: defaultReminderLeadMinutes,
                quietHours: quietHours,
                timeZoneName: timeZoneName,
                localeCode: localeCode,
                onboardingDone: onboardingDone,
                morningPromptMinutes: morningPromptMinutes,
                eveningPromptMinutes: eveningPromptMinutes,
                selectedCalendarIds: selectedCalendarIds,
                backupHintShown: backupHintShown,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String workingHours,
                required String deepWindows,
                required String lunch,
                required int maxDeepBlocksPerDay,
                required int deepBlockMinutes,
                required int bufferBetweenEventsMinutes,
                required int dailyCushionMinutes,
                required int weekStart,
                required int defaultReminderLeadMinutes,
                Value<String?> quietHours = const Value.absent(),
                required String timeZoneName,
                required String localeCode,
                required bool onboardingDone,
                Value<int?> morningPromptMinutes = const Value.absent(),
                Value<int?> eveningPromptMinutes = const Value.absent(),
                Value<String> selectedCalendarIds = const Value.absent(),
                Value<bool> backupHintShown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesTableCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                workingHours: workingHours,
                deepWindows: deepWindows,
                lunch: lunch,
                maxDeepBlocksPerDay: maxDeepBlocksPerDay,
                deepBlockMinutes: deepBlockMinutes,
                bufferBetweenEventsMinutes: bufferBetweenEventsMinutes,
                dailyCushionMinutes: dailyCushionMinutes,
                weekStart: weekStart,
                defaultReminderLeadMinutes: defaultReminderLeadMinutes,
                quietHours: quietHours,
                timeZoneName: timeZoneName,
                localeCode: localeCode,
                onboardingDone: onboardingDone,
                morningPromptMinutes: morningPromptMinutes,
                eveningPromptMinutes: eveningPromptMinutes,
                selectedCalendarIds: selectedCalendarIds,
                backupHintShown: backupHintShown,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTableTable,
      PreferencesRow,
      $$PreferencesTableTableFilterComposer,
      $$PreferencesTableTableOrderingComposer,
      $$PreferencesTableTableAnnotationComposer,
      $$PreferencesTableTableCreateCompanionBuilder,
      $$PreferencesTableTableUpdateCompanionBuilder,
      (
        PreferencesRow,
        BaseReferences<_$AppDatabase, $PreferencesTableTable, PreferencesRow>,
      ),
      PreferencesRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ReminderRulesTableTableManager get reminderRules =>
      $$ReminderRulesTableTableManager(_db, _db.reminderRules);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$PreferencesTableTableTableManager get preferencesTable =>
      $$PreferencesTableTableTableManager(_db, _db.preferencesTable);
}
