import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/pip_avatar.dart';
import '../../widgets/sticker_card.dart';
import '../calendar/sync/providers.dart';
import 'choice_pills.dart';
import 'onboarding_providers.dart';
import 'onboarding_strings.dart';
import 'permission_rationale_card.dart';
import 'weekday_hours_editor.dart';

const _stepCount = 5;

/// First-run flow: welcome, notifications, calendar, working hours, done.
/// Every step can be skipped; nothing here is a dead end.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key, required this.onFinished, this.picker});

  /// Called after `onboardingDone` has been saved.
  final VoidCallback onFinished;

  /// Test hook for the time picker.
  final MinutesPicker? picker;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _controller = PageController();
  int _step = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_step >= _stepCount - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final repo = ref.read(preferencesRepositoryProvider);
    final prefs = await repo.get();
    await repo.save(prefs.copyWith(onboardingDone: true));
    ref.invalidate(onboardingDoneProvider);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _stepCount - 1;
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  _ProgressDots(count: _stepCount, index: _step),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: _next,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 44),
                        foregroundColor: AppColors.muted,
                      ),
                      child: Text(
                        OnboardingStrings.skip,
                        style: AppText.bold(size: 14, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _WelcomeStep(onNext: _next),
                  _NotificationsStep(onNext: _next),
                  _CalendarStep(onNext: _next),
                  _HoursStep(onNext: _next, picker: widget.picker),
                  _DoneStep(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});

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

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: children,
    );
  }
}

Widget _title(String text) =>
    Text(text, style: AppText.display(size: 28, height: 1.15));

