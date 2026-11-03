/// Evening review copy (EN). Pip's tone: an invitation, never guilt.
abstract final class ReviewStrings {
  static const bannerTitle = 'Ready for a one-minute look back?';
  static const bannerAction = 'Start';
  static const skip = 'Skip';
  static const next = 'Continue';

  static const doneTitle = 'What got done?';
  static const doneHint = 'Tick anything you finished. Pip counts it all.';
  static const doneEmpty = 'Nothing was waiting on today. Lovely and light.';

  static const moveTitle = 'What moves on?';
  static const moveHint = 'Give each one a gentle new spot.';
  static const moveEmpty = 'Nothing left to move. You are clear.';
  static const tomorrow = 'Tomorrow';
  static const later = 'Later this week';
  static const keepToday = 'Keep today';
  static const tomorrowAnyway = 'Tomorrow anyway';
  static const drop = 'Drop';
  static const dropped = 'Dropped.';
  static const undo = 'Undo';
  static const deadlineNote =
      'This one is due today. Moving it is fine, just your call.';
  static const repeatsNote = 'Repeats on its own, so it stays put.';

  static const winTitle = 'One win';
  static const winHint = 'Big or tiny. What are you glad about today?';
  static const winField = 'Today I...';
  static const save = 'Save and finish';

  static const finishTitle = 'Day wrapped';
  static const finishButton = 'Done';

  static const praise = [
    'You showed up today. That is the whole trick.',
    'A good day to be you. Sleep well.',
    'Small steps still count. Nice work today.',
    'Look at you, closing the day with care.',
    'Whatever got done, I am proud of you.',
  ];

  /// One praise line, stable for a given [seed] (the day of the month).
  static String praiseFor(int seed) => praise[seed % praise.length];
}
