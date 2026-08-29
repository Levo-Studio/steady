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
        }
    }
}
