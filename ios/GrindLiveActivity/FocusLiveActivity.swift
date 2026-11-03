import ActivityKit
import SwiftUI
import WidgetKit

/// Opens the Focus tab. The empty host keeps `/focus` as the URL path, which
/// go_router matches; must equal `LiveActivityMethods.deepLink` in
/// lib/features/focus/live_activity/method_channel_live_activity_service.dart.
private let focusDeepLink = URL(string: "grind:///focus")!

/// The focus session on the Lock Screen and in the Dynamic Island (#20).
/// Started by ios/Runner/LiveActivityPlugin.swift. The extension's deployment
/// target is iOS 16.2, so no availability checks are needed here.
struct FocusLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusActivityAttributes.self) { context in
      LockScreenView(attributes: context.attributes, state: context.state)
        .activityBackgroundTint(GrindColor.violet)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(focusDeepLink)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          PipView(size: 52, cheering: !context.state.isPaused, accessory: context.attributes.accessory)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Countdown(state: context.state)
            .font(.grindDisplay(30))
            .foregroundColor(GrindColor.sun)
            .frame(maxWidth: 110, alignment: .trailing)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            StatusLabel(attributes: context.attributes, state: context.state)
            Text(context.attributes.taskTitle)
              .font(.system(size: 15, weight: .semibold, design: .rounded))
              .foregroundColor(.white)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ProgressBar(state: context.state)
            .padding(.horizontal, 4)
            .padding(.top, 6)
        }
      } compactLeading: {
        PipView(size: 22, accessory: context.attributes.accessory, simplified: true)
      } compactTrailing: {
        Countdown(state: context.state)
          .font(.grindLabel(14))
          .monospacedDigit()
          .foregroundColor(context.state.isPaused ? .white : GrindColor.sun)
          .frame(maxWidth: 48)
      } minimal: {
        PipView(size: 20, simplified: true)
      }
      .widgetURL(focusDeepLink)
      .keylineTint(GrindColor.sun)
    }
  }
}

// MARK: - Lock Screen

/// Sticker style, like the "Lock Screen preview" on the Focus tab: Pip, the
/// status in sun yellow, the task, and the countdown on a sun sticker with an
/// ink border and a hard ink shadow.
private struct LockScreenView: View {
  let attributes: FocusActivityAttributes
  let state: FocusActivityAttributes.ContentState

  var body: some View {
    HStack(spacing: 12) {
      PipView(size: 52, cheering: !state.isPaused, accessory: attributes.accessory)
      VStack(alignment: .leading, spacing: 3) {
        StatusLabel(attributes: attributes, state: state)
        Text(attributes.taskTitle)
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundColor(.white)
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Countdown(state: state)
        .font(.grindDisplay(26))
        .monospacedDigit()
        .foregroundColor(GrindColor.ink)
        .multilineTextAlignment(.center)
        .frame(width: 96)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(state.isPaused ? Color.white : GrindColor.sun)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(GrindColor.ink, lineWidth: GrindSticker.border)
        )
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(GrindColor.ink)
            .offset(x: GrindSticker.shadow, y: GrindSticker.shadow)
        )
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}

// MARK: - Shared pieces

/// Counts down to `endDate`, or shows the frozen time while paused. The
/// system redraws `Text(timerInterval:)` every second without app updates.
private struct Countdown: View {
  let state: FocusActivityAttributes.ContentState

  var body: some View {
    Text(
      timerInterval: state.startDate...state.endDate,
      pauseTime: state.pausedAt,
      countsDown: true,
      showsHours: false)
  }
}

private struct StatusLabel: View {
  let attributes: FocusActivityAttributes
  let state: FocusActivityAttributes.ContentState

  var body: some View {
    Text(state.isPaused ? attributes.pausedLabel : attributes.focusingLabel)
      .font(.grindLabel(12))
      .textCase(.uppercase)
      .foregroundColor(GrindColor.sun)
  }
}

/// Session progress in the expanded Dynamic Island. Uses the system timer
/// progress while running; a static bar while paused.
private struct ProgressBar: View {
  let state: FocusActivityAttributes.ContentState

  var body: some View {
    Group {
      if let pausedAt = state.pausedAt {
        ProgressView(value: fraction(at: pausedAt))
      } else {
        ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
      }
    }
    .progressViewStyle(.linear)
    .tint(GrindColor.sun)
  }

  private func fraction(at date: Date) -> Double {
    let total = state.endDate.timeIntervalSince(state.startDate)
    guard total > 0 else { return 1 }
    return min(1, max(0, date.timeIntervalSince(state.startDate) / total))
  }
}
