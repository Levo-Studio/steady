//
//  Typography.swift
//  Steady
//
//  Every named text style from design/steady-design-reference.md §3.
//

import SwiftUI

/// A single named text style from the design reference.
///
/// Helvetica Neue throughout, only two weights — 400 Regular and 500 Medium.
/// Tracking is authored in `em` and negative, tightening as the type grows;
/// it is multiplied out against the point size here.
struct SteadyTextStyle: Sendable, Equatable {

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

    init(
        size: CGFloat,
        lineHeight: CGFloat = 1,
        weight: Weight,
        tracking: CGFloat = 0,
        tabularFigures: Bool = false,
        relativeTo: Font.TextStyle = .body,
        maxDynamicTypeSize: DynamicTypeSize? = nil
    ) {
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.tracking = tracking
        self.tabularFigures = tabularFigures
        self.relativeTo = relativeTo
        self.maxDynamicTypeSize = maxDynamicTypeSize
    }

    /// Absolute letter spacing in points at the default size.
    var letterSpacing: CGFloat { size * tracking }

    /// Extra leading needed to reach the authored line height.
    var lineSpacing: CGFloat { max(0, size * (lineHeight - 1)) }

    var font: Font {
        var font = Font.custom(weight.fontName, size: size, relativeTo: relativeTo)
        if tabularFigures { font = font.monospacedDigit() }
        return font
    }
}

// MARK: - The named styles

extension SteadyTextStyle {

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

    /// `22 / 1.2`, 500, −0.03em. "Delete today's entry?"
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

    /// `17 / 1`, 500, −0.02em. "Edit today's weight".
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

    /// `13 / 1.45`, 400. The onboarding privacy note.
    static let privacyNote = Self(size: 13, lineHeight: 1.45, weight: .regular, relativeTo: .footnote)

    /// `12 / 1`, 400, tabular. The ruler's visible min and max.
    static let rulerBound = Self(size: 12, weight: .regular, tabularFigures: true, relativeTo: .caption)

    /// `12 / 1`, 400. "A product by Levo Studio".
    static let credit = Self(size: 12, weight: .regular, relativeTo: .caption)

    /// `12 / 1`, 400, `+0.14em`, uppercase. The "EDIT" eyebrow.
    static let eyebrow = Self(size: 12, weight: .regular, tracking: 0.14, relativeTo: .caption)
}

// MARK: - Application

private struct SteadyTextStyleModifier: ViewModifier {
    let style: SteadyTextStyle

    func body(content: Content) -> some View {
        let styled = content
            .font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(style.lineSpacing)

        if let cap = style.maxDynamicTypeSize {
            styled.dynamicTypeSize(...cap)
        } else {
            styled
        }
    }
}

extension View {
    /// Applies a named style from the design reference: family, size, weight,
    /// tracking, line height, tabular figures and the Dynamic Type ceiling.
    func steadyTextStyle(_ style: SteadyTextStyle) -> some View {
        modifier(SteadyTextStyleModifier(style: style))
    }
}
