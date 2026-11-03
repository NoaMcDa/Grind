import 'calendar_sync_strings.dart';

/// A sync failure with copy that is safe to show on screen.
///
/// Providers throw this (or a subclass) so the engine can surface a specific
/// message; anything else becomes [CalendarSyncStrings.genericError].
class CalendarSyncException implements Exception {
  const CalendarSyncException(
    this.message, {
    this.userMessage = CalendarSyncStrings.genericError,
    this.cause,
  });

  /// Technical, for logs.
  final String message;

  /// Calm, specific, never guilt.
  final String userMessage;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The provider has no valid authorization any more (token revoked or, on
/// web, the browser session ended). The user has to tap Connect again.
class CalendarAuthException extends CalendarSyncException {
  const CalendarAuthException(super.message, {super.cause})
    : super(userMessage: CalendarSyncStrings.reconnect);
}

/// The external event a task points at no longer exists. The engine reacts
/// by creating a fresh event instead of failing.
class ExternalEventMissingException extends CalendarSyncException {
  const ExternalEventMissingException(super.message, {super.cause});
}
