import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_activity_service.dart';
import 'method_channel_live_activity_service.dart';
import 'platform_support.dart';

export 'live_activity_service.dart';
export 'method_channel_live_activity_service.dart';

/// The Lock Screen / Dynamic Island bridge the focus controller drives. The
/// method channel on iOS, a no-op everywhere else (web, tests). Needs no
/// override in `main.dart`; tests override it with a recording fake or a
/// [MethodChannelLiveActivityService] over a mock channel.
final liveActivityServiceProvider = Provider<LiveActivityService>(
  (_) => isLiveActivityPlatform()
      ? MethodChannelLiveActivityService()
      : const NoopLiveActivityService(),
);
