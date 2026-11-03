# Strings migration map

Switch call sites from the `*_strings.dart` files to `context.l10n.<key>`
(`import 'package:grind/l10n/l10n.dart'`). Keys marked **existing** were
already in the ARB files; where a `*_strings.dart` constant duplicates one,
use the existing key instead of adding a new one. Helpers that took a
`DateTime`/list stay in Dart and feed localized pieces into the keys below.

Tone rewrites: `snoozeAgainHint`, `onboardingCalFailed` and
`settingsConnectFailed` no longer contain "again" (the banned-words test in
`test/theme/theme_l10n_test.dart` enforces this for all values).

Intentionally not in ARB: `SettingsStrings.appVersion` ('0.1.0', not
copy; read it from the package info), demo content in the focus, pip and ask
screens (already covered by existing keys such as `focusProgress`,
`hardModeOn`, `askTitle`, `addedToDay`).

## Common

| Source | ARB key |
|---|---|
| `OnboardingStrings.skip` | `commonSkip` |
| `OnboardingStrings.back`, `SettingsStrings.back`, `PlanStrings.back` | `commonBack` |
| `TasksStrings.cancel`, `SettingsStrings.cancel` | `commonCancel` |
| `TasksStrings.save` | `commonSave` |
| `TasksStrings.clear` | `commonClear` |
| `TasksStrings.delete` | `commonDelete` |
| `OnboardingStrings.calConnect`, `SettingsStrings.connect` | `commonConnect` |
| `OnboardingStrings.calConnected`, `SettingsStrings.connected` | `commonConnected` |
| `OnboardingStrings.sunday`, `SettingsStrings.sunday` | `commonSunday` |
| `OnboardingStrings.monday`, `SettingsStrings.monday` | `commonMonday` |
| `TasksStrings.today` | `commonToday` |
| `TasksStrings.tomorrow`, `RemindersStrings.tomorrow` | `commonTomorrow` |
| `OnboardingStrings.calGoogle`, `SettingsStrings.google`, `PlanStrings.calendarGoogle` | `commonGoogleCalendar` |
| `OnboardingStrings.calApple`, `SettingsStrings.apple`, `PlanStrings.calendarApple` | `commonAppleCalendar` |
| `OnboardingStrings.english`, `SettingsStrings.english` | `commonLanguageEnglish` |
| `OnboardingStrings.hebrew`, `SettingsStrings.hebrew` | `commonLanguageHebrew` |
| `TasksStrings.minutes(m)`, `SettingsStrings.minutesBefore(m)` (m > 0) | `commonMinutes(minutes)` |
| `TasksStrings._weekdays`, `PlanStrings.weekdayShort`, `OnboardingStrings.dayShort`, `RecurrenceStrings.weekdayShort(d)` | `commonWeekdayShortMon` ... `commonWeekdayShortSun` (weekday 1 = Mon) |
| `RecurrenceStrings.weekdayFull(d)` | `commonWeekdayFullMon` ... `Sun` |
| `RecurrenceStrings.weekdayLetter(d)` | `commonWeekdayLetterMon` ... `Sun` |
| `TasksStrings._months`, `PlanStrings.monthShort` | `commonMonthShortJan` ... `Dec` |
| `TasksStrings.date(d)` | `commonDateShort(weekday, month, day)` (pass the localized weekday and month names) |

Pick the key from a weekday number with a small switch in Dart, for example
`[l.commonWeekdayShortMon, ..., l.commonWeekdayShortSun][weekday - 1]`.

## Tasks (`tasks_strings.dart`)

