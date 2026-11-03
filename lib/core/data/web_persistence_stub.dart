/// Native platforms: storage is already durable. Always true.
Future<bool> requestPersistentStorage() async => true;

/// Native platforms: storage is already durable. Always true.
Future<bool> isStoragePersisted() async => true;
