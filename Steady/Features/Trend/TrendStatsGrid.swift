//
//  TrendStatsGrid.swift
//  Steady
//
//  The 2 × 2 stats grid from design reference §7.8, and its empty-start
//  variant from §7.3.
//

import SwiftUI

/// Today · Yesterday · 7-day avg · Last week (or ⌀ per week).
///
/// The dividers are drawn as a right border on the left column and a bottom
/// border on the top row, exactly as the design has them, so they form a cross
/// that stops well short of the 24 pt corners.
struct TrendStatsGrid: View {

    let stats: TrendEngine.Stats
    /// Before the first reading every value is an em dash at 36 pt in `mut` —
    /// including the fourth cell, which otherwise sits at 40 pt in `ac`.
    let isEmpty: Bool
    /// Tapping Today opens Edit today. It is the only tappable cell, and only
    /// when today actually has a reading.
    let onEditToday: () -> Void

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                todayCell
                    .dividerRight()
                    .dividerBottom()

                cell(label: "Yesterday", value: TrendEngine.format(stats.yesterday, decimals: 1))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Yesterday")
                    .accessibilityValue(spoken(TrendEngine.format(stats.yesterday, decimals: 1)))
                    .dividerBottom()
            }
            GridRow {
                cell(
                    label: "7-day avg",
                    value: TrendEngine.format(stats.sevenDayAverage, decimals: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("7-day average")
                .accessibilityValue(spoken(TrendEngine.format(stats.sevenDayAverage, decimals: 1)))
                .dividerRight()

                cell(
                    label: stats.perWeekLabel,
                    value: perWeekValue,
                    style: isEmpty ? .statValue : .statPerWeekValue,
                    colour: isEmpty ? Palette.mut : Palette.ac
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    stats.perWeekLabel.replacingOccurrences(of: "⌀ ", with: "Average ")
                )
                .accessibilityValue(spoken(perWeekValue))
            }
        }
        .background(Palette.sur, in: .rect(cornerRadius: Metrics.radiusStatsGrid))
    }

    /// Today is the only tappable cell — and only when there is something to
    /// edit. With no reading for today the cell shows an em dash and the hint
    /// "Opens today’s entry" would promise a screen for a day that has no
    /// entry, so it is a plain cell instead. Logging today is the Log tab's job.
    @ViewBuilder
    private var todayCell: some View {
        let value = TrendEngine.format(stats.today, decimals: 1)
        if stats.today == nil {
            cell(label: "Today", value: value)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Today")
                .accessibilityValue(spoken(value))
        } else {
            Button(action: onEditToday) {
                cell(label: "Today", value: value)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Today")
            .accessibilityValue(spoken(value))
            .accessibilityHint("Opens today’s entry")
        }
    }

    private var perWeekValue: String {
        TrendEngine.format(stats.perWeek, decimals: stats.perWeekDecimals, signed: true)
    }

    private func cell(
        label: String,
        value: String,
        style: SteadyTextStyle = .statValue,
        colour: Color = Palette.ink
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .steadyTextStyle(.cardLabel)
                .foregroundStyle(Palette.mut)
            Text(value)
                .steadyTextStyle(style)
                .foregroundStyle(isEmpty ? Palette.mut : colour)
                .padding(.top, Metrics.space3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(Metrics.space4)
    }

    /// VoiceOver reads a bare "—" as nothing at all, and a bare number without
    /// its unit as a quantity of unknown kind.
    private func spoken(_ value: String) -> String {
        value == "—" ? "No reading" : "\(value) kilograms"
    }
}

private extension View {

    func dividerRight() -> some View {
        overlay(alignment: .trailing) {
            Rectangle()
                .fill(Palette.line)
                .frame(width: Metrics.hairline)
        }
    }

    func dividerBottom() -> some View {
        overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.line)
                .frame(height: Metrics.hairline)
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    let readings = TrendPreviewData.samples(days: 120)
    let trend = TrendEngine.trend(for: readings.map(\.kilograms))
    return VStack(spacing: Metrics.space3) {
        TrendStatsGrid(
            stats: TrendEngine.stats(for: .week, readings: readings, trend: trend),
            isEmpty: false,
            onEditToday: {}
        )
        TrendStatsGrid(
            stats: TrendEngine.stats(for: .month, readings: readings, trend: trend),
            isEmpty: false,
            onEditToday: {}
        )
        TrendStatsGrid(
            stats: TrendEngine.stats(for: .week, readings: [], trend: []),
            isEmpty: true,
            onEditToday: {}
        )
    }
    .padding(Metrics.space4)
    .background(Palette.bg)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let readings = TrendPreviewData.samples(days: 400)
    let trend = TrendEngine.trend(for: readings.map(\.kilograms))
    return VStack(spacing: Metrics.space3) {
        TrendStatsGrid(
            stats: TrendEngine.stats(for: .year, readings: readings, trend: trend),
            isEmpty: false,
            onEditToday: {}
        )
        TrendStatsGrid(
            stats: TrendEngine.stats(for: .week, readings: [], trend: []),
            isEmpty: true,
            onEditToday: {}
        )
    }
    .padding(Metrics.space4)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
