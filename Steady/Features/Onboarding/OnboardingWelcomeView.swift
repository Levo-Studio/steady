//
//  OnboardingWelcomeView.swift
//  Steady
//
//  Design reference §7.1 — onboarding, welcome.
//

import SwiftUI

/// The first thing anybody sees, once ever.
///
/// It makes one argument — the daily number is noise, the line is the signal —
/// and it makes it with the hero graphic rather than with more copy.
struct OnboardingWelcomeView: View {

    /// Moves to the health-access step.
    let onContinue: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(alignment: .leading, spacing: 0) {
                header

                Spacer()

                Text("The scale lies. The line doesn’t.")
                    .steadyTextStyle(.onboardingHeadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Pasta, salt, a long flight — the scale reacts to all of it. Steady smooths it out and leaves you one honest line.")
                    .steadyTextStyle(.onboardingBody)
                    .foregroundStyle(Palette.mut)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Metrics.space4)

                // `margin: 40 0 auto` — the graphic hangs off the body, and the
                // free space below it is what pushes the privacy note and the
                // button to the foot of the screen.
                OnboardingHeroGraphic()
                    .padding(.top, Metrics.space5)

                Spacer()

                privacyNote
                    .padding(.top, Metrics.space4)

                PrimaryButton("Start weighing", fill: .ink, action: onContinue)
                    .padding(.top, Metrics.space4)
            }
            .multilineTextAlignment(.leading)
        }
    }

    /// The lockup on the left, the credit on the right, baselines aligned.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Wordmark()
            Spacer(minLength: Metrics.space3)
            Text("A product by Levo Studio")
                .steadyTextStyle(.credit)
                .foregroundStyle(Palette.mut)
        }
    }

    /// Two lines, centred. The claim the whole product rests on, so it sits
    /// directly above the button rather than in a footnote somewhere.
    private var privacyNote: some View {
        VStack(spacing: 0) {
            Text("Your weight stays in Apple Health.")
            Text("Nobody can read it — not Apple, not us.")
        }
        .steadyTextStyle(.privacyNote)
        .foregroundStyle(Palette.mut)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    OnboardingWelcomeView {}
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingWelcomeView {}
        .preferredColorScheme(.dark)
}
