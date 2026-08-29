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
    var wantsLogEntry = false

    /// Routes to Log and asks it to present entry rather than the
    /// already-logged state.
    func routeToLogEntry() {
        tab = .log
        wantsLogEntry = true
    }

    /// Reads the request exactly once.
    func consumeLogEntryRequest() -> Bool {
        guard wantsLogEntry else { return false }
        wantsLogEntry = false
        return true
    }
}
