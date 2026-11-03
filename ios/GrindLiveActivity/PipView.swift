import SwiftUI

/// Pip drawn with SwiftUI shapes, a port of the CustomPainter in
/// lib/widgets/pip_avatar.dart: sun-yellow blob, ink outline, oval eyes with
/// glints, pink cheeks, mint leaf. All coordinates are in that file's
/// 100 x 100 box and scaled to `size`, so the two stay easy to compare.
struct PipView: View {
  var size: CGFloat
  /// Arms raised, as on the Focus screen.
  var cheering = false
  /// A `PipAccessory` name; unknown names draw no accessory.
  var accessory = "none"
  /// Very small sizes (minimal Dynamic Island) drop the details that would
  /// turn to noise.
  var simplified = false

  private var unit: CGFloat { size / 100 }

  var body: some View {
    ZStack {
      if cheering && !simplified {
        arms
      }
      sticker(leaf, fill: GrindColor.mint, line: 4)
      line(from: (50, 22), to: (50, 28), width: 4)
      sticker(circle(50, 60, 34), fill: GrindColor.sun, line: simplified ? 7 : 5)
      if !simplified {
        filled(circle(30, 68, 4.5), GrindColor.pink)
        filled(circle(70, 68, 4.5), GrindColor.pink)
      }
      if accessory == "sunglasses" && !simplified {
        sunglasses
      } else {
        eyes
      }
      stroked(smile, width: simplified ? 6 : 4)
      if !simplified {
        accessoryView
      }
    }
    .frame(width: size, height: size)
    .accessibilityElement()
    .accessibilityLabel("Pip")
  }

  // MARK: - Parts

  private var arms: some View {
    ZStack {
      stroked(
        path { p in
          p.move(to: pt(26, 56))
          p.addQuadCurve(to: pt(15, 30), control: pt(12, 46))
          p.move(to: pt(74, 56))
          p.addQuadCurve(to: pt(85, 30), control: pt(88, 46))
        }, width: 3)
      sticker(circle(15, 28, 5), fill: GrindColor.sun, line: 2.5)
      sticker(circle(85, 28, 5), fill: GrindColor.sun, line: 2.5)
    }
  }

  private var leaf: Path {
    path { p in
      p.move(to: pt(50, 22))
      p.addCurve(to: pt(66, 6), control1: pt(50, 12), control2: pt(56, 6))
      p.addCurve(to: pt(50, 22), control1: pt(66, 16), control2: pt(60, 22))
      p.closeSubpath()
    }
  }

  private var eyes: some View {
    ZStack {
      filled(oval(39, 56, 10, 14), GrindColor.ink)
      filled(oval(61, 56, 10, 14), GrindColor.ink)
      if !simplified {
        filled(circle(41, 53, 1.8), .white)
        filled(circle(63, 53, 1.8), .white)
      }
    }
  }

  private var sunglasses: some View {
    ZStack {
      filled(roundedRect(39, 56, 18, 12, 5), GrindColor.ink)
      filled(roundedRect(61, 56, 18, 12, 5), GrindColor.ink)
      line(from: (48, 56), to: (52, 56), width: 2.5)
      line(from: (30, 55), to: (20, 52), width: 2.5)
      line(from: (70, 55), to: (80, 52), width: 2.5)
      line(from: (34, 54), to: (38, 54), width: 1.8, color: GrindColor.sky)
      line(from: (56, 54), to: (60, 54), width: 1.8, color: GrindColor.sky)
    }
  }

  private var smile: Path {
    path { p in
      p.move(to: pt(42, 70))
      p.addQuadCurve(to: pt(58, 70), control: pt(50, 78))
    }
  }

  @ViewBuilder
  private var accessoryView: some View {
    switch accessory {
    case "scarf":
      ZStack {
        sticker(
          path { p in
            p.move(to: pt(22, 80))
            p.addQuadCurve(to: pt(78, 80), control: pt(50, 96))
            p.addLine(to: pt(80, 88))
            p.addQuadCurve(to: pt(20, 88), control: pt(50, 106))
            p.closeSubpath()
          }, fill: GrindColor.violet, line: 2.5)
        sticker(
          path { p in
            p.move(to: pt(64, 92))
            p.addLine(to: pt(71, 104))
            p.addLine(to: pt(62, 106))
            p.addLine(to: pt(57, 94))
            p.closeSubpath()
          }, fill: GrindColor.violet, line: 2.5)
      }
    case "partyHat":
      ZStack {
        sticker(
          path { p in
            p.move(to: pt(26, 38))
            p.addLine(to: pt(37, 6))
            p.addLine(to: pt(52, 30))
            p.closeSubpath()
          }, fill: GrindColor.pink, line: 3)
        line(from: (31, 25), to: (44, 25), width: 2.5, color: GrindColor.violet)
        sticker(circle(37, 6, 4), fill: GrindColor.sun, line: 2.5)
      }
    case "crown":
      ZStack {
        sticker(
          path { p in
            p.move(to: pt(32, 34))
            p.addLine(to: pt(30, 14))
            p.addLine(to: pt(41, 23))
            p.addLine(to: pt(50, 10))
            p.addLine(to: pt(59, 23))
            p.addLine(to: pt(70, 14))
            p.addLine(to: pt(68, 34))
            p.closeSubpath()
          }, fill: GrindColor.violet, line: 3)
        sticker(circle(30, 13, 3.2), fill: GrindColor.sun, line: 2)
        sticker(circle(50, 9, 3.2), fill: GrindColor.sun, line: 2)
        sticker(circle(70, 13, 3.2), fill: GrindColor.sun, line: 2)
      }
    default:
      EmptyView()
    }
  }

  // MARK: - Drawing helpers (100 x 100 box -> size)

  private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x * unit, y: y * unit)
  }

  private func path(_ build: (inout Path) -> Void) -> Path {
    var p = Path()
    build(&p)
    return p
  }

  private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    oval(cx, cy, r * 2, r * 2)
  }

  private func oval(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: (cx - w / 2) * unit, y: (cy - h / 2) * unit, width: w * unit, height: h * unit))
  }

  private func roundedRect(
    _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat
  ) -> Path {
    Path(
      roundedRect: CGRect(
        x: (cx - w / 2) * unit, y: (cy - h / 2) * unit, width: w * unit, height: h * unit),
      cornerRadius: r * unit)
  }

  private func style(_ width: CGFloat) -> StrokeStyle {
    StrokeStyle(lineWidth: width * unit, lineCap: .round, lineJoin: .round)
  }

  private func filled(_ p: Path, _ color: Color) -> some View {
    p.fill(color)
  }

  private func stroked(_ p: Path, width: CGFloat, color: Color = GrindColor.ink) -> some View {
    p.stroke(color, style: style(width))
  }

  private func sticker(_ p: Path, fill: Color, line width: CGFloat) -> some View {
    ZStack {
      p.fill(fill)
      p.stroke(GrindColor.ink, style: style(width))
    }
  }

  private func line(
    from a: (CGFloat, CGFloat), to b: (CGFloat, CGFloat), width: CGFloat,
    color: Color = GrindColor.ink
  ) -> some View {
    stroked(
      path { p in
        p.move(to: pt(a.0, a.1))
        p.addLine(to: pt(b.0, b.1))
      }, width: width, color: color)
  }
}
