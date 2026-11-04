import 'hard_mode_selection.dart';

/// Where hard mode is right now, for the opt-in sheet, the focus screen's
/// "Hard mode on · N apps shielded" line, and Settings. Four coarse phases
/// instead of three booleans, so the UI reads one value and switches on it.
///
/// Derived — never mutated. Build with [HardModeStatus.fromSelection], which
/// takes the stored user choice ([HardModeSelection]) and the current
/// Family Controls authorization. See #45 and `hard_mode_shield_service.dart`.
enum HardModePhase {
  /// The user has not turned hard mode on, or the platform can't shield
  /// (web, Android, desktop). No prompt, no shield, no copy about either.
  off,

  /// The user turned hard mode on but Family Controls has not granted
  /// permission yet (never asked, or they declined). UI shows the
  /// explainer and a "Grant access" action.
  unauthorized,

  /// Authorized, but no apps picked yet. UI shows the picker CTA.
  authorizedIdle,

  /// Authorized AND at least one app picked. The shield installs on the
  /// next focus start and the summary line reads
  /// "Hard mode on · [shieldedCount] apps shielded".
  shielded,
}

/// Immutable snapshot of hard mode's user-facing state.
class HardModeStatus {
  const HardModeStatus._({required this.phase, this.shieldedCount = 0});

  /// Nothing to show. The default for a fresh install and for platforms
  /// where hard mode is hidden.
  static const off = HardModeStatus._(phase: HardModePhase.off);

  /// The user turned the switch on but Family Controls is not authorized.
  static const unauthorized = HardModeStatus._(
    phase: HardModePhase.unauthorized,
  );

  /// Authorized but no apps picked. The picker CTA state.
  static const authorizedIdle = HardModeStatus._(
    phase: HardModePhase.authorizedIdle,
  );

  /// Actively shielding [count] apps. [count] must be at least 1 — a
  /// zero-count shielded state is not meaningful; use [authorizedIdle].
  factory HardModeStatus.shielded(int count) {
    assert(count > 0, 'HardModeStatus.shielded needs at least one app');
    return HardModeStatus._(
      phase: HardModePhase.shielded,
      shieldedCount: count,
    );
  }

  final HardModePhase phase;

  /// How many apps the shield covers. Zero in every phase except
  /// [HardModePhase.shielded].
  final int shieldedCount;

  /// True when the shield is (or is about to be) installed. Drives the
  /// summary line and the "Hard mode on" chip on the focus screen.
  bool get isShielding => phase == HardModePhase.shielded;

  /// True when the opt-in UI should route the user to the Family Controls
  /// prompt. The selection is on but the OS hasn't said yes yet.
  bool get needsAuthorization => phase == HardModePhase.unauthorized;

  /// Derive the phase from the stored user choice and the current
  /// Family Controls authorization.
  ///
  /// Rules, in order:
  /// 1. [HardModeSelection.enabled] is false → [HardModePhase.off].
  /// 2. Enabled but not [authorized] → [HardModePhase.unauthorized].
  /// 3. Enabled, authorized, no tokens → [HardModePhase.authorizedIdle].
  /// 4. Enabled, authorized, tokens present → [HardModePhase.shielded]
  ///    with [HardModeSelection.shieldedCount].
  ///
  /// Pass [authorized] false on platforms that can't shield (web, Android,
  /// desktop) so an enabled selection reads as [HardModePhase.unauthorized]
  /// rather than pretending the shield is live.
  factory HardModeStatus.fromSelection(
    HardModeSelection selection, {
    required bool authorized,
  }) {
    if (!selection.enabled) return HardModeStatus.off;
    if (!authorized) return HardModeStatus.unauthorized;
    if (selection.applicationTokens.isEmpty) {
      return HardModeStatus.authorizedIdle;
    }
    return HardModeStatus.shielded(selection.shieldedCount);
  }

  @override
  bool operator ==(Object other) =>
      other is HardModeStatus &&
      other.phase == phase &&
      other.shieldedCount == shieldedCount;

  @override
  int get hashCode => Object.hash(phase, shieldedCount);

  @override
  String toString() => 'HardModeStatus($phase, shieldedCount: $shieldedCount)';
}
