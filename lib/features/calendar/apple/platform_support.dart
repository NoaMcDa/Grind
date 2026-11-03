import 'platform_support_stub.dart'
    if (dart.library.io) 'platform_support_io.dart';

/// True only on iOS. The web build resolves to the stub, so it never imports
/// `dart:io`.
bool isAppleCalendarPlatform() => isIosPlatform();
