/// Which calm message the UI shows for a sync failure. The copy itself lives
/// in the ARB files (`calendarSyncGenericError`, `calendarSyncReconnect`) so
/// it follows the app language at display time.
enum SyncErrorKind { generic, reconnect }

/// A sync failure that is safe to show on screen.
///
/// Providers throw this (or a subclass) so the engine can surface a specific
/// [kind]; anything else becomes [SyncErrorKind.generic].
class CalendarSyncException implements Exception {
  const CalendarSyncException(
    this.message, {
    this.kind = SyncErrorKind.generic,
    this.cause,
  });

  /// Technical, for logs.
  final String message;

  /// Selects the calm, specific, never-guilt copy shown to the user.
  final SyncErrorKind kind;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The provider has no valid authorization any more (token revoked or, on
/// web, the browser session ended). The user has to tap Connect again.
class CalendarAuthException extends CalendarSyncException {
  const CalendarAuthException(super.message, {super.cause})
    : super(kind: SyncErrorKind.reconnect);
}

/// The external event a task points at no longer exists. The engine reacts
/// by creating a fresh event instead of failing.
class ExternalEventMissingException extends CalendarSyncException {
  const ExternalEventMissingException(super.message, {super.cause});
}
