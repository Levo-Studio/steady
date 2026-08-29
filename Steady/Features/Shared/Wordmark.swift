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
        HStack(spacing: Metrics.wordmarkGap) {
            Mark(size: markSize)
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
