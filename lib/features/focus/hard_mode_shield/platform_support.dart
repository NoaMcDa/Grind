import 'platform_support_stub.dart'
    if (dart.library.io) 'platform_support_io.dart';

/// True only on iOS. The web build resolves to the stub, so it never imports
/// `dart:io`. iOS below 15 and devices without the Family Controls
/// entitlement are handled on the Swift side (every call returns false or
/// does nothing).
bool supportsHardMode() => isIosPlatform();
