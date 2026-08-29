//
//  OnboardingFlowView.swift
//  Steady
//
//  Placeholder. Replaced wholesale by the Onboarding feature, which builds
//  design reference §7.1 and §7.2 here.
//

import SwiftUI

struct OnboardingFlowView: View {

    /// Called when onboarding is finished, by either path. "Maybe later" also
    /// completes it — the user simply lands on the access-off state.
    let onComplete: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Wordmark()
            Spacer()
            PrimaryButton("Start weighing", fill: .ink, action: onComplete)
        }
        .padding(.top, Metrics.onboardingTop)
        .padding(.horizontal, Metrics.screenSides)
        .padding(.bottom, Metrics.screenBottom)
    }
}
