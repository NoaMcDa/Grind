/// The user's hard mode choice: whether OS-level app shielding is on, and
/// the opaque Family Controls application tokens from the system
/// `FamilyActivityPicker`. One value object the opt-in UI, a future
/// settings provider, and [HardModeShieldService.enable] all share.
///
/// Immutable. [applicationTokens] is unmodifiable; use [copyWith] to
/// change it. See #45 and `hard_mode_shield_service.dart`.
class HardModeSelection {
  HardModeSelection({
    this.enabled = false,
    List<String> applicationTokens = const [],
  }) : applicationTokens = List.unmodifiable(applicationTokens);

  /// Hard mode off, no tokens picked. The starting state for a new install
  /// and the state after the user clears their selection.
  static const empty = HardModeSelection._raw(
    enabled: false,
    applicationTokens: [],
  );

  const HardModeSelection._raw({
    required this.enabled,
    required this.applicationTokens,
  });

  /// Whether the user has turned hard mode on in settings. Independent of
  /// whether any apps are picked: an enabled selection with no tokens
  /// installs no shield (see [isActive]).
  final bool enabled;

  /// Opaque tokens from `FamilyActivityPicker`. Not stable across devices
  /// or reinstalls; store them per device. Unmodifiable.
  final List<String> applicationTokens;

  /// True when hard mode should actually shield anything: the switch is on
  /// AND at least one app was picked. The focus controller reads this
  /// before calling [HardModeShieldService.enable].
  bool get isActive => enabled && applicationTokens.isNotEmpty;

  /// How many apps the shield would cover. For the opt-in sheet copy
  /// ("Hard mode on · 3 apps shielded").
  int get shieldedCount => applicationTokens.length;

  HardModeSelection copyWith({
    bool? enabled,
    List<String>? applicationTokens,
  }) => HardModeSelection(
    enabled: enabled ?? this.enabled,
    applicationTokens: applicationTokens ?? this.applicationTokens,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'applicationTokens': applicationTokens,
  };

  /// Reads `{"enabled": bool, "applicationTokens": [string, ...]}`.
  /// Throws a [FormatException] on bad shapes. Missing keys read as the
  /// empty default so older stored values keep working.
  factory HardModeSelection.fromJson(Map<String, Object?> json) {
    final enabled = json['enabled'] ?? false;
    if (enabled is! bool) {
      throw const FormatException('Hard mode selection: enabled must be bool.');
    }
    final raw = json['applicationTokens'] ?? const <Object?>[];
    if (raw is! List) {
      throw const FormatException(
        'Hard mode selection: applicationTokens must be a list.',
      );
    }
    final tokens = <String>[];
    for (final t in raw) {
      if (t is! String) {
        throw const FormatException(
          'Hard mode selection: every application token must be a string.',
        );
      }
      tokens.add(t);
    }
    return HardModeSelection(enabled: enabled, applicationTokens: tokens);
  }

  @override
  bool operator ==(Object other) =>
      other is HardModeSelection &&
      other.enabled == enabled &&
      _listsEqual(other.applicationTokens, applicationTokens);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(applicationTokens));

  @override
  String toString() =>
      'HardModeSelection(enabled: $enabled, '
      'applicationTokens: $applicationTokens)';
}

bool _listsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
