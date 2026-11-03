import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grind/core/core.dart';

import 'apple_calendar_channel.dart';
import 'apple_calendar_provider.dart';

/// For `main.dart`: replaces the fake [appleCalendarProvider] with EventKit.
/// Safe on every platform; off iOS the provider reports "unavailable".
Override appleCalendarOverride({AppleCalendarChannel? channel}) =>
    appleCalendarProvider.overrideWith(
      (ref) => AppleCalendarProvider(
        channel: channel,
        clock: ref.watch(clockProvider),
      ),
    );

/// Fires on every change to the device's calendar database. Empty unless
/// [appleCalendarProvider] is an [AppleCalendarProvider] on iOS. The sync
/// engine (#13) listens to this to re-pull Apple events.
final appleCalendarChangesProvider = StreamProvider<void>((ref) {
  final provider = ref.watch(appleCalendarProvider);
  return provider is AppleCalendarProvider
      ? provider.changes
      : const Stream<void>.empty();
});
