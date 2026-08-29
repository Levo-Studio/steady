//
//  ChartGeometry.swift
//  Steady
//
//  Value series -> points. A pure port of `chart()` from
//  design/reference-weight.js, per design reference §7.8.
//

import CoreGraphics
import Foundation

/// The laid-out geometry of one chart: where every dot sits, where the trend
/// line runs, and how to place an arbitrary value on the same scale.
///
/// Pure and deterministic — no SwiftUI, no HealthKit. The chart is drawn by hand
/// with `Canvas` and `Path` rather than Swift Charts precisely so that these
/// numbers are the ones that reach the screen.
nonisolated struct ChartGeometry: Equatable, Sendable {

    /// The raw readings, one point each.
    var dots: [CGPoint]
    /// The trend polyline.
    var trendPoints: [CGPoint]
    /// The padded bottom of the value range.
    var minValue: Double
    /// The padded top of the value range.
    var maxValue: Double
    var width: CGFloat
    var height: CGFloat

    /// The default padding factor. The concept passes `0.3` explicitly,
    /// overriding the reference function's own `0.34`.
    static let defaultPadFactor: Double = 0.3

    /// Lays out one range.
    ///
    /// The value range spans raw and trend together, then both ends are padded
    /// by `(max − min) × padFactor`. When every value is identical the span is
    /// treated as `1`, so a flat week does not collapse to a single row of
    /// pixels.
    ///
    /// X is `i / (n − 1) × width`, or the centre when there is one point —
    /// **by index, not by date**, so a skipped day closes up rather than
    /// leaving a hole.
    static func make(
        raw: [Double],
        trend: [Double],
        width: CGFloat,
        height: CGFloat,
        padFactor: Double = defaultPadFactor
    ) -> ChartGeometry {
        let all = raw + trend
        guard !all.isEmpty else {
            return ChartGeometry(
                dots: [], trendPoints: [],
                minValue: 0, maxValue: 1,
                width: width, height: height
            )
        }

        var lower = all.min() ?? 0
        var upper = all.max() ?? 1
        let span = (upper - lower) == 0 ? 1 : (upper - lower)
        let pad = span * padFactor
        lower -= pad
        upper += pad

        let n = raw.count
        let x: (Int) -> CGFloat = { i in
            let value = n > 1 ? (CGFloat(i) / CGFloat(n - 1)) * width : width / 2
            return round1(value)
        }
        let y: (Double) -> CGFloat = { value in
            round1(height - CGFloat((value - lower) / (upper - lower)) * height)
        }

        return ChartGeometry(
            dots: raw.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) },
            trendPoints: trend.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) },
            minValue: lower,
            maxValue: upper,
            width: width,
            height: height
        )
    }

    /// Whether there are enough points to draw a line at all. A range with
    /// fewer than two readings draws its dots and no line.
    var drawsLine: Bool { trendPoints.count >= 2 }

    /// Where an arbitrary value sits on this chart's scale.
    func y(of value: Double) -> CGFloat {
        guard maxValue > minValue else { return height / 2 }
        return Self.round1(height - CGFloat((value - minValue) / (maxValue - minValue)) * height)
    }

    /// The reference rounds every coordinate to one decimal before it reaches
    /// the SVG. Reproduced so the Swift geometry is identical to it.
    static func round1(_ value: CGFloat) -> CGFloat {
        (value * 10).rounded() / 10
    }
}
