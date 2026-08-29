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

import Combine
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
    /// Not a screen: every state-driven animation in §9, replayed on a timer so
    /// they can be recorded and watched.
    case motionRehearsal

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
        case .motionRehearsal:
            TrendPreviewData.samples(days: 400)
        }
    }

    var accessState: HealthAccessState {
        self == .trendAccessOff ? .off : .granted
    }

    var failsRead: Bool { self == .trendReadFailed }

    var tab: RootTab {
        switch self {
        case .trend, .trendEmpty, .trendReadFailed, .trendAccessOff, .motionRehearsal: .trend
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
        case .motionRehearsal:
            MotionRehearsal()
        }
    }
}


// MARK: - Motion rehearsal

/// Replays every state-driven animation in design reference §9 on a timer.
///
/// Synthetic touches cannot be delivered to the simulator, so this drives the
/// same state the controls drive, in the same `withAnimation` the controls use.
/// What it verifies is what is in question: that the pills genuinely *slide*
/// rather than cross-fading, that the chart line genuinely draws in, that the
/// numbers roll, and that the sheet rises from the edge. Recording it and
/// stepping through the frames is the only way to see an intermediate position.
struct MotionRehearsal: View {

    @Environment(WeightStore.self) private var store
    @Environment(\.motion) private var motion

    @State private var tab = RootTab.trend
    @State private var period = Period.week
    @State private var showsSheet = false
    @State private var chartToken = 0
    @State private var step = 0

    private let beat = Timer.publish(every: 0.9, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Metrics.space3) {
            // The same card §7.8 specifies — `sur`, radius 28, padding 24. It
            // is not decoration here: the period control's track is filled `bg`
            // *because* it is inset in a `sur` card, so a rehearsal without the
            // card renders the track invisibly and misrepresents the screen.
            VStack(alignment: .leading, spacing: Metrics.space4) {
                TrendHeader(summary: store.summary(for: period), isEmpty: false)
                TrendChart(
                    series: store.series(for: period),
                    period: period,
                    redrawToken: chartToken
                )
                PeriodControl(selection: $period)
            }
            .padding(Metrics.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.sur, in: .rect(cornerRadius: Metrics.radiusCard))

            TrendStatsGrid(
                stats: TrendEngine.stats(for: period, readings: store.readings, trend: store.trend),
                isEmpty: false,
                onEditToday: {}
            )
            Spacer()
            TabBar(selection: $tab)
        }
        .padding(.horizontal, Metrics.screenSides)
        .padding(.top, Metrics.screenTop)
        .padding(.bottom, Metrics.screenBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            if showsSheet {
                DeleteConfirmationSheet(kilograms: 72.4, date: .now, onDelete: {}, onKeep: {})
                    .transition(motion.sheet)
            }
        }
        .ignoresSafeArea(.container, edges: .vertical)
        .onReceive(beat) { _ in advance() }
    }

    /// Each beat moves exactly one thing, so a recording can be read without
    /// guessing which animation a frame belongs to.
    private func advance() {
        step += 1
        switch step % 6 {
        case 1, 2:
            withAnimation(Motion.settle) {
                period = period == .week ? .month : (period == .month ? .year : .week)
                chartToken += 1
            }
        case 3:
            withAnimation(Motion.settle) { tab = tab == .trend ? .log : .trend }
        case 4:
            withAnimation(Motion.present) { showsSheet = true }
        case 5:
            withAnimation(Motion.present) { showsSheet = false }
        default:
            withAnimation(Motion.settle) { tab = tab == .trend ? .log : .trend }
        }
    }
}

#endif
