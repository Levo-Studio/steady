//
//  Typography.swift
//  Steady
//
//  Every named text style from design/steady-design-reference.md §3.
//

import SwiftUI
import UIKit

/// A single named text style from the design reference.
///
/// Helvetica Neue throughout, only two weights — 400 Regular and 500 Medium.
/// Tracking is authored in `em` and negative, tightening as the type grows;
/// it is multiplied out against the point size here.
nonisolated struct SteadyTextStyle: Sendable, Equatable {

    enum Weight: Sendable {
        case regular   // 400
        case medium    // 500

        var fontName: String {
            switch self {
            case .regular: "HelveticaNeue"
            case .medium: "HelveticaNeue-Medium"
            }
        }
    }

    /// Point size at the default Dynamic Type setting.
    let size: CGFloat
    /// Line height as a multiple of the size.
    let lineHeight: CGFloat
    let weight: Weight
    /// Letter spacing in `em`, exactly as authored.
    let tracking: CGFloat
    /// Whether the style renders runtime numerals and therefore must not reflow.
    let tabularFigures: Bool
    /// The system text style this scales against.
    let relativeTo: Font.TextStyle
    /// Ceiling on Dynamic Type growth. The display numerals are already the
    /// largest thing on screen, so they scale but are capped rather than
    /// allowed to break the layout.
    let maxDynamicTypeSize: DynamicTypeSize?
    /// Whether the style is set in capitals. Only the "EDIT" eyebrow is.
    let isUppercased: Bool

    init(
        size: CGFloat,
        lineHeight: CGFloat = 1,
        weight: Weight,
        tracking: CGFloat = 0,
        tabularFigures: Bool = false,
        relativeTo: Font.TextStyle = .body,
        maxDynamicTypeSize: DynamicTypeSize? = nil,
        isUppercased: Bool = false
    ) {
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.tracking = tracking
        self.tabularFigures = tabularFigures
        self.relativeTo = relativeTo
        self.maxDynamicTypeSize = maxDynamicTypeSize
        self.isUppercased = isUppercased
    }

    var font: Font {
        var font = Font.custom(weight.fontName, size: size, relativeTo: relativeTo)
        if tabularFigures { font = font.monospacedDigit() }
        return font
    }
}

// MARK: - Resolved metrics

nonisolated extension SteadyTextStyle {

    /// The style's measurements once Dynamic Type has been applied.
    ///
    /// Tracking is authored in `em`, so it has to be multiplied against the
    /// *resolved* point size — `.tracking()` takes absolute points while
    /// `Font.custom(relativeTo:)` scales the glyphs, and using the unscaled
    /// figure leaves the accessibility sizes visibly under-tracked.
    struct Resolved: Equatable, Sendable {
        /// The point size after Dynamic Type scaling.
        var pointSize: CGFloat
        /// The line box the design specifies: `pointSize × lineHeight`.
        var lineBox: CGFloat
        /// The line height Helvetica Neue actually has at `pointSize`
        /// — roughly `1.19 × em`, which is why most styles need *less*
        /// leading than the font gives, not more.
        var naturalLineHeight: CGFloat
        /// Absolute letter spacing in points.
        var letterSpacing: CGFloat

        /// Half the difference between the design's line box and the font's
        /// own. Positive opens the lines up, negative closes them; it is the
        /// distance the first baseline moves.
        var halfLeading: CGFloat { (lineBox - naturalLineHeight) / 2 }

        /// Whether the font already sits within a hair of the design's box.
        var matchesNaturalLineHeight: Bool { abs(lineBox - naturalLineHeight) < 0.01 }
    }

    /// The style's metrics at one Dynamic Type size.
    func resolved(at dynamicTypeSize: DynamicTypeSize) -> Resolved {
        let capped = maxDynamicTypeSize.map { min(dynamicTypeSize, $0) } ?? dynamicTypeSize
        let traits = UITraitCollection(preferredContentSizeCategory: capped.contentSizeCategory)
        let pointSize = UIFontMetrics(forTextStyle: relativeTo.uiTextStyle)
            .scaledValue(for: size, compatibleWith: traits)
        let font = UIFont(name: weight.fontName, size: pointSize)
            ?? .systemFont(ofSize: pointSize, weight: weight == .medium ? .medium : .regular)
        return Resolved(
            pointSize: pointSize,
            lineBox: pointSize * lineHeight,
            naturalLineHeight: font.lineHeight,
            letterSpacing: pointSize * tracking
        )
    }
}

// MARK: - The named styles

