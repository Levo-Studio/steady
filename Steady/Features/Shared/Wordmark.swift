//
//  Wordmark.swift
//  Steady
//
//  The in-app header lockup, per design reference §7.1 and §8.
//

import SwiftUI

/// The mark with "steady" set beside it.
///
/// Lowercase, Helvetica Neue 500 at −0.03em in `ink`, with the mark to its left
/// and a `12` pt gap. Used in the onboarding header; it is not a title bar and
/// never repeats inside the app's two destinations.
struct Wordmark: View {

    var markSize: CGFloat = Metrics.markHeaderSize

    var body: some View {
        // Design reference §7.1: the lockup is baseline-aligned, not centred.
        // The mark has no text baseline of its own; in the source it is an
        // inline SVG, whose baseline is its bottom edge, so that is the guide
        // it publishes here.
        HStack(alignment: .firstTextBaseline, spacing: Metrics.wordmarkGap) {
            Mark(size: markSize)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
            Text("steady")
                .steadyTextStyle(.wordmark)
                .foregroundStyle(Palette.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steady")
    }
}

#Preview("Light") {
    Wordmark().padding().background(Palette.bg).preferredColorScheme(.light)
}

#Preview("Dark") {
    Wordmark().padding().background(Palette.bg).preferredColorScheme(.dark)
}
