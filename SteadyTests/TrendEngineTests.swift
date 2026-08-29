//
//  TrendEngineTests.swift
//  SteadyTests
//

import Foundation
import Testing
@testable import Steady

@Suite("TrendEngine")
struct TrendEngineTests {

    // MARK: - EWMA

    @Test("EWMA seeds on the first value and matches hand computation")
    func ewmaHandComputed() {
        let e = TrendEngine.ewma([70, 71, 72], alpha: 0.18)
        // e0 = 70
        // e1 = 0.18 × 71 + 0.82 × 70   = 70.18
        // e2 = 0.18 × 72 + 0.82 × 70.18 = 70.5076
        #expect(e.count == 3)
        #expect(abs(e[0] - 70) < 1e-12)
        #expect(abs(e[1] - 70.18) < 1e-12)
        #expect(abs(e[2] - 70.5076) < 1e-12)
    }

    @Test("EWMA of a constant series is that constant")
    func ewmaConstant() {
        let e = TrendEngine.trend(for: Array(repeating: 72.4, count: 20))
        #expect(e.allSatisfy { abs($0 - 72.4) < 1e-12 })
    }

    @Test("EWMA handles empty and single-element input")
    func ewmaDegenerate() {
        #expect(TrendEngine.trend(for: []).isEmpty)
        #expect(TrendEngine.trend(for: [81.3]) == [81.3])
    }

    @Test("A single 1.5 kg spike moves the line by alpha times the spike")
    func ewmaSpike() {
        let flat = Array(repeating: 70.0, count: 30)
        let spiked = flat + [71.5]
        let e = TrendEngine.trend(for: spiked)
        #expect(abs(e.last! - (70 + 0.18 * 1.5)) < 1e-9)
    }

    @Test("The trend over the reference series matches reference-weight.js")
    func ewmaMatchesReference() {
        let trend = TrendEngine.trend(for: ReferenceSeries.raw)
        #expect(trend.count == 400)
        #expect(abs(trend[399] - 72.3913904307) < 1e-9)
        #expect(abs(trend[392] - 71.6044092771) < 1e-9)
    }

    // MARK: - The week's least-squares fit

    @Test("The fit of a straight line is that line")
    func fitExactLine() {
        let fitted = TrendEngine.leastSquaresFit([0, 2, 4, 6])
        for (a, b) in zip(fitted, [0.0, 2, 4, 6]) {
            #expect(abs(a - b) < 1e-12)
        }
    }

    @Test("The fit recovers a known slope through noisy points")
    func fitKnownSlope() {
        // mean x = 2, mean y = 3, numerator 8, denominator 10 -> slope 0.8
        let fitted = TrendEngine.leastSquaresFit([1, 3, 2, 5, 4])
        let expected = [1.4, 2.2, 3.0, 3.8, 4.6]
        for (a, b) in zip(fitted, expected) {
            #expect(abs(a - b) < 1e-12)
        }
    }

    @Test("The fit of a flat series has zero slope")
    func fitFlat() {
        let fitted = TrendEngine.leastSquaresFit(Array(repeating: 72.0, count: 7))
        #expect(fitted.allSatisfy { abs($0 - 72) < 1e-12 })
    }

    @Test("The fit handles empty and single-element input")
    func fitDegenerate() {
        #expect(TrendEngine.leastSquaresFit([]).isEmpty)
        #expect(TrendEngine.leastSquaresFit([70]) == [70])
    }

    // MARK: - Ranges

    @Test("The week draws a straight fit, not the EWMA")
    func weekSeriesIsAFit() {
        let values = ReferenceSeries.raw
        let series = TrendEngine.series(for: .week, values: values, trend: TrendEngine.trend(for: values))
        #expect(series.raw.count == 7)
        #expect(series.trend == TrendEngine.leastSquaresFit(series.raw))
        // A straight line has a constant first difference.
        let deltas = zip(series.trend.dropFirst(), series.trend).map(-)
        for delta in deltas {
            #expect(abs(delta - deltas[0]) < 1e-9)
        }
    }

    @Test("The month slices the whole-history EWMA rather than recomputing it")
    func monthSeriesSlicesTheTrend() {
        let values = ReferenceSeries.raw
        let trend = TrendEngine.trend(for: values)
        let series = TrendEngine.series(for: .month, values: values, trend: trend)
        #expect(series.raw.count == 30)
        #expect(series.trend == Array(trend.suffix(30)))
    }

