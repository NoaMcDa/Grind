import SwiftUI
import WidgetKit

/// Entry point of the GrindLiveActivity widget extension. Only the focus Live
/// Activity for now; home-screen widgets (phase 2) can join this bundle.
@main
struct GrindLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    FocusLiveActivity()
  }
}
