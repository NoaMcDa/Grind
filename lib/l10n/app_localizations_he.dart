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
  String get quickWhatsNext => 'מה הבא?';

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
  String commonHours(int hours) {
    return '$hours ש׳';
  }

  @override
  String commonHoursMinutes(int hours, int minutes) {
    return '$hours ש׳ $minutes דק׳';
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
  String get tasksCustomDuration => 'משך';

  @override
  String get tasksCustomDurationHint => '90, 4h, 1:30';

  @override
  String get tasksCustomDurationInvalid => 'הזינו משך כמו 4h, 1:30 או 90';

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
  String get remindersLine11 => 'גם רק לפתוח את זה נחשב.';

  @override
  String get remindersLine12 => 'התחלה מהירה עדיפה על תוכנית מושלמת.';

  @override
  String get remindersLine13 => 'פיפ מעודד אותך.';

  @override
  String get remindersLine14 => 'עשר דקות של ריכוז עושות הרבה.';

  @override
  String get remindersLine15 => 'קטן וקליל זה מספיק.';

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
  String get planAddAsTask => 'הוספה כמשימה';

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
  String get onboardingQuietLabel => 'שקט בלילה';

  @override
  String onboardingQuietBody(String range) {
    return 'בלי תזכורות $range. אפשר לשנות בהגדרות.';
  }

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

  @override
  String get pipNoAccessory => 'בלי אביזר';

  @override
  String get momentumSteady => 'יציב';

  @override
  String get momentumQuiet => 'שקט';

  @override
  String get pipMoodWarm => 'פיפ חם ונעים';

  @override
  String get pipMoodResting => 'פיפ נח';

  @override
  String get pipLineHello => 'פיפ כאן מתי שנוח לך. דבר קטן אחד מספיק.';

  @override
  String pipShowedUp(int days) {
    return 'הופעת $days מתוך 7 הימים האחרונים.';
  }

  @override
  String get pipLineGlowing => 'זו תנופה אמיתית.';

  @override
  String get pipLineWarm => 'יציב ויפה.';

  @override
  String get pipLineQuiet => 'כל קצת נחשב.';

  @override
  String get pipMomentumNote => 'התנופה דועכת לאט, יום שקט אחד לא מאפס אותה.';

  @override
  String get pipWeekSemantics =>
      'מה הושלם בכל יום השבוע. ימים בלי השלמות הם ימי מנוחה.';

  @override
  String get pipRestDay => 'יום מנוחה';

  @override
  String get pipWeekCaption => 'משימות וסבבים שהושלמו בכל יום';

  @override
  String get pipFirstWin => 'הניצחון הראשון שלך יופיע כאן.';

  @override
  String get accCrown => 'כתר';

  @override
  String pipMoreTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count משימות נוספות',
      one: 'משימה אחת נוספת',
    );
    return '$_temp0';
  }

  @override
  String pipMoreDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים נוספים',
      one: 'יום אחד נוסף',
    );
    return '$_temp0';
  }

  @override
  String get pipFinishGoal => 'להשלים יעד';

  @override
  String pipUnlockedToast(String item) {
    return 'חדש אצל פיפ: $item. אפשר ללבוש במלתחה של פיפ.';
  }

  @override
  String get pipToggleWear => 'הקשה ללבוש או להסיר';

  @override
  String pipMoreSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סבבים נוספים',
      one: 'סבב אחד נוסף',
    );
    return '$_temp0';
  }

  @override
  String get focusFree => 'ריכוז חופשי';

  @override
  String get focusBreak => 'הפסקה';

  @override
  String get focusLongBreak => 'הפסקה ארוכה';

  @override
  String get focusReady => 'מוכן';

  @override
  String get focusOnBreak => 'בהפסקה';

  @override
  String focusOfTotal(String total) {
    return 'מתוך $total';
  }

  @override
  String get focusHardModeSoon => 'מצב קשוח · בקרוב';

  @override
  String focusMinusMinutes(int minutes) {
    return '−$minutes דק׳';
  }

  @override
  String get focusStartNext => 'להתחיל ריכוז הבא';

  @override
  String get focusEndBreak => 'לסיים הפסקה';

  @override
  String get focusDoneTitle => 'הסבב הסתיים. עבודה יפה.';

  @override
  String get focusEarlyTitle => 'הסבב הסתיים. הוא עדיין נחשב.';

  @override
  String focusFocusedFor(String duration) {
    return 'התרכזת $duration.';
  }

  @override
  String focusFocusedForTask(String duration, String task) {
    return 'התרכזת $duration על $task.';
  }

  @override
  String get focusMarkDone => 'לסמן משימה כבוצעה';

  @override
  String get focusKeepGoing => 'להמשיך';

  @override
  String get focusLogWin => 'לרשום ניצחון';

  @override
  String get focusWinLogged => 'הניצחון נרשם. פיפ ראה.';

  @override
  String get focusWinTitle => 'מה הספקת?';

  @override
  String get focusWinHint => 'טיוטה של פרק 2';

  @override
  String get focusTaskDone => 'המשימה בוצעה. פיפ גאה בך.';

  @override
  String get focusSessionOverToast => 'הזמן נגמר! הסבב הסתיים, אפשר לנשום.';

  @override
  String get focusBreakOverToast => 'ההפסקה נגמרה. מוכנים כשנוח לך.';

  @override
  String get focusCheerIdle1 =>
      'בוחרים אורך ולוחצים על התחלה. פיפ ישמור על הזמן.';

  @override
  String get focusCheerIdle2 => 'צעד קטן אחד מספיק כדי להתחיל. פיפ כאן לידך.';

  @override
  String get focusCheerStart1 => 'הדקות הראשונות הן הקשות, וכבר התחלת.';

  @override
  String get focusCheerStart2 => 'רק הצעד הקטן הבא. שום דבר אחר לא חשוב עכשיו.';

  @override
  String get focusCheerMiddle1 => 'קצב יפה. נשארים פשוטים.';

  @override
  String get focusCheerMiddle2 => 'אתם בתוך זה. פיפ מעודד בשקט.';

  @override
  String get focusCheerPastHalf1 =>
      'עברתם את החצי. ממשיכים, מספיק שהטיוטה הראשונה תהיה קיימת.';

  @override
  String get focusCheerPastHalf2 => 'יותר מחצי כבר מאחורינו. בקצב יציב מגיעים.';

  @override
  String get focusCheerNearEnd1 => 'כמעט שם. מסיימים את המשפט שאתם באמצעו.';

  @override
  String get focusCheerNearEnd2 => 'נשארו כמה דקות. נוחתים בעדינות.';

  @override
  String get focusCheerPaused1 => 'בהשהיה. נושמים, פיפ יחכה.';

  @override
  String get focusCheerPaused2 => 'הפסקות קטנות הן בסדר. חוזרים כשמוכנים.';

  @override
  String get focusCheerBreak1 => 'זמן הפסקה. קמים, מתמתחים, שותים מים.';

  @override
  String get focusCheerBreak2 => 'מנוחה היא חלק מהעבודה. מסתכלים על משהו רחוק.';

  @override
  String get reviewBannerTitle => 'מוכנים להסתכלות קצרה אחורה?';

  @override
  String get reviewBannerAction => 'להתחיל';

  @override
  String get reviewDoneTitle => 'מה הושלם?';

  @override
  String get reviewDoneHint => 'מסמנים כל מה שסיימתם. פיפ סופר הכול.';

  @override
  String get reviewDoneEmpty => 'שום דבר לא חיכה היום. קליל ונעים.';

  @override
  String get reviewMoveTitle => 'מה ממשיך הלאה?';

  @override
  String get reviewMoveHint => 'נותנים לכל אחד מקום חדש ונעים.';

  @override
  String get reviewMoveEmpty => 'אין מה להזיז. הכול פנוי.';

  @override
  String get reviewLater => 'בהמשך השבוע';

  @override
  String get reviewKeepToday => 'להשאיר להיום';

  @override
  String get reviewTomorrowAnyway => 'למחר בכל זאת';

  @override
  String get reviewDrop => 'להוריד';

  @override
  String get reviewDropped => 'הוסר.';

  @override
  String get reviewDeadlineNote =>
      'המשימה הזו מיועדת להיום. אפשר להזיז אותה, ההחלטה שלך.';

  @override
  String get reviewRepeatsNote => 'חוזרת מעצמה, אז היא נשארת במקומה.';

  @override
  String get reviewCheckInTitle => 'צ\'ק-אין על היעדים';

  @override
  String get reviewCheckInHint =>
      'סמנו כל מה שעשיתם היום. פיפ ירשום +1 על כל אחד.';

  @override
  String get reviewCheckInEmpty =>
      'אין עדיין יעדים חוזרים. אפשר להוסיף אחד מלשונית היעדים.';

  @override
  String reviewCheckInUnitWeek(String unit) {
    return '$unit השבוע';
  }

  @override
  String reviewCheckInUnitMonth(String unit) {
    return '$unit החודש';
  }

  @override
  String get reviewWinTitle => 'ניצחון אחד';

  @override
  String get reviewWinHint => 'גדול או קטנטן. על מה שמחתם היום?';

  @override
  String get reviewWinField => 'היום אני...';

  @override
  String get reviewSave => 'לשמור ולסיים';

  @override
  String get reviewFinishTitle => 'היום נסגר';

  @override
  String get reviewPraise1 => 'הגעתם היום. זה כל הסוד.';

  @override
  String get reviewPraise2 => 'יום טוב להיות אתם. לילה טוב.';

  @override
  String get reviewPraise3 => 'צעדים קטנים עדיין נחשבים. עבודה יפה היום.';

  @override
  String get reviewPraise4 => 'תראו אתכם, סוגרים את היום בתשומת לב.';

  @override
  String get reviewPraise5 => 'מה שלא יהיה שהושלם, אני גאה בכם.';

  @override
  String get goalsTitle => 'יעדים';

  @override
  String get goalsAllGoalsLink => 'כל היעדים';

  @override
  String get goalsSubtitle => 'קרובים ורחוקים. כל צעד קטן נחשב.';

  @override
  String get goalsNewGoal => 'יעד חדש';

  @override
  String get goalsEditGoal => 'עריכת יעד';

  @override
  String get goalsEmptyTitle => 'עדיין אין יעדים';

  @override
  String get goalsEmptyBody =>
      'בוחרים דבר אחד שהייתם שמחים להזיז החודש. פיפ יעודד.';

  @override
  String get goalsEmptyAction => 'להוסיף יעד';

  @override
  String get goalsHorizonWeek => 'השבוע';

  @override
  String get goalsHorizonMonth => 'החודש';

  @override
  String get goalsHorizonQuarter => 'הרבעון';

  @override
  String get goalsHorizonYear => 'השנה';

  @override
  String get goalsHorizonShortWeek => 'שבוע';

  @override
  String get goalsHorizonShortMonth => 'חודש';

  @override
  String get goalsHorizonShortQuarter => 'רבעון';

  @override
  String get goalsHorizonShortYear => 'שנה';

  @override
  String get goalsStatusActive => 'פעיל';

  @override
  String get goalsStatusPaused => 'בהשהיה';

  @override
  String get goalsStatusDone => 'הושלם';

  @override
  String get goalsCloseToDone => 'כמעט שם';

  @override
  String get goalsCompleted => 'הושלם';

  @override
  String get goalsResting => 'במנוחה';

  @override
  String goalsOfTarget(int current, int target) {
    return '$current מתוך $target';
  }

  @override
  String goalsOfTargetUnit(int current, int target, String unit) {
    return '$current מתוך $target $unit';
  }

  @override
  String goalsProgressLine(String summary, int percent) {
    return '$summary · $percent%';
  }

  @override
  String get goalsNoMetric => 'מוסיפים ספירה כדי לראות התקדמות';

  @override
  String goalsByDate(String date) {
    return 'עד $date';
  }

  @override
  String goalsDate(String month, int day) {
    return '$day ב$month';
  }

  @override
  String get goalsDetailTitle => 'יעד';

  @override
  String get goalsNotFound => 'היעד הזה כבר לא כאן.';

  @override
  String get goalsBackToGoals => 'חזרה ליעדים';

  @override
  String get goalsAddOne => 'להוסיף אחד';

  @override
  String goalsAddOneTo(String unit) {
    return 'להוסיף אחד ל$unit';
  }

  @override
  String get goalsEditCount => 'עריכת הספירה';

  @override
  String get goalsCountLabel => 'ספירה עד עכשיו';

  @override
  String get goalsCountInvalid => 'מספר שלם מ-0 ומעלה מתאים.';

  @override
  String get goalsLinkedCountHint => 'עולה כשמסמנים משימה מקושרת.';

  @override
  String get goalsLinkedTasks => 'משימות מקושרות';

  @override
  String get goalsNoLinkedTasks =>
      'עדיין אין כאן משימות. מקשרים אחת והיא תיספר ליעד.';

  @override
  String get goalsLinkTask => 'לקשר משימה';

  @override
  String get goalsPickTask => 'איזו משימה מקדמת את היעד?';

  @override
  String get goalsNoTasksToLink => 'לכל משימה פתוחה כבר יש יעד.';

  @override
  String get goalsUnlink => 'לנתק';

  @override
  String get goalsTargetDateLabel => 'תאריך יעד';

  @override
  String get goalsNoTargetDate => 'מתי שמתאים';

  @override
  String get goalsImportanceLabel => 'חשיבות';

  @override
  String goalsImportanceValue(int n) {
    return '$n מתוך 5';
  }

  @override
  String get goalsDeleteTitle => 'למחוק את היעד?';

  @override
  String get goalsDeleteBody =>
      'המשימות שלו נשארות; הן רק לא יצביעו יותר על יעד.';

  @override
  String get goalsKeep => 'להשאיר';

  @override
  String get goalsDeleted => 'היעד נמחק';

  @override
  String get goalsMarkDone => 'לסמן כהושלם';

  @override
  String get goalsReopen => 'חזרה לפעיל';

  @override
  String get goalsTitleLabel => 'מה רוצים להשיג?';

  @override
  String get goalsTitleHint => 'לסיים את הקורס בניהול פרויקטים';

  @override
  String get goalsTitleRequired => 'נותנים שם קצר וזה מוכן.';

  @override
  String get goalsAreaLabel => 'תחום';

  @override
  String get goalsCustomArea => 'משלכם';

  @override
  String get goalsCustomAreaHint => 'נותנים שם לתחום';

  @override
  String get goalsHorizonLabel => 'טווח';

  @override
  String get goalsMetricLabel => 'למדוד (לא חובה)';

  @override
  String get goalsTargetLabel => 'יעד מספרי';

  @override
  String get goalsTargetInvalid => 'מספר שלם מעל 0 מתאים.';

  @override
  String get goalsUnitLabel => 'יחידה';

  @override
  String get goalsUnitHint => 'שיעורים';

  @override
  String get goalsDefaultUnit => 'צעדים';

  @override
  String get goalsLinkedUnit => 'משימות';

  @override
  String get goalsCountManual => 'אני סופר';

  @override
  String get goalsCountLinked => 'משימות מקושרות';

  @override
  String get goalsStatusLabel => 'סטטוס';

  @override
  String goalsMilestoneCloseToDone(String title) {
    return 'כמעט שם עם \"$title\". קצב נהדר.';
  }

  @override
  String goalsMilestoneCompleted(String title) {
    return 'עשיתם את זה: \"$title\" הושלם.';
  }

  @override
  String get goalsCounted => 'נספר. צעד יפה.';

  @override
  String get capacityTitle => 'השבוע';

  @override
  String get capacitySubtitle => 'האם זה ריאלי? פיפ הציץ.';

  @override
  String get capacityTabWeek => 'שבוע';

  @override
  String get capacityTabPriorities => 'סדרי עדיפויות';

  @override
  String get capacityBack => 'חזרה';

  @override
  String capacityHoursShort(String n) {
    return '$n ש׳';
  }

  @override
  String capacityMinutesShort(String n) {
    return '$n דק׳';
  }

  @override
  String capacityTotals(String free, String planned) {
    return '$free פנויות · $planned מתוכננות';
  }

  @override
  String get capacityVerdictFits => 'זה נכנס, ועוד נשאר מקום לנשום.';

  @override
  String get capacityVerdictTight =>
      'צפוף, אבל אפשרי. כדאי להסתכל מה יכול לחכות.';

  @override
  String capacityVerdictOver(String over) {
    return 'עודף של $over. נזיז כמה דברים, בלי לחץ.';
  }

  @override
  String get capacityStateFits => 'נכנס';

  @override
  String get capacityStateTight => 'צפוף';

  @override
  String get capacityStateOver => 'עמוס מדי';

  @override
  String get capacityDayPacked => 'עמוס';

  @override
  String capacityDaySemantics(String day, String free, String planned) {
    return '$day: $free פנויות, $planned מתוכננות';
  }

  @override
  String get capacityMoveTitle => 'מה אפשר להזיז';

  @override
  String get capacityMoveIntro =>
      'קודם מה שהכי זול להזיז. שום דבר כאן לא מגיע השבוע.';

  @override
  String get capacityMoveOne => 'להעביר לשבוע הבא';

  @override
  String get capacityMoveAll => 'להעביר את כל המוצעים';

  @override
  String get capacityMovedOne => 'הועבר לשבוע הבא. דבר אחד פחות.';

  @override
  String capacityMovedMany(int count) {
    return '$count הועברו לשבוע הבא. אפשר לנשום.';
  }

  @override
  String get capacityReasonNoDeadline => 'אין מועד, אז שבוע הבא מתאים.';

  @override
  String capacityReasonDue(String day) {
    return 'מועד היעד רק ב-$day.';
  }

  @override
  String capacitySlack(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ימים של מרווח',
      one: 'יום אחד של מרווח',
      zero: 'מגיע מיד אחרי השבוע',
    );
    return '$_temp0';
  }

  @override
  String get capacityNothingToMove => 'אין צורך להזיז כלום. יפה.';

  @override
  String get capacityPrioTitle => 'מה הכי חשוב';

  @override
  String get capacityPrioIntro =>
      'פיפ מדרג לפי מועד, מטרה ומאמץ. גוררים משימה למעלה, ופיפ זוכר.';

  @override
  String get capacityPrioEmpty => 'אין משימות פתוחות. תיהנו מהשקט.';

  @override
  String capacityRank(int rank) {
    return '#$rank';
  }

  @override
  String get capacityReasonPinnedTop => 'נעצתם אותה בראש';

  @override
  String get capacityReasonOverdue => 'עבר המועד, אז היא ראשונה';

  @override
  String get capacityReasonDueSoon => 'מגיעה בקרוב';

  @override
  String get capacityReasonMarkedHigh => 'סימנתם אותה כגבוהה';

  @override
  String get capacityReasonGoalMatters => 'חשובה למטרה שאכפת לכם ממנה';

  @override
  String get capacityReasonGoalStalled => 'המטרה שלה לא זזה זמן מה';

  @override
  String get capacityReasonGoalMoving => 'המטרה שלה בתנופה';

  @override
  String get capacityReasonQuickWin => 'ניצחון מהיר';

  @override
  String get capacityReasonSteady => 'יציבה, בלי לחץ';

  @override
  String get capacityPinTop => 'ראשונה';

  @override
  String get capacityPinHigh => 'גבוהה';

  @override
  String get capacityPinNormal => 'רגילה';

  @override
  String get capacityPinLow => 'נמוכה';

  @override
  String get capacityPinTitle => 'כמה זה חשוב?';

  @override
  String capacityPinLabel(String pin) {
    return 'עדיפות: $pin';
  }

  @override
  String get capacityDragHandle => 'גוררים כדי לשנות סדר';

  @override
  String get capacityRemembered => 'נרשם. פיפ יזכור.';

  @override
  String get capacityWeightsTitle => 'משקלים';

  @override
  String get capacityWeightsHint => 'מתקדם. כוונון הדירוג של פיפ בזמן הבטא.';

  @override
  String get capacityWeightUrgency => 'מועד יעד';

  @override
  String get capacityWeightImportance => 'חשיבות המטרה';

  @override
  String get capacityWeightPriority => 'העדיפות שלכם';

  @override
  String get capacityWeightQuickWin => 'ניצחונות מהירים';

  @override
  String get capacityWeightsReset => 'איפוס לברירת מחדל';

  @override
  String get goodAfternoon => 'צהריים טובים!';

  @override
  String get goodEvening => 'ערב טוב!';

  @override
  String todayMarkOpen(String title) {
    return 'סימון \"$title\" כפתוח';
  }

  @override
  String todayComplete(String title) {
    return 'השלמת \"$title\"';
  }

  @override
  String get planReplanTitle => 'הטיוטה של פיפ לשבוע';

  @override
  String get planReplanPlacedLabel => 'איפה כל דבר נוחת';

  @override
  String get planReplanUnplacedLabel => 'מה לא נכנס';

  @override
  String get planReplanNothing => 'אין מה להזיז. השבוע שלך כבר נראה מסודר.';

  @override
  String get planReplanPast =>
      'השבוע הזה כבר מאחורינו. אפשר לבחור את היום או יום מאוחר יותר.';

  @override
  String planReplanKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n דברים שהצבת בעצמך נשארים במקומם.',
      one: 'דבר אחד שהצבת בעצמך נשאר במקומו.',
    );
    return '$_temp0';
  }

  @override
  String get planApply => 'אישור';

  @override
  String get planNotNow => 'לא עכשיו';

  @override
  String planApplied(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'בוצע. ל-$n דברים יש מקום עכשיו.',
      one: 'בוצע. לדבר אחד יש מקום עכשיו.',
      zero: 'הכול מוכן, לא היה צורך להזיז כלום.',
    );
    return '$_temp0';
  }

  @override
  String planScheduledAt(String when, String reason) {
    return '$when · $reason';
  }

  @override
  String planNotScheduled(String reason) {
    return 'עוד אין מקום: $reason';
  }

  @override
  String get planNothingToSchedule => 'המשימה הזו כבר הושלמה';

  @override
  String get planNoRoomThisWeek => 'אין חלון פנוי עד סוף השבוע';

  @override
  String planHoursShort(String hours) {
    return '$hours ש׳';
  }

  @override
  String planCapacityFull(String amount) {
    return 'שבוע מלא: חריגה של $amount. פיפ יעזור לקצץ.';
  }

  @override
  String planCapacityNothing(String free) {
    return '$free פנויות · עוד לא תוכנן כלום';
  }

  @override
  String planCapacityLine(String free, String planned) {
    return '$free פנויות · $planned מתוכננות';
  }

  @override
  String planDurationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n שעות',
      two: 'שעתיים',
      one: 'שעה אחת',
    );
    return '$_temp0';
  }

  @override
  String planDurationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n דקות',
      one: 'דקה אחת',
    );
    return '$_temp0';
  }

  @override
  String planSummaryHead(String free, String demand) {
    return 'יש לך $free פנויות ו$demand של תוכניות.';
  }

  @override
  String planSummaryFits(String head) {
    return '$head הכול נכנס, ונשאר מקום לנשום.';
  }

  @override
  String planSummaryLighter(String head) {
    return '$head אולי שבוע קל יותר יעזור.';
  }

  @override
  String planSummaryDefer(String head, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n דברים יכולים',
      one: 'דבר אחד יכול',
    );
    return '$head $_temp0 לעבור לשבוע הבא.';
  }

  @override
  String get planWordToday => 'היום';

  @override
  String get planWordTomorrow => 'מחר';

  @override
  String get planDeadlineToday => 'מועד היעד של היום';

  @override
  String get planDeadlineTomorrow => 'מועד היעד של מחר';

  @override
  String planDeadlineOn(String day) {
    return 'מועד היעד של $day';
  }

  @override
  String get planReasonPlacedByYou => 'הצבת את זה כאן';

  @override
  String planReasonDue(String when) {
    return 'יעד: $when';
  }

  @override
  String planReasonPartOf(String title) {
    return 'חלק מ\"$title\"';
  }

  @override
  String get planReasonFocusWindow => 'חלון הפוקוס שלך';

  @override
  String planReasonChunkFirst(int minutes, int total) {
    return 'הראשון: $minutes מתוך $total דק׳';
  }

  @override
  String planReasonChunkNext(int minutes, int total) {
    return 'הבא: $minutes מתוך $total דק׳';
  }

  @override
  String planReasonChunkLast(int minutes, int total) {
    return 'האחרון: $minutes מתוך $total דק׳';
  }

  @override
  String planReasonEarliestGap(int minutes) {
    return 'החלון הפנוי הראשון של $minutes דקות';
  }

  @override
  String planReasonEarliestGapBefore(int minutes, String deadline) {
    return 'החלון הפנוי הראשון של $minutes דקות לפני $deadline';
  }

  @override
  String get planReasonDatePassed => 'תאריך היעד עבר, רוצה לבחור חדש?';

  @override
  String get planByThisWeek => 'השבוע';

  @override
  String planByBefore(String when) {
    return 'לפני $when';
  }

  @override
  String planReasonFocusFull(String by) {
    return 'בלוקי הפוקוס מלאים $by';
  }

  @override
  String planReasonOnlyFit(int fit, int need, String by) {
    return 'רק $fit מתוך $need דק׳ נכנסות $by';
  }

  @override
  String planReasonNoSlot(int minutes, String by) {
    return 'אין חלון פנוי של $minutes דקות $by';
  }

  @override
  String get planDiffReasonTimePassed => 'הזמן הזה כבר עבר';

  @override
  String planDiffReasonEventTook(String title) {
    return 'עכשיו $title בשעה הזאת';
  }

  @override
  String get planDiffReasonHoursChanged => 'שעות העבודה שלך השתנו';

  @override
  String planDiffReasonPinned(String title) {
    return 'שמת שם את $title';
  }

  @override
  String planDiffReasonMadeRoomFor(String title) {
    return 'פיניתי מקום ל$title';
  }

  @override
  String get planDiffReasonEarlierOpened => 'התפנה חלון מוקדם יותר';

  @override
  String get planDiffReasonReshuffled => 'סידרתי מחדש סביב השינויים של היום';

  @override
  String get planDiffRemovedNotOnList => 'כבר לא ברשימה שלך';

  @override
  String get planDiffRemovedDone => 'סיימת, יפה';

  @override
  String get planDiffRemovedSkipped => 'דילוג לעת עתה';

  @override
  String get planDiffRemovedNoLongerFits => 'לא נכנס השבוע';

  @override
  String planTriggerSkipped(String title) {
    return 'דילגת על $title';
  }

  @override
  String planTriggerOverrunMinutes(String title, int minutes) {
    return '$title חרגה ב-$minutes דק׳';
  }

  @override
  String planTriggerOverrunHours(String title, int hours) {
    return '$title חרגה ב-$hours שעות';
  }

  @override
  String planTriggerOverrunHoursMinutes(String title, int hours, int minutes) {
    return '$title חרגה ב-$hours שעות ו-$minutes דק׳';
  }

  @override
  String planTriggerEventLands(String title, String time) {
    return '$title נכנס ב-$time';
  }

  @override
  String planTriggerEventMovedTime(String title, String time) {
    return '$title זז ל-$time';
  }

  @override
  String planTriggerEventMovedDayTime(String title, String day, String time) {
    return '$title זז ל$day ב-$time';
  }

  @override
  String get goalsMetricKindLabel => 'איך זה נספר';

  @override
  String get goalsMetricNone => 'בלי ספירה';

  @override
  String get goalsMetricFinite => 'סך הכול';

  @override
  String get goalsMetricPerWeek => 'בשבוע';

  @override
  String get goalsMetricPerMonth => 'בחודש';

  @override
  String get goalsQuotaLabel => 'כמה';

  @override
  String get goalsRecurringHintWeek =>
      'מתחיל מחדש כל שבוע. גם +1 וגם משימות מקושרות נספרים.';

  @override
  String get goalsRecurringHintMonth =>
      'מתחיל מחדש כל חודש. גם +1 וגם משימות מקושרות נספרים.';

  @override
  String get goalsDefaultRecurringUnit => 'פעמים';

  @override
  String goalsThisWeek(int current, int target, String unit) {
    return '$current מתוך $target $unit השבוע';
  }

  @override
  String goalsThisMonth(int current, int target, String unit) {
    return '$current מתוך $target $unit החודש';
  }

  @override
  String get goalsQuotaHitWeek => 'סגור לשבוע הזה';

  @override
  String get goalsQuotaHitMonth => 'סגור לחודש הזה';

  @override
  String get goalsUndoTick => 'להוריד אחד';

  @override
  String get goalsTickUndone => 'ירד אחד.';

  @override
  String get goalsRecurringCountHint => 'גם משימות מקושרות שסומנו נספרות כאן.';

  @override
  String get goalsTrendWeeks => '8 השבועות האחרונים';

  @override
  String get goalsTrendMonths => '8 החודשים האחרונים';

  @override
  String goalsTrendSummary(int hit, int tracked) {
    return 'המכסה הושגה ב-$hit מתוך $tracked.';
  }

  @override
  String get goalsTrendQuietNote =>
      'תקופות שקטות הן רק מידע. שום דבר לא מתאפס.';

  @override
  String get goalsTrendBefore => 'לפני היעד';

  @override
  String goalsMilestoneMetricHit(String title) {
    return '\"$title\": המכסה הושגה. זה הקצב.';
  }

  @override
  String get highlightsTitle => 'הדגשים';

  @override
  String get highlightsSubtitle => 'כל היעדים במבט אחד.';

  @override
  String get highlightsGroupCompleted => 'הושלמו';

  @override
  String get highlightsGroupCloseToDone => 'כמעט שם';

  @override
  String get highlightsGroupOnTrack => 'בדרך';

  @override
  String get highlightsGroupStalled => 'מחכים לך';

  @override
  String highlightsStalledNote(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'שקט $days ימים',
      one: 'שקט יום אחד',
    );
    return '$_temp0. צעד קטן אחד יעיר אותו.';
  }

  @override
  String get highlightsEmptyTitle => 'עדיין אין מה להדגיש';

  @override
  String get highlightsEmptyBody => 'מוסיפים יעד ופיפ ישמור על לוח התוצאות.';

  @override
  String get recapTitleThisWeek => 'השבוע שלך עם פיפ';

  @override
  String get recapTitleLastWeek => 'השבוע שעבר עם פיפ';

  @override
  String recapRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String recapLeadGoalCompleted(String title) {
    return 'סיימת את \"$title\". זה גדול.';
  }

  @override
  String recapLeadMetricHit(String title, int count, int quota, String unit) {
    return '\"$title\": $count מתוך $quota $unit. בדיוק בקצב.';
  }

  @override
  String recapLeadWin(String win) {
    return 'הרגע הכי טוב: $win';
  }

  @override
  String recapLeadTasksDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count דברים הושלמו',
      one: 'דבר אחד הושלם',
    );
    return '$_temp0. זה מצטבר.';
  }

  @override
  String get recapLeadQuiet => 'שבוע שקט. גם מנוחה נחשבת.';

  @override
  String get recapStatDone => 'משימות הושלמו';

  @override
  String get recapStatMoved => 'יעדים שזזו';

  @override
  String get recapStatHit => 'מכסות שהושגו';

  @override
  String get recapStatRolled => 'עברו הלאה';

  @override
  String get recapWins => 'ניצחונות שרשמת';

  @override
  String recapRolledOverLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count משימות עברו ליום אחר. זה תכנון, וגם זה נחשב.',
      one: 'משימה אחת עברה ליום אחר. זה תכנון, וגם זה נחשב.',
      zero: 'הכול נשאר ביום שלו.',
    );
    return '$_temp0';
  }

  @override
  String get recapShare => 'לשתף';

  @override
  String recapShareHeader(String range) {
    return 'השבוע שלי עם פיפ ($range)';
  }

  @override
  String recapShareWins(String list) {
    return 'ניצחונות: $list';
  }

  @override
  String recapShareHits(String list) {
    return 'מכסות שהושגו: $list';
  }

  @override
  String recapShareMoved(String list) {
    return 'יעדים שזזו: $list';
  }

  @override
  String recapShareDone(int count) {
    return 'משימות שהושלמו: $count';
  }

  @override
  String get recapShareFooter => 'נשלח מ-Grind';

  @override
  String get settingsSyncing => 'מסנכרן...';

  @override
  String get settingsSyncIdle => 'מעודכן';

  @override
  String get settingsSyncError => 'פיפ לא הצליח להגיע ליומן כרגע.';

  @override
  String settingsLastSynced(String time) {
    return 'סונכרן לאחרונה ב-$time';
  }

  @override
  String get settingsTimeZone => 'אזור זמן';

  @override
  String get settingsTimeZoneSearch => 'חיפוש, למשל לונדון';

  @override
  String get settingsTimeZoneNoMatch => 'אין אזור בשם הזה. אפשר לנסות עיר.';

  @override
  String settingsUseDeviceZone(String zone) {
    return 'להשתמש בזמן המכשיר: $zone';
  }

  @override
  String get settingsExportHint =>
      'כולל אירועי יומן שפיפ שיקף, כמו שמות של פגישות.';

  @override
  String get settingsPrivacyBody =>
      'התוכניות שלך נשארות במכשיר הזה. בלי חשבון, בלי ניתוחי שימוש. אם מחברים יומן, פיפ קורא את האירועים כדי לתכנן סביבם, וכותב בחזרה רק את המשימות שקבעת. אפשר לנתק בכל עת.';

  @override
  String get calendarSyncGenericError =>
      'פיפ לא הצליח להגיע ליומן כרגע. ניסיון נוסף בדרך.';

  @override
  String get calendarSyncReconnect =>
      'פיפ מחכה לשלום חדש מהיומן. אפשר לחבר אותו מחדש בהגדרות.';

  @override
  String get calendarUntitledEvent => '(ללא כותרת)';

  @override
  String get calendarWrittenByGrind => 'תוכנן עם Grind.';

  @override
  String get analyticsTitle => 'המספרים שלך';

  @override
  String get analyticsSubtitle => 'רק מה שקרה. בלי ציונים.';

  @override
  String get analyticsEmptyTitle => 'עוד אין מה להציג';

  @override
  String get analyticsEmptyBody =>
      'אחרי משימה או סשן פוקוס, המספרים שלך יופיעו כאן.';

  @override
  String get analyticsFocusTitle => 'דקות פוקוס';

  @override
  String get analyticsFocusSub => '14 הימים האחרונים';

  @override
  String get analyticsRestLegend =>
      'עמודות חיוורות הן ימי מנוחה. גם מנוחה נחשבת.';

  @override
  String get analyticsFocusTotalNone => 'תקופה שקטה. פיפ סבלן.';

  @override
  String analyticsFocusTotalMinutes(int minutes) {
    return '$minutes דק׳ של פוקוס בשבועיים';
  }

  @override
  String analyticsFocusTotalHours(int hours) {
    return '$hours שע׳ של פוקוס בשבועיים';
  }

  @override
  String analyticsFocusTotalHoursMinutes(int hours, int minutes) {
    return '$hours שע׳ ו-$minutes דק׳ של פוקוס בשבועיים';
  }

  @override
  String get analyticsCompletionTitle => 'אחוז השלמה';

  @override
  String get analyticsCompletionSub => '8 השבועות האחרונים';

  @override
  String get analyticsCompletionNote =>
      'החלק מהמשימות של כל שבוע שסיימת. מקף אומר שלא תוכננו משימות.';

  @override
  String get analyticsAccuracyTitle => 'דיוק ההערכות';

  @override
  String get analyticsAccuracySub => 'זמן מתוכנן מול זמן בפועל';

  @override
  String get analyticsAccuracyWaiting => 'עוד כמה משימות ופיפ יידע.';

  @override
  String get analyticsAccuracyHow =>
      'פיפ משתמש בזה כדי לתכנן עם קצת יותר מרווח במקומות שזה עוזר.';

  @override
  String analyticsAccuracyLonger(String category, String ratio) {
    return 'משימות $category לרוב נמשכות פי $ratio יותר';
  }

  @override
  String analyticsAccuracyShorter(String category, String ratio) {
    return 'משימות $category לרוב לוקחות פי $ratio מהזמן';
  }

  @override
  String analyticsAccuracyOnTarget(String category) {
    return 'משימות $category לרוב מסתיימות בדיוק לפי ההערכה';
  }

  @override
  String analyticsSamples(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n משימות',
      one: 'משימה אחת',
    );
    return '$_temp0';
  }

  @override
  String analyticsSemanticsFocus(int minutes, int restDays) {
    return 'דקות פוקוס, 14 הימים האחרונים: $minutes בסך הכול, $restDays ימי מנוחה';
  }

  @override
  String analyticsSemanticsCompletion(int done, int planned) {
    return 'אחוז השלמה, 8 השבועות האחרונים: $done מתוך $planned משימות הושלמו';
  }

  @override
  String get tasksGoalLabel => 'מטרה';

  @override
  String get tasksNoGoal => 'בלי מטרה';

  @override
  String get tasksRepeatsLabel => 'חוזרת';

  @override
  String get tasksScheduledLabel => 'בתוכנית';

  @override
  String get tasksNotScheduled => 'עוד לא שובצה';

  @override
  String get tasksNextOneSet => 'כל הכבוד. הבאה כבר מחכה.';

  @override
  String get planScheduleForMe => 'לשבץ בשבילי';

  @override
  String get planDetails => 'פרטים';

  @override
  String get planOpenInCalendarApple =>
      'אפשר לפתוח את אפליקציית היומן כדי לראות את זה. קישור ישיר בדרך.';

  @override
  String get planOpenInCalendarLocal => 'זה חי רק בתוך Grind.';

  @override
  String get planOpenInCalendarFailed =>
      'היומן לא נפתח כרגע. אפשר לנסות עוד רגע.';

  @override
  String get promptMorningTitle => 'בוקר טוב';

  @override
  String get promptMorningBody => 'מתאים לתכנן את היום ביחד?';

  @override
  String promptMorningBodyFirst(String task) {
    return 'מתאים לתכנן את היום ביחד? ראשון בתור: $task';
  }

  @override
  String get promptEveningTitle => 'ערב טוב';

  @override
  String get promptEveningBody => 'דקה אחת להציץ אחורה על היום?';

  @override
  String promptEveningBodyWin(String win) {
    return 'הרגע הטוב של היום: $win. דקה להציץ אחורה?';
  }

  @override
  String promptEveningBodyDone(String task) {
    return 'היום סיימת את \"$task\". דקה להציץ אחורה?';
  }

  @override
  String promptEveningBodyDoneMany(int count, String task) {
    return '$count דברים הושלמו היום, ביניהם \"$task\". דקה להציץ אחורה?';
  }

  @override
  String get recapNotificationTitle => 'השבוע שלך עם פיפ';

  @override
  String get goalsMilestones => 'אבני דרך';

  @override
  String goalsMilestonesProgress(int done, int total) {
    return '$done מתוך $total הושגו';
  }

  @override
  String get goalsMilestonesEmpty =>
      'אפשר לפרק יעד ארוך לכמה צעדים. לכל צעד יש משימות שבועיות משלו.';

  @override
  String get goalsMilestoneAdd => 'הוספת אבן דרך';

  @override
  String get goalsMilestoneNew => 'אבן דרך חדשה';

  @override
  String get goalsMilestoneEdit => 'עריכת אבן דרך';

  @override
  String get goalsMilestoneTitleLabel => 'אבן דרך';

  @override
  String get goalsMilestoneTitleHint => 'לסיים את מודול 3';

  @override
  String get goalsMilestoneTitleRequired => 'כדאי לתת לה שם קצר';

  @override
  String get goalsMilestoneDateLabel => 'תאריך';

  @override
  String get goalsMilestoneNoDate => 'בלי תאריך';

  @override
  String goalsMilestoneNextLine(String title, String date) {
    return 'הבא: $title, $date';
  }

  @override
  String goalsMilestoneNextNoDate(String title) {
    return 'הבא: $title';
  }

  @override
  String get goalsMilestoneMoved => 'הוזז';

  @override
  String goalsMilestoneMovedBody(String date) {
    return 'התאריך עבר. מה דעתך על $date?';
  }

  @override
  String goalsMilestoneMoveAccept(String date) {
    return 'להעביר ל-$date';
  }

  @override
  String goalsMilestoneMovedToast(String date) {
    return 'הועבר ל-$date. יש מספיק זמן.';
  }

  @override
  String goalsMilestoneReachedToast(String title) {
    return 'הגעת לאבן דרך: $title';
  }

  @override
  String get goalsMilestoneMoveUp => 'להזיז למעלה';

  @override
  String get goalsMilestoneMoveDown => 'להזיז למטה';

  @override
  String get goalsMilestoneDeleteTitle => 'למחוק את אבן הדרך?';

  @override
  String get goalsMilestoneDeleteBody => 'המשימות שלה נשארות עם היעד.';

  @override
  String get goalsMilestoneDeleted => 'אבן הדרך נמחקה';

  @override
  String get goalsMilestoneAddTask => 'הוספת משימה';

  @override
  String goalsMilestoneTaskSheetTitle(String title) {
    return 'משימה בשביל $title';
  }

  @override
  String get goalsMilestoneTaskHint => 'לצפות בשיעור 7';

  @override
  String get goalsMilestoneWeekLabel => 'באיזה שבוע';

  @override
  String get goalsMilestoneThisWeek => 'השבוע';

  @override
  String get goalsMilestoneNextWeek => 'בשבוע הבא';

  @override
  String get goalsMilestoneEstimateLabel => 'בערך כמה זמן';

  @override
  String get goalsMilestoneTaskAdded => 'המשימה נוספה. התוכנית תמצא לה מקום.';

  @override
  String goalsMilestoneTasksCount(int done, int total) {
    return '$done מתוך $total משימות הושלמו';
  }

  @override
  String get goalsNextTask => 'המשימה המתוכננת הבאה';

  @override
  String get goalsNextTaskNone => 'עדיין אין כלום ביומן. מתי שנוח לך.';

  @override
  String goalsNextTaskWhen(String date, String time) {
    return '$date, $time';
  }

  @override
  String get goalsMilestoneOptions => 'אפשרויות לאבן הדרך';

  @override
  String planReasonFillsGap(int minutes) {
    return 'ממלא חלון של $minutes דקות';
  }

  @override
  String get planReasonFocusClear => 'שומר את חלון הפוקוס פנוי';

  @override
  String get planReasonYourOrder => 'לפי הסדר שבחרת';

  @override
  String get planByToday => 'היום';

  @override
  String get todayPlanDayTitle => 'לתכנן את היום עם פיפ';

  @override
  String get todayPlanDayBody =>
      'פיפ יכול לשרטט את היום סביב היומן. מתי שנוח לך.';

  @override
  String get todayPlanDayAction => 'טיוטה ליום שלי';

  @override
  String get todayPlanDayHide => 'להסתיר להיום';

  @override
  String get draftTitle => 'היום שלך, בטיוטה';

  @override
  String draftSummary(String free, String planned) {
    return 'זמן פנוי היום: $free. בטיוטה: $planned.';
  }

  @override
  String get draftNothing => 'אין מה לשבץ כרגע. היום שלך.';

  @override
  String get draftNoTime => 'לא נשאר זמן פנוי היום. מחר דף חדש.';

  @override
  String get draftOrderLabel => 'היום, לפי הסדר';

  @override
  String draftLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n דברים נוספים יכולים לחכות ליום אחר.',
      one: 'דבר אחד נוסף יכול לחכות ליום אחר.',
    );
    return '$_temp0';
  }

  @override
  String get draftAcceptAll => 'לאשר הכול';

  @override
  String draftRemove(String title) {
    return 'להסיר את $title מהטיוטה';
  }

  @override
  String draftMoveEarlier(String title) {
    return 'להקדים את $title';
  }

  @override
  String draftMoveLater(String title) {
    return 'לדחות את $title';
  }

  @override
  String get draftNoRoom => 'זה לא נכנס שם';

  @override
  String get planExplainHeader => 'הנה היום שלך.';

  @override
  String planExplainBlocks(int n, String first, String last, String planned) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n בלוקים בין $first ל-$last, $planned סך הכול.',
      one: 'בלוק אחד בין $first ל-$last, $planned סך הכול.',
    );
    return '$_temp0';
  }

  @override
  String get planExplainFocus => 'עבודה עמוקה נוחתת בחלון הפוקוס שלך.';

  @override
  String get planExplainNothing => 'אין מה לשבץ כרגע. היום שלך.';

  @override
  String get planExplainNoTime => 'לא נשאר זמן פנוי היום. מחר דף חדש.';

  @override
  String planExplainUnplacedOnly(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'אין מקום ביומן היום; $n משימות יחכו ליום אחר.',
      one: 'אין מקום ביומן היום; משימה אחת תחכה ליום אחר.',
    );
    return '$_temp0';
  }

  @override
  String planExplainUnplacedExtra(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n משימות לא נכנסות היום.',
      one: 'משימה אחת לא נכנסת היום.',
    );
    return '$_temp0';
  }

  @override
  String followupHereAt(String start, String reasons) {
    return 'זה ב-$start, כי $reasons.';
  }

  @override
  String followupHereNoReason(String start) {
    return 'זה ב-$start.';
  }

  @override
  String followupNotFit(String reason) {
    return 'זה לא נכנס היום — $reason.';
  }

  @override
  String get followupNotFitBare => 'זה לא נכנס היום.';

  @override
  String followupWhen(String start, String end) {
    return 'זה מתחיל ב-$start ורץ עד $end.';
  }

  @override
  String followupAlreadyPlaced(String start) {
    return 'זה בתוכנית של היום, ב-$start.';
  }

  @override
  String get followupUnknown => 'זה לא על התוכנית של היום.';

  @override
  String get voicePermissionTitle => 'הכתבת משימה';

  @override
  String get voicePermissionRationale =>
      'Grind מקשיב רק בזמן שהכפתור לחוץ. מה שאתם אומרים הופך לטקסט בתיבה, ואתם רואים אותו לפני שנשלח משהו.';

  @override
  String get voicePermissionAllow => 'אישור מיקרופון';

  @override
  String get voicePermissionNotNow => 'לא עכשיו';

  @override
  String get voicePermissionGranted =>
      'המיקרופון פעיל. החזיקו את הכפתור כדי להכתיב.';

  @override
  String get voicePermissionDenied =>
      'בלי בעיה. אפשר להמשיך להקליד. את גישת המיקרופון אפשר להפעיל בהגדרות מתי שרוצים.';

  @override
  String get voicePermissionBlocked =>
      'גישת המיקרופון ל-Grind כבויה. פתחו את ההגדרות כדי להפעיל.';

  @override
  String get voicePermissionOpenSettings => 'פתיחת ההגדרות';

  @override
  String get voicePrivacyNote =>
      'באייפון הזיהוי מתבצע על המכשיר הזה. באינטרנט הדפדפן אחראי לכך — בחלק מהדפדפנים האודיו נשלח לשירות שלהם.';

  @override
  String get voiceUnavailable =>
      'הכתבה קולית אינה זמינה בדפדפן הזה. תמיד אפשר להקליד.';

  @override
  String get voiceListening => 'מקשיב…';

  @override
  String get voiceStopListening => 'עצירת ההקלטה';

  @override
  String get voiceLocaleLabel => 'שפת ההכתבה';

  @override
  String get voiceLocaleHebrew => 'עברית';

  @override
  String get voiceLocaleEnglish => 'אנגלית';

  @override
  String toolConfirmationDone(String ranges) {
    return 'בוצע: $ranges';
  }

  @override
  String get toolConfirmationEmpty => 'בוצע.';

  @override
  String commonJoinAnd(String head, String tail) {
    return '$head ו-$tail';
  }

  @override
  String get commonListSeparator => ', ';
}
