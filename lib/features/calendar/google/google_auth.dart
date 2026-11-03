import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

import 'google_calendar_gateway.dart';
import 'google_config.dart';

/// Outcome of an interactive sign-in.
enum GoogleSignInOutcome { authorized, cancelled, failed }

/// OAuth for Google Calendar, on the device. Tests use a fake.
abstract interface class GoogleAuth {
  /// Interactive sign-in + scope consent. Call from a button tap (web
  /// browsers block popups that are not user-initiated).
  Future<({GoogleSignInOutcome outcome, String? error})> signIn();

  /// A gateway with a valid access token, obtained without user interaction,
  /// or null when the user must sign in again.
  Future<GoogleCalendarGateway?> gateway();

  /// Revoke the grant and forget the session.
  Future<void> signOut();
}

/// [GoogleAuth] over `google_sign_in` 7.x.
///
/// iOS: the Google Sign-In SDK keeps the refresh token in the Keychain and
/// refreshes access tokens itself. Web: Google Identity Services (the GIS
/// script in `web/index.html`) issues short-lived access tokens for the
/// browser session only; after a reload the user taps Connect again.
class GoogleSignInAuth implements GoogleAuth {
  GoogleSignInAuth(this.config);

  final GoogleCalendarConfig config;

  static Future<void>? _initialized;

  GoogleSignInClientAuthorization? _authz;
  DateTime? _authzAt;
  gcal.CalendarApi? _api;
  // Closes the HTTP client behind [_api]; called when it is replaced.
  void Function()? _closeClient;

  // Access tokens live about an hour; ask again well before that.
  static const _tokenTtl = Duration(minutes: 45);

  GoogleSignIn get _gsi => GoogleSignIn.instance;

  Future<void> _ensureInit() => _initialized ??= _gsi.initialize(
    clientId: config.clientId,
    serverClientId: null,
  );

  @override
  Future<({GoogleSignInOutcome outcome, String? error})> signIn() async {
    try {
      await _ensureInit();
      final GoogleSignInClientAuthorization authz;
      if (_gsi.supportsAuthenticate()) {
        final account = await _gsi.authenticate(
          scopeHint: GoogleCalendarConfig.scopes,
        );
        authz = await account.authorizationClient.authorizeScopes(
          GoogleCalendarConfig.scopes,
        );
      } else {
        // Web: GIS token client, no separate authentication step needed.
        authz = await _gsi.authorizationClient.authorizeScopes(
          GoogleCalendarConfig.scopes,
        );
      }
      _remember(authz);
      return (outcome: GoogleSignInOutcome.authorized, error: null);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return (outcome: GoogleSignInOutcome.cancelled, error: null);
      }
      return (
        outcome: GoogleSignInOutcome.failed,
        error: 'Google sign-in failed (${e.code.name}): ${e.description}',
      );
    } catch (e) {
      return (
        outcome: GoogleSignInOutcome.failed,
        error: 'Google sign-in failed: $e',
      );
    }
  }

  @override
  Future<GoogleCalendarGateway?> gateway() async {
    final at = _authzAt;
    if (_api != null &&
        at != null &&
        DateTime.now().difference(at) < _tokenTtl) {
      return GoogleApisCalendarGateway(_api!);
    }
    await _ensureInit();
    GoogleSignInClientAuthorization? authz;
    try {
      if (_gsi.supportsAuthenticate()) {
        final account = await _gsi.attemptLightweightAuthentication();
        authz = await account?.authorizationClient.authorizationForScopes(
          GoogleCalendarConfig.scopes,
        );
      } else {
        authz = await _gsi.authorizationClient.authorizationForScopes(
          GoogleCalendarConfig.scopes,
        );
      }
    } on GoogleSignInException {
      authz = null;
    }
    if (authz == null) return null;
    _remember(authz);
    return GoogleApisCalendarGateway(_api!);
  }

  void _remember(GoogleSignInClientAuthorization authz) {
    _closeClient?.call();
    final client = authz.authClient(scopes: GoogleCalendarConfig.scopes);
    _closeClient = client.close;
    _authz = authz;
    _authzAt = DateTime.now();
    _api = gcal.CalendarApi(client);
  }

  @override
  Future<void> signOut() async {
    await _ensureInit();
    final token = _authz?.accessToken;
    if (token != null) {
      await _gsi.authorizationClient
          .clearAuthorizationToken(accessToken: token)
          .catchError((Object _) {});
    }
    try {
      await _gsi.disconnect();
    } catch (_) {
      await _gsi.signOut().catchError((Object _) {});
    }
    _closeClient?.call();
    _closeClient = null;
    _authz = null;
    _authzAt = null;
    _api = null;
  }
}