nonisolated extension SteadyTextStyle {

    /// `104 / 1`, 500, −0.055em, tabular. Log, Edit and Already-logged.
    static let entryValue = Self(
        size: 104, weight: .medium, tracking: -0.055, tabularFigures: true,
        relativeTo: .largeTitle, maxDynamicTypeSize: .xLarge
    )

    /// `22 / 1`, 400. The "kg" beside the entry value.
    static let entryUnit = Self(size: 22, weight: .regular, relativeTo: .title2, maxDynamicTypeSize: .xLarge)

    /// `64 / 1`, 500, −0.05em, tabular. The Trend headline figure.
    static let trendHeadline = Self(
        size: 64, weight: .medium, tracking: -0.05, tabularFigures: true,
        relativeTo: .largeTitle, maxDynamicTypeSize: .xLarge
    )

    /// `15 / 1`, 400. The "kg" beside the Trend headline.
    static let trendHeadlineUnit = Self(size: 15, weight: .regular, relativeTo: .subheadline)

    /// `40 / 1`, 500, −0.055em, tabular, `ac`. The per-week stat on Month/Year.
    static let statPerWeekValue = Self(
        size: 40, weight: .medium, tracking: -0.055, tabularFigures: true,
        relativeTo: .title, maxDynamicTypeSize: .xxLarge
    )

    /// `36 / 1.14`, 500, −0.035em.
    static let onboardingHeadline = Self(
        size: 36, lineHeight: 1.14, weight: .medium, tracking: -0.035, relativeTo: .title
    )

    /// `36 / 1`, 500, −0.05em, tabular. Today / Yesterday / 7-day avg.
    static let statValue = Self(
        size: 36, weight: .medium, tracking: -0.05, tabularFigures: true,
        relativeTo: .title, maxDynamicTypeSize: .xxLarge
    )

    /// `20 / 1`, 500, −0.03em. The in-app wordmark.
    static let wordmark = Self(size: 20, weight: .medium, tracking: -0.03, relativeTo: .title3)

    /// `24 / 1.2`, 500, −0.03em. "Logged for today".
    static let loggedForToday = Self(
        size: 24, lineHeight: 1.2, weight: .medium, tracking: -0.03, relativeTo: .title2
    )

    /// `22 / 1.2`, 500, −0.03em. "Delete today’s entry?"
    static let deleteSheetTitle = Self(
        size: 22, lineHeight: 1.2, weight: .medium, tracking: -0.03, relativeTo: .title2
    )

    /// `17`, 500, −0.01em. The label on an `ink`-filled primary button.
    static let primaryButtonInk = Self(size: 17, weight: .medium, tracking: -0.01, relativeTo: .headline)

    /// `17`, 500, no tracking. The label on an `ac`-filled primary button.
    static let primaryButtonAccent = Self(size: 17, weight: .medium, relativeTo: .headline)

    /// `17`, 500. "Delete entry" in the confirm sheet.
    static let sheetButtonDestructive = Self(size: 17, weight: .medium, relativeTo: .headline)

    /// `17`, 400. "Keep it" in the confirm sheet.
    static let sheetButtonKeep = Self(size: 17, weight: .regular, relativeTo: .headline)

    /// `17 / 1`, 500, −0.02em. "Edit today’s weight".
    static let editTitle = Self(size: 17, weight: .medium, tracking: -0.02, relativeTo: .headline)

    /// `16 / 1.55`, 400. Onboarding body copy.
    static let onboardingBody = Self(size: 16, lineHeight: 1.55, weight: .regular, relativeTo: .body)

    /// `16 / 1`, 500. "Read weight" / "Write weight".
    static let healthRowTitle = Self(size: 16, weight: .medium, relativeTo: .body)

    /// `15 / 1`, 500. The selected tab item.
    static let tabItemActive = Self(size: 15, weight: .medium, relativeTo: .subheadline)

    /// `15 / 1`, 400. An unselected tab item.
    static let tabItemInactive = Self(size: 15, weight: .regular, relativeTo: .subheadline)

    /// `15 / 1.5`, 400. Delete-sheet body.
    static let deleteSheetBody = Self(size: 15, lineHeight: 1.5, weight: .regular, relativeTo: .subheadline)

    /// `15 / 1`, 400. "Cancel" in the Edit header.
    static let headerCancel = Self(size: 15, weight: .regular, relativeTo: .subheadline)

    /// `15 / 1`, 500. "Delete" in the Edit header.
    static let headerDelete = Self(size: 15, weight: .medium, relativeTo: .subheadline)

    /// `14 / 1`, 500. A period segment.
    static let periodSegment = Self(size: 14, weight: .medium, relativeTo: .footnote)

    /// `14 / 1`, 400. The date line, the Edit meta line, "vs trend".
    static let meta = Self(size: 14, weight: .regular, relativeTo: .footnote)

    /// `14 / 1`, 400, tabular. Meta lines that carry a runtime numeral.
    static let metaNumeric = Self(size: 14, weight: .regular, tabularFigures: true, relativeTo: .footnote)

    /// `14 / 1.5`, 400. The empty-state chart copy.
    static let emptyChartCopy = Self(size: 14, lineHeight: 1.5, weight: .regular, relativeTo: .footnote)

    /// `13 / 1`, 400. Card and stat labels.
    static let cardLabel = Self(size: 13, weight: .regular, relativeTo: .footnote)

    /// `13 / 1`, 400, tabular. The Trend sub-line, which carries a value.
    static let cardLabelNumeric = Self(size: 13, weight: .regular, tabularFigures: true, relativeTo: .footnote)

    /// `13 / 1`, 500, tabular. The delta badge.
    static let deltaBadge = Self(size: 13, weight: .medium, tabularFigures: true, relativeTo: .footnote)

    /// `13 / 1`, 400. Health-row subtitles, the access-off banner.
    static let healthRowSubtitle = Self(size: 13, weight: .regular, relativeTo: .footnote)

    /// `13 / 1`, 500. "Allow" on the access-off banner.
    static let bannerAction = Self(size: 13, weight: .medium, relativeTo: .footnote)

    /// `13 / 1`, 400. "Maybe later" on the health-access screen. The source is
    /// `400 13px/1`, so the line box is the point size — it must not borrow the
    /// privacy note's `1.45`, which would inflate a single-line label's box to
    /// `18.9` and push the glyph off the specified `24` and `40` gaps.
    static let maybeLater = Self(size: 13, weight: .regular, relativeTo: .footnote)

    /// `13 / 1.45`, 400. The onboarding privacy note.
    static let privacyNote = Self(size: 13, lineHeight: 1.45, weight: .regular, relativeTo: .footnote)

    /// `12 / 1`, 400, tabular. The ruler's visible min and max.
    static let rulerBound = Self(size: 12, weight: .regular, tabularFigures: true, relativeTo: .caption)

    /// `12 / 1`, 400. "A product by Levo Studio".
    static let credit = Self(size: 12, weight: .regular, relativeTo: .caption)

    /// `12 / 1`, 400, `+0.14em`, uppercase. The "EDIT" eyebrow.
    static let eyebrow = Self(
        size: 12, weight: .regular, tracking: 0.14, relativeTo: .caption, isUppercased: true
    )
}

