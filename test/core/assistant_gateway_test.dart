import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('FakeAssistantGateway.capture', () {
    test('pulls a minute duration out of the text', () async {
      final gateway = FakeAssistantGateway();
      final response = await gateway.capture(
        const CaptureRequest(text: 'gym tomorrow 45 min'),
      );
      expect(response.estimatedMinutes, 45);
      expect(response.title, 'gym tomorrow');
      expect(response.confidence, greaterThan(0.5));
    });

    test('keeps the raw text when no duration is mentioned', () async {
      final gateway = FakeAssistantGateway();
      final response = await gateway.capture(
        const CaptureRequest(text: 'call mom'),
      );
      expect(response.estimatedMinutes, isNull);
      expect(response.title, 'call mom');
      expect(response.confidence, lessThanOrEqualTo(0.5));
    });

    test('records every call for assertions', () async {
      final gateway = FakeAssistantGateway();
      await gateway.capture(const CaptureRequest(text: 'first'));
      await gateway.capture(const CaptureRequest(text: 'second'));
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls.first.intent, AssistantIntent.capture);
      expect((gateway.calls.first.request as CaptureRequest).text, 'first');
    });
  });

  group('FakeAssistantGateway.planExplanation', () {
    test('summarises a plan with no unplaced tasks', () async {
      final gateway = FakeAssistantGateway();
      final response = await gateway.planExplanation(
        const PlanExplanationRequest(
          taskCount: 4,
          focusMinutes: 150,
          firstTaskTitle: 'Deep work',
        ),
      );
      expect(response.summary, contains('4 tasks'));
      expect(response.summary, contains('Deep work'));
      expect(response.suggestion, isNull);
    });

    test('suggests moving the first unplaced task', () async {
      final gateway = FakeAssistantGateway();
      final response = await gateway.planExplanation(
        const PlanExplanationRequest(
          taskCount: 3,
          focusMinutes: 60,
          firstTaskTitle: 'Standup',
          unplacedTitles: ['Reading'],
        ),
      );
      expect(response.suggestion, contains('Reading'));
    });
  });

  group('FakeAssistantGateway.praise', () {
    test('returns a distinct line per trigger', () async {
      final gateway = FakeAssistantGateway();
      final taskDone = await gateway.praise(
        const PraiseRequest(trigger: PraiseTrigger.taskDone),
      );
      final dayClear = await gateway.praise(
        const PraiseRequest(trigger: PraiseTrigger.dayCleared),
      );
      expect(taskDone.line, isNot(dayClear.line));
      expect(taskDone.line, isNotEmpty);
      expect(dayClear.line, isNotEmpty);
    });

    test('mentions the streak length for streak praise', () async {
      final gateway = FakeAssistantGateway();
      final response = await gateway.praise(
        const PraiseRequest(trigger: PraiseTrigger.streakHit, streakDays: 7),
      );
      expect(response.line, contains('7'));
    });
  });

  group('FakeAssistantGateway.failWith', () {
    test('throws the configured exception from every intent', () async {
      final gateway = FakeAssistantGateway(
        failWith: const AssistantException(
          'offline',
          kind: AssistantErrorKind.network,
        ),
      );
      await expectLater(
        gateway.capture(const CaptureRequest(text: 'x')),
        throwsA(
          isA<AssistantException>().having(
            (e) => e.kind,
            'kind',
            AssistantErrorKind.network,
          ),
        ),
      );
      await expectLater(
        gateway.planExplanation(
          const PlanExplanationRequest(
            taskCount: 0,
            focusMinutes: 0,
            firstTaskTitle: '',
          ),
        ),
        throwsA(isA<AssistantException>()),
      );
      await expectLater(
        gateway.praise(const PraiseRequest(trigger: PraiseTrigger.taskDone)),
        throwsA(isA<AssistantException>()),
      );
    });
  });
}
