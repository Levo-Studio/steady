//
//  RulerGeometryTests.swift
//  SteadyTests
//
//  The ruler's conversion, its snapping, and the rule that fires the haptic.
//  Design reference §5 and STEADY.md §6.
//

import Foundation
import Testing
@testable import Steady

@Suite("Ruler geometry")
struct RulerGeometryTests {

    // MARK: - The conversion constant

    @Test("One tick is 0.1 kg and 14.2 pt")
    func tickConstants() {
        #expect(RulerGeometry.kilogramsPerTick == 0.1)
        #expect(RulerGeometry.pointsPerTick == 14.2)
        #expect(abs(RulerGeometry.pointsPerKilogram - 142) < 1e-9)
    }

    @Test("The visible window is 2.4 kg across 24 tick intervals")
    func window() {
        let intervals = Double(Metrics.rulerTickCount - 1)
        let span = intervals * RulerGeometry.kilogramsPerTick
        #expect(abs(span - Metrics.rulerHalfWindow * 2) < 1e-9)
        #expect(abs(intervals * RulerGeometry.pointsPerTick - 340.8) < 1e-9)
    }

    // MARK: - Value <-> offset

    @Test("Dragging left increases the value")
    func dragLeftIncreases() {
        let value = RulerGeometry.value(from: 72.4, translation: -14.2)
        #expect(abs(value - 72.5) < 1e-9)
    }

    @Test("Dragging right decreases the value")
    func dragRightDecreases() {
        let value = RulerGeometry.value(from: 72.4, translation: 14.2)
        #expect(abs(value - 72.3) < 1e-9)
    }

    @Test("A drag of n ticks moves the value by n × 0.1 kg", arguments: [-37, -5, -1, 0, 1, 5, 37])
    func dragScalesLinearly(ticks: Int) {
        let translation = -Double(ticks) * RulerGeometry.pointsPerTick
        let value = RulerGeometry.value(from: 72.4, translation: translation)
        #expect(abs(value - (72.4 + Double(ticks) * 0.1)) < 1e-9)
    }

    @Test("A part-tick drag is not snapped, so the strip tracks the finger")
    func dragIsContinuous() {
        let value = RulerGeometry.value(from: 72.4, translation: -7.1)
        #expect(abs(value - 72.45) < 1e-9)
        #expect(value != RulerGeometry.snap(value))
    }

    @Test("Points and kilograms round-trip through the tick index")
    func roundTrip() {
        for tick in stride(from: 200, through: 4000, by: 137) {
            let kilograms = RulerGeometry.kilograms(forTick: tick)
            #expect(RulerGeometry.tickIndex(for: kilograms) == tick)
            #expect(abs(RulerGeometry.offsetFromNeedle(ofTick: tick, at: kilograms)) < 1e-6)
        }
    }

    @Test("A tick's distance from the needle is its distance in kilograms × 142")
    func offsetFromNeedle() {
        let offset = RulerGeometry.offsetFromNeedle(ofTick: 729, at: 72.4)
        #expect(abs(offset - 14.2 * 5) < 1e-6)
    }

    @Test("The strip's phase is always within half a tick of zero")
    func phaseStaysSmall() {
        for step in 0...200 {
            let value = 72.0 + Double(step) * 0.017
            let phase = RulerGeometry.phase(for: value)
            #expect(abs(phase) <= RulerGeometry.pointsPerTick / 2 + 1e-9)
        }
    }

    @Test("The visible ticks cover the strip's width")
    func visibleTicksCoverTheStrip() {
        let width = Metrics.contentWidth
        let ticks = RulerGeometry.visibleTicks(at: 72.43, width: Double(width))
        let left = RulerGeometry.offsetFromNeedle(ofTick: ticks.lowerBound, at: 72.43)
        let right = RulerGeometry.offsetFromNeedle(ofTick: ticks.upperBound, at: 72.43)
        #expect(left <= -Double(width) / 2)
        #expect(right >= Double(width) / 2)
    }

    // MARK: - Snapping

    @Test("Every value snaps to 0.1 kg")
    func snapsToTenth() {
        #expect(RulerGeometry.snap(72.44) == 72.4)
        #expect(RulerGeometry.snap(72.45) == 72.5)
        #expect(RulerGeometry.snap(72.4999) == 72.5)
        #expect(RulerGeometry.snap(70) == 70.0)
    }

    @Test("A snapped value is an exact multiple of 0.1")
    func snapIsExact() {
        for step in 0...500 {
            let raw = 60.0 + Double(step) * 0.0137
            let snapped = RulerGeometry.snap(raw)
            #expect(abs(snapped * 10 - (snapped * 10).rounded()) < 1e-9)
            #expect(abs(snapped - raw) <= 0.05 + 1e-9)
        }
    }

