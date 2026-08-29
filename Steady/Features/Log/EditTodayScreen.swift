//
//  EditTodayScreen.swift
//  Steady
//
//  Design reference §7.6 and §7.7 — editing today, and deleting it.
//

import SwiftUI

/// A full screen, not a sheet and not a menu.
///
/// Delete sits in the header, diagonally opposite Update, because deleting a
/// day silently redraws the trend and must never be adjacent to the confirm
/// action.
struct EditTodayScreen: View {

    let reading: WeightSample
    @Binding var selectedTab: RootTab
    var onDismiss: () -> Void

    @Environment(WeightStore.self) private var store

    @State private var value: Double
    @State private var isConfirmingDelete = false
    @State private var isWorking = false

    @Environment(\.motion) private var motion

    init(reading: WeightSample, selectedTab: Binding<RootTab>, onDismiss: @escaping () -> Void) {
        self.reading = reading
        _selectedTab = selectedTab
        self.onDismiss = onDismiss
        _value = State(initialValue: RulerGeometry.snap(reading.kilograms))
    }

    #if DEBUG
    /// Opens with the confirmation already up, so §7.7 can be rendered on a
    /// device and looked at. Debug builds only — the shipping initialiser above
    /// has no way to reach this state except through the Delete button.
    init(
        reading: WeightSample,
        selectedTab: Binding<RootTab>,
        confirmingDelete: Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.init(reading: reading, selectedTab: selectedTab, onDismiss: onDismiss)
        _isConfirmingDelete = State(initialValue: confirmingDelete)
    }
    #endif

    var body: some View {
        ZStack(alignment: .bottom) {
            screen
                .blur(radius: isConfirmingDelete ? Metrics.sheetBlurRadius : 0)
                .opacity(isConfirmingDelete ? Metrics.sheetBackdropOpacity : 1)
                .accessibilityHidden(isConfirmingDelete)

            if isConfirmingDelete {
                Palette.scrim
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { setConfirming(false) }

                DeleteConfirmationSheet(
                    kilograms: reading.kilograms,
                    date: reading.date,
                    isOwnedBySteady: canDelete,
                    onDelete: delete,
                    onKeep: { setConfirming(false) },
                    onOpenHealth: openHealth
                )
                // §7.7, revised: flush. No side inset, no bottom inset — the
                // sheet spans the full width and its bottom edge is the bottom
                // of the display. The stack below is what reaches the physical
                // edge; the sheet is simply aligned to it.
                .transition(motion.sheet)
            }
        }
        // The sheet is bottom-aligned in this stack, so the stack is what has to
        // reach the physical bottom of the display. Expanding the sheet itself
        // does not work: `screen` already opts out of the safe area, so the
        // stack is laid out inside it and a child's `.ignoresSafeArea` has
        // nothing left to expand into — the fill stopped exactly one home
        // indicator short of the edge.
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - The screen

    private var screen: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: Metrics.space2) {
                Text("EDIT")
                    .steadyTextStyle(.eyebrow)
                    .foregroundStyle(Palette.mut)
                Text("Edit today’s weight")
                    .steadyTextStyle(.editTitle)
                    .foregroundStyle(Palette.ink)
                Text("Logged \(LogDateFormat.time(reading.date)) · \(LogDateFormat.dayLine(reading.date))")
                    .steadyTextStyle(.metaNumeric)
                    .foregroundStyle(Palette.mut)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Metrics.space4)

            Spacer(minLength: Metrics.space4)

            VStack(spacing: 0) {
                WeightEntryBlock(
                    kilograms: value,
                    subLine: wasLine,
                    subLineColor: Palette.mut
                )
                WeightRuler(value: $value)
                    .padding(.top, Metrics.space5)
                StepperRow(value: $value)
                    .padding(.top, Metrics.space4)
            }

            Spacer(minLength: Metrics.space4)

            if let failure = store.failure {
                FailureLine(message: failure.message)
                    .padding(.bottom, Metrics.space3)
            }

            PrimaryButton("Update", fill: .accent, action: update)
                .disabled(isWorking)

