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
/// It asks the router for the *entry* screen rather than the Log tab, because
/// on a day that is already logged the tab shows "Logged for today" and the
/// point of the intent is to weigh in. So this always lands on the ruler,
/// logged or not.
///
/// Routing goes through `AppRouter.shared`, the same state the tab bar drives,
/// so there is no second navigation path to keep in step.
struct LogWeightIntent: AppIntent {

    static let title: LocalizedStringResource = "Log Weight"

    static let description = IntentDescription(
        "Opens Steady on the log screen with the ruler ready, whether or not today is already logged.",
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

/// Opens Steady on today's reading so it can be changed or deleted.
///
/// Falls back to the ruler when today has no reading yet — `LogView` resolves
/// that at consume time, so a request raised against a day that turns out to be
/// empty cannot strand the user on an edit screen with nothing to edit.
struct EditTodayIntent: AppIntent {

    static let title: LocalizedStringResource = "Edit Today's Weight"

    static let description = IntentDescription(
        "Opens Steady on today's reading so it can be changed or deleted.",
        categoryName: "Logging",
        searchKeywords: ["weight", "edit", "change", "correct", "delete"]
    )

    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.routeToEditToday()
        return .result()
    }
}

/// Does nothing, and deliberately.
///
/// `SaveWeightIntent` has to declare `OpensIntent` so it *can* open the editor
/// on a conflict, and that conformance obliges every branch to name an intent.
/// On the branch that simply saved there is nothing to open, so it names this
/// one: `openAppWhenRun` is false, `perform` is empty, and Steady stays closed.
///
/// Not published in `SteadyShortcuts`, so it never appears in the Shortcuts app.
struct NoFollowUpIntent: AppIntent {

    static let title: LocalizedStringResource = "Do Nothing"

    static let openAppWhenRun = false
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        .result()
    }
}

/// Writes a reading without opening the app — unless today already has one.
///
/// A scale that talks to Shortcuts, or an automation that asks for the number,
/// can save it while Steady stays closed. It goes through the same
/// `HealthService` the UI uses, so the ownership rules hold.
///
/// **It never overwrites a reading that already exists for today.** Silently
/// replacing a weight the user entered by hand, from a background automation
/// they may have forgotten they set up, is the kind of thing that makes people
/// distrust an app with their data. On a conflict it reports the reading that
/// is already there and opens the editor, which is the one screen that can
/// change or delete it deliberately.
struct SaveWeightIntent: AppIntent {

    static let title: LocalizedStringResource = "Save Weight"

    static let description = IntentDescription(
        "Saves a weight to Apple Health without opening Steady. If today is already logged, it opens the editor instead of overwriting it.",
        categoryName: "Logging",
        searchKeywords: ["weight", "save", "health"]
    )

    /// Runs in the background. There is normally nothing to look at.
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

    func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
        let health = HealthService()
        // Snapped here as well as in the UI, so a Shortcut cannot introduce a
        // precision the rest of the app does not have.
        let value = WeightSample.snap(kilograms)

        if let today = try? await todaysReading(from: health) {
            return .result(
                opensIntent: EditTodayIntent(),
                dialog: IntentDialog(
                    "Today is already logged at \(formatted(today.kilograms)) kg. Opening Steady so you can change it."
                )
            )
        }

        try await health.save(kilograms: value, on: .now)
        return .result(
            opensIntent: NoFollowUpIntent(),
            dialog: IntentDialog("Saved \(formatted(value)) kg.")
        )
    }

    /// Today's reading, or `nil` when the day is still empty.
    private func todaysReading(from health: HealthService) async throws -> WeightSample? {
        let readings = try await health.readDailyReadings()
        guard let last = readings.last else { return nil }
        return Calendar.current.isDateInToday(last.date) ? last : nil
    }

    /// One decimal, locale-independent, matching the rest of the app.
    private func formatted(_ kilograms: Double) -> String {
        String(format: "%.1f", kilograms)
    }
}
