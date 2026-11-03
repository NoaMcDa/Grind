import 'dart:ui' show Locale;

/// What just happened.
enum PraiseEvent { taskDone, sessionDone, weeklyGoal, showedUp }

/// light = a quiet nod, big = a proper cheer.
enum PraiseIntensity { light, big }

class PraiseLine {
  const PraiseLine(this.en, this.he, this.intensity);
  final String en, he;
  final PraiseIntensity intensity;
  String text(String lang) => lang == 'he' ? he : en;
}

const _l = PraiseIntensity.light;
const _b = PraiseIntensity.big;

/// 50 lines, each with an English and a Hebrew version at the same index.
/// Hebrew uses forms that are spelled the same for any gender.
/// Rules: docs/tone-guide.md. Never ask for anything, never guilt.
abstract final class PraisePool {
  static const lines = <PraiseEvent, List<PraiseLine>>{
    PraiseEvent.taskDone: [
      PraiseLine('Done. Nice one.', 'בוצע. יפה מאוד.', _l),
      PraiseLine('One thing off the list.', 'עוד דבר אחד סומן.', _l),
      PraiseLine('That counts.', 'וזה נחשב.', _l),
      PraiseLine('Pip noticed. Well done.', 'פיפ שם לב. כל הכבוד.', _l),
      PraiseLine('Quietly getting things done.', 'מתקדמים בשקט.', _l),
      PraiseLine('A small win, and it is yours.', 'ניצחון קטן, והוא שלך.', _l),
      PraiseLine('Look at you, moving.', 'תראו אותך, בתנועה.', _l),
      PraiseLine(
        'That was a real one. Big win!',
        'זה היה משהו אמיתי. ניצחון גדול!',
        _b,
      ),
      PraiseLine('Pip is doing a little dance.', 'פיפ רוקד ריקוד קטן.', _b),
      PraiseLine('You made that happen.', 'זה קרה בזכותך.', _b),
      PraiseLine('Wow. Pip is so proud.', 'וואו. פיפ ממש גאה.', _b),
      PraiseLine(
        'That took effort, and you did it.',
        'זה לא היה קל, ועשית את זה.',
        _b,
      ),
      PraiseLine('Another step, more momentum.', 'עוד צעד, עוד קצת תנופה.', _l),
      PraiseLine(
        'Finished. Take a breath, you earned it.',
        'סיימת. נשימה עמוקה, מגיע לך.',
        _b,
      ),
    ],
    PraiseEvent.sessionDone: [
      PraiseLine(
        'Focus session done. Nice rhythm.',
        'סבב מיקוד הסתיים. קצב יפה.',
        _l,
      ),
      PraiseLine('Time well spent.', 'זמן שהושקע יפה.', _l),
      PraiseLine('You stayed with it.', 'נשארת עם זה.', _l),
      PraiseLine(
        'That was a block of real focus.',
        'זה היה בלוק של מיקוד אמיתי.',
        _l,
      ),
      PraiseLine(
        'Pip enjoyed the quiet company.',
        'פיפ נהנה מהחברה השקטה.',
        _l,
      ),
      PraiseLine('Steady and calm. Lovely.', 'יציב ורגוע. מקסים.', _l),
      PraiseLine('Every minute counted.', 'כל דקה נחשבה.', _l),
      PraiseLine(
        'A whole session! Pip is cheering.',
        'סבב שלם! פיפ מעודד בקול.',
        _b,
      ),
      PraiseLine(
        'That was deep focus. Impressive.',
        'זה היה מיקוד עמוק. מרשים.',
        _b,
      ),
      PraiseLine(
        'You protected your time and it shows.',
        'שמרת על הזמן שלך וזה ניכר.',
        _b,
      ),
      PraiseLine('Big effort. Big glow.', 'מאמץ גדול. זוהר גדול.', _b),
      PraiseLine(
        'Pip felt that focus from here.',
        'פיפ הרגיש את המיקוד מכאן.',
        _b,
      ),
      PraiseLine(
        'Time for a stretch and some water.',
        'זמן למתיחה ולכוס מים.',
        _l,
      ),
      PraiseLine(
        'Look at that, a full block done.',
        'תראו, בלוק שלם הושלם.',
        _b,
      ),
    ],
    PraiseEvent.weeklyGoal: [
      PraiseLine(
        'Weekly goal reached. Pip is glowing!',
        'יעד השבוע הושג. פיפ זוהר!',
        _b,
      ),
      PraiseLine(
        'You did what you set out to do this week.',
        'עשית השבוע את מה שהתכוונת.',
        _b,
      ),
      PraiseLine('A full week of showing up.', 'שבוע שלם של הגעה.', _b),
      PraiseLine(
        'Getting close to the weekly goal.',
        'מתקרבים ליעד השבועי.',
        _l,
      ),
      PraiseLine('The week is shaping up nicely.', 'השבוע מתעצב יפה.', _l),
      PraiseLine(
        'Goal done. Celebrate a little.',
        'היעד הושג. אפשר לחגוג קצת.',
        _b,
      ),
      PraiseLine('Halfway there and moving well.', 'באמצע הדרך ובקצב טוב.', _l),
      PraiseLine('This week was yours.', 'השבוע הזה היה שלך.', _b),
      PraiseLine('Steady progress adds up.', 'התקדמות יציבה מצטברת.', _l),
      PraiseLine(
        'Pip has a new sparkle thanks to you.',
        'לפיפ יש נצנוץ חדש בזכותך.',
        _b,
      ),
      PraiseLine(
        'That is a week to be proud of.',
        'זה שבוע שאפשר להתגאות בו.',
        _b,
      ),
    ],
    PraiseEvent.showedUp: [
      PraiseLine('You are here. That is the start.', 'הגעת. זו ההתחלה.', _l),
      PraiseLine('Showing up counts.', 'להגיע זה כבר נחשב.', _l),
      PraiseLine('Pip is glad you stopped by.', 'פיפ שמח שקפצת לבקר.', _l),
      PraiseLine('Good to see you.', 'טוב לראות אותך.', _l),
      PraiseLine('A quiet day still counts.', 'גם יום שקט נחשב.', _l),
      PraiseLine('Rest is part of the rhythm.', 'מנוחה היא חלק מהקצב.', _l),
      PraiseLine(
        'Day after day, you keep coming back.',
        'יום אחרי יום, ממשיכים לחזור.',
        _b,
      ),
      PraiseLine('That is real consistency.', 'זו עקביות אמיתית.', _b),
      PraiseLine(
        'So many days this week. Pip is beaming.',
        'כל כך הרבה ימים השבוע. פיפ קורן.',
        _b,
      ),
      PraiseLine(
        'Whenever it suits you, Pip is here.',
        'כשנוח לך, פיפ כאן.',
        _l,
      ),
      PraiseLine(
        'Look at this rhythm you are building.',
        'תראו איזה קצב אתם בונים.',
        _b,
      ),
    ],
  };