| Constant / helper | ARB key |
|---|---|
| `newTask` | `tasksNewTask` |
| `editTask` | `tasksEditTask` |
| `titleLabel` | `tasksTitleLabel` |
| `titleRequired` | `tasksTitleRequired` |
| `dueLabel` | `tasksDueLabel` |
| `pickDate` | `tasksPickDate` |
| `noDate` | `tasksNoDate` |
| `dueTime` | `tasksDueTime` |
| `reminderTime` | `tasksReminderTime` |
| `addTime` | `tasksAddTime` |
| `estimateLabel` | `tasksEstimateLabel` |
| `custom` | `tasksCustom` |
| `customMinutes` | `tasksCustomMinutes` |
| `energyLabel` | `sectionEnergy` (existing) |
| `deep` | `energyDeep` (existing) |
| `light` | `energyLight` (existing) |
| `firstActionLabel` | `tasksFirstActionLabel` |
| `firstActionHint` | `tasksFirstActionHint` |
| `notesLabel` | `tasksNotesLabel` |
| `addTask`, `emptyAction` | `addATask` (existing) |
| `detailTitle` | `tasksDetailTitle` |
| `notFound` | `tasksNotFound` |
| `backToToday` | `tasksBackToToday` |
| `complete` | `tasksComplete` |
| `reopen` | `tasksReopen` |
| `edit` | `edit` (existing) |
| `deleteTitle` | `tasksDeleteTitle` |
| `deleteBody` | `tasksDeleteBody` |
| `keep` | `tasksKeep` |
| `deleted` | `tasksDeleted` |
| `markedDone` | `tasksMarkedDone` |
| `undo` | `undo` (existing) |
| `emptyTitle` | `tasksEmptyTitle` |
| `emptyBody` | `tasksEmptyBody` |
| `upNext` | `upNext` (existing) |
| `momentum` | `sectionMomentum` (existing) |
| `doneOf(done, total)` | `tasksDoneOfToday(done, total)` |
| `minutes(m)` | `commonMinutes(minutes)` |
| `date(d)` | `commonDateShort` (see Common) |

## Reminders (`reminders_strings.dart`, `reminder_copy.dart`)

| Field / helper | ARB key |
|---|---|
| `reminderNow` | `reminderNow` (existing; uppercase it with `toUpperCase()` if the card wants caps) |
| `done` | `done` (existing) |
| `snooze15` | `snooze15` (existing) |
| `startFocus` | `startFocus` (existing) |
| `niceStart` | `niceStart` (existing) |
| `happyDance` | `pipHappyDance` (existing) |
| `seeYouAt(time)` | `seeYouAt(time)` (existing) |
| `snoozeHint` | `snoozeAgainHint` (existing, value reworded) |
| `undo` | `undo` (existing) |
| `tonight` | `remindersTonight` |
| `tomorrow` | `commonTomorrow` |
| `pickATime` | `remindersPickATime` |
| `ReminderCopy._moveOffer` | `remindersMoveOffer` |
| `ReminderCopy._moveLine(lang, title)` | `remindersMoveLine(title)` |
| `ReminderCopy._pool` (20 lines, index i) | `remindersLine01` ... `remindersLine20` (same order as the pool) |

`ReminderCopy` also runs outside a widget tree (notifications). It has no
`BuildContext` there: load the strings with
`lookupAppLocalizations(Locale(prefs.localeCode))` from
`app_localizations.dart` and index `remindersLineNN` by the same hash it uses
now. `ReminderCopy._fallbackTitle` ('Grind') is the app name and stays in Dart.

## Recurrence (`recurrence_strings.dart`)

| Getter / helper | ARB key |
|---|---|
| `doesNotRepeat` | `recurrenceDoesNotRepeat` |
| `daily` | `recurrenceDaily` |
| `weekdays` | `recurrenceWeekdays` |
| `weekly` | `recurrenceWeekly` |
| `monthly` | `recurrenceMonthly` |
| `repeatLabel` | `recurrenceRepeatLabel` |
| `onDays` | `recurrenceOnDays` |
| `everyLabel` | `recurrenceEveryLabel` |
| `endsLabel` | `recurrenceEndsLabel` |
| `never` | `recurrenceNever` |
| `onDate` | `recurrenceOnDate` |
| `done` | `recurrenceDone` |
| `increase` / `decrease` | `recurrenceIncrease` / `recurrenceDecrease` |
| `intervalUnit(day, n)` | `recurrenceUnitDay(n)` |
| `intervalUnit(week, n)` | `recurrenceUnitWeek(n)` |
| `intervalUnit(month, n)` | `recurrenceUnitMonth(n)` |
| `editThisOne` | `recurrenceEditThisOne` |
| `editAllFuture` | `recurrenceEditAllFuture` |
| `editTitle` | `recurrenceEditTitle` |
| `editHint` | `recurrenceEditHint` |
| `everyDay(n)` | `recurrenceEveryDay(n)` |
| `everyWeekday` | `recurrenceEveryWeekday` |
| `everyWeek(n, days)` | `recurrenceEveryWeek(n, days)`: build `days` from `commonWeekdayShort*` joined with ", " (English) or, in Hebrew, with the last item joined by `recurrenceListJoinLast(head, last)` |
| `everyWeekPlain(n)` | `recurrenceEveryWeekPlain(n)` |
| `everyMonth(n, null)` | `recurrenceEveryMonth(n)` |
| `everyMonth(n, day)` | `recurrenceEveryMonthOn(n, day)`: pass the day as a string (English ordinal "3rd" from `_ordinal`, plain number in Hebrew) |
| `untilSuffix(d)` | `' ${recurrenceUntil(date)}'` |
| `countSuffix(c)` | `', ${recurrenceTimesCount(c)}'` |
| `dateLabel(d)` | `recurrenceDateLabel(day, month, year)` with `commonMonthShort*` (Hebrew output changes from `5/11/2026` to `5 בנוב׳ 2026`) |
| `_heJoin` | `recurrenceListJoinLast(head, last)` |

