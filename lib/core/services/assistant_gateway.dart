/// Client-side gateway for the assistant (epic #38).
///
/// The real implementation (not yet wired) posts `{intent, input, context}` to
/// a server-side function that runs the LLM; the client never touches an API
/// key. This file defines the typed intents, request/response shapes and a
/// deterministic fake every feature and test can depend on.
///
/// Three intents are supported today:
///   * **capture** — natural language in, a structured task draft out.
///     The LLM parses language; the on-device scheduler owns time arithmetic
///     (see `docs/research/replanning-architecture.md` §4).
///   * **planExplanation** — a short, friendly summary of a plan already built
///     by the deterministic scheduler.
///   * **praise** — a short encouraging line.
///
/// The LLM never picks times. Placement stays in the on-device scheduler.
library;

/// Which assistant intent is being invoked.
enum AssistantIntent { capture, planExplanation, praise }

/// Raised when the gateway can't produce a response (network, timeout, the
/// user opted out, rate limit, upstream error).
class AssistantException implements Exception {
  const AssistantException(
    this.message, {
    this.kind = AssistantErrorKind.other,
  });

  final String message;
  final AssistantErrorKind kind;

  @override
  String toString() => 'AssistantException($kind): $message';
}

enum AssistantErrorKind {
  /// The caller (or the user, via settings) chose not to send anything.
  optedOut,
  network,
  timeout,
  rateLimited,

  /// Response did not match the expected schema.
  invalidResponse,
  other,
}

/// Natural-language capture: "gym tomorrow 7am, 45 min" → a task draft.
///
/// The gateway only returns raw fields; turning them into a concrete time
/// (resolving "tomorrow", checking working hours) is the scheduler's job.
class CaptureRequest {
  const CaptureRequest({required this.text, this.localeCode = 'en'});

  final String text;
  final String localeCode;
}

/// A single task draft. All fields except [title] are optional on purpose:
/// the LLM returns what it heard, the client decides what to do with blanks.
class CaptureResponse {
  const CaptureResponse({
    required this.title,
    this.notes,
    this.hintedDate,
    this.hintedTimeMinutes,
    this.estimatedMinutes,
    this.confidence = 1.0,
  });

  final String title;
  final String? notes;

  /// A calendar day the user mentioned ("tomorrow", "Friday") resolved against
  /// the caller's clock. Null when the user gave none.
  final DateTime? hintedDate;

  /// Minutes after midnight for a time of day ("7am" → 420). Null when none.
  final int? hintedTimeMinutes;

  /// Duration the user mentioned ("45 min" → 45).
  final int? estimatedMinutes;

  /// 0.0–1.0; anything below 0.5 should be shown as a question, not a
  /// confirmation.
  final double confidence;
}

/// A friendly explanation of a plan the scheduler already produced.
///
/// The caller passes a few structured summary fields (no raw notes, no full
/// task objects) so the prompt stays small and privacy-safe.
class PlanExplanationRequest {
  const PlanExplanationRequest({
    required this.taskCount,
    required this.focusMinutes,
    required this.firstTaskTitle,
    this.unplacedTitles = const [],
    this.localeCode = 'en',
  });

  final int taskCount;
  final int focusMinutes;
  final String firstTaskTitle;

  /// Task titles that didn't fit on the day, so the copy can mention them.
  final List<String> unplacedTitles;
  final String localeCode;
}

class PlanExplanationResponse {
  const PlanExplanationResponse({required this.summary, this.suggestion});

  /// One short paragraph, ready to show.
  final String summary;

  /// Optional one-line nudge ("Shall we move Deep work earlier?").
  final String? suggestion;
}

/// A short encouraging line after a win or a stretch.
class PraiseRequest {
  const PraiseRequest({
    required this.trigger,
    this.streakDays = 0,
    this.localeCode = 'en',
  });

  /// What the user just did; the gateway uses this to pick the right tone.
  final PraiseTrigger trigger;
  final int streakDays;
  final String localeCode;
}

