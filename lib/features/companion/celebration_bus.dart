import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/celebration/confetti_overlay.dart';
import '../../widgets/celebration/pip_bounce.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/pip_toast.dart';
import 'pip_providers.dart';
import 'praise.dart';
import 'unlocks.dart';

/// Something worth a small cheer (#34). Fire one with [celebrate] and the
/// [CelebrationHost] does the rest.
sealed class CelebrationEvent {
  const CelebrationEvent();

  /// A task was marked done. [big] for a task that took real effort.
  const factory CelebrationEvent.taskCompleted({bool big}) = TaskCompleted;

  /// A focus session ended. [full] is true when the planned time was
  /// reached (a bigger cheer); an early finish still counts, quietly.
  const factory CelebrationEvent.focusSessionFinished({bool full}) =
      FocusSessionFinished;

  /// A recurring metric reached its target for the period.
  const factory CelebrationEvent.metricReached() = MetricReached;

  /// A goal was completed.
  const factory CelebrationEvent.goalCompleted() = GoalCompleted;

  /// The user showed up on several days.
  const factory CelebrationEvent.showedUp() = ShowedUp;

  /// An accessory was unlocked (fired by the host, once per unlock).
  const factory CelebrationEvent.unlocked(PipAccessory accessory) =
      AccessoryUnlocked;
}

final class TaskCompleted extends CelebrationEvent {
  const TaskCompleted({this.big = false});
  final bool big;
}

final class FocusSessionFinished extends CelebrationEvent {
  const FocusSessionFinished({this.full = true});
  final bool full;
}

final class MetricReached extends CelebrationEvent {
  const MetricReached();
}

final class GoalCompleted extends CelebrationEvent {
  const GoalCompleted();
}

final class ShowedUp extends CelebrationEvent {
  const ShowedUp();
}

final class AccessoryUnlocked extends CelebrationEvent {
  const AccessoryUnlocked(this.accessory);
  final PipAccessory accessory;
}

/// Broadcast stream of [CelebrationEvent]s.
class CelebrationBus {
  final _controller = StreamController<CelebrationEvent>.broadcast();

  Stream<CelebrationEvent> get stream => _controller.stream;

  void emit(CelebrationEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void dispose() => _controller.close();
}

final celebrationBusProvider = Provider<CelebrationBus>((ref) {
  final bus = CelebrationBus();
  ref.onDispose(bus.dispose);
  return bus;
});

/// Fire a celebration from a widget.
void celebrate(WidgetRef ref, CelebrationEvent event) =>
    ref.read(celebrationBusProvider).emit(event);

/// Fire a celebration from a provider or notifier.
void celebrateFrom(Ref ref, CelebrationEvent event) =>
    ref.read(celebrationBusProvider).emit(event);

/// How big the cheer is.
PraiseIntensity intensityOf(CelebrationEvent e) => switch (e) {
  TaskCompleted(:final big) =>
    big ? PraiseIntensity.big : PraiseIntensity.light,
  FocusSessionFinished(:final full) =>
    full ? PraiseIntensity.big : PraiseIntensity.light,
  MetricReached() ||
  GoalCompleted() ||
  AccessoryUnlocked() => PraiseIntensity.big,
  ShowedUp() => PraiseIntensity.light,
};

/// Which praise pool an event draws from; null when the host has its own
/// string (unlocks).
PraiseEvent? praiseEventOf(CelebrationEvent e) => switch (e) {
  TaskCompleted() => PraiseEvent.taskDone,
  FocusSessionFinished() => PraiseEvent.sessionDone,
  MetricReached() || GoalCompleted() => PraiseEvent.weeklyGoal,
  ShowedUp() => PraiseEvent.showedUp,
  AccessoryUnlocked() => null,
};

/// Chooses how each burst looks so repeats stay fresh (novelty fades by
/// week three): the palette starts one colour further round every time,
/// and every [altEvery]th burst swaps to the ribbon shape set.
class CelebrationVariety {
  CelebrationVariety({this.altEvery = 5});

  final int altEvery;
  int _n = 0;

  int get count => _n;

