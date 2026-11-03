import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../theme/app_text.dart';
import '../../theme/tokens.dart';
import '../../widgets/pill.dart';
import '../../widgets/sticker_card.dart';
import '../calendar/sync/providers.dart';
import '../calendar/sync/sync_status.dart';
import '../onboarding/choice_pills.dart';
import '../onboarding/weekday_hours_editor.dart';
import 'backup_actions.dart';
import 'calendar_selection.dart';
import 'quiet_hours.dart';
import 'settings_row.dart';
import 'settings_store.dart';
import 'settings_strings.dart';
import 'time_zone/device_time_zone.dart';
import 'time_zone/time_zone_picker.dart';

bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Everything the onboarding asked for, plus backup and about. Reachable at
/// `/settings`; every skipped onboarding step can be resumed here.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.picker = pickMinutes});

  /// Test hook for the time picker.
  final MinutesPicker picker;

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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                if (canPop)
                  IconButton(
                    tooltip: SettingsStrings.back,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                Expanded(
                  child: Text(
                    SettingsStrings.title,
                    style: AppText.display(height: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _section(SettingsStrings.calendars, [
              _CalendarProviderTile(
                label: SettingsStrings.google,
                providerOf: googleCalendarProvider,
                statusOf: syncStatusProvider,
              ),
              if (_isIos)
                _CalendarProviderTile(
                  label: SettingsStrings.apple,
                  providerOf: appleCalendarProvider,
                  statusOf: appleSyncStatusProvider,
                ),
            ]),
            _section(SettingsStrings.notifications, [
              const _NotificationPermissionRow(),
              SettingsRow(label: SettingsStrings.leadTime),
              ChoicePills<int>(
                options: {
                  for (final m in const [0, 5, 10, 15, 30])
                    m: SettingsStrings.minutesBefore(m),
                },
                selected: prefs.defaultReminderLeadMinutes,
                onSelected: (v) => _update(
                  ref,
                  (p) => p.copyWith(defaultReminderLeadMinutes: v),
                ),
              ),
              const SizedBox(height: 8),
              SettingsRow(
                label: SettingsStrings.quietHours,
                subtitle: SettingsStrings.quietHoursHint,
                trailing: Switch(
                  key: const ValueKey('quiet-switch'),
                  value: prefs.quietHours != null,
                  activeThumbColor: AppColors.card,
                  activeTrackColor: AppColors.violet,
                  inactiveThumbColor: AppColors.ink,
                  inactiveTrackColor: AppColors.lilac,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    AppColors.ink,
                  ),
                  onChanged: (v) => _update(
                    ref,
                    (p) => p.copyWith(quietHours: v ? defaultQuietHours : null),
                  ),
                ),
              ),
              if (prefs.quietHours != null)
                _TimeRangeRow(
                  range: prefs.quietHours!,
                  picker: picker,
                  onChanged: (r) =>
                      _update(ref, (p) => p.copyWith(quietHours: r)),
                ),
              _PromptTimes(picker: picker),
            ]),
            _section(SettingsStrings.planning, [
              _TimeZoneRow(timeZoneName: prefs.timeZoneName),
              const SettingsRow(label: SettingsStrings.workingHours),
              WeekdayHoursEditor(
                value: prefs.workingHours,
                weekStart: prefs.weekStart,
                picker: picker,
                onChanged: (h) =>
                    _update(ref, (p) => p.copyWith(workingHours: h)),
              ),
              const SizedBox(height: 8),
              const SettingsRow(label: SettingsStrings.weekStart),
              ChoicePills<int>(
                options: const {
                  DateTime.sunday: SettingsStrings.sunday,
                  DateTime.monday: SettingsStrings.monday,
                },
                selected: prefs.weekStart,
                onSelected: (v) =>
                    _update(ref, (p) => p.copyWith(weekStart: v)),
              ),
            ]),
            _section(SettingsStrings.language, [
              ChoicePills<String>(
                options: const {
                  'en': SettingsStrings.english,
                  'he': SettingsStrings.hebrew,
                },
                selected: prefs.localeCode,
                onSelected: (v) =>
                    _update(ref, (p) => p.copyWith(localeCode: v)),
              ),
            ]),
            _section(SettingsStrings.data, [const _DataActions()]),
            _section(SettingsStrings.about, [
              const SettingsRow(
                label: SettingsStrings.version,
                trailing: Pill(label: SettingsStrings.appVersion),
              ),
              SettingsRow(
                label: SettingsStrings.licences,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink,
                ),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Grind',
                  applicationVersion: SettingsStrings.appVersion,
                ),
              ),
              const SettingsRow(
                label: SettingsStrings.privacy,
                subtitle: SettingsStrings.privacyCopy,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title.toUpperCase(), style: AppText.label()),
          ),
          StickerCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRangeRow extends StatelessWidget {
  const _TimeRangeRow({
    required this.range,
    required this.onChanged,
    required this.picker,
  });

  final TimeRange range;
  final ValueChanged<TimeRange> onChanged;
  final MinutesPicker picker;

  @override
  Widget build(BuildContext context) {
    Future<void> edit(bool start) async {
      final v = await picker(
        context,
        start ? range.startMinutes : range.endMinutes,
      );
      if (v == null) return;
      // An end before the start crosses midnight (22:00 – 07:00).
      final next = start
          ? changeQuietHours(range, start: v)
          : changeQuietHours(range, end: v);
      if (next != null) onChanged(next);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              formatQuietHours(range),
              key: const ValueKey('quiet-summary'),
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          Text(SettingsStrings.quietFrom, style: AppText.bold(size: 14)),
          TimePill(
            key: const ValueKey('quiet-start'),
            minutes: range.startMinutes,
            semanticLabel: SettingsStrings.quietFrom,
            onTap: () => edit(true),
          ),
          Text(SettingsStrings.quietTo, style: AppText.bold(size: 14)),
          TimePill(
            key: const ValueKey('quiet-end'),
            minutes: range.endMinutes,
            semanticLabel: SettingsStrings.quietTo,
            onTap: () => edit(false),
          ),
        ],
      ),
    );
  }
}

