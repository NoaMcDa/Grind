import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'web_notification_service.dart';

/// `window.Notification`.
@JS('Notification')
extension type _Notification._(JSObject _) implements JSObject {
  external factory _Notification(String title, _Options options);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
  external set onclick(JSFunction? handler);
  external void close();
}

extension type _Options._(JSObject _) implements JSObject {
  external factory _Options({String body, String tag, String icon});
}

@JS('window')
external JSObject get _window;

extension on JSObject {
  external void focus();
}

/// [BrowserNotificationApi] over the browser Notification API via
/// `dart:js_interop` (no `package:web`, which is not a direct dependency).
class JsBrowserNotificationApi implements BrowserNotificationApi {
  @override
  bool get supported => globalContext.has('Notification');

  @override
  String get permission => supported ? _Notification.permission : 'denied';

  @override
  Future<String> requestPermission() async {
    if (!supported) return 'denied';
    final result = await _Notification.requestPermission().toDart;
    return result.toDart;
  }

  @override
  void show({
    required String title,
    required String body,
    required String tag,
    required void Function() onClick,
  }) {
    final n = _Notification(
      title,
      _Options(body: body, tag: tag, icon: 'icons/Icon-192.png'),
    );
    n.onclick = (JSAny? _) {
      _window.focus();
      n.close();
      onClick();
    }.toJS;
  }
}
