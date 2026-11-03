/// The marker that ties an Apple Calendar event to the Grind task it was
/// written back from. Stored twice so either survives a user edit:
/// the URL field holds `grind://task/<taskId>` (set by the Swift plugin) and
/// the notes end with `grindTaskId:<taskId>` (built here).
abstract final class WriteBackMarker {
  static const notesPrefix = 'grindTaskId:';
  static const urlScheme = 'grind';
  static const urlHost = 'task';

  static final _notesPattern = RegExp(r'grindTaskId:(\S+)');

  /// The notes to store on the event: the task's own notes, then the marker.
  static String notesFor({required String taskId, String? taskNotes}) {
    final marker = '$notesPrefix$taskId';
    final own = taskNotes?.trim();
    return own == null || own.isEmpty ? marker : '$own\n\n$marker';
  }

  static String urlFor(String taskId) =>
      Uri(scheme: urlScheme, host: urlHost, pathSegments: [taskId]).toString();

  /// The task id in [url] or [notes], or null for an ordinary event.
  /// The URL wins: users rarely edit it, while notes are free text.
  static String? parse({String? url, String? notes}) {
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null &&
          uri.scheme == urlScheme &&
          uri.host == urlHost &&
          uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }
    if (notes != null) {
      final match = _notesPattern.allMatches(notes).lastOrNull;
      if (match != null) return match.group(1);
    }
    return null;
  }
}
