//
//  RulerGeometry.swift
//  Steady
//
//  The maths behind the ruler, per design/steady-design-reference.md §5 and
//  STEADY.md §6. Pure value-in / value-out: no SwiftUI, no HealthKit, so the
//  conversion and the snapping can be tested without a simulator.
//

import Foundation

/// The conversion between a drag in points and a weight in kilograms.
///
/// The design draws 25 ticks `14.2` pt apart across a `2.4` kg window, so one
/// tick is `0.1` kg and `14.2` pt is the single constant the whole interaction
/// hangs on. Everything else here follows from it.
nonisolated enum RulerGeometry {

    /// One tick.
    static let kilogramsPerTick: Double = 0.1

    /// The gap between two ticks, `14.2` pt.
    static let pointsPerTick = Double(Metrics.rulerTickSpacing)

    /// `142` pt per kilogram. The drag conversion constant.
    static let pointsPerKilogram = pointsPerTick / kilogramsPerTick

    /// Every fifth tick is drawn tall, so the majors land on whole `0.5` kg.
    static let majorTickInterval = 5

    /// The bounds the drag is clamped to, so it cannot run to absurdity.
    static let range = WeightSample.plausibleRange

    // MARK: - Value and drag

    /// Holds a value inside the plausible range.
    static func clamp(_ kilograms: Double) -> Double {
        min(max(kilograms, range.lowerBound), range.upperBound)
    }

    /// The value the product works in: clamped, then snapped to `0.1` kg.
    ///
    /// Nothing downstream ever sees a finer figure — not the display, not the
    /// Save label, not HealthKit.
    static func snap(_ kilograms: Double) -> Double {
        WeightSample.snap(clamp(kilograms))
    }

    /// The continuous value a drag has reached.
    ///
    /// Dragging **left** — a negative translation — increases the value, because
    /// the ticks travel with the finger and a higher number scrolls in from the
    /// right. The result is deliberately *not* snapped: the strip tracks the
    /// finger 1:1 and only the reading snaps.
    static func value(from start: Double, translation: Double) -> Double {
        clamp(start - translation / pointsPerKilogram)
    }

    /// The reading a continuous value shows — the tick nearest the needle.
    static func tickIndex(for kilograms: Double) -> Int {
        Int((clamp(kilograms) / kilogramsPerTick).rounded())
    }

    /// The weight a tick index stands for.
    static func kilograms(forTick index: Int) -> Double {
        // Deliberately not clamped. The clamp belongs to the *value*, not to the
        // drawing: a ruler does not stop being a ruler past the last reachable
        // reading. Clamping here collapsed every out-of-range index onto the
        // needle, stacking a dozen strokes on top of each other at 20.0 kg and
        // leaving half the strip blank.
        WeightSample.snap(Double(index) * kilogramsPerTick)
    }

    /// A single `0.1` kg step, as the `−` and `+` buttons make it.
    static func stepped(_ kilograms: Double, by steps: Int) -> Double {
        snap(kilograms + Double(steps) * kilogramsPerTick)
    }

    /// Whether a tick is one of the tall ones.
    static func isMajor(tick index: Int) -> Bool {
        index % majorTickInterval == 0
    }

    // MARK: - Strip position

    /// Where a tick sits, measured from the needle.
    static func offsetFromNeedle(ofTick index: Int, at value: Double) -> Double {
        (kilograms(forTick: index) - clamp(value)) * pointsPerKilogram
    }

    /// The ticks that fall inside a strip of `width`, plus one either side so
    /// nothing pops in at the edges.
    static func visibleTicks(at value: Double, width: Double) -> ClosedRange<Int> {
        let centre = tickIndex(for: value)
        let half = Int((width / 2 / pointsPerTick).rounded(.up)) + 1
        return (centre - half)...(centre + half)
    }

    // MARK: - Labels

    /// The visible range end-points printed under the strip: `value ∓ 1.2`,
    /// held inside the plausible range.
    ///
    /// The clamp matters at the ends of the range: at `20.0` an unclamped left
    /// label would read `18.8`, a weight the ruler cannot reach.
    static func bounds(at value: Double) -> (lower: Double, upper: Double) {
        // Also not clamped, for the same reason and one more: the needle is
        // always centred, so a clamped end-point would claim the edge of the
        // strip held a value the centre is already showing. The labels describe
        // the strip that is drawn, and the strip simply stops moving once the
        // value can go no further.
        let centre = clamp(value)
        return (centre - Metrics.rulerHalfWindow, centre + Metrics.rulerHalfWindow)
    }
}

/// Counts the `0.1` kg ticks a drag crosses, so the haptic fires on the
/// crossing rather than on the frame.
///
/// This is the whole haptic rule in a testable shape: it answers "did the
/// reading move to a new tick since you last asked", and it can only answer
/// yes once per tick. A drag that buzzes every frame and one that never buzzes
/// both read as broken, and both are the same bug — asking the wrong question.
nonisolated struct RulerTickTracker: Equatable, Sendable {

    /// The tick the reading last stood on.
    private(set) var tick: Int

    init(value: Double) {
        tick = RulerGeometry.tickIndex(for: value)
    }

    /// Moves to a new continuous value and reports how many ticks were crossed.
    ///
    /// Zero means the reading has not changed and nothing should fire. A fast
    /// flick can cross several ticks between two frames; that is reported
    /// honestly here and the caller decides what to do with it — the haptic
    /// fires once, because five taps inside one frame is a buzz, not five taps.
    @discardableResult
    mutating func advance(to value: Double) -> Int {
        let next = RulerGeometry.tickIndex(for: value)
        defer { tick = next }
        return abs(next - tick)
    }
}