// MARK: - Line boxes

/// Draws a `Text` on the design's line box instead of the font's.
///
/// This is the whole reason the styles do not simply use `.lineSpacing()`.
/// SwiftUI's `.lineSpacing` *adds* leading on top of the font's own line
/// height and clamps negative values to zero, so it can only ever make a line
/// box taller. Helvetica Neue's natural line height is about `1.19 × em`,
/// while design reference §3 asks for `1` on almost everything — the `104` pt
/// entry value, the `64` pt trend headline, every stat value — and `1.14` on
/// the onboarding headline. Every one of those needs the box made *smaller*.
///
/// So the layout is taken over: the text is measured and broken at the font's
/// own line height, then the box it occupies is shrunk to `lines × lineBox`
/// and each line is drawn centred inside its target box, which is the CSS
/// half-leading model the design was authored in.
///
/// The measuring and the drawing are deliberately two separate pieces. A
/// `TextRenderer` that reports a shorter height gets that same height handed
/// back to it as the line-breaking proposal, so a box below the font's natural
/// one silently costs lines: `.onboardingHeadline` at `36 / 1.14` fits
/// `floor(41.04 / 42.91) = 0` extra lines and truncates to one ellipsed line at
/// the *default* type size. The renderer therefore does not size anything at
/// all — it only positions the lines — and `LineBoxLayout` does the shrinking
/// one level up, after the break points are already fixed.
private struct LineBoxRenderer: TextRenderer {

    /// The design's line box in points, `size × lineHeight`.
    let lineBox: CGFloat
    /// What the font would have used.
    let naturalLineHeight: CGFloat

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let halfLeading = (lineBox - naturalLineHeight) / 2
        for (index, line) in layout.enumerated() {
            let target = CGFloat(index) * lineBox + halfLeading
            var lineContext = context
            lineContext.translateBy(x: 0, y: target - line.typographicBounds.rect.minY)
            lineContext.draw(line)
        }
    }
}

