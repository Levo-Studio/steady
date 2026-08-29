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
///
/// Nothing resets on a tab change because nothing survives one: `RootView`
/// switches on `router.tab` and this view is destroyed and rebuilt, taking its
/// state with it.
struct LogView: View {

    @Binding var selectedTab: RootTab

    @Environment(WeightStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.motion) private var motion

    @State private var isEditing = false

    /// Set when something outside the UI — a Shortcut, the Action Button —
    /// asked for the ruler. It survives until the reading is saved, so the
    /// screen does not flip back to "Logged for today" under the user's finger.
    @State private var showsEntryOverToday = false

    /// Which of the three screens is showing. Derived, never stored — the
    /// state is the readings plus the two flags, and a second copy of it would
    /// only be a second thing to keep in step.
    private enum Screen: Equatable {
        case entry, logged, edit
    }

    private var screen: Screen {
        if store.todayReading == nil { return .entry }
        if isEditing { return .edit }
        return showsEntryOverToday ? .entry : .logged
    }

    var body: some View {
        content
            .task {
                // Arriving on Log is a state transition too, so a message left
                // over from Trend does not follow the user here.
                store.clearFailure()
                consumeRoutingRequest()
            }
            .onChange(of: router.wantsLogEntry) { _, _ in consumeRoutingRequest() }
            .onChange(of: router.wantsEditToday) { _, _ in consumeRoutingRequest() }
            .onChange(of: screen) { _, _ in
                // A failure line is the answer to the last command. Moving to
                // a different screen asks a different question, so the old
                // answer goes rather than persisting until the next write.
                store.clearFailure()
            }
            .onChange(of: store.todayReading == nil) { _, isGone in
                // An external delete — Health, another app — pulls today's
                // reading out from under Edit. The view already falls through
                // to the ruler, but the flag has to go with it, or the next
                // external write for today would drop the user straight back
                // into Edit instead of "Logged for today".
                if isGone { isEditing = false }
            }
    }

    @ViewBuilder
    private var content: some View {
        // §9: a screen swap inside a tab is opacity plus a `4` pt lift with
        // `present`. Never a horizontal slide — there is no navigation stack
        // here and a slide would imply one.
        ZStack {
            if let reading = store.todayReading, isEditing {
                EditTodayScreen(reading: reading, selectedTab: $selectedTab) {
                    withAnimation(motion.present) { isEditing = false }
                }
                .transition(motion.screenSwap)
            } else if let reading = store.todayReading, !showsEntryOverToday {
                LoggedTodayScreen(reading: reading, selectedTab: $selectedTab) {
                    withAnimation(motion.present) { isEditing = true }
                }
                .transition(motion.screenSwap)
            } else {
                LogEntryScreen(selectedTab: $selectedTab) {
                    withAnimation(motion.present) { showsEntryOverToday = false }
                }
                .transition(motion.screenSwap)
            }
        }
        // A save or an external change moves the screen without going through
        // one of the closures above, so the swap is animated here as well.
        .animation(motion.present, value: screen)
    }

    /// Takes whichever request the router is holding. They are mutually
    /// exclusive, so at most one branch runs.
    private func consumeRoutingRequest() {
        if router.consumeEditTodayRequest() {
            withAnimation(motion.present) {
                // A request can outlive the reading it was made about — the day
                // can be deleted in Health between the tap and this call. Edit
                // has nothing to edit then, so the entry screen is the honest
                // answer rather than stranding the user on a screen that
                // cannot render.
                let hasReading = store.todayReading != nil
                isEditing = hasReading
                showsEntryOverToday = !hasReading
            }
            return
        }
        guard router.consumeLogEntryRequest() else { return }
        withAnimation(motion.present) {
            isEditing = false
            showsEntryOverToday = true
        }
    }
}

#if DEBUG
// The previews below use LogPreviewSupport, which is itself DEBUG-only.
// #Preview blocks are compiled in Release, so leaving these unguarded broke
// the Release build.
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

#endif