            TabBar(selection: $selectedTab)
                .padding(.top, Metrics.space4)
        }
        .steadyScreenPadding()
    }

    private var header: some View {
        HStack(spacing: Metrics.space4) {
            Button(action: onDismiss) {
                Text("Cancel")
                    .steadyTextStyle(.headerCancel)
                    .foregroundStyle(Palette.mut)
                    .padding(.vertical, LogMetrics.headerTargetInset)
                    .contentShape(.rect)
            }
            .buttonStyle(.pressable)
            .padding(.vertical, -LogMetrics.headerTargetInset)

            Spacer(minLength: Metrics.space4)

            Button { setConfirming(true) } label: {
                Text("Delete")
                    .steadyTextStyle(.headerDelete)
                    .foregroundStyle(Palette.danger)
                    .padding(.vertical, LogMetrics.headerTargetInset)
                    .contentShape(.rect)
            }
            .buttonStyle(.pressable)
            .padding(.vertical, -LogMetrics.headerTargetInset)
            .disabled(isWorking)
            // Always tappable, including for a reading Steady did not write.
            // HealthKit will not let an app delete another source's sample, but
            // a greyed-out control explains nothing and offers nothing — the
            // sheet says who wrote it and opens Health, which can remove it.
            .accessibilityHint(canDelete ? "" : "Written by another app. Opens Health, which can remove it.")
        }
        // STEADY.md §11: the 44 pt target is grown on each label above, not
        // with a minHeight here. A minHeight on this stack would expand the
        // row, leave the buttons their intrinsic ~18 pt, and push everything
        // below it 29 pt down the screen.
    }

    // MARK: - State

    /// Whether Steady wrote this reading, and therefore whether it can delete
    /// it. HealthKit only lets an app remove what it saved itself.
    private var canDelete: Bool {
        reading.isOwnedBySteady(appBundleIdentifier: Bundle.main.bundleIdentifier)
    }

    /// "was 72.4 kg", and empty while the value is untouched.
    private var wasLine: String {
        guard RulerGeometry.snap(reading.kilograms) != value else { return "" }
        return "was \(TrendEngine.format(reading.kilograms, decimals: 1)) kg"
    }

    private func setConfirming(_ confirming: Bool) {
        // §9: the sheet rises from the bottom edge with `present` while the
        // scrim and the blur behind it fade over the same duration — one
        // transaction, so they cannot drift apart.
        withAnimation(motion.present) {
            isConfirmingDelete = confirming
        }
    }

    private func update() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            // An edit keeps the moment the user actually weighed. Letting the
            // write default to `.now` would move a 07:14 sample to whenever it
            // was corrected, and §7.5's "at 07:14" would then print a time the
            // user never stood on the scale. A reading from another source is
            // genuinely a new Steady entry, so that one takes the current time.
            let saved = await store.save(
                kilograms: value,
                on: canDelete ? reading.date : .now
            )
            isWorking = false
            if saved { onDismiss() }
        }
    }

    /// Hands the user to Health, the only place a reading Steady did not write
    /// can be removed. There is no deep link to a single sample, so this opens
    /// the app itself.
    private func openHealth() {
        setConfirming(false)
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }

    private func delete() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            let deleted = await store.delete(reading)
            isWorking = false
            setConfirming(false)
            if deleted { onDismiss() }
        }
    }
}

#if DEBUG
// The previews below use LogPreviewSupport, which is itself DEBUG-only.
// #Preview blocks are compiled in Release, so leaving these unguarded broke
// the Release build.
#Preview("Light") {
    @Previewable @State var tab = RootTab.log
    let history = WeightSample.previewHistory()
    LogPreviewHost(scheme: .light, readings: history) {
        EditTodayScreen(reading: history[history.count - 1], selectedTab: $tab) {}
    }
}

#Preview("Dark") {
    @Previewable @State var tab = RootTab.log
    let history = WeightSample.previewHistory()
    LogPreviewHost(scheme: .dark, readings: history) {
        EditTodayScreen(reading: history[history.count - 1], selectedTab: $tab) {}
    }
}

#Preview("Delete — light") {
    @Previewable @State var tab = RootTab.log
    let history = WeightSample.previewHistory()
    LogPreviewHost(scheme: .light, readings: history) {
        EditTodayScreenDeletePreview(reading: history[history.count - 1], selectedTab: $tab)
    }
}

#Preview("Delete — dark") {
    @Previewable @State var tab = RootTab.log
    let history = WeightSample.previewHistory()
    LogPreviewHost(scheme: .dark, readings: history) {
        EditTodayScreenDeletePreview(reading: history[history.count - 1], selectedTab: $tab)
    }
}

#endif

#if DEBUG
/// Opens the Edit screen with the confirmation already showing, so §7.7 has a
/// preview of its own in both themes.
private struct EditTodayScreenDeletePreview: View {

    let reading: WeightSample
    @Binding var selectedTab: RootTab

    var body: some View {
        ZStack(alignment: .bottom) {
            EditTodayScreen(reading: reading, selectedTab: $selectedTab) {}
                .blur(radius: Metrics.sheetBlurRadius)
                .opacity(Metrics.sheetBackdropOpacity)
            Palette.scrim.ignoresSafeArea()
            DeleteConfirmationSheet(
                kilograms: reading.kilograms,
                date: reading.date,
                onDelete: {},
                onKeep: {}
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
#endif
