//
//  TrendChart.swift
//  Steady
//
//  The 306 × 140 chart from design reference §7.8, and the empty-start
//  replacement from §7.3. Drawn by hand with `Canvas` and `Path` — never Swift
//  Charts, per STEADY.md §5.
//

import SwiftUI

/// The chart: a glow area under the trend, the raw readings as a thin polyline
/// and dots, and the accent trend line on top.
///
/// The z-order is load-bearing and is drawn in exactly this sequence:
///
/// 1. `trendArea` — the trend path closed down to the baseline, filled `glow`.
/// 2. `rawLine` — the polyline through the raw readings, `raw`, width 1.5.
/// 3. The raw dots, `raw`, radius 4 / 2.2 / 1.6 by range.
/// 4. `trendLine` — the trend polyline, `ac`, width 5.
///
/// The accent line sits above everything and the readings read as texture
/// beneath it. Reordering these is a design bug, not a refactor.
struct TrendChart: View {

    let series: TrendEngine.Series
    let period: Period

    /// How far the drawing may spill outside the 306 × 140 box.
    ///
    /// The design says `overflow: visible`, and it means it: a week dot sitting
    /// on the first or last reading is centred on `x = 0` or `x = width` with a
    /// radius of 4, and the 5 pt trend line hangs 2.5 pt past its end points.
    /// `Canvas` clips to its own bounds, so the canvas is grown by this much on
    /// every side and pulled back with negative padding — the layout still
    /// occupies exactly 306 × 140.
    private static let overflow: CGFloat = 5

    var body: some View {
        Canvas(opaque: false) { context, size in
            let width = size.width - Self.overflow * 2
            let height = size.height - Self.overflow * 2
            guard width > 0, height > 0 else { return }
            context.translateBy(x: Self.overflow, y: Self.overflow)

            let geometry = ChartGeometry.make(
                raw: series.raw,
                trend: series.trend,
                width: width,
                height: height
            )

            // 1 — the area under the trend.
            if geometry.drawsLine, let first = geometry.trendPoints.first,
               let last = geometry.trendPoints.last {
                var area = Path()
                area.move(to: CGPoint(x: first.x, y: height))
                area.addLine(to: first)
                for point in geometry.trendPoints.dropFirst() { area.addLine(to: point) }
                area.addLine(to: CGPoint(x: last.x, y: height))
                area.closeSubpath()
                context.fill(area, with: .color(Palette.glow))
            }

            // 2 — the thin polyline through the raw readings.
            if geometry.dots.count >= 2 {
                context.stroke(
                    Self.polyline(geometry.dots),
                    with: .color(Palette.raw),
                    style: StrokeStyle(lineWidth: Metrics.rawLineWidth, lineJoin: .round)
                )
            }

            // 3 — the readings themselves.
            let radius = period.dotRadius
            for dot in geometry.dots {
                let box = CGRect(
                    x: dot.x - radius, y: dot.y - radius,
                    width: radius * 2, height: radius * 2
                )
                context.fill(Path(ellipseIn: box), with: .color(Palette.raw))
            }

            // 4 — the trend line, on top of everything.
            if geometry.drawsLine {
                context.stroke(
                    Self.polyline(geometry.trendPoints),
                    with: .color(Palette.ac),
                    style: StrokeStyle(
                        lineWidth: Metrics.trendLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .frame(height: Metrics.chartHeight + Self.overflow * 2)
        .padding(-Self.overflow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trend chart, \(period.title.lowercased())")
        .accessibilityValue(accessibilitySummary)
    }

    private static func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }

    /// The chart is a drawing, so VoiceOver would otherwise find nothing here at
    /// all. This is the picture in a sentence: how much is plotted, where the
    /// line starts and ends, and which way it is going.
    private var accessibilitySummary: String {
        guard let first = series.trend.first, let last = series.trend.last else {
            return "No readings yet."
        }
        let unit = period == .year ? "weekly averages" : "readings"
        let direction = TrendEngine.direction(from: first, to: last)
        return """
            \(series.raw.count) \(unit). \
            Trend \(direction.spoken), from \(TrendEngine.format(first, decimals: 1)) \
            to \(TrendEngine.format(last, decimals: 1)) kilograms.
            """
    }
}

// MARK: - Empty start

/// What stands in for the chart before the first reading exists,
/// per design reference §7.3.
///
/// The copy sits at the *top* of the 140 pt box and a single dashed baseline
/// runs across the full width at `y = 118`, so the card keeps the height and the
/// shape it will have once there is a line to draw.
struct TrendChartEmptyState: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            copy
                .steadyTextStyle(.emptyChartCopy)
                .foregroundStyle(Palette.mut)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Metrics.chartHeight)
        .overlay(alignment: .topLeading) {
            HorizontalRule()
                .stroke(
                    Palette.raw,
                    style: StrokeStyle(
                        lineWidth: Metrics.rawLineWidth,
                        dash: Metrics.emptyBaselineDash
                    )
                )
                .opacity(Metrics.emptyBaselineOpacity)
                .frame(height: Metrics.rawLineWidth)
                .offset(y: Metrics.emptyBaselineY - Metrics.rawLineWidth / 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Your line starts after the first weigh-in. Give it a week and it will mean something."
        )
    }

    /// Two words carry the emphasis: the thing that has to happen is `ink`,
    /// and how long it takes is `ac`.
    private var copy: Text {
        Text("Your line starts after the ")
            + Text("first weigh-in").foregroundStyle(Palette.ink)
            + Text(". Give it ")
            + Text("a week").foregroundStyle(Palette.ac)
            + Text(" and it will mean something.")
    }
}

/// A single horizontal line through the middle of its rect.
private struct HorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Previews

#Preview("Light") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(spacing: Metrics.space4) {
        ForEach(Period.allCases) { period in
            TrendChart(
                series: TrendEngine.series(for: period, values: values, trend: trend),
                period: period
            )
        }
        TrendChartEmptyState()
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let values = TrendPreviewData.values(days: 120)
    let trend = TrendEngine.trend(for: values)
    return VStack(spacing: Metrics.space4) {
        ForEach(Period.allCases) { period in
            TrendChart(
                series: TrendEngine.series(for: period, values: values, trend: trend),
                period: period
            )
        }
        TrendChartEmptyState()
    }
    .padding(Metrics.space4)
    .background(Palette.sur)
    .preferredColorScheme(.dark)
}
