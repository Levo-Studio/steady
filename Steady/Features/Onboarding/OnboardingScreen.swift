//
//  OnboardingScreen.swift
//  Steady
//
//  The padding container both onboarding screens sit in,
//  per design reference §1 and §7.1 / §7.2.
//

import SwiftUI

/// An onboarding screen's frame: `80` top, `24` sides, `40` bottom.
///
/// The padding is measured from the **physical** edges of the display, not from
/// the safe area — design reference §1 is explicit about it, because the concept
/// is drawn on the whole 874 pt device frame including the status-bar region.
/// Padding `80` inside the safe area instead would drop the header about 59 pt
/// and take every vertical relationship below it along. So the screen ignores
/// the safe area and pads from the true edge.
///
/// The bottom `40` is measured the same way and still clears the home
/// indicator: the largest bottom inset on any iPhone is `34`, so the content
/// never comes within 6 pt of it.
struct OnboardingScreen<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.top, Metrics.onboardingTop)
            .padding(.horizontal, Metrics.screenSides)
            .padding(.bottom, Metrics.screenBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Palette.bg)
            .ignoresSafeArea()
    }
}

#Preview("Light") {
    OnboardingScreen {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark()
            Spacer()
            Text("The scale lies. The line doesn’t.")
                .steadyTextStyle(.onboardingHeadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton("Start weighing", fill: .ink) {}
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingScreen {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark()
            Spacer()
            Text("The scale lies. The line doesn’t.")
                .steadyTextStyle(.onboardingHeadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton("Start weighing", fill: .ink) {}
        }
    }
    .preferredColorScheme(.dark)
}
