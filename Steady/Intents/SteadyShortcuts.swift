//
//  SteadyShortcuts.swift
//  Steady
//
//  What Steady offers the Shortcuts app without the user building anything.
//

import AppIntents

/// The shortcuts that appear in the Shortcuts app on their own.
///
/// Every phrase has to contain `\(.applicationName)`, which is why they all
/// name Steady. The first phrase is the one Siri prefers and the one shown in
/// the Shortcuts gallery, so it is the plainest.
struct SteadyShortcuts: AppShortcutsProvider {

    /// Blue, matching the app's accent rather than a system default.
    static let shortcutTileColor: ShortcutTileColor = .blue

    /// `EditTodayIntent` is deliberately absent. It still appears when browsing
    /// Steady's actions in the Shortcuts app, but it is not offered as a
    /// ready-made shortcut, because reaching the editor is not something the
    /// user should have to wire up — `SaveWeightIntent` hands over to it on its
    /// own when the day is already logged.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWeightIntent(),
            phrases: [
                "Log weight in \(.applicationName)",
                "Log my weight in \(.applicationName)",
                "Weigh in with \(.applicationName)",
                "Open \(.applicationName) log",
                "New weigh-in in \(.applicationName)"
            ],
            shortTitle: "Log Weight",
            systemImageName: "scalemass"
        )

        AppShortcut(
            intent: SaveWeightIntent(),
            phrases: [
                "Save weight to \(.applicationName)",
                "Save my weight in \(.applicationName)"
            ],
            shortTitle: "Save Weight",
            systemImageName: "square.and.arrow.down"
        )
    }
}
