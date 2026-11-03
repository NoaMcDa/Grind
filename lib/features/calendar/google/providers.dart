import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/l10n.dart';
import 'google_auth.dart';
import 'google_calendar_provider.dart';
import 'google_config.dart';
import 'key_value_store.dart';

/// Swap the fake Google provider for the real one. In `main.dart`:
///
/// ```dart
/// GrindApp(overrides: [..., googleCalendarOverride()])
/// ```
///
/// Without `--dart-define=GOOGLE_CLIENT_ID_IOS/WEB` the provider stays
/// disconnected and `connect()` returns false with a setup hint in
/// [GoogleCalendarProvider.lastError].
Override googleCalendarOverride({
  GoogleCalendarConfig config = const GoogleCalendarConfig.fromEnvironment(),
  GoogleAuth? auth,
  KeyValueStore? store,
}) => googleCalendarProvider.overrideWith(
  (ref) => GoogleCalendarProvider(
    auth: auth ?? GoogleSignInAuth(config),
    store: store ?? platformKeyValueStore(),
    config: config,
    clock: ref.watch(clockProvider),
    l10n: () => lookupAppLocalizations(
      Locale(ref.read(preferencesProvider).value?.localeCode ?? 'en'),
    ),
  ),
);
