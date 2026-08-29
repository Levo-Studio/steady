//
//  PrimaryButton.swift
//  Steady
//
//  The 60 pt pill button, per design reference §4, §7.1, §7.4 and §7.5.
//

import SwiftUI

/// The full-width primary action.
///
/// Three fills, and the split between the first two is deliberate: `ink` is the
/// neutral primary used in onboarding, `ac` is the committing action inside the
/// app — Save and Update. They are not unified. The `ink` label also carries
/// −0.01em tracking where the accent label carries none.
struct PrimaryButton<Label: View>: View {

    enum Fill {
        /// Onboarding's neutral primary: `ink` fill, `bg` label.
        case ink
        /// The committing action: `ac` fill, `acink` label.
        case accent
        /// A 1 pt `line` border, no fill, `ink` label. "Edit today's weight".
        case outline
    }

    let fill: Fill
    let action: () -> Void
    @ViewBuilder let label: Label

    var body: some View {
        Button(action: action) {
            label
                .steadyTextStyle(textStyle)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.primaryButtonHeight)
                .background(background, in: .capsule)
                .overlay {
                    if fill == .outline {
                        Capsule().strokeBorder(Palette.line, lineWidth: Metrics.hairline)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private var textStyle: SteadyTextStyle {
        fill == .accent ? .primaryButtonAccent : .primaryButtonInk
    }

    private var foreground: Color {
        switch fill {
        case .ink: Palette.bg
        case .accent: Palette.acink
        case .outline: Palette.ink
        }
    }

    private var background: Color {
        switch fill {
        case .ink: Palette.ink
        case .accent: Palette.ac
        case .outline: .clear
        }
    }
}

extension PrimaryButton where Label == Text {
    init(_ title: String, fill: Fill, action: @escaping () -> Void) {
        self.fill = fill
        self.action = action
        self.label = Text(title)
    }
}

#Preview("Light") {
    VStack(spacing: Metrics.space3) {
        PrimaryButton("Start weighing", fill: .ink) {}
        PrimaryButton(fill: .accent) {} label: {
            HStack(spacing: Metrics.space1) {
                Text("Save")
                Text("72.4").monospacedDigit()
                Text("kg")
            }
        }
        PrimaryButton("Edit today's weight", fill: .outline) {}
    }
    .padding(Metrics.space4)
    .background(Palette.bg)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: Metrics.space3) {
        PrimaryButton("Allow in Apple Health", fill: .ink) {}
        PrimaryButton("Update", fill: .accent) {}
        PrimaryButton("Edit today's weight", fill: .outline) {}
    }
    .padding(Metrics.space4)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
