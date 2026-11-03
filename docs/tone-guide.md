# Pip's tone guide

Pip is a cheering squad of one. Pip celebrates what happened and never
measures what did not. Research basis: `docs/handoff/RESEARCH.md` Part 1C
(streaks and shame backfire for people with ADHD) and Part 2B (the cheering
layer asks for nothing).

## Voice rules

1. **Celebrate, never grade.** Name what happened. Do not compare with a goal,
   a day, or another person.
2. **No guilt, no debt.** Nothing is overdue, missed, or owed. A quiet day is
   rest, and rest is part of the rhythm.
3. **Never ask for anything.** Pip does not request a task, a streak, a
   rating, or a return visit. Praise lines are statements, not questions or
   calls to action.
4. **Short and warm.** Under 60 characters, one idea, plain words. At most one
   exclamation mark, and only for big wins.
5. **No streak language.** Count days shown up ("5 of the last 7"), never
   "days in a row". Nothing resets to zero.
6. **Zero is not shown as zero.** Empty days say "rest day". An empty meter is
   an empty track, never red.
7. **Autonomy.** Invite ("Ready when you are"), never command.
8. **No emoji.** Stroke icons only.

## Good and bad

| Bad | Good |
| --- | --- |
| You missed yesterday. | Pip is here whenever you are. |
| You should do more this week. | The week is shaping up nicely. |
| Streak lost! Start again. | You showed up 4 of the last 7 days. |
| 0 tasks done. | Rest day. |
| You failed to finish. | Every bit counts. |
| Don't break the chain! | Day after day, you keep coming back. |
| Come back tomorrow! | Good to see you. |

## Banned words

English (whole words): should, failed, fail, missed, miss, again, you broke,
behind, overdue, lazy, late, must, forgot.

Hebrew (substrings): נכשלת, פספסת, שוב, נכשל, פספס, כישלון, צריך, חייב, איחור.

Enforced by `test/features/companion/praise_test.dart` over the whole pool.
`reminder_copy.dart` keeps its own list; the two lists overlap by design.

## Hebrew notes

- Write gender-neutral: past-tense second person is spelled the same for all
  genders (הגעת, עשית, סיימת); plural or impersonal forms elsewhere (תראו,
  מתקדמים).
- Avoid `שוב` also inside other words (for example `חשוב`): the check is a
  substring match, so rephrase.
- Keep punctuation simple; the app mirrors for RTL, do not add arrows.
- Translate the feeling, not the words. Same index in the EN and HE pools.

## Using the pool

`praiseFor(PraiseEvent.taskDone, locale: locale)` from
`lib/features/companion/praise.dart`. It rotates deterministically and never
repeats one of the last 10 lines of an event.

## PR checklist line

- [ ] New Pip/praise/reminder copy follows `docs/tone-guide.md`: no banned
      words, no guilt, no asks, no streak language, EN and HE both added.
