import 'unstick_option.dart';

/// Deterministic, no-network fallback for the "I'm stuck" intent (#41).
///
/// Returns 1–3 [UnstickOption]s for a task the user says they are behind
/// on. Used when:
///   * the device is offline,
///   * the user opted out of the cloud assistant,
///   * the gateway returned no suggestions.
///
/// Rules are deliberately simple — the point is to always give the user
/// a smaller next step, never to be clever:
///
/// * `firstAction` ("open the file for 2 min") is always the last option.
///   It is the safety net: however stuck the user is, two minutes is
///   always available.
/// * Before it, up to two context options are added:
///   * Long task (≥ 50 min): `split` into two shorter blocks.
///   * Overdue at least a day: `reschedule` to tomorrow.
///   * Otherwise (and when not tiny): `shorten` to 15 min.
///
/// The suggester is pure: same inputs produce the same options.
class StaticUnstickSuggester {
  const StaticUnstickSuggester({this.localeCode = 'en'});

  /// `'en'` or `'he'`. Any other value falls back to English.
  final String localeCode;

  bool get _isHebrew => localeCode == 'he';

  /// Build 1–3 options for a task of [estimatedMinutes] duration.
  ///
  /// [overdueBy] is how long the task is already past its deadline;
  /// null or non-positive means it is not overdue yet.
  List<UnstickOption> suggestFor({
    required int estimatedMinutes,
    Duration? overdueBy,
  }) {
    final leads = <UnstickOption>[];
    final long = estimatedMinutes >= 50;
    final tiny = estimatedMinutes < 30;
    final overdue = overdueBy != null && overdueBy > Duration.zero;

    if (long) {
      leads.add(_split(estimatedMinutes));
    }
    if (overdue) {
      leads.add(_reschedule());
    }
    if (!tiny && leads.length < 2) {
      leads.add(_shorten());
    }

    // Keep at most two leading options so firstAction always fits.
    final head = leads.length <= 2 ? leads : leads.sublist(0, 2);
    return [...head, _firstAction()];
  }

  UnstickOption _split(int minutes) {
    // Split evenly; both chunks are at least 20 min so a block is still
    // useful. The scheduler decides when they land.
    final chunkMinutes = (minutes / 2).ceil().clamp(20, 45);
    return UnstickOption(
      kind: UnstickKind.split,
      title: _isHebrew ? UnstickTone.splitTitleHe : UnstickTone.splitTitleEn,
      humanRationale: _isHebrew
          ? UnstickTone.splitRationaleHe
          : UnstickTone.splitRationaleEn,
      parameters: {'chunkMinutes': chunkMinutes, 'chunks': 2},
    );
  }

  UnstickOption _shorten() => UnstickOption(
    kind: UnstickKind.shorten,
    title: _isHebrew ? UnstickTone.shortenTitleHe : UnstickTone.shortenTitleEn,
    humanRationale: _isHebrew
        ? UnstickTone.shortenRationaleHe
        : UnstickTone.shortenRationaleEn,
    parameters: const {'minutes': 15},
  );

  UnstickOption _reschedule() => UnstickOption(
    kind: UnstickKind.reschedule,
    title: _isHebrew
        ? UnstickTone.rescheduleTitleHe
        : UnstickTone.rescheduleTitleEn,
    humanRationale: _isHebrew
        ? UnstickTone.rescheduleRationaleHe
        : UnstickTone.rescheduleRationaleEn,
    parameters: const {'when': 'tomorrow'},
  );

  UnstickOption _firstAction() => UnstickOption(
    kind: UnstickKind.firstAction,
    title: _isHebrew
        ? UnstickTone.firstActionTitleHe
        : UnstickTone.firstActionTitleEn,
    humanRationale: _isHebrew
        ? UnstickTone.firstActionRationaleHe
        : UnstickTone.firstActionRationaleEn,
    parameters: const {'minutes': 2, 'label': 'open the file'},
  );

  /// The acknowledgement Pip opens with before the pills.
  String get acknowledgement =>
      _isHebrew ? UnstickTone.acknowledgeHe : UnstickTone.acknowledgeEn;
}
