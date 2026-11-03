/// Small key/value document store for notification bookkeeping: the index of
/// scheduled ids and the journal of responses received while the app was not
/// running. File-backed on iOS (see `file_notification_store.dart`), in memory
/// in tests.
abstract interface class NotificationStore {
  /// The stored document, or null if none.
  Future<String?> read(String name);
  Future<void> write(String name, String contents);
  Future<void> delete(String name);
}

class MemoryNotificationStore implements NotificationStore {
  final Map<String, String> docs = {};

  @override
  Future<String?> read(String name) async => docs[name];

  @override
  Future<void> write(String name, String contents) async =>
      docs[name] = contents;

  @override
  Future<void> delete(String name) async => docs.remove(name);
}

/// Document names.
const indexDocument = 'notification_index.json';
const pendingResponsesDocument = 'pending_notification_responses.json';
