//
//  Metrics.swift
//  Steady
//
//  The spacing scale, radii and control heights from
//  design/steady-design-reference.md §1, §4, §5 and §7.
//

import CoreGraphics

/// Every gap, radius and control height in the product.
///
/// There is exactly one spacing scale, base 14, each step ×1.68. If a layout
/// wants 12, 16 or 20 it is off the scale — the nearest scale value is correct.
nonisolated enum Metrics {

    // MARK: - Spacing scale (design reference §4)

    /// `5` — tab bar padding.
    static let space1: CGFloat = 5
    /// `8` — the tight gap: value to unit, sub-lines, sheet button column.
    static let space2: CGFloat = 8
    /// `14` — the base step: stepper gap, stats grid offset, sheet body.
    static let space3: CGFloat = 14
    /// `24` — the standard block gap and side padding.
    static let space4: CGFloat = 24
    /// `40` — the large block gap and bottom padding.
    static let space5: CGFloat = 40
    /// `67` — the ruler container height.
    static let space6: CGFloat = 67

    // MARK: - Radii (design reference §4)

    /// Cards and the delete confirmation sheet.
    static let radiusCard: CGFloat = 28
    /// The app-icon tile (concept sheet only).
    static let radiusIconTile: CGFloat = 26
    /// The 2×2 stats grid.
    static let radiusStatsGrid: CGFloat = 24
    /// Buttons, tab bar, segmented control, badges, needle, toggles.
    static let radiusPill: CGFloat = 100

    // MARK: - Control heights (design reference §4)

    /// Save / Update / Start weighing / Allow, and the outlined Edit button.
    static let primaryButtonHeight: CGFloat = 60
    /// The − and + buttons.
    static let stepperButtonHeight: CGFloat = 60
    /// "Delete entry" / "Keep it".
    static let sheetButtonHeight: CGFloat = 56
    /// A tab bar item.
    static let tabItemHeight: CGFloat = 44
    /// The tab bar's own padding, giving a 54 pt container.
    static let tabBarPadding: CGFloat = 5
    /// The gap between the two tab items.
    static let tabBarGap: CGFloat = 6
    /// A period segment.
    static let periodSegmentHeight: CGFloat = 36
    /// The period control's padding, giving a 44 pt container.
    static let periodControlPadding: CGFloat = 4
    /// The gap between period segments.
    static let periodControlGap: CGFloat = 6
    /// The "Apple Health access is off" banner.
    static let accessBannerHeight: CGFloat = 48
    /// Horizontal padding inside the access-off banner.
    static let accessBannerPadding: CGFloat = 20

    /// The illustrative Health toggles in onboarding.
    static let toggleSize = CGSize(width: 51, height: 31)
    static let toggleKnobDiameter: CGFloat = 27
    static let toggleInset: CGFloat = 2

    /// The check circle on the already-logged state.
    static let checkCircleDiameter: CGFloat = 56

    // MARK: - Onboarding hero (design reference §7.1)

    /// The accent curve through the hero's dots. Numerically the same as the
    /// chart's `trendLineWidth`, deliberately kept separate: the hero is §7.1
    /// and the trend polyline is §7.8, and a change to one must not move the
    /// other.
    static let heroCurveWidth: CGFloat = 5

    // MARK: - Screen padding (design reference §1)

    /// `70` top, `24` sides, `40` bottom.
    static let screenTop: CGFloat = 70
    static let screenSides: CGFloat = 24
    static let screenBottom: CGFloat = 40

    /// Onboarding sits `80` from the top instead of `70`.
    static let onboardingTop: CGFloat = 80

    /// The width the design is authored at: `402 − 24 − 24`.
    static let contentWidth: CGFloat = 354

    // MARK: - Strokes

    /// Borders are always exactly 1 pt in `line`.
    static let hairline: CGFloat = 1

    // MARK: - Chart (design reference §7.8)

    /// `354 − 24 − 24` card padding.
    static let chartWidth: CGFloat = 306
    static let chartHeight: CGFloat = 140
    /// The trend polyline.
    static let trendLineWidth: CGFloat = 5
    /// The thin polyline through the raw readings.
    static let rawLineWidth: CGFloat = 1.5
    // The chart's value-range padding factor is not here: it belongs to the
    // maths that applies it, as `ChartGeometry.defaultPadFactor`.
    /// The empty state's dashed baseline.
    static let emptyBaselineY: CGFloat = 118
    static let emptyBaselineDash: [CGFloat] = [6, 7]
    static let emptyBaselineOpacity: Double = 0.5

    // MARK: - Ruler (design reference §5)

    /// The tick strip.
    static let rulerStripHeight: CGFloat = 40
    /// The strip plus its labels.
    static let rulerContainerHeight: CGFloat = 67
    static let rulerTickCount = 25
    /// The x of tick 0 at the authored width.
    static let rulerTickOrigin: CGFloat = 7
    /// One tick = 0.1 kg = 14.2 pt. This is the drag conversion constant.
    static let rulerTickSpacing: CGFloat = 14.2
    static let rulerMajorTickHeight: CGFloat = 30
    static let rulerMinorTickHeight: CGFloat = 16
    static let rulerTickWidth: CGFloat = 1.5
    static let needleWidth: CGFloat = 3
    static let needleHeight: CGFloat = 48
    /// The needle overhangs the strip by 8 pt at the top.
    static let needleTopOverhang: CGFloat = 8
    /// Half the visible window, so the labels read `value ∓ 1.2`.
    static let rulerHalfWindow: Double = 1.2

    // MARK: - The mark (design reference §8)

    /// The mark is drawn on a 26 pt grid.
    static let markGrid: CGFloat = 26
    static let markRingRadius: CGFloat = 11.6
    static let markRingStroke: CGFloat = 2.6
    static let markDotRadius: CGFloat = 4.2
    /// The mark's size in the in-app header lockup.
    static let markHeaderSize: CGFloat = 24
    /// The gap between the mark and the wordmark.
    static let wordmarkGap: CGFloat = 12

    // MARK: - Motion (design reference §9)

    /// The only timed animation in the product: the period change.
    static let periodChangeDuration: Double = 0.34
    /// The lift that accompanies it, dropped under Reduce Motion.
    static let periodChangeLift: CGFloat = 6

    // MARK: - Delete confirmation (design reference §7.7)

    static let sheetBlurRadius: CGFloat = 3
    static let sheetBackdropOpacity: Double = 0.55
    /// The design specifies `0 −14px 60px`, and a CSS blur radius is about
    /// twice the Gaussian sigma. `.shadow(radius:)` *is* the sigma, so the
    /// 60 pt blur is a 30 pt radius here. This is the only shadow in the
    /// product; getting it wrong makes it twice as diffuse as designed.
    static let sheetShadowRadius: CGFloat = 30
    static let sheetShadowOffsetY: CGFloat = -14
}
