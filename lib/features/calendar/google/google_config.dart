import 'package:flutter/foundation.dart';

/// OAuth configuration for Google Calendar. Client ids come from
/// `--dart-define`; nothing secret is compiled in (OAuth client ids for
/// installed and browser apps are public by design).
///
/// ```sh
/// flutter run -d chrome --web-port 5000 \
///   --dart-define=GOOGLE_CLIENT_ID_WEB=1234-abc.apps.googleusercontent.com
/// flutter build ios \
///   --dart-define=GOOGLE_CLIENT_ID_IOS=1234-xyz.apps.googleusercontent.com
/// ```
class GoogleCalendarConfig {
  const GoogleCalendarConfig({
    required this.iosClientId,
    required this.webClientId,
  });

  /// Reads the ids passed with `--dart-define`.
  const GoogleCalendarConfig.fromEnvironment()
    : iosClientId = const String.fromEnvironment(
        'GOOGLE_CLIENT_ID_IOS',
        defaultValue: iosPlaceholder,
      ),
      webClientId = const String.fromEnvironment(
        'GOOGLE_CLIENT_ID_WEB',
        defaultValue: webPlaceholder,
      );

  static const iosPlaceholder = 'REPLACE_ME_GOOGLE_CLIENT_ID_IOS';
  static const webPlaceholder = 'REPLACE_ME_GOOGLE_CLIENT_ID_WEB';

  /// `calendar.events` to read and write events, `calendar.readonly` for the
  /// calendar list.
  static const scopes = [
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  final String iosClientId;
  final String webClientId;

  /// The id for the platform the app runs on.
  String clientIdFor({required bool web}) => web ? webClientId : iosClientId;

  String get clientId => clientIdFor(web: kIsWeb);

  /// False while the `--dart-define` placeholder is still in place.
  bool isConfiguredFor({required bool web}) =>
      _looksReal(clientIdFor(web: web));

  bool get isConfigured => isConfiguredFor(web: kIsWeb);

  static bool _looksReal(String id) =>
      id.trim().isNotEmpty &&
      !id.startsWith('REPLACE_ME') &&
      id.endsWith('.apps.googleusercontent.com');

  /// Developer-facing explanation shown as `lastError` when not configured.
  String setupHelp({required bool web}) {
    final name = web ? 'GOOGLE_CLIENT_ID_WEB' : 'GOOGLE_CLIENT_ID_IOS';
    final kind = web ? 'Web application' : 'iOS';
    return 'Google Calendar is not set up in this build yet: $name is still '
        'the placeholder. Create an OAuth client id of type "$kind" in the '
        'Google Cloud Console (APIs & Services > Credentials), then run with '
        '--dart-define=$name=<id>.apps.googleusercontent.com. Step by step: '
        'docs/adr/0005-google-calendar.md#oauth-setup '
        '(https://github.com/NoaMcDa/Grind/blob/main/docs/adr/0005-google-calendar.md#oauth-setup).';
  }
}
