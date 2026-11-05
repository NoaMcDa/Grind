import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hard_mode_shield_service.dart';
import 'method_channel_hard_mode_shield_service.dart';
import 'platform_support.dart';

export 'hard_mode_selection.dart';
export 'hard_mode_selection_diff.dart';
export 'hard_mode_shield_service.dart';
export 'hard_mode_status.dart';
export 'method_channel_hard_mode_shield_service.dart';
export 'platform_support.dart' show supportsHardMode;

/// The FamilyControls / ManagedSettings bridge the focus controller drives
/// when the user has opted into hard mode. The method channel on iOS, a
/// no-op everywhere else (web, Android, desktop, tests). Needs no override
/// in `main.dart`; tests override it with a recording fake or a
/// [MethodChannelHardModeShieldService] over a mock channel.
final hardModeShieldServiceProvider = Provider<HardModeShieldService>(
  (_) => supportsHardMode()
      ? MethodChannelHardModeShieldService()
      : const NoopHardModeShieldService(),
);