/// The zone every day boundary and reminder uses; opens the picker.
class _TimeZoneRow extends ConsumerWidget {
  const _TimeZoneRow({required this.timeZoneName});

  final String timeZoneName;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final device = await ref.read(deviceTimeZoneProvider).current();
    if (!context.mounted) return;
    final picked = await showTimeZonePicker(
      context,
      current: timeZoneName,
      deviceZone: device,
    );
    if (picked == null) return;
    await saveTimeZone(ref.read(preferencesRepositoryProvider), picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsRow(
      key: const ValueKey('time-zone-row'),
      label: SettingsStrings.timeZone,
      subtitle: timeZoneLabel(timeZoneName),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
      onTap: () => _edit(context, ref),
    );
  }
}

class _PromptTimes extends ConsumerStatefulWidget {
  const _PromptTimes({required this.picker});

  final MinutesPicker picker;

  @override
  ConsumerState<_PromptTimes> createState() => _PromptTimesState();
}

class _PromptTimesState extends ConsumerState<_PromptTimes> {
  int? _morning;
  int? _evening;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(settingsStoreProvider);
    final m = await store.morningPromptMinutes();
    final e = await store.eveningPromptMinutes();
    if (!mounted) return;
    setState(() {
      _morning = m;
      _evening = e;
      _loaded = true;
    });
  }

  Widget _row(
    String label,
    int? value,
    String keyName,
    Future<void> Function(int?) save,
    void Function(int?) set,
    int fallback,
  ) {
    return SettingsRow(
      label: label,
      subtitle: value == null ? null : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            TimePill(
              key: ValueKey('$keyName-time'),
              minutes: value,
              semanticLabel: label,
              onTap: () async {
                final v = await widget.picker(context, value);
                if (v == null) return;
                await save(v);
                setState(() => set(v));
              },
            ),
          Switch(
            key: ValueKey('$keyName-switch'),
            value: value != null,
            activeThumbColor: AppColors.card,
            activeTrackColor: AppColors.violet,
            inactiveThumbColor: AppColors.ink,
            inactiveTrackColor: AppColors.lilac,
            trackOutlineColor: const WidgetStatePropertyAll(AppColors.ink),
            onChanged: (on) async {
              final v = on ? fallback : null;
              await save(v);
              setState(() => set(v));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final store = ref.read(settingsStoreProvider);
    return Column(
      children: [
        _row(
          SettingsStrings.morningPrompt,
          _morning,
          'morning',
          store.setMorningPromptMinutes,
          (v) => _morning = v,
          8 * 60,
        ),
        _row(
          SettingsStrings.eveningPrompt,
          _evening,
          'evening',
          store.setEveningPromptMinutes,
          (v) => _evening = v,
          20 * 60,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            SettingsStrings.promptsHint,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationPermissionRow extends ConsumerStatefulWidget {
  const _NotificationPermissionRow();

  @override
  ConsumerState<_NotificationPermissionRow> createState() =>
      _NotificationPermissionRowState();
}

class _NotificationPermissionRowState
    extends ConsumerState<_NotificationPermissionRow> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    bool g;
    try {
      g = await ref.read(notificationServiceProvider).hasPermission();
    } catch (_) {
      g = false;
    }
    if (mounted) setState(() => _granted = g);
  }

  Future<void> _request() async {
    bool g;
    try {
      g = await ref.read(notificationServiceProvider).requestPermission();
    } catch (_) {
      g = false;
    }
    if (mounted) setState(() => _granted = g);
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted ?? false;
    return SettingsRow(
      label: SettingsStrings.notifPermission,
      subtitle: _granted == null
          ? null
          : (granted
                ? SettingsStrings.notifPermissionOn
                : SettingsStrings.notifPermissionOff),
      trailing: granted || _granted == null
          ? null
          : _SmallButton(label: 'Allow', onPressed: _request),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: _pill(),
    );
  }

  Widget _pill() {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.violet : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.ink, width: AppStroke.border),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.bold(
            size: 14,
            height: 1,
            color: primary ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _CalendarProviderTile extends ConsumerStatefulWidget {
  const _CalendarProviderTile({
    required this.label,
    required this.providerOf,
    required this.statusOf,
  });

  final String label;
  final Provider<CalendarProvider> providerOf;
  final StreamProvider<SyncStatus> statusOf;

  @override
  ConsumerState<_CalendarProviderTile> createState() =>
      _CalendarProviderTileState();
}

class _CalendarProviderTileState extends ConsumerState<_CalendarProviderTile> {
  bool _connected = false;
  bool _failed = false;
  List<ExternalCalendar> _calendars = const [];
  CalendarSelection? _selection;

  CalendarProvider get _provider => ref.read(widget.providerOf);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final connected = await _provider.isConnected();
      var calendars = <ExternalCalendar>[];
      CalendarSelection? selection;
      if (connected) {
        calendars = await _provider.listCalendars();
        final saved = await ref
            .read(settingsStoreProvider)
            .selectedCalendarIds(_provider.source);
        selection = saved == null
            ? CalendarSelection.defaults(_provider.source, calendars)
            : CalendarSelection(source: _provider.source, ids: saved);
      }
      if (!mounted) return;
      setState(() {
        _connected = connected;
        _calendars = calendars;
        _selection = selection;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _connect() async {
    try {
      final ok = await _provider.connect();
      if (!mounted) return;
      setState(() => _failed = !ok);
      await _refresh();
      // Events should appear now, not at the next 15 minute tick.
      if (ok) unawaited(_syncNow());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _syncNow() async {
    try {
      await ref.read(calendarSyncSchedulerProvider).runNow();
    } catch (_) {
      // Failures are shown through the sync status pill.
    }
  }

  Future<void> _disconnect() async {
    await _provider.disconnect();
    await _refresh();
    // Clears the mirrored events of this calendar.
    unawaited(_syncNow());
  }

  Future<void> _toggle(String id) async {
    final next = _selection!.toggle(id);
    await ref
        .read(settingsStoreProvider)
        .setSelectedCalendarIds(next.source, next.ids);
    if (mounted) setState(() => _selection = next);
    unawaited(_syncNow());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          label: widget.label,
          subtitle: _connected
              ? SettingsStrings.connected
              : SettingsStrings.notConnected,
          trailing: _SmallButton(
            label: _connected
                ? SettingsStrings.disconnect
                : SettingsStrings.connect,
            primary: !_connected,
            onPressed: _connected ? _disconnect : _connect,
          ),
        ),
        if (_connected) _SyncStatusPill(status: ref.watch(widget.statusOf)),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              SettingsStrings.connectFailed,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
        if (_connected && _selection != null) ...[
          Text(SettingsStrings.calendarsToUse, style: AppText.label(size: 12)),
          for (final c in _calendars)
            CheckboxListTile(
              key: ValueKey('cal-${widget.label}-${c.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: AppColors.violet,
              checkColor: Colors.white,
              side: const BorderSide(
                color: AppColors.ink,
                width: AppStroke.border,
              ),
              title: Text(c.name, style: AppText.bold(size: 14)),
              value: _selection!.contains(c.id),
              onChanged: (_) => _toggle(c.id),
            ),
        ],
      ],
    );
  }
}

/// Idle / syncing / last synced hh:mm / error, for one calendar provider.
class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({required this.status});

  final AsyncValue<SyncStatus> status;

  static String two(int v) => v.toString().padLeft(2, '0');

  static String label(SyncStatus s) {
    switch (s.phase) {
      case SyncPhase.syncing:
        return SettingsStrings.syncing;
      case SyncPhase.error:
        return s.message ?? SettingsStrings.syncError;
      case SyncPhase.idle:
        final t = s.lastSyncedAt?.toLocal();
        return t == null
            ? SettingsStrings.syncIdle
            : SettingsStrings.lastSynced('${two(t.hour)}:${two(t.minute)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = status.value;
    if (s == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Pill(
          key: const ValueKey('sync-status'),
          height: 28,
          label: label(s),
          color: s.isError ? AppColors.card : AppColors.lilac,
        ),
      ),
    );
  }
}

class _DataActions extends ConsumerWidget {
  const _DataActions();

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    String msg;
    try {
      await action();
      msg = done;
    } catch (_) {
      msg = SettingsStrings.actionFailed;
    }
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.read(backupActionsProvider);
    return Column(
      children: [
        SettingsRow(
          label: SettingsStrings.exportBackup,
          subtitle: SettingsStrings.exportHint,
          trailing: const Icon(
            Icons.file_upload_outlined,
            color: AppColors.ink,
          ),
          onTap: () =>
              _run(context, backup.exportBackup, SettingsStrings.exportDone),
        ),
        SettingsRow(
          label: SettingsStrings.importBackup,
          trailing: const Icon(
            Icons.file_download_outlined,
            color: AppColors.ink,
          ),
          onTap: () =>
              _run(context, backup.importBackup, SettingsStrings.importDone),
        ),
        SettingsRow(
          label: SettingsStrings.deleteAll,
          destructive: true,
          trailing: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFC4254B),
          ),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text(SettingsStrings.deleteConfirmTitle),
                content: const Text(SettingsStrings.deleteConfirmBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(SettingsStrings.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(SettingsStrings.deleteConfirm),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await _run(
                context,
                backup.deleteAllData,
                SettingsStrings.deleted,
              );
            }
          },
        ),
      ],
    );
  }
}
