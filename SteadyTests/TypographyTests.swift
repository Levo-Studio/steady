//
//  TypographyTests.swift
//  SteadyTests
//
//  The line box every text style renders on, measured against design
//  reference §3. These are the numbers every vertical rhythm value in the
//  design depends on, so they are asserted rather than eyeballed.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Steady

@MainActor
@Suite("Typography")
struct TypographyTests {

    /// The design is drawn at `402 − 24 − 24`, minus a card's `24` padding.
    static let chartCardWidth: CGFloat = 306

    /// Renders one styled string and returns the height SwiftUI gives it.
    private func height(
        _ text: String,
        style: SteadyTextStyle,
        width: CGFloat = chartCardWidth
    ) -> CGFloat {
        let view = Text(text)
            .steadyTextStyle(style)
            .dynamicTypeSize(.large)
            .frame(width: width)
        let host = UIHostingController(rootView: view)
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    /// SwiftUI rounds a frame onto the device pixel grid, so an exact compare
    /// would fail on a ⅓ pt boundary. Half a point is well inside the 1 pt
    /// hairline the design's smallest feature is drawn with.
    private let tolerance: CGFloat = 0.5

    private func expectLineBox(
        _ text: String,
        style: SteadyTextStyle,
        lines: CGFloat,
        width: CGFloat = chartCardWidth,
        _ comment: Comment,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let measured = height(text, style: style, width: width)
        let expected = lines * style.size * style.lineHeight
        #expect(
            abs(measured - expected) < tolerance,
            "\(comment.description): measured \(measured), design wants \(expected)",
            sourceLocation: sourceLocation
        )
    }

    // MARK: - The line boxes design reference §3 fixes

    @Test("The 104 pt entry value occupies exactly 104 pt, not the font's 123.97")
    func entryValueLineBox() {
        expectLineBox("72.4", style: .entryValue, lines: 1, "entry value 104 / 1")
    }

    @Test("The 64 pt trend headline occupies exactly 64 pt, not the font's 76.29")
    func trendHeadlineLineBox() {
        expectLineBox("72.6", style: .trendHeadline, lines: 1, "trend headline 64 / 1")
    }

    @Test("The 40 pt per-week stat occupies exactly 40 pt")
    func statPerWeekLineBox() {
        expectLineBox("+0.03", style: .statPerWeekValue, lines: 1, "per-week stat 40 / 1")
    }

    @Test("The 36 pt stat values occupy exactly 36 pt")
    func statValueLineBox() {
        expectLineBox("72.4", style: .statValue, lines: 1, "stat value 36 / 1")
    }

    @Test("The onboarding headline is 1.14 line boxes per line, across two lines")
    func onboardingHeadlineLineBox() {
        // "The scale lies. The line doesn't." wraps to two lines at 306 pt.
        expectLineBox(
            "The scale lies. The line doesn\u{2019}t.",
            style: .onboardingHeadline, lines: 2,
            "onboarding headline 36 / 1.14"
        )
    }

    @Test("The onboarding body opens the line box up to 1.55")
    func onboardingBodyLineBox() {
        let copy = "Pasta, salt, a long flight \u{2014} the scale reacts to all of it. "
            + "Steady smooths it out and leaves you one honest line."
        expectLineBox(copy, style: .onboardingBody, lines: 3, "onboarding body 16 / 1.55")
    }

    @Test("The delete-sheet body sits on a 1.5 line box")
    func deleteSheetBodyLineBox() {
        let copy = "72.4 kg from Saturday, 29 August will be removed and the trend recalculated."
        expectLineBox(copy, style: .deleteSheetBody, lines: 2, "delete-sheet body 15 / 1.5")
    }

    @Test("A 13 pt label occupies exactly 13 pt")
    func cardLabelLineBox() {
        expectLineBox("Trend weight", style: .cardLabel, lines: 1, "card label 13 / 1")
    }

    @Test("The tab item and period segment sit on their own point size")
    func controlLabelLineBoxes() {
        expectLineBox("Log", style: .tabItemActive, lines: 1, width: 160, "tab item 15 / 1")
        expectLineBox("Week", style: .periodSegment, lines: 1, width: 100, "period segment 14 / 1")
    }

    // MARK: - The model itself

    @Test("Helvetica Neue's natural line height is well above the design's, so the box must shrink")
    func naturalLineHeightIsLargerThanTheDesignBox() {
        let entry = SteadyTextStyle.entryValue.resolved(at: .large)
        #expect(entry.lineBox == 104)
        #expect(entry.naturalLineHeight > entry.lineBox)
        // A model that can only add leading would leave this at 0.
        #expect(entry.halfLeading < 0)
    }

    @Test("A line height above the font's own still opens the box up")
    func generousLineHeightsStillAdd() {
        let body = SteadyTextStyle.onboardingBody.resolved(at: .large)
        #expect(abs(body.lineBox - 24.8) < 0.001)
        #expect(body.halfLeading > 0)
    }

    // MARK: - Tracking

    @Test("Tracking is authored in em and scales with Dynamic Type")
    func trackingScalesWithDynamicType() {
        let style = SteadyTextStyle.onboardingHeadline
        let base = style.resolved(at: .large)
        let large = style.resolved(at: .accessibility3)
        #expect(abs(base.letterSpacing - 36 * -0.035) < 0.001)
        #expect(large.pointSize > base.pointSize)
        // Absolute points, so the em figure has to be multiplied out against
        // the resolved size or the big sizes come out under-tracked.
        #expect(abs(large.letterSpacing - large.pointSize * -0.035) < 0.001)
        #expect(large.letterSpacing < base.letterSpacing)
    }

    @Test("A capped style stops growing at its ceiling")
    func dynamicTypeCeilingIsRespected() {
        let entry = SteadyTextStyle.entryValue
        #expect(entry.maxDynamicTypeSize == .xLarge)
        #expect(entry.resolved(at: .accessibility5) == entry.resolved(at: .xLarge))
    }

    // MARK: - Case

    @Test("The eyebrow is the one uppercase style in the product")
    func eyebrowIsUppercased() {
        #expect(SteadyTextStyle.eyebrow.isUppercased)
        #expect(abs(SteadyTextStyle.eyebrow.tracking - 0.14) < 0.001)
        for style: SteadyTextStyle in [.entryValue, .trendHeadline, .cardLabel, .onboardingBody] {
            #expect(!style.isUppercased)
        }
    }
}
