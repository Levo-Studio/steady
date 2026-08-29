//
//  ScreenScenario.swift
//  Steady
//
//  A debug-only way to launch straight into one screen state with seeded
//  readings, so every state in design reference §7 can be rendered on a device
//  and looked at rather than reasoned about.
//

// Debug builds only. This bypasses HealthKit entirely and seeds the store from
// `StubHealthService`, whose `save(kilograms:on:)` does nothing — shipping it
// would put a silent no-op between the app and a real weigh-in. It has no
// business in a release binary.
#if DEBUG

import SwiftUI

/// One of the states design reference §7 draws.
///
/// Selected with `-steadyScenario <name>` at launch. With no argument the app
/// starts normally against the real health store, so a debug build behaves like
/// a release one unless it is deliberately asked not to.
enum ScreenScenario: String, CaseIterable {

    /// §7.1
    case onboardingWelcome
    /// §7.2
    case onboardingHealth
    /// §7.4
    case logEntry
    /// §7.5
    case logged
    /// §7.6
    case editToday
    /// §7.7
    case deleteConfirmation
    /// §7.8
    case trend
    /// §7.3
    case trendEmpty
    /// The read-failed variant of the Trend card.
    case trendReadFailed
    /// §7.9
    case trendAccessOff

    /// The scenario named on the command line, if any.
    static var current: ScreenScenario? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-steadyScenario"),
              arguments.index(after: index) < arguments.endIndex else { return nil }
        return ScreenScenario(rawValue: arguments[arguments.index(after: index)])
    }

    /// The history the scenario is seeded with.
    var readings: [WeightSample] {
        switch self {
        case .onboardingWelcome, .onboardingHealth, .trendEmpty:
            []
        case .logEntry:
            // No reading for today, so §7.4 rather than §7.5.
            WeightSample.previewHistory(today: nil)
        case .logged, .editToday, .deleteConfirmation:
            WeightSample.previewHistory()
        case .trend, .trendReadFailed:
            TrendPreviewData.samples(days: 400)
        case .trendAccessOff:
            TrendPreviewData.samples(days: 60)
        }
    }

    var accessState: HealthAccessState {
        self == .trendAccessOff ? .off : .granted
    }

    var failsRead: Bool { self == .trendReadFailed }

    var tab: RootTab {
        switch self {
        case .trend, .trendEmpty, .trendReadFailed, .trendAccessOff: .trend
        default: .log
        }
    }
}

/// Renders one scenario against a seeded, in-memory store.
struct ScreenScenarioHost: View {

    let scenario: ScreenScenario

    @State private var store: WeightStore
    @State private var router = AppRouter()
    @State private var tab: RootTab

    init(scenario: ScreenScenario) {
        self.scenario = scenario
        _store = State(
            initialValue: WeightStore(
                health: StubHealthService(
                    readings: scenario.readings,
                    state: scenario.accessState,
                    failsRead: scenario.failsRead
                )
            )
        )
        _tab = State(initialValue: scenario.tab)
    }

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            content
        }
        .environment(store)
        .environment(router)
        .tint(Palette.ac)
        .task { await store.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch scenario {
        case .onboardingWelcome:
            OnboardingWelcomeView {}
        case .onboardingHealth:
            OnboardingHealthAccessView {}
        case .editToday, .deleteConfirmation:
            if let reading = store.todayReading {
                EditTodayScreen(
                    reading: reading,
                    selectedTab: $tab,
                    confirmingDelete: scenario == .deleteConfirmation
                ) {}
            }
        case .logEntry, .logged:
            LogView(selectedTab: $tab)
        case .trend, .trendEmpty, .trendReadFailed, .trendAccessOff:
            TrendView(selectedTab: $tab)
        }
    }
}

#endif
