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

    /// The tab bar's pill lives here rather than inside `TabBar`, because the
    /// screen below the tab bar is rebuilt on every tab change and a namespace
    /// declared inside the control would die with it. Held at the root, the
    /// outgoing pill and the incoming one are recognised as the same view and
    /// `matchedGeometryEffect` slides between them — design reference §9 calls
    /// that the most important animation in the app.
    @Namespace private var tabPillNamespace

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
        .environment(\.tabPillNamespace, tabPillNamespace)
        .task {
            await store.refresh()
        }
        .task {
            // Keeps the trend in step with a weight logged in another app.
            await store.observeChanges()
        }
    }
}
