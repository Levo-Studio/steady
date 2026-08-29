//
//  LogEntryScreen.swift
//  Steady
//
//  Design reference §7.4 — the Log screen with the ruler.
//

import SwiftUI

/// The screen the product exists for: a date, a number, a ruler, and Save.
struct LogEntryScreen: View {

    @Binding var selectedTab: RootTab

    /// Called after a reading actually lands in Apple Health, so the screen
    /// above can drop back to the already-logged state.
    var onSaved: () -> Void = {}

    @Environment(WeightStore.self) private var store

    @State private var value = WeightSample.fallbackValue
    /// The opening value is taken once, when the readings first arrive. Taking
    /// it again would drag the ruler out from under a user who has already
    /// moved it.
    @State private var hasOpeningValue = false
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            Text(LogDateFormat.dayLine(.now))
                .steadyTextStyle(.meta)
                .foregroundStyle(Palette.mut)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: Metrics.space4)

            VStack(spacing: 0) {
                WeightEntryBlock(kilograms: value, subLine: vsTrend)
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

            PrimaryButton(fill: .accent) {
                save()
            } label: {
                HStack(spacing: Metrics.space1) {
                    Text("Save")
                    Text(TrendEngine.format(value, decimals: 1))
                        .monospacedDigit()
                    Text("kg")
                }
            }
            .disabled(isSaving)
            .accessibilityLabel("Save \(TrendEngine.format(value, decimals: 1)) kilograms")

            TabBar(selection: $selectedTab)
                .padding(.top, Metrics.space4)
        }
        .steadyScreenPadding()
        .onChange(of: store.hasLoaded, initial: true) { _, _ in takeOpeningValue() }
    }

    /// "+0.3 kg vs trend" — the entry minus the current trend, one decimal,
    /// explicit `+` when positive. Empty until there is a trend to differ from.
    private var vsTrend: String {
        guard let trend = store.currentTrend else { return "" }
        let delta = TrendEngine.format(value - trend, decimals: 1, signed: true)
        return "\(delta) kg vs trend"
    }

    /// Yesterday's reading, else the most recent one, else `70.0`.
    private func takeOpeningValue() {
        guard store.hasLoaded, !hasOpeningValue else { return }
        hasOpeningValue = true
        value = store.openingValue
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            let saved = await store.save(kilograms: value)
            isSaving = false
            // A refused write leaves the screen exactly where it was, with the
            // store's message under the button. Advancing on a save that did
            // not happen is the one outcome worse than the error.
            if saved { onSaved() }
        }
    }
}

#if DEBUG
// The previews below use LogPreviewSupport, which is itself DEBUG-only.
// #Preview blocks are compiled in Release, so leaving these unguarded broke
// the Release build.
#Preview("Light") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .light, readings: WeightSample.previewHistory(today: nil)) {
        LogEntryScreen(selectedTab: $tab)
    }
}

#Preview("Dark") {
    @Previewable @State var tab = RootTab.log
    LogPreviewHost(scheme: .dark, readings: WeightSample.previewHistory(today: nil)) {
        LogEntryScreen(selectedTab: $tab)
    }
}

#endif
