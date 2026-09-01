//
//  AccessOffBanner.swift
//  Steady
//
//  The one row that separates design reference §7.9 from §7.8.
//

import SwiftUI

/// "Apple Health access is off" with an "Allow" that asks Apple Health again,
/// and falls through to Settings once the system sheet is spent.
///
/// It sits between the stats grid and the tab bar and changes nothing else about
/// the screen — the Trend screen keeps working, it simply has nothing to show.
struct AccessOffBanner: View {

    let onAllow: () -> Void

    /// STEADY.md §11: grow the target, never the drawing. "Allow" draws at
    /// about `34 × 13`, so the label is padded past `44` in both axes, given
    /// the hit shape there, and pulled back by the same amount — the banner
    /// still measures `48` and the text still sits `20` from the edge. Putting
    /// a `minHeight` on the row instead would expand the banner and leave the
    /// button its intrinsic height, which is the mistake §11 names.
    private static let tapTargetPad: CGFloat = 16

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
                    .padding(Self.tapTargetPad)
                    .contentShape(.rect)
                    .padding(-Self.tapTargetPad)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Allow")
            .accessibilityHint("Asks Apple Health for access again, or opens Settings")
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
