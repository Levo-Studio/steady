//
//  HealthService.swift
//  Steady
//
//  The only file in the app that imports HealthKit.
//

import Foundation
import HealthKit

/// What the app is able to do with Apple Health right now.
///
/// Deliberately coarse. HealthKit never reports read authorisation honestly —
/// `authorizationStatus` for a read type answers `.sharingAuthorized` even when
/// the user denied reading, by design, so that apps cannot detect a denial. So
/// nothing here branches on read status.
nonisolated enum HealthAccessState: Sendable, Equatable {
    /// No health data on this device at all.
    case unavailable
    /// Steady can see readings, or can write them, or both.
    case granted
    /// Nothing readable and nothing writable — the access-off state.
    case off
}

nonisolated enum HealthServiceError: Error, Sendable {
    /// HealthKit is not available on this device.
    case unavailable
    /// The sample belongs to another source. HealthKit refuses to delete it and
    /// a Delete that silently fails is worse than no Delete at all.
    case notOwnedBySteady
    /// The sample is no longer in the store.
    case sampleNotFound
}

/// The app's entire contract with Apple Health.
///
/// Behind a protocol so the store can be faked in tests — no test touches the
/// real health database.
nonisolated protocol HealthServicing: Sendable {

    /// Whether this device has health data at all.
    var isAvailable: Bool { get }

    /// Presents the system authorisation sheet for reading and writing body mass.
    func requestAuthorization() async throws

    /// Whether Steady may write. This one status *is* honest, which is why the
    /// access-off determination leans on it.
    func isWriteAuthorized() async -> Bool

    /// Read and write access, determined by attempting the query rather than by
    /// asking about read status.
    func accessState() async -> HealthAccessState

    /// Every body-mass reading, oldest first, collapsed to one per calendar day.
    func readDailyReadings() async throws -> [WeightSample]

    /// Writes a reading, replacing any Steady-written reading already on that
    /// calendar day.
    func save(kilograms: Double, on date: Date) async throws

    /// Deletes a reading. Only ever a reading Steady wrote.
    func delete(_ sample: WeightSample) async throws

    /// Fires whenever body mass changes anywhere on the device, so a weight
    /// logged in another app appears without a manual refresh.
    func changes() async -> AsyncStream<Void>
}

/// The live implementation, backed by `HKHealthStore`.
///
/// An actor: every view reaches Health through `await`, and no view imports
/// HealthKit.
actor HealthService: HealthServicing {

    private let store = HKHealthStore()
    private let quantityType = HKQuantityType(.bodyMass)
    private let calendar: Calendar
    private let appBundleIdentifier: String?

    /// Kilograms only. The design is drawn in kg and there is no settings
    /// screen to switch units.
    private let unit = HKUnit.gramUnit(with: .kilo)

    init(calendar: Calendar = .current, appBundleIdentifier: String? = Bundle.main.bundleIdentifier) {
        self.calendar = calendar
        self.appBundleIdentifier = appBundleIdentifier
    }

    nonisolated var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorisation

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthServiceError.unavailable }
        try await store.requestAuthorization(toShare: [quantityType], read: [quantityType])
    }

    func isWriteAuthorized() async -> Bool {
        guard isAvailable else { return false }
        return store.authorizationStatus(for: quantityType) == .sharingAuthorized
    }

    func accessState() async -> HealthAccessState {
        guard isAvailable else { return .unavailable }
        if await isWriteAuthorized() { return .granted }
        // Read status cannot be trusted, so ask for the data instead. Samples
        // coming back means reading works even though nothing says so.
        let samples = (try? await rawSamples()) ?? []
        return samples.isEmpty ? .off : .granted
    }

    // MARK: - Reading

    func readDailyReadings() async throws -> [WeightSample] {
        let samples = try await rawSamples()
        return TrendEngine.dailyReadings(
            from: samples,
            calendar: calendar,
            steadyBundleIdentifier: appBundleIdentifier
        )
    }

    private func rawSamples() async throws -> [WeightSample] {
        guard isAvailable else { throw HealthServiceError.unavailable }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let results = try await descriptor.result(for: store)
        return results.map(weightSample(from:))
    }

    private func weightSample(from sample: HKQuantitySample) -> WeightSample {
        WeightSample(
            id: sample.uuid,
            date: sample.startDate,
            kilograms: sample.quantity.doubleValue(for: unit),
            sourceBundleIdentifier: sample.sourceRevision.source.bundleIdentifier
        )
    }

    // MARK: - Writing

    func save(kilograms: Double, on date: Date) async throws {
        guard isAvailable else { throw HealthServiceError.unavailable }

        // Replace rather than accumulate: a day has one value in Steady.
        // Only Steady's own samples are removed — a smart scale's reading for
        // the same day stays where it is.
        try await deleteSteadySamples(on: date)

        let quantity = HKQuantity(unit: unit, doubleValue: WeightSample.snap(kilograms))
        let sample = HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )
        try await store.save(sample)
    }

    func delete(_ sample: WeightSample) async throws {
        guard isAvailable else { throw HealthServiceError.unavailable }
        guard sample.isOwnedBySteady(appBundleIdentifier: appBundleIdentifier) else {
            throw HealthServiceError.notOwnedBySteady
        }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: HKQuery.predicateForObject(with: sample.id))],
            sortDescriptors: [],
            limit: 1
        )
        guard let stored = try await descriptor.result(for: store).first else {
            throw HealthServiceError.sampleNotFound
        }
        guard stored.sourceRevision.source.bundleIdentifier == appBundleIdentifier else {
            throw HealthServiceError.notOwnedBySteady
        }
        try await store.delete(stored)
    }

    private func deleteSteadySamples(on date: Date) async throws {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [
                .quantitySample(
                    type: quantityType,
                    predicate: HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
                )
            ],
            sortDescriptors: []
        )
        let sameDay = try await descriptor.result(for: store)
        let ours = sameDay.filter { $0.sourceRevision.source.bundleIdentifier == appBundleIdentifier }
        guard !ours.isEmpty else { return }
        try await store.delete(ours)
    }

    // MARK: - Observation

    func changes() -> AsyncStream<Void> {
        AsyncStream { continuation in
            guard HKHealthStore.isHealthDataAvailable() else {
                continuation.finish()
                return
            }
            let task = Task {
                // An anchored object query delivers the initial set and then
                // every subsequent change, which is what keeps the trend in
                // step with a reading written by another app.
                let store = HKHealthStore()
                let descriptor = HKAnchoredObjectQueryDescriptor(
                    predicates: [.quantitySample(type: HKQuantityType(.bodyMass))],
                    anchor: nil
                )
                do {
                    for try await _ in descriptor.results(for: store) {
                        continuation.yield(())
                    }
                } catch {
                    // A failed observation is not worth surfacing: the app still
                    // reads on appear. Nothing is logged here — health data, and
                    // anything derived from it, never reaches a log.
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
