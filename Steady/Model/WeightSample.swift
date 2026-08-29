//
//  WeightSample.swift
//  Steady
//
//  A single weight reading. HealthKit is the database; this is the shape the
//  rest of the app sees it in.
//

import Foundation

/// One weight reading: when it was taken, what it said, and who wrote it.
///
/// Kilograms only. The design is drawn in kg and there is no settings screen
/// to switch units, so there is no unit on this type to get wrong.
nonisolated struct WeightSample: Identifiable, Hashable, Sendable {

    /// The HealthKit sample's UUID. A sample that has not been written yet
    /// carries a fresh UUID rather than none, so the type stays `Identifiable`
    /// without an optional identity to branch on.
    let id: UUID

    /// The sample's start date — the moment the reading was taken.
    let date: Date

    /// The reading in kilograms, snapped to 0.1 as everything in Steady is.
    let kilograms: Double

    /// The bundle identifier of the app that wrote the sample, when HealthKit
    /// reports one. A smart scale's samples carry its identifier, not ours.
    let sourceBundleIdentifier: String?

    init(
        id: UUID = UUID(),
        date: Date,
        kilograms: Double,
        sourceBundleIdentifier: String? = nil
    ) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }

    /// Whether Steady wrote this sample, and therefore whether Steady is
    /// allowed to delete it. HealthKit refuses deletion of another source's
    /// data, and offering a Delete that silently fails is worse than not
    /// offering one.
    func isOwnedBySteady(appBundleIdentifier: String?) -> Bool {
        guard let appBundleIdentifier, let sourceBundleIdentifier else { return false }
        return sourceBundleIdentifier == appBundleIdentifier
    }
}

nonisolated extension WeightSample {

    /// The reading rounded to the 0.1 kg the product works in.
    static func snap(_ kilograms: Double) -> Double {
        (kilograms * 10).rounded() / 10
    }

    /// The bounds the ruler drag is clamped to, so it cannot run to absurdity.
    static let plausibleRange: ClosedRange<Double> = 20.0...400.0

    /// The opening value when there is no prior reading at all.
    static let fallbackValue: Double = 70.0
}
