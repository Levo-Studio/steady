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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The sheet is one of the four movements the design allows. 0.28s so it
    /// arrives without ceremony.
    private static let sheetDuration: Double = 0.28

    init(reading: WeightSample, selectedTab: Binding<RootTab>, onDismiss: @escaping () -> Void) {
        self.reading = reading
        _selectedTab = selectedTab
        self.onDismiss = onDismiss
        _value = State(initialValue: RulerGeometry.snap(reading.kilograms))
    }

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
                    onDelete: delete,
                    onKeep: { setConfirming(false) }
                )
                .padding(.horizontal, Metrics.space4)
                .padding(.bottom, Metrics.space5)
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(
                    reduceMotion
                        ? .opacity
                        : .move(edge: .bottom).combined(with: .opacity)
                )
            }
        }
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
            .buttonStyle(.plain)
            .padding(.vertical, -LogMetrics.headerTargetInset)

            Spacer(minLength: Metrics.space4)

            Button { setConfirming(true) } label: {
                Text("Delete")
                    .steadyTextStyle(.headerDelete)
                    // A reading Steady did not write cannot be removed, so the
                    // control drops out of the danger colour entirely rather
                    // than offering an action that would silently fail.
                    .foregroundStyle(canDelete ? Palette.danger : Palette.mut)
                    .padding(.vertical, LogMetrics.headerTargetInset)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.vertical, -LogMetrics.headerTargetInset)
            .disabled(!canDelete || isWorking)
            .accessibilityHint(canDelete ? "" : "This reading was written by another app and cannot be deleted here.")
        }
        // STEADY.md §11: the 44 pt target is grown on each label above, not
        // with a minHeight here. A minHeight on this stack would expand the
        // row, leave the buttons their intrinsic ~18 pt, and push everything
        // below it 29 pt down the screen.
    }

    // MARK: - State

    /// Deleting only ever touches a sample Steady wrote. HealthKit refuses
    /// another source's data, and a Delete that silently fails is worse than
    /// one that is plainly unavailable.
    private var canDelete: Bool {
        reading.isOwnedBySteady(appBundleIdentifier: Bundle.main.bundleIdentifier)
    }

    /// "was 72.4 kg", and empty while the value is untouched.
    private var wasLine: String {
        guard RulerGeometry.snap(reading.kilograms) != value else { return "" }
        return "was \(TrendEngine.format(reading.kilograms, decimals: 1)) kg"
    }

    private func setConfirming(_ confirming: Bool) {
        withAnimation(.easeOut(duration: Self.sheetDuration)) {
            isConfirmingDelete = confirming
        }
    }

    private func update() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            let saved = await store.save(kilograms: value)
            isWorking = false
            if saved { onDismiss() }
        }
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
            .padding(.horizontal, Metrics.space4)
            .padding(.bottom, Metrics.space5)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
#endif
