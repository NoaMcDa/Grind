# Re-planning architecture: model, algorithm, or hybrid?

Date: 2 Nov 2026 · For: Noa (Grind / Pip) · Scope: "draft my day", "re-plan when things change", "is this week realistic?", "what to defer"

## Executive summary

1. **Direct answer: no trained model. Ship a deterministic scheduler with an explicit scoring function, and use Claude only at the edges (parsing language, explaining, negotiating).**
2. Every public description of Motion, Reclaim, Sunsama and Viva Insights reads as rule- and priority-based placement into free calendar gaps; none documents a learned scheduler, and the one product that did (Timeful → Google Calendar Goals) was shut down in Nov 2022.
3. A greedy "score, sort, fill gaps" pass over one week of tasks runs in microseconds in Dart, works offline, gives the same answer on iOS and web, and can print a one-line reason per placement, which the encouraging Pip tone needs.
4. The LLM must not pick times: research on LLM scheduling shows constraint mistranslation and infeasible outputs even from strong models; Claude's job is natural language → structured constraints, and plan → friendly explanation.
5. Learning enters later as per-user statistics (median actual-vs-estimated ratio per task type, completion rate by hour band), not a training pipeline; with a sane default they need roughly 5–10 completed tasks per category before they beat the default.
6. Weekly capacity is arithmetic: free calendar minutes inside working hours, minus buffers, versus the sum of adjusted estimates; overbooking triggers deferral suggestions ranked by deadline slack and goal importance.

## 1. How existing products do it

What is public is thin; vendors say "AI" and describe rules. Direct fetches of help.reclaim.ai and usemotion.com were blocked in this session, so the summaries below come from search excerpts of those pages and from reviews.

