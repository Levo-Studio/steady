//
//  LogView.swift
//  Steady
//
//  Placeholder. Replaced wholesale by the Log feature, which builds design
//  reference §7.4, §7.5, §7.6 and §7.7 here.
//

import SwiftUI

struct LogView: View {

    @Binding var selectedTab: RootTab

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Log")
                .steadyTextStyle(.loggedForToday)
                .foregroundStyle(Palette.ink)
            Spacer()
            TabBar(selection: $selectedTab)
        }
        .padding(.top, Metrics.screenTop)
        .padding(.horizontal, Metrics.screenSides)
        .padding(.bottom, Metrics.screenBottom)
    }
}
