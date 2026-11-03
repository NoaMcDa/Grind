import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';
import '../widgets/pip_avatar.dart';

enum AppTab { today, plan, focus, pip, ask }

/// The bottom tab bar, driven by the router's [StatefulNavigationShell].
class GrindShellTabBar extends StatelessWidget {
  const GrindShellTabBar({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return GrindTabBar(
      current: AppTab.values[shell.currentIndex],
      onSelect: (tab) => shell.goBranch(
        tab.index,
        initialLocation: tab.index == shell.currentIndex,
      ),
    );
  }
}

/// Plain tab bar (same look as the original shell's).
class GrindTabBar extends StatelessWidget {
  const GrindTabBar({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 6 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppStroke.border),
        ),
      ),
      child: Row(
        children: [
          for (final tab in AppTab.values)
            Expanded(
              child: _TabItem(
                tab: tab,
                active: tab == current,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  static const _labels = {
    AppTab.today: 'Today',
    AppTab.plan: 'Plan',
    AppTab.focus: 'Focus',
    AppTab.pip: 'Pip',
    AppTab.ask: 'Ask',
  };

  Widget _icon(Color color) => switch (tab) {
    AppTab.today => Icon(Icons.wb_sunny_outlined, color: color, size: 22),
    AppTab.plan => Icon(Icons.calendar_today_outlined, color: color, size: 22),
    AppTab.focus => Icon(Icons.timer_outlined, color: color, size: 22),
    AppTab.pip => PipIcon(color: color, size: 22),
    AppTab.ask => Icon(Icons.chat_bubble_outline, color: color, size: 22),
  };

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.violet : AppColors.muted;
    return Semantics(
      button: true,
      selected: active,
      label: _labels[tab],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 28,
                alignment: Alignment.center,
                decoration: active
                    ? BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppStroke.borderThin,
                        ),
                      )
                    : null,
                child: _icon(active ? Colors.white : color),
              ),
              const SizedBox(height: 3),
              Text(
                _labels[tab]!,
                style: AppText.bold(size: 11, color: color, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
