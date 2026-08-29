//
//  AppRouter.swift
//  Steady
//
//  The one navigation path in the app.
//

import Observation
import SwiftUI

/// Which destination is showing, and the hook an App Intent uses to drive it.
///
/// The tab bar and Shortcuts route through the same state — there is no second
/// navigation path to keep in sync.
@MainActor
@Observable
final class AppRouter {

    /// The router the app scene installs, so an `AppIntent` running outside the
    /// view hierarchy can reach it.
    static let shared = AppRouter()

    var tab: RootTab = .log

    /// Set when something outside the UI asks for the Log entry screen, ruler
    /// ready. The Log screen consumes it and clears it.
    private(set) var wantsLogEntry = false

    /// Set when something asks to edit the reading today already has — the
    /// Today cell on the Trend screen is the only caller so far.
    ///
    /// The two requests are mutually exclusive by construction: each setter
    /// clears the other. They ask for different screens, so a router holding
    /// both would leave the Log screen picking one arbitrarily, and the loser
    /// would sit there until some unrelated event happened to consume it.
    private(set) var wantsEditToday = false

    /// Routes to Log and lets it decide which state to show.
    ///
    /// This is what a Shortcut asks for. On an empty day Log shows the ruler;
    /// on a day that already has a reading it shows "Logged for today" with the
    /// route into editing. Forcing the ruler here would let a Shortcut log a
    /// second time over a day that is already done.
    func routeToLog() {
        tab = .log
        wantsLogEntry = false
        wantsEditToday = false
    }

    /// Routes to Log and asks it to present entry rather than the
    /// already-logged state.
    func routeToLogEntry() {
        tab = .log
        wantsLogEntry = true
        wantsEditToday = false
    }

    /// Routes to Log and asks it to present design reference §7.6 for today's
    /// existing reading.
    ///
    /// Before this existed the Trend screen's Today cell called
    /// `routeToLogEntry()`, which dropped a blank ruler over a day that was
    /// already logged — the user was offered a fresh entry for a reading they
    /// had asked to correct.
    func routeToEditToday() {
        tab = .log
        wantsEditToday = true
        wantsLogEntry = false
    }

    /// Reads the request exactly once.
    func consumeLogEntryRequest() -> Bool {
        guard wantsLogEntry else { return false }
        wantsLogEntry = false
        return true
    }

    /// Reads the request exactly once.
    func consumeEditTodayRequest() -> Bool {
        guard wantsEditToday else { return false }
        wantsEditToday = false
        return true
    }
}
