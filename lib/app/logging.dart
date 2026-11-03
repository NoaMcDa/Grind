import 'dart:developer' as developer;

/// Tiny logging hook. Shows in DevTools / the browser console; swap the body
/// for a real sink later without touching call sites.
void log(String message, {Object? error, StackTrace? stackTrace}) {
  developer.log(message, name: 'grind', error: error, stackTrace: stackTrace);
}
