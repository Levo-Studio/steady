//
//  TabBar.swift
//  Steady
//
//  The two-item tab bar, per design reference §7.
//

import SwiftUI

/// The app's two destinations. There is no settings screen, no history screen,
/// and no third tab.
nonisolated enum RootTab: String, CaseIterable, Identifiable, Sendable {
    case log
    case trend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .log: "Log"
        case .trend: "Trend"
        }
    }
}

/// Pinned to the bottom of every non-onboarding screen.
///
/// A `sur` pill with `5` pt padding around two `44` pt items. The selected item
/// takes an `ink` fill with `bg` text at weight 500; the other has no fill and
/// `mut` text at 400.
struct TabBar: View {

    @Binding var selection: RootTab

    var body: some View {
        HStack(spacing: Metrics.tabBarGap) {
            ForEach(RootTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    selection = tab
                } label: {
                    Text(tab.title)
                        .steadyTextStyle(isSelected ? .tabItemActive : .tabItemInactive)
                        .foregroundStyle(isSelected ? Palette.bg : Palette.mut)
                        .frame(maxWidth: .infinity)
                        .frame(height: Metrics.tabItemHeight)
                        .background(isSelected ? Palette.ink : .clear, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(Metrics.tabBarPadding)
        .background(Palette.sur, in: .capsule)
    }
}

#Preview("Light") {
    @Previewable @State var tab = RootTab.log
    TabBar(selection: $tab)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var tab = RootTab.trend
    TabBar(selection: $tab)
        .padding(Metrics.space4)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
