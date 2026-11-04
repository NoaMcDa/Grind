/// Hard mode (#45): optional OS-level blocking of chosen apps while a focus
/// session is running. iOS only, through FamilyControls +
/// `ManagedSettingsStore.shield.applications` + DeviceActivity. See
/// `docs/handoff/RESEARCH.md` Part 2A (FamilyControls row) and Part 2C
/// (entitlement).
///
/// The focus controller calls [enable] on start and [disable] on end. Every
/// call is best effort: on web, Android, desktop, tests, iOS below 15 and
/// without the Family Controls entitlement the calls do nothing, and a
/// failure on iOS never reaches the timer. The user always chooses the apps
/// through the system [FamilyActivityPicker], so this interface only sees
/// opaque tokens.
abstract interface class HardModeShieldService {
  /// Ask for the Family Controls authorization (the "Grind would like to
  /// access Screen Time" prompt). Call once when the user turns hard mode on
  /// in settings; the choice is remembered by the OS. Returns true when the
  /// user is now authorized, false when they declined or the platform is
  /// unsupported.
  Future<bool> requestAuthorization();

  /// True when Family Controls is currently authorized for Grind. Reads the
  /// OS state; never prompts.
  Future<bool> isAuthorized();

  /// Shield every app in [applicationTokens] (opaque tokens from the system
  /// picker). Replaces any previous selection: the full set to shield is
  /// passed on every call. An empty list clears the shield, same as
  /// [disable]. Returns true when the shield was installed.
  Future<bool> enable({required List<String> applicationTokens});

  /// Clear the shield. Safe to call when none is installed.
  Future<void> disable();
}

/// Off iOS, and on an iOS build without the entitlement: does nothing. Lets
/// the focus controller call the service unconditionally.
class NoopHardModeShieldService implements HardModeShieldService {
  const NoopHardModeShieldService();

  @override
  Future<bool> requestAuthorization() async => false;

  @override
  Future<bool> isAuthorized() async => false;

  @override
  Future<bool> enable({required List<String> applicationTokens}) async => false;

  @override
  Future<void> disable() async {}
}
