//
//  TypographyWrappingTests.swift
//  SteadyTests
//
//  Design reference §3 asks for a line box below Helvetica Neue's natural one
//  on almost every style. Those boxes were verified by height alone, and a
//  height check cannot see a truncated line — so these tests look at the
//  glyphs: how many lines were drawn, and whether any of the string was lost.
//

import SwiftUI
import Testing
import UIKit
@testable import Steady

@MainActor
@Suite("Typography — wrapping")
struct TypographyWrappingTests {

    /// The safe content width of the onboarding column: `402 − 24 − 24`.
    static let onboardingWidth: CGFloat = 354
    /// The design's chart card interior.
    static let cardWidth: CGFloat = 306

    private let tolerance: CGFloat = 0.5

    /// Asserts that a styled string breaks over `lines` lines, keeps all of its
    /// ink, and still reports `lines × lineBox`.
    private func expectWraps(
        _ text: String,
        style: SteadyTextStyle,
        width: CGFloat,
        lines: Int,
        at dynamicTypeSize: DynamicTypeSize = .large,
        _ label: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let styled = TextRenderProbe.render(text, style: style, width: width, dynamicTypeSize: dynamicTypeSize)
        let reference = TextRenderProbe.renderWithoutLineBox(
            text, style: style, width: width, dynamicTypeSize: dynamicTypeSize
        )

        #expect(
            styled.lineCount == lines,
            "\(label): drew \(styled.lineCount) lines of ink over \(styled.inkExtent) pt, expected \(lines)",
            sourceLocation: sourceLocation
        )
        // A truncated line swaps the tail of the copy for an ellipsis, which
        // costs most of the ink on that line. Ten percent is far more slack
        // than the half-leading shift can account for.
        #expect(
            Double(styled.inkPixels) > Double(reference.inkPixels) * 0.9,
            "\(label): \(styled.inkPixels) inked pixels against \(reference.inkPixels) untruncated — text was lost",
            sourceLocation: sourceLocation
        )

        let metrics = style.resolved(at: dynamicTypeSize)
        let expected = CGFloat(lines) * metrics.lineBox
        #expect(
            abs(styled.reportedHeight - expected) < tolerance,
            "\(label): reported \(styled.reportedHeight), design wants \(expected)",
            sourceLocation: sourceLocation
        )
    }

    /// The number of lines the same string takes with no line-box treatment.
    private func naturalLineCount(
        _ text: String,
        style: SteadyTextStyle,
        width: CGFloat,
        at dynamicTypeSize: DynamicTypeSize
    ) -> Int {
        TextRenderProbe
            .renderWithoutLineBox(text, style: style, width: width, dynamicTypeSize: dynamicTypeSize)
            .lineCount
    }

    // MARK: - The headline that shipped truncated

    static let welcomeHeadline = "The scale lies. The line doesn\u{2019}t."
    static let healthHeadline = "One box to tick, then it\u{2019}s out of the way."

    @Test("The welcome headline renders both its lines at the default size")
    func welcomeHeadlineWrapsAtDefaultSize() {
        expectWraps(
            Self.welcomeHeadline, style: .onboardingHeadline,
            width: Self.onboardingWidth, lines: 2,
            "onboarding headline, .large"
        )
    }

    @Test("The health headline renders in full at the default size")
    func healthHeadlineWrapsAtDefaultSize() {
        expectWraps(
            Self.healthHeadline, style: .onboardingHeadline,
            width: Self.onboardingWidth, lines: 2,
            "health headline, .large"
        )
    }

    @Test("The welcome headline still wraps at the largest accessibility size")
    func welcomeHeadlineWrapsAtAccessibility5() {
        let lines = naturalLineCount(
            Self.welcomeHeadline, style: .onboardingHeadline,
            width: Self.onboardingWidth, at: .accessibility5
        )
        expectWraps(
            Self.welcomeHeadline, style: .onboardingHeadline,
            width: Self.onboardingWidth, lines: lines, at: .accessibility5,
            "onboarding headline, .accessibility5"
        )
    }

    // MARK: - Every wrapping style below the natural ratio

    /// Design reference §3 in the styles that set a box under Helvetica Neue's
    /// own ratio *and* carry copy long enough to wrap. Anything at or above the
    /// natural ratio (`onboardingBody` at 1.55, `privacyNote` at 1.45) never
    /// had the problem and is covered by the height tests already.
    static let wrappingCases: [(name: String, style: SteadyTextStyle, text: String, width: CGFloat)] = [
        ("onboardingHeadline", .onboardingHeadline, welcomeHeadline, onboardingWidth),
        ("healthRowSubtitle", .healthRowSubtitle,
         "So Steady can read the weight you already have in Health.", 220),
        ("healthRowTitle", .healthRowTitle, "Allow in Apple Health", 120),
        ("cardLabel", .cardLabel, "Trend weight over the last seven days", 140),
        ("periodSegment", .periodSegment, "Week", 44),
        ("metaNumeric", .metaNumeric, "0.4 kg below the 7-day trend", 120),
        ("wordmark", .wordmark, "steady", 60),
        ("primaryButtonInk", .primaryButtonInk, "Connect Apple Health", 150),
        ("primaryButtonAccent", .primaryButtonAccent, "Log today\u{2019}s weight", 130),
        ("maybeLater", .maybeLater, "Maybe later", 60),
        ("tabItemActive", .tabItemActive, "Log", 40),
        ("bannerAction", .bannerAction, "Allow", 40),
        ("meta", .meta, "Saturday, 29 August", 100),
        ("editTitle", .editTitle, "Edit today\u{2019}s weight", 120),
        ("loggedForToday", .loggedForToday, "Logged for today", 150),
        ("deleteSheetTitle", .deleteSheetTitle, "Delete today\u{2019}s entry?", 150),
        ("credit", .credit, "A product by Levo Studio", 100),
        ("eyebrow", .eyebrow, "Edit", 40),
    ]

    @Test("Every sub-natural line box still wraps rather than truncates", arguments: [
        DynamicTypeSize.large, DynamicTypeSize.accessibility5
    ])
    func everySubNaturalLineBoxWraps(size: DynamicTypeSize) {
        for testCase in Self.wrappingCases {
            let metrics = testCase.style.resolved(at: size)
            let lines = naturalLineCount(
                testCase.text, style: testCase.style, width: testCase.width, at: size
            )
            expectWraps(
                testCase.text, style: testCase.style, width: testCase.width,
                lines: lines, at: size,
                "\(testCase.name) (\(metrics.lineBox) box / \(metrics.naturalLineHeight) natural), \(size)"
            )
        }
    }

    // MARK: - What the fix must not disturb

    @Test("A single-line 13 / 1 label still reports exactly its point size")
    func maybeLaterKeepsItsPointSizeBox() {
        // The hit area on the health-access screen is (44 − 13) / 2 = 15.5,
        // computed from this number.
        for size in [DynamicTypeSize.large, .accessibility5] {
            let metrics = SteadyTextStyle.maybeLater.resolved(at: size)
            #expect(abs(metrics.lineBox - metrics.pointSize) < 0.001)
            let render = TextRenderProbe.render(
                "Maybe later", style: .maybeLater, width: 200, dynamicTypeSize: size
            )
            #expect(render.lineCount == 1)
            #expect(abs(render.reportedHeight - metrics.pointSize) < tolerance)
        }
    }

    @Test("A single-line 15 / 1 header label still reports 15, which the Log header inset is built on")
    func headerLabelKeepsItsPointSizeBox() {
        // LogLayout.headerTargetInset is (44 − 15) / 2 = 14.5.
        let render = TextRenderProbe.render("Cancel", style: .headerCancel, width: 200)
        #expect(render.lineCount == 1)
        #expect(abs(render.reportedHeight - 15) < tolerance)
    }

    @Test("The first baseline still sits where the half-leading model puts it")
    func firstBaselineFollowsTheLineBox() {
        // The 104 / 22 lockup on the Log screen is baseline-aligned, so the
        // guide has to move with the box, not with the font.
        let value = SteadyTextStyle.entryValue.resolved(at: .large)
        let unit = SteadyTextStyle.entryUnit.resolved(at: .large)
        #expect(value.halfLeading < 0)
        #expect(unit.halfLeading < 0)

        // Neither "72.4" nor "kn" has a descender, so the bottom of their ink
        // *is* the baseline they were drawn on. The two are set far enough
        // apart to read as separate clusters of ink; if the guide were left on
        // the font's baseline rather than the line box's, the 104 pt figure and
        // the 22 pt unit would part company by the difference of their two
        // half-leadings — about 8 pt.
        let row = HStack(alignment: .firstTextBaseline, spacing: 60) {
            Text("72.4").steadyTextStyle(.entryValue)
            Text("kn").steadyTextStyle(.entryUnit)
        }
        .dynamicTypeSize(.large)

        let bottoms = TextRenderProbe.inkBottomPerCluster(of: row, width: 400, separatedByAtLeast: 30)
        #expect(bottoms.count == 2, "expected the figure and the unit to read as two clusters of ink")
        if bottoms.count == 2 {
            #expect(
                abs(bottoms[0] - bottoms[1]) <= 1,
                "the 104 pt figure sits on row \(bottoms[0]), its unit on \(bottoms[1])"
            )
        }
        // The control: the same two strings stacked on `.top` land nowhere near
        // each other, which is what the probe would report if the guide stopped
        // tracking the line box.
        let topAligned = HStack(alignment: .top, spacing: 60) {
            Text("72.4").steadyTextStyle(.entryValue)
            Text("kn").steadyTextStyle(.entryUnit)
        }
        .dynamicTypeSize(.large)
        let unaligned = TextRenderProbe.inkBottomPerCluster(
            of: topAligned, width: 400, separatedByAtLeast: 30
        )
        #expect(unaligned.count == 2)
        if unaligned.count == 2 {
            #expect(abs(unaligned[0] - unaligned[1]) > 20)
        }
    }
}
