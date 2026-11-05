import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/unstick/unstick_option.dart';
import 'package:grind/features/ask/unstick/unstick_response.dart';

void main() {
  const splitOption = UnstickOption(
    kind: UnstickKind.split,
    title: 'Two short blocks',
    humanRationale: 'Easier to start than one long block.',
    parameters: {'chunkMinutes': 25, 'chunks': 2},
  );
  const firstActionOption = UnstickOption(
    kind: UnstickKind.firstAction,
    title: 'Open the file for 2 min',
    humanRationale: 'Just the first step, nothing more.',
    parameters: {'minutes': 2, 'label': 'open the file'},
  );

  group('UnstickResponse construction', () {
    test('holds required fields with offline as the default source', () {
      final res = UnstickResponse(
        acknowledgement: "That's a lot. Let's make it smaller.",
        options: const [splitOption, firstActionOption],
      );

      expect(res.acknowledgement, "That's a lot. Let's make it smaller.");
      expect(res.options, [splitOption, firstActionOption]);
      expect(res.source, UnstickSource.offline);
    });

    test('options list is unmodifiable', () {
      final res = UnstickResponse(
        acknowledgement: 'ack',
        options: const [firstActionOption],
      );

      expect(() => res.options.add(splitOption), throwsUnsupportedError);
    });

    test('rejects empty acknowledgement and out-of-range options', () {
      expect(
        () =>
            UnstickResponse(acknowledgement: '', options: const [splitOption]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UnstickResponse(acknowledgement: 'ack', options: const []),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UnstickResponse(
          acknowledgement: 'ack',
          options: const [
            splitOption,
            splitOption,
            splitOption,
            firstActionOption,
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('UnstickResponse equality', () {
    test('same fields compare equal; different order does not', () {
      final a = UnstickResponse(
        acknowledgement: 'ack',
        options: const [splitOption, firstActionOption],
      );
      final b = UnstickResponse(
        acknowledgement: 'ack',
        options: const [splitOption, firstActionOption],
      );
      final flipped = UnstickResponse(
        acknowledgement: 'ack',
        options: const [firstActionOption, splitOption],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == flipped, isFalse);
    });

    test('different source breaks equality', () {
      final offline = UnstickResponse(
        acknowledgement: 'ack',
        options: const [firstActionOption],
      );
      final llm = offline.copyWith(source: UnstickSource.llm);

      expect(offline == llm, isFalse);
      expect(llm.source, UnstickSource.llm);
      expect(llm.options, offline.options);
    });
  });

  group('UnstickResponse JSON', () {
    test('round-trips through toJson/fromJson', () {
      final res = UnstickResponse(
        acknowledgement: "That's a lot. Let's make it smaller.",
        options: const [splitOption, firstActionOption],
        source: UnstickSource.llm,
      );

      final decoded = UnstickResponse.fromJson(res.toJson());
      expect(decoded, res);
    });

    test('defaults source to offline when the field is missing or unknown', () {
      final decoded = UnstickResponse.fromJson({
        'acknowledgement': 'ack',
        'options': [firstActionOption.toJson()],
      });
      expect(decoded, isNotNull);
      expect(decoded!.source, UnstickSource.offline);

      final unknown = UnstickResponse.fromJson({
        'acknowledgement': 'ack',
        'options': [firstActionOption.toJson()],
        'source': 'carrier-pigeon',
      });
      expect(unknown, isNotNull);
      expect(unknown!.source, UnstickSource.offline);
    });

    test('fromJson rejects structurally bad input', () {
      expect(UnstickResponse.fromJson(null), isNull);
      expect(UnstickResponse.fromJson('nope'), isNull);
      expect(UnstickResponse.fromJson({'options': []}), isNull);
      expect(
        UnstickResponse.fromJson({'acknowledgement': '', 'options': []}),
        isNull,
      );
      expect(
        UnstickResponse.fromJson({
          'acknowledgement': 'ack',
          'options': 'not a list',
        }),
        isNull,
      );
      expect(
        UnstickResponse.fromJson({'acknowledgement': 'ack', 'options': []}),
        isNull,
      );
    });

    test('fromJson skips malformed options but keeps the good ones', () {
      final decoded = UnstickResponse.fromJson({
        'acknowledgement': 'ack',
        'options': [
          splitOption.toJson(),
          'not an object',
          {'kind': 'split'}, // missing title/rationale
          firstActionOption.toJson(),
        ],
      });

      expect(decoded, isNotNull);
      expect(decoded!.options, [splitOption, firstActionOption]);
    });

    test('fromJson rejects a response with more than three options', () {
      final decoded = UnstickResponse.fromJson({
        'acknowledgement': 'ack',
        'options': [
          splitOption.toJson(),
          splitOption.toJson(),
          splitOption.toJson(),
          firstActionOption.toJson(),
        ],
      });
      expect(decoded, isNull);
    });

    test('fromJson rejects a response with no parseable options', () {
      final decoded = UnstickResponse.fromJson({
        'acknowledgement': 'ack',
        'options': ['not an object', 42],
      });
      expect(decoded, isNull);
    });
  });
}