    @Test("The year is 52 weekly means run through a second EWMA at alpha 0.3")
    func yearSeries() {
        let values = ReferenceSeries.raw
        let series = TrendEngine.series(for: .year, values: values, trend: TrendEngine.trend(for: values))
        #expect(series.raw.count == 52)
        #expect(abs(series.raw[0] - 71.9533419028) < 1e-9)
        #expect(abs(series.raw[51] - 72.5495907986) < 1e-9)
        #expect(abs(series.trend[51] - 71.6585416070) < 1e-9)
        #expect(series.trend == TrendEngine.ewma(series.raw, alpha: 0.3))
    }

    @Test("A day shows the same trend value on the month chart and the year chart")
    func trendIsNotRecomputedPerRange() {
        let values = ReferenceSeries.raw
        let trend = TrendEngine.trend(for: values)
        let month = TrendEngine.series(for: .month, values: values, trend: trend)
        #expect(month.trend.last == trend.last)
    }

    // MARK: - Summary

    @Test("The week headline is the current trend value with one decimal")
    func summaryWeek() {
        let summary = TrendEngine.summary(for: .week, trend: TrendEngine.trend(for: ReferenceSeries.raw))
        #expect(summary.label == "Trend weight")
        #expect(summary.headline == "72.4")
        #expect(summary.subLine == "")
        #expect(summary.badge == "+0.8 kg this week")
        #expect(abs(summary.perWeek! - 0.7869811536160256) < 1e-9)
    }

    @Test("The month headline is the mean trend, and its badge carries two decimals")
    func summaryMonth() {
        let summary = TrendEngine.summary(for: .month, trend: TrendEngine.trend(for: ReferenceSeries.raw))
        #expect(summary.label == "⌀ Trend weight")
        #expect(summary.headline == "71.5")
        #expect(summary.subLine == "this week 72.4")
        #expect(summary.badge == "⌀ +0.23 kg")
        #expect(abs(summary.perWeek! - 0.23102213466878352) < 1e-9)
    }

    @Test("The year headline is the mean trend over 364 days, badge to two decimals")
    func summaryYear() {
        let summary = TrendEngine.summary(for: .year, trend: TrendEngine.trend(for: ReferenceSeries.raw))
        #expect(summary.label == "⌀ Trend weight")
        #expect(summary.headline == "69.9")
        #expect(summary.subLine == "this week 72.4")
        #expect(summary.badge == "⌀ -0.01 kg")
        #expect(abs(summary.perWeek! - (-0.00795237941802868)) < 1e-9)
    }

    @Test("One decimal on Week, two on Month and Year")
    func summaryDecimalsPerRange() {
        // A rise of 0.007 kg per week is 0.0 at one decimal and 0.01 at two,
        // which is exactly why the decimal count changes with the range.
        let values = (0..<400).map { 70.0 + Double($0) * 0.001 }
        let trend = TrendEngine.trend(for: values)
        #expect(TrendEngine.summary(for: .week, trend: trend).badge == "+0.0 kg this week")
        #expect(TrendEngine.summary(for: .month, trend: trend).badge == "⌀ +0.01 kg")
        #expect(TrendEngine.summary(for: .year, trend: trend).badge == "⌀ +0.01 kg")
    }

    @Test("With no readings the headline is an em dash and the sub-line keeps its height")
    func summaryEmpty() {
        for period in Period.allCases {
            let summary = TrendEngine.summary(for: period, trend: [])
            #expect(summary.headline == "—")
            #expect(summary.badge == "— kg")
            #expect(summary.subLine == "\u{00A0}")
            #expect(summary.perWeek == nil)
            #expect(summary.currentTrend == nil)
        }
    }

    @Test("A single reading reports no change rather than crashing")
    func summarySingleReading() {
        let trend = TrendEngine.trend(for: [72.4])
        #expect(TrendEngine.summary(for: .week, trend: trend).headline == "72.4")
        #expect(TrendEngine.summary(for: .week, trend: trend).perWeek == 0)
        #expect(TrendEngine.summary(for: .month, trend: trend).headline == "72.4")
        #expect(TrendEngine.summary(for: .year, trend: trend).perWeek == 0)
    }

    // MARK: - Stats

