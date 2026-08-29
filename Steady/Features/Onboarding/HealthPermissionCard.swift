//
//  HealthPermissionCard.swift
//  Steady
//
//  The two-row card on the health-access screen, per design reference §7.2.
//

import SwiftUI

/// What the system sheet is about to ask for, shown before it appears.
///
/// The toggles in it are **illustrative**. They are drawn in their on state
/// because that is what the sheet will offer, and they are not controls: they
/// hold no state, they are not tappable, and they cannot be reached by
/// VoiceOver as anything but part of the row's description. The only thing on
/// this screen that changes authorisation is the button below it.
struct HealthPermissionCard: View {

    /// The row's vertical padding. `16` is off the spacing scale and is
    /// specified literally in design reference §7.2 — the card's own `8` and the
    /// row's `16` are what give the two rows their `60`-ish height inside a
    /// `28` pt radius.
    private static let rowVerticalPadding: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            row(title: "Read weight", subtitle: "Stays on your phone")

            // A divider under the first row only: it separates the two rows,
            // it does not box them in.
            Rectangle()
                .fill(Palette.line)
                .frame(height: Metrics.hairline)

            row(title: "Write weight", subtitle: "To save what you log")
        }
        .padding(.vertical, Metrics.space2)
        .padding(.horizontal, Metrics.space4)
        .background(Palette.sur, in: .rect(cornerRadius: Metrics.radiusCard))
    }

    private func row(title: String, subtitle: String) -> some View {
        HStack(spacing: Metrics.space3) {
            VStack(alignment: .leading, spacing: Metrics.space1) {
                Text(title)
                    .steadyTextStyle(.healthRowTitle)
                    .foregroundStyle(Palette.ink)
                Text(subtitle)
                    .steadyTextStyle(.healthRowSubtitle)
                    .foregroundStyle(Palette.mut)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Metrics.space3)

            HealthToggleGlyph()
        }
        .padding(.vertical, Self.rowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle). Will be requested.")
    }
}

/// The on-state toggle from design reference §4: a `51 × 31` pill in `ac` with a
/// white knob of `27`, inset `2`.
///
/// The knob is `Palette.toggleKnob`, which is white in both themes — see the
/// token for why it is not `acink`.
private struct HealthToggleGlyph: View {

    var body: some View {
        Capsule()
            .fill(Palette.ac)
            .frame(width: Metrics.toggleSize.width, height: Metrics.toggleSize.height)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(Palette.toggleKnob)
                    .frame(
                        width: Metrics.toggleKnobDiameter,
                        height: Metrics.toggleKnobDiameter
                    )
                    .padding(Metrics.toggleInset)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    HealthPermissionCard()
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HealthPermissionCard()
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
