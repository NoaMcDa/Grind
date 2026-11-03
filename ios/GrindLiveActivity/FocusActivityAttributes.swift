import Foundation

#if canImport(ActivityKit)
  import ActivityKit

  /// The focus session as ActivityKit sees it. Compiled into BOTH targets:
  /// Runner (LiveActivityPlugin starts and updates it) and GrindLiveActivity
  /// (the widget extension draws it). Keep the two in sync by keeping this
  /// one file in both targets' "Target Membership".
  /// See docs/adr/0007-live-activity.md.
  @available(iOS 16.1, *)
  struct FocusActivityAttributes: ActivityAttributes {
    /// Changes during the session (pause, resume, +5 min).
    public struct ContentState: Codable, Hashable {
      /// Lower bound of the countdown range; never after [endDate].
      var startDate: Date
      /// When the timer reaches zero if it keeps running.
      var endDate: Date
      /// Set while paused: the countdown freezes at `endDate - pausedAt`.
      var pausedAt: Date?

      var isPaused: Bool { pausedAt != nil }

      /// Remaining time while paused, for the static label.
      var frozenRemaining: TimeInterval {
        guard let pausedAt else { return 0 }
        return max(0, endDate.timeIntervalSince(pausedAt))
      }
    }

    /// Fixed for the whole session.
    var taskTitle: String
    /// Pip's cosmetic: none, scarf, sunglasses, partyHat, rainBoots, crown
    /// (`PipAccessory` names in lib/widgets/pip_avatar.dart).
    var accessory: String
    /// Status words in the user's language, sent by the Dart side.
    var focusingLabel: String
    var pausedLabel: String
  }
#endif
