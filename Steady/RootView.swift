//
//  RootView.swift
//  Steady
//
//  The onboarding gate and the two-tab routing. Nothing else.
//

import SwiftUI

struct RootView: View {

    /// The only thing Steady persists outside HealthKit.
    ///
    /// Onboarding shows once, ever. It is never re-shown, and there is no way
    /// to trigger it again from inside the app — including after "Maybe later",
    /// which completes onboarding and lands on the access-off state.
    @AppStorage(RootView.onboardingCompleteKey) private var onboardingComplete = false

    @Environment(AppRouter.self) private var router
    @Environment(WeightStore.self) private var store

    static let onboardingCompleteKey = "steady.onboardingComplete"

    var body: some View {
        @Bindable var router = router

        ZStack {
            Palette.bg.ignoresSafeArea()

            if onboardingComplete {
                switch router.tab {
                case .log:
                    LogView(selectedTab: $router.tab)
                case .trend:
                    TrendView(selectedTab: $router.tab)
                }
            } else {
                OnboardingFlowView { onboardingComplete = true }
            }
        }
        .task {
            await store.refresh()
        }
        .task {
            // Keeps the trend in step with a weight logged in another app.
            await store.observeChanges()
        }
    }
}
