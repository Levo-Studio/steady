//
//  TrendPreviewData.swift
//  Steady
//
//  Deterministic readings and a stub Health service, so every Trend view ships a
//  light and a dark preview without touching the health database.
//

import Foundation

/// A plausible run of readings, generated the same way every time.
///
/// A slow drift with two out-of-phase wobbles on top of it — enough daily noise
/// that the trend line has something to do, which is the entire point of the
/// screen. Nothing here is real data and nothing here is written anywhere.
nonisolated enum TrendPreviewData {

    static func values(days: Int, start: Double = 74.6) -> [Double] {
        (0..<days).map { i in
            let day = Double(i)
            let drift = -0.011 * day
            let wobble = 0.75 * sin(day * 0.7) + 0.4 * sin(day * 0.23 + 1.1)
            return WeightSample.snap(start + drift + wobble)
        }
    }

    static func samples(days: Int, calendar: Calendar = .current) -> [WeightSample] {
        let today = calendar.startOfDay(for: .now)
        return values(days: days).enumerated().compactMap { index, value in
            guard let date = calendar.date(
                byAdding: .day,
                value: index - (days - 1),
                to: today
            ) else { return nil }
            return WeightSample(
                date: date.addingTimeInterval(7 * 3600),
                kilograms: value,
                sourceBundleIdentifier: "levo-studio.Steady"
            )
        }
    }
}

/// A `HealthServicing` that answers from memory.
///
/// Previews render inside the app target, so they need a service; this one never
/// imports HealthKit and never writes anything.
nonisolated struct StubHealthService: HealthServicing {

    var readings: [WeightSample] = []
    var state: HealthAccessState = .granted

    var isAvailable: Bool { state != .unavailable }

    func requestAuthorization() async throws {}

    func isWriteAuthorized() async -> Bool { state == .granted }

    func accessState() async -> HealthAccessState { state }

    func readDailyReadings() async throws -> [WeightSample] { readings }

    func save(kilograms: Double, on date: Date) async throws {}

    func delete(_ sample: WeightSample) async throws {}

    func changes() async -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