    @Test("A step is exactly 0.1 and does not accumulate error")
    func steppingIsExact() {
        var value = 70.0
        for _ in 0..<30 { value = RulerGeometry.stepped(value, by: 1) }
        #expect(value == 73.0)
        for _ in 0..<30 { value = RulerGeometry.stepped(value, by: -1) }
        #expect(value == 70.0)
    }

    @Test("The value is clamped to the plausible range")
    func clamping() {
        #expect(RulerGeometry.value(from: 20.0, translation: 14.2 * 100) == 20.0)
        #expect(RulerGeometry.value(from: 400.0, translation: -14.2 * 100) == 400.0)
        #expect(RulerGeometry.snap(19.94) == 20.0)
        #expect(RulerGeometry.stepped(400.0, by: 1) == 400.0)
    }

    // MARK: - Majors and labels

    @Test("Majors land on whole 0.5 kg")
    func majors() {
        #expect(RulerGeometry.isMajor(tick: RulerGeometry.tickIndex(for: 72.5)))
        #expect(RulerGeometry.isMajor(tick: RulerGeometry.tickIndex(for: 73.0)))
        #expect(!RulerGeometry.isMajor(tick: RulerGeometry.tickIndex(for: 72.4)))
    }

    @Test("The labels read value ∓ 1.2")
    func bounds() {
        let ends = RulerGeometry.bounds(at: 72.4)
        #expect(abs(ends.lower - 71.2) < 1e-9)
        #expect(abs(ends.upper - 73.6) < 1e-9)
        #expect(TrendEngine.format(ends.lower, decimals: 1) == "71.2")
        #expect(TrendEngine.format(ends.upper, decimals: 1) == "73.6")
    }
}

/// The haptic contract, expressed as the thing that decides it.
///
/// A drag that buzzes on every frame and one that never buzzes are the same
/// bug — firing on the frame instead of on the crossing — so what is asserted
/// here is the count over a whole gesture, not the mechanism.
@Suite("Ruler tick tracker")
struct RulerTickTrackerTests {

    /// Replays a drag frame by frame and counts how often the haptic would
    /// fire, exactly as `WeightRuler` calls it.
    private func taps(from start: Double, translations: [Double]) -> Int {
        var tracker = RulerTickTracker(value: start)
        var taps = 0
        for translation in translations {
            let value = RulerGeometry.value(from: start, translation: translation)
            if tracker.advance(to: value) > 0 { taps += 1 }
        }
        return taps
    }

    @Test("Standing still never fires")
    func silentWhenStill() {
        #expect(taps(from: 72.4, translations: Array(repeating: 0, count: 60)) == 0)
    }

    @Test("Moving inside one tick never fires")
    func silentInsideATick() {
        // Half a tick, in sixty frames: the reading never changes.
        let translations = (0..<60).map { -Double($0) * (RulerGeometry.pointsPerTick / 2) / 60 }
        #expect(taps(from: 72.4, translations: translations) == 0)
    }

    @Test("A smooth drag over ten ticks fires exactly ten times")
    func oncePerTick() {
        // 600 frames for 10 ticks: forty frames per tick, and only the frame
        // that crosses may fire.
        let distance = 10 * RulerGeometry.pointsPerTick
        let translations = (1...600).map { -distance * Double($0) / 600 }
        #expect(taps(from: 72.4, translations: translations) == 10)
    }

    @Test("Reversing back over the same ticks fires again on the way back")
    func firesOnTheReturn() {
        let distance = 3 * RulerGeometry.pointsPerTick
        var translations = (1...180).map { -distance * Double($0) / 180 }
        translations += (0..<180).map { -distance * Double(179 - $0) / 180 }
        #expect(taps(from: 72.4, translations: translations) == 6)
    }

    @Test("A tick already reported is never reported twice")
    func neverTwiceForTheSameTick() {
        var tracker = RulerTickTracker(value: 72.4)
        #expect(tracker.advance(to: 72.451) == 1)
        #expect(tracker.advance(to: 72.46) == 0)
        #expect(tracker.advance(to: 72.54) == 0)
        #expect(tracker.advance(to: 72.449) == 1)
    }

    @Test("A flick that crosses several ticks in one frame reports them all")
    func reportsEveryTickCrossed() {
        var tracker = RulerTickTracker(value: 72.4)
        // The caller fires once for this — five taps inside one frame is a
        // buzz, not five taps — but the count is honest.
        #expect(tracker.advance(to: 72.9) == 5)
        #expect(tracker.advance(to: 72.9) == 0)
    }

    @Test("A drag pinned against the clamp goes quiet")
    func silentAtTheClamp() {
        let translations = (1...120).map { Double($0) * RulerGeometry.pointsPerTick }
        // From 20.2 there are two ticks of travel left, then nothing.
        #expect(taps(from: 20.2, translations: translations) == 2)
    }
}
