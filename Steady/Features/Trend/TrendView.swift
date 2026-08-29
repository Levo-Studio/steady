//
//  TrendView.swift
//  Steady
//
//  The Trend screen: design reference §7.8, its empty start §7.3, and its
//  access-off variant §7.9.
//

import SwiftUI

struct TrendView: View {

    @Binding var selectedTab: RootTab

    @Environment(WeightStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var period: Period = .week

    /// Bumped on every range tap so the entrance replays even when the range
    /// that is already showing is tapped again — design reference §7.8 keeps
    /// three identical keyframe names for exactly that reason.
    @State private var entranceToken = 0

    var body: some View {
        VStack(spacing: 0) {
            chartCard

            TrendStatsGrid(
                stats: TrendEngine.stats(
                    for: period,
                    readings: store.readings,
                    trend: store.trend
                ),
                isEmpty: state.showsPlaceholders,
                onEditToday: editToday
            )
            .padding(.top, Metrics.space3)

            if showsAccessBanner {
                AccessOffBanner(onAllow: requestAccess)
                    .padding(.top, Metrics.space3)
            }

            Spacer(minLength: Metrics.space4)

            TabBar(selection: $selectedTab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Metrics.screenTop)
        .padding(.horizontal, Metrics.screenSides)
        .padding(.bottom, Metrics.screenBottom)
        // Design reference §1: the padding is measured from the *physical* top
        // of the screen, not from the safe area. The concept's 874 pt canvas is
        // the whole device frame, so 70 means 70 from the true edge — padding
        // inside the safe area instead lands everything about 59 pt too low.
        // The bottom 40 clears the home indicator on its own.
        .ignoresSafeArea(.container, edges: .vertical)
    }

    // MARK: - The chart card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TrendHeader(
                summary: store.summary(for: period),
                isEmpty: state.showsPlaceholders
            )
                .periodEntrance(token: entranceToken, lift: lift)

            chart
                .padding(.top, Metrics.space4)

            PeriodControl(selection: $period) { _ in
                entranceToken &+= 1
            }
            .padding(.top, Metrics.space4)
        }
        .padding(Metrics.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.sur, in: .rect(cornerRadius: Metrics.radiusCard))
    }

    @ViewBuilder
    private var chart: some View {
        switch state {
        case .ready:
            TrendChart(series: store.series(for: period), period: period)
                // The chart re-draws on the same 0.34s timing as the headline.
                // It carries the cross-fade only: the design lifts the headline
                // block and the badge, not the drawing.
                .periodEntrance(token: entranceToken, lift: 0)
        case .loading:
            TrendChartLoadingState()
        case .empty, .readFailed, .accessOff:
            TrendChartEmptyState(state: state)
        }
    }

    // MARK: - State

    /// Which of the screen's shapes is on. The decision itself lives in
    /// `TrendScreenState` so it can be tested — asking `!store.hasReadings`
    /// here conflated three different absences, and told a user whose read had
    /// just failed that their line had not started yet.
    private var state: TrendScreenState {
        TrendScreenState.resolve(
            hasLoaded: store.hasLoaded,
            failure: store.failure,
            hasReadings: store.hasReadings,
            accessState: store.accessState
        )
    }

    private var showsAccessBanner: Bool { store.accessState == .off }

    /// Reduce Motion drops the translate and keeps the cross-fade.
    private var lift: CGFloat {
        reduceMotion ? 0 : Metrics.periodChangeLift
    }

    // MARK: - Actions

    /// The Today cell opens Edit today. Routing goes through `AppRouter`, which
    /// is the app's single navigation path — the Log feature owns the screen
    /// itself.
    private func editToday() {
        router.routeToLogEntry()
    }

    private func requestAccess() {
        Task { await store.requestAuthorization() }
    }
}

// MARK: - Previews

private struct TrendPreviewHost: View {

    let readings: [WeightSample]
    var accessState: HealthAccessState = .granted

    @State private var store: WeightStore
    @State private var router = AppRouter()
    @State private var tab = RootTab.trend

    init(readings: [WeightSample], accessState: HealthAccessState = .granted) {
        self.readings = readings
        self.accessState = accessState
        _store = State(
            initialValue: WeightStore(
                health: StubHealthService(readings: readings, state: accessState)
            )
        )
    }

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            TrendView(selectedTab: $tab)
        }
        .environment(store)
        .environment(router)
        .task { await store.refresh() }
    }
}

#Preview("Light") {
    TrendPreviewHost(readings: TrendPreviewData.samples(days: 400))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrendPreviewHost(readings: TrendPreviewData.samples(days: 400))
        .preferredColorScheme(.dark)
}

#Preview("Empty start — light") {
    TrendPreviewHost(readings: [])
        .preferredColorScheme(.light)
}

#Preview("Empty start — dark") {
    TrendPreviewHost(readings: [])
        .preferredColorScheme(.dark)
}

#Preview("Access off — light") {
    TrendPreviewHost(readings: [], accessState: .off)
        .preferredColorScheme(.light)
}

#Preview("Access off — dark") {
    TrendPreviewHost(readings: TrendPreviewData.samples(days: 60), accessState: .off)
        .preferredColorScheme(.dark)
}
