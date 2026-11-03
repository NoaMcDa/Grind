import SwiftUI

/// The tokens from lib/theme/tokens.dart that the widget extension needs.
/// The extension cannot read Flutter assets, so the values are copied here.
enum GrindColor {
  static let ground = Color(hex: 0xF5F2FF)
  static let ink = Color(hex: 0x17123A)
  static let muted = Color(hex: 0x5A5478)
  static let violet = Color(hex: 0x5B3DF5)
  static let sun = Color(hex: 0xFFC83D)
  static let mint = Color(hex: 0x2EC4A6)
  static let pink = Color(hex: 0xFF7AB0)
  static let sky = Color(hex: 0x7FC8FF)
}

/// Sticker style: 2.5 pt ink border, hard 3 pt ink shadow, no blur.
enum GrindSticker {
  static let border: CGFloat = 2.5
  static let shadow: CGFloat = 3
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1)
  }
}

/// Display type. Bricolage Grotesque is not bundled in the extension, so the
/// heavy rounded system face stands in for it.
extension Font {
  static func grindDisplay(_ size: CGFloat) -> Font {
    .system(size: size, weight: .heavy, design: .rounded)
  }

  static func grindLabel(_ size: CGFloat) -> Font {
    .system(size: size, weight: .bold, design: .rounded)
  }
}