/// Reports the design's line box for text that has been broken at the font's.
///
/// The text inside is always proposed an unbounded height, so it wraps over as
/// many lines as the width demands. Only the size handed back to the parent is
/// the design's — `lines × lineBox` — which is what every vertical rhythm value
/// in the design reference is measured against. The lines are then drawn into
/// that shorter box by `LineBoxRenderer`; on a sub-natural box the last line's
/// descender reaches a fraction of a point past the bottom edge, which is the
/// same overhang the CSS the design was authored in produces.
private struct LineBoxLayout: Layout {

    /// The design's line box in points, `size × lineHeight`.
    let lineBox: CGFloat
    /// What the font would have used.
    let naturalLineHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let natural = naturalSize(width: proposal.width, subviews: subviews)
        return CGSize(width: natural.width, height: lineCount(for: natural.height) * lineBox)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        let natural = naturalSize(width: bounds.width, subviews: subviews)
        subview.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: natural.height)
        )
    }

    /// The baselines the renderer will actually draw on, so a baseline-aligned
    /// row still lines up once the box has been resized. `SteadyTextStyle`
    /// adds the half-leading on top of these; a `Layout` that returned nil here
    /// would fall back to the box's edges and take the `104` pt entry value's
    /// "kg" with it.
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        guard let subview = subviews.first else { return nil }
        let dimensions = subview.dimensions(in: ProposedViewSize(width: bounds.width, height: nil))
        switch guide {
        case .firstTextBaseline:
            return dimensions[.firstTextBaseline]
        case .lastTextBaseline:
            // Every line above the last one has been pulled in by the
            // difference between the two boxes, so the last baseline moves by
            // that difference times the number of gaps above it.
            let gaps = lineCount(for: dimensions.height) - 1
            return dimensions[.lastTextBaseline] + gaps * (lineBox - naturalLineHeight)
        default:
            return nil
        }
    }

    /// The text laid out with no height constraint, which is the only way to
    /// see how many lines it really wants.
    private func naturalSize(width: CGFloat?, subviews: Subviews) -> CGSize {
        subviews.first?.sizeThatFits(ProposedViewSize(width: width, height: nil)) ?? .zero
    }

    /// SwiftUI has already rounded the natural height to the pixel grid, so the
    /// line count is recovered by division rather than carried across.
    private func lineCount(for naturalHeight: CGFloat) -> CGFloat {
        guard naturalLineHeight > 0 else { return 1 }
        return max(1, (naturalHeight / naturalLineHeight).rounded())
    }
}

// MARK: - Application

private struct SteadyTextStyleModifier: ViewModifier {
    let style: SteadyTextStyle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let metrics = style.resolved(at: dynamicTypeSize)
        let styled = content
            .font(style.font)
            .tracking(metrics.letterSpacing)
            .textCase(style.isUppercased ? .uppercase : nil)
            .lineBox(metrics)

        if let cap = style.maxDynamicTypeSize {
            styled.dynamicTypeSize(...cap)
        } else {
            styled
        }
    }
}

private extension View {

    /// Puts the text on the design's line box and moves the baselines with it,
    /// so a baseline-aligned row (the entry value and its "kg") still lines up
    /// after the box has been resized.
    @ViewBuilder
    func lineBox(_ metrics: SteadyTextStyle.Resolved) -> some View {
        if metrics.matchesNaturalLineHeight {
            self
        } else {
            LineBoxLayout(
                lineBox: metrics.lineBox,
                naturalLineHeight: metrics.naturalLineHeight
            ) {
                textRenderer(
                    LineBoxRenderer(
                        lineBox: metrics.lineBox,
                        naturalLineHeight: metrics.naturalLineHeight
                    )
                )
            }
            .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] + metrics.halfLeading }
            .alignmentGuide(.lastTextBaseline) { $0[.lastTextBaseline] + metrics.halfLeading }
        }
    }
}

// MARK: - Dynamic Type bridging

private extension Font.TextStyle {

    nonisolated

    /// The UIKit style `Font.custom(_:size:relativeTo:)` scales against, so the
    /// resolved point size can be recovered for the line-box maths.
var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .extraLargeTitle, .extraLargeTitle2: .largeTitle
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}

private extension DynamicTypeSize {

    nonisolated var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

extension View {
    /// Applies a named style from the design reference: family, size, weight,
    /// tracking, line box, tabular figures, letter case and the Dynamic Type
    /// ceiling.
    func steadyTextStyle(_ style: SteadyTextStyle) -> some View {
        modifier(SteadyTextStyleModifier(style: style))
    }
}