  static int get total => lines.values.fold(0, (a, l) => a + l.length);

  /// Words no praise line may contain (docs/tone-guide.md). English is
  /// matched as whole words, Hebrew as substrings.
  static const bannedEn = [
    'should',
    'failed',
    'fail',
    'missed',
    'miss',
    'again',
    'you broke',
    'behind',
    'overdue',
    'lazy',
    'late',
    'must',
    'forgot',
  ];
  static const bannedHe = [
    'נכשלת',
    'פספסת',
    'שוב',
    'נכשל',
    'פספס',
    'כישלון',
    'צריך',
    'חייב',
    'איחור',
  ];
}

/// Deterministic rotation: seeded by date and a counter, and never repeats
/// one of the last [memory] lines of the same event.
class PraiseRotation {
  PraiseRotation({this.memory = 10});

  final int memory;
  final _history = <PraiseEvent, List<int>>{};
  int _counter = 0;

  PraiseLine pick(
    PraiseEvent event, {
    PraiseIntensity? intensity,
    required DateTime now,
  }) {
    final pool = PraisePool.lines[event]!;
    final recent = _history.putIfAbsent(event, () => []);
    final keep = memory < pool.length ? memory : pool.length - 1;
    var candidates = [
      for (var i = 0; i < pool.length; i++)
        if (!recent.contains(i)) i,
    ];
    final matching = intensity == null
        ? candidates
        : candidates.where((i) => pool[i].intensity == intensity).toList();
    if (matching.isNotEmpty) candidates = matching;
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final idx =
        candidates[(seed * 31 + _counter * 17 + event.index * 7) %
            candidates.length];
    _counter++;
    recent.add(idx);
    while (recent.length > keep) {
      recent.removeAt(0);
    }
    return pool[idx];
  }
}

final _shared = PraiseRotation();

/// A praise line for [event] in [locale] ('he' gives Hebrew, anything else
/// English). Callers: Today on task complete, Focus on session end.
String praiseFor(
  PraiseEvent event, {
  Locale locale = const Locale('en'),
  PraiseIntensity? intensity,
  DateTime? now,
  PraiseRotation? rotation,
}) => (rotation ?? _shared)
    .pick(event, intensity: intensity, now: now ?? DateTime.now())
    .text(locale.languageCode);