    @Test("The four stats match the reference metrics")
    func statsMatchReference() {
        let values = ReferenceSeries.raw
        let stats = TrendEngine.stats(for: .week, values: values, trend: TrendEngine.trend(for: values))
        #expect(TrendEngine.format(stats.today, decimals: 1) == "72.9")
        #expect(TrendEngine.format(stats.yesterday, decimals: 1) == "72.8")
        #expect(TrendEngine.format(stats.sevenDayAverage, decimals: 1) == "72.5")
        #expect(stats.perWeekLabel == "Last week")
        #expect(stats.perWeekDecimals == 1)
    }

    @Test("The fourth stat is relabelled and re-scaled on Month and Year")
    func statsPerWeekLabel() {
        let values = ReferenceSeries.raw
        let trend = TrendEngine.trend(for: values)
        for period in [Period.month, .year] {
            let stats = TrendEngine.stats(for: period, values: values, trend: trend)
            #expect(stats.perWeekLabel == "⌀ per week")
            #expect(stats.perWeekDecimals == 2)
        }
    }

    @Test("Stats are nil rather than zero when there is nothing to average")
    func statsEmpty() {
        let stats = TrendEngine.stats(for: .week, values: [], trend: [])
        #expect(stats.today == nil)
        #expect(stats.yesterday == nil)
        #expect(stats.sevenDayAverage == nil)
        #expect(TrendEngine.format(stats.today, decimals: 1) == "—")
    }

    @Test("The seven-day average uses only the readings that exist")
    func statsSevenDayAverageWithFewerReadings() {
        let stats = TrendEngine.stats(for: .week, values: [70, 72], trend: TrendEngine.trend(for: [70, 72]))
        #expect(abs(stats.sevenDayAverage! - 71) < 1e-12)
    }

    // MARK: - Missing days

    /// A fixed UTC calendar and a UTC midnight, so day bucketing does not
    /// depend on where the tests happen to run.
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var midnightUTC: Date { Date(timeIntervalSince1970: 1_699_920_000) }

    @Test("Skipped days are absent, not interpolated, and X is by index")
    func gapsAreNotBackFilled() {
        let calendar = utc
        let start = midnightUTC
        let dates = [0, 1, 5, 6].map { calendar.date(byAdding: .day, value: $0, to: start)! }
        let samples = zip(dates, [70.0, 70.4, 71.0, 71.2]).map {
            WeightSample(date: $0.0, kilograms: $0.1)
        }
        let values = TrendEngine.dailyValues(from: samples, calendar: calendar)
        #expect(values == [70.0, 70.4, 71.0, 71.2])
        // Four readings across six calendar days still produce four points.
        #expect(TrendEngine.trend(for: values).count == 4)
    }

    @Test("A day is represented by its earliest sample")
    func dayCollapsesToTheEarliestSample() {
        let calendar = utc
        let morning = midnightUTC.addingTimeInterval(7 * 3600)
        let evening = morning.addingTimeInterval(12 * 3600)
        let samples = [
            WeightSample(date: evening, kilograms: 73.1),
            WeightSample(date: morning, kilograms: 72.4)
        ]
        #expect(TrendEngine.dailyValues(from: samples, calendar: calendar) == [72.4])
    }

    @Test("Readings arrive in date order regardless of the order they came in")
    func readingsAreSortedByDay() {
        let calendar = utc
        let start = midnightUTC
        let samples = [2, 0, 1].map {
            WeightSample(
                date: calendar.date(byAdding: .day, value: $0, to: start)!,
                kilograms: 70 + Double($0)
            )
        }
        #expect(TrendEngine.dailyValues(from: samples, calendar: calendar) == [70, 71, 72])
    }

    @Test("Weekly means bucket short histories without inventing days")
    func weeklyMeansShortHistory() {
        let means = TrendEngine.weeklyMeans(Array(repeating: 70.0, count: 10))
        #expect(means.count == 2)
        #expect(means.allSatisfy { abs($0 - 70) < 1e-12 })
        #expect(TrendEngine.weeklyMeans([]).isEmpty)
    }

    // MARK: - Formatting

    @Test("Positive values carry an explicit plus and negatives a minus")
    func formatting() {
        #expect(TrendEngine.format(0.3, decimals: 1, signed: true) == "+0.3")
        #expect(TrendEngine.format(-0.3, decimals: 1, signed: true) == "-0.3")
        #expect(TrendEngine.format(0.03, decimals: 2, signed: true) == "+0.03")
        #expect(TrendEngine.format(0, decimals: 2, signed: true) == "+0.00")
        #expect(TrendEngine.format(72.44, decimals: 1) == "72.4")
        #expect(TrendEngine.format(nil, decimals: 1) == "—")
    }
}
