/// All user-facing settings copy, in one place so localization can move it.
abstract final class SettingsStrings {
  static const title = 'Settings';
  static const back = 'Back';

  static const calendars = 'Calendars';
  static const google = 'Google Calendar';
  static const apple = 'Apple Calendar';
  static const connect = 'Connect';
  static const disconnect = 'Disconnect';
  static const connected = 'Connected';
  static const notConnected = 'Not connected';
  static const calendarsToUse = 'Calendars to use';
  static const connectFailed =
      'That did not work this time. You can try again whenever you like.';

  static const syncing = 'Syncing...';
  static const syncIdle = 'Up to date';
  static const syncError = 'Pip could not reach your calendar just now.';
  static String lastSynced(String hhmm) => 'Last synced $hhmm';

  static const notifications = 'Notifications';
  static const notifPermission = 'Allow notifications';
  static const notifPermissionOn = 'On';
  static const notifPermissionOff =
      'Off. Grind keeps working; turn them on if you want reminders.';
  static const leadTime = 'Remind me before';
  static const leadAtTime = 'At the time';
  static const quietHours = 'Quiet hours';
  static const quietHoursHint = 'No notifications in this window.';
  static const quietFrom = 'From';
  static const quietTo = 'To';
  static const morningPrompt = 'Morning prompt';
  static const eveningPrompt = 'Evening prompt';
  static const promptsHint = 'A short hello from Pip to plan or wrap up.';

  static const planning = 'Planning';
  static const workingHours = 'Working hours';
  static const weekStart = 'Week starts on';
  static const timeZone = 'Time zone';
  static const timeZoneSearch = 'Search, e.g. London';
  static const timeZoneNoMatch = 'No zone by that name. Try a city.';
  static String useDeviceZone(String zone) => 'Use this device: $zone';
  static const sunday = 'Sunday';
  static const monday = 'Monday';

  static const language = 'Language';
  static const english = 'English';
  static const hebrew = 'עברית';

  static const data = 'Data';
  static const exportBackup = 'Export backup';
  static const exportHint =
      'Includes calendar events Pip mirrored, such as meeting titles.';
  static const importBackup = 'Import backup';
  static const deleteAll = 'Delete all data';
  static const exportDone = 'Backup saved.';
  static const importDone = 'Backup restored.';
  static const actionFailed = 'That did not work this time. Nothing was lost.';
  static const deleteConfirmTitle = 'Delete everything?';
  static const deleteConfirmBody =
      'This removes all tasks, plans and settings from this device. '
      'It cannot be undone.';
  static const deleteConfirm = 'Delete';
  static const cancel = 'Cancel';
  static const deleted = 'All data deleted.';

  static const about = 'About';
  static const version = 'Version';
  static const appVersion = '0.1.0';
  static const licences = 'Licences';
  static const privacy = 'Privacy';
  static const privacyCopy =
      'Your plans stay on this device. No account, no analytics. '
      'If you connect a calendar, Pip reads its events to plan around them '
      'and writes back only the tasks you schedule. '
      'Disconnect any time.';

  static String minutesBefore(int m) => m == 0 ? leadAtTime : '$m min';
}