  ConfettiStyle next(PraiseIntensity intensity) {
    final n = _n++;
    final k = confettiPalette.length;
    final colors = [for (var i = 0; i < k; i++) confettiPalette[(n + i) % k]];
    return ConfettiStyle(
      colors: colors,
      shapes: (n + 1) % altEvery == 0
          ? ConfettiShapes.ribbons
          : ConfettiShapes.classic,
      count: intensity == PraiseIntensity.big ? 42 : 20,
    );
  }
}

class _Burst {
  _Burst(this.id, this.style, this.bounce, this.accessory);
  final int id;
  final ConfettiStyle style;
  final bool bounce;
  final PipAccessory accessory;
}

/// Wrap the app with this (e.g. in `MaterialApp.builder`, below the
/// `ScaffoldMessenger`). It listens to [celebrationBusProvider] and shows:
/// a short confetti burst, a medium haptic on iOS, a Pip toast with one
/// praise line and, for a finished focus session, a Pip bounce. It also
/// watches the unlock rules and fires [CelebrationEvent.unlocked] once for
/// each new accessory.
///
/// Everything is drawn in an [IgnorePointer] layer, so input is never
/// blocked. With `MediaQuery.disableAnimations` the confetti and bounce are
/// skipped; the toast and haptic still happen.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key, required this.child});

  final Widget child;

  /// Whether a host is above [context] (screens with their own cheer line
  /// can then leave the toast to it).
  static bool isPresent(BuildContext context) =>
      context.findAncestorWidgetOfExactType<CelebrationHost>() != null;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  final _variety = CelebrationVariety();
  final _bursts = <_Burst>[];
  StreamSubscription<CelebrationEvent>? _sub;
  String? _lastLine;
  int _id = 0;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(celebrationBusProvider).stream.listen(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUnlocks());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _checkUnlocks() {
    if (!mounted || !ref.read(unlocksReadyProvider)) return;
    final fresh = ref
        .read(unlockSeenProvider.notifier)
        .sync(ref.read(unlockedAccessoriesProvider));
    for (final a in fresh) {
      celebrate(ref, CelebrationEvent.unlocked(a));
    }
  }

  String _line(CelebrationEvent e, AppLocalizations l, Locale locale) {
    if (e is AccessoryUnlocked) {
      return l.pipUnlockedToast(accessoryName(l, e.accessory));
    }
    final pe = praiseEventOf(e)!;
    final intensity = intensityOf(e);
    var line = praiseFor(pe, locale: locale, intensity: intensity);
    for (var i = 0; i < 4 && line == _lastLine; i++) {
      line = praiseFor(pe, locale: locale, intensity: intensity);
    }
    return line;
  }

  void _handle(CelebrationEvent e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final line = _line(e, l, locale);
    _lastLine = line;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    }

    if (!MediaQuery.disableAnimationsOf(context)) {
      final worn = ref.read(companionPrefsProvider).accessory;
      final burst = _Burst(
        _id++,
        _variety.next(intensityOf(e)),
        e is FocusSessionFinished,
        PipAccessory.values.firstWhere(
          (a) => a.name == worn,
          orElse: () => PipAccessory.none,
        ),
      );
      setState(() => _bursts.add(burst));
    }

    // A completed task already shows its own toast with Undo (TaskActions);
    // a second snackbar would queue behind it. Confetti and haptic still run.
    if (e is! TaskCompleted && ScaffoldMessenger.maybeOf(context) != null) {
      showPipToast(context, line, duration: const Duration(seconds: 3));
    }
  }

  void _remove(_Burst b) {
    if (mounted) setState(() => _bursts.remove(b));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unlockedAccessoriesProvider, (_, _) => _checkUnlocks());
    ref.listen(unlocksReadyProvider, (_, _) => _checkUnlocks());
    return Stack(
      children: [
        widget.child,
        for (final b in _bursts) ...[
          Positioned.fill(
            key: ValueKey('confetti-${b.id}'),
            child: ConfettiOverlay(
              style: b.style,
              seed: b.id + 1,
              onDone: () => _remove(b),
            ),
          ),
          if (b.bounce)
            Positioned.fill(
              key: ValueKey('bounce-${b.id}'),
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0.35),
                  child: PipBounce(accessory: b.accessory),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
