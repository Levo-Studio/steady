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

    @Environment(\.motion) private var motion
    /// The control survives a range change, so its pill's namespace can live
    /// here — unlike the tab bar's, whose screen is rebuilt underneath it.
    @Namespace private var pillNamespace

    private static let pillID = "steady.periodControl.pill"

    var body: some View {
        // The container's `4` pt vertical padding lives on each segment rather
        // than on the stack, so the segment's tap target fills the full 44 pt
        // container while the drawn pill stays 36 — STEADY.md §11 names this
        // control specifically: grow the target, never the drawing. The
        // horizontal 4 stays on the stack, where it is not between anything the
        // finger has to hit. Not one pixel moves.
        HStack(spacing: Metrics.periodControlGap) {
            ForEach(Period.allCases) { period in
                let isSelected = period == selection
                Button {
                    // §9: the pill slides with `settle`, and the same
                    // transaction carries the headline's and the stats grid's
                    // numeric transitions — they all describe one range change.
                    withAnimation(motion.settle) {
                        selection = period
                        onSelect(period)
                    }
                } label: {
                    Text(period.title)
                        .steadyTextStyle(.periodSegment)
                        .foregroundStyle(isSelected ? Palette.bg : Palette.mut)
                        .frame(maxWidth: .infinity)
                        .frame(height: Metrics.periodSegmentHeight)
                        .background { if isSelected { pill } }
                        .padding(.vertical, Metrics.periodControlPadding)
                        .contentShape(.rect)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(period.title)
                .accessibilityHint("Shows the \(period.title.lowercased()) range")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, Metrics.periodControlPadding)
        .background(Palette.bg, in: .capsule)
    }

    /// The `ink` fill behind the selected segment — the same view moving
    /// between the three positions, not three capsules cross-fading. Under
    /// Reduce Motion it cross-fades instead, which is the removal §9 names.
    @ViewBuilder
    private var pill: some View {
        if motion.slidesPill {
            Capsule()
                .fill(Palette.ink)
                .matchedGeometryEffect(id: Self.pillID, in: pillNamespace)
        } else {
            Capsule()
                .fill(Palette.ink)
                .transition(.opacity)
        }
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
