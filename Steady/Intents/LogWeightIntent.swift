//
//  LogWeightIntent.swift
//  Steady
//
//  STEADY.md §9: a Shortcut, a Home Screen tile, the Lock Screen or the Action
//  Button should land on the ruler with no navigation in between.
//

import AppIntents
import Foundation

/// Opens Steady on the Log screen, ruler ready.
///
/// Routing goes through `AppRouter.shared`, the same state the tab bar drives,
/// so there is no second navigation path to keep in step. The router is asked
/// for the entry screen specifically rather than for the Log tab, because on a
/// day that is already logged the tab would show "Logged for today" and the
/// point of the intent is to weigh in.
struct LogWeightIntent: AppIntent {

    static let title: LocalizedStringResource = "Log Weight"

    static let description = IntentDescription(
        "Opens Steady on the log screen with the ruler ready.",
        categoryName: "Logging",
        searchKeywords: ["weight", "weigh", "log", "scale"]
    )

    /// The whole point is to arrive on the screen, so the app has to come up.
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.routeToLogEntry()
        return .result()
    }
}

/// Writes a reading without opening the app.
///
/// The natural extension once the Log screen exists: a scale that talks to
/// Shortcuts, or an automation that asks for the number, can save it without
/// Steady ever appearing. It goes through the same `HealthService` the UI uses,
/// so the replace-today rule and the ownership rules hold.
struct SaveWeightIntent: AppIntent {

    static let title: LocalizedStringResource = "Save Weight"

    static let description = IntentDescription(
        "Saves a weight to Apple Health without opening Steady.",
        categoryName: "Logging",
        searchKeywords: ["weight", "save", "health"]
    )

    /// Runs in the background. There is nothing to look at.
    static let openAppWhenRun = false

    @Parameter(
        title: "Weight",
        description: "The reading in kilograms.",
        inclusiveRange: (20.0, 400.0)
    )
    var kilograms: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$kilograms) kg to Apple Health")
    }

    func perform() async throws -> some IntentResult {
        let health = HealthService()
        // Snapped here as well as in the UI, so a Shortcut cannot introduce a
        // precision the rest of the app does not have.
        try await health.save(kilograms: WeightSample.snap(kilograms), on: .now)
        return .result()
    }
}
