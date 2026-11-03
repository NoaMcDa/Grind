import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../widgets.dart';

/// Every design-system component in its states, for visual review.
/// Not routed in production; the integrator may add a debug route.
class WidgetGallery extends StatelessWidget {
  const WidgetGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
          children: [
            Text('Widget gallery', style: AppText.display()),
            _Section('StickerCard', [
              StickerCard(child: Text(l.planDrafted, style: AppText.bold())),
              const SizedBox(height: 14),
              StickerCard(
                color: AppColors.lilac,
                shadow: 0,
                child: Text(l.done, style: AppText.bold()),
              ),
              const SizedBox(height: 14),
              StickerCard(
                dashed: true,
                child: Text(l.fromCalendar, style: AppText.bold()),
              ),
            ]),
            _Section('PillButton', [
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  PillButton(label: l.startFocus, onPressed: () {}),
                  PillButton(
                    label: l.addTask,
                    onPressed: () {},
                    color: AppColors.violet,
                    textColor: Colors.white,
                    display: true,
                    icon: const Icon(Icons.add),
                  ),
                  PillButton(label: l.snooze15, color: AppColors.sun),
                  PillButton(
                    label: l.edit,
                    onPressed: () {},
                    height: 32,
                    shadow: 0,
                  ),
                ],
              ),
            ]),
            _Section('Pill + IconChip + SectionLabel', [
              SectionLabel(l.sectionEnergy),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconChip.deep(label: l.energyDeep),
                  IconChip.light(label: l.energyLight),
                  Pill(label: l.doneOfTotal(2, 5), color: AppColors.mint),
                  Pill(label: l.cloudAssistant, color: AppColors.sun),
                  Pill(label: l.comingSoon, color: AppColors.pink),
                ],
              ),
            ]),
            _Section('MomentumMeter', [
              const MomentumMeter(value: 0),
              const SizedBox(height: 10),
              MomentumMeter(
                value: 0.55,
                segments: const [AppColors.violet, AppColors.pink],
                shadow: 3,
                semanticLabel: l.momentumSemantic,
              ),
              const SizedBox(height: 10),
              const MomentumMeter(value: 1, segments: [AppColors.mint]),
            ]),
            _Section('PipAvatar', [
              const Wrap(
                spacing: 12,
                children: [
                  PipAvatar(size: 64),
                  PipAvatar(size: 64, cheering: true),
                  PipAvatar(size: 64, accessory: PipAccessory.scarf),
                  PipAvatar(size: 64, accessory: PipAccessory.sunglasses),
                  PipIcon(),
                ],
              ),
            ]),
            _Section('StickerTextField', [
              StickerTextField(label: l.addATask, hint: l.composerHint),
              const SizedBox(height: 12),
              StickerTextField(hint: l.composerHint, pill: true),
              const SizedBox(height: 12),
              const StickerTextField(
                label: 'Title',
                errorText: 'Give it a name, Pip will take it from there.',
              ),
              const SizedBox(height: 12),
              StickerTextField(label: l.edit, enabled: false),
            ]),
            _Section('Date / time pickers + sheet + toast', [
              Builder(
                builder: (ctx) => Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    PillButton(
                      label: 'Date',
                      onPressed: () => showStickerDatePicker(
                        ctx,
                        initialDate: DateTime.now(),
                      ),
                    ),
                    PillButton(
                      label: 'Time',
                      onPressed: () => showStickerTimePicker(
                        ctx,
                        initialTime: TimeOfDay.now(),
                      ),
                    ),
                    PillButton(
                      label: 'Sheet',
                      onPressed: () => showStickerSheet<void>(
                        ctx,
                        (c) =>
                            Text(l.planArranged(5, 2), style: AppText.body()),
                      ),
                    ),
                    PillButton(
                      label: 'Toast',
                      onPressed: () => showPipToast(ctx, l.niceStart),
                    ),
                  ],
                ),
              ),
            ]),
            _Section('StickerSheetFrame', [
              StickerSheetFrame(
                child: Text(l.snoozeAgainHint, style: AppText.body()),
              ),
            ]),
            _Section('SkeletonBox', [
              const SkeletonBox(height: 20, width: 180),
              const SizedBox(height: 8),
              const SkeletonBox(height: 64),
            ]),
            _Section('EmptyState', [
              EmptyState(
                title: l.emptyDefaultTitle,
                body: l.emptyDefaultBody,
                actionLabel: l.addATask,
                onAction: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
