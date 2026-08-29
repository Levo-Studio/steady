//
//  TrendEngine.swift
//  Steady
//
//  The trend maths. A pure Swift port of design/reference-weight.js — value in,
//  value out, no SwiftUI, no HealthKit.
//

import Foundation

/// Everything Steady knows how to compute about a run of weight readings.
///
/// The whole product is one number: an exponential weighted moving average with
/// `α = 0.18`. Its centre of mass is `(1 − α) / α ≈ 4.6` days and its half-life
/// is `ln(0.5) / ln(0.82) ≈ 3.5` days, which absorbs a salt or carbohydrate
/// swing of a kilo or two while still turning inside a week of a real change of
/// direction. It is fixed by the design and is not a tuning knob.
nonisolated enum TrendEngine {

    /// The trend smoothing factor. Fixed.
    static let alpha: Double = 0.18

    /// The second pass applied to the year view's weekly means, which are
    /// already smooth enough that the primary EWMA traced every wiggle.
    static let yearAlpha: Double = 0.3

    /// The year view is 52 whole weeks.
    static let yearSpanInDays = 364

    // MARK: - Readings

    /// Collapses HealthKit samples to one value per calendar day, in date order.
    ///
    /// Two rules, in this order:
    ///
    /// 1. **If Steady itself wrote a sample for that day, that sample is the
    ///    day's value.** An entry the user made by hand always beats another
    ///    source. Without this a smart scale that writes at 06:00 would make
    ///    the user's own 20:00 entry invisible — the app would show a number
    ///    the user did not type and offer no way to correct it. Where Steady
    ///    somehow wrote more than once, the latest wins, because that is the
    ///    most recent thing the user said.
    /// 2. Otherwise the day is represented by its **earliest** sample, because
    ///    the product is about morning weight taken under consistent
    ///    conditions.
    ///
    /// Days with no reading are simply absent — the series is never
    /// interpolated or back-filled, and a gap makes the line's recovery slower
    /// in wall-clock terms, which is honest.
    ///
    /// - Parameter steadyBundleIdentifier: Steady's own bundle identifier.
    ///   `nil` disables rule 1 and leaves the earliest-sample rule alone,
    ///   which is what a caller with no notion of ownership wants.
    static func dailyValues(
        from samples: [WeightSample],
        calendar: Calendar = .current,
        steadyBundleIdentifier: String?
    ) -> [Double] {
        dailyReadings(
            from: samples,
            calendar: calendar,
            steadyBundleIdentifier: steadyBundleIdentifier
        ).map(\.kilograms)
    }

    /// As `dailyValues(from:calendar:steadyBundleIdentifier:)`, but keeping the
    /// sample that represents each day so the caller can attribute or delete it.
    static func dailyReadings(
        from samples: [WeightSample],
        calendar: Calendar = .current,
        steadyBundleIdentifier: String?
    ) -> [WeightSample] {
        var chosenByDay: [Date: WeightSample] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.date)
            guard let existing = chosenByDay[day] else {
                chosenByDay[day] = sample
                continue
            }
            chosenByDay[day] = preferred(
                existing, over: sample,
                steadyBundleIdentifier: steadyBundleIdentifier
            )
        }
        return chosenByDay
            .sorted { $0.key < $1.key }
            .map(\.value)
    }

    /// Which of two samples from the same day represents that day.
    private static func preferred(
        _ a: WeightSample,
        over b: WeightSample,
        steadyBundleIdentifier: String?
    ) -> WeightSample {
        let aIsOurs = a.isOwnedBySteady(appBundleIdentifier: steadyBundleIdentifier)
        let bIsOurs = b.isOwnedBySteady(appBundleIdentifier: steadyBundleIdentifier)
        if aIsOurs != bIsOurs { return aIsOurs ? a : b }
        // Both Steady's, or neither: the user's latest word, or the morning.
        if aIsOurs { return a.date >= b.date ? a : b }
        return a.date <= b.date ? a : b
    }

    // MARK: - Smoothing

    /// `e[0] = v[0]`, `e[i] = α·v[i] + (1 − α)·e[i−1]`.
    static func ewma(_ values: [Double], alpha: Double) -> [Double] {
        guard var e = values.first else { return [] }
        var out: [Double] = []
        out.reserveCapacity(values.count)
        for (i, v) in values.enumerated() {
            e = i == 0 ? v : alpha * v + (1 - alpha) * e
            out.append(e)
        }
        return out
    }

    /// The trend series, run once over the **entire** history, oldest to newest.
    ///
    /// Ranges are sliced off the end of this result and never recomputed, so a
    /// given day shows the same trend value on the month chart and the year
    /// chart.
    static func trend(for values: [Double]) -> [Double] {
        ewma(values, alpha: alpha)
    }

    /// A least-squares straight line through `y`, evaluated at every index.
    ///
    /// The week view uses this instead of the EWMA: over seven points the EWMA
    /// still carries most of the raw wobble, so the chart would show two noisy
    /// lines instead of a calm line with readings scattered around it. The
    /// straight fit gives the week the one thing worth knowing — direction.
    static func leastSquaresFit(_ y: [Double]) -> [Double] {
        let n = y.count
        guard n > 0 else { return [] }
        let meanX = Double(n - 1) / 2
        let meanY = y.reduce(0, +) / Double(n)
        var numerator = 0.0
        var denominator = 0.0
        for (i, v) in y.enumerated() {
            let dx = Double(i) - meanX
            numerator += dx * (v - meanY)
            denominator += dx * dx
        }
        let slope = denominator == 0 ? 0 : numerator / denominator
        return (0..<n).map { meanY + slope * (Double($0) - meanX) }
    }

    /// The trailing 52 weekly means of `values`.
    ///
    /// With a full year or more of readings this matches the reference exactly:
    /// 52 buckets of 7, starting at `count − 364`. With less history it buckets
    /// what exists from the oldest reading forward, which leaves the most recent
    /// bucket partial rather than inventing days that were never weighed.
    static func weeklyMeans(_ values: [Double]) -> [Double] {
        let count = values.count
        guard count > 0 else { return [] }
        let start = max(0, count - yearSpanInDays)
        var out: [Double] = []
        var i = start
        while i < count {
            let end = min(i + 7, count)
            let bucket = values[i..<end]
            out.append(bucket.reduce(0, +) / Double(bucket.count))
            i += 7
        }
        return out
    }

    // MARK: - Series per range

    /// The raw readings and the trend line for one range, ready to plot.
    struct Series: Equatable, Sendable {
        /// The plotted readings. Daily on Week and Month, weekly means on Year.
        var raw: [Double]
        /// The line drawn over them.
        var trend: [Double]
    }

    /// Slices the range off the end of the history and produces the line the
    /// design specifies for it.
    ///
    /// - Parameters:
    ///   - values: the full daily reading history, oldest first.
    ///   - trend: the full EWMA over that history, from `trend(for:)`.
    static func series(for period: Period, values: [Double], trend: [Double]) -> Series {
        switch period {
        case .week:
            let raw = Array(values.suffix(period.spanInDays))
            return Series(raw: raw, trend: leastSquaresFit(raw))
        case .month:
            return Series(
                raw: Array(values.suffix(period.spanInDays)),
                trend: Array(trend.suffix(period.spanInDays))
            )
        case .year:
            let means = weeklyMeans(values)
            return Series(raw: means, trend: ewma(means, alpha: yearAlpha))
        }
    }

    // MARK: - Headline

    /// The figures above the chart.
    struct Summary: Equatable, Sendable {
        /// "Trend weight", prefixed `⌀ ` on Month and Year. The prefix is the
        /// entire mechanism that tells the user the headline changed meaning.
        var label: String
        /// The `64` pt figure, one decimal, or `—` with no readings.
        var headline: String
        /// The 13 pt accent line under it. Empty on Week.
        var subLine: String
        /// The delta badge.
        var badge: String
        /// The per-week change, unformatted. `nil` with no readings.
        var perWeek: Double?
        /// The current trend value. `nil` with no readings.
        var currentTrend: Double?
    }

    /// Headline, sub-line and badge for one range.
    ///
    /// - Parameter trend: the full EWMA over the entire history.
    static func summary(for period: Period, trend: [Double]) -> Summary {
        let label = period.headlineIsAverage ? "⌀ Trend weight" : "Trend weight"
        let n = trend.count

        guard n > 0, let current = trend.last else {
            // Design reference §7.3: an em dash in `mut`, a `— kg` badge, and a
            // sub-line that keeps its height.
            return Summary(
                label: label,
                headline: "—",
                subLine: "\u{00A0}",
                badge: "— kg",
                perWeek: nil,
                currentTrend: nil
            )
        }

        switch period {
        case .week:
            let startIndex = max(0, n - 8)
            let perWeek = current - trend[startIndex]
            return Summary(
                label: label,
                headline: format(current, decimals: 1),
                subLine: "",
                badge: "\(format(perWeek, decimals: 1, signed: true)) kg this week",
                perWeek: perWeek,
                currentTrend: current
            )

        case .month, .year:
            let span = period.spanInDays
            let window = trend.suffix(span)
            let mean = window.reduce(0, +) / Double(window.count)
            let startIndex = max(0, n - span)
            let days = n - startIndex
            let perWeek = days > 0 ? (current - trend[startIndex]) / Double(days) * 7 : 0
            return Summary(
                label: label,
                headline: format(mean, decimals: 1),
                subLine: "this week \(format(current, decimals: 1))",
                badge: "⌀ \(format(perWeek, decimals: period.perWeekDecimals, signed: true)) kg",
                perWeek: perWeek,
                currentTrend: current
            )
        }
    }

    // MARK: - Stats grid

    /// The four cells under the chart.
    struct Stats: Equatable, Sendable {
        /// Today's raw reading, not a trend value, resolved by calendar date.
        /// `nil` when today has no reading — the cell then shows an em dash,
        /// which is §7.3's treatment of an absent value.
        var today: Double?
        /// Yesterday's raw reading, resolved by calendar date. `nil` when
        /// yesterday has no reading.
        var yesterday: Double?
        /// The arithmetic mean of the last seven raw readings.
        var sevenDayAverage: Double?
        /// The per-week change. Same figure as the badge.
        var perWeek: Double?
        /// The label on the fourth cell, which changes with the range.
        var perWeekLabel: String
        /// Decimals on the fourth cell: one on Week, two on Month and Year.
        var perWeekDecimals: Int
    }

    /// The four cells under the chart.
    ///
    /// Today and Yesterday are resolved by **calendar date**, not by position
    /// in the history. Design reference §7.8 labels them "today's raw reading"
    /// and "yesterday's raw reading", and a user who skipped today has neither
    /// — taking the last two readings instead puts an older day's weight under
    /// a "Today" label and sends the tap to Edit today for a day that is not
    /// today. When the day genuinely has no reading the value is `nil` and the
    /// cell renders the em dash.
    ///
    /// The seven-day average stays positional: §7.8 defines it as the mean of
    /// the last seven raw readings, not of the last seven days.
    ///
    /// - Parameters:
    ///   - readings: the daily reading history, oldest first.
    ///   - trend: the full EWMA over that history.
    ///   - now: the moment "today" is measured from.
    ///   - calendar: the calendar the days are bucketed in.
    static func stats(
        for period: Period,
        readings: [WeightSample],
        trend: [Double],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Stats {
        let values = readings.map(\.kilograms)
        let recent = values.suffix(7)
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        return Stats(
            today: reading(on: today, in: readings, calendar: calendar),
            yesterday: reading(on: yesterday, in: readings, calendar: calendar),
            sevenDayAverage: recent.isEmpty ? nil : recent.reduce(0, +) / Double(recent.count),
            perWeek: summary(for: period, trend: trend).perWeek,
            perWeekLabel: period.perWeekLabel,
            perWeekDecimals: period.perWeekDecimals
        )
    }

    /// The value recorded on one calendar day, if any.
    private static func reading(
        on day: Date?,
        in readings: [WeightSample],
        calendar: Calendar
    ) -> Double? {
        guard let day else { return nil }
        return readings.last { calendar.startOfDay(for: $0.date) == day }?.kilograms
    }

    /// The positional variant, which cannot tell "today" from "the most recent
    /// reading". Kept only so `WeightStore` still compiles; callers that have
    /// the dated readings must use `stats(for:readings:trend:now:calendar:)`.
    @available(
        *, deprecated,
        message: "Resolves Today and Yesterday positionally. Use stats(for:readings:trend:now:calendar:)."
    )
    static func stats(for period: Period, values: [Double], trend: [Double]) -> Stats {
        let recent = values.suffix(7)
        return Stats(
            today: values.last,
            yesterday: values.count >= 2 ? values[values.count - 2] : nil,
            sevenDayAverage: recent.isEmpty ? nil : recent.reduce(0, +) / Double(recent.count),
            perWeek: summary(for: period, trend: trend).perWeek,
            perWeekLabel: period.perWeekLabel,
            perWeekDecimals: period.perWeekDecimals
        )
    }

    // MARK: - Direction

    /// Which way a run of trend values is going. Spoken by the chart's
    /// VoiceOver summary, which is the only place the picture becomes a
    /// sentence.
    enum Direction: String, Equatable, Sendable {
        case rising
        case falling
        case level

        /// The word VoiceOver reads.
        var spoken: String { rawValue }
    }

    /// Below this much total change over the plotted range the line is called
    /// level rather than rising or falling. It is half of the 0.1 kg the
    /// product rounds to, so a change too small to have been typed is not
    /// announced as a direction.
    static let levelThreshold: Double = 0.05

    /// The direction of a trend line from its first plotted value to its last.
    static func direction(from first: Double, to last: Double) -> Direction {
        let change = last - first
        guard abs(change) >= levelThreshold else { return .level }
        return change > 0 ? .rising : .falling
    }

    // MARK: - Formatting

    /// A weight figure, or an em dash when there is nothing to show.
    ///
    /// Positive values carry an explicit `+` when `signed` is set. Formatting is
    /// locale-independent: the design is drawn with a decimal point.
    static func format(_ value: Double?, decimals: Int, signed: Bool = false) -> String {
        guard let value else { return "—" }
        // Keep a value that *rounds* to zero from printing as "-0.0". Guarding
        // on the raw value is not enough: −0.04 is not zero but still prints
        // as "-0.0" at one decimal.
        let scale = pow(10.0, Double(decimals))
        let rounded = (value * scale).rounded() / scale
        let normalised = rounded == 0 ? 0 : rounded
        return String(format: "%\(signed ? "+" : "").\(decimals)f", normalised)
    }
}
