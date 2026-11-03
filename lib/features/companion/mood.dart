import '../../l10n/app_localizations.dart';
import 'effort_score.dart';

/// How Pip looks and sounds. All three are kind: even [quiet] is a rested,
/// content Pip, never a sad one.
enum PipMood { glowing, warm, quiet }

PipMood moodFor(MomentumLevel level) => switch (level) {
  MomentumLevel.strong => PipMood.glowing,
  MomentumLevel.steady => PipMood.warm,
  MomentumLevel.quiet => PipMood.quiet,
};

/// Copy for the Pip screen. No negative wording anywhere (docs/tone-guide.md).
abstract final class MoodCopy {
  static String title(AppLocalizations l, PipMood m) => switch (m) {
    PipMood.glowing => l.pipGlowing,
    PipMood.warm => l.pipMoodWarm,
    PipMood.quiet => l.pipMoodResting,
  };

  static String momentumLabel(AppLocalizations l, MomentumLevel level) =>
      switch (level) {
        MomentumLevel.strong => l.momentumStrong,
        MomentumLevel.steady => l.momentumSteady,
        MomentumLevel.quiet => l.momentumQuiet,
      };

  /// Hero sentence. With no activity Pip just says hello.
  static String line(AppLocalizations l, PipMood m, int showedUpDays) {
    if (showedUpDays <= 0) return l.pipLineHello;
    final days = l.pipShowedUp(showedUpDays);
    return switch (m) {
      PipMood.glowing => '$days ${l.pipLineGlowing}',
      PipMood.warm => '$days ${l.pipLineWarm}',
      PipMood.quiet => '$days ${l.pipLineQuiet}',
    };
  }
}
