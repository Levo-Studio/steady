//
//  LogView.swift
//  Steady
//
//  The Log destination: entry (§7.4), already logged (§7.5), and edit (§7.6).
//

import SwiftUI

/// One destination with three states, chosen by what Apple Health already
/// holds for today.
///
/// There is no navigation stack here on purpose. Edit is a state of Log, not a
/// pushed screen, so the tab bar stays live underneath it and Shortcuts routes
/// through the same state the tab bar drives.
struct LogView: View {

    @Binding var selectedTab: RootTab

    @Environment(WeightStore.self) private var store
    @Environment(AppRouter.self) private var router

    @State private var isEditing = false

    /// Set when something outside the UI — a Shortcut, the Action Button —
    /// asked for the ruler. It survives until the reading is saved, so the
    /// screen does not flip back to "Logged for today" under the user's finger.
    @State private var showsEntryOverToday = false

    var body: some View {
        content
            .task { consumeRoutingRequest() }
            .onChange(of: router.wantsLogEntry) { _, _ in consumeRoutingRequest() }
            .onChange(of: selectedTab) { _, _ in
                // Leaving the tab abandons the edit rather than parking a
                // half-finished screen behind the Trend tab.
                isEditing = false
                showsEntryOverToday = false
            }
    }

    @ViewBuilder
    private var content: some View {
        if let reading = store.todayReading, isEditing {
            EditTodayScreen(reading: reading, selectedTab: $selectedTab) {
                isEditing = false
            }
        } else if let reading = store.todayReading, !showsEntryOverToday {
            LoggedTodayScreen(reading: reading, selectedTab: $selectedTab) {
                isEditing = true
            }
        } else {
            LogEntryScreen(selectedTab: $selectedTab) {
                showsEntryOverToday = false
            }
        }
    }

    private func consumeRoutingRequest() {
        guard router.consumeLogEntryRequest() else { return }
        isEditing = false
        showsEntryOverToday = true
    }
}

#Preview("Light — entry") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .light, readings: WeightSample.previewHistory(today: nil)) {
        LogView(selectedTab: $tab)
    }
}

#Preview("Dark — entry") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .dark, readings: WeightSample.previewHistory(today: nil)) {
        LogView(selectedTab: $tab)
    }
}

#Preview("Light — logged") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .light, readings: WeightSample.previewHistory()) {
        LogView(selectedTab: $tab)
    }
}

#Preview("Dark — logged") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .dark, readings: WeightSample.previewHistory()) {
        LogView(selectedTab: $tab)
    }
}
