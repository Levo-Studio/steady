//
//  TrendHeader.swift
//  Steady
//
//  The headline block and the delta badge from design reference §7.8, and the
//  0.34s entrance they share on a range change (§7.8, §9).
//

import SwiftUI

/// The row above the chart: label, the 64 pt figure, the sub-line, and the
/// badge on the right, all sitting on one baseline.
struct TrendHeader: View {

    let summary: TrendEngine.Summary
    /// Whether there is no history yet. The em dash is `mut`, not `ink` — the
    /// headline is a placeholder, not a value.
    let isEmpty: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.space3) {
            headline
            Spacer(minLength: Metrics.space2)
            badge
        }
        .accessibilityElement(children: .combine)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(summary.label)
                .steadyTextStyle(.cardLabel)
                .foregroundStyle(Palette.mut)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(summary.headline)
                    .steadyTextStyle(.trendHeadline)
                    .foregroundStyle(isEmpty ? Palette.mut : Palette.ink)
                Text("kg")
                    .steadyTextStyle(.trendHeadlineUnit)
                    .foregroundStyle(Palette.mut)
            }
            .padding(.top, Metrics.space2)

            Text(summary.subLine)
                .steadyTextStyle(.cardLabelNumeric)
                .foregroundStyle(Palette.ac)
                .padding(.top, Metrics.space2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headlineAccessibilityLabel)
    }

    private var badge: some View {
        Text(summary.badge)
            .steadyTextStyle(.deltaBadge)
            .foregroundStyle(Palette.acsoftink)
            .padding(.vertical, Metrics.space2)
            .padding(.horizontal, Metrics.space3)
            .background(Palette.acsoft, in: .capsule)
            .fixedSize()
            .accessibilityLabel(badgeAccessibilityLabel)
    }

    /// The `⌀` prefix and the em dash both need saying out loud — neither
    /// survives as a spoken glyph.
    private var headlineAccessibilityLabel: String {
        let label = summary.label.replacingOccurrences(of: "⌀ ", with: "Average ")
        guard summary.currentTrend != nil else {
            return "\(label), no reading yet"
        }
        var spoken = "\(label), \(summary.headline) kilograms"
        // The sub-line is a non-breaking space on the empty state and an empty
        // string on Week, so it is spoken only when it actually says something.
        let subLine = summary.subLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !subLine.isEmpty {
            spoken += ", \(subLine) kilograms"
        }
        return spoken
    }

    private var badgeAccessibilityLabel: String {
        guard summary.perWeek != nil else { return "No change yet" }
        return summary.badge
            .replacingOccurrences(of: "⌀ ", with: "Average ")
            .replacingOccurrences(of: "kg", with: "kilograms")
    }
}

// MARK: - The period-change entrance

/// The one timed animation on this screen: `opacity 0 → 1` with a 6 pt lift over
/// `0.34s`, ease.
///
/// It is driven by a token rather than by the range itself so that re-selecting
/// the range that is already showing replays it — the design keeps three
/// identical keyframe names for exactly that reason. Under Reduce Motion the
/// lift is dropped and the cross-fade remains.
struct PeriodEntrance: ViewModifier {

    /// Bumped on every range tap.
    let token: Int
    /// The distance the block travels. Zero under Reduce Motion.
    let lift: CGFloat

    func body(content: Content) -> some View {
        KeyframeAnimator(
            initialValue: Phase(opacity: 0, lift: lift),
            trigger: token
        ) { phase in
            content
                .opacity(phase.opacity)
                .offset(y: phase.lift)
        } keyframes: { _ in
            KeyframeTrack(\.opacity) {
                LinearKeyframe(
                    1,
                    duration: Metrics.periodChangeDuration,
                    timingCurve: .ease
                )
            }
            KeyframeTrack(\.lift) {
                LinearKeyframe(
                    0,
                    duration: Metrics.periodChangeDuration,
                    timingCurve: .ease
                )
            }
        }
    }

    struct Phase {
        var opacity: Double
        var lift: CGFloat
    }
}

extension View {

    /// Replays the range-change entrance whenever `token` changes.
    func periodEntrance(token: Int, lift: CGFloat) -> some View {
        modifier(PeriodEntrance(token: token, lift: lift))
    }
}

private extension UnitCurve {

    /// CSS `ease`, which is what the concept animates on:
    /// `cubic-bezier(0.25, 0.1, 0.25, 1)`.
    static let ease = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.25, y: 0.1),
        endControlPoint: UnitPoint(x: 0.25, y: 1)
    )
}

// MARK: - Previews

#Preview("Light") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(alignment: .leading, spacing: Metrics.space5) {
        ForEach(Period.allCases) { period in
            TrendHeader(summary: TrendEngine.summary(for: period, trend: trend), isEmpty: false)
        }
        TrendHeader(summary: TrendEngine.summary(for: .week, trend: []), isEmpty: true)
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(alignment: .leading, spacing: Metrics.space5) {
        ForEach(Period.allCases) { period in
            TrendHeader(summary: TrendEngine.summary(for: period, trend: trend), isEmpty: false)
        }
        TrendHeader(summary: TrendEngine.summary(for: .week, trend: []), isEmpty: true)
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.dark)
}
