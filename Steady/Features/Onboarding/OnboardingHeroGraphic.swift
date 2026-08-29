//
//  OnboardingHeroGraphic.swift
//  Steady
//
//  The welcome screen's hero, per design reference §7.1.
//

import SwiftUI

/// Eight noisy readings and one calm line — the product in one picture, and the
/// drawing the app mark is reduced from.
///
/// Authored at `306 × 104`. Every coordinate below is literal at that size and
/// the whole drawing scales uniformly with the container, so the curve keeps its
/// relationship to the dots at any width.
///
/// It sits **flush left**. In the source the wrapper is `margin: 40px 0 auto`
/// — the horizontal margins are zero — inside a flex column with no
/// `text-align`, so the `306`-wide drawing hangs off the leading edge of the
/// content column and the slack is trailing. At the authored `402` pt width the
/// column is `354`, so there is `48` pt of slack on the right and none on the
/// left. Narrower than `306` and the drawing scales down to fit; wider and it
/// stays `306`.
struct OnboardingHeroGraphic: View {

    /// The size the design reference specifies, and the coordinate space every
    /// value here is expressed in.
    private static let designSize = CGSize(width: 306, height: 104)

    /// Radius `4`, in `raw`.
    private static let dotRadius: CGFloat = 4

    private static let dots: [CGPoint] = [
        CGPoint(x: 8, y: 76),
        CGPoint(x: 50, y: 52),
        CGPoint(x: 92, y: 82),
        CGPoint(x: 134, y: 44),
        CGPoint(x: 176, y: 64),
        CGPoint(x: 218, y: 32),
        CGPoint(x: 260, y: 52),
        CGPoint(x: 298, y: 20)
    ]

    /// `M8 72 C 90 62, 200 42, 298 26` — one cubic, stroke `5`, round caps.
    private static var curve: Path {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: 72))
        path.addCurve(
            to: CGPoint(x: 298, y: 26),
            control1: CGPoint(x: 90, y: 62),
            control2: CGPoint(x: 200, y: 42)
        )
        return path
    }

    var body: some View {
        Canvas { context, size in
            context.scaleBy(
                x: size.width / Self.designSize.width,
                y: size.height / Self.designSize.height
            )

            for dot in Self.dots {
                let box = CGRect(
                    x: dot.x - Self.dotRadius,
                    y: dot.y - Self.dotRadius,
                    width: Self.dotRadius * 2,
                    height: Self.dotRadius * 2
                )
                context.fill(Path(ellipseIn: box), with: .color(Palette.raw))
            }

            context.stroke(
                Self.curve,
                with: .color(Palette.ac),
                style: StrokeStyle(lineWidth: Metrics.heroCurveWidth, lineCap: .round)
            )
        }
        .aspectRatio(Self.designSize.width / Self.designSize.height, contentMode: .fit)
        .frame(maxWidth: Self.designSize.width)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityAddTraits(.isImage)
        .accessibilityLabel("Scattered daily readings with one smooth line drawn through them")
    }
}

#Preview("Light") {
    OnboardingHeroGraphic()
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingHeroGraphic()
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
