//
//  ValuePlaceholder.swift
//  Steady
//
//  The em dash that stands in for a display numeral, per design reference §7.3.
//

import CoreText
import SwiftUI
import UIKit

/// The `—` that replaces a `64`, `40` or `36` pt value before there is one.
///
/// ## Why this is not a `Text`
///
/// Design reference §7.3 asks for an em dash at the value's own size, and a
/// literal `Text("—")` is typographically correct and visually wrong. Helvetica
/// Neue draws the em dash about `0.23 em` above the baseline, so at `64` pt the
/// bar sits ~`15` pt up while the `15` pt "kg" beside it has a cap height of
/// ~`11` pt — the dash clears the unit entirely and reads as a rule floating
/// above it rather than as a missing number. The digits it stands in for occupy
/// `0` to ~`46` pt, so their optical centre is at ~`23` pt, eight points higher
/// still, and the box looks empty because the only ink in it is nowhere near
/// where a value's ink would be.
///
/// So the glyph is drawn rather than set: the em dash's **own** bounding box is
/// measured from the font, and that exact bar is placed with its centre on the
/// numerals' cap-height centre-line. It is the same mark at the same weight and
/// the same width, moved onto the digit centre-line.
///
/// ## Why it does not disturb the populated case
///
/// Nothing about the layout changes when a real value is present, because this
/// view is only substituted when there is no value. It claims exactly the line
/// box the style specifies (`size × lineHeight`, the same box
/// `SteadyTextStyle` gives a real numeral) and publishes the same first
/// baseline, so the `14` pt label-to-value gap, the `8` pt value-to-sub-line
/// gap and the baseline the "kg" aligns to are all untouched.
struct ValuePlaceholder: View {

    /// The style the absent value would have been set in.
    let style: SteadyTextStyle
    /// `mut` at every call site — §7.3 is explicit that a placeholder is not
    /// `ink`. Passed rather than assumed so the view has no opinion on colour.
    var colour: Color = Palette.mut

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let geometry = Geometry(style: style, dynamicTypeSize: dynamicTypeSize)

        // The em dash itself, set at the style and then hidden, is the layout.
        // Nothing is calculated about the box: it *is* a real `Text` of this
        // style, so its line box, its width and its baseline are exactly what
        // §7.3's glyph would have produced, and the surrounding measurements
        // cannot drift from the populated case.
        Text(verbatim: "—")
            .steadyTextStyle(style)
            .hidden()
            // Aligning the overlay on the text's own first baseline is what
            // removes the arithmetic: a `Rectangle` has no baseline of its own,
            // so SwiftUI aligns its bottom edge to the text's, and the offset
            // below is then measured from the baseline itself.
            .overlay(alignment: Alignment(horizontal: .center, vertical: .firstTextBaseline)) {
                Rectangle()
                    .fill(colour)
                    .frame(width: geometry.width, height: geometry.thickness)
                    // Up onto the numerals' optical centre — half a cap height
                    // above the baseline, which is where a value's mass sits.
                    .offset(y: geometry.thickness / 2 - geometry.capHeight / 2)
            }
            .accessibilityHidden(true)
    }

    /// The bar's own dimensions, and where the numerals' centre-line is.
    private struct Geometry {

        /// The em dash's drawn width at this size — the glyph's ink, not its
        /// advance, so the bar is exactly the mark §7.3 asks for.
        let width: CGFloat
        /// The em dash's drawn thickness at this size.
        let thickness: CGFloat
        /// The digits' cap height, which is the whole point: their optical
        /// centre is half of it above the baseline.
        let capHeight: CGFloat

        init(style: SteadyTextStyle, dynamicTypeSize: DynamicTypeSize) {
            let metrics = style.resolved(at: dynamicTypeSize)
            let uiFont = UIFont(name: style.weight.fontName, size: metrics.pointSize)
                ?? .systemFont(
                    ofSize: metrics.pointSize,
                    weight: style.weight == .medium ? .medium : .regular
                )
            capHeight = uiFont.capHeight

            let dash = Self.emDashBounds(font: uiFont)
            width = dash.width
            thickness = dash.height
        }

        /// The em dash's drawn box at this size, taken from the font rather
        /// than guessed, so the bar is the glyph — same width, same weight.
        private static func emDashBounds(font: UIFont) -> CGSize {
            let ctFont = font as CTFont
            var glyph = CTFontGetGlyphWithName(ctFont, "emdash" as CFString)
            guard glyph != 0 else { return fallbackBounds(font: font) }
            var rect = CGRect.zero
            withUnsafeMutablePointer(to: &glyph) { glyphs in
                withUnsafeMutablePointer(to: &rect) { rects in
                    _ = CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, glyphs, rects, 1)
                }
            }
            guard rect.width > 0, rect.height > 0 else { return fallbackBounds(font: font) }
            return rect.size
        }

        /// If the family ever stops shipping a named `emdash` glyph, the mark
        /// still has to be there. `1 em` wide and `1/16 em` thick is what
        /// Helvetica Neue draws, to within a rounding error.
        private static func fallbackBounds(font: UIFont) -> CGSize {
            CGSize(width: font.pointSize, height: max(1, font.pointSize / 16))
        }
    }
}

// MARK: - Substitution

extension View {

    /// Swaps a display numeral for §7.3's em dash when there is no value.
    ///
    /// The populated branch is the view as written, untouched — the placeholder
    /// only ever replaces a value that is not there.
    @ViewBuilder
    func valuePlaceholder(
        _ isPlaceholder: Bool,
        style: SteadyTextStyle,
        colour: Color = Palette.mut
    ) -> some View {
        if isPlaceholder {
            ValuePlaceholder(style: style, colour: colour)
        } else {
            self
        }
    }
}

#if DEBUG

// MARK: - Previews

/// The placeholder beside the "kg" it kept clearing, at the three display
/// sizes, so the fix is judged by rendering rather than by reasoning.
#Preview("Light") {
    VStack(alignment: .leading, spacing: Metrics.space5) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            ValuePlaceholder(style: .trendHeadline)
            Text("kg").steadyTextStyle(.trendHeadlineUnit).foregroundStyle(Palette.mut)
        }
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("72.6").steadyTextStyle(.trendHeadline).foregroundStyle(Palette.ink)
            Text("kg").steadyTextStyle(.trendHeadlineUnit).foregroundStyle(Palette.mut)
        }
        ValuePlaceholder(style: .statValue)
        ValuePlaceholder(style: .statPerWeekValue)
    }
    .padding(Metrics.space4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.sur)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(alignment: .leading, spacing: Metrics.space5) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            ValuePlaceholder(style: .trendHeadline)
            Text("kg").steadyTextStyle(.trendHeadlineUnit).foregroundStyle(Palette.mut)
        }
        ValuePlaceholder(style: .statValue)
    }
    .padding(Metrics.space4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.sur)
    .preferredColorScheme(.dark)
}

#endif
