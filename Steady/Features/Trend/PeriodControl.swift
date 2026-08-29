//
//  PeriodControl.swift
//  Steady
//
//  The three-segment range control from design reference §7.8.
//

import SwiftUI

/// Week · Month · Year.
///
/// The container is filled `bg`, not `sur` — it is inset inside a `sur` card, so
/// the segment track is the screen colour showing through. Getting this the
/// other way round makes the control disappear.
struct PeriodControl: View {

    @Binding var selection: Period

    /// Called on every tap, including a tap on the range that is already
    /// selected. The design keeps three separate keyframe names purely so that
    /// re-selecting a range re-triggers the entrance animation, so a repeat tap
    /// is a real event here rather than a no-op.
    var onSelect: (Period) -> Void = { _ in }

    var body: some View {
        HStack(spacing: Metrics.periodControlGap) {
            ForEach(Period.allCases) { period in
                let isSelected = period == selection
                Button {
                    selection = period
                    onSelect(period)
                } label: {
                    Text(period.title)
                        .steadyTextStyle(.periodSegment)
                        .foregroundStyle(isSelected ? Palette.bg : Palette.mut)
                        .frame(maxWidth: .infinity)
                        .frame(height: Metrics.periodSegmentHeight)
                        .background(isSelected ? Palette.ink : .clear, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(period.title)
                .accessibilityHint("Shows the \(period.title.lowercased()) range")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(Metrics.periodControlPadding)
        .background(Palette.bg, in: .capsule)
    }
}

// MARK: - Previews

#Preview("Light") {
    @Previewable @State var period = Period.week
    PeriodControl(selection: $period)
        .padding(Metrics.space4)
        .background(Palette.sur)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var period = Period.year
    PeriodControl(selection: $period)
        .padding(Metrics.space4)
        .background(Palette.sur)
        .preferredColorScheme(.dark)
}
