//
//  TrendView.swift
//  Steady
//
//  Placeholder. Replaced wholesale by the Trend feature, which builds design
//  reference §7.3, §7.8 and §7.9 here.
//

import SwiftUI

struct TrendView: View {

    @Binding var selectedTab: RootTab

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Trend")
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
