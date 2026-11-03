import 'platform_support_stub.dart'
    if (dart.library.io) 'platform_support_io.dart';

/// True only on iOS. The web build resolves to the stub, so it never imports
/// `dart:io`. iOS below 16.2 is handled on the Swift side (start returns
/// false, update and end do nothing).
bool isLiveActivityPlatform() => isIosPlatform();
