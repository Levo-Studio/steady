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

    /// Design reference §7.8: the value and its unit sit `6` apart on a shared
    /// baseline. It is the only 6 in this feature that is not the tab-bar or
    /// period-control gap, and it has no `Metrics` token yet — `Theme/` is not
    /// this feature's to extend, so it is named here rather than left as a
    /// literal at the call site.
    private static let headlineUnitGap: CGFloat = 6

    /// How far the `64` pt figure may shrink before the row would overflow.
    /// See the comment at the call site for where the number comes from.
    private static let headlineMinimumScale: CGFloat = 0.45

    var body: some View {
        // §7.8 says `space-between`, which is a *zero* minimum gap, not a
        // floor. A spacing plus a `minLength` forced 36 pt between the headline
        // and the badge; because the badge is `.fixedSize()` all of it landed on
        // the 64 pt figure, which truncated at 393 pt — the most common iPhone
        // width — and at every width with a three-digit weight.
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            headline
            Spacer()
            badge
        }
        .accessibilityElement(children: .combine)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(summary.label)
                .steadyTextStyle(.cardLabel)
                .foregroundStyle(Palette.mut)

            HStack(alignment: .firstTextBaseline, spacing: Self.headlineUnitGap) {
                Text(summary.headline)
                    .steadyTextStyle(.trendHeadline)
                    .foregroundStyle(isEmpty ? Palette.mut : Palette.ink)
                    // The design is authored at 402 pt and §1 requires it to
                    // hold down to 320. A true `space-between` is enough for a
                    // two-digit weight from 375 up, but not below it and not
                    // for a three-digit one: at 320 the Week row wants 302 pt
                    // of an available 224. The badge is the row's only other
                    // element and truncating it would eat the number in it, so
                    // the figure is what gives — STEADY.md §11 already caps the
                    // display numerals rather than letting them break the
                    // layout. The floor is the worst real case: a 320 pt screen
                    // with a three-digit weight needs the numeral at 0.47 of
                    // its authored width.
                    .lineLimit(1)
                    .minimumScaleFactor(Self.headlineMinimumScale)
                Text("kg")
                    .steadyTextStyle(.trendHeadlineUnit)
                    .foregroundStyle(Palette.mut)
            }
            .padding(.top, Metrics.space2)

            // Week has no sub-line at all (§7.3's empty state keeps its height
            // with a non-breaking space, which only means something if an
            // *empty* string does not). An unconditional `Text("")` still
            // reports a full line box, so Week picked up 8 + 13 pt of dead
            // space that pushed the whole screen down.
            if !summary.subLine.isEmpty {
                Text(summary.subLine)
                    .steadyTextStyle(.cardLabelNumeric)
                    .foregroundStyle(Palette.ac)
                    .padding(.top, Metrics.space2)
            }
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
        // The initial value is the *settled* state, not the start of the
        // animation: a keyframe animator driven by a trigger holds its initial
        // value until the trigger first changes, so starting at zero opacity
        // would leave the headline invisible until the user touched the period
        // control. Each run jumps to the start of the entrance with a
        // `MoveKeyframe` and interpolates back from there.
        KeyframeAnimator(
            initialValue: Phase(opacity: 1, lift: 0),
            trigger: token
        ) { phase in
            content
                .opacity(phase.opacity)
                .offset(y: phase.lift)
        } keyframes: { _ in
            KeyframeTrack(\.opacity) {
                MoveKeyframe(0)
                LinearKeyframe(
                    1,
                    duration: Metrics.periodChangeDuration,
                    timingCurve: .ease
                )
            }
            KeyframeTrack(\.lift) {
                MoveKeyframe(lift)
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
