import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// `Intl.DateTimeFormat().resolvedOptions().timeZone`, or null when the
/// browser does not expose it.
Future<String?> readDeviceTimeZone() async {
  final intl = globalContext.getProperty<JSObject?>('Intl'.toJS);
  if (intl == null) return null;
  final ctor = intl.getProperty<JSFunction?>('DateTimeFormat'.toJS);
  if (ctor == null) return null;
  final format = ctor.callAsConstructor<JSObject>();
  final options = format.callMethod<JSObject>('resolvedOptions'.toJS);
  final zone = options.getProperty<JSString?>('timeZone'.toJS);
  return zone?.toDart;
}
