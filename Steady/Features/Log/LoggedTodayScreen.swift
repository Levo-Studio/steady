//
//  LoggedTodayScreen.swift
//  Steady
//
//  Design reference §7.5 — the Log screen once today has a reading.
//

import SwiftUI

/// Shown instead of the ruler when today is already logged.
///
/// The day is done, so the screen states that and gets out of the way. Editing
/// is one tap behind an outlined button rather than the accent fill, because
/// nothing here is asking to be committed.
struct LoggedTodayScreen: View {

    let reading: WeightSample
    @Binding var selectedTab: RootTab
    var onEdit: () -> Void

    @Environment(WeightStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            Text(LogDateFormat.dayLine(.now))
                .steadyTextStyle(.meta)
                .foregroundStyle(Palette.mut)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: Metrics.space4)

            VStack(spacing: 0) {
                CheckCircle()

                Text("Logged for today")
                    .steadyTextStyle(.loggedForToday)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Metrics.space4)

                WeightEntryBlock(kilograms: reading.kilograms, subLine: loggedLine)
                    .padding(.top, Metrics.space4)
            }

            Spacer(minLength: Metrics.space4)

            if let failure = store.failure {
                FailureLine(message: failure.message)
                    .padding(.bottom, Metrics.space3)
            }

            PrimaryButton("Edit today’s weight", fill: .outline, action: onEdit)

            TabBar(selection: $selectedTab)
                .padding(.top, Metrics.space4)
        }
        .steadyScreenPadding()
    }

    /// "at 07:14 · trend 72.6" — the time the reading was taken and the current
    /// trend to one decimal.
    private var loggedLine: String {
        let time = LogDateFormat.time(reading.date)
        guard let trend = store.currentTrend else { return "at \(time)" }
        return "at \(time) · trend \(TrendEngine.format(trend, decimals: 1))"
    }
}

// MARK: - The check

/// A `56` pt `acsoft` disc with the tick from design reference §7.5.
private struct CheckCircle: View {

    var body: some View {
        Circle()
            .fill(Palette.acsoft)
            .frame(
                width: Metrics.checkCircleDiameter,
                height: Metrics.checkCircleDiameter
            )
            .overlay {
                CheckGlyph()
                    .stroke(
                        Palette.acsoftink,
                        style: StrokeStyle(
                            lineWidth: LogMetrics.checkGlyphStroke,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: LogMetrics.checkGlyphBox, height: LogMetrics.checkGlyphBox)
            }
            .accessibilityHidden(true)
    }
}

/// `M5 13.5l5 5L21 8`, drawn on the 26 box the design specifies.
private struct CheckGlyph: Shape {

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / LogMetrics.checkGlyphBox
        var path = Path()
        path.move(to: CGPoint(x: 5 * scale, y: 13.5 * scale))
        path.addLine(to: CGPoint(x: 10 * scale, y: 18.5 * scale))
        path.addLine(to: CGPoint(x: 21 * scale, y: 8 * scale))
        return path
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
        LoggedTodayScreen(reading: history[history.count - 1], selectedTab: $tab) {}
    }
}

#Preview("Dark") {
    @Previewable @State var tab = RootTab.log
    let history = WeightSample.previewHistory()
    LogPreviewHost(scheme: .dark, readings: history) {
        LoggedTodayScreen(reading: history[history.count - 1], selectedTab: $tab) {}
    }
}

#endif
