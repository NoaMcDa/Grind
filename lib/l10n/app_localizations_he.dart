// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get tabToday => 'היום';

  @override
  String get tabPlan => 'תוכנית';

  @override
  String get tabFocus => 'פוקוס';

  @override
  String get tabPip => 'פיפ';

  @override
  String get tabAsk => 'שאלו';

  @override
  String get askTitle => 'שאלו את פיפ';

  @override
  String get cloudAssistant => 'עוזר בענן';

  @override
  String get askGotIt => 'הבנתי! זו המשימה:';

  @override
  String addedToDay(String day) {
    return 'נוסף ל$day';
  }

  @override
  String get add => 'הוספה';

  @override
  String get edit => 'עריכה';

  @override
  String get yesPlanIt => 'כן, בואו נתכנן';

  @override
  String get justOneBlock => 'רק בלוק אחד';

  @override
  String get quickPlanMyDay => 'תכננו לי את היום';

  @override
  String get quickMoveGym => 'להעביר את האימון לערב';

  @override
  String get composerHint => 'כתבו או הקליטו משימה…';

  @override
  String get speakATask => 'הקלטת משימה';

  @override
  String get sendMessage => 'שליחת הודעה';

  @override
  String focusProgress(int current, int total) {
    return 'פוקוס $current מתוך $total';
  }

  @override
  String hardModeOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count אפליקציות חסומות',
      one: 'אפליקציה אחת חסומה',
    );
    return 'מצב קשוח פעיל · $_temp0';
  }

  @override
  String get paused => 'בהפסקה';

  @override
  String get focusing => 'בפוקוס';

  @override
  String plusMinutes(int minutes) {
    return '+$minutes דק׳';
  }

  @override
  String get pause => 'השהיה';

  @override
  String get resume => 'המשך';

  @override
  String get end => 'סיום';

  @override
  String sessionsDone(int done, int total) {
    return '$done מתוך $total סבבים הושלמו';
  }

  @override
  String get lockScreenPreview => 'תצוגת מסך נעילה';

  @override
  String get liveActivity => 'פעילות חיה';

  @override
  String get pipSays => 'פיפ:';

  @override
  String get pipCheeringSquad => 'קבוצת העידוד הפרטית שלך';

  @override
  String get pipGlowing => 'פיפ קורן';

  @override
  String get sectionMomentum => 'מומנטום';

  @override
  String get momentumStrong => 'חזק';

  @override
  String get sectionThisWeek => 'השבוע';

  @override
  String get weeklyChartSemantics =>
      'דקות פוקוס לכל יום השבוע. יום רביעי היה יום מנוחה, וזה בסדר גמור.';

  @override
  String get focusMinutesPerDay => 'דקות פוקוס ליום';

  @override
  String get sectionWins => 'הניצחונות שלך';

  @override
  String get sectionUnlocks => 'פתיחות';

  @override
  String get accScarf => 'צעיף';

  @override
  String get accSunglasses => 'משקפי שמש';

  @override
  String get accPartyHat => 'כובע מסיבה';

  @override
  String get accRainBoots => 'מגפי גשם';

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get wearing => 'לבוש עכשיו';

  @override
  String get tapToWear => 'הקישו כדי ללבוש';

  @override
  String pipWearing(String item) {
    return 'לובש: $item';
  }

  @override
  String get sectionEnergy => 'אנרגיה';

  @override
  String get energyDeep => 'פוקוס עמוק';

  @override
  String get energyLight => 'קל';

  @override
  String doneOfTotal(int done, int total) {
    return '$done מתוך $total הושלמו';
  }

  @override
  String get planDrafted => 'היום שלך, בטיוטה';

  @override
  String planArranged(int tasks, int classes) {
    return 'פיפ סידר $tasks משימות סביב $classes שיעורים. אפשר לגרור ולשנות.';
  }

  @override
  String get rePlanWithPip => 'תכנון מחדש עם פיפ';

  @override
  String get addTask => 'הוספת משימה';

  @override
  String get fromCalendar => 'מהיומן';

  @override
  String get startFocus => 'התחלת פוקוס';

  @override
  String get goodMorning => 'בוקר טוב!';

  @override
  String get upNext => 'הבא בתור';

  @override
  String get addATask => 'הוספת משימה';

  @override
  String get reminderNow => 'תזכורת · עכשיו';

  @override
  String get done => 'בוצע';

  @override
  String get snooze15 => 'דחייה ב־15';

  @override
  String get niceStart => 'התחלה יפה!';

  @override
  String get pipHappyDance => 'פיפ רוקד ריקוד שמחה קטן.';

  @override
  String seeYouAt(String time) {
    return 'נתראה ב־$time';
  }

  @override
  String get snoozeAgainHint =>
      'עוד קצת זמן? פיפ יציע להזיז את זה למקום נוח יותר.';

  @override
  String get undo => 'ביטול';

  @override
  String get pipSemanticLabel => 'פיפ, המלווה שלך';

  @override
  String get momentumSemantic => 'מומנטום';

  @override
  String get loading => 'טוען';

  @override
  String get dragHandle => 'ידית גרירה';

  @override
  String get dismiss => 'סגירה';

  @override
  String get emptyDefaultTitle => 'עוד אין כאן כלום';

  @override
  String get emptyDefaultBody => 'כשתרצו, פיפ כאן.';

  @override
  String get commonBack => 'חזרה';

  @override
  String get commonSkip => 'דילוג';

  @override
  String get commonCancel => 'ביטול';

  @override
  String get commonSave => 'שמירה';

  @override
  String get commonClear => 'ניקוי';

  @override
  String get commonDelete => 'מחיקה';

  @override
  String get commonConnect => 'חיבור';

  @override
  String get commonConnected => 'מחובר';

  @override
  String get commonSunday => 'ראשון';

  @override
  String get commonMonday => 'שני';

  @override
  String get commonToday => 'היום';

  @override
  String get commonTomorrow => 'מחר';

  @override
  String get commonGoogleCalendar => 'יומן Google';

  @override
  String get commonAppleCalendar => 'יומן Apple';

  @override
  String get commonLanguageEnglish => 'English';

  @override
  String get commonLanguageHebrew => 'עברית';

  @override
  String commonMinutes(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String get commonWeekdayShortMon => 'שני';

  @override
  String get commonWeekdayShortTue => 'שלישי';

  @override
  String get commonWeekdayShortWed => 'רביעי';

  @override
  String get commonWeekdayShortThu => 'חמישי';

  @override
  String get commonWeekdayShortFri => 'שישי';

  @override
  String get commonWeekdayShortSat => 'שבת';

  @override
  String get commonWeekdayShortSun => 'ראשון';

  @override
  String get commonWeekdayFullMon => 'יום שני';

  @override
  String get commonWeekdayFullTue => 'יום שלישי';

  @override
  String get commonWeekdayFullWed => 'יום רביעי';

  @override
  String get commonWeekdayFullThu => 'יום חמישי';

  @override
  String get commonWeekdayFullFri => 'יום שישי';

  @override
  String get commonWeekdayFullSat => 'יום שבת';

  @override
  String get commonWeekdayFullSun => 'יום ראשון';

  @override
  String get commonWeekdayLetterMon => 'ב׳';

  @override
  String get commonWeekdayLetterTue => 'ג׳';

  @override
  String get commonWeekdayLetterWed => 'ד׳';

  @override
  String get commonWeekdayLetterThu => 'ה׳';

  @override
  String get commonWeekdayLetterFri => 'ו׳';

  @override
  String get commonWeekdayLetterSat => 'ש׳';

  @override
  String get commonWeekdayLetterSun => 'א׳';

  @override
  String get commonMonthShortJan => 'ינו׳';

  @override
  String get commonMonthShortFeb => 'פבר׳';

  @override
  String get commonMonthShortMar => 'מרץ';

  @override
  String get commonMonthShortApr => 'אפר׳';

  @override
  String get commonMonthShortMay => 'מאי';

  @override
  String get commonMonthShortJun => 'יוני';

  @override
  String get commonMonthShortJul => 'יולי';

  @override
  String get commonMonthShortAug => 'אוג׳';

  @override
  String get commonMonthShortSep => 'ספט׳';

  @override
  String get commonMonthShortOct => 'אוק׳';

  @override
  String get commonMonthShortNov => 'נוב׳';

  @override
  String get commonMonthShortDec => 'דצמ׳';

  @override
  String commonDateShort(String weekday, String month, int day) {
    return '$weekday, $day ב$month';
  }

  @override
  String get tasksNewTask => 'משימה חדשה';

  @override
  String get tasksEditTask => 'עריכת משימה';

  @override
  String get tasksTitleLabel => 'מה לעשות?';

  @override
  String get tasksTitleRequired => 'שם קצר וסיימנו.';

  @override
  String get tasksDueLabel => 'מועד';

  @override
  String get tasksPickDate => 'בחירת תאריך';

  @override
  String get tasksNoDate => 'בלי תאריך';

  @override
  String get tasksDueTime => 'שעת יעד';

  @override
  String get tasksReminderTime => 'תזכורת';

  @override
  String get tasksAddTime => 'הוספת שעה';

  @override
  String get tasksEstimateLabel => 'כמה זמן?';

  @override
  String get tasksCustom => 'מותאם אישית';

  @override
  String get tasksCustomMinutes => 'דקות';

  @override
  String get tasksFirstActionLabel => 'צעד ראשון';

  @override
  String get tasksFirstActionHint => 'אם השעה 7:00, אז לפתוח את קובץ התזה';

  @override
  String get tasksNotesLabel => 'הערות';

  @override
  String get tasksDetailTitle => 'משימה';

  @override
  String get tasksNotFound => 'המשימה הזאת כבר לא כאן.';

  @override
  String get tasksBackToToday => 'חזרה להיום';

  @override
  String get tasksComplete => 'סימון כבוצע';

  @override
  String get tasksReopen => 'סימון כפתוח';

  @override
  String get tasksDeleteTitle => 'למחוק את המשימה?';

  @override
  String get tasksDeleteBody => 'אפשר לבטל מיד אחרי.';

  @override
  String get tasksKeep => 'להשאיר';

  @override
  String get tasksDeleted => 'המשימה נמחקה';

  @override
  String get tasksMarkedDone => 'כל הכבוד';

  @override
  String get tasksEmptyTitle => 'אין משהו להיום';

  @override
  String get tasksEmptyBody => 'מוסיפים דבר קטן אחד, ופיפ ידאג להזכיר.';

  @override
  String tasksDoneOfToday(int done, int total) {
    return '$done מתוך $total היום';
  }

  @override
  String get remindersTonight => 'הערב';

  @override
  String get remindersPickATime => 'לבחור שעה';

  @override
  String get remindersMoveOffer => 'רוצה להזיז את זה?';

  @override
  String remindersMoveLine(String title) {
    return 'אפשר למצוא ל\"$title\" רגע נוח יותר.';
  }

  @override
  String get remindersLine01 => 'עשרים וחמש דקות מספיקות כדי להתחיל.';

  @override
  String get remindersLine02 => 'גם צעד קטן נחשב.';

  @override
  String get remindersLine03 => 'רק הצעד הראשון. פיפ דואג לשאר.';

  @override
  String get remindersLine04 => 'להתחיל זה החלק הקשה, וכבר הגעת.';

  @override
  String get remindersLine05 => 'אחרי חמש דקות זה נהיה קל יותר.';

  @override
  String get remindersLine06 => 'עמוד אחד זו התחלה מצוינת.';

  @override
  String get remindersLine07 => 'פיפ כבר הכין את הטיימר.';

  @override
  String get remindersLine08 => 'מספיק להתחיל. לסיים זה בונוס.';

  @override
  String get remindersLine09 => 'בחרת את הצעד הזה מסיבה טובה.';

  @override
  String get remindersLine10 => 'לאט לאט זה מצטבר.';

  @override
  String get remindersLine11 => 'פשוט לפתוח ולראות איך זה מרגיש.';

  @override
  String get remindersLine12 => 'התחלה מהירה עדיפה על תוכנית מושלמת.';

  @override
  String get remindersLine13 => 'פיפ מעודד אותך.';

  @override
  String get remindersLine14 => 'עשר דקות של ריכוז עושות הרבה.';

  @override
  String get remindersLine15 => 'להתחיל בקטן ובקלילות.';

  @override
  String get remindersLine16 => 'הרגע הזה שלך.';

  @override
  String get remindersLine17 => 'תנופה מתחילה בתנועה אחת.';

  @override
  String get remindersLine18 => 'בנחת. מתחילים מאיפה שנמצאים.';

  @override
  String get remindersLine19 => 'התחלה קטנה עכשיו, הקלה גדולה אחר כך.';

  @override
  String get remindersLine20 => 'פיפ כאן, מתי שנוח.';

  @override
  String get recurrenceDoesNotRepeat => 'לא חוזר';

  @override
  String get recurrenceDaily => 'כל יום';

  @override
  String get recurrenceWeekdays => 'ימי חול';

  @override
  String get recurrenceWeekly => 'שבועי';

  @override
  String get recurrenceMonthly => 'חודשי';

  @override
  String get recurrenceRepeatLabel => 'חזרה';

  @override
  String get recurrenceOnDays => 'בימים';

  @override
  String get recurrenceEveryLabel => 'כל';

  @override
  String get recurrenceEndsLabel => 'מסתיים';

  @override
  String get recurrenceNever => 'אף פעם';

  @override
  String get recurrenceOnDate => 'בתאריך';

  @override
  String get recurrenceDone => 'סיום';

  @override
  String get recurrenceIncrease => 'הגדלה';

  @override
  String get recurrenceDecrease => 'הקטנה';

  @override
  String recurrenceUnitDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ימים',
      one: 'יום',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'שבועות',
      one: 'שבוע',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'חודשים',
      one: 'חודש',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceEditThisOne => 'רק את זה';

  @override
  String get recurrenceEditAllFuture => 'את כל הבאים';

  @override
  String get recurrenceEditTitle => 'לערוך רק את הפעם הזאת?';

  @override
  String get recurrenceEditHint =>
      'אפשר לשנות פעם אחת, או את הסדרה מכאן והלאה.';

  @override
  String recurrenceEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'כל $n ימים',
      one: 'כל יום',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceEveryWeekday => 'בכל יום חול';

  @override
  String recurrenceEveryWeek(int n, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'כל $n שבועות ביום $days',
      one: 'כל יום $days',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryWeekPlain(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'כל $n שבועות',
      one: 'כל שבוע',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'כל $n חודשים',
      one: 'כל חודש',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonthOn(int n, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'כל $n חודשים',
      one: 'כל חודש',
    );
    return '$_temp0 ב-$day';
  }

  @override
  String recurrenceListJoinLast(String head, String last) {
    return '$head ו$last';
  }

  @override
  String recurrenceUntil(String date) {
    return 'עד $date';
  }

  @override
  String recurrenceTimesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פעמים',
      one: 'פעם אחת',
    );
    return '$_temp0';
  }

  @override
  String recurrenceDateLabel(int day, String month, int year) {
    return '$day ב$month $year';
  }

  @override
  String get planYourDay => 'היום שלך';

  @override
  String planSubtitle(int tasks, int events) {
    String _temp0 = intl.Intl.pluralLogic(
      tasks,
      locale: localeName,
      other: '$tasks משימות',
      one: 'משימה אחת',
    );
    String _temp1 = intl.Intl.pluralLogic(
      events,
      locale: localeName,
      other: '$events אירועים',
      one: 'אירוע אחד',
    );
    return 'פיפ סידר $_temp0 סביב $_temp1. לחיצה ארוכה על משימה מזיזה אותה.';
  }

  @override
  String get planEmptyTitle => 'עוד לא תוכנן כלום';

  @override
  String get planEmptyBody => 'יום שקט. מוסיפים משימה, ופיפ ימצא לה מקום טוב.';

  @override
  String get planPreviousDay => 'היום הקודם';

  @override
  String get planNextDay => 'היום הבא';

  @override
  String get planPickDay => 'בחירת יום';

  @override
  String get planWeekStripLabel => 'שבוע';

  @override
  String get planNowLabel => 'עכשיו';

  @override
  String planDayLoad(String day, int percent) {
    return '$day, $percent% תפוס';
  }

  @override
  String get planAllDay => 'כל היום';

  @override
  String get planCalendarLocal => 'Grind';

  @override
  String get planCalendarLabel => 'יומן';

  @override
  String get planOpenInCalendar => 'פתיחה ביומן';

  @override
  String get planOpenInCalendarSoon => 'פתיחת אפליקציית היומן תגיע בקרוב.';

  @override
  String get planMarkDone => 'סימון כבוצע';

  @override
  String get planMarkOpen => 'סימון כלא בוצע';

  @override
  String get planUnschedule => 'הסרה מהלוח';

  @override
  String get planCantDropHere => 'המשבצת הזאת תפוסה באירוע.';

  @override
  String get onboardingWelcomeTitle => 'היי, אני פיפ';

  @override
  String get onboardingWelcomeBody =>
      'Grind שומר את התוכניות שלך בטלפון הזה. שום דבר לא יוצא ממנו.';

  @override
  String get onboardingWelcomeStart => 'מתחילים';

  @override
  String get onboardingNotifTitle => 'תזכורות עדינות, רק כשבא לך';

  @override
  String get onboardingNotifRationaleTitle => 'למה התראות?';

  @override
  String get onboardingNotifRationale =>
      'תזכורות יכולות להגיע אליך רק אם Grind רשאי להציג אותן. אזכיר לך רק דברים שביקשת שאזכיר.';

  @override
  String get onboardingNotifAllow => 'לאפשר';

  @override
  String get onboardingNotifNotNow => 'לא עכשיו';

  @override
  String get onboardingNotifGranted => 'ההתראות פעילות. תודה!';

  @override
  String get onboardingNotifDenied =>
      'בלי בעיה. Grind עובד מצוין גם בלי התראות. אפשר להפעיל אותן אחר כך בהגדרות.';

  @override
  String get onboardingContinue => 'המשך';

  @override
  String get onboardingCalTitle => 'להביא את היומן שלך';

  @override
  String get onboardingCalRationale =>
      'חיבור יומן מאפשר לי לתכנן סביב פגישות שכבר יש לך. האירועים נקראים במכשיר הזה ונשארים בו.';

  @override
  String get onboardingCalFailed =>
      'זה לא הצליח הפעם. אפשר לנסות מאוחר יותר, או לדלג בינתיים.';

  @override
  String get onboardingCalLater => 'תמיד אפשר לחבר יומן אחר כך בהגדרות.';

  @override
  String get onboardingHoursTitle => 'מתי נעים לך לעבוד?';

  @override
  String get onboardingHoursBody =>
      'אתכנן סביב השעות האלה. כבו יום כדי להשאיר אותו פנוי.';

  @override
  String get onboardingWeekStartLabel => 'השבוע מתחיל ב';

  @override
  String get onboardingLanguageLabel => 'שפה';

  @override
  String get onboardingDoneTitle => 'הכול מוכן.';

  @override
  String get onboardingDoneBody =>
      'הכול נשאר במכשיר הזה. אפשר לשנות כל דבר בהגדרות, מתי שנוח.';

  @override
  String get onboardingDoneButton => 'קחו אותי להיום';

  @override
  String get onboardingDayOff => 'יום חופש';

  @override
  String get onboardingStartTime => 'שעת התחלה';

  @override
  String get onboardingEndTime => 'שעת סיום';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsCalendars => 'יומנים';

  @override
  String get settingsDisconnect => 'ניתוק';

  @override
  String get settingsNotConnected => 'לא מחובר';

  @override
  String get settingsCalendarsToUse => 'יומנים לשימוש';

  @override
  String get settingsConnectFailed =>
      'זה לא הצליח הפעם. מתי שנוח, אפשר לנסות מאוחר יותר.';

  @override
  String get settingsNotifications => 'התראות';

  @override
  String get settingsNotifPermission => 'אישור התראות';

  @override
  String get settingsNotifPermissionOn => 'פעיל';

  @override
  String get settingsNotifPermissionOff =>
      'כבוי. Grind ממשיך לעבוד; אפשר להפעיל אם רוצים תזכורות.';

  @override
  String get settingsLeadTime => 'להזכיר לי לפני';

  @override
  String get settingsLeadAtTime => 'בזמן עצמו';

  @override
  String get settingsQuietHours => 'שעות שקט';

  @override
  String get settingsQuietHoursHint => 'בלי התראות בטווח הזה.';

  @override
  String get settingsQuietFrom => 'מ';

  @override
  String get settingsQuietTo => 'עד';

  @override
  String get settingsMorningPrompt => 'הודעת בוקר';

  @override
  String get settingsEveningPrompt => 'הודעת ערב';

  @override
  String get settingsPromptsHint => 'שלום קצר מפיפ כדי לתכנן או לסכם.';

  @override
  String get settingsPlanning => 'תכנון';

  @override
  String get settingsWorkingHours => 'שעות עבודה';

  @override
  String get settingsWeekStart => 'השבוע מתחיל ב';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsData => 'נתונים';

  @override
  String get settingsExportBackup => 'ייצוא גיבוי';

  @override
  String get settingsImportBackup => 'ייבוא גיבוי';

  @override
  String get settingsDeleteAll => 'מחיקת כל הנתונים';

  @override
  String get settingsExportDone => 'הגיבוי נשמר.';

  @override
  String get settingsImportDone => 'הגיבוי שוחזר.';

  @override
  String get settingsActionFailed => 'זה לא הצליח הפעם. שום דבר לא אבד.';

  @override
  String get settingsDeleteConfirmTitle => 'למחוק הכול?';

  @override
  String get settingsDeleteConfirmBody =>
      'זה ימחק את כל המשימות, התוכניות וההגדרות מהמכשיר הזה. אי אפשר לבטל.';

  @override
  String get settingsDeleteConfirm => 'מחיקה';

  @override
  String get settingsDeleted => 'כל הנתונים נמחקו.';

  @override
  String get settingsAbout => 'אודות';

  @override
  String get settingsVersion => 'גרסה';

  @override
  String get settingsLicences => 'רישיונות';

  @override
  String get settingsPrivacy => 'פרטיות';

  @override
  String get settingsPrivacyCopy =>
      'הכול נשאר במכשיר הזה. בלי חשבון, בלי הרשמה.';
}
