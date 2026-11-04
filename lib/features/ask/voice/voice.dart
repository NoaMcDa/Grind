import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_input_service.dart';
import 'web_voice_input_service.dart';

export 'voice_input_service.dart';
export 'voice_session.dart';
export 'web_voice_input_service.dart';

/// The mic bridge the Ask composer uses to turn speech into text (#43).
///
/// Picks the fallback that fits this surface. iOS native wiring via
/// `speech_to_text` and the web wiring over `window.SpeechRecognition`
/// land in later slices and override this provider in `main.dart` (and
/// in `test/features/ask/voice/*` for the few tests that need a fake)
/// once they land. Keeping the selection in one place means the
/// composer never imports a platform-specific class directly.
final voiceInputServiceProvider = Provider<VoiceInputService>(
  (_) => kIsWeb ? const WebVoiceInputService() : const StubVoiceInputService(),
);
