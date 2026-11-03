import Flutter
import Foundation

#if canImport(ActivityKit)
  import ActivityKit
#endif

/// Grind's bridge to ActivityKit: the focus timer on the Lock Screen and in
/// the Dynamic Island (#20). Dart side: lib/features/focus/live_activity/.
/// Decision, Xcode steps and manual test plan: docs/adr/0007-live-activity.md.
///
/// Method channel `grind/live_activity` (times are epoch milliseconds):
///   start {taskTitle, endDateMs, accessory, pausedAtMs?, focusingLabel,
///     pausedLabel} -> Bool (false: iOS < 16.2 or Live Activities off)
///   update {paused, endDateMs, pausedAtMs?} -> nil
///   end -> nil
/// All three are safe to call at any time; below iOS 16.2 they do nothing.
/// Errors: FlutterError code `invalidArgs`, `activityKit`.
///
/// `FocusActivityAttributes` lives in ios/GrindLiveActivity/ and is compiled
/// into both the Runner and the GrindLiveActivity extension targets.
final class LiveActivityPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "grind/live_activity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LiveActivityPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "start":
      #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
          start(args, result)
          return
        }
      #endif
      result(false)
    case "update":
      #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
          update(args, result)
          return
        }
      #endif
      result(nil)
    case "end":
      #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
          end(result)
          return
        }
      #endif
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Helpers

  private static func date(_ value: Any?) -> Date? {
    guard let ms = value as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: ms.doubleValue / 1000)
  }

  private static func invalid(_ message: String) -> FlutterError {
    FlutterError(code: "invalidArgs", message: message, details: nil)
  }
}

// MARK: - ActivityKit (iOS 16.2+)

#if canImport(ActivityKit)
  @available(iOS 16.2, *)
  extension LiveActivityPlugin {
    private typealias FocusActivity = Activity<FocusActivityAttributes>

    private func start(_ args: [String: Any], _ result: @escaping FlutterResult) {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        result(false)
        return
      }
      guard let endDate = Self.date(args["endDateMs"]) else {
        result(Self.invalid("start needs endDateMs"))
        return
      }
      let attributes = FocusActivityAttributes(
        taskTitle: args["taskTitle"] as? String ?? "",
        accessory: args["accessory"] as? String ?? "none",
        focusingLabel: args["focusingLabel"] as? String ?? "Focusing",
        pausedLabel: args["pausedLabel"] as? String ?? "Paused")
      let pausedAt = Self.date(args["pausedAtMs"])
      let state = FocusActivityAttributes.ContentState(
        startDate: Self.lowerBound(Date(), endDate, pausedAt),
        endDate: endDate,
        pausedAt: pausedAt)

      Task { @MainActor in
        // One session at a time: replace whatever is still showing (a
        // previous run of the app, or a session ended while killed).
        await Self.endAll()
        do {
          _ = try FocusActivity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: Self.staleDate(state)),
            pushType: nil)
          result(true)
        } catch {
          result(
            FlutterError(
              code: "activityKit", message: error.localizedDescription, details: nil))
        }
      }
    }

    private func update(_ args: [String: Any], _ result: @escaping FlutterResult) {
      guard let endDate = Self.date(args["endDateMs"]) else {
        result(Self.invalid("update needs endDateMs"))
        return
      }
      let paused = args["paused"] as? Bool ?? false
      Task { @MainActor in
        for activity in FocusActivity.activities {
          let pausedAt = paused ? (Self.date(args["pausedAtMs"]) ?? Date()) : nil
          let state = FocusActivityAttributes.ContentState(
            startDate: Self.lowerBound(activity.content.state.startDate, endDate, pausedAt),
            endDate: endDate,
            pausedAt: pausedAt)
          await activity.update(
            ActivityContent(state: state, staleDate: Self.staleDate(state)))
        }
        result(nil)
      }
    }

    private func end(_ result: @escaping FlutterResult) {
      Task { @MainActor in
        await Self.endAll()
        result(nil)
      }
    }

    private static func endAll() async {
      for activity in FocusActivity.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }

    /// `Text(timerInterval:)` traps on an inverted range, and the pause time
    /// should sit inside it: the lower bound is the earliest of the three.
    private static func lowerBound(_ start: Date, _ end: Date, _ pausedAt: Date?) -> Date {
      min(start, end, pausedAt ?? end)
    }

    /// Running: the activity goes stale when the timer reaches zero (iOS dims
    /// it until the app ends it). Paused: never stale on its own.
    private static func staleDate(_ state: FocusActivityAttributes.ContentState) -> Date? {
      state.pausedAt == nil ? state.endDate : nil
    }
  }
#endif
