//
//  OnboardingFlowView.swift
//  Steady
//
//  The two-step first-launch flow: design reference §7.1 then §7.2.
//

import SwiftUI

/// Onboarding, start to finish.
///
/// Two screens, no back navigation, no skip on the first one, and no way to see
/// it a second time — `RootView` records completion in the single `UserDefaults`
/// boolean that is the only thing Steady persists outside HealthKit.
///
/// The step change is a plain state change with no animation. Design reference
/// §9 lists the four movements that exist in the product and a screen swap is
/// not one of them, so there is nothing here for Reduce Motion to strip.
struct OnboardingFlowView: View {

    /// Called when onboarding is finished — that is, once the health request
    /// has been answered. A decline completes it too: the user simply lands on
    /// the access-off state.
    let onComplete: () -> Void

    @State private var step: Step = .welcome

    private enum Step {
        case welcome
        case healthAccess
    }

    var body: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView { step = .healthAccess }
        case .healthAccess:
            OnboardingHealthAccessView(onComplete: onComplete)
        }
    }
}

#Preview("Light") {
    OnboardingFlowView {}
        .environment(WeightStore(health: HealthService()))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingFlowView {}
        .environment(WeightStore(health: HealthService()))
        .preferredColorScheme(.dark)
}
