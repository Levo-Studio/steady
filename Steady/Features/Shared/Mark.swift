//
//  Mark.swift
//  Steady
//
//  The app mark, per design/steady-design-reference.md §8.
//

import SwiftUI

/// Two concentric circles: an outer ring and a solid centre dot.
///
/// It is the hero graphic of the welcome screen reduced to one glyph — noisy
/// readings around one calm centre. Authored on a 26 pt grid with a ring at
/// `r = 11.6`, stroke `2.6`, and a dot at `r = 4.2`; every value scales from
/// that grid. The mark is `ac` in both themes.
struct Mark: View {

    var size: CGFloat = Metrics.markHeaderSize

    private var scale: CGFloat { size / Metrics.markGrid }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.ac, lineWidth: Metrics.markRingStroke * scale)
                .frame(
                    width: (Metrics.markRingRadius * 2 + Metrics.markRingStroke) * scale,
                    height: (Metrics.markRingRadius * 2 + Metrics.markRingStroke) * scale
                )
            Circle()
                .fill(Palette.ac)
                .frame(
                    width: Metrics.markDotRadius * 2 * scale,
                    height: Metrics.markDotRadius * 2 * scale
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    Mark(size: 64).padding().background(Palette.bg).preferredColorScheme(.light)
}

#Preview("Dark") {
    Mark(size: 64).padding().background(Palette.bg).preferredColorScheme(.dark)
}
