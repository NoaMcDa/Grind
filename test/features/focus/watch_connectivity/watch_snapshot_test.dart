import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/focus/watch_connectivity/watch_connectivity.dart';

void main() {
  final writtenAt = DateTime.utc(2026, 11, 4, 6);
  final fireAt = DateTime.utc(2026, 11, 4, 7);

  WatchSnapshot sample({WatchReminder? reminder, WatchMomentum? momentum}) =>
      WatchSnapshot(
        writtenAt: writtenAt,
        nextReminder:
            reminder ??
            WatchReminder(
              taskId: 't-1',
              fireAt: fireAt,
              title: 'Thesis',
              ifThen: 'open the thesis file',
            ),
        momentum: momentum ?? const WatchMomentum(value: 72.5, level: 'steady'),
      );

  test('encode then tryDecode roundtrips every field', () {
    final decoded = WatchSnapshot.tryDecode(sample().encode());
    expect(decoded, isNotNull);
    expect(decoded!.writtenAt, writtenAt);
    expect(decoded.schema, WatchSnapshot.schemaVersion);
    expect(decoded.nextReminder?.taskId, 't-1');
    expect(decoded.nextReminder?.title, 'Thesis');
    expect(decoded.nextReminder?.fireAt, fireAt);
    expect(decoded.nextReminder?.ifThen, 'open the thesis file');
    expect(decoded.momentum.value, 72.5);
    expect(decoded.momentum.level, 'steady');
  });

  test('a missing nextReminder stays absent through the roundtrip', () {
    final snap = WatchSnapshot(
      writtenAt: writtenAt,
      momentum: const WatchMomentum(value: 0, level: 'quiet'),
    );
    final json = jsonDecode(snap.encode()) as Map<String, Object?>;
    expect(json.containsKey('nextReminder'), isFalse);
    final decoded = WatchSnapshot.tryDecode(snap.encode());
    expect(decoded?.nextReminder, isNull);
  });

  test('a reminder with no if-then stays absent through the roundtrip', () {
    final snap = sample(
      reminder: WatchReminder(taskId: 't-2', fireAt: fireAt, title: 'Admin'),
    );
    final json = jsonDecode(snap.encode()) as Map<String, Object?>;
    final reminder = json['nextReminder'] as Map<String, Object?>;
    expect(reminder.containsKey('ifThen'), isFalse);
    final decoded = WatchSnapshot.tryDecode(snap.encode());
    expect(decoded?.nextReminder?.ifThen, isNull);
  });

  test('writtenAt is normalized to UTC after decode', () {
    final snap = WatchSnapshot(
      writtenAt: DateTime(2026, 11, 4, 6).toLocal(),
      momentum: const WatchMomentum(value: 0, level: 'quiet'),
    );
    final decoded = WatchSnapshot.tryDecode(snap.encode());
    expect(decoded?.writtenAt.isUtc, isTrue);
  });

  test('encode is stable: equal snapshots produce byte-identical JSON', () {
    // The watch skips a redraw when nothing changed by comparing the JSON
    // strings, so this guarantee matters as much as decode-roundtrip.
    expect(sample().encode(), sample().encode());
  });

  group('tryDecode rejects unusable payloads', () {
    test('null or empty raw', () {
      expect(WatchSnapshot.tryDecode(null), isNull);
      expect(WatchSnapshot.tryDecode(''), isNull);
    });

    test('malformed JSON', () {
      expect(WatchSnapshot.tryDecode('{not json'), isNull);
    });

    test('JSON that is not an object', () {
      expect(WatchSnapshot.tryDecode('[]'), isNull);
      expect(WatchSnapshot.tryDecode('42'), isNull);
    });

    test('a newer schema the watch does not know yet', () {
      final json = jsonEncode({
        'schema': WatchSnapshot.schemaVersion + 1,
        'writtenAt': writtenAt.toIso8601String(),
        'momentum': {'value': 10.0, 'level': 'quiet'},
      });
      expect(WatchSnapshot.tryDecode(json), isNull);
    });

    test('a non-integer or missing schema', () {
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 'one',
            'writtenAt': writtenAt.toIso8601String(),
            'momentum': {'value': 0.0, 'level': 'quiet'},
          }),
        ),
        isNull,
      );
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'writtenAt': writtenAt.toIso8601String(),
            'momentum': {'value': 0.0, 'level': 'quiet'},
          }),
        ),
        isNull,
      );
    });

    test('missing or unparseable writtenAt', () {
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 1,
            'momentum': {'value': 0.0, 'level': 'quiet'},
          }),
        ),
        isNull,
      );
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 1,
            'writtenAt': 'not-a-date',
            'momentum': {'value': 0.0, 'level': 'quiet'},
          }),
        ),
        isNull,
      );
    });

    test('missing or malformed momentum block', () {
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 1,
            'writtenAt': writtenAt.toIso8601String(),
          }),
        ),
        isNull,
      );
      // level must be a string.
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 1,
            'writtenAt': writtenAt.toIso8601String(),
            'momentum': {'value': 0.0, 'level': 2},
          }),
        ),
        isNull,
      );
      // value must be a number.
      expect(
        WatchSnapshot.tryDecode(
          jsonEncode({
            'schema': 1,
            'writtenAt': writtenAt.toIso8601String(),
            'momentum': {'value': 'high', 'level': 'steady'},
          }),
        ),
        isNull,
      );
    });

    test('a malformed reminder drops the field but keeps the snapshot', () {
      // The watch still shows "no reminder up next" instead of refusing the
      // whole payload when only the reminder shape is off.
      final json = jsonEncode({
        'schema': 1,
        'writtenAt': writtenAt.toIso8601String(),
        'nextReminder': {'taskId': 't', 'title': 'x'}, // no fireAt
        'momentum': {'value': 0.0, 'level': 'quiet'},
      });
      final decoded = WatchSnapshot.tryDecode(json);
      expect(decoded, isNotNull);
      expect(decoded!.nextReminder, isNull);
    });
  });

  test('WatchReminder equality covers every field', () {
    final a = WatchReminder(
      taskId: 't-1',
      fireAt: fireAt,
      title: 'Thesis',
      ifThen: 'open the thesis file',
    );
    final b = WatchReminder(
      taskId: 't-1',
      fireAt: fireAt,
      title: 'Thesis',
      ifThen: 'open the thesis file',
    );
    final differentIfThen = WatchReminder(
      taskId: 't-1',
      fireAt: fireAt,
      title: 'Thesis',
      ifThen: 'different step',
    );
    final noIfThen = WatchReminder(
      taskId: 't-1',
      fireAt: fireAt,
      title: 'Thesis',
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(differentIfThen));
    expect(a, isNot(noIfThen));
  });

  test('WatchMomentum equality covers value and level', () {
    const a = WatchMomentum(value: 50, level: 'steady');
    const b = WatchMomentum(value: 50, level: 'steady');
    const c = WatchMomentum(value: 50, level: 'strong');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
