//
//  LogPreviewSupport.swift
//  Steady
//
//  Debug-only scaffolding so every Log state has a light and a dark preview
//  without touching the real health database.
//

#if DEBUG
import SwiftUI

/// A `HealthServicing` that answers from an array. No `HKHealthStore`, no
/// authorisation sheet, nothing written anywhere.
struct PreviewHealthService: HealthServicing {

    var readings: [WeightSample] = []
    var state: HealthAccessState = .granted

    var isAvailable: Bool { true }

    func requestAuthorization() async throws {}
    func isWriteAuthorized() async -> Bool { state == .granted }
    func accessState() async -> HealthAccessState { state }
    func readDailyReadings() async throws -> [WeightSample] { readings }
    func save(kilograms: Double, on date: Date) async throws {}
    func delete(_ sample: WeightSample) async throws {}
    func changes() async -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

extension WeightSample {

    /// A plausible run of daily readings ending today, so the trend and the
    /// "vs trend" line have something real to say.
    static func previewHistory(
        days: Int = 30,
        today: Double? = 72.4,
        todaySource: String? = "levo-studio.Steady"
    ) -> [WeightSample] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        var out: [WeightSample] = []
        for offset in stride(from: days - 1, through: 1, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: start) else { continue }
            let wobble = sin(Double(offset) * 1.1) * 0.6
            out.append(
                WeightSample(
                    date: date.addingTimeInterval(7 * 3600 + 14 * 60),
                    kilograms: snap(72.9 + wobble - Double(days - offset) * 0.01),
                    sourceBundleIdentifier: "levo-studio.Steady"
                )
            )
        }
        if let today {
            out.append(
                WeightSample(
                    date: start.addingTimeInterval(7 * 3600 + 14 * 60),
                    kilograms: today,
                    sourceBundleIdentifier: todaySource
                )
            )
        }
        return out
    }
}

/// Hosts a Log screen with a seeded store, in one colour scheme.
struct LogPreviewHost<Content: View>: View {

    let scheme: ColorScheme
    let readings: [WeightSample]
    @ViewBuilder let content: Content

    @State private var store: WeightStore
    @State private var router = AppRouter()

    init(
        scheme: ColorScheme,
        readings: [WeightSample] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.scheme = scheme
        self.readings = readings
        self.content = content()
        _store = State(wrappedValue: WeightStore(health: PreviewHealthService(readings: readings)))
    }

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            content
        }
        .environment(store)
        .environment(router)
        .task { await store.refresh() }
        .preferredColorScheme(scheme)
    }
}
#endif
