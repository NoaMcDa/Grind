/// Home-screen widget bridge (#23). The pure-Dart layer: the snapshot the
/// iOS widget extension reads through the App Group, and a builder that
/// composes it from the notification plan and the momentum score. The
/// `saveWidgetData` call and the Swift widget come in later slices.
library;

export 'widget_snapshot.dart';
export 'widget_snapshot_builder.dart';
export 'widget_snapshot_delta.dart';
