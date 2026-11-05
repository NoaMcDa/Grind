import 'hard_mode_selection.dart';

/// A structural diff between two [HardModeSelection]s — did the on/off
/// switch flip, and which application tokens were added or removed
/// between a `before` and an `after`.
///
/// Used by the focus controller and the hard mode settings surface
/// (#45). The user can change their selection in two places — the
/// Family Controls picker (tokens) and the "Hard mode" switch (enabled)
/// — and the shield has to be re-installed whenever either changes
/// while a focus session is running. Rather than re-installing on every
/// tap (an extra IPC round-trip for identity edits), callers diff the
/// previous and next selections and act only on [requiresReinstall].
///
/// The diff is presentation-agnostic; nothing here renders copy. Pure
/// Dart, no I/O, so it unit-tests against hand-built pairs.
class HardModeSelectionDiff {
  const HardModeSelectionDiff._({
    required this.enabledChanged,
    required this.addedTokens,
    required this.removedTokens,
  });

  /// Returns the diff between [before] and [after]. Tokens are compared
  /// as a set — their order in the two lists does not matter, which
  /// matches how `ManagedSettingsStore.shield.applications` is applied
  /// on the Swift side (a set, not an ordered list). A token present in
  /// both inputs appears in neither [addedTokens] nor [removedTokens].
  factory HardModeSelectionDiff.between(
    HardModeSelection before,
    HardModeSelection after,
  ) {
    final beforeTokens = before.applicationTokens.toSet();
    final afterTokens = after.applicationTokens.toSet();
    final added = afterTokens.difference(beforeTokens);
    final removed = beforeTokens.difference(afterTokens);
    return HardModeSelectionDiff._(
      enabledChanged: before.enabled != after.enabled,
      addedTokens: Set.unmodifiable(added),
      removedTokens: Set.unmodifiable(removed),
    );
  }

  /// An empty diff — nothing changed between the two selections.
  static const HardModeSelectionDiff empty = HardModeSelectionDiff._(
    enabledChanged: false,
    addedTokens: <String>{},
    removedTokens: <String>{},
  );

  /// True when the user flipped the hard-mode switch (off → on or
  /// on → off). Independent of token changes.
  final bool enabledChanged;

  /// Tokens that are in `after` but not in `before`. Unmodifiable.
  final Set<String> addedTokens;

  /// Tokens that are in `before` but not in `after`. Unmodifiable.
  final Set<String> removedTokens;

  /// True when at least one token was added or removed. The enabled
  /// flag flipping on its own does not count here — use
  /// [enabledChanged] or [isEmpty] for the full picture.
  bool get tokensChanged => addedTokens.isNotEmpty || removedTokens.isNotEmpty;

  /// True when nothing changed: same enabled flag and the same token
  /// set. The caller can short-circuit and skip the shield call.
  bool get isEmpty =>
      !enabledChanged && addedTokens.isEmpty && removedTokens.isEmpty;

  /// True when at least one field changed. The complement of [isEmpty].
  bool get isNotEmpty => !isEmpty;

  /// True when the focus controller should call the shield service
  /// again. Any change (the switch or the token set) is reason enough:
  /// the Swift side applies the full new token list on every call, so
  /// a token addition or removal both need the same re-install, and
  /// flipping the switch on or off needs an enable or disable call.
  bool get requiresReinstall => isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is HardModeSelectionDiff &&
      other.enabledChanged == enabledChanged &&
      _setsEqual(other.addedTokens, addedTokens) &&
      _setsEqual(other.removedTokens, removedTokens);

  @override
  int get hashCode => Object.hash(
    enabledChanged,
    Object.hashAllUnordered(addedTokens),
    Object.hashAllUnordered(removedTokens),
  );

  @override
  String toString() {
    if (isEmpty) return 'HardModeSelectionDiff(empty)';
    final parts = <String>[];
    if (enabledChanged) parts.add('enabledChanged');
    if (addedTokens.isNotEmpty) parts.add('added: ${addedTokens.length}');
    if (removedTokens.isNotEmpty) {
      parts.add('removed: ${removedTokens.length}');
    }
    return 'HardModeSelectionDiff(${parts.join(', ')})';
  }
}

bool _setsEqual(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
