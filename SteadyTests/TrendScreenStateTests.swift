//
//  TrendScreenStateTests.swift
//  SteadyTests
//

import Foundation
import Testing
@testable import Steady

@Suite("TrendScreenState")
struct TrendScreenStateTests {

    // MARK: - The bug this type exists for

    @Test("A failed read is never the empty start")
    func failedReadIsNotEmpty() {
        // `WeightStore.refresh()` empties `readings` when the read throws, so
        // the only thing that separates ten years of history from none at all
        // is the failure.
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: .readFailed,
            hasReadings: false,
            accessState: .granted
        )
        #expect(state == .readFailed)
        #expect(state != .empty)
    }

    @Test("A cold launch is loading, not empty")
    func coldLaunchIsLoading() {
        let state = TrendScreenState.resolve(
            hasLoaded: false,
            failure: nil,
            hasReadings: false,
            accessState: .granted
        )
        #expect(state == .loading)
    }

    @Test("Access off with no readings does not claim there is no history")
    func accessOffWithoutReadings() {
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: nil,
            hasReadings: false,
            accessState: .off
        )
        #expect(state == .accessOff)
    }

    // MARK: - The ordinary cases

    @Test("Readings and a clean read is the §7.8 screen")
    func ready() {
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: nil,
            hasReadings: true,
            accessState: .granted
        )
        #expect(state == .ready)
    }

    @Test("A clean read of an empty history is the empty start")
    func empty() {
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: nil,
            hasReadings: false,
            accessState: .granted
        )
        #expect(state == .empty)
    }

    @Test("No health data on the device is the empty start, not a failure")
    func unavailableDevice() {
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: nil,
            hasReadings: false,
            accessState: .unavailable
        )
        #expect(state == .empty)
    }

    // MARK: - Precedence

    @Test("Readings outrank every failure and every access state")
    func readingsWinOutright() {
        let failures: [WeightStoreFailure?] = [
            nil, .readFailed, .saveFailed, .deleteFailed, .authorizationFailed
        ]
        for failure in failures {
            for access in [HealthAccessState.granted, .off, .unavailable] {
                #expect(
                    TrendScreenState.resolve(
                        hasLoaded: true,
                        failure: failure,
                        hasReadings: true,
                        accessState: access
                    ) == .ready
                )
            }
        }
    }

    @Test("Nothing is asserted before the first read returns")
    func loadingOutranksAccessAndFailure() {
        for access in [HealthAccessState.granted, .off, .unavailable] {
            #expect(
                TrendScreenState.resolve(
                    hasLoaded: false,
                    failure: .readFailed,
                    hasReadings: false,
                    accessState: access
                ) == .loading
            )
        }
    }

    @Test("A failed read outranks access being off")
    func readFailureOutranksAccess() {
        let state = TrendScreenState.resolve(
            hasLoaded: true,
            failure: .readFailed,
            hasReadings: false,
            accessState: .off
        )
        #expect(state == .readFailed)
    }

    @Test("A failed save or delete leaves the empty start alone")
    func otherFailuresDoNotMask() {
        for failure in [WeightStoreFailure.saveFailed, .deleteFailed, .authorizationFailed] {
            #expect(
                TrendScreenState.resolve(
                    hasLoaded: true,
                    failure: failure,
                    hasReadings: false,
                    accessState: .granted
                ) == .empty
            )
        }
    }

    // MARK: - Placeholders

    @Test("Only the drawn chart shows real values")
    func placeholders() {
        #expect(TrendScreenState.ready.showsPlaceholders == false)
        for state in [TrendScreenState.loading, .empty, .readFailed, .accessOff] {
            #expect(state.showsPlaceholders)
        }
    }
}
