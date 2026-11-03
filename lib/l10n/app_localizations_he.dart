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
      'דחייה נוספת? פיפ יציע להזיז את זה למקום נוח יותר.';

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
}
