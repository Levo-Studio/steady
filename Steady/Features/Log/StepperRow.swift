//
//  StepperRow.swift
//  Steady
//
//  The − / + fine adjustment, per design reference §5.
//

import SwiftUI

/// Two `60` pt pills under the ruler.
///
/// Fine-tuning after the drag, not the primary path — which is why they are
/// quiet `sur` fills rather than anything that competes with Save. Each press
/// moves the reading by exactly `0.1` kg and fires one haptic tick, the same
/// detent the ruler makes.
struct StepperRow: View {

    @Binding var value: Double

    @State private var haptics = RulerHaptics()

    var body: some View {
        HStack(spacing: Metrics.space3) {
            // U+2212 MINUS SIGN, not a hyphen: at 26 pt against a `+` of the
            // same weight, a hyphen is visibly short and sits too high.
            button("\u{2212}", steps: -1, label: "Decrease weight")
            button("+", steps: 1, label: "Increase weight")
        }
    }

    private func button(_ glyph: String, steps: Int, label: String) -> some View {
        Button {
            value = RulerGeometry.stepped(value, by: steps)
            haptics.tick()
        } label: {
            Text(glyph)
                .steadyTextStyle(.stepperGlyph)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.stepperButtonHeight)
                .background(Palette.sur, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension SteadyTextStyle {

    /// `26 / 1`, 400. The `−` and `+` glyphs. Design reference §5 specifies the
    /// size on the control rather than in the type table, so it is named here
    /// rather than in `Typography.swift`.
    static let stepperGlyph = Self(size: 26, weight: .regular, relativeTo: .title2)
}

#Preview("Light") {
    @Previewable @State var value = 72.4
    StepperRow(value: $value)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var value = 72.4
    StepperRow(value: $value)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
