//
//  TrendScreenState.swift
//  Steady
//
//  Which of the Trend screen's four shapes is on screen. A pure value so the
//  decision can be unit-tested — the view only renders it.
//

import Foundation

/// What the Trend screen is showing.
///
/// The distinction that matters is between *there is no history* and *the
/// history could not be established*. `WeightStore.refresh()` empties
/// `readings` when the read throws, so a screen that asks nothing but
/// "are there readings?" tells a user with ten years of data that their line
/// has not started yet. It also renders the empty start to anybody who simply
/// has not been queried yet, which is every cold launch: the §7.3 card paints
/// and then snaps to the real chart a frame later.
enum TrendScreenState: Equatable, Sendable {

    /// The first read has not come back. Nothing is claimed either way.
    case loading

    /// There are readings and the chart can be drawn — design reference §7.8.
    case ready

    /// Apple Health answered, access is granted, and there is genuinely no
    /// history. This is the only state that may show §7.3's empty-start copy.
    case empty

    /// The read threw. There may be years of readings behind it; we cannot see
    /// them and must not say they are absent.
    case readFailed

    /// Access is off and there is no history, which means the absence of
    /// readings proves nothing — Apple Health would return an empty set either
    /// way. With history, §7.9 is §7.8 plus the banner and this state does not
    /// apply.
    case accessOff

    /// Resolves the screen's state from everything the store knows.
    ///
    /// Order is deliberate. Readings win outright: once there is a line to
    /// draw, a later failed command does not take the chart away. Otherwise
    /// nothing may be asserted until the first read has returned, a failed read
    /// outranks access, and the empty start is what is left — the one case
    /// where "no readings" actually means the user has never weighed in.
    ///
    /// `.unavailable` falls through to `.empty`: a device with no health data
    /// at all has no history that could exist, so there is nothing being
    /// concealed.
    static func resolve(
        hasLoaded: Bool,
        failure: WeightStoreFailure?,
        hasReadings: Bool,
        accessState: HealthAccessState
    ) -> TrendScreenState {
        if hasReadings { return .ready }
        if !hasLoaded { return .loading }
        if failure == .readFailed { return .readFailed }
        if accessState == .off { return .accessOff }
        return .empty
    }

    /// Whether the headline, the badge and the four stat cells stand in for
    /// values that are not there: an em dash at `mut`, per §7.3.
    var showsPlaceholders: Bool { self != .ready }
}
