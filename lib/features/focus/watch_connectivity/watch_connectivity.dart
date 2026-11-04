import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'method_channel_watch_connectivity_service.dart';
import 'platform_support.dart';
import 'watch_connectivity_service.dart';

export 'method_channel_watch_connectivity_service.dart';
export 'watch_connectivity_service.dart';
export 'watch_snapshot.dart';

/// The Apple Watch bridge the focus controller drives (#46). The method
/// channel on iOS, a no-op everywhere else (web, tests). Needs no override
/// in `main.dart`; tests override it with a recording fake or a
/// [MethodChannelWatchConnectivityService] over a mock channel.
final watchConnectivityServiceProvider = Provider<WatchConnectivityService>((
  ref,
) {
  if (!isWatchConnectivityPlatform()) {
    return const NoopWatchConnectivityService();
  }
  final service = MethodChannelWatchConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});