## Plan (`plan_strings.dart`)

| Constant / helper | ARB key |
|---|---|
| `titleToday` | `planDrafted` (existing) |
| `titleOtherDay` | `planYourDay` |
| `subtitle(tasks, events)` | `planSubtitle(tasks, events)` (plurals inside) |
| `emptyTitle` / `emptyBody` | `planEmptyTitle` / `planEmptyBody` |
| `previousDay` / `nextDay` / `pickDay` | `planPreviousDay` / `planNextDay` / `planPickDay` |
| `weekStripLabel` | `planWeekStripLabel` |
| `nowLabel` | `planNowLabel` |
| `dayLoad(day, percent)` | `planDayLoad(day, percent)` |
| `doneCount(done, total)` | `doneOfTotal(done, total)` (existing) |
| `fromCalendar` | `fromCalendar` (existing; uppercase in the widget) |
| `allDay` | `planAllDay` |
| `calendarGoogle` / `calendarApple` | `commonGoogleCalendar` / `commonAppleCalendar` |
| `calendarLocal` | `planCalendarLocal` |
| `calendarLabel` | `planCalendarLabel` |
| `openInCalendar` | `planOpenInCalendar` |
| `openInCalendarSoon` | `planOpenInCalendarSoon` |
| `markDone` | `planMarkDone` |
| `markOpen` | `planMarkOpen` |
| `unschedule` | `planUnschedule` |
| `taskDetailTitle` | `tasksDetailTitle` |
| `back` | `commonBack` |
| `cantDropHere` | `planCantDropHere` |
| `weekdayShort`, `monthShort` | `commonWeekdayShort*`, `commonMonthShort*` |

## Onboarding (`onboarding_strings.dart`)

| Constant | ARB key |
|---|---|
| `skip` / `back` | `commonSkip` / `commonBack` |
| `welcomeTitle` / `welcomeBody` / `welcomeStart` | `onboardingWelcomeTitle` / `onboardingWelcomeBody` / `onboardingWelcomeStart` |
| `notifTitle` | `onboardingNotifTitle` |
| `notifRationaleTitle` | `onboardingNotifRationaleTitle` |
| `notifRationale` | `onboardingNotifRationale` |
| `notifAllow` / `notifNotNow` | `onboardingNotifAllow` / `onboardingNotifNotNow` |
| `notifGranted` / `notifDenied` | `onboardingNotifGranted` / `onboardingNotifDenied` |
| `continueLabel` | `onboardingContinue` |
| `calTitle` / `calRationale` | `onboardingCalTitle` / `onboardingCalRationale` |
| `calGoogle` / `calApple` | `commonGoogleCalendar` / `commonAppleCalendar` |
| `calConnect` / `calConnected` | `commonConnect` / `commonConnected` |
| `calFailed` | `onboardingCalFailed` |
| `calLater` | `onboardingCalLater` |
| `hoursTitle` / `hoursBody` | `onboardingHoursTitle` / `onboardingHoursBody` |
| `weekStartLabel` | `onboardingWeekStartLabel` |
| `languageLabel` | `onboardingLanguageLabel` |
| `sunday` / `monday` | `commonSunday` / `commonMonday` |
| `english` / `hebrew` | `commonLanguageEnglish` / `commonLanguageHebrew` |
| `doneTitle` / `doneBody` / `doneButton` | `onboardingDoneTitle` / `onboardingDoneBody` / `onboardingDoneButton` |
| `dayOff` | `onboardingDayOff` |
| `dayShort` | `commonWeekdayShort*` |
| `startTime` / `endTime` | `onboardingStartTime` / `onboardingEndTime` |

