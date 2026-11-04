import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/goals/domain/goal_metric.dart';
import 'package:grind/features/goals/domain/goal_record.dart';
import 'package:grind/features/goals/goal_providers.dart';
import 'package:grind/features/recurrence/occurrence_completion.dart';
import 'package:grind/theme/app_text.dart';
import 'package:grind/theme/tokens.dart';
import 'package:grind/widgets/widgets.dart';

import 'review_providers.dart';
import 'review_repository.dart';
import '../../l10n/l10n.dart';
import 'rollover.dart';

/// Route-ready entry point: add `/review` pointing at this widget.
class EveningReviewEntry extends ConsumerWidget {
  const EveningReviewEntry({super.key, this.onFinished});

  /// Defaults to popping the route.
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EveningReviewFlow(
      onFinished: () {
        ref.invalidate(eveningReviewDueProvider);
        if (onFinished != null) {
          onFinished!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
    );
  }
}

/// Banner for the Today screen, shown only while the review is due.
class EveningReviewBanner extends ConsumerWidget {
  const EveningReviewBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(eveningReviewDueProvider).valueOrNull ?? false;
    if (!due) return const SizedBox.shrink();
    return StickerCard(
      color: AppColors.lilac,
      child: Row(
        children: [
          const PipAvatar(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.reviewBannerTitle,
              style: AppText.bold(size: 15),
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: context.l10n.reviewBannerAction,
            color: AppColors.violet,
            textColor: Colors.white,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

/// Four skippable steps: what got done, what moves on, a check-in on
/// recurring-metric goals (#31), and one win.
class EveningReviewFlow extends ConsumerStatefulWidget {
  const EveningReviewFlow({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<EveningReviewFlow> createState() => _EveningReviewFlowState();
}

class _EveningReviewFlowState extends ConsumerState<EveningReviewFlow> {
  static const _steps = 5; // done, move, check-in, win, finish

  final _controller = PageController();
  final _win = TextEditingController();
  int _step = 0;
  bool _loaded = false;

  List<Task> _today = [];
  Map<String, ReminderRule> _rules = {};
  List<GoalRecord> _checkInGoals = [];
  final Set<String> _checked = {};
  final Set<String> _doneIds = {};
  final Set<String> _checkedInGoalIds = {};
  final Map<String, RolloverChoice> _choices = {};
  int _doneCount = 0;
  int _movedCount = 0;
  int _checkInCount = 0;
  bool _saved = false;

  DateTime get _now => ref.read(clockProvider).now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _win.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await ref.read(taskRepositoryProvider).getAll();
    final rules = await ref.read(reminderRepositoryProvider).getAll();
    final goals = await ref.read(goalRepositoryProvider).getAll();
    // Shown once: whatever happens next, today's review is not offered again.
    await ref.read(reviewRepositoryProvider).markHandled(dayKey(_now));
    if (!mounted) return;
    setState(() {
      _today = reviewTasksFor(all, _now);
      _rules = {for (final r in rules) r.taskId: r};
      _checkInGoals = [
        for (final g in goals)
          if (g.deletedAt == null &&
              g.status == GoalStatus.active &&
              g.recurring != null)
            g,
      ];
      _loaded = true;
    });
  }

  bool _isRecurring(Task t) => _rules.containsKey(t.id);

  List<Task> get _movable => [
    for (final t in _today)
      if (!_doneIds.contains(t.id) && !_isRecurring(t)) t,
  ];

  void _go() {
    if (_step >= _steps - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmDone() async {
    final repo = ref.read(taskRepositoryProvider);
    final rules = ref.read(reminderRepositoryProvider);
    final prefs = await ref.read(preferencesRepositoryProvider).get();
    final now = _now.toUtc();
    for (final t in _today.where((t) => _checked.contains(t.id))) {
      final rule = _rules[t.id];
      if (rule == null) {
        await repo.upsert(
          t.copyWith(status: TaskStatus.done, completedAt: now, updatedAt: now),
        );
      } else {
        // One occurrence, stored with its rule like
        // `TaskActions.completeRecurring` (the series goes on).
        await storeSeriesCompletion(
          tasks: repo,
          rules: rules,
          task: t,
          rule: rule,
          occurrenceAt: t.remindAt ?? now,
          timeZoneName: prefs.timeZoneName,
          now: now,
        );
      }
      _doneIds.add(t.id);
      _doneCount++;
    }
    _go();
  }

  Future<void> _confirmMoves() async {
    final repo = ref.read(taskRepositoryProvider);
    final now = _now;
    for (final t in _movable) {
      switch (_choices[t.id]) {
        case RolloverChoice.tomorrow:
          final moved = rolloverTask(t, 1, now: now);
          if (moved != null) {
            await repo.upsert(moved);
            _movedCount++;
          }
        case RolloverChoice.laterThisWeek:
          final moved = rolloverTask(t, 2, now: now);
          if (moved != null) {
            await repo.upsert(moved);
            _movedCount++;
          }
        case RolloverChoice.tomorrowAnyway:
          final moved = rolloverTask(t, 1, now: now, pushDeadline: true);
          if (moved != null) {
            await repo.upsert(moved);
            _movedCount++;
          }
        case RolloverChoice.drop:
          await repo.delete(t.id);
          _movedCount++;
        case RolloverChoice.keep:
        case null:
          break;
      }
    }
    _go();
  }

  Future<void> _confirmCheckIn() async {
    final actions = ref.read(goalActionsProvider);
    for (final g in _checkInGoals) {
      if (_checkedInGoalIds.contains(g.id)) {
        await actions.increment(g);
        _checkInCount++;
      }
    }
    _go();
  }

  Future<void> _saveWin() async {
    final win = _win.text.trim();
    if (!_saved &&
        (win.isNotEmpty || _doneCount + _movedCount + _checkInCount > 0)) {
      _saved = true;
      await ref
          .read(reviewRepositoryProvider)
          .save(
            ReviewEntry(
              date: dayKey(_now),
              win: win,
              doneCount: _doneCount,
              movedCount: _movedCount,
            ),
          );
    }
    _go();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: !_loaded
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                    child: Row(
                      children: [
                        _Dots(count: _steps, index: _step),
                        const Spacer(),
                        if (_step < _steps - 1)
                          TextButton(
                            key: const ValueKey('review-skip'),
                            onPressed: _go,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(64, 44),
                              foregroundColor: AppColors.muted,
                            ),
                            child: Text(
                              context.l10n.commonSkip,
                              style: AppText.bold(
                                size: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _step = i),
                      children: [
                        _page([
                          _title(context.l10n.reviewDoneTitle),
                          const SizedBox(height: 6),
                          _hint(context.l10n.reviewDoneHint),
                          const SizedBox(height: 16),
                          if (_today.isEmpty)
                            _hint(context.l10n.reviewDoneEmpty)
                          else
                            for (final t in _today) _doneRow(t),
                          const SizedBox(height: 16),
                          _primary(
                            context.l10n.onboardingContinue,
                            _confirmDone,
                          ),
                        ]),
                        _page([
                          _title(context.l10n.reviewMoveTitle),
                          const SizedBox(height: 6),
                          _hint(context.l10n.reviewMoveHint),
                          const SizedBox(height: 16),
                          if (_movable.isEmpty)
                            _hint(context.l10n.reviewMoveEmpty)
                          else
                            for (final t in _movable) _moveCard(t),
                          for (final t in _today)
                            if (_isRecurring(t) && !_doneIds.contains(t.id))
                              _recurringNote(t),
                          const SizedBox(height: 16),
                          _primary(
                            context.l10n.onboardingContinue,
                            _confirmMoves,
                          ),
                        ]),
                        _page([
                          _title(context.l10n.reviewCheckInTitle),
                          const SizedBox(height: 6),
                          _hint(context.l10n.reviewCheckInHint),
                          const SizedBox(height: 16),
                          if (_checkInGoals.isEmpty)
                            _hint(context.l10n.reviewCheckInEmpty)
                          else
                            for (final g in _checkInGoals) _checkInRow(g),
                          const SizedBox(height: 16),
                          _primary(
                            context.l10n.onboardingContinue,
                            _confirmCheckIn,
                          ),
                        ]),
                        _page([
                          _title(context.l10n.reviewWinTitle),
                          const SizedBox(height: 6),
                          _hint(context.l10n.reviewWinHint),
                          const SizedBox(height: 16),
                          StickerTextField(
                            key: const ValueKey('review-win-field'),
                            controller: _win,
                            hint: context.l10n.reviewWinField,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _primary(context.l10n.reviewSave, _saveWin),
                        ]),
                        _page([
                          const SizedBox(height: 24),
                          const Center(child: PipAvatar(size: 140)),
                          const SizedBox(height: 20),
                          _title(context.l10n.reviewFinishTitle),
                          const SizedBox(height: 8),
                          Text(
                            _praise(context.l10n, _now.day),
                            key: const ValueKey('review-praise'),
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _primary(context.l10n.done, widget.onFinished),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _page(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: children,
  );

  Widget _title(String s) =>
      Text(s, style: AppText.display(size: 28, height: 1.15));

  Widget _hint(String s) => Text(
    s,
    style: AppText.body(
      size: 15,
      weight: FontWeight.w500,
      height: 1.45,
      color: AppColors.muted,
    ),
  );

  Widget _primary(String label, VoidCallback onTap) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: PillButton(
      key: ValueKey('review-primary-$label'),
      label: label,
      color: AppColors.violet,
      textColor: Colors.white,
      display: true,
      fontSize: 16,
      height: 52,
      shadow: 4,
      horizontalPadding: 32,
      onPressed: onTap,
    ),
  );

  Widget _doneRow(Task t) {
    final on = _checked.contains(t.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('review-done-${t.id}'),
        borderRadius: BorderRadius.circular(AppRadii.row),
        onTap: () => setState(() {
          on ? _checked.remove(t.id) : _checked.add(t.id);
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: StickerCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shadow: 2,
            color: on ? AppColors.mint.withValues(alpha: 0.25) : AppColors.card,
            child: Row(
              children: [
                Icon(
                  on
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: on ? AppColors.mint : AppColors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(t.title, style: AppText.bold(size: 15))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkInRow(GoalRecord g) {
    final on = _checkedInGoalIds.contains(g.id);
    final m = g.recurring!;
    final sub = switch (m.period) {
      MetricPeriod.week => context.l10n.reviewCheckInUnitWeek(m.unit),
      MetricPeriod.month => context.l10n.reviewCheckInUnitMonth(m.unit),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('review-checkin-${g.id}'),
        borderRadius: BorderRadius.circular(AppRadii.row),
        onTap: () => setState(() {
          on ? _checkedInGoalIds.remove(g.id) : _checkedInGoalIds.add(g.id);
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: StickerCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shadow: 2,
            color: on ? AppColors.mint.withValues(alpha: 0.25) : AppColors.card,
            child: Row(
              children: [
                Icon(
                  on
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: on ? AppColors.mint : AppColors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.title, style: AppText.bold(size: 15)),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: AppText.body(size: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recurringNote(Task t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: StickerCard(
      shadow: 0,
      padding: const EdgeInsets.all(12),
      child: Text(
        '${t.title}. ${context.l10n.reviewRepeatsNote}',
        style: AppText.body(size: 13, color: AppColors.muted),
      ),
    ),
  );

  String _label(RolloverChoice c) => switch (c) {
    RolloverChoice.tomorrow => context.l10n.commonTomorrow,
    RolloverChoice.laterThisWeek => context.l10n.reviewLater,
    RolloverChoice.keep => context.l10n.reviewKeepToday,
    RolloverChoice.tomorrowAnyway => context.l10n.reviewTomorrowAnyway,
    RolloverChoice.drop => context.l10n.reviewDrop,
  };

  Widget _moveCard(Task t) {
    final options = optionsFor(t);
    final chosen = _choices[t.id];
    final deadline = !fitsDeadline(t, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StickerCard(
        shadow: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title, style: AppText.bold(size: 15)),
            if (deadline) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.reviewDeadlineNote,
                style: AppText.body(size: 13, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 10),
            if (chosen == RolloverChoice.drop)
              Row(
                children: [
                  Text(
                    context.l10n.reviewDropped,
                    style: AppText.bold(size: 14),
                  ),
                  const SizedBox(width: 8),
                  PillButton(
                    key: ValueKey('review-undo-${t.id}'),
                    label: context.l10n.undo,
                    onPressed: () => setState(() => _choices.remove(t.id)),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options)
                    PillButton(
                      key: ValueKey('review-opt-${t.id}-${o.name}'),
                      label: _label(o),
                      color: chosen == o ? AppColors.sun : AppColors.card,
                      onPressed: () => setState(() => _choices[t.id] = o),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              width: i == index ? 26 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: i == index
                    ? AppColors.violet
                    : (i < index ? AppColors.mint : AppColors.card),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppStroke.borderThin,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One praise line, stable for a given [seed] (the day of the month).
String _praise(AppLocalizations l, int seed) {
  final lines = [
    l.reviewPraise1,
    l.reviewPraise2,
    l.reviewPraise3,
    l.reviewPraise4,
    l.reviewPraise5,
  ];
  return lines[seed % lines.length];
}
