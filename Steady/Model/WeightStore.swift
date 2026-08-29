//
//  WeightStore.swift
//  Steady
//
//  The observable state every screen reads from. Views never compute the trend
//  themselves and never talk to HealthKit themselves.
//

import Foundation
import Observation

/// The app's single source of truth: the readings, the trend derived from them,
/// and what Apple Health is currently letting us do.
///
/// There is no cache and no local copy — HealthKit is the database and this is a
/// view onto it, refreshed on appear and whenever Health reports a change.
@MainActor
@Observable
final class WeightStore {

    /// One reading per calendar day, oldest first.
    private(set) var readings: [WeightSample] = []

    /// The α = 0.18 EWMA over the entire history, index-aligned with `readings`.
    private(set) var trend: [Double] = []

    private(set) var accessState: HealthAccessState = .granted

    /// True until the first read completes, so the empty state is not shown to
    /// somebody who simply has not been queried yet.
    private(set) var hasLoaded = false

    private let health: HealthServicing
    private let calendar: Calendar

    init(health: HealthServicing, calendar: Calendar = .current) {
        self.health = health
        self.calendar = calendar
    }

    // MARK: - Derived

    /// The daily readings as plain values, which is what `TrendEngine` works in.
    var values: [Double] { readings.map(\.kilograms) }

    var hasReadings: Bool { !readings.isEmpty }

    /// The current trend value, or `nil` before the first reading.
    var currentTrend: Double? { trend.last }

    /// Today's reading, if there is one. Its presence is what switches the Log
    /// screen to the already-logged state.
    var todayReading: WeightSample? {
        let today = calendar.startOfDay(for: .now)
        return readings.last { calendar.startOfDay(for: $0.date) == today }
    }

    /// Yesterday's reading, if there is one.
    var yesterdayReading: WeightSample? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) else {
            return nil
        }
        return readings.last { calendar.startOfDay(for: $0.date) == yesterday }
    }

    /// The value the ruler opens on: yesterday's reading, falling back to the
    /// most recent reading, falling back to 70.0.
    var openingValue: Double {
        let value = yesterdayReading?.kilograms
            ?? readings.last?.kilograms
            ?? WeightSample.fallbackValue
        return WeightSample.snap(value)
    }

    func summary(for period: Period) -> TrendEngine.Summary {
        TrendEngine.summary(for: period, trend: trend)
    }

    func stats(for period: Period) -> TrendEngine.Stats {
        TrendEngine.stats(for: period, values: values, trend: trend)
    }

    func series(for period: Period) -> TrendEngine.Series {
        TrendEngine.series(for: period, values: values, trend: trend)
    }

    // MARK: - Commands

    func refresh() async {
        accessState = await health.accessState()
        readings = (try? await health.readDailyReadings()) ?? []
        trend = TrendEngine.trend(for: values)
        hasLoaded = true
    }

    func requestAuthorization() async {
        try? await health.requestAuthorization()
        await refresh()
    }

    func save(kilograms: Double, on date: Date = .now) async {
        try? await health.save(kilograms: kilograms, on: date)
        await refresh()
    }

    /// Deletes a reading. Only succeeds for readings Steady wrote — a smart
    /// scale's sample is not ours to remove.
    @discardableResult
    func delete(_ sample: WeightSample) async -> Bool {
        do {
            try await health.delete(sample)
            await refresh()
            return true
        } catch {
            return false
        }
    }

    /// Keeps the app in step with weights written elsewhere.
    func observeChanges() async {
        for await _ in await health.changes() {
            await refresh()
        }
    }
}
