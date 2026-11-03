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
  static String title(PipMood m) => switch (m) {
    PipMood.glowing => 'Pip is glowing',
    PipMood.warm => 'Pip is warm',
    PipMood.quiet => 'Pip is resting',
  };

  static String momentumLabel(MomentumLevel l) => switch (l) {
    MomentumLevel.strong => 'Strong',
    MomentumLevel.steady => 'Steady',
    MomentumLevel.quiet => 'Quiet',
  };

  /// Hero sentence. With no activity Pip just says hello.
  static String line(PipMood m, int showedUpDays) {
    if (showedUpDays <= 0) {
      return 'Pip is here whenever you are. One small thing is plenty.';
    }
    final days = 'You showed up $showedUpDays of the last 7 days.';
    return switch (m) {
      PipMood.glowing => "$days That's real momentum.",
      PipMood.warm => '$days Nicely steady.',
      PipMood.quiet => '$days Every bit counts.',
    };
  }
}
