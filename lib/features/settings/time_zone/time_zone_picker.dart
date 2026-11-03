import 'package:flutter/material.dart';

import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/pill.dart';
import '../../../widgets/sticker_bottom_sheet.dart';
import '../../../widgets/sticker_text_field.dart';
import '../settings_strings.dart';
import 'device_time_zone.dart';

/// "America/New_York" -> "America/New York".
String timeZoneLabel(String name) => name.replaceAll('_', ' ');

/// Names matching [query] (case-insensitive; spaces match underscores).
List<String> filterTimeZones(List<String> names, String query) {
  final q = query.trim().toLowerCase().replaceAll(' ', '_');
  if (q.isEmpty) return names;
  return names.where((n) => n.toLowerCase().contains(q)).toList();
}

/// Searchable list of every zone in the database, with the device zone as a
/// one-tap option on top. Pops the chosen name, or null.
Future<String?> showTimeZonePicker(
  BuildContext context, {
  required String current,
  String? deviceZone,
}) => showStickerSheet<String>(
  context,
  (ctx) => TimeZonePicker(current: current, deviceZone: deviceZone),
);

class TimeZonePicker extends StatefulWidget {
  const TimeZonePicker({super.key, required this.current, this.deviceZone});

  final String current;

  /// Offered as a one-tap option when it is a known zone.
  final String? deviceZone;

  @override
  State<TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<TimeZonePicker> {
  final _query = TextEditingController();
  late final List<String> _all = timeZoneNames();
  late List<String> _shown = _all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(String name) {
    if (!isKnownTimeZone(name)) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final device = isKnownTimeZone(widget.deviceZone)
        ? widget.deviceZone
        : null;
    final height = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            SettingsStrings.timeZone,
            style: AppText.display(size: 20, height: 1.2),
          ),
          const SizedBox(height: 12),
          if (device != null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PillButton(
                key: const ValueKey('tz-use-device'),
                label: SettingsStrings.useDeviceZone(timeZoneLabel(device)),
                color: AppColors.sun,
                height: 44,
                shadow: 3,
                fontSize: 14,
                icon: const Icon(Icons.my_location_outlined),
                onPressed: () => _pick(device),
              ),
            ),
            const SizedBox(height: 12),
          ],
          StickerTextField(
            key: const ValueKey('tz-search'),
            controller: _query,
            hint: SettingsStrings.timeZoneSearch,
            pill: true,
            prefixIcon: const Icon(Icons.search, color: AppColors.ink),
            textInputAction: TextInputAction.search,
            onChanged: (q) => setState(() => _shown = filterTimeZones(_all, q)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: _shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      SettingsStrings.timeZoneNoMatch,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _shown.length,
                    itemExtent: 48,
                    itemBuilder: (context, i) {
                      final name = _shown[i];
                      final selected = name == widget.current;
                      return InkWell(
                        key: ValueKey('tz-$name'),
                        onTap: () => _pick(name),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                timeZoneLabel(name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: selected
                                    ? AppText.bold(size: 15)
                                    : AppText.body(
                                        size: 15,
                                        weight: FontWeight.w500,
                                      ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check, color: AppColors.violet),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
