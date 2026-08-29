//
//  WeightStore.swift
//  Steady
//
//  The observable state every screen reads from. Views never compute the trend
//  themselves and never talk to HealthKit themselves.
//

import Foundation
import Observation

/// Something the user asked for that Apple Health refused.
///
/// Coarse on purpose: the screens have room for one line, and the underlying
/// error is never shown. Nothing here carries a weight value — health data,
/// and anything derived from it, never reaches a log or an error string.
nonisolated enum WeightStoreFailure: Equatable, Sendable {
    /// The authorisation sheet could not be presented, or was dismissed
    /// without granting write access.
    case authorizationFailed
    /// The reading could not be written. A denied write lands here, which is
    /// the case that used to fail silently.
    case saveFailed
    /// The reading could not be removed. Usually another source owns it.
    case deleteFailed
    /// The readings could not be read back. Distinct from having none, because
    /// the empty-start screen would otherwise claim a history that exists is
    /// absent.
    case readFailed

    /// What the Log screen puts on screen. Plain and factual, per the
    /// product's voice.
    var message: String {
        switch self {
        case .authorizationFailed: "Apple Health access could not be granted."
        case .saveFailed: "Apple Health did not accept the entry."
        case .deleteFailed: "Apple Health did not remove the entry."
        case .readFailed: "Apple Health could not be read."
        }
    }
}

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

    /// The last command Apple Health refused, for the screen to render.
    ///
    /// A save that fails silently is the worst outcome here: the user believes
    /// the day is logged, the trend does not move, and nothing says why.
    private(set) var failure: WeightStoreFailure?

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

    /// The four cells under the chart.
    ///
    /// Resolved from the dated readings, not from their positions: Today and
    /// Yesterday are calendar days, and a user who skipped today has neither.
    func stats(for period: Period) -> TrendEngine.Stats {
        TrendEngine.stats(for: period, readings: readings, trend: trend)
    }

    func series(for period: Period) -> TrendEngine.Series {
        TrendEngine.series(for: period, values: values, trend: trend)
    }

    // MARK: - Commands

    func refresh() async {
        accessState = await health.accessState()
        do {
            readings = try await health.readDailyReadings()
            failure = nil
        } catch {
            // A failed read must not look like an empty history: the Trend
            // screen would render the empty-start state and quietly claim the
            // user has never weighed in.
            readings = []
            failure = .readFailed
        }
        trend = TrendEngine.trend(for: values)
        hasLoaded = true
    }

    func requestAuthorization() async {
        failure = nil
        do {
            try await health.requestAuthorization()
        } catch {
            failure = .authorizationFailed
        }
        await refresh()
    }

    /// Writes a reading. Returns whether it landed, so a screen can stay put
    /// rather than advance on a write that did not happen.
    @discardableResult
    func save(kilograms: Double, on date: Date = .now) async -> Bool {
        failure = nil
        do {
            try await health.save(kilograms: kilograms, on: date)
        } catch {
            failure = .saveFailed
            return false
        }
        await refresh()
        return true
    }

    /// Deletes a reading. Only succeeds for readings Steady wrote — a smart
    /// scale's sample is not ours to remove.
    @discardableResult
    func delete(_ sample: WeightSample) async -> Bool {
        failure = nil
        do {
            try await health.delete(sample)
            await refresh()
            return true
        } catch {
            failure = .deleteFailed
            return false
        }
    }

    /// Dismisses the error the screen is showing.
    func clearFailure() {
        failure = nil
    }

    /// Keeps the app in step with weights written elsewhere.
    func observeChanges() async {
        for await _ in await health.changes() {
            await refresh()
        }
    }
}