Widget _body(String text) => Text(
  text,
  style: AppText.body(
    size: 15,
    weight: FontWeight.w500,
    height: 1.45,
    color: AppColors.muted,
  ),
);

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      children: [
        const SizedBox(height: 24),
        const Center(child: PipAvatar(size: 160)),
        const SizedBox(height: 24),
        _title(OnboardingStrings.welcomeTitle),
        const SizedBox(height: 10),
        _body(OnboardingStrings.welcomeBody),
        const SizedBox(height: 28),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PillButton(
            label: OnboardingStrings.welcomeStart,
            color: AppColors.violet,
            textColor: Colors.white,
            display: true,
            fontSize: 16,
            height: 52,
            shadow: 4,
            horizontalPadding: 32,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

enum _Perm { unknown, granted, denied }

class _NotificationsStep extends ConsumerStatefulWidget {
  const _NotificationsStep({required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<_NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends ConsumerState<_NotificationsStep> {
  _Perm _perm = _Perm.unknown;

  Future<void> _allow() async {
    bool ok;
    try {
      ok = await ref.read(notificationServiceProvider).requestPermission();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _perm = ok ? _Perm.granted : _Perm.denied);
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      children: [
        _title(OnboardingStrings.notifTitle),
        const SizedBox(height: 16),
        PermissionRationaleCard(
          icon: Icons.notifications_none_rounded,
          title: OnboardingStrings.notifRationaleTitle,
          body: OnboardingStrings.notifRationale,
        ),
        const SizedBox(height: 16),
        if (_perm == _Perm.granted)
          StickerCard(
            color: AppColors.mint.withValues(alpha: 0.25),
            child: Text(
              OnboardingStrings.notifGranted,
              style: AppText.bold(size: 14),
            ),
          ),
        if (_perm == _Perm.denied)
          StickerCard(
            key: const ValueKey('notif-denied'),
            color: AppColors.sun.withValues(alpha: 0.35),
            child: Text(
              OnboardingStrings.notifDenied,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (_perm == _Perm.unknown)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PillButton(
                label: OnboardingStrings.notifAllow,
                color: AppColors.violet,
                textColor: Colors.white,
                onPressed: _allow,
              ),
              PillButton(
                label: OnboardingStrings.notifNotNow,
                onPressed: widget.onNext,
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PillButton(
              label: OnboardingStrings.continueLabel,
              color: AppColors.violet,
              textColor: Colors.white,
              onPressed: widget.onNext,
            ),
          ),
      ],
    );
  }
}

bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class _CalendarStep extends ConsumerWidget {
  const _CalendarStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepScaffold(
      children: [
        _title(OnboardingStrings.calTitle),
        const SizedBox(height: 12),
        _body(OnboardingStrings.calRationale),
        const SizedBox(height: 16),
        _CalendarRow(
          label: OnboardingStrings.calGoogle,
          provider: googleCalendarProvider,
          color: AppColors.sky,
        ),
        if (_isIos) ...[
          const SizedBox(height: 14),
          _CalendarRow(
            label: OnboardingStrings.calApple,
            provider: appleCalendarProvider,
            color: AppColors.pink,
          ),
        ],
        const SizedBox(height: 14),
        _body(OnboardingStrings.calLater),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PillButton(
            label: OnboardingStrings.continueLabel,
            color: AppColors.violet,
            textColor: Colors.white,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

class _CalendarRow extends ConsumerStatefulWidget {
  const _CalendarRow({
    required this.label,
    required this.provider,
    required this.color,
  });

  final String label;
  final Provider<CalendarProvider> provider;
  final Color color;

  @override
  ConsumerState<_CalendarRow> createState() => _CalendarRowState();
}

class _CalendarRowState extends ConsumerState<_CalendarRow> {
  bool _connected = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ref.read(widget.provider).isConnected();
      if (mounted) setState(() => _connected = c);
    } catch (_) {}
  }

  Future<void> _connect() async {
    try {
      final ok = await ref.read(widget.provider).connect();
      if (!mounted) return;
      setState(() {
        _connected = ok;
        _failed = !ok;
      });
      // Events should show up now, not at the next 15 minute tick.
      if (ok) unawaited(ref.read(calendarSyncSchedulerProvider).runNow());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppStroke.borderThin,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppText.display(size: 17, height: 1.2),
                ),
              ),
              if (_connected)
                const Pill(
                  label: OnboardingStrings.calConnected,
                  color: AppColors.mint,
                  height: 30,
                )
              else
                PillButton(
                  label: OnboardingStrings.calConnect,
                  color: AppColors.violet,
                  textColor: Colors.white,
                  onPressed: _connect,
                ),
            ],
          ),
          if (_failed) ...[
            const SizedBox(height: 10),
            Text(
              OnboardingStrings.calFailed,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HoursStep extends ConsumerWidget {
  const _HoursStep({required this.onNext, this.picker});

  final VoidCallback onNext;
  final MinutesPicker? picker;

  Future<void> _update(
    WidgetRef ref,
    Preferences Function(Preferences) change,
  ) async {
    final repo = ref.read(preferencesRepositoryProvider);
    await repo.save(change(await repo.get()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).value ?? const Preferences();
    return _StepScaffold(
      children: [
        _title(OnboardingStrings.hoursTitle),
        const SizedBox(height: 10),
        _body(OnboardingStrings.hoursBody),
        const SizedBox(height: 12),
        StickerCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: WeekdayHoursEditor(
            value: prefs.workingHours,
            weekStart: prefs.weekStart,
            picker: picker ?? pickMinutes,
            onChanged: (h) => _update(ref, (p) => p.copyWith(workingHours: h)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          OnboardingStrings.weekStartLabel,
          style: AppText.bold(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        ChoicePills<int>(
          options: const {
            DateTime.sunday: OnboardingStrings.sunday,
            DateTime.monday: OnboardingStrings.monday,
          },
          selected: prefs.weekStart,
          onSelected: (v) => _update(ref, (p) => p.copyWith(weekStart: v)),
        ),
        const SizedBox(height: 18),
        Text(
          OnboardingStrings.languageLabel,
          style: AppText.bold(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        ChoicePills<String>(
          options: const {
            'en': OnboardingStrings.english,
            'he': OnboardingStrings.hebrew,
          },
          selected: prefs.localeCode,
          onSelected: (v) => _update(ref, (p) => p.copyWith(localeCode: v)),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PillButton(
            label: OnboardingStrings.continueLabel,
            color: AppColors.violet,
            textColor: Colors.white,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      children: [
        const SizedBox(height: 24),
        const Center(child: PipAvatar(size: 160, cheering: true)),
        const SizedBox(height: 24),
        _title(OnboardingStrings.doneTitle),
        const SizedBox(height: 10),
        _body(OnboardingStrings.doneBody),
        const SizedBox(height: 28),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PillButton(
            label: OnboardingStrings.doneButton,
            color: AppColors.violet,
            textColor: Colors.white,
            display: true,
            fontSize: 16,
            height: 52,
            shadow: 4,
            horizontalPadding: 28,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}
