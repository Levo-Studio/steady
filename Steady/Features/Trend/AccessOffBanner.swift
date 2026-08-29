//
//  AccessOffBanner.swift
//  Steady
//
//  The one row that separates design reference §7.9 from §7.8.
//

import SwiftUI

/// "Apple Health access is off" with an "Allow" that re-presents the system
/// authorisation sheet.
///
/// It sits between the stats grid and the tab bar and changes nothing else about
/// the screen — the Trend screen keeps working, it simply has nothing to show.
struct AccessOffBanner: View {

    let onAllow: () -> Void

    var body: some View {
        HStack(spacing: Metrics.space3) {
            Text("Apple Health access is off")
                .steadyTextStyle(.healthRowSubtitle)
                .foregroundStyle(Palette.mut)
            Spacer(minLength: Metrics.space2)
            Button(action: onAllow) {
                Text("Allow")
                    .steadyTextStyle(.bannerAction)
                    .foregroundStyle(Palette.ac)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Allow")
            .accessibilityHint("Asks Apple Health for access again")
        }
        .padding(.horizontal, Metrics.accessBannerPadding)
        .frame(minHeight: Metrics.accessBannerHeight)
        .frame(maxWidth: .infinity)
        .background(Palette.sur, in: .capsule)
    }
}

// MARK: - Previews

#Preview("Light") {
    AccessOffBanner(onAllow: {})
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AccessOffBanner(onAllow: {})
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