## Settings (`settings_strings.dart`)

| Constant / helper | ARB key |
|---|---|
| `title` | `settingsTitle` |
| `back` | `commonBack` |
| `calendars` | `settingsCalendars` |
| `google` / `apple` | `commonGoogleCalendar` / `commonAppleCalendar` |
| `connect` / `connected` | `commonConnect` / `commonConnected` |
| `disconnect` | `settingsDisconnect` |
| `notConnected` | `settingsNotConnected` |
| `calendarsToUse` | `settingsCalendarsToUse` |
| `connectFailed` | `settingsConnectFailed` |
| `notifications` | `settingsNotifications` |
| `notifPermission` | `settingsNotifPermission` |
| `notifPermissionOn` / `notifPermissionOff` | `settingsNotifPermissionOn` / `settingsNotifPermissionOff` |
| `leadTime` | `settingsLeadTime` |
| `leadAtTime` | `settingsLeadAtTime` |
| `quietHours` / `quietHoursHint` | `settingsQuietHours` / `settingsQuietHoursHint` |
| `quietFrom` / `quietTo` | `settingsQuietFrom` / `settingsQuietTo` |
| `morningPrompt` / `eveningPrompt` | `settingsMorningPrompt` / `settingsEveningPrompt` |
| `promptsHint` | `settingsPromptsHint` |
| `planning` | `settingsPlanning` |
| `workingHours` | `settingsWorkingHours` |
| `weekStart` | `settingsWeekStart` |
| `sunday` / `monday` | `commonSunday` / `commonMonday` |
| `language` | `settingsLanguage` |
| `english` / `hebrew` | `commonLanguageEnglish` / `commonLanguageHebrew` |
| `data` | `settingsData` |
| `exportBackup` / `importBackup` / `deleteAll` | `settingsExportBackup` / `settingsImportBackup` / `settingsDeleteAll` |
| `exportDone` / `importDone` | `settingsExportDone` / `settingsImportDone` |
| `actionFailed` | `settingsActionFailed` |
| `deleteConfirmTitle` / `deleteConfirmBody` | `settingsDeleteConfirmTitle` / `settingsDeleteConfirmBody` |
| `deleteConfirm` | `settingsDeleteConfirm` |
| `cancel` | `commonCancel` |
| `deleted` | `settingsDeleted` |
| `about` / `version` / `licences` / `privacy` | `settingsAbout` / `settingsVersion` / `settingsLicences` / `settingsPrivacy` |
| `privacyCopy` | `settingsPrivacyCopy` |
| `appVersion` | not copy; keep in Dart |
| `minutesBefore(m)` | `m == 0 ? settingsLeadAtTime : commonMinutes(m)` |

## Already covered by existing keys (screens with inline literals)

| Screen literal | ARB key |
|---|---|
| focus: "FOCUS 2 OF 4", hard-mode pill, "PAUSED", "+5 min", "End", sessions semantics | `focusProgress`, `hardModeOn`, `paused`, `plusMinutes`, `end`, `sessionsDone` |
| pip: "Pip", "Strong", "wearing: x", "Party hat", "Rain boots" | `tabPip`, `momentumStrong`, `pipWearing`, `accPartyHat`, `accRainBoots` |
| ask: "Ask Pip", "Cloud assistant", "Added to Friday", "Light", "Add", "Edit", "Yes, plan it", "Just one block", "Send message" | `askTitle`, `cloudAssistant`, `addedToDay`, `energyLight`, `add`, `edit`, `yesPlanIt`, `justOneBlock`, `sendMessage` |
