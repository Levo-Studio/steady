//
//  OnboardingHealthAccessView.swift
//  Steady
//
//  Design reference §7.2 — onboarding, health access.
//

import SwiftUI

/// The second and last onboarding step: the one box to tick.
///
/// Both paths off this screen finish onboarding. "Allow in Apple Health"
/// presents the real system sheet first; "Maybe later" does not, and the user
/// lands on the access-off state, which is where access can still be granted.
/// Onboarding is never shown again either way.
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

                PrimaryButton("Allow in Apple Health", fill: .ink, action: requestAccess)
                    .disabled(isRequesting)

                maybeLater
            }
            .multilineTextAlignment(.leading)
        }
    }

    /// 13 pt `mut`, centred, `24` under the button.
    ///
    /// The label is small by design, so the hit area is grown to the 44 pt
    /// minimum with vertical padding and the extra bottom half is then taken
    /// back out of the layout: the text keeps its `24` gap above and its `40`
    /// from the foot of the screen, while the target extends into the padding
    /// below it where there is nothing else to hit.
    private var maybeLater: some View {
        Button {
            onComplete()
        } label: {
            Text("Maybe later")
                .steadyTextStyle(.privacyNote)
                .foregroundStyle(Palette.mut)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Self.hitAreaPadding)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isRequesting)
        .accessibilityLabel("Maybe later")
        .accessibilityHint("Finishes setup without Apple Health access")
        .padding(.top, Metrics.space4 - Self.hitAreaPadding)
        .padding(.bottom, -Self.hitAreaPadding)
    }

    /// Half the difference between a 13 pt line and a 44 pt target, rounded up.
    private static let hitAreaPadding: CGFloat = 14

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
