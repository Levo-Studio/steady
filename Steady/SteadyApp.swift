//
//  SteadyApp.swift
//  Steady
//
//  Created by  Julius Grimm on 29.08.26.
//

import SwiftUI

@main
struct SteadyApp: App {

    @State private var store = WeightStore(health: HealthService())
    @State private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(router)
                // The app tint comes from the palette, not from an
                // `AccentColor` asset, so `Palette` stays the one place a
                // Steady colour is named. Without it SwiftUI falls back to
                // the system blue, which is a semantic colour STEADY.md §10
                // forbids and is not the design's accent.
                .tint(Palette.ac)
        }
    }
}
