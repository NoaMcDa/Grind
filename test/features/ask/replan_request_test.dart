import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/replan_request.dart';

ReplanRequest? _en(String s) =>
    classifyReplanRequest(s, locale: const Locale('en'));
ReplanRequest? _he(String s) =>
    classifyReplanRequest(s, locale: const Locale('he'));

void main() {
  group('empty, unknown and fallback', () {
    test('empty and whitespace return null', () {
      expect(_en(''), isNull);
      expect(_en('   '), isNull);
      expect(_en('\n\t'), isNull);
    });

    test('free chat that names no re-plan phrase returns null', () {
      expect(_en('hey pip'), isNull);
      expect(_en("i'm behind on my thesis, help"), isNull);
      expect(_en('plan my day'), isNull);
      expect(_he('היי פיפ'), isNull);
    });

    test('no locale defaults to the English phrase table', () {
      expect(
        classifyReplanRequest('move gym earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(classifyReplanRequest('הזז גים מוקדם'), isNull);
    });
  });

  group('MoveTaskDirection (English)', () {
    test('"move X earlier" maps to MoveDirection.earlier', () {
      expect(
        _en('move gym earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('Move the gym earlier!'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
    });

    test('"move X later" maps to MoveDirection.later', () {
      expect(
        _en('move gym later'),
        const MoveTaskDirection('gym', MoveDirection.later),
      );
      expect(
        _en('Move the reading later.'),
        const MoveTaskDirection('reading', MoveDirection.later),
      );
    });

    test('push / bump / shift alternates reach the same request', () {
      expect(
        _en('push gym earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('bump the call later'),
        const MoveTaskDirection('call', MoveDirection.later),
      );
      expect(
        _en('shift reading earlier'),
        const MoveTaskDirection('reading', MoveDirection.earlier),
      );
    });

    test('"do X earlier" and "start X later" are picked up', () {
      expect(
        _en('do gym earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('start the gym later'),
        const MoveTaskDirection('gym', MoveDirection.later),
      );
    });

    test('"X is too late" / "X is too early" nudge the right direction', () {
      expect(
        _en('gym is too late'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('the gym too late'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('the call is too early'),
        const MoveTaskDirection('call', MoveDirection.later),
      );
    });
  });

  group('MoveTaskDirection (Hebrew)', () {
    test('imperative "הזז X מוקדם" maps to earlier', () {
      expect(
        _he('הזז את הגים מוקדם'),
        // The leading `את ` is part of the task reference here —
        // the extractor only strips a leading `ה` article, matching
        // ask_intent.dart's behaviour.
        const MoveTaskDirection('את הגים', MoveDirection.earlier),
      );
      expect(
        _he('הזז גים מוקדם'),
        const MoveTaskDirection('גים', MoveDirection.earlier),
      );
      expect(
        _he('תזיזי הגים מוקדם יותר'),
        const MoveTaskDirection('גים', MoveDirection.earlier),
      );
    });

    test('imperative "הזז X מאוחר" maps to later', () {
      expect(
        _he('הזז גים מאוחר'),
        const MoveTaskDirection('גים', MoveDirection.later),
      );
      expect(
        _he('תזיז הקריאה יותר מאוחר'),
        const MoveTaskDirection('קריאה', MoveDirection.later),
      );
    });

    test('"X מאוחר" nudges earlier and "X מוקדם" nudges later', () {
      expect(
        _he('הגים כל כך מאוחר'),
        const MoveTaskDirection('גים', MoveDirection.earlier),
      );
      expect(
        _he('הקריאה מוקדם'),
        const MoveTaskDirection('קריאה', MoveDirection.later),
      );
    });
  });

  group('DropTaskFromToday (English)', () {
    test('"drop X from today" reaches DropTaskFromToday', () {
      expect(_en('drop gym from today'), const DropTaskFromToday('gym'));
      expect(
        _en('drop the reading from the plan'),
        const DropTaskFromToday('reading'),
      );
    });

    test('"remove X from today" reaches DropTaskFromToday', () {
      expect(
        _en('remove the call from today'),
        const DropTaskFromToday('call'),
      );
    });

    test('"take X off today" reaches DropTaskFromToday', () {
      expect(_en('take the gym off today'), const DropTaskFromToday('gym'));
      expect(
        _en('take reading off the plan'),
        const DropTaskFromToday('reading'),
      );
    });

    test(
      "\"i can't do X today\" and \"skip X today\" reach DropTaskFromToday",
      () {
        expect(_en("i can't do gym today"), const DropTaskFromToday('gym'));
        expect(_en('i cant do the gym today'), const DropTaskFromToday('gym'));
        expect(_en('skip gym today'), const DropTaskFromToday('gym'));
      },
    );
  });

  group('DropTaskFromToday (Hebrew)', () {
    test('imperative "הורד X מהיום" reaches DropTaskFromToday', () {
      expect(_he('הורד את הגים מהיום'), const DropTaskFromToday('את הגים'));
      expect(_he('תוריד גים מהיום'), const DropTaskFromToday('גים'));
      expect(_he('הורידו גים מהתוכנית'), const DropTaskFromToday('גים'));
    });

    test('"דלג על X היום" reaches DropTaskFromToday', () {
      expect(_he('דלג על הגים היום'), const DropTaskFromToday('גים'));
      expect(_he('דלגי על קריאה היום'), const DropTaskFromToday('קריאה'));
    });

    test('"לא יכול X היום" reaches DropTaskFromToday', () {
      expect(_he('אני לא יכול גים היום'), const DropTaskFromToday('גים'));
      expect(_he('לא יכולה קריאה היום'), const DropTaskFromToday('קריאה'));
    });
  });

  group('rule ordering', () {
    test('"take X off today" does not trip the move patterns', () {
      final r = _en('take gym off today');
      expect(r, isA<DropTaskFromToday>());
      expect((r as DropTaskFromToday).taskReference, 'gym');
    });

    test('"move X later" does not trip the "too late" pattern', () {
      final r = _en('move gym later');
      expect(r, isA<MoveTaskDirection>());
      expect((r as MoveTaskDirection).direction, MoveDirection.later);
    });

    test('"X too late" nudges earlier, not later', () {
      final r = _en('gym is too late') as MoveTaskDirection;
      expect(r.direction, MoveDirection.earlier);
    });
  });

  group('normalization', () {
    test('case and trailing punctuation are ignored', () {
      expect(
        _en('MOVE GYM EARLIER'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('Move gym earlier!!!'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(
        _en('  move gym earlier  '),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
    });

    test('runs of whitespace collapse', () {
      expect(
        _en('move   gym    earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
    });

    test('a leading English article is trimmed from the task reference', () {
      expect(
        _en('move the gym earlier'),
        const MoveTaskDirection('gym', MoveDirection.earlier),
      );
      expect(_en('drop my gym from today'), const DropTaskFromToday('gym'));
      expect(
        _en('take an errand off today'),
        const DropTaskFromToday('errand'),
      );
    });

    test('a leading Hebrew ה is trimmed from the task reference', () {
      expect(
        _he('הזז הגים מוקדם'),
        const MoveTaskDirection('גים', MoveDirection.earlier),
      );
      expect(_he('דלג על הקריאה היום'), const DropTaskFromToday('קריאה'));
    });
  });

  group('ReplanRequest value semantics', () {
    test('two MoveTaskDirection with equal fields are equal', () {
      const a = MoveTaskDirection('gym', MoveDirection.earlier);
      const b = MoveTaskDirection('gym', MoveDirection.earlier);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('MoveTaskDirection with different direction are not equal', () {
      const a = MoveTaskDirection('gym', MoveDirection.earlier);
      const b = MoveTaskDirection('gym', MoveDirection.later);
      expect(a, isNot(b));
    });

    test('DropTaskFromToday equality is by task reference', () {
      const a = DropTaskFromToday('gym');
      const b = DropTaskFromToday('gym');
      const c = DropTaskFromToday('call');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test(
      'MoveTaskDirection and DropTaskFromToday with same ref are not equal',
      () {
        const a = MoveTaskDirection('gym', MoveDirection.earlier);
        const b = DropTaskFromToday('gym');
        expect(a, isNot(b));
      },
    );
  });
}
