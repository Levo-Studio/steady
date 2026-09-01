//
//  OnboardingHealthAccessView.swift
//  Steady
//
//  Design reference §7.2 — onboarding, health access.
//

import SwiftUI

/// The second and last onboarding step: the one box to tick.
///
/// The screen has one way out: "Continue" presents the real system sheet and
/// onboarding finishes once it is answered, granted or not. A denial lands on
/// the access-off state, which is where access can still be granted later.
/// Onboarding is never shown again.
struct OnboardingHealthAccessView: View {

    let onComplete: () -> Void

    @Environment(WeightStore.self) private var store

    /// Guards against a second tap while the system sheet is coming up.
    @State private var isRequesting = false

    var body: some View {
        OnboardingScreen {
            VStack(alignment: .leading, spacing: 0) {
                Wordmark()

                Spacer()

                Text("One box to tick, then we’re done.")
                    .steadyTextStyle(.onboardingHeadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your weight lives in Apple Health. We never see it — not us, not even Apple. Your data is yours.")
                    .steadyTextStyle(.onboardingBody)
                    .foregroundStyle(Palette.mut)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Metrics.space4)

                HealthPermissionCard()
                    .padding(.top, Metrics.space5)

                Spacer()

                PrimaryButton("Continue", fill: .ink, action: requestAccess)
                    .disabled(isRequesting)
            }
            .multilineTextAlignment(.leading)
        }
    }

    private func requestAccess() {
        guard !isRequesting else { return }
        isRequesting = true
        Task {
            // Onboarding completes whether or not the sheet is granted. A denial
            // is not an error state here — it is the access-off state, which the
            // Trend screen already renders and can request access from. Trapping
            // the user on this screen would be the only way to make it worse.
            await store.requestAuthorization()
            isRequesting = false
            onComplete()
        }
    }
}

#Preview("Light") {
    OnboardingHealthAccessView {}
        .environment(WeightStore(health: HealthService()))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingHealthAccessView {}
        .environment(WeightStore(health: HealthService()))
        .preferredColorScheme(.dark)
}
