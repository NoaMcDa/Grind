import 'package:flutter/material.dart';

import '../features/ask/ask_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/pip/pip_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/today/today_screen.dart';
import '../theme/app_text.dart';
import '../theme/tokens.dart';
import '../widgets/pip_avatar.dart';

enum AppTab { today, plan, focus, pip, ask }

/// Five-tab shell: Today · Plan · Focus · Pip · Ask.
///
/// On wide (web) viewports the app is centred in a phone-width column so the
/// layout stays the one that was designed.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.today;

  void _go(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(
        onStartFocus: () => _go(AppTab.focus),
        onAdd: () => _go(AppTab.ask),
      ),
      PlanScreen(
        onStartFocus: () => _go(AppTab.focus),
        onAdd: () => _go(AppTab.ask),
      ),
      const FocusScreen(),
      const PipScreen(),
      const AskScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(index: _tab.index, children: screens),
              ),
              _TabBar(current: _tab, onSelect: _go),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

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
