import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../core/util/duration_input.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/pip_toast.dart';
import '../../widgets/sticker_bottom_sheet.dart';
import '../../widgets/sticker_text_field.dart';
import '../../widgets/sticker_card.dart';
import '../tasks/task_actions.dart';
import 'providers.dart';

/// Productive layer: a full-screen focus session with Pip cheering.
///
/// All numbers come from [focusControllerProvider], which stores start and
/// end timestamps. The one-second timer here only redraws and asks the
/// controller to [FocusController.tick]; the app returning to the
/// foreground does the same, so a session that ended in the background is
/// picked up at once.
///
/// Web: the tab title does not count down. `SystemChrome` has no title API
/// on the web and the app's `Title` widget belongs to `lib/app`; a
/// `document.title` countdown needs a small web-only helper there.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, this.taskId});

  /// Task to focus on, from the `/focus?taskId=` deep link.
  final String? taskId;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;

  FocusController get _ctrl => ref.read(focusControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _syncTicker(FocusPhase phase) {
    final needed = phase == FocusPhase.focusing || phase == FocusPhase.onBreak;
    if (needed && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!needed && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final what = await _ctrl.tick();
    if (!mounted) return;
    if (what == FocusTick.breakOver) {
      _alert(context.l10n.focusBreakOverToast);
    }
    setState(() {});
  }

  /// In-app stand-in for the end-of-session notification (see report).
  void _alert(String message) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    }
    showPipToast(context, message);
  }

  Future<void> _showEndSheet(FocusOutcome outcome) async {
    if (outcome.completed) _alert(context.l10n.focusSessionOverToast);
    final task = _task(outcome.taskId);
    final choice = await showStickerSheet<_EndChoice>(
      context,
      (ctx) => _EndSheet(outcome: outcome, task: task),
    );
    if (!mounted) return;
    _ctrl.dismissOutcome();
    switch (choice) {
      case _EndChoice.markDone:
        if (task != null) {
          await ref.read(taskActionsProvider).setDone(task, true);
          if (mounted) showPipToast(context, context.l10n.focusTaskDone);
        }
      case _EndChoice.keepGoing:
        // A finished session rolls into its break; an early end starts a
        // fresh session on the same task.
        if (!outcome.completed) await _ctrl.start(taskId: outcome.taskId);
      case _EndChoice.logWin:
        final win = await showStickerSheet<String>(
          context,
          (ctx) => const _WinSheet(),
        );
        if (!mounted || win == null || win.trim().isEmpty) return;
        await _ctrl.saveWin(outcome.sessionId, win);
        if (mounted) showPipToast(context, context.l10n.focusWinLogged);
      case null:
        break;
    }
  }

  /// A line for [progress] (0..1). [seed] picks within the pool so the line
  /// stays put for a session instead of flickering every tick.
  String _cheer(
    AppLocalizations l, {
    required bool idle,
    required bool paused,
    required bool onBreak,
    required double progress,
    int seed = 0,
  }) {
    final List<String> pool;
    if (onBreak) {
      pool = [l.focusCheerBreak1, l.focusCheerBreak2];
    } else if (idle) {
      pool = [l.focusCheerIdle1, l.focusCheerIdle2];
    } else if (paused) {
      pool = [l.focusCheerPaused1, l.focusCheerPaused2];
    } else if (progress < 0.25) {
      pool = [l.focusCheerStart1, l.focusCheerStart2];
    } else if (progress < 0.5) {
      pool = [l.focusCheerMiddle1, l.focusCheerMiddle2];
    } else if (progress < 0.85) {
      pool = [l.focusCheerPastHalf1, l.focusCheerPastHalf2];
    } else {
      pool = [l.focusCheerNearEnd1, l.focusCheerNearEnd2];
    }
    return pool[seed.abs() % pool.length];
  }

  Task? _task(String? id) {
    if (id == null) return null;
    final tasks = ref.read(tasksProvider).valueOrNull ?? const <Task>[];
    return tasks.where((t) => t.id == id).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(focusControllerProvider.select((s) => s.valueOrNull?.outcome), (
      prev,
      next,
    ) {
      if (next != null && prev?.sessionId != next.sessionId) {
        _showEndSheet(next);
      }
    });

    final l = context.l10n;
    final s =
        ref.watch(focusControllerProvider).valueOrNull ?? const FocusState();
    _syncTicker(s.phase);
    final now = ref.watch(clockProvider).now().toUtc();

    final taskId = s.session?.taskId ?? (s.hasSession ? null : widget.taskId);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
    final task = taskId == null
        ? null
        : tasks.where((t) => t.id == taskId).firstOrNull;
    final title = task?.title ?? l.focusFree;

    final idle = s.phase == FocusPhase.idle;
    final paused = s.phase == FocusPhase.paused;
    final onBreak = s.phase == FocusPhase.onBreak;
    final remaining = _format(s.remaining(now));
    final progress = s.progress(now);
    final cycle = s.settings.sessionsPerCycle;
    final dots = s.completedInCycle.clamp(0, cycle);

    final String header;
    if (onBreak) {
      header = s.completedInCycle >= cycle
          ? l.focusLongBreak.toUpperCase()
          : l.focusBreak.toUpperCase();
    } else {
      header = l.focusProgress(s.currentNumber, cycle).toUpperCase();
    }

    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.violet,
      child: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(20, 20 + top, 20, 16),
        children: [
          Text(header, style: AppText.label(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(size: 22, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Pill(
              label: l.focusHardModeSoon,
              color: AppColors.sun,
              height: 32,
              fontSize: 13,
              shadow: 3,
              border: AppStroke.border,
              icon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 52),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(250),
                    painter: _RingPainter(progress),
                  ),
                  const Positioned(
                    top: -58,
                    child: PipAvatar(size: 76, cheering: true),
                  ),
                  Semantics(
                    liveRegion: false,
                    label: remaining,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          remaining,
                          key: const Key('focus-remaining'),
                          style: AppText.display(
                            size: 64,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (paused)
                          Pill(
                            label: l.paused.toUpperCase(),
                            color: AppColors.sun,
                            height: 24,
                            fontSize: 12,
                          )
                        else
                          Text(
                            l.focusOfTotal(_format(s.total)),
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _PipBubble(
            text: _cheer(
              l,
              idle: idle,
              paused: paused,
              onBreak: onBreak,
              progress: progress,
              seed: s.session?.startedAt.minute ?? s.completedInCycle,
            ),
          ),
          const SizedBox(height: 18),
          _controls(context, s, taskId),
          const SizedBox(height: 18),
          Semantics(
            label: l.sessionsDone(dots, cycle),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < cycle; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < dots ? AppColors.sun : Colors.transparent,
                          border: Border.all(
                            color: i < dots ? AppColors.ink : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.lockScreenPreview.toUpperCase(),
                style: AppText.label(color: Colors.white),
              ),
              Text(
                l.liveActivity,
                style: AppText.body(size: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _LockScreenPreview(
            status: onBreak
                ? l.focusOnBreak.toUpperCase()
                : idle
                ? l.focusReady.toUpperCase()
                : paused
                ? l.paused.toUpperCase()
                : l.focusing.toUpperCase(),
            title: title,
            remaining: remaining,
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, FocusState s, String? taskId) {
    final l = context.l10n;
    const step = FocusSettings.stepMinutes;
    final Widget left;
    final Widget right;
    final String mainLabel;
    final IconData mainIcon;
    final VoidCallback mainAction;

    switch (s.phase) {
      case FocusPhase.idle:
        // Coarser steps above an hour so 1 h → 4 h is a handful of taps.
        final current = s.settings.focusMinutes;
        final upStep = FocusSettings.stepFor(current);
        final downStep = FocusSettings.stepFor(current - 1);
        left = PillButton(
          label: l.focusMinusMinutes(downStep),
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 18,
          onPressed: current > FocusSettings.minFocusMinutes
              ? () => _ctrl.adjustNextLength(-downStep)
              : null,
        );
        right = PillButton(
          label: l.plusMinutes(upStep),
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 18,
          onPressed: current < FocusSettings.maxFocusMinutes
              ? () => _ctrl.adjustNextLength(upStep)
              : null,
        );
        mainLabel = l.startFocus;
        mainIcon = Icons.play_arrow;
        mainAction = () => _ctrl.start(taskId: taskId);
      case FocusPhase.focusing:
      case FocusPhase.paused:
        final paused = s.phase == FocusPhase.paused;
        left = PillButton(
          label: l.plusMinutes(step),
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 20,
          onPressed: () => _ctrl.extend(),
        );
        right = PillButton(
          label: l.end,
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 22,
          onPressed: () => _ctrl.end(),
        );
        mainLabel = paused ? l.resume : l.pause;
        mainIcon = paused ? Icons.play_arrow : Icons.pause;
        mainAction = paused ? _ctrl.resume : _ctrl.pause;
      case FocusPhase.onBreak:
        left = PillButton(
          label: l.plusMinutes(step),
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 20,
          onPressed: () => _ctrl.extend(),
        );
        right = PillButton(
          label: l.focusEndBreak,
          height: 48,
          shadow: 3,
          fontSize: 15,
          horizontalPadding: 18,
          onPressed: _ctrl.skipBreak,
        );
        mainLabel = l.focusStartNext;
        mainIcon = Icons.play_arrow;
        mainAction = () => _ctrl.start(taskId: taskId);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: left),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          label: mainLabel,
          excludeSemantics: true,
          onTap: mainAction,
          child: GestureDetector(
            onTap: mainAction,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.sun,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppStroke.border,
                ),
                boxShadow: AppShadows.hard(),
              ),
              child: Icon(mainIcon, size: 32, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: right),
      ],
    );
  }
}

/// mm:ss, or h:mm:ss from an hour up.
String _format(Duration d) {
  final total = (d.inMilliseconds / 1000).ceil();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final sec = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}

class _PipBubble extends StatelessWidget {
  const _PipBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        StickerCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.pipSays} ',
                  style: AppText.bold(),
                ),
                TextSpan(
                  text: text,
                  style: AppText.body(weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -9,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  left: BorderSide(
                    color: AppColors.ink,
                    width: AppStroke.border,
                  ),
                  top: BorderSide(
                    color: AppColors.ink,
                    width: AppStroke.border,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A preview of the iOS Live Activity; the native one is a later issue.
class _LockScreenPreview extends StatelessWidget {
  const _LockScreenPreview({
    required this.status,
    required this.title,
    required this.remaining,
  });

  final String status;
  final String title;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 18, 0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const PipAvatar(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: AppText.label(size: 12, color: AppColors.sun),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    weight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            remaining,
            style: AppText.display(size: 28, color: Colors.white, height: 1),
          ),
        ],
      ),
    );
  }
}

enum _EndChoice { markDone, keepGoing, logWin }

class _EndSheet extends StatelessWidget {
  const _EndSheet({required this.outcome, required this.task});

  final FocusOutcome outcome;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canMarkDone = task != null && !task!.isDone;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const PipAvatar(size: 48, cheering: true),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                outcome.completed ? l.focusDoneTitle : l.focusEarlyTitle,
                style: AppText.display(size: 20, height: 1.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          task == null
              ? l.focusFocusedFor(formatDuration(outcome.focusedMinutes, l))
              : l.focusFocusedForTask(
                  formatDuration(outcome.focusedMinutes, l),
                  task!.title,
                ),
          style: AppText.body(weight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (canMarkDone) ...[
          PillButton(
            label: l.focusMarkDone,
            color: AppColors.sun,
            height: 48,
            shadow: 3,
            fontSize: 15,
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(_EndChoice.markDone),
          ),
          const SizedBox(height: 10),
        ],
        PillButton(
          label: l.focusKeepGoing,
          height: 48,
          shadow: 3,
          fontSize: 15,
          onPressed: () => Navigator.of(context).pop(_EndChoice.keepGoing),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: l.focusLogWin,
          height: 48,
          shadow: 3,
          fontSize: 15,
          icon: const Icon(Icons.star_outline),
          onPressed: () => Navigator.of(context).pop(_EndChoice.logWin),
        ),
      ],
    );
  }
}

/// One line on what got done; pops the text (or null when dismissed).
class _WinSheet extends StatefulWidget {
  const _WinSheet();

  @override
  State<_WinSheet> createState() => _WinSheetState();
}

class _WinSheetState extends State<_WinSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(l.focusWinTitle, style: AppText.display(size: 20, height: 1.2)),
          const SizedBox(height: 12),
          StickerTextField(
            key: const ValueKey('focus-win-field'),
            controller: _text,
            hint: l.focusWinHint,
            pill: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          PillButton(
            key: const ValueKey('focus-win-save'),
            label: l.commonSave,
            color: AppColors.sun,
            height: 48,
            shadow: 3,
            fontSize: 15,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const r = 108.0;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.sun
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
