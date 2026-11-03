/// All user-facing onboarding copy, in one place so localization can move it.
/// Pip's tone: inviting, honest, never guilt.
abstract final class OnboardingStrings {
  static const skip = 'Skip';
  static const back = 'Back';

  static const welcomeTitle = "Hi, I'm Pip";
  static const welcomeBody =
      'Grind keeps your plans on this phone. Nothing leaves it.';
  static const welcomeStart = 'Start';

  static const notifTitle = 'Gentle nudges, only when you want them';
  static const notifRationaleTitle = 'Why notifications?';
  static const notifRationale =
      'Reminders can only reach you if Grind may show them. I will only '
      'nudge you about things you asked me to remind you of.';
  static const notifAllow = 'Allow';
  static const notifNotNow = 'Not now';
  static const notifGranted = 'Notifications are on. Thank you!';
  static const notifDenied =
      'No problem. Grind works fine without notifications. You can switch '
      'them on later in Settings.';
  static const continueLabel = 'Continue';

  static const calTitle = 'Bring your calendar along';
  static const calRationale =
      'Connecting a calendar lets me plan around meetings you already have. '
      'Events are read on this device and stay here.';
  static const calGoogle = 'Google Calendar';
  static const calApple = 'Apple Calendar';
  static const calConnect = 'Connect';
  static const calConnected = 'Connected';
  static const calFailed =
      'That did not work this time. You can try again, or skip it for now.';
  static const calLater = 'You can always connect one later in Settings.';

  static const hoursTitle = 'When do you like to work?';
  static const hoursBody =
      'I will plan around these hours. Switch a day off to keep it free.';
  static const weekStartLabel = 'Week starts on';
  static const languageLabel = 'Language';
  static const sunday = 'Sunday';
  static const monday = 'Monday';
  static const english = 'English';
  static const hebrew = 'עברית';

  static const doneTitle = "You're set.";
  static const doneBody =
      'Everything stays on this device. You can change any of this in '
      'Settings, whenever you like.';
  static const doneButton = 'Take me to Today';

  static const dayOff = 'Day off';
  static const dayShort = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  static const startTime = 'Start time';
  static const endTime = 'End time';
}