enum PraiseTrigger {
  taskDone,
  focusSessionDone,
  dayCleared,
  goalMilestone,
  streakHit,
}

class PraiseResponse {
  const PraiseResponse({required this.line});

  final String line;
}

/// The single abstraction every feature talks to. Real implementations POST
/// to the server-side function; [FakeAssistantGateway] returns canned data.
abstract interface class AssistantGateway {
  Future<CaptureResponse> capture(CaptureRequest request);
  Future<PlanExplanationResponse> planExplanation(
    PlanExplanationRequest request,
  );
  Future<PraiseResponse> praise(PraiseRequest request);
}

/// Deterministic in-memory implementation.
///
/// Used by default in [assistantGatewayProvider] and by every widget test so
/// nothing reaches the network. Behaviour:
///
/// * [capture] does a tiny regex pass for a "N min" duration and strips it
///   from the title; everything else comes back blank. This is *not* the
///   real capture parser — it just gives tests a stable answer.
/// * [planExplanation] returns a short deterministic sentence built from the
///   request fields.
/// * [praise] returns a short deterministic line per trigger.
///
/// Set [failWith] to make every call throw — handy for error-path tests.
class FakeAssistantGateway implements AssistantGateway {
  FakeAssistantGateway({this.failWith});

  /// When non-null, every method throws this instead of answering.
  AssistantException? failWith;

  /// Calls received, in order, for assertions in tests.
  final List<({AssistantIntent intent, Object request})> calls = [];

  static final _durationRe = RegExp(
    r'(\d{1,3})\s*(?:min|mins|minutes|m)\b',
    caseSensitive: false,
  );

  @override
  Future<CaptureResponse> capture(CaptureRequest request) async {
    calls.add((intent: AssistantIntent.capture, request: request));
    final err = failWith;
    if (err != null) throw err;
    final match = _durationRe.firstMatch(request.text);
    final minutes = match == null ? null : int.tryParse(match.group(1)!);
    final cleaned =
        (match == null
                ? request.text
                : request.text
                      .replaceFirst(match.group(0)!, '')
                      .replaceAll(RegExp(r'[,\s]+$'), ''))
            .trim();
    return CaptureResponse(
      title: cleaned.isEmpty ? request.text.trim() : cleaned,
      estimatedMinutes: minutes,
      confidence: minutes == null ? 0.5 : 0.8,
    );
  }

  @override
  Future<PlanExplanationResponse> planExplanation(
    PlanExplanationRequest request,
  ) async {
    calls.add((intent: AssistantIntent.planExplanation, request: request));
    final err = failWith;
    if (err != null) throw err;
    final hours = (request.focusMinutes / 60).toStringAsFixed(1);
    final summary =
        '${request.taskCount} tasks, ~$hours h of focus. '
        'Starting with ${request.firstTaskTitle}.';
    final suggestion = request.unplacedTitles.isEmpty
        ? null
        : "${request.unplacedTitles.first} didn't fit today — move to tomorrow?";
    return PlanExplanationResponse(summary: summary, suggestion: suggestion);
  }

  @override
  Future<PraiseResponse> praise(PraiseRequest request) async {
    calls.add((intent: AssistantIntent.praise, request: request));
    final err = failWith;
    if (err != null) throw err;
    return PraiseResponse(line: _praiseLine(request));
  }

  String _praiseLine(PraiseRequest r) {
    switch (r.trigger) {
      case PraiseTrigger.taskDone:
        return 'Nice, one more done.';
      case PraiseTrigger.focusSessionDone:
        return 'Focus block clear — that counts.';
      case PraiseTrigger.dayCleared:
        return 'All of today, done. Enjoy the evening.';
      case PraiseTrigger.goalMilestone:
        return 'A milestone this week. Pip is pleased.';
      case PraiseTrigger.streakHit:
        return 'That is ${r.streakDays} days in a row.';
    }
  }
}
