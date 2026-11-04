import 'platform_support_stub.dart'
    if (dart.library.io) 'platform_support_io.dart';

/// True only on iOS, where WatchConnectivity is available. The web build
/// resolves to the stub, so it never imports `dart:io`. iOS without a
/// paired watch is handled on the Swift side (startSession returns false,
/// update and end do nothing).
bool isWatchConnectivityPlatform() => isIosPlatform();
