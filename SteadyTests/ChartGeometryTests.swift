//
//  ChartGeometryTests.swift
//  SteadyTests
//

import CoreGraphics
import Foundation
import Testing
@testable import Steady

@Suite("ChartGeometry")
struct ChartGeometryTests {

    private let width: CGFloat = 306
    private let height: CGFloat = 140

    @Test("The week chart matches reference-weight.js point for point")
    func weekMatchesReference() {
        let values = ReferenceSeries.raw
        let series = TrendEngine.series(for: .week, values: values, trend: TrendEngine.trend(for: values))
        let geometry = ChartGeometry.make(raw: series.raw, trend: series.trend, width: width, height: height)

        let expectedDots: [CGPoint] = [
            CGPoint(x: 0, y: 113.8), CGPoint(x: 51, y: 92.9), CGPoint(x: 102, y: 70.7),
            CGPoint(x: 153, y: 44.7), CGPoint(x: 204, y: 42.9), CGPoint(x: 255, y: 45.1),
            CGPoint(x: 306, y: 37.6)
        ]
        #expect(geometry.dots == expectedDots)

        let expectedTrend: [CGPoint] = [
            CGPoint(x: 0, y: 101.7), CGPoint(x: 51, y: 89.1), CGPoint(x: 102, y: 76.5),
            CGPoint(x: 153, y: 64), CGPoint(x: 204, y: 51.4), CGPoint(x: 255, y: 38.8),
            CGPoint(x: 306, y: 26.2)
        ]
        #expect(geometry.trendPoints == expectedTrend)

        #expect(abs(geometry.minValue - 71.6813454786) < 1e-9)
        #expect(abs(geometry.maxValue - 73.2799208258) < 1e-9)
    }

    @Test("The month chart matches reference-weight.js at both ends")
    func monthMatchesReference() {
        let values = ReferenceSeries.raw
        let series = TrendEngine.series(for: .month, values: values, trend: TrendEngine.trend(for: values))
        let geometry = ChartGeometry.make(raw: series.raw, trend: series.trend, width: width, height: height)
        #expect(geometry.dots.count == 30)
        #expect(geometry.dots.first == CGPoint(x: 0, y: 77.9))
        #expect(geometry.dots.last == CGPoint(x: 306, y: 26.2))
    }

    @Test("The range is padded by 0.3 of the combined span, top and bottom")
    func padFactor() {
        let geometry = ChartGeometry.make(raw: [70, 80], trend: [70, 80], width: width, height: height)
        // span 10, pad 3 -> 67 ... 83
        #expect(abs(geometry.minValue - 67) < 1e-12)
        #expect(abs(geometry.maxValue - 83) < 1e-12)
        #expect(geometry.dots[0].y == 113.8)  // 70 sits 3/16 up a 140 pt box
        #expect(geometry.dots[1].y == 26.3)
    }

    @Test("Padding spans raw and trend together, not either alone")
    func padSpansBothSeries() {
        let geometry = ChartGeometry.make(raw: [70, 71], trend: [60, 90], width: width, height: height)
        // span is 60...90 -> 30, pad 9
        #expect(abs(geometry.minValue - 51) < 1e-12)
        #expect(abs(geometry.maxValue - 99) < 1e-12)
    }

    @Test("A flat series is given a span of 1 rather than collapsing")
    func flatSeries() {
        let geometry = ChartGeometry.make(raw: [72, 72, 72], trend: [72, 72, 72], width: width, height: height)
        #expect(abs(geometry.minValue - 71.7) < 1e-9)
        #expect(abs(geometry.maxValue - 72.3) < 1e-9)
        #expect(geometry.dots.allSatisfy { $0.y == 70 })
    }

    @Test("X is by index, so a single point is centred")
    func singlePointIsCentred() {
        let geometry = ChartGeometry.make(raw: [72], trend: [72], width: width, height: height)
        #expect(geometry.dots.count == 1)
        #expect(geometry.dots[0].x == 153)
        #expect(geometry.drawsLine == false)
    }

    @Test("X is by index, so a skipped day closes up rather than leaving a hole")
    func xIsIndexBased() {
        let geometry = ChartGeometry.make(
            raw: [70, 71, 72, 73, 74],
            trend: [70, 71, 72, 73, 74],
            width: 100,
            height: height
        )
        #expect(geometry.dots.map(\.x) == [0, 25, 50, 75, 100])
    }

    @Test("An empty series lays out to nothing without dividing by zero")
    func emptySeries() {
        let geometry = ChartGeometry.make(raw: [], trend: [], width: width, height: height)
        #expect(geometry.dots.isEmpty)
        #expect(geometry.trendPoints.isEmpty)
        #expect(geometry.drawsLine == false)
        #expect(geometry.y(of: 72) == 70)
    }

    @Test("An arbitrary value lands on the same scale as the plotted points")
    func yOfArbitraryValue() {
        let geometry = ChartGeometry.make(raw: [70, 80], trend: [70, 80], width: width, height: height)
        #expect(geometry.y(of: 75) == 70)
        #expect(geometry.y(of: 70) == geometry.dots[0].y)
    }

    @Test("The pad factor is overridable and defaults to the concept's 0.3")
    func padFactorIsOverridable() {
        #expect(ChartGeometry.defaultPadFactor == 0.3)
        let geometry = ChartGeometry.make(
            raw: [70, 80], trend: [70, 80],
            width: width, height: height, padFactor: 0.34
        )
        #expect(abs(geometry.minValue - 66.6) < 1e-9)
    }

    @Test("Dot radii change with the range")
    func dotRadiiPerPeriod() {
        #expect(Period.week.dotRadius == 4)
        #expect(Period.month.dotRadius == 2.2)
        #expect(Period.year.dotRadius == 1.6)
    }
}