| Product | What the public docs say | ML confirmed? |
| --- | --- | --- |
| **Motion** | Auto-scheduler weighs priority, due date, duration, chunking, work schedules and existing events; shorter tasks can slot ahead of longer ones with slightly earlier deadlines; reruns on every change; flags tasks that cannot fit ([help center](https://help.usemotion.com/motion-overview/whats-motion/ai-auto-scheduling-explained-harness-the-power-of-intelligent-task-management), [reference](https://www.usemotion.com/help/time-management/auto-scheduling/reference-auto-scheduling)). | No. Called "AI" and "an algorithm"; no model type, training or learning from user data disclosed. |
| **Reclaim.ai** | P1–P4 priorities; critical meetings and habits first, then tasks by priority and then due date; ties broken by type (meetings > habits > tasks) and "time defense"; non-Reclaim events are never overbooked ([how Reclaim manages your schedule](https://help.reclaim.ai/en/articles/6207587-how-reclaim-manages-your-schedule-automatically), [scheduling settings](https://help.reclaim.ai/en/articles/10491907-customize-your-scheduling-settings-for-reclaim-events)). | No. A documented priority hierarchy; no learning described. |
| **Sunsama** | Per-task auto-placement into a free gap inside working hours, never overlapping events; otherwise manual ritual planning ([timeboxing docs](https://help.sunsama.com/docs/usage-guides/timeboxing/timeboxing-auto-scheduling)). Planned-vs-actual blocks on the calendar are a roadmap item ([roadmap](https://roadmap.sunsama.com/improvements/p/compare-actual-time-vs-planned-time)). | No. Rule-based gap fill. |
| **Akiflow** | Mostly manual time blocking with "slots"; reviews disagree on how much the Aki assistant schedules ([comparison](https://efficient.app/compare/sunsama-vs-akiflow), [Morgen](https://www.morgen.so/blog-posts/sunsama-vs-akiflow)). | Not public. |
| **Lifestack** | Energy score from sleep-based circadian rhythm and wearable heart-rate data; scheduler takes preferred start time and desired deep-work amount; users correct energy estimates by hand ([How Lifestack works](https://demind-inc.notion.site/How-Lifestack-Works-7fd29b5e0bc649cc859a51487ea38805), [blog](https://lifestack.ai/blog/introducing-lifestack)). | Partly: a physiological model, not a learned scheduler. Internals not public. |
| **Google Calendar Focus time** | A manually created event type that declines conflicting invites; Time Insights suggests days, it does not place blocks ([Workspace update](https://workspaceupdates.googleblog.com/2021/10/set-aside-time-for-focus-in-google.html), [9to5Google](https://9to5google.com/2021/10/20/google-calendar-focus-time/)). | No. |
| **Google Calendar Goals (Timeful)** | Timeful was a machine-learning scheduler acquired in 2015 ([TechCrunch](https://techcrunch.com/2015/05/04/google-acquires-timeful-to-bring-smart-scheduling-to-google-apps/amp/)); became Calendar "Goals" in 2016, which found free time for recurring goals; removed November 2022 ([Android Police](https://www.androidpolice.com/goals-leaving-google-calendar/)). | Yes, historically. It is the one learned scheduler on this list, and it was discontinued. |
| **Microsoft Viva Insights focus plan** | Books up to four hours a day of focus blocks starting from the start of the workday, skipping 12–13:00, honouring a morning/afternoon preference, never over existing events ([focus plan docs](https://support.microsoft.com/en-us/viva/insights/focus-plan-for-viva-insights)). | No. Plainly rule-based. |

Takeaway: the products Noa is benchmarked against place tasks with explicit priority rules into free gaps. The marketing word "AI" does not change that. There is no public evidence that a learned scheduler produces better plans for a single user than a well-tuned rule set, and the clearest learned attempt (Goals) did not survive.

## 2. Algorithmic options

| Approach | What it is | Explainability | Speed on phone/web | Testability | Fit for Grind |
| --- | --- | --- | --- | --- | --- |
| **Greedy priority heuristics** (EDD/EDF, WSPT) | Sort by one rule, then place. EDD is provably optimal for maximum lateness on one machine; WSPT (weight ÷ duration) is optimal for total weighted completion time ([Bonn lecture notes](https://www.or.uni-bonn.de/lectures/ss10/scheduling_data/sched10_2.pdf), [MetricGate](https://metricgate.com/docs/job-scheduling/)). | Excellent: "earlier deadline", "big win per minute". | Microseconds for < 200 tasks. | Trivial: pure functions. | **Core of v1**, combined into one weighted score. |
| **Interval scheduling into gaps** | Compute free intervals = working hours minus events; fill them earliest-first. Unweighted earliest-finish greedy is optimal; the weighted version needs DP in O(n log n) ([MIT 6.046](https://ocw.mit.edu/courses/6-046j-design-and-analysis-of-algorithms-spring-2015/ff2a7015ff913fc01f0381d8f5126a9a_MIT6_046JS15_lec01.pdf), [UW CSE 312](https://courses.cs.washington.edu/courses/cse312/12sp/slides/algorithms.pdf)). | Good: "this was the first gap long enough". | Microseconds. | Easy with fixture calendars. | **Core of v1** (the placement half). |
| **Constraint programming (OR-Tools CP-SAT)** | Declare interval variables, no-overlap, deadlines, max deep blocks; solver optimises ([CP-SAT primer](https://backiee.wasmer.app/http_www_github_com/topics/cp-sat)). | Weak: the optimum has no local reason; you can only say "this minimised the objective". | No Dart port exists; would run on the backend in Python, which breaks offline and adds latency ([search found no Dart binding](https://context7.com/google/or-tools)). | Good for the model; harder to assert why a specific placement happened. | Overkill for one person's week; keep as a backend option only if hard constraints multiply. |
| **Local search / simulated annealing** | Start from the greedy plan, perturb, keep improvements. Strong on university timetabling benchmarks ([arXiv 1104.2518](https://arxiv.org/pdf/1104.2518)). | Weak-to-moderate: non-deterministic unless seeded. | Fine in Dart, but on Flutter web `compute()` runs on the main thread because web has no isolates ([Flutter docs](https://docs-ai-translation-preview.flutter.cn/perf/isolates), [issue 145132](https://github.com/flutter/flutter/issues/145132)). | Needs seeded RNG for reproducible tests. | Optional v2 polish step on top of greedy, time-boxed to ~50 ms. |

For one user, one week, perhaps 20–60 tasks and 10–30 events, the problem is small. A greedy score-and-fill pass is optimal enough, and its reasons are the product: Pip can say "I put the thesis chapter first because it is due Thursday and you work best before noon".

## 3. Where learning helps (and how little data it needs)

The planning fallacy is real and task-length dependent: people underestimate longer tasks, and feedback on past misestimates reduces the bias ([König et al. 2015](https://eprints.bournemouth.ac.uk/21336/), [Thomas 2004](https://pearl.plymouth.ac.uk/psy-theses/133)). This is the one place where "learning" clearly pays, and it does not need a model:

- **Duration correction.** Keep, per task category (or per goal), the ratio actual ÷ estimated. Use the **running median** of the last ~10 ratios: medians resist the one 3-hour outlier that a mean or exponential smoothing would absorb ([Stata smoothers](https://www.stata.com/manuals/rsmooth.pdf)). Apply `adjusted = estimate × median_ratio`, clamped to [0.5, 3.0]. Before 5 samples, use ratio 1.0 (or a global prior of ~1.2 if Noa wants to bake in the fallacy). Exponential smoothing (α ≈ 0.3) is a fine second option once outliers are clipped.
- **Completion rate by hour band and energy tag.** Count completed vs planned per (hour band, deep/light) cell. Use it only as a tie-breaker in the score and only after ~10 observations per cell; before that, the user's declared energy windows win. Lifestack does the same thing with wearables and still lets users override the estimate by hand ([How Lifestack works](https://demind-inc.notion.site/How-Lifestack-Works-7fd29b5e0bc649cc859a51487ea38805)).
- **Learned priority weights from overrides.** When the user drags a task above a higher-scored one, log a pairwise preference (task A over B, with both feature vectors). This is exactly the training signal for a pairwise ranker, but the literature does not give a minimum sample size and warns that implicit feedback is biased by presentation order ([Joachims et al.](https://www.cs.cornell.edu/~schnabts/downloads/joachims2017ltr.pdf), [Scheel et al.](https://dai-labor.de/en/publications/personalized-learning-to-rank-applied-to-search-engines-2/)). With four weights and a handful of overrides a week, a logistic regression would be fitting noise for months. **Log the overrides from v1, fit nothing until there are hundreds.**
- **Cold start.** Defaults for everything: estimate as entered, energy windows from onboarding ("when do you focus best?"), weights from the scoring function below. Learned statistics are additive corrections with explicit minimum sample sizes, so a new user and a user whose stats were wiped get identical, sane plans.

## 4. The LLM's role

Claude is already planned for the assistant, so the question is only where its boundary sits. The evidence says: **language in, language out, never time arithmetic.**

- A 2025 study of LLMs on calendar scheduling and other constraint problems found that even the strongest models mistranslate constraints, and that having the LLM write solver code underperforms in few-shot settings ([arXiv 2505.13252](https://arxiv.org/pdf/2505.13252)). A scheduling benchmark had to run a solver after generation and discard infeasible outputs ([R-ConstraintBench](https://arxiv.org/pdf/2508.15204)). A design essay on appointment negotiation recommends tool calls, schema validation and always re-querying the calendar rather than trusting the model's recall ([Brenner](https://brenner-axiom.codeberg.page/research/2026-02-20-scheduling-llm-negotiation/)). The pattern "LLM parses intent into a strict schema, deterministic engine does all time math" is the one practitioners converge on ([Chronos AI write-up](https://devpost.com/software/chronos-ai)).
- Reproducibility: the same tasks and calendar must produce the same plan on iOS, web and in a unit test. An LLM cannot promise that. Cost and latency: the deterministic pass is free and instant; a Claude call is a network round trip. Hallucinated times: a model that writes "14:30" has no way of knowing the gap is 25 minutes long unless it does interval arithmetic, which is exactly what it is bad at.

Concrete split, using the Messages API from the Supabase backend:

| Job | Mechanism | Rough cost per call |
| --- | --- | --- |
| Capture: "gym tomorrow 7am, 45 min" → `TaskDraft` | Structured outputs (`output_config.format`, JSON schema with `additionalProperties: false`) ([docs](https://platform.claude.com/docs/de/build-with-claude/structured-outputs)) on Claude Haiku 5.5 | ~300 in / 100 out tokens ≈ $0.0001 |
| Vague goal → constraints: "finish the PM course before the exam" → milestones, weekly quota, deadline | Structured outputs on Claude Sonnet 5.5 | ~1.5K in / 400 out ≈ $0.007 |
| Explain a plan in Pip's voice, Hebrew or English | Plain text; input is the scheduler's `PlacementReason` list, not raw tasks | ~2K in / 300 out ≈ $0.007 on Sonnet 5.5, ≈ $0.0004 on Haiku 5.5 |
| Negotiate: "make it smaller", "move the deep stuff to the morning" | Tool calling with `strict: true` tools such as `set_max_minutes`, `move_energy_window`, `defer_task`; the app re-runs the scheduler after each tool call | ~2–3K in / 200 out ≈ $0.01 |

Prices used: Sonnet 5.5 $2 / $10 per million input / output tokens, Haiku 5.5 $0.10 / $0.50 (Anthropic first-party rates, cached Oct 2026; confirm on [Anthropic's pricing page](https://platform.claude.com/docs/en/about-claude/pricing)). Even a heavy user re-planning ten times a day on Sonnet costs well under $0.10/day; on Haiku it is noise. Put the tool list and system prompt first and the day's data last so prompt caching hits.

## 5. Weekly capacity: "is this week realistic?"

Capacity is arithmetic, not inference:

```
for each day d in week:
  working = workingHours[d.weekday]                      // e.g. 09:00–18:00
  busy    = union(calendar events ∩ working)             // merged intervals
  free[d] = sum(working − busy) − buffers(d)             // buffers: 10 min per event, lunch, per-day cushion
  deepCap[d] = min(free[d], maxDeepBlocks × deepBlockMinutes)

demand = Σ adjustedMinutes(task) for tasks due or planned this week
overbooked = demand > Σ free[d]  (also check deep tasks vs Σ deepCap[d])
```

Deferral suggestions, when overbooked, are a sorted list, lowest score first, from the same scoring function as placement: defer the tasks with the most **deadline slack** (days until due, minus days of work still needed) and the least **goal importance**, until demand ≤ capacity. Never defer a task whose deadline is inside the week, and prefer deferring whole tasks over shaving every task (Pip says "move the reading to next week", not "do everything 20% worse"). Show the number, in Pip's tone: "You have 14 hours free and 19 hours of plans. Two things could move to next week."

## 6. Recommendation and phased path

**v1 (MVP gate): deterministic scheduler in Dart, in `lib/features/plan/scheduler/`.** Pure functions, no I/O, same code on iOS and web, runs on the main isolate because it finishes in under a millisecond. Explicit scoring function, every placement carries a `reason`. "Re-plan with Pip" is just `plan()` again with the updated calendar and the completed/skipped tasks removed, plus pinning: tasks the user moved manually are locked (`lockedStart`) and not re-placed. Capacity view from §5.

**v2 (after Sync & stats): per-user statistics, no training pipeline.** Store `FocusSession(actualMinutes)` and planned-vs-actual per task. Add the median duration ratio and the hour-band completion tie-breaker as additive adjustments with minimum-sample gates. Log manual overrides as pairwise preferences. Optionally a seeded local-search polish (swap two tasks, keep if score improves, ≤ 50 ms).

**v3 (only with evidence): a small learned ranker.** If the override log shows the user consistently disagreeing with the score (say > 30% of weeks have ≥ 3 overrides) and there are a few hundred pairs, fit a 4–6 weight logistic model per user on the backend and ship the weights to the device as plain numbers. The scheduler does not change; only `weights` does. If the overrides are rare, v3 never happens, and that is the expected outcome.

### Data model (inputs)

```dart
class Task {
  String id; String title; String? goalId;
  int estimatedMinutes;            // user's estimate
  Energy energy;                   // deep | light
  DateTime? due;                   // hard deadline (end of day)
  DateTime? notBefore;             // earliest allowed start
  int priority;                    // 1 (must) .. 3 (nice), user-set, default 2
  int minutesDone;                 // progress on finite tasks
  bool splittable; int minChunk;   // can be chunked, smallest chunk (e.g. 25)
  DateTime? lockedStart;           // user pinned it; scheduler respects
  String category;                 // for duration stats: "study", "admin", "workout"...
}

class Goal { String id; String title; double importance /*0..1*/; Horizon horizon; double progress /*0..1*/; }

class CalendarEvent { String id; DateTime start, end; bool busy; }   // busy=false → ignored

class Preferences {
  Map<int /*weekday*/, List<TimeRange>> workingHours;
  List<TimeRange> deepWindows;     // e.g. 09:00–12:00
  int maxDeepBlocksPerDay;         // e.g. 2
  int deepBlockMinutes;            // e.g. 90
  int bufferBetweenEvents;         // e.g. 10
  int dailyCushionMinutes;         // e.g. 60, never planned
  List<TimeRange> lunch;
}

class UserStats {                  // v2, all optional with sample counts
  Map<String, Stat> durationRatioByCategory;   // Stat {median, n}
  Map<HourBand, Map<Energy, Stat>> completionRate;
}

class Placement { String taskId; DateTime start, end; List<String> reasons; }
class Plan { List<Placement> placed; List<Task> unplaced; Capacity capacity; List<Task> deferralSuggestions; }
```

### Core scoring and placement (pseudocode)

```
score(task, goal, now, stats):
  days_left   = max(0, (task.due ?? now+14d) − now).inDays
  work_left   = adjustedMinutes(task, stats) / 60
  slack       = days_left − work_left / avgFreeHoursPerDay     // negative = already late
  urgency     = clamp(1 − slack / 7, 0, 1)                      // 1 when due now, 0 a week+ of slack
  importance  = goal?.importance ?? 0.5
  priority    = (4 − task.priority) / 3                         // 1.0, 0.67, 0.33
  momentum    = goal != null && goal.progress > 0 && goal.progress < 1 ? 0.2 : 0
  stalled     = goal != null && goal.lastProgressAt < now − 7d ? 0.15 : 0
  per_minute  = (urgency + importance) / max(adjustedMinutes, 15)   // WSPT flavour, favours quick wins
  return W.urg*urgency + W.imp*importance + W.pri*priority + momentum + stalled + W.quick*per_minute
  // defaults: W.urg=0.40, W.imp=0.25, W.pri=0.20, W.quick=0.15 (sum of main weights = 1)

plan(tasks, events, prefs, stats, now):
  gaps  = freeGaps(prefs.workingHours, events, prefs.buffers, prefs.lunch, prefs.cushion)   // sorted by start
  fixed = tasks.where(lockedStart != null)  → place verbatim, subtract from gaps
  queue = tasks.where(not done, not locked).sortedBy(score desc, then due asc, then minutes asc)
  for task in queue:
    need = adjustedMinutes(task, stats)
    candidates = gaps.where(g.minutes >= (task.splittable ? task.minChunk : need)
                            && g.start >= task.notBefore && g.end <= task.due)
    if task.energy == deep:
      candidates = preferFirst(candidates, inside prefs.deepWindows)       // stable: deep windows first
      candidates = candidates.where(deepBlocksUsed(day) < prefs.maxDeepBlocksPerDay)
    g = candidates.first ?? continue (→ unplaced, with reason "no gap of N min before due")
    chunk = min(need, g.minutes)
    emit Placement(task, g.start, g.start+chunk, reasons: [
        urgency > 0.6 ? "due ${task.due}" : null,
        importance > 0.7 ? "part of ${goal.title}" : null,
        inDeepWindow ? "your focus window" : null,
        chunk < need ? "first ${chunk} of ${need} min" : null ].nonNull)
    split gap; if chunk < need and task.splittable: push remainder back into queue (same score)
  capacity = capacityForWeek(gaps, tasks, stats)
  deferrals = capacity.overbooked ? queue.reversed.takeWhile(demand > capacity.free && task.due not in week) : []
  return Plan(placed, unplaced, capacity, deferrals)
```

Everything is a pure function of `(tasks, events, prefs, stats, now)`. `now` is injected, never read from the clock inside the scheduler.

### Unit-testing it

- `test/scheduler/` with golden fixtures: a `Preferences` fixture, three calendar fixtures (empty day, meeting-heavy day, back-to-back week), and task lists as JSON. Assert exact placements; because the function is deterministic, a changed expectation is a changed rule.
- Property tests (package `glados` or a small hand-rolled loop with a seeded `Random`): no placement overlaps a busy event or another placement; no placement outside working hours; no placement after `due`; deep blocks per day ≤ max; total placed minutes ≤ free minutes; every unplaced task has a reason.
- Scoring tests in isolation: a task due tomorrow outranks one due in a month at equal importance; a P1 nice-to-have does not beat a must-do due today; a 15-minute task ranks above a 3-hour task at equal urgency (quick-win term).
- Re-plan tests: mark one task done, shift one meeting, run `plan()` again, assert locked tasks did not move and nothing else moved without a reason.
- Capacity tests: demand 19 h vs free 14 h returns `overbooked = true` and deferrals that bring demand under 14 h, with no in-week deadlines deferred.
- Stats tests: with n < 5 the ratio is 1.0; a single 10× outlier does not move the median more than one rank.

What stays off the device: the Claude calls (backend), calendar sync (Supabase), and, if it ever exists, the v3 weight fitting.

## Comparison of approaches

| Approach | Explainability | Offline / on-device | Build effort | Data needed | Main risk |
| --- | --- | --- | --- | --- | --- |
| Greedy score + gap fill (recommended v1) | High: one reason per placement | Yes, Dart, iOS + web | Low (days) | None | Slightly suboptimal packing; invisible to a single user |
| + per-user statistics (v2) | High: "your study tasks usually run 1.4× longer" | Yes | Low (a week) | 5–10 samples per category | Over-correcting from few samples; mitigated by gates and clamps |
| CP-SAT solver | Low: optimal, but no local reason | No: backend only, no Dart port | Medium | None | Online dependency; latency; hard to phrase reasons |
| Local search / annealing | Medium if seeded | Yes, but main thread on web | Medium | None | Non-reproducible without seed; marginal gain |
| Learned ranker (v3) | Medium: weights are readable, decisions are not | Weights on device, fitting on backend | High (pipeline, evaluation) | Hundreds of override pairs per user | Fits noise; months of cold start; nothing to show users |
| LLM picks times | Low and unverifiable | No | Low to write, high to make safe | None | Infeasible or hallucinated slots, cost per plan, non-determinism |
| LLM at the edges (recommended) | High: explains the deterministic plan | No (needs network); plan still works without it | Low | None | Cost and latency only on the explain/negotiate path |

## Sources

Product documentation and reviews
- [Motion help: AI auto-scheduling explained](https://help.usemotion.com/motion-overview/whats-motion/ai-auto-scheduling-explained-harness-the-power-of-intelligent-task-management)
- [Motion help: reference, auto-scheduling](https://www.usemotion.com/help/time-management/auto-scheduling/reference-auto-scheduling)
- [Reclaim help: how Reclaim manages your schedule automatically](https://help.reclaim.ai/en/articles/6207587-how-reclaim-manages-your-schedule-automatically)
- [Reclaim help: customize scheduling settings](https://help.reclaim.ai/en/articles/10491907-customize-your-scheduling-settings-for-reclaim-events)
- [Sunsama help: timeboxing auto-scheduling](https://help.sunsama.com/docs/usage-guides/timeboxing/timeboxing-auto-scheduling)
- [Sunsama roadmap: compare actual vs planned time](https://roadmap.sunsama.com/improvements/p/compare-actual-time-vs-planned-time)
- [Sunsama vs Akiflow (efficient.app)](https://efficient.app/compare/sunsama-vs-akiflow) · [Morgen comparison](https://www.morgen.so/blog-posts/sunsama-vs-akiflow)
- [How Lifestack works (Notion)](https://demind-inc.notion.site/How-Lifestack-Works-7fd29b5e0bc649cc859a51487ea38805) · [Introducing Lifestack](https://lifestack.ai/blog/introducing-lifestack)
- [Google Workspace update: Focus time (2021)](https://workspaceupdates.googleblog.com/2021/10/set-aside-time-for-focus-in-google.html) · [9to5Google on Focus time](https://9to5google.com/2021/10/20/google-calendar-focus-time/)
- [TechCrunch: Google acquires Timeful (2015)](https://techcrunch.com/2015/05/04/google-acquires-timeful-to-bring-smart-scheduling-to-google-apps/amp/) · [Android Police: Goals leaving Google Calendar](https://www.androidpolice.com/goals-leaving-google-calendar/)
- [Microsoft: Focus plan for Viva Insights](https://support.microsoft.com/en-us/viva/insights/focus-plan-for-viva-insights)
- [Clockwise reviews (no engineering details public)](https://aiindigo.com/blog/clockwise-review-2026-can-ai-actually-fix-your-calendar)

Algorithms
- [Single-machine scheduling rules, EDD and WSPT (Univ. Bonn)](https://www.or.uni-bonn.de/lectures/ss10/scheduling_data/sched10_2.pdf) · [MetricGate job scheduling](https://metricgate.com/docs/job-scheduling/)
- [MIT 6.046 lecture 1: interval scheduling](https://ocw.mit.edu/courses/6-046j-design-and-analysis-of-algorithms-spring-2015/ff2a7015ff913fc01f0381d8f5126a9a_MIT6_046JS15_lec01.pdf) · [UW CSE 312: weighted interval scheduling](https://courses.cs.washington.edu/courses/cse312/12sp/slides/algorithms.pdf)
- [CP-SAT primer](https://backiee.wasmer.app/http_www_github_com/topics/cp-sat) · [OR-Tools (context7 mirror)](https://context7.com/google/or-tools)
- [Simulated annealing for course timetabling (arXiv 1104.2518)](https://arxiv.org/pdf/1104.2518)
- [Flutter: isolates and web limitations](https://docs-ai-translation-preview.flutter.cn/perf/isolates) · [flutter/flutter#145132](https://github.com/flutter/flutter/issues/145132) · [isolated_worker package](https://pub.dev/packages/isolated_worker)

Learning and estimation
- [König et al. 2015: previous misestimation and future task duration](https://eprints.bournemouth.ac.uk/21336/) · [Thomas 2004 thesis on time prediction](https://pearl.plymouth.ac.uk/psy-theses/133)
- [Stata smoothers (median vs other smoothers)](https://www.stata.com/manuals/rsmooth.pdf)
- [Joachims et al.: unbiased learning-to-rank with biased feedback](https://www.cs.cornell.edu/~schnabts/downloads/joachims2017ltr.pdf) · [Scheel et al.: personalized learning to rank](https://dai-labor.de/en/publications/personalized-learning-to-rank-applied-to-search-engines-2/)

LLM and scheduling
- [A reality check of language models as formalizers on CSPs (arXiv 2505.13252)](https://arxiv.org/pdf/2505.13252)
- [R-ConstraintBench: LLMs on NP-complete scheduling (arXiv 2508.15204)](https://arxiv.org/pdf/2508.15204)
- [LLMs and structured approaches for appointment negotiation](https://brenner-axiom.codeberg.page/research/2026-02-20-scheduling-llm-negotiation/) · [Chronos AI (LLM parses, CP-SAT schedules)](https://devpost.com/software/chronos-ai)
- [Anthropic: structured outputs (`output_config.format`)](https://platform.claude.com/docs/de/build-with-claude/structured-outputs) · [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)
