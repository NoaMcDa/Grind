import 'logging.dart';

/// Base class for failures the app expects and can explain to the user.
///
/// [message] is for logs (English, technical). [userMessage] is what the UI
/// shows, in Pip's tone: calm, specific, never guilt.
sealed class AppException implements Exception {
  const AppException(this.message, {this.userMessage, this.cause});

  final String message;
  final String? userMessage;
  final Object? cause;

  /// Copy safe to show on screen.
  String get displayMessage =>
      userMessage ??
      'Something went sideways. Pip is on it, try again in a moment.';

  @override
  String toString() => '$runtimeType: $message';
}

/// Local database / file problems.
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.cause,
    super.userMessage =
        "Pip couldn't save that. Your plan is safe, try once more.",
  });
}

/// Network problems (calendar sync, later backend).
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.cause,
    super.userMessage =
        "No connection right now. Pip will pick this up when you're back.",
  });
}

/// Calendar provider problems (permissions, sync).
class CalendarException extends AppException {
  const CalendarException(
    super.message, {
    super.cause,
    super.userMessage =
        "Pip can't reach your calendar. Check the connection in Settings.",
  });
}

/// A task, session or event that does not exist (stale deep link).
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.cause,
    super.userMessage =
        "Pip couldn't find that one. It may have been moved or removed.",
  });
}

/// Input the user can fix.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause, super.userMessage});
}

/// Where errors go. Defaults to the log; the integrator can point it at
/// crash reporting from `main.dart`.
void Function(Object error, StackTrace? stackTrace, {String? context})
errorReporter = _logReporter;

void _logReporter(Object error, StackTrace? stackTrace, {String? context}) {
  log(context ?? 'unhandled error', error: error, stackTrace: stackTrace);
}

/// Report an error that was caught and handled (or is about to be shown).
void reportError(Object error, [StackTrace? stackTrace, String? context]) {
  errorReporter(error, stackTrace, context: context);
}
